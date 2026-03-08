import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Comment {
  String author;
  String text;
  DateTime date;

  Comment({required this.author, required this.text, required this.date});
}

class suaraPuanCommentPage extends StatefulWidget {
  @override
  State<suaraPuanCommentPage> createState() => _suaraPuanCommentPageState();
}

class _suaraPuanCommentPageState extends State<suaraPuanCommentPage> {
  @override
  Widget build(BuildContext context) {
    return CommentSection();
    // return Padding(
    //   padding: const EdgeInsets.all(20.0),
    //   child: Text("asdf"),
    // );
  }
}

class CommentSection extends StatefulWidget {
  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  List<Comment> comments = [];
  TextEditingController _commentController = TextEditingController();

  void _addComment(String text) {
    if (text.isNotEmpty) {
      Comment newComment = Comment(
        author: 'John Doe', // Example author name
        text: text,
        date: DateTime.now(),
      );
      setState(() {
        comments.add(newComment);
      });
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              Comment comment = comments[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(comment.author[0]),
                ),
                title: Text(comment.author),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.text),
                    SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMd().add_jm().format(comment.date),
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("asdf"),
        ),
        Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                  ),
                  onSubmitted: (text) => _addComment(text),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () => _addComment(_commentController.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
