import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/create_resource_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/cubit/create_resource_dialog_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_image.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Theme/surface_gradients.dart';
import 'package:horseandriderscompanion/Utilities/resource_urls.dart';

class QuickShareResourcePage extends StatefulWidget {
  const QuickShareResourcePage({super.key});

  static Future<void> open(
    BuildContext context, {
    required List<Skill?> skills,
    required RiderProfile profile,
  }) async {
    final repository =
        context.read<ResourcesStore?>() ?? context.read<ResourcesRepository>();
    final mediaStorage =
        context.read<MediaStorageRepository?>() ??
        context.read<CloudRepository?>();
    final shared = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => CreateResourceDialogCubit(
            isEdit: false,
            resource: null,
            skills: skills,
            usersProfile: profile,
            resourcesRepository: repository,
            mediaStorage: mediaStorage,
          ),
          child: const QuickShareResourcePage(),
        ),
      ),
    );
    if ((shared ?? false) && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resource shared')));
    }
  }

  @override
  State<QuickShareResourcePage> createState() => _QuickShareResourcePageState();
}

const _linkTypes = {
  ResourceType.externalArticle: 'Article',
  ResourceType.video: 'Video',
  ResourceType.link: 'Website',
};

class _QuickShareResourcePageState extends State<QuickShareResourcePage> {
  final _url = TextEditingController();
  final _title = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _paste(CreateResourceDialogCubit cubit) async {
    ClipboardData? data;
    try {
      data = await Clipboard.getData(Clipboard.kTextPlain);
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paste directly into the Resource URL field.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty ||
        cubit.state.submitStatus == ResourceSubmitStatus.submitting) {
      return;
    }
    _url.text = text;
    cubit.urlChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateResourceDialogCubit>();
    return BlocConsumer<CreateResourceDialogCubit, CreateResourceDialogState>(
      listener: (context, state) {
        if (state.title != _title.text) _title.text = state.title;
        if (state.submitStatus == ResourceSubmitStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final saving = state.submitStatus == ResourceSubmitStatus.submitting;
        return PopScope(
          canPop: !saving,
          child: Scaffold(
            backgroundColor: theme.extension<SurfaceGradients>()?.chrome != null
                ? Colors.transparent
                : theme.colorScheme.surface,
            appBar: ThemedAppBar(title: const Text('Add resource')),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 840;
                  final form = _form(context, cubit, state, saving);
                  final preview = _CommunityPreview(
                    resource: cubit.linkPreview,
                    skills:
                        state.resourceSkills?.whereType<Skill>() ?? const [],
                  );
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: wide
                            ? Row(
                                key: const Key('quickShareWide'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: form),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 2, child: preview),
                                ],
                              )
                            : Column(
                                key: const Key('quickShareNarrow'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  form,
                                  const SizedBox(height: 20),
                                  preview,
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _form(
    BuildContext context,
    CreateResourceDialogCubit cubit,
    CreateResourceDialogState state,
    bool saving,
  ) {
    final selected = state.resourceSkills?.whereType<Skill>().toList() ?? [];
    final available =
        state.filteredSkills
            ?.whereType<Skill>()
            .where(
              (skill) =>
                  skill.id.isNotEmpty && !selected.any((s) => s.id == skill.id),
            )
            .toList() ??
        [];
    final fetching = state.urlFetchedStatus == UrlFetchedStatus.fetching;
    final urlField = TextField(
      key: const Key('resourceUrl'),
      controller: _url,
      enabled: !saving,
      keyboardType: TextInputType.url,
      autocorrect: false,
      onChanged: cubit.urlChanged,
      decoration: InputDecoration(
        labelText: 'Resource URL',
        hintText: 'https://',
        errorText:
            state.url.value.isNotEmpty &&
                resourceWebUri(state.url.value) == null
            ? 'Enter a valid web URL'
            : null,
      ),
    );
    final paste = OutlinedButton.icon(
      key: const Key('pasteResourceUrl'),
      onPressed: saving ? null : () => _paste(cubit),
      icon: const Icon(Icons.content_paste),
      label: const Text('Paste'),
    );

    return Column(
      key: const Key('quickShareForm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Quick share', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (_, constraints) => constraints.maxWidth < 420
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [urlField, const SizedBox(height: 8), paste],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: urlField),
                    const SizedBox(width: 8),
                    paste,
                  ],
                ),
        ),
        if (fetching) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            semanticsLabel: 'Fetching link preview',
          ),
        ],
        if (state.urlFetchedStatus == UrlFetchedStatus.manual)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Preview details are unavailable. You can enter a title '
              'and share the link.',
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in _linkTypes.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: state.linkType == entry.key,
                onSelected: saving
                    ? null
                    : (_) => cubit.linkTypeChanged(entry.key),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('resourceTitle'),
          controller: _title,
          enabled: !saving,
          onChanged: cubit.titleChanged,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Title (required)'),
        ),
        const SizedBox(height: 20),
        Text('Related skills', style: Theme.of(context).textTheme.titleMedium),
        const Text('Select at least one skill.'),
        const SizedBox(height: 8),
        TextField(
          enabled: !saving,
          onChanged: cubit.searchSkills,
          decoration: const InputDecoration(
            labelText: 'Search skills',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 8),
        if (selected.isNotEmpty || available.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final skill in selected)
                InputChip(
                  label: Text(skill.skillName),
                  onDeleted: saving
                      ? null
                      : () => cubit.resourceSkillsChanged(skill.id),
                ),
              for (final skill in available.take(8))
                ActionChip(
                  label: Text(skill.skillName),
                  onPressed: saving
                      ? null
                      : () => cubit.resourceSkillsChanged(skill.id),
                ),
            ],
          )
        else
          Text(
            state.skills.isEmpty
                ? 'Skills are unavailable.'
                : 'No matching skills.',
          ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('resourceRecommendation'),
          enabled: !saving,
          minLines: 2,
          maxLines: 3,
          maxLength: 280,
          textCapitalization: TextCapitalization.sentences,
          onChanged: cubit.recommendationChanged,
          decoration: const InputDecoration(
            labelText: 'Why do you recommend it?',
            hintText: 'Optional',
          ),
        ),
        if (state.isError)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              state.error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        FilledButton.icon(
          key: const Key('shareResource'),
          onPressed: saving || !cubit.isFormValidForLink()
              ? null
              : cubit.submit,
          icon: saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.share_outlined),
          label: Text(saving ? 'Sharing…' : 'Share resource'),
        ),
        TextButton(
          onPressed: saving || state.usersProfile == null
              ? null
              : () {
                  showAppGlassModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => CreateResourcDialog(
                      skills: state.skills,
                      resource: null,
                      userProfile: state.usersProfile!,
                      initialInputType: ResourceInputType.pdf,
                    ),
                  );
                },
          child: const Text('Upload a PDF'),
        ),
      ],
    );
  }
}

class _CommunityPreview extends StatelessWidget {
  const _CommunityPreview({required this.resource, required this.skills});

  final Resource resource;
  final Iterable<Skill> skills;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = resource.description ?? '';
    return GradientCard(
      key: const Key('communityResourcePreview'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Community preview', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(_linkTypes[resource.type]!, style: theme.textTheme.labelLarge),
            Text(
              resource.name!.isEmpty ? 'Resource title' : resource.name!,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Center(child: ResourceImage(url: resource.thumbnail ?? '')),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description, maxLines: 7, overflow: TextOverflow.ellipsis),
            ],
            if (resource.url!.isNotEmpty)
              Text(resource.url!, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (final skill in skills)
                    Chip(label: Text(skill.skillName)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
