import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole { admin, user }

class AuthProvider with ChangeNotifier {
  UserRole? _role;
  UserRole? get role => _role;

  // Call this after login
  Future<void> checkUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _role = UserRole.user;
      notifyListeners();
      return;
    }

    // Check if email contains "admin"
    if (user.email?.toLowerCase().contains('admin') == true) {
      _role = UserRole.admin;
    } else {
      _role = UserRole.user;
    }

    notifyListeners();
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _role = null;
    notifyListeners();
  }
}