import 'package:flutter/material.dart';
import 'package:unikam_survey/data/models/user_modele.dart';
import 'management_home_screen.dart';
import 'teacher_home_screen.dart';
import 'student_home_screen.dart';

class RoleBasedHomeScreen extends StatelessWidget {
  final UserModel user;

  const RoleBasedHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final role = user.role.trim().toLowerCase();

    switch (role) {
      case 'admin':
      case 'chef de groupe':
        return ManagementHomeScreen(user: user);
      case 'enseignant':
      case 'teacher':
        return TeacherHomeScreen(user: user);
      default:
        return StudentHomeScreen(user: user);
    }
  }
}
