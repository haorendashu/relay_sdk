import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:relay_sdk/network/memory/mem_relay_client.dart';
import 'package:relay_sdk/network/statistics/network_log_item.dart';
import 'package:relay_sdk/network/statistics/traffic.dart';
import 'package:relay_sdk/network/statistics/traffic_counter.dart';

import 'statistics/network_logs_manager.dart';

class Connection {
  late String id;

  String ip;

  WebSocket? webSocket;

  MemRelayClient? memRelayClient;

  String? authPubkey;

  String? authChallenge;

  TrafficCounter? trafficCounter;

  NetworkLogsManager? networkLogsManager;

  Connection(
    this.ip, {
    this.webSocket,
    this.memRelayClient,
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

  void send(List message) {
    var text = jsonEncode(message);
    if (webSocket != null) {
      webSocket!.add(text);
    } else if (memRelayClient != null) {
      memRelayClient!.onRelayToClient(message);
    }

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
