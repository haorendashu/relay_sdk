import 'package:relay_sdk/worker/worker_config.dart';
import 'package:relay_sdk/worker/worker_wrapper.dart';

import 'event_filter_check_worker.dart';

class EventFilterCheck extends WorkerWrapper<WorkerConfig> {
  Function(List<dynamic>)? callback;

  void onNostrMessage(String connId, List message) {
    if (sendPort != null) {
      sendPort!.send(["", connId, message]);
    }
  }

  @override
  WorkerConfig genConfig() {
    return WorkerConfig(sendPort: receivePort.sendPort);
  }

  @override
  Function(WorkerConfig) getWorkerStartFunc() {
    return EventFilterCheckWorker.start;
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
}
