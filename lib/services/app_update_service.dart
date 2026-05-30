import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'app_links.dart';
import 'app_version.dart';

enum AppUpdatePhase { downloading, extracting, complete }

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.tagName,
    required this.releasePageUrl,
    required this.isPrerelease,
    required this.publishedAt,
    required this.releaseNotes,
    this.assetName,
    this.downloadUrl,
  });

  final String version;
  final String tagName;
  final Uri releasePageUrl;
  final bool isPrerelease;
  final DateTime? publishedAt;
  final String releaseNotes;
  final String? assetName;
  final Uri? downloadUrl;

  bool get hasDownloadAsset => downloadUrl != null;
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message, {this.actionLabel, this.actionUrl});

  final String message;
  final String? actionLabel;
  final Uri? actionUrl;

  @override
  String toString() => message;
}

class AppUpdateService {
  AppUpdateService({
    http.Client? client,
    this.owner = AppLinks.repositoryOwner,
    this.repo = AppLinks.repositoryName,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final String owner;
  final String repo;
  final http.Client _client;
  final bool _ownsClient;

  static const _stableChannel = 'stable';

  Uri get releasePageUrl => Uri.https('github.com', '/$owner/$repo/releases');

  Future<AppUpdateInfo?> checkForUpdate({
    String currentReleaseName = FlowReadVersion.releaseName,
    String currentChannel = FlowReadVersion.channel,
  }) async {
    final currentVersion = _ReleaseVersion.parse(currentReleaseName);
    if (currentVersion == null) {
      throw AppUpdateException('当前版本号无法识别：$currentReleaseName');
    }

    final uri = Uri.https('api.github.com', '/repos/$owner/$repo/releases', {
      'per_page': '20',
    });
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _responseException(response);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const AppUpdateException('GitHub Release 返回格式异常');
    }

    final updates = <_ParsedRelease>[];
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      if (item['draft'] == true) continue;

      final version = _versionFromRelease(item);
      if (version == null) continue;
      if (!_isAllowedChannel(
        version,
        currentChannel,
        githubPrerelease: item['prerelease'] == true,
      )) {
        continue;
      }
      if (version.compareTo(currentVersion) <= 0) continue;

      final info = _infoFromRelease(item, version);
      if (info != null) {
        updates.add(_ParsedRelease(version: version, info: info));
      }
    }

    updates.sort((a, b) => b.version.compareTo(a.version));
    return updates.firstOrNull?.info;
  }

  Future<File> downloadZip(
    AppUpdateInfo update, {
    void Function(AppUpdatePhase phase, double progress)? onProgress,
  }) async {
    final downloadUrl = update.downloadUrl;
    if (downloadUrl == null) {
      throw AppUpdateException('该版本没有可下载的资源文件');
    }

    final tempDir = await getTemporaryDirectory();
    final downloadDir = Directory(
      '${tempDir.path}/flow_read_update_${update.version}',
    );
    if (downloadDir.existsSync()) {
      downloadDir.deleteSync(recursive: true);
    }
    downloadDir.createSync(recursive: true);

    final zipPath = '${downloadDir.path}/${update.assetName ?? 'update.zip'}';
    final zipFile = File(zipPath);
    final request = http.Request('GET', downloadUrl);
    request.headers.addAll(_headers);

    final streamedResponse = await _client.send(request);
    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      _cleanupDir(downloadDir);
      throw _responseException(
        http.Response(
          await streamedResponse.stream.bytesToString(),
          streamedResponse.statusCode,
        ),
      );
    }

    final totalBytes = streamedResponse.contentLength ?? 0;
    var receivedBytes = 0;

    onProgress?.call(AppUpdatePhase.downloading, 0);

