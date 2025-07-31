import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/pages/searchPage.dart';
import 'package:fontend_pro/pages/profilePage.dart';
import 'package:fontend_pro/models/get_all_post.dart';
import 'package:fontend_pro/models/get_user_uid.dart';
import 'package:fontend_pro/pages/following_tab_page.dart';
import 'package:fontend_pro/pages/recommended_tab_page.dart';
import 'package:fontend_pro/pages/user_add_friendsPage.dart';
import 'package:fontend_pro/pages/user_upload_photoPage.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Mainpage extends StatefulWidget {
  const Mainpage({super.key});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  bool isFavorite = false;

  int _currentIndex = 0; // เก็บ index ของ navbar ที่เลือก

  GetStorage gs = GetStorage();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    var uid = gs.read('user');
    log(uid.toString());
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomePageTab(),
      Searchpage(),
      UserUploadPhotopage(),
      UserAddFriendspage(),
      Profilepage(),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 25,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              // Inner shadow effect
              BoxShadow(
                color: Colors.white.withOpacity(0.9),
                blurRadius: 1,
                offset: const Offset(0, 1),
                spreadRadius: -1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
              ),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _currentIndex,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.black87,
                unselectedItemColor: Colors.grey.shade600,
                selectedFontSize: 0,
                unselectedFontSize: 0,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                onTap: (index) {
                  if (index == 2) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => const UserUploadPhotopage(),
                    );
                  } else {
                    setState(() {
                      _currentIndex = index;
                    });
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_filled),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: 'Search',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.add_circle_outline),
                    label: 'Upload',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.group),
                    label: 'Friends',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
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
