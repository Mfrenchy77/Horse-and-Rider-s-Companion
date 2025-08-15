// part of 'article_form_cubit.dart';

// class ArticleFormState extends Equatable {
//   const ArticleFormState({
//     this.title = '',
//     this.content = '',
//     this.tags = const [],
//     this.coverBytes,
//     this.coverFileName,
//     this.isSubmitting = false,
//     this.error,
//     this.submittedId,
//   });

//   final String title;
//   final String content;
//   final List<String> tags;
//   final Uint8List? coverBytes;
//   final String? coverFileName;
//   final bool isSubmitting;
//   final String? error;
//   final String? submittedId;

//   ArticleFormState copyWith({
//     String? title,
//     String? content,
//     List<String>? tags,
//     Uint8List? coverBytes,
//     String? coverFileName,
//     bool? isSubmitting,
//     String? error, // set null explicitly to clear
//     String? submittedId,
//   }) {
//     return ArticleFormState(
//       title: title ?? this.title,
//       content: content ?? this.content,
//       tags: tags ?? this.tags,
//       coverBytes: coverBytes ?? this.coverBytes,
//       coverFileName: coverFileName ?? this.coverFileName,
//       isSubmitting: isSubmitting ?? this.isSubmitting,
//       error: error,
//       submittedId: submittedId ?? this.submittedId,
//     );
//   }

//   @override
//   List<Object?> get props => [
//         title,
//         content,
//         tags,
//         coverBytes,
//         coverFileName,
//         isSubmitting,
//         error,
//         submittedId,
//       ];
// }
