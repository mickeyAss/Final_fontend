import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fontend_pro/pages/login.dart';
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/get_all_category.dart';
import 'package:fontend_pro/models/register_user_request.dart';

class CategoryWomanTab extends StatefulWidget {
  const CategoryWomanTab({super.key});

  @override
  State<CategoryWomanTab> createState() => _CategoryWomanTabState();
}

List<GetAllCategory> categories = [];

class StyleItem {
  final String imagePath;
  final String title;
  bool isSelected;

  StyleItem({
    required this.imagePath,
    required this.title,
    this.isSelected = false,
  });
}

class _CategoryWomanTabState extends State<CategoryWomanTab> {
  late Future<List<GetAllCategory>> futureCategories;
  List<bool> selected = [];

  @override
  void initState() {
    super.initState();
    futureCategories = loadCategories();
  }

  int get selectedCount => selected.where((e) => e).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder<List<GetAllCategory>>(
            future: futureCategories,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('ไม่พบข้อมูลสไตล์'));
              }

              final snapshotCategories = snapshot.data!;
              if (selected.length != snapshotCategories.length) {
                selected = List.generate(snapshotCategories.length, (_) => false);
              }
              categories = snapshotCategories; // อัปเดตตัวแปร global

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  itemCount: snapshotCategories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = snapshotCategories[index];
                    final isSelected = selected[index];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selected[index] = !isSelected;
                        });
                      },
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(item.cimage),
                                fit: BoxFit.cover,
                                colorFilter: isSelected
                                    ? ColorFilter.mode(
                                        Colors.black.withOpacity(0.4),
                                        BlendMode.darken)
                                    : null,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: Text(
                              item.cname,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 5,
                                    color: Colors.black.withOpacity(0.7),
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.black : Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        size: 18, color: Colors.white)
                                    : const SizedBox(width: 18, height: 18),
                              ),
                            ),
                          ),
                          // ไอคอนตกใจสำหรับแสดงรายละเอียด
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel:
                                      MaterialLocalizations.of(context)
                                          .modalBarrierDismissLabel,
                                  barrierColor: Colors.black54,
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                  pageBuilder:
                                      (context, animation, secondaryAnimation) {
                                    return Center(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxHeight: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.55,
                                            maxWidth: 360,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.25),
                                                blurRadius: 20,
                                                offset: Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 24, horizontal: 24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Header Icon
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: const Icon(
                                                  Icons.info_outline,
                                                  size: 48,
                                                  color: Colors.black87,
                                                ),
                                              ),

                                              const SizedBox(height: 20),

                                              // Title
                                              Text(
                                                item.cname,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),

                                              const SizedBox(height: 16),

                                              // Description with scroll
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  child: Text(
                                                    item.cdescription,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color:
                                                          Colors.grey.shade800,
                                                      height: 1.5,
                                                    ),
                                                    textAlign:
                                                        TextAlign.justify,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 24),

                                              // Close button
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.black87,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 14),
                                                    elevation: 5,
                                                    shadowColor: Colors.black45,
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: const Text(
                                                    'ปิด',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  transitionBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    return ScaleTransition(
                                      scale: CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutBack,
                                      ),
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.6),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        // ปุ่มล่าง
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    // กดข้าม สมัครเลย ไม่ต้องเลือก category
                    submitRegister(skipCategory: true);
                  },
                  child: const Text('ข้าม'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: selectedCount > 0 ? () => submitRegister() : null,
                  child: Text('ยืนยัน ($selectedCount)'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ดึงข้อมูลจาก API
  Future<List<GetAllCategory>> loadCategories() async {
    final config = await Configuration.getConfig();
    final url = config['apiEndpoint'];
    log("กำลังโหลดข้อมูล category จาก: $url/category/get");

    final response = await http.get(Uri.parse("$url/category/get"));

    if (response.statusCode == 200) {
      final allCategories = getAllCategoryFromJson(response.body);

      // กรองเฉพาะรายการที่ ctype == Ctype.F (enum)
      final filtered = allCategories.where((item) => item.ctype == Ctype.F).toList();

      log("โหลดข้อมูล category สำเร็จ (${filtered.length} รายการที่ ctype = F)");
      return filtered;
    } else {
      log("โหลดข้อมูล category ไม่สำเร็จ: ${response.statusCode}");
      throw Exception('โหลดข้อมูล category ไม่สำเร็จ');
    }
  }

  void submitRegister({bool skipCategory = false}) async {
    if (!skipCategory) {
      if (categories.isEmpty || selected.length != categories.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ข้อมูลหมวดหมู่ยังไม่สมบูรณ์")),
        );
        return;
      }

      final selectedCategoryIds = <int>[];
      for (int i = 0; i < selected.length; i++) {
        if (selected[i]) {
          selectedCategoryIds.add(categories[i].cid);
        }
      }

      if (selectedCategoryIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("กรุณาเลือกอย่างน้อย 1 หมวดหมู่")),
        );
        return;
      }

      await _registerUser(selectedCategoryIds);
    } else {
      // กรณีข้าม ไม่เลือก category ส่งเป็น list ว่าง
      await _registerUser([]);
    }
  }

  Future<void> _registerUser(List<int> categoryIds) async {
    final gs = GetStorage();
    final model = RegisterUserRequest(
      name: gs.read('register_name') ?? '',
      email: gs.read('register_email') ?? '',
      password: gs.read('register_password') ?? '',
      height: gs.read('register_height') ?? 0,
      weight: gs.read('register_weight') ?? 0,
      shirtSize: gs.read('register_shirtSize') ?? '',
      chest: gs.read('register_chest') ?? 0,
      waistCircumference: gs.read('register_waist') ?? 0,
      hip: gs.read('register_hips') ?? 0,
      personalDescription: '', // สมมุติค่าคงที่
      categoryIds: categoryIds,
    );

    final config = await Configuration.getConfig();
    final url = "${config['apiEndpoint']}/user/register";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: registerUserRequestToJson(model),
      );

      log("Register response: ${response.statusCode} ${response.body}");

      if (response.statusCode == 201) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Loginpage()),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("สมัครไม่สำเร็จ"),
            content: Text("รหัสสถานะ: ${response.statusCode}\n${response.body}"),
            actions: [
              TextButton(
                child: const Text("ตกลง"),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        );
      }
    } catch (e) {
      log("Register error: $e");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("ข้อผิดพลาด"),
          content: Text("เกิดข้อผิดพลาดระหว่างสมัครสมาชิก\n$e"),
          actions: [
            TextButton(
              child: const Text("ตกลง"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      );
    }
  }
}
