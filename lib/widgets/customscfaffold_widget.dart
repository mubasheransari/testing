import 'package:flutter/material.dart';

import 'boxDecorationWidget.dart';

class CustomScaffoldWidget extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final bool isDrawerRequired;
  final String appbartitle;
  final bool isAppBarContentRequired;
  final bool showNotificationIcon;

  const CustomScaffoldWidget({
    Key? key,
    required this.body,
    required this.appbartitle,
    this.appBar,
    this.drawer,
    this.isDrawerRequired = false,
    this.isAppBarContentRequired = true,
    this.showNotificationIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: _scaffoldKey,
     // drawer: isDrawerRequired ? CustomNavDrawer() : null,
      appBar: appBar,
      backgroundColor: const Color(0xFFF5F7FA),
      body: DecoratedBox(
        decoration: boxDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              if (isAppBarContentRequired)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      isDrawerRequired
                          ? InkWell(
                              onTap: () {
                                _scaffoldKey.currentState?.openDrawer();
                              },
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white,
                                child: Image.asset("assets/menu-02.png"),
                              ),
                            )
                          : InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white,
                                child:
                                    Icon(Icons.arrow_back, color: Colors.black),
                              ),
                            ),
                      Text(
                        appbartitle,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Satoshi',
                        ),
                      ),
                      if (showNotificationIcon)
                        InkWell(
                          onTap: () {
                           
                          },
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            child: Image.asset("assets/notification.png"),
                          ),
                        )
                      // else
                      // CircleAvatar(
                      //       radius: 22,
                      //       backgroundColor: Colors.white,
                      //       child:  IconButton(onPressed: (){
                          
                      //       }, icon: Icon(Icons.favorite_border_outlined,color: Colors.red,)),
                      //     ),
                     

                    ],
                  ),
                ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}


//final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

// class CustomScaffoldWidget extends StatelessWidget {
//   final Widget body;
//   final PreferredSizeWidget? appBar;
//   final Widget? drawer;
//   final bool isDrawerRequired;
//   final String appbartitle;
//   final bool isAppBarContentRequired;

//   const CustomScaffoldWidget({
//     Key? key,
//     required this.body,
//     required this.appbartitle,
//     this.appBar,
//     this.drawer,
//     this.isDrawerRequired = false,
//     this.isAppBarContentRequired = true,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//     return Scaffold(
//       key: _scaffoldKey,
//       drawer: isDrawerRequired ? CustomNavDrawer() : null,
//       appBar: appBar,
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: DecoratedBox(
//         decoration: boxDecoration(),
//         child: SafeArea(
//           child: Column(
//             children: [
//               isAppBarContentRequired == true
//                   ? Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 16, vertical: 12),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           isDrawerRequired
//                               ? InkWell(
//                                   onTap: () {
//                                     _scaffoldKey.currentState?.openDrawer();
//                                   },
//                                   child: CircleAvatar(
//                                     radius: 22,
//                                     backgroundColor: Colors.white,
//                                     child: Image.asset("assets/menu-02.png"),
//                                   ),
//                                 )
//                               : InkWell(
//                                   onTap: () {
//                                     Navigator.pop(context);
//                                   },
//                                   child: const CircleAvatar(
//                                     radius: 22,
//                                     backgroundColor: Colors.white,
//                                     child: Icon(Icons.arrow_back,
//                                         color: Colors.black),
//                                   ),
//                                 ),
//                           Text(
//                             appbartitle,
//                             style: const TextStyle(
//                               fontSize: 24,
//                               color: Colors.black,
//                               fontWeight: FontWeight.bold,
//                               fontFamily: 'Satoshi',
//                             ),
//                           ),
//                           InkWell(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) =>
//                                       const NotificationScreen(),
//                                 ),
//                               );
//                             },
//                             child: CircleAvatar(
//                               radius: 22,
//                               backgroundColor: Colors.white,
//                               child: Image.asset("assets/notification.png"),
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   : SizedBox(),
//               Expanded(child: body),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


















// import 'package:flutter/material.dart';
// import '../Features/navdrawer.dart';
// import '../Features/notification_screen.dart';
// import 'boxDecorationWidget.dart';

// final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

// class CustomScaffoldWidget extends StatelessWidget {
//   final Widget body;
//   final PreferredSizeWidget? appBar;
//   final Widget? drawer;
//   bool isDrawerRequired;
//   final String appbartitle;

//   CustomScaffoldWidget(
//       {Key? key,
//       required this.body,
//       required this.appbartitle,
//       this.appBar,
//       this.drawer,
//       this.isDrawerRequired = false})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: isDrawerRequired == true ? CustomNavDrawer() : null,
//       key: _scaffoldKey, // optional: for global drawer access
//       appBar: appBar,
//       backgroundColor: const Color(0xFFF5F7FA),
//       body: DecoratedBox(
//         decoration: boxDecoration(),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(top: 80.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     isDrawerRequired == true
//                         ? InkWell(
//                             onTap: () {
//                               print("abc");
//                               // Open drawer here
//                               _scaffoldKey.currentState?.openDrawer();
//                             },
//                             child: CircleAvatar(
//                               radius: 22,
//                               backgroundColor: Colors.white,
//                               child: Image.asset("assets/menu-02.png"),
//                             ),
//                           )
//                         : InkWell(
//                             onTap: () {
//                               Navigator.pop(context);
//                             },
//                             child: CircleAvatar(
//                               radius: 22,
//                               backgroundColor: Colors.white,
//                               child:
//                                   Icon(Icons.arrow_back, color: Colors.black),
//                             ),
//                           ),
//                     const SizedBox(width: 8),
//                     Text(
//                       appbartitle,
//                       style: TextStyle(
//                         fontSize: 24,
//                         color: Colors.black, //Color(0xff323747),
//                         fontWeight: FontWeight.bold,
//                         fontFamily: 'Satoshi',
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     InkWell(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => NotificationScreen(),
//                           ),
//                         );
//                       },
//                       child: CircleAvatar(
//                         radius: 22,
//                         backgroundColor: Colors.white,
//                         child: Image.asset("assets/notification.png"),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               body
//               //   Column(children: [body],)
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
