import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fontend_pro/pages/searchPage.dart';
import 'package:fontend_pro/pages/profilePage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fontend_pro/pages/notificationsPage.dart';
import 'package:fontend_pro/pages/following_tab_page.dart';
import 'package:fontend_pro/pages/recommended_tab_page.dart';
import 'package:fontend_pro/pages/user_add_friendsPage.dart';
import 'package:fontend_pro/pages/user_upload_photoPage.dart';
import 'package:fontend_pro/models/get_notification.dart' as NotificationModel;

class Mainpage extends StatefulWidget {
  const Mainpage({super.key});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> with WidgetsBindingObserver, TickerProviderStateMixin {
  final GetStorage gs = GetStorage();
  int unreadCount = 0;
  int _currentIndex = 0;

  late DatabaseReference notifRef;
  StreamSubscription<DatabaseEvent>? notifSubscription;
  Timer? fallbackTimer;
  String? currentUserId;
  bool isFirebaseConnected = false;

  // สำหรับ Notification Popup
  OverlayEntry? _overlayEntry;
  AnimationController? _animationController;
  late Animation<Offset> _slideAnimation;
  Timer? _hideTimer;
  bool _isAnimationInitialized = false;
  bool _isShowingPopup = false; // เพิ่ม flag ป้องกัน popup ซ้ำ

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUser();
    _initFirebase();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOutBack,
    ));
    _isAnimationInitialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // เมื่อ app กลับมาทำงาน ให้ refresh ข้อมูล
      _fetchUnreadNotificationCount();
    }
  }

  void _initializeUser() {
    currentUserId = gs.read('user')?.toString();
    debugPrint('Current user id from GetStorage: $currentUserId');
    
    if (currentUserId == null || currentUserId!.isEmpty) {
      debugPrint('Warning: User ID is null or empty');
    }
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();
      
      if (currentUserId == null || currentUserId!.isEmpty) {
        debugPrint('Error: User ID is null or empty, falling back to API');
        _fallbackToApiPolling();
        return;
      }

      notifRef = FirebaseDatabase.instance.ref('notifications');
      
      // ตรวจสอบการเชื่อมต่อ Firebase
      DatabaseReference connectedRef = FirebaseDatabase.instance.ref('.info/connected');
      connectedRef.onValue.listen((event) {
        bool connected = event.snapshot.value as bool? ?? false;
        bool wasConnected = isFirebaseConnected;
        isFirebaseConnected = connected;
        debugPrint('Firebase connection status: $connected');
        
        if (!connected && fallbackTimer == null) {
          _fallbackToApiPolling();
        } else if (connected && !wasConnected) {
          // เมื่อ Firebase กลับมาเชื่อมต่อ ให้หยุด API polling
          fallbackTimer?.cancel();
          fallbackTimer = null;
        }
      });

      _setupNotificationListener();
      
      // เรียก API ครั้งแรกเฉพาะเมื่อ Firebase ไม่เชื่อมต่อ
      if (!isFirebaseConnected) {
        _fetchUnreadNotificationCount();
      }
      
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      _fallbackToApiPolling();
    }
  }

  void _setupNotificationListener() {
    // ฟังการเปลี่ยนแปลงจาก notifications ทั้งหมด
    notifSubscription = notifRef.onValue.listen(
      (DatabaseEvent event) {
        debugPrint('Firebase data received: ${event.snapshot.value != null}');
        _processFirebaseData(event.snapshot.value);
      },
      onError: (error) {
        debugPrint('Firebase listener error: $error');
        isFirebaseConnected = false;
        _fallbackToApiPolling();
      },
    );
  }

  void _processFirebaseData(dynamic data) {
    debugPrint('Processing Firebase data...');

    if (currentUserId == null || currentUserId!.isEmpty) {
      debugPrint('User ID is null, cannot process notifications');
      return;
    }

    int count = 0;
    
    try {
      if (data != null && data is Map) {
        final Map<String, dynamic> notifications = Map<String, dynamic>.from(data);
        
        debugPrint('Total notifications in Firebase: ${notifications.length}');

        notifications.forEach((key, value) {
          if (value != null && value is Map) {
            final Map<String, dynamic> notif = Map<String, dynamic>.from(value);
            
            debugPrint('Notification: receiver_uid=${notif['receiver_uid']}, is_read=${notif['is_read']}, current_user=$currentUserId');
            
            final receiverUid = notif['receiver_uid']?.toString();
            final isRead = notif['is_read'];

            if (receiverUid == currentUserId) {
              bool isUnread = false;
              if (isRead is bool) {
                isUnread = !isRead;
              } else if (isRead is int) {
                isUnread = (isRead == 0);
              } else if (isRead is String) {
                isUnread = (isRead == '0' || isRead.toLowerCase() == 'false');
              }
              
              if (isUnread) {
                count++;
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error processing Firebase data: $e');
      return;
    }

    debugPrint('Calculated unread count: $count (previous: $unreadCount)');

    if (mounted && count != unreadCount) {
      // แสดง popup เฉพาะเมื่อจำนวนเพิ่มขึ้น และมีการเปลี่ยนแปลงจริง ๆ
      if (count > unreadCount && unreadCount >= 0) {
        int newNotifications = count - unreadCount;
        _showNotificationPopup(newNotifications);
      }
      
      setState(() {
        unreadCount = count;
      });
      debugPrint('Updated UI with unread count: $unreadCount');
    }
  }

  // Fallback method หาก Firebase มีปัญหา
  void _fallbackToApiPolling() {
    if (fallbackTimer != null) return; // ป้องกันการสร้าง timer ซ้ำ
    
    debugPrint('Starting API polling fallback...');
    _fetchUnreadNotificationCount();
    
    // Poll ทุก 15 วินาที
    fallbackTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _fetchUnreadNotificationCount();
      } else {
        timer.cancel();
        fallbackTimer = null;
      }
    });
  }

  // ฟังก์ชันเพื่อดึงจำนวนการแจ้งเตือนจาก API
  Future<void> _fetchUnreadNotificationCount() async {
    if (currentUserId == null || currentUserId!.isEmpty) {
      debugPrint('Cannot fetch notifications: User ID is null');
      return;
    }

    try {
      var config = await Configuration.getConfig();
      var apiEndpoint = config['apiEndpoint'];
      final url = Uri.parse('$apiEndpoint/user/notifications/$currentUserId');

      debugPrint('Fetching notifications from API: $url');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final NotificationModel.GetNotification data =
            NotificationModel.getNotificationFromJson(response.body);

        int count = data.notifications
            .where((notification) => notification.isRead == 0)
            .length;

        debugPrint('API returned $count unread notifications');

        if (mounted) {
          // แสดง popup เฉพาะถ้า Firebase ไม่เชื่อมต่อ และมีการเปลี่ยนแปลงจริง
          if (!isFirebaseConnected && count > unreadCount && unreadCount >= 0) {
            int newNotifications = count - unreadCount;
            _showNotificationPopup(newNotifications);
          }
          
          setState(() {
            unreadCount = count;
          });
        }
      } else {
        debugPrint('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching notification count from API: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    notifSubscription?.cancel();
    fallbackTimer?.cancel();
    _hideTimer?.cancel();
    _animationController?.dispose();
    _hideOverlay();
    super.dispose();
  }

  // ฟังก์ชันแสดง Notification Popup
  void _showNotificationPopup(int newCount) {
    // ป้องกันการแสดง popup ซ้ำ
    if (_isShowingPopup) {
      debugPrint('Popup already showing, skipping');
      return;
    }

    if (!_isAnimationInitialized || _animationController == null) {
      debugPrint('Animation not initialized, skipping popup');
      return;
    }

    if (_overlayEntry != null) {
      _hideOverlay();
    }

    _isShowingPopup = true; // ตั้ง flag

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildNotificationPopup(newCount),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController!.forward();

    // เพิ่มเสียงสั่น (haptic feedback)
    HapticFeedback.lightImpact();

    // ซ่อน popup หลังจาก 4 วินาที
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      _hideOverlay();
    });
  }

  Widget _buildNotificationPopup(int newCount) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              _hideOverlay();
              _navigateToNotifications();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade600,
                    Colors.blue.shade700,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'การแจ้งเตือนใหม่',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          newCount == 1 
                            ? 'คุณมีการแจ้งเตือน 1 รายการใหม่'
                            : 'คุณมีการแจ้งเตือน $newCount รายการใหม่',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _hideOverlay(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _hideOverlay() {
    if (_overlayEntry != null && _isAnimationInitialized && _animationController != null) {
      _animationController!.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _isShowingPopup = false; // รีเซ็ต flag
      });
    } else if (_overlayEntry != null) {
      // หาก animation ไม่พร้อม ให้ลบ overlay ทันที
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isShowingPopup = false; // รีเซ็ต flag
    }
    _hideTimer?.cancel();
  }

  Route _createRouteToNotifications() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const Notificationspage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  // เมื่อกลับจากหน้า notification
  void _navigateToNotifications() async {
    _hideOverlay(); // ซ่อน popup ก่อนไปหน้าอื่น
    await Navigator.of(context).push(_createRouteToNotifications());
    
    // Refresh ข้อมูลหลังจากกลับมา
    await Future.delayed(const Duration(milliseconds: 300));
    _fetchUnreadNotificationCount();
  }

  // Method สำหรับ manual refresh
  void refreshNotificationCount() {
    debugPrint('Manual refresh notification count');
    _fetchUnreadNotificationCount();
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TabBar(
                              labelColor: Colors.black,
                              unselectedLabelColor: Colors.black54,
                              indicatorColor: Colors.black,
                              tabs: const [
                                Tab(text: 'กำลังติดตาม'),
                                Tab(text: 'สำหรับคุณ'),
                              ],
                            ),
                          ),
                          Stack(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.notifications_none,
                                  color: isFirebaseConnected ? Colors.black : Colors.grey,
                                ),
                                onPressed: () {
                                  debugPrint("Opening notifications - Current count: $unreadCount");
                                  _navigateToNotifications();
                                },
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Text(
                                      unreadCount > 99
                                          ? '99+'
                                          : unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
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
              BoxShadow(
                color: Colors.white.withOpacity(0.9),
                blurRadius: 1,
                offset: const Offset(1, 1),
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