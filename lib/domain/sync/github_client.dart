import 'dart:convert';

import 'package:http/http.dart' as http;

/// GitHub 侧的错误，带一句人话解释。
class GitHubException implements Exception {
  GitHubException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  String get friendly => switch (statusCode) {
        401 => 'Token 无效或已过期',
        403 => '没有写权限（Token 需要 repo scope）',
        404 => '仓库不存在，或这个 Token 看不到它',
        409 || 422 => '远端刚被别的设备改过，请再同步一次',
        _ => message,
      };

  @override
  String toString() {
    // 0 = 本地就失败了（没网、地址写错），不该显示成 HTTP 状态码
    if (statusCode == 0) return message;
    return '$friendly（HTTP $statusCode）$message';
  }
}

/// 引用更新失败 = 有人抢先推了，调用方应该重新拉一次再试。
class SyncConflictException extends GitHubException {
  SyncConflictException(super.statusCode, super.message);
}

class RepoInfo {
  const RepoInfo({required this.fullName, required this.defaultBranch, required this.private});
  final String fullName;
  final String defaultBranch;
  final bool private;
}

class WriteOutcome {
  const WriteOutcome({required this.commitSha, required this.branch});
  final String commitSha;
  final String branch;
}

/// 极简 GitHub Git Data API 客户端。
///
/// 用 blob → tree → commit → ref 这条链路，而不是 Contents API：
/// 后者单文件上限 1MB，一本 40 万字的书就会超。
class GitHubClient {
  GitHubClient({
    required this.owner,
    required this.repo,
    required this.token,
    this.branch = 'main',
    http.Client? httpClient,
    Uri? apiBase,
  })  : _http = httpClient ?? http.Client(),
        _base = apiBase ?? Uri.parse('https://api.github.com');

  final String owner;
  final String repo;
  final String token;
  final String branch;
  final http.Client _http;
  final Uri _base;

