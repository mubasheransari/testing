import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:taskoon/Screens/User_booking/service_inprogress_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // brand palette
  static const String kFont = 'Poppins';
  static const Color kBg = Color(0xFFF5F3FF);
  static const Color kPrimary = Color(0xFF5C2D91);
  static const Color kPrimarySoft = Color(0xFFEDE7FF);
  static const Color kGreen = Color(0xFF2F7D32);

  // 0 = card, 1 = apple, 2 = gpay, 3 = wallet
  int _method = 0;
  bool _save = false;

  final _cardCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _expCtrl = TextEditingController();

  @override
  void dispose() {
    _cardCtrl.dispose();
    _nameCtrl.dispose();
    _cvvCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: kFont,
          color: Color(0xFF827A9A),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kPrimary.withOpacity(.35), width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kPrimary, width: 1.3),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top bar
              Row(
                children: [
                    IconButton(onPressed: (){
                      Navigator.pop(context);
                    }, icon: Icon(Icons.arrow_back, color: kPrimary)),
                  // _roundedIcon(
                  //   onTap: () => Navigator.pop(context),
                  //   child: const Icon(Icons.arrow_back, color: kPrimary),
                  // ),
                  const SizedBox(width: 14),
                  const Text(
                    'Checkout',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // amount / summary section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFE6FF), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // amount
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Total payable',
                            style: TextStyle(
                              fontFamily: kFont,
                              fontSize: 14,
                              color: Color(0xFF7B7397),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '\$40.00',
                            style: TextStyle(
                              fontFamily: kFont,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.verified_rounded,
                                  color: kGreen, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'Secured payment',
                                style: TextStyle(
                                  fontFamily: kFont,
                                  fontSize: 11.5,
                                  color: Color(0xFF5C2D91),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 75,
                      width: 76,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Order #',
                            style: TextStyle(
                              fontFamily: kFont,
                              fontSize: 11,
                              color: kPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'TSK-8923',
                            style: TextStyle(
                              fontFamily: kFont,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Choose payment method',
                style: TextStyle(
                  fontFamily: kFont,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A2657),
                ),
              ),
              const SizedBox(height: 10),

              // methods row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MethodChip(
                      active: _method == 0,
                      icon: Icons.credit_card_rounded,
                      label: 'Card',
                      onTap: () => setState(() => _method = 0),
                    ),
                    const SizedBox(width: 10),
                    _MethodChip.asset(
                      active: _method == 1,
                      asset: 'assets/apple_pay.png',
                      label: 'Apple Pay',
                      onTap: () => setState(() => _method = 1),
                    ),
                    const SizedBox(width: 10),
                    _MethodChip.asset(
                      active: _method == 2,
                      asset: 'assets/google_pay_icon.jpg',
                      label: 'Google Pay',
                      onTap: () => setState(() => _method = 2),
                    ),
                    const SizedBox(width: 10),
                    _MethodChip(
                      active: _method == 3,
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Wallet',
                      onTap: () => setState(() => _method = 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // dynamic form
              if (_method == 0) ...[
                TextField(
                  controller: _cardCtrl,
                  style: const TextStyle(fontFamily: kFont),
                  keyboardType: TextInputType.number,
                  decoration: _input('Card number'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(fontFamily: kFont),
                  decoration: _input("Cardholder's name"),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cvvCtrl,
                        style: const TextStyle(fontFamily: kFont),
                        keyboardType: TextInputType.number,
                        decoration: _input('CVV / CVC'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _expCtrl,
                        style: const TextStyle(fontFamily: kFont),
                        keyboardType: TextInputType.datetime,
                        decoration: _input('MM / YY'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Checkbox(
                      visualDensity: VisualDensity.compact,
                      value: _save,
                      onChanged: (v) => setState(() => _save = v ?? false),
                      activeColor: kPrimary,
                    ),
                    const Flexible(
                      child: Text(
                        'Save this card for future payments',
                        style: TextStyle(
                          fontFamily: kFont,
                          fontSize: 13,
                          color: Color(0xFF6A637C),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  width: w,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: kPrimary.withOpacity(.12), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _method == 1
                            ? Icons.phone_iphone_rounded
                            : _method == 2
                                ? Icons.android_rounded
                                : Icons.account_balance_wallet_rounded,
                        color: kPrimary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _method == 1
                              ? 'Apple Pay is selected. You will confirm on the next step.'
                              : _method == 2
                                  ? 'Google Pay is selected. You will confirm on the next step.'
                                  : 'Wallet will be used for this transaction.',
                          style: const TextStyle(
                            fontFamily: kFont,
                            fontSize: 13.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],

              const SizedBox(height: 8),
              // bottom button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _onPay,
                  child: const Text(
                    'PAY NOW',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundedIcon({required Widget child, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kPrimary.withOpacity(.12)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(child: child),
      ),
    );
  }

  void _onPay() {
    if (_method == 0) {
      if (_cardCtrl.text.isEmpty ||
          _nameCtrl.text.isEmpty ||
          _cvvCtrl.text.isEmpty ||
          _expCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please fill all card details',
              style: TextStyle(fontFamily: kFont),
            ),
          ),
        );
        return;
      }
    }

    Navigator.push(context, MaterialPageRoute(builder: (context)=> ServiceInProgressScreen()));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _method == 0
              ? 'Processing card…'
              : _method == 1
                  ? 'Opening Apple Pay…'
                  : _method == 2
                      ? 'Opening Google Pay…'
                      : 'Paying from wallet…',
          style: const TextStyle(fontFamily: kFont),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                   chips                                    */
/* -------------------------------------------------------------------------- */

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : asset = null;

  const _MethodChip.asset({
    required this.active,
    required this.asset,
    required this.label,
    required this.onTap,
  }) : icon = null;

  final bool active;
  final IconData? icon;
  final String? asset;
  final String label;
  final VoidCallback onTap;

  static const String kFont = 'Poppins';
  static const Color kPrimary = Color(0xFF5C2D91);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF2EEFF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? kPrimary : Colors.white,
            width: 1.1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: kPrimary.withOpacity(.12),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, color: kPrimary)
            else
              Image.asset(asset!, height: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: kFont,
                fontSize: 13.4,
                fontWeight: FontWeight.w500,
                color: kPrimary,
              ),
            ),
            const SizedBox(width: 4),
            if (active)
              const Icon(Icons.check_circle, color: kPrimary, size: 16),
          ],
        ),
      ),
    );
  }
}


// class CheckoutScreen extends StatefulWidget {
//   const CheckoutScreen({super.key});

//   @override
//   State<CheckoutScreen> createState() => _CheckoutScreenState();
// }

// class _CheckoutScreenState extends State<CheckoutScreen> {
//   static const Color kPurple = Color(0xFF5C2D91);
//   static const Color kBorder = Color(0xFF5C2D91);
//   static const Color kGreen = Color(0xFF2F7D32);
//   static const String kFont = 'Poppins';

//   // 0 = card, 1 = apple, 2 = gpay
//   int _method = 0;
//   bool _save = false;

//   final _cardCtrl = TextEditingController();
//   final _nameCtrl = TextEditingController();
//   final _cvvCtrl = TextEditingController();
//   final _expCtrl = TextEditingController();

//   @override
//   void dispose() {
//     _cardCtrl.dispose();
//     _nameCtrl.dispose();
//     _cvvCtrl.dispose();
//     _expCtrl.dispose();
//     super.dispose();
//   }

//   InputDecoration _input(String hint) => InputDecoration(
//         hintText: hint,
//         hintStyle: const TextStyle(
//           fontFamily: kFont,
//           color: Color(0xFF8A8797),
//           fontSize: 14,
//         ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(16),
//           borderSide: const BorderSide(color: kBorder, width: 1.3),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(16),
//           borderSide: const BorderSide(color: kPurple, width: 1.6),
//         ),
//       );

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.of(context).size.width;
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F6FF),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // top bar
//               Container(
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(22),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(.02),
//                       blurRadius: 12,
//                       offset: const Offset(0, 4),
//                     )
//                   ],
//                 ),
//                 padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back, color: kPurple),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                     const SizedBox(width: 3),
//                     const Text(
//                       'Checkout',
//                       style: TextStyle(
//                         fontFamily: kFont,
//                         fontSize: 22,
//                         fontWeight: FontWeight.w600,
//                         color: kPurple,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 22),

//               const Text(
//                 'Payment method',
//                 style: TextStyle(
//                   fontFamily: kFont,
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600,
//                   color: kPurple,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   _PayOption(
//                     isActive: _method == 0,
//                     icon: Icons.credit_card,
//                     label: 'Card',
//                     onTap: () => setState(() => _method = 0),
//                   ),
//                   const SizedBox(width: 10),
//                   _PayOption.asset(
//                     isActive: _method == 1,
//                     asset: 'assets/apple-pay.png',
//                     label: 'Apple',
//                     onTap: () => setState(() => _method = 1),
//                   ),
//                   const SizedBox(width: 10),
//                   _PayOption.asset(
//                     isActive: _method == 2,
//                     asset: 'assets/gpay.png',
//                     label: 'Google',
//                     onTap: () => setState(() => _method = 2),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 22),

//               // card fields visible only when card selected
//               if (_method == 0) ...[
//                 TextField(
//                   controller: _cardCtrl,
//                   keyboardType: TextInputType.number,
//                   style: const TextStyle(fontFamily: kFont),
//                   decoration: _input('Card Number'),
//                 ),
//                 const SizedBox(height: 14),
//                 TextField(
//                   controller: _nameCtrl,
//                   style: const TextStyle(fontFamily: kFont),
//                   decoration: _input("Cardholder's name"),
//                 ),
//                 const SizedBox(height: 14),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _cvvCtrl,
//                         keyboardType: TextInputType.number,
//                         style: const TextStyle(fontFamily: kFont),
//                         decoration: _input('CVV/CVC'),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: TextField(
//                         controller: _expCtrl,
//                         keyboardType: TextInputType.datetime,
//                         style: const TextStyle(fontFamily: kFont),
//                         decoration: _input('Expiry date'),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 14),
//                 Row(
//                   children: [
//                     Checkbox(
//                       visualDensity: VisualDensity.compact,
//                       value: _save,
//                       onChanged: (v) => setState(() => _save = v ?? false),
//                       activeColor: kPurple,
//                     ),
//                     const Flexible(
//                       child: Text(
//                         'Save this card for future payments',
//                         style: TextStyle(
//                           fontFamily: kFont,
//                           fontSize: 13.2,
//                           color: Color(0xFF5B5A65),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//               ] else ...[
//                 Container(
//                   width: w,
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(color: const Color(0xFFE2D5FF)),
//                   ),
//                   child: Text(
//                     _method == 1
//                         ? 'You will be charged via Apple Pay.'
//                         : 'You will be charged via Google Pay.',
//                     style: const TextStyle(
//                       fontFamily: kFont,
//                       fontSize: 14,
//                       color: Color(0xFF443954),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ],

//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kGreen,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     elevation: 0,
//                   ),
//                   onPressed: _onPay,
//                   child: const Text(
//                     'PAY NOW',
//                     style: TextStyle(
//                       fontFamily: kFont,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                       letterSpacing: .15,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _onPay() {
//     if (_method == 0) {
//       if (_cardCtrl.text.isEmpty ||
//           _nameCtrl.text.isEmpty ||
//           _cvvCtrl.text.isEmpty ||
//           _expCtrl.text.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Please fill all card fields',
//               style: TextStyle(fontFamily: kFont),
//             ),
//           ),
//         );
//         return;
//       }
//     }
//     // TODO: integrate real payment
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           _method == 0
//               ? 'Processing card payment…'
//               : _method == 1
//                   ? 'Opening Apple Pay…'
//                   : 'Opening Google Pay…',
//           style: const TextStyle(fontFamily: kFont),
//         ),
//       ),
//     );
//   }
// }

// /* -------------------------------------------------------------------------- */
// /*                                 helpers                                    */
// /* -------------------------------------------------------------------------- */

// class _PayOption extends StatelessWidget {
//   const _PayOption({
//     required this.isActive,
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   }) : asset = null;

//   const _PayOption.asset({
//     required this.isActive,
//     required this.asset,
//     required this.label,
//     required this.onTap,
//   }) : icon = null;

//   final bool isActive;
//   final IconData? icon;
//   final String? asset;
//   final String label;
//   final VoidCallback onTap;

//   static const Color kPurple = Color(0xFF5C2D91);
//   static const String kFont = 'Poppins';

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 140),
//         width: 95,
//         height: 70,
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: isActive ? const Color(0xFFEFE7FF) : Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: isActive ? kPurple : const Color(0xFFE6E1ED),
//             width: 1.3,
//           ),
//           boxShadow: isActive
//               ? [
//                   BoxShadow(
//                     color: kPurple.withOpacity(.15),
//                     blurRadius: 10,
//                     offset: const Offset(0, 6),
//                   )
//                 ]
//               : [],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (icon != null)
//               Icon(icon, color: kPurple, size: 28)
//             else
//               Image.asset(asset!, height: 26),
//             const SizedBox(height: 6),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontFamily: kFont,
//                 fontSize: 11,
//                 color: kPurple,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
