import 'dart:convert';

import 'package:nostr_sdk/relay/relay_info.dart';
import 'package:relay_sdk/data/relay_db.dart';
import 'package:relay_sdk/network/connection.dart';
import 'package:relay_sdk/network/relay_server.dart';

class RelayManager {
  RelayServer? relayServer;

  RelayDB? relayDB;

  void start() {
    relayDB = RelayDB();
    relayDB!.callback = onRelayDBMessage;
    relayDB!.start();

    var relayInfo = RelayInfo(
        "Local Relay",
        "This is a cache relay. It will cache some event.",
        "29320975df855fe34a7b45ada2421e2c741c37c0136901fe477133a91eb18b07",
        "29320975df855fe34a7b45ada2421e2c741c37c0136901fe477133a91eb18b07",
        ["1", "11", "12", "16", "33", "42", "45", "50", "95"],
        "Cache Relay",
        "0.1.0");
    relayServer = RelayServer(relayInfo: relayInfo);
    relayServer!.port = 4869;
    relayServer!.onWebSocketMessage = onWebSocketMessage;
    relayServer!.startServer();
  }

  void onWebSocketMessage(Connection conn, message) {
    if (message is String) {
      var msgJson = jsonDecode(message);
      print(msgJson);
      if (msgJson is List && msgJson.length > 1 && relayDB != null) {
        relayDB!.onNostrMessage(conn.id, msgJson);
      }
    }
  }

  void onRelayDBMessage(message) {
    if (message is List && message.length > 2 && relayServer != null) {
      var method = message[0];
      var connId = message[1];
      var nostrMsg = message[2];

      relayServer!.send(connId, nostrMsg);
    }
  }
}
