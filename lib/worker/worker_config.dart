import 'dart:isolate';

class WorkerConfig {
  final SendPort sendPort;

  WorkerConfig({
    required this.sendPort,
  });
}
