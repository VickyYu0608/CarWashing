import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('服务条款')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            '清洗到家服务条款',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          SizedBox(height: 12),
          Text(
            '1. 用户下单即表示同意平台服务规范与价格说明。\n'
            '2. 预约到店请按时到达，迟到可能影响服务安排。\n'
            '3. 自助洗车请按设备提示操作，违规使用造成的损坏由用户承担。\n'
            '4. 平台将在法律允许范围内处理退款与纠纷。',
            style: TextStyle(height: 1.6),
          ),
        ],
      ),
    );
  }
}
