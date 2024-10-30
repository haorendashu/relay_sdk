import 'dart:isolate';

class WorkerPort {
  SendPort sendPort;

  ReceivePort receivePort;

  WorkerPort(this.sendPort, this.receivePort);
}
