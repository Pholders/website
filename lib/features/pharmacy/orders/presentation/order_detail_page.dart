import 'package:flutter/material.dart';

/// OrderDetailPage — placeholder until Figma design is implemented.
class OrderDetailPage extends StatelessWidget {

  const OrderDetailPage({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('OrderDetailPage')),
    );
  }
}
