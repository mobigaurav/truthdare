import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'remote_config_service.dart';

final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});

final remoteConfigInitProvider = FutureProvider<void>((ref) async {
  final rc = ref.read(remoteConfigServiceProvider);
  await rc.init();
});
