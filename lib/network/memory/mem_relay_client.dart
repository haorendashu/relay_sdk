import 'package:nostr_sdk/relay/relay.dart';

class MemRelayClient extends Relay {
  MemRelayClient(super.url, super.relayStatus);

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> doConnect() async {
    return true;
  }

  // Client send message to relay.
  // This method id for client use.
  // It's a method from Relay interface.
  @override
  bool send(List message, {bool? forceSend}) {
    if (onClientToRelay != null) {
      onClientToRelay!(message);
      return true;
    }
    return false;
  }

  // receive message from relay
  void onRelayToClient(List message) {
    if (onMessage != null) {
      onMessage!(this, message);
    }
  }

  Function(List message)? onClientToRelay;
}
