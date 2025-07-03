import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fontend_pro/pages/choose_categoryPage.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
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
        backgroundColor: Colors.grey,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_left, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'สมัครสมาชิก',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        color: Color.fromARGB(255, 255, 255, 255),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'กรุณากรอกข้อมูลเพื่อสมัครสมาชิก\n'
                  'เริ่มต้นด้วยการตั้งชื่อผู้ใช้ที่คุณต้องการใช้ ใส่อีเมลที่สามารถติดต่อได้\n'
                  'และสร้างรหัสผ่านที่ปลอดภัย เพื่อให้คุณสามารถเข้าสู่ระบบและใช้บริการได้อย่างปลอดภัย',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 10),
              Text('ข้อมูลของคุณ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildTextField('ชื่อผู้ใช้', nameNoCt1),
              _buildTextField('อีเมล', emailNoCt1),
              _buildTextField('รหัสผ่าน', passwordNoCt1, obscure: true),
              _buildTextField('ยืนยันรหัสผ่าน', conpasswordNoCt1,
                  obscure: true),
              SizedBox(height: 20),
              Text('สัดส่วนของคุณ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                'โดยเราจะนำข้อมูลสัดส่วนของคุณไปค้นหาเสื้อผ้า หรือไลฟ์สไตล์ที่เหมาะกับลักษณะร่างกายของคุณ',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _buildNumberInput('ส่วนสูง', () => height,
                          (val) => setState(() => height = val))),
                  SizedBox(width: 10),
                  Expanded(
                      child: _buildNumberInput('น้ำหนัก', () => weight,
                          (val) => setState(() => weight = val))),
                  SizedBox(width: 10),
                  Expanded(child: _buildDropdownInput('Size')),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _buildNumberInput('รอบอก', () => chest,
                          (val) => setState(() => chest = val))),
                  SizedBox(width: 10),
                  Expanded(
                      child: _buildNumberInput('รอบเอว', () => waist,
                          (val) => setState(() => waist = val))),
                  SizedBox(width: 10),
                  Expanded(
                      child: _buildNumberInput('สะโพก', () => hips,
                          (val) => setState(() => hips = val))),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Container(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 227, 227, 227),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 135),
                      textStyle: TextStyle(fontSize: 16),
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: (){
                      Get.to(ChooseCategorypage());
                    },
                    child: Text('ยืนยัน',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        cursorColor: Colors.grey,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberInput(
      String label, int? Function() getValue, void Function(int?) setValue) {
    TextEditingController controller = TextEditingController(
      text: getValue()?.toString() ?? '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(height: 5),
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  int current = getValue() ?? 0;
                  if (current > 0) {
                    setValue(current - 1);
                    controller.text = (current - 1).toString();
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (value) {
                    int? val = int.tryParse(value);
                    // ป้องกันเลขติดลบจากการพิมพ์
                    if (val != null && val >= 0) {
                      setValue(val);
                    } else {
                      controller.text = '0';
                      setValue(0);
                    }
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  int current = getValue() ?? 0;
                  setValue(current + 1);
                  controller.text = (current + 1).toString();
                },
              ),
            ],
          ),
        ),
        Text('*ไม่จำเป็นต้องระบุ',
            style: TextStyle(color: Colors.red, fontSize: 12)),
      ],
    );
  }

  Widget _buildDropdownInput(String label) {
    List<String> sizeOptions = ['S', 'M', 'L', 'XL'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
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
            onChanged: (value) {
              setState(() {
                selectedSize = value;
              });
            },
          ),
        ),
        Text('*ไม่จำเป็นต้องระบุ',
            style: TextStyle(color: Colors.red, fontSize: 12)),
      ],
    );
  }

  // void register() async {
  //   // ตรวจสอบให้แน่ใจว่าทุกช่องกรอกข้อมูลถูกต้องและไม่มีช่องว่าง
  //   if (nameNoCt1.text.trim().isEmpty ||
  //       emailNoCt1.text.trim().isEmpty ||
  //       passwordNoCt1.text.trim().isEmpty ||
  //       conpasswordNoCt1.text.trim().isEmpty) {
  //     log('กรอกข้อมูลไม่ครบทุกช่องหรือมีช่องว่าง');
  //     showModalBottomSheet(
  //       context: context,
  //       isDismissible: false, // ❌ ปิดไม่ได้โดยการแตะนอก
  //       enableDrag: false, // ❌ ปิดไม่ได้โดยการลากลง
  //       backgroundColor: Colors.white,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //       ),
  //       builder: (BuildContext context) {
  //         return Padding(
  //           padding: const EdgeInsets.all(20.0),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Icon(Icons.warning_amber_rounded,
  //                   color: Colors.orange, size: 40),
  //               SizedBox(height: 10),
  //               Text(
  //                 'กรุณากรอกข้อมูลให้ครบ',
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //                 textAlign: TextAlign.center,
  //               ),
  //               SizedBox(height: 5),
  //               Text(
  //                 'ทุกช่องต้องไม่มีช่องว่าง',
  //                 style: TextStyle(fontSize: 14, color: Colors.black87),
  //                 textAlign: TextAlign.center,
  //               ),
  //               SizedBox(height: 20),
  //               FilledButton(
  //                 onPressed: () => Navigator.of(context).pop(),
  //                 style: FilledButton.styleFrom(
  //                   backgroundColor: Colors.orange.shade800,
  //                   foregroundColor: Colors.white,
  //                   padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                 ),
  //                 child: Text('ตกลง', style: TextStyle(fontSize: 14)),
  //               ),
  //             ],
  //           ),
  //         );
  //       },
  //     );

  //     return;
  //   }

  //   if (passwordNoCt1.text != conpasswordNoCt1.text) {
  //     log('Passwords do not match');
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           title: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Icon(Icons.error_outline, color: Colors.red, size: 40),
  //               SizedBox(height: 10),
  //               Text(
  //                 'รหัสผ่านไม่ตรงกัน',
  //                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  //               ),
  //             ],
  //           ),
  //           actions: <Widget>[
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 FilledButton(
  //                   child: Text('ตกลง'),
  //                   style: FilledButton.styleFrom(
  //                     backgroundColor: Colors.red.shade700,
  //                     foregroundColor: Colors.white,
  //                     textStyle: TextStyle(fontSize: 14),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(8.0),
  //                     ),
  //                     elevation: 5,
  //                   ),
  //                   onPressed: () {
  //                     Navigator.of(context).pop();
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //     return;
  //   }

  //   // ทำการสมัครสมาชิก
  //   var model = RegisterUserRequest(
  //       name: nameNoCt1.text,
  //       email: emailNoCt1.text,
  //       password: passwordNoCt1.text,
  //       height: height.toString(),
  //       weight: weight.toString(),
  //       shirtSize: selectedSize.toString(),
  //       chest: chest.toString(),
  //       waistCircumference: waist.toString(),
  //       hip: hips.toString());

  //   var config = await Configuration.getConfig();
  //   var url = config['apiEndpoint'];

  //   try {
  //     var response = await http.post(
  //       Uri.parse("$url/user/register"),
  //       headers: {"Content-Type": "application/json; charset=utf-8"},
  //       body: registerUserRequestToJson(model),
  //     );

  //     // ล็อกข้อมูลการตอบสนอง
  //     log('Status code: ${response.statusCode}');
  //     log('Response body: ${response.body}');

  //     // แสดงป็อบอัพสำหรับสถานะสมัครสมาชิกสำเร็จ
  //     if (response.statusCode == 201) {
  //       // แสดงป็อบอัพเตือนเมื่อไม่มีการกรอกข้อมูล
  //       showModalBottomSheet(
  //         context: context,
  //         isDismissible: false, // ❌ ปิดไม่ได้โดยการแตะนอก
  //         enableDrag: false, // ❌ ปิดไม่ได้โดยการลากลง
  //         backgroundColor: Colors.white,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //         ),
  //         builder: (context) {
  //           return Padding(
  //             padding: const EdgeInsets.all(20),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Icon(Icons.check_circle_outline,
  //                     color: Colors.green, size: 40),
  //                 SizedBox(height: 10),
  //                 Text(
  //                   'สมัครสมาชิกสำเร็จแล้ว',
  //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //                 ),
  //                 SizedBox(height: 10),
  //                 Text(
  //                   'คุณสามารถเข้าสู่ระบบได้ทันที',
  //                   style: TextStyle(color: Colors.grey[600]),
  //                 ),
  //                 SizedBox(height: 20),
  //                 ElevatedButton(
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: Colors.green,
  //                     foregroundColor: Colors.white,
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                     padding:
  //                         EdgeInsets.symmetric(horizontal: 30, vertical: 12),
  //                   ),
  //                   child: Text('ตกลง'),
  //                   onPressed: () {
  //                     Navigator.pop(context); // ปิดป็อบอัพ
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (context) => Loginpage(),
  //                       ),
  //                     );
  //                   },
  //                 )
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     }
  //   } catch (e) {
  //     log('Error: $e');
  //     // แสดงป็อบอัพเมื่อเกิดข้อผิดพลาดในการเชื่อมต่อ
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           title: Center(
  //               child: Text(
  //             'เกิดข้อผิดพลาดในการเชื่อมต่อ',
  //             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
  //           )),
  //           actions: <Widget>[
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 FilledButton(
  //                   child: Text('ตกลง'),
  //                   style: FilledButton.styleFrom(
  //                       backgroundColor: Color.fromARGB(255, 72, 0, 0),
  //                       foregroundColor:
  //                           const Color.fromARGB(255, 255, 255, 255),
  //                       textStyle: TextStyle(fontSize: 14),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(8.0),
  //                       ),
  //                       elevation: 5),
  //                   onPressed: () {
  //                     Navigator.of(context).pop();
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   }
  // }
}
