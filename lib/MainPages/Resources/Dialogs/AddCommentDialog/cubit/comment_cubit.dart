// lib/MainPages/Resources/Dialogs/AddCommentDialog/cubit/comment_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

part 'comment_state.dart';

class CommentCubit extends Cubit<CommentState> {
  CommentCubit({
    required Comment? comment,
    required Resource resource,
    required RiderProfile usersProfile,
    ResourcesRepository? resourcesRepository,
  }) : _resourceRepository = resourcesRepository ?? ResourcesRepository(),
       super(const CommentState()) {
    emit(
      state.copyWith(
        comment: comment,
        resource: resource,
        usersProfile: usersProfile,
      ),
    );
  }

  final ResourcesRepository _resourceRepository;

  void setEdit({required bool isEdit}) => emit(state.copyWith(isEdit: isEdit));

  void updateCommentMessage(String commentMessage) =>
      emit(state.copyWith(commentMessage: commentMessage));

  /// Create or update a comment.
  Future<void> sendComment() async {
    final res = state.resource;
    if (res == null) {
      emit(state.copyWith(status: CommentStatus.initial));
      debugPrint('Resource is null, cannot send comment');
      return;
    }

    emit(state.copyWith(status: CommentStatus.loading));

    // Work on a copy, never mutate in-place
    final comments = List<Comment>.from(res.comments ?? const <Comment>[]);

    if (state.isEdit && state.comment != null) {
      // EDIT: replace existing
      final idx = comments.indexWhere((c) => c.id == state.comment!.id);
      if (idx != -1) {
        comments[idx] = state.comment!.copyWith(
          comment: state.commentMessage.trim(), // JSON string
          editedDate: DateTime.now(),
          // keep user/rating/parentId/resourceId as-is
        );
      } else {
        debugPrint('Edit requested but original comment not found; appending.');
        comments.add(
          state.comment!.copyWith(
            comment: state.commentMessage.trim(),
            editedDate: DateTime.now(),
          ),
        );
      }
    } else {
      // NEW or REPLY: parentId = parent comment id (if replying), else null
      final newComment = Comment(
        id: ViewUtils.createId(),
        parentId: state.comment?.id,
        comment: state.commentMessage.trim(), // JSON string
        usersWhoRated: <BaseListItem>[],
        rating: 0,
        editedDate: null,
        user: _createUser(),
        date: DateTime.now(),
        resourceId: res.id,
      );
      comments.add(newComment);
    }

    final updatedResource = res.copyWith(comments: comments);

    try {
      await _resourceRepository.createOrUpdateResource(
        resource: updatedResource,
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            resource: updatedResource,
            status: CommentStatus.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('sendComment error: $e');
      if (!isClosed) emit(state.copyWith(status: CommentStatus.initial));
    }
  }

  BaseListItem _createUser() => BaseListItem(
    id: state.usersProfile?.email,
    name: state.usersProfile?.name,
    imageUrl: state.usersProfile?.picUrl,
  );

  bool isRatingPositive(Comment comment) {
    final rating = getUserRatingForComment(comment);
    return rating?.isSelected ?? false;
  }

  BaseListItem? getUserRatingForComment(Comment comment) {
    final current =
        state.resource?.comments?.firstWhereOrNull(
          (item) => item.id == comment.id,
        ) ??
        comment;
    return current.usersWhoRated?.firstWhereOrNull(
      (item) => item.id == state.usersProfile?.email,
    );
  }

  /// Keep the rating controls in sync with new resource snapshots.
  void updateResource(Resource resource) {
    if (!isClosed && !identical(state.resource, resource)) {
      emit(state.copyWith(resource: resource));
    }
  }

  bool _ratingInFlight = false;

  Future<void> reccomendComment({required Comment comment}) =>
      _rateComment(comment: comment, vote: 1);

  Future<void> dontReccomendComment({required Comment comment}) =>
      _rateComment(comment: comment, vote: -1);

  Future<void> _rateComment({
    required Comment comment,
    required int vote,
  }) async {
    if (_ratingInFlight || isClosed) return;
    final resource = state.resource;
    final userEmail = state.usersProfile?.email;
    final comments = List<Comment>.from(resource?.comments ?? const []);
    final index = comments.indexWhere((item) => item.id == comment.id);
    if (resource == null ||
        resource.id == null ||
        comment.id == null ||
        userEmail == null ||
        userEmail.trim().isEmpty ||
        index < 0) {
      return;
    }

    _ratingInFlight = true;
    emit(
      state.copyWith(
        positiveStatus: vote == 1
            ? PositiveStatus.loading
            : state.positiveStatus,
        negativeStatus: vote == -1
            ? NegativeStatus.loading
            : state.negativeStatus,
      ),
    );
    try {
      final updatedComment = await _resourceRepository.rateComment(
        resourceId: resource.id!,
        commentId: comment.id!,
        userEmail: userEmail,
        vote: vote,
      );
      final latest = state.resource ?? resource;
      final updatedResource = latest.copyWith(
        comments: [
          for (final item in latest.comments ?? <Comment>[])
            if (item.id == updatedComment.id) updatedComment else item,
        ],
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            resource: updatedResource,
            positiveStatus: vote == 1
                ? PositiveStatus.success
                : state.positiveStatus,
            negativeStatus: vote == -1
                ? NegativeStatus.success
                : state.negativeStatus,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            positiveStatus: vote == 1
                ? PositiveStatus.failure
                : state.positiveStatus,
            negativeStatus: vote == -1
                ? NegativeStatus.failure
                : state.negativeStatus,
          ),
        );
      }
    } finally {
      _ratingInFlight = false;
    }
  }
}
