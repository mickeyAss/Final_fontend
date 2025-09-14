import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fontend_pro/models/admin_report.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  AdminReportsResponse? reportsData;
  bool isLoading = true;
  String selectedFilter = "all"; // all, high, medium, low

  late TabController _tabController;
  GetStorage gs = GetStorage();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAllReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchAllReports() async {
    setState(() => isLoading = true);
    
    try {
      // เรียก API ทั้งสองเส้นแยกกัน
      final results = await Future.wait([
        fetchPostReports(),
        fetchUserReports(),
      ]);
      
      final postReports = results[0] as List<PostReport>;
      final userReports = results[1] as List<UserReport>;
      
      setState(() {
        reportsData = AdminReportsResponse(
          postReports: postReports,
          userReports: userReports,
        );
        isLoading = false;
      });
      
      debugPrint("✅ All reports loaded: ${postReports.length} post reports and ${userReports.length} user reports");
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("เกิดข้อผิดพลาด: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      debugPrint("❌ Error fetching all reports: $e");
    }
  }

  Future<List<PostReport>> fetchPostReports() async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];
      final response = await http.get(
        Uri.parse("$url/image_post/admin/post-reports"),
      );

      if (response.statusCode == 200) {
        debugPrint("🔍 Post Reports Response: ${response.body}");
        
        final List<dynamic> jsonData = json.decode(response.body);
        final List<PostReport> postReports = jsonData
            .map<PostReport>((item) => PostReport.fromJson(item))
            .toList();
            
        debugPrint("✅ ${postReports.length} post reports loaded");
        return postReports;
      } else {
        debugPrint("❌ Post Reports HTTP Error: ${response.statusCode}");
        throw Exception("โหลดรายงานโพสต์ไม่สำเร็จ (${response.statusCode})");
      }
    } catch (e) {
      debugPrint("❌ Post Reports Error: $e");
      throw Exception("เกิดข้อผิดพลาดในการโหลดรายงานโพสต์: $e");
    }
  }

  Future<List<UserReport>> fetchUserReports() async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];
      final response = await http.get(
        Uri.parse("$url/image_post/admin/user-reports"),
      );

      if (response.statusCode == 200) {
        debugPrint("🔍 User Reports Response: ${response.body}");
        
        final List<dynamic> jsonData = json.decode(response.body);
        final List<UserReport> userReports = jsonData
            .map<UserReport>((item) => UserReport.fromJson(item))
            .toList();
            
        debugPrint("✅ ${userReports.length} user reports loaded");
        return userReports;
      } else {
        debugPrint("❌ User Reports HTTP Error: ${response.statusCode}");
        throw Exception("โหลดรายงานผู้ใช้ไม่สำเร็จ (${response.statusCode})");
      }
    } catch (e) {
      debugPrint("❌ User Reports Error: $e");
      throw Exception("เกิดข้อผิดพลาดในการโหลดรายงานผู้ใช้: $e");
    }
  }

  // Wrapper method for backward compatibility
  Future<void> fetchReports() async {
    await fetchAllReports();
  }

  Future<void> deletePost(int postId) async {
    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http
          .delete(Uri.parse("$url/image_post/delete-post/$postId"));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ลบโพสต์สำเร็จ"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        fetchAllReports(); // รีเฟรชข้อมูลหลังลบโพสต์
      } else {
        debugPrint("❌ Delete HTTP Error: ${response.statusCode}");
        debugPrint("❌ Delete Response: ${response.body}");
        throw Exception("ลบโพสต์ไม่สำเร็จ (${response.statusCode})");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("เกิดข้อผิดพลาดในการลบ: $e"),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint("❌ Delete Error: $e");
    }
  }

  String formatTime(DateTime? dateTime) {
    if (dateTime == null) return "ไม่ระบุ";
    try {
      return timeago.format(dateTime.toLocal(), locale: 'en_short');
    } catch (e) {
      return dateTime.toString();
    }
  }

  Color getPriorityColor(int reportCount) {
    if (reportCount >= 5) return Colors.red;
    if (reportCount >= 3) return Colors.orange;
    return Colors.yellow[800]!;
  }

  String getPriorityLabel(int reportCount) {
    if (reportCount >= 5) return "สูง";
    if (reportCount >= 3) return "กลาง";
    return "ต่ำ";
  }

  IconData getPriorityIcon(int reportCount) {
    if (reportCount >= 5) return Icons.priority_high;
    if (reportCount >= 3) return Icons.warning;
    return Icons.info;
  }

  List<PostReport> getFilteredPostReports() {
    if (reportsData == null) return [];
    final reports = reportsData!.postReports;
    if (selectedFilter == "all") return reports;

    return reports.where((report) {
      final count = report.reportCount;
      switch (selectedFilter) {
        case "high":
          return count >= 5;
        case "medium":
          return count >= 3 && count < 5;
        case "low":
          return count < 3;
        default:
          return true;
      }
    }).toList();
  }

  Widget buildStatusChip(String status) {
    Color chipColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'active':
        chipColor = Colors.green;
        statusText = "ใช้งานได้";
        break;
      case 'inactive':
        chipColor = Colors.grey;
        statusText = "ไม่ใช้งาน";
        break;
      case 'suspended':
        chipColor = Colors.red;
        statusText = "ถูกระงับ";
        break;
      case 'public':
        chipColor = Colors.blue;
        statusText = "สาธารณะ";
        break;
      case 'private':
        chipColor = Colors.purple;
        statusText = "ส่วนตัว";
        break;
      case 'friends':
        chipColor = Colors.teal;
        statusText = "เฉพาะเพื่อน";
        break;
      default:
        chipColor = Colors.blue;
        statusText = status;
    }

    return Chip(
      label: Text(
        statusText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final postReports = getFilteredPostReports();
    final userReports = reportsData?.userReports ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAllReports,
            tooltip: "รีเฟรช",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: "ออกจากระบบ",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.report_problem),
              text: "รายงานโพสต์ (${reportsData?.postReports.length ?? 0})",
            ),
            Tab(
              icon: const Icon(Icons.person_off),
              text: "รายงานผู้ใช้ (${userReports.length})",
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Statistics Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[700]!, Colors.red[600]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard("โพสต์ทั้งหมด", (reportsData?.postReports.length ?? 0).toString(),
                        Icons.list_alt, Colors.white),
                    _buildStatCard(
                        "ผู้ใช้ทั้งหมด",
                        userReports.length.toString(),
                        Icons.people_alt,
                        Colors.white),
                    _buildStatCard(
                        "ระดับสูง",
                        (reportsData?.postReports
                            .where((r) => r.reportCount >= 5)
                            .length ?? 0)
                            .toString(),
                        Icons.priority_high,
                        Colors.white),
                  ],
                ),
              ],
            ),
          ),

          // Content with TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Post Reports Tab
                Column(
                  children: [
                    // Filter Bar for Post Reports
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip("ทั้งหมด", "all"),
                            const SizedBox(width: 8),
                            _buildFilterChip("ระดับสูง", "high"),
                            const SizedBox(width: 8),
                            _buildFilterChip("ระดับกลาง", "medium"),
                            const SizedBox(width: 8),
                            _buildFilterChip("ระดับต่ำ", "low"),
                          ],
                        ),
                      ),
                    ),
                    
                    // Post Reports List
                    Expanded(
                      child: _buildPostReportsContent(postReports),
                    ),
                  ],
                ),
                
                // User Reports Tab
                _buildUserReportsContent(userReports),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostReportsContent(List<PostReport> postReports) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.red)
      );
    }

    if (postReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              selectedFilter == "all" ? "ยังไม่มีรายงานโพสต์" : "ไม่มีรายงานโพสต์ในกลุ่มนี้",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: fetchAllReports,
              child: const Text("ลองใหม่"),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchAllReports,
      color: Colors.red,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: postReports.length,
        itemBuilder: (context, index) {
          final reportData = postReports[index];
          return _buildPostReportCard(reportData);
        },
      ),
    );
  }

  Widget _buildUserReportsContent(List<UserReport> userReports) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.red)
      );
    }

    if (userReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "ยังไม่มีรายงานผู้ใช้",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: fetchAllReports,
              child: const Text("ลองใหม่"),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchAllReports,
      color: Colors.red,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: userReports.length,
        itemBuilder: (context, index) {
          final userReport = userReports[index];
          return _buildUserReportCard(userReport);
        },
      ),
    );
  }

  Widget _buildUserReportCard(UserReport userReport) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.person_off, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  "รายงานผู้ใช้",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "ID: ${userReport.reportId}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Reported User Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ผู้ถูกรายงาน:",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        userReport.reportedName ?? "ไม่ระบุ",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        "ID: ${userReport.reportedId}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Reporter Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.report_problem, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ผู้รายงาน:",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          userReport.reporterName ?? "ไม่ระบุ",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          "ID: ${userReport.reporterId}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Reason
            if (userReport.reason?.isNotEmpty == true) ...[
              const Text(
                "เหตุผลในการรายงาน:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  userReport.reason!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Time
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "รายงานเมื่อ: ${formatTime(userReport.createdAt)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement view user profile
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("ฟีเจอร์ดูโปรไฟล์ผู้ใช้กำลังพัฒนา"),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text("ดูโปรไฟล์"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _showBanUserDialog(userReport);
                  },
                  icon: const Icon(Icons.block, size: 16),
                  label: const Text("แบนผู้ใช้"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBanUserDialog(UserReport userReport) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ ยืนยันแบนผู้ใช้"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("คุณต้องการแบนผู้ใช้นี้หรือไม่?"),
            const SizedBox(height: 8),
            Text(
              "ผู้ถูกรายงาน: ${userReport.reportedName ?? 'ไม่ระบุ'}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("ID: ${userReport.reportedId}"),
            Text("เหตุผล: ${userReport.reason ?? 'ไม่ระบุ'}"),
            const SizedBox(height: 8),
            const Text(
              "หมายเหตุ: การแบนผู้ใช้จะป้องกันไม่ให้เข้าสู่ระบบได้",
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Implement ban user API call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("ฟีเจอร์แบนผู้ใช้กำลังพัฒนา"),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("แบนผู้ใช้"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.9)),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.red[100],
      checkmarkColor: Colors.red[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.red[700] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildPostReportCard(PostReport reportData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          // Header with Priority
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: getPriorityColor(reportData.reportCount).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  getPriorityIcon(reportData.reportCount),
                  color: getPriorityColor(reportData.reportCount),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "ความสำคัญ: ${getPriorityLabel(reportData.reportCount)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: getPriorityColor(reportData.reportCount),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getPriorityColor(reportData.reportCount),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${reportData.reportCount} รายงาน",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Owner Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: reportData.owner.profileImage.isNotEmpty
                          ? NetworkImage(reportData.owner.profileImage)
                          : null,
                      child: reportData.owner.profileImage.isEmpty
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reportData.owner.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Row(
                            children: [
                              buildStatusChip(reportData.status),
                              const SizedBox(width: 8),
                              Text(
                                "โพสต์เมื่อ: ${formatTime(reportData.date)}",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Post Content
                if (reportData.topic?.isNotEmpty == true) ...[
                  Text(
                    reportData.topic!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],

                if (reportData.description?.isNotEmpty == true) ...[
                  Text(
                    reportData.description!,
                    style: TextStyle(color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                // Post Images
                if (reportData.images.isNotEmpty) ...[
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: reportData.images.length,
                      itemBuilder: (context, imgIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              reportData.images[imgIndex],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Reports Details
                if (reportData.reports.isNotEmpty) ...[
                  const Divider(),
                  ExpansionTile(
                    title: Text(
                      "รายละเอียดรายงาน (${reportData.reports.length} รายการ)",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: reportData.reports.map<Widget>((report) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(
                            left: BorderSide(color: Colors.red, width: 3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.report_problem,
                                    size: 16, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    report.reason ?? "ไม่ระบุเหตุผล",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.person,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  "ผู้รายงาน: ",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  report.reporterName ?? "ไม่ระบุ",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  " (ID: ${report.reporterId ?? 'ไม่ระบุ'})",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  "เวลา: ${formatTime(report.createdAt)}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.grey[500], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          "ไม่มีรายละเอียดรายงาน",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("⚠️ ยืนยันลบโพสต์"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("คุณต้องการลบโพสต์นี้หรือไม่?"),
                                const SizedBox(height: 8),
                                Text(
                                  "โพสต์: ${reportData.topic ?? 'ไม่มีหัวข้อ'}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text("เจ้าของ: ${reportData.owner.name}"),
                                Text("ถูกรายงาน: ${reportData.reportCount} ครั้ง"),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text("ยกเลิก"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  deletePost(reportData.postId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("ลบโพสต์"),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_forever, size: 16),
                      label: const Text("ลบโพสต์"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'ออกจากระบบ',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ Admin?',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await logoutUser();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ออกจากระบบ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> logoutUser() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );

      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      await gs.erase();

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to login page
      Get.offAllNamed('/login');

      // Show success message
      Get.snackbar(
        'สำเร็จ',
        'ออกจากระบบแล้ว',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) Navigator.of(context).pop();

      log("เกิดข้อผิดพลาดขณะออกจากระบบ: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("เกิดข้อผิดพลาดขณะออกจากระบบ: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}