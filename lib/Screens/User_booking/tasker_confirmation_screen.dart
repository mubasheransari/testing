import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_bloc.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_event.dart';
import 'package:taskoon/Blocs/user_booking_bloc/user_booking_state.dart';
import 'package:flutter_stripe/flutter_stripe.dart';


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get_storage/get_storage.dart';

class TaskerConfirmationScreen extends StatefulWidget {
  final String name, distance, rating, cost, bookingDetailId;

  const TaskerConfirmationScreen({
    super.key,
    required this.name,
    required this.distance,
    required this.rating,
    required this.cost,
    required this.bookingDetailId,
  });

  @override
  State<TaskerConfirmationScreen> createState() =>
      _TaskerConfirmationScreenState();
}

class _TaskerConfirmationScreenState extends State<TaskerConfirmationScreen> {
  static const Color kPurple = Color(0xFF5C2E91);
  static const Color kPurpleDark = Color(0xFF3E1E69);
  static const Color kBg = Color(0xFFF5F3FB);
  static const Color kMuted = Color(0xFF75748A);
  static const String kFont = 'Poppins';

  final GetStorage _box = GetStorage();

  bool _isPresentingPaymentSheet = false;
  String? _lastHandledClientSecret;

  Future<void> _openStripePaymentSheet(String clientSecret) async {
    if (_isPresentingPaymentSheet) return;

    try {
      _isPresentingPaymentSheet = true;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Taskoon',
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful ✅')),
      );
    } on StripeException catch (e) {
      if (!mounted) return;

      final msg = e.error.localizedMessage ?? 'Payment cancelled';
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      _isPresentingPaymentSheet = false;
    }
  }

  void _startPayment() {
    if (_isPresentingPaymentSheet) return;

    context.read<UserBookingBloc>().add(
          CreatePaymentIntentRequested(
            bookingDetailId: widget.bookingDetailId,
          ),
        );
  }

  Future<void> _showCancelReasonDialog() async {
    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kPurple.withOpacity(.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Cancel Booking',
                          style: TextStyle(
                            fontFamily: kFont,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kPurpleDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please tell us why you want to cancel this booking.',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 13,
                      height: 1.35,
                      color: kMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 4,
                    minLines: 4,
                    style: const TextStyle(
                      fontFamily: kFont,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter cancellation reason',
                      hintStyle: TextStyle(
                        fontFamily: kFont,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F7FB),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: kPurple.withOpacity(.10)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: kPurple.withOpacity(.10)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: kPurple),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Cancellation reason is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Please enter a valid reason';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: kPurple.withOpacity(.15),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontFamily: kFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kPurpleDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState?.validate() != true) {
                                return;
                              }
                              Navigator.pop(
                                dialogContext,
                                reasonController.text.trim(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Confirm',
                              style: TextStyle(
                                fontFamily: kFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (reason == null || reason.trim().isEmpty) return;

    final storedUserId = _box.read('userId')?.toString() ?? '';
    if (storedUserId.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User id not found')),
      );
      return;
    }

    context.read<UserBookingBloc>().add(
          CancelBooking(
            userId: storedUserId,
            bookingDetailId: widget.bookingDetailId,
            reason: reason.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final int ratingValue = int.tryParse(widget.rating) ?? 0;

    return MultiBlocListener(
      listeners: [
        BlocListener<UserBookingBloc, UserBookingState>(
          listenWhen: (previous, current) =>
              previous.createPaymentIntentStatus !=
                  current.createPaymentIntentStatus ||
              previous.paymentIntentResponse != current.paymentIntentResponse ||
              previous.paymentIntentError != current.paymentIntentError,
          listener: (context, state) async {
            if (state.createPaymentIntentStatus ==
                CreatePaymentIntentStatus.failure) {
              final msg =
                  state.paymentIntentError ?? 'Failed to create payment intent';

              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg)),
              );
              return;
            }

            if (state.createPaymentIntentStatus ==
                CreatePaymentIntentStatus.success) {
              final clientSecret =
                  (state.paymentIntentResponse?.result?['clientSecret']
                              ?.toString()
                              .trim() ??
                          '');

              if (clientSecret.isEmpty) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Client secret not found')),
                );
                return;
              }

              if (_lastHandledClientSecret == clientSecret) return;
              _lastHandledClientSecret = clientSecret;

              await _openStripePaymentSheet(clientSecret);
            }
          },
        ),
        BlocListener<UserBookingBloc, UserBookingState>(
          listenWhen: (previous, current) =>
              previous.userBookingCancelStatus !=
              current.userBookingCancelStatus,
          listener: (context, state) {
            if (state.userBookingCancelStatus ==
                UserBookingCancelStatus.success) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking cancelled successfully')),
              );

              Navigator.of(context).pop(true);
            } else if (state.userBookingCancelStatus ==
                UserBookingCancelStatus.failure) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to cancel booking')),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFDA57),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/trained_cleaners.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Your tasker will arrive at your\nscheduled time',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: kFont,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                  color: kPurple,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      width: w * 0.9,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: kPurple.withOpacity(.07)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.03),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              fontFamily: kFont,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B1B1B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _divider(),
                          _rowLabelValue('Distance', "${widget.distance} miles"),
                          _divider(),
                          _rowLabelValue('Role', 'Pro, cleaner'),
                          _divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Row(
                                  children: [
                                    ...List.generate(5, (index) {
                                      final isFilled = index < ratingValue;
                                      return Icon(
                                        isFilled
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 18,
                                        color: isFilled
                                            ? const Color(0xFFFFB800)
                                            : Colors.grey.shade400,
                                      );
                                    }),
                                    const SizedBox(width: 8),
                                    Text(
                                      ratingValue == 0
                                          ? 'No rating yet'
                                          : ratingValue.toString(),
                                      style: TextStyle(
                                        fontFamily: kFont,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: ratingValue == 0
                                            ? Colors.grey.shade500
                                            : kPurple,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  widget.rating.toString(),
                                  style: const TextStyle(
                                    fontFamily: kFont,
                                    fontSize: 13,
                                    color: kPurple,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _divider(),
                          const SizedBox(height: 10),
                          const Text(
                            'Base cost',
                            style: TextStyle(
                              fontFamily: kFont,
                              fontSize: 12.5,
                              color: kMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'AUD ${widget.cost}',
                            style: const TextStyle(
                              fontFamily: kFont,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              BlocBuilder<UserBookingBloc, UserBookingState>(
                buildWhen: (previous, current) =>
                    previous.createPaymentIntentStatus !=
                    current.createPaymentIntentStatus,
                builder: (context, state) {
                  final isLoading = state.createPaymentIntentStatus ==
                      CreatePaymentIntentStatus.submitting;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPurpleDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isLoading ? null : _startPayment,
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'PROCEED TO PAYMENT',
                                style: TextStyle(
                                  fontFamily: kFont,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .4,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
              BlocBuilder<UserBookingBloc, UserBookingState>(
                buildWhen: (previous, current) =>
                    previous.userBookingCancelStatus !=
                    current.userBookingCancelStatus,
                builder: (context, state) {
                  final isCancelling = state.userBookingCancelStatus ==
                      UserBookingCancelStatus.submitting;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isCancelling ? null : _showCancelReasonDialog,
                        child: isCancelling
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'CANCEL BOOKING',
                                style: TextStyle(
                                  fontFamily: kFont,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .4,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowLabelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: kFont,
              fontSize: 13.5,
              color: kMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: kFont,
              fontSize: 13.8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101010),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 18,
        color: kPurple.withOpacity(.10),
        thickness: 1,
      );
}

/*
class TaskerConfirmationScreen extends StatefulWidget {
  final String name, distance, rating, cost, bookingDetailId;

  const TaskerConfirmationScreen({
    super.key,
    required this.name,
    required this.distance,
    required this.rating,
    required this.cost,
    required this.bookingDetailId,
  });

  @override
  State<TaskerConfirmationScreen> createState() =>
      _TaskerConfirmationScreenState();
}

class _TaskerConfirmationScreenState extends State<TaskerConfirmationScreen> {
  static const Color kPurple = Color(0xFF5C2E91);
  static const Color kPurpleDark = Color(0xFF3E1E69);
  static const Color kBg = Color(0xFFF5F3FB);
  static const Color kMuted = Color(0xFF75748A);
  static const String kFont = 'Poppins';

  bool _isPresentingPaymentSheet = false;
  String? _lastHandledClientSecret;

  Future<void> _openStripePaymentSheet(String clientSecret) async {
    if (_isPresentingPaymentSheet) return;

    try {
      _isPresentingPaymentSheet = true;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Taskoon',
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Successful ✅')),
      );
    } on StripeException catch (e) {
      if (!mounted) return;

      final msg = e.error.localizedMessage ?? 'Payment cancelled';
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      _isPresentingPaymentSheet = false;
    }
  }

  void _startPayment() {
    if (_isPresentingPaymentSheet) return;

    context.read<UserBookingBloc>().add(
          CreatePaymentIntentRequested(
            bookingDetailId: widget.bookingDetailId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final int ratingValue = int.tryParse(widget.rating) ?? 0;

    return BlocListener<UserBookingBloc, UserBookingState>(
      listenWhen: (previous, current) =>
          previous.createPaymentIntentStatus != current.createPaymentIntentStatus ||
          previous.paymentIntentResponse != current.paymentIntentResponse ||
          previous.paymentIntentError != current.paymentIntentError,
      listener: (context, state) async {
        if (state.createPaymentIntentStatus == CreatePaymentIntentStatus.failure) {
          final msg = state.paymentIntentError ?? 'Failed to create payment intent';

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          return;
        }

        if (state.createPaymentIntentStatus == CreatePaymentIntentStatus.success) {
          final clientSecret =
              (state.paymentIntentResponse?.result?['clientSecret']
                          ?.toString()
                          .trim() ??
                      '');

          if (clientSecret.isEmpty) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Client secret not found')),
            );
            return;
          }

          if (_lastHandledClientSecret == clientSecret) return;
          _lastHandledClientSecret = clientSecret;

          await _openStripePaymentSheet(clientSecret);
        }
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 14),

              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFDA57),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/trained_cleaners.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Your tasker will arrive at your\nscheduled time',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: kFont,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                  color: kPurple,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      width: w * 0.9,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: kPurple.withOpacity(.07)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.03),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              fontFamily: kFont,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B1B1B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _divider(),

                          _rowLabelValue('Distance', "${widget.distance} miles"),
                          _divider(),

                          _rowLabelValue('Role', 'Pro, cleaner'),
                          _divider(),

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Row(
                                  children: [
                                    ...List.generate(5, (index) {
                                      final isFilled = index < ratingValue;
                                      return Icon(
                                        isFilled
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 18,
                                        color: isFilled
                                            ? const Color(0xFFFFB800)
                                            : Colors.grey.shade400,
                                      );
                                    }),
                                    const SizedBox(width: 8),
                                    Text(
                                      ratingValue == 0
                                          ? 'No rating yet'
                                          : ratingValue.toString(),
                                      style: TextStyle(
                                        fontFamily: kFont,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: ratingValue == 0
                                            ? Colors.grey.shade500
                                            : kPurple,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  widget.rating.toString(),
                                  style: const TextStyle(
                                    fontFamily: kFont,
                                    fontSize: 13,
                                    color: kPurple,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _divider(),
                          const SizedBox(height: 10),

                          const Text(
                            'Base cost',
                            style: TextStyle(
                              fontFamily: kFont,
                              fontSize: 12.5,
                              color: kMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'AUD ${widget.cost}',
                            style: const TextStyle(
                              fontFamily: kFont,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              BlocBuilder<UserBookingBloc, UserBookingState>(
                buildWhen: (previous, current) =>
                    previous.createPaymentIntentStatus != current.createPaymentIntentStatus,
                builder: (context, state) {
                  final isLoading =
                      state.createPaymentIntentStatus == CreatePaymentIntentStatus.submitting;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPurpleDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isLoading ? null : _startPayment,
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'PROCEED TO PAYMENT',
                                style: TextStyle(
                                  fontFamily: kFont,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .4,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'CANCEL BOOKING',
                      style: TextStyle(
                        fontFamily: kFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .4,
                        color: Colors.white,
                      ),
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

  Widget _rowLabelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: kFont,
              fontSize: 13.5,
              color: kMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: kFont,
              fontSize: 13.8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101010),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 18,
        color: kPurple.withOpacity(.10),
        thickness: 1,
      );
}
*/




































// class TaskerConfirmationScreen extends StatefulWidget {
//   final String name, distance, rating, cost, bookingDetailId;

//   const TaskerConfirmationScreen({
//     super.key,
//     required this.name,
//     required this.distance,
//     required this.rating,
//     required this.cost,
//     required this.bookingDetailId,
//   });

//   @override
//   State<TaskerConfirmationScreen> createState() =>
//       _TaskerConfirmationScreenState();
// }

// class _TaskerConfirmationScreenState extends State<TaskerConfirmationScreen> {
//   // Theme taken from UserBookingHome
//   static const Color kPurple = Color(0xFF5C2E91);
//   static const Color kPurpleDark = Color(0xFF3E1E69);
//   static const Color kBg = Color(0xFFF5F3FB);
//   static const Color kMuted = Color(0xFF75748A);
//   static const Color kGreen = Color(0xFF3DB38D);
//   static const String kFont = 'Poppins';

//   bool _isPresentingPaymentSheet = false;
//   String? _lastHandledClientSecret;

//   Future<void> _openStripePaymentSheet(String clientSecret) async {
//     if (_isPresentingPaymentSheet) return;

//     try {
//       _isPresentingPaymentSheet = true;

//       await Stripe.instance.initPaymentSheet(
//         paymentSheetParameters: SetupPaymentSheetParameters(
//           paymentIntentClientSecret: clientSecret,
//           merchantDisplayName: 'Taskoon',
//           style: ThemeMode.system,
//         ),
//       );

//       await Stripe.instance.presentPaymentSheet();

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Payment Successful ✅'),
//         ),
//       );

//       // optional success navigation
//       // Navigator.of(context).pushReplacement(
//       //   MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
//       // );
//     } on StripeException catch (e) {
//       if (!mounted) return;

//       final msg = e.error.localizedMessage ?? 'Payment cancelled';
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(msg)),
//       );
//     } catch (e) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(e.toString())),
//       );
//     } finally {
//       _isPresentingPaymentSheet = false;
//     }
//   }

//   void _startPayment() {
//     if (_isPresentingPaymentSheet) return;

//     context.read<UserBookingBloc>().add(
//           CreatePaymentIntentRequested(
//             bookingDetailId: widget.bookingDetailId,
//           ),
//         );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.of(context).size.width;
//     final int ratingValue = int.tryParse(widget.rating) ?? 0;

//     return BlocListener<UserBookingBloc, UserBookingState>(
//       listenWhen: (previous, current) =>
//           previous.createPaymentIntentStatus != current.createPaymentIntentStatus ||
//           previous.paymentIntentResponse != current.paymentIntentResponse ||
//           previous.paymentIntentError != current.paymentIntentError,
//       listener: (context, state) async {
//         if (state.createPaymentIntentStatus == CreatePaymentIntentStatus.failure) {
//           final msg = state.paymentIntentError ?? 'Failed to create payment intent';

//           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(msg)),
//           );
//           return;
//         }

//         if (state.createPaymentIntentStatus == CreatePaymentIntentStatus.success) {
//           final clientSecret =
//               state.paymentIntentResponse?.result?.clientSecret?.trim() ?? '';

//           if (clientSecret.isEmpty) {
//             ScaffoldMessenger.of(context).hideCurrentSnackBar();
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('Client secret not found')),
//             );
//             return;
//           }

//           if (_lastHandledClientSecret == clientSecret) return;
//           _lastHandledClientSecret = clientSecret;

//           await _openStripePaymentSheet(clientSecret);
//         }
//       },
//       child: Scaffold(
//         backgroundColor: kBg,
//         body: SafeArea(
//           child: Column(
//             children: [
//               const SizedBox(height: 14),

//               Container(
//                 width: 118,
//                 height: 118,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFFFFDA57),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(.06),
//                       blurRadius: 14,
//                       offset: const Offset(0, 8),
//                     ),
//                   ],
//                 ),
//                 child: ClipOval(
//                   child: Image.asset(
//                     'assets/trained_cleaners.png',
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 18),

//               const Text(
//                 'Your tasker will arrive at your\nscheduled time',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontFamily: kFont,
//                   fontSize: 16.5,
//                   fontWeight: FontWeight.w600,
//                   color: kPurple,
//                   height: 1.25,
//                 ),
//               ),

//               const SizedBox(height: 18),

//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Center(
//                     child: Container(
//                       width: w * 0.9,
//                       padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(18),
//                         border: Border.all(color: kPurple.withOpacity(.07)),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(.03),
//                             blurRadius: 18,
//                             offset: const Offset(0, 10),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.name,
//                             style: const TextStyle(
//                               fontFamily: kFont,
//                               fontSize: 18,
//                               fontWeight: FontWeight.w800,
//                               color: Color(0xFF1B1B1B),
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           _divider(),

//                           _rowLabelValue('Distance', "${widget.distance} miles"),
//                           _divider(),

//                           _rowLabelValue('Role', 'Pro, cleaner'),
//                           _divider(),

//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 10),
//                             child: Row(
//                               children: [
//                                 Row(
//                                   children: [
//                                     ...List.generate(5, (index) {
//                                       final isFilled = index < ratingValue;
//                                       return Icon(
//                                         isFilled
//                                             ? Icons.star_rounded
//                                             : Icons.star_border_rounded,
//                                         size: 18,
//                                         color: isFilled
//                                             ? const Color(0xFFFFB800)
//                                             : Colors.grey.shade400,
//                                       );
//                                     }),
//                                     const SizedBox(width: 8),
//                                     Text(
//                                       ratingValue == 0
//                                           ? 'No rating yet'
//                                           : ratingValue.toString(),
//                                       style: TextStyle(
//                                         fontFamily: kFont,
//                                         fontSize: 13,
//                                         fontWeight: FontWeight.w700,
//                                         color: ratingValue == 0
//                                             ? Colors.grey.shade500
//                                             : kPurple,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const Spacer(),
//                                 Text(
//                                   widget.rating.toString(),
//                                   style: const TextStyle(
//                                     fontFamily: kFont,
//                                     fontSize: 13,
//                                     color: kPurple,
//                                     fontWeight: FontWeight.w700,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),

//                           _divider(),
//                           const SizedBox(height: 10),

//                           const Text(
//                             'Base cost',
//                             style: TextStyle(
//                               fontFamily: kFont,
//                               fontSize: 12.5,
//                               color: kMuted,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             'AUD ${widget.cost}',
//                             style: const TextStyle(
//                               fontFamily: kFont,
//                               fontSize: 18,
//                               fontWeight: FontWeight.w800,
//                               color: kPurple,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),

//               BlocBuilder<UserBookingBloc, UserBookingState>(
//                 buildWhen: (previous, current) =>
//                     previous.createPaymentIntentStatus != current.createPaymentIntentStatus,
//                 builder: (context, state) {
//                   final isLoading =
//                       state.createPaymentIntentStatus == CreatePaymentIntentStatus.submitting;

//                   return Padding(
//                     padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
//                     child: SizedBox(
//                       width: double.infinity,
//                       height: 54,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: kPurpleDark,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           elevation: 0,
//                         ),
//                         onPressed: isLoading ? null : _startPayment,
//                         child: isLoading
//                             ? const SizedBox(
//                                 width: 22,
//                                 height: 22,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2.2,
//                                   color: Colors.white,
//                                 ),
//                               )
//                             : const Text(
//                                 'PROCEED TO PAYMENT',
//                                 style: TextStyle(
//                                   fontFamily: kFont,
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w700,
//                                   letterSpacing: .4,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                       ),
//                     ),
//                   );
//                 },
//               ),

//               Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
//                 child: SizedBox(
//                   width: double.infinity,
//                   height: 54,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       elevation: 0,
//                     ),
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                     child: const Text(
//                       'CANCEL BOOKING',
//                       style: TextStyle(
//                         fontFamily: kFont,
//                         fontSize: 15,
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: .4,
//                         color: Colors.white,
//                       ),
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

//   Widget _rowLabelValue(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Row(
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontFamily: kFont,
//               fontSize: 13.5,
//               color: kMuted,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const Spacer(),
//           Text(
//             value,
//             style: const TextStyle(
//               fontFamily: kFont,
//               fontSize: 13.8,
//               fontWeight: FontWeight.w700,
//               color: Color(0xFF101010),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _divider() => Divider(
//         height: 18,
//         color: kPurple.withOpacity(.10),
//         thickness: 1,
//       );
// }
/*
class TaskerConfirmationScreen extends StatelessWidget {
  final String name, distance, rating, cost,bookingDetailId;

  TaskerConfirmationScreen({
    super.key,
    required this.name,
    required this.distance,
    required this.rating,
    required this.cost,
    required this.bookingDetailId
  });

  // Theme taken from UserBookingHome
  static const Color kPurple = Color(0xFF5C2E91);
  static const Color kPurpleDark = Color(0xFF3E1E69);
  static const Color kBg = Color(0xFFF5F3FB);
  static const Color kMuted = Color(0xFF75748A);
  static const Color kGreen = Color(0xFF3DB38D);
  static const String kFont = 'Poppins';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final int ratingValue = int.tryParse(rating) ?? 0;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // top bar (same theme as UserBookingHome)
         /*   Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.arrow_back, color: kPurple),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tasker Assigned',
                      style: TextStyle(
                        fontFamily: kFont,
                        fontSize: 18,
                        color: kPurpleDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),*/

            const SizedBox(height: 14),

            // avatar + title (kept same content, updated styling)
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFDA57),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/trained_cleaners.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Your tasker will arrive at your\nscheduled time',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kFont,
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                color: kPurple,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 18),

            // card (theme like UserBookingHome)
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    width: w * 0.9,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kPurple.withOpacity(.07)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.03),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // name
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: kFont,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B1B1B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _divider(),

                        _rowLabelValue('Distance', "$distance miles"),
                        _divider(),

                        _rowLabelValue('Role', 'Pro, cleaner'),
                        _divider(),

                        // rating row
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Row(
                                children: [
                                  ...List.generate(5, (index) {
                                    final isFilled = index < ratingValue;
                                    return Icon(
                                      isFilled
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      size: 18,
                                      color: isFilled
                                          ? const Color(0xFFFFB800)
                                          : Colors.grey.shade400,
                                    );
                                  }),
                                  const SizedBox(width: 8),
                                  Text(
                                    ratingValue == 0
                                        ? 'No rating yet'
                                        : ratingValue.toString(),
                                    style: TextStyle(
                                      fontFamily: kFont,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: ratingValue == 0
                                          ? Colors.grey.shade500
                                          : kPurple,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                rating.toString(),
                                style: const TextStyle(
                                  fontFamily: kFont,
                                  fontSize: 13,
                                  color: kPurple,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        _divider(),
                        const SizedBox(height: 10),

                        // base cost (same content, themed)
                        const Text(
                          'Base cost',
                          style: TextStyle(
                            fontFamily: kFont,
                            fontSize: 12.5,
                            color: kMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'AUD $cost',
                          style: const TextStyle(
                            fontFamily: kFont,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: kPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // button (theme like home green button style)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurpleDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    context.read<UserBookingBloc>().add(
  CreatePaymentIntentRequested(
    bookingDetailId: bookingDetailId
  ),
);

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const PaymentMethodScreen(),
                      ),
                    );
                  },
                  child:  Text(
                    'PROCEED TO PAYMENT',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
             Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const PaymentMethodScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'CANCEL BOOKING',
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
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

  Widget _rowLabelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: kFont,
              fontSize: 13.5,
              color: kMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: kFont,
              fontSize: 13.8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101010),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 18,
        color: kPurple.withOpacity(.10),
        thickness: 1,
      );
}
*/


// class TaskerConfirmationScreen extends StatelessWidget {
//   String name, distance,rating,cost;
//    TaskerConfirmationScreen({super.key,required this.name,required this.distance,required this.rating,required this.cost});

//   static const Color kPurple = Color(0xFF5C2D91);
//   static const Color kGreen = Color(0xFF2F7D32);
//   static const String kFont = 'Poppins'; // make sure added in pubspec.yaml

//   @override
//   Widget build(BuildContext context) {
//     final w = MediaQuery.of(context).size.width;
// final int ratingValue = int.tryParse(rating) ?? 0;
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F3FB),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // top bar
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back, color: kPurple),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   const SizedBox(width: 4),
//                 const  Text(
//                     'Tasker assigned',
//                 style: TextStyle(
//                 fontFamily: 'Poppins',
//             fontSize: 22,
//             color: Color(0xFF4A2C73),
//             fontWeight: FontWeight.w500,
//           ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 12),
//             // avatar + title
//             Container(
//               width: 130,
//               height: 130,
//               decoration: const BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Color(0xFFFFDA57),
//               ),
//               child: ClipOval(
//                 child: Image.asset(
//                   'assets/trained_cleaners.png', // replace with your asset
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//         const    Text(
//               'Your tasker will arrive at your\nscheduled time',
//               textAlign: TextAlign.center,
//               style:  TextStyle(
//                 fontFamily: kFont,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500,
//                 color: kPurple,
//                 height: 1.3,
//               ),
//             ),
//             const SizedBox(height: 20),

//             // card
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Center(
//                   child: Container(
//                     width: w * 0.9,
//                     padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(.04),
//                           blurRadius: 16,
//                           offset: const Offset(0, 6),
//                         )
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // name
//                         Text(
//                          name,
//                           style: const TextStyle(
//                             fontFamily: kFont,
//                             fontSize: 20,
//                             fontWeight: FontWeight.w700,
//                             color: Color(0xFF1B1B1B),
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         _divider(),
//                         _rowLabelValue('Distance', "${distance} miles"),
//                         _divider(),
//                         _rowLabelValue('Role', 'Pro, cleaner'),
//                         _divider(),
//                         Row(
//                           children: [
//                             Row(
//   children: [
//     ...List.generate(5, (index) {
//       final isFilled = index < ratingValue;
//       return Icon(
//         isFilled ? Icons.star_rounded : Icons.star_border_rounded,
//         size: 18,
//         color: isFilled
//             ? const Color(0xFFFFB800)
//             : Colors.grey.shade400,
//       );
//     }),
//     const SizedBox(width: 6),
//     Text(
//       ratingValue == 0 ? 'No rating yet' : ratingValue.toString(),
//       style: TextStyle(
//         fontFamily: 'Poppins',
//         fontSize: 13,
//         fontWeight: FontWeight.w600,
//         color: ratingValue == 0
//             ? Colors.grey.shade500
//             : const Color(0xFF5C2D91),
//       ),
//     ),
//   ],
// ),


// // Row(
// //   children: List.generate(5, (index) {
// //     final isFilled = index < ratingValue;

// //     return Icon(
// //       isFilled ? Icons.star_rounded : Icons.star_border_rounded,
// //       color: isFilled ? const Color(0xFFFFB800) : Colors.grey.shade400,
// //       size: 20,
// //     );
// //   }),
// // ),
// //                           //   ...List.generate(
//                           //  int.parse(rating),
//                           //     (i) => const Icon(
//                           //       Icons.star_rounded,
//                           //       color: Color(0xFFFFB800),
//                           //       size: 20,
//                           //     ),
//                           //   ),
//                             const SizedBox(width: 6),
//                              Text(
//                               rating.toString(),
//                               style: const TextStyle(
//                                 fontFamily: kFont,
//                                 fontSize: 13,
//                                 color: kPurple,
//                               ),
//                             )
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         _divider(),
//                         const SizedBox(height: 10),
//                         const Text(
//                           'Base cost',
//                           style: TextStyle(
//                             fontFamily: kFont,
//                             fontSize: 12.5,
//                             color: Colors.grey,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                          Text(
//                           'AUD $cost',
//                           style:const TextStyle(
//                             fontFamily: kFont,
//                             fontSize: 17,
//                             fontWeight: FontWeight.w700,
//                             color: kPurple,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//             // button
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
//                      Navigator.of(context).pushReplacement(
//         MaterialPageRoute(
//           builder: (_) => const PaymentMethodScreen(), // <- your real screen
//         ),
//       );
//                   },
//                   child: const Text(
//                     'PROCEED TO PAYMENT',
//                     style: TextStyle(
//                       fontFamily: kFont,
//                       fontSize: 15.5,
//                       fontWeight: FontWeight.w600,
//                       letterSpacing: .4,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _rowLabelValue(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Row(
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontFamily: kFont,
//               fontSize: 13.5,
//               color: Color(0xFF707070),
//             ),
//           ),
//           const Spacer(),
//           Text(
//             value,
//             style: const TextStyle(
//               fontFamily: kFont,
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF101010),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _divider() => const Divider(
//         height: 18,
//         color: Color(0xFFECE9F5),
//         thickness: 1,
//       );
// }
