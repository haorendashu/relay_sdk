import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/filter.dart';

import '../worker/worker.dart';
import '../worker/worker_config.dart';

class EventFilterCheckWorker extends Worker {
  EventFilterCheckWorker({required super.config});

  static void start(WorkerConfig config) {
    var worker = EventFilterCheckWorker(config: config);
    worker.doStart();
  }

  Map<String, List<Filter>> allFilters = {};

  @override
  void onIsolateMessage(message) {
    if (message is List && message.length > 2) {
      var method = message[0];
      var connId = message[1];
      var nostrMsg = message[2];
      if (nostrMsg is List && nostrMsg.isNotEmpty) {
        var action = nostrMsg[0];
        if (action == "EVENT") {
          handleEvent(method, connId, nostrMsg);
        } else if (action == "REQ") {
          handleReq(method, connId, nostrMsg);
          return;
        } else if (action == "CLOSE") {
          if (nostrMsg.length > 1) {
            var subscriptionId = nostrMsg[1];
            var key = _getKey(connId, subscriptionId);
            allFilters.remove(key);
            return;
          }
        }
      }
    }
  }

  void handleReq(String method, String connId, List nostrMsg) {
    if (nostrMsg.length > 2) {
      List<Filter> filters = [];
      var subscriptionId = nostrMsg[1];
      var key = _getKey(connId, subscriptionId);

      for (var i = 2; i < nostrMsg.length; i++) {
        var filterMap = nostrMsg[i];
        var filter = Filter.fromJson(filterMap);
        filters.add(filter);
      }

      allFilters[key] = filters;
    }
  }

  void handleEvent(String method, String connId, List nostrMsg) {
    if (nostrMsg.length > 1) {
      var eventMap = nostrMsg[1];
      var event = Event.fromJson(eventMap);

      var entries = allFilters.entries;
      for (var entry in entries) {
        var key = entry.key;
        var filters = entry.value;
        for (var filter in filters) {
          if (filter.checkEvent(event)) {
            // this filter match this event, send to this conn
            var index = key.indexOf(" ");
            if (index > 0) {
              var connId = key.substring(0, index);
              var subscriptionId = key.substring(index + 1);

              send([
                "",
                connId,
                ["EVENT", subscriptionId, eventMap]
              ]);

              // break to next entry, no need to check this filters
              break;
            }
          }
        }
      }
    }
  }

  String _getKey(String connId, String subscriptionId) {
    return "$connId $subscriptionId";
  }

  @override
  void run() {}
}
