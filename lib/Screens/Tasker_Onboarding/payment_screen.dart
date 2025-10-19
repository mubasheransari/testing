import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_bloc.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_event.dart';
import 'package:taskoon/Blocs/auth_bloc/auth_state.dart';
import 'package:taskoon/Screens/Tasker_Onboarding/paymennt_success.dart';
import 'package:taskoon/Screens/Tasker_Onboarding/webview_stripe.dart';

import '../../Constants/constants.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const purple = Color(0xFF7841BA);
  static const bg = Color(0xFFF9F7FF);
  static const cardBorder = Color(0xFFEFEFF6);
  static const fieldFill = Color(0xFFF6F7FA);

  // fake pricing
  final double certification = 0;
  final double processing = 33;

  int method = 0; // 0: card, 1: paypal, 2: bank
  final nameCtrl = TextEditingController(text: 'John Doe');
  final numberCtrl = TextEditingController(text: '1234 5678 9012 3456');
  final expCtrl = TextEditingController(text: 'MM/YY');
  final cvvCtrl = TextEditingController(text: '123');

  @override
  void dispose() {
    nameCtrl.dispose();
    numberCtrl.dispose();
    expCtrl.dispose();
    cvvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = certification + processing;

    const currentStep = 5;
    const totalSteps = 7;
    final progress = currentStep / totalSteps;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 130,
        automaticallyImplyLeading: false,
        elevation: 0,
        // surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text('Tasker Onboarding',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black54)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text('$currentStep/$totalSteps',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.black54)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey,
                    valueColor: const AlwaysStoppedAnimation(Constants.purple),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Progress',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black54)),
                    const Spacer(),
                    Text('${(progress * 100).round()}% complete',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.black54)),
                  ],
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(right: 14.0, left: 14.0, top: 10),
                  child: Text(
                      "Complete your certification payment to proceed with the onboarding process.",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.black54)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
         ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 200),
            children: [
              _OrderSummaryCard(
                certification: certification,
                processing: processing,
                total: total,
              ),
              const SizedBox(height: 16),
              // _PaymentMethodCard(
              //   method: method,
              //   onChanged: (v) => setState(() => method = v),
              // ),
              // const SizedBox(height: 12),

              // // Cardholder form (matches your soft white section)
              // Container(
              //   padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     border: Border.all(color: cardBorder),
              //     borderRadius: BorderRadius.circular(16),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       _label('Cardholder Name'),
              //       const SizedBox(height: 8),
              //       _Field(controller: nameCtrl),
              //       const SizedBox(height: 16),
              //       _label('Card Number'),
              //       const SizedBox(height: 8),
              //       _Field(
              //           controller: numberCtrl,
              //           keyboardType: TextInputType.number),
              //       const SizedBox(height: 16),
              //       Row(
              //         children: [
              //           Expanded(
              //             child: Column(
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 _label('Expiry Date'),
              //                 const SizedBox(height: 8),
              //                 _Field(controller: expCtrl, hint: 'MM/YY'),
              //               ],
              //             ),
              //           ),
              //           const SizedBox(width: 16),
              //           Expanded(
              //             child: Column(
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 _label('CVV'),
              //                 const SizedBox(height: 8),
              //                 _Field(
              //                     controller: cvvCtrl,
              //                     keyboardType: TextInputType.number),
              //               ],
              //             ),
              //           ),
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),

          Align(
  alignment: Alignment.bottomCenter,
  child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
    listenWhen: (prev, curr) => prev.paymentStatus != curr.paymentStatus,
    listener: (context, state) {
      if (state.paymentStatus == PaymentStatus.urlReady &&
          state.paymentSessionUrl != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CheckoutWebView(url: state.paymentSessionUrl!),
          ),
        );
      } else if (state.paymentStatus == PaymentStatus.failure &&
                 state.paymentError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.paymentError!)),
        );
      }
    },
    builder: (context, state) {
      final loading = state.paymentStatus == PaymentStatus.loading;

      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 20,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: purple, // your existing color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: loading
                  ? null
                  : () {
                    
                                    final box = GetStorage();
      final savedUserId = box.read<String>('userId');
                      context.read<AuthenticationBloc>().add(
                            CreatePaymentSessionRequested(
                              userId:savedUserId.toString(),
                              amount: total, // <-- your total as num/double
                              paymentMethod: 'stripe',
                            ),
                          );
                    },
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Pay \$${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .2,
                      ),
                    ),
            ),
          ),
        ),
      );
    },
  ),
),

          // Sticky bottom Pay button
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: Container(
          //     decoration: const BoxDecoration(
          //       color: Colors.white,
          //       boxShadow: [
          //         BoxShadow(
          //           color: Color(0x1A000000),
          //           blurRadius: 20,
          //           offset: Offset(0, -6),
          //         ),
          //       ],
          //     ),
          //     child: SafeArea(
          //       top: false,
          //       minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          //       child: SizedBox(
          //         height: 56,
          //         width: double.infinity,
          //         child: ElevatedButton(
          //           style: ElevatedButton.styleFrom(
          //             elevation: 0,
          //             backgroundColor: purple,
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(12),
          //             ),
          //           ),
          //           onPressed: () {
          //             Navigator.push(
          //                 context,
          //                 MaterialPageRoute(
          //                     builder: (context) => PaymentSuccessScreen()));
          //           },
          //           child: Text(
          //             'Pay \$${total.toStringAsFixed(0)}',
          //             style: const TextStyle(
          //               color: Colors.white,
          //               fontWeight: FontWeight.w700,
          //               letterSpacing: .2,
          //             ),
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _label(String s) => Text(
        s,
        style: const TextStyle(fontWeight: FontWeight.w700),
      );
}

