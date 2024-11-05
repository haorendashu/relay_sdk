import 'package:flutter/services.dart';
import 'package:relay_sdk/worker/worker_wrapper.dart';
import 'package:relay_sdk/worker/worker_config.dart';

import 'relay_db_config.dart';
import 'relay_db_worker.dart';

class RelayDB extends WorkerWrapper<RelayDbConfig> {
  RootIsolateToken rootIsolateToken;

  RelayDB(this.rootIsolateToken);

  Function(List<dynamic>)? callback;

  void onNostrMessage(String connId, List message) {
    if (sendPort != null) {
      sendPort!.send(["", connId, message]);
    }
  }

  @override
  void onIsolateMessage(message) {
    if (message is List && message.length > 2 && callback != null) {
      var method = message[0];
      var connId = message[1];
      var nostrMsg = message[2];

      callback!(message);
    }
  }

  @override
  RelayDbConfig genConfig() {
    return RelayDbConfig(
        rootIsolateToken: rootIsolateToken, sendPort: receivePort.sendPort);
  }

  @override
  Function(RelayDbConfig) getWorkerStartFunc() {
    return RelayDBWorker.start;
  }
}
