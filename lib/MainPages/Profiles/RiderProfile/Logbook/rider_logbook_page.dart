import 'package:database_repository/database_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_entry_card.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_filter_bar.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_hero_header.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_shared_widgets.dart';
import 'package:horseandriderscompanion/CommonWidgets/personalized_logbook_backdrop.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/cubit/logbook_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/logbook_connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';
import 'package:intl/intl.dart';

part 'log_entry_editor.dart';

LogbookConnectionRepository? _readLogbookConnections(BuildContext context) =>
    context.read<LogbookConnectionRepository?>() ??
    context.read<ConnectionRepository?>();

LogbookRiderProfileRepository? _readLogbookRiderProfiles(
  BuildContext context,
) =>
    context.read<LogbookRiderProfileRepository?>() ??
    context.read<RiderProfileRepository?>();

class RiderLogbookPage extends StatefulWidget {
  const RiderLogbookPage({
    super.key,
    required this.email,
    this.previewImage,
  });

  final String email;
  final ImageProvider? previewImage;

  static void open(BuildContext context) {
    final state = context.read<AppCubit>().state;
    final email = state.usersProfile?.email;
    if (state.isGuest || email == null || email.isEmpty) return;
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (_) => RiderLogbookPage(email: email)),
    );
  }

  static Future<bool?> addEntry(
    BuildContext context, {
    HorseProfile? initialHorse,
    CoachingConnection? horseConnection,
    RiderLogType? initialType,
    List<PracticedSkillTag> initialPracticedSkills = const [],
    List<BaseListItem> knownEntries = const [],
    BaseListItem? entry,
  }) => _addEntry(
    context,
    initialHorse: initialHorse,
    horseConnection: horseConnection,
    initialType: initialType,
    initialPracticedSkills: initialPracticedSkills,
    knownEntries: knownEntries,
    entry: entry,
  );

  static Future<bool?> addLessonFor(
    BuildContext context,
    CoachingConnection student, {
    BaseListItem? entry,
    Skill? initialSkill,
    LevelState? initialLevel,
  }) => _addEntry(
    context,
    student: student,
    entry: entry,
    initialSkill: initialSkill,
    initialLevel: initialLevel,
  );

  static Future<bool?> _addEntry(
    BuildContext context, {
    CoachingConnection? student,
    HorseProfile? initialHorse,
    CoachingConnection? horseConnection,
    RiderLogType? initialType,
    List<PracticedSkillTag> initialPracticedSkills = const [],
    List<BaseListItem> knownEntries = const [],
    BaseListItem? entry,
    Skill? initialSkill,
    LevelState? initialLevel,
  }) async {
    final app = context.read<AppCubit>();
    final profile = app.state.usersProfile;
    if (app.state.isGuest || profile == null) return null;

    // Provide LogbookCubit at the route level so the editor works when opened
    // from Rider Profile, Horse Profile, Connections, or Skill Tree 2.0.
    final saved = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (ctx) => LogbookCubit(
            connectionRepository: _readLogbookConnections(ctx),
            riderProfileRepository: _readLogbookRiderProfiles(ctx),
          ),
          child: _LogEntryEditor(
            email: profile.email,
            initialStudent: student,
            initialHorse: initialHorse,
            horseConnection: horseConnection,
            initialType: initialType,
            initialPracticedSkills: initialPracticedSkills,
            knownEntries: knownEntries,
            initialSkill: initialSkill,
            initialLevel: initialLevel,
            entry: entry,
          ),
        ),
      ),
    );
    final viewed = app.state.viewingProfile;
    if ((saved ?? false) &&
        context.mounted &&
        student != null &&
        app.state.isViewing &&
        viewed != null &&
        viewed.email.toLowerCase() == student.learner) {
      await app.refreshViewedRider(viewed.email);
    }
    return saved;
  }

  @override
  State<RiderLogbookPage> createState() => _RiderLogbookPageState();
}

