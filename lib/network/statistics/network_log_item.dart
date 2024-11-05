class NetworkLogItem {
  static const NETWORK_IN = 1;

  static const NETWORK_OUT = 2;

  final int networkType;

  final String text;

  NetworkLogItem(this.networkType, this.text);
}