  /// 接受 `owner/repo`、`https://github.com/owner/repo`、带或不带 `.git`。
  static (String, String)? parseRepo(String input) {
    var text = input.trim();
    if (text.isEmpty) return null;
    text = text.replaceAll(RegExp(r'^https?://[^/]+/'), '');
    text = text.replaceAll(RegExp(r'^github\.com/'), '');
    text = text.replaceAll(RegExp(r'\.git$'), '');
    text = text.replaceAll(RegExp(r'/+$'), '');
    final parts = text.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length < 2) return null;
    return (parts[0], parts[1]);
  }

  Map<String, String> get _headers => {
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer $token',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'mopu-app',
      };

  Uri _uri(String path) => Uri.parse('${_base.toString().replaceAll(RegExp(r'/$'), '')}$path');

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
    bool allow404 = false,
  }) async {
    http.Response response;
    final uri = _uri(path);
    try {
      response = switch (method) {
        'GET' => await _http.get(uri, headers: _headers),
        'POST' => await _http.post(uri, headers: _headers, body: jsonEncode(body ?? {})),
        'PATCH' => await _http.patch(uri, headers: _headers, body: jsonEncode(body ?? {})),
        _ => throw ArgumentError('不支持的 method: $method'),
      };
    } catch (error) {
      throw GitHubException(0, '连不上 GitHub：$error');
    }

    if (response.statusCode == 404 && allow404) {
      return const {};
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final hint = _extractMessage(response.body);
      if ((response.statusCode == 409 || response.statusCode == 422) &&
          (method == 'PATCH' || path.contains('/git/refs'))) {
        throw SyncConflictException(response.statusCode, hint);
      }
      throw GitHubException(response.statusCode, hint);
    }
    if (response.body.isEmpty) return const {};
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return decoded is Map ? decoded.cast<String, dynamic>() : {'value': decoded};
  }

  String _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) return '：${decoded['message']}';
    } catch (_) {
      // 忽略
    }
    return body.length > 120 ? body.substring(0, 120) : body;
  }

  // ───────────────────────────── 读 ─────────────────────────────

  Future<RepoInfo> repoInfo() async {
    final json = await _send('GET', '/repos/$owner/$repo');
    return RepoInfo(
      fullName: '${json['full_name'] ?? '$owner/$repo'}',
      defaultBranch: '${json['default_branch'] ?? 'main'}',
      private: json['private'] == true,
    );
  }

  /// 当前分支头指针；空仓库返回 null。
  Future<String?> headSha({String? onBranch}) async {
    final target = onBranch ?? branch;
    final json = await _send(
      'GET',
      '/repos/$owner/$repo/git/ref/heads/$target',
      allow404: true,
    );
    final object = json['object'];
    if (object is Map && object['sha'] is String) return object['sha'] as String;
    return null;
  }

  /// 读一个文件；不存在返回 null。
  Future<String?> readText(String path) async {
    final head = await headSha();
    if (head == null) return null;

    final commit = await _send('GET', '/repos/$owner/$repo/git/commits/$head');
    final treeSha = (commit['tree'] as Map?)?['sha'];
    if (treeSha is! String) return null;

    final tree = await _send('GET', '/repos/$owner/$repo/git/trees/$treeSha');
    final entries = tree['tree'];
    if (entries is! List) return null;

    String? blobSha;
    for (final entry in entries) {
      if (entry is Map && entry['path'] == path && entry['type'] == 'blob') {
        blobSha = entry['sha'] as String?;
        break;
      }
    }
    if (blobSha == null) return null;

    final blob = await _send('GET', '/repos/$owner/$repo/git/blobs/$blobSha');
    final content = blob['content'];
    if (content is! String) return null;
    return utf8.decode(base64.decode(content.replaceAll('\n', '')));
  }

  // ───────────────────────────── 写 ─────────────────────────────

  /// 写入一个文件并在分支上产生一个 commit。
  ///
  /// [expectHead] 传入读到的头指针：如果期间远端变了，PATCH ref 会失败并抛
  /// [SyncConflictException]，调用方重来一次即可，不会覆盖别人的提交。
  Future<WriteOutcome> writeText({
    required String path,
    required String content,
    required String message,
    String? expectHead,
  }) async {
    final head = expectHead ?? await headSha();

    final blob = await _send('POST', '/repos/$owner/$repo/git/blobs', body: {
      'content': base64.encode(utf8.encode(content)),
      'encoding': 'base64',
    });
    final blobSha = blob['sha'] as String;

    final treeBody = <String, dynamic>{
      'tree': [
        {'path': path, 'mode': '100644', 'type': 'blob', 'sha': blobSha},
      ],
    };

    if (head == null) {
      // 空仓库：第一个 commit 没有父节点
      final tree = await _send('POST', '/repos/$owner/$repo/git/trees', body: treeBody);
      final treeSha = tree['sha'] as String;
      final commit = await _send('POST', '/repos/$owner/$repo/git/commits', body: {
        'message': message,
        'tree': treeSha,
        'parents': <String>[],
      });
      final commitSha = commit['sha'] as String;
      await _send('POST', '/repos/$owner/$repo/git/refs', body: {
        'ref': 'refs/heads/$branch',
        'sha': commitSha,
      });
      return WriteOutcome(commitSha: commitSha, branch: branch);
    }

    final parent = await _send('GET', '/repos/$owner/$repo/git/commits/$head');
    final baseTree = (parent['tree'] as Map?)?['sha'];
    treeBody['base_tree'] = baseTree;

    final tree = await _send('POST', '/repos/$owner/$repo/git/trees', body: treeBody);
    final treeSha = tree['sha'] as String;

    final commit = await _send('POST', '/repos/$owner/$repo/git/commits', body: {
      'message': message,
      'tree': treeSha,
      'parents': [head],
    });
    final commitSha = commit['sha'] as String;

    await _send('PATCH', '/repos/$owner/$repo/git/refs/heads/$branch', body: {
      'sha': commitSha,
      'force': false,
    });

    return WriteOutcome(commitSha: commitSha, branch: branch);
  }
}