RiderProfile? _owner(AppState state, String email) {
  final rider = state.usersProfile;
  return !state.isGuest && rider?.email == email ? rider : null;
}

String _dateLabel(DateTime? date) =>
    date == null ? 'Date unavailable' : DateFormat.yMMMd().format(date);

String _entryMetadata(BaseListItem entry) =>
    '${entry.riderLogType.label} · ${_dateLabel(entry.date)}';

String _entryTitle(BaseListItem entry) {
  final info = entry.riderLog;
  final title =
      info?.title ??
      entry.name?.trim().split('\n').first ??
      info?.highlights?.trim().split('\n').first ??
      info?.focus?.trim().split('\n').first;
  if (title != null && title.isNotEmpty) return title;
  if (info != null && info.practicedSkills.isNotEmpty) {
    return info.practicedSkills.map((s) => s.skillName).join(', ');
  }
  return entry.riderLogType.label;
}

String? _entryAttribution(BaseListItem entry, RiderProfile rider) {
  final email = entry.parentId?.trim() ?? '';
  if (email.isEmpty || email.toLowerCase() == rider.email.toLowerCase()) {
    return null;
  }

  if (entry.riderLog?.authorRole == 'instructor') {
    final name = entry.message?.trim();
    final label = name == null || name.isEmpty ? email : name;
    return 'Added by instructor $label';
  }

  for (final instructor in rider.instructors ?? const <BaseListItem>[]) {
    if (instructor.id?.toLowerCase() == email.toLowerCase()) {
      final name = instructor.name?.trim();
      final label = name == null || name.isEmpty ? email : name;
      return 'Added by instructor $label';
    }
  }
  final name = entry.message?.trim();
  return 'Added by ${name == null || name.isEmpty ? email : name}';
}

sealed class _TimelineListItem {
  const _TimelineListItem();
}

class _TimelineMonthItem extends _TimelineListItem {
  const _TimelineMonthItem(this.date);
  final DateTime date;
}

class _TimelineEntryItem extends _TimelineListItem {
  const _TimelineEntryItem(this.entry);
  final BaseListItem entry;
}

class _RiderLogbookPageState extends State<RiderLogbookPage> {
  RiderLogType? _filter;
  String? _horseFilterKey;
  bool _newestFirst = true;
  String _query = '';
  String? _journalUid;
  Stream<List<BaseListItem>>? _journal;
  late final LogbookCubit _logbookCubit;

  @override
  void initState() {
    super.initState();
    _logbookCubit = LogbookCubit(
      connectionRepository: _readLogbookConnections(context),
      riderProfileRepository: _readLogbookRiderProfiles(context),
    );
  }

  @override
  void dispose() {
    _logbookCubit.close();
    super.dispose();
  }

  Stream<List<BaseListItem>>? _journalFor(BuildContext context, String uid) {
    if (_journalUid != uid) {
      _journalUid = uid;
      _journal = uid.isEmpty
          ? null
          : _readLogbookConnections(context)?.watchJournal(uid);
    }
    return _journal;
  }

