import 'package:flutter/material.dart';
import 'package:taskoon/Screens/User_booking/checkout_screen.dart';


import 'package:flutter/material.dart';
// import 'checkout_screen.dart'; // your existing screen

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  static const Color kPurple = Color(0xFF5C2E91);
  static const Color kPage = Color(0xFFF4F3FA);
  static const String kFont = 'Poppins';

  // ids: apple, gpay, card, wallet, saved
  String _selected = 'apple';

  void _onSelect(String id) {
    setState(() => _selected = id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: kPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(
            fontFamily: kFont,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: kPurple,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // amount / summary card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPurple.withOpacity(.03)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.02),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: kPurple.withOpacity(.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.payments_rounded, color: kPurple),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Total amount',
                            style: TextStyle(
                              fontFamily: kFont,
                              fontSize: 12.5,
                              color: Color(0xFF7A6F8D),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '\$ 40.00',
                            style: TextStyle(
                              fontFamily: kFont,
                              fontSize: 20,
                              color: kPurple,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.info_outline_rounded,
                        size: 20, color: Color(0xFFB0A6BE)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // "Payment method" title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Payment method',
                  style: TextStyle(
                    fontFamily: kFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kPurple,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  PaymentMethodTile(
                    id: 'apple',
                    selectedId: _selected,
                    onSelect: _onSelect,
                    title: 'Apple Pay',
                    leading: _circleIcon(
                      Image.asset(
                        'assets/apple_pay.png',
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  PaymentMethodTile(
                    id: 'gpay',
                    selectedId: _selected,
                    onSelect: _onSelect,
                    title: 'Google Pay',
                    leading: _circleIcon(
                      Image.asset(
                        'assets/google_pay_icon.jpg',
                        height: 18,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  PaymentMethodTile(
                    id: 'card',
                    selectedId: _selected,
                    onSelect: _onSelect,
                    title: 'Debit / Credit card',
                    subtitle: 'Use Visa, Master or Amex',
                    leading: _circleIcon(
                      const Icon(Icons.credit_card_rounded,
                          color: kPurple, size: 20),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: kPurple),
                  ),
                  PaymentMethodTile(
                    id: 'wallet',
                    selectedId: _selected,
                    onSelect: _onSelect,
                    title: 'Taskoon wallet',
                    subtitle: 'Balance: \$20.00',
                    leading: _circleIcon(
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: Color(0xFF2E99E4)),
                    ),
                  ),
                  PaymentMethodTile(
                    id: 'saved',
                    selectedId: _selected,
                    onSelect: _onSelect,
                    title: 'Saved payment methods',
                    leading: _circleIcon(
                      const Icon(Icons.lock_outline_rounded,
                          color: kPurple, size: 20),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: kPurple),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // bottom button
            Container(
              color: kPage,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                  },
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(Widget child) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF0EDF7)),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.id,
    required this.selectedId,
    required this.onSelect,
    required this.title,
    required this.leading,
    this.subtitle,
    this.trailing,
  });

  final String id;
  final String? selectedId;
  final void Function(String id) onSelect;
  final String title;
  final String? subtitle;
  final Widget leading;
  final Widget? trailing;

  static const String kFont = 'Poppins';
  static const Color kPurple = Color(0xFF5C2E91);

  @override
  Widget build(BuildContext context) {
    final bool isSelected = id == selectedId;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onSelect(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPurple.withOpacity(.25) : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.015),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: kFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3E1E69),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: kFont,
                        fontSize: 11.5,
                        color: Color(0xFF8D88A0),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing ??
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSelected ? kPurple : const Color(0xFFC7C8D2),
                      width: 1.7,
                    ),
                    color: Colors.white,
                  ),
                  child: isSelected
                      ? const Center(
                          child: CircleAvatar(
                            radius: 5,
                            backgroundColor: kPurple,
                          ),
                        )
                      : null,
                ),
          ],
        ),
      ),
    );
  }
}


// class PaymentMethodScreen extends StatefulWidget {
//   const PaymentMethodScreen({super.key});

//   @override
//   State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
// }

// class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
//   static const Color kPurple = Color(0xFF5C2D91);
//   static const Color kGreen = Color(0xFF2F7D32);
//   static const String kFont = 'Poppins';

//   // ids: apple, gpay, savedCard, card, wallet
//   String? _selected = 'apple';

