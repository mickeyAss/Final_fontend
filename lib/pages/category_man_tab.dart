import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/pages/mainPage.dart';
import 'package:fontend_pro/models/get_all_category.dart';
import 'package:fontend_pro/models/register_user_request.dart';

class CategoryManTab extends StatefulWidget {
  const CategoryManTab({super.key});

  @override
  State<CategoryManTab> createState() => _CategoryManTabState();
}

// ✅ ตัวแปร global (จะได้รับค่าหลังโหลด FutureBuilder)
List<GetAllCategory> categories = [];

class _CategoryManTabState extends State<CategoryManTab> {
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

              categories = snapshotCategories; // ✅ อัปเดต global

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
                                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                                    : const SizedBox(width: 18, height: 18),
                              ),
                            ),
                          ),
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
                    submitRegister(skipCategory: true); // ข้าม
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

  Future<List<GetAllCategory>> loadCategories() async {
    final config = await Configuration.getConfig();
    final url = config['apiEndpoint'];
    log("📦 โหลด category จาก: $url/category/get");

    final response = await http.get(Uri.parse("$url/category/get"));

    if (response.statusCode == 200) {
      final allCategories = getAllCategoryFromJson(response.body);
      final filtered = allCategories.where((item) => item.ctype == Ctype.M).toList();

      log("✅ โหลดสำเร็จ (${filtered.length} รายการ)");
      return filtered;
    } else {
      log("❌ โหลด category ไม่สำเร็จ: ${response.statusCode}");
      throw Exception('โหลด category ไม่สำเร็จ');
    }
  }

  void submitRegister({bool skipCategory = false}) async {
    if (!skipCategory) {
      if (categories.isEmpty || selected.length != categories.length) {
        log("⚠️ categories หรือ selected ไม่ตรงกัน");
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

      log("🎯 หมวดหมู่ที่เลือก: $selectedCategoryIds");
      await _registerUser(selectedCategoryIds);
    } else {
      await _registerUser([]); // ข้าม
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
      personalDescription: '',
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

      log("📨 Register response: ${response.statusCode} ${response.body}");

      if (response.statusCode == 201) {
        final responseBody = response.body;
        final Map<String, dynamic> data = responseBody.isNotEmpty ? Map<String, dynamic>.from(jsonDecode(responseBody)) : {};
        final uid = data['uid'];

        if (uid != null) {
          gs.write('user', uid); // ✅ เก็บ UID
          log("✅ บันทึก UID ลง GetStorage: $uid");
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Mainpage()),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("สมัครไม่สำเร็จ"),
            content: Text("รหัสสถานะ: ${response.statusCode}\n${response.body}"),
            actions: [TextButton(child: const Text("ตกลง"), onPressed: () => Navigator.pop(context))],
          ),
        );
      }
    } catch (e) {
      log("❗ Register error: $e");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("ข้อผิดพลาด"),
          content: Text("เกิดข้อผิดพลาดระหว่างสมัครสมาชิก\n$e"),
          actions: [TextButton(child: const Text("ตกลง"), onPressed: () => Navigator.pop(context))],
        ),
      );
    }
  }
}
