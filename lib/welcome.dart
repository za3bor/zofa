import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:zofa/customer/signup.dart';
import 'package:zofa/customer/tabs.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color brown = const Color(0xFF6D4C41); // Warm healthy brown

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset('assets/background.jpg', fit: BoxFit.cover),
            ),

            // Semi-transparent overlay
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),

                    // Welcome Text
                    Text(
                      'ברוכים הבאים ל-זופא',
                      style: GoogleFonts.assistant(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 6,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    Text(
                      'חנות הבריאות שלך',
                      style: GoogleFonts.assistant(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 60),

                    // Guest Button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_outline),
                      label: Text(
                        'המשך כאורח',
                        style: GoogleFonts.assistant(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: brown.withValues(alpha: 0.4),
                      ),
                      onPressed: () async {
                        final userStatusBox = Hive.box('userStatus');
                        await userStatusBox.put('isLoggedIn', true);
                        await userStatusBox.put('isGuest', true);
                        await userStatusBox.put('isAdmin', false);

                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const TabsScreen(),
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    // Login Button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.phone_android),
                      label: Text(
                        'התחבר עם מספר טלפון',
                        style: GoogleFonts.assistant(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: brown,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 6,
                        shadowColor: Colors.black.withValues(alpha: 0.2),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
