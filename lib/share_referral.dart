import 'package:car_washing_app/l10n/locale_controller.dart';
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
    final s = context.s;
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
                  Text(
                    s.shareGiftTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                s.shareBeforeFirstWash,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              if (freeWashCredits > 0) ...[
                const SizedBox(height: 8),
                Text(s.currentFreeWashCountLine(freeWashCredits)),
              ],
            ],
          ),
        ),
      );
    }

    final message = s.shareMessage(shareCode);

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
                  s.shareToFriends,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.yourShareCodeLine(shareCode),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.shareCodeBenefit,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            if (freeWashCredits > 0) ...[
              const SizedBox(height: 6),
              Text(s.currentFreeWashAvailable(freeWashCredits)),
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
                        SnackBar(content: Text(s.shareCodeCopied)),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(s.copyShareCode),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: message));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.shareTextCopied)),
                      );
                    }
                  },
                  icon: const Icon(Icons.message_outlined),
                  label: Text(s.copyShareText),
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
    final s = context.s;
    final message = s.shareMessage(widget.shareCode);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.shareAndFreeWash, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: s.remainingCountLabel,
                    value: '${widget.freeWashCredits}',
                    icon: Icons.card_giftcard,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: s.usedCountLabel,
                    value: '${widget.freeWashUsedCount}',
                    icon: Icons.local_car_wash_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: s.shareSuccessCountLabel,
                    value: '${widget.referralSuccessCount}',
                    icon: Icons.people_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.canShare) ...[
              Text(
                s.myShareCodeLine(widget.shareCode),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.shareBenefitDetail,
                style: const TextStyle(fontSize: 13, height: 1.4),
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
                          SnackBar(content: Text(s.shareCodeCopied)),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(s.copyShareCode),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: message));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.shareTextCopied)),
                        );
                      }
                    },
                    icon: const Icon(Icons.message_outlined),
                    label: Text(s.copyShareText),
                  ),
                ],
              ),
            ] else ...[
              Text(
                s.shareBeforeFirstWash,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                s.shareCodeShort(widget.shareCode),
                style: TextStyle(color: Theme.of(context).disabledColor),
              ),
            ],
            if (widget.referredByName != null) ...[
              const SizedBox(height: 12),
              Text(s.referredByLine(widget.referredByName!)),
            ],
            if (widget.referredUsers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(s.invitedFriends, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              for (final name in widget.referredUsers)
                Text('· $name', style: const TextStyle(fontSize: 13)),
            ],
            if (widget.canRedeemCode) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(s.redeemShareCode, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: s.enterFriendShareCode,
                  border: const OutlineInputBorder(),
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
                        SnackBar(content: Text(s.redeemSuccess)),
                      );
                    }
                  } on Object catch (exception) {
                    setState(() => error =
                        exception.toString().replaceFirst('Bad state: ', ''));
                  }
                },
                child: Text(s.redeemShareCodeBtn),
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
