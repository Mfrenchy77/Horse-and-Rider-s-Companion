export 'curriculum_file_downloader_stub.dart'
    if (dart.library.html) 'curriculum_file_downloader_web.dart'
    if (dart.library.js_interop) 'curriculum_file_downloader_web.dart';
