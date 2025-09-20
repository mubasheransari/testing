import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget child;
  final bool canPop;
  const AppScaffold({super.key, required this.child, this.title, this.canPop = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (title != null)
          ? AppBar(
              automaticallyImplyLeading: canPop,
              title: Text(title!, style: Theme.of(context).textTheme.titleMedium),
              centerTitle: true,
              surfaceTintColor: Colors.transparent,
              backgroundColor: Tokens.surface,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Tokens.s20),
          child: child,
        ),
      ),
    );
  }
}
