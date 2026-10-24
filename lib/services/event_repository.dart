import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_item.dart';
import '../models/tech_event.dart';

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
  Stream<List<EventItem>> watchEvents() =>
      _events.snapshots().map((snapshot) => _sortedEvents(snapshot.docs));

  @override
  Future<List<EventItem>> fetchEvents() async {
    final snapshot = await _events.get(
      const GetOptions(source: Source.serverAndCache),
    );
    return _sortedEvents(snapshot.docs);
  }

  List<EventItem> _sortedEvents(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final events = documents
        .map((doc) => TechEvent.fromDoc(doc).toEventItem())
        .toList();
    events.sort((first, second) => first.id.compareTo(second.id));
    return List.unmodifiable(events);
  }

  @override
  Future<void> refresh() async {
    await _events.get(const GetOptions(source: Source.server));
  }
}
