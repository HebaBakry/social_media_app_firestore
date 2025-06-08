import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _posts = _firestore.collection('posts');
  static final CollectionReference _users = _firestore.collection('users');

  // Create post (now only stores user ID)
  static Future<void> createPost(String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _posts.add({
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get posts stream with user data
  static Stream<QuerySnapshot> getPostsStream() {
    return _posts.orderBy('createdAt', descending: true).snapshots();
  }

  // Update post
  static Future<void> updatePost(String postId, String newContent) async {
    await _posts.doc(postId).update({
      'content': newContent,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete post
  static Future<void> deletePost(String postId) async {
    await _posts.doc(postId).delete();
  }

  // Create/update user profile
  static Future<void> updateUserProfile({
    required String userId,
    required String username,
  }) async {
    await _users.doc(userId).set({
      'username': username,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get user data
  static Future<DocumentSnapshot> getUserData(String userId) async {
    return await _users.doc(userId).get();
  }

  static Stream<QuerySnapshot> getUserPostsStream(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<DocumentSnapshot> getUserStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots();
  }
}
