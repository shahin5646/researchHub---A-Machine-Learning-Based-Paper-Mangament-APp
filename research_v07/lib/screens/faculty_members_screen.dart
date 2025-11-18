import 'package:flutter/material.dart';
import '../data/faculty_data.dart';
import '../models/faculty.dart';
import 'faculty_profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class FacultyMembersScreen extends StatelessWidget {
  const FacultyMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Faculty Members',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: facultyMembers.length,
        itemBuilder: (context, index) {
          final Faculty faculty = facultyMembers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(faculty.imageUrl),
                radius: 24,
              ),
              title: Text(faculty.name,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text(faculty.designation),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FacultyProfileScreen(faculty: faculty),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
