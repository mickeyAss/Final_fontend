// import 'package:flutter/material.dart';
// import 'package:fontend_pro/pages/mainPage.dart'; // นำเข้า Mainpage
// import 'package:fontend_pro/pages/profilePage.dart'; // นำเข้า Profilepage

// class BottomNavbar extends StatefulWidget {
//   const BottomNavbar({super.key});

//   @override
//   State<BottomNavbar> createState() => _BottomNavbarState();
// }

// class _BottomNavbarState extends State<BottomNavbar> {
//   int selectedIndex = 0;  // ตัวแปรเก็บหน้าที่เลือก

//   // ฟังก์ชันเมื่อผู้ใช้เลือกเมนู
//   void _onItemTapped(int index) {
//     setState(() {
//       selectedIndex = index;  // เปลี่ยนหน้าที่เลือก
//     });
//   }

//   // สร้างหน้าที่จะถูกแสดงตามที่เลือก
//   Widget _buildBody() {
//     switch (selectedIndex) {
//       case 0:
//         return  Mainpage(uid: 1);  // หน้าหลัก
//       case 1:
//         return const Profilepage();  // หน้าโปรไฟล์
//       default:
//         return const Center(child: Text('Page not found'));  // หน้าอื่น ๆ
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _buildBody(),  // แสดงหน้า
//       bottomNavigationBar: BottomNavigationBar(
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',  // เปลี่ยนเป็นชื่อที่ต้องการ
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',  // เปลี่ยนเป็นชื่อที่ต้องการ
//           ),
//         ],
//         currentIndex: selectedIndex,  // ใช้ selectedIndex เพื่อแสดงหน้าปัจจุบัน
//         onTap: _onItemTapped,  // ฟังก์ชันเมื่อเลือกเมนู
//       ),
//     );
//   }
// }
