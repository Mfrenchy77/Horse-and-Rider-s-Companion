import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/adaptive_app_bar_actions.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_admin_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_media.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_suggestion_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_text.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/share_helper.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({
    super.key,
    this.slug,
    this.initialQuery = '',
    this.repository,
  });
  static const path = '/Dictionary';
  final String? slug;
  final String initialQuery;
  final DictionaryRepository? repository;

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  late final repository = widget.repository ?? DictionaryRepository();
  late Future<List<DictionaryEntry>> _entries = _load();
  Map<String, String> _skillLabels = {};

  Future<List<DictionaryEntry>> _load() async {
    try {
      _skillLabels = await repository.skillLabels();
    } catch (_) {
      _skillLabels = {};
    }
    return repository.load();
  }

  late final _search = TextEditingController(text: widget.initialQuery);
  String? _category;
  String? _letter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _suggest(DictionaryEntry? entry) => showAppGlassDialog<void>(
    context: context,
    builder: (_) =>
        DictionarySuggestionDialog(repository: repository, entry: entry),
  );

  String? _matchedSynonym(DictionaryEntry entry, String rawQuery) {
    final needle = rawQuery.trim().toLowerCase();
    if (needle.isEmpty || entry.term.toLowerCase().contains(needle)) {
      return null;
    }
    for (final syn in entry.strings('synonyms')) {
      if (syn.toLowerCase().contains(needle)) return syn;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.select((AppCubit cubit) => cubit.state.isAdmin);
    return FutureBuilder<List<DictionaryEntry>>(
      future: _entries,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        final entry = widget.slug == null
            ? null
            : DictionaryRepository.resolve(entries, widget.slug!);
        return Scaffold(
          appBar: ThemedAppBar(
            centerTitle: true,
            title: const AppTitle(),
            leading: BackButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(
                    widget.slug == null ? ProfilePage.path : '/Dictionary',
                  );
                }
              },
            ),
            actions: [
              AdaptiveAppBarActions(
                actions: [
                  AdaptiveAppBarAction(
                    label: 'Suggest a term',
                    icon: Icons.add_comment_outlined,
                    priority: 2,
                    onPressed: () => _suggest(entry),
                  ),
                  if (entry != null)
                    AdaptiveAppBarAction(
                      label: 'Share definition',
                      icon: Icons.share_outlined,
                      priority: 3,
                      onPressed: () => shareAppLink(
                        context,
                        title: entry.term,
                        dialogTitle: 'Share definition',
                        url: '${resolveShareOrigin()}/Dictionary/${entry.slug}',
                        text: entry.definition,
                      ),
                    ),
                  if (admin)
                    AdaptiveAppBarAction(
                      label: 'Review Dictionary',
                      icon: Icons.fact_check_outlined,
                      onPressed: () => context.push(DictionaryAdminPage.path),
                    ),
                ],
              ),
            ],
          ),
          body: SizedBox.expand(
            child: AppScaffoldBackdrop(
              child: snapshot.hasError
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.spaceLg),
                        child: AppEmptyState(
                          icon: Icons.error_outline,
                          title: 'Could not load the Dictionary.',
                          description:
                              'Check your connection and try loading the '
                              'glossary again.',
                          actionLabel: 'Try again',
                          onAction: () => setState(() => _entries = _load()),
                        ),
                      ),
                    )
                  : snapshot.connectionState != ConnectionState.done
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTokens.spaceMd),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: widget.slug != null
                              ? entry == null
                                    ? AppSurfaceCard(
                                        child: Column(
                                          spacing: 8,
                                          children: [
                                            const Text(
                                              'This definition is unavailable.',
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  context.go('/Dictionary'),
                                              child: const Text(
                                                'Browse the Dictionary',
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : _detail(entry, entries)
                              : _browse(entries),
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _browse(List<DictionaryEntry> entries) {
    final categories =
        entries.expand((entry) => entry.strings('categories')).toSet().toList()
          ..sort();
    final matches = DictionaryRepository.search(
      entries,
      query: _search.text,
      category: _category,
      letter: _letter,
    );
    final hasFilters =
        _search.text.trim().isNotEmpty || _category != null || _letter != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Equestrian words, explained',
                style: AppTokens.sectionTitleStyle(context),
              ),
              const SizedBox(height: 4),
              Text(
                'Plain-language horsemanship definitions across English, '
                'Western, trail, ranch, driving, and groundwork — free for '
                'everyone.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() => _letter = null),
                decoration: InputDecoration(
                  labelText: 'Search terms and alternate names',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(_search.clear),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('All categories'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  for (final category in categories)
                    ChoiceChip(
                      key: Key('dictionaryCategory_$category'),
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (sel) =>
                          setState(() => _category = sel ? category : null),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  AppSelectionHighlight(
                    selected: _letter == null,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(36, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => setState(() => _letter = null),
                      child: const Text('All'),
                    ),
                  ),
                  for (final code in List.generate(26, (i) => i + 65))
                    AppSelectionHighlight(
                      selected: _letter == String.fromCharCode(code),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: () =>
                            setState(() => _letter = String.fromCharCode(code)),
                        child: Text(String.fromCharCode(code)),
                      ),
                    ),
                ],
              ),
              if (hasFilters) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _search.clear();
                      _category = null;
                      _letter = null;
                    }),
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                    label: Text(
                      'Clear filters (${matches.length} '
                      '${matches.length == 1 ? 'term' : 'terms'})',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (matches.isEmpty)
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                const Text(
                  'No matching terms. Try another search or suggest a term.',
                ),
                OutlinedButton.icon(
                  onPressed: () => _suggest(null),
                  icon: const Icon(Icons.add_comment_outlined, size: 18),
                  label: const Text('Suggest this term'),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumn = constraints.maxWidth >= 720;
              if (!twoColumn) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in matches) ...[
                      _termCard(entry),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }
              final cardWidth = (constraints.maxWidth - 12) / 2;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final entry in matches)
                      SizedBox(width: cardWidth, child: _termCard(entry)),
                  ],
                ),
              );
            },
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _suggest(null),
            icon: const Icon(Icons.add),
            label: const Text('Suggest a term'),
          ),
        ),
      ],
    );
  }

  Widget _termCard(DictionaryEntry entry) {
    final matchedSyn = _matchedSynonym(entry, _search.text);
    final categories = entry.strings('categories');
    final synonyms = entry.strings('synonyms');
    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        onTap: () => context.push('/Dictionary/${entry.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          entry.term,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (matchedSyn != null)
                          AppStatusBadge(
                            label: 'Also called: $matchedSyn',
                            tone: AppStatusTone.coral,
                          ),
                        for (final cat in categories)
                          AppStatusBadge(label: cat, tone: AppStatusTone.info),
                      ],
                    ),
                    Text(
                      entry.definition,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (synonyms.isNotEmpty && matchedSyn == null)
                      Text(
                        'Also called: ${synonyms.join(' · ')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTokens.secondaryTextColor(context),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppTokens.secondaryTextColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(DictionaryEntry entry, List<DictionaryEntry> entries) {
    final app = context.read<AppCubit>().state;
    final categories = entry.strings('categories');
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (categories.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final cat in categories)
                  AppStatusBadge(label: cat, tone: AppStatusTone.info),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Text(entry.term, style: AppTokens.heroTitleStyle(context)),
          const SizedBox(height: 12),
          Text(
            entry.definition,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (entry.strings('synonyms').isNotEmpty)
            _section(
              'Also called',
              Text(entry.strings('synonyms').join(' · ')),
            ),
          if (entry.explanation.isNotEmpty)
            _section(
              'In context',
              DictionaryText(
                text: entry.explanation,
                entries: entries
                    .where((other) => other.id != entry.id)
                    .toList(),
              ),
            ),
          if (entry.text('usage').isNotEmpty)
            _section('Usage', Text(entry.text('usage'))),
          if (entry.text('regionalUsage').isNotEmpty)
            _section('Regional variations', Text(entry.text('regionalUsage'))),
          if (entry.strings('examples').isNotEmpty)
            _section('Examples', Text(entry.strings('examples').join('\n\n'))),
          if (entry.strings('relatedTerms').isNotEmpty)
            _section(
              'Related terminology',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in entry.strings('relatedTerms'))
                    if (DictionaryRepository.resolve(entries, id)
                        case final related?)
                      ActionChip(
                        label: Text(related.term),
                        onPressed: () =>
                            context.push('/Dictionary/${related.slug}'),
                      ),
                ],
              ),
            ),
          if (entry.strings('skillIds').isNotEmpty)
            _section(
              'Related skills',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in entry.strings('skillIds'))
                    ActionChip(
                      avatar: const Icon(Icons.account_tree_outlined, size: 16),
                      label: Text(
                        app.allSkills
                                .where((skill) => skill?.id == id)
                                .firstOrNull
                                ?.skillName ??
                            _skillLabels[id] ??
                            'Explore related skill',
                      ),
                      onPressed: () =>
                          SkillTreeView.openSkill(GoRouter.of(context), id),
                    ),
                ],
              ),
            ),
          if (entry.strings('resourceIds').isNotEmpty)
            _section(
              'Related Resources',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final id in entry.strings('resourceIds'))
                    TextButton(
                      onPressed: () => context.push(
                        '/Resources/Comments/${Uri.encodeComponent(id)}',
                      ),
                      child: Text(
                        app.resources
                                .where((resource) => resource.id == id)
                                .firstOrNull
                                ?.name ??
                            'Read Resource',
                      ),
                    ),
                ],
              ),
            ),
          if ((entry.data['media'] as List<dynamic>? ?? []).isNotEmpty)
            _section(
              'Educational media',
              DictionaryMediaGallery(
                media: (entry.data['media'] as List<dynamic>)
                    .map((item) => (item as Map).cast<String, dynamic>())
                    .toList(),
              ),
            ),
          if (entry.strings('attributions').isNotEmpty)
            _section(
              'Community contributors',
              Text(entry.strings('attributions').join(', ')),
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _suggest(entry),
                icon: const Icon(Icons.edit_note_outlined, size: 18),
                label: const Text('Suggest an improvement'),
              ),
              OutlinedButton.icon(
                onPressed: () => shareAppLink(
                  context,
                  title: entry.term,
                  dialogTitle: 'Share definition',
                  url: '${resolveShareOrigin()}/Dictionary/${entry.slug}',
                  text: entry.definition,
                ),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Share term'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}
