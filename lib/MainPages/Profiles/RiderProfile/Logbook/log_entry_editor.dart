// ignore_for_file: lines_longer_than_80_chars

part of 'rider_logbook_page.dart';

class _LogEntryEditor extends StatefulWidget {
  const _LogEntryEditor({
    required this.email,
    this.entry,
    this.initialStudent,
    this.initialHorse,
    this.horseConnection,
    this.initialType,
    this.initialPracticedSkills = const [],
    this.knownEntries = const [],
    this.initialSkill,
    this.initialLevel,
  });

  final String email;
  final BaseListItem? entry;
  final CoachingConnection? initialStudent;
  final HorseProfile? initialHorse;
  final CoachingConnection? horseConnection;
  final RiderLogType? initialType;
  final List<PracticedSkillTag> initialPracticedSkills;
  final List<BaseListItem> knownEntries;
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
  late final _highlights = TextEditingController(
    text: widget.entry?.riderLog?.highlights,
  );
  late final _focus = TextEditingController(
    text: widget.entry?.riderLog?.focus,
  );
  late final _notes = TextEditingController(text: widget.entry?.name);
  late final _nextSteps = TextEditingController(
    text: widget.entry?.riderLog?.nextSteps,
  );
  late final _videoUrl = TextEditingController(
    text: widget.entry?.riderLog?.videoUrl,
  );

  late String? _selectedHorseName =
      widget.entry?.riderLog?.horse ??
      widget.initialHorse?.name ??
      widget.horseConnection?.horseName;

  late String _horseChoice = switch (widget.entry?.riderLog) {
    RiderLogDetails(horseId: final String id) => 'horse:$id',
    RiderLogDetails(horse: final String _) => 'other',
    _ =>
      widget.initialHorse != null
          ? 'horse:${widget.initialHorse!.id}'
          : widget.horseConnection?.horseId != null
          ? 'horse:${widget.horseConnection!.horseId}'
          : 'none',
  };

  late RiderLogType _type =
      widget.entry?.riderLogType ??
      widget.initialType ??
      (widget.initialHorse != null || widget.horseConnection != null
          ? RiderLogType.training
          : RiderLogType.lesson);

  late DateTime? _date = widget.entry == null
      ? DateTime.now()
      : widget.entry!.date;

  late SessionFeel? _feel = widget.entry?.riderLog?.feel;

  late List<PracticedSkillTag> _practicedSkills = List.of(
    widget.entry?.riderLog?.practicedSkills ?? widget.initialPracticedSkills,
  );

  // Explicit opt-in only: never checked automatically.
  bool _markPracticedAsLearning = false;
  List<PracticedSkillTag> _eligibleLearningTags = const [];
  int _eligibilityRequest = 0;

  // Private reflections default to author-only (false) even when a horse is
  // selected; only pre-enabled when editing an already-shared reflection.
  late bool _shareReflection = widget.entry?.riderLog?.shared ?? false;

  late bool _takeawaysExpanded = switch (widget.entry?.riderLog) {
    final RiderLogDetails d =>
      d.highlights != null ||
          d.focus != null ||
          d.nextSteps != null ||
          d.title != null ||
          d.videoUrl != null,
    null => false,
  };

  final Map<String, List<BaseListItem>> _fetchedHorseHistory = {};
  final Set<String> _loadingHorseHistoryIds = {};

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

  bool _saving = false;
  String? _error;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshHorseHistoryForNextSteps();
      _refreshLearningEligibility();
    });
  }

  String? get _selectedHorseId => _horseChoice.startsWith('horse:')
      ? _horseChoice.substring('horse:'.length)
      : null;

  SkillTreeV2Repository? _resolveSkillTreeRepo() {
    try {
      final provided = context.read<SkillTreeV2Repository?>();
      if (provided != null) return provided;
    } catch (_) {}
    return SkillTreeV2View.defaultRepository();
  }

  Future<void> _refreshHorseHistoryForNextSteps() async {
    if (widget.entry != null ||
        _student != null ||
        widget.knownEntries.isNotEmpty ||
        (widget.initialHorse == null && widget.horseConnection == null)) {
      return;
    }
    final horseId = _selectedHorseId;
    if (horseId == null ||
        _fetchedHorseHistory.containsKey(horseId) ||
        _loadingHorseHistoryIds.contains(horseId)) {
      return;
    }
    final repo = _readLogbookConnections(context);
    if (repo == null) return;
    _loadingHorseHistoryIds.add(horseId);
    try {
      final items = await repo.history({
        'action': 'horseHistory',
        'horseId': horseId,
      });
      if (!mounted) return;
      setState(() {
        _loadingHorseHistoryIds.remove(horseId);
        _fetchedHorseHistory[horseId] = items;
      });
    } on Exception catch (_) {
      _loadingHorseHistoryIds.remove(horseId);
    }
  }

  Future<void> _refreshLearningEligibility() async {
    final req = ++_eligibilityRequest;
    final appState = context.read<AppCubit>().state;
    final rider = _owner(appState, widget.email);
    if (rider == null || _student != null || _practicedSkills.isEmpty) {
      if (mounted) {
        setState(() {
          _eligibleLearningTags = const [];
          _markPracticedAsLearning = false;
        });
      }
      return;
    }

    final repo = _resolveSkillTreeRepo();
    if (repo == null) {
      if (mounted) {
        setState(() {
          _eligibleLearningTags = const [];
          _markPracticedAsLearning = false;
        });
      }
      return;
    }

    final horseId = _selectedHorseId;
    final ownsSelectedHorse =
        horseId != null &&
        ((rider.ownedHorses?.any((h) => h.id == horseId) ?? false) ||
            (widget.initialHorse?.id == horseId &&
                !widget.initialHorse!.isArchived &&
                widget.initialHorse!.currentOwnerId.toLowerCase() ==
                    rider.email.toLowerCase()) ||
            (appState.horseProfile?.id == horseId &&
                !appState.horseProfile!.isArchived &&
                appState.horseProfile!.currentOwnerId.toLowerCase() ==
                    rider.email.toLowerCase()));

    var riderProgress = const <String, SkillProgressRecord>{};
    var riderVerifications = const <String, SkillVerificationRecord>{};
    var horseProgress = const <String, SkillProgressRecord>{};
    var horseVerifications = const <String, SkillVerificationRecord>{};

    final needsRider = _practicedSkills.any(
      (t) => t.subject == 'rider' && t.level != null,
    );
    final needsHorse =
        ownsSelectedHorse &&
        _practicedSkills.any((t) => t.subject == 'horse' && t.level != null);

    try {
      if (needsRider) {
        riderProgress = await repo.fetchProgress(
          subject: SkillSubject.rider,
          profileDocId: rider.email,
        );
        riderVerifications = await repo.fetchVerifications(
          subject: SkillSubject.rider,
          profileDocId: rider.email,
        );
      }
      if (needsHorse) {
        horseProgress = await repo.fetchProgress(
          subject: SkillSubject.horse,
          profileDocId: horseId,
        );
        horseVerifications = await repo.fetchVerifications(
          subject: SkillSubject.horse,
          profileDocId: horseId,
        );
      }
    } catch (_) {
      return;
    }

    if (!mounted || req != _eligibilityRequest) return;

    final eligible = <PracticedSkillTag>[];
    for (final tag in _practicedSkills) {
      final level = parsePracticedDifficultyLevel(tag.level);
      if (level == null) continue;
      if (tag.subject == 'rider') {
        final selfState = riderProgress[tag.skillId]?.levels[level]?.state;
        final verified =
            riderVerifications[tag.skillId]?.levels.containsKey(level) ?? false;
        if (selfState == null && !verified) {
          eligible.add(tag);
        }
      } else if (tag.subject == 'horse' && ownsSelectedHorse) {
        final selfState = horseProgress[tag.skillId]?.levels[level]?.state;
        final verified =
            horseVerifications[tag.skillId]?.levels.containsKey(level) ?? false;
        if (selfState == null && !verified) {
          eligible.add(tag);
        }
      }
    }

    setState(() {
      _eligibleLearningTags = eligible;
      if (eligible.isEmpty) _markPracticedAsLearning = false;
    });
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
    await _refreshLearningEligibility();
    if (student == null || !mounted) return;
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

  @override
  void dispose() {
    for (final controller in [
      _title,
      _instructor,
      _horse,
      _placing,
      _highlights,
      _focus,
      _notes,
      _nextSteps,
      _videoUrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _hasStructuredContent =>
      _highlights.text.trim().isNotEmpty ||
      _focus.text.trim().isNotEmpty ||
      _nextSteps.text.trim().isNotEmpty ||
      _title.text.trim().isNotEmpty ||
      _practicedSkills.isNotEmpty;

  Future<void> _applyOptInLearningUpdates(
    AppState appState,
    RiderProfile rider,
    String? horseId,
  ) async {
    if (!_markPracticedAsLearning ||
        _student != null ||
        _eligibleLearningTags.isEmpty) {
      return;
    }
    final repo = _resolveSkillTreeRepo();
    if (repo == null) return;
    for (final tag in _eligibleLearningTags) {
      final level = parsePracticedDifficultyLevel(tag.level);
      if (level == null) continue;
      final subject = tag.subject == 'horse'
          ? SkillSubject.horse
          : SkillSubject.rider;
      final profileDocId = subject == SkillSubject.horse
          ? horseId
          : rider.email;
      if (profileDocId == null || profileDocId.isEmpty) continue;
      try {
        await repo.setLevelProgress(
          subject: subject,
          profileDocId: profileDocId,
          skillId: tag.skillId,
          level: level,
          state: LevelState.LEARNING,
          actorUid: appState.user.id,
          actorName: rider.name,
        );
      } catch (_) {
        // Non-blocking: journal entry itself is already persisted.
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final rawVideo = _videoUrl.text.trim();
    if (rawVideo.isNotEmpty && !_takeawaysExpanded) {
      setState(() => _takeawaysExpanded = true);
    }
    if (!_form.currentState!.validate()) return;
    final appState = context.read<AppCubit>().state;
    final rider = _owner(appState, widget.email);
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
      final horseId = _selectedHorseId;
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
          feel: _feel,
          highlights: value(_highlights),
          focus: value(_focus),
          nextSteps: value(_nextSteps),
          practicedSkills: _practicedSkills,
          videoUrl: value(_videoUrl),
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

      final wasShared = widget.entry?.riderLog?.shared ?? false;
      final shouldShare = _type == RiderLogType.reflection
          ? (horseId != null ? _shareReflection : wasShared)
          : (horseId != null || wasShared);
      final isAuthorOnlyReflection =
          _type == RiderLogType.reflection && !shouldShare;

      final details = RiderLogDetails(
        type: _type,
        title: value(_title),
        instructor: value(_instructor),
        horse: _horseChoice == 'other'
            ? value(_horse)
            : _linkedHorses(rider)[_horseChoice],
        horseId: horseId,
        placing: _type == RiderLogType.show ? value(_placing) : null,
        authorOnly: isAuthorOnlyReflection,
        feel: _feel,
        highlights: value(_highlights),
        focus: value(_focus),
        nextSteps: value(_nextSteps),
        practicedSkills: _practicedSkills,
        videoUrl: value(_videoUrl),
      );

      if (shouldShare) {
        await context.read<LogbookCubit>().saveSharedJournalEntry(
          id: _id,
          isEdit: widget.entry != null,
          shared: wasShared,
          date: _date,
          notes: _notes.text.trim(),
          details: details,
        );
      } else {
        await context.read<LogbookCubit>().saveLocalEntry(
          rider: rider,
          isEdit: widget.entry != null && !wasShared,
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
        if (wasShared && mounted && widget.entry != null) {
          try {
            await context.read<LogbookCubit>().deleteEntry(widget.entry!);
          } catch (_) {}
        }
      }

      await _applyOptInLearningUpdates(appState, rider, horseId);
      if (mounted) Navigator.of(context).pop(true);
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

  Future<void> _pickPracticedSkills() async {
    final defaultSubject = _selectedHorseId != null
        ? SkillSubject.horse
        : SkillSubject.rider;
    final picked = await showPracticedSkillsPickerDialog(
      context: context,
      initialSelection: _practicedSkills,
      defaultSubject: defaultSubject,
    );
    if (!mounted || picked == null) return;
    setState(() => _practicedSkills = picked);
    await _refreshLearningEligibility();
  }

  ({BaseListItem entry, String nextSteps})? _previousNextStepsForSelection(
    AppState appState,
    RiderProfile rider,
  ) {
    if (widget.entry != null) return null;
    final horseId = _selectedHorseId;
    final otherHorseName = _horseChoice == 'other' ? _horse.text.trim() : null;
    if (horseId == null && (otherHorseName == null || otherHorseName.isEmpty)) {
      return null;
    }
    final combined = <BaseListItem>[
      ...widget.knownEntries,
      ...?rider.notes,
      if (horseId != null && widget.initialHorse?.id == horseId)
        ...?widget.initialHorse?.notes,
      if (horseId != null && appState.horseProfile?.id == horseId)
        ...?appState.horseProfile?.notes,
      if (horseId != null) ...?_fetchedHorseHistory[horseId],
    ];
    return findPreviousNextSteps(
      combined,
      horseId: horseId,
      horseName: horseId == null ? otherHorseName : null,
      excludeEntryId: _id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppCubit>().state;
    final rider = _owner(appState, widget.email);
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
    final previousNextSteps = rider == null
        ? null
        : _previousNextStepsForSelection(appState, rider);
    final selectedHorseLabel = rider == null
        ? 'this horse'
        : (_linkedHorses(rider, connections: connections)[_horseChoice] ??
              _selectedHorseName ??
              'this horse');

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
                                child: AppFeedbackBanner(
                                  message: _error!,
                                  tone: AppStatusTone.error,
                                ),
                              ),
                            ),
                          AppPrimaryButton(
                            onPressed: _saving || _loadingHorses ? null : _save,
                            icon: _saving ? Icons.hourglass_top : Icons.check,
                            label: _saving ? 'Saving…' : 'Save entry',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null,
        body: AppScaffoldBackdrop(
          child: SafeArea(
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
                              if (previousNextSteps != null) ...[
                                _previousNextStepsBanner(
                                  context,
                                  previousNextSteps,
                                  selectedHorseLabel,
                                ),
                                const SizedBox(height: 10),
                              ],
                              _section(context, 'What would you like to log?', [
                                Text(
                                  'You can log an entry with or without '
                                  'a horse.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppTokens.secondaryTextColor(
                                          context,
                                        ),
                                      ),
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
                                _horseAndDateFields(rider, connections),
                                if (_horseChoice == 'other')
                                  _field(
                                    context,
                                    _horse,
                                    'Horse name',
                                    required: true,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                if (_type == RiderLogType.reflection &&
                                    _selectedHorseId != null)
                                  SwitchListTile.adaptive(
                                    key: const Key('shareReflectionSwitch'),
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    value: _shareReflection,
                                    onChanged: _saving
                                        ? null
                                        : (val) => setState(
                                            () => _shareReflection = val,
                                          ),
                                    title: Text(
                                      'Share reflection on '
                                      '$selectedHorseLabel’s logbook',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    subtitle: Text(
                                      _shareReflection
                                          ? 'Visible on $selectedHorseLabel’s '
                                                'shared logbook.'
                                          : 'Author-only — kept private to you '
                                                'unless shared.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTokens.secondaryTextColor(
                                              context,
                                            ),
                                          ),
                                    ),
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
                                if (_type != RiderLogType.care) ...[
                                  const Divider(height: 1),
                                  _feelSelector(context),
                                  _practicedSkillsSection(context),
                                ],
                              ]),
                              const SizedBox(height: 10),
                              _section(context, 'Session notes & takeaways', [
                                if (_student != null &&
                                    widget.initialSkill != null)
                                  ..._skillFields(context),
                                _field(
                                  context,
                                  _notes,
                                  'Notes',
                                  minLines: 3,
                                  maxLines: 7,
                                  validator: (text) {
                                    if ((text?.trim().isEmpty ?? true) &&
                                        !_hasStructuredContent) {
                                      return 'Enter a note.';
                                    }
                                    return null;
                                  },
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    key: const Key('toggleTakeawaysSection'),
                                    onPressed: () => setState(
                                      () => _takeawaysExpanded =
                                          !_takeawaysExpanded,
                                    ),
                                    icon: Icon(
                                      _takeawaysExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _takeawaysExpanded
                                          ? 'Hide structured takeaways & video'
                                          : 'Add takeaways, next steps, or video (optional)',
                                    ),
                                  ),
                                ),
                                if (_takeawaysExpanded) ...[
                                  _field(
                                    context,
                                    _highlights,
                                    'What went well (optional)',
                                    key: const Key('logEntryHighlights'),
                                    maxLines: 2,
                                  ),
                                  _field(
                                    context,
                                    _focus,
                                    'What needs work (optional)',
                                    key: const Key('logEntryFocus'),
                                    maxLines: 2,
                                  ),
                                  _field(
                                    context,
                                    _nextSteps,
                                    'Plans for next session (optional)',
                                    key: const Key('logEntryNextSteps'),
                                    maxLines: 3,
                                  ),
                                  _field(
                                    context,
                                    _title,
                                    'Title (optional)',
                                    key: const Key('logEntryTitle'),
                                    maxLength: 100,
                                  ),
                                  _field(
                                    context,
                                    _videoUrl,
                                    'Training video link (optional)',
                                    key: const Key('logEntryVideoUrl'),
                                    icon: Icons.ondemand_video_outlined,
                                    capitalizeSentences: false,
                                    keyboardType: TextInputType.url,
                                    validator: (text) {
                                      final raw = text?.trim() ?? '';
                                      if (raw.isEmpty) return null;
                                      final uri = Uri.tryParse(raw);
                                      if (uri == null ||
                                          !uri.hasAuthority ||
                                          (uri.scheme != 'https' &&
                                              uri.scheme != 'http')) {
                                        return 'Enter a valid http:// or https:// video link.';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTokens.spaceLg),
                      child: AppEmptyState(
                        icon: Icons.auto_stories_outlined,
                        title: 'Rider logbook unavailable',
                        description: 'Your rider logbook is unavailable.',
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _previousNextStepsBanner(
    BuildContext context,
    ({BaseListItem entry, String nextSteps}) hit,
    String horseLabel,
  ) {
    final theme = Theme.of(context);
    final accent = AppTokens.accentColor(context);
    final dateText = hit.entry.date == null
        ? null
        : DateFormat.MMMd().format(hit.entry.date!);
    final heading = dateText == null
        ? 'From last session with $horseLabel'
        : 'From last session with $horseLabel ($dateText)';

    return AppSurfaceCard(
      key: const Key('previousSessionNextStepsBanner'),
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag_outlined, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  heading,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  hit.nextSteps,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTokens.primaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feelSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text(
          'Session feel (optional)',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTokens.secondaryTextColor(context),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final feel in SessionFeel.values)
              ChoiceChip(
                key: Key('sessionFeel_${feel.name}'),
                visualDensity: VisualDensity.compact,
                label: Text(feel.label),
                selected: _feel == feel,
                onSelected: _saving
                    ? null
                    : (selected) =>
                          setState(() => _feel = selected ? feel : null),
              ),
          ],
        ),
      ],
    );
  }

  Widget _practicedSkillsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Practiced skills (optional)',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTokens.secondaryTextColor(context),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('addPracticedSkillsButton'),
              onPressed: _saving ? null : _pickPracticedSkills,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                _practicedSkills.isEmpty
                    ? 'Tag practiced skills'
                    : 'Edit skills (${_practicedSkills.length})',
              ),
            ),
          ],
        ),
        if (_practicedSkills.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in _practicedSkills)
                InputChip(
                  key: Key('taggedSkillChip_${tag.skillId}'),
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    tag.levelLabel == null
                        ? tag.skillName
                        : '${tag.skillName} · ${tag.levelLabel}',
                  ),
                  onDeleted: _saving
                      ? null
                      : () {
                          setState(() {
                            _practicedSkills = _practicedSkills
                                .where((s) => s.skillId != tag.skillId)
                                .toList();
                          });
                          _refreshLearningEligibility();
                        },
                ),
            ],
          ),
        if (_student == null && _eligibleLearningTags.isNotEmpty)
          CheckboxListTile(
            key: const Key('markPracticedAsLearningCheckbox'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _markPracticedAsLearning,
            onChanged: _saving
                ? null
                : (val) =>
                      setState(() => _markPracticedAsLearning = val ?? false),
            title: Text(
              _eligibleLearningTags.length == 1
                  ? 'Mark this skill as Learning?'
                  : 'Mark these practiced skills as Learning?',
            ),
            subtitle: Text(
              _eligibleLearningTags
                  .map(
                    (t) => t.levelLabel == null
                        ? t.skillName
                        : '${t.skillName} (${t.levelLabel})',
                  )
                  .join(', '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTokens.secondaryTextColor(context),
              ),
            ),
          ),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      AppSurfaceCard(
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Text(
              title,
              style: AppTokens.sectionTitleStyle(
                context,
              ).copyWith(fontSize: 18),
            ),
            ...children,
          ],
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
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      ),
                      foregroundColor: _type == entry.key
                          ? AppTokens.accentColor(context)
                          : AppTokens.primaryTextColor(context),
                      backgroundColor: _type == entry.key
                          ? AppTokens.accentColor(
                              context,
                            ).withValues(alpha: 0.16)
                          : Theme.of(context).brightness == Brightness.dark
                          ? AppTokens.midnightButtonFill
                          : colors.surface,
                      side: BorderSide(
                        color: _type == entry.key
                            ? AppTokens.accentColor(context)
                            : Theme.of(context).brightness == Brightness.dark
                            ? AppTokens.midnightButtonBorder
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
    ConnectionsState? connections,
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
    final activeConnections =
        connections ?? context.read<ConnectionsCubit?>()?.state;
    if (activeConnections != null) {
      final lowerEmail = rider.email.toLowerCase();
      for (final conn in activeConnections.connections) {
        if (conn.kind == 'horse' &&
            conn.status == 'accepted' &&
            conn.coach == lowerEmail &&
            conn.horseId != null &&
            conn.horseId!.isNotEmpty) {
          links.putIfAbsent(
            'horse:${conn.horseId}',
            () => conn.horseName ?? conn.horseId!,
          );
        }
      }
    }
    if (widget.initialHorse != null && !widget.initialHorse!.isArchived) {
      links.putIfAbsent(
        'horse:${widget.initialHorse!.id}',
        () => widget.initialHorse!.name,
      );
    }
    if (widget.horseConnection?.horseId != null) {
      final hId = widget.horseConnection!.horseId!;
      links.putIfAbsent(
        'horse:$hId',
        () => widget.horseConnection!.horseName ?? hId,
      );
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

  Widget _horseAndDateFields(
    RiderProfile rider,
    ConnectionsState? connections,
  ) {
    final repository =
        context.read<HorseProfileStore?>() ??
        context.read<HorseProfileRepository?>();
    if (_student != null || repository == null) {
      return _dateAndHorse(rider, connections: connections);
    }
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
    if (_activeStudentHorseIds == null) {
      return _dateAndHorse(rider, connections: connections);
    }
    return FutureBuilder<Set<String>>(
      future: _activeStudentHorseIds,
      builder: (context, snapshot) => _dateAndHorse(
        rider,
        activeStudentHorseIds: snapshot.data ?? {},
        connections: connections,
      ),
    );
  }

  Future<Set<String>> _loadActiveHorseIds(
    HorseProfileStore repository,
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
    ConnectionsState? connections,
  }) {
    final date = OutlinedButton.icon(
      key: const Key('logEntryDate'),
      onPressed: _saving ? null : _chooseDate,
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(_dateLabel(_date)),
    );
    final horses = _student == null
        ? _linkedHorses(
            rider,
            activeStudentHorseIds: activeStudentHorseIds,
            connections: connections,
          )
        : {..._studentHorses};
    if (_horseChoice.startsWith('horse:') &&
        !horses.containsKey(_horseChoice)) {
      horses[_horseChoice] =
          widget.entry?.riderLog?.horse ?? 'Previously linked horse';
    }
    final helperText = _type == RiderLogType.reflection
        ? 'Reflections stay private to you unless you choose to share.'
        : 'Selecting a linked horse shares this entry in its logbook.';
    final horse = DropdownButtonFormField<String>(
      key: ValueKey('logEntryHorse-${_student?.id ?? 'self'}'),
      initialValue: _horseChoice,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Horse (optional)',
        helperText: helperText,
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
          : (value) {
              setState(() {
                _horseChoice = value!;
                _selectedHorseName = horses[value];
              });
              _refreshHorseHistoryForNextSteps();
              _refreshLearningEligibility();
            },
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
    bool capitalizeSentences = true,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final borderColor = isDark
        ? AppTokens.midnightButtonBorder
        : colors.outlineVariant;
    return TextFormField(
      key: key,
      controller: controller,
      enabled: !_saving,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onChanged: onChanged,
      textCapitalization: capitalizeSentences
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon, size: 18),
        filled: true,
        fillColor: isDark ? AppTokens.midnightInputFill : colors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        counterText: maxLength == null ? null : '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          borderSide: BorderSide(
            color: AppTokens.accentColor(context),
            width: 1.5,
          ),
        ),
      ),
      validator:
          validator ??
          (required
              ? (text) => (text?.trim().isEmpty ?? true)
                    ? (controller == _notes
                          ? 'Enter a note.'
                          : 'Enter the horse name.')
                    : null
              : null),
    );
  }
}
