import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/like_post.dart';
import 'package:fontend_pro/pages/profilePage.dart';
import 'package:fontend_pro/models/get_comment.dart';
import 'package:fontend_pro/models/get_all_category.dart';
import 'package:fontend_pro/pages/other_user_profile.dart';
import 'package:fontend_pro/models/get_all_post.dart' as model;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// ฟังก์ชันช่วยในการแสดงผล status สำหรับ enum
String getStatusText(model.PostStatus status) {
  switch (status) {
    case model.PostStatus.public:
      return 'สาธารณะ';
    case model.PostStatus.friends:
      return 'เฉพาะเพื่อน';
    default:
      return 'สาธารณะ';
  }
}

IconData getStatusIcon(model.PostStatus status) {
  switch (status) {
    case model.PostStatus.public:
      return Icons.public;
    case model.PostStatus.friends:
      return Icons.people;
    default:
      return Icons.public;
  }
}

Color getStatusColor(model.PostStatus status) {
  switch (status) {
    case model.PostStatus.public:
      return Colors.green;
    case model.PostStatus.friends:
      return Colors.blue;
    default:
      return Colors.green;
  }
}

// ฟังก์ชันสำหรับสีเข้ม
Color getStatusDarkColor(model.PostStatus status) {
  switch (status) {
    case model.PostStatus.public:
      return Colors.green.shade700;
    case model.PostStatus.friends:
      return Colors.blue.shade700;
    default:
      return Colors.green.shade700;
  }
}

class RecommendedTab extends StatefulWidget {
  final PageController pageController;
  const RecommendedTab({super.key, required this.pageController});

  @override
  State<RecommendedTab> createState() => RecommendedTabState();
}

class RecommendedTabState extends State<RecommendedTab>
    with AutomaticKeepAliveClientMixin {
  // เพิ่ม AutomaticKeepAliveClientMixin เพื่อรักษา state
  @override
  bool get wantKeepAlive => true;

  List<GetAllCategory> category = [];
  List<model.GetAllPost> allPosts = [];
  List<model.GetAllPost> filteredPosts = [];

  int selectedIndex = -1;
  int? selectedCid;
  GetStorage gs = GetStorage();

  Map<int, bool> showHeartMap = {};
  Map<int, int> likeCountMap = {};
  Map<int, bool> likedMap = {};
  Map<int, bool> savedMap = {};
  Map<int, int> saveCountMap = {};
  Map<int, int> currentPageMap = {};
  Map<int, PageController> pageControllers = {};

  bool isInitialLoading = true;
  bool isRefreshing = false;
  List<Map<String, dynamic>> commentsList = [];
  late int loggedInUid;
  Set<int> followingUserIds = {};
  dynamic user;

  Map<int, bool> commentLikedMap = {};
  Map<int, int> commentLikeCountMap = {};
  bool isTogglingCommentLike = false;

  // ปรับปรุงการจัดการ firstLoad
  bool _isFirstLoadAfterPost = false;
  bool _hasInitialized = false;

  Map<int, String?> followingStatusMap =
      {}; // เก็บ status: 'accepted', 'pending', 'rejected', null
  @override
  void initState() {
    super.initState();
    loadInitialData();
    user = gs.read('user');
    dev.log(user.toString());
    loadSavedPosts();

    dynamic rawUid = gs.read('user');
    if (rawUid is int) {
      loggedInUid = rawUid;
    } else if (rawUid is String) {
      loggedInUid = int.tryParse(rawUid) ?? 0;
    } else {
      loggedInUid = 0;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // เพิ่ม method สำหรับรีเซ็ต state เมื่อเปลี่ยนหน้า
  void resetToNormalFeed() {
    if (_isFirstLoadAfterPost) {
      _isFirstLoadAfterPost = false;
      // รีโหลดเป็น normal feed แบบ random
      loadAllPosts(firstLoad: false, randomize: false); //
    }
  }

  // ฟังก์ชันแปลงเวลาเป็นรูปแบบ Instagram
  String _formatTimeAgo(DateTime postDate) {
    final now = DateTime.now();
    final difference = now.difference(postDate);

    if (difference.inSeconds < 60) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks สัปดาห์ที่แล้ว';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months เดือนที่แล้ว';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ปีที่แล้ว';
    }
  }

  // ปรับปรุง loadInitialData
  Future<void> loadInitialData() async {
    if (_hasInitialized) return;

    setState(() {
      isInitialLoading = true;
    });

    await loadCategories();
    await loadAllPosts(
        firstLoad: false, randomize: false); // เริ่มต้นด้วย normal feed

    setState(() {
      isInitialLoading = false;
      _hasInitialized = true;
    });
  }

  // ปรับปรุง refreshAfterPosting
  Future<void> refreshAfterPosting() async {
    setState(() {
      _isFirstLoadAfterPost = true; // ตั้งค่าให้แสดงโพสต์ใหม่
    });

    await loadAllPosts(firstLoad: true);

    // ตั้ง timer เพื่อรีเซ็ตกลับเป็น normal feed หลัง 30 วินาที
    Timer(const Duration(seconds: 30), () {
      if (mounted && _isFirstLoadAfterPost) {
        resetToNormalFeed();
      }
    });
  }

  // ปรับปรุง refreshData
  Future<void> refreshData() async {
    if (isRefreshing) return;

    setState(() {
      isRefreshing = true;
      _isFirstLoadAfterPost = false; // รีเซ็ตเป็น normal feed
    });

    try {
      await loadCategories();
      await loadAllPosts(
          firstLoad: false, randomize: true); // ✅ เพิ่ม randomize: true

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('อัพเดทข้อมูลสำเร็จ'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('เกิดข้อผิดพลาดในการอัพเดทข้อมูล'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isRefreshing = false;
        });
      }
    }
  }

  // เพิ่มฟังก์ชันสำหรับตรวจสอบว่าผู้ใช้ไลค์คอมเมนต์หรือไม่
  Future<void> checkCommentLikes(List<int> commentIds) async {
    if (loggedInUid == 0 || commentIds.isEmpty) return;

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      // สร้าง list ของ Future สำหรับแต่ละ comment
      List<Future> futures = commentIds.map((commentId) async {
        // ตรวจสอบว่าไลค์หรือไม่
        final likeUri = Uri.parse(
            '$url/image_post/is-comment-liked?user_id=$loggedInUid&comment_id=$commentId');
        final likeRes = await http.get(likeUri);
        if (likeRes.statusCode == 200) {
          final data = json.decode(likeRes.body);
          setState(() {
            commentLikedMap[commentId] = data['liked'] ?? false;
          });
        }

        // ดึงจำนวนไลค์
        final countUri =
            Uri.parse('$url/image_post/comment-like-count/$commentId');
        final countRes = await http.get(countUri);
        if (countRes.statusCode == 200) {
          final countData = json.decode(countRes.body);
          setState(() {
            commentLikeCountMap[commentId] = countData['like_count'] ?? 0;
          });
        }
      }).toList();

      // รันทุก request พร้อมกัน
      await Future.wait(futures);
    } catch (e) {
      debugPrint('Error checking comment likes: $e');
    }
  }

