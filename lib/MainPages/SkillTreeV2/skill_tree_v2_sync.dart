import 'package:database_repository/database_repository.dart';
import 'package:flutter/foundation.dart';

/// Lightweight broadcast counter so mounted Rider and Horse profile skill
/// views refresh automatically after Skill Tree 2.0 progress or verification
/// updates.
class SkillTreeV2Sync {
  const SkillTreeV2Sync._();

  static final ValueNotifier<int> progressRevision = ValueNotifier<int>(0);
  static SkillSubject? lastUpdatedSubject;
  static String? lastUpdatedProfileDocId;

  static void notifyProgressChanged({
    SkillSubject? subject,
    String? profileDocId,
  }) {
    lastUpdatedSubject = subject;
    lastUpdatedProfileDocId = profileDocId?.trim();
    progressRevision.value++;
  }
}
