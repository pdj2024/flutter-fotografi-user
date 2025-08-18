import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


import 'navigation_provider.dart';

class ChatService {
  // get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // get user stream
  Stream<List<Map<String,dynamic>>> getUserStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
          final user = doc.data();

          return user;
      }).toList();
    });
  }

  // send message
  Future<void> sendMessage(NavigationProvider navigationProvider, String receiverID, String receiverEmail, dynamic message) async {
    // get current user info
    final String currentUserID = 'cus_2'; //navigationProvider.getCurrentUserID();
    final String currentUserEmail = 'cus_2@gmail.com'; // navigationProvider.getCurrentUserEmail();
    final Timestamp timestamp = Timestamp.now();

    // create a new message
    Message newMessage = Message(
      senderID: currentUserID,
      senderEmail: currentUserEmail,
      receiverID: receiverID,
      receiverEmail: receiverEmail,
      message: message,
      timestamp: timestamp,
       category: 'chat',
      );

    // construct chat roo ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

     // generate custom doc ID for message
  final now = DateTime.now();
final formattedDate = DateFormat('yyyy_MM_dd__HH_mm_ss').format(now);

// generate 4 digit random number
final random = Random();
final randomDigits = random.nextInt(9000) + 1000; // 1000-9999

final customDocId = 'message_user_${formattedDate}__${randomDigits}';

  // add new message to database with custom doc ID
  await _firestore.collection("chat_rooms")
      .doc(chatRoomID)
      .collection("messages")
      .doc(customDocId)
      .set(newMessage.toMap());
  }

  // get messages
 

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages({
  required String userID,
  required String otherUserID,
}) {
 List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');
  return FirebaseFirestore.instance
    .collection('chat_rooms')
    .doc(chatRoomID)
    .collection('messages')
    .orderBy('timestamp', descending: false)
    .withConverter<Map<String, dynamic>>(
      fromFirestore: (snapshots, _) => snapshots.data()!,
      toFirestore: (data, _) => data,
    )
    .snapshots();
}



}

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String receiverEmail;
  final String message;
  final Timestamp timestamp;
  final String category;

  Message({
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.receiverEmail,
    required this.message,
    required this.timestamp,
    required this.category
  });

  // convert to a map
  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'receiverEmail': receiverEmail,
      'message': message,
      'timestamp': timestamp,
      'category': category
    };
  }
}