part of 'create_resource_dialog_cubit.dart';

enum UrlFetchedStatus { initial, fetching, fetched, error }

class CreateResourceDialogState extends Equatable {
  const CreateResourceDialogState({
    this.error = '',
    this.imageUrl = '',
    this.isError = false,
    this.url = const Url.pure(),
    this.status = FormzStatus.pure,
    this.title = const SingleWord.pure(),
    this.description = const SingleWord.pure(),
    this.urlFetchedStatus = UrlFetchedStatus.initial,
  });

  final Url url;
  final String error;
  final bool isError;
  final String imageUrl;
  final SingleWord title;
  final FormzStatus status;
  final SingleWord description;
  final UrlFetchedStatus urlFetchedStatus;
  @override
  List<Object> get props => [
        url,
        title,
        error,
        status,
        isError,
        imageUrl,
        description,
        urlFetchedStatus,
      ];

  CreateResourceDialogState copyWith({
    Url? url,
    String? error,
    bool? isError,
    SingleWord? title,
    String? imageUrl,
    FormzStatus? status,
    SingleWord? description,
    UrlFetchedStatus? urlFetchedStatus,
  }) {
    return CreateResourceDialogState(
      url: url ?? this.url,
      error: error ?? this.error,
      title: title ?? this.title,
      status: status ?? this.status,
      isError: isError ?? this.isError,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      urlFetchedStatus: urlFetchedStatus ?? this.urlFetchedStatus,
    );
  }
}
