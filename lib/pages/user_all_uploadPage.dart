import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/pages/mainpage.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:fontend_pro/models/insert_post.dart';
import 'package:fontend_pro/models/get_hashtags.dart';
import 'package:fontend_pro/models/insert_hashtag.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fontend_pro/models/get_all_category.dart';

// อย่าลืมนำเข้าหน้า Mainpage ด้วย

class UserAllUploadPage extends StatefulWidget {
  const UserAllUploadPage({super.key});

  @override
  State<UserAllUploadPage> createState() => _UserAllUploadPageState();
}

class _UserAllUploadPageState extends State<UserAllUploadPage> {
  final GetStorage gs = GetStorage();
  List<AssetEntity> selectedAssets = [];
  bool isLoading = true;

  List<GetAllCategory> selectedCategories = [];
  late Future<List<GetAllCategory>> futureCategories;

  String _postPrivacy = 'Public'; // ค่าเริ่มต้น

  List<Datum> hashtagSuggestions = []; // ✅ ใช้ Datum ไม่ใช่ GetHashtags
  bool isShowingHashtagSuggestions = false;
  String currentHashtagQuery = '';
  int hashtagStartPosition = 0;
  OverlayEntry? hashtagOverlay;
  final LayerLink _layerLink = LayerLink();

  List<Datum> selectedHashtags = [];

  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final Map<String, Map<String, dynamic>> privacyOptions = {
    'Public': {
      'label': 'โพสต์แบบสาธารณะ',
      'icon': Icons.public,
    },
    'Friends': {
      'label': 'โพสต์เฉพาะเพื่อน',
      'icon': Icons.group,
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSelectedAssets();
    futureCategories = loadCategories();
    fetchHashtags(); // เดิม
    _setupDescriptionListener(); // เพิ่มใหม่
  }

  Future<void> _loadSelectedAssets() async {
    setState(() {
      isLoading = true;

      var user = gs.read('user');
      log('user id: ${user.toString()}');

      var image = gs.read('selected_image_ids');
      log('image: ${image.toString()}');
    });

    final List<dynamic>? storedIds =
        gs.read<List<dynamic>>('selected_image_ids');
    if (storedIds == null || storedIds.isEmpty) {
      setState(() {
        isLoading = false;
        selectedAssets = [];
      });
      return;
    }

    List<AssetEntity> assets = [];
    for (final id in storedIds) {
      final asset = await AssetEntity.fromId(id); // ✅ ใช้เมธอดนี้
      if (asset != null) {
        assets.add(asset);
      }
    }

    setState(() {
      selectedAssets = assets;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _removeHashtagOverlay();
    _descriptionController.dispose();
    _topicController.dispose();
    super.dispose();
  }

// ฟังก์ชันใหม่สำหรับจัดการ hashtag search
  void _setupDescriptionListener() {
    _descriptionController.addListener(() {
      _handleHashtagSearch();
    });
  }

  void _handleHashtagSearch() {
    final text = _descriptionController.text;
    final cursorPosition = _descriptionController.selection.baseOffset;

    if (cursorPosition <= 0) {
      _hideHashtagSuggestions();
      return;
    }

    int hashtagStart = -1;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] == '#') {
        hashtagStart = i;
        break;
      } else if (text[i] == ' ' || text[i] == '\n') {
        break;
      }
    }

    if (hashtagStart == -1) {
      _hideHashtagSuggestions();
      return;
    }

    String hashtagQuery = text.substring(hashtagStart + 1, cursorPosition);

    if (hashtagQuery.contains(' ') || hashtagQuery.contains('\n')) {
      _hideHashtagSuggestions();
      return;
    }

    hashtagStartPosition = hashtagStart;
    currentHashtagQuery = hashtagQuery;

    _searchHashtags(hashtagQuery); // ✅ แสดงผลแบบ real-time
  }

