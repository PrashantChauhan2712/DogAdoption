import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dog_adoption/components/my_post_button.dart';
import 'package:dog_adoption/components/my_textfield.dart';
import 'package:dog_adoption/database/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dog_adoption/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_post_page.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreDatabase database = FirestoreDatabase();
  final TextEditingController searchValueController = TextEditingController();
  String selectedCategory = 'Breed'; // Default category is Breed
  bool isPressed = false;

  late User currentUser; // Define currentUser attribute

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!; // Retrieve current user
  }

  void logout() {
    FirebaseAuth.instance.signOut();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Home Page",
          style: TextStyle(
            color: Colors.white, // Change text color here
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddPostPage(database: database)),
              );
            },
            icon: Row(
              children: [
                Text(
                  "Post",
                  style: TextStyle(color: Colors.black),
                ),
                SizedBox(width: 5), // Add some space between text and icon
                Icon(Icons.add),
              ],
            ),
          ),
        ],
      ),

      drawer: MyDrawer(),
      body: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 8),
              DropdownButton<String>(
                value: selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue!;
                  });
                },
                items: <String>['Breed', 'Age', 'Color'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              Expanded(
                child: MyTextField(
                  hintText: 'Enter search value',
                  obscureText: false,
                  controller: searchValueController,
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 40, // Adjust width as needed
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Trigger rebuild to apply filter
                  },
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.zero), // Remove padding
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent), // Transparent background
                  ),
                  child: Icon(
                    Icons.search,
                    color: Colors.black,
                  ),
                ),
              ),

              SizedBox(width: 8),
            ],
          ),
     // Track whether the button is pressed or not


      StreamBuilder(
            stream: database.getPostStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              final posts = snapshot.data!.docs;

              if (snapshot.data == null || posts.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: Text("No Dogs"),
                  ),
                );
              }

              // Filter posts based on selected category and search value
              final filteredPosts = posts.where((post) {
                final String postValue = post[selectedCategory].toString().toLowerCase();
                final String searchValue = searchValueController.text.toLowerCase();
                return postValue.contains(searchValue);
              }).toList();

              return Expanded(
                child: ListView.builder(
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    final post = filteredPosts[index];

                    String breed = post['Breed'];
                    String age = post['Age'];
                    String color = post['Color'];
                    bool hasMedicalCondition = post['HasMedicalCondition'];
                    String userEmail = post['UserEmail'];
                    Timestamp timestamp = post['TimeStamp'];
                    String image = post['image'];
                    bool isMyPost = userEmail == currentUser.email;

                    return ListTile(
                      title: Text('Breed: $breed'),
                      leading: Container(
                        height: 80,
                        width: 80,
                        child: Image.network(image),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Age: $age'),
                          Text('Color: $color'),
                          Text('Has Medical Condition: ${hasMedicalCondition ? 'Yes' : 'No'}'),
                          Text('User Email: $userEmail'),
                          Row(
                            children: [
                              Container(
                                width: 40,
                              child : ElevatedButton(
                                onPressed: () {
                                  _showCommentDialog(context, post.id); // Show comment dialog
                                },
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.zero), // Remove padding
                                  backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent), // Transparent background
                                ),
                                child :
                                Icon(
                                  Icons.comment,
                                  color: Colors.black,
                                ),
                              ),
                              ),
                              SizedBox(width: 8,),
                              if (isMyPost)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _viewComments(post.id); // Implement view comments
                                  },
                                  icon: Icon(
                                      Icons.comment_bank,
                                      color: Colors.black ,),
                                  label: Text(
                                    'View',
                                    style: TextStyle(
                                      color: Colors.grey[700], // Dark grey color
                                    ),
                                  ),
                                ),
                            ],
                          ),

                        ],
                      ),
                    );
                  },
                ),
              );
            },
          )
        ],
      ),
    );
  }
  Future<void> _showCommentDialog(BuildContext context, String postId) async {
    String comment = '';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Comment'),
          content: TextField(
            onChanged: (value) {
              comment = value;
            },
            decoration: InputDecoration(hintText: 'Enter your comment'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[700], // Dark grey color
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),

            TextButton(
              child: Text(
                  'Post',
                style: TextStyle(
                  color: Colors.grey[700], // Dark grey color
                ),
              ),
              onPressed: () {
                // Save comment to Firestore
                database.addComment(postId, comment);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> _viewComments(String postId) async {
    try {
      // Retrieve comments for the post from Firestore
      QuerySnapshot commentsSnapshot = await FirebaseFirestore.instance
          .collection('Posts')
          .doc(postId)
          .collection('Comments')
          .orderBy('timestamp', descending: true)
          .get();

      // Prepare comments data
      List<Map<String, dynamic>> comments = commentsSnapshot.docs.map((doc) {
        return {
          'username': doc['username'],
          'comment': doc['comment'],
        };
      }).toList();

      // Show comments in a dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Comments'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: comments.map((comment) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comment by: ${comment['username']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(comment['comment']),
                        Divider(), // Add divider between comments
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }
}

