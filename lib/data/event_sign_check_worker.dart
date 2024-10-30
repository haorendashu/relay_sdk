import 'package:nostr_sdk/event.dart';
import 'package:relay_sdk/worker/worker.dart';

import '../worker/worker_config.dart';

class EventSignCheckWorker extends Worker {
  EventSignCheckWorker({required super.config});

  static void start(WorkerConfig config) {
    var worker = EventSignCheckWorker(config: config);
    worker.doStart();
  }

  Map<String, int> checkPassEvents = {};

  @override
  void onIsolateMessage(message) {
    if (message is List && message.length > 2) {
      // // This is local relay method
      // var method = message[0];
      // var connId = message[1];
      var nostrMsg = message[2];
      if (nostrMsg is List && nostrMsg.isNotEmpty) {
        var action = nostrMsg[0];

        if (action == "EVENT") {
          var eventJsonMap = nostrMsg[1];
          var id = eventJsonMap["id"];

          if (checkPassEvents[id] != null) {
            send(message);
            return;
          }

          if (doCheckSign(eventJsonMap)) {
            // event check pass!
            checkPassEvents[id] = 1;
            send(message);
            return;
          }
        }
      }
    }
  }

  bool doCheckSign(Map<String, dynamic> eventJsonMap) {
    try {
      var event = Event.fromJson(eventJsonMap);
      if (event.isValid && event.isSigned) {
        return true;
      }
    } catch (e) {}
    return false;
  }

  @override
  void run() {}
}
