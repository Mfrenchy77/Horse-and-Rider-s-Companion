// ignore_for_file: cast_nullable_to_non_nullable

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

part 'transfer_horse_state.dart';

class TransferHorseCubit extends Cubit<TransferHorseState> {
  TransferHorseCubit({
    required RiderProfile userProfile,
    required HorseProfile horseProfile,
    required MessagesRepository messagesRepository,
    required RiderProfileRepository riderProfileRepository,
  })  : _messagesRepository = messagesRepository,
        _riderProfileRepository = riderProfileRepository,
        super(const TransferHorseState()) {
    emit(
      state.copyWith(
        userProfile: userProfile,
        horseProfile: horseProfile,
      ),
    );
  }

  Timer? _debounce;
  final MessagesRepository _messagesRepository;
  final RiderProfileRepository _riderProfileRepository;

  /// Email text changed
  void emailChanged(String email) {
    final emailField = Email.dirty(email);

    emit(
      state.copyWith(email: emailField),
    );
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (emailField.isValid) {
        debugPrint('Email is valid: $email');
        getTransferProfile(email);
      } else {
        debugPrint('Email is not valid: $email');
        emit(
          state.copyWith(
            isTransferable: false,
            // ignore: avoid_redundant_argument_values
            transferProfile: null,
            status: TransferHorseStatus.initial,
          ),
        );
      }
    });
  }

  /// Try to get the transfer profile
  Future<void> getTransferProfile(String email) async {
    emit(state.copyWith(status: TransferHorseStatus.searching));
    try {
      final snapshot =
          await _riderProfileRepository.getRiderProfileByEmail(email: email);
      if (snapshot.exists) {
        final transferProfile = snapshot.data();
        debugPrint('User found: ${transferProfile?.name}');

        emit(
          state.copyWith(
            isError: false,
            status: TransferHorseStatus.initial,
            isTransferable: true,
            transferProfile: transferProfile,
            message: '${transferProfile?.name} found',
          ),
        );
      } else {
        emit(
          state.copyWith(
            isTransferable: false,
            // ignore: avoid_redundant_argument_values
            transferProfile: null,
            status: TransferHorseStatus.initial,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in getTransferProfile: $e');

      emit(
        state.copyWith(
          isError: true,
          status: TransferHorseStatus.error,
          message: 'An error occurred while searching for the user.',
        ),
      );
    }
  }

  /// Send a message to the transfer profile to accept the horse
  Future<void> sendTransferRequest() async {
    emit(
      state.copyWith(
        status: TransferHorseStatus.sending,
      ),
    );
    // send a message to the transfer profile to accept the horse
    if (state.userProfile?.email != state.transferProfile?.email) {
      final horse = BaseListItem(
        id: state.horseProfile?.id,
        name: state.horseProfile?.name,
        extra: state.userProfile?.email,
        imageUrl: state.horseProfile?.picUrl,
        parentId: state.horseProfile?.currentOwnerId,
        message: state.horseProfile?.currentOwnerName,
        isCollapsed: false,
        isSelected: false,
      );

      final conversation = Conversation(
        id: _createHorseConversationId(),
        parties: [state.userProfile?.email, state.transferProfile?.email]
            .map((e) => e!.toLowerCase())
            .toList(),
        partiesIds: [state.userProfile?.id, state.transferProfile?.id]
            .map((e) => e!)
            .toList(),
        createdOn: DateTime.now(),
        lastEditDate: DateTime.now(),
        createdBy: state.userProfile!.name,
        lastEditBy: state.userProfile?.name,
        recentMessage: _createTransferMessage(
          request: horse,
          groupId: _createHorseConversationId(),
        ),
      );

      if (state.userProfile?.email != null &&
          state.transferProfile?.email != null &&
          state.userProfile!.email != state.transferProfile!.email) {
        try {
          await _messagesRepository.createOrUpdateConversation(
            conversation: conversation,
          );
          await _messagesRepository
              .createOrUpdateMessage(
            message: _createTransferMessage(
              request: horse,
              groupId: conversation.id,
            ),
          )
              .then(
            (value) {
              debugPrint('Message sent');
              emit(
                state.copyWith(
                  isMessage: true,
                  status: TransferHorseStatus.success,
                  message: 'Message sent to '
                      '${state.transferProfile?.email}',
                ),
              );
            },
          );
        } catch (e) {
          debugPrint('Error in sendTransferRequest: $e');
          emit(
            state.copyWith(
              isError: true,
              status: TransferHorseStatus.error,
              message: 'Error sending transfer request',
            ),
          );
        }
      } else {
        emit(
          state.copyWith(
            isError: true,
            status: TransferHorseStatus.error,
            message: 'You cannot transfer this horse to yourself',
          ),
        );
      }
    } else {
      emit(
        state.copyWith(
          isError: true,
          status: TransferHorseStatus.error,
          message: 'Not a valid transfer',
        ),
      );
    }
  }

  Message _createTransferMessage({
    required BaseListItem request,
    required String groupId,
  }) {
    return Message(
      id: groupId,
      date: DateTime.now(),
      requestItem: request,
      subject: 'Transfer Horse',
      sender: state.userProfile?.name,
      messageType: MessageType.TRANSFER_HORSE_REQUEST,
      senderProfilePicUrl: state.userProfile?.picUrl,
      message: '${state.userProfile?.name} wants to transfer'
          ' ${state.horseProfile?.name} to you',
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      recipients: [state.userProfile?.name, state.transferProfile?.name]
          .map((e) => e)
          .toList(),
    );
  }

  /// Creates a unique group id for the message
  String _createHorseConversationId() {
    // Create a list of the two emails, converted to paths and in lowercase
    final emails = <String>[
      state.userProfile?.email.toLowerCase() as String,
      state.transferProfile?.email.toLowerCase() as String,
    ]..sort();

    // Join the emails with an underscore
    final idbuff = emails.join('_');
    return convertEmailToPath(idbuff);
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
