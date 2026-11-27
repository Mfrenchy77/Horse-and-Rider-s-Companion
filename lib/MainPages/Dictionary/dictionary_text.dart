import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_matcher.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_media.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/known_terms_repository.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

export 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_matcher.dart';

void _openFullDefinition(BuildContext context, DictionaryEntry entry) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    router.push('/Dictionary/${entry.slug}');
    return;
  }
  Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(builder: (_) => DictionaryPage(slug: entry.slug)),
  );
}

void _openDictionarySearch(BuildContext context, String query) {
  final encoded = Uri.encodeQueryComponent(query);
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    router.push('/Dictionary?q=$encoded');
    return;
  }
  Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => DictionaryPage(initialQuery: query),
    ),
  );
}

const Duration _kDefinitionDialogEnterDuration = Duration(milliseconds: 320);
const Duration _kDefinitionDialogExitDuration = Duration(milliseconds: 240);

Rect? _overlayRectForRenderBox(RenderBox box, RenderBox overlayBox) {
  if (!box.attached || !box.hasSize || box.size.isEmpty) return null;
  if (!overlayBox.attached || !overlayBox.hasSize || overlayBox.size.isEmpty) {
    return null;
  }
  final topLeft = overlayBox.globalToLocal(box.localToGlobal(Offset.zero));
  final rect = topLeft & box.size;
  if (!rect.left.isFinite ||
      !rect.top.isFinite ||
      !rect.width.isFinite ||
      !rect.height.isFinite) {
    return null;
  }
  final overlayRect = Offset.zero & overlayBox.size;
  return overlayRect.overlaps(rect) ? rect : null;
}

Rect? _resolveOriginRectInOverlay(
  BuildContext originContext,
  NavigatorState navigator,
) {
  if (!originContext.mounted) return null;
  final renderObject = originContext.findRenderObject();
  final overlayObject = navigator.overlay?.context.findRenderObject();
  if (renderObject is! RenderBox || overlayObject is! RenderBox) return null;
  final rect = _overlayRectForRenderBox(renderObject, overlayObject);
  if (rect == null) return null;

  final scrollable = Scrollable.maybeOf(originContext);
  if (scrollable != null && scrollable.mounted) {
    final scrollObject = scrollable.context.findRenderObject();
    if (scrollObject is RenderBox &&
        scrollObject.attached &&
        scrollObject.hasSize) {
      final scrollTopLeft = overlayObject.globalToLocal(
        scrollObject.localToGlobal(Offset.zero),
      );
      final scrollRect = scrollTopLeft & scrollObject.size;
      if (!scrollRect.overlaps(rect)) return null;
    }
  }
  return rect;
}

Rect? _convertGlobalRectToOverlay(Rect globalRect, NavigatorState navigator) {
  if (globalRect.isEmpty) return null;
  final overlayObject = navigator.overlay?.context.findRenderObject();
  if (overlayObject is! RenderBox ||
      !overlayObject.attached ||
      !overlayObject.hasSize ||
      overlayObject.size.isEmpty) {
    return null;
  }
  final localTopLeft = overlayObject.globalToLocal(globalRect.topLeft);
  final rect = localTopLeft & globalRect.size;
  if (!rect.left.isFinite ||
      !rect.top.isFinite ||
      !rect.width.isFinite ||
      !rect.height.isFinite) {
    return null;
  }
  final overlayRect = Offset.zero & overlayObject.size;
  return overlayRect.overlaps(rect) ? rect : null;
}

