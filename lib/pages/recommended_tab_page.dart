import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/get_all_category.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:http/http.dart' as http;

class RecommendedTab extends StatefulWidget {
  final PageController pageController;
  const RecommendedTab({super.key, required this.pageController});

  @override
  State<RecommendedTab> createState() => _RecommendedTabState();
}

class _RecommendedTabState extends State<RecommendedTab> {
  List<GetAllCategory> category = [];
  late Future<void> loadData_Category;
  int selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    loadData_Category = loadDataCategory();
  }

  final PageController pageController = PageController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, // ให้เลื่อนแนวนอน
            child: FutureBuilder(
                future: loadData_Category,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading user data'));
                  }
                  return Row(
                    children: category.asMap().entries.map((entry) {
                      int index = entry.key;
                      var cate = entry.value;

                      bool isSelected = selectedIndex == index;

                      return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: TextButton(
                              onPressed: () {
                                setState(() {
                                  selectedIndex = index;
                                });
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: isSelected
                                    ? Colors.black
                                    : Colors
                                        .black54, // เปลี่ยนสีตัวอักษรเมื่อเลือก
                              ),
                              child: Text(
                                cate.cname,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              )));
                    }).toList(),
                  );
                }),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/pic2.jpg',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "apxd_lxz ",
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                          foregroundColor:
                              const Color.fromARGB(255, 255, 255, 255),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2), // ลด padding ด้านบน-ล่าง
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize:
                              const Size(0, 40), // ลดขนาดขั้นต่ำของปุ่ม
                          visualDensity: VisualDensity
                              .compact, // ลดความสูงของปุ่มให้กะทัดรัดขึ้น
                        ),
                        onPressed: () {},
                        child: const Text("ติดตาม"),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (String result) {
                          // Handle เมื่อกดเลือกเมนู
                          if (result == 'report') {
                            // ดำเนินการรายงาน
                          } else if (result == 'block') {
                            // ดำเนินการบล็อก
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'report',
                            child: Text('รายงาน'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'block',
                            child: Text('บล็อก'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              Center(
                child: Container(
                  height: 450, // กำหนดความสูงให้กับ PageView
                  width: double.infinity, // กำหนดความกว้างเต็มหน้าจอ
                  child: PageView(
                    controller: pageController, // เชื่อมโยงกับ PageController
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/p1.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/p2.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/p3.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              // SmoothPageIndicator
              Center(
                child: SmoothPageIndicator(
                  controller: pageController, // เชื่อมโยงกับ PageController
                  count: 3, // จำนวนรูป
                  effect: ExpandingDotsEffect(
                    dotWidth: 8, // ขนาดจุด
                    dotHeight: 8, // ความสูงของจุด
                    spacing: 8, // ระยะห่างระหว่างจุด
                    expansionFactor: 4, // ขนาดขยายจุดเมื่อถูกเลือก
                    dotColor: const Color.fromARGB(
                        255, 0, 0, 0), // สีของจุดที่ไม่ได้เลือก
                    activeDotColor: Colors.black38, // สีของจุดที่เลือก
                  ),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 255, 255, 255),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 2), // ลด padding ด้านบน-ล่าง
                            textStyle: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            minimumSize:
                                const Size(0, 40), // ลดขนาดขั้นต่ำของปุ่ม
                            visualDensity: VisualDensity
                                .compact, // ลดความสูงของปุ่มให้กะทัดรัดขึ้น
                          ),
                          onPressed: () {},
                          child: const Text('สตรีท')),
                      SizedBox(
                        width: 8,
                      ),
                      OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 255, 255, 255),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 2), // ลด padding ด้านบน-ล่าง
                            textStyle: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            minimumSize:
                                const Size(0, 40), // ลดขนาดขั้นต่ำของปุ่ม
                            visualDensity: VisualDensity
                                .compact, // ลดความสูงของปุ่มให้กะทัดรัดขึ้น
                          ),
                          onPressed: () {},
                          child: const Text('chainese')),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // ทำสิ่งที่ต้องการเมื่อไอคอนแรกถูกกด
                        },
                        child: Row(
                          children: [
                            Icon(Icons.favorite_border),
                            Text("423"),
                          ],
                        ),
                      ),
                      SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          // ทำสิ่งที่ต้องการเมื่อไอคอนที่สองถูกกด
                        },
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/chat.png',
                              height: 20,
                              width: 20,
                            ),
                            SizedBox(width: 3),
                            Text("42"),
                          ],
                        ),
                      ),
                      SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          // ทำสิ่งที่ต้องการเมื่อไอคอนที่สามถูกกด
                        },
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_outline_rounded),
                            Text("224"),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),

              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "แต่งตัวชิลๆ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("ไอเดียแต่งตัวถ่ายรูปหน้ากระจกสวยๆจ้าา"),
                    Text(
                      "#ถ่ายรูปหน้ากระจก #ชุดเล่น",
                      style: TextStyle(color: Colors.blue),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      "3 วันที่แล้ว",
                      style: TextStyle(color: Colors.black38, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      )),
    );
  }

  Future<void> loadDataCategory() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    final response = await http.get(Uri.parse("$url/category/get"));
    if (response.statusCode == 200) {
      category = getAllCategoryFromJson(response.body);
      log(response.body);
      setState(() {});
    } else {
      log('Error loading user data: ${response.statusCode}');
    }
  }
}
