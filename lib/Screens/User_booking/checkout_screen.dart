import 'package:flutter/material.dart';
import 'package:taskoon/Screens/User_booking/service_inprogress_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const String kFont = 'Poppins';
  static const Color kBg = Color(0xFFF4F3FA);
  static const Color kPrimary = Color(0xFF5C2E91);
  static const Color kTextMuted = Color(0xFF837E96);
  static const Color kSuccess = Color(0xFF2F7D32);

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
          color: Color(0xFF9A95AD),
          fontSize: 13.5,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: kPrimary.withOpacity(.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: kPrimary.withOpacity(.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kPrimary, width: 1.3),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontFamily: kFont,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: kPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // amount card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: kPrimary.withOpacity(.02)),
                  borderRadius: BorderRadius.circular(16),
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
                  const  Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total payable',
                            style: TextStyle(
                              fontFamily: kFont,
                              fontSize: 12.5,
                              color: kTextMuted,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            '\$40.00',
                            style: TextStyle(
                              fontFamily: kFont,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: const [
                              Icon(Icons.verified_rounded,
                                  size: 17, color: kSuccess),
                              SizedBox(width: 5),
                              Text(
                                'Secured payment',
                                style: TextStyle(
                                  fontFamily: kFont,
                                  fontSize: 11.2,
                                  color: kPrimary,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    Container(
                      height: 68,
                      width: 72,
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child:const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Order',
                            style: TextStyle(
                              fontFamily: kFont,
                              fontSize: 11.5,
                              color: kTextMuted,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'TSK-8923',
                            style: TextStyle(
                              fontFamily: kFont,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Payment method',
                style: TextStyle(
                  fontFamily: kFont,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: kPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // method chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MethodChip(
                      active: _method == 0,
                      label: 'Card',
                      icon: Icons.credit_card_rounded,
                      onTap: () => setState(() => _method = 0),
                    ),
                    const SizedBox(width: 8),
                    _MethodChip.asset(
                      active: _method == 1,
                      label: 'Apple Pay',
                      asset: 'assets/apple_pay.png',
                      onTap: () => setState(() => _method = 1),
                    ),
                    const SizedBox(width: 8),
                    _MethodChip.asset(
                      active: _method == 2,
                      label: 'Google Pay',
                      asset: 'assets/google_pay_icon.jpg',
                      onTap: () => setState(() => _method = 2),
                    ),
                    const SizedBox(width: 8),
                    _MethodChip(
                      active: _method == 3,
                      label: 'Wallet',
                      icon: Icons.account_balance_wallet_rounded,
                      onTap: () => setState(() => _method = 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // form area
              if (_method == 0) _buildCardForm() else _buildSelectedInfo(),

              const SizedBox(height: 20),

              // pay button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _onPay,
                  child: const Text(
                    'PAY NOW',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 15,
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

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(.02)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.015),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _cardCtrl,
            keyboardType: TextInputType.number,
            decoration: _input('Card number'),
            style: const TextStyle(fontFamily: kFont),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: _input('Cardholder name'),
            style: const TextStyle(fontFamily: kFont),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cvvCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _input('CVV / CVC'),
                  style: const TextStyle(fontFamily: kFont),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _expCtrl,
                  keyboardType: TextInputType.datetime,
                  decoration: _input('MM / YY'),
                  style: const TextStyle(fontFamily: kFont),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Checkbox(
                visualDensity: VisualDensity.compact,
                value: _save,
                activeColor: kPrimary,
                onChanged: (v) => setState(() => _save = v ?? false),
              ),
              const Flexible(
                child: Text(
                  'Save this card for future payments',
                  style: TextStyle(
                    fontFamily: kFont,
                    fontSize: 12.5,
                    color: kTextMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedInfo() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kPrimary.withOpacity(.03)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.01),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
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
                fontSize: 13,
                color: Color(0xFF4A465B),
              ),
            ),
          ),
        ],
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

    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ServiceProgressScreen(totalMinutes: 3)));

  /*  ScaffoldMessenger.of(context).showSnackBar(
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
    );*/
  }
}

/* -------------------------- method chip (modern) -------------------------- */

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.active,
    required this.label,
    required this.onTap,
    this.icon,
  }) : asset = null;

  const _MethodChip.asset({
    required this.active,
    required this.label,
    required this.asset,
    required this.onTap,
  }) : icon = null;

  final bool active;
  final String label;
  final IconData? icon;
  final String? asset;
  final VoidCallback onTap;

  static const String kFont = 'Poppins';
  static const Color kPrimary = Color(0xFF5C2E91);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF0ECFF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? kPrimary : Colors.white,
            width: 1,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: kPrimary.withOpacity(.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, color: kPrimary, size: 18)
            else
              Image.asset(asset!, height: 19),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: kFont,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kPrimary,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle, size: 15, color: kPrimary),
            ],
          ],
        ),
      ),
    );
  }
}
