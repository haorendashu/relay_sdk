import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/relay/relay_info.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:relay_sdk/network/memory/mem_relay_client.dart';

import 'data/event_filter_check.dart';
import 'data/event_sign_check.dart';
import 'data/relay_db.dart';
import 'network/connection.dart';
import 'network/relay_server.dart';
import 'network/statistics/network_logs_manager.dart';
import 'network/statistics/traffic_counter.dart';

class RelayManager {
  String appName;

  bool openDB = true;

  bool openSignCheck = true;

  bool openFilterCheck = true;

  RelayServer? relayServer;

  RelayDB? relayDB;

  EventSignCheck? eventSignCheck;

  EventFilterCheck? eventFilterCheck;

  TrafficCounter? trafficCounter;

  NetworkLogsManager? networkLogsManager;

  RootIsolateToken rootIsolateToken;

  Function? connectionListener;

  Map<String, OnRequest> httpHandles = {};

  RelayManager(this.rootIsolateToken, this.appName);

  bool isRunning() {
    if (relayServer != null) {
      return true;
    }

    return false;
  }

  Future<void> start(RelayInfo relayInfo, int port) async {
    if (openDB) {
      relayDB = RelayDB(rootIsolateToken, appName);
      relayDB!.callback = onRelayDBMessage;
      relayDB!.start();
    }

    if (openSignCheck) {
      eventSignCheck = EventSignCheck();
      eventSignCheck!.callback = onEventCheckMessage;
      eventSignCheck!.start();
    }

    if (openFilterCheck) {
      eventFilterCheck = EventFilterCheck();
      eventFilterCheck!.callback = onEventFilterMessage;
      eventFilterCheck!.start();
    }

    relayServer = RelayServer(relayInfo: relayInfo, address: "0.0.0.0");
    relayServer!.port = port;
    relayServer!.onWebSocketMessage = onWebSocketMessage;
    relayServer!.onWebSocketConnected = onWebSocketConnected;
    relayServer!.trafficCounter = trafficCounter;
    relayServer!.networkLogsManager = networkLogsManager;
    relayServer!.connectionListener = connectionListener;
    relayServer!.httpHandles = httpHandles;
    await relayServer!.startServer();
  }

  void onWebSocketMessage(Connection conn, List message) {
    // print(message);
    if (message.length > 1) {
      var action = message[0];
      if (action == "EVENT" && eventSignCheck != null) {
        // check event sign
        eventSignCheck!.onNostrMessage(conn.id, message);
        return;
      } else if (action == "REQ") {
        // TODO need to check Auth for kind 4

        // save req filters to eventFilterCheck
        if (eventFilterCheck != null) {
          eventFilterCheck!.onNostrMessage(conn.id, message);
        }
      } else if (action == "CLOSE") {
        // close filter
        if (eventFilterCheck != null) {
          eventFilterCheck!.onNostrMessage(conn.id, message);
        }
        return;
      } else if (action == "AUTH") {
        // check auth message
        handleAuthMessage(conn, message[1]);
        return;
      } else if (action == "COUNT") {}

      onEvent(conn.id, message);
    }
  }

  void onEvent(String connId, List msgJson) {
    if (eventFilterCheck != null) {
      eventFilterCheck!.onNostrMessage(connId, msgJson);
    }
    if (relayDB != null) {
      relayDB!.onNostrMessage(connId, msgJson);
    }
  }

  void onEventCheckMessage(message) {
    if (message is List && message.length > 2 && relayServer != null) {
      // var method = message[0];
      var connId = message[1];
      var nostrMsg = message[2];

      onEvent(connId, nostrMsg);
    }
  }

  void onRelayDBMessage(message) {
    if (message is List && message.length > 2 && relayServer != null) {
      // var method = message[0];
      var connId = message[1];
      var nostrMsg = message[2];

      relayServer!.send(connId, nostrMsg);
    }
  }

  onEventFilterMessage(message) {
    if (message is List && message.length > 2 && relayServer != null) {
      // var method = message[0];
      var connId = message[1];
      var nostrMsg = message[2];

      relayServer!.send(connId, nostrMsg);
    }
  }

  void handleAuthMessage(Connection conn, Map<String, dynamic> eventJson) {
    try {
      var event = Event.fromJson(eventJson);
      if (event.kind == EventKind.AUTHENTICATION &&
          event.isValid &&
          event.isSigned) {
        var tags = event.tags;
        for (var tag in tags) {
          if (tag is List && tag.length > 1) {
            var key = tag[0];
            var value = tag[1];

            if (key == "challenge" && value == conn.authChallenge) {
              conn.authPubkey = event.pubkey;
              // print("auth pass!");
            }
          }
        }
      }
    } catch (e) {}
  }

  onWebSocketConnected(Connection conn) {
    try {
      // send auth message.
      conn.authChallenge = StringUtil.rndNameStr(12);
      conn.send(["AUTH", conn.authChallenge]);
    } catch (e) {}
  }

  void stop() {
    if (relayServer != null) {
      relayServer!.stop();
      relayServer = null;
    }

    if (relayDB != null) {
      relayDB!.dispose();
      relayDB = null;
    }

    if (eventSignCheck != null) {
      eventSignCheck!.dispose();
      eventSignCheck = null;
    }

    if (eventFilterCheck != null) {
      eventFilterCheck!.dispose();
      eventFilterCheck = null;
    }
  }

  List<Connection> getConnections() {
    if (relayServer != null) {
      return relayServer!.getConnections();
    }

    return [];
  }

  void addMemClient(MemRelayClient memRelayClient) {
    if (relayServer != null) {
      relayServer!.addMemClient(memRelayClient);
    }
  }
}
