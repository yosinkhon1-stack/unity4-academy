import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:unity4_academy/firebase_options.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Web environment persistence can sometimes cause 'Internal Assertion Failed' errors.
    // Disabling it explicitly for stability on web.
    try {
      if (identical(0, 0.0)) { // Simple check for web (dart2js/ddc treats int and double differently in some aspects, but 'identical(0, 0.0)' is true on web)
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: false,
        );
      }
    } catch (e) {
      print("Firestore settings error: $e");
    }
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
}
