// ignore_for_file: public_member_api_docs, constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:any_link_preview/any_link_preview.dart';
import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/Utilities/resource_urls.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';
import 'package:http/http.dart' as http;

part 'create_resource_dialog_state.dart';

class CreateResourceDialogCubit extends Cubit<CreateResourceDialogState> {
  CreateResourceDialogCubit({
    required bool isEdit,
    required Resource? resource,
    required List<Skill?>? skills,
    required RiderProfile? usersProfile,
    required this._resourcesRepository,
    this._storage,
    ResourceInputType initialInputType = ResourceInputType.link,

    /// Optional overrides (handy for emulator/local testing)
    String? previewMetaEndpoint,
    String? fetchReadableEndpoint,
    String? resolveImageEndpoint,
  }) : _debounce = null,
       _previewMetaUrl = (previewMetaEndpoint?.trim().isEmpty ?? true)
           ? _kDefaultPreviewMetaUrl
           : previewMetaEndpoint!.trim(),
       _fetchReadableUrl = (fetchReadableEndpoint?.trim().isEmpty ?? true)
           ? _kDefaultFetchReadableUrl
           : fetchReadableEndpoint!.trim(),
       _resolveImageUrl = (resolveImageEndpoint?.trim().isEmpty ?? true)
           ? resourceImageResolverEndpoint
           : resolveImageEndpoint!.trim(),
       super(const CreateResourceDialogState()) {
    emit(
      state.copyWith(
        skills: skills,
        isEdit: isEdit,
        resource: resource,
        filteredSkills: skills,
        usersProfile: usersProfile,
        title: resource?.name ?? '',
        imageUrl: resource?.thumbnail ?? '',
        url: Url.dirty(resource?.url ?? ''),
        description: resource?.description ?? '',
        urlFetchedStatus: isEdit
            ? UrlFetchedStatus.fetched
            : UrlFetchedStatus.initial,
        inputType: resource?.type == ResourceType.pdf
            ? ResourceInputType.pdf
            : initialInputType,
      ),
    );

    final initialResourceSkills = getSkillsForResource(
      ids: resource?.skillTreeIds,
    );
    emit(state.copyWith(resourceSkills: initialResourceSkills));
  }

  // --------------------------------------------------------------------------
  // Cloud Function endpoints (defaults to your deployed functions)
  static const String _kDefaultPreviewMetaUrl =
      'https://us-central1-horse-and-riders-compani-d2bd4.cloudfunctions.net/previewMeta';
  static const String _kDefaultFetchReadableUrl =
      'https://us-central1-horse-and-riders-compani-d2bd4.cloudfunctions.net/fetchReadable';

  Timer? _debounce;
  final ResourcesRepository _resourcesRepository;
  final FirebaseStorage? _storage;
  int _metadataRequest = 0;
  String? _metadataTitle;
  String? _metadataImage;
  String? _metadataDescription;

  final String _previewMetaUrl;
  final String _fetchReadableUrl;
  final String _resolveImageUrl;

  // ----------------- tiny logger -----------------
  static int _seq = 0;
  String _newTrace() => '${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
  void _d(String tag, String msg) {
    if (kDebugMode) debugPrint('[CreateResourceDialogCubit][$tag] $msg');
  }

  String _clipForLog(String? s, [int max = 160]) {
    if (s == null || s.isEmpty) return '';
    return s.length <= max ? s : '${s.substring(0, max - 1)}…';
  }

  // ----------------- Input type -----------------
  void inputTypeChanged(ResourceInputType t) {
    emit(state.copyWith(inputType: t));
  }

