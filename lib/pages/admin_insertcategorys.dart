import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminInsertCategory extends StatefulWidget {
  const AdminInsertCategory({super.key});

  @override
  State<AdminInsertCategory> createState() => _AdminInsertCategoryState();
}

class _AdminInsertCategoryState extends State<AdminInsertCategory> {
  final _formKey = GlobalKey<FormState>();
  final _cnameController = TextEditingController();
  final _ctypeController = TextEditingController();
  final _cdescriptionController = TextEditingController();
  
  File? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _cnameController.dispose();
    _ctypeController.dispose();
    _cdescriptionController.dispose();
    super.dispose();
  }

  // ฟังก์ชันเลือกรูปภาพ
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: ${e.toString()}', isError: true);
    }
  }

  // อัปโหลดรูปภาพไปยัง Firebase Storage
  Future<String?> uploadFileToFirebase(File file) async {
    try {
      log('🔄 Starting Firebase upload for file: ${file.path}');

      if (!file.existsSync()) {
        log('❌ File does not exist: ${file.path}');
        return null;
      }

      log('📁 File info: ${file.path} (${file.lengthSync()} bytes)');

      final fileName = "category_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance.ref().child("categories/$fileName");

      log('☁️ Uploading to Firebase Storage: categories/$fileName');

      final uploadTask = await ref.putFile(file).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          log('❌ Firebase upload timeout for file: ${file.path}');
          throw Exception('Firebase upload timeout');
        },
      );

      final url = await uploadTask.ref.getDownloadURL();
      log('✅ Firebase upload successful: $url');
      return url;
    } catch (e, stackTrace) {
      log('❌ Firebase upload error for file ${file.path}: $e');
      log('Stack trace: $stackTrace');
      return null;
    }
  }

  // แสดง Dialog เลือกแหล่งที่มาของรูปภาพ
  void _changeImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'เลือกรูปภาพหมวดหมู่',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                _buildBottomSheetOption(
                  icon: Icons.camera_alt,
                  title: 'ถ่ายรูป',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildBottomSheetOption(
                  icon: Icons.photo_library,
                  title: 'เลือกจากแกลเลอรี่',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_imageFile != null)
                  _buildBottomSheetOption(
                    icon: Icons.delete_outline,
                    title: 'ลบรูปภาพ',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _imageFile = null;
                      });
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red.shade600 : Colors.blue.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red.shade600 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _insertCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageFile == null) {
      _showSnackBar('กรุณาเลือกรูปภาพหมวดหมู่', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // อัปโหลดรูปภาพไป Firebase Storage
      final imageUrl = await uploadFileToFirebase(_imageFile!);
      
      if (imageUrl == null) {
        throw Exception('ไม่สามารถอัปโหลดรูปภาพได้');
      }

      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.post(
        Uri.parse('$url/category/insert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cname': _cnameController.text.trim(),
          'cimage': imageUrl,
          'ctype': _ctypeController.text.trim(),
          'cdescription': _cdescriptionController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (mounted) {
          _showSnackBar(data['message'] ?? 'เพิ่มหมวดหมู่สำเร็จ', isError: false);
          
          // ล้างฟอร์ม
          _formKey.currentState!.reset();
          _cnameController.clear();
          _ctypeController.clear();
          _cdescriptionController.clear();
          setState(() {
            _imageFile = null;
          });
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'เกิดข้อผิดพลาด');
      }
    } catch (e) {
      log("Insert category error: $e");
      _showSnackBar('เกิดข้อผิดพลาด: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'เพิ่มหมวดหมู่',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey.shade100,
                            child: _imageFile != null
                                ? Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 60,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'ยังไม่ได้เลือกรูปภาพ',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _changeImage,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _changeImage,
                    child: Text(
                      _imageFile != null ? 'เปลี่ยนรูปภาพ' : 'เลือกรูปภาพหมวดหมู่',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Form Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildModernTextField(
                      label: "ชื่อหมวดหมู่",
                      controller: _cnameController,
                      hint: "กรอกชื่อหมวดหมู่",
                      icon: Icons.category_outlined,
                    ),
                    const SizedBox(height: 24),
                    _buildModernTextField(
                      label: "ประเภทหมวดหมู่",
                      controller: _ctypeController,
                      hint: "กรอกประเภทหมวดหมู่",
                      icon: Icons.type_specimen_outlined,
                    ),
                    const SizedBox(height: 24),
                    _buildModernTextField(
                      label: "คำอธิบาย",
                      controller: _cdescriptionController,
                      hint: "กรอกคำอธิบายหมวดหมู่",
                      icon: Icons.description_outlined,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _insertCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'บันทึกหมวดหมู่',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Clear Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          _formKey.currentState!.reset();
                          _cnameController.clear();
                          _ctypeController.clear();
                          _cdescriptionController.clear();
                          setState(() {
                            _imageFile = null;
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    'ล้างข้อมูล',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 14,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'กรุณากรอก$label';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}