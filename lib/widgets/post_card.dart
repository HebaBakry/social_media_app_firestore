import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:social_media_app/screens/profile_screen.dart';
import 'package:social_media_app/services/firebase_service.dart';

class PostCard extends StatefulWidget {
  final DocumentSnapshot post;
  final User? currentUser;
  final Function(String, String) onEdit;
  final Function(String) onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUser,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  @override
  Widget build(BuildContext context) {
    final postId = widget.post.id;
    final content = widget.post['content'] ?? '';
    final userId = widget.post['userId'] ?? '';
    final timestamp = widget.post['createdAt'] as Timestamp?;
    final date = timestamp?.toDate();

    final isOwner =
        widget.currentUser != null && widget.currentUser!.uid == userId;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseService.getUserStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        String username = 'User';
        String firstLetter = '?';
        String? photoURL;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;

          username = data['username'] ?? 'User';
          firstLetter = username.isNotEmpty ? username[0].toUpperCase() : '?';

          photoURL = data.containsKey('photoURL') ? data['photoURL'] : null;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(uid: userId),
                        ),
                      ),
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
                          image: photoURL != null
                              ? DecorationImage(
                                  image: NetworkImage(photoURL),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoURL == null
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (date != null)
                          Text(
                            DateFormat('MMM d, y • h:mm a').format(date),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    if (isOwner)
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            widget.onEdit(postId, content);
                          } else if (value == 'delete') {
                            widget.onDelete(postId);
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(content, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