  // ----------------- Link mode ------------------
  void urlChanged(String value) {
    final url = Url.dirty(value.trim());
    if (url.value == state.url.value) return;
    _metadataRequest++;
    _d('urlChanged', 'value="${_clipForLog(value)}" valid=${url.isValid}');
    emit(
      state.copyWith(
        url: url,
        urlFetchedStatus: UrlFetchedStatus.initial,
        title: state.title == _metadataTitle ? '' : state.title,
        description: state.description == _metadataDescription
            ? ''
            : state.description,
        imageUrl: state.imageUrl == _metadataImage ? '' : state.imageUrl,
        isError: false,
        error: '',
      ),
    );

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (url.isValid) {
        getMetadata(url.value);
      } else {
        _d('debounce', 'skipped getMetadata (invalid url)');
      }
    });
  }

  void titleChanged(String value) {
    _metadataTitle = null;
    emit(state.copyWith(title: value));
  }

  void imageUrlChanged(String value) {
    _metadataImage = null;
    emit(state.copyWith(imageUrl: value));
  }

  void descriptionChanged(String value) {
    _metadataDescription = null;
    emit(state.copyWith(description: value));
  }

  void recommendationChanged(String value) =>
      emit(state.copyWith(recommendation: value));

  void linkTypeChanged(ResourceType type) =>
      emit(state.copyWith(linkType: type));

  Uri? _restrictedPage;

  bool _blocksEmbedding(String? url) {
    final uri = resourceWebUri(url);
    return uri != null &&
        (uri == _restrictedPage ||
            (uri == resourceWebUri(state.resource?.url) &&
                (state.resource?.blocksEmbedding ?? false)));
  }

  Resource get linkPreview {
    final note = state.recommendation.trim();
    return Resource(
      name: state.title.trim(),
      url: state.url.value,
      blocksEmbedding: _blocksEmbedding(state.url.value),
      type: state.linkType,
      thumbnail: imageSourceUrl(state.imageUrl)?.toString(),
      description: note.isEmpty ? state.description.trim() : note,
      skillTreeIds: state.resourceSkills
          ?.whereType<Skill>()
          .map((skill) => skill.id)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(),
    );
  }

  bool _checkUrlValid(String url) => resourceWebUri(url) != null;

  // ---------- HTTP helper ----------
  static const _jsonHeaders = {'Content-Type': 'application/json'};

  Future<Map<String, dynamic>?> _postJson(
    String endpoint, {
    required Map<String, dynamic> body,
    Duration timeout = const Duration(seconds: 15),
    String? trace,
  }) async {
    final sw = Stopwatch()..start();
    _d('HTTP', 'POST $endpoint trace=$trace bodyKeys=${body.keys.toList()}');
    try {
      final uri = Uri.parse(endpoint);
      final resp = await http
          .post(uri, headers: _jsonHeaders, body: jsonEncode(body))
          .timeout(timeout);
      _d(
        'HTTP',
        '← $endpoint status=${resp.statusCode} '
            'len=${resp.body.length}B '
            'elapsed=${sw.elapsedMilliseconds}ms trace=$trace',
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>?;
      }
    } catch (e, st) {
      _d('HTTP', 'ERROR $endpoint trace=$trace error=$e\n$st');
    }
    return null;
  }

  String _clip(String s, [int max = 280]) =>
      s.length <= max ? s : '${s.substring(0, max - 1)}…';

  String _absUrl(String maybeRelative, String pageUrl) {
    if (maybeRelative.isEmpty) return '';
    try {
      final base = Uri.parse(pageUrl);
      final u = Uri.parse(maybeRelative);
      return u.hasScheme ? u.toString() : base.resolveUri(u).toString();
    } catch (_) {
      return maybeRelative;
    }
  }

  /// Prefer readable/article metadata; fall back to OG/Twitter tags; then title.
  Map<String, String> _mergeMeta({
    required Map<String, dynamic>? preview,
    required Map<String, dynamic>? readable,
    required String fallbackTitle,
    required String pageUrl,
  }) {
    String pick(dynamic v) => (v is String && v.trim().isNotEmpty) ? v : '';

    final pTitle = pick(preview?['title']);
    final pDesc = pick(preview?['description']);
    final pImg = _absUrl(pick(preview?['image']), pageUrl);

    final rTitle = pick(readable?['title']);
    final rDesc = pick(readable?['description']).isNotEmpty
        ? pick(readable?['description'])
        : pick(readable?['excerpt']);
    final rImg = _absUrl(pick(readable?['image']), pageUrl);

    final title = [
      rTitle,
      pTitle,
      fallbackTitle,
    ].firstWhere((s) => s.trim().isNotEmpty, orElse: () => fallbackTitle);

    final desc = [
      rDesc,
      pDesc,
    ].firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');

    // Prefer readable image first, then preview image
    final img = [
      rImg,
      pImg,
    ].firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');

    return {'title': title, 'description': _clip(desc), 'image': img};
  }

  /// Resolves a preview to its original image URL.
  Future<String?> _resolveImage(
    String pageUrl, {
    String? hint,
    String? trace,
  }) async {
    _d('resolveImage', '→ $pageUrl hint="${_clipForLog(hint)}" trace=$trace');
    final source = imageSourceUrl(hint);
    final resp = await _postJson(
      _resolveImageUrl,
      body: {'url': pageUrl, if (source != null) 'hint': source.toString()},
      timeout: const Duration(seconds: 25),
      trace: trace,
    );
    return (imageSourceUrl(resp?['resolvedUrl'] as String?) ??
            imageSourceUrl(resp?['proxiedUrl'] as String?))
        ?.toString();
  }

  Future<void> getMetadata(String url) async {
    _debounce?.cancel();
    final request = ++_metadataRequest;
    bool isCurrent() => !isClosed && request == _metadataRequest;
    final trace = _newTrace();
    _d('getMetadata', 'start url=$url trace=$trace');
    emit(state.copyWith(urlFetchedStatus: UrlFetchedStatus.fetching));

    if (!_checkUrlValid(url)) {
      _d('getMetadata', 'invalid url trace=$trace');
      emit(
        state.copyWith(
          urlFetchedStatus: UrlFetchedStatus.error,
          isError: true,
          error: 'Invalid URL',
        ),
      );
      return;
    }

    // Try Cloud Functions first
    try {
      final p = await _postJson(
        _previewMetaUrl,
        body: {'url': url},
        trace: trace,
      );
      if (!isCurrent()) return;
      if (p?['blocksEmbedding'] == true) {
        _restrictedPage = resourceWebUri(url);
      }
      final r = await _postJson(
        _fetchReadableUrl,
        body: {'url': url},
        trace: trace,
      );

      _d(
        'getMetadata',
        'previewMeta: title="${_clipForLog(p?['title'] as String?)}" '
            'img="${_clipForLog(p?['image'] as String?)}" trace=$trace',
      );
      _d(
        'getMetadata',
        'fetchReadable: title="${_clipForLog(r?['title'] as String?)}" '
            'img="${_clipForLog(r?['image'] as String?)}" trace=$trace',
      );

      if (!isCurrent()) return;
      if (p != null || r != null) {
        final merged = _mergeMeta(
          preview: p,
          readable: r,
          fallbackTitle: state.title,
          pageUrl: url,
        );

        // ALWAYS run the resolver (even if meta image looks direct).
        final candidateImg = state.imageUrl.isNotEmpty
            ? state.imageUrl
            : (merged['image'] ?? '');
        String? finalImg;
        try {
          final resolved = await _resolveImage(
            url,
            hint: candidateImg,
            trace: trace,
          );
          if (resolved != null && resolved.isNotEmpty) {
            finalImg = resolved;
          } else {
            finalImg = candidateImg;
          }
        } catch (e, st) {
          _d('resolveImage', 'ERROR trace=$trace $e\n$st');
          finalImg = candidateImg;
        }

        _d(
          'getMetadata',
          'done (CF path) title="${_clipForLog(merged['title'])}" '
              'finalImg="${_clipForLog(finalImg)}" trace=$trace',
        );

        if (!isCurrent()) return;
        _applyMetadata(url, merged['title']!, merged['description']!, finalImg);
        return;
      }
    } catch (e, st) {
      _d('getMetadata', 'CF ERROR trace=$trace $e\n$st');
      // fall through to ALP
    }

    if (!isCurrent()) return;
    // Fallback: AnyLinkPreview (with CORS proxy to fetch meta if needed)
    try {
      _d('fallback', 'AnyLinkPreview → $url trace=$trace');
      final metadata = await AnyLinkPreview.getMetadata(
        link: url,
        cache: const Duration(days: 7),
        proxyUrl: 'https://corsproxy.io/?',
      );

      if (!isCurrent()) return;
      if (metadata == null ||
          ((metadata.title?.isEmpty ?? true) && state.title.isEmpty)) {
        _d('fallback', 'ALP returned empty trace=$trace');
        emit(state.copyWith(urlFetchedStatus: UrlFetchedStatus.manual));
      } else {
        final mergedImg = _absUrl(metadata.image ?? '', url);
        _d(
          'fallback',
          'ALP title="${_clipForLog(metadata.title)}" '
              'img="${_clipForLog(mergedImg)}" trace=$trace',
        );

        // Try resolver to upgrade to a verified direct/wp upload if possible
        String? finalImg = mergedImg;
        try {
          final resolved = await _resolveImage(
            url,
            hint: mergedImg,
            trace: trace,
          );
          if (resolved != null && resolved.isNotEmpty) {
            finalImg = resolved;
          }
        } catch (e, st) {
          _d('resolveImage', 'ERROR (fallback) trace=$trace $e\n$st');
        }

        _d(
          'getMetadata',
          'done (fallback) title="${_clipForLog(metadata.title)}" '
              'finalImg="${_clipForLog(finalImg)}" trace=$trace',
        );

        if (!isCurrent()) return;
        _applyMetadata(
          url,
          metadata.title ?? '',
          _clip(metadata.desc ?? ''),
          state.imageUrl.isNotEmpty ? state.imageUrl : finalImg,
        );
      }
    } catch (e, st) {
      _d('fallback', 'ALP ERROR trace=$trace $e\n$st');
      if (isCurrent()) {
        emit(state.copyWith(urlFetchedStatus: UrlFetchedStatus.manual));
      }
    }
  }

  void _applyMetadata(
    String url,
    String title,
    String description,
    String? image,
  ) {
    if (state.title.isEmpty || state.title == _metadataTitle) {
      _metadataTitle = title;
    }
    if (state.description.isEmpty ||
        state.description == _metadataDescription) {
      _metadataDescription = description;
    }
    _metadataImage = imageSourceUrl(image)?.toString() ?? '';
    emit(
      state.copyWith(
        url: Url.dirty(url),
        title: _metadataTitle ?? state.title,
        description: _metadataDescription ?? state.description,
        imageUrl: _metadataImage,
        urlFetchedStatus: UrlFetchedStatus.fetched,
      ),
    );
  }

  // ----------------- Skill picking ------------------
  void resourceSkillsChanged(String skillId) {
    final base = state.resource ?? Resource();
    final updated = List<String>.from(base.skillTreeIds);
    if (updated.contains(skillId)) {
      updated.remove(skillId);
    } else {
      updated.add(skillId);
    }
    final updatedSkills = getSkillsForResource(ids: updated);
    emit(
      state.copyWith(
        resource: base.copyWith(skillTreeIds: updated),
        resourceSkills: updatedSkills,
      ),
    );
  }

  void searchSkills(String value) {
    final all = state.skills;
    if (value.isEmpty) {
      emit(state.copyWith(filteredSkills: all));
      return;
    }
    final filtered = all
        .where(
          (s) =>
              s?.skillName.toLowerCase().contains(value.toLowerCase()) ?? false,
        )
        .toList();
    emit(state.copyWith(filteredSkills: filtered));
  }

  void difficultyFilterChanged(DifficultyFilter? d) {
    emit(state.copyWith(difficultyFilter: d));
    _sortSkills(state.categoryFilter, d);
  }

  void categoryFilterChanged(CategoryFilter? c) {
    emit(state.copyWith(categoryFilter: c));
    _sortSkills(c, state.difficultyFilter);
  }

  void _sortSkills(CategoryFilter? c, DifficultyFilter? d) {
    final allSkills = state.skills;
    var list = _sortSkillsByCategory(c, allSkills);
    list = _sortSkillsByDifficulty(d, list);
    emit(state.copyWith(filteredSkills: list));
  }

  List<Skill?> _sortSkillsByCategory(CategoryFilter? c, List<Skill?> skills) {
    switch (c) {
      case CategoryFilter.All:
        return skills;
      case CategoryFilter.Husbandry:
        return skills
            .where((e) => e?.category.name == CategoryFilter.Husbandry.name)
            .toList();
      case CategoryFilter.Mounted:
        return skills
            .where((e) => e?.category.name == CategoryFilter.Mounted.name)
            .toList();
      case CategoryFilter.In_Hand:
        return skills
            .where((e) => e?.category.name == CategoryFilter.In_Hand.name)
            .toList();
      case CategoryFilter.Other:
        return skills
            .where((e) => e?.category.name == CategoryFilter.Other.name)
            .toList();
      case null:
        return skills;
    }
  }

  List<Skill?> _sortSkillsByDifficulty(
    DifficultyFilter? d,
    List<Skill?> skills,
  ) {
    switch (d) {
      case DifficultyFilter.All:
        return skills;
      case DifficultyFilter.Introductory:
        return skills
            .where(
              (e) => e?.difficulty.name == DifficultyFilter.Introductory.name,
            )
            .toList();
      case DifficultyFilter.Intermediate:
        return skills
            .where(
              (e) => e?.difficulty.name == DifficultyFilter.Intermediate.name,
            )
            .toList();
      case DifficultyFilter.Advanced:
        return skills
            .where((e) => e?.difficulty.name == DifficultyFilter.Advanced.name)
            .toList();
      case null:
        return skills;
    }
  }

  List<Skill?>? getSkillsForResource({required List<String?>? ids}) {
    if (ids == null) return null;
    final out = <Skill?>[];
    for (final s in state.skills) {
      if (ids.contains(s?.id)) out.add(s);
    }
    return out;
  }

  // ----------------- PDF mode ------------------
  Future<void> pickPdf() async {
    emit(state.copyWith(pdfPicking: true, error: '', isError: false));
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (file == null) {
        emit(state.copyWith(pdfPicking: false));
        return;
      }
      final bytes = await file.readAsBytes();
      emit(
        state.copyWith(pdfPicking: false, pdfBytes: bytes, pdfName: file.name),
      );
    } catch (e) {
      emit(
        state.copyWith(
          pdfPicking: false,
          error: 'File pick failed: $e',
          isError: true,
        ),
      );
    }
  }

  void clearPickedPdf() => emit(state.copyWith(clearPdf: true));

  // ----------------- Edit Resource ------------------
  Future<void> editResource() async {
    if (state.submitStatus == ResourceSubmitStatus.submitting) return;
    emit(state.copyWith(submitStatus: ResourceSubmitStatus.submitting));
    if (resourceWebUri(state.url.value) == null) {
      emit(
        state.copyWith(
          isError: true,
          error: 'Url is not valid',
          submitStatus: ResourceSubmitStatus.error,
        ),
      );
      return;
    }
    final editedResource = (state.resource ?? Resource()).copyWith(
      comments: state.resource?.comments ?? [],
      lastEditDate: DateTime.now(),
      name: state.title.isEmpty ? state.resource?.name : state.title,
      rating: state.resource?.rating ?? 1,
      lastEditBy: state.usersProfile?.email,
      description: state.description.isEmpty
          ? state.resource?.description
          : state.description,
      usersWhoRated:
          state.resource?.usersWhoRated ??
          [
            BaseListItem(
              isSelected: true,
              isCollapsed: false,
              id: state.usersProfile?.email,
            ),
          ],
      id: state.resource?.id ?? ViewUtils.createId(),
      numberOfRates: state.resource?.numberOfRates ?? 0,
      url: state.url.value.isEmpty ? state.resource?.url : state.url.value,
      blocksEmbedding: _blocksEmbedding(
        state.url.value.isEmpty ? state.resource?.url : state.url.value,
      ),
      skillTreeIds:
          state.resourceSkills
              ?.map((e) => e?.id)
              .whereType<String>()
              .toList() ??
          [],
      thumbnail: imageSourceUrl(state.imageUrl)?.toString(),
    );
    try {
      await _resourcesRepository.createOrUpdateResource(
        resource: editedResource,
      );
      emit(state.copyWith(submitStatus: ResourceSubmitStatus.success));
    } catch (e) {
      final msg = (e is FirebaseException)
          ? (e.message ?? 'Firebase Error')
          : 'Error';
      emit(
        state.copyWith(
          isError: true,
          error: msg,
          submitStatus: ResourceSubmitStatus.error,
        ),
      );
    }
  }

  // ----------------- Submit ------------------
  Future<void> submit() async {
    if (state.submitStatus == ResourceSubmitStatus.submitting) return;
    emit(
      state.copyWith(
        submitStatus: ResourceSubmitStatus.submitting,
        error: '',
        isError: false,
      ),
    );
    try {
      if (state.inputType == ResourceInputType.link) {
        if (!isFormValidForLink()) {
          emit(
            state.copyWith(
              submitStatus: ResourceSubmitStatus.error,
              error: hasSelectedSkills
                  ? 'Please provide a valid URL and title.'
                  : 'Select at least one related skill and enter '
                        'a valid URL and title.',
              isError: true,
            ),
          );
          return;
        }
        _debounce?.cancel();
        _metadataRequest++;
        await _saveLink();
      } else {
        if (!isFormValidForPdf()) {
          emit(
            state.copyWith(
              submitStatus: ResourceSubmitStatus.error,
              error: 'Please choose a PDF and enter a title.',
              isError: true,
            ),
          );
          return;
        }
        await _savePdf();
      }
      if (!isClosed) {
        emit(state.copyWith(submitStatus: ResourceSubmitStatus.success));
      }
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          submitStatus: ResourceSubmitStatus.error,
          isError: true,
          error: e is FirebaseException
              ? (e.message ?? 'Firebase error')
              : '$e',
        ),
      );
    }
  }

  Future<void> _saveLink() async {
    final id = state.resource?.id ?? _resourcesRepository.newId();
    final resource = linkPreview.copyWith(
      id: id,
      createdAt: DateTime.now(),
      rating: 0,
      numberOfRates: 0,
      status: ResourceStatus.published,
      usersWhoRated: [],
      comments: [],
      lastEditDate: DateTime.now(),
      authorId: state.usersProfile?.email,
      lastEditBy: state.usersProfile?.email,
      authorName: state.usersProfile?.name,
      authorPhoto: state.usersProfile?.picUrl,
    );
    await _resourcesRepository.createResourceWithServerTimestamps(
      resource: resource,
    );
  }

  Future<void> _savePdf() async {
    final bytes = state.pdfBytes!;
    final name = state.pdfName ?? 'document.pdf';
    final id = state.resource?.id ?? _resourcesRepository.newId();

    emit(state.copyWith(pdfUploading: true, pdfUploadProgress: 0));

    final ref = (_storage ?? FirebaseStorage.instance).ref().child(
      'resources/pdfs/$id/$name',
    );
    final meta = SettableMetadata(contentType: 'application/pdf');
    final uploadTask = ref.putData(bytes, meta);

    uploadTask.snapshotEvents.listen((snap) {
      final p = snap.totalBytes == 0
          ? 0.0
          : snap.bytesTransferred / snap.totalBytes;
      emit(state.copyWith(pdfUploadProgress: p));
    });

    final snapshot = await uploadTask;
    final url = await snapshot.ref.getDownloadURL();

    emit(state.copyWith(pdfUploading: false));

    final resource = Resource(
      id: id,
      type: ResourceType.pdf,
      url: url,
      name: state.title,
      createdAt: DateTime.now(),
      lastEditDate: DateTime.now(),
      authorId: state.usersProfile?.email,
      lastEditBy: state.usersProfile?.email,
      authorName: state.usersProfile?.name,
      authorPhoto: state.usersProfile?.picUrl,
      description: state.description.isNotEmpty ? state.description : null,
      skillTreeIds:
          state.resourceSkills
              ?.map((e) => e?.id)
              .whereType<String>()
              .toList() ??
          const [],
    );
    await _resourcesRepository.createResourceWithServerTimestamps(
      resource: resource,
    );
  }

  // ------------- Validation helpers -------------
  bool get hasSelectedSkills =>
      state.resourceSkills?.whereType<Skill>().any(
        (skill) => skill.id.isNotEmpty,
      ) ??
      false;

  bool isFormValidForLink() =>
      state.title.trim().isNotEmpty &&
      resourceWebUri(state.url.value) != null &&
      hasSelectedSkills;
  bool isFormValidForPdf() => state.title.isNotEmpty && state.pdfBytes != null;

  void clearMetaDataError() =>
      emit(state.copyWith(urlFetchedStatus: UrlFetchedStatus.manual));

  void clearError() => emit(
    state.copyWith(
      error: '',
      isError: false,
      submitStatus: ResourceSubmitStatus.initial,
    ),
  );

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
