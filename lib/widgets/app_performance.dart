import 'package:car_washing_app/app_theme.dart';
import 'package:car_washing_app/l10n/locale_controller.dart';
import 'package:car_washing_app/main.dart';
import 'package:flutter/material.dart';

/// Lightweight sync UI state — avoids rebuilding entire app on sync flag changes.
class AppSyncUiState {
  const AppSyncUiState({
    this.isSyncing = false,
    this.lastSyncError,
  });

  final bool isSyncing;
  final String? lastSyncError;

  AppSyncUiState copyWith({
    bool? isSyncing,
    String? lastSyncError,
    bool clearError = false,
  }) {
    return AppSyncUiState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncError: clearError ? null : (lastSyncError ?? this.lastSyncError),
    );
  }
}

/// Rebuilds only when store/order/reservation catalog changes.
class CatalogBuilder extends StatelessWidget {
  const CatalogBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, AppStore store) builder;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: store.catalogTick,
      builder: (context, _, __) => builder(context, store),
    );
  }
}

/// Sync progress / error banner without listening to the whole [AppStore].
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return ValueListenableBuilder<AppSyncUiState>(
      valueListenable: store.syncUi,
      builder: (context, sync, _) {
        if (!sync.isSyncing && sync.lastSyncError == null) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sync.isSyncing) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: AppColors.primarySurface,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  context.s.syncingData,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            if (sync.lastSyncError != null) ...[
              const SizedBox(height: 8),
              Material(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.cloud_off_outlined,
                    color: Colors.orange.shade800,
                  ),
                  title: Text(
                    sync.lastSyncError!,
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(context.s.syncFailedHint),
                  trailing: TextButton(
                    onPressed: sync.isSyncing ? null : onRetry,
                    child: Text(context.s.retrySync),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Builds tab pages on first visit and keeps them alive in an [IndexedStack].
class LazyIndexedShell extends StatefulWidget {
  const LazyIndexedShell({
    required this.index,
    required this.pageCount,
    required this.pageBuilder,
    super.key,
  });

  final int index;
  final int pageCount;
  final Widget Function(int index) pageBuilder;

  @override
  State<LazyIndexedShell> createState() => _LazyIndexedShellState();
}

class _LazyIndexedShellState extends State<LazyIndexedShell> {
  final Map<int, Widget> _pages = {};

  @override
  void didUpdateWidget(covariant LazyIndexedShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pages.putIfAbsent(widget.index, () => widget.pageBuilder(widget.index));
  }

  @override
  Widget build(BuildContext context) {
    _pages.putIfAbsent(widget.index, () => widget.pageBuilder(widget.index));
    return IndexedStack(
      index: widget.index,
      sizing: StackFit.expand,
      children: List.generate(widget.pageCount, (i) {
        final page = _pages[i];
        if (page == null) {
          return const SizedBox.shrink();
        }
        return KeyedSubtree(
          key: ValueKey('lazy_shell_tab_$i'),
          child: page,
        );
      }),
    );
  }
}
