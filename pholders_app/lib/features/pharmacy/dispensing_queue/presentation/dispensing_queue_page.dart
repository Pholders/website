import 'package:flutter/material.dart';

import '../../orders/presentation/orders_page.dart';

class DispensingQueuePage extends StatelessWidget {
  const DispensingQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PharmacyOrderListPage(
      title: 'Dispensing Queue',
      initialStatus: 'preparing',
    );
  }
}
