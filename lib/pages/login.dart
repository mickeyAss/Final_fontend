import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/pages/register.dart';
import 'package:fontend_pro/pages/mainPage.dart';
import 'package:fontend_pro/models/login_user_request.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  TextEditingController emailNoCt1 = TextEditingController();
  TextEditingController passwordNoCt1 = TextEditingController();

  GetStorage gs = GetStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade100],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(milliseconds: 800),
                  child: Image.asset(
                    "assets/images/Logo.png",
                    width: 90,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  "ยินดีต้อนรับ!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "เข้าสู่บัญชีของคุณ",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 30),

                // Email
                buildTextField(
                  label: "อีเมล",
                  controller: emailNoCt1,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),

                // Password
                buildTextField(
                  label: "รหัสผ่าน",
                  controller: passwordNoCt1,
                  icon: Icons.lock_outline,
                  obscure: true,
                ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: Text("ลืมรหัสผ่าน ?"),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Login Button
                AnimatedScale(
                  duration: Duration(milliseconds: 300),
                  scale: 1.0,
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: loginuser,
                      child:
                          Text("เข้าสู่ระบบ", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text("หรือ"),
                    ),
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),

                const SizedBox(height: 20),

                // Google login
                OutlinedButton.icon(
                  icon: Image.asset(
                    'assets/images/google.png',
                    width: 24,
                    height: 24,
                  ),
                  label: Text(
                    "เข้าสู่ระบบด้วย Google",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                    side: BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('ยังไม่มีบัญชีใช่หรือไม่?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RegisterPage()),
                        );
                      },
                      child: Text("สร้างบัญชีใหม่"),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void loginuser() async {
    LoginUserRequest model = LoginUserRequest(
      email: emailNoCt1.text,
      password: passwordNoCt1.text,
    );

    // เช็คว่ามีการกรอกข้อมูลหรือไม่
    if (model.email.trim().isEmpty || model.password.trim().isEmpty) {
      // แสดงป็อบอัพเตือนเมื่อไม่มีการกรอกข้อมูล
      showModernDialog(
        context: context,
        icon: Icons.error_outline,
        iconColor: Colors.orange,
        title: 'กรุณากรอกข้อมูลให้ครบถ้วน',
        message: 'กรุณากรอกอีเมลและรหัสผ่านก่อนเข้าสู่ระบบ',
      );

      return; // ออกจากฟังก์ชันถ้าไม่มีข้อมูล
    }

    showLoadingDialog(context); // <--- แสดงโหลดดิ้ง

    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final response = await http.post(
        Uri.parse("$url/user/login"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode(model.toJson()),
      );

      Navigator.pop(context); // <--- ปิดโหลดดิ้ง

      if (response.statusCode == 200) {
        // การล็อกอินสำเร็จ
        var responseData = jsonDecode(response.body); // เปลี่ยนตรงนี้
        if (responseData['message'] == 'Login successful') {
          await gs.write(
              'user',
              responseData['user']
                  ['uid']); //ถ้าlogin ผ่านให้เก็บ username ไว้ในระบบ
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Mainpage(),
            ),
          );
          log('เข้าสู่ระบบสำเร็จ');
        }
      } else if (response.statusCode == 401) {
        var errorData = jsonDecode(response.body);

        showModernDialog(
          context: context,
          icon: Icons.lock_outline,
          iconColor: Colors.red,
          title: 'รหัสผ่านไม่ถูกต้อง',
          message: 'โปรดตรวจสอบและลองอีกครั้ง',
        );

        log('Error: ${errorData['error']}');
      } else if (response.statusCode == 404) {
        var errorData = jsonDecode(response.body);
        showModernDialog(
          context: context,
          icon: Icons.mail_outline,
          iconColor: Colors.orange,
          title: 'อีเมลไม่ถูกต้อง',
          message: 'ไม่พบบัญชีผู้ใช้ โปรดตรวจสอบอีเมลอีกครั้ง',
        );

        log('Error: ${errorData['error']}');
      }
    } catch (e) {
      log('Error: $e');
    }
  }

  void showModernDialog({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
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
                  boxShadow: [
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
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('ตกลง'),
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
}