// ฟังก์ชันสำหรับกดไลค์/ยกเลิกไลค์คอมเมนต์
  Future<void> toggleCommentLike(int commentId) async {
    if (isTogglingCommentLike || loggedInUid == 0) return;

    setState(() {
      isTogglingCommentLike = true;
    });

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final isLiked = commentLikedMap[commentId] ?? false;
      final endpoint =
          isLiked ? '/image_post/unlike-comment' : '/image_post/like-comment';
      final uri = Uri.parse('$url$endpoint');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "user_id": loggedInUid,
          "comment_id": commentId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          commentLikedMap[commentId] = data['liked'] ?? false;
          commentLikeCountMap[commentId] = data['like_count'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error toggling comment like: $e');
    } finally {
      setState(() {
        isTogglingCommentLike = false;
      });
    }
  }

  Future<void> loadCategories() async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];
      final categoryResponse = await http.get(Uri.parse("$url/category/get"));
      if (categoryResponse.statusCode == 200) {
        category = getAllCategoryFromJson(categoryResponse.body);
      } else {
        throw Exception('โหลดหมวดหมู่ไม่สำเร็จ');
      }
    } catch (e) {
      dev.log('Error loading categories: $e');
    }
  }

  // อัพเดท loadFollowingStatus เดิมให้เรียกใช้ฟังก์ชันใหม่
  Future<void> loadFollowingStatus() async {
    await _loadFollowingStatusForPosts(allPosts);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadAllPosts(
      {bool firstLoad = false, bool randomize = false}) async {
    try {
      final config = await Configuration.getConfig();
      final url = config['apiEndpoint'];
      final uid = gs.read('user');

      final shouldShowOwnPosts = firstLoad || _isFirstLoadAfterPost;

      // ✅ โหลด API พร้อมกัน
      final responses = await Future.wait([
        http.get(Uri.parse(
            "$url/image_post/get?uid=$uid&firstLoad=$shouldShowOwnPosts&randomize=$randomize")),
        http.get(Uri.parse("$url/image_post/liked-posts/$uid")),
      ]);

      final postResponse = responses[0];
      final likedResponse = responses[1];

      if (postResponse.statusCode == 200 && likedResponse.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(postResponse.body);
        final allPostsFromApi =
            jsonData.map((item) => model.GetAllPost.fromJson(item)).toList();

        final likedIds = jsonDecode(likedResponse.body)['likedPostIds'];
        final likedSet = Set<int>.from(likedIds);

        // ✅ โหลดสถานะ follow พร้อมกัน (หรือปรับให้ backend รวมข้อมูลมา)
        await _loadFollowingStatusForPosts(allPostsFromApi);

        allPosts = allPostsFromApi;
        filteredPosts = _filterPostsByPrivacy(allPosts);

        showHeartMap.clear();
        likeCountMap.clear();
        likedMap.clear();

        allPosts.forEach((postItem) {
          final postId = postItem.post.postId;
          likeCountMap[postId] = postItem.post.amountOfLike;
          likedMap[postId] = likedSet.contains(postId);
        });

        for (int i = 0; i < filteredPosts.length; i++) {
          showHeartMap[i] = false;
        }

        if (mounted) setState(() {});
      } else {
        throw Exception('โหลดโพสต์หรือโพสต์ที่ไลก์ไม่สำเร็จ');
      }
    } catch (e) {
      dev.log('Error loading posts: $e');
      allPosts = [];
      filteredPosts = [];
      likedMap.clear();
      likeCountMap.clear();
      showHeartMap.clear();
      followingUserIds.clear();
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadFollowingStatusForPosts(
      List<model.GetAllPost> posts) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      // เคลียร์ข้อมูลเก่า
      followingStatusMap.clear();

      // ตรวจสอบสถานะการติดตามสำหรับทุกคนในโพสต์
      Set<int> uniqueUserIds = posts.map((post) => post.user.uid).toSet();

      for (int targetUserId in uniqueUserIds) {
        if (targetUserId != loggedInUid) {
          final response = await http.get(
            Uri.parse(
                '$url/user/is-following?follower_id=$loggedInUid&following_id=$targetUserId'),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final isFollowing = data['isFollowing'] ?? false;
            final status = data['status']; // 'accepted', 'pending', หรือ null

            if (isFollowing) {
              followingStatusMap[targetUserId] = status;
            } else {
              followingStatusMap[targetUserId] = null;
            }
          }
        }
      }
    } catch (e) {
      dev.log('Error loading following status: $e');
    }
  }

// ฟังก์ชันใหม่สำหรับกรองโพสต์ตามสถานะความเป็นส่วนตัว
  List<model.GetAllPost> _filterPostsByPrivacy(List<model.GetAllPost> posts) {
    return posts.where((post) {
      // ถ้าเป็นโพสต์ของตัวเอง ให้แสดงเสมอ
      if (post.user.uid == loggedInUid) {
        return true;
      }

      // ถ้าเป็นโพสต์สาธารณะ ให้แสดงเสมอ
      if (post.post.postStatus == model.PostStatus.public) {
        return true;
      }

      // ถ้าเป็นโพสต์เฉพาะเพื่อน ให้แสดงเฉพาะคนที่ติดตามแล้ว (status = 'accepted')
      if (post.post.postStatus == model.PostStatus.friends) {
        final status = followingStatusMap[post.user.uid];
        return status == 'accepted';
      }

      return false;
    }).toList();
  }

// แก้ไขฟังก์ชัน filterPostsByCategory ให้รวมการกรองสถานะด้วย
  void filterPostsByCategory(int? cid) {
    setState(() {
      selectedCid = cid;
      selectedIndex = cid == null
          ? -1
          : category.indexWhere((element) => element.cid == cid);

      List<model.GetAllPost> postsToFilter;

      if (cid == null) {
        // ถ้าไม่เลือกหมวดหมู่ ใช้โพสต์ทั้งหมด
        postsToFilter = allPosts;
      } else {
        // ถ้าเลือกหมวดหมู่ กรองตามหมวดหมู่
        postsToFilter = allPosts.where((post) {
          return post.categories.any((cat) => cat.cid == cid);
        }).toList();
      }

      // กรองตามสถานะความเป็นส่วนตัวอีกครั้ง (เผื่อสถานะการติดตามเปลี่ยน)
      filteredPosts = _filterPostsByPrivacy(postsToFilter);

      showHeartMap.clear();
      for (int i = 0; i < filteredPosts.length; i++) {
        showHeartMap[i] = false;
      }
    });
  }

  Future<void> cancelFollowRequest(int targetUserId) async {
    // ใช้ unfollowUser เดิม แต่เปลี่ยน message
    await unfollowUser(targetUserId);
  }

  void likePost(int postId) async {
    final uid = gs.read('user'); // อ่าน user id จาก GetStorage
    final isLiked = likedMap[postId] ?? false;

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      // ✅ สลับ endpoint ตามสถานะ like/unlike
      final endpoint = isLiked ? '/image_post/unlike' : '/image_post/like';
      final uri = Uri.parse('$url$endpoint');

      final likeModel = LikePost(userId: uid, postId: postId);
      final bodyJson = likePostToJson(likeModel);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: bodyJson,
      );

      if (response.statusCode == 200) {
        setState(() {
          likedMap[postId] = !isLiked;

          if (!isLiked) {
            // กดไลก์
            likeCountMap[postId] = (likeCountMap[postId] ?? 0) + 1;
          } else {
            // กดยกเลิกไลก์
            likeCountMap[postId] = (likeCountMap[postId] ?? 1) - 1;
            if (likeCountMap[postId]! < 0) {
              likeCountMap[postId] = 0; // ป้องกันติดลบ
            }
          }
        });
      } else {
        dev.log("Like/Unlike API failed: ${response.body}");
      }
    } catch (e) {
      dev.log("Error like/unlike post: $e");
    }
  }

  void savePost(int postId) async {
    final uid = gs.read('user'); // อ่าน user id จาก GetStorage
    final isSaved = savedMap[postId] ?? false; // เช็คว่าบันทึกไปแล้วหรือยัง

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      // ✅ สลับ endpoint ตามสถานะ save/unsave
      final endpoint = isSaved ? '/image_post/unsave' : '/image_post/save';
      final uri = Uri.parse('$url$endpoint');

      final saveModel = LikePost(userId: uid, postId: postId);
      // ใช้โมเดลเดียวกับ like ได้เลย ถ้า fields ชื่อเหมือนกัน
      final bodyJson = likePostToJson(saveModel);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: bodyJson,
      );

      if (response.statusCode == 200) {
        setState(() {
          savedMap[postId] = !isSaved;

          if (!isSaved) {
            // บันทึกโพสต์
            saveCountMap[postId] = (saveCountMap[postId] ?? 0) + 1;
          } else {
            // ยกเลิกบันทึกโพสต์
            saveCountMap[postId] = (saveCountMap[postId] ?? 1) - 1;
            if (saveCountMap[postId]! < 0) {
              saveCountMap[postId] = 0; // ป้องกันค่าติดลบ
            }
          }
        });
      } else {
        dev.log("Save/Unsave API failed: ${response.body}");
      }
    } catch (e) {
      dev.log("Error save/unsave post: $e");
    }
  }

  Future<void> loadSavedPosts() async {
    final uid = gs.read('user'); // user id จาก GetStorage
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];
    final uri = Uri.parse('$url/image_post/saved-posts/$uid');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List savedPostIds = data['savedPostIds'];

        setState(() {
          // รีเซ็ต savedMap และใส่สถานะ true ให้โพสต์ที่โหลดมา
          savedMap = {};
          for (var postId in savedPostIds) {
            savedMap[postId] = true;
          }
        });
      } else {
        dev.log("Failed to load saved posts: ${response.body}");
      }
    } catch (e) {
      dev.log("Error loading saved posts: $e");
    }
  }

  // แก้ไขฟังก์ชัน followUser
  Future<void> followUser(int targetUserId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final response = await http.post(
        Uri.parse('$url/user/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'follower_id': loggedInUid,
          'following_id': targetUserId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'] ?? 'pending'; // รับ status จาก backend

        dev.log(
            'ติดตามผู้ใช้ $targetUserId สำเร็จ: ${data['message']} (status: $status)');

        setState(() {
          followingStatusMap[targetUserId] = status;
        });

        // แสดง snackbar แตกต่างกันตามสถานะ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    status == 'accepted'
                        ? Icons.check_circle
                        : Icons.access_time,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status == 'accepted'
                          ? 'ติดตามสำเร็จ'
                          : 'ส่งคำขอติดตามแล้ว รอการยืนยัน',
                    ),
                  ),
                ],
              ),
              backgroundColor:
                  status == 'accepted' ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        dev.log(
            'เกิดข้อผิดพลาดในการติดตาม: ${errorData['error'] ?? errorData['message']}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['error'] ?? 'เกิดข้อผิดพลาดในการติดตาม'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      dev.log('Error following user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // แก้ไขฟังก์ชัน unfollowUser
  Future<void> unfollowUser(int targetUserId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final uri = Uri.parse('$url/user/unfollow');
      final request = http.Request('DELETE', uri);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'follower_id': loggedInUid,
        'following_id': targetUserId,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        dev.log('เลิกติดตามผู้ใช้ $targetUserId สำเร็จ: ${data['message']}');

        setState(() {
          followingStatusMap[targetUserId] = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('เลิกติดตามสำเร็จ'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        dev.log(
            'เกิดข้อผิดพลาดในการเลิกติดตาม: ${errorData['error'] ?? errorData['message']}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['error'] ??
                  errorData['message'] ??
                  'เกิดข้อผิดพลาดในการเลิกติดตาม'),
              backgroundColor:
                  response.statusCode == 404 ? Colors.orange : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      dev.log('Error unfollowing user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(int commentId, int postId) async {
    final gs = GetStorage();
    final userId = gs.read('user');
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final response = await http.post(
        Uri.parse('$url/image_post/delete-comment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'comment_id': commentId,
          'user_id': userId,
          'post_id': postId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final deletedBy = data['deletedBy'] ?? 'ผู้ใช้';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('ลบความคิดเห็นสำเร็จ (โดย: $deletedBy)'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('ไม่พบความคิดเห็น')),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (response.statusCode == 403) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.block, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('คุณไม่มีสิทธิ์ลบความคิดเห็นนี้')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Failed to delete comment');
      }
    } catch (e) {
      dev.log('Error deleting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('เกิดข้อผิดพลาดในการลบความคิดเห็น')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // เพิ่มฟังก์ชัน buildFollowButton สำหรับจัดการปุ่มติดตาม
  Widget buildFollowButton(model.GetAllPost postItem) {
    final status = followingStatusMap[postItem.user.uid];
    final isSelf = postItem.user.uid == loggedInUid;

    if (isSelf) {
      return const SizedBox.shrink();
    }

    // กำหนด UI ตามสถานะ
    IconData icon;
    String text;
    Color backgroundColor;
    Color textColor;
    Color borderColor;
    VoidCallback onTap;

    if (status == 'accepted') {
      // ✅ กำลังติดตามอยู่ (accepted)
      icon = Icons.check_rounded;
      text = '';
      backgroundColor = Colors.grey[50]!;
      textColor = Colors.green[600]!;
      borderColor = Colors.grey[300]!;
      onTap = () => unfollowUser(postItem.user.uid);
    } else if (status == 'pending') {
      // ⏳ รอการยืนยัน (pending)
      icon = Icons.access_time_rounded;
      text = 'รอยืนยัน';
      backgroundColor = Colors.orange[50]!;
      textColor = Colors.orange[700]!;
      borderColor = Colors.orange[200]!;
      onTap = () => cancelFollowRequest(postItem.user.uid);
    } else if (status == 'rejected') {
      // ❌ ถูกปฏิเสธ (rejected) - แสดงเป็นปุ่มติดตามใหม่ได้
      icon = Icons.person_add_rounded;
      text = 'ติดตามอีกครั้ง';
      backgroundColor = Colors.red[50]!;
      textColor = Colors.red[700]!;
      borderColor = Colors.red[200]!;
      onTap = () => followUser(postItem.user.uid);
    } else {
      // 👤 ยังไม่ได้ติดตาม (null)
      icon = Icons.person_add_rounded;
      text = 'ติดตาม';
      backgroundColor = Colors.black87;
      textColor = Colors.white;
      borderColor = Colors.black87;
      onTap = () => followUser(postItem.user.uid);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(
              horizontal: text.isEmpty ? 9 : 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey(status),
                    size: 15,
                    color: textColor,
                  ),
                ),
                if (text.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // สำหรับ AutomaticKeepAliveClientMixin
    if (isInitialLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: const Center(
          child: CircularProgressIndicator(
            color: Colors.black,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: refreshData,
        color: Colors.black,
        backgroundColor: Colors.white,
        displacement: 40,
        child: Column(
          children: [
            if (_isFirstLoadAfterPost)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.blue.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.new_releases, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'แสดงโพสต์ใหม่ของคุณ',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: resetToNormalFeed,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ปิด',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Enhanced Category Filter Section
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    const SizedBox(width: 24),
                    // "ทั้งหมด" button with modern gradient
                    GestureDetector(
                      onTap: () => filterPostsByCategory(null),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: selectedCid == null
                              ? LinearGradient(
                                  colors: [
                                    const Color(0xFF2C2C2C),
                                    const Color(0xFF1A1A1A),
                                    const Color(0xFF000000),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  stops: const [0.0, 0.5, 1.0],
                                )
                              : null,
                          color: selectedCid == null ? null : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: selectedCid == null
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.05),
                                    blurRadius: 1,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selectedCid == null)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.apps_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            Text(
                              'ทั้งหมด',
                              style: TextStyle(
                                color: selectedCid == null
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                                fontWeight: selectedCid == null
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Category buttons with modern styling
                    ...category.map((cate) {
                      final cid = cate.cid;
                      final isSelected = selectedCid == cid;
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: () => filterPostsByCategory(cid),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xFF2C2C2C),
                                        const Color(0xFF1A1A1A),
                                        const Color(0xFF000000),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      stops: const [0.0, 0.5, 1.0],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.05),
                                        blurRadius: 1,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                Text(
                                  cate.cname,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF6B7280),
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
            ),

            Expanded(
              child: filteredPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.photo_outlined,
                              size: 36,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ไม่มีโพสต์ในหมวดหมู่นี้',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ลองเลือกหมวดหมู่อื่น หรือลากลงเพื่อรีเฟรช',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final postItem = filteredPosts[index];
                        final pageController = PageController();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 1),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Instagram-style Header
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    // Profile image
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black,
                                            Colors.black12,
                                            Colors.black54,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: CircleAvatar(
                                          backgroundImage: NetworkImage(
                                              postItem.user.profileImage),
                                          radius: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Username, status, and time
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              if (postItem.user.uid ==
                                                  loggedInUid) {
                                                // UID ตรงกับผู้ล็อกอิน → ไปหน้า Profile ของตัวเอง
                                                Get.to(
                                                    () => const Profilepage());
                                              } else {
                                                // UID ไม่ตรง → ไปหน้า OtherUserProfilePage
                                                Get.to(() =>
                                                    OtherUserProfilePage(
                                                        userId:
                                                            postItem.user.uid));
                                              }
                                            },
                                            child: Text(
                                              postItem.user.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              // Status Badge ใต้ username
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: getStatusColor(postItem
                                                          .post.postStatus)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: getStatusColor(
                                                        postItem
                                                            .post.postStatus),
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      getStatusIcon(postItem
                                                          .post.postStatus),
                                                      size: 8,
                                                      color: getStatusDarkColor(
                                                          postItem
                                                              .post.postStatus),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      getStatusText(postItem
                                                          .post.postStatus),
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color:
                                                            getStatusDarkColor(
                                                                postItem.post
                                                                    .postStatus),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatTimeAgo(
                                                    postItem.post.postDate),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Follow button and menu
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        buildFollowButton(postItem),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          onPressed: () {
                                            // Step 1: กดที่เมนู -> โชว์เมนูเลือก "รายงานโพสต์"
                                            showModalBottomSheet(
                                              context: context,
                                              builder: (context) {
                                                return ListTile(
                                                  leading: Icon(Icons.report,
                                                      color: Colors.red),
                                                  title:
                                                      const Text("รายงานโพสต์"),
                                                  onTap: () {
                                                    Navigator.pop(
                                                        context); // ปิดเมนูแรก
                                                    // Step 2: แสดงเหตุผลการรายงาน
                                                    showModalBottomSheet(
                                                      context: context,
                                                      builder: (context) {
                                                        final reasons = [
                                                          "สแปม",
                                                          "เนื้อหาไม่เหมาะสม",
                                                          "ละเมิดลิขสิทธิ์",
                                                          "อื่น ๆ",
                                                        ];

                                                        return ListView.builder(
                                                          shrinkWrap: true,
                                                          itemCount:
                                                              reasons.length,
                                                          itemBuilder:
                                                              (context, index) {
                                                            return ListTile(
                                                              title: Text(
                                                                  reasons[
                                                                      index]),
                                                              onTap: () {
                                                                Navigator.pop(
                                                                    context);
                                                                _reportPost(
                                                                  context,
                                                                  postItem.post
                                                                      .postId,
                                                                  reasons[
                                                                      index],
                                                                  gs.read(
                                                                      'user'), // uid ของคนที่กดรายงาน (ปัจจุบัน login อยู่)
                                                                );
                                                              },
                                                            );
                                                          },
                                                        );
                                                      },
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.more_vert,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 24,
                                            minHeight: 24,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),

                              // Image Section with Status Badge overlay (ตัวเลือกที่ 1)
                              if (postItem.images.isNotEmpty)
                                SizedBox(
                                  height: 400,
                                  width: double.infinity,
                                  child: Stack(
                                    children: [
                                      PageView(
                                        controller: pageController,
                                        onPageChanged: (page) {
                                          setState(() {
                                            currentPageMap[index] = page;
                                          });
                                        },
                                        children: postItem.images.map((img) {
                                          return GestureDetector(
                                            onDoubleTap: () async {
                                              likePost(postItem.post.postId);
                                              setState(() =>
                                                  showHeartMap[index] = true);
                                              await Future.delayed(
                                                  const Duration(seconds: 1));
                                              setState(() =>
                                                  showHeartMap[index] = false);
                                            },
                                            child: Image.network(
                                              img.image,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Container(
                                                  color: Colors.grey[100],
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.black,
                                                      strokeWidth: 2,
                                                      value: loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[100],
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                            Icons.error_outline,
                                                            color: Colors
                                                                .grey[400],
                                                            size: 32),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          'ไม่สามารถโหลดรูปภาพได้',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                              fontSize: 14),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        }).toList(),
                                      ),

                                      // แถบเลื่อนด้านล่าง
                                      Positioned(
                                        bottom: 8,
                                        left: 0,
                                        right: 0,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(
                                              postItem.images.length,
                                              (dotIndex) {
                                            return Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4),
                                              width: currentPageMap[index] ==
                                                      dotIndex
                                                  ? 10
                                                  : 6,
                                              height: currentPageMap[index] ==
                                                      dotIndex
                                                  ? 10
                                                  : 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: currentPageMap[index] ==
                                                        dotIndex
                                                    ? Colors.white
                                                    : Colors.white
                                                        .withOpacity(0.4),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),

                                      // Heart animation
                                      Center(
                                        child: AnimatedScale(
                                          scale: showHeartMap[index] == true
                                              ? 1.2
                                              : 0.0,
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.elasticOut,
                                          child: AnimatedOpacity(
                                            opacity: showHeartMap[index] == true
                                                ? 1.0
                                                : 0.0,
                                            duration: const Duration(
                                                milliseconds: 200),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Color.fromARGB(
                                                        255, 247, 32, 32)
                                                    .withOpacity(0.8),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color.fromARGB(
                                                            255, 247, 32, 32)
                                                        .withOpacity(0.3),
                                                    blurRadius: 20,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.favorite,
                                                color: Colors.white,
                                                size: 36,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Page indicator (Instagram style - top right)
                                      if (postItem.images.length > 1)
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.6),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '1/${postItem.images.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                              // Action buttons (Instagram style)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    // Like button
                                    GestureDetector(
                                      onTap: () =>
                                          likePost(postItem.post.postId),
                                      child: Icon(
                                        likedMap[postItem.post.postId] == true
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: likedMap[postItem.post.postId] ==
                                                true
                                            ? const Color.fromARGB(
                                                255, 247, 32, 32)
                                            : Colors.black,
                                        size: 24,
                                      ),
                                    ),

                                    // Likes count
                                    if ((likeCountMap[postItem.post.postId] ??
                                            0) >
                                        0)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          '${likeCountMap[postItem.post.postId]}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),

                                    const SizedBox(width: 16),

                                    // Comment button
                                    GestureDetector(
                                      onTap: () {
                                        _showCommentBottomSheet(
                                            context, postItem.post.postId);
                                      },
                                      child: const Icon(
                                        Icons.chat,
                                        color: Colors.black,
                                        size: 24,
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    const Spacer(),

                                    // Save button
                                    GestureDetector(
                                      onTap: () {
                                        savePost(postItem.post.postId);
                                      },
                                      child: Icon(
                                        savedMap[postItem.post.postId] == true
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color: savedMap[postItem.post.postId] ==
                                                true
                                            ? Color.fromARGB(255, 255, 200, 0)
                                            : Colors.black,
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: FutureBuilder<GetComment>(
                                  future: _fetchComments(postItem.post.postId),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data!.comments.isNotEmpty) {
                                      final commentCount =
                                          snapshot.data!.comments.length;

                                      return GestureDetector(
                                        onTap: () => _showCommentBottomSheet(
                                            context, postItem.post.postId),
                                        child: Text(
                                          commentCount == 1
                                              ? 'ดูความคิดเห็น 1 รายการ'
                                              : 'ดูความคิดเห็นทั้งหมด $commentCount รายการ',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),

                              // Categories (ไม่มี Status Badge)
                              if (postItem.categories.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: postItem.categories.map((cat) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              255, 214, 214, 214),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color:
                                                  Color.fromARGB(255, 0, 0, 0)),
                                        ),
                                        child: Text(
                                          cat.cname,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),

                              // Caption
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (postItem.post.postTopic != null)
                                      Text(
                                        postItem.post.postTopic!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                          height: 1.3,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    if (postItem.post.postDescription != null &&
                                        postItem.post.postDescription!
                                            .trim()
                                            .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          postItem.post.postDescription!,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Hashtags
                              if (postItem.hashtags.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  child: Wrap(
                                    spacing: 4,
                                    children: postItem.hashtags.map((tag) {
                                      return Text(
                                        '#${tag.tagName}',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentBottomSheet(BuildContext context, int postId) {
    TextEditingController _commentController = TextEditingController();
    FocusNode _focusNode = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AnimatedPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle Bar
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: Color.fromARGB(255, 0, 0, 0),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'ความคิดเห็น',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Comments List
                    Expanded(
                      child: FutureBuilder<GetComment>(
                        future: _fetchComments(postId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Container(
                              color: Colors.white,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color.fromARGB(255, 0, 0, 0)),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'กำลังโหลดความคิดเห็น...',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final comments = snapshot.data!.comments;

                          // 🔥 เรียกฟังก์ชันตรวจสอบไลค์หลังจากโหลดคอมเมนต์เสร็จ
                          if (comments.isNotEmpty) {
                            final commentIds =
                                comments.map((c) => c.commentId).toList();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              checkCommentLikes(commentIds);
                            });
                          }

                          if (comments.isEmpty) {
                            return Container(
                              color: Colors.white,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'ยังไม่มีความคิดเห็น',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'เป็นคนแรกที่แสดงความคิดเห็น',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Container(
                            color: Colors.white,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: comments.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final c = comments[index];
                                final isMyComment = c.uid == loggedInUid;

                                // ตรวจสอบว่าเป็นเจ้าของโพสต์หรือไม่
                                final currentPost = filteredPosts.firstWhere(
                                  (post) => post.post.postId == postId,
                                  orElse: () => filteredPosts.first,
                                );
                                final isPostOwner =
                                    currentPost.user.uid == loggedInUid;
                                final canDelete = isMyComment || isPostOwner;
                                final isLiked =
                                    commentLikedMap[c.commentId] ?? false;
                                final likeCount =
                                    commentLikeCountMap[c.commentId] ?? 0;

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Hero(
                                            tag: 'avatar_${c.name}_$index',
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.grey[300]!,
                                                  width: 1,
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                radius: 18,
                                                backgroundImage: c
                                                        .profileImage.isNotEmpty
                                                    ? NetworkImage(
                                                        c.profileImage)
                                                    : const AssetImage(
                                                            'assets/default_avatar.png')
                                                        as ImageProvider,
                                                backgroundColor:
                                                    Colors.grey[200],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      c.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    if (isPostOwner &&
                                                        !isMyComment) ...[
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.blue[50],
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                          border: Border.all(
                                                            color: Colors
                                                                .blue[200]!,
                                                            width: 0.5,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'เจ้าของโพสต์',
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            color: Colors
                                                                .blue[700],
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 12,
                                                      color: Colors.grey[500],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatTimeAgo(
                                                          c.createdAt),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[500],
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // 🎯 เพิ่มส่วน Like Button
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  toggleCommentLike(
                                                      c.commentId);
                                                  setModalState(
                                                      () {}); // รีเฟรช UI ใน modal
                                                },
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isLiked
                                                          ? Icons.favorite
                                                          : Icons
                                                              .favorite_border,
                                                      size: 18,
                                                      color: isLiked
                                                          ? Colors.red
                                                          : Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      likeCount > 0
                                                          ? '$likeCount'
                                                          : '',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (canDelete)
                                            PopupMenuButton<String>(
                                              icon: Icon(
                                                Icons.more_vert,
                                                size: 18,
                                                color: Colors.grey[600],
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              itemBuilder: (context) => [
                                                // แสดงปุ่มแก้ไขเฉพาะเจ้าของคอมเมนต์
                                                if (isMyComment)
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.edit_outlined,
                                                          color:
                                                              Colors.blue[700],
                                                          size: 18,
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          'แก้ไขความคิดเห็น',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .blue[700],
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.delete_outline,
                                                        color: Colors.red,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'ลบความคิดเห็น',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.red[700],
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              onSelected: (value) async {
                                                if (value == 'edit') {
                                                  await _editComment(
                                                      context,
                                                      c.commentId,
                                                      postId,
                                                      c.commentText);
                                                  setModalState(
                                                      () {}); // รีเฟรช modal
                                                } else if (value == 'delete') {
                                                  final confirm =
                                                      await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                      ),
                                                      title: Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .delete_forever,
                                                            color:
                                                                Colors.red[400],
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          const Text(
                                                              'ลบความคิดเห็น'),
                                                        ],
                                                      ),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                              'คุณต้องการลบความคิดเห็นนี้หรือไม่?'),
                                                          const SizedBox(
                                                              height: 8),
                                                          if (isPostOwner &&
                                                              !isMyComment)
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .orange[50],
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                border:
                                                                    Border.all(
                                                                  color: Colors
                                                                          .orange[
                                                                      200]!,
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .info_outline,
                                                                    size: 16,
                                                                    color: Colors
                                                                            .orange[
                                                                        700],
                                                                  ),
                                                                  const SizedBox(
                                                                      width: 8),
                                                                  Expanded(
                                                                    child: Text(
                                                                      'คุณกำลังลบความคิดเห็นของผู้อื่นในฐานะเจ้าของโพสต์',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .orange[700],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  false),
                                                          child: const Text(
                                                              'ยกเลิก'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  true),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                            foregroundColor:
                                                                Colors.white,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                          ),
                                                          child:
                                                              const Text('ลบ'),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (confirm == true) {
                                                    await _deleteComment(
                                                        c.commentId, postId);
                                                    setModalState(
                                                        () {}); // รีเฟรช modal
                                                  }
                                                }
                                              },
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        c.commentText,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                          height: 1.4,
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

                    // Comment Input
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey[200]!),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                  maxHeight: 120,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _commentController,
                                  focusNode: _focusNode,
                                  maxLines: null,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'แสดงความคิดเห็น...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _commentController,
                              builder: (context, value, child) {
                                final hasText = value.text.trim().isNotEmpty;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: hasText
                                          ? () async {
                                              final text = _commentController
                                                  .text
                                                  .trim();
                                              if (text.isNotEmpty) {
                                                _commentController.clear();
                                                _focusNode.unfocus();

                                                // Show loading state
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: const Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                        Color>(
                                                                    Colors
                                                                        .white),
                                                          ),
                                                        ),
                                                        SizedBox(width: 12),
                                                        Text(
                                                            'กำลังส่งความคิดเห็น...'),
                                                      ],
                                                    ),
                                                    duration: const Duration(
                                                        seconds: 1),
                                                    backgroundColor:
                                                        Colors.blue,
                                                  ),
                                                );

                                                await _submitComment(
                                                    postId, text);
                                                setModalState(
                                                    () {}); // รีโหลด FutureBuilder
                                              }
                                            }
                                          : null,
                                      borderRadius: BorderRadius.circular(24),
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: hasText
                                              ? Colors.blue
                                              : Colors.grey[300],
                                          shape: BoxShape.circle,
                                          boxShadow: hasText
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.blue
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Icon(
                                          Icons.send_rounded,
                                          color: hasText
                                              ? Colors.white
                                              : Colors.grey[500],
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<GetComment> _fetchComments(int postId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];
    final res = await http.get(Uri.parse('$url/image_post/comments/$postId'));

    if (res.statusCode == 200) {
      final commentData = getCommentFromJson(res.body);

      // ดึง commentId แล้วเรียก checkCommentLikes แต่ไม่ต้อง await
      final commentIds = commentData.comments.map((c) => c.commentId).toList();
      checkCommentLikes(commentIds); // 🔥 เรียก background

      return commentData; // คืนค่าคอมเมนต์ทันที
    } else {
      throw Exception('โหลดคอมเมนต์ไม่สำเร็จ');
    }
  }

  Future<void> _submitComment(int postId, String commentText) async {
    final gs = GetStorage();
    final userId = gs.read('user'); // ดึง user id จาก local storage
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];
    final res = await http.post(
      Uri.parse('$url/image_post/comment'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'post_id': postId,
        'user_id': userId,
        'comment_text': commentText,
      }),
    );
    if (res.statusCode != 200) {
      debugPrint('ส่งคอมเมนต์ไม่สำเร็จ: ${res.body}');
    }
  }

  Future<void> loadDataCategory() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    final response = await http.get(Uri.parse("$url/category/get"));
    if (response.statusCode == 200) {
      category = getAllCategoryFromJson(response.body);
      dev.log(response.body);
      setState(() {});
    } else {
      dev.log('Error loading user data: ${response.statusCode}');
    }
  }

  Future<void> _reportPost(
      BuildContext context, int postId, String reason, int reporterId) async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final response = await http.post(
        Uri.parse("$url/image_post/report-posts"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "post_id": postId,
          "reporter_id": reporterId,
          "reason": reason,
        }),
      );

      final resBody = jsonDecode(response.body);
      final message = resBody['message'] ?? "รายงานโพสต์สำเร็จ";
      final isAlreadyReported = message.contains("รายงานไปแล้ว");

      Get.snackbar(
        "สถานะ",
        message,
        backgroundColor: isAlreadyReported ? Colors.orange : Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        "เกิดข้อผิดพลาด",
        "$e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _editComment(BuildContext context, int commentId, int postId,
      String currentText) async {
    final TextEditingController editController =
        TextEditingController(text: currentText);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue[400]),
            const SizedBox(width: 8),
            const Text('แก้ไขความคิดเห็น'),
          ],
        ),
        content: TextField(
          controller: editController,
          maxLines: 5,
          maxLength: 1000,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'แก้ไขความคิดเห็นของคุณ...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (editController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาใส่ความคิดเห็น'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final newText = editController.text.trim();
    if (newText.isEmpty) return;

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];
      final userId = gs.read('user');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('กำลังแก้ไขความคิดเห็น...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Colors.blue,
        ),
      );

      final response = await http.put(
        Uri.parse('$url/image_post/edit-comment/$commentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'post_id': postId,
          'comment_text': newText,
        }),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final editedBy = data['editedBy'] ?? 'ผู้ใช้';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('แก้ไขความคิดเห็นสำเร็จ (โดย: $editedBy)'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorData['error'] ?? 'แก้ไขไม่สำเร็จ')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      dev.log('Error editing comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('เกิดข้อผิดพลาดในการแก้ไขความคิดเห็น')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
