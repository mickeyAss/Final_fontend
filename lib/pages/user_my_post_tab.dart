import 'package:flutter/material.dart';

class UserMyPostTab extends StatefulWidget {
  const UserMyPostTab({super.key});

  @override
  State<UserMyPostTab> createState() => _UserMyPostTabState();
}

class _UserMyPostTabState extends State<UserMyPostTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(), // ให้ใช้ scroll จากหน้าหลัก
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          'assets/images/s1.jpg',
          'assets/images/s2.jpg',
          'assets/images/s3.jpg',
          'assets/images/p1.jpg',
          'assets/images/p2.jpg',
          'assets/images/p3.jpg',
        ].map((imagePath) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          );
        }).toList(),
      ),
    );
  }
}
