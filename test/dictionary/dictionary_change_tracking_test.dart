// ignore_for_file: lines_longer_than_80_chars

import 'package:authentication_repository/authentication_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_admin_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_diff.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_suggestion_dialog.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

import '../support/app_test_harness.dart';

class _RecordingRepo extends DictionaryRepository {
  _RecordingRepo(this.entries, {super.firestore});

  final List<DictionaryEntry> entries;
  final List<(String, Map<String, dynamic>)> calls = [];

  @override
  Future<List<DictionaryEntry>> load() async => entries;

  @override
  Future<void> call(String function, Map<String, dynamic> data) async {
    calls.add((function, data));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<DictionaryEntry> seedEntries;
  late AppTestHarness harness;

  setUp(() async {
    DictionaryRepository.invalidateCache();
    seedEntries = await DictionaryRepository.cachedEntries();
    harness = await AppTestHarness.create();
  });

  tearDown(() => harness.close());

  Widget wrap(Widget child) => BlocProvider<AppCubit>.value(
    value: harness.cubit,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: mainThemeDark,
      home: child,
    ),
  );

  void signInAsVerifiedAdmin() {
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        usersProfile: RiderProfile(
          id: 'admin',
          email: 'admin@example.com',
          name: 'Admin',
        ),
        user: const User(
          id: 'uid-admin',
          email: 'admin@example.com',
          name: 'Admin',
          isGuest: false,
          emailVerified: true,
          isAdmin: true,
        ),
      ),
    );
  }

  group('Word-level diff and structured field preservation', () {
    test('diffWords accurately distinguishes added, removed, and unchanged text', () {
      const original =
          'A three-beat gait faster than a trot and slower than a gallop.';
      const edited =
          'A balanced three-beat gait faster than a trot or jog and slower than a gallop.';

      final segments = diffWords(original, edited);
      expect(
        segments.where((s) => s.op == DiffOp.insert).map((s) => s.text.trim()),
        containsAll(['balanced', 'or jog']),
      );
      expect(
        segments.where((s) => s.op == DiffOp.delete),
        isEmpty,
      );
      expect(
        segments.where((s) => s.op == DiffOp.equal).map((s) => s.text).join(),
        contains('three-beat gait faster than a trot'),
      );

      final replacement = diffWords(
        'Limited experience in an arena.',
        'Growing confidence on trails.',
      );
      expect(replacement.any((s) => s.op == DiffOp.delete), isTrue);
      expect(replacement.any((s) => s.op == DiffOp.insert), isTrue);
      expect(replacement.any((s) => s.op == DiffOp.equal), isTrue);
    });

    test('applyChangedFieldsToEntry preserves all unchanged fields and concurrent edits to other fields', () {
      final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
      final base = DictionaryStructuredFields.fromEntry(canter);
      final proposed = DictionaryStructuredFields(
        definition: 'A cadenced three-beat gait with suspension.',
        explanation: base.explanation,
        usage: base.usage,
        regionalUsage: base.regionalUsage,
        examples: base.examples,
        synonyms: base.synonyms,
      );

      expect(proposed.changedKeysAgainst(base), ['definition']);

      // Suppose the live entry meanwhile had regionalUsage updated and keeps categories/skillIds.
      final liveData = <String, dynamic>{
        ...canter.data,
        'regionalUsage': 'Updated live regional usage that must not be overwritten.',
        'categories': const ['Gaits', 'Foundations'],
        'skillIds': const ['rider.mounted.canter'],
      };

      final merged = proposed.applyChangedFieldsToEntry(liveData, base: base);
      expect(merged['definition'], 'A cadenced three-beat gait with suspension.');
      expect(
        merged['regionalUsage'],
        'Updated live regional usage that must not be overwritten.',
      );
      expect(merged['explanation'], canter.explanation);
      expect(merged['categories'], ['Gaits', 'Foundations']);
      expect(merged['skillIds'], ['rider.mounted.canter']);
    });
  });

  group('Contributor experience (DictionarySuggestionDialog)', () {
    testWidgets(
      'existing entry pre-fills structured fields, shows current published definition, previews changes, uses Suggest an Improvement wording, and supports guest submission',
      (tester) async {
        tester.view.physicalSize = const Size(920, 960);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        harness.cubit.emit(harness.cubit.state.copyWith(isGuest: true));
        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
        final repo = _RecordingRepo(seedEntries);

        await tester.pumpWidget(
          wrap(
            Scaffold(
              body: DictionarySuggestionDialog(repository: repo, entry: canter),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Uses "Suggest an Improvement" instead of "Correction"
        expect(find.text('Suggest an Improvement · Canter'), findsOneWidget);
        expect(find.text('Correction'), findsNothing);

        // Displays current published definition card for reference
        expect(
          find.byKey(const Key('dictionaryCurrentPublishedCard')),
          findsOneWidget,
        );

        // Editable structured fields are pre-filled with published values
        final defField = tester.widget<TextFormField>(
          find.byKey(const Key('suggestionField_definition')),
        );
        expect(defField.controller!.text, canter.definition);

        final synonymsField = tester.widget<TextFormField>(
          find.byKey(const Key('suggestionField_synonyms')),
        );
        expect(synonymsField.controller!.text, contains('lope'));

        // Clicking Review Changes before editing shows helpful validation message
        await tester.tap(
          find.byKey(const Key('dictionaryReviewChangesButton')),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Edit at least one field before reviewing changes.'),
          findsOneWidget,
        );

        // Edit only the short definition and add a reason
        await tester.enterText(
          find.byKey(const Key('suggestionField_definition')),
          'A balanced three-beat gait with a moment of suspension, called lope in Western riding.',
        );
        await tester.enterText(
          find.byKey(const Key('suggestionReasonField')),
          'Highlights suspension and Western lope terminology right in the summary.',
        );

        // Open Review Changes step
        await tester.tap(
          find.byKey(const Key('dictionaryReviewChangesButton')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Review Changes · Canter'), findsOneWidget);
        expect(
          find.byKey(const Key('dictionaryReviewChangesView')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dictionaryDiffCard_definition')),
          findsOneWidget,
        );
        // Unchanged fields are NOT shown as modified and are explicitly preserved
        expect(
          find.byKey(const Key('dictionaryDiffCard_explanation')),
          findsNothing,
        );
        expect(
          find.textContaining('5 unchanged fields will remain'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Highlights suspension and Western lope'),
          findsOneWidget,
        );

        // Can return to editing and come back, or submit directly
        await tester.tap(
          find.byKey(const Key('dictionaryBackToEditingButton')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Suggest an Improvement · Canter'), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('dictionaryReviewChangesButton')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('dictionarySubmitSuggestionButton')),
        );
        await tester.pumpAndSettle();

        expect(repo.calls, hasLength(1));
        final submitted = repo.calls.single.$2;
        expect(submitted['termId'], 'canter');
        expect(submitted['baseRevision'], 0);
        expect(
          submitted['reason'],
          'Highlights suspension and Western lope terminology right in the summary.',
        );
        final proposedMap = submitted['proposedFields'] as Map<String, dynamic>;
        expect(
          proposedMap['definition'],
          'A balanced three-beat gait with a moment of suspension, called lope in Western riding.',
        );
        expect(proposedMap['explanation'], canter.explanation);
        // Guest account prompt remains available after submission
        expect(
          find.byKey(const Key('dictionaryCreateAccountButton')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'new term submission keeps empty form and replaces Correction label with Suggest an Improvement',
      (tester) async {
        final repo = _RecordingRepo(seedEntries);
        await tester.pumpWidget(
          wrap(Scaffold(body: DictionarySuggestionDialog(repository: repo))),
        );
        await tester.pumpAndSettle();

        expect(find.text('Contribute to the Dictionary'), findsOneWidget);
        expect(
          find.byKey(const Key('dictionaryCurrentPublishedCard')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('dictionaryReviewChangesButton')),
          findsNothing,
        );

        // Open dropdown to confirm "Suggest an Improvement" replaces "Correction"
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        expect(find.text('Suggest an Improvement'), findsWidgets);
        expect(find.text('Correction'), findsNothing);
      },
    );
  });

  group('Administrator Inbox diff review, proposal editing, and revision safety', () {
    testWidgets(
      'admin views highlighted diffs & contributor reason, edits proposal before approval, and incorporates only changed fields across mobile and desktop layouts',
      (tester) async {
        // Test responsive mobile layout first (390x850), then desktop (1180x900)
        tester.view.physicalSize = const Size(390, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        signInAsVerifiedAdmin();
        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
        final baseFields = DictionaryStructuredFields.fromEntry(canter);
        final proposedFields = DictionaryStructuredFields(
          definition:
              'A controlled three-beat gait faster than a trot and slower than a gallop.',
          explanation: baseFields.explanation,
          usage: baseFields.usage,
          regionalUsage: baseFields.regionalUsage,
          examples: baseFields.examples,
          synonyms: baseFields.synonyms,
        );

        final db = FakeFirebaseFirestore();
        await db.collection('DictionarySuggestions').doc('sug-edit-1').set({
          'term': 'Canter',
          'termId': 'canter',
          'kind': 'correction',
          'status': 'submitted',
          'proposal': proposedFields.summaryAgainst(
            baseFields,
            reason: 'Add clarity that canter is controlled.',
          ),
          'reason': 'Add clarity that canter is controlled.',
          'baseRevision': 0,
          'baseFields': baseFields.toMap(),
          'proposedFields': proposedFields.toMap(),
          'changedFields': ['definition'],
          'recognitionConsent': false,
          'createdAt': Timestamp.now(),
        });

        final repo = _RecordingRepo(seedEntries, firestore: db);
        await tester.pumpWidget(
          wrap(DictionaryAdminPage(firestore: db, repository: repo)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Badge says "Suggest an Improvement", not "correction"
        expect(find.text('Suggest an Improvement'), findsOneWidget);
        expect(find.text('correction'), findsNothing);
        // Diff card and contributor reason are rendered
        expect(
          find.byKey(const Key('dictionaryDiffCard_sug-edit-1_definition')),
          findsOneWidget,
        );
        expect(
          find.text('Add clarity that canter is controlled.'),
          findsOneWidget,
        );
        // No revision mismatch when published revision matches baseRevision (0 == 0)
        expect(
          find.byKey(const Key('suggestionRevisionMismatch_sug-edit-1')),
          findsNothing,
        );

        // Switch to desktop viewport and edit the proposal before approving
        tester.view.physicalSize = const Size(1180, 900);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final editProposalBtn = find.byKey(
          const Key('editProposalButton_sug-edit-1'),
        );
        await tester.ensureVisible(editProposalBtn);
        await tester.tap(editProposalBtn);
        await tester.pumpAndSettle();

        expect(find.text('Edit proposal · Canter'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('adminEditProposal_definition')),
          'A balanced, cadenced three-beat gait faster than a trot and slower than a gallop.',
        );
        await tester.enterText(
          find.byKey(const Key('adminEditProposal_note')),
          'Refined wording to balanced and cadenced.',
        );
        await tester.tap(find.byKey(const Key('saveAndApproveProposalButton')));
        await tester.pumpAndSettle();

        expect(repo.calls.last.$1, 'editDictionary');
        expect(repo.calls.last.$2['action'], 'review');
        expect(repo.calls.last.$2['status'], 'approved');
        expect(
          (repo.calls.last.$2['editedFields'] as Map)['definition'],
          'A balanced, cadenced three-beat gait faster than a trot and slower than a gallop.',
        );
      },
    );

    testWidgets(
      'concurrent revision mismatch warns administrator, shows old/current/proposed wording, and requires explicit confirmation before applying',
      (tester) async {
        tester.view.physicalSize = const Size(1180, 920);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        signInAsVerifiedAdmin();
        final greenStarter = DictionaryRepository.resolve(seedEntries, 'green')!;
        final contributorBase = DictionaryStructuredFields.fromEntry(
          greenStarter,
        );

        // Simulate live published definition having advanced to revision 2 while suggestion was pending!
        final updatedLiveGreen = DictionaryEntry({
          ...greenStarter.data,
          'revision': 2,
          'publishedAt': Timestamp.now(),
          'definition':
              'A horse or rider still building experience in a specific discipline or setting.',
          'regionalUsage':
              'Updated regional note preserved from revision 2.',
        });
        final liveEntries = [
          for (final e in seedEntries)
            if (e.id == 'green') updatedLiveGreen else e,
        ];

        final contributorProposed = DictionaryStructuredFields(
          definition:
              'A horse or rider with early-stage training in a particular task.',
          explanation: contributorBase.explanation,
          usage: contributorBase.usage,
          regionalUsage: contributorBase.regionalUsage,
          examples: contributorBase.examples,
          synonyms: contributorBase.synonyms,
        );

        final db = FakeFirebaseFirestore();
        await db.collection('DictionarySuggestions').doc('sug-stale-1').set({
          'term': 'Green',
          'termId': 'green',
          'kind': 'correction',
          'status': 'approved',
          'proposal': 'Suggested improvement to Short definition.',
          'reason': 'Specify task-specific early-stage training.',
          'baseRevision': 0,
          'baseFields': contributorBase.toMap(),
          'proposedFields': contributorProposed.toMap(),
          'changedFields': ['definition'],
          'recognitionConsent': false,
          'createdAt': Timestamp.now(),
        });

        final repo = _RecordingRepo(liveEntries, firestore: db);
        await tester.pumpWidget(
          wrap(DictionaryAdminPage(firestore: db, repository: repo)),
        );
        await tester.pumpAndSettle();

        // 1. Inbox displays clear revision mismatch warning + old, current, and proposed wording
        // for both the contributor-modified field (definition) and concurrently updated field (regionalUsage).
        expect(
          find.byKey(const Key('suggestionRevisionMismatch_sug-stale-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dictionaryDiffCard_sug-stale-1_definition')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dictionaryDiffCard_sug-stale-1_regionalUsage')),
          findsOneWidget,
        );
        expect(find.text('Old wording (rev 0)'), findsNWidgets(2));
        expect(find.text('Current published wording (rev 2)'), findsNWidgets(2));
        expect(find.text('Proposed wording'), findsNWidgets(2));

        // 2. Open Incorporate wording -> _EntryEditor shows mismatch banner & disables Publish until acknowledged
        final incorporateBtn = find.byKey(
          const Key('incorporateWording_sug-stale-1'),
        );
        await tester.ensureVisible(incorporateBtn);
        await tester.tap(incorporateBtn);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('editorRevisionMismatchWarning')),
          findsOneWidget,
        );

        // Unchanged field (regionalUsage) preserved the live rev 2 wording rather than reverting to rev 0!
        final regionalController = tester
            .widget<TextFormField>(
              find.byKey(const Key('dictionaryField_regionalUsage')),
            )
            .controller!;
        expect(
          regionalController.text,
          'Updated regional note preserved from revision 2.',
        );

        // Publish button is disabled before explicit confirmation
        final publishButtonBefore = tester.widget<FilledButton>(
          find.byKey(const Key('dictionaryPublishButton')),
        );
        expect(publishButtonBefore.onPressed, isNull);

        // Explicitly confirm review of old, current, and proposed wording
        final ackCheckbox = find.byKey(
          const Key('acknowledgeRevisionMismatchCheckbox'),
        );
        await tester.ensureVisible(ackCheckbox);
        await tester.tap(ackCheckbox);
        await tester.pumpAndSettle();

        final publishButtonAfter = find.byKey(
          const Key('dictionaryPublishButton'),
        );
        await tester.ensureVisible(publishButtonAfter);
        await tester.tap(publishButtonAfter);
        await tester.pumpAndSettle();

        expect(repo.calls.last.$1, 'editDictionary');
        expect(repo.calls.last.$2['action'], 'publish');
        expect(repo.calls.last.$2['expectedRevision'], 2);
        expect(repo.calls.last.$2['acknowledgeRevisionMismatch'], isTrue);
        expect(
          (repo.calls.last.$2['entry'] as Map)['regionalUsage'],
          'Updated regional note preserved from revision 2.',
        );
      },
    );
  });
}
