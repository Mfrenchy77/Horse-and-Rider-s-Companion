// lib/MainPages/Resources/Widgets/create_comment_dialog.dart
import 'dart:convert';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/AddCommentDialog/cubit/comment_cubit.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class CreateCommentDialog extends StatelessWidget {
  const CreateCommentDialog({
    super.key,
    this.comment,
    required this.isEdit,
    required this.resource,
    required this.usersProfile,
  });

  final bool isEdit;
  final Comment? comment;
  final Resource resource;
  final RiderProfile usersProfile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CommentCubit(
        comment: comment,
        resource: resource,
        usersProfile: usersProfile,
      )..setEdit(isEdit: isEdit),
      child: _CreateCommentDialogBody(
        isEdit: isEdit,
        comment: comment,
        resource: resource,
        usersProfile: usersProfile,
      ),
    );
  }
}

class _CreateCommentDialogBody extends StatefulWidget {
  const _CreateCommentDialogBody({
    required this.isEdit,
    required this.comment,
    required this.resource,
    required this.usersProfile,
  });

  final bool isEdit;
  final Comment? comment;
  final Resource resource;
  final RiderProfile usersProfile;

  @override
  State<_CreateCommentDialogBody> createState() =>
      _CreateCommentDialogBodyState();
}

class _CreateCommentDialogBodyState extends State<_CreateCommentDialogBody> {
  late final quill.QuillController _controller;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();

    // Build initial document from JSON if editing; else an empty doc.
    final initialJsonString =
        widget.isEdit && (widget.comment?.comment?.isNotEmpty ?? false)
        ? widget.comment!.comment!
        : jsonEncode(quill.Document().toDelta().toJson());

    final initialDoc = quill.Document.fromJson(
      jsonDecode(initialJsonString) as List<dynamic>,
    );
    _controller = quill.QuillController(
      document: initialDoc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Seed the cubit with the initial JSON *after* first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final jsonStr = jsonEncode(_controller.document.toDelta().toJson());
      context.read<CommentCubit>().updateCommentMessage(jsonStr);
    });

    _recomputeCanSend();
    _controller.addListener(_onDocChanged);
  }

  void _onDocChanged() {
    if (!mounted) return;

    // Update local "can send" based on visible plain text
    _recomputeCanSend();

    // Push JSON to cubit (recommended storage for Quill)
    final jsonStr = jsonEncode(_controller.document.toDelta().toJson());
    context.read<CommentCubit>().updateCommentMessage(jsonStr);
  }

  void _recomputeCanSend() {
    final plain = _controller.document.toPlainText().trim();
    final next = plain.length >= 3;
    if (next != _canSend) {
      setState(() => _canSend = next);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onDocChanged)
      ..dispose();
    super.dispose();
  }

  void _send() {
    context.read<CommentCubit>().sendComment();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = HorseAndRidersTheme().getTheme();

    final titleText = widget.comment == null && !widget.isEdit
        ? 'Commenting on ${widget.resource.name ?? 'Resource'}'
        : widget.comment != null && !widget.isEdit
        ? 'Replying to ${widget.comment!.user?.name ?? 'User'}'
        : 'Edit comment';

    final screen = MediaQuery.of(context).size;
    final maxW = screen.width.clamp(320.0, 720.0);
    final editorHeight = (screen.height.clamp(360.0, 640.0) - 200).clamp(
      180.0,
      440.0,
    );

    return AppGlassDialog(
      maxWidth: 720,
      density: AppGlassDensity.frosted,
      scrollable: false,
      title: Text(titleText, textAlign: TextAlign.center),
      content: SizedBox(
        width: maxW,
        height: editorHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.comment != null && !widget.isEdit) ...[
              Divider(
                thickness: 2,
                indent: 20,
                endIndent: 20,
                color: theme.primaryColor,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SelectableText(
                  // For reply preview show parent’s plain text
                  quill.Document.fromJson(
                    jsonDecode(widget.comment!.comment ?? '[]')
                        as List<dynamic>,
                  ).toPlainText(),
                  textAlign: TextAlign.center,
                ),
              ),
              Divider(
                thickness: 2,
                indent: 20,
                endIndent: 20,
                color: theme.primaryColor,
              ),
            ],

            const SizedBox(height: 8),

            // Comments only need basic inline formatting.
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final attribute in [
                    quill.Attribute.bold,
                    quill.Attribute.italic,
                    quill.Attribute.underline,
                    quill.Attribute.strikeThrough,
                  ])
                    quill.QuillToolbarToggleStyleButton(
                      controller: _controller,
                      attribute: attribute,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Editor
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: quill.QuillEditor.basic(
                    controller: _controller,
                    config: quill.QuillEditorConfig(
                      placeholder: widget.comment == null
                          ? 'Enter your comment...'
                          : 'Edit your comment...',
                      autoFocus: true,
                      expands: true,
                      keyboardAppearance: Theme.of(context).brightness,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.send),
          onPressed: _canSend ? _send : null,
          label: const Text('Send Comment'),
        ),
      ],
    );
  }
}
