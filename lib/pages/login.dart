import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fontend_pro/config/config.dart';
import 'package:fontend_pro/pages/register.dart';
import 'package:fontend_pro/pages/mainPage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fontend_pro/models/login_user_request.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> with TickerProviderStateMixin {
  TextEditingController emailNoCt1 = TextEditingController();
  TextEditingController passwordNoCt1 = TextEditingController();

  GetStorage gs = GetStorage();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  late AnimationController _logoController;
  late AnimationController _slideController;
  late Animation<double> _logoAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // เริ่มแอนิเมชัน
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _slideController.dispose();
    emailNoCt1.dispose();
    passwordNoCt1.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black,
                Colors.grey[900]!,
                Colors.black,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // Logo (เหมือนเดิม)
                  AnimatedBuilder(
                    animation: _logoAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              "assets/images/Logo.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Welcome text (เหมือนเดิม)
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _slideController,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Colors.grey],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: const Text(
                              "ยินดีต้อนรับกลับ!",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "เข้าสู่บัญชีของคุณเพื่อเริ่มต้นการใช้งาน",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Text Fields (เหมือนเดิม)
                  _buildModernTextField(
                    label: "อีเมล",
                    controller: emailNoCt1,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 20),

                  _buildModernTextField(
                    label: "รหัสผ่าน",
                    controller: passwordNoCt1,
                    icon: Icons.lock_outline,
                    obscure: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[500],
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Forgot Password (เหมือนเดิม)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        showModernDialog(
                          context: context,
                          icon: Icons.info_outline,
                          iconColor: Colors.blue,
                          title: 'ฟีเจอร์ยังไม่พร้อมใช้งาน',
                          message:
                              'ระบบลืมรหัสผ่านกำลังพัฒนา กรุณาติดต่อผู้ดูแลระบบ',
                        );
                      },
                      child: Text(
                        "ลืมรหัสผ่าน?",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ✅ ปรับปรุงปุ่ม Login ให้ Loading แบบเรียบง่าย
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: _isLoading
                          ? LinearGradient(
                              colors: [Colors.grey[400]!, Colors.grey[300]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [Colors.white, Colors.grey[200]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      boxShadow: _isLoading
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.black,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : loginuser,
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey[700]!),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "กำลังเข้าสู่ระบบ...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              "เข้าสู่ระบบ",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Divider (เหมือนเดิม)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey[600]!,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "หรือเข้าสู่ระบบด้วย",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey[600]!,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ✅ ปรับปรุงปุ่ม Google ให้ Loading แบบเรียบง่าย
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            _isLoading ? Colors.grey[600]! : Colors.grey[700]!,
                        width: 1,
                      ),
                      color: _isLoading ? Colors.grey[800] : Colors.grey[900],
                    ),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : signInWithGoogle,
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey[400]!),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "กำลังเชื่อมต่อ...",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Image.asset(
                                      'assets/images/google.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Google",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Register Link (เหมือนเดิม)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ยังไม่มีบัญชีใช่หรือไม่? ',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegisterPage(),
                                  ),
                                );
                              },
                        child: Text(
                          "สร้างบัญชีใหม่",
                          style: TextStyle(
                            color: _isLoading ? Colors.grey[600] : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[900],
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.grey[500],
            size: 20,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.white,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // Email/Password Login Method
  void loginuser() async {
    if (_isLoading) return;

    // ปิด keyboard
    FocusScope.of(context).unfocus();

    // Validate input
    final email = emailNoCt1.text.trim();
    final password = passwordNoCt1.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showModernDialog(
        context: context,
        icon: Icons.error_outline,
        iconColor: Colors.orange,
        title: 'กรุณากรอกข้อมูลให้ครบถ้วน',
        message: 'กรุณากรอกอีเมลและรหัสผ่านก่อนเข้าสู่ระบบ',
      );
      return;
    }

    // Email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      showModernDialog(
        context: context,
        icon: Icons.email_outlined,
        iconColor: Colors.orange,
        title: 'รูปแบบอีเมลไม่ถูกต้อง',
        message: 'กรุณากรอกอีเมลในรูปแบบที่ถูกต้อง',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final loginRequest = LoginUserRequest(
        email: email,
        password: password,
      );

      final response = await http.post(
        Uri.parse("$url/user/login"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode({
          "email": loginRequest.email,
          "password": loginRequest.password,
          "isGoogleLogin": false,
        }),
      );

      log('Login Response Status: ${response.statusCode}');
      log('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        if (responseData['message'] == 'Login successful') {
          var user = responseData['user'];

          // บันทึกข้อมูลผู้ใช้
          await gs.write('user', user['uid']);
          await gs.write('user_data', user);
          await gs.write('login_type', 'email');

          log('เข้าสู่ระบบสำเร็จ');

          // ✅ เข้าหน้า Main เลย ไม่แสดง popup
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Mainpage()),
            );
          }
        }
      } else {
        // จัดการข้อผิดพลาด
        var errorData = jsonDecode(response.body);
        String errorTitle;
        String errorMessage;

        switch (response.statusCode) {
          case 401:
            errorTitle = 'รหัสผ่านไม่ถูกต้อง';
            errorMessage = 'โปรดตรวจสอบรหัสผ่านและลองอีกครั้ง';
            break;
          case 404:
            errorTitle = 'ไม่พบบัญชีผู้ใช้';
            errorMessage =
                'ไม่พบบัญชีที่ใช้อีเมลนี้ กรุณาตรวจสอบอีเมลหรือสร้างบัญชีใหม่';
            break;
          case 400:
            errorTitle = 'ข้อมูลไม่ถูกต้อง';
            errorMessage = 'กรุณาตรวจสอบข้อมูลที่กรอกและลองใหม่';
            break;
          default:
            errorTitle = 'เกิดข้อผิดพลาด';
            errorMessage =
                errorData['error'] ?? 'ไม่สามารถเข้าสู่ระบบได้ กรุณาลองใหม่';
        }

        showModernDialog(
          context: context,
          icon: Icons.error_outline,
          iconColor: Colors.red,
          title: errorTitle,
          message: errorMessage,
        );

        log('Login Error (${response.statusCode}): ${errorData['error']}');
      }
    } catch (e) {
      log('Login Exception: $e');
      showModernDialog(
        context: context,
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        message:
            'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบอินเทอร์เน็ตและลองใหม่',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// ✅ ปรับปรุงฟังก์ชัน signInWithGoogle - ไม่แสดง popup เมื่อสำเร็จ
  Future<void> signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // ขั้นตอนที่ 1: Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // ผู้ใช้ยกเลิกการ sign in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // ขั้นตอนที่ 2: Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // ตรวจสอบว่าได้ idToken หรือไม่
      if (googleAuth.idToken == null) {
        throw Exception('ไม่สามารถรับ ID Token จาก Google ได้');
      }

      // ขั้นตอนที่ 3: เตรียมข้อมูลสำหรับส่งไปยัง API
      final String name = googleUser.displayName ?? '';
      final String email = googleUser.email;
      final String profileImage = googleUser.photoUrl ?? '';
      final String idToken = googleAuth.idToken!;

      log('Google Sign In Data: Name=$name, Email=$email');

      // ขั้นตอนที่ 4: ส่งข้อมูลไปยัง API
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.post(
        Uri.parse("$url/user/login"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode({
          "email": email,
          "isGoogleLogin": true,
          "idToken": idToken,
          "name": name,
          "profile_image": profileImage,
        }),
      );

      log('Google Login Response Status: ${response.statusCode}');
      log('Google Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        var user = responseData['user'];

        // บันทึก user data
        await gs.write('user', user['uid']);
        await gs.write('user_data', user);
        await gs.write('login_type', 'google');

        bool isNewUser =
            responseData['message'].toString().contains('new user');
        log('Google Login successful: ${responseData['message']}');

        // ✅ เข้าหน้า Main เลย ไม่แสดง popup
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Mainpage()),
          );
        }
      } else {
        // จัดการ error cases
        var errorData = jsonDecode(response.body);
        String errorMessage;
        String errorTitle;

        switch (response.statusCode) {
          case 400:
            errorTitle = 'ข้อมูลไม่ถูกต้อง';
            errorMessage = 'ข้อมูลการเข้าสู่ระบบไม่ครบถ้วนหรือไม่ถูกต้อง';
            break;
          case 401:
            errorTitle = 'การตรวจสอบล้มเหลว';
            errorMessage = 'ไม่สามารถตรวจสอบ Google Token ได้';
            break;
          case 500:
            errorTitle = 'เซิร์ฟเวอร์ขัดข้อง';
            errorMessage = 'เกิดข้อผิดพลาดที่เซิร์ฟเวอร์ กรุณาลองใหม่ในภายหลัง';
            break;
          default:
            errorTitle = 'เกิดข้อผิดพลาด';
            errorMessage =
                errorData['error'] ?? 'ไม่สามารถเข้าสู่ระบบด้วย Google ได้';
        }

        showModernDialog(
          context: context,
          icon: Icons.error_outline,
          iconColor: Colors.red,
          title: errorTitle,
          message: errorMessage,
        );

        log('Google login error (${response.statusCode}): ${errorData['error']}');
      }
    } on Exception catch (e) {
      log('Google sign-in exception: $e');
      showModernDialog(
        context: context,
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'เกิดข้อผิดพลาดกับ Google',
        message:
            'ไม่สามารถเชื่อมต่อกับ Google ได้ กรุณาตรวจสอบอินเทอร์เน็ตและลองใหม่',
      );
    } catch (e) {
      log('Google sign-in error: $e');
      showModernDialog(
        context: context,
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'เกิดข้อผิดพลาดที่ไม่คาดคิด',
        message:
            'กรุณาลองใหม่อีกครั้ง หากปัญหายังคงอยู่ กรุณาติดต่อผู้ดูแลระบบ',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Modern Dialog Method
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
      barrierColor: Colors.black87,
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
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey[700]!,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
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
                          border: Border.all(
                            color: iconColor.withOpacity(0.3),
                            width: 2,
                          ),
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
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey[200]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.black,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ตกลง',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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

  // Auto Login Check Method (เรียกใช้ใน initState ถ้าต้องการ)
  Future<void> checkAutoLogin() async {
    final userId = gs.read('user');
    final loginType = gs.read('login_type');

    if (userId != null && loginType != null) {
      // มีข้อมูล login เก่าอยู่ - สามารถไปหน้าหลักได้เลย
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Mainpage()),
      );
    }
  }

  // Logout Method (สำหรับใช้ในหน้าอื่น)
  Future<void> logout() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();

      // Clear storage
      await gs.erase();

      // Navigate to login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Loginpage()),
        (route) => false,
      );
    } catch (e) {
      log('Logout error: $e');
    }
  }
}
