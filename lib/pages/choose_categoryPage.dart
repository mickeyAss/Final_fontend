import 'dart:developer'; // สำหรับ log
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/pages/category_man_tab.dart';
import 'package:fontend_pro/pages/category_woman_tab.dart';

class ChooseCategorypage extends StatefulWidget {
  const ChooseCategorypage({super.key});

  @override
  State<ChooseCategorypage> createState() => _ChooseCategorypageState();
}

class _ChooseCategorypageState extends State<ChooseCategorypage> {
  int selectedGenderIndex = 0; // 0 = ผู้ชาย, 1 = ผู้หญิง
  final box = GetStorage();

  @override
  void initState() {
    super.initState();

    // อ่านและ log ข้อมูลจาก GetStorage
    log('Register Name: ${box.read('register_name')}');
    log('Register Email: ${box.read('register_email')}');
    log('Register Password: ${box.read('register_password')}');
    log('Register Height: ${box.read('register_height')}');
    log('Register Weight: ${box.read('register_weight')}');
    log('Register Chest: ${box.read('register_chest')}');
    log('Register Waist: ${box.read('register_waist')}');
    log('Register Hips: ${box.read('register_hips')}');
    log('Register Shirt Size: ${box.read('register_shirtSize')}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
                left: 20,
                top: 20,
                right: 20), // top จาก 50 เหลือ 20 เพราะมี AppBar แล้ว
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "สไตล์การแต่งตัวของคุณเป็น",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "แบบไหน?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "เลือกสไตล์การแต่งตัวที่คุณสนใจเพื่อแสดงผลลัพธ์ในสิ่งที่คุณสนใจมากขึ้น",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black45,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      selectedGenderIndex = 0;
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        selectedGenderIndex == 0 ? Colors.black : Colors.white,
                    foregroundColor:
                        selectedGenderIndex == 0 ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                      side: const BorderSide(color: Colors.black12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text("การแต่งกายผู้ชาย"),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      selectedGenderIndex = 1;
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        selectedGenderIndex == 1 ? Colors.black : Colors.white,
                    foregroundColor:
                        selectedGenderIndex == 1 ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                      side: const BorderSide(color: Colors.black12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text("การแต่งกายผู้หญิง"),
                ),
              ),
            ],
          ),

          Expanded(
            child: IndexedStack(
              index: selectedGenderIndex,
              children: const [
                CategoryManTab(),
                CategoryWomanTab(),
              ],
            ),
          )
        ],
      ),
    );
  }
}