/// Opens a compact glass dialog showing a published Dictionary [entry] without
/// navigating away from the current screen.
Future<void> showDictionaryDefinitionDialog(
  BuildContext context,
  DictionaryEntry entry, {
  BuildContext? originContext,
  Rect? originRect,
  KnownTermsRepository? knownTermsRepository,
}) {
  final synonyms = entry.strings('synonyms');
  final categories = entry.strings('categories');
  final heroMedia = firstPublishedDictionaryImage(entry);
  final navigator = Navigator.of(context, rootNavigator: true);
  final knownRepo = knownTermsRepository ?? KnownTermsRepository.instance;
  unawaited(knownRepo.ensureLoaded());
  final localOriginRect = originRect == null
      ? null
      : _convertGlobalRectToOverlay(originRect, navigator);
  final resolveOriginRect = originContext != null
      ? () => _resolveOriginRectInOverlay(originContext, navigator)
      : null;

  return showAppGlassDialog<void>(
    context: context,
    originRect: localOriginRect,
    resolveOriginRect: resolveOriginRect,
    transitionDuration: _kDefinitionDialogEnterDuration,
    reverseTransitionDuration: _kDefinitionDialogExitDuration,
    builder: (dialogContext) {
      final screenSize = MediaQuery.sizeOf(dialogContext);
      final imageHeight = (screenSize.width < 400 || screenSize.height < 640)
          ? 160.0
          : 184.0;
      return AppGlassDialog(
        key: const Key('dictionaryDefinitionDialog'),
        maxWidth: 460,
        title: Text(
          entry.term,
          style: AppTokens.sectionTitleStyle(dialogContext),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            if (heroMedia != null) ...[
              RepaintBoundary(
                child: ClipRRect(
                  key: const Key('dictionaryDefinitionDialogImageContainer'),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  child: Material(
                    color: Theme.of(
                      dialogContext,
                    ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
                    child: InkWell(
                      key: const Key('dictionaryDefinitionDialogImageTap'),
                      onTap: () => showProfilePhoto(
                        dialogContext,
                        heroMedia.url,
                        heroTag: 'dictionary-def-dialog-${entry.id}',
                        caption: heroMedia.label.isEmpty
                            ? entry.term
                            : heroMedia.label,
                        explanation: heroMedia.explanation.isEmpty
                            ? null
                            : heroMedia.explanation,
                        imageTypeLabel: heroMedia.imageType.label,
                        attribution: heroMedia.attribution,
                      ),
                      child: Semantics(
                        button: true,
                        label: heroMedia.label.isNotEmpty
                            ? '${heroMedia.label}. '
                                  'Tap to view full illustration.'
                            : 'Illustration for ${entry.term}. '
                                  'Tap to view larger.',
                        child: SizedBox(
                          width: double.infinity,
                          height: imageHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              SmartImage(
                                heroMedia.url,
                                key: const Key(
                                  'dictionaryDefinitionDialogImage',
                                ),
                                width: double.infinity,
                                height: imageHeight,
                                maxLogicalWidth: 460,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.zoom_in,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (heroMedia.label.isNotEmpty)
                Text(
                  heroMedia.label,
                  key: const Key('dictionaryDefinitionDialogImageCaption'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: AppTokens.secondaryTextColor(dialogContext),
                  ),
                ),
            ],
            if (categories.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final cat in categories)
                    AppStatusBadge(label: cat, tone: AppStatusTone.info),
                ],
              ),
            Text(
              entry.definition,
              style: Theme.of(dialogContext).textTheme.bodyLarge,
            ),
            if (synonyms.isNotEmpty)
              Text(
                'Also called: ${synonyms.join(' · ')}',
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  color: AppTokens.secondaryTextColor(dialogContext),
                ),
              ),
            const Divider(height: 8),
            _KnownTermCheckbox(entryId: entry.id, repository: knownRepo),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.menu_book_outlined, size: 16),
            onPressed: () {
              Navigator.pop(dialogContext);
              _openFullDefinition(context, entry);
            },
            label: const Text('View full definition'),
          ),
        ],
      );
    },
  );
}

/// Looks up [selectedText] against published [entries] and shows a compact
/// definition dialog, a multi-meaning chooser if ambiguous, or a
/// non-disruptive not-found dialog.
Future<void> showSelectedTermDefinition(
  BuildContext context, {
  required String selectedText,
  required List<DictionaryEntry> entries,
  Rect? originRect,
  KnownTermsRepository? knownTermsRepository,
}) {
  final result = lookupSelectedDictionaryTerm(selectedText, entries);
  if (result.exactMatch case final match?) {
    return showDictionaryDefinitionDialog(
      context,
      match,
      originRect: originRect,
      knownTermsRepository: knownTermsRepository,
    );
  }
  final navigator = Navigator.of(context, rootNavigator: true);
  final localOriginRect = originRect == null
      ? null
      : _convertGlobalRectToOverlay(originRect, navigator);
  if (result.ambiguousMatches.isNotEmpty) {
    return showAppGlassDialog<void>(
      context: context,
      originRect: localOriginRect,
      transitionDuration: _kDefinitionDialogEnterDuration,
      reverseTransitionDuration: _kDefinitionDialogExitDuration,
      builder: (dialogContext) => AppGlassDialog(
        key: const Key('dictionaryAmbiguousDialog'),
        maxWidth: 480,
        title: Text(
          result.normalizedQuery,
          style: AppTokens.sectionTitleStyle(dialogContext),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(
              'This term has multiple published meanings:',
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                color: AppTokens.secondaryTextColor(dialogContext),
              ),
            ),
            for (final entry in result.ambiguousMatches)
              AppSurfaceCard(
                padding: const EdgeInsets.all(AppTokens.spaceSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          entry.term,
                          style: Theme.of(dialogContext).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        for (final cat in entry.strings('categories'))
                          AppStatusBadge(label: cat, tone: AppStatusTone.info),
                      ],
                    ),
                    Text(
                      entry.definition,
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.menu_book_outlined, size: 15),
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _openFullDefinition(context, entry);
                        },
                        label: const Text('View full definition'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  final displayQuery = result.normalizedQuery.isEmpty
      ? selectedText.trim()
      : result.normalizedQuery;
  return showAppGlassDialog<void>(
    context: context,
    originRect: localOriginRect,
    transitionDuration: _kDefinitionDialogEnterDuration,
    reverseTransitionDuration: _kDefinitionDialogExitDuration,
    builder: (dialogContext) => AppGlassDialog(
      key: const Key('dictionaryNoDefinitionDialog'),
      maxWidth: 420,
      title: Text(
        'No definition found',
        style: AppTokens.sectionTitleStyle(dialogContext),
      ),
      content: Text(
        displayQuery.isEmpty
            ? 'Select a word or phrase to look it up in the Equestrian '
                  'Dictionary.'
            : 'No published Dictionary entry was found for "$displayQuery".',
        style: Theme.of(dialogContext).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
        if (displayQuery.isNotEmpty)
          FilledButton.tonalIcon(
            icon: const Icon(Icons.search, size: 16),
            onPressed: () {
              Navigator.pop(dialogContext);
              _openDictionarySearch(context, displayQuery);
            },
            label: const Text('Search Dictionary'),
          ),
      ],
    ),
  );
}

class _KnownTermCheckbox extends StatelessWidget {
  const _KnownTermCheckbox({required this.entryId, required this.repository});

  final String entryId;
  final KnownTermsRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppTokens.accentColor(context);

    return ListenableBuilder(
      listenable: repository,
      builder: (context, _) {
        final isKnown = repository.isKnown(entryId);
        return Semantics(
          container: true,
          checked: isKnown,
          label: 'I know this term — stop highlighting it',
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: const Key('dictionaryKnownTermTapTarget'),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              onTap: () => unawaited(repository.toggleKnown(entryId)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          key: const Key('dictionaryKnownTermCheckbox'),
                          value: isKnown,
                          activeColor: accent,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: (_) =>
                              unawaited(repository.toggleKnown(entryId)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'I know this term — stop highlighting it',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Known terms appear as ordinary text. You can '
                              'change this anytime.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTokens.secondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Renders [text] with:
/// 1. Subtle, accessible inline Dictionary highlights for recognized published
///    terms (tapping opens a compact definition dialog without leaving the
///    screen).
/// 2. Optional manual text selection with a "Define" action in the platform
///    selection toolbar alongside standard Copy / Select All actions.
class DictionaryText extends StatefulWidget {
  const DictionaryText({
    super.key,
    required this.text,
    required this.entries,
    this.style,
    this.enableSelection = true,
    this.maxMatches = 6,
    this.excludeEntryId,
    this.knownTermsRepository,
    this.knownTermIdsOverride,
  });

  final String text;
  final List<DictionaryEntry> entries;
  final TextStyle? style;
  final bool enableSelection;
  final int maxMatches;
  final String? excludeEntryId;
  final KnownTermsRepository? knownTermsRepository;
  final Set<String>? knownTermIdsOverride;

  @override
  State<DictionaryText> createState() => _DictionaryTextState();
}

class _DictionaryTextState extends State<DictionaryText> {
  late KnownTermsRepository _knownRepo;
  late List<DictionaryMatch> _matches;
  String _selectedText = '';

  Set<String> get _effectiveKnownIds =>
      widget.knownTermIdsOverride ?? _knownRepo.getKnownTerms();

  List<DictionaryMatch> _computeMatches() => matchDictionaryTerms(
    widget.text,
    widget.entries,
    maxMatches: widget.maxMatches,
    excludeEntryId: widget.excludeEntryId,
    knownTermIds: _effectiveKnownIds,
  );

  bool _matchesEqual(List<DictionaryMatch> a, List<DictionaryMatch> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].start != b[i].start ||
          a[i].end != b[i].end ||
          a[i].entry.id != b[i].entry.id) {
        return false;
      }
    }
    return true;
  }

  void _handleKnownTermsChanged() {
    if (!mounted || widget.knownTermIdsOverride != null) return;
    final next = _computeMatches();
    if (!_matchesEqual(_matches, next)) {
      setState(() => _matches = next);
    }
  }

  @override
  void initState() {
    super.initState();
    _knownRepo = widget.knownTermsRepository ?? KnownTermsRepository.instance;
    if (widget.knownTermIdsOverride == null) {
      _knownRepo.addListener(_handleKnownTermsChanged);
      unawaited(_knownRepo.ensureLoaded());
    }
    _matches = _computeMatches();
  }

  @override
  void didUpdateWidget(covariant DictionaryText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextRepo =
        widget.knownTermsRepository ?? KnownTermsRepository.instance;
    final wasListening = oldWidget.knownTermIdsOverride == null;
    final shouldListen = widget.knownTermIdsOverride == null;
    if (wasListening && (!shouldListen || !identical(nextRepo, _knownRepo))) {
      _knownRepo.removeListener(_handleKnownTermsChanged);
    }
    _knownRepo = nextRepo;
    if (shouldListen &&
        (!wasListening ||
            !identical(
              nextRepo,
              oldWidget.knownTermsRepository ?? KnownTermsRepository.instance,
            ))) {
      _knownRepo.addListener(_handleKnownTermsChanged);
      unawaited(_knownRepo.ensureLoaded());
    }

    if (oldWidget.text != widget.text ||
        !identical(oldWidget.entries, widget.entries) ||
        oldWidget.maxMatches != widget.maxMatches ||
        oldWidget.excludeEntryId != widget.excludeEntryId ||
        widget.knownTermIdsOverride != oldWidget.knownTermIdsOverride ||
        !identical(
          nextRepo,
          oldWidget.knownTermsRepository ?? KnownTermsRepository.instance,
        )) {
      _matches = _computeMatches();
    }
  }

  @override
  void dispose() {
    _knownRepo.removeListener(_handleKnownTermsChanged);
    super.dispose();
  }

  Widget _buildContent(BuildContext context) {
    if (_matches.isEmpty) {
      return Text(widget.text, style: widget.style);
    }
    final effectiveStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final accent = AppTokens.accentColor(context);
    final spans = <InlineSpan>[];
    var offset = 0;
    for (final match in _matches) {
      if (match.start > offset) {
        spans.add(TextSpan(text: widget.text.substring(offset, match.start)));
      }
      final matchedWord = widget.text.substring(match.start, match.end);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Builder(
            builder: (termContext) => Semantics(
              button: true,
              label: '$matchedWord, open dictionary definition',
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  minimumSize: const Size(0, 22),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  foregroundColor: accent,
                ),
                onPressed: () => showDictionaryDefinitionDialog(
                  context,
                  match.entry,
                  originContext: termContext,
                  knownTermsRepository: _knownRepo,
                ),
                child: Text(
                  matchedWord,
                  style: effectiveStyle.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.solid,
                    decorationColor: accent,
                    decorationThickness: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      offset = match.end;
    }
    if (offset < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(offset)));
    }
    return Text.rich(TextSpan(style: effectiveStyle, children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (!widget.enableSelection) {
      return content;
    }
    return SelectionArea(
      onSelectionChanged: (SelectedContent? selection) {
        _selectedText = selection?.plainText ?? '';
      },
      contextMenuBuilder: (menuContext, selectableRegionState) {
        final buttonItems = List<ContextMenuButtonItem>.of(
          selectableRegionState.contextMenuButtonItems,
        );
        final selected = _selectedText.trim();
        if (selected.isNotEmpty) {
          final anchor = selectableRegionState.contextMenuAnchors.primaryAnchor;
          buttonItems.insert(
            0,
            ContextMenuButtonItem(
              label: 'Define',
              onPressed: () {
                ContextMenuController.removeAny();
                selectableRegionState.clearSelection();
                showSelectedTermDefinition(
                  context,
                  selectedText: selected,
                  entries: widget.entries,
                  originRect: Rect.fromCenter(
                    center: anchor,
                    width: 72,
                    height: 24,
                  ),
                  knownTermsRepository: _knownRepo,
                );
              },
            ),
          );
        }
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: selectableRegionState.contextMenuAnchors,
          buttonItems: buttonItems,
        );
      },
      child: content,
    );
  }
}

/// Renders [text] with subtle inline Dictionary popovers and manual "Define"
/// text selection using the cached published glossary, falling back gracefully
/// while loading or when no unambiguous terms appear.
class ContextualDictionaryText extends StatefulWidget {
  const ContextualDictionaryText({
    super.key,
    required this.text,
    this.style,
    this.entriesOverride,
    this.enableSelection = true,
    this.maxMatches = 6,
    this.knownTermsRepository,
  });

  final String text;
  final TextStyle? style;
  final List<DictionaryEntry>? entriesOverride;
  final bool enableSelection;
  final int maxMatches;
  final KnownTermsRepository? knownTermsRepository;

  @override
  State<ContextualDictionaryText> createState() =>
      _ContextualDictionaryTextState();
}

class _ContextualDictionaryTextState extends State<ContextualDictionaryText> {
  @override
  void initState() {
    super.initState();
    if (widget.entriesOverride == null) {
      unawaited(DictionaryRepository.cachedEntries());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entriesOverride case final overrideEntries?) {
      return DictionaryText(
        text: widget.text,
        entries: overrideEntries,
        style: widget.style,
        enableSelection: widget.enableSelection,
        maxMatches: widget.maxMatches,
        knownTermsRepository: widget.knownTermsRepository,
      );
    }
    return ValueListenableBuilder<List<DictionaryEntry>?>(
      valueListenable: DictionaryRepository.entriesNotifier,
      builder: (context, entries, _) => DictionaryText(
        text: widget.text,
        entries: entries ?? const <DictionaryEntry>[],
        style: widget.style,
        enableSelection: widget.enableSelection,
        maxMatches: widget.maxMatches,
        knownTermsRepository: widget.knownTermsRepository,
      ),
    );
  }
}
