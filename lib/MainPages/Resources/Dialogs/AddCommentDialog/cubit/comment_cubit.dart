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
  }) : super(const CommentState()) {
    emit(
      state.copyWith(
        comment: comment,
        resource: resource,
        usersProfile: usersProfile,
      ),
    );
  }

  final ResourcesRepository _resourceRepository = ResourcesRepository();

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
      emit(state.copyWith(status: CommentStatus.success));
    } catch (e) {
      debugPrint('sendComment error: $e');
      emit(state.copyWith(status: CommentStatus.initial));
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
    final newRatingUser = BaseListItem(
      id: state.usersProfile?.email ?? '',
      isCollapsed: false,
      isSelected: false,
    );

    final usersRating = comment.usersWhoRated?.firstWhere(
      (element) => element.id == state.usersProfile?.email,
      orElse: BaseListItem.new,
    );
    return comment.usersWhoRated == null ? newRatingUser : usersRating;
  }

  // --- your recommend / don't recommend methods unchanged below ---
  Future<void> reccomendComment({required Comment comment}) async {
    final commentsResource = state.resource;
    if (commentsResource == null) {
      emit(state.copyWith(positiveStatus: PositiveStatus.loading));
      debugPrint('Resource is null, cannot recommend comment');
      return;
    } else {
      commentsResource.comments?.map((e) {
        if (e.id == comment.id) {
          return _setNewPositiveRating(comment: comment);
        } else {
          return e;
        }
      }).toList();
      try {
        await _resourceRepository.createOrUpdateResource(
          resource: commentsResource,
        );
        emit(state.copyWith(positiveStatus: PositiveStatus.success));
      } catch (e) {
        emit(state.copyWith(positiveStatus: PositiveStatus.initial));
        debugPrint('Error Positive Comment Recommendation: $e');
      }
    }
  }

  Future<void> dontReccomendComment({required Comment comment}) async {
    final commentsResource = state.resource;
    if (commentsResource == null) {
      emit(state.copyWith(negativeStatus: NegativeStatus.loading));
      debugPrint('Resource is null, cannot recommend comment');
      return;
    } else {
      commentsResource.comments?.map((e) {
        if (e.id == comment.id) {
          return _setNewNegativeRating(comment: comment);
        } else {
          return e;
        }
      }).toList();
      try {
        await _resourceRepository.createOrUpdateResource(
          resource: commentsResource,
        );
        emit(state.copyWith(negativeStatus: NegativeStatus.success));
      } catch (e) {
        emit(state.copyWith(negativeStatus: NegativeStatus.initial));
        debugPrint('Error Negative Comment Recommendation: $e');
      }
    }
  }

  Comment _setNewPositiveRating({required Comment comment}) {
    final userEmail = state.usersProfile?.email;
    final newuser =
        BaseListItem(id: userEmail, isSelected: true, isCollapsed: false);
    final newUsersWhoRated = [newuser];

    final newPositiveRating = (comment.rating ?? 0) + 1;
    final newDoublePositveRating = (comment.rating ?? 0) + 2;
    final newNegativeRating = (comment.rating ?? 0) - 1;

    if (comment.usersWhoRated != null && comment.usersWhoRated!.isNotEmpty) {
      final user =
          comment.usersWhoRated?.firstWhereOrNull((e) => e.id == userEmail);
      if (user != null) {
        if (user.isSelected == null && user.isCollapsed == null) {
          comment.usersWhoRated?.add(newuser);
          comment.rating = newPositiveRating;
          return comment;
        } else if (user.isSelected ?? false) {
          comment.usersWhoRated
              ?.firstWhere((e) => e.id == userEmail)
              .isSelected = false;
          comment.usersWhoRated
              ?.firstWhere((e) => e.id == userEmail)
              .isCollapsed = false;
          comment.rating = newNegativeRating;
          return comment;
        } else if (user.isSelected == false && user.isCollapsed == false) {
          comment.usersWhoRated
              ?.firstWhere((e) => e.id == userEmail)
              .isSelected = true;
          comment.usersWhoRated
              ?.firstWhere((e) => e.id == userEmail)
              .isCollapsed = false;
          comment.rating = newPositiveRating;
          return comment;
        } else if (user.isSelected == false && (user.isCollapsed ?? false)) {
          comment.usersWhoRated
              ?.firstWhere((e) => e.id == userEmail)
              .isSelected = true;
          comment.usersWhoRated
              ?.firstWhere((e) => e.id == userEmail)
              .isCollapsed = false;
          comment.rating = newDoublePositveRating;
          return comment;
        } else {
          return comment;
        }
      } else {
        comment.usersWhoRated?.add(newuser);
        comment.rating = newPositiveRating;
        return comment;
      }
    } else {
      comment
        ..usersWhoRated = newUsersWhoRated
        ..rating = newPositiveRating;
      return comment;
    }
  }

  Comment _setNewNegativeRating({required Comment comment}) {
    final userEmail = state.usersProfile!.email;
    final newuser =
        BaseListItem(id: userEmail, isSelected: false, isCollapsed: true);
    final newUsersWhoRated = [newuser];

    final newPositiveRating = (comment.rating ?? 0) + 1;
    final newNegativeRating = (comment.rating ?? 0) - 1;
    final newDoubleNegativeRating = (comment.rating ?? 0) - 2;

    if (comment.usersWhoRated != null && comment.usersWhoRated!.isNotEmpty) {
      final user =
          comment.usersWhoRated?.firstWhereOrNull((e) => e.id == userEmail);
      if (user != null) {
        if (user.isSelected == null && user.isCollapsed == null) {
          comment.usersWhoRated?.add(newuser);
          comment.rating = newNegativeRating;
          return comment;
        } else if (user.isSelected == false && (user.isCollapsed ?? false)) {
          comment.usersWhoRated
              ?.firstWhere((e) => e.id == userEmail)
              .isSelected = false;
          comment.usersWhoRated
              ?.firstWhere((e) => e.id == userEmail)
              .isCollapsed = false;
          comment.rating = newPositiveRating;
          return comment;
        } else if (user.isSelected == false && user.isCollapsed == false) {
          comment.usersWhoRated
              ?.firstWhere((e) => e.id == userEmail)
              .isSelected = false;
          comment.usersWhoRated
              ?.firstWhere((e) => e.id == userEmail)
              .isCollapsed = true;
          comment.rating = newNegativeRating;
          return comment;
        } else if (user.isSelected ?? false) {
          comment.usersWhoRated
              ?.firstWhere((e) => e.id == userEmail)
              .isSelected = false;
          comment.usersWhoRated
              ?.firstWhere((e) => e.id == userEmail)
              .isCollapsed = true;
          comment.rating = newDoubleNegativeRating;
          return comment;
        } else {
          return comment;
        }
      } else {
        comment.usersWhoRated?.add(newuser);
        comment.rating = newNegativeRating;
        return comment;
      }
    } else {
      comment
        ..usersWhoRated = newUsersWhoRated
        ..rating = newNegativeRating;
      return comment;
    }
  }
}
