import 'package:blackout/features/post/post_screen.dart';
import 'package:blackout/features/profile/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Section
                Row(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: data['photoUrl'] != ''
                          ? NetworkImage(data['photoUrl'])
                          : null,
                      child: data['photoUrl'] == ''
                          ? const Icon(Icons.person, size: 45)
                          : null,
                    ),

                    const SizedBox(width: 25),

                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat("0", "Posts"),
                          _buildStat(data['followers'].toString(), "Followers"),
                          _buildStat(data['following'].toString(), "Following"),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Username
                Text(
                  data['username'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 5),

                // Bio
                Text(data['bio'].isEmpty ? "No bio yet." : data['bio']),

                const SizedBox(height: 15),

                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                    child: const Text("Edit Profile"),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddPostScreen()),
                    );
                  },
                  child: Text("Post"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
