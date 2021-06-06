import 'package:flutter/material.dart';
import 'authentication.dart';
import 'upload_page.dart';
import 'firebase_query.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;

class Home extends StatefulWidget {
  @override

  Home({this.auth, this.onLoggedOut});

  final AuthImplementation auth;
  final VoidCallback onLoggedOut;

  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  CrudMethods crudMethods = new CrudMethods();

  Stream blogsStream;

  Widget blogsList() {
    return Container(
      child: blogsStream != null
          ? StreamBuilder(
            stream: blogsStream,
            builder: (context, snapshot) {
              return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: snapshot.data.docs.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return BlogsTile(
                      id: snapshot.data.docs[index].reference.id,
                      author: snapshot.data.docs[index].data()['author'],
                      image: snapshot.data.docs[index].data()['image'],
                      description: snapshot.data.docs[index].data()["description"],
                      date: snapshot.data.docs[index].data()['date'],
                      time: snapshot.data.docs[index].data()['time'],
                    );
                  });
            },
          )
          : Container(
            alignment: Alignment.center,
            child: Center(
              child: Text(
                "No blogs posted.",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
    );
  }

  @override
  void initState() {
    crudMethods.getData().then((result) {
      setState(() {
        blogsStream = result;
        print(blogsStream);
      });
    });

    super.initState();
  }

  void _logoutUser() async {
    try {
      await widget.auth.logOut();
      widget.onLoggedOut();
    } catch (e) {
      print("Error = $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(
          Icons.directions_bike_rounded,
          color: Colors.grey[900],
        ),
        title: Text("Cycling World", style: TextStyle(color: Colors.grey[900])),
        backgroundColor: Color(0xfff1ca89),
        actions: [
          IconButton(
            tooltip: "logout button",
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              // _logoutUser();
              loggingOutDialog(context);
            },
            color: Colors.grey[900],
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "upload photo",
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Upload();
          }));
        },
        child: const Icon(Icons.add),
        backgroundColor: Color(0xfff1ca89),
      ),
      body: blogsList(),
    );
  }

  void loggingOutDialog(BuildContext context) {
    var alertDialog = AlertDialog(
      title: Text("Log-out"),
      content: SingleChildScrollView(
        child: ListBody(
          children: [Text("Are you sure you want to log-out?")],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _logoutUser();
          },
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            )),
            backgroundColor: MaterialStateProperty.all(Colors.orangeAccent),
          ),
          child: Text("Yes"),
        ),
        ElevatedButton(
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            )),
            backgroundColor: MaterialStateProperty.all(Colors.grey),
          ),
          onPressed: () {
            return Navigator.pop(context);
          },
          child: Text("No"),
        )
      ],
    );

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return alertDialog;
        });
  }

}

class BlogsTile extends StatelessWidget {

  String id,author,image, description, date, time;

  CrudMethods crudMethods = CrudMethods();

  BlogsTile(
      {
      @required this.id,
      @required this.author,
      @required this.image,
      @required this.description,
      @required this.date,
      @required this.time});

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation:  10.0,
      margin: EdgeInsets.all(15.0),
      child: Container(
        padding: EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  author,
                  style: Theme.of(context).textTheme.subtitle2,
                  textAlign: TextAlign.center,
                ),
                ElevatedButton(
                  onPressed: () {
                    deleteDialog(context);
                  },
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                )
              ],
            ),
            SizedBox(
              height: 10.0,
            ),
            Image.network(image, fit: BoxFit.cover,),
            SizedBox(
              height: 10.0,
            ),
            Text(
              "$date / $time",
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 10.0,
            ),
            Text(
              id,
              style: TextStyle(
                  fontSize: 1,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            Text(
              description,
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 10.0,
            ),
          ],
        ),
      ),
    );
  }

  void deleteDialog(BuildContext context) {
    var alertDialog = AlertDialog(
      title: Text("Delete post?"),
      content: SingleChildScrollView(
        child: ListBody(
          children: [Text("Are you sure you want to delete this post?")],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: ()   {
            //  DELETE POST
            User user = FirebaseAuth.instance.currentUser;
            String userUid = user.uid.toString();

            var data;
            var dbUid;

            var imgUrl;

            FirebaseFirestore.instance
                .collection('blogs')
                .doc(id)
                .get()
                .then((DocumentSnapshot documentSnapshot) async {
              data = documentSnapshot.data();
              dbUid = (data["uid"]);
              imgUrl = (data["image"]);

              print("dbUid: $dbUid");
              print("userUid: $userUid");
              print("image: $imgUrl");

              var url = (data["image"]);

              var fileUrl = Uri.decodeFull(Path.basename(url)).replaceAll(new RegExp(r'(\?alt).*'), '');

              if (userUid == dbUid) {

                Reference storageReference = FirebaseStorage.instance.ref(fileUrl);
                await storageReference.delete();

                await FirebaseFirestore.instance.collection("blogs").doc(id).delete();

                Get.back();
                Get.snackbar('Deleted', 'Your post has been deleted.');
              } else {
                deleteErrorDialog(context);
              }
            });
            // crudMethods.deletePost(id);

          },
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                )),
            backgroundColor: MaterialStateProperty.all(Colors.redAccent),
          ),
          child: Text("Yes"),
        ),
        ElevatedButton(
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                )),
            backgroundColor: MaterialStateProperty.all(Colors.grey),
          ),
          onPressed: () {
            return Navigator.pop(context);
          },
          child: Text("No"),
        )
      ],
    );

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return alertDialog;
        });
  }

  void deleteErrorDialog(BuildContext context) {
    var alertDialog = AlertDialog(
      title: Text("Oops"),
      content: SingleChildScrollView(
        child: ListBody(
          children: [Text("Post not deleted. You are not the Author of this post.")],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                )),
            backgroundColor: MaterialStateProperty.all(Colors.grey),
          ),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Text("Close"),
        )
      ],
    );

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return alertDialog;
        });
  }
}

