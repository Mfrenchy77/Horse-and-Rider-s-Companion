import 'package:database_repository/database_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_entry_card.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_filter_bar.dart';
import 'package:horseandriderscompanion/CommonWidgets/logbook_hero_header.dart';
import 'package:horseandriderscompanion/CommonWidgets/personalized_logbook_backdrop.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/cubit/logbook_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/logbook_connection_repository.dart';
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

  static Future<void> addEntry(BuildContext context) => _addEntry(context);

  static Future<void> addLessonFor(
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

  static Future<void> _addEntry(
    BuildContext context, {
    CoachingConnection? student,
    BaseListItem? entry,
    Skill? initialSkill,
    LevelState? initialLevel,
  }) async {
    final app = context.read<AppCubit>();
    final profile = app.state.usersProfile;
    if (app.state.isGuest || profile == null) return;

    // This editor can be opened from outside
    // RiderLogbookPage (e.g. Connections).
    // Provide LogbookCubit at the route level so the editor does not depend on
    // ancestor pages.
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
  final title = entry.riderLog?.title ?? entry.name?.trim().split('\n').first;
  return title == null || title.isEmpty ? entry.riderLogType.label : title;
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

class _RiderLogbookPageState extends State<RiderLogbookPage> {
  RiderLogType? _filter;
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

  void _openEditor([BaseListItem? entry]) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _logbookCubit,
          child: _LogEntryEditor(email: widget.email, entry: entry),
        ),
      ),
    );
  }

  Future<void> _openEntry(BaseListItem entry) async {
    final action = await showAppGlassDialog<String>(
      context: context,
      builder: (_) => BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final rider = _owner(state, widget.email);
          if (rider == null) {
            return const AppGlassDialog(
              content: Text('Logbook unavailable.'),
            );
          }
          final info = entry.riderLog;
          final attribution = _entryAttribution(entry, rider);
          return AppGlassDialog(
            title: Text(
              info?.title ?? entry.riderLogType.label,
              style: AppTokens.sectionTitleStyle(context),
            ),
            maxWidth: 560,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppStatusBadge(
                      label: entry.riderLogType.label,
                      icon: Icons.bookmark_outline_rounded,
                      tone: AppStatusTone.coral,
                    ),
                    Text(
                      _dateLabel(entry.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTokens.secondaryTextColor(context),
                      ),
                    ),
                    if (entry.riderLogType == RiderLogType.show &&
                        info?.placing != null)
                      LogbookPlacingBadge(placing: info!.placing!),
                  ],
                ),
                if (attribution != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    attribution,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTokens.secondaryTextColor(context),
                    ),
                  ),
                ],
                if (info?.instructor != null)
                  _EntryField(label: 'Instructor', value: info!.instructor!),
                if (entry.riderLogType == RiderLogType.show &&
                    info?.placing != null)
                  _EntryField(label: 'Placing', value: info!.placing!),
                if (info?.horse != null)
                  _EntryField(label: 'Horse', value: info!.horse!),
                if (info?.focus != null)
                  _EntryField(label: 'Work / focus', value: info!.focus!),
                if (entry.name?.trim().isNotEmpty ?? false)
                  _EntryField(label: 'Notes', value: entry.name!),
                if (info?.nextSteps != null)
                  _EntryField(label: 'Next steps', value: info!.nextSteps!),
              ],
            ),
            actions: [
              AppOutlinedButton(
                onPressed: () => Navigator.pop(context),
                label: 'Close',
              ),
              if (entry.canEditRiderLog(rider.email))
                AppPrimaryButton(
                  onPressed: () => Navigator.pop(context, 'edit'),
                  icon: Icons.edit_outlined,
                  label: 'Edit entry',
                ),
              if (entry.canEditRiderLog(rider.email) &&
                  _readLogbookConnections(context) != null)
                AppDestructiveButton(
                  outlined: true,
                  onPressed: () => Navigator.pop(context, 'delete'),
                  label: 'Delete entry',
                ),
            ],
          );
        },
      ),
    );
    if (!mounted) return;
    if (action == 'edit') _openEditor(entry);
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
    final entries =
        [
              ...?rider.notes?.where((entry) => !sharedIds.contains(entry.id)),
              ...shared,
            ]
            .where((entry) {
              if (_filter != null && entry.riderLogType != _filter) {
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
                info?.focus,
                info?.nextSteps,
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
              onAddEntry: _openEditor,
              fallbackIcon: Icons.person_outline_rounded,
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
            child: LogbookFilterBar<RiderLogType?>(
              options: [
                const LogbookFilterOption(value: null, label: 'All entries'),
                for (final type in RiderLogType.values)
                  LogbookFilterOption(value: type, label: type.label),
              ],
              selected: _filter,
              onSelected: (type) => setState(() => _filter = type),
              newestFirst: _newestFirst,
              onSortChanged: (value) => setState(() => _newestFirst = value),
              onSearchChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
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
                title: _filter == null && _query.isEmpty
                    ? 'Start your training journal'
                    : 'No matching entries',
                description: _filter == null && _query.isEmpty
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
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final attribution = _entryAttribution(entry, rider);
                final horse = entry.riderLog?.horse;
                final title = _entryTitle(entry);
                return LogbookEntryCard(
                  title: title,
                  metadata: [
                    _entryMetadata(entry),
                    if (horse != null) horse,
                    if (attribution != null) attribution,
                  ].join('\n'),
                  preview: entry.name != title ? entry.name : null,
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
                  onTap: () => _openEntry(entry),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EntryField extends StatelessWidget {
  const _EntryField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTokens.secondaryTextColor(context),
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTokens.primaryTextColor(context),
          ),
        ),
      ],
    ),
  );
}
