import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_item.dart';

abstract interface class EventRepository {
  Stream<List<EventItem>> watchEvents();

  Future<List<EventItem>> fetchEvents();

  Future<void> refresh();
}

class FirestoreEventRepository implements EventRepository {
  FirestoreEventRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection('events');

  @override
  Stream<List<EventItem>> watchEvents() => _events.snapshots().map(
    (snapshot) => snapshot.docs
        .map((doc) => EventItem.fromFirestore(doc.id, doc.data()))
        .toList(growable: false),
  );

  @override
  Future<List<EventItem>> fetchEvents() async {
    final snapshot = await _events.get(
      const GetOptions(source: Source.serverAndCache),
    );
    return snapshot.docs
        .map((doc) => EventItem.fromFirestore(doc.id, doc.data()))
        .toList(growable: false);
  }

  @override
  Future<void> refresh() async {
    await _events.get(const GetOptions(source: Source.server));
  }
}
