// lib/Resources/articles/create_article_view.dart
// Focus-safe Create Article view using flutter_quill.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:horseandriderscompanion/MainPages/Resources/Article/cubit/create_article_cubit.dart';

class CreateArticleView extends StatefulWidget {
  const CreateArticleView({super.key, this.onCreated});
  final void Function(String resourceId)? onCreated;

  @override
  State<CreateArticleView> createState() => _CreateArticleViewState();
}

class _CreateArticleViewState extends State<CreateArticleView> {
  final _formKey = GlobalKey<FormState>();

  // Title/desc/tag controllers live outside any BlocBuilder
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  // Quill controller and a PERSISTENT FocusNode
  late final QuillController _quill;
  late final FocusNode _editorFocusNode;
  final ScrollController _editorScroll = ScrollController();

  // simple debounce for content updates
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _editorFocusNode = FocusNode(debugLabel: 'article_editor_focus');
    _quill = QuillController.basic();
    _quill.addListener(_onQuillChanged);
  }

  void _onQuillChanged() {
    // debounce to avoid emitting every keystroke
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      final deltaJson = jsonEncode(_quill.document.toDelta().toJson());
      final plainLen = _quill.document.toPlainText().trim().length;
      context.read<CreateArticleCubit>().editorUpdated(
            deltaJson: deltaJson,
            plainTextLength: plainLen,
          );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _quill
      ..removeListener(_onQuillChanged)
      ..dispose();
    _editorFocusNode.dispose();
    _editorScroll.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only listen for side effects (snackbars, navigation)
    return BlocListener<CreateArticleCubit, ArticleCreateState>(
      listenWhen: (p, c) =>
          p.status != c.status || p.errorMessage != c.errorMessage,
      listener: (context, state) {
        if (state.status == ArticleCreateStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.status == ArticleCreateStatus.success &&
            state.createdResourceId != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Article created!')));
          widget.onCreated?.call(state.createdResourceId!);
          if (widget.onCreated == null) {
            Navigator.of(context).pop(state.createdResourceId);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Article'),
          actions: [
            // Tiny bloc selectors that won't rebuild the editor:
            BlocSelector<CreateArticleCubit, ArticleCreateState, bool>(
              selector: (s) =>
                  s.isFormValid && s.status != ArticleCreateStatus.submitting,
              builder: (context, canSubmit) {
                return TextButton.icon(
                  onPressed: canSubmit
                      ? () => context.read<CreateArticleCubit>().submit()
                      : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Submit'),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              // No onChanged => setState(); validation happens on submit
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'How to Sit the Trot',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: context.read<CreateArticleCubit>().titleChanged,
                    validator: (_) {
                      final ok =
                          context.read<CreateArticleCubit>().state.isValidTitle;
                      return ok ? null : 'Title must be 3–120 characters';
                    },
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Short description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged:
                        context.read<CreateArticleCubit>().descriptionChanged,
                  ),
                  const SizedBox(height: 12),

                  // Tags
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Add tag (press Enter)',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (v) {
                            context.read<CreateArticleCubit>().addTag(v);
                            _tagCtrl.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Add tag',
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          context
                              .read<CreateArticleCubit>()
                              .addTag(_tagCtrl.text);
                          _tagCtrl.clear();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  BlocSelector<CreateArticleCubit, ArticleCreateState,
                      List<String>>(
                    selector: (s) => s.tags,
                    builder: (context, tags) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: -8,
                        children: [
                          for (final t in tags)
                            Chip(
                              label: Text(t),
                              onDeleted: () => context
                                  .read<CreateArticleCubit>()
                                  .removeTag(t),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Cover image
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context
                            .read<CreateArticleCubit>()
                            .pickAndUploadCover(),
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Upload cover'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BlocSelector<CreateArticleCubit,
                            ArticleCreateState, String?>(
                          selector: (s) => s.coverImageUrl,
                          builder: (context, url) => Text(
                            url ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Editor
                  Text(
                    'Content',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  QuillSimpleToolbar(
                    controller: _quill,
                  ),
                  const SizedBox(height: 8),

                  Container(
                    constraints: const BoxConstraints(minHeight: 220),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: QuillEditor.basic(
                        key: const PageStorageKey('create_article_editor'),
                        controller: _quill,
                        focusNode: _editorFocusNode, // <-- persistent focus
                        scrollController: _editorScroll,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Tiny, isolated rebuilds for the counter and validation hint
                  Align(
                    alignment: Alignment.centerRight,
                    child: BlocSelector<CreateArticleCubit, ArticleCreateState,
                        int>(
                      selector: (s) => s.contentChars,
                      builder: (_, chars) => Text(
                        '$chars characters',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  BlocSelector<CreateArticleCubit, ArticleCreateState, bool>(
                    selector: (s) => s.isValidContent,
                    builder: (_, ok) => ok
                        ? const SizedBox.shrink()
                        : const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              'Please write at least 20 characters.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Submit row (isolated)
                  BlocSelector<CreateArticleCubit, ArticleCreateState,
                      ({bool canSubmit, bool busy})>(
                    selector: (s) => (
                      canSubmit: s.isFormValid &&
                          s.status != ArticleCreateStatus.submitting,
                      busy: s.status == ArticleCreateStatus.submitting ||
                          s.status == ArticleCreateStatus.uploadingCover ||
                          s.status == ArticleCreateStatus.pickingCover
                    ),
                    builder: (context, vm) {
                      return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: vm.canSubmit
                                  ? () => context
                                      .read<CreateArticleCubit>()
                                      .submit()
                                  : null,
                              icon: vm.busy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: const Text('Submit (Pending)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: vm.canSubmit
                                  ? () => context
                                      .read<CreateArticleCubit>()
                                      .submit(publishNow: true)
                                  : null,
                              icon: const Icon(Icons.publish_outlined),
                              label: const Text('Publish Now'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
