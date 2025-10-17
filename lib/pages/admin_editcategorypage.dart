import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

// โมเดล
class GetAllCategory {
  int cid;
  String cname;
  String cimage;
  String ctype;
  String cdescription;

  GetAllCategory({
    required this.cid,
    required this.cname,
    required this.cimage,
    required this.ctype,
    required this.cdescription,
  });

  factory GetAllCategory.fromJson(Map<String, dynamic> json) {
    return GetAllCategory(
      cid: json["cid"],
      cname: json["cname"] ?? '',
      cimage: json["cimage"] ?? '',
      ctype: json["ctype"] ?? '',
      cdescription: json["cdescription"] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        "cid": cid,
        "cname": cname,
        "cimage": cimage,
        "ctype": ctype,
        "cdescription": cdescription,
      };
}

class EditCategoryPage extends StatefulWidget {
  const EditCategoryPage({super.key});

  @override
  State<EditCategoryPage> createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends State<EditCategoryPage> {
  List<GetAllCategory> categories = [];
  bool _isLoading = false;
  bool _isSaving = false;
  TextEditingController _searchController = TextEditingController();

  GetAllCategory? selectedCategory;
  Map<String, TextEditingController> fieldControllers = {};
  File? _imageFile;

  final Map<String, String> fieldLabels = {
    'cname': 'name',
    'ctype': 'type',
    'cdescription': 'description',
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories({String? query}) async {
    setState(() => _isLoading = true);
    try {
      final config = await Configuration.getConfig();
      final url = config['apiEndpoint'];

      String endpoint = query == null || query.isEmpty
          ? "$url/category/get"
          : "$url/category/search?q=$query";

      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          categories = data.map((e) => GetAllCategory.fromJson(e)).toList();
        });
      } else {
        _showSnackBar('โหลดหมวดหมู่ไม่สำเร็จ', isError: true);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectCategory(GetAllCategory category) {
    setState(() {
      selectedCategory = category;
      _imageFile = null;
      fieldControllers.clear();

      fieldControllers['cname'] = TextEditingController(text: category.cname);
      fieldControllers['ctype'] = TextEditingController(text: category.ctype);
      fieldControllers['cdescription'] =
          TextEditingController(text: category.cdescription);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadFileToFirebase(File file) async {
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref =
          FirebaseStorage.instance.ref().child("category_images/$fileName");
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      _showSnackBar('อัปโหลดรูปไม่สำเร็จ', isError: true);
      return null;
    }
  }

  Future<void> _saveCategory() async {
    if (selectedCategory == null) return;
    setState(() => _isSaving = true);

    try {
      final config = await Configuration.getConfig();
      final url = config['apiEndpoint'];

      Map<String, dynamic> updatedData = {
        'cname': fieldControllers['cname']!.text,
        'ctype': fieldControllers['ctype']!.text,
        'cdescription': fieldControllers['cdescription']!.text,
      };

      // อัปโหลดรูปถ้ามี
      if (_imageFile != null) {
        final uploadedUrl = await _uploadFileToFirebase(_imageFile!);
        if (uploadedUrl != null) {
          updatedData['cimage'] = uploadedUrl;
        }
      }

      final response = await http.put(
        Uri.parse("$url/category/update/${selectedCategory!.cid}"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        _showSnackBar('บันทึกสำเร็จ', isError: false);

        // อัปเดตรูปและข้อมูลใน selectedCategory ทันที
        setState(() {
          selectedCategory!.cname = updatedData['cname'];
          selectedCategory!.ctype = updatedData['ctype'];
          selectedCategory!.cdescription = updatedData['cdescription'];
          if (updatedData.containsKey('cimage')) {
            selectedCategory!.cimage = updatedData['cimage'];
          }
          _imageFile = null; // รีเซ็ตรูป temp หลังบันทึก
        });

        // ถ้าต้องการ อัปเดตรายการ categories ด้วย
        int index =
            categories.indexWhere((c) => c.cid == selectedCategory!.cid);
        if (index != -1) {
          categories[index] = selectedCategory!;
        }
      } else {
        _showSnackBar('บันทึกไม่สำเร็จ', isError: true);
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _changeCategoryImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
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
                const SizedBox(height: 12),
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
                _buildBottomSheetOption(
                  icon: Icons.delete_outline,
                  title: 'ลบรูป',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imageFile = null;
                      selectedCategory!.cimage = '';
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? Colors.red : Colors.blue),
            const SizedBox(width: 16),
            Text(title,
                style: TextStyle(
                    color: isDestructive ? Colors.red : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขหมวดหมู่')),
      body: Column(
        children: [
          // ซ่อนช่องค้นหาเมื่อเลือกหมวดหมู่แล้ว
          if (selectedCategory == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'ค้นหาหมวดหมู่',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _loadCategories(query: value),
              ),
            ),

          // ถ้ายังไม่ได้เลือกหมวดหมู่ ให้โชว์รายการ
          if (selectedCategory == null)
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.grey[200],
                        image: DecorationImage(
                          image: category.cimage.isNotEmpty
                              ? NetworkImage(category.cimage)
                              : const AssetImage('assets/placeholder.png')
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(category.cname),
                    onTap: () => _selectCategory(category),
                  );
                },
              ),
            ),

          // ถ้าเลือกหมวดหมู่แล้ว ให้โชว์ฟอร์มเต็มหน้า
          if (selectedCategory != null)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.grey[200],
                            image: DecorationImage(
                              image: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (selectedCategory!.cimage.isNotEmpty
                                      ? NetworkImage(selectedCategory!.cimage)
                                      : const AssetImage(
                                          'assets/placeholder.png')),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _changeCategoryImage,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 0, 0, 0),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('แก้ไขรูป',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),

                    // ฟิลด์แก้ไข
                    ...fieldControllers.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: entry.value,
                          decoration: InputDecoration(
                            labelText: fieldLabels[entry.key] ?? entry.key,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // สีดำ
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('บันทึก'),
                    ),
                    const SizedBox(height: 16),
                    // ปุ่มย้อนกลับไปเลือกหมวดหมู่ใหม่
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedCategory = null;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black, // สีดำ
                      ),
                      child: const Text('ย้อนกลับไปเลือกหมวดหมู่'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
