import 'package:cloud_firestore/cloud_firestore.dart';

class PlanAddResult {
  const PlanAddResult({required this.added, required this.shouldAwardXp});

  final bool added;
  final bool shouldAwardXp;
}

abstract interface class EventUserRepository {
  Stream<Set<String>> watchSavedEventIds();

  Stream<Map<String, bool>> watchPlan();

  Future<void> setSaved(String eventId, bool saved);

  Future<PlanAddResult> addToPlan(String eventId);

  Future<void> removeFromPlan(String eventId);

  Future<void> setReminder(String eventId, bool enabled);
}

class FirestoreEventUserRepository implements EventUserRepository {
  FirestoreEventUserRepository({required this._firestore, required this._uid});

  final FirebaseFirestore _firestore;
  final String _uid;

  CollectionReference<Map<String, dynamic>> get _saved =>
      _firestore.collection('users').doc(_uid).collection('savedEvents');

  CollectionReference<Map<String, dynamic>> get _plan =>
      _firestore.collection('users').doc(_uid).collection('plan');

  CollectionReference<Map<String, dynamic>> get _xpAwards =>
      _firestore.collection('users').doc(_uid).collection('eventXpAwards');

  @override
  Stream<Set<String>> watchSavedEventIds() => _saved.snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => doc.id).toSet(),
  );

  @override
  Stream<Map<String, bool>> watchPlan() => _plan.snapshots().map(
    (snapshot) => {
      for (final doc in snapshot.docs)
        doc.id: doc.data()['reminderEnabled'] as bool? ?? false,
    },
  );

  @override
  Future<void> setSaved(String eventId, bool saved) async {
    final reference = _saved.doc(eventId);
    if (!saved) {
      await reference.delete();
      return;
    }
    await reference.set({
      'eventId': eventId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<PlanAddResult> addToPlan(String eventId) =>
      _firestore.runTransaction((transaction) async {
        final planReference = _plan.doc(eventId);
        final awardReference = _xpAwards.doc(eventId);
        final planSnapshot = await transaction.get(planReference);
        final awardSnapshot = await transaction.get(awardReference);
        if (planSnapshot.exists) {
          return const PlanAddResult(added: false, shouldAwardXp: false);
        }
        transaction.set(planReference, {
          'eventId': eventId,
          'addedAt': FieldValue.serverTimestamp(),
          'reminderEnabled': false,
          'xpAwarded': awardSnapshot.exists,
        });
        if (awardSnapshot.exists) {
          return const PlanAddResult(added: true, shouldAwardXp: false);
        }
        transaction.set(awardReference, {
          'eventId': eventId,
          'awardedAt': FieldValue.serverTimestamp(),
        });
        return const PlanAddResult(added: true, shouldAwardXp: true);
      });

  @override
  Future<void> removeFromPlan(String eventId) async {
    await _plan.doc(eventId).delete();
  }

  @override
  Future<void> setReminder(String eventId, bool enabled) async {
    await _plan.doc(eventId).update({
      'reminderEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
