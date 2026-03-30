import 'package:flutter_webrtc/flutter_webrtc.dart';

class GameDataChannel {
  final RTCDataChannel _channel;

  void Function(String message)? onMessage;
  void Function()? onOpen;
  void Function()? onClose;

  GameDataChannel(this._channel) {
    _channel.onMessage = (RTCDataChannelMessage msg) {
      if (msg.isBinary) return;
      onMessage?.call(msg.text);
    };

    _channel.onDataChannelState = (RTCDataChannelState state) {
      switch (state) {
        case RTCDataChannelState.RTCDataChannelOpen:
          onOpen?.call();
          break;
        case RTCDataChannelState.RTCDataChannelClosed:
          onClose?.call();
          break;
        default:
          break;
      }
    };
  }

  void send(String message) {
    if (_channel.state == RTCDataChannelState.RTCDataChannelOpen) {
      _channel.send(RTCDataChannelMessage(message));
    }
  }

  void close() {
    _channel.close();
  }
}
