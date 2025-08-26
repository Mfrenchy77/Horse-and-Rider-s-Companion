// ignore_for_file: public_member_api_docs

part of 'create_article_cubit.dart';

enum ArticleCreateStatus {
  idle,
  success,
  failure,
  submitting,
  pickingCover,
  uploadingCover,
}

class ArticleCreateState extends Equatable {
  const ArticleCreateState({
    this.title = '',
    this.content = '',
    this.errorMessage,
    this.coverImageUrl,
    this.description = '',
    this.contentChars = 0,
    this.createdResourceId,
    this.tags = const <String>[],
    this.status = ArticleCreateStatus.idle,
  });

  final String title;
  final String content;
  final int contentChars;
  final List<String> tags;
  final String description;
  final String? errorMessage;
  final String? coverImageUrl;
  final String? createdResourceId;
  final ArticleCreateStatus status;
  bool get isValidTags => tags.length <= 6;
  bool get isValidContent => contentChars >= 20;
  bool get isFormValid => isValidTitle && isValidContent && isValidTags;
  bool get isValidTitle =>
      title.trim().length >= 3 && title.trim().length <= 120;

  ArticleCreateState copyWith({
    String? title,
    String? content,
    int? contentChars,
    List<String>? tags,
    String? description,
    String? errorMessage,
    String? coverImageUrl,
    String? createdResourceId,
    ArticleCreateStatus? status,
  }) {
    return ArticleCreateState(
      tags: tags ?? this.tags,
      errorMessage: errorMessage,
      title: title ?? this.title,
      status: status ?? this.status,
      content: content ?? this.content,
      description: description ?? this.description,
      contentChars: contentChars ?? this.contentChars,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdResourceId: createdResourceId ?? this.createdResourceId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        tags,
        title,
        status,
        content,
        description,
        contentChars,
        errorMessage,
        coverImageUrl,
        createdResourceId,
      ];
}
