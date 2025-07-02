import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fontend_pro/pages/login.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/models/register_user_request.dart';

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
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
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
      body: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 12,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('ข้อมูลของคุณ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildTextField('ชื่อผู้ใช้', nameNoCt1),
              _buildTextField('อีเมล', emailNoCt1),
              _buildTextField('รหัสผ่าน', passwordNoCt1, obscure: true),
              _buildTextField('ยืนยันรหัสผ่าน', conpasswordNoCt1,
                  obscure: true),
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
                unit: 'ซม.',
                value: chest,
                suggestedValues: List.generate(51, (i) => 70 + i),
                onChanged: (val) => setState(() => chest = val),
              ),
              _buildInputWithDropdown(
                label: 'รอบเอว',
                unit: 'ซม.',
                value: waist,
                suggestedValues: List.generate(51, (i) => 60 + i),
                onChanged: (val) => setState(() => waist = val),
              ),
              _buildInputWithDropdown(
                label: 'สะโพก',
                unit: 'ซม.',
                value: hips,
                suggestedValues: List.generate(51, (i) => 80 + i),
                onChanged: (val) => setState(() => hips = val),
              ),
              SizedBox(height: 12),
              _buildDropdownInput('Size'),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    textStyle: TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: register,
                  child: Text('ยืนยัน',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
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
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        cursorColor: Colors.grey,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
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
      log('กรอกข้อมูลไม่ครบทุกช่องหรือมีช่องว่าง');
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 40),
                SizedBox(height: 10),
                Text('กรุณากรอกข้อมูลให้ครบ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                SizedBox(height: 5),
                Text('ทุกช่องต้องไม่มีช่องว่าง',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.center),
                SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('ตกลง', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    if (passwordNoCt1.text != conpasswordNoCt1.text) {
      log('Passwords do not match');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40),
                SizedBox(height: 10),
                Text('รหัสผ่านไม่ตรงกัน',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    child: Text('ตกลง'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(fontSize: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          );
        },
      );
      return;
    }

    // ตรวจสอบรูปแบบรหัสผ่านให้ตรงเงื่อนไขความปลอดภัย
    final password = passwordNoCt1.text.trim();
    final passwordRegex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$');

    if (!passwordRegex.hasMatch(password)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, color: Colors.orange, size: 40),
                SizedBox(height: 10),
                Text('รหัสผ่านไม่ปลอดภัย',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center),
              ],
            ),
            content: Text(
              'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร และประกอบด้วย:\n• ตัวพิมพ์ใหญ่\n• ตัวพิมพ์เล็ก\n• ตัวเลข',
              style: TextStyle(fontSize: 14),
            ),
            actions: <Widget>[
              Center(
                child: FilledButton(
                  child: Text('ตกลง'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    // ทำการสมัครสมาชิก
    var model = RegisterUserRequest(
      name: nameNoCt1.text,
      email: emailNoCt1.text,
      password: password,
      height: height.toString(),
      weight: weight.toString(),
      shirtSize: selectedSize.toString(),
      chest: chest.toString(),
      waistCircumference: waist.toString(),
      hip: hips.toString(),
    );

    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      var response = await http.post(
        Uri.parse("$url/user/register"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: registerUserRequestToJson(model),
      );

      log('Status code: ${response.statusCode}');
      log('Response body: ${response.body}');

      if (response.statusCode == 201) {
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 40),
                  SizedBox(height: 10),
                  Text('สมัครสมาชิกสำเร็จแล้ว',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('คุณสามารถเข้าสู่ระบบได้ทันที',
                      style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: Text('ตกลง'),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Loginpage(),
                        ),
                      );
                    },
                  )
                ],
              ),
            );
          },
        );
      } else {
        // รองรับการแสดง error message จาก API ถ้ามี
        final message = response.body.contains('error')
            ? response.body
            : 'เกิดข้อผิดพลาดในการสมัครสมาชิก';
        log('สมัครไม่สำเร็จ: $message');
      }
    } catch (e) {
      log('Error: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Center(
              child: Text(
                'เกิดข้อผิดพลาดในการเชื่อมต่อ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    child: Text('ตกลง'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 72, 0, 0),
                      foregroundColor: Colors.white,
                      textStyle: TextStyle(fontSize: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          );
        },
      );
    }
  }
}
