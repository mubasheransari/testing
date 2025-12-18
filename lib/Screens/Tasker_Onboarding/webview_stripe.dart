import 'package:flutter/material.dart';
import 'package:taskoon/Screens/Tasker_Onboarding/paymennt_success.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutWebView extends StatefulWidget {
  final String url;
  final bool Function(Uri uri)? isSuccessUrl;
  final bool Function(Uri uri)? isCancelUrl;

  const CheckoutWebView({
    super.key,
    required this.url,
    this.isSuccessUrl,
    this.isCancelUrl,
  });

  @override
  State<CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<CheckoutWebView> {
  late final WebViewController _controller;
  bool loading = true;

  bool _defaultIsSuccess(Uri uri) {
    final isHostOk = uri.host == '192.3.3.187';
    final lastSeg = uri.pathSegments.isNotEmpty ? uri.pathSegments.last.toLowerCase() : '';
    final isSuccessPage = lastSeg == 'payment-success.html';
    final hasSessionId = (uri.queryParameters['session_id'] ?? '').isNotEmpty;
    return isHostOk && isSuccessPage && hasSessionId;
  }

  bool _defaultIsCancel(Uri uri) {
    if (uri.host == '192.3.3.187') {
      final lastSeg = uri.pathSegments.isNotEmpty ? uri.pathSegments.last.toLowerCase() : '';
      if (lastSeg == 'payment-cancel.html') return true;
    }
    if (uri.path.toLowerCase().contains('/cancel')) return true;
    if (uri.queryParameters['canceled'] == '1') return true;
    return false;
  }

  bool _isExternalScheme(Uri uri) {
    const external = {
      'mailto','tel','sms','intent','geo','maps','upi','whatsapp',
      'facebook','twitter','instagram'
    };
    return external.contains(uri.scheme);
  }

  Future<NavigationDecision> _handleNav(String url) async {
    Uri uri;
    try { uri = Uri.parse(url); } catch (_) { return NavigationDecision.navigate; }

    final isSuccess = (widget.isSuccessUrl ?? _defaultIsSuccess)(uri);
    final isCancel  = (widget.isCancelUrl ?? _defaultIsCancel)(uri);

    if (isSuccess) {
      final sessionId = uri.queryParameters['session_id'];
      // ⬇️ navigate to success screen from here
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PaymentSuccessScreen() //PaymentSuccessScreen(sessionId: sessionId)
          ),
        );
      }
      return NavigationDecision.prevent;
    }

    if (isCancel) {
      if (mounted) Navigator.pop(context, {'ok': false});
      return NavigationDecision.prevent;
    }

    if (_isExternalScheme(uri)) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return NavigationDecision.prevent;
      }
    }

    return NavigationDecision.navigate;
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => loading = true);
            _handleNav(url);
          },
          onPageFinished: (_) => setState(() => loading = false),
          onNavigationRequest: (req) => _handleNav(req.url),
          onWebResourceError: (err) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Load error: ${err.errorCode} ${err.description}')),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const SizedBox(height: 35),
          Padding(
            padding: const EdgeInsets.only(top: 35.0),
            child: WebViewWidget(controller: _controller),
          ),
          if (loading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

