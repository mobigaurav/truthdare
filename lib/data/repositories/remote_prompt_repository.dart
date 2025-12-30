import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/telemetry/app_analytics.dart';
import '../models/prompt.dart';

class RemotePromptRepository {
  static const _cacheKey = 'remote_prompts_cache_v1';
  static const _cacheUpdatedAtKey = 'remote_prompts_cache_updatedAt';
  static const _cacheVersionKey = 'remote_prompts_cache_version';
  static const _cacheCountKey = 'remote_prompts_cache_count';

  /// Load prompts with this priority:
  /// 1) cached remote (if exists)
  /// 2) bundled asset prompts.json
  Future<List<Prompt>> loadPromptsFromCacheOrAsset({
    required String assetPath,
  }) async {
    final sp = await SharedPreferences.getInstance();
    final cached = sp.getString(_cacheKey);

    if (cached != null && cached.isNotEmpty) {
      try {
        return _parsePromptsFromJson(cached);
      } catch (e) {
        // fall through to asset
        await AppAnalytics.remotePromptsFetch(
          status: 'fail_parse_cache',
          error: _shortErr(e),
        );
      }
    }

    final raw = await rootBundle.loadString(assetPath);
    return _parsePromptsFromJson(raw);
  }

  /// Fetch remote prompts and cache them.
  /// Returns true if cache updated (content changed).
  Future<bool> fetchAndCacheRemotePrompts(String url) async {
    if (url.trim().isEmpty) return false;

    final uri = Uri.tryParse(url);
    if (uri == null) {
      await AppAnalytics.remotePromptsFetch(
        status: 'fail_invalid_url',
        error: 'invalid_url',
      );
      return false;
    }

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        await AppAnalytics.remotePromptsFetch(
          status: 'fail_http',
          host: uri.host,
          httpStatus: res.statusCode,
        );
        return false;
      }

      // Parse root (for telemetry fields)
      Map<String, dynamic>? root;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          root = decoded;
        }
      } catch (e) {
        await AppAnalytics.remotePromptsFetch(
          status: 'fail_parse_remote',
          host: uri.host,
          error: _shortErr(e),
        );
        return false;
      }

      final version = root?['version']?.toString();
      final updatedAt = root?['updatedAt']?.toString();

      // Validate JSON + parse prompts (so we don't cache bad payload)
      final prompts = _parsePromptsFromJson(res.body);
      if (prompts.isEmpty) {
        await AppAnalytics.remotePromptsFetch(
          status: 'fail_empty',
          host: uri.host,
          version: version,
          updatedAt: updatedAt,
          count: 0,
        );
        return false;
      }

      final sp = await SharedPreferences.getInstance();

      // ✅ Prevent useless cache rewrites / provider invalidation
      final existingBody = sp.getString(_cacheKey);
      if (existingBody != null && existingBody == res.body) {
        await AppAnalytics.remotePromptsFetch(
          status: 'not_modified',
          host: uri.host,
          version: version,
          updatedAt: updatedAt,
          count: prompts.length,
        );
        return false;
      }

      // Cache JSON
      await sp.setString(_cacheKey, res.body);

      // Store metadata
      if (updatedAt != null) {
        await sp.setString(_cacheUpdatedAtKey, updatedAt);
      }
      if (version != null) {
        await sp.setString(_cacheVersionKey, version);
      }
      await sp.setInt(_cacheCountKey, prompts.length);

      await AppAnalytics.remotePromptsFetch(
        status: 'success',
        host: uri.host,
        version: version,
        updatedAt: updatedAt,
        count: prompts.length,
      );

      return true;
    } catch (e) {
      await AppAnalytics.remotePromptsFetch(
        status: 'fail_exception',
        host: uri.host,
        error: _shortErr(e),
      );
      return false;
    }
  }

  Future<String?> getCachedUpdatedAt() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_cacheUpdatedAtKey);
  }

  Future<String?> getCachedVersion() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_cacheVersionKey);
  }

  Future<int?> getCachedCount() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_cacheCountKey);
  }

  List<Prompt> _parsePromptsFromJson(String raw) {
    final decoded = jsonDecode(raw);

    // Support two formats:
    // 1) { prompts: [...] }  (remote)
    // 2) [ ... ]            (legacy asset)
    final List<dynamic> list = decoded is Map<String, dynamic>
        ? (decoded['prompts'] as List<dynamic>? ?? const [])
        : (decoded as List<dynamic>);

    return list
        .map((e) => Prompt.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  String _shortErr(Object e) {
    final s = e.toString();
    return s.length > 120 ? s.substring(0, 120) : s;
  }
}
