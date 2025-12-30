import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final _rc = FirebaseRemoteConfig.instance;

  bool _initialized = false;
  Future<void>? _initFuture;

  Future<void> init() {
    // ✅ Ensure init is only executed once even if called multiple times
    if (_initialized) return Future.value();
    _initFuture ??= _initInternal();
    return _initFuture!;
  }

  Future<void> _initInternal() async {
    await _rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 6),
        minimumFetchInterval: const Duration(hours: 6),
      ),
    );

    await _rc.setDefaults({
      'interstitial_every_n_prompts': 5,
      'remote_prompts_url': '',
    });

    await _rc.fetchAndActivate();
    _initialized = true;
  }

  int get interstitialEveryN => _rc.getInt('interstitial_every_n_prompts');
  String get remotePromptsUrl => _rc.getString('remote_prompts_url');
}
