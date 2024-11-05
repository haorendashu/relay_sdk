import 'package:flutter/services.dart';
import 'package:relay_sdk/worker/worker_config.dart';

class RelayDbConfig extends WorkerConfig {
  RootIsolateToken rootIsolateToken;

  RelayDbConfig({required this.rootIsolateToken, required super.sendPort});
}
