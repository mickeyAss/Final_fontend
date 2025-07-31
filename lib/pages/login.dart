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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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

                      // Logo
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

                      // Welcome text
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _slideController,
                          child: Column(
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
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

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
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

                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey[200]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
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
                          child: const Text(
                            "เข้าสู่ระบบ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

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

                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[700]!,
                            width: 1,
                          ),
                          color: Colors.grey[900],
                        ),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  await signInWithGoogle();
                                },
                          child: Row(
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

                      const SizedBox(height: 10),

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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "สร้างบัญชีใหม่",
                              style: TextStyle(
                                color: Colors.white,
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
        ),

        // เพิ่ม Overlay โหลดเมื่อกำลังโหลด
        if (_isLoading) ...[
          ModalBarrier(
            color: Colors.black.withOpacity(0.5),
            dismissible: false,
          ),
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ],
      ],
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

  void loginuser() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    final model = LoginUserRequest(
      email: emailNoCt1.text.trim(),
      password: passwordNoCt1.text.trim(),
    );

    if (model.email.isEmpty || model.password.isEmpty) {
      showModernDialog(
        context: context,
        icon: Icons.error_outline,
        iconColor: Colors.orange,
        title: 'กรุณากรอกข้อมูลให้ครบถ้วน',
        message: 'กรุณากรอกอีเมลและรหัสผ่านก่อนเข้าสู่ระบบ',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var config = await Configuration.getConfig();
      var url = config['apiEndpoint'];

      final response = await http.post(
        Uri.parse("$url/user/login"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode(model.toJson()),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        if (responseData['message'] == 'Login successful') {
          await gs.write('user', responseData['user']['uid']);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Mainpage()),
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
      showModernDialog(
        context: context,
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'เกิดข้อผิดพลาด',
        message: 'ไม่สามารถเข้าสู่ระบบได้ กรุณาลองใหม่',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

 Future<void> signInWithGoogle() async {
  if (_isLoading) return;

  setState(() {
    _isLoading = true;
  });

  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final String name = googleUser.displayName ?? '';
    final String email = googleUser.email;
    final String profileImage = googleUser.photoUrl ?? '';

    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    final response = await http.post(
      Uri.parse("$url/user/login"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: jsonEncode({
        "email": email,
        "isGoogleLogin": true,
        "name": name,
        "profile_image": profileImage,
      }),
    );

    if (response.statusCode == 200) {
      var responseData = jsonDecode(response.body);
      var user = responseData['user'];

      await gs.write('user', user['uid']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Mainpage()),
      );

      log('Login with Google successful');
    } else {
      var errorData = jsonDecode(response.body);
      showModernDialog(
        context: context,
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: 'เกิดข้อผิดพลาด',
        message: errorData['error'] ?? 'ไม่สามารถเข้าสู่ระบบด้วย Google ได้',
      );
      log('Google login error: ${errorData['error']}');
    }
  } catch (e) {
    log('Google sign-in error: $e');
    showModernDialog(
      context: context,
      icon: Icons.error_outline,
      iconColor: Colors.red,
      title: 'เกิดข้อผิดพลาด',
      message: 'ไม่สามารถเข้าสู่ระบบด้วย Google ได้ กรุณาลองใหม่',
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
}