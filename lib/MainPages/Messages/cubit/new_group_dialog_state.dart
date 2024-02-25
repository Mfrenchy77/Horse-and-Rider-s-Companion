part of 'new_group_dialog_cubit.dart';

enum SearchState { email, name }

class NewGroupDialogState extends Equatable {
  const NewGroupDialogState({
    this.error = '',
    this.isError = false,
    this.name = const Name.pure(),
    this.status = FormzStatus.pure,
    this.email = const Email.pure(),
    this.groupType = GroupType.private,
    this.searchState = SearchState.name,
    this.groupMembers = const <RiderProfile>[],
    this.searchResult = const <RiderProfile?>[],
  });
  final Name name;
  final Email email;
  final bool isError;
  final String error;
  final FormzStatus status;
  final GroupType groupType;
  final SearchState searchState;
  final List<RiderProfile?> searchResult;
  final List<RiderProfile?> groupMembers;

  NewGroupDialogState copyWith({
    Name? name,
    Email? email,
    bool? isError,
    String? error,
    FormzStatus? status,
    GroupType? groupType,
    SearchState? searchState,
    List<RiderProfile?>? searchResult,
    List<RiderProfile?>? groupMembers,
  }) {
    return NewGroupDialogState(
      name: name ?? this.name,
      error: error ?? this.error,
      email: email ?? this.email,
      status: status ?? this.status,
      isError: isError ?? this.isError,
      groupType: groupType ?? this.groupType,
      searchState: searchState ?? this.searchState,
      searchResult: searchResult ?? this.searchResult,
      groupMembers: groupMembers ?? this.groupMembers,
    );
  }

  @override
  List<Object?> get props => [
        name,
        email,
        error,
        status,
        isError,
        groupType,
        searchState,
        searchResult,
        groupMembers,
      ];
}
