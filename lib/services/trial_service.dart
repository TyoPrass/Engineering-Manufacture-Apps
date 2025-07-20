import 'package:cloud_firestore/cloud_firestore.dart';

class TrialService {
  final CollectionReference _trialCollection =
      FirebaseFirestore.instance.collection('Trial');

  Future<void> saveTrialData(Map<String, dynamic> data) async {
    try {
      // Add timestamp fields separately
      await _trialCollection.add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return;
    } catch (e) {
      print('Error saving trial data: $e');
      throw Exception('Failed to save trial data: $e');
    }
  }

  Future<void> updateTrialData(String docId, Map<String, dynamic> data) async {
    try {
      // Add update timestamp
      data['updated_at'] = FieldValue.serverTimestamp();

      await _trialCollection.doc(docId).update(data);
    } catch (e) {
      throw Exception('Failed to update trial data: $e');
    }
  }

  Future<void> deleteTrialData(String docId) async {
    try {
      await _trialCollection.doc(docId).delete();
    } catch (e) {
      throw Exception('Failed to delete trial data: $e');
    }
  }
}
