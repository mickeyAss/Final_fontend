import 'package:flutter/material.dart';

class CategoryManTab extends StatefulWidget {
  const CategoryManTab({super.key});

  @override
  State<CategoryManTab> createState() => _CategoryManTabState();
}

class _CategoryManTabState extends State<CategoryManTab> {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, // 2 คอลัมน์ (แถวละ 2 รูป)
      crossAxisSpacing: 6, // ช่องว่างระหว่างรูปแนวนอน
      mainAxisSpacing: 6, // ช่องว่างระหว่างรูปแนวตั้ง
      shrinkWrap: true, // ให้ GridView อยู่ใน Column ได้
      physics: NeverScrollableScrollPhysics(), // ป้องกัน scroll ซ้อน
      children: [
        Image.asset("assets/images/m2.jpg", fit: BoxFit.cover),
      ],
    );
  }
}
