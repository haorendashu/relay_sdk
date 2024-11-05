import 'dart:convert';
import 'dart:io';

import 'package:nostr_sdk/relay/relay_info.dart';
import 'package:relay_sdk/network/connection.dart';
import 'package:relay_sdk/network/statistics/network_log_item.dart';
import 'package:relay_sdk/network/statistics/network_logs_manager.dart';

import 'statistics/traffic_counter.dart';

class RelayServer {
  String address;

  int port;

  RelayInfo relayInfo;

  Map<String, OnRequest> httpHandles = {};

  Map<String, Connection> connections = {};

  Function(Connection conn)? onWebSocketConnected;

  Function(Connection conn, dynamic message)? onWebSocketMessage;

  Function? connectionListener;

  TrafficCounter? trafficCounter;

  NetworkLogsManager? networkLogsManager;

  RelayServer({
    this.address = "localhost",
    this.port = 8080,
    required this.relayInfo,
    this.connectionListener,
    this.trafficCounter,
    this.networkLogsManager,
  });

  HttpServer? server;

  void stop() {
    if (server != null) {
      httpHandles.clear();
      connections.clear();
      server!.close(force: true);
    }
  }

  Future<void> startServer() async {
    server = await HttpServer.bind(
      address,
      port,
      shared: true,
    );
    print('WebSocket server started on $address:$port');
    server!.listen((request) {
      var ip = getIpFromRequest(request);

      if (WebSocketTransformer.isUpgradeRequest(request)) {
        WebSocketTransformer.upgrade(request).then((webSocket) {
          webSocket.pingInterval = const Duration(seconds: 30);
          var conn = Connection(
            webSocket,
            ip,
            trafficCounter: trafficCounter,
            networkLogsManager: networkLogsManager,
          );
          connections[conn.id] = conn;
          print("New connection ${conn.id} from $ip");
          callConnectionListener();

          webSocket.listen((message) {
            // print('Received message: $message');
            if (onWebSocketMessage != null) {
              onWebSocketMessage!(conn, message);
            }
            conn.onReceive();

            if (networkLogsManager != null) {
              networkLogsManager!
                  .add(conn.id, NetworkLogItem.NETWORK_IN, message);
            }
          }, onDone: () {
            print("Connection ${conn.id} remove");
            connections.remove(conn.id);
            callConnectionListener();
          });

          if (onWebSocketConnected != null) {
            onWebSocketConnected!(conn);
          }
        });
      } else {
        var response = request.response;
        var addr = request.uri.toString();

        try {
          if ((addr == "" || addr == "/")) {
            var accept = request.headers.value(HttpHeaders.acceptHeader);
            if (accept != null && accept.contains("nostr+json")) {
              responseRelayInfo(request, response);
              return;
            }

            responseIndex(request, response);
            return;
          }

          var httpHandle = httpHandles[addr];
          if (httpHandle != null) {
            httpHandle(request, response);
            return;
          }
        } catch (e) {
          // TODO response 500
        }

        return response404(request, response);
      }
    });
  }

  void responseRelayInfo(HttpRequest request, HttpResponse response) {
    response.headers.add("Content-Type", "application/json");
    var jsonMap = relayInfo.toJson();
    response.write(jsonEncode(jsonMap));
    response.done;
  }

  void responseIndex(HttpRequest request, HttpResponse response) {}

  void response404(HttpRequest request, HttpResponse response) {}

  void send(connId, nostrMsg) {
    var conn = connections[connId];
    if (conn != null) {
      var text = jsonEncode(nostrMsg);
      conn.send(text);
    }
  }

  void callConnectionListener() {
    if (connectionListener != null) {
      connectionListener!();
    }
  }

  List<Connection> getConnections() {
    return connections.values.toList();
  }
}

String getIpFromRequest(HttpRequest request) {
  var ip = request.headers.value("CF-Connecting-IP");
  if (ip != null) {
    return ip;
  }

  ip = request.headers.value("X-Forwarded-For");
  if (ip != null) {
    return ip;
  }

  return request.connectionInfo != null
      ? request.connectionInfo!.remoteAddress.toString()
      : "127.0.0.1";
}

typedef OnRequest(HttpRequest, HttpResponse);
