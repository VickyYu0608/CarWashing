import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerServicePage extends StatefulWidget {
  const CustomerServicePage({super.key});

  @override
  State<CustomerServicePage> createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends State<CustomerServicePage> {
  final messageController = TextEditingController();

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.customerServiceTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const AppIconBadge(icon: Icons.phone_in_talk_outlined),
              title: Text(s.hqPhoneTitle),
              subtitle: Text(s.hqPhoneHours),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchUrl(Uri.parse('tel:4008886688')),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.onlineMessage, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(
            controller: messageController,
            maxLines: 4,
            decoration: InputDecoration(hintText: s.messageHint),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.messageSubmitted)),
              );
              messageController.clear();
            },
            child: Text(s.submitMessage),
          ),
        ],
      ),
    );
  }
}
