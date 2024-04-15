part of 'new_group_dialog_cubit.dart';

enum SearchState { email, name }


class NewGroupDialogState extends Equatable {
  const NewGroupDialogState({
    this.id = '',
    this.error = '',
    this.usersProfile,
    this.isError = false,
    this.name = const Name.pure(),
    this.email = const Email.pure(),
    this.status = FormStatus.initial,
    this.searchState = SearchState.name,
    this.searchResult = const <RiderProfile?>[],
  });

  /// This is the id of the new Conversation to be created
  final String id;

  /// The search querry by name
  final Name name;

  /// The search querry by email
  final Email email;

  /// If there is an error
  final bool isError;

  /// The error message
  final String error;

  /// The status of the form
  final FormStatus status;

  /// The type of group to be created
  final SearchState searchState;

  /// The profile of the user
  final RiderProfile? usersProfile;

  /// The search result
  final List<RiderProfile?> searchResult;

  NewGroupDialogState copyWith({
    String? id,
    Name? name,
    Email? email,
    bool? isError,
    String? error,
    FormStatus? status,
    SearchState? searchState,
    RiderProfile? usersProfile,
    List<RiderProfile?>? searchResult,
  }) {
    return NewGroupDialogState(
      id: id ?? this.id,
      name: name ?? this.name,
      error: error ?? this.error,
      email: email ?? this.email,
      status: status ?? this.status,
      isError: isError ?? this.isError,
      searchState: searchState ?? this.searchState,
      usersProfile: usersProfile ?? this.usersProfile,
      searchResult: searchResult ?? this.searchResult,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        error,
        status,
        isError,
        searchState,
        usersProfile,
        searchResult,
      ];
}
