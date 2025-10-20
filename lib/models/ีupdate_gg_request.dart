class UpdateGoogleUserRequest  {
  final int? uid; // สำหรับอัปเดต user ที่ล็อกอินด้วย Google
  final double? height;
  final double? weight;
  final String? shirtSize;
  final double? chest;
  final double? waistCircumference;
  final double? hip;
  final List<int>? categoryIds;

  UpdateGoogleUserRequest ({
    this.uid,
    this.height,
    this.weight,
    this.shirtSize,
    this.chest,
    this.waistCircumference,
    this.hip,
    this.categoryIds,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (uid != null) data['uid'] = uid;
    if (height != null) data['height'] = height;
    if (weight != null) data['weight'] = weight;
    if (shirtSize != null) data['shirt_size'] = shirtSize;
    if (chest != null) data['chest'] = chest;
    if (waistCircumference != null) data['waist_circumference'] = waistCircumference;
    if (hip != null) data['hip'] = hip;
    if (categoryIds != null && categoryIds!.isNotEmpty) data['category_ids'] = categoryIds;

    return data;
  }
}
