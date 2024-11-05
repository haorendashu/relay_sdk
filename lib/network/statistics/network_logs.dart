import 'dart:collection';

import 'package:relay_sdk/network/statistics/network_log_item.dart';

class NetworkLogs {
  final int maxLength;

  NetworkLogs(this.maxLength);

  Queue<NetworkLogItem> items = ListQueue();

  void add(NetworkLogItem item) {
    items.add(item);
    if (items.length > maxLength) {
      items.removeFirst();
    }
  }
}
