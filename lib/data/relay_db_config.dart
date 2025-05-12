import 'package:flutter/services.dart';
import 'package:relay_sdk/worker/worker_config.dart';

class RelayDBConfig extends WorkerConfig {
  RootIsolateToken rootIsolateToken;

  String appName;

  RelayDBConfig({
    required this.rootIsolateToken,
    required super.sendPort,
    required this.appName,
  });
}
