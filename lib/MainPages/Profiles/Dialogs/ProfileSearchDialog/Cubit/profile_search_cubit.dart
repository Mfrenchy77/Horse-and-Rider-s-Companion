import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/Utilities/util_methods.dart';

part 'profile_search_state.dart';

class ProfileSearchCubit extends Cubit<ProfileSearchState> {
  ProfileSearchCubit({
    required ApiKeyProvider keysRepository,
    required this._riderProfileRepository,
    required this._horseProfileRepository,
    // ignore: prefer_initializing_formals
  }) : _keysRepository = keysRepository,
       super(const ProfileSearchState());

  ///Repositories
  final RiderProfileStore _riderProfileRepository;
  final HorseProfileStore _horseProfileRepository;
  final ApiKeyProvider _keysRepository;

  StreamSubscription<dynamic>? _searchSubscription;
  final List<StreamSubscription<dynamic>> _locationSearchSubscriptions = [];

  void _cancelSearchSubscriptions() {
    _searchSubscription?.cancel();
    _searchSubscription = null;
    for (final sub in _locationSearchSubscriptions) {
      sub.cancel();
    }
    _locationSearchSubscriptions.clear();
  }

  /// Monitors the default Field's [value] in the Search Dialog for
  /// Riders and Horses
  void nameChanged(String value) {
    final name = Name.dirty(value);
    emit(state.copyWith(searchValue: name));
  }

  /// Monitor the Email Field's [value] in the Search Dialog
  void emailChanged(String value) {
    final email = Email.dirty(value);
    emit(state.copyWith(email: email));
  }

  /// Monitor the Zip Code Field's [value] in the Search Dialog
  /// for Riders and Horses
  void zipCodeChanged(String value) {
    final zipCode = ZipCode.dirty(value);
    emit(state.copyWith(zipCode: zipCode));
  }

  /// Location Range [value] changed
  void locationRangeChanged(int? value) {
    if (value != null) {
      final locationRange = LocationRange.dirty(value);
      emit(state.copyWith(locationRange: locationRange));
    } else {
      emit(
        state.copyWith(
          locationRange: const LocationRange.pure(),
          status: FormStatus.initial,
        ),
      );
    }
  }

  /// Change the [searchType]
  void searchTypeChanged(SearchType searchType) {
    emit(
      state.copyWith(
        searchType: searchType,
        email: const Email.pure(),
        searchValue: const Name.pure(),
      ),
    );
  }

  /// This toggles the search type between Rider and Horse
  void toggleForRider() {
    emit(
      state.copyWith(
        isSearchRider: !state.isSearchRider,
        searchType: !state.isSearchRider ? SearchType.name : SearchType.horse,
      ),
    );
  }

