import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:gun_arena_io/network/signaling/firebase_signaling.dart';
import 'package:gun_arena_io/network/webrtc/data_channel.dart';

class RtcManager {
  final FirebaseSignaling signaling;
  final Map<String, RTCPeerConnection> connectionMap = {};
  final Map<String, GameDataChannel> dataChannelMap = {};

  final void Function(String peerId, GameDataChannel channel)? onChannelOpen;
  final void Function(String peerId)? onChannelClose;
  final void Function(String peerId, String message)? onMessage;

  StreamSubscription<dynamic>? _signalSubscription;

  static const Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  RtcManager({
    required this.signaling,
    this.onChannelOpen,
    this.onChannelClose,
    this.onMessage,
  });

  Future<void> startListening() async {
    _signalSubscription = signaling.onSignal(_handleSignal);
  }

  // Host: create offer and connection to a peer
  Future<void> createOffer(String peerId) async {
    final RTCPeerConnection pc = await _createPeerConnection(peerId);

    final RTCDataChannelInit dataChannelConfig = RTCDataChannelInit()
      ..ordered = false
      ..maxRetransmits = 0;

    final RTCDataChannel dc = await pc.createDataChannel('game', dataChannelConfig);
    _setupDataChannel(peerId, dc);

    final RTCSessionDescription offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    await signaling.sendSignal(
      to: peerId,
      type: 'offer',
      data: {'sdp': offer.sdp, 'type': offer.type},
    );
  }

  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    final RTCPeerConnection pc =
        await createPeerConnection(_rtcConfig);

    pc.onIceCandidate = (RTCIceCandidate candidate) {
      signaling.sendSignal(
        to: peerId,
        type: 'ice',
        data: {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };

    pc.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _handlePeerDisconnect(peerId);
      }
    };

    pc.onDataChannel = (RTCDataChannel dc) {
      _setupDataChannel(peerId, dc);
    };

    connectionMap[peerId] = pc;
    return pc;
  }

  void _setupDataChannel(String peerId, RTCDataChannel dc) {
    final GameDataChannel channel = GameDataChannel(dc);

    channel.onMessage = (String message) {
      onMessage?.call(peerId, message);
    };

    channel.onClose = () {
      _handlePeerDisconnect(peerId);
    };

    channel.onOpen = () {
      dataChannelMap[peerId] = channel;
      onChannelOpen?.call(peerId, channel);
    };
  }

  void _handleSignal(Map<String, dynamic> signal) async {
    final String from = signal['from'] as String;
    final String type = signal['type'] as String;
    final Map<String, dynamic> data = Map<String, dynamic>.from(signal['data'] as Map);

    switch (type) {
      case 'offer':
        await _handleOffer(from, data);
        break;
      case 'answer':
        await _handleAnswer(from, data);
        break;
      case 'ice':
        await _handleIceCandidate(from, data);
        break;
    }
  }

  Future<void> _handleOffer(String from, Map<String, dynamic> data) async {
    final RTCPeerConnection pc = await _createPeerConnection(from);

    await pc.setRemoteDescription(
      RTCSessionDescription(data['sdp'] as String, data['type'] as String),
    );

    final RTCSessionDescription answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    await signaling.sendSignal(
      to: from,
      type: 'answer',
      data: {'sdp': answer.sdp, 'type': answer.type},
    );
  }

  Future<void> _handleAnswer(String from, Map<String, dynamic> data) async {
    final RTCPeerConnection? pc = connectionMap[from];
    if (pc == null) return;

    await pc.setRemoteDescription(
      RTCSessionDescription(data['sdp'] as String, data['type'] as String),
    );
  }

  Future<void> _handleIceCandidate(String from, Map<String, dynamic> data) async {
    final RTCPeerConnection? pc = connectionMap[from];
    if (pc == null) return;

    await pc.addCandidate(
      RTCIceCandidate(
        data['candidate'] as String?,
        data['sdpMid'] as String?,
        data['sdpMLineIndex'] as int?,
      ),
    );
  }

  void _handlePeerDisconnect(String peerId) {
    dataChannelMap.remove(peerId);
    onChannelClose?.call(peerId);
  }

  void sendToAll(String message) {
    for (final GameDataChannel channel in dataChannelMap.values) {
      channel.send(message);
    }
  }

  void sendTo(String peerId, String message) {
    dataChannelMap[peerId]?.send(message);
  }

  Future<void> dispose() async {
    _signalSubscription?.cancel();

    for (final GameDataChannel channel in dataChannelMap.values) {
      channel.close();
    }
    dataChannelMap.clear();

    for (final RTCPeerConnection pc in connectionMap.values) {
      await pc.close();
    }
    connectionMap.clear();
  }
}
