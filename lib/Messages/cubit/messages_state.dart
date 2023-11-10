part of 'messages_cubit.dart';

enum MessagesStatus { groups, message }

enum AcceptStatus { loading, waiting, accepted }

enum GroupSort { createdDate, lastupdatedDate, unread }

class MessagesState extends Equatable {
  const MessagesState({
    this.group,
    this.message,
    this.text = '',
    this.groups = const [],
    this.messages = const [],
    this.status = MessagesStatus.groups,
    this.groupSort = GroupSort.createdDate,
    this.acceptStatus = AcceptStatus.waiting,
  });
  final String text;
  final Group? group;
  final Message? message;
  final GroupSort groupSort;
  final List<Group?> groups;
  final MessagesStatus status;
  final List<Message?> messages;
  final AcceptStatus acceptStatus;

  MessagesState copyWith({
    Group? group,
    String? text,
    Message? message,
    List<Group?>? groups,
    GroupSort? groupSort,
    MessagesStatus? status,
    List<Message?>? messages,
    AcceptStatus? acceptStatus,
  }) {
    return MessagesState(
      text: text ?? this.text,
      group: group ?? this.group,
      groups: groups ?? this.groups,
      status: status ?? this.status,
      message: message ?? this.message,
      messages: messages ?? this.messages,
      groupSort: groupSort ?? this.groupSort,
      acceptStatus: acceptStatus ?? this.acceptStatus,
    );
  }

  @override
  List<Object?> get props => [
        text,
        group,
        status,
        groups,
        message,
        messages,
        groupSort,
        acceptStatus,
      ];
}
