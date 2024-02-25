// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'messages_state.dart';

class MessagesCubit extends Cubit<MessagesState> {
  MessagesCubit({
    required MessagesRepository messagesRepository,
    required RiderProfileRepository riderProfileRepository,
    required HorseProfileRepository horseProfileRepository,
    required this.riderProfile,
  })  : _messagesRepository = messagesRepository,
        _horseProfileRepository = horseProfileRepository,
        _riderProfileRepository = riderProfileRepository,
        super(const MessagesState()) {
    ///   Groups Stream
    _groupsStream = _messagesRepository
        .getGroups(userEmail: riderProfile.email)
        .listen((event) {
      _groups = event.docs.map((e) => (e.data()) as Group?).toList();
      _groups?.sort(
        (a, b) => b!.createdOn.compareTo(a!.createdOn),
      );

      emit(state.copyWith(groups: _groups));
    });
  }

  final RiderProfile riderProfile;

  List<Message?>? _messages;
  final MessagesRepository _messagesRepository;
  final RiderProfileRepository _riderProfileRepository;
  final HorseProfileRepository _horseProfileRepository;
  StreamSubscription<QuerySnapshot<Object?>>? _messagesStream;

  List<Group?>? _groups;
  late final StreamSubscription<QuerySnapshot<Object?>>? _groupsStream;

  void openOrNewMessage(Group? group) {
    if (group != null) {
      ///   Messages Stream
      group.messageState = MessageState.READ;
      _messagesRepository.createOrUpdateGroup(
        group: group,
      );

      _messagesStream =
          _messagesRepository.getMessages(id: group.id).listen((event) {
        _messages = event.docs.map((e) => (e.data()) as Message).toList();
        _messages?.sort(
          (a, b) => (a!.date as DateTime).compareTo(
            b!.date as DateTime,
          ),
        );
        emit(
          state.copyWith(messages: _messages?.reversed.toList()),
        );
      });
      emit(state.copyWith(group: group, status: MessagesStatus.message));
    } else {
      emit(state.copyWith(status: MessagesStatus.message, group: group));
    }
  }

  void textChanged(String value) {
    final text = value;
    emit(state.copyWith(text: text));
  }

  void sendMessage() {
    if (state.text.isNotEmpty) {
      final message = Message(
        date: DateTime.now(),
        messsageId: DateTime.now().millisecondsSinceEpoch.toString(),
        id: state.group?.id,
        sender: riderProfile.name,
        senderProfilePicUrl: riderProfile.picUrl,
        recipients: state.group?.parties,
        subject: '',
        message: state.text,
      );
      state.group?.messageState = MessageState.UNREAD;

      _messagesRepository
        ..createOrUpdateMessage(
          id: message.messsageId,
          message: message,
        )
        ..createOrUpdateGroup(
          group: state.group as Group,
        );
    } else {
      debugPrint('Empty Text');
    }
    emit(state.copyWith(text: ''));
  }

  /// determines if the message request should be visible
  /// if the sender in not the current user
  /// and if the request is not already accepted
  /// returns true if the request should be visible
  bool isRequestVisible({required Message message}) {
    return message.requestItem?.id != riderProfile.email;
  }

  ///   method that checks if the request is accepted
  bool isRequestAccepted({required Message message}) {
    debugPrint('messageSender: ${message.sender}');
    if (message.messageType == MessageType.INSTRUCTOR_REQUEST) {
      debugPrint(
        'Instructor/Student List: ${riderProfile.instructors?.map((e) => e.name)}',
      );
      return riderProfile.instructors
              ?.any((element) => element.name == message.sender) ??
          false;
    } else if (message.messageType == MessageType.STUDENT_HORSE_REQUEST) {
      _riderProfileRepository
          .getProfileByName(name: message.sender as String)
          .first
          .then((value) {
        final senderProfile = value.data() as RiderProfile;

        debugPrint(
          'StudentHorses: ${senderProfile.studentHorses?.map((e) => e.name)}',
        );
        debugPrint('message.requestItem?.name: ${message.requestItem?.name}');
        return senderProfile.studentHorses
                ?.any((element) => element.name == message.requestItem?.name) ??
            false;
      });
    }
    return false;
  }

//  method that accepts MessageType request and adds
//  to the user's and receiver's appropriate lists
  void acceptRequest({
    required Message message,
    required BuildContext context,
  }) {
    emit(state.copyWith(acceptStatus: AcceptStatus.loading));
    _riderProfileRepository
        .getProfileByName(name: message.sender as String)
        .listen((event) {
      final receiverProfile = event.data() as RiderProfile;
      final receiverItem = BaseListItem(
        id: riderProfile.email,
        name: riderProfile.name,
        imageUrl: riderProfile.picUrl,
        isCollapsed: true,
        isSelected: true,
      );
      final riderItem = BaseListItem(
        id: receiverProfile.email,
        name: receiverProfile.name,
        imageUrl: receiverProfile.picUrl,
        isCollapsed: true,
        isSelected: true,
      );
      switch (message.messageType) {
        case MessageType.INSTRUCTOR_REQUEST:
          final instructorAcceptNote = BaseListItem(
            id: DateTime.now().toString(),
            name: 'Added ${riderProfile.name} as an Instructor',
            date: DateTime.now(),
            parentId: receiverProfile.email,
            message: receiverProfile.name,
          );
          final studentAcceptNote = BaseListItem(
            id: DateTime.now().toString(),
            name: 'Added ${receiverProfile.name} as a Student',
            date: DateTime.now(),
            parentId: riderProfile.email,
            message: riderProfile.name,
          );
          if (receiverProfile.instructors == null ||
              receiverProfile.instructors!.isEmpty) {
            receiverProfile.instructors = [riderItem];
          } else {
            receiverProfile.instructors
                ?.removeWhere((element) => element.id == riderProfile.email);
            receiverProfile.instructors?.add(riderItem);
          }
          receiverProfile.notes?.add(instructorAcceptNote);

          if (riderProfile.students == null || riderProfile.students!.isEmpty) {
            riderProfile.students = [receiverItem];
          } else {
            riderProfile.students
                ?.removeWhere((element) => element.id == receiverProfile.email);
            riderProfile.students?.add(receiverItem);
          }
          riderProfile.notes?.add(studentAcceptNote);

          try {
            _riderProfileRepository
              ..createOrUpdateRiderProfile(
                riderProfile: receiverProfile,
              )
              ..createOrUpdateRiderProfile(
                riderProfile: riderProfile,
              );
            message.requestItem?.isSelected = true;
            _messagesRepository
                .createOrUpdateMessage(
              message: message,
              id: message.messsageId,
            )
                .then((value) {
              emit(state.copyWith(acceptStatus: AcceptStatus.accepted));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.blue,
                  content: Text('Added ${receiverProfile.name} as an Student'),
                ),
              );
            });
            emit(state.copyWith(acceptStatus: AcceptStatus.accepted));
          } catch (e) {
            emit(state.copyWith(acceptStatus: AcceptStatus.waiting));
            debugPrint(e.toString());
          }
          break;
        case MessageType.STUDENT_HORSE_REQUEST:
          debugPrint('STUDENT_HORSE_REQUEST');
          HorseProfile studentHorse;
          if (message.requestItem != null) {
            _horseProfileRepository
                .getHorseProfileById(id: message.requestItem!.id ?? '')
                .listen((event) {
              studentHorse = event.data() as HorseProfile;
              debugPrint('studentHorse: $studentHorse');
              final horseNote = BaseListItem(
                id: DateTime.now().toString(),
                name: 'Added ${receiverProfile.name} as a trainer',
                date: DateTime.now(),
                parentId: studentHorse.id,
                message: studentHorse.name,
              );

              final senderAcceptnote = BaseListItem(
                id: DateTime.now().toString(),
                name: 'Added ${studentHorse.name} as a student horse',
                date: DateTime.now(),
                parentId: receiverProfile.email,
                message: receiverProfile.name,
              );
              final receiverAcceptnote = BaseListItem(
                id: DateTime.now().toString(),
                name:
                    'Added ${receiverProfile.name} as a trainer for ${studentHorse.name}',
                date: DateTime.now(),
                parentId: studentHorse.id,
                message: studentHorse.name,
              );

              if (studentHorse.instructors == null ||
                  studentHorse.instructors!.isEmpty) {
                studentHorse.instructors = [receiverItem];
              } else {
                studentHorse.instructors?.removeWhere(
                  (element) => element.id == receiverItem.id,
                );
                studentHorse.instructors?.add(
                  receiverItem,
                );
              }
              studentHorse.notes?.add(horseNote);

              if (receiverProfile.studentHorses == null ||
                  receiverProfile.studentHorses!.isEmpty) {
                receiverProfile.studentHorses = [
                  message.requestItem as BaseListItem,
                ];
              } else {
                receiverProfile.studentHorses?.removeWhere(
                  (element) => element.id == message.requestItem?.id,
                );
                receiverProfile.studentHorses
                    ?.add(message.requestItem as BaseListItem);
              }
              receiverProfile.notes?.add(senderAcceptnote);
              riderProfile.notes?.add(receiverAcceptnote);
              try {
                _horseProfileRepository.createOrUpdateHorseProfile(
                  horseProfile: studentHorse,
                );
                _riderProfileRepository
                  ..createOrUpdateRiderProfile(
                    riderProfile: riderProfile,
                  )
                  ..createOrUpdateRiderProfile(
                    riderProfile: receiverProfile,
                  );
                message.messageState = MessageState.READ;
                _messagesRepository
                    .createOrUpdateMessage(
                  message: message,
                  id: message.messsageId,
                )
                    .then((value) {
                  emit(state.copyWith(acceptStatus: AcceptStatus.accepted));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.blue,
                      content: Text(
                        'Added ${receiverProfile.name} as a trainer for ${studentHorse.name}',
                      ),
                    ),
                  );
                });
              } on FirebaseException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Failed: ${e.message!}'),
                  ),
                );
                emit(state.copyWith(acceptStatus: AcceptStatus.waiting));
                debugPrint(e.toString());
              }
            });
          } else {
            debugPrint('message.requestItem is null');
            emit(state.copyWith(acceptStatus: AcceptStatus.waiting));
          }

          break;
        case MessageType.STUDENT_REQUEST:
          final studentAcceptNote = BaseListItem(
            id: DateTime.now().toString(),
            name: 'Added ${riderProfile.name} as a student',
            date: DateTime.now(),
            parentId: receiverProfile.email,
            message: receiverProfile.name,
          );
          final instructorAcceptNote = BaseListItem(
            id: DateTime.now().toString(),
            name: 'Added ${receiverProfile.name} as an instructor',
            date: DateTime.now(),
            parentId: riderProfile.email,
            message: riderProfile.name,
          );

          // TODO(mfrenchy77): check the logic here
          if (receiverProfile.students == null ||
              receiverProfile.students!.isEmpty) {
            receiverProfile.students = [receiverItem];
          } else {
            receiverProfile.students?.removeWhere(
              (element) => element.id == receiverItem.id,
            );
            receiverProfile.students?.add(
              receiverItem,
            );
          }
          receiverProfile.notes?.add(studentAcceptNote);
          if (riderProfile.instructors == null ||
              riderProfile.instructors!.isEmpty) {
            riderProfile.instructors = [riderItem];
          } else {
            riderProfile.instructors?.removeWhere(
              (element) => element.id == riderItem.id,
            );
            riderProfile.instructors?.add(
              riderItem,
            );
          }
          riderProfile.notes?.add(instructorAcceptNote);
          try {
            _riderProfileRepository
              ..createOrUpdateRiderProfile(riderProfile: riderProfile)
              ..createOrUpdateRiderProfile(riderProfile: receiverProfile);
            message.requestItem?.isSelected = true;
            _messagesRepository
                .createOrUpdateMessage(
              message: message,
              id: message.messsageId,
            )
                .then((value) {
              emit(state.copyWith(acceptStatus: AcceptStatus.accepted));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.blue,
                  content: Text(
                    'Added ${receiverProfile.name} as an instructor for ${riderProfile.name}',
                  ),
                ),
              );
            });
          } on FirebaseException catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content: Text('Failed: ${e.message!}'),
              ),
            );
            emit(state.copyWith(acceptStatus: AcceptStatus.waiting));
            debugPrint(e.toString());
          }
          break;

        case MessageType.EDIT_REQUEST:
          // TODO(mfrenchy77): 2021-02-17 This is where whe are going to handle skill tree edit requests to the author of the skill
          debugPrint('EDIT_REQUEST');
          break;
        case MessageType.CHAT:
          debugPrint('CHAT');
          break;
      }
    });
  }

  void goToGroups() {
    final updatedGroup = state.group as Group
      ..recentMessage = state.messages.isNotEmpty ? state.messages.first : null
      ..lastEditDate = DateTime.now()
      ..lastEditBy = riderProfile.name;
    _messagesRepository.createOrUpdateGroup(group: updatedGroup);
    emit(state.copyWith(status: MessagesStatus.groups));

    _messagesStream?.cancel();
  }

//  opens the dialog to sort message groups
  void openSortDialog({
    required BuildContext context,
  }) {
    debugPrint('openSortDialog');
    showDialog<AlertDialog>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Messages By:'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<GroupSort>(
              title: const Text('Newest'),
              value: GroupSort.createdDate,
              groupValue: state.groupSort,
              onChanged: (value) {
                _sortGroup(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<GroupSort>(
              title: const Text('Recently Updated'),
              value: GroupSort.lastupdatedDate,
              groupValue: state.groupSort,
              onChanged: (value) {
                _sortGroup(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<GroupSort>(
              title: const Text('Unread'),
              value: GroupSort.unread,
              groupValue: state.groupSort,
              onChanged: (value) {
                _sortGroup(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String sortedMessagesText() {
    switch (state.groupSort) {
      case GroupSort.createdDate:
        return 'Newest';
      case GroupSort.lastupdatedDate:
        return 'Recently Updated';
      case GroupSort.unread:
        return 'Unread';
    }
  }

  /// This is where we are going to sort the groups by messageState, creadtedDate, and lastEditDate
  void _sortGroup(GroupSort value) {
    emit(state.copyWith(groupSort: value));

    switch (state.groupSort) {
      case GroupSort.createdDate:
        state.groups.sort(
          (a, b) =>
              (b?.createdOn as DateTime).compareTo(a?.createdOn as DateTime),
        );
        emit(state.copyWith(groups: state.groups));
        break;
      case GroupSort.lastupdatedDate:
        state.groups.sort(
          (a, b) => (b?.lastEditDate as DateTime)
              .compareTo(a?.lastEditDate as DateTime),
        );
        emit(state.copyWith(groups: state.groups));

        break;
      case GroupSort.unread:
        state.groups.sort(
          (a, b) => (a?.messageState.index as int)
              .compareTo(b?.messageState.index as int),
        );

        emit(state.copyWith(groups: state.groups));
        break;
    }
  }

  void setGroup(Group? group) {
    emit(state.copyWith(group: group));
  }

  @override
  Future<void> close() {
    _groupsStream?.cancel();
    return super.close();
  }
}
