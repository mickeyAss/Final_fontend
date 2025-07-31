import 'package:get/get.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ใส่ข้อมูลเริ่มต้นถ้ามี
    _nameController.text = "Sarawut Sutthibanyo";
    _bioController.text = "คำอธิบายสำหรับ ชอบเที่ยว ชอบกำมะรูป 💚😍🥰";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 24),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'แก้ไขโปรไฟล์',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // บันทึกข้อมูล
              _saveProfile();
            },
            child: const Text(
              'เสร็จสิ้น',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Image Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: const NetworkImage(
                          // ใส่ URL รูปโปรไฟล์ที่นี่
                          'https://via.placeholder.com/200x200.png?text=Profile'
                        ),
                        child: null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // เปลี่ยนรูปโปรไฟล์
                  _changeProfilePicture();
                },
                child: const Text(
                  'เปลี่ยนรูปโปรไฟล์',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Name Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ชื่อ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        hintText: 'ใส่ชื่อของคุณ',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Bio Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'คำอธิบายสำหรับ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _bioController,
                      maxLines: 4,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        hintText: 'เขียนคำอธิบายเกี่ยวกับตัวคุณ',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeProfilePicture() {
    // ฟังก์ชันสำหรับเปลี่ยนรูปโปรไฟล์
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'เปลี่ยนรูปโปรไฟล์',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.black),
                title: const Text('ถ่ายรูป'),
                onTap: () {
                  Navigator.pop(context);
                  // เพิ่มโค้ดถ่ายรูปที่นี่
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.black),
                title: const Text('เลือกจากแกลเลอรี่'),
                onTap: () {
                  Navigator.pop(context);
                  // เพิ่มโค้ดเลือกรูปจากแกลเลอรี่ที่นี่
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('ลบรูปโปรไฟล์', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // เพิ่มโค้ดลบรูปโปรไฟล์ที่นี่
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _saveProfile() {
    // ฟังก์ชันบันทึกข้อมูล
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();
    
    if (name.isEmpty) {
      // แสดง error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาใส่ชื่อ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // เพิ่มโค้ดบันทึกข้อมูลไปยัง API ที่นี่
    print('Name: $name');
    print('Bio: $bio');
    
    // แสดง success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('บันทึกข้อมูลเรียบร้อยแล้ว'),
        backgroundColor: Colors.green,
      ),
    );
    
    // กลับไปหน้าก่อนหน้า
    Future.delayed(const Duration(seconds: 1), () {
      Get.back();
    });
  }
}