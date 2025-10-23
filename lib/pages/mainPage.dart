import 'dart:async';
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
  final int initialIndex;
  const Mainpage({super.key, this.initialIndex = 0});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final GetStorage gs = GetStorage();
  int unreadCount = 0;
  late int _currentIndex;

  // Firebase & Polling
  late DatabaseReference notifRef;
  StreamSubscription<DatabaseEvent>? notifSubscription;
  Timer? fallbackTimer;
  String? currentUserId;
  bool isFirebaseConnected = false;

  // Animation & Popup
  OverlayEntry? _overlayEntry;
  AnimationController? _animationController;
  late Animation<Offset> _slideAnimation;
  Timer? _hideTimer;
  bool _isAnimationInitialized = false;
  bool _isShowingPopup = false;

  // GlobalKey สำหรับ RecommendedTab
  final GlobalKey<RecommendedTabState> _recommendedTabKey = GlobalKey();

  // ติดตามแท็บก่อนหน้า
  int _lastTabIndex = 0;

  // ✅ เพิ่มตัวแปรควบคุมแท็บ
  late PageController _pageController;
  late RecommendedTab _recommendedTab;
  late FollowingTab _followingTab;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _lastTabIndex = _currentIndex;
    WidgetsBinding.instance.addObserver(this);
    _initializeUser();
    _initFirebase();
    _initAnimations();

    // ✅ สร้างแท็บและ controller ครั้งเดียว
    _pageController = PageController();
    _recommendedTab = RecommendedTab(
      key: _recommendedTabKey,
      pageController: _pageController,
    );
    _followingTab = FollowingTab(pageController: _pageController);
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
      _fetchUnreadNotificationCount();
      // เมื่อกลับมาที่แอป ให้รีเซ็ต feed เป็นปกติ
      _resetRecommendedTabIfNeeded();
    }
  }

  void _resetRecommendedTabIfNeeded() {
    if (_currentIndex == 0) {
      _recommendedTabKey.currentState?.resetToNormalFeed();
    }
  }

  void _initializeUser() {
    currentUserId = gs.read('user')?.toString();
    debugPrint('Current user id: $currentUserId');
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();

      if (currentUserId == null || currentUserId!.isEmpty) {
        _fallbackToApiPolling();
        return;
      }

      notifRef = FirebaseDatabase.instance.ref('notifications');
      DatabaseReference connectedRef =
          FirebaseDatabase.instance.ref('.info/connected');

      connectedRef.onValue.listen((event) {
        bool connected = event.snapshot.value as bool? ?? false;
        bool wasConnected = isFirebaseConnected;
        isFirebaseConnected = connected;

        if (!connected && fallbackTimer == null) {
          _fallbackToApiPolling();
        } else if (connected && !wasConnected) {
          fallbackTimer?.cancel();
          fallbackTimer = null;
        }
      });

      _setupNotificationListener();

      if (!isFirebaseConnected) {
        _fetchUnreadNotificationCount();
      }
    } catch (e) {
      debugPrint('Firebase init error: $e');
      _fallbackToApiPolling();
    }
  }

  void _setupNotificationListener() {
    notifSubscription = notifRef.onValue.listen(
      (DatabaseEvent event) {
        _processFirebaseData(event.snapshot.value);
      },
      onError: (error) {
        isFirebaseConnected = false;
        _fallbackToApiPolling();
      },
    );
  }

  void _processFirebaseData(dynamic data) {
    if (currentUserId == null || currentUserId!.isEmpty) return;
    int count = 0;

    try {
      if (data != null && data is Map) {
        final Map<String, dynamic> notifications =
            Map<String, dynamic>.from(data);

        notifications.forEach((key, value) {
          if (value is Map) {
            final notif = Map<String, dynamic>.from(value);
            final receiverUid = notif['receiver_uid']?.toString();
            final isRead = notif['is_read'];

            if (receiverUid == currentUserId) {
              bool isUnread = false;
              if (isRead is bool)
                isUnread = !isRead;
              else if (isRead is int)
                isUnread = (isRead == 0);
              else if (isRead is String) {
                isUnread = (isRead == '0' || isRead.toLowerCase() == 'false');
              }

              if (isUnread) count++;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error processing Firebase data: $e');
      return;
    }

    if (mounted && count != unreadCount) {
      if (count > unreadCount) {
        int newNotifications = count - unreadCount;
        _showNotificationPopup(newNotifications);
      }
      setState(() => unreadCount = count);
    }
  }

  void _fallbackToApiPolling() {
    if (fallbackTimer != null) return;
    _fetchUnreadNotificationCount();
    fallbackTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        _fetchUnreadNotificationCount();
      } else {
        fallbackTimer?.cancel();
        fallbackTimer = null;
      }
    });
  }

  Future<void> _fetchUnreadNotificationCount() async {
    if (currentUserId == null || currentUserId!.isEmpty) return;

    try {
      var config = await Configuration.getConfig();
      var apiEndpoint = config['apiEndpoint'];
      final url = Uri.parse('$apiEndpoint/user/notifications/$currentUserId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final NotificationModel.GetNotification data =
            NotificationModel.getNotificationFromJson(response.body);

        int count = data.notifications.where((n) => n.isRead == 0).length;

        if (mounted) {
          if (!isFirebaseConnected && count > unreadCount) {
            int newNotifications = count - unreadCount;
            _showNotificationPopup(newNotifications);
          }
          setState(() => unreadCount = count);
        }
      }
    } catch (e) {
      debugPrint('API polling error: $e');
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

  void _showNotificationPopup(int newCount) {
    if (_isShowingPopup) return;
    if (!_isAnimationInitialized || _animationController == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildNotificationPopup(newCount),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isShowingPopup = true;
    _animationController!.forward();
    HapticFeedback.lightImpact();

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), _hideOverlay);
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
                  colors: [Colors.blue.shade600, Colors.blue.shade700],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      newCount == 1
                          ? 'คุณมีการแจ้งเตือนใหม่ 1 รายการ'
                          : 'คุณมีการแจ้งเตือนใหม่ $newCount รายการ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _animationController?.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _isShowingPopup = false;
      });
    }
    _hideTimer?.cancel();
  }

  void _navigateToNotifications() async {
    _hideOverlay();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
    _fetchUnreadNotificationCount();
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: const UserUploadPhotopage(),
        ),
      ).then((result) {
        if (result == 'post_created') {
          setState(() {
            _currentIndex = 0;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _recommendedTabKey.currentState?.refreshAfterPosting();
          });
        }
      });
    } else {
      HapticFeedback.lightImpact();
      setState(() {
        _lastTabIndex = _currentIndex;
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildHomeWithTabs(),
      const Searchpage(),
      Container(),
      const UserAddFriendspage(),
      const Profilepage(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: _buildEnhancedBottomNavigationBar(),
    );
  }

  Widget _buildEnhancedBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildNavItem(0, Icons.home_rounded),
            _buildNavItem(1, Icons.search_rounded),
            _buildFABNavItem(),
            _buildNavItem(3, Icons.group_rounded),
            _buildNavItem(4, Icons.person_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        child: SizedBox(
          height: 60,
          child: Center(
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey.shade500,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFABNavItem() {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(2),
        child: const SizedBox(
          height: 60,
          child: Center(
            child: Icon(Icons.add_box_outlined, color: Colors.black, size: 26),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeWithTabs() {
    return DefaultTabController(
      length: 2,
      initialIndex: 1,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey.shade600,
                      indicatorColor: Colors.black,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      tabs: const [
                        Tab(text: 'กำลังติดตาม'),
                        Tab(text: 'สำหรับคุณ'),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isFirebaseConnected
                                ? Colors.black.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.notifications_rounded,
                              color: isFirebaseConnected
                                  ? Colors.black
                                  : Colors.grey.shade500,
                              size: 24,
                            ),
                            onPressed: _navigateToNotifications,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _followingTab,
                _recommendedTab,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
