import 'dart:io';
import 'dart:math';

import 'package:relay_sdk/network/statistics/network_log_item.dart';
import 'package:relay_sdk/network/statistics/traffic.dart';
import 'package:relay_sdk/network/statistics/traffic_counter.dart';

import 'statistics/network_logs_manager.dart';

class Connection {
  late String id;

  String ip;

  WebSocket _webSocket;

  String? authPubkey;

  String? authChallenge;

  TrafficCounter? trafficCounter;

  NetworkLogsManager? networkLogsManager;

  Connection(
    this._webSocket,
    this.ip, {
    this.trafficCounter,
    this.networkLogsManager,
  }) {
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

  void send(String text) {
    _webSocket.add(text);
    onSend();

    if (trafficCounter != null) {
      trafficCounter!.add(id, text.length);
    }
    if (networkLogsManager != null) {
      networkLogsManager!.add(id, NetworkLogItem.NETWORK_OUT, text);
    }
  }

  void onSend({DateTime? dt}) {
    _sendNum++;
    dt ??= DateTime.now();
    receiveDate = dt;
  }
}
