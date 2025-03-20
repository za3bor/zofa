import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../main.dart'; // Adjust this import based on your app structure

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Verification Completed
  Future<void> verificationCompleted(
      PhoneAuthCredential phoneAuthCredential, BuildContext context) async {
    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently signed in.')),
      );
      return;
    }

    await user.reauthenticateWithCredential(phoneAuthCredential);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User reauthenticated successfully')),
      );
    }
  }

  // Verification Failed
  void verificationFailed(FirebaseAuthException error, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Phone verification failed: ${error.message}')),
    );
  }

  // Code Sent
  void codeSent(
      String verificationId, int? resendToken, BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController codeController = TextEditingController();

        return AlertDialog(
          title: const Text('Enter SMS code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'SMS Code'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final smsCode = codeController.text.trim();
                  if (smsCode.isNotEmpty) {
                    final credential = PhoneAuthProvider.credential(
                      verificationId: verificationId,
                      smsCode: smsCode,
                    );
                    try {
                      await user.reauthenticateWithCredential(credential);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reauthentication successful')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Reauthentication failed: $e')),
                        );
                      }
                    }
                    codeController.dispose();
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        );
      },
    );
  }

Future<bool> reauthenticateUser(BuildContext context) async {
  final user = _auth.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No user is currently signed in.')),
    );
    return false;
  }

  Completer<bool> completer = Completer<bool>(); // Wait for user input

  await _auth.verifyPhoneNumber(
    phoneNumber: user.phoneNumber!,
    verificationCompleted: (PhoneAuthCredential credential) async {
      await user.reauthenticateWithCredential(credential);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Re-authentication successful')),
        );
      }
      completer.complete(true);
    },
    verificationFailed: (FirebaseAuthException error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${error.message}')),
        );
      }
      completer.complete(false);
    },
    codeSent: (String verificationId, int? resendToken) {
      showDialog(
        context: context,
        builder: (context) {
          final TextEditingController codeController = TextEditingController();
          return AlertDialog(
            title: const Text('Enter SMS code'),
            content: TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'SMS Code'),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final smsCode = codeController.text.trim();
                  if (smsCode.isNotEmpty) {
                    final credential = PhoneAuthProvider.credential(
                      verificationId: verificationId,
                      smsCode: smsCode,
                    );
                    try {
                      await user.reauthenticateWithCredential(credential);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Re-authentication successful')),
                        );
                        Navigator.pop(context);
                      }
                      completer.complete(true);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Re-authentication failed: $e')),
                        );
                      }
                      completer.complete(false);
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    },
    codeAutoRetrievalTimeout: (String verificationId) {},
  );

  return completer.future; // Wait until reauthentication is done
}


  // Delete Firebase Cloud Messaging (FCM) Token
  Future<void> deleteFcmToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    // ignore: empty_catches
    } catch (e) {
    }
  }

  // Delete Account
  Future<void> deleteAccount(BuildContext context, String ipAddress) async {
    try {
      final user = _auth.currentUser;

      if (user == null || user.phoneNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is currently signed in.')),
        );
        return;
      }
    // Step 1: Reauthenticate the user
      final isReauthenticated = await reauthenticateUser(context);
      if (!isReauthenticated) return;

    // Step 2: Delete user-related data (e.g., Firestore, API, Hive)
      final response = await http
          .delete(
        Uri.parse('http://$ipAddress/api/deleteUser/${user.phoneNumber}'),
      )
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Request timed out');
      });

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        final message = body is Map && body.containsKey('message')
            ? body['message']
            : 'Failed to delete user';
        throw Exception(message);
      }

      await deleteHiveData();
      await deleteFcmToken();
      await user.delete();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MyApp()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  // Delete Hive Data
  Future<void> deleteHiveData() async {
    try {
      var box = await Hive.openBox('cart');
      await box.clear(); // Clears all data inside the box

      // If you want to delete the box completely, use:
      await Hive.deleteBoxFromDisk('cart');
    // ignore: empty_catches
    } catch (e) {
    }
  }
}
