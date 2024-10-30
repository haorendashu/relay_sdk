import 'dart:io';
import 'dart:math';

class Connection {
  late String id;

  String ip;

  WebSocket webSocket;

  String? authPubkey;

  String? authChallenge;

  Connection(this.webSocket, this.ip) {
    id = (DateTime.now().millisecondsSinceEpoch + Random().nextInt(100000))
        .toString();
  }

  int _receiveNum = 0;

  int get receiveNum => _receiveNum;

  DateTime? receiveDate;

  void onReceive({DateTime? dt}) {
    _receiveNum++;
    dt ??= DateTime.now();
    receiveDate = dt;
  }

  int _sendNum = 0;

  int get sendNum => _sendNum;

  DateTime? sendDate;

  void onSend({DateTime? dt}) {
    _sendNum++;
    dt ??= DateTime.now();
    receiveDate = dt;
  }
}
