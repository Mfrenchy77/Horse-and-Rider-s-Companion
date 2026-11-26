// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/hero_header.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_media.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_profile_primary_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/primary_rider_view.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:photo_view/photo_view.dart';

import '../support/app_test_harness.dart';

class _StubDictionaryRepo extends DictionaryRepository {
  _StubDictionaryRepo(this.entries);

  final List<DictionaryEntry> entries;

  @override
  Future<Map<String, String>> skillLabels() async => {};

  @override
  Future<List<DictionaryEntry>> load() async => entries;
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

  Widget wrap(Widget child, {ThemeData? theme}) => BlocProvider<AppCubit>.value(
    value: harness.cubit,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme ?? mainThemeDark,
      home: child,
    ),
  );

  group('Shared HeroHeader across Dictionary and Profiles', () {
    testWidgets(
      'Dictionary entry with multiple images promotes first image to hero without duplicating it and preserves secondary images & links',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 960);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
        const primaryUrl =
            'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_public%2Fcanter%2Fprimary.png?alt=media&token=1';
        const secondaryUrl1 =
            'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_public%2Fcanter%2Fsecond.jpg?alt=media&token=2';
        const secondaryUrl2 =
            'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_public%2Fcanter%2Fthird.webp?alt=media&token=3';

        final enriched = DictionaryEntry({
          ...canter.data,
          'media': [
            {'url': primaryUrl, 'label': 'Primary footfall diagram'},
            {'url': secondaryUrl1, 'label': 'Secondary lead diagram'},
            {'url': secondaryUrl2, 'label': 'Third stride diagram'},
            {
              'url': 'https://example.com/biomechanics',
              'label': 'External biomechanics guide',
            },
          ],
        });

        await tester.pumpWidget(
          wrap(
            DictionaryPage(
              slug: 'canter',
              repository: _StubDictionaryRepo([enriched]),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Hero header uses shared HeroHeader with BoxFit.cover and black-to-transparent gradient.
        final heroFinder = find.byKey(const Key('dictionaryHeroHeader'));
        expect(heroFinder, findsOneWidget);
        final heroWidget = tester.widget<HeroHeader>(heroFinder);
        expect(heroWidget.imageUrl, primaryUrl);
        expect(heroWidget.imageFit, BoxFit.cover);

        final gradientBox = tester.widget<DecoratedBox>(
          find.byKey(const Key('heroHeaderGradientOverlay')),
        );
        final gradient =
            (gradientBox.decoration as BoxDecoration).gradient!
                as LinearGradient;
        expect(gradient.begin, Alignment.bottomCenter);
        expect(gradient.end, Alignment.topCenter);
        expect(gradient.colors.last, Colors.transparent);

        // Term and category badges appear in the hero overlay; definition directly below hero.
        expect(
          find.descendant(of: heroFinder, matching: find.text(enriched.term)),
          findsOneWidget,
        );
        for (final cat in enriched.strings('categories')) {
          expect(
            find.descendant(of: heroFinder, matching: find.text(cat)),
            findsOneWidget,
          );
        }
        final heroRect = tester.getRect(heroFinder);
        final defRect = tester.getRect(find.text(enriched.definition));
        expect(defRect.top, greaterThanOrEqualTo(heroRect.bottom));
        expect(find.byKey(const Key('dictionaryHeroCaption')), findsOneWidget);

        // Primary image URL is NOT duplicated in the Educational Media gallery.
        final allSmartImages = tester
            .widgetList<SmartImage>(find.byType(SmartImage))
            .map((w) => w.url)
            .toList();
        expect(allSmartImages.where((u) => u == primaryUrl), hasLength(1));
        expect(allSmartImages, containsAll([secondaryUrl1, secondaryUrl2]));
        expect(allSmartImages, hasLength(3));

        // Secondary gallery has only 2 images + 1 external link.
        expect(
          find.byKey(const Key('dictionaryInlineImage_0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dictionaryInlineImage_1')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('dictionaryInlineImage_2')), findsNothing);
        expect(find.text('External biomechanics guide'), findsOneWidget);
      },
    );

    testWidgets(
      'Dictionary entry with only one image hides Educational Media section when no secondary items exist',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
        final enriched = DictionaryEntry({
          ...canter.data,
          'media': [
            {
              'url':
                  'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_public%2Fcanter%2Fonly.png?alt=media&token=1',
              'label': 'Only image',
            },
          ],
        });

        await tester.pumpWidget(
          wrap(
            DictionaryPage(
              slug: 'canter',
              repository: _StubDictionaryRepo([enriched]),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SmartImage), findsOneWidget);
        expect(find.byType(DictionaryMediaGallery), findsNothing);
        expect(find.text('Educational media'), findsNothing);
      },
    );

    testWidgets(
      'tapping Dictionary hero image opens full-resolution PhotoView without Hero conflict',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
        final enriched = DictionaryEntry({
          ...canter.data,
          'media': [
            {
              'url':
                  'https://firebasestorage.googleapis.com/v0/b/demo/o/dictionary_public%2Fcanter%2Fzoom.png?alt=media&token=9',
              'label': 'Zoomable diagram',
            },
          ],
        });

        await tester.pumpWidget(
          wrap(
            DictionaryPage(
              slug: 'canter',
              repository: _StubDictionaryRepo([enriched]),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.byKey(const Key('dictionaryHeroTapTarget')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        final photoViewFinder = find.byType(PhotoView);
        expect(photoViewFinder, findsOneWidget);
        final photoView = tester.widget<PhotoView>(photoViewFinder);
        expect(photoView.heroAttributes, isNull);
      },
    );

    testWidgets(
      'Dictionary entry without images renders graceful fallback surface in dark and light themes',
      (tester) async {
        tester.view.physicalSize = const Size(900, 860);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;
        final noImageEntry = DictionaryEntry({
          ...canter.data,
          'media': const <Map<String, dynamic>>[],
        });

        for (final theme in [mainThemeDark, mainThemeLight]) {
          await tester.pumpWidget(
            wrap(
              DictionaryPage(
                slug: 'canter',
                repository: _StubDictionaryRepo([noImageEntry]),
              ),
              theme: theme,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 100));

          expect(
            find.byKey(const Key('heroHeaderFallbackSurface')),
            findsOneWidget,
          );
          expect(find.byType(SmartImage), findsNothing);
          expect(
            find.byKey(const Key('dictionaryHeroTapTarget')),
            findsNothing,
          );
          expect(find.text(noImageEntry.term), findsOneWidget);
          expect(find.text(noImageEntry.definition), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Dictionary app bar uses AppTitle wordmark on wide screens and compact horse-shield logo on narrow screens',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1;

        final canter = DictionaryRepository.resolve(seedEntries, 'canter')!;

        // Wide screen -> full AppTitle wordmark.
        tester.view.physicalSize = const Size(1024, 800);
        await tester.pumpWidget(
          wrap(
            DictionaryPage(
              slug: 'canter',
              repository: _StubDictionaryRepo([canter]),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(AppTitle), findsOneWidget);
        expect(
          find.byKey(const Key('dictionaryAppBarWordmark')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dictionaryAppBarCompactLogo')),
          findsNothing,
        );
        expect(find.byType(BackButton), findsOneWidget);

        // Narrow screen -> compact horse-shield logo.
        tester.view.physicalSize = const Size(360, 800);
        await tester.pumpWidget(
          wrap(
            DictionaryPage(
              slug: 'canter',
              repository: _StubDictionaryRepo([canter]),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.byKey(const Key('dictionaryAppBarCompactLogo')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('dictionaryAppBarWordmark')), findsNothing);
        expect(find.byType(BackButton), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Horse and Rider profile headers use shared HeroHeader with black-to-transparent gradient and tap-to-zoom',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final rider = RiderProfile(
          id: 'matt@example.com',
          email: 'matt@example.com',
          name: 'Matt French',
          locationName: 'La Mesa, California',
          isTrainer: true,
          picUrl: 'https://example.com/rider.jpg',
        );
        final horse = HorseProfile(
          id: 'valero',
          name: 'Valero',
          locationName: 'La Mesa, California',
          currentOwnerId: rider.email,
          currentOwnerName: rider.name,
          picUrl: 'https://example.com/valero.jpg',
          isPublic: true,
        );

        harness.cubit.emit(
          harness.cubit.state.copyWith(
            isGuest: false,
            usersProfile: rider,
            horseProfile: horse,
          ),
        );

        // Rider profile uses HeroHeader.
        await tester.pumpWidget(
          wrap(
            Scaffold(
              body: SingleChildScrollView(
                child: PrimaryRiderView(profile: rider, includeLists: false),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(HeroHeader), findsOneWidget);
        expect(
          find.byKey(const Key('heroHeaderGradientOverlay')),
          findsOneWidget,
        );
        expect(find.text('Matt French'), findsOneWidget);
        expect(find.text('Professional Trainer'), findsOneWidget);
        expect(find.text('La Mesa, California'), findsOneWidget);

        // Tapping rider cover opens PhotoView.
        await tester.tap(find.byKey(const Key('riderCoverPhoto')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(PhotoView), findsOneWidget);

        // Close viewer and verify Horse profile uses HeroHeader too.
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        await tester.pumpWidget(
          wrap(
            Scaffold(
              body: SingleChildScrollView(
                child: HorseProfilePrimaryView(horseProfile: horse),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(HeroHeader), findsOneWidget);
        expect(
          find.byKey(const Key('heroHeaderGradientOverlay')),
          findsOneWidget,
        );
        expect(find.text('Valero'), findsOneWidget);
        expect(find.byKey(const Key('horseCoverPhoto')), findsOneWidget);
      },
    );
  });
}
