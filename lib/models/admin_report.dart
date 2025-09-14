import 'dart:convert';

// Combined response model that includes both post and user reports
class AdminReportsResponse {
  List<PostReport> postReports;
  List<UserReport> userReports;

  AdminReportsResponse({
    required this.postReports,
    required this.userReports,
  });

  factory AdminReportsResponse.fromJson(Map<String, dynamic> json) {
    return AdminReportsResponse(
      postReports: json["postReports"] != null 
          ? List<PostReport>.from(json["postReports"].map((x) => PostReport.fromJson(x)))
          : [],
      userReports: json["userReports"] != null
          ? List<UserReport>.from(json["userReports"].map((x) => UserReport.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    "postReports": List<dynamic>.from(postReports.map((x) => x.toJson())),
    "userReports": List<dynamic>.from(userReports.map((x) => x.toJson())),
  };
}

// Post Report Model (based on your AdminReport)
class PostReport {
  int postId;
  String? topic;
  String? description;
  DateTime date;
  String status;
  Owner owner;
  int reportCount;
  List<String> images;
  List<Report> reports;

  PostReport({
    required this.postId,
    required this.topic,
    required this.description,
    required this.date,
    required this.status,
    required this.owner,
    required this.reportCount,
    required this.images,
    required this.reports,
  });

  factory PostReport.fromJson(Map<String, dynamic> json) => PostReport(
    postId: json["postId"],
    topic: json["topic"],
    description: json["description"],
    date: DateTime.parse(json["date"]),
    status: json["status"],
    owner: Owner.fromJson(json["owner"]),
    reportCount: json["reportCount"],
    images: List<String>.from(json["images"].map((x) => x)),
    reports: List<Report>.from(json["reports"].map((x) => Report.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "postId": postId,
    "topic": topic,
    "description": description,
    "date": date.toIso8601String(),
    "status": status,
    "owner": owner.toJson(),
    "reportCount": reportCount,
    "images": List<dynamic>.from(images.map((x) => x)),
    "reports": List<dynamic>.from(reports.map((x) => x.toJson())),
  };
}

// User Report Model (based on your AdminReportUser)
class UserReport {
  int reportId;
  int reportedId;
  String? reportedName;
  int reporterId;
  String? reporterName;
  String? reason;
  DateTime? createdAt;

  UserReport({
    required this.reportId,
    required this.reportedId,
    required this.reportedName,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    required this.createdAt,
  });

  factory UserReport.fromJson(Map<String, dynamic> json) => UserReport(
    reportId: json["reportId"],
    reportedId: json["reportedId"],
    reportedName: json["reportedName"],
    reporterId: json["reporterId"],
    reporterName: json["reporterName"],
    reason: json["reason"],
    createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "reportId": reportId,
    "reportedId": reportedId,
    "reportedName": reportedName,
    "reporterId": reporterId,
    "reporterName": reporterName,
    "reason": reason,
    "createdAt": createdAt?.toIso8601String(),
  };
}

// Owner model for posts
class Owner {
  String name;
  String profileImage;

  Owner({
    required this.name,
    required this.profileImage,
  });

  factory Owner.fromJson(Map<String, dynamic> json) => Owner(
    name: json["name"] ?? "",
    profileImage: json["profileImage"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "profileImage": profileImage,
  };
}

// Individual report within a post report
class Report {
  int reportId;
  int reporterId;
  String? reporterName;
  String? reason;
  DateTime? createdAt;

  Report({
    required this.reportId,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) => Report(
    reportId: json["report_id"] ?? json["reportId"] ?? 0,
    reporterId: json["reporter_id"] ?? json["reporterId"] ?? 0,
    reporterName: json["reporter_name"] ?? json["reporterName"],
    reason: json["reason"],
    createdAt: json["created_at"] != null 
        ? DateTime.parse(json["created_at"])
        : json["createdAt"] != null
            ? DateTime.parse(json["createdAt"])
            : null,
  );

  Map<String, dynamic> toJson() => {
    "report_id": reportId,
    "reporter_id": reporterId,
    "reporter_name": reporterName,
    "reason": reason,
    "created_at": createdAt?.toIso8601String(),
  };
}

// Helper functions for parsing different response formats
List<PostReport> postReportsFromJson(String str) => 
    List<PostReport>.from(json.decode(str).map((x) => PostReport.fromJson(x)));

String postReportsToJson(List<PostReport> data) => 
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

List<UserReport> userReportsFromJson(String str) => 
    List<UserReport>.from(json.decode(str).map((x) => UserReport.fromJson(x)));

String userReportsToJson(List<UserReport> data) => 
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

// For backward compatibility with your existing AdminReport
typedef AdminReport = PostReport;
typedef AdminReportUser = UserReport;