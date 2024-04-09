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

  /// Resource Repository
  final ResourcesRepository _resourceRepository = ResourcesRepository();

  /// Set the edit state to Editing
  void setEdit({required bool isEdit}) {
    emit(state.copyWith(isEdit: isEdit));
  }

  /// Update the comment message
  void updateCommentMessage(String commentMessage) {
    emit(
      state.copyWith(
        commentMessage: commentMessage,
      ),
    );
  }

  /// Send the comment
  Future<void> sendComment() async {
    if (state.resource != null) {
      emit(state.copyWith(status: CommentStatus.loading));
      final comment = Comment(
        id: ViewUtils.createId(),
        parentId: state.comment?.id,
        comment: state.commentMessage.trim(),
        usersWhoRated: <BaseListItem>[],
        rating: state.isEdit ? state.comment?.rating : 0,
        editedDate: state.isEdit ? DateTime.now() : null,
        user: state.isEdit ? state.comment?.user : _createUser(),
        date: state.isEdit
            ? state.comment?.date ?? DateTime.now()
            : DateTime.now(),
        resourceId:
            state.isEdit ? state.comment?.resourceId : state.resource!.id,
      );

      final updatedResource = state.resource!;
      updatedResource.comments = updatedResource.comments ?? <Comment>[];
      updatedResource.comments!.add(comment);

      await _resourceRepository.createOrUpdateResource(
        resource: updatedResource,
      );
      emit(state.copyWith(status: CommentStatus.success));
    } else {
      emit(state.copyWith(status: CommentStatus.initial));
      debugPrint('Resource is null, cannot send comment');
    }
  }

  /// create a user from the usersProfile
  BaseListItem _createUser() {
    return BaseListItem(
      id: state.usersProfile?.email,
      name: state.usersProfile?.name,
      imageUrl: state.usersProfile?.picUrl,
    );
  }

  /// Determines if user has rated the [comment] positively or not
  bool isRatingPositive(Comment comment) {
    final rating = getUserRatingForComment(comment);
    return rating?.isSelected ?? false;
  }

  /// Gets the user rating for the [comment] or creates a new one
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
    if (comment.usersWhoRated == null) {
      return newRatingUser;
    } else {
      return usersRating;
    }
  }

  ///  User has clicked the recommend [comment] button
  Future<void> reccomendComment({required Comment comment}) async {
    final commentsResource = state.resource;
    if (commentsResource == null) {
      emit(state.copyWith(positiveStatus: PositiveStatus.loading));
      debugPrint('Resource is null, cannot recommend comment');
      return;
    } else {
// set the new rating and add to the update the comment in the resource
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

  ///  User has clicked the dont recommend [comment] button
  Future<void> dontReccomendComment({required Comment comment}) async {
    final commentsResource = state.resource;
    if (commentsResource == null) {
      emit(state.copyWith(negativeStatus: NegativeStatus.loading));
      debugPrint('Resource is null, cannot recommend comment');
      return;
    } else {
      // set the new rating and add to the update the comment in the resource
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

  ///   Sets the new Rating on the [comment] based on whether or not they rated
  Comment _setNewPositiveRating({
    required Comment comment,
  }) {
    final userEmail = state.usersProfile?.email;

    //   List item with user and rated is true
    final newuser = BaseListItem(
      id: userEmail,
      isSelected: true,
      isCollapsed: false,
    );

    //   List with the user and rated value loaded in
    final newUsersWhoRated = [newuser];

    // New Ratings
    final newPositiveRating = comment.rating! + 1;
    final newDoublePositveRating = comment.rating! + 2;
    final newNegativeRating = comment.rating! - 1;

    // All Conditions possible
    if (comment.usersWhoRated != null && comment.usersWhoRated!.isNotEmpty) {
      //   Reference to the user
      final user = comment.usersWhoRated?.firstWhereOrNull(
        (element) => element.id == userEmail,
      );
      //   'List is not NULL
      if (user != null) {
        //   Found UserWhoRated
        if (user.isSelected == null && user.isCollapsed == null) {
          //   Never Rated before addding User and +1
          comment.usersWhoRated?.add(newuser);
          comment.rating = newPositiveRating;
          return comment;
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == true && user.isCollapsed == false) {
          //   Already Positive Rating, -1
          comment.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isSelected = false;
          comment.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isCollapsed = false;
          comment.rating = newNegativeRating;
          return comment;
        } else if (user.isSelected == false && user.isCollapsed == false) {
          //   User does not have a registered rateing +1
          comment.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isSelected = true;
          comment.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isCollapsed = false;
          comment.rating = newPositiveRating;
          return comment;
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == false && user.isCollapsed == true) {
          //   User already rated NEGATIVE, adding +2
          comment.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isSelected = true;
          comment.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isCollapsed = false;
          comment.rating = newDoublePositveRating;
          return comment;
        } else {
          //   Unexpeted Condition  NULL
          return comment;
        }
      } else {
        //   No UserWhoRated Found, Adding one
        comment.usersWhoRated?.add(newuser);
        comment.rating = newPositiveRating;
        return comment;
      }
    } else {
      //   UserWhoRated List is null adding and a +1
      comment
        ..usersWhoRated = newUsersWhoRated
        ..rating = newPositiveRating;
      return comment;
    }
  }

  ///   Sets the new Rating on the [comment] based on whether or not they rated
  Comment _setNewNegativeRating({required Comment comment}) {
    final userEmail = state.usersProfile!.email;

    //   List item with user and rated is true
    final newuser = BaseListItem(
      id: userEmail,
      isSelected: false,
      isCollapsed: true,
    );

    //  List with the user and rated value loaded in
    final newUsersWhoRated = [newuser];

    //   New Rating Conditions
    final newPositiveRating = comment.rating! + 1;
    final newNegativeRating = comment.rating! - 1;
    final newDoubleNegativeRating = comment.rating! - 2;

    if (comment.usersWhoRated != null && comment.usersWhoRated!.isNotEmpty) {
      //   Reference to the User
      final user = comment.usersWhoRated?.firstWhereOrNull(
        (element) => element.id == userEmail,
      );

      //  List is not NULL
      if (user != null) {
        ///  Found UserWhoRated
        if (user.isSelected == null && user.isCollapsed == null) {
          //   Never Rated before addding User and -1
          comment.usersWhoRated?.add(newuser);
          comment.rating = newNegativeRating;
          return comment;
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == false && user.isCollapsed == true) {
          //   Already Negative Rating, +1
          comment.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isSelected = false;
          comment.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isCollapsed = false;
          comment.rating = newPositiveRating;
          return comment;
        } else if (user.isSelected == false && user.isCollapsed == false) {
          //   User does not have a registered rating -1
          comment.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isSelected = false;
          comment.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isCollapsed = true;
          comment.rating = newNegativeRating;
          return comment;
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == true && user.isCollapsed == false) {
          //   User already rated POSITIVE, adding -2
          comment.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isSelected = false;
          comment.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isCollapsed = true;
          comment.rating = newDoubleNegativeRating;
          return comment;
        } else {
          //   Unexpeted Condition  NULL
          return comment;
        }
      } else {
        //   No UserWhoRated Found, Adding one and -1
        comment.usersWhoRated?.add(newuser);
        comment.rating = newNegativeRating;
        return comment;
      }
    } else {
      //   UserWhoRated List is null adding and a -1
      comment
        ..usersWhoRated = newUsersWhoRated
        ..rating = newNegativeRating;
      return comment;
    }
  }
}
