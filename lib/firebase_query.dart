import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CrudMethods {

  Future<void> addData(blogData) async {
    FirebaseFirestore.instance
        .collection("blogs")
        .add(blogData)
        .catchError((e) {
      print(e);
    });
  }

  getData() async {
    return await FirebaseFirestore.instance
        .collection("blogs")
        .orderBy("time", descending: true)
        .snapshots();
  }

  getDisplayName()  {
    User user = FirebaseAuth.instance.currentUser;
    String uid = user.uid.toString();
    String name;

    return FirebaseFirestore.instance
        .collection("Users")
        .where("uid", isEqualTo: uid)
        .get();
  }

  getUsersUid() {
    User user = FirebaseAuth.instance.currentUser;
    String uid = user.uid.toString();
    return uid;
  }

  deletePost(String id)  {
    User user = FirebaseAuth.instance.currentUser;
    String userUid = user.uid.toString();

    var data;
    var dbUid;

    // FirebaseFirestore.instance.collection("blogs").doc(id).get();

    FirebaseFirestore.instance
        .collection('blogs')
        .doc(id)
        .get()
        .then((DocumentSnapshot documentSnapshot) async {
          data = documentSnapshot.data();
          dbUid = (data["uid"]);

          print("dbUid: $dbUid");
          print("userUid: $userUid");

          if (userUid == dbUid) {
            await FirebaseFirestore.instance.collection("blogs").doc(id).delete();
          }
    });
  }

}