  Future<void> _searchHashtags(String query) async {
    try {
      final config = await Configuration.getConfig();
      final url = config['apiEndpoint'];

      final response =
          await http.get(Uri.parse('$url/hashtags/search?q=$query'));

      if (response.statusCode == 200) {
        final getHashtags = getHashtagsFromJson(response.body);
        final results = getHashtags.data;

        if (results.isNotEmpty) {
          setState(() {
            hashtagSuggestions = results;
          });
          _showHashtagSuggestions();
        } else {
          _hideHashtagSuggestions(); // ✅ ไม่มีผลลัพธ์ → ปิดรายการ
        }
      } else {
        _hideHashtagSuggestions(); // ✅ error → ปิดรายการ
      }
    } catch (e) {
      log('Error searching hashtags: $e');
      _hideHashtagSuggestions();
    }
  }

  void _showHashtagSuggestions() {
  if (hashtagSuggestions.isEmpty) return;

  _removeHashtagOverlay();

  hashtagOverlay = OverlayEntry(
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);
      final keyboardHeight = mediaQuery.viewInsets.bottom;

      return Positioned(
        left: 12,
        right: 12,
        bottom: keyboardHeight + 70,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 5),
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(16),
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade100,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.tag,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'แท็กยอดนิยม',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // List
                    Flexible(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: hashtagSuggestions.length,
                        itemBuilder: (context, index) {
                          final hashtag = hashtagSuggestions[index];
                          return _buildHashtagItem(hashtag, index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Overlay.of(context).insert(hashtagOverlay!);
  setState(() {
    isShowingHashtagSuggestions = true;
  });
}

Widget _buildHashtagItem(dynamic hashtag, int index) {
  // สร้างสีพื้นหลังที่หลากหลาย
  final colors = [
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFF45B7D1),
    const Color(0xFF96CEB4),
    const Color(0xFFFECA57),
    const Color(0xFF6C5CE7),
    const Color(0xFFFF9FF3),
    const Color(0xFFFF6B35),
  ];
  
  final color = colors[index % colors.length];

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
    ),
    child: InkWell(
      onTap: () => _selectHashtag(hashtag.tagName),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            // Avatar แท็ก
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.8),
                    color.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tag_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            // ข้อมูลแท็ก
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${hashtag.tagName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'แท็กยอดนิยม • แตะเพื่อเพิ่ม',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // ไอคอนเพิ่ม
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add_rounded,
                color: color,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ปรับปรุงฟังก์ชันเลือกแท็ก
void _selectHashtag(String hashtagName) {
  final selectedTag = hashtagSuggestions.firstWhere(
    (tag) => tag.tagName == hashtagName,
    orElse: () => Datum(tagId: -1, tagName: hashtagName),
  );

  // ป้องกันซ้ำ
  if (!selectedHashtags.any((tag) => tag.tagName == selectedTag.tagName)) {
    selectedHashtags.add(selectedTag);
  }

  final text = _descriptionController.text;
  final beforeHashtag = text.substring(0, hashtagStartPosition);
  final afterCursor =
      text.substring(_descriptionController.selection.baseOffset);

  final newText = '$beforeHashtag#$hashtagName $afterCursor';
  final newCursorPosition = beforeHashtag.length + hashtagName.length + 2;

  _descriptionController.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: newCursorPosition),
  );

  // เพิ่ม animation เมื่อเลือกแท็ก
  _hideHashtagSuggestions();
  
  // แสดง feedback
  HapticFeedback.lightImpact();
}

// ปรับปรุงฟังก์ชันซ่อนแท็ก
void _hideHashtagSuggestions() {
  _removeHashtagOverlay();
  setState(() {
    isShowingHashtagSuggestions = false;
    hashtagSuggestions.clear();
    currentHashtagQuery = '';
  });
}

// เพิ่ม animation สำหรับการปิด overlay
void _removeHashtagOverlay() {
  hashtagOverlay?.remove();
  hashtagOverlay = null;
}

  void _showCategoryBottomSheet(BuildContext context) {
    List<GetAllCategory> tempSelected = List.from(selectedCategories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: FutureBuilder<List<GetAllCategory>>(
            future: futureCategories,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text("เกิดข้อผิดพลาด"));
              }

              final categories = snapshot.data!;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'สไตล์เสื้อผ้าของคุณเป็นอย่างไร?',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: categories.map((cate) {
                          final isSelected = tempSelected
                              .any((selected) => selected.cid == cate.cid);
                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(cate.cname),
                            activeColor: Colors.black, // สีพื้นกล่องเมื่อเลือก
                            checkColor: Colors.white, // สีเครื่องหมายติ๊กถูก
                            onChanged: (bool? value) {
                              if (value == true) {
                                tempSelected.add(cate);
                              } else {
                                tempSelected.removeWhere(
                                    (item) => item.cid == cate.cid);
                              }
                              (context as Element).markNeedsBuild();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () {
                      setState(() {
                        selectedCategories = tempSelected;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('ตกลง'),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.keyboard_arrow_left,
            color: Colors.black87,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'สร้างโพสต์ใหม่',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: TextButton(
            onPressed: submitPost,
            style: TextButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              'โพสต์',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : selectedAssets.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ไม่มีรูปภาพที่เลือก',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Gallery Section
                    Container(
                      height: 280,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: selectedAssets.length,
                        itemBuilder: (context, index) {
                          final asset = selectedAssets[index];
                          return FutureBuilder<Uint8List?>(
                            future: asset.thumbnailDataWithSize(
                              const ThumbnailSize(400, 400),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                return GestureDetector(
                                  onTap: () => _showImagePreview(context, snapshot.data!),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    width: 220,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.cover,
                                          ),
                                          // Gradient overlay
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.1),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Image counter
                                          if (selectedAssets.length > 1)
                                            Positioned(
                                              top: 12,
                                              right: 12,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.7),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${index + 1}/${selectedAssets.length}',
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
                                  ),
                                );
                              }
                              return Container(
                                width: 220,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    
                    // Content Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Topic Section
                          _buildSectionHeader('หัวเรื่อง', Icons.title_rounded),
                          const SizedBox(height: 12),
                          _buildTopicField(),
                          const SizedBox(height: 24),
                          
                          // Description Section
                          _buildSectionHeader('คำบรรยาย', Icons.edit_note_rounded),
                          const SizedBox(height: 12),
                          _buildDescriptionField(),
                          const SizedBox(height: 24),
                          
                          // Category Section
                          _buildCategorySection(),
                          const SizedBox(height: 24),
                          
                          // Privacy Section
                          _buildPrivacySection(),
                          const SizedBox(height: 100), // Space for bottom padding
                        ],
                      ),
                    ),
                  ],
                ),
              ),
  );
}

Widget _buildSectionHeader(String title, IconData icon) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
      ),
      const SizedBox(width: 12),
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: -0.3,
        ),
      ),
    ],
  );
}

