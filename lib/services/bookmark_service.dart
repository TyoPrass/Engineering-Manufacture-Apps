import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user ID with proper error handling
  String? _getCurrentUserId() {
    final user = _auth.currentUser;
    return user?.uid;
  }

  // Check if a document is bookmarked by the current user
  Future<bool> isBookmarked(String collectionName, String documentId) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) return false;

      // Check if this document is bookmarked by the current user
      final bookmarkDoc = await _firestore
          .collection('bookmarks')
          .where('userId', isEqualTo: userId)
          .where('collectionName', isEqualTo: collectionName)
          .where('documentId', isEqualTo: documentId)
          .limit(1)
          .get();

      return bookmarkDoc.docs.isNotEmpty;
    } catch (e) {
      print('Error checking bookmark status: $e');
      return false;
    }
  }

  // Add a bookmark for the current user
  Future<void> addBookmark(String collectionName, String documentId) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Create a unique ID for the bookmark
      final bookmarkId = '$userId-$collectionName-$documentId';

      await _firestore.collection('bookmarks').doc(bookmarkId).set({
        'userId': userId,
        'collectionName': collectionName,
        'documentId': documentId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding bookmark: $e');
      rethrow;
    }
  }

  // Remove a bookmark for the current user
  Future<void> removeBookmark(String collectionName, String documentId) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Delete with the unique bookmark ID
      final bookmarkId = '$userId-$collectionName-$documentId';
      await _firestore.collection('bookmarks').doc(bookmarkId).delete();
    } catch (e) {
      print('Error removing bookmark: $e');
      rethrow;
    }
  }

  // Get all bookmarked document IDs for a specific collection for the current user
  Stream<List<String>> getBookmarkedIds(String collectionName) {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        // Return empty stream if not logged in
        return Stream.value([]);
      }

      return _firestore
          .collection('bookmarks')
          .where('userId', isEqualTo: userId)
          .where('collectionName', isEqualTo: collectionName)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => doc.data()['documentId'] as String)
            .toList();
      });
    } catch (e) {
      print('Error getting bookmarked IDs: $e');
      return Stream.value([]);
    }
  }
}
