import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreDatabase {
  User? user = FirebaseAuth.instance.currentUser;

  final CollectionReference posts = FirebaseFirestore.instance.collection('Posts');

  Future<void> addPosts(String breed, String age, String color, bool hasMedicalCondition, String image) {
    return posts.add({
      'UserEmail': user!.email,
      'Breed': breed,
      'Age': age,
      'Color': color,
      'HasMedicalCondition': hasMedicalCondition,
      'TimeStamp': Timestamp.now(),
      'image' : image,
    });
  }
  Future<void> addComment(String postId, String comment) async {
    try {
      await posts.doc(postId).collection('Comments').add({
        'username': user!.email,
        'comment': comment,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error adding comment: $e');
    }
  }
  Stream<QuerySnapshot> getPostStream(){
    final postsStream = FirebaseFirestore.instance
        .collection('Posts')
        .orderBy('TimeStamp', descending: true)
        .snapshots();

    return postsStream;
  }
}

