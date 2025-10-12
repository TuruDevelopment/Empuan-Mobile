import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comment Section',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CommentSection(),
    );
  }
}

class Comment {
  String text;
  DateTime date;
  String userName;
  String userProfilePic;

  Comment(this.text, this.date, this.userName, this.userProfilePic);
}

class CommentSection extends StatefulWidget {
  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  List<Comment> comments = [];

  TextEditingController _commentController = TextEditingController();
  TextEditingController _userNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comment Section'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                Comment comment = comments[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage(comment.userProfilePic),
                  ),
                  title: Text(comment.userName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment.text),
                      SizedBox(height: 4),
                      Text(
                        '${comment.date.toString().split('.')[0]}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    onSubmitted: (_) => _postComment(),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _postComment,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Text('Name: '),
                Expanded(
                  child: TextField(
                    controller: _userNameController,
                    onSubmitted: (_) => _postComment(),
                    decoration: InputDecoration(
                      hintText: 'Enter your display name...',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _postComment() {
    String newCommentText = _commentController.text;
    String userName = _userNameController.text.isNotEmpty
        ? _userNameController.text
        : 'Anonymous';
    DateTime now = DateTime.now();
    Comment newComment = Comment(newCommentText, now, userName,
        'assets/profile_pic_placeholder.png');
    setState(() {
      comments.add(newComment);
      _commentController.clear();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _userNameController.dispose();
    super.dispose();
  }
}