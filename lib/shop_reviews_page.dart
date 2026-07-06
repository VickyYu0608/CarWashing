import 'package:car_washing_app/api_client.dart';
import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:car_washing_app/main.dart';
import 'package:flutter/material.dart';

class ShopReviewsPage extends StatefulWidget {
  const ShopReviewsPage({super.key});

  @override
  State<ShopReviewsPage> createState() => _ShopReviewsPageState();
}

class _ShopReviewsPageState extends State<ShopReviewsPage> {
  List<Map<String, dynamic>> reviews = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (ApiClient.accessToken != null) {
        reviews = await ApiClient.fetchReviews();
      }
    } on Object {
      // ignore
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.myReviews)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : reviews.isEmpty
              ? Center(child: Text(s.noReviews))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final user = AppScope.of(context)
                        .accountById(review['user_account_id'] as String);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(user.displayName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                const Spacer(),
                                Text(s.starRating(review['rating'] as int)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(review['comment'] as String? ?? ''),
                            if ((review['reply'] as String? ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  s.shopReplyPrefix(review['reply'] as String),
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