Widget _buildTopicField() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: TextField(
      controller: _topicController,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      decoration: InputDecoration(
        hintText: 'เขียนหัวเรื่องที่น่าสนใจ...',
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w400,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
      ),
    ),
  );
}

Widget _buildDescriptionField() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _descriptionController,
        maxLines: 5,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'แบ่งปันเรื่องราวของคุณ...\nใช้ # เพื่อเพิ่มแฮชแท็ก',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    ),
  );
}

Widget _buildCategorySection() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.category_rounded,
          color: Colors.orange.shade600,
          size: 20,
        ),
      ),
      title: Text(
        'เลือกหมวดหมู่',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      subtitle: Text(
        selectedCategories.isEmpty
            ? 'ยังไม่ได้เลือกหมวดหมู่'
            : '${selectedCategories.length} หมวดหมู่ที่เลือก',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.keyboard_arrow_right,
          color: Colors.grey.shade600,
          size: 18,
        ),
      ),
      onTap: () => _showCategoryBottomSheet(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

Widget _buildPrivacySection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.privacy_tip_rounded,
              color: Colors.blue.shade600,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'ความเป็นส่วนตัว',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _postPrivacy,
            isExpanded: true,
            icon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
              ),
            ),
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            items: privacyOptions.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          entry.value['icon'],
                          color: Colors.grey.shade700,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(entry.value['label']),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null && value != _postPrivacy) {
                setState(() {
                  _postPrivacy = value;
                });
              }
            },
          ),
        ),
      ),
    ],
  );
}

