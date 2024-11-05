import 'package:relay_sdk/network/statistics/network_log_item.dart';
import 'package:relay_sdk/network/statistics/network_logs.dart';

mixin NetworkLogsManager {
  Map<String, NetworkLogs> logsMap = {};

  static const int MAX_LOG_LENGTH = 1000;

  NetworkLogs totalLogs = NetworkLogs(MAX_LOG_LENGTH);

  NetworkLogs getLogs(String id) {
    var t = logsMap[id];
    if (t == null) {
      t = NetworkLogs(MAX_LOG_LENGTH);
      logsMap[id] = t;
    }

    return t;
  }

  void remote(String id) {
    logsMap.remove(id);
  }

  void add(String id, int networkType, String text) {
    var item = NetworkLogItem(networkType, text);
    totalLogs.add(item);
    var logs = getLogs(id);
    logs.add(item);
  }
}
