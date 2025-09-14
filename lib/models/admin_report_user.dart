import 'dart:convert';
// To parse this JSON data, do
//
//     final adminReportUser = adminReportUserFromJson(jsonString);


List<AdminReportUser> adminReportUserFromJson(String str) => List<AdminReportUser>.from(json.decode(str).map((x) => AdminReportUser.fromJson(x)));

String adminReportUserToJson(List<AdminReportUser> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class AdminReportUser {
    int reportId;
    int reportedId;
    String reportedName;
    int reporterId;
    String reporterName;
    String reason;
    DateTime createdAt;

    AdminReportUser({
        required this.reportId,
        required this.reportedId,
        required this.reportedName,
        required this.reporterId,
        required this.reporterName,
        required this.reason,
        required this.createdAt,
    });

    factory AdminReportUser.fromJson(Map<String, dynamic> json) => AdminReportUser(
        reportId: json["reportId"],
        reportedId: json["reportedId"],
        reportedName: json["reportedName"],
        reporterId: json["reporterId"],
        reporterName: json["reporterName"],
        reason: json["reason"],
        createdAt: DateTime.parse(json["createdAt"]),
    );

    Map<String, dynamic> toJson() => {
        "reportId": reportId,
        "reportedId": reportedId,
        "reportedName": reportedName,
        "reporterId": reporterId,
        "reporterName": reporterName,
        "reason": reason,
        "createdAt": createdAt.toIso8601String(),
    };
}
