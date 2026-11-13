import 'package:database_repository/database_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/cubit/logbook_cubit.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Theme/ocean_coral.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';
import 'package:intl/intl.dart';

class RiderLogbookPage extends StatefulWidget {
  const RiderLogbookPage({super.key, required this.email});

  final String email;

  static void open(BuildContext context) {
    final state = context.read<AppCubit>().state;
    final email = state.usersProfile?.email;
    if (state.isGuest || email == null || email.isEmpty) return;
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (_) => RiderLogbookPage(email: email)),
    );
  }

  static Future<void> addLessonFor(
    BuildContext context,
    CoachingConnection student, {
    BaseListItem? entry,
    Skill? initialSkill,
    LevelState? initialLevel,
  }) async {
    final app = context.read<AppCubit>();
    final profile = app.state.usersProfile;
    if (profile == null) return;

    // This editor can be opened from outside
    // RiderLogbookPage (e.g. Connections).
    // Provide LogbookCubit at the route level so the editor does not depend on
    // ancestor pages.
    final saved = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (ctx) => LogbookCubit(
            connectionRepository: ctx.read<ConnectionRepository?>(),
            riderProfileRepository: ctx.read<RiderProfileRepository>(),
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
  String? _journalUid;
  Stream<List<BaseListItem>>? _journal;

  Stream<List<BaseListItem>>? _journalFor(BuildContext context, String uid) {
    if (_journalUid != uid) {
      _journalUid = uid;
      _journal = uid.isEmpty
          ? null
          : context.read<ConnectionRepository?>()?.watchJournal(uid);
    }
    return _journal;
  }

  void _openEditor([BaseListItem? entry]) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _LogEntryEditor(email: widget.email, entry: entry),
      ),
    );
  }

  Future<void> _openEntry(BaseListItem entry) async {
    final action = await showAppDialog<String>(
      context: context,
      builder: (_) => BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final rider = _owner(state, widget.email);
          if (rider == null) {
            return const OceanCoralAppDialog(
              content: Text('Logbook unavailable.'),
            );
          }
          final info = entry.riderLog;
          final attribution = _entryAttribution(entry, rider);
          return OceanCoralAppDialog(
            scrollable: true,
            title: Text(info?.title ?? entry.riderLogType.label),
            maxWidth: 560,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry.riderLogType.label} · ${_dateLabel(entry.date)}'),
                if (attribution != null) Text(attribution),
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
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (entry.canEditRiderLog(rider.email))
                FilledButton(
                  onPressed: () => Navigator.pop(context, 'edit'),
                  child: const Text('Edit entry'),
                ),
              if (entry.canEditRiderLog(rider.email) &&
                  context.read<ConnectionRepository?>() != null)
                TextButton(
                  onPressed: () => Navigator.pop(context, 'delete'),
                  child: const Text('Delete entry'),
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
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => OceanCoralAppDialog(
        title: const Text('Delete this entry?'),
        content: const Text('A shared entry is removed from both logbooks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || !(confirmed ?? false)) return;
    try {
      await context.read<LogbookCubit>().deleteEntry(entry);
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

    return BlocProvider(
      create: (context) => LogbookCubit(
        connectionRepository: context.read<ConnectionRepository?>(),
        riderProfileRepository: context.read<RiderProfileRepository>(),
      ),
      child: Scaffold(
        appBar: ThemedAppBar(title: const Text('Rider logbook')),
        body: SafeArea(
          child: rider == null
              ? Center(
                  child: state.pageStatus == AppPageStatus.loading
                      ? const CircularProgressIndicator()
                      : const Text('Your rider logbook is unavailable.'),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 840),
                    child: StreamBuilder<List<BaseListItem>>(
                      key: ValueKey(state.user.id),
                      stream: _journalFor(context, state.user.id),
                      builder: (context, snapshot) => _timeline(
                        context,
                        rider,
                        snapshot.data ?? const [],
                        sharedError: snapshot.hasError,
                        sharedLoading:
                            snapshot.connectionState == ConnectionState.waiting,
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
            .where((entry) => _filter == null || entry.riderLogType == _filter)
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
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: GradientCard(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _openEditor,
                      icon: const Icon(Icons.add),
                      label: const Text('Add entry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final type in [null, ...RiderLogType.values])
                      ChoiceChip(
                        label: Text(type?.label ?? 'All entries'),
                        selected: _filter == type,
                        onSelected: (_) => setState(() => _filter = type),
                      ),
                  ],
                ),
                DropdownButton<bool>(
                  value: _newestFirst,
                  onChanged: (value) {
                    if (value != null) setState(() => _newestFirst = value);
                  },
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Newest first')),
                    DropdownMenuItem(value: false, child: Text('Oldest first')),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (sharedLoading)
          const SliverToBoxAdapter(child: LinearProgressIndicator()),
        if (sharedError)
          const SliverToBoxAdapter(
            child: ListTile(title: Text('Shared entries could not be loaded.')),
          ),
        if (entries.isEmpty && !sharedLoading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _filter == null
                    ? 'Add your first entry.'
                    : 'No entries in this category.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final attribution = _entryAttribution(entry, rider);
                final horse = entry.riderLog?.horse;
                return GradientCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      _entryTitle(entry),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        _entryMetadata(entry),
                        if (horse != null) horse,
                        if (attribution != null) attribution,
                      ].join('\n'),
                    ),
                    trailing:
                        entry.riderLogType == RiderLogType.show &&
                            entry.riderLog?.placing != null
                        ? _PlacingBadge(placing: entry.riderLog!.placing!)
                        : const Icon(Icons.chevron_right),
                    onTap: () => _openEntry(entry),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PlacingBadge extends StatelessWidget {
  const _PlacingBadge({required this.placing});

  final String placing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, color) = switch (placing.trim().toLowerCase()) {
      '1' || '1st' => ('1st', const Color(0xFFFFD15C)),
      '2' || '2nd' => ('2nd', const Color(0xFFCBD5E1)),
      '3' || '3rd' => ('3rd', const Color(0xFFDBA47B)),
      _ => (placing, colors.secondaryContainer),
    };
    final foreground = color.computeLuminance() > .18
        ? Colors.black
        : Colors.white;
    return Semantics(
      label: 'Show placing: $label',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 100),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 16, color: foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: foreground),
              ),
            ),
          ],
        ),
      ),
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
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        SelectableText(value),
      ],
    ),
  );
}

class _LogEntryEditor extends StatefulWidget {
  const _LogEntryEditor({
    required this.email,
    this.entry,
    this.initialStudent,
    this.initialSkill,
    this.initialLevel,
  });

  final String email;
  final BaseListItem? entry;
  final CoachingConnection? initialStudent;
  final Skill? initialSkill;
  final LevelState? initialLevel;

  @override
  State<_LogEntryEditor> createState() => _LogEntryEditorState();
}

class _LogEntryEditorState extends State<_LogEntryEditor> {
  final _form = GlobalKey<FormState>();
  late final _id = widget.entry?.id ?? ViewUtils.createId();
  late final _title = TextEditingController(
    text: widget.entry?.riderLog?.title,
  );
  late final _instructor = TextEditingController(
    text: widget.entry?.riderLog?.instructor,
  );
  late final _horse = TextEditingController(
    text: widget.entry?.riderLog?.horse,
  );
  late final _placing = TextEditingController(
    text: widget.entry?.riderLog?.placing,
  );
  String? _selectedHorseName;
  late String _horseChoice = switch (widget.entry?.riderLog) {
    RiderLogDetails(horseId: final String id) => 'horse:$id',
    RiderLogDetails(horse: final String _) => 'other',
    _ => 'none',
  };
  late final _focus = TextEditingController(
    text: widget.entry?.riderLog?.focus,
  );
  late final _notes = TextEditingController(text: widget.entry?.name);
  late final _nextSteps = TextEditingController(
    text: widget.entry?.riderLog?.nextSteps,
  );
  late RiderLogType _type = widget.entry?.riderLogType ?? RiderLogType.lesson;
  late DateTime? _date = widget.entry == null
      ? DateTime.now()
      : widget.entry!.date;
  CoachingConnection? _student;
  Map<String, String> _studentHorses = {};
  List<String> _personalStudentHorseIds = [];
  Future<Set<String>>? _activeStudentHorseIds;
  bool _loadingHorses = false;
  int _horseRequest = 0;
  late String? _skillId = widget.initialSkill?.id;
  late String _level = switch (widget.initialLevel) {
    LevelState.PROFICIENT || LevelState.VERIFIED => 'PROFICIENT',
    _ => 'LEARNING',
  };

  @override
  void initState() {
    super.initState();
    final student = widget.initialStudent;
    if (student != null) {
      _student = student;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _chooseStudent(student, preserveHorse: widget.entry != null);
        }
      });
    }
  }

  Future<void> _chooseStudent(
    CoachingConnection? student, {
    bool preserveHorse = false,
  }) async {
    final request = ++_horseRequest;
    setState(() {
      _student = student;
      if (!preserveHorse) _horseChoice = 'none';
      _studentHorses = {};
      _loadingHorses = student != null;
      _error = null;
    });
    if (student == null) return;
    try {
      final previous = widget.entry?.riderLog;
      final horses = await context
          .read<LogbookCubit>()
          .fetchStudentHorseOptions(
            student,
            preserveHorseId: preserveHorse ? previous?.horseId : null,
            preserveHorseName: preserveHorse
                ? (previous?.horse ?? previous?.horseId)
                : null,
          );
      if (!mounted || _horseRequest != request) return;
      setState(() {
        _studentHorses = horses;
        _loadingHorses = false;
      });
    } catch (_) {
      if (!mounted || _horseRequest != request) return;
      setState(() {
        _loadingHorses = false;
        _error = 'Could not load the student’s horses.';
      });
    }
  }

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _title,
      _instructor,
      _horse,
      _placing,
      _focus,
      _notes,
      _nextSteps,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final rider = _owner(context.read<AppCubit>().state, widget.email);
    if (rider == null ||
        !(widget.entry?.canEditRiderLog(rider.email) ?? true)) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    String? value(TextEditingController controller) {
      final text = controller.text.trim();
      return text.isEmpty ? null : text;
    }

    try {
      final horseId = _horseChoice.startsWith('horse:')
          ? _horseChoice.substring('horse:'.length)
          : null;
      final student = _type == RiderLogType.lesson ? _student : null;
      if (student != null) {
        final message = await context.read<LogbookCubit>().saveStudentLesson(
          student: student,
          recordId: _id,
          notes: _notes.text.trim(),
          isEdit: widget.entry != null,
          entryId: widget.entry?.id,
          horseId: horseId,
          horse: _horseChoice == 'other' ? value(_horse) : null,
          date: _date,
          title: value(_title),
          focus: value(_focus),
          nextSteps: value(_nextSteps),
          skillId: widget.initialSkill?.id ?? _skillId,
          level: _level,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        Navigator.of(context).pop(true);
        return;
      }
      final details = RiderLogDetails(
        type: _type,
        title: value(_title),
        instructor: value(_instructor),
        horse: _horseChoice == 'other'
            ? value(_horse)
            : _linkedHorses(rider)[_horseChoice],
        horseId: horseId,
        placing: _type == RiderLogType.show ? value(_placing) : null,
        focus: value(_focus),
        nextSteps: value(_nextSteps),
      );
      final shared = widget.entry?.riderLog?.shared ?? false;
      if (horseId != null || shared) {
        await context.read<LogbookCubit>().saveSharedJournalEntry(
          id: _id,
          isEdit: widget.entry != null,
          shared: shared,
          date: _date,
          notes: _notes.text.trim(),
          details: details,
        );
      } else {
        await context.read<LogbookCubit>().saveLocalEntry(
          rider: rider,
          isEdit: widget.entry != null,
          entry: BaseListItem(
            id: _id,
            date: _date,
            name: _notes.text.trim(),
            imageUrl: switch (_type) {
              RiderLogType.lesson || RiderLogType.training => 'LogTag.Training',
              RiderLogType.show => 'LogTag.Show',
              RiderLogType.care => 'LogTag.Health',
              RiderLogType.reflection ||
              RiderLogType.activity => 'LogTag.Other',
            },
            parentId: widget.entry?.parentId ?? rider.email,
            message: widget.entry?.message ?? rider.name,
            riderLog: details,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = switch (error) {
          ConnectionFailure(:final message) => message,
          StateError(:final message) => message,
          _ => 'Could not save the entry. Your draft is still here.',
        };
      });
    }
  }

  Future<void> _chooseDate() async {
    final initial = _date ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial.year < 1900 ? initial : DateTime(1900),
      lastDate: initial.year > 2100 ? initial : DateTime(2100, 12, 31),
    );
    if (mounted && date != null) setState(() => _date = date);
  }

  @override
  Widget build(BuildContext context) {
    final rider = context.select(
      (AppCubit cubit) => _owner(cubit.state, widget.email),
    );
    final allowed = rider != null;
    final connections = context.watch<ConnectionsCubit?>()?.state;
    final students =
        connections?.connections
            .where(
              (link) =>
                  link.kind == 'rider' &&
                  link.status == 'accepted' &&
                  link.coach == rider?.email.toLowerCase(),
            )
            .toList() ??
        [];
    final showStudents =
        widget.entry == null &&
        ((rider?.isTrainer ?? false) || widget.initialStudent != null) &&
        _type == RiderLogType.lesson;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: ThemedAppBar(
          title: Text(
            widget.initialSkill != null
                ? 'Verify skill'
                : widget.entry == null
                ? 'Add log entry'
                : 'Edit log entry',
          ),
        ),
        bottomNavigationBar: allowed
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                          FilledButton.icon(
                            onPressed: _saving || _loadingHorses ? null : _save,
                            icon: _saving
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(_saving ? 'Saving…' : 'Save entry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null,
        body: SafeArea(
          bottom: false,
          child: allowed
              ? SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _section(context, 'What would you like to log?', [
                              const Text(
                                'You can log an entry with or without a horse.',
                              ),
                              _typeSelector(context),
                            ]),
                            const SizedBox(height: 10),
                            _section(context, 'Entry details', [
                              if (showStudents)
                                DropdownButtonFormField<String>(
                                  key: const Key('logEntryStudent'),
                                  initialValue: _student?.id ?? '',
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Student',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: '',
                                      child: Text('My logbook'),
                                    ),
                                    for (final student in students)
                                      DropdownMenuItem(
                                        value: student.id,
                                        child: Text(
                                          student.learnerName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    if (_student != null &&
                                        !students.any(
                                          (link) => link.id == _student!.id,
                                        ))
                                      DropdownMenuItem(
                                        value: _student!.id,
                                        child: Text(_student!.learnerName),
                                      ),
                                  ],
                                  onChanged:
                                      _saving || widget.initialSkill != null
                                      ? null
                                      : (id) => _chooseStudent(
                                          students
                                              .where((link) => link.id == id)
                                              .firstOrNull,
                                        ),
                                ),
                              if (_loadingHorses)
                                const LinearProgressIndicator(),
                              _horseAndDateFields(rider),
                              if (_horseChoice == 'other')
                                _field(
                                  context,
                                  _horse,
                                  'Horse name',
                                  required: true,
                                ),
                              if (_type == RiderLogType.show)
                                _field(
                                  context,
                                  _placing,
                                  'Placing (optional)',
                                  maxLength: 40,
                                ),
                              if (_student == null &&
                                  (_type == RiderLogType.lesson ||
                                      _instructor.text.isNotEmpty)) ...[
                                const Divider(height: 1),
                                _field(
                                  context,
                                  _instructor,
                                  'Instructor (optional)',
                                  icon: Icons.person_outline,
                                ),
                              ],
                              const Divider(height: 1),
                              _field(
                                context,
                                _title,
                                'Title (optional)',
                                maxLength: 100,
                              ),
                              _field(
                                context,
                                _focus,
                                'Work / focus (optional)',
                                maxLines: 2,
                              ),
                            ]),
                            const SizedBox(height: 10),
                            _section(context, 'Notes and next steps', [
                              if (_student != null) ..._skillFields(context),
                              _field(
                                context,
                                _notes,
                                'Notes',
                                minLines: 3,
                                maxLines: 7,
                                required: true,
                              ),
                              _field(
                                context,
                                _nextSteps,
                                'Next steps (optional)',
                                maxLines: 3,
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const Center(child: Text('Your rider logbook is unavailable.')),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      GradientCard(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              ...children,
            ],
          ),
        ),
      );

  Widget _typeSelector(BuildContext context) {
    const types = {
      RiderLogType.lesson: (Icons.school_outlined, 'Lesson'),
      RiderLogType.training: (Icons.directions_run, 'Training ride'),
      RiderLogType.show: (Icons.emoji_events_outlined, 'Show'),
      RiderLogType.care: (Icons.medical_services_outlined, 'Care visit'),
      RiderLogType.reflection: (Icons.edit_note, 'Reflection'),
    };
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 540
            ? 5
            : constraints.maxWidth >= 280
            ? 3
            : 2;
        const gap = 8.0;
        final tileWidth =
            (constraints.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final entry in types.entries)
              SizedBox(
                width: tileWidth,
                child: Semantics(
                  selected: _type == entry.key,
                  child: OutlinedButton(
                    key: ValueKey('logType-${entry.key.name}'),
                    onPressed: _saving
                        ? null
                        : widget.initialStudent != null &&
                              entry.key != RiderLogType.lesson
                        ? null
                        : () {
                            if (entry.key != RiderLogType.lesson &&
                                _student != null) {
                              _chooseStudent(null);
                            }
                            setState(() => _type = entry.key);
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 9,
                      ),
                      minimumSize: const Size(0, 64),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: _type == entry.key
                          ? colors.primary
                          : colors.onSurface,
                      backgroundColor: _type == entry.key
                          ? Color.alphaBlend(
                              colors.primary.withValues(alpha: .16),
                              colors.surface,
                            )
                          : colors.surface,
                      side: BorderSide(
                        color: _type == entry.key
                            ? colors.primary
                            : colors.outline,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(entry.value.$1, size: 21),
                        const SizedBox(height: 4),
                        Text(entry.value.$2, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Map<String, String> _linkedHorses(
    RiderProfile rider, {
    Set<String>? activeStudentHorseIds,
  }) {
    final links = <String, String>{};
    for (final horse in [
      ...?rider.ownedHorses,
      for (final horse in rider.studentHorses ?? <BaseListItem>[])
        if (activeStudentHorseIds?.contains(horse.id) ?? true) horse,
    ]) {
      final id = horse.id;
      if (id != null && id.isNotEmpty) {
        final name = horse.name?.trim();
        links['horse:$id'] = name == null || name.isEmpty ? id : name;
      }
    }
    final previous = widget.entry?.riderLog;
    final previousId = previous?.horseId;
    if (previousId != null) {
      links.putIfAbsent(
        'horse:$previousId',
        () => previous?.horse ?? previousId,
      );
    }
    final selectedName = _selectedHorseName;
    if (selectedName != null && _horseChoice.startsWith('horse:')) {
      links.putIfAbsent(_horseChoice, () => selectedName);
    }
    return links;
  }

  Widget _horseAndDateFields(RiderProfile rider) {
    final repository = context.read<HorseProfileRepository?>();
    if (_student != null || repository == null) return _dateAndHorse(rider);
    final ids =
        (rider.studentHorses ?? <BaseListItem>[])
            .map((horse) => horse.id)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    if (!listEquals(_personalStudentHorseIds, ids)) {
      _personalStudentHorseIds = ids;
      _activeStudentHorseIds = ids.isEmpty
          ? null
          : _loadActiveHorseIds(repository, ids);
    }
    if (_activeStudentHorseIds == null) return _dateAndHorse(rider);
    return FutureBuilder<Set<String>>(
      future: _activeStudentHorseIds,
      builder: (context, snapshot) =>
          _dateAndHorse(rider, activeStudentHorseIds: snapshot.data ?? {}),
    );
  }

  Future<Set<String>> _loadActiveHorseIds(
    HorseProfileRepository repository,
    List<String> ids,
  ) async {
    final batches = await Future.wait([
      for (var index = 0; index < ids.length; index += 30)
        repository
            .getAllUsersHorses(ids: ids.skip(index).take(30).toList())
            .first,
    ]);
    return {
      for (final batch in batches)
        for (final horse in batch)
          if (!horse.isArchived) horse.id,
    };
  }

  Widget _dateAndHorse(
    RiderProfile rider, {
    Set<String>? activeStudentHorseIds,
  }) {
    final date = OutlinedButton.icon(
      key: const Key('logEntryDate'),
      onPressed: _saving ? null : _chooseDate,
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(_dateLabel(_date)),
    );
    final horses = _student == null
        ? _linkedHorses(rider, activeStudentHorseIds: activeStudentHorseIds)
        : {..._studentHorses};
    if (_horseChoice.startsWith('horse:') &&
        !horses.containsKey(_horseChoice)) {
      horses[_horseChoice] =
          widget.entry?.riderLog?.horse ?? 'Previously linked horse';
    }
    final horse = DropdownButtonFormField<String>(
      key: ValueKey('logEntryHorse-${_student?.id ?? 'self'}'),
      initialValue: _horseChoice,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Horse (optional)',
        helperText:
            'Selecting a linked horse shares this entry in its logbook.',
        helperMaxLines: 2,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: [
        const DropdownMenuItem(value: 'none', child: Text('No horse')),
        for (final entry in horses.entries)
          DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          ),
        const DropdownMenuItem(value: 'other', child: Text('Other')),
      ],
      onChanged: _saving || _loadingHorses
          ? null
          : (value) => setState(() {
              _horseChoice = value!;
              _selectedHorseName = horses[value];
            }),
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 480
          ? Row(
              children: [
                date,
                const SizedBox(width: 12),
                Expanded(child: horse),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [date, horse],
            ),
    );
  }

  List<Widget> _skillFields(BuildContext context) {
    final skills = context
        .read<AppCubit>()
        .state
        .allSkills
        .whereType<Skill>()
        .where((skill) => skill.rider)
        .toList();
    if (skills.isEmpty) return const [];
    return [
      DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(
          labelText: widget.initialSkill == null
              ? 'Skill progress (optional)'
              : 'Skill to verify',
        ),
        initialValue: _skillId,
        items: [
          const DropdownMenuItem<String>(child: Text('No skill update')),
          for (final skill in skills)
            DropdownMenuItem(
              value: skill.id,
              child: Text(skill.skillName, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: _saving || widget.initialSkill != null
            ? null
            : (value) => setState(() => _skillId = value),
      ),
      if (_skillId != null || widget.initialSkill != null)
        DropdownButtonFormField<String>(
          initialValue: _level,
          decoration: const InputDecoration(labelText: 'Progress'),
          items: const [
            DropdownMenuItem(value: 'LEARNING', child: Text('Learning')),
            DropdownMenuItem(value: 'PROFICIENT', child: Text('Proficient')),
          ],
          onChanged: _saving
              ? null
              : (value) => setState(() => _level = value!),
        ),
    ];
  }

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label, {
    Key? key,
    IconData? icon,
    int minLines = 1,
    int maxLines = 1,
    int? maxLength,
    bool required = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      key: key,
      controller: controller,
      enabled: !_saving,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon, size: 18),
        filled: true,
        fillColor: colors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        counterText: maxLength == null ? null : '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: required
          ? (text) => (text?.trim().isEmpty ?? true)
                ? (controller == _notes
                      ? 'Enter a note.'
                      : 'Enter the horse name.')
                : null
          : null,
    );
  }
}
