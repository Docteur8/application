import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collections
  static CollectionReference get usersCollection => _firestore.collection('users');
  static CollectionReference get vehiclesCollection => _firestore.collection('vehicles');
  static CollectionReference get chatsCollection => _firestore.collection('chats');
  static CollectionReference get messagesCollection => _firestore.collection('messages');

  // Auth
  static FirebaseAuth get auth => _auth;
  static User? get currentUser => _auth.currentUser;
  static String? get currentUserId => _auth.currentUser?.uid;

  // Firestore
  static FirebaseFirestore get firestore => _firestore;

  // Storage
  static FirebaseStorage get storage => _storage;
  static Reference get storageRef => _storage.ref();

  // Get vehicle by ID
  static Future<DocumentSnapshot> getVehicle(String vehicleId) async {
    return await vehiclesCollection.doc(vehicleId).get();
  }

  // Get user by ID
  static Future<DocumentSnapshot> getUser(String userId) async {
    return await usersCollection.doc(userId).get();
  }

  // Stream of vehicles
  static Stream<QuerySnapshot> vehiclesStream({
    String? type,
    String? sortBy,
    int limit = 20,
  }) {
    Query query = vehiclesCollection;

    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }

    if (sortBy == 'price_asc') {
      query = query.orderBy('price', descending: false);
    } else if (sortBy == 'price_desc') {
      query = query.orderBy('price', descending: true);
    } else if (sortBy == 'date_desc') {
      query = query.orderBy('createdAt', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return query.limit(limit).snapshots();
  }

  // Stream of user's vehicles
  static Stream<QuerySnapshot> userVehiclesStream(String userId) {
    return vehiclesCollection
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Stream of chats
  static Stream<QuerySnapshot> chatsStream(String userId) {
    return chatsCollection
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Stream of messages
  static Stream<QuerySnapshot> messagesStream(String chatId) {
    return messagesCollection
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Search vehicles
  static Future<QuerySnapshot> searchVehicles(String searchTerm) async {
    final lowerSearch = searchTerm.toLowerCase();
    return await vehiclesCollection
        .where('title', isGreaterThanOrEqualTo: lowerSearch)
        .where('title', isLessThanOrEqualTo: '$lowerSearch\uf8ff')
        .limit(20)
        .get();
  }
}