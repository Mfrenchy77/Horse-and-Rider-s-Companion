part of 'comment_cubit.dart';

enum CommentStatus {
  initial,
  loading,
  success,
}

enum PositiveStatus {
  initial,
  loading,
  success,
}

enum NegativeStatus {
  initial,
  loading,
  success,
}

class CommentState extends Equatable {
  const CommentState({
    this.comment,
    this.resource,
    this.usersProfile,
    this.isEdit = false,
    this.commentMessage = '',
    this.status = CommentStatus.initial,
    this.positiveStatus = PositiveStatus.initial,
    this.negativeStatus = NegativeStatus.initial,
  });

  /// Whether we are editing a comment or creating a new one
  final bool isEdit;

  /// The comment that the user is commenting on
  final Comment? comment;

  /// The resource that the user is commenting on
  final Resource? resource;

  /// The status of the comment
  final CommentStatus status;

  /// The users comment message
  final String commentMessage;

  ///User's profile
  final RiderProfile? usersProfile;

  /// The status of the positive rating
  final PositiveStatus positiveStatus;

  /// The status of the negative rating
  final NegativeStatus negativeStatus;

  CommentState copyWith({
    bool? isEdit,
    Comment? comment,
    Resource? resource,
    String? commentMessage,
    CommentStatus? status,
    RiderProfile? usersProfile,
    PositiveStatus? positiveStatus,
    NegativeStatus? negativeStatus,
  }) {
    return CommentState(
      isEdit: isEdit ?? this.isEdit,
      status: status ?? this.status,
      comment: comment ?? this.comment,
      resource: resource ?? this.resource,
      usersProfile: usersProfile ?? this.usersProfile,
      commentMessage: commentMessage ?? this.commentMessage,
      negativeStatus: negativeStatus ?? this.negativeStatus,
      positiveStatus: positiveStatus ?? this.positiveStatus,
    );
  }

  @override
  List<Object?> get props => [
        isEdit,
        status,
        comment,
        resource,
        usersProfile,
        commentMessage,
        positiveStatus,
        negativeStatus,
      ];
}
