import 'package:car_washing_app/api_client.dart';
import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/license_materials_page.dart';
import 'package:car_washing_app/main.dart';
import 'package:flutter/material.dart';

/// 平台审核中心：待审优先、红色提醒、可填写审批意见
class AdminApprovalPage extends StatefulWidget {
  const AdminApprovalPage({this.onQueueChanged, super.key});

  final VoidCallback? onQueueChanged;

  @override
  State<AdminApprovalPage> createState() => _AdminApprovalPageState();
}

class _AdminApprovalPageState extends State<AdminApprovalPage> {
  Map<String, dynamic>? _pending;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      _pending = await ApiClient.fetchAdminPending();
      await AppScope.of(context).syncAccountsFromBackend();
    } on Object {
      // keep local
    }
    if (mounted) {
      setState(() => _loading = false);
      widget.onQueueChanged?.call();
    }
  }

  Future<void> _approveAccount(
    String accountId,
    ApprovalStatus status,
    String reply,
  ) async {
    await ApiClient.updateApproval(
      accountId: accountId,
      approvalStatus: status.name,
      adminReply: reply,
    );
    final appStore = AppScope.of(context);
    final account = appStore.accountById(accountId);
    account.approvalStatus = status;
    if (reply.isNotEmpty) account.adminReply = reply;
    appStore.notifyListeners();
    await _refresh();
  }

  Future<void> _approveStore(
    String storeId,
    ApprovalStatus status,
    String reply,
  ) async {
    await ApiClient.updateStoreApproval(
      storeId: storeId,
      approvalStatus: status.name,
      adminReply: reply,
    );
    await AppScope.of(context).syncFromBackend();
    await _refresh();
  }

  Future<void> _showReviewSheet({
    required String title,
    required String subtitle,
    required Future<void> Function(ApprovalStatus status, String reply) onSubmit,
    List<String> licenseFiles = const [],
  }) async {
    final replyController = TextEditingController();
    var decision = ApprovalStatus.approved;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 6),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              if (licenseFiles.isNotEmpty) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LicenseMaterialsPage(
                        title: '经营许可证',
                        files: licenseFiles,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: Text('查看证照（${licenseFiles.length}）'),
                ),
              ],
              const SizedBox(height: 16),
              SegmentedButton<ApprovalStatus>(
                segments: const [
                  ButtonSegment(
                    value: ApprovalStatus.approved,
                    label: Text('通过'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: ApprovalStatus.rejected,
                    label: Text('驳回'),
                    icon: Icon(Icons.cancel_outlined),
                  ),
                ],
                selected: {decision},
                onSelectionChanged: (value) {
                  decision = value.first;
                  (context as Element).markNeedsBuild();
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: replyController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '审批意见（选填，驳回时建议填写）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await onSubmit(decision, replyController.text.trim());
                },
                child: const Text('提交审批'),
              ),
            ],
          ),
        );
      },
    );
    replyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountCount = _pending?['pending_account_count'] as int? ?? 0;
    final storeCount = _pending?['pending_store_count'] as int? ?? 0;
    final accounts = (_pending?['pending_accounts'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final stores = (_pending?['pending_stores'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '审核中心',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  accountCount + storeCount > 0
                      ? '有 ${accountCount + storeCount} 项待处理，请优先审核'
                      : '暂无待审核项，全部已处理',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ))
          else ...[
            _SectionHeader(
              title: '商家账号审核',
              count: accountCount,
              pending: accountCount > 0,
            ),
            if (accounts.isEmpty)
              const _EmptyHint(text: '暂无待审商家账号')
            else
              for (final item in accounts)
                _PendingAccountCard(
                  data: item,
                  onReview: () => _showReviewSheet(
                    title: item['display_name'] as String? ?? '商家',
                    subtitle: item['phone'] as String? ?? '',
                    licenseFiles: (item['license_files'] as List<dynamic>? ?? [])
                        .map((e) => e.toString())
                        .toList(),
                    onSubmit: (status, reply) =>
                        _approveAccount(item['id'] as String, status, reply),
                  ),
                ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: '门店审核',
              count: storeCount,
              pending: storeCount > 0,
            ),
            if (stores.isEmpty)
              const _EmptyHint(text: '暂无待审门店')
            else
              for (final item in stores)
                _PendingStoreCard(
                  data: item,
                  onReview: () => _showReviewSheet(
                    title: item['name'] as String? ?? '门店',
                    subtitle: item['address'] as String? ?? '',
                    onSubmit: (status, reply) =>
                        _approveStore(item['id'] as String, status, reply),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.pending,
  });

  final String title;
  final int count;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: pending ? Colors.red.withOpacity(0.12) : Colors.green.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            pending ? '待审 $count' : '已清空',
            style: TextStyle(
              color: pending ? Colors.red : Colors.green,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingAccountCard extends StatelessWidget {
  const _PendingAccountCard({required this.data, required this.onReview});

  final Map<String, dynamic> data;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.red.shade50,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.store, color: Colors.white),
        ),
        title: Text(
          data['display_name'] as String? ?? '',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(data['shop_address'] as String? ?? data['phone'] as String? ?? ''),
        trailing: FilledButton(onPressed: onReview, child: const Text('审核')),
      ),
    );
  }
}

class _PendingStoreCard extends StatelessWidget {
  const _PendingStoreCard({required this.data, required this.onReview});

  final Map<String, dynamic> data;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      color: Colors.red.shade50,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.storefront, color: Colors.white),
        ),
        title: Text(
          data['name'] as String? ?? '',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(data['address'] as String? ?? ''),
        trailing: FilledButton(onPressed: onReview, child: const Text('审核')),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
