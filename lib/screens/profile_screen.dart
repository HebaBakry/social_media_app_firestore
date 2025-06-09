import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/services/auth_service.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/services/toast_service.dart';
import 'package:social_media_app/widgets/post_card.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = AuthService.currentUser;
  String _username = 'User';
  bool _isEditing = false;
  bool _isLoadingUserData = true;
  bool _isSavingProfile = false;
  String? photoURL;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingUserData = true);
    try {
      final snapshot = await FirebaseService.getUserData(widget.uid);
      final userData = snapshot.data() as Map<String, dynamic>?;

      _username = userData?['username'] ?? 'User';
      _usernameController.text = _username;
      photoURL = userData?['photoURL'];
      print('photo: $photoURL');
    } catch (e) {
      ToastService.showError('Failed to load user data: $e');
      _username = 'User';
      _usernameController.text = _username;
    } finally {
      setState(() => _isLoadingUserData = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (currentUser == null) return;

    setState(() => _isSavingProfile = true);
    try {
      await AuthService.updateProfile(_usernameController.text);
      await FirebaseService.updateUserProfile(
        userId: currentUser!.uid,
        username: _usernameController.text,
        photoURL: currentUser!.photoURL!,
      );

      setState(() {
        _username = _usernameController.text;
        _isEditing = false;
      });

      ToastService.showSuccess('Profile updated successfully!');
    } catch (e) {
      ToastService.showError('Failed to update profile: $e');
    } finally {
      setState(() => _isSavingProfile = false);
    }
  }

  Widget _buildProfileHeader() {
    final firstLetter = _username.isNotEmpty ? _username[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 40),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.deepPurple.shade100,
                        backgroundImage: photoURL != null
                            ? NetworkImage(photoURL!)
                            : null,
                        child: photoURL == null
                            ? Text(
                                firstLetter,
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade800,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: widget.uid == currentUser?.uid && !_isEditing
                            ? IconButton(
                                onPressed: () =>
                                    setState(() => _isEditing = true),
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.deepPurple.shade400,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _isEditing
                    ? Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _usernameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a username';
                                  }
                                  if (value.length > 20) {
                                    return 'Username too long (max 20 chars)';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelText: 'Username',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: _isSavingProfile
                                      ? null
                                      : _updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple.shade400,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    elevation: 3,
                                  ),
                                  child: _isSavingProfile
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Save Changes'),
                                ),
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: _isSavingProfile
                                      ? null
                                      : () {
                                          setState(() {
                                            _isEditing = false;
                                            _usernameController.text =
                                                _username;
                                          });
                                        },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey.shade600,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Text(
                            _username,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Member since ${currentUser?.metadata.creationTime?.year ?? ''}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    if (currentUser == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'User not logged in.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.post_add, color: Colors.deepPurple.shade400),
              const SizedBox(width: 8),
              Text(
                widget.uid == currentUser?.uid
                    ? 'My Posts'
                    : "${_username.trim()}'s Posts",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.getUserPostsStream(widget.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading posts: ${snapshot.error}',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.deepPurple),
                );
              }

              final posts = snapshot.data?.docs ?? [];

              if (posts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.post_add,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PostCard(
                      post: posts[index],
                      currentUser: currentUser,
                      onEdit: (postId, content) {
                        // Implement edit functionality
                      },
                      onDelete: (postId) {
                        // Implement delete functionality
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.uid == currentUser?.uid
              ? 'My Profile'
              : "${_username.trim()}'s Profile",
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
      ),
      body: _isLoadingUserData
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple.shade400,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [_buildProfileHeader(), _buildPostsSection()],
              ),
            ),
    );
  }
}
