import 'package:flutter/services.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/sqlite_util.dart';
import 'package:relay_sdk/data/relay_db_config.dart';

import '../worker/worker.dart';
import '../worker/worker_config.dart';

import 'package:nostr_sdk/relay_local/relay_local_db.dart';
import 'package:nostr_sdk/relay_local/relay_local_mixin.dart';

// import 'package:sqflite/sqflite.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class RelayDBWorker extends Worker with RelayLocalMixin {
  RelayDBWorker({required super.config});

  static void start(RelayDbConfig config) {
    var worker = RelayDBWorker(config: config);
    worker.doStart();
  }

  RelayLocalDB? relayLocalDB;

  @override
  void onIsolateMessage(message) {
    if (relayLocalDB == null) {
      return;
    }

    if (message is List && message.length > 2) {
      // // This is local relay method
      // var method = message[0];

      var connId = message[1];
      var nostrMsg = message[2];
      if (nostrMsg is List && nostrMsg.isNotEmpty) {
        var action = nostrMsg[0];
        if (action == "EVENT") {
          doEvent(connId, nostrMsg);
        } else if (action == "REQ") {
          doReq(connId, nostrMsg);
        } else if (action == "CLOSE") {
          // this relay only use to handle cache event, so it wouldn't push new event to client.
        } else if (action == "AUTH") {
          // don't handle the message
        } else if (action == "COUNT") {
          doCount(connId, nostrMsg);
        }
      }
    }
  }

  @override
  void run() async {
    if (config is RelayDbConfig) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(
          (config as RelayDbConfig).rootIsolateToken);
    }
    SqliteUtil.configSqliteFactory();
    // if (PlatformUtil.isWeb()) {
    //   databaseFactory = databaseFactoryFfiWeb;
    // } else if (PlatformUtil.isWindowsOrLinux()) {
    //   // Initialize FFI
    //   sqfliteFfiInit();
    //   // Change the default factory
    //   databaseFactory = databaseFactoryFfi;
    // }
    relayLocalDB = await RelayLocalDB.init();
  }

  @override
  void callback(String? connId, List list) {
    send(["", connId, list]);
  }

  // this method should only call in RelayLocalMixin, so the relayLocalDB will not be null.
  @override
  RelayLocalDB getRelayLocalDB() {
    return relayLocalDB!;
  }
}
