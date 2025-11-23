import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import 'simple_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class DashboardRouter extends StatelessWidget {
  const DashboardRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    
    if (currentUser == null) {
      // Redirect to login if no user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Route to appropriate dashboard based on user type
    switch (currentUser.userType) {
      case UserType.seniorAdmin:
      case UserType.secondaryAdmin:
      case UserType.manager:
        return const AdminDashboardScreen();
      case UserType.steward:
      case UserType.siasteward:
        return const SimpleDashboardScreen();
    }
  }
}
