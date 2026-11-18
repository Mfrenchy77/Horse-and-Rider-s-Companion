import 'package:database_repository/database_repository.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

/// Identifies each guided onboarding tour independently.
enum OnboardingTourId { profile, skillTree, resources }

/// Tracks the invitation state for a tour independently from completion.
enum OnboardingInviteState { unseen, deferred, accepted }

/// Per-user onboarding persistence backed by [SharedPrefs].
///
/// Tracks invitation state and tour completion independently for each
/// [OnboardingTourId], scoped by the signed-in user's identifier so multiple
/// accounts on the same device do not share onboarding state.
class OnboardingPrefs {
  const OnboardingPrefs._();

  static String _normalizeUserKey(String? userKey) {
    final trimmed = userKey?.trim().toLowerCase() ?? '';
    return trimmed.isEmpty ? 'anonymous' : trimmed;
  }

  static String _inviteKey(OnboardingTourId tour, String? userKey) =>
      'onboarding_${tour.name}_${_normalizeUserKey(userKey)}_invite';

  static String _completedKey(OnboardingTourId tour, String? userKey) =>
      'onboarding_${tour.name}_${_normalizeUserKey(userKey)}_completed';

  static OnboardingInviteState inviteState({
    required OnboardingTourId tour,
    required String? userKey,
  }) {
    final raw = SharedPrefs().getString(_inviteKey(tour, userKey));
    return switch (raw) {
      'deferred' => OnboardingInviteState.deferred,
      'accepted' => OnboardingInviteState.accepted,
      _ => OnboardingInviteState.unseen,
    };
  }

  static Future<void> setInviteState({
    required OnboardingTourId tour,
    required String? userKey,
    required OnboardingInviteState state,
  }) async {
    await SharedPrefs().setString(_inviteKey(tour, userKey), state.name);
  }

  static bool isCompleted({
    required OnboardingTourId tour,
    required String? userKey,
  }) {
    return SharedPrefs().getBool(_completedKey(tour, userKey)) ?? false;
  }

  static Future<void> setCompleted({
    required OnboardingTourId tour,
    required String? userKey,
    required bool completed,
  }) async {
    await SharedPrefs().setBool(
      _completedKey(tour, userKey),
      value: completed,
    );
  }

  /// Heuristic to avoid interrupting established accounts with an unsolicited
  /// first-visit banner while still welcoming newly registered riders.
  static bool isLikelyNewProfile(RiderProfile profile) {
    final hasHorses =
        (profile.ownedHorses?.isNotEmpty ?? false) ||
        (profile.studentHorses?.isNotEmpty ?? false) ||
        (profile.archivedHorses?.isNotEmpty ?? false);
    final hasConnections =
        (profile.students?.isNotEmpty ?? false) ||
        (profile.instructors?.isNotEmpty ?? false);
    final hasNotes = profile.notes?.isNotEmpty ?? false;
    final hasLegacySkills = profile.skillLevels?.isNotEmpty ?? false;
    return !hasHorses && !hasConnections && !hasNotes && !hasLegacySkills;
  }

  /// Returns `true` only when the first-visit invitation should appear on the
  /// signed-in user's own Rider Profile.
  static bool shouldShowProfileInvitation({
    required RiderProfile profile,
    required String? userKey,
  }) {
    if (isCompleted(tour: OnboardingTourId.profile, userKey: userKey)) {
      return false;
    }
    final invite = inviteState(
      tour: OnboardingTourId.profile,
      userKey: userKey,
    );
    if (invite != OnboardingInviteState.unseen) {
      return false;
    }
    return isLikelyNewProfile(profile);
  }
}
