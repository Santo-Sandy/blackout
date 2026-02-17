import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController captionController = TextEditingController();
  bool isLoading = false;

  Future<void> pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String> uploadImage(String postId) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('posts')
        .child('$postId.jpg');

    await ref.putFile(_imageFile!);

    return await ref.getDownloadURL();
  }

  Future<void> uploadPost() async {
    if (_imageFile == null) return;

    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser!;
    final postId = const Uuid().v4();

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final imageUrl = await uploadImage(postId);

    await FirebaseFirestore.instance.collection('posts').doc(postId).set({
      'postId': postId,
      'uid': user.uid,
      'username': userDoc['username'],
      'userPhoto': userDoc['photoUrl'] ?? '',
      'imageUrl': imageUrl,
      'caption': captionController.text.trim(),
      'likes': [],
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() => isLoading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Post"),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: uploadPost),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : const Icon(Icons.add_a_photo, size: 50),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: captionController,
              decoration: const InputDecoration(hintText: "Write a caption..."),
            ),
            const SizedBox(height: 20),
            if (isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
