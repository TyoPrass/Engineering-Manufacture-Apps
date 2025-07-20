import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:engginering/routes/app_pages.dart';
import 'package:engginering/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var user = Rxn<User>();
  var username = ''.obs;
  var userEmail = ''.obs;
  var profileImageUrl = ''.obs; // Add this line for profile image
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    user.value = _auth.currentUser;
    _auth.authStateChanges().listen((User? firebaseUser) {
      user.value = firebaseUser;
      if (firebaseUser != null) {
        username.value =
            firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? '';
      }
    });
    loadUserData();
  }

  Future<void> loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      username.value = currentUser.displayName ?? '';
      userEmail.value = currentUser.email ?? '';

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          profileImageUrl.value = userData['profileImage'] ?? '';
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    isLoading.value = true;

    try {
      // Sign in with email and password using Firebase
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        username.value = userCredential.user!.displayName ?? '';
        userEmail.value = userCredential.user!.email ?? '';

        // Load user data from Firestore to get the profile image URL
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          profileImageUrl.value = userData['profileImage'] ?? '';
        }
      }

      username.value = userCredential.user?.displayName ?? email.split('@')[0];
      Get.offAllNamed(Routes.HOME);
      Get.snackbar(
        'Success',
        'Logged in successfully as ${username.value}',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-credential':
          errorMessage = 'The credentials are invalid.';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
          break;
      }
      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void register(String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    isLoading.value = true;

    try {
      // Create user with email and password in Firebase
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update profile to set the display name
      await userCredential.user?.updateDisplayName(name);

      // Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userCredential.user?.uid)
          .set({
        'Username': name,
        'Email': email,
        'CreatedAt': FieldValue.serverTimestamp(),
      });

      // Sign out the user after registration so they need to login
      await _auth.signOut();

      // Navigate to login page
      Get.offAllNamed(Routes.LOGIN); // Redirect to login page
      Get.snackbar(
        'Success',
        'Registered successfully as $name. Please login to continue.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'The account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
          break;
      }
      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An unexpected error occurred: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    try {
      await _auth.signOut();
      username.value = '';
      userEmail.value = '';
      profileImageUrl.value = ''; // Clear profile image URL on logout
      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to log out: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      username.value = '';
      Get.offAllNamed(Routes.LOGIN); // Redirect to login_page.dart
      print('User signed out and redirected to login page');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sign out: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // Uji Coba
  final RxString testEmail = ''.obs;

  // Optionally, initialize testEmail with a value
  void setUserEmail(String email) {
    testEmail.value = email;
  }
}
