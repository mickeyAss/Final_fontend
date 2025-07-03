import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/get_all_category.dart';

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
        // ใช้ FutureBuilder ตรงนี้
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

              final categories = snapshot.data!;
              if (selected.length != categories.length) {
                selected = List.generate(categories.length, (_) => false);
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = categories[index];
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
                    Navigator.of(context).pop();
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
                  onPressed: selectedCount > 0
                      ? () {
                          print('เลือก $selectedCount สไตล์');
                        }
                      : null,
                  child: Text('ถัดไป ($selectedCount)'),
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

    // กรองเฉพาะรายการที่ ctype == Ctype.M (enum)
    final filtered = allCategories.where((item) => item.ctype == Ctype.F).toList();

    log("โหลดข้อมูล category สำเร็จ (${filtered.length} รายการที่ ctype = F)");
    return filtered;
  } else {
    log("โหลดข้อมูล category ไม่สำเร็จ: ${response.statusCode}");
    throw Exception('โหลดข้อมูล category ไม่สำเร็จ');
  }
}

}