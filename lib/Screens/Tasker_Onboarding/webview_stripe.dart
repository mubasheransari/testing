import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CheckoutWebView extends StatefulWidget {
  final String url;
  const CheckoutWebView({super.key, required this.url});

  @override
  State<CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<CheckoutWebView> {
  late final WebViewController _controller;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => loading = false),
          // OPTIONAL: handle redirect URLs your backend sets
          onNavigationRequest: (req) {
            if (req.url.contains('/success')) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            if (req.url.contains('/cancel')) {
              Navigator.pop(context, false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  //    appBar: AppBar(title: const Text('Checkout')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top:35.0),
            child: WebViewWidget(controller: _controller),
          ),
          if (loading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
