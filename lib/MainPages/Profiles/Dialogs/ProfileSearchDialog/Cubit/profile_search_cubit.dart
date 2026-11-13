import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/Utilities/util_methods.dart';

part 'profile_search_state.dart';

class ProfileSearchCubit extends Cubit<ProfileSearchState> {
  ProfileSearchCubit({
    required this._keysRepository,
    required this._riderProfileRepository,
    required this._horseProfileRepository,
  }) : super(const ProfileSearchState());

  ///Repositories
  final RiderProfileRepository _riderProfileRepository;
  final HorseProfileRepository _horseProfileRepository;
  final KeysRepository _keysRepository;

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
    debugPrint('Name Changed to $value');
    final name = Name.dirty(value);
    emit(state.copyWith(searchValue: name));
  }

  /// Monitor the Email Field's [value] in the Search Dialog
  void emailChanged(String value) {
    debugPrint('Email Changed to $value');
    final email = Email.dirty(value);
    emit(state.copyWith(email: email));
  }

  /// Monitor the Zip Code Field's [value] in the Search Dialog
  /// for Riders and Horses
  void zipCodeChanged(String value) {
    debugPrint('Zip Code Changed to $value');
    final zipCode = ZipCode.dirty(value);
    emit(state.copyWith(zipCode: zipCode));
  }

  /// Location Range [value] changed
  void locationRangeChanged(int? value) {
    debugPrint('Location Range Changed to $value');
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
    debugPrint(
      'Search Type Changed  from ${state.searchType.name} to $searchType',
    );

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
    debugPrint('Is Search for Rider Changed to ${!state.isSearchRider}');
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
    debugPrint(
      'getProfile by Name for ${capitalizeWords(state.searchValue.value)}',
    );
    // Cancel the previous subscription if there was one
    _cancelSearchSubscriptions();
    try {
      _searchSubscription = _riderProfileRepository
          .getProfilesByName(
            name: capitalizeWords(state.searchValue.value).trim(),
          )
          .listen((results) {
            if (isClosed) return;
            debugPrint('Results: ${results.length}');
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
    } catch (e) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          error: e.toString(),
          isError: true,
        ),
      );
      debugPrint("Failed with error '$e': $e");
    }
  }

  /// Remove usersProfile from the search results
  List<RiderProfile> removeUserProfile(RiderProfile? usersProfile) {
    if (usersProfile == null) {
      return state.riderProfiles;
    }

    debugPrint(
      'Removing User Profile: '
      '${usersProfile.email} from Search Results',
    );
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
    try {
      _searchSubscription = _riderProfileRepository
          .getRiderProfile(email: state.email.value.trim().toLowerCase())
          .listen((profile) {
            if (isClosed) return;
            if (profile != null) {
              profileResults.add(profile);
              if (profileResults.isNotEmpty) {
                emit(
                  state.copyWith(
                    riderProfiles: profileResults,
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
            } else {
              emit(
                state.copyWith(status: FormStatus.failure, error: 'No Results'),
              );
            }
          });
    } on FirebaseException catch (e) {
      emit(state.copyWith(status: FormStatus.failure, error: e.message));

      debugPrint("Failed with error '${e.code}': ${e.message}");
    }
  }

  /// Search for a Rider Profile by Zip Code
  void searchRiderByZipCode() {
    debugPrint('Search by Zip Code ${state.searchValue}');
    emit(state.copyWith(status: FormStatus.submitting));
    _cancelSearchSubscriptions();

    try {
      _searchSubscription = _riderProfileRepository
          .getProfilesByZipcode(zipcode: state.zipCode.value.trim())
          .listen((profiles) {
            if (isClosed) return;
            debugPrint('Results: ${profiles.length}');
            if (profiles.isNotEmpty) {
              debugPrint('Results: ${profiles.length}');
              emit(
                state.copyWith(
                  riderProfiles: profiles,
                  status: FormStatus.success,
                ),
              );
            } else {
              debugPrint('No Results');
              emit(
                state.copyWith(status: FormStatus.failure, error: 'No Results'),
              );
            }
          });
    } catch (e) {
      emit(state.copyWith(status: FormStatus.failure, error: e.toString()));
      debugPrint("Failed with error '$e': $e");
    }
  }

  /// Search for a Rider by City Location

  /// Search for a Horse by Name
  void searchForHorseByName() {
    debugPrint('Search for horse ${state.searchValue}');
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
    } on FirebaseException catch (e) {
      emit(state.copyWith(status: FormStatus.failure, error: e.message));

      debugPrint("Failed with error '${e.code}': ${e.message}");
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
    } on FirebaseException catch (e) {
      emit(state.copyWith(status: FormStatus.failure, error: e.message));

      debugPrint("Failed with error '${e.code}': ${e.message}");
    }
  }

  /// Search for Horse by Id
  void searchForHorseById() {
    emit(state.copyWith(status: FormStatus.submitting));
    final horseProfileResults = <HorseProfile>[];
    _cancelSearchSubscriptions();
    if (state.searchValue.value.isNotEmpty) {
      try {
        _searchSubscription = _horseProfileRepository
            .getHorseProfileById(
              id: state.searchValue.value.toLowerCase().trim(),
            )
            .listen((horseProfile) {
              if (isClosed) return;
              if (horseProfile != null) {
                horseProfileResults.add(horseProfile);
              }
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
      } on FirebaseException catch (e) {
        emit(state.copyWith(status: FormStatus.failure, error: e.message));

        debugPrint("Failed with error '${e.code}': ${e.message}");
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
    debugPrint('Clear Search Results');
    emit(state.copyWith(riderProfiles: [], horseProfiles: []));
  }

  /// Clear the error message
  void clearError() {
    debugPrint('Clear Error');
    emit(state.copyWith(isError: false, error: ''));
  }

  @override
  Future<void> close() {
    _cancelSearchSubscriptions();
    return super.close();
  }
}
