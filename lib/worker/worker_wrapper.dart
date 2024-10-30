import 'dart:isolate';

/// Worker Wrapper.
/// Hold on a worker runner.
/// Communicate between main isolate and sub isolate (Worker).
abstract class WorkerWrapper<T> {
  ReceivePort receivePort = ReceivePort();

  SendPort? sendPort;

  Isolate? _isolate;

  // start a isolate.
  Future<void> start() async {
    _isolate = await Isolate.spawn(
      getWorkerStartFunc(),
      genConfig(),
    );

    receivePort.listen((message) {
      if (message is SendPort) {
        sendPort = message;
      } else {
        onIsolateMessage(message);
      }
    });
  }

  void onIsolateMessage(message);

  Function(T) getWorkerStartFunc();

  T genConfig();

  void dispose() {
    if (_isolate != null) {
      _isolate!.kill();
      _isolate = null;
    }
  }
}