    final sink = zipFile.openWrite();
    try {
      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress?.call(
            AppUpdatePhase.downloading,
            receivedBytes / totalBytes,
          );
        }
      }
    } finally {
      await sink.close();
    }

    return zipFile;
  }

  Future<String> extractAndFindApp(File zipFile, String extractDir) async {
    await extractFileToDisk(zipFile.path, extractDir);
    return _findAppBundle(extractDir);
  }

  Future<String> downloadAndExtract(
    AppUpdateInfo update, {
    void Function(AppUpdatePhase phase, double progress)? onProgress,
  }) async {
    final zipFile = await downloadZip(update, onProgress: onProgress);

    onProgress?.call(AppUpdatePhase.extracting, 0);

    final tempDir = await getTemporaryDirectory();
    final extractDir = '${tempDir.path}/flow_read_extracted_${update.version}';
    final extractDirObj = Directory(extractDir);
    if (extractDirObj.existsSync()) {
      extractDirObj.deleteSync(recursive: true);
    }
    extractDirObj.createSync(recursive: true);

    final appPath = await extractAndFindApp(zipFile, extractDir);
    final appDir = Directory(appPath);
    if (!appDir.existsSync()) {
      throw AppUpdateException(
        '下载的文件中未找到可安装的应用',
        actionLabel: '打开发布页',
        actionUrl: update.releasePageUrl,
      );
    }

    onProgress?.call(AppUpdatePhase.complete, 1);

    zipFile.parent.deleteSync(recursive: true);

    return appPath;
  }

  static void _cleanupDir(Directory dir) {
    try {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    } catch (_) {}
  }

  static String _findAppBundle(String rootPath) {
    final dir = Directory(rootPath);
    if (!dir.existsSync()) return '';

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is Directory &&
          entity.path.endsWith('.app') &&
          File('${entity.path}/Contents/Info.plist').existsSync()) {
        return entity.path;
      }
    }

    return '';
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Map<String, String> get _headers => {
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'FlowRead/${FlowReadVersion.releaseName}',
  };

  static _ReleaseVersion? _versionFromRelease(Map<String, dynamic> release) {
    final tagName = release['tag_name'] as String?;
    final name = release['name'] as String?;
    return _ReleaseVersion.parse(tagName ?? '') ??
        _ReleaseVersion.parse(name ?? '');
  }

  static bool _isAllowedChannel(
    _ReleaseVersion version,
    String channel, {
    required bool githubPrerelease,
  }) {
    final isPrerelease = version.isPrerelease || githubPrerelease;
    final normalized = channel.trim().toLowerCase();
    if (normalized.isEmpty || normalized == _stableChannel) {
      return !isPrerelease;
    }
    return !isPrerelease ||
        version.prerelease == normalized ||
        version.prerelease.startsWith('$normalized.');
  }

  static AppUpdateInfo? _infoFromRelease(
    Map<String, dynamic> release,
    _ReleaseVersion version,
  ) {
    final tagName = release['tag_name'] as String?;
    final htmlUrl = release['html_url'] as String?;
    if (tagName == null || tagName.isEmpty || htmlUrl == null) {
      return null;
    }

    final releasePageUrl = Uri.tryParse(htmlUrl);
    if (releasePageUrl == null) return null;

    final asset = _pickMacosAsset(release['assets']);
    return AppUpdateInfo(
      version: version.releaseName,
      tagName: tagName,
      releasePageUrl: releasePageUrl,
      isPrerelease: release['prerelease'] == true || version.isPrerelease,
      publishedAt: _parsePublishedAt(release['published_at']),
      releaseNotes: (release['body'] as String?)?.trim() ?? '',
      assetName: asset?.name,
      downloadUrl: asset?.downloadUrl,
    );
  }

  static _ReleaseAsset? _pickMacosAsset(Object? rawAssets) {
    if (rawAssets is! List) return null;

    final assets = rawAssets
        .whereType<Map<String, dynamic>>()
        .map(_ReleaseAsset.fromJson)
        .nonNulls
        .toList();
    if (assets.isEmpty) return null;

    final zipAssets = assets.where((asset) {
      return asset.name.toLowerCase().endsWith('.zip');
    }).toList();

    return zipAssets.firstWhereOrNull((asset) {
          final name = asset.name.toLowerCase();
          return name.contains('macos') || name.contains('darwin');
        }) ??
        zipAssets.firstOrNull ??
        assets.first;
  }

  static DateTime? _parsePublishedAt(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }

  AppUpdateException _responseException(http.Response response) {
    String? message;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        message = decoded['message'] as String?;
      }
    } catch (_) {
      message = null;
    }

    if (response.statusCode == 403) {
      return AppUpdateException(
        message == null
            ? 'GitHub Release 请求受限，请稍后再试'
            : 'GitHub Release 请求受限：$message',
        actionLabel: '打开 Release 页面',
        actionUrl: releasePageUrl,
      );
    }
    if (response.statusCode == 404) {
      return AppUpdateException(
        '无法访问 GitHub Release，仓库可能是私有的，或更新源地址未公开。',
        actionLabel: '打开 Release 页面',
        actionUrl: releasePageUrl,
      );
    }
    return AppUpdateException(
      message == null
          ? '检查更新失败：HTTP ${response.statusCode}'
          : '检查更新失败：$message',
      actionLabel: '打开 Release 页面',
      actionUrl: releasePageUrl,
    );
  }
}

