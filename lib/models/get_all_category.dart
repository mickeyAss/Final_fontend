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
    Ctype ctype;
    String cdescription;

    GetAllCategory({
        required this.cid,
        required this.cname,
        required this.cimage,
        required this.ctype,
        required this.cdescription,
    });

    factory GetAllCategory.fromJson(Map<String, dynamic> json) => GetAllCategory(
        cid: json["cid"],
        cname: json["cname"],
        cimage: json["cimage"],
        ctype: ctypeValues.map[json["ctype"]]!,
        cdescription: json["cdescription"],
    );

    Map<String, dynamic> toJson() => {
        "cid": cid,
        "cname": cname,
        "cimage": cimage,
        "ctype": ctypeValues.reverse[ctype],
        "cdescription": cdescription,
    };
}

enum Ctype {
    F,
    M
}

final ctypeValues = EnumValues({
    "F": Ctype.F,
    "M": Ctype.M
});

class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
            reverseMap = map.map((k, v) => MapEntry(v, k));
            return reverseMap;
    }
}
