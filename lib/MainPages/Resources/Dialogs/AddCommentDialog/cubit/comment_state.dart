part of 'comment_cubit.dart';

class CommentState extends Equatable {
  const CommentState({
    this.comment,
    this.resource,
    this.usersProfile,
    this.commentMessage = '',
  });

  /// The comment that the user is commenting on
  final Comment? comment;

  /// The resource that the user is commenting on
  final Resource? resource;

  /// The users comment message
  final String commentMessage;

  ///User's profile
  final RiderProfile? usersProfile;

  CommentState copyWith({
    Comment? comment,
    Resource? resource,
    String? commentMessage,
    RiderProfile? usersProfile,
  }) {
    return CommentState(
      comment: comment ?? this.comment,
      resource: resource ?? this.resource,
      usersProfile: usersProfile ?? this.usersProfile,
      commentMessage: commentMessage ?? this.commentMessage,
    );
  }

  @override
  List<Object?> get props => [
        comment,
        resource,
        usersProfile,
        commentMessage,
      ];
}
