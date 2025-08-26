import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/resource_icon.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_select_chip.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_type_icon.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/CreateResourceDialog/cubit/create_resource_dialog_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_item.dart';

class CreateResourcDialog extends StatelessWidget {
  const CreateResourcDialog({
    super.key,
    required this.skills,
    required this.resource,
    required this.userProfile,
  });

  final Resource? resource;
  final List<Skill?>? skills;
  final RiderProfile userProfile;

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController(text: resource?.name ?? '');
    final descController =
        TextEditingController(text: resource?.description ?? '');
    final imageController =
        TextEditingController(text: resource?.thumbnail ?? '');

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => ResourcesRepository()),
        RepositoryProvider(create: (_) => KeysRepository()),
      ],
      child: BlocProvider(
        create: (context) => CreateResourceDialogCubit(
          skills: skills,
          resource: resource,
          isEdit: resource != null,
          usersProfile: userProfile,
          resourcesRepository: context.read<ResourcesRepository>(),
        ),
        child:
            BlocListener<CreateResourceDialogCubit, CreateResourceDialogState>(
          listenWhen: (p, c) =>
              p.title != c.title ||
              p.imageUrl != c.imageUrl ||
              p.description != c.description ||
              p.submitStatus != c.submitStatus ||
              p.urlFetchedStatus != c.urlFetchedStatus ||
              p.error != c.error,
          listener: (context, state) {
            final cubit = context.read<CreateResourceDialogCubit>();

            // Autofill fields after parsing link
            if (state.urlFetchedStatus == UrlFetchedStatus.fetched) {
              titleController.text = state.title;
              descController.text = state.description;
              imageController.text = state.imageUrl;
            }

            if (state.submitStatus == ResourceSubmitStatus.success) {
              Navigator.of(context).pop();
            }

            if (state.isError ||
                state.submitStatus == ResourceSubmitStatus.error) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 5),
                    backgroundColor: Colors.red,
                    content: Text(
                      state.error.isEmpty
                          ? 'Something went wrong'
                          : state.error,
                    ),
                  ),
                ).closed.then((_) => cubit.clearError());
            }
          },
          child:
              BlocBuilder<CreateResourceDialogCubit, CreateResourceDialogState>(
            builder: (context, state) {
              final cubit = context.read<CreateResourceDialogCubit>();
              final canSubmit = state.inputType == ResourceInputType.link
                  ? cubit.isFormValidForLink()
                  : cubit.isFormValidForPdf();

              return Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(state.isEdit ? 'Edit Resource' : 'Add Resource'),
                ),
                body: AlertDialog(
                  scrollable: true,
                  title: Text(
                    state.isEdit ? 'Edit Resource' : 'Create New Resource',
                  ),
                  content: Form(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1) Mode toggle
                        SegmentedButton<ResourceInputType>(
                          segments: const [
                            ButtonSegment(
                              value: ResourceInputType.link,
                              label: Text('Link'),
                              icon: Icon(Icons.link),
                            ),
                            ButtonSegment(
                              value: ResourceInputType.pdf,
                              label: Text('PDF'),
                              icon: Icon(Icons.picture_as_pdf),
                            ),
                          ],
                          selected: {state.inputType},
                          onSelectionChanged: (s) =>
                              cubit.inputTypeChanged(s.first),
                        ),
                        gap(),

                        // 2) LINK MODE
                        if (state.inputType == ResourceInputType.link) ...[
                          _UrlField(
                            state: state,
                            onChanged: cubit.urlChanged,
                            onFetch: () => cubit.getMetadata(state.url.value),
                            onClear: () => cubit.urlChanged(''),
                            onPasteFromClipboard: () async {
                              final data =
                                  await Clipboard.getData('text/plain');
                              final text = data?.text?.trim() ?? '';
                              if (text.isNotEmpty) cubit.urlChanged(text);
                            },
                          ),
                          smallGap(),
                          if (state.urlFetchedStatus ==
                              UrlFetchedStatus.fetching)
                            const _InlineProgress(
                              message: 'Fetching website information...',
                            ),
                          if (state.urlFetchedStatus == UrlFetchedStatus.error)
                            const _InlineError(
                              message: 'Failed to fetch details.'
                                  ' You can fill in the fields below manually.',
                            ),
                          if (state.urlFetchedStatus ==
                                  UrlFetchedStatus.fetched ||
                              state.urlFetchedStatus ==
                                  UrlFetchedStatus.manual) ...[
                            // Quick visual preview
                            ResourcesItem(
                              isResourceList: false,
                              resource: Resource(
                                type: ResourceType.link,
                                name: state.title,
                                description: state.description,
                                thumbnail: state.imageUrl,
                                lastEditDate: DateTime.now(),
                              ),
                            ),
                            gap(),

                            // Details collapsed by default to reduce clutter
                            ExpansionTile(
                              initiallyExpanded: state.title.isEmpty,
                              title: const Text('Details'),
                              childrenPadding: const EdgeInsets.only(
                                left: 8,
                                right: 8,
                                bottom: 8,
                              ),
                              children: [
                                TextFormField(
                                  controller: titleController,
                                  minLines: 1,
                                  maxLines: 3,
                                  onChanged: cubit.titleChanged,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    labelText: 'Title',
                                    hintText: 'Resource title',
                                    icon: Icon(Icons.title),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Title is required'
                                          : null,
                                ),
                                gap(),
                                TextFormField(
                                  controller: descController,
                                  minLines: 1,
                                  maxLines: 5,
                                  onChanged: cubit.descriptionChanged,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    hintText: 'Short description (optional)',
                                    icon: Icon(Icons.description),
                                  ),
                                ),
                                gap(),
                                TextFormField(
                                  controller: imageController,
                                  onChanged: cubit.imageUrlChanged,
                                  keyboardType: TextInputType.url,
                                  decoration: const InputDecoration(
                                    labelText: 'Image URL',
                                    hintText: 'Enter an image URL (optional)',
                                    icon: Icon(Icons.image),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],

                        // 3) PDF MODE
                        if (state.inputType == ResourceInputType.pdf) ...[
                          _PdfPicker(
                            fileName: state.pdfName,
                            picking: state.pdfPicking,
                            uploading: state.pdfUploading,
                            progress: state.pdfUploadProgress,
                            onPickPressed: cubit.pickPdf,
                            onClearPressed: cubit.clearPickedPdf,
                          ),
                          gap(),
                          if (state.pdfBytes != null)
                            ExpansionTile(
                              initiallyExpanded: true,
                              title: const Text('Details'),
                              childrenPadding: const EdgeInsets.only(
                                left: 8,
                                right: 8,
                                bottom: 8,
                              ),
                              children: [
                                TextFormField(
                                  controller: titleController,
                                  minLines: 1,
                                  maxLines: 3,
                                  onChanged: cubit.titleChanged,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    labelText: 'Title',
                                    hintText: 'Document title',
                                    icon: Icon(Icons.title),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Title is required'
                                          : null,
                                ),
                                gap(),
                                TextFormField(
                                  controller: descController,
                                  minLines: 1,
                                  maxLines: 6,
                                  onChanged: cubit.descriptionChanged,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    hintText: 'Short description (optional)',
                                    icon: Icon(Icons.description),
                                  ),
                                ),
                              ],
                            ),
                        ],

                        gap(),

                        // 4) Skills (progressive disclosure)
                        if ((state.inputType == ResourceInputType.link &&
                                (state.urlFetchedStatus ==
                                        UrlFetchedStatus.fetched ||
                                    state.urlFetchedStatus ==
                                        UrlFetchedStatus.manual)) ||
                            (state.inputType == ResourceInputType.pdf &&
                                state.pdfBytes != null))
                          ExpansionTile(
                            title: const Text('Related skills (optional)'),
                            childrenPadding: const EdgeInsets.only(
                              left: 8,
                              right: 8,
                              bottom: 8,
                            ),
                            children: [
                              SearchBar(
                                hintText: 'Search skills',
                                onChanged: cubit.searchSkills,
                              ),
                              smallGap(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  DropdownButton<CategoryFilter>(
                                    value: state.categoryFilter,
                                    onChanged: cubit.categoryFilterChanged,
                                    items: CategoryFilter.values
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c.name),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  smallGap(),
                                  DropdownButton<DifficultyFilter>(
                                    value: state.difficultyFilter,
                                    onChanged: cubit.difficultyFilterChanged,
                                    items: DifficultyFilter.values
                                        .map(
                                          (d) => DropdownMenuItem(
                                            value: d,
                                            child: Text(d.name),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                              gap(),
                              Wrap(
                                spacing: 8,
                                children:
                                    state.filteredSkills!.map((Skill? skill) {
                                  return SkillSelectChip(
                                    trailingIcon: SkillTypeIcon(
                                      difficulty: skill?.difficulty,
                                      isRider: skill?.rider ?? true,
                                    ),
                                    skill: skill,
                                    leadingIcon: ResourceIcon(
                                      category: skill?.category,
                                      difficulty: skill?.difficulty,
                                    ),
                                    textLabel: skill?.skillName ?? '',
                                    isSelected: state.resourceSkills?.any(
                                          (s) => s?.id == skill?.id,
                                        ) ??
                                        false,
                                    onTap: (_) => context
                                        .read<CreateResourceDialogCubit>()
                                        .resourceSkillsChanged(skill?.id ?? ''),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    if (state.submitStatus == ResourceSubmitStatus.submitting)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      FilledButton.icon(
                        icon: const Icon(Icons.check),
                        onPressed: canSubmit ? cubit.submit : null,
                        label: Text(
                          state.inputType == ResourceInputType.link
                              ? 'Save link'
                              : 'Upload PDF',
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Compact URL field with paste/fetch/clear and inline status.
class _UrlField extends StatelessWidget {
  const _UrlField({
    required this.state,
    required this.onChanged,
    required this.onFetch,
    required this.onClear,
    required this.onPasteFromClipboard,
  });

  final CreateResourceDialogState state;
  final ValueChanged<String> onChanged;
  final VoidCallback onFetch;
  final VoidCallback onClear;
  final Future<void> Function() onPasteFromClipboard;

  @override
  Widget build(BuildContext context) {
    final isBusy = state.urlFetchedStatus == UrlFetchedStatus.fetching;
    final isError = state.urlFetchedStatus == UrlFetchedStatus.error;

    return TextFormField(
      initialValue: state.resource?.url ?? state.url.value,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
      onFieldSubmitted: (_) => onFetch(),
      decoration: InputDecoration(
        labelText: 'Resource URL',
        hintText: 'Paste a link (YouTube, article, etc.)',
        icon: const Icon(Icons.link),
        errorText: isError ? 'Please enter a valid URL' : null,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBusy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            IconButton(
              tooltip: 'Paste',
              onPressed: isBusy ? null : onPasteFromClipboard,
              icon: const Icon(Icons.content_paste),
            ),
            IconButton(
              tooltip: 'Fetch',
              onPressed: isBusy ? null : onFetch,
              icon: const Icon(Icons.download),
            ),
            IconButton(
              tooltip: 'Clear',
              onPressed: isBusy ? null : onClear,
              icon: const Icon(Icons.clear),
            ),
          ],
        ),
      ),
      validator: (_) => state.url.isNotValid ? 'Enter a valid URL' : null,
    );
  }
}

class _InlineProgress extends StatelessWidget {
  const _InlineProgress({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(message)),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(message, style: const TextStyle(color: Colors.red)),
    );
  }
}

// Small PDF picker/upload UI used in PDF mode
class _PdfPicker extends StatelessWidget {
  const _PdfPicker({
    required this.fileName,
    required this.picking,
    required this.uploading,
    required this.progress,
    required this.onPickPressed,
    required this.onClearPressed,
  });

  final String? fileName;
  final bool picking;
  final bool uploading;
  final double progress;
  final VoidCallback onPickPressed;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: picking || uploading ? null : onPickPressed,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Choose PDF'),
            ),
            smallGap(),
            if (fileName != null && fileName!.isNotEmpty)
              Expanded(
                child: Text(
                  fileName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (fileName != null && fileName!.isNotEmpty) ...[
              smallGap(),
              IconButton(
                tooltip: 'Clear',
                onPressed: picking || uploading ? null : onClearPressed,
                icon: const Icon(Icons.clear),
              ),
            ],
          ],
        ),
        if (uploading) ...[
          smallGap(),
          LinearProgressIndicator(value: progress == 0 ? null : progress),
        ],
      ],
    );
  }
}
