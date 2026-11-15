import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/ability_summary_v2_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/instructor_ability_matrix_v2_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_family_list_v2.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_tree_v2_header.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

class SkillTreeV2View extends StatefulWidget {
  const SkillTreeV2View({
    super.key,
    this.repository,
    this.enableLocalInstructorPreview = false,
  });

  final SkillTreeV2Repository? repository;
  final bool enableLocalInstructorPreview;

  @override
  State<SkillTreeV2View> createState() => _SkillTreeV2ViewState();
}

class _SkillTreeV2ViewState extends State<SkillTreeV2View> {
  late final SkillTreeV2Cubit _cubit;
  final ScrollController _scrollController = ScrollController();
  double _savedListScrollOffset = 0;
  bool _mobileShowingDetail = false;
  LocalHistoryEntry? _localHistoryEntry;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppCubit>().state;
    final initialSubject = appState.isForRider
        ? SkillSubject.rider
        : SkillSubject.horse;
    final repo = widget.repository ?? _resolveDefaultRepository();
    _cubit = SkillTreeV2Cubit(repository: repo, initialSubject: initialSubject)
      ..initialize(
        initialSubject: initialSubject,
        profileDocId: _profileDocIdFor(appState, initialSubject),
      );
  }

  SkillTreeV2Repository _resolveDefaultRepository() {
    try {
      return SkillTreeV2Repository(
        store: HybridCurriculumSkillTreeV2Store(
          primaryStore: FirestoreSkillTreeV2Store(),
        ),
      );
    } catch (_) {
      return SkillTreeV2Repository(
        store: HybridCurriculumSkillTreeV2Store(
          primaryStore: InMemorySkillTreeV2Store(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _localHistoryEntry = null;
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  bool get _hasInternalBackState =>
      _mobileShowingDetail ||
      _cubit.state.viewMode != SkillTreeV2ViewMode.browse;

  void _syncLocalHistoryEntry() {
    final route = ModalRoute.of(context);
    if (route == null) return;
    if (_hasInternalBackState && _localHistoryEntry == null) {
      final entry = LocalHistoryEntry(onRemove: _onLocalHistoryRemoved);
      _localHistoryEntry = entry;
      route.addLocalHistoryEntry(entry);
    } else if (!_hasInternalBackState && _localHistoryEntry != null) {
      final entry = _localHistoryEntry;
      _localHistoryEntry = null;
      entry?.remove();
    }
  }

  void _onLocalHistoryRemoved() {
    _localHistoryEntry = null;
    if (!mounted) return;
    _stepBackInternally();
  }

  void _stepBackInternally() {
    if (_mobileShowingDetail) {
      _returnToBrowsingList();
      return;
    }
    if (_cubit.state.viewMode == SkillTreeV2ViewMode.matrix) {
      _cubit.setViewMode(SkillTreeV2ViewMode.summary);
      return;
    }
    if (_cubit.state.viewMode != SkillTreeV2ViewMode.browse) {
      _cubit.setViewMode(SkillTreeV2ViewMode.browse);
    }
  }

  void _openMobileDetail(String skillId, {DifficultyState? level}) {
    _savedListScrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0;
    _cubit.selectSkill(skillId, level: level);
    setState(() => _mobileShowingDetail = true);
    _syncLocalHistoryEntry();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _returnToBrowsingList() {
    setState(() => _mobileShowingDetail = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        final target = _savedListScrollOffset.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.jumpTo(target);
      }
    });
  }

  void _handleAppBarBack(BuildContext context) {
    if (_hasInternalBackState) {
      if (_localHistoryEntry != null) {
        Navigator.of(context).maybePop();
      } else {
        _stepBackInternally();
      }
      return;
    }
    context.read<AppCubit>().changeIndex(0);
  }

  String? _profileDocIdFor(AppState appState, SkillSubject subject) {
    if (subject == SkillSubject.rider) {
      final rider = appState.isViewing
          ? appState.viewingProfile
          : appState.usersProfile;
      return rider?.email;
    }
    return appState.horseProfile?.id;
  }

  CoachingConnection? _activeCoachingLink(
    AppState appState,
    ConnectionsState? connectionState,
    SkillSubject subject,
  ) {
    if (appState.isGuest ||
        connectionState == null ||
        connectionState.email != appState.usersProfile?.email.toLowerCase()) {
      return null;
    }
    if (subject == SkillSubject.rider) {
      final rider = appState.isViewing
          ? appState.viewingProfile
          : appState.usersProfile;
      if (!appState.isViewing || rider == null) return null;
      return connectionState.instructorFor(rider.email);
    }
    final horse = appState.horseProfile;
    if (horse == null || horse.isArchived) return null;
    return connectionState.connections
        .where(
          (link) =>
              link.kind == 'horse' &&
              link.status == 'accepted' &&
              link.coach == connectionState.email &&
              link.horseId == horse.id &&
              link.learner == horse.currentOwnerId.toLowerCase() &&
              link.ownershipVersion == horse.ownershipVersion,
        )
        .firstOrNull;
  }

  Future<void> _handleVerifyLevel({
    required BuildContext context,
    required CurriculumSkill skill,
    required DifficultyState level,
    required bool verified,
    required CoachingConnection? coachingLink,
    required String? profileDocId,
    required AppState appState,
  }) async {
    final reasonController = TextEditingController();
    final confirmed = await showAppGlassDialog<bool>(
      context: context,
      builder: (dialogContext) => AppGlassDialog(
        title: Text(
          verified ? 'Verify Proficient Level' : 'Revoke Verification',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppTokens.spaceSm,
          children: [
            Text(
              verified
                  ? 'Verify ${skill.name} '
                        '(${difficultyDisplayLabel(level)}) as Proficient?'
                  : 'Revoke verification for ${skill.name} '
                        '(${difficultyDisplayLabel(level)})? '
                        'The self-assessment record will remain intact.',
            ),
            if (!verified)
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Optional reason',
                  border: OutlineInputBorder(),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(verified ? 'Verify' : 'Revoke'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (!(confirmed ?? false) || !context.mounted) return;

    if (coachingLink != null) {
      final connections = context.read<ConnectionsCubit?>();
      if (connections == null) return;
      final result = await connections.submit({
        'action': verified ? 'verifySkillLevel' : 'revokeSkillLevel',
        'id': coachingLink.id,
        'version': coachingLink.version,
        'recordId': ViewUtils.createId(),
        'skillId': skill.id,
        'level': level.name,
        if (!verified && reason.isNotEmpty) 'reason': reason,
      });
      if (!context.mounted) return;
      final ok = result?['verified'] == verified;
      if (ok && profileDocId != null) {
        await _cubit.refreshProfileData(
          subject: skill.subject,
          profileDocId: profileDocId,
        );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? (verified
                      ? 'Level verified.'
                      : 'Verification revoked.')
                : connections.state.actionFeedback ??
                      'Could not update verification.',
          ),
        ),
      );
      return;
    }

    if (widget.enableLocalInstructorPreview &&
        _cubit.store is InMemorySkillTreeV2Store &&
        profileDocId != null) {
      await _cubit.applyLocalVerification(
        skill: skill,
        level: level,
        verified: verified,
        profileDocId: profileDocId,
        coachUid: appState.user.id,
        coachName: appState.usersProfile?.name ?? 'Preview Instructor',
        reason: reason.isEmpty ? null : reason,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppCubit>().state;
    final connectionState = context.watch<ConnectionsCubit?>()?.state;

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<SkillTreeV2Cubit, SkillTreeV2State>(
        listenWhen: (prev, curr) =>
            prev.actionMessage != curr.actionMessage &&
            curr.actionMessage != null,
        listener: (context, state) {
          final msg = state.actionMessage;
          if (msg != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
            _cubit.clearActionMessage();
          }
        },
        builder: (context, state) {
          final profileDocId = _profileDocIdFor(appState, state.subject);
          _cubit.syncProfile(
            subject: state.subject,
            profileDocId: profileDocId,
          );

          final isRiderSubject = state.subject == SkillSubject.rider;
          final rider = appState.isViewing
              ? appState.viewingProfile
              : appState.usersProfile;
          final horse = appState.horseProfile;
          final profileLabel = isRiderSubject ? rider?.name : horse?.name;

          final canSelfAssess = !appState.isGuest &&
              profileDocId != null &&
              profileDocId.isNotEmpty &&
              (isRiderSubject ? !appState.isViewing : horse != null);

          final selfAssessDisabledReason = canSelfAssess
              ? null
              : appState.isGuest
              ? 'Sign in to record self-assessments.'
              : isRiderSubject && appState.isViewing
              ? 'Viewing another rider profile (read-only self-assessment).'
              : !isRiderSubject && horse == null
              ? 'Select or add a horse profile to record Horse progress.'
              : 'Select a profile to record progress.';

          final coachingLink = _activeCoachingLink(
            appState,
            connectionState,
            state.subject,
          );
          final canVerify =
              coachingLink != null ||
              (widget.enableLocalInstructorPreview &&
                  _cubit.store is InMemorySkillTreeV2Store &&
                  profileDocId != null);

          final isWide = MediaQuery.sizeOf(context).width >= 900;

          final Widget body;
          if (state.isLoading) {
            body = const Center(child: CircularProgressIndicator());
          } else if (state.errorMessage != null) {
            body = Center(child: Text(state.errorMessage!));
          } else {
            body = SingleChildScrollView(
            key: const Key('skillTreeV2View'),
            controller: _scrollController,
            padding: const EdgeInsets.all(AppTokens.spaceMd),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppTokens.spaceMd,
                  children: [
                    SkillTreeV2Header(
                      state: state,
                      hasHorseProfile: horse != null,
                      horseName: horse?.name,
                      onSelectSubject: (subject) {
                        setState(() => _mobileShowingDetail = false);
                        _cubit.selectSubject(
                          subject,
                          profileDocId: _profileDocIdFor(appState, subject),
                        );
                        _syncLocalHistoryEntry();
                      },
                      onSelectRealm: (realm) {
                        setState(() => _mobileShowingDetail = false);
                        _cubit.selectRealm(realm);
                        _syncLocalHistoryEntry();
                      },
                      onSelectViewMode: (mode) {
                        setState(() => _mobileShowingDetail = false);
                        _cubit.setViewMode(mode);
                        _syncLocalHistoryEntry();
                      },
                      onSearchChanged: (query) {
                        setState(() => _mobileShowingDetail = false);
                        _cubit.setSearchQuery(query);
                        _syncLocalHistoryEntry();
                      },
                    ),
                    if (state.viewMode == SkillTreeV2ViewMode.summary)
                      AbilitySummaryV2View(
                        state: state,
                        profileLabel: profileLabel,
                        canVerify: canVerify,
                        onBrowseRealm: (realm) {
                          setState(() => _mobileShowingDetail = false);
                          _cubit.selectRealm(realm);
                          _syncLocalHistoryEntry();
                        },
                        onExploreSkills: () {
                          setState(() => _mobileShowingDetail = false);
                          _cubit.setViewMode(SkillTreeV2ViewMode.browse);
                          _syncLocalHistoryEntry();
                        },
                        onSelectSkill: (skill, level) {
                          _cubit.openSkillInExplore(skill, level: level);
                          if (!isWide) {
                            _openMobileDetail(skill.id, level: level);
                          } else {
                            _syncLocalHistoryEntry();
                          }
                        },
                        onOpenReviewVerifications: canVerify
                            ? () {
                                setState(() => _mobileShowingDetail = false);
                                _cubit.setViewMode(SkillTreeV2ViewMode.matrix);
                                _syncLocalHistoryEntry();
                              }
                            : null,
                      )
                    else if (state.viewMode == SkillTreeV2ViewMode.matrix &&
                        canVerify)
                      InstructorAbilityMatrixV2View(
                        state: state,
                        canVerify: canVerify,
                        onBackToMySkills: () {
                          setState(() => _mobileShowingDetail = false);
                          _cubit.setViewMode(SkillTreeV2ViewMode.summary);
                          _syncLocalHistoryEntry();
                        },
                        onChangeFilter: _cubit.setMatrixFilter,
                        onSelectCell: (skill, level) {
                          if (!isWide) {
                            _openMobileDetail(skill.id, level: level);
                          } else {
                            _cubit.selectSkill(skill.id, level: level);
                            _syncLocalHistoryEntry();
                          }
                        },
                        onVerifyCell: (skill, level, {required verified}) =>
                            _handleVerifyLevel(
                              context: context,
                              skill: skill,
                              level: level,
                              verified: verified,
                              coachingLink: coachingLink,
                              profileDocId: profileDocId,
                              appState: appState,
                            ),
                      )
                    else if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: AppTokens.spaceMd,
                        children: [
                          Expanded(
                            flex: 5,
                            child: SkillFamilyListV2(
                              state: state,
                              onSelectSkill: (skill) =>
                                  _cubit.selectSkill(skill.id),
                              onToggleFamily: _cubit.toggleFamilyExpanded,
                            ),
                          ),
                          Expanded(
                            flex: 7,
                            child: state.selectedSkill == null
                                ? const AppSurfaceCard(
                                    child: Text(
                                      'Select a skill to view standards.',
                                    ),
                                  )
                                : SkillDetailV2Panel(
                                    state: state,
                                    skill: state.selectedSkill!,
                                    allResources: appState.resources,
                                    canSelfAssess: canSelfAssess,
                                    selfAssessDisabledReason:
                                        selfAssessDisabledReason,
                                    canVerify: canVerify,
                                    onSelectLevel: _cubit.selectLevel,
                                    onSelfAssess: (level, nextState) {
                                      if (profileDocId == null) return;
                                      _cubit.setSelfAssessment(
                                        skillId: state.selectedSkill!.id,
                                        level: level,
                                        levelState: nextState,
                                        profileDocId: profileDocId,
                                        actorUid: appState.user.id,
                                        actorName: appState.usersProfile?.name,
                                      );
                                    },
                                    onVerifyLevel:
                                        (level, {required verified}) =>
                                            _handleVerifyLevel(
                                          context: context,
                                          skill: state.selectedSkill!,
                                          level: level,
                                          verified: verified,
                                          coachingLink: coachingLink,
                                          profileDocId: profileDocId,
                                          appState: appState,
                                        ),
                                    onSelectRelatedSkill: (id) =>
                                        _cubit.selectSkill(id),
                                    onChangeResourceSort:
                                        _cubit.setResourceSort,
                                  ),
                          ),
                        ],
                      )
                    else if (_mobileShowingDetail &&
                        state.selectedSkill != null)
                      SkillDetailV2Panel(
                        state: state,
                        skill: state.selectedSkill!,
                        allResources: appState.resources,
                        canSelfAssess: canSelfAssess,
                        selfAssessDisabledReason: selfAssessDisabledReason,
                        canVerify: canVerify,
                        onBack: () => _handleAppBarBack(context),
                        onSelectLevel: _cubit.selectLevel,
                        onSelfAssess: (level, nextState) {
                          if (profileDocId == null) return;
                          _cubit.setSelfAssessment(
                            skillId: state.selectedSkill!.id,
                            level: level,
                            levelState: nextState,
                            profileDocId: profileDocId,
                            actorUid: appState.user.id,
                            actorName: appState.usersProfile?.name,
                          );
                        },
                        onVerifyLevel: (level, {required verified}) =>
                            _handleVerifyLevel(
                              context: context,
                              skill: state.selectedSkill!,
                              level: level,
                              verified: verified,
                              coachingLink: coachingLink,
                              profileDocId: profileDocId,
                              appState: appState,
                            ),
                        onSelectRelatedSkill: (id) => _cubit.selectSkill(id),
                        onChangeResourceSort: _cubit.setResourceSort,
                      )
                    else
                      SkillFamilyListV2(
                        state: state,
                        onSelectSkill: (skill) => _openMobileDetail(skill.id),
                        onToggleFamily: _cubit.toggleFamilyExpanded,
                      ),
                  ],
                ),
              ),
            ),
          );
          }

          return Scaffold(
            appBar: ThemedAppBar(
              leading: BackButton(
                key: const Key('skillTreeV2AppBarBackButton'),
                onPressed: () => _handleAppBarBack(context),
              ),
              title: const Text('Skill Tree 2.0 (Preview)'),
            ),
            body: AppScaffoldBackdrop(child: body),
          );
        },
      ),
    );
  }
}
