import 'dart:collection';

class Traffic {
  final int timeSecond;

  final int itemNum;

  Traffic(this.timeSecond, this.itemNum) {
    _doMove();
  }

  Queue<TrafficItem> queue = Queue();

  void add(int v) {
    var ti = queue.last;
    ti.add(v);
  }

  void move() {
    _doMove();
  }

  void _doMove() {
    var currentItem = TrafficItem(timeSecond);
    queue.add(currentItem);

    if (queue.length > 3) {
      queue.removeFirst();
    }
  }

  String toTrafficString() {
    int total = 0;
    int timeSecond = 0;
    for (var item in queue) {
      total += item.total;
      timeSecond += item.timeSecond;
    }

    var item = TrafficItem(timeSecond);
    item.total = total;

    return item.toTrafficString();
  }
}

class TrafficItem {
  final int timeSecond;

  TrafficItem(this.timeSecond);

  int total = 0;

  void add(int v) {
    total += v;
  }

  String toTrafficString() {
    var speed = total / timeSecond;

    if (speed > MB) {
      return "${(speed / MB).toStringAsFixed(1)} MB/s";
    } else if (total > KB) {
      return "${(speed / KB).toStringAsFixed(1)} KB/s";
    } else {
      return "${speed.toStringAsFixed(2)} B/s";
    }
  }

  static const int MB = 1024 * 1024;

  static const int KB = 1024;
}