void _showImagePreview(BuildContext context, Uint8List imageData) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                InteractiveViewer(
                  child: Image.memory(
                    imageData,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Future<String?> uploadToFirebase(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return null;

    final fileName = "${DateTime.now().millisecondsSinceEpoch}_${asset.id}.jpg";
    final ref = FirebaseStorage.instance.ref().child("final_image/$fileName");

    try {
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      log('Firebase upload error: $e');
      return null;
    }
  }

  Future<void> submitPost() async {
  final topic = _topicController.text.trim();
  final rawDescription = _descriptionController.text.trim();
  final userString = gs.read('user');

  if (selectedAssets.isEmpty ||
      userString == null ||
      userString.toString().isEmpty) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 40),
            const SizedBox(height: 10),
            const Text('กรุณาเลือกรูปภาพอย่างน้อย 1 รูป',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      ),
    );
    return;
  }

  showLoadingDialog(context);

  try {
    final config = await Configuration.getConfig();
    final url = config['apiEndpoint'];
    final userId = int.tryParse(userString.toString()) ?? 0;

    // อัปโหลดรูป
    List<String> imageUrls = [];
    for (final asset in selectedAssets) {
      final imageUrl = await uploadToFirebase(asset);
      if (imageUrl != null) imageUrls.add(imageUrl);
    }

    if (imageUrls.isEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปโหลดรูปภาพไม่สำเร็จ')),
      );
      return;
    }

    // ✅ ดึงแฮชแท็กจาก description ทั้งหมด (ปรับปรุง regex)
    final RegExp hashtagRegex = RegExp(r'#([a-zA-Z0-9ก-๙_]+)');
    final matches = hashtagRegex.allMatches(rawDescription);
    final Set<String> allHashtagsInText = matches
        .map((m) => m.group(1)?.trim() ?? '')
        .where((tag) => tag.isNotEmpty)
        .toSet();

    // ✅ รวมแฮชแท็กจาก description และ selectedHashtags
    final Set<String> combinedHashtags = {
      ...selectedHashtags.map((e) => e.tagName.trim()),
      ...allHashtagsInText,
    };

    log('Combined hashtags: $combinedHashtags');

    // ✅ ตรวจสอบและ insert แฮชแท็ก (ปรับปรุง logic)
    List<int> hashtagIds = [];

    for (final tagName in combinedHashtags) {
      final cleanTag = tagName.trim();
      
      if (cleanTag.isEmpty) continue;

      try {
        // ค้นหา hashtag ในระบบก่อน
        final searchRes = await http.get(
          Uri.parse('$url/hashtags/search?q=${Uri.encodeComponent(cleanTag)}'),
        );

        if (searchRes.statusCode == 200) {
          final result = jsonDecode(searchRes.body);
          
          // ตรวจสอบว่าเจอ hashtag ที่ตรงกันหรือไม่
          bool foundExact = false;
          if (result['data'] != null && result['data'].isNotEmpty) {
            for (final item in result['data']) {
              if (item['tag_name']?.toString().toLowerCase() == cleanTag.toLowerCase()) {
                hashtagIds.add(item['tag_id']);
                foundExact = true;
                log('Found existing hashtag: $cleanTag with ID: ${item['tag_id']}');
                break;
              }
            }
          }

          // ถ้าไม่เจอ hashtag ที่ตรงกัน ให้ insert ใหม่
          if (!foundExact) {
            log('Hashtag not found, inserting new: $cleanTag');
            
            final insertBody = InsertHashtag(tagName: cleanTag);
            final insertRes = await http.post(
              Uri.parse('$url/hashtags/insert'),
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: insertHashtagToJson(insertBody),
            );

            log('Insert response status: ${insertRes.statusCode}');
            log('Insert response body: ${insertRes.body}');

            if (insertRes.statusCode == 200 || insertRes.statusCode == 201) {
              final insertData = jsonDecode(insertRes.body);
              
              // ตรวจสอบ response structure
              if (insertData['data'] != null) {
                int? newTagId;
                
                if (insertData['data'] is List && insertData['data'].isNotEmpty) {
                  newTagId = insertData['data'][0]['tag_id'];
                } else if (insertData['data'] is Map) {
                  newTagId = insertData['data']['tag_id'];
                }
                
                if (newTagId != null) {
                  hashtagIds.add(newTagId);
                  log('Successfully inserted hashtag: $cleanTag with ID: $newTagId');
                } else {
                  log('Insert successful but no tag_id returned for: $cleanTag');
                }
              } else {
                log('Insert response has no data field for: $cleanTag');
              }
            } else {
              log('Insert hashtag failed for "$cleanTag": ${insertRes.statusCode} - ${insertRes.body}');
            }
          }
        } else {
          log('Search hashtag failed for "$cleanTag": ${searchRes.statusCode} - ${searchRes.body}');
        }
      } catch (e) {
        log('Error processing hashtag "$cleanTag": $e');
      }
    }

    log('Final hashtag IDs: $hashtagIds');

    // แยกคำบรรยายจริงออกจาก hashtag
    final filteredDescription = rawDescription
        .replaceAll(hashtagRegex, '') // ลบ hashtag ออก
        .replaceAll(RegExp(r'\s+'), ' ') // ลบช่องว่างเกิน
        .trim();

    final categoryIds = selectedCategories.map((e) => e.cid).toList();

    final postModel = Insertpost(
      postTopic: topic,
      postDescription: filteredDescription,
      postFkUid: userId,
      images: imageUrls,
      categoryIdFk: categoryIds,
      hashtags: hashtagIds,
    );

    final jsonBody = insertpostToJson(postModel);
    log('Post data: $jsonBody');

    // ส่งโพสต์
    final postResponse = await http.post(
      Uri.parse("$url/image_post/post/add"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: jsonBody,
    );

    Navigator.pop(context);
    
    if (postResponse.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('โพสต์เรียบร้อย'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Mainpage()),
      );
    } else {
      log('Post failed: ${postResponse.statusCode} - ${postResponse.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการโพสต์: ${postResponse.statusCode}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e, stackTrace) {
    Navigator.pop(context);
    log('Exception in submitPost: $e', stackTrace: stackTrace);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้ปิดเอง
      barrierColor: Colors.black.withOpacity(0.3), // พื้นหลังโปร่งใส
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        );
      },
    );
  }

  Future<List<GetAllCategory>> loadCategories() async {
    final config = await Configuration.getConfig();
    final url = config['apiEndpoint'];
    log("กำลังโหลดข้อมูล category จาก: $url/category/get");

    final response = await http.get(Uri.parse("$url/category/get"));

    if (response.statusCode == 200) {
      final allCategories = getAllCategoryFromJson(response.body);

      // กรองเฉพาะรายการที่ ctype == Ctype.M (enum)
      final filtered =
          allCategories.where((item) => item.ctype == Ctype.M).toList();

      log("โหลดข้อมูล category สำเร็จ (${filtered.length} รายการที่ ctype = M)");
      return filtered;
    } else {
      log("โหลดข้อมูล category ไม่สำเร็จ: ${response.statusCode}");
      throw Exception('โหลดข้อมูล category ไม่สำเร็จ');
    }
  }
}

Future<void> fetchHashtags({String query = ''}) async {
  try {
    final config = await Configuration.getConfig();
    final url = config['apiEndpoint'];

    final response = await http.get(Uri.parse('$url/hashtags/search?q=$query'));

    if (response.statusCode == 200) {
      final getHashtags = getHashtagsFromJson(response.body);

      log('fetchHashtags isNew: ${getHashtags.isNew}');
      log('fetchHashtags data count: ${getHashtags.data.length}');

      for (var hashtag in getHashtags.data) {
        log('Hashtag id: ${hashtag.tagId}, name: ${hashtag.tagName}');
      }
    } else {
      log('Failed to fetch hashtags: Status code ${response.statusCode}');
    }
  } catch (e) {
    log('Error fetching hashtags: $e');
  }
}

class FullscreenImagePage extends StatelessWidget {
  final Uint8List imageData;

  const FullscreenImagePage({super.key, required this.imageData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          // เพื่อซูมภาพได้
          child: Image.memory(imageData),
        ),
      ),
    );
  }
}
