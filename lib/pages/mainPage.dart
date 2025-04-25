import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Mainpage extends StatefulWidget {
  final int uid;
  Mainpage({super.key, required this.uid});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  final PageController pageController = PageController();
   bool isFavorite = false; // สถานะของหัวใจ


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(10), // ลดความสูงของ TabBar
            child: const TabBar(
              tabs: [
                Tab(text: 'กำลังติดตาม'),
                Tab(text: 'แนะนำสำหรับคุณ'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            FollowingTab(),
            RecommendedTab(pageController: pageController),
          ],
        ),
      ),
    );
  }
}

class FollowingTab extends StatelessWidget {
  const FollowingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('เนื้อหาของ "กำลังติดตาม"'),
    );
  }
}

class RecommendedTab extends StatelessWidget {
  final PageController pageController;

  const RecommendedTab({super.key, required this.pageController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(onPressed: () {}, child: Text("ทั้งหมด")),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/pic2.jpg',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "apxd_lxz ",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2), // ลด padding ด้านบน-ล่าง
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(0, 40), // ลดขนาดขั้นต่ำของปุ่ม
                            visualDensity: VisualDensity
                                .compact, // ลดความสูงของปุ่มให้กะทัดรัดขึ้น
                          ),
                          onPressed: () {},
                          child: const Text("ติดตาม"),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (String result) {
                            // Handle เมื่อกดเลือกเมนู
                            if (result == 'report') {
                              // ดำเนินการรายงาน
                            } else if (result == 'block') {
                              // ดำเนินการบล็อก
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'report',
                              child: Text('รายงาน'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'block',
                              child: Text('บล็อก'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Center(
                  child: Container(
                    height: 450, // กำหนดความสูงให้กับ PageView
                    width: double.infinity, // กำหนดความกว้างเต็มหน้าจอ
                    child: PageView(
                      controller: pageController, // เชื่อมโยงกับ PageController
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/p1.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/p2.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/p3.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                // SmoothPageIndicator
                Center(
                  child: SmoothPageIndicator(
                    controller: pageController, // เชื่อมโยงกับ PageController
                    count: 3, // จำนวนรูป
                    effect: ExpandingDotsEffect(
                      dotWidth: 8, // ขนาดจุด
                      dotHeight: 8, // ความสูงของจุด
                      spacing: 8, // ระยะห่างระหว่างจุด
                      expansionFactor: 4, // ขนาดขยายจุดเมื่อถูกเลือก
                      dotColor:
                          const Color.fromARGB(255, 0, 0, 0), // สีของจุดที่ไม่ได้เลือก
                      activeDotColor: Colors.black38, // สีของจุดที่เลือก
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 255, 255, 255),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 2), // ลด padding ด้านบน-ล่าง
                              textStyle: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              minimumSize: const Size(0, 40), // ลดขนาดขั้นต่ำของปุ่ม
                              visualDensity: VisualDensity
                                  .compact, // ลดความสูงของปุ่มให้กะทัดรัดขึ้น
                            ),
                            onPressed: () {},
                            child: const Text('สตรีท')),
                        SizedBox(
                          width: 8,
                        ),
                        OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 255, 255, 255),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 2), // ลด padding ด้านบน-ล่าง
                              textStyle: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              minimumSize: const Size(0, 40), // ลดขนาดขั้นต่ำของปุ่ม
                              visualDensity: VisualDensity
                                  .compact, // ลดความสูงของปุ่มให้กะทัดรัดขึ้น
                            ),
                            onPressed: () {},
                            child: const Text('chainese')),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // ทำสิ่งที่ต้องการเมื่อไอคอนแรกถูกกด
                          },
                          child: Row(
                            children: [
                              Icon(Icons.favorite_border),
                              Text("423"),
                            ],
                          ),
                        ),
                        SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            // ทำสิ่งที่ต้องการเมื่อไอคอนที่สองถูกกด
                          },
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/chat.png',
                                height: 20,
                                width: 20,
                              ),
                              SizedBox(width: 3),
                              Text("42"),
                            ],
                          ),
                        ),
                        SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            // ทำสิ่งที่ต้องการเมื่อไอคอนที่สามถูกกด
                          },
                          child: Row(
                            children: [
                              Icon(Icons.bookmark_outline_rounded),
                              Text("224"),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("แต่งตัวชิลๆ",style: TextStyle(fontWeight: FontWeight.bold),),
                      Text("ไอเดียแต่งตัวถ่ายรูปหน้ากระจกสวยๆจ้าา"),
                      Text("#ถ่ายรูปหน้ากระจก #ชุดเล่น",style: TextStyle(color: Colors.blue),), 
                      SizedBox(height: 5,),
                     Text("3 วันที่แล้ว",style: TextStyle(color: Colors.black38 , fontSize: 10),),
                    ],
                  ),
                ),
              ],
            ),
            // SizedBox(height: 10,),
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: [
            //         Row(
            //           children: [
            //             ClipOval(
            //               child: Image.asset(
            //                 'assets/images/pic1.jpg',
            //                 width: 40,
            //                 height: 40,
            //                 fit: BoxFit.cover,
            //               ),
            //             ),
            //             SizedBox(width: 10),
            //             Text(
            //               "Apidsada Laochai",
            //               style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            //             ),
            //           ],
            //         ),
            //         Row(
            //           children: [
            //             FilledButton(
            //               style: FilledButton.styleFrom(
            //                 backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            //                 foregroundColor: const Color.fromARGB(255, 255, 255, 255),
            //                 padding: const EdgeInsets.symmetric(
            //                     horizontal: 12,
            //                     vertical: 2), // ลด padding ด้านบน-ล่าง
            //                 textStyle: const TextStyle(
            //                   fontSize: 12,
            //                   fontWeight: FontWeight.bold,
            //                 ),
            //                 elevation: 10,
            //                 shape: RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(8),
            //                 ),
            //                 minimumSize: const Size(0, 40), // ลดขนาดขั้นต่ำของปุ่ม
            //                 visualDensity: VisualDensity
            //                     .compact, // ลดความสูงของปุ่มให้กะทัดรัดขึ้น
            //               ),
            //               onPressed: () {},
            //               child: const Text("ติดตาม"),
            //             ),
            //             PopupMenuButton<String>(
            //               icon: const Icon(Icons.more_vert),
            //               onSelected: (String result) {
            //                 // Handle เมื่อกดเลือกเมนู
            //                 if (result == 'report') {
            //                   // ดำเนินการรายงาน
            //                 } else if (result == 'block') {
            //                   // ดำเนินการบล็อก
            //                 }
            //               },
            //               itemBuilder: (BuildContext context) =>
            //                   <PopupMenuEntry<String>>[
            //                 const PopupMenuItem<String>(
            //                   value: 'report',
            //                   child: Text('รายงาน'),
            //                 ),
            //                 const PopupMenuItem<String>(
            //                   value: 'block',
            //                   child: Text('บล็อก'),
            //                 ),
            //               ],
            //             ),
            //           ],
            //         ),
            //       ],
            //     ),
            //     SizedBox(height: 10),
            //     Center(
            //       child: Container(
            //         height: 450, // กำหนดความสูงให้กับ PageView
            //         width: double.infinity, // กำหนดความกว้างเต็มหน้าจอ
            //         child: PageView(
            //           controller: pageController, // เชื่อมโยงกับ PageController
            //           children: [
            //             ClipRRect(
            //               borderRadius: BorderRadius.circular(20),
            //               child: Image.asset(
            //                 'assets/images/p5.jpg',
            //                 fit: BoxFit.cover,
            //               ),
            //             ),
            //             ClipRRect(
            //               borderRadius: BorderRadius.circular(20),
            //               child: Image.asset(
            //                 'assets/images/p4.jpg',
            //                 fit: BoxFit.cover,
            //               ),
            //             ),
                        
            //           ],
            //         ),
            //       ),
            //     ),
            //     SizedBox(height: 10),
            //     // SmoothPageIndicator
            //     Center(
            //       child: SmoothPageIndicator(
            //         controller: pageController, // เชื่อมโยงกับ PageController
            //         count: 2, // จำนวนรูป
            //         effect: ExpandingDotsEffect(
            //           dotWidth: 8, // ขนาดจุด
            //           dotHeight: 8, // ความสูงของจุด
            //           spacing: 8, // ระยะห่างระหว่างจุด
            //           expansionFactor: 4, // ขนาดขยายจุดเมื่อถูกเลือก
            //           dotColor:
            //               const Color.fromARGB(255, 0, 0, 0), // สีของจุดที่ไม่ได้เลือก
            //           activeDotColor: Colors.black38, // สีของจุดที่เลือก
            //         ),
            //       ),
            //     ),
            //     SizedBox(height: 10),
            //     Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: [
            //         Row(
            //           children: [
            //             OutlinedButton(
            //                 style: OutlinedButton.styleFrom(
            //                   backgroundColor:
            //                       const Color.fromARGB(255, 255, 255, 255),
            //                   foregroundColor: Colors.black,
            //                   padding: const EdgeInsets.symmetric(
            //                       horizontal: 20,
            //                       vertical: 2), // ลด padding ด้านบน-ล่าง
            //                   textStyle: const TextStyle(
            //                       fontSize: 12, color: Colors.black54),
            //                   elevation: 10,
            //                   shape: RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(20),
            //                   ),
            //                   minimumSize: const Size(0, 40), // ลดขนาดขั้นต่ำของปุ่ม
            //                   visualDensity: VisualDensity
            //                       .compact, // ลดความสูงของปุ่มให้กะทัดรัดขึ้น
            //                 ),
            //                 onPressed: () {},
            //                 child: const Text('สตรีท')),
            //             SizedBox(
            //               width: 8,
            //             ),
            //             OutlinedButton(
            //                 style: OutlinedButton.styleFrom(
            //                   backgroundColor:
            //                       const Color.fromARGB(255, 255, 255, 255),
            //                   foregroundColor: Colors.black,
            //                   padding: const EdgeInsets.symmetric(
            //                       horizontal: 20,
            //                       vertical: 2), // ลด padding ด้านบน-ล่าง
            //                   textStyle: const TextStyle(
            //                       fontSize: 12, color: Colors.black54),
            //                   elevation: 10,
            //                   shape: RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(20),
            //                   ),
            //                   minimumSize: const Size(0, 40), // ลดขนาดขั้นต่ำของปุ่ม
            //                   visualDensity: VisualDensity
            //                       .compact, // ลดความสูงของปุ่มให้กะทัดรัดขึ้น
            //                 ),
            //                 onPressed: () {},
            //                 child: const Text('airport')),
            //           ],
            //         ),
            //         Row(
            //           children: [
            //             GestureDetector(
            //               onTap: () {
            //                 // ทำสิ่งที่ต้องการเมื่อไอคอนแรกถูกกด
            //               },
            //               child: Row(
            //                 children: [
            //                   Icon(Icons.favorite_border),
            //                   Text("1256"),
            //                 ],
            //               ),
            //             ),
            //             SizedBox(width: 5),
            //             GestureDetector(
            //               onTap: () {
            //                 // ทำสิ่งที่ต้องการเมื่อไอคอนที่สองถูกกด
            //               },
            //               child: Row(
            //                 children: [
            //                   Image.asset(
            //                     'assets/images/chat.png',
            //                     height: 20,
            //                     width: 20,
            //                   ),
            //                   SizedBox(width: 3),
            //                   Text("325"),
            //                 ],
            //               ),
            //             ),
            //             SizedBox(width: 5),
            //             GestureDetector(
            //               onTap: () {
            //                 // ทำสิ่งที่ต้องการเมื่อไอคอนที่สามถูกกด
            //               },
            //               child: Row(
            //                 children: [
            //                   Icon(Icons.bookmark_outline_rounded),
            //                   Text("444"),
            //                 ],
            //               ),
            //             ),
            //           ],
            //         )
            //       ],
            //     ),
                
            //     Padding(
            //       padding: const EdgeInsets.only(left: 8),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Text("แต่งตัวขึ้นเครื่อง",style: TextStyle(fontWeight: FontWeight.bold),),
            //           Text("ไปบินกันจ้า"),
            //           Text("#ถ่ายรูปสนามบิน #เป๋าลาก #สตรีท",style: TextStyle(color: Colors.blue),), 
            //           SizedBox(height: 5,),
            //          Text("5 วันที่แล้ว",style: TextStyle(color: Colors.black38 , fontSize: 10),),
            //         ],
            //       ),
            //     ),
            //   ],
            // )
          ],
        ),
      ),
    );
     
  }
}
