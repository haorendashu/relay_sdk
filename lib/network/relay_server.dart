import 'dart:convert';
import 'dart:io';

import 'package:nostr_sdk/relay/relay_info.dart';
import 'package:relay_sdk/network/connection.dart';
import 'package:relay_sdk/network/statistics/network_log_item.dart';
import 'package:relay_sdk/network/statistics/network_logs_manager.dart';

import 'memory/mem_relay_client.dart';
import 'statistics/traffic_counter.dart';

class RelayServer {
  String address;

  int port;

  RelayInfo relayInfo;

  Map<String, OnRequest> httpHandles = {};

  Map<String, Connection> connections = {};

  Function(Connection conn)? onWebSocketConnected;

  Function(Connection conn, List message)? onWebSocketMessage;

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
            ip,
            webSocket: webSocket,
            trafficCounter: trafficCounter,
            networkLogsManager: networkLogsManager,
          );
          connections[conn.id] = conn;
          print("New connection ${conn.id} from $ip");
          callConnectionListener();

          webSocket.listen((message) {
            // print('Received message: $message');
            if (onWebSocketMessage != null && message is String) {
              var jsonObj = jsonDecode(message);
              if (jsonObj is List) {
                onWebSocketMessage!(conn, jsonObj);
              }
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

            var httpHandle = httpHandles[addr];
            if (httpHandle != null) {
              httpHandle(request, response);
              return;
            } else {
              responseDefaultIndex(request, response);
              return;
            }
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
    response.close();
  }

  void responseDefaultIndex(HttpRequest request, HttpResponse response) {
    response.write("Hello Nostr !");
    response.close();
  }

  void response404(HttpRequest request, HttpResponse response) {
    response.statusCode = 404;
    response.close();
  }

  void send(connId, nostrMsg) {
    var conn = connections[connId];
    if (conn != null && nostrMsg is List) {
      conn.send(nostrMsg);
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

  void addMemClient(MemRelayClient memRelayClient) {
    var conn = Connection("127.0.0.1", memRelayClient: memRelayClient);

    connections[conn.id] = conn;
    print("New connection ${conn.id} from Local");
    callConnectionListener();

    memRelayClient.onClientToRelay = (List message) {
      if (onWebSocketMessage != null) {
        onWebSocketMessage!(conn, message);
      }
      conn.onReceive();

      if (networkLogsManager != null) {
        networkLogsManager!
            .add(conn.id, NetworkLogItem.NETWORK_IN, jsonEncode(message));
      }
    };

    if (onWebSocketConnected != null) {
      onWebSocketConnected!(conn);
    }
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
      ? request.connectionInfo!.remoteAddress.address
      : "127.0.0.1";
}

typedef OnRequest(HttpRequest, HttpResponse);
