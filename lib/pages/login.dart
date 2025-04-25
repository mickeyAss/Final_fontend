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
      body: Container(
        color: Color.fromARGB(255, 255, 255, 255),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 100, bottom: 70),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/images/Logo.png",
                      width: 80,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("ยินดีต้อนรับสู่ LifeStyle"),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                      child: TextField(
                        controller: emailNoCt1,
                        cursorColor: Colors.grey, // เปลี่ยนสีของเคอร์เซอร์
                        decoration: InputDecoration(
                          labelText: 'อีเมล',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey, width: 2), // สีขอบปกติ
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey,
                                width: 2), // สีขอบเมื่อโฟกัส
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                      child: TextField(
                        controller: passwordNoCt1,
                        cursorColor: Colors.grey, // เปลี่ยนสีของเคอร์เซอร์
                        decoration: InputDecoration(
                          labelText: 'รหัสผ่าน',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey, width: 2), // สีขอบปกติ
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey,
                                width: 2), // สีขอบเมื่อโฟกัส
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: GestureDetector(
                        onTap: () {
                          // ฟังก์ชันที่ต้องการเมื่อกดข้อความ
                          print('ลืมรหัสผ่านถูกกด');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "ลืมรหัสผ่าน ?",
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 111, 111,
                                      111) // เปลี่ยนสีข้อความให้ดูเหมือนลิงก์
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                      child: Container(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Color.fromARGB(
                                255, 227, 227, 227), // สีพื้นหลังของปุ่ม
                            foregroundColor: Colors.black, // สีข้อความบนปุ่ม
                            padding: EdgeInsets.only(left: 135, right: 135),
                            textStyle: TextStyle(fontSize: 16),
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10), // ความมนของปุ่ม
                            ),
                          ),
                          onPressed: loginuser,
                          child: Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.black54,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "หรือ",
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.black54,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity, // ขยายความกว้างเต็มหน้าจอ
                      height: 45,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                10), // กำหนดค่ารัศมีของมุม
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize
                              .min, // เพื่อไม่ให้มีการขยายกว้างเกินไป
                          children: [
                            Image.asset(
                              'assets/images/google.png', // ใส่ path ของรูปภาพ
                              width: 24, // ขนาดของรูปภาพ
                              height: 24, // ขนาดของรูปภาพ
                            ),
                            const SizedBox(
                                width: 10), // ช่องว่างระหว่างรูปภาพและข้อความ
                            const Text(
                              'Login with Google',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ยังไม่มีบัญชีใช่หรือไม่?'),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        RegisterPage()), // เปลี่ยนชื่อหน้าตามที่ใช้จริง
                              );
                            },
                            child: Text(
                              '  สร้างบัญชีใหม่',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(
                                    255, 0, 0, 0), // เพิ่มสีให้น่าคลิกขึ้น
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
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
      showModalBottomSheet(
        context: context,
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
                Icon(Icons.error_outline, color: Colors.orange, size: 40),
                SizedBox(height: 10),
                Text(
                  'กรุณากรอกข้อมูลให้ครบถ้วน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'กรุณากรอกอีเมลและรหัสผ่านก่อนเข้าสู่ระบบ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: Text('ตกลง'),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
          );
        },
      );

      return; // ออกจากฟังก์ชันถ้าไม่มีข้อมูล
    }

    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    try {
      final response = await http.post(
        Uri.parse("$url/user/login"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode(model.toJson()),
      );

      if (response.statusCode == 200) {
        // การล็อกอินสำเร็จ
        var responseData = jsonDecode(response.body); // เปลี่ยนตรงนี้
        if (responseData['message'] == 'Login successful') {
          gs.write(
              'uid',
              responseData['user']
                  ['uid']); //ถ้าlogin ผ่านให้เก็บ username ไว้ในระบบ
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Mainpage(
                uid: responseData['user']['uid'], // เปลี่ยนตรงนี้
              ),
            ),
          );
          log('เข้าสู่ระบบสำเร็จ');
        }
      } else if (response.statusCode == 401) {
        var errorData = jsonDecode(response.body);

        showModalBottomSheet(
          context: context,
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
                  Icon(Icons.lock_outline, color: Colors.red, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'รหัสผ่านไม่ถูกต้อง',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'โปรดตรวจสอบและลองอีกครั้ง',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: Text('ตกลง'),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            );
          },
        );

        log('Error: ${errorData['error']}');
      } else if (response.statusCode == 404) {
        var errorData = jsonDecode(response.body);
        showModalBottomSheet(
          context: context,
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
                  Icon(Icons.mail_outline, color: Colors.orange, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'อีเมลไม่ถูกต้อง',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'ไม่พบบัญชีผู้ใช้ โปรดตรวจสอบอีเมลอีกครั้ง',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: Text('ตกลง'),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            );
          },
        );
        log('Error: ${errorData['error']}');
      }
    } catch (e) {
      log('Error: $e');
    }
  }
}
