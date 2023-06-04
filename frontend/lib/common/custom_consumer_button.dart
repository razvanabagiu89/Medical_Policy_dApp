import '../metamask_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/gradient_button.dart';

class CustomConsumerButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String buttonText;

  const CustomConsumerButton({
    required this.onPressed,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MetaMaskProvider>(
      builder: (context, provider, child) {
        return Opacity(
          opacity: provider.isConnected ? 1 : 0.4,
          child: GradientButton(
            onPressed: provider.isConnected ? onPressed : () {},
            buttonText: buttonText,
          ),
        );
      },
    );
  }
}
