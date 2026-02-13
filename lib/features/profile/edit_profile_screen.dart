import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final usernameController = TextEditingController();
  final bioController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String?> uploadImage(String uid) async {
    if (_imageFile == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('$uid.jpg');

    await ref.putFile(_imageFile!);

    return await ref.getDownloadURL();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    final data = doc.data()!;

    usernameController.text = data['username'];
    bioController.text = data['bio'];
  }

  Future<void> updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    setState(() => isLoading = true);

    String? imageUrl;

    if (_imageFile != null) {
      imageUrl = await uploadImage(user!.uid);
    }

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'username': usernameController.text.trim(),
      'bio': bioController.text.trim(),
      if (imageUrl != null) 'photoUrl': imageUrl,
    });

    setState(() => isLoading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : null,
                child: _imageFile == null
                    ? const Icon(Icons.camera_alt, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(labelText: "Bio"),
              maxLines: 3,
            ),
            const SizedBox(height: 25),
            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: updateProfile,
                      child: const Text("Save"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
