// import 'dart:developer';

// import 'package:flutter/material.dart';
// import 'package:fontend_pro/pages/edit_profile.dart';
// import 'package:fontend_pro/pages/mainPage.dart';
// import 'package:get/get.dart';

// class Profilepage extends StatefulWidget {
//   const Profilepage({super.key});

//   @override
//   State<Profilepage> createState() => _ProfilepageState();
// }

// class _ProfilepageState extends State<Profilepage> {
//   int selectedIndex = 0;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: Colors.white,
//         selectedItemColor: Colors.black,
//         unselectedItemColor: Colors.grey,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.add_circle_outline), label: 'Post'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.people_alt_outlined), label: 'Friends'),
//           BottomNavigationBarItem(icon: Icon(Icons.person_pin), label: 'Me'),
//         ],
//         currentIndex: selectedIndex,
//         onTap: (int index) {
//           setState(() {
//             selectedIndex = index;
//             log(selectedIndex.toString());
//           });
//         },
//       ),
//       body: _buildBody(),
//     );
//   }

//   Widget _buildBody() {
//     switch (selectedIndex) {
//       case 0:
//         return const Mainpage(); // หน้า Mainpage
//       case 4:
//         return _buildProfilePage(); // หน้าโปรไฟล์
//       default:
//         return Center(
//           child: Text('Page $selectedIndex'),
//         );
//     }
//   }

//   Widget _buildProfilePage() {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 50.0),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               const Spacer(),
//               const Text(
//                 "Apidsada Laochai",
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const Spacer(),
//               const Icon(Icons.settings),
//             ],
//           ),
//           const SizedBox(height: 30),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               ClipOval(
//                 child: Image.asset(
//                   'assets/images/pic1.jpg',
//                   width: 80,
//                   height: 80,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               Column(
//                 children: const [
//                   Text(
//                     "10",
//                     style: TextStyle(
//                         fontWeight: FontWeight.bold, fontSize: 15),
//                   ),
//                   Text(
//                     "กำลังติดตาม",
//                     style: TextStyle(color: Colors.black54),
//                   )
//                 ],
//               ),
//               const Text(
//                 "|",
//                 style: TextStyle(fontSize: 25, color: Colors.black45),
//               ),
//               Column(
//                 children: const [
//                   Text("20",
//                       style: TextStyle(
//                           fontWeight: FontWeight.bold, fontSize: 15)),
//                   Text(
//                     "ผู้ติดตาม",
//                     style: TextStyle(color: Colors.black54),
//                   )
//                 ],
//               ),
//               const Text(
//                 "|",
//                 style: TextStyle(fontSize: 25, color: Colors.black45),
//               ),
//               Column(
//                 children: const [
//                   Text("30",
//                       style: TextStyle(
//                           fontWeight: FontWeight.bold, fontSize: 15)),
//                   Text(
//                     "ถูกใจ",
//                     style: TextStyle(color: Colors.black54),
//                   )
//                 ],
//               )
//             ],
//           ),
//           const SizedBox(height: 20),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: const [
//               Text("I love travel"),
//             ],
//           ),
//           const SizedBox(height: 20),
//           OutlinedButton(
//               style: OutlinedButton.styleFrom(
//                 backgroundColor: const Color.fromARGB(255, 255, 255, 255),
//                 foregroundColor: Colors.black,
//                 padding: const EdgeInsets.only(left: 135, right: 135),
//                 textStyle: const TextStyle(
//                     fontSize: 12, fontWeight: FontWeight.bold),
//                 elevation: 10,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(5),
//                 ),
//               ),
//               onPressed: () {
//                 Get.to(() => const EditProfilePage());
//               },
//               child: const Text('แก้ไขโปรไฟล์')),
//         ],
//       ),
//     );
//   }
// }
