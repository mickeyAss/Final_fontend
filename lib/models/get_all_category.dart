import 'dart:convert';
// To parse this JSON data, do
//
//     final getAllCategory = getAllCategoryFromJson(jsonString);


List<GetAllCategory> getAllCategoryFromJson(String str) => List<GetAllCategory>.from(json.decode(str).map((x) => GetAllCategory.fromJson(x)));

String getAllCategoryToJson(List<GetAllCategory> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetAllCategory {
    int cid;
    String cname;
    String cimage;
    String ctype;

    GetAllCategory({
        required this.cid,
        required this.cname,
        required this.cimage,
        required this.ctype,
    });

    factory GetAllCategory.fromJson(Map<String, dynamic> json) => GetAllCategory(
        cid: json["cid"],
        cname: json["cname"],
        cimage: json["cimage"],
        ctype: json["ctype"],
    );

    Map<String, dynamic> toJson() => {
        "cid": cid,
        "cname": cname,
        "cimage": cimage,
        "ctype": ctype,
    };
}
