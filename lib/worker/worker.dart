import 'dart:isolate';

import 'package:relay_sdk/worker/worker_config.dart';
import 'package:relay_sdk/worker/worker_port.dart';

/// This is a isolate worker runner who doing something in isolate.
abstract class Worker {
  WorkerConfig config;

  ReceivePort receivePort = ReceivePort();

  Worker({required this.config});

  void doStart() {
    config.sendPort.send(receivePort.sendPort);

    receivePort.listen(onIsolateMessage);

    run();
  }

  void run();

  void onIsolateMessage(message);

  void send(List<dynamic> list) {
    config.sendPort.send(list);
  }
}
