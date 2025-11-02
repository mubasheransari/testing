import 'package:flutter/material.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  static const Color kPurple = Color(0xFF5C2D91);
  static const Color kGreen = Color(0xFF2F7D32);
  static const String kFont = 'Poppins';

  // ids: apple, gpay, savedCard, card, wallet
  String? _selected = 'apple';

  void _onSelect(String id) {
    setState(() => _selected = id);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: kPurple),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Total transaction',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: kPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // amount card
            Container(
              width: w * 0.85,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0DFFF),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                children: const [
                  Text(
                    'Amount',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 16,
                      color: kPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '\$ 40.00',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: kPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _PayTile(
                    id: 'apple',
                    selectedId: _selected,
                    onTap: _onSelect,
                    leading: _roundedIcon(
                      child: Image.asset(
                        'assets/apple-pay.png',
                        height: 20,
                      ),
                    ),
                    title: 'Apple Pay',
                  ),
                  _PayTile(
                    id: 'gpay',
                    selectedId: _selected,
                    onTap: _onSelect,
                    leading: _roundedIcon(
                      child: Image.asset(
                        'assets/gpay.png',
                        height: 20,
                      ),
                    ),
                    title: 'Google Pay',
                  ),
                  _PayTile(
                    id: 'savedCard',
                    selectedId: _selected,
                    onTap: _onSelect,
                    leading: _roundedIcon(
                      child: const Icon(Icons.credit_card, color: kPurple),
                    ),
                    title: 'Add debit/credit',
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: kPurple),
                  ),
                  _PayTile(
                    id: 'card',
                    selectedId: _selected,
                    onTap: _onSelect,
                    leading: _roundedIcon(
                      child: const Icon(Icons.account_balance_wallet_outlined,
                          color: Color(0xFF2E99E4)),
                    ),
                    title: 'Card',
                  ),
                  _PayTile(
                    id: 'wallet',
                    selectedId: _selected,
                    onTap: _onSelect,
                    leading: _roundedIcon(
                      child:
                          const Icon(Icons.local_offer_outlined, color: kPurple),
                    ),
                    title: 'Wallet Pay',
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: kPurple),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // handle select
                  },
                  child: const Text(
                    'SELECT',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 15,
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

  Widget _roundedIcon({required Widget child}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF0EDF7)),
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _PayTile extends StatelessWidget {
  const _PayTile({
    required this.id,
    required this.selectedId,
    required this.onTap,
    required this.leading,
    required this.title,
    this.trailing,
  });

  final String id;
  final String? selectedId;
  final void Function(String id) onTap;
  final Widget leading;
  final String title;
  final Widget? trailing;

  static const String kFont = 'Poppins';
  static const Color kPurple = Color(0xFF5C2D91);

  @override
  Widget build(BuildContext context) {
    final bool isSelected = id == selectedId;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onTap(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kPurple.withOpacity(.3) : Colors.transparent,
          ),
          color: isSelected ? const Color(0xFFF8F4FF) : Colors.white,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: kFont,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4C4C4C),
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing!,
            ] else ...[
              Container(
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isSelected ? kPurple : const Color(0xFFCDD1DA),
                      width: 1.8),
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
          ],
        ),
      ),
    );
  }
}
