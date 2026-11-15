import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'open_library_service.dart';

enum DownloadTaskStatus {
  idle,
  downloading,
  completed,
  failed,
  canceled,
}

class ActiveDownloadTask {
  final String bookId;
  final String title;
  final String author;
  final String format; // 'epub' | 'pdf'
  final String downloadUrl;
  final double progress; // 0.0 to 1.0 (-1.0 if indeterminate)
  final int downloadedBytes;
  final int totalBytes;
  final DownloadTaskStatus status;
  final String? localFilePath;
  final String? localUri;
  final int? nativeDownloadId;
  final String? errorMessage;

  const ActiveDownloadTask({
    required this.bookId,
    required this.title,
    required this.author,
    required this.format,
    required this.downloadUrl,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = -1,
    this.status = DownloadTaskStatus.downloading,
    this.localFilePath,
    this.localUri,
    this.nativeDownloadId,
    this.errorMessage,
  });

  bool get isRunning => status == DownloadTaskStatus.downloading;
  bool get isCompleted => status == DownloadTaskStatus.completed;
  bool get isFailed => status == DownloadTaskStatus.failed;

  ActiveDownloadTask copyWith({
    String? bookId,
    String? title,
    String? author,
    String? format,
    String? downloadUrl,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    DownloadTaskStatus? status,
    String? localFilePath,
    String? localUri,
    int? nativeDownloadId,
    String? errorMessage,
  }) {
    return ActiveDownloadTask(
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      format: format ?? this.format,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      localFilePath: localFilePath ?? this.localFilePath,
      localUri: localUri ?? this.localUri,
      nativeDownloadId: nativeDownloadId ?? this.nativeDownloadId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DownloadResult {
  final bool success;
  final String? filePath;
  final String? localUri;
  final int? nativeDownloadId;
  final String? message;

  const DownloadResult({
    required this.success,
    this.filePath,
    this.localUri,
    this.nativeDownloadId,
    this.message,
  });
}

class EbookDownloadService {
  static const MethodChannel _channel = MethodChannel('com.example.readers_hub/download');

  EbookDownloadService._() {
    _initNativeChannel();
  }

  static final EbookDownloadService instance = EbookDownloadService._();

  /// Reactive notifier for active download across all screens and bottom sheets.
  final ValueNotifier<ActiveDownloadTask?> currentTask = ValueNotifier(null);

  Timer? _pollingTimer;

  void _initNativeChannel() {
    if (!kIsWeb && Platform.isAndroid) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onDownloadStatusUpdate') {
          final args = call.arguments as Map?;
          final id = args?['downloadId'] as int?;
          final info = args?['info'] as Map?;
          if (id != null && info != null && currentTask.value?.nativeDownloadId == id) {
            _handleNativeStatusUpdate(id, info);
          }
        }
      });
    }
  }

  void _handleNativeStatusUpdate(int downloadId, Map info) {
    final statusStr = info['status'] as String? ?? '';
    final progress = (info['progress'] as num?)?.toDouble() ?? -1.0;
    final downloadedBytes = (info['downloadedBytes'] as num?)?.toInt() ?? 0;
    final totalBytes = (info['totalBytes'] as num?)?.toInt() ?? -1;
    final localUri = info['localUri'] as String?;

    if (currentTask.value == null || currentTask.value?.nativeDownloadId != downloadId) {
      return;
    }

    if (statusStr == 'completed') {
      _stopPolling();
      currentTask.value = currentTask.value!.copyWith(
        status: DownloadTaskStatus.completed,
        progress: 1.0,
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        localUri: localUri,
      );
    } else if (statusStr == 'failed') {
      _stopPolling();
      currentTask.value = currentTask.value!.copyWith(
        status: DownloadTaskStatus.failed,
        errorMessage: 'Download failed on device',
      );
    } else if (statusStr == 'running' || statusStr == 'pending') {
      currentTask.value = currentTask.value!.copyWith(
        status: DownloadTaskStatus.downloading,
        progress: progress,
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        localUri: localUri,
      );
    }
  }

  /// Request runtime notification permission on Android 13+
  Future<void> requestNotificationPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('requestNotificationPermission');
      } catch (e) {
        debugPrint('Could not request notification permission: $e');
      }
    }
  }

  /// Returns the target directory for downloaded books.
  Future<Directory> getDownloadsDirectory() async {
    Directory? baseDir;
    if (!kIsWeb && Platform.isAndroid) {
      baseDir = await getExternalStorageDirectory();
    }
    baseDir ??= await getApplicationDocumentsDirectory();

    final booksDir = Directory('${baseDir.path}/Liread_Books');
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return booksDir;
  }

  /// Sanitizes book title into a safe filename.
  String sanitizeFilename(String title, String format) {
    final clean = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    final safeName = clean.isEmpty ? 'book' : (clean.length > 50 ? clean.substring(0, 50) : clean);
    return '$safeName.$format';
  }

  /// Direct 1-click book download. Runs with background system notifications on Android,
  /// and updates [currentTask] so the user can explore the app or exit the APK.
  Future<DownloadResult> downloadBook({
    required OpenLibraryBook book,
    String format = 'epub',
    void Function(double progress)? onProgress,
  }) async {
    final downloadUrl = format.toLowerCase() == 'pdf'
        ? (book.pdfDownloadUrl ?? book.epubDownloadUrl)
        : (book.epubDownloadUrl ?? book.pdfDownloadUrl);

    if (downloadUrl == null || downloadUrl.isEmpty) {
      return const DownloadResult(
        success: false,
        message: 'No direct download link available for this edition.',
      );
    }

    final filename = sanitizeFilename(book.title, format);
    final mimeType = format.toLowerCase() == 'pdf' ? 'application/pdf' : 'application/epub+zip';

    // On Web, browsers trigger download via external URL directly
    if (kIsWeb) {
      try {
        final uri = Uri.parse(downloadUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return const DownloadResult(
          success: true,
          message: 'Download initiated in browser.',
        );
      } catch (e) {
        return DownloadResult(success: false, message: 'Browser download failed: $e');
      }
    }

    // Initialize the active task for in-app reactive tracking
    final task = ActiveDownloadTask(
      bookId: book.id,
      title: book.title,
      author: book.author,
      format: format,
      downloadUrl: downloadUrl,
    );
    currentTask.value = task;

    // ── Android Native Background Download via DownloadManager ──────
    if (Platform.isAndroid) {
      try {
        final downloadId = await _channel.invokeMethod<int>('enqueueDownload', {
          'url': downloadUrl,
          'title': book.title,
          'filename': filename,
          'mimeType': mimeType,
        });

        if (downloadId != null && downloadId > 0) {
          currentTask.value = task.copyWith(
            nativeDownloadId: downloadId,
            status: DownloadTaskStatus.downloading,
          );

          // Poll DownloadManager status periodically while app is open
          final completer = Completer<DownloadResult>();
          _startPolling(downloadId, onProgress, completer);

          return await completer.future;
        }
      } catch (e) {
        debugPrint('Native DownloadManager failed or unavailable, falling back to Dart HTTP download: $e');
      }
    }

    // ── Dart In-App HTTP Stream Fallback (iOS, Desktop, or Test Harness) ──
    return await _downloadViaDartHttp(
      book: book,
      downloadUrl: downloadUrl,
      filename: filename,
      format: format,
      onProgress: onProgress,
    );
  }

  void _startPolling(
    int downloadId,
    void Function(double progress)? onProgress,
    Completer<DownloadResult> completer,
  ) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      try {
        final result = await _channel.invokeMapMethod<String, dynamic>(
          'getDownloadProgress',
          {'downloadId': downloadId},
        );

        if (result == null) return;

        final status = result['status'] as String? ?? '';
        final progress = (result['progress'] as num?)?.toDouble() ?? -1.0;
        final downloadedBytes = (result['downloadedBytes'] as num?)?.toInt() ?? 0;
        final totalBytes = (result['totalBytes'] as num?)?.toInt() ?? -1;
        final localUri = result['localUri'] as String?;

        if (progress >= 0.0) {
          onProgress?.call(progress);
        }

        if (status == 'completed') {
          timer.cancel();
          currentTask.value = currentTask.value?.copyWith(
            status: DownloadTaskStatus.completed,
            progress: 1.0,
            downloadedBytes: totalBytes > 0 ? totalBytes : downloadedBytes,
            totalBytes: totalBytes,
            localUri: localUri,
          );
          if (!completer.isCompleted) {
            completer.complete(DownloadResult(
              success: true,
              localUri: localUri,
              nativeDownloadId: downloadId,
              message: 'Saved to Downloads/Liread_Books',
            ));
          }
        } else if (status == 'failed') {
          timer.cancel();
          currentTask.value = currentTask.value?.copyWith(
            status: DownloadTaskStatus.failed,
            errorMessage: 'Download failed',
          );
          if (!completer.isCompleted) {
            completer.complete(const DownloadResult(
              success: false,
              message: 'Android DownloadManager encountered an error.',
            ));
          }
        } else {
          currentTask.value = currentTask.value?.copyWith(
            status: DownloadTaskStatus.downloading,
            progress: progress,
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            localUri: localUri,
          );
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<DownloadResult> _downloadViaDartHttp({
    required OpenLibraryBook book,
    required String downloadUrl,
    required String filename,
    required String format,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final uri = Uri.parse(downloadUrl);
      final client = http.Client();
      final request = http.Request('GET', uri)
        ..headers['User-Agent'] = 'LireadMobile/1.0 (contact: liread@app.local)';

      final response = await client.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final contentLength = response.contentLength ?? 0;
        final targetDir = await getDownloadsDirectory();
        final file = File('${targetDir.path}/$filename');

        final sink = file.openWrite();
        int bytesReceived = 0;

        await response.stream.listen(
          (chunk) {
            bytesReceived += chunk.length;
            sink.add(chunk);
            final p = contentLength > 0 ? (bytesReceived / contentLength) : -1.0;
            if (p >= 0 && onProgress != null) onProgress(p);
            currentTask.value = currentTask.value?.copyWith(
              progress: p,
              downloadedBytes: bytesReceived,
              totalBytes: contentLength,
            );
          },
          cancelOnError: true,
        ).asFuture();

        await sink.flush();
        await sink.close();

        currentTask.value = currentTask.value?.copyWith(
          status: DownloadTaskStatus.completed,
          progress: 1.0,
          localFilePath: file.path,
        );

        return DownloadResult(
          success: true,
          filePath: file.path,
          message: 'Saved to ${file.path}',
        );
      } else {
        currentTask.value = currentTask.value?.copyWith(
          status: DownloadTaskStatus.failed,
          errorMessage: 'Server returned HTTP ${response.statusCode}',
        );
        return DownloadResult(
          success: false,
          message: 'Server returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
      currentTask.value = currentTask.value?.copyWith(
        status: DownloadTaskStatus.failed,
        errorMessage: e.toString(),
      );
      return DownloadResult(
        success: false,
        message: 'Download failed: $e',
      );
    }
  }

  /// Cancel current download.
  Future<void> cancelCurrentDownload() async {
    final task = currentTask.value;
    if (task == null) return;

    _stopPolling();

    if (task.nativeDownloadId != null && !kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('cancelDownload', {
          'downloadId': task.nativeDownloadId,
        });
      } catch (e) {
        debugPrint('Error canceling native download: $e');
      }
    }

    currentTask.value = null;
  }

  /// Launch external viewer or file explorer for the downloaded book.
  Future<bool> openDownloadedBook(
    String filePathOrUri, {
    int? downloadId,
    String? format,
  }) async {
    try {
      if (kIsWeb) return false;

      final mimeType = (format?.toLowerCase() == 'pdf' || filePathOrUri.endsWith('.pdf'))
          ? 'application/pdf'
          : 'application/epub+zip';

      // On Android, use native Intent with content URI to prevent FileUriExposedException
      if (Platform.isAndroid) {
        try {
          final id = downloadId ?? currentTask.value?.nativeDownloadId;
          final opened = await _channel.invokeMethod<bool>('openDownloadedFile', {
            'downloadId': id,
            'uri': filePathOrUri,
            'mimeType': mimeType,
          });
          if (opened == true) return true;
        } catch (e) {
          debugPrint('Native open failed, attempting launchUrl: $e');
        }
      }

      final uri = filePathOrUri.startsWith('content://') || filePathOrUri.startsWith('file://')
          ? Uri.parse(filePathOrUri)
          : Uri.file(filePathOrUri);

      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error opening book file: $e');
      return false;
    }
  }

  /// Clear the active task banner.
  void dismissTask() {
    currentTask.value = null;
  }
}
