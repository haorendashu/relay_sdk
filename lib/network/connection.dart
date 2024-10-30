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
}
