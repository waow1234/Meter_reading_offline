// Import the firebase_core and cloud_firestore plugin
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseCloudStoreProvider = Provider<FirebaseCloudStore>((ref) {
  return FirebaseCloudStore(
    firestore: FirebaseFirestore.instance,
  );
});

/// this is a wrapper class for FirebaseFirebaseDatabase.
class FirebaseCloudStore {
  final FirebaseFirestore firestore;

  FirebaseCloudStore({
    required this.firestore,
  });

  CollectionReference collection(String table) {
    return firestore.collection(table);
  }
}
