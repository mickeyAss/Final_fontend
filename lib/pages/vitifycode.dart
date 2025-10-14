import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fontend_pro/config/config.dart';
// import 'package:fontend_pro/pages/reset_password_page.dart'; // นำเข้าหน้ารีเซ็ตรหัสผ่าน

class VerifyCodePage extends StatefulWidget {
  final String email;
  
  const VerifyCodePage({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final List<TextEditingController> controllers = 
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = 
      List.generate(6, (_) => FocusNode());
  
  bool isLoading = false;
  bool isResending = false;

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String getVerificationCode() {
    return controllers.map((c) => c.text).join();
  }

  Future<void> verifyCode() async {
    final code = getVerificationCode();
    
    // ตรวจสอบว่ากรอกครบ 6 หลัก
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกรหัสยืนยันให้ครบ 6 หลัก'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.post(
        Uri.parse('$url/user/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'verificationCode': code,
          'email': widget.email,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // แสดงข้อความสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'รหัสยืนยันตัวตนถูกต้อง'),
            backgroundColor: Colors.green,
          ),
        );

        // นำทางไปหน้ารีเซ็ตรหัสผ่าน
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(
              email: widget.email,
              verificationCode: code,
            ),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'รหัสยืนยันตัวตนไม่ถูกต้อง'),
            backgroundColor: Colors.red,
          ),
        );
        
        // ล้างรหัสที่กรอก
        _clearCode();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> resendCode() async {
    setState(() => isResending = true);

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.post(
        Uri.parse('$url/user/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งรหัสยืนยันตัวตนใหม่แล้ว'),
            backgroundColor: Colors.green,
          ),
        );
        _clearCode();
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'ไม่สามารถส่งรหัสใหม่ได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isResending = false);
    }
  }

  void _clearCode() {
    for (var controller in controllers) {
      controller.clear();
    }
    focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("ยืนยันรหัส OTP"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // ไอคอน
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 60,
                color: Colors.green.shade700,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // หัวข้อ
            const Text(
              "ตรวจสอบอีเมลของคุณ",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // คำอธิบาย
            Text(
              "เราได้ส่งรหัสยืนยันตัวตน 6 หลักไปที่\n${widget.email}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            // ช่องกรอก OTP 6 หลัก
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  height: 60,
                  child: TextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        // ไปช่องถัดไป
                        focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        // กลับไปช่องก่อนหน้า
                        focusNodes[index - 1].requestFocus();
                      }
                      
                      // ถ้ากรอกครบ 6 หลัก ให้ยืนยันอัตโนมัติ
                      if (index == 5 && value.isNotEmpty) {
                        verifyCode();
                      }
                    },
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 30),
            
            // ปุ่มยืนยันรหัส
            ElevatedButton(
              onPressed: isLoading ? null : verifyCode,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "ยืนยันรหัส",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            
            const SizedBox(height: 20),
            
            // ปุ่มส่งรหัสใหม่
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "ไม่ได้รับรหัส?",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 5),
                TextButton(
                  onPressed: isResending ? null : resendCode,
                  child: isResending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "ส่งรหัสใหม่",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder สำหรับหน้ารีเซ็ตรหัสผ่าน
class ResetPasswordPage extends StatelessWidget {
  final String email;
  final String verificationCode;
  
  const ResetPasswordPage({
    Key? key,
    required this.email,
    required this.verificationCode,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ตั้งรหัสผ่านใหม่")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("อีเมล: $email"),
            Text("รหัสยืนยัน: $verificationCode"),
          ],
        ),
      ),
    );
  }
}