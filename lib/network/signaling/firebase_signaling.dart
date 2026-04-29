import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSignaling {
  static const Duration _heartbeatInterval = Duration(seconds: 5);
  static const Duration _staleThreshold = Duration(seconds: 15);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<StreamSubscription<dynamic>> _subscriptionList = [];
  Timer? _heartbeatTimer;

  String? _roomId;
  String? _localId;

  String? get roomId => _roomId;
  String? get localId => _localId;

  // Create a new room, returns roomId
  Future<String> createRoom({
    required String hostId,
    required String hostName,
  }) async {
    final DocumentReference<Map<String, dynamic>> roomRef =
        await _firestore.collection('rooms').add({
      'hostId': hostId,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _roomId = roomRef.id;
    _localId = hostId;

    await roomRef.collection('players').doc(hostId).set({
      'name': hostName,
      'ready': true,
      'joinedAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    });

    _startHeartbeat();
    return roomRef.id;
  }

  // Join an existing room
  Future<void> joinRoom({
    required String roomId,
    required String playerId,
    required String playerName,
  }) async {
    _roomId = roomId;
    _localId = playerId;

    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('players')
        .doc(playerId)
        .set({
      'name': playerName,
      'ready': true,
      'joinedAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    });

    _startHeartbeat();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      if (_roomId == null || _localId == null) return;
      try {
        await _firestore
            .collection('rooms')
            .doc(_roomId)
            .collection('players')
            .doc(_localId)
            .update({'lastSeen': FieldValue.serverTimestamp()});
      } catch (_) {
        // Ignore transient failures; next tick will retry.
      }
    });
  }

  // Get room data
  Future<Map<String, dynamic>?> getRoomData() async {
    if (_roomId == null) return null;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _firestore.collection('rooms').doc(_roomId).get();
    return doc.data();
  }

  // Listen for player changes in the room
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> onPlayersChanged(
    void Function(List<Map<String, dynamic>> playerList) callback,
  ) {
    final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> sub =
        _firestore
            .collection('rooms')
            .doc(_roomId)
            .collection('players')
            .snapshots()
            .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final DateTime now = DateTime.now();
      final List<Map<String, dynamic>> playerList = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .where((Map<String, dynamic> p) {
            // Always show local player so UI doesn't blink during own heartbeat.
            if (p['id'] == _localId) return true;
            final dynamic ts = p['lastSeen'];
            if (ts is! Timestamp) return true;
            return now.difference(ts.toDate()) < _staleThreshold;
          })
          .toList();
      callback(playerList);
    });
    _subscriptionList.add(sub);
    return sub;
  }

  // Send signaling data (offer, answer, or ICE candidate)
  Future<void> sendSignal({
    required String to,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    if (_roomId == null || _localId == null) return;

    await _firestore
        .collection('rooms')
        .doc(_roomId)
        .collection('signaling')
        .add({
      'from': _localId,
      'to': to,
      'type': type,
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Listen for signaling messages targeted at this player
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> onSignal(
    void Function(Map<String, dynamic> signal) callback,
  ) {
    final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> sub =
        _firestore
            .collection('rooms')
            .doc(_roomId)
            .collection('signaling')
            .where('to', isEqualTo: _localId)
            .snapshots()
            .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
      for (final DocumentChange<Map<String, dynamic>> change
          in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final Map<String, dynamic> data = change.doc.data()!;
          callback({
            'id': change.doc.id,
            'from': data['from'],
            'type': data['type'],
            'data': data['data'],
          });
          // Clean up processed signal
          change.doc.reference.delete();
        }
      }
    });
    _subscriptionList.add(sub);
    return sub;
  }

  // Update room status
  Future<void> updateRoomStatus(String status, {int? mapSeed}) async {
    if (_roomId == null) return;
    final Map<String, dynamic> updates = <String, dynamic>{'status': status};
    if (mapSeed != null) updates['mapSeed'] = mapSeed;
    await _firestore.collection('rooms').doc(_roomId).update(updates);
  }

  // Get all peer ids in the room except local player.
  Future<List<String>> getPeerIds() async {
    if (_roomId == null || _localId == null) return <String>[];
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('rooms')
        .doc(_roomId)
        .collection('players')
        .get();
    return snapshot.docs
        .where((QueryDocumentSnapshot<Map<String, dynamic>> d) => d.id != _localId)
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => d.id)
        .toList();
  }

  // Listen for room status changes
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> onRoomChanged(
    void Function(Map<String, dynamic>? data) callback,
  ) {
    final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> sub =
        _firestore
            .collection('rooms')
            .doc(_roomId)
            .snapshots()
            .listen((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      callback(snapshot.data());
    });
    _subscriptionList.add(sub);
    return sub;
  }

  // Remove player from room
  Future<void> leaveRoom() async {
    if (_roomId == null || _localId == null) return;
    await _firestore
        .collection('rooms')
        .doc(_roomId)
        .collection('players')
        .doc(_localId)
        .delete();
  }

  // Get player count
  Future<int> getPlayerCount() async {
    if (_roomId == null) return 0;
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('rooms')
        .doc(_roomId)
        .collection('players')
        .get();
    return snapshot.docs.length;
  }

  // Clean up all listeners
  void dispose() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    for (final StreamSubscription<dynamic> sub in _subscriptionList) {
      sub.cancel();
    }
    _subscriptionList.clear();
  }
}
