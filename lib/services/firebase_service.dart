import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../models/user.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<UserModel?> getUserProfile(String userId) async {
  try {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (!doc.exists) {
      print("No se encontró el perfil del usuario en Firestore");
      return null;
    }

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: userId,
      name: data["name"] ?? "Usuario sin nombre",
      email: data["email"] ?? "",
      phoneNumber: data["phoneNumber"] ?? "",
      birthDate: data["birthDate"] is Timestamp 
          ? (data["birthDate"] as Timestamp).toDate()
          : DateTime(2000, 1, 1), // Valor por defecto si no es Timestamp
      notificationsPreference: data["notificationsPreference"] ?? false,
      themePreference: data["themePreference"] ?? "light",
      location: data["location"] ?? "",
      userType: data["userType"] ?? "standard",
    );
  } catch (e) {
    print("Error obteniendo perfil de usuario: $e");
    return null;
  }
}


  Future<void> checkAndUpdateUserProfile(User user) async {
    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    DocumentSnapshot doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        "name": "Usuario sin nombre",
        "email": user.email,
        "phoneNumber": "",
        "birthDate": DateTime(2000, 1, 1),
        "notificationsPreference": false,
        "themePreference": "light",
        "location": "",
        "userType": "standard",
      }, SetOptions(merge: true));
    }
  }



  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      print("Error actualizando perfil: $e");
    }
  }

  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUserModel() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userData['id'] = user.uid;
        return UserModel.fromMap(userData);
      }
    }
    return null;
  }

  Future<void> createUserProfile(UserModel user) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).set(user.toMap());
    }
  }

  Future<List<Task>> getTasks() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('tasks')
          .get();
      
      return querySnapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  Future<void> addTask(Task task) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('tasks')
          .doc(task.id)
          .set(task.toMap());
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('tasks')
          .doc(task.id)
          .update(task.toMap());
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      print(e.toString());
    }
  }

  /*Future<void> updateUserProfile(UserModel user) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).update(user.toMap());
    }
  }*/

  Future<String> getUserName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.get('name') ?? 'Usuario';
    }
    return 'Usuario';
  }
}

