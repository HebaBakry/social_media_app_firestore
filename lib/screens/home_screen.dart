import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:social_media_app/screens/log_in_screen.dart';
import 'package:social_media_app/screens/profile_screen.dart';
import 'package:social_media_app/services/auth_service.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/services/toast_service.dart';
import 'package:social_media_app/widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _postController = TextEditingController();
  final currentUser = AuthService.currentUser;
  late String username;
  late String firstLetter;

  @override
  void initState() {
    super.initState();
    username = currentUser?.displayName ?? 'User';
    firstLetter = username.isNotEmpty ? username[0].toUpperCase() : 'U';
  }

  void _logout(BuildContext context) async {
    try {
      await AuthService.signOut();
      ToastService.showSuccess('Logged out successfully!');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ToastService.showError('Logout failed: ${e.toString()}');
    }
  }

  Future<void> _createPost(String content) async {
    if (content.trim().isEmpty) return;
    try {
      await FirebaseService.createPost(content.trim());
      ToastService.showSuccess('Post created!');
      _postController.clear();
    } catch (e) {
      ToastService.showError('Failed to create post: $e');
    }
  }

  void _editPost(String postId, String currentContent) async {
    final TextEditingController controller = TextEditingController(
      text: currentContent,
    );

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Post',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 5,
                  minLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'What would you like to say?',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final newContent = controller.text.trim();
                      if (newContent.isEmpty) {
                        ToastService.showError('Post cannot be empty');
                        return;
                      }

                      try {
                        await FirebaseService.updatePost(postId, newContent);
                        ToastService.showSuccess('Post updated successfully!');
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        ToastService.showError('Failed to update post: $e');
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deletePost(String postId) async {
    try {
      await FirebaseService.deletePost(postId);
      ToastService.showSuccess('Post deleted!');
    } catch (e) {
      ToastService.showError('Failed to delete post: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple.shade400,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileScreen(uid: currentUser!.uid),
                          ),
                        ).then((_) {
                          setState(() {
                            final updatedUser = AuthService.currentUser;
                            username = updatedUser?.displayName ?? 'User';
                            firstLetter = username.isNotEmpty
                                ? username[0].toUpperCase()
                                : 'U';
                          });
                        }),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurple.shade100,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        image: currentUser?.photoURL != null
                            ? DecorationImage(
                                image: NetworkImage(currentUser!.photoURL!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: currentUser?.photoURL == null
                          ? Center(
                              child: Text(
                                firstLetter,
                                style: TextStyle(
                                  color: Colors.deepPurple.shade800,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _postController,
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Colors.grey[200],
                        filled: true,
                      ),
                      onSubmitted: (value) {
                        _createPost(value);
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.deepPurple.shade400),
                    onPressed: () => _createPost(_postController.text),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.getPostsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading posts'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final posts = snapshot.data!.docs;
                  if (posts.isEmpty) {
                    return const Center(
                      child: Text('No posts yet. Create one!'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return PostCard(
                        post: post,
                        currentUser: currentUser,
                        onEdit: _editPost,
                        onDelete: _deletePost,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
