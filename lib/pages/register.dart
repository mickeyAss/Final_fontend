import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/pages/choose_categoryPage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController nameNoCt1 = TextEditingController();
  TextEditingController emailNoCt1 = TextEditingController();
  TextEditingController passwordNoCt1 = TextEditingController();
  TextEditingController conpasswordNoCt1 = TextEditingController();

  int? height;
  int? weight;
  int? chest;
  int? waist;
  int? hips;
  String? selectedSize;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_left, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('สมัครสมาชิก',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade100],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
                bottom:
                    80), // กำหนด padding เพิ่มล่าง เพื่อให้เนื้อหาไม่ซ้อนทับปุ่มยืนยัน
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: AnimatedOpacity(
                    opacity: 1.0,
                    duration: Duration(milliseconds: 600),
                    child: Column(
                      children: [
                        Icon(Icons.person_add_alt_1_rounded,
                            color: Colors.black87, size: 40),
                        SizedBox(height: 12),
                        Text('ยินดีต้อนรับเข้าสู่โลกของคุณ',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text(
                            'สมัครสมาชิกเพื่อค้นหาสไตล์ที่ใช่\nและรับประสบการณ์ที่ออกแบบมาเพื่อคุณ',
                            style:
                                TextStyle(fontSize: 13, color: Colors.black54),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text('ข้อมูลของคุณ',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 10),

                // ลบการตั้ง readOnly ออก
                _buildTextField('ชื่อผู้ใช้', nameNoCt1),
                _buildTextField('อีเมล', emailNoCt1),
                _buildTextField('รหัสผ่าน', passwordNoCt1, obscure: true),
                _buildTextField('ยืนยันรหัสผ่าน', conpasswordNoCt1, obscure: true),

                SizedBox(height: 20),
                _buildSectionHeader('สัดส่วนของคุณ',
                    'เราจะใช้ข้อมูลสัดส่วนของคุณเพื่อแนะนำเสื้อผ้าและไลฟ์สไตล์ที่เหมาะกับรูปร่างของคุณที่สุด'),
                SizedBox(height: 10),
                _buildInputWithDropdown(
                  label: 'ส่วนสูง',
                  unit: 'ซม.',
                  value: height,
                  suggestedValues: List.generate(41, (i) => 150 + i),
                  onChanged: (val) => setState(() => height = val),
                ),
                _buildInputWithDropdown(
                  label: 'น้ำหนัก',
                  unit: 'กก.',
                  value: weight,
                  suggestedValues: List.generate(51, (i) => 40 + i),
                  onChanged: (val) => setState(() => weight = val),
                ),
                _buildInputWithDropdown(
                  label: 'รอบอก',
                  unit: 'นิ้ว',
                  value: chest,
                  suggestedValues: List.generate(51, (i) => 20+ i),
                  onChanged: (val) => setState(() => chest = val),
                ),
                _buildInputWithDropdown(
                  label: 'รอบเอว',
                  unit: 'นิ้ว',
                  value: waist,
                  suggestedValues: List.generate(51, (i) => 15 + i),
                  onChanged: (val) => setState(() => waist = val),
                ),
                _buildInputWithDropdown(
                  label: 'สะโพก',
                  unit: 'นิ้ว',
                  value: hips,
                  suggestedValues: List.generate(51, (i) => 20 + i),
                  onChanged: (val) => setState(() => hips = val),
                ),
                SizedBox(height: 12),
                _buildDropdownInput('Size'),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),

      // ปุ่มยืนยันติดล่างจอ
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: register,
            child: const Text(
              'ยืนยัน',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputWithDropdown({
    required String label,
    required String unit,
    required int? value,
    required List<int> suggestedValues,
    required void Function(int) onChanged,
  }) {
    final controller = TextEditingController(text: value?.toString() ?? '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300, width: 1.4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'กรอกหรือเลือก $label',
                      border: InputBorder.none,
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null) onChanged(parsed);
                    },
                  ),
                ),
                PopupMenuButton<int>(
                  icon: Icon(Icons.arrow_drop_down),
                  onSelected: (val) {
                    controller.text = val.toString();
                    onChanged(val);
                  },
                  itemBuilder: (context) {
                    return suggestedValues.map((val) {
                      return PopupMenuItem(
                        value: val,
                        child: Text('$val $unit'),
                      );
                    }).toList();
                  },
                ),
                SizedBox(width: 8),
                Text(unit, style: TextStyle(color: Colors.black87)),
                
              ],
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('*ไม่จำเป็นต้องระบุ',
                style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscure = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly, // คุณจะเห็นว่าค่าดีฟอลต์เป็น false
        cursorColor: Colors.grey,
        decoration: InputDecoration(
          hintText: label,
          filled: true,
          fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade500, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdownInput(String label) {
    List<String> sizeOptions = ['S', 'M', 'L', 'XL'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 6),
        Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            underline: SizedBox(),
            value: selectedSize,
            hint: Text(''),
            items: sizeOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) => setState(() => selectedSize = value),
          ),
        ),
        SizedBox(height: 4),
        Text('*ไม่จำเป็นต้องระบุ',
            style: TextStyle(color: Colors.red, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String description) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.straighten_rounded, size: 36, color: Colors.black87),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 6),
                Text(description,
                    style: TextStyle(
                        fontSize: 13, color: Colors.black54, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void register() async {
    if (nameNoCt1.text.trim().isEmpty ||
        emailNoCt1.text.trim().isEmpty ||
        passwordNoCt1.text.trim().isEmpty ||
        conpasswordNoCt1.text.trim().isEmpty) {
      showModernDialog(
        context: context,
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
        title: 'กรุณากรอกข้อมูลให้ครบ',
        message: 'ทุกช่องต้องไม่มีช่องว่าง',
      );
      return;
    }

    if (passwordNoCt1.text != conpasswordNoCt1.text) {
      showModernDialog(
        context: context,
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'รหัสผ่านไม่ตรงกัน',
        message: 'โปรดตรวจสอบรหัสผ่านและลองใหม่อีกครั้ง',
      );
      return;
    }

    final password = passwordNoCt1.text.trim();
    final passwordRegex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$');

    if (!passwordRegex.hasMatch(password)) {
      showModernDialog(
        context: context,
        icon: Icons.lock_outline,
        iconColor: Colors.orange,
        title: 'รหัสผ่านไม่ปลอดภัย',
        message:
            'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร และประกอบด้วย:\n• ตัวพิมพ์ใหญ่\n• ตัวพิมพ์เล็ก\n• ตัวเลข',
      );
      return;
    }

    // เก็บข้อมูลทั้งหมดลง GetStorage
    final box = GetStorage();
    await box.write('register_name', nameNoCt1.text.trim());
    await box.write('register_email', emailNoCt1.text.trim());
    await box.write('register_password', password);
    await box.write('register_height', height ?? 0);
    await box.write('register_weight', weight ?? 0);
    await box.write('register_chest', chest ?? 0);
    await box.write('register_waist', waist ?? 0);
    await box.write('register_hips', hips ?? 0);
    await box.write('register_shirtSize', selectedSize ?? '');

    // ไปหน้า ChooseCategorypage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ChooseCategorypage()),
    );
  }

  void showModernDialog({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String confirmText = 'ตกลง',
  }) {
    showGeneralDialog(
      context: context,
      barrierLabel: "CustomDialog",
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (_, animation, __, ___) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(animation.value),
          child: Opacity(
            opacity: animation.value,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconColor.withOpacity(0.1),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Icon(icon, size: 40, color: iconColor),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (onConfirm != null) onConfirm();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(confirmText),
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
  }
}