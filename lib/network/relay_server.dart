import 'dart:convert';
import 'dart:io';

import 'package:nostr_sdk/relay/relay_info.dart';
import 'package:relay_sdk/network/connection.dart';

class RelayServer {
  String address;

  int port;

  RelayInfo relayInfo;

  Map<String, OnRequest> httpHandles = {};

  Map<String, Connection> connections = {};

  Function(Connection conn)? onWebSocketConnected;

  Function(Connection conn, dynamic message)? onWebSocketMessage;

  RelayServer({
    this.address = "localhost",
    this.port = 8080,
    required this.relayInfo,
  });

  Future<void> startServer() async {
    final server = await HttpServer.bind(
      address,
      port,
      shared: true,
    );
    print('WebSocket server started on $address:$port');
    server.listen((request) {
      var ip = getIpFromRequest(request);

      if (WebSocketTransformer.isUpgradeRequest(request)) {
        WebSocketTransformer.upgrade(request).then((webSocket) {
          webSocket.pingInterval = const Duration(seconds: 30);
          var conn = Connection(webSocket, ip);
          connections[conn.id] = conn;

          webSocket.listen((message) {
            // print('Received message: $message');
            if (onWebSocketMessage != null) {
              onWebSocketMessage!(conn, message);
            }
            conn.onReceive();
          }, onDone: () {
            connections.remove(conn.id);
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
      conn.webSocket.add(text);
      conn.onSend();
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
      ? request.connectionInfo!.remoteAddress.toString()
      : "127.0.0.1";
}

typedef OnRequest(HttpRequest, HttpResponse);