//   void _onSelect(String id) {
//     setState(() => _selected = id);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.of(context).size.width;
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // top bar
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back, color: kPurple),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   const SizedBox(width: 4),
//                   const Text(
//                     'Total transaction',
//                     style: TextStyle(
//                       fontFamily: kFont,
//                       fontSize: 20,
//                       fontWeight: FontWeight.w600,
//                       color: kPurple,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             // amount card
//             Container(
//               width: w * 0.85,
//               padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF0DFFF),
//                 borderRadius: BorderRadius.circular(26),
//               ),
//               child: Column(
//                 children: const [
//                   Text(
//                     'Amount',
//                     style: TextStyle(
//                       fontFamily: kFont,
//                       fontSize: 16,
//                       color: kPurple,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     '\$ 40.00',
//                     style: TextStyle(
//                       fontFamily: kFont,
//                       fontSize: 36,
//                       fontWeight: FontWeight.w700,
//                       color: kPurple,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'Payment method',
//                   style: TextStyle(
//                     fontFamily: kFont,
//                     fontSize: 15,
//                     fontWeight: FontWeight.w700,
//                     color: kPurple,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 14),
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 children: [
//                   _PayTile(
//                     id: 'apple',
//                     selectedId: _selected,
//                     onTap: _onSelect,
//                     leading: _roundedIcon(
//                       child: Image.asset(
//                         'assets/apple_pay.png',
//                         height: 30,
//                         width: 30,
//                         fit: BoxFit.fill,
//                       ),
//                     ),
//                     title: 'Apple Pay',
//                   ),
//                   _PayTile(
//                     id: 'gpay',
//                     selectedId: _selected,
//                     onTap: _onSelect,
//                     leading: _roundedIcon(
//                       child: Image.asset(
//                         'assets/google_pay_icon.jpg',
//                         height: 20,
//                       ),
//                     ),
//                     title: 'Google Pay',
//                   ),
//                   _PayTile(
//                     id: 'savedCard',
//                     selectedId: _selected,
//                     onTap: _onSelect,
//                     leading: _roundedIcon(
//                       child: const Icon(Icons.credit_card, color: kPurple),
//                     ),
//                     title: 'Add debit/credit',
//                     trailing: const Icon(Icons.chevron_right_rounded,
//                         color: kPurple),
//                   ),
//                   _PayTile(
//                     id: 'card',
//                     selectedId: _selected,
//                     onTap: _onSelect,
//                     leading: _roundedIcon(
//                       child: const Icon(Icons.account_balance_wallet_outlined,
//                           color: Color(0xFF2E99E4)),
//                     ),
//                     title: 'Card',
//                   ),
//                   _PayTile(
//                     id: 'wallet',
//                     selectedId: _selected,
//                     onTap: _onSelect,
//                     leading: _roundedIcon(
//                       child:
//                           const Icon(Icons.local_offer_outlined, color: kPurple),
//                     ),
//                     title: 'Wallet Pay',
//                     trailing: const Icon(Icons.chevron_right_rounded,
//                         color: kPurple),
//                   ),
//                   const SizedBox(height: 12),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kGreen,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     elevation: 0,
//                   ),
//                   onPressed: () {
//                                     Navigator.push(context, MaterialPageRoute(builder: (context)=> CheckoutScreen()));

//                   },
//                   child: const Text(
//                     'SELECT',
//                     style: TextStyle(
//                       fontFamily: kFont,
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                       letterSpacing: .3,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _roundedIcon({required Widget child}) {
//     return Container(
//       width: 40,
//       height: 40,
//       decoration: BoxDecoration(
//         border: Border.all(color: const Color(0xFFF0EDF7)),
//         shape: BoxShape.circle,
//         color: Colors.white,
//       ),
//       alignment: Alignment.center,
//       child: child,
//     );
//   }
// }

// class _PayTile extends StatelessWidget {
//   const _PayTile({
//     required this.id,
//     required this.selectedId,
//     required this.onTap,
//     required this.leading,
//     required this.title,
//     this.trailing,
//   });

//   final String id;
//   final String? selectedId;
//   final void Function(String id) onTap;
//   final Widget leading;
//   final String title;
//   final Widget? trailing;

//   static const String kFont = 'Poppins';
//   static const Color kPurple = Color(0xFF5C2D91);

//   @override
//   Widget build(BuildContext context) {
//     final bool isSelected = id == selectedId;
//     return InkWell(
//       borderRadius: BorderRadius.circular(14),
//       onTap: () => onTap(id),
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: isSelected ? kPurple.withOpacity(.3) : Colors.transparent,
//           ),
//           color: isSelected ? const Color(0xFFF8F4FF) : Colors.white,
//         ),
//         child: Row(
//           children: [
//             leading,
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 title,
//                 style: const TextStyle(
//                   fontFamily: kFont,
//                   fontSize: 14.5,
//                   fontWeight: FontWeight.w500,
//                   color: Color(0xFF4C4C4C),
//                 ),
//               ),
//             ),
//             if (trailing != null) ...[
//               trailing!,
//             ] else ...[
//               Container(
//                 width: 21,
//                 height: 21,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                       color: isSelected ? kPurple : const Color(0xFFCDD1DA),
//                       width: 1.8),
//                   color: Colors.white,
//                 ),
//                 child: isSelected
//                     ? const Center(
//                         child: CircleAvatar(
//                           radius: 5,
//                           backgroundColor: kPurple,
//                         ),
//                       )
//                     : null,
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
