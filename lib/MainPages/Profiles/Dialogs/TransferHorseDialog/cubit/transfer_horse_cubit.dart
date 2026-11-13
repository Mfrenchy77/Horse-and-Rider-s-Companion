// ignore_for_file: cast_nullable_to_non_nullable

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

part 'transfer_horse_state.dart';

class TransferHorseCubit extends Cubit<TransferHorseState> {
  TransferHorseCubit({
    required RiderProfile userProfile,
    required HorseProfile horseProfile,
    required this._messagesRepository,
    required this._riderProfileRepository,
  }) : super(const TransferHorseState()) {
    emit(state.copyWith(userProfile: userProfile, horseProfile: horseProfile));
  }

  Timer? _debounce;
  final MessagesRepository _messagesRepository;
  final RiderProfileStore _riderProfileRepository;

  int _lookupVersion = 0;
  bool _sending = false;

  /// Email text changed. Invalidate old results before the debounce finishes.
  void emailChanged(String email) {
    final normalized = email.trim().toLowerCase();
    final emailField = Email.dirty(normalized);
    _lookupVersion++;
    _debounce?.cancel();
    emit(
      state.copyWith(
        email: emailField,
        clearTransferProfile: true,
        isTransferable: false,
        isError: false,
        isMessage: false,
        message: '',
        status: TransferHorseStatus.initial,
      ),
    );
    if (!emailField.isValid) return;
    _debounce = Timer(const Duration(milliseconds: 500), () {
      getTransferProfile(normalized);
    });
  }

  /// Only the latest recipient lookup may update this dialog.
  Future<void> getTransferProfile(String email) async {
    if (isClosed) return;
    final version = ++_lookupVersion;
    final normalized = email.trim().toLowerCase();
    final emailField = Email.dirty(normalized);
    emit(
      state.copyWith(
        email: emailField,
        clearTransferProfile: true,
        isTransferable: false,
        isError: false,
        message: '',
        status: emailField.isValid
            ? TransferHorseStatus.searching
            : TransferHorseStatus.initial,
      ),
    );
    if (!emailField.isValid) return;
    try {
      final profile = await _riderProfileRepository.getRiderProfileByEmail(
        email: normalized,
      );
      if (isClosed || version != _lookupVersion) return;
      emit(
        state.copyWith(
          transferProfile: profile,
          clearTransferProfile: profile == null,
          isTransferable:
              profile != null &&
              profile.email.toLowerCase() !=
                  state.userProfile?.email.toLowerCase(),
          status: TransferHorseStatus.initial,
          message: profile == null ? '' : '${profile.name} found',
        ),
      );
    } catch (error) {
      if (isClosed || version != _lookupVersion) return;
      _fail('An error occurred while searching for the user.');
    }
  }

  /// Persist the conversation and its request using one captured recipient.
  Future<void> sendTransferRequest() async {
    if (isClosed || _sending) return;
    final sender = state.userProfile;
    final recipient = state.transferProfile;
    final horse = state.horseProfile;
    if (sender == null ||
        recipient == null ||
        horse == null ||
        sender.email.isEmpty ||
        recipient.email.isEmpty) {
      _fail('Select a valid recipient before transferring this horse.');
      return;
    }
    if (sender.email.toLowerCase() == recipient.email.toLowerCase()) {
      _fail('You cannot transfer this horse to yourself');
      return;
    }
    if (!state.isTransferable) {
      _fail('Select a valid recipient before transferring this horse.');
      return;
    }
    if (horse.currentOwnerId.toLowerCase() != sender.email.toLowerCase()) {
      _fail('Only the current owner can transfer this horse.');
      return;
    }

    _sending = true;
    emit(
      state.copyWith(
        status: TransferHorseStatus.sending,
        isError: false,
        isMessage: false,
        message: '',
      ),
    );
    try {
      final emails = [sender.email.toLowerCase(), recipient.email.toLowerCase()]
        ..sort();
      final conversationId = convertEmailToPath(emails.join('_'));
      final request = BaseListItem(
        id: horse.id,
        name: horse.name,
        extra: sender.email,
        imageUrl: horse.picUrl,
        parentId: horse.currentOwnerId,
        message: horse.currentOwnerName,
        isCollapsed: false,
        isSelected: false,
      );
      final message = Message(
        id: conversationId,
        date: DateTime.now(),
        requestItem: request,
        subject: 'Transfer Horse',
        sender: sender.name,
        senderId: sender.email.toLowerCase(),
        messageType: MessageType.TRANSFER_HORSE_REQUEST,
        senderProfilePicUrl: sender.picUrl,
        message: '${sender.name} wants to transfer ${horse.name} to you',
        messageId: ViewUtils.createId(),
        recipients: [sender.name, recipient.name],
      );
      final conversation = Conversation(
        id: conversationId,
        parties: [sender.name, recipient.name],
        partiesIds: [sender.email.toLowerCase(), recipient.email.toLowerCase()],
        createdOn: DateTime.now(),
        lastEditDate: DateTime.now(),
        createdBy: sender.name,
        lastEditBy: sender.name,
        recentMessage: message,
      );
      await _messagesRepository.createOrUpdateConversation(
        conversation: conversation,
      );
      await _messagesRepository.createOrUpdateMessage(message: message);
      if (!isClosed) {
        emit(
          state.copyWith(
            isMessage: true,
            status: TransferHorseStatus.success,
            message: 'Message sent to ${recipient.email}',
          ),
        );
      }
    } catch (error) {
      _fail('Error sending transfer request');
    } finally {
      _sending = false;
    }
  }

  void _fail(String message) {
    if (!isClosed) {
      emit(
        state.copyWith(
          isError: true,
          status: TransferHorseStatus.error,
          message: message,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _lookupVersion++;
    _debounce?.cancel();
    return super.close();
  }

  /// Clear the error message
  void clearError() {
    emit(
      state.copyWith(
        message: '',
        isError: false,
        isMessage: false,
        status: TransferHorseStatus.initial,
      ),
    );
  }
}
