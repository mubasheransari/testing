import 'package:flutter/material.dart';
import 'package:taskoon/Screens/User_booking/checkout_screen.dart';



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
                   const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:  [
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

