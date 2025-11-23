import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/enhanced_splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_router.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/shifts/shifts_screen.dart';
import 'screens/payroll/payroll_screen.dart';
import 'services/data_seeding_service.dart';
import 'core/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 MAIN: Starting app initialization...');
  
  // Initialize database
  await DatabaseHelper.instance.database;
  print('🗄️ MAIN: Database initialized');
  
  // Seed database if needed
  final seedingService = DataSeedingService.instance;
  print('🌱 MAIN: Checking if seeding is needed...');
  
  if (await seedingService.needsSeeding()) {
    print('🌱 MAIN: Seeding is needed, starting seeding process...');
    await seedingService.seedDatabase();
    print('🌱 MAIN: Seeding completed');
  } else {
    print('🌱 MAIN: Seeding not needed, skipping...');
  }
  
  print('🚀 MAIN: Starting Flutter app...');
  runApp(const SecurityShiftBookingApp());
}

class SecurityShiftBookingApp extends StatelessWidget {
  const SecurityShiftBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mankind Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1E3A8A),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const EnhancedSplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardRouter(),
        '/profile': (context) => const ProfileScreen(),
        '/shifts': (context) => const ShiftsScreen(),
        '/payroll': (context) => const PayrollScreen(),
      },
    );
  }
}
