import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fontend_pro/models/get_all_category.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/pages/mainpage.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:fontend_pro/models/insert_post.dart';
import 'package:firebase_storage/firebase_storage.dart';

// อย่าลืมนำเข้าหน้า Mainpage ด้วย

class UserAllUploadPage extends StatefulWidget {
  const UserAllUploadPage({super.key});

  @override
  State<UserAllUploadPage> createState() => _UserAllUploadPageState();
}

class _UserAllUploadPageState extends State<UserAllUploadPage> {
  final GetStorage gs = GetStorage();
  List<AssetEntity> selectedAssets = [];
  bool isLoading = true;

  List<GetAllCategory> selectedCategories = [];
  late Future<List<GetAllCategory>> futureCategories;

  String _postPrivacy = 'Public'; // ค่าเริ่มต้น

  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final Map<String, Map<String, dynamic>> privacyOptions = {
    'Public': {
      'label': 'โพสต์แบบสาธารณะ',
      'icon': Icons.public,
    },
    'Friends': {
      'label': 'โพสต์เฉพาะเพื่อน',
      'icon': Icons.group,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSelectedAssets();
    futureCategories = loadCategories();
  }

  Future<void> _loadSelectedAssets() async {
    setState(() {
      isLoading = true;

      var user = gs.read('user');
      log('user id: ${user.toString()}');

      var image = gs.read('selected_image_ids');
      log('image: ${image.toString()}');
    });

    final List<dynamic>? storedIds =
        gs.read<List<dynamic>>('selected_image_ids');
    if (storedIds == null || storedIds.isEmpty) {
      setState(() {
        isLoading = false;
        selectedAssets = [];
      });
      return;
    }

    List<AssetEntity> assets = [];
    for (final id in storedIds) {
      final asset = await AssetEntity.fromId(id); // ✅ ใช้เมธอดนี้
      if (asset != null) {
        assets.add(asset);
      }
    }

    setState(() {
      selectedAssets = assets;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_left, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('สมัครสมาชิก',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : selectedAssets.isEmpty
              ? const Center(child: Text('ไม่มีรูปภาพที่เลือก'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.zero,
                          itemCount: selectedAssets.length,
                          itemBuilder: (context, index) {
                            final asset = selectedAssets[index];
                            return FutureBuilder<Uint8List?>(
                              future: asset.thumbnailDataWithSize(
                                const ThumbnailSize(300, 300),
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    snapshot.hasData) {
                                  return GestureDetector(
                                    onTap: () async {
                                      await showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (context) {
                                          return Dialog(
                                            backgroundColor: Colors.transparent,
                                            insetPadding:
                                                const EdgeInsets.all(16),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: InteractiveViewer(
                                                child: Image.memory(
                                                  snapshot.data!,
                                                  fit: BoxFit.contain,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.8,
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.6,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 8,
                                            offset: const Offset(2, 4),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                            width: 200,
                                            height: 200,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return Container(
                                  width: 200,
                                  height: 200,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 10,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.zero,
                                itemCount: selectedAssets.length,
                                itemBuilder: (context, index) {
                                  // รูปภาพเหมือนเดิม
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            Text(
                              'หัวเรื่องที่น่าสนใจ',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade900,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _topicController,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                height: 1.3,
                              ),
                              decoration: InputDecoration(
                                hintText: 'พิมพ์หัวเรื่องที่นี่...',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.black,
                                        Colors.grey,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.title,
                                      color: Colors.white),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    width: 2,
                                  ),
                                ),
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'คำบรรยาย',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade900,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _descriptionController,
                              maxLines: 4,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                height: 1.4,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'เขียนคำบรรยายหรือเพิ่มแฮชแท็ก(#) เกี่ยวกับไลฟ์สไตล์ของคุณ...',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.black,
                                        Colors.grey,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.edit_note,
                                      color: Colors.white),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    width: 2,
                                  ),
                                ),
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 44,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _postPrivacy,
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: Colors.black54),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  items: privacyOptions.entries.map((entry) {
                                    final isSelected =
                                        entry.key == _postPrivacy;
                                    return DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        decoration: isSelected
                                            ? BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              )
                                            : null,
                                        child: Row(
                                          children: [
                                            Icon(entry.value['icon'],
                                                color: Colors.black87,
                                                size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              entry.value['label'],
                                              style: TextStyle(
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w400,
                                                color: isSelected
                                                    ? Colors.black
                                                    : Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null &&
                                        value != _postPrivacy) {
                                      _postPrivacy = value;
                                      if (mounted) setState(() {});
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await showDialog<List<GetAllCategory>>(
                            context: context,
                            builder: (context) {
                              // สร้างตัวแปรชั่วคราวเพื่อเก็บหมวดหมู่ที่เลือก
                              List<GetAllCategory> tempSelected =
                                  List.from(selectedCategories);

                              return AlertDialog(
                                title: Text('เลือกหมวดหมู่'),
                                content: FutureBuilder<List<GetAllCategory>>(
                                  future: futureCategories,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Text("เกิดข้อผิดพลาด");
                                    }

                                    final categories = snapshot.data!;

                                    return SingleChildScrollView(
                                      child: Column(
                                        children: categories.map((cate) {
                                          final isSelected = tempSelected.any(
                                              (selected) =>
                                                  selected.cid == cate.cid);
                                          return CheckboxListTile(
                                            value: isSelected,
                                            title: Text(cate.cname),
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (value == true) {
                                                  tempSelected.add(cate);
                                                } else {
                                                  tempSelected.removeWhere(
                                                      (item) =>
                                                          item.cid == cate.cid);
                                                }
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, null),
                                    child: Text('ยกเลิก'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, tempSelected),
                                    child: Text('ตกลง'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (result != null) {
                            setState(() {
                              selectedCategories = result;
                            });
                          }
                        },
                        child: Text(
                            "เลือกหมวดหมู่ (${selectedCategories.length})"),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: submitPost,
            icon: const Icon(Icons.send, color: Colors.black),
            label: const Text(
              'โพสต์',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: Colors.black, width: 1.2),
              ),
              shadowColor: Colors.black.withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> uploadToFirebase(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return null;

    final fileName = "${DateTime.now().millisecondsSinceEpoch}_${asset.id}.jpg";
    final ref = FirebaseStorage.instance.ref().child("final_image/$fileName");

    try {
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      log('Firebase upload error: $e');
      return null;
    }
  }

  Future<void> submitPost() async {
    final topic = _topicController.text.trim();
    final description = _descriptionController.text.trim();
    final user = gs.read('user').toString();

    if (selectedAssets.isEmpty || user == null) {
      // แสดงแจ้งเตือนถ้าไม่เลือกภาพหรือไม่มี uid
      showModalBottomSheet(
        context: context,
        isDismissible: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 40),
              const SizedBox(height: 10),
              const Text('กรุณาเลือกรูปภาพอย่างน้อย 1 รูป',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ตกลง'),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // แสดง dialog โหลดก่อนเริ่ม
    showLoadingDialog(context);

    try {
      // อัปโหลดรูปขึ้น Firebase Storage
      List<String> imageUrls = [];

      for (final asset in selectedAssets) {
        final imageUrl = await uploadToFirebase(asset);
        if (imageUrl != null) {
          imageUrls.add(imageUrl);
        }
      }

      if (imageUrls.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปโหลดรูปภาพไม่สำเร็จ')),
        );
        return;
      }

      final postModel = Insertpost(
        postTopic: topic,
        postDescription: description,
        postFkUid: user.toString(),
        images: imageUrls, // ส่ง URL ที่อัปโหลดแล้ว
      );

      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      var postResponse = await http.post(
        Uri.parse("$url/image_post/post/add"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: insertpostToJson(postModel),
      );

      if (postResponse.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('โพสต์เรียบร้อย')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Mainpage()),
        );
      } else {
        log('Error inserting post: ${postResponse.body}');
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการโพสต์')),
        );
      }
    } catch (e) {
      log('Exception: $e');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
      );
    }
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้ปิดเอง
      barrierColor: Colors.black.withOpacity(0.3), // พื้นหลังโปร่งใส
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        );
      },
    );
  }

  Future<List<GetAllCategory>> loadCategories() async {
    final config = await Configuration.getConfig();
    final url = config['apiEndpoint'];
    log("กำลังโหลดข้อมูล category จาก: $url/category/get");

    final response = await http.get(Uri.parse("$url/category/get"));

    if (response.statusCode == 200) {
      final allCategories = getAllCategoryFromJson(response.body);

      // กรองเฉพาะรายการที่ ctype == Ctype.M (enum)
      final filtered =
          allCategories.where((item) => item.ctype == Ctype.M).toList();

      log("โหลดข้อมูล category สำเร็จ (${filtered.length} รายการที่ ctype = M)");
      return filtered;
    } else {
      log("โหลดข้อมูล category ไม่สำเร็จ: ${response.statusCode}");
      throw Exception('โหลดข้อมูล category ไม่สำเร็จ');
    }
  }
}

class FullscreenImagePage extends StatelessWidget {
  final Uint8List imageData;

  const FullscreenImagePage({super.key, required this.imageData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          // เพื่อซูมภาพได้
          child: Image.memory(imageData),
        ),
      ),
    );
  }
}
