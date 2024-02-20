part of 'messages_cubit.dart';

enum MessagesStatus { groups, message }

enum AcceptStatus { loading, waiting, accepted }

enum GroupSort { createdDate, lastupdatedDate, unread }

class MessagesState extends Equatable {
  const MessagesState({
    this.group,
    this.error,
    this.message,
    this.text = '',
    this.isError = false,
    this.groups = const [],
    this.messages = const [],
    this.status = MessagesStatus.groups,
    this.groupSort = GroupSort.createdDate,
    this.acceptStatus = AcceptStatus.waiting,
  });
  final String text;
  final bool isError;
  final Group? group;
  final String? error;
  final Message? message;
  final GroupSort groupSort;
  final List<Group?> groups;
  final MessagesStatus status;
  final List<Message?> messages;
  final AcceptStatus acceptStatus;

  MessagesState copyWith({
    Group? group,
    String? text,
    bool? isError,
    String? error,
    Message? message,
    List<Group?>? groups,
    GroupSort? groupSort,
    MessagesStatus? status,
    List<Message?>? messages,
    AcceptStatus? acceptStatus,
  }) {
    return MessagesState(
      text: text ?? this.text,
      error: error ?? this.error,
      group: group ?? this.group,
      groups: groups ?? this.groups,
      status: status ?? this.status,
      isError: isError ?? this.isError,
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
        error,
        status,
        groups,
        isError,
        message,
        messages,
        groupSort,
        acceptStatus,
      ];
}