/* ----------------- Order Summary ----------------- */

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.certification,
    required this.processing,
    required this.total,
  });

  final double certification;
  final double processing;
  final double total;

  static const cardBorder = Color(0xFFEFEFF6);

  @override
  Widget build(BuildContext context) {
    final line = Divider(height: 1, color: Colors.black.withOpacity(.06));
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _row(
            'Certification',
            '\$${certification.toStringAsFixed(0)}',
            sub: 'Includes training materials and certification exam',
          ),
          line,
          _row('Processing Fee', '\$${processing.toStringAsFixed(0)}'),
          line,
          _row('Total', '\$${total.toStringAsFixed(0)}', bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {String? sub, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    )),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      sub,
                      style: TextStyle(color: Colors.black.withOpacity(.55)),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------- Payment Method Card --------------- */

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.onChanged,
  });

  final int method;
  final ValueChanged<int> onChanged;

  static const cardBorder = Color(0xFFEFEFF6);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Method',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _MethodRow(
            selected: method == 0,
            icon: CupertinoIcons.creditcard,
            label: 'Credit/Debit Card',
            trailingBadge: 'Recommended',
            onTap: () => onChanged(0),
          ),
          _MethodRow(
            selected: method == 1,
            icon: CupertinoIcons.money_dollar_circle,
            label: 'PayPal',
            onTap: () => onChanged(1),
          ),
          _MethodRow(
            selected: method == 2,
            icon: CupertinoIcons.building_2_fill,
            label: 'Bank Transfer',
            onTap: () => onChanged(2),
          ),
        ],
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingBadge,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailingBadge;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: const Color(0xFFEAEAF2));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: border,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _RadioDot(selected: selected),
              const SizedBox(width: 12),
              Icon(icon, size: 20, color: const Color(0xFF2D2D2D)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              if (trailingBadge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trailingBadge!,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF7841BA) : const Color(0xFFE0DAF8),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF7841BA),
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

/* ----------------- Form Field ----------------- */

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF6F7FA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE6E8EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE6E8EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBFC6D5)),
        ),
      ),
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }
}
