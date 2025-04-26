import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleManager {
  static const String ROLE_USER = 'user';
  static const String ROLE_ADMIN = 'admin';
  static const String ROLE_ENTERPRISE = 'enterprise';
  static const String ADMIN_EMAIL = 'abdelghafourkorachi9@gmail.com';

  static Future<void> setUserRole(User user, String role) async {
    print('Setting user role for: ${user.email}, role=$role');
    try {
      String finalRole = user.email == ADMIN_EMAIL ? ROLE_ADMIN : role;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'email': user.email,
            'role': finalRole,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(
            Duration(seconds: 20),
            onTimeout: () {
              throw Exception('Firestore write timed out');
            },
          );
      print('User role set successfully: ${user.email}, role=$finalRole');
    } on FirebaseException catch (e) {
      print(
        'Firestore error setting user role: code=${e.code}, message=${e.message}',
      );
      // Vérifier si l'erreur est liée au réseau (mode hors ligne probable)
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        print('Firestore is offline, write queued locally');
      } else {
        throw Exception('Firestore error: ${e.code} - ${e.message}');
      }
    } catch (e) {
      print('Unexpected error setting user role: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<String?> getUserRole(User user) async {
    print('Getting user role for: ${user.email}');
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        String role = doc.get('role') as String;
        if (user.email == ADMIN_EMAIL && role != ROLE_ADMIN) {
          await setUserRole(user, ROLE_ADMIN);
          return ROLE_ADMIN;
        }
        print('User role retrieved: ${user.email}, role=$role');
        return role;
      }
      print('No role found for user: ${user.email}');
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }
}
