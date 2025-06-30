import 'dart:developer';

import 'package:fontend_pro/models/get_all_post.dart';
import 'package:fontend_pro/pages/following_tab_page.dart';
import 'package:fontend_pro/pages/recommended_tab_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/get_user_uid.dart';
import 'package:fontend_pro/pages/profilePage.dart';
import 'package:fontend_pro/pages/searchPage.dart';
import 'package:fontend_pro/pages/user_add_friendsPage.dart';
import 'package:fontend_pro/pages/user_upload_photoPage.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Mainpage extends StatefulWidget {
  final int uid;

  Mainpage({super.key, required this.uid});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  bool isFavorite = false;

  int _currentIndex = 0; // เก็บ index ของ navbar ที่เลือก

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomePageTab(),
      Searchpage(),
      UserUploadPhotopage(),
      UserAddFriendspage(),
      Profilepage(uid: widget.uid),
    ];
    return Scaffold(
      body: SafeArea(
        child: _currentIndex == 0
            ? DefaultTabController(
                length: 2,
                initialIndex: 1, 
                child: Column(
                  children: [
                    // สร้าง TabBar เองโดยไม่ใช้ AppBar
                    TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black54,
                      indicatorColor: Colors.black,
                      tabs: const [
                        Tab(text: 'กำลังติดตาม'),
                        Tab(text: 'แนะนำสำหรับคุณ'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          FollowingTab(pageController: PageController()),
                          RecommendedTab(pageController: PageController()),
                        ],
                      ),
                    )
                  ],
                ),
              )
            : _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.white,
         elevation: 8,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        selectedFontSize: 0, // ลดขนาดฟอนต์ของข้อความที่เลือกเป็น 0
        unselectedFontSize: 0, // ลดขนาดฟอนต์ของข้อความที่ไม่เลือกเป็น 0
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_sharp),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
      ),
    );
  }
}

// หน้าแรกที่มี TabBar
class HomePageTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        RecommendedTab(pageController: PageController()),
        FollowingTab(pageController: PageController()),
      ],
    );
  }
}