class _ParsedRelease {
  const _ParsedRelease({required this.version, required this.info});

  final _ReleaseVersion version;
  final AppUpdateInfo info;
}

class _ReleaseAsset {
  const _ReleaseAsset({required this.name, required this.downloadUrl});

  final String name;
  final Uri downloadUrl;

  static _ReleaseAsset? fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final url = json['browser_download_url'] as String?;
    if (name == null || url == null) return null;

    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    return _ReleaseAsset(name: name, downloadUrl: uri);
  }
}

class _ReleaseVersion implements Comparable<_ReleaseVersion> {
  const _ReleaseVersion({
    required this.major,
    required this.minor,
    required this.patch,
    required this.prerelease,
  });

  final int major;
  final int minor;
  final int patch;
  final String prerelease;

  bool get isPrerelease => prerelease.isNotEmpty;

  String get releaseName {
    final base = '$major.$minor.$patch';
    return isPrerelease ? '$base-$prerelease' : base;
  }

  static _ReleaseVersion? parse(String value) {
    final match = RegExp(
      r'(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?',
    ).firstMatch(value.trim());
    if (match == null) return null;

    return _ReleaseVersion(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
      prerelease: match.group(4)?.toLowerCase() ?? '',
    );
  }

  @override
  int compareTo(_ReleaseVersion other) {
    final majorCompare = major.compareTo(other.major);
    if (majorCompare != 0) return majorCompare;

    final minorCompare = minor.compareTo(other.minor);
    if (minorCompare != 0) return minorCompare;

    final patchCompare = patch.compareTo(other.patch);
    if (patchCompare != 0) return patchCompare;

    if (!isPrerelease && other.isPrerelease) return 1;
    if (isPrerelease && !other.isPrerelease) return -1;
    if (!isPrerelease && !other.isPrerelease) return 0;

    return _comparePrerelease(prerelease, other.prerelease);
  }

  static int _comparePrerelease(String a, String b) {
    final leftParts = a.split('.');
    final rightParts = b.split('.');
    final length = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;

    for (var i = 0; i < length; i++) {
      if (i >= leftParts.length) return -1;
      if (i >= rightParts.length) return 1;

      final left = leftParts[i];
      final right = rightParts[i];
      final leftNumber = int.tryParse(left);
      final rightNumber = int.tryParse(right);

      if (leftNumber != null && rightNumber != null) {
        final compare = leftNumber.compareTo(rightNumber);
        if (compare != 0) return compare;
        continue;
      }
      if (leftNumber != null) return -1;
      if (rightNumber != null) return 1;

      final compare = left.compareTo(right);
      if (compare != 0) return compare;
    }
    return 0;
  }
}

extension _FirstWhereOrNullExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T value) test) {
    for (final value in this) {
      if (test(value)) return value;
    }
    return null;
  }
}
