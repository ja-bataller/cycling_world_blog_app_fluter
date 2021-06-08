import 'package:cycling_world_blog_app/firebase_query.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'home_page.dart';
import 'firebase_query.dart';
import 'package:get/get.dart';

class Upload extends StatefulWidget {
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {

  File sampleImage;
  String _myValue;
  String url;

  final formKey = GlobalKey<FormState>();

  CrudMethods crudMethods = CrudMethods();

  var name;
  var displayName;

  var id;
  var deleteId;

  var uid;

  @override
  void initState() {

    crudMethods.getDisplayName().then((QuerySnapshot docs) {
      docs.docs.forEach((document) {
        name = document.data();
        displayName = (name["displayName"]);
        print(displayName);
      });
    });

    // crudMethods.deletePost().then((QuerySnapshot docs) {
    //   docs.docs.forEach((DocumentSnapshot document) {
    //     id = document.data();
    //     deleteId = document.reference.id;
    //     print(id);
    //     print(deleteId);
    //   });
    // });

    uid = crudMethods.getUsersUid();
    print(uid);

    super.initState();
  }

  Future getImage() async {
    var tempImage = await ImagePicker().getImage(source: ImageSource.gallery);

    setState(() {
      sampleImage = File(tempImage.path);
    });
  }

  bool validateAndSave() {
    final form = formKey.currentState;

    if(form.validate()) {
      form.save();
      return true;
    }
    else {
      return false;
    }
  }

  void saveToDatabase(url) {
    var userUID = uid;
    var author = displayName;
    var dbTimeKey = DateTime.now();
    var formatDate = DateFormat("MMM d, yyyy");
    var formatTime = DateFormat("EEEE, hh:mm aaa");

    String date = formatDate.format(dbTimeKey);
    String time = formatTime.format(dbTimeKey);

    print(userUID);
    print(author);
    print(dbTimeKey);
    print(_myValue);
    print(date);
    print(time);

    var data = {
      "uid": uid,
      "author": author,
      "image": url,
      "description": _myValue,
      "date": date,
      "time": time,
      'createdOn':FieldValue.serverTimestamp(),
    };

    crudMethods.addData(data);
    // FirebaseDatabase.instance.reference().child("Posts").push().set(data);

  }

  void goToHomePage() {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return Home();
        })
    );
  }

  void uploadImage() async {
    if (validateAndSave()) {
      final Reference uploadImageReference = FirebaseStorage.instance.ref().child("Post images");

      Navigator.pop(context);

      var timeKey = DateTime.now();

      final UploadTask uploadTask = uploadImageReference.child(timeKey.toString() + ".jpg").putFile(sampleImage);

      var imageURL =  await (await uploadTask).ref.getDownloadURL();

      url = imageURL.toString();
      print("Image URL $url");
      saveToDatabase(url);
      Get.snackbar('Uploaded', 'Your photo has been posted.');
    }

  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.grey[900], //change your color here
          ),
          title: Text("Upload Photo", style: TextStyle(color: Colors.grey[900])),
          centerTitle: true,
          backgroundColor: Color(0xfff1ca89),
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              getImage();
            },
            tooltip: "Add Photo",
            child: Icon(Icons.add_a_photo_outlined),
            backgroundColor: Color(0xfff1ca89),
            ),
        body: Center(
          child: sampleImage == null ? Text("Select an Image") : enableUpload(),
        ),
      ),
    );
  }

  Widget enableUpload() {
    return Container(
      child: Form (
        key: formKey,
        child: ListView (
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.0),
                child: Image.file(
                  sampleImage,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0 ),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0)),
                  focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.brown),
                  borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                validator: (value) => value.isEmpty ? "enter description here" : null,
                onSaved: (value) => _myValue  = value,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0 ),
              child: SizedBox(
                height: 40.0,
                child: ElevatedButton(
                    onPressed: () {
                     uploadImage();
                    },
                    child: Text("Upload"),
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0),)),
                    backgroundColor:MaterialStateProperty.all(Colors.orangeAccent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
