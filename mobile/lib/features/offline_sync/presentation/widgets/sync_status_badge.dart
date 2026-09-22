import 'package:flutter/material.dart';

class SyncStatusBadge extends StatelessWidget {
  final int pendingCount;
  final bool isSyncing;
  final VoidCallback? onSyncTap;

  const SyncStatusBadge({
    super.key,
    required this.pendingCount,
    this.isSyncing = false,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOfflineReady = pendingCount == 0;
    final color = isSyncing
        ? const Color(0xFF2563EB)
        : isOfflineReady
            ? const Color(0xFF059669)
            : const Color(0xFFD97706);

    final text = isSyncing
        ? 'Syncing...'
        : isOfflineReady
            ? 'All Synced'
            : '$pendingCount Pending';

    final icon = isSyncing
        ? Icons.sync
        : isOfflineReady
            ? Icons.cloud_done_rounded
            : Icons.cloud_upload_outlined;

    return Semantics(
      button: onSyncTap != null,
      label: 'Sync Status: $text',
      child: ActionChip(
        avatar: Icon(icon, color: color, size: 20),
        label: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        backgroundColor: color.withValues(alpha: 0.12),
        side: BorderSide(color: color, width: 1.5),
        onPressed: onSyncTap,
      ),
    );
  }
}