  /// Search for a Rider Profile by Name
  void searchProfilesByName() {
    emit(state.copyWith(status: FormStatus.submitting));
    // Cancel the previous subscription if there was one
    _cancelSearchSubscriptions();
    try {
      _searchSubscription = _riderProfileRepository
          .getProfilesByName(
            name: capitalizeWords(state.searchValue.value).trim(),
          )
          .listen((results) {
            if (isClosed) return;
            if (results.isNotEmpty) {
              emit(
                state.copyWith(
                  riderProfiles: results,
                  status: FormStatus.success,
                ),
              );
            } else {
              emit(
                state.copyWith(
                  status: FormStatus.failure,
                  error: 'No Results',
                  isError: true,
                ),
              );
            }
          });
    } catch (e, stackTrace) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          error: e.toString(),
          isError: true,
        ),
      );
      AppLogger.error(
        LogCategory.profile,
        'Profile search by name failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Remove usersProfile from the search results
  List<RiderProfile> removeUserProfile(RiderProfile? usersProfile) {
    if (usersProfile == null) {
      return state.riderProfiles;
    }
    // Create a new list to avoid modifying the state directly
    final profiles = List<RiderProfile>.from(state.riderProfiles);
    // Find the index of the profile to remove
    final index = profiles.indexWhere(
      (profile) => profile.email == usersProfile.email,
    );

    // If found, remove the profile from the list
    if (index != -1) {
      profiles.removeAt(index);
    }
    return profiles;
  }

  /// search Rider Profiles by Email
  void searchProfileByEmail() {
    emit(state.copyWith(status: FormStatus.submitting));
    final profileResults = <RiderProfile>[];
    _cancelSearchSubscriptions();
    final targetEmail = state.email.value.trim().toLowerCase();
    try {
      _searchSubscription = _riderProfileRepository
          .getPublicRiderProfile(email: targetEmail)
          .listen(
            (profile) {
              if (isClosed) return;
              if (profile != null) {
                profileResults
                  ..clear()
                  ..add(profile);
                emit(
                  state.copyWith(
                    riderProfiles: List<RiderProfile>.of(profileResults),
                    status: FormStatus.success,
                  ),
                );
              } else {
                emit(
                  state.copyWith(
                    status: FormStatus.failure,
                    error: 'No Results',
                  ),
                );
              }
            },
            onError: (Object error) {
              if (isClosed) return;
              emit(
                state.copyWith(status: FormStatus.failure, error: 'No Results'),
              );
            },
          );
    } on RepositoryException catch (e, stackTrace) {
      emit(state.copyWith(status: FormStatus.failure, error: e.message));
      AppLogger.error(
        LogCategory.profile,
        'Profile search by email failed (${e.code})',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Search for a Rider Profile by Zip Code
  void searchRiderByZipCode() {
    emit(state.copyWith(status: FormStatus.submitting));
    _cancelSearchSubscriptions();

    try {
      _searchSubscription = _riderProfileRepository
          .getProfilesByZipcode(zipcode: state.zipCode.value.trim())
          .listen((profiles) {
            if (isClosed) return;
            if (profiles.isNotEmpty) {
              emit(
                state.copyWith(
                  riderProfiles: profiles,
                  status: FormStatus.success,
                ),
              );
            } else {
              emit(
                state.copyWith(status: FormStatus.failure, error: 'No Results'),
              );
            }
          });
    } catch (e, stackTrace) {
      emit(state.copyWith(status: FormStatus.failure, error: e.toString()));
      AppLogger.error(
        LogCategory.profile,
        'Profile search by zip code failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Search for a Rider by City Location

  /// Search for a Horse by Name
  void searchForHorseByName() {
    emit(state.copyWith(status: FormStatus.submitting));
    _cancelSearchSubscriptions();
    try {
      _searchSubscription = _horseProfileRepository
          .getHorseByName(name: state.searchValue.value.trim())
          .listen((results) {
            if (isClosed) return;
            if (results.isNotEmpty) {
              emit(
                state.copyWith(
                  horseProfiles: results,
                  status: FormStatus.success,
                ),
              );
            } else {
              emit(
                state.copyWith(status: FormStatus.failure, error: 'No Results'),
              );
            }
          });
    } on RepositoryException catch (e, stackTrace) {
      emit(state.copyWith(status: FormStatus.failure, error: e.message));
      AppLogger.error(
        LogCategory.profile,
        'Horse search by name failed (${e.code})',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  ///  Search results for a horseProfile by Nick Name
  void searchForHorseByNickName() {
    emit(state.copyWith(status: FormStatus.submitting));
    _cancelSearchSubscriptions();
    try {
      _searchSubscription = _horseProfileRepository
          .getHorseByNickName(nickName: state.searchValue.value.trim())
          .listen((results) {
            if (isClosed) return;
            if (results.isNotEmpty) {
              emit(
                state.copyWith(
                  horseProfiles: results,
                  status: FormStatus.success,
                ),
              );
            } else {
              emit(
                state.copyWith(status: FormStatus.failure, error: 'No Results'),
              );
            }
          });
    } on RepositoryException catch (e, stackTrace) {
      emit(state.copyWith(status: FormStatus.failure, error: e.message));
      AppLogger.error(
        LogCategory.profile,
        'Horse search by nickname failed (${e.code})',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Search for Horse by Id
  void searchForHorseById() {
    emit(state.copyWith(status: FormStatus.submitting));
    _cancelSearchSubscriptions();
    final targetId = state.searchValue.value.toLowerCase().trim();
    if (targetId.isNotEmpty) {
      void emitResult(HorseProfile? horseProfile) {
        if (isClosed) return;
        if (horseProfile != null) {
          emit(
            state.copyWith(
              horseProfiles: [horseProfile],
              status: FormStatus.success,
            ),
          );
        } else {
          emit(state.copyWith(status: FormStatus.failure, error: 'No Results'));
        }
      }

      void searchPublicFallback() {
        _searchSubscription?.cancel();
        _searchSubscription = _horseProfileRepository
            .getPublicHorseProfileById(id: targetId)
            .listen(
              emitResult,
              onError: (_) {
                if (isClosed) return;
                emit(
                  state.copyWith(
                    status: FormStatus.failure,
                    error: 'No Results',
                  ),
                );
              },
            );
      }

      try {
        _searchSubscription = _horseProfileRepository
            .getHorseProfileById(id: targetId)
            .listen((horseProfile) {
              if (isClosed) return;
              if (horseProfile != null) {
                emitResult(horseProfile);
              } else {
                searchPublicFallback();
              }
            }, onError: (_) => searchPublicFallback());
      } on RepositoryException catch (e, stackTrace) {
        emit(state.copyWith(status: FormStatus.failure, error: e.message));
        AppLogger.error(
          LogCategory.profile,
          'Horse search by ID failed (${e.code})',
          error: e,
          stackTrace: stackTrace,
        );
      }
    } else {
      emit(
        state.copyWith(
          isError: true,
          status: FormStatus.failure,
          error: 'Please enter a valid Horse Id',
        ),
      );
    }
  }

  /// Search for Horse by Location.
  void searchForHorseByLocation() {
    emit(state.copyWith(status: FormStatus.submitting));
    _cancelSearchSubscriptions();
    _keysRepository.getLocationApiKey().then((value) {
      if (isClosed) return;
      final zipcodeRepository = ZipcodeRepository(apiKey: value);
      zipcodeRepository
          .queryRadius(
            postalCode: state.zipCode.value,
            radius: state.locationRange.value,
          )
          .then((event) {
            if (isClosed) return;
            _cancelSearchSubscriptions();

            /// results are a list of zip codes
            /// we want to get all the profiles that have the
            /// zip codes in their profile for each zip code
            final results = event?.postalCodes;
            if (results != null) {
              final horseProfileResults = <HorseProfile>[];
              for (final zipCode in results) {
                final sub = _horseProfileRepository
                    .getHorseByZipCode(zipCode: zipCode)
                    .listen((profiles) {
                      if (isClosed) return;
                      horseProfileResults.addAll(profiles);
                      if (horseProfileResults.isNotEmpty) {
                        emit(
                          state.copyWith(
                            horseProfiles: horseProfileResults,
                            status: FormStatus.success,
                          ),
                        );
                      } else {
                        emit(
                          state.copyWith(
                            status: FormStatus.failure,
                            error: 'No Results',
                          ),
                        );
                      }
                    });
                _locationSearchSubscriptions.add(sub);
              }
            } else {
              emit(
                state.copyWith(status: FormStatus.failure, error: 'No Results'),
              );
            }
          });
    });
  }

  /// Clears the search results
  void clearSearchResults() {
    emit(state.copyWith(riderProfiles: [], horseProfiles: []));
  }

  /// Clear the error message
  void clearError() {
    emit(state.copyWith(isError: false, error: ''));
  }

  @override
  Future<void> close() {
    _cancelSearchSubscriptions();
    return super.close();
  }
}
