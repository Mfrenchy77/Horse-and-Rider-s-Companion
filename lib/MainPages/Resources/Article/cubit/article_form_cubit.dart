// import 'dart:typed_data';
// import 'package:bloc/bloc.dart';
// import 'package:database_repository/database_repository.dart';
// import 'package:equatable/equatable.dart';

// part 'article_form_state.dart';

// class ArticleFormCubit extends Cubit<ArticleFormState> {
//   ArticleFormCubit(this._repo) : super(const ArticleFormState());

//   final Resource _repo;

//   void titleChanged(String v) => emit(state.copyWith(title: v));
//   void contentChanged(String v) => emit(state.copyWith(content: v));
//   void tagsChanged(List<String> v) => emit(state.copyWith(tags: v));

//   void coverSelected({
//     required Uint8List bytes,
//     required String fileName,
//   }) {
//     emit(state.copyWith(coverBytes: bytes, coverFileName: fileName));
//   }

//   Future<Article?> submit() async {
//     if (state.isSubmitting) return null;
//     final title = state.title.trim();
//     final content = state.content.trim();
//     if (title.length < 3) {
//       emit(state.copyWith(error: 'Title must be at least 3 characters.'));
//       return null;
//     }
//     if (content.length < 30) {
//       emit(state.copyWith(error: 'Please write at least 30 characters.'));
//       return null;
//     }

//     emit(state.copyWith(isSubmitting: true, error: null));
//     try {
//       final article = await _repo.createArticle(
//         title: title,
//         content: content,
//         tags: state.tags,
//         coverBytes: state.coverBytes,
//         coverFileName: state.coverFileName,
//       );
//       emit(state.copyWith(isSubmitting: false, submittedId: article.id));
//       return article;
//     } catch (e) {
//       emit(state.copyWith(isSubmitting: false, error: e.toString()));
//       return null;
//     }
//   }
// }
