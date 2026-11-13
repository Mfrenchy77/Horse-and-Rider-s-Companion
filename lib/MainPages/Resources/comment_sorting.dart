import 'package:database_repository/database_repository.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';

/// Returns a sorted copy of [comments] for the given [sortState].
///
/// Pure and side-effect free, so it is safe to call from `build()` without
/// mutating state-owned lists.
List<Comment> sortCommentsBy(
  List<Comment> comments,
  CommentSortState sortState,
) {
  final sorted = List<Comment>.of(comments);
  switch (sortState) {
    case CommentSortState.Recent:
      sorted.sort((a, b) => b.date.compareTo(a.date));
    case CommentSortState.Oldest:
      sorted.sort((a, b) => a.date.compareTo(b.date));
    case CommentSortState.Best:
      sorted.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    case CommentSortState.Worst:
      sorted.sort((a, b) => (a.rating ?? 0).compareTo(b.rating ?? 0));
  }
  return sorted;
}
