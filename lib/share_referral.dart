import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShareReferralPanel extends StatelessWidget {
  const ShareReferralPanel({
    required this.shareCode,
    required this.canShare,
    required this.freeWashCredits,
    super.key,
  });

  final String shareCode;
  final bool canShare;
  final int freeWashCredits;

  @override
  Widget build(BuildContext context) {
    if (!canShare) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.card_giftcard,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    '分享有礼',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '完成首次洗车后，即可分享专属邀请码给好友。您和好友各获得 1 次免费洗车机会。',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              if (freeWashCredits > 0) ...[
                const SizedBox(height: 8),
                Text('当前免费洗车次数：$freeWashCredits'),
              ],
            ],
          ),
        ),
      );
    }

    final message =
        '我在「清洗到家」洗过车了，邀请你一起来！注册时填写我的分享码 $shareCode，我们各得 1 次免费洗车。';

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.share,
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  '分享给好友',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '您的分享码：$shareCode',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '好友注册或在我的页面填写分享码后，双方各得 1 次免费洗车。',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            if (freeWashCredits > 0) ...[
              const SizedBox(height: 6),
              Text('当前可用免费洗车：$freeWashCredits 次'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: shareCode));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('分享码已复制')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('复制分享码'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: message));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('分享文案已复制，可粘贴给好友')),
                      );
                    }
                  },
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('复制分享文案'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReferralProfileSection extends StatefulWidget {
  const ReferralProfileSection({
    required this.shareCode,
    required this.freeWashCredits,
    required this.freeWashUsedCount,
    required this.referralSuccessCount,
    required this.canShare,
    required this.referredByName,
    required this.referredUsers,
    required this.canRedeemCode,
    required this.onRedeemCode,
    super.key,
  });

  final String shareCode;
  final int freeWashCredits;
  final int freeWashUsedCount;
  final int referralSuccessCount;
  final bool canShare;
  final String? referredByName;
  final List<String> referredUsers;
  final bool canRedeemCode;
  final Future<void> Function(String code) onRedeemCode;

  @override
  State<ReferralProfileSection> createState() => _ReferralProfileSectionState();
}

class _ReferralProfileSectionState extends State<ReferralProfileSection> {
  final codeController = TextEditingController();
  String? error;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message =
        '我在「清洗到家」洗过车了，邀请你一起来！注册时填写我的分享码 ${widget.shareCode}，我们各得 1 次免费洗车。';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('分享与免费洗车', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: '剩余次数',
                    value: '${widget.freeWashCredits}',
                    icon: Icons.card_giftcard,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: '已使用',
                    value: '${widget.freeWashUsedCount}',
                    icon: Icons.local_car_wash_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: '分享成功',
                    value: '${widget.referralSuccessCount}',
                    icon: Icons.people_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.canShare) ...[
              Text(
                '我的分享码：${widget.shareCode}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '分享给好友，双方各得 1 次免费洗车。好友可在注册时填写，或在下方兑换。',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: widget.shareCode),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('分享码已复制')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('复制分享码'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: message));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('分享文案已复制，可粘贴给好友')),
                        );
                      }
                    },
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('复制分享文案'),
                  ),
                ],
              ),
            ] else ...[
              const Text(
                '完成首次洗车后，即可分享专属邀请码给好友，双方各得 1 次免费洗车。',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                '分享码：${widget.shareCode}',
                style: TextStyle(color: Theme.of(context).disabledColor),
              ),
            ],
            if (widget.referredByName != null) ...[
              const SizedBox(height: 12),
              Text('通过分享码注册，邀请人：${widget.referredByName}'),
            ],
            if (widget.referredUsers.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('已邀请好友：', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              for (final name in widget.referredUsers)
                Text('· $name', style: const TextStyle(fontSize: 13)),
            ],
            if (widget.canRedeemCode) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('兑换分享码', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: '输入好友分享码',
                  border: OutlineInputBorder(),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 6),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () async {
                  try {
                    await widget.onRedeemCode(codeController.text.trim());
                    codeController.clear();
                    setState(() => error = null);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('分享码兑换成功，双方各得 1 次免费洗车')),
                      );
                    }
                  } on Object catch (exception) {
                    setState(() => error =
                        exception.toString().replaceFirst('Bad state: ', ''));
                  }
                },
                child: const Text('兑换分享码'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
