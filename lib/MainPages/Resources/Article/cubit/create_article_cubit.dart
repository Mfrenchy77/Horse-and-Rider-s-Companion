// lib/Resources/articles/create_article_cubit.dart
// ignore_for_file: public_member_api_docs

import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

part 'create_article_state.dart';

class CreateArticleCubit extends Cubit<ArticleCreateState> {
  CreateArticleCubit({
    ResourcesRepository? resourcesRepository,
    FirebaseStorage? storage,
    RiderProfile? user,
  })  : _repo = resourcesRepository ?? ResourcesRepository(),
        _storage = storage ?? FirebaseStorage.instance,
        _user = user,
        super(const ArticleCreateState());

  final ResourcesRepository _repo;
  final FirebaseStorage _storage;
  final RiderProfile? _user;

  // ------------------ Field updates ------------------

  void titleChanged(String v) => emit(state.copyWith(title: v));
  void descriptionChanged(String v) => emit(state.copyWith(description: v));

  void addTag(String v) {
    final t = v.trim();
    if (t.isEmpty || state.tags.contains(t)) return;
    if (state.tags.length >= 6) {
      emit(state.copyWith(errorMessage: 'You can add up to 6 tags.'));
      return;
    }
    emit(state.copyWith(tags: [...state.tags, t]));
  }

  void removeTag(String v) => emit(
        state.copyWith(tags: [...state.tags]..remove(v)),
      );

  /// Called by the view when the Quill document changes.
  void editorUpdated({
    required String deltaJson,
    required int plainTextLength,
  }) {
    emit(state.copyWith(content: deltaJson, contentChars: plainTextLength));
  }

  // ------------------ Cover upload ------------------

  Future<void> pickAndUploadCover() async {
    emit(
      state.copyWith(
        status: ArticleCreateStatus.pickingCover,
      ),
    );
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (res == null || res.files.isEmpty) {
        emit(state.copyWith(status: ArticleCreateStatus.idle));
        return;
      }

      final file = res.files.single;
      final bytes = file.bytes;
      final filename = file.name;
      if (bytes == null) {
        emit(
          state.copyWith(
            status: ArticleCreateStatus.failure,
            errorMessage: 'Could not read file bytes. Try a smaller image.',
          ),
        );
        return;
      }

      if (_user == null) {
        emit(
          state.copyWith(
            status: ArticleCreateStatus.failure,
            errorMessage: 'You must be signed in to upload a cover.',
          ),
        );
        return;
      }

      // Use repo to mint an ID (no direct Firestore access here)
      final tempId = state.createdResourceId ?? _repo.newId();

      emit(state.copyWith(status: ArticleCreateStatus.uploadingCover));

      final ref = _storage.ref().child('covers/$_user.email/$tempId/$filename');
      final meta = SettableMetadata(contentType: _guessContentType(filename));
      final task = await ref.putData(bytes, meta);
      final downloadUrl = await task.ref.getDownloadURL();

      emit(
        state.copyWith(
          coverImageUrl: downloadUrl,
          createdResourceId: tempId,
          status: ArticleCreateStatus.idle,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ArticleCreateStatus.failure,
          errorMessage: 'Cover upload failed: $e',
        ),
      );
    }
  }

  String _guessContentType(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
    if (n.endsWith('.webp')) return 'image/webp';
    return 'image/*';
  }

  // ------------------ Submit ------------------

  Future<void> submit({bool publishNow = false}) async {
    if (!state.isFormValid) {
      emit(
        state.copyWith(
          errorMessage: 'Please fix validation: title ≥ 3 chars,'
              ' content ≥ 20 chars, ≤ 6 tags.',
        ),
      );
      return;
    }

    if (_user == null) {
      emit(
        state.copyWith(
          errorMessage: 'You must be signed in to publish an article.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ArticleCreateStatus.submitting,
      ),
    );
    try {
      final id = state.createdResourceId ?? _repo.newId();

      final resource = Resource(
        id: id,
        rating: 0,
        lastEditBy: _user?.email,
        lastEditDate: DateTime.now(),
        thumbnail: state.coverImageUrl,
        type: ResourceType.article,
        status: publishNow ? ResourceStatus.published : ResourceStatus.pending,
        name: state.title.trim(),
        description:
            state.description.trim().isEmpty ? null : state.description.trim(),
        content: state.content,
        tags: state.tags,
        coverImageUrl: state.coverImageUrl,
        authorId: _user?.email,
        authorName: _user?.name,
        authorPhoto: _user?.picUrl,
      );

      await _repo.createArticle(resource: resource);

      emit(
        state.copyWith(
          status: ArticleCreateStatus.success,
          createdResourceId: id,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ArticleCreateStatus.failure,
          errorMessage: 'Could not save article: $e',
        ),
      );
    }
  }
}
