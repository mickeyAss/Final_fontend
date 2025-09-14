import 'dart:io';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:get_storage/get_storage.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:fontend_pro/pages/user_all_uploadPage.dart';

class UserUploadPhotopage extends StatefulWidget {
  const UserUploadPhotopage({super.key});

  @override
  State<UserUploadPhotopage> createState() => _UserUploadPhotopageState();
}

class _UserUploadPhotopageState extends State<UserUploadPhotopage> {
  List<AssetEntity> images = [];
  Set<AssetEntity> selectedImages = {};
  bool isLoading = false;
  bool isLoadingMore = false;
  final int maxSelection = 5;
  final int pageSize = 50; // จำนวนรูปที่โหลดต่อครั้ง
  int currentPage = 0;
  bool hasMore = true;
  AssetPathEntity? currentAlbum;

  final Map<AssetEntity, Uint8List?> thumbnailCache = {};
  final GetStorage gs = GetStorage();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadImages();
    _setupScrollListener();
    var user = gs.read('user');
    log('user id: ${user.toString()}');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!isLoadingMore && hasMore) {
          _loadMoreImages();
        }
      }
    });
  }

  Future<void> _loadImages() async {
    setState(() {
      isLoading = true;
      currentPage = 0;
      hasMore = true;
      images.clear();
      thumbnailCache.clear();
    });

    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    if (!ps.hasAccess) {
      await PhotoManager.openSetting();
      setState(() {
        isLoading = false;
      });
      return;
    }

    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    if (albums.isNotEmpty) {
      currentAlbum = albums[0];
      await _loadPageImages();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadPageImages() async {
    if (currentAlbum == null) return;

    try {
      List<AssetEntity> newMedia = await currentAlbum!.getAssetListPaged(
        page: currentPage,
        size: pageSize,
      );

      if (newMedia.isEmpty) {
        setState(() {
          hasMore = false;
        });
        return;
      }

      for (final asset in newMedia) {
        try {
          final thumbData = await asset.thumbnailDataWithSize(
            const ThumbnailSize(200, 200),
          );
          thumbnailCache[asset] = thumbData;
        } catch (e) {
          log('Error loading thumbnail for ${asset.id}: $e');
          thumbnailCache[asset] = null;
        }
      }

      setState(() {
        images.addAll(newMedia);
        currentPage++;
        if (newMedia.length < pageSize) {
          hasMore = false;
        }
      });
    } catch (e) {
      log('Error loading page images: $e');
      setState(() {
        hasMore = false;
      });
    }
  }

  Future<void> _loadMoreImages() async {
    if (isLoadingMore || !hasMore) return;

    setState(() {
      isLoadingMore = true;
    });

    await _loadPageImages();

    setState(() {
      isLoadingMore = false;
    });
  }

  Future<void> _refreshImages() async {
    await _loadImages();
  }

  void _onImageTap(AssetEntity image) {
    setState(() {
      if (selectedImages.contains(image)) {
        selectedImages.remove(image);
      } else {
        if (selectedImages.length < maxSelection) {
          selectedImages.add(image);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เลือกได้สูงสุด $maxSelection รูปเท่านั้น'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    });
  }

  /// ฟังก์ชันแปลงไฟล์ AssetEntity เป็น JPEG
  Future<File?> convertAssetEntityToJpeg(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) return null;

    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final jpegData = img.encodeJpg(image, quality: 90);
      final newPath = file.path.replaceAll(RegExp(r'\.\w+$'), '.jpg');
      final newFile = File(newPath);
      await newFile.writeAsBytes(jpegData);
      return newFile;
    } catch (e) {
      log('Error converting to JPEG: $e');
      return null;
    }
  }

  /// แปลงภาพที่เลือกทั้งหมดก่อนส่ง
  Future<List<File>> _convertSelectedImages() async {
    List<File> jpegFiles = [];
    for (var asset in selectedImages) {
      final jpegFile = await convertAssetEntityToJpeg(asset);
      if (jpegFile != null) {
        jpegFiles.add(jpegFile);
      }
    }
    return jpegFiles;
  }

  Future<void> _onNextPressed() async {
    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('โปรดเลือกภาพก่อนกดถัดไป'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // แปลงภาพเป็น JPEG
    final jpegFiles = await _convertSelectedImages();
    log('แปลงภาพเสร็จแล้ว: ${jpegFiles.length} ไฟล์');

    // เก็บ id ของรูปที่เลือกใน GetStorage (เหมือนเดิม)
    final List<String> selectedIds =
        selectedImages.map((e) => e.id).toList(growable: false);
    await gs.write('selected_image_ids', selectedIds);

    // ไปหน้า UserAllUploadPage
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserAllUploadPage()),
    );
  }

  Widget _buildGridItem(AssetEntity image) {
    final bool isSelected = selectedImages.contains(image);
    final Uint8List? thumbData = thumbnailCache[image];

    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: isSelected ? 10 : 3,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isSelected
            ? BorderSide(color: Colors.blueGrey.shade300, width: 3)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _onImageTap(image),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbData != null)
              Image.memory(
                thumbData,
                fit: BoxFit.cover,
              )
            else
              Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(
                    Icons.image,
                    color: Colors.grey,
                    size: 40,
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: isSelected
                  ? Colors.blueGrey.withOpacity(0.4)
                  : Colors.transparent,
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade700.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.shade900.withOpacity(0.7),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(5),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white70,
                    size: 28,
                  ),
                ),
              ),
            if (isSelected)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade700.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '${selectedImages.toList().indexOf(image) + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.blueGrey,
          strokeWidth: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 6,
        centerTitle: true,
        title: Text(
          'เลือกภาพ (${selectedImages.length}/$maxSelection)',
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _refreshImages,
            tooltip: 'รีเฟรชรูปภาพ',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueGrey),
            )
          : images.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ไม่พบรูปภาพในเครื่อง',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _refreshImages,
                        child: const Text(
                          'รีเฟรช',
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshImages,
                  color: Colors.blueGrey,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildGridItem(images[index]),
                            childCount: images.length,
                          ),
                        ),
                        if (isLoadingMore)
                          SliverToBoxAdapter(
                            child: _buildLoadingIndicator(),
                          ),
                        if (!hasMore && images.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'แสดงรูปภาพทั้งหมดแล้ว (${images.length} รูป)',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: selectedImages.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _onNextPressed,
              icon: const Icon(Icons.arrow_forward),
              label: Text('ถัดไป (${selectedImages.length})'),
              backgroundColor: Colors.blueGrey.shade700,
              foregroundColor: Colors.white70,
              elevation: 8,
            )
          : null,
      bottomNavigationBar: selectedImages.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'เลือกแล้ว ${selectedImages.length} รูป',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (selectedImages.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedImages.clear();
                          });
                        },
                        child: const Text(
                          'ล้างทั้งหมด',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
