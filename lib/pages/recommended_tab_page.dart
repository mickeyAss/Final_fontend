import 'dart:convert';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/get_all_category.dart';
import 'package:fontend_pro/models/get_all_post.dart' as model;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class RecommendedTab extends StatefulWidget {
  final PageController pageController;
  const RecommendedTab({super.key, required this.pageController});

  @override
  State<RecommendedTab> createState() => _RecommendedTabState();
}

class _RecommendedTabState extends State<RecommendedTab> {
  List<GetAllCategory> category = [];
  List<model.GetAllPost> post = [];

  late Future<List<dynamic>> loadDataAll;

  int selectedIndex = -1;
  GetStorage gs = GetStorage();

  Map<int, bool> showHeartMap = {};
  Map<int, int> likeCountMap = {};
  Map<int, bool> likedMap = {};

  @override
  void initState() {
    super.initState();
    loadDataAll = loadData();
    var user = gs.read('user');
    log(user.toString());
  }

  Future<List<dynamic>> loadData() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    final categoryResponse = await http.get(Uri.parse("$url/category/get"));
    final postResponse = await http.get(Uri.parse("$url/image_post/get"));

    if (categoryResponse.statusCode == 200 && postResponse.statusCode == 200) {
      category = getAllCategoryFromJson(categoryResponse.body);

      final List<dynamic> jsonData = jsonDecode(postResponse.body);
      post = jsonData.map((item) => model.GetAllPost.fromJson(item)).toList();

      for (var p in post) {
        likeCountMap[p.post.postId] ??= p.post.amountOfLike ?? 0;
        likedMap[p.post.postId] ??= false;
      }

      return [category, post];
    } else {
      throw Exception('โหลดข้อมูลไม่สำเร็จ');
    }
  }

  Future<void> likePost(int postId) async {
    final isLikedNow = likedMap[postId] ?? false;

    setState(() {
      likedMap[postId] = !isLikedNow;
      if (isLikedNow) {
        likeCountMap[postId] = (likeCountMap[postId] ?? 1) - 1;
      } else {
        likeCountMap[postId] = (likeCountMap[postId] ?? 0) + 1;
      }
    });

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.post(
        Uri.parse("$url/image_post/like/$postId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"isLiked": isLikedNow}),
      );

      if (response.statusCode == 200) {
        log("🔁 Like toggled: ${response.body}");
      } else {
        log("❌ Failed to toggle like: ${response.statusCode}");
      }
    } catch (e) {
      log("🚨 Error toggling like: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: FutureBuilder<List<dynamic>>(
        future: loadDataAll,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.black, // เพิ่มสีดำที่นี่
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // หมวดหมู่
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
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
                            foregroundColor:
                                isSelected ? Colors.black : Colors.black54,
                          ),
                          child: Text(
                            cate.cname,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // รายการโพสต์
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: post.length,
                  itemBuilder: (context, index) {
                    final postItem = post[index];
                    final pageController = PageController();

                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  ClipOval(
                                    child: Image.network(
                                      postItem.user.profileImage ?? '',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Image.asset(
                                        'assets/default_profile.png',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    postItem.user.name,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 2),
                                      textStyle: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                      elevation: 10,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      minimumSize: Size(0, 40),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () {},
                                    child: Text("ติดตาม"),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert),
                                    onSelected: (value) {},
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                          value: 'report',
                                          child: Text('รายงาน')),
                                      PopupMenuItem(
                                          value: 'block', child: Text('บล็อก')),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          if (postItem.images.isNotEmpty)
                            Center(
                              child: Container(
                                height: 450,
                                width: double.infinity,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PageView(
                                      controller: pageController,
                                      children: postItem.images.map((image) {
                                        return GestureDetector(
                                          onDoubleTap: () async {
                                            likePost(postItem.post.postId);
                                            setState(() {
                                              showHeartMap[index] = true;
                                            });
                                            await Future.delayed(
                                                Duration(seconds: 1));
                                            setState(() {
                                              showHeartMap[index] = false;
                                            });
                                          },
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Image.network(
                                              image.image,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    AnimatedOpacity(
                                      opacity: showHeartMap[index] == true
                                          ? 1.0
                                          : 0.0,
                                      duration: Duration(milliseconds: 300),
                                      child: Icon(
                                        Icons.favorite,
                                        color: Colors.red.withOpacity(0.8),
                                        size: 100,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (postItem.images.length > 1)
                            Center(
                              child: SmoothPageIndicator(
                                controller: pageController,
                                count: postItem.images.length,
                                effect: ExpandingDotsEffect(
                                  dotWidth: 8,
                                  dotHeight: 8,
                                  spacing: 8,
                                  expansionFactor: 4,
                                  dotColor: Colors.black,
                                  activeDotColor: Colors.black38,
                                ),
                              ),
                            ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: BouncingScrollPhysics(),
                                  child: Row(
                                    children: postItem.categories
                                        .map((category) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6.0),
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.grey.shade100,
                                                  foregroundColor:
                                                      Colors.black87,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 6),
                                                  textStyle: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  side: BorderSide(
                                                      color:
                                                          Colors.grey.shade400,
                                                      width: 1.2),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                ),
                                                onPressed: () {},
                                                child: Text(category.cname),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      likePost(postItem.post.postId);
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          likedMap[postItem.post.postId] == true
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 22,
                                          color:
                                              likedMap[postItem.post.postId] ==
                                                      true
                                                  ? Colors.red
                                                  : Colors.black87,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          likeCountMap[postItem.post.postId]
                                                  ?.toString() ??
                                              '0',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  GestureDetector(
                                    onTap: () {},
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          'assets/images/chat.png',
                                          height: 20,
                                          width: 20,
                                          color: Colors.black87,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          (postItem.post.amountOfComment ?? 0)
                                              .toString(),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  GestureDetector(
                                    onTap: () {},
                                    child: Row(
                                      children: [
                                        Icon(Icons.bookmark_outline_rounded,
                                            size: 22, color: Colors.black87),
                                        SizedBox(width: 6),
                                        Text(
                                          (postItem.post.amountOfSave ?? 0)
                                              .toString(),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(postItem.post.postTopic,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                if (postItem.post.postDescription != null)
                                  Text(postItem.post.postDescription!),
                                Text("#ถ่ายรูปหน้ากระจก #ชุดเล่น",
                                    style: TextStyle(color: Colors.blue)),
                                SizedBox(height: 5),
                                Text(
                                  DateFormat('d MMM yyyy')
                                      .format(postItem.post.postDate),
                                  style: TextStyle(
                                      color: Colors.black38, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Divider(thickness: 1),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
