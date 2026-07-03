import 'package:car_washing_app/app_theme.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('联系客服')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const AppIconBadge(icon: Icons.phone_in_talk_outlined),
              title: const Text('总部客服电话'),
              subtitle: const Text('400-888-6688 · 9:00–21:00'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchUrl(Uri.parse('tel:4008886688')),
            ),
          ),
          const SizedBox(height: 16),
          const Text('在线留言', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(
            controller: messageController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '请描述您的问题，客服将尽快回复',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('留言已提交，客服会尽快联系您')),
              );
              messageController.clear();
            },
            child: const Text('提交留言'),
          ),
        ],
      ),
    );
  }
}
