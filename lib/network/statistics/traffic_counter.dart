import 'package:relay_sdk/network/statistics/traffic.dart';

mixin TrafficCounter {
  Map<String, Traffic> trafficMap = {};

  static const int TRAFFIC_TIME_SECOND = 3;

  static const int TRAFFIC_ITEM_NUM = 3;

  Traffic totalTraffic = Traffic(TRAFFIC_TIME_SECOND, TRAFFIC_ITEM_NUM);

  Traffic getTraffic(String id) {
    var t = trafficMap[id];
    if (t == null) {
      t = Traffic(TRAFFIC_TIME_SECOND, TRAFFIC_ITEM_NUM);
      trafficMap[id] = t;
    }

    return t;
  }

  void removeTraffic(String id) {
    trafficMap.remove(id);
  }

  void move() {
    totalTraffic.move();

    for (var traffic in trafficMap.values) {
      traffic.move();
    }
  }

  void add(String id, int length) {
    var t = getTraffic(id);
    t.add(length);

    totalTraffic.add(length);
  }
}