  void _openEditor({
    BaseListItem? entry,
    List<BaseListItem> knownEntries = const [],
  }) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _logbookCubit,
          child: _LogEntryEditor(
            email: widget.email,
            entry: entry,
            knownEntries: knownEntries,
          ),
        ),
      ),
    );
  }

  Future<void> _openEntry(
    BaseListItem entry,
    List<BaseListItem> allEntries,
  ) async {
    final rider = _owner(context.read<AppCubit>().state, widget.email);
    if (rider == null) return;
    final canEdit = entry.canEditRiderLog(rider.email);
    final canDelete = canEdit && _readLogbookConnections(context) != null;
    final action = await showLogbookEntryDetailDialog(
      context: context,
      entry: entry,
      categoryLabel: entry.riderLogType.label,
      fallbackTitle: _entryTitle(entry),
      attribution: _entryAttribution(entry, rider),
      canEdit: canEdit,
      canDelete: canDelete,
    );
    if (!mounted) return;
    if (action == 'edit') {
      _openEditor(entry: entry, knownEntries: allEntries);
    }
    if (action == 'delete') await _deleteEntry(entry);
  }

  Future<void> _deleteEntry(BaseListItem entry) async {
    final confirmed = await showAppGlassDialog<bool>(
      context: context,
      builder: (context) => AppGlassDialog(
        title: const Text('Delete this entry?'),
        content: const Text('A shared entry is removed from both logbooks.'),
        actions: [
          AppOutlinedButton(
            onPressed: () => Navigator.pop(context),
            label: 'Cancel',
          ),
          AppDestructiveButton(
            onPressed: () => Navigator.pop(context, true),
            label: 'Delete',
          ),
        ],
      ),
    );
    if (!mounted || !(confirmed ?? false)) return;
    try {
      await _logbookCubit.deleteEntry(entry);
    } catch (error) {
      if (!mounted) return;
      final message = error is ConnectionFailure
          ? error.message
          : 'Could not delete the entry.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Map<String, String> _horseFilterOptions(
    RiderProfile rider,
    List<BaseListItem> allEntries,
  ) {
    final options = <String, String>{};
    for (final horse in [
      ...?rider.ownedHorses,
      ...?rider.studentHorses,
    ]) {
      final id = horse.id?.trim();
      final name = horse.name?.trim();
      if (id != null && id.isNotEmpty) {
        options['id:$id'] = (name != null && name.isNotEmpty) ? name : id;
      }
    }
    for (final entry in allEntries) {
      final info = entry.riderLog;
      if (info == null) continue;
      final id = info.horseId?.trim();
      final name = info.horse?.trim();
      if (id != null && id.isNotEmpty) {
        options.putIfAbsent(
          'id:$id',
          () => (name != null && name.isNotEmpty) ? name : id,
        );
      } else if (name != null && name.isNotEmpty) {
        final alreadyNamed = options.values.any(
          (existing) => existing.toLowerCase() == name.toLowerCase(),
        );
        if (!alreadyNamed) {
          options['name:${name.toLowerCase()}'] = name;
        }
      }
    }
    return options;
  }

  bool _matchesHorseFilter(BaseListItem entry, String? filterKey) {
    if (filterKey == null) return true;
    final info = entry.riderLog;
    if (info == null) return false;
    if (filterKey.startsWith('id:')) {
      return info.horseId == filterKey.substring(3);
    }
    if (filterKey.startsWith('name:')) {
      return info.horse?.trim().toLowerCase() == filterKey.substring(5);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppCubit>().state;
    final rider = _owner(state, widget.email);

    return BlocProvider.value(
      value: _logbookCubit,
      child: Scaffold(
        appBar: ThemedAppBar(title: const Text('Rider logbook')),
        body: PersonalizedLogbookBackdrop(
          photoUrl: rider?.picUrl,
          imageProvider: widget.previewImage,
          child: SafeArea(
            child: rider == null
                ? Center(
                    child: state.pageStatus == AppPageStatus.loading
                        ? const AppLoadingState(
                            message: 'Loading rider logbook…',
                          )
                        : const Padding(
                            padding: EdgeInsets.all(AppTokens.spaceLg),
                            child: AppEmptyState(
                              icon: Icons.auto_stories_outlined,
                              title: 'Rider logbook unavailable',
                              description: 'Your rider logbook is unavailable.',
                            ),
                          ),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: StreamBuilder<List<BaseListItem>>(
                        key: ValueKey(state.user.id),
                        stream: _journalFor(context, state.user.id),
                        builder: (context, snapshot) => _timeline(
                          context,
                          rider,
                          snapshot.data ?? const [],
                          sharedError: snapshot.hasError,
                          sharedLoading:
                              snapshot.connectionState ==
                              ConnectionState.waiting,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _timeline(
    BuildContext context,
    RiderProfile rider,
    List<BaseListItem> shared, {
    required bool sharedError,
    required bool sharedLoading,
  }) {
    final sharedIds = shared.map((entry) => entry.id).toSet();
    final allEntries = [
      ...?rider.notes?.where((entry) => !sharedIds.contains(entry.id)),
      ...shared,
    ];
    final horseOptions = _horseFilterOptions(rider, allEntries);
    final activeHorseFilter =
        _horseFilterKey != null && horseOptions.containsKey(_horseFilterKey)
        ? _horseFilterKey
        : null;

    final entries =
        allEntries
            .where((entry) {
              if (_filter != null && entry.riderLogType != _filter) {
                return false;
              }
              if (!_matchesHorseFilter(entry, activeHorseFilter)) {
                return false;
              }
              if (_query.isEmpty) return true;
              final info = entry.riderLog;
              return [
                entry.name,
                entry.riderLogType.label,
                info?.title,
                info?.horse,
                info?.instructor,
                info?.feel?.label,
                info?.highlights,
                info?.focus,
                info?.nextSteps,
                ...?info?.practicedSkills.map((s) => s.skillName),
              ].whereType<String>().any(
                (value) => value.toLowerCase().contains(_query),
              );
            })
            .toList()
          ..sort((a, b) {
            if (a.date == null) return b.date == null ? 0 : 1;
            if (b.date == null) return -1;
            return _newestFirst
                ? b.date!.compareTo(a.date!)
                : a.date!.compareTo(b.date!);
          });

    final selectedHorseId =
        activeHorseFilter != null && activeHorseFilter.startsWith('id:')
        ? activeHorseFilter.substring(3)
        : null;
    final selectedHorseName =
        activeHorseFilter != null && activeHorseFilter.startsWith('name:')
        ? activeHorseFilter.substring(5)
        : null;
    final nextStepsHit = findPreviousNextSteps(
      allEntries,
      horseId: selectedHorseId,
      horseName: selectedHorseName,
    );
    final recentSkills = recentPracticedSkills(
      allEntries,
      horseId: selectedHorseId,
    );
    final showUpNext =
        _query.isEmpty &&
        _filter == null &&
        (nextStepsHit != null || recentSkills.isNotEmpty);

    final listItems = <_TimelineListItem>[];
    String? lastMonth;
    for (final entry in entries) {
      final month = monthGroupKey(entry.date);
      if (month != null && month != lastMonth) {
        lastMonth = month;
        listItems.add(_TimelineMonthItem(entry.date!));
      }
      listItems.add(_TimelineEntryItem(entry));
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.spaceLg,
            AppTokens.spaceLg,
            AppTokens.spaceLg,
            AppTokens.spaceMd,
          ),
          sliver: SliverToBoxAdapter(
            child: LogbookHeroHeader(
              title: rider.name,
              photoUrl: rider.picUrl,
              imageProvider: widget.previewImage,
              onAddEntry: () => _openEditor(knownEntries: allEntries),
              fallbackIcon: Icons.person_outline_rounded,
            ),
          ),
        ),
        if (showUpNext)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spaceLg,
              0,
              AppTokens.spaceLg,
              AppTokens.spaceMd,
            ),
            sliver: SliverToBoxAdapter(
              child: LogbookUpNextCard(
                nextStepsHit: nextStepsHit,
                recentSkills: recentSkills,
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.spaceLg,
            0,
            AppTokens.spaceLg,
            AppTokens.spaceMd,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LogbookFilterBar<RiderLogType?>(
                  options: [
                    const LogbookFilterOption(
                      value: null,
                      label: 'All entries',
                    ),
                    for (final type in RiderLogType.values)
                      LogbookFilterOption(value: type, label: type.label),
                  ],
                  selected: _filter,
                  onSelected: (type) => setState(() => _filter = type),
                  newestFirst: _newestFirst,
                  onSortChanged: (value) =>
                      setState(() => _newestFirst = value),
                  onSearchChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                ),
                if (horseOptions.length >= 2 &&
                    allEntries.any(
                      (e) =>
                          (e.riderLog?.horseId?.isNotEmpty ?? false) ||
                          (e.riderLog?.horse?.isNotEmpty ?? false),
                    )) ...[
                  const SizedBox(height: AppTokens.spaceSm),
                  SingleChildScrollView(
                    key: const Key('riderLogbookHorseFilterBar'),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          key: const Key('horseFilter_all'),
                          visualDensity: VisualDensity.compact,
                          label: const Text('All horses'),
                          selected: activeHorseFilter == null,
                          onSelected: (_) =>
                              setState(() => _horseFilterKey = null),
                        ),
                        for (final option in horseOptions.entries) ...[
                          const SizedBox(width: 6),
                          FilterChip(
                            key: Key('horseFilter_${option.key}'),
                            visualDensity: VisualDensity.compact,
                            label: Text(option.value),
                            selected: activeHorseFilter == option.key,
                            onSelected: (_) => setState(
                              () => _horseFilterKey =
                                  activeHorseFilter == option.key
                                  ? null
                                  : option.key,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (sharedLoading)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceLg,
              vertical: AppTokens.spaceXs,
            ),
            sliver: SliverToBoxAdapter(
              child: LinearProgressIndicator(
                color: AppTokens.accentColor(context),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        if (sharedError)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppTokens.spaceLg,
              0,
              AppTokens.spaceLg,
              AppTokens.spaceMd,
            ),
            sliver: SliverToBoxAdapter(
              child: AppFeedbackBanner(
                message: 'Shared entries could not be loaded.',
                tone: AppStatusTone.warning,
              ),
            ),
          ),
        if (entries.isEmpty && !sharedLoading)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spaceLg,
              AppTokens.spaceSm,
              AppTokens.spaceLg,
              AppTokens.spaceXl,
            ),
            sliver: SliverToBoxAdapter(
              child: AppEmptyState(
                icon: Icons.auto_stories_outlined,
                title:
                    _filter == null &&
                        activeHorseFilter == null &&
                        _query.isEmpty
                    ? 'Start your training journal'
                    : 'No matching entries',
                description:
                    _filter == null &&
                        activeHorseFilter == null &&
                        _query.isEmpty
                    ? 'Add your first entry.'
                    : 'No entries match your current filter or search.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spaceLg,
              0,
              AppTokens.spaceLg,
              AppTokens.spaceXl,
            ),
            sliver: SliverList.builder(
              itemCount: listItems.length,
              itemBuilder: (context, index) {
                final item = listItems[index];
                if (item is _TimelineMonthItem) {
                  return LogbookMonthHeader(date: item.date);
                }
                final entry = (item as _TimelineEntryItem).entry;
                final attribution = _entryAttribution(entry, rider);
                final horse = entry.riderLog?.horse;
                final title = _entryTitle(entry);
                return LogbookEntryCard(
                  title: title,
                  metadata: [
                    _entryMetadata(entry),
                    ?horse,
                    ?attribution,
                  ].join('\n'),
                  preview: buildLogbookCardPreview(entry, title),
                  footer: buildLogbookEntryFooter(context, entry),
                  icon: switch (entry.riderLogType) {
                    RiderLogType.lesson => Icons.school_outlined,
                    RiderLogType.training => Icons.directions_run,
                    RiderLogType.show => Icons.emoji_events_outlined,
                    RiderLogType.care => Icons.health_and_safety_outlined,
                    RiderLogType.reflection => Icons.notes,
                    RiderLogType.activity => Icons.history,
                  },
                  trailing:
                      entry.riderLogType == RiderLogType.show &&
                          entry.riderLog?.placing != null
                      ? LogbookPlacingBadge(placing: entry.riderLog!.placing!)
                      : null,
                  onTap: () => _openEntry(entry, allEntries),
                );
              },
            ),
          ),
      ],
    );
  }
}
