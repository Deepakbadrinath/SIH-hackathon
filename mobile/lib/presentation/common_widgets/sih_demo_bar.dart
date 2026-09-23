import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/navigation_keys.dart';
import '../../features/caregiver/presentation/controllers/caregiver_controller.dart';
import '../../features/demo/presentation/controllers/demo_controller.dart';
import '../../features/elderly_home/presentation/controllers/elderly_home_controller.dart';
import '../../features/offline_sync/presentation/controllers/sync_controller.dart';
import '../../features/voice/presentation/controllers/voice_controller.dart';
import 'app_hover_interactive.dart';

/// Floating, collapsible control bar specifically built for SIH judges and presenters.
/// Provides immediate, reliable simulation of network toggles, sync triggers, and instant demo data resets.
class SihDemoBar extends StatelessWidget {
  const SihDemoBar({super.key});

  @override
  Widget build(BuildContext context) {
    DemoController? demoCtrl;
    SyncController? syncCtrl;

    try {
      demoCtrl = context.watch<DemoController?>();
      syncCtrl = context.watch<SyncController?>();
    } catch (_) {
      demoCtrl = null;
      syncCtrl = null;
    }

    if (demoCtrl == null || !demoCtrl.isDemoModeActive) {
      return const SizedBox.shrink();
    }

    final isOffline = demoCtrl.isOfflineSimulated;
    final pendingCount = syncCtrl?.pendingCount ?? 0;
    final isExpanded = demoCtrl.isExpanded;

    if (!isExpanded) {
      return SafeArea(
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0, bottom: 12.0),
            child: AppHoverInteractive(
              onTap: () => demoCtrl?.toggleExpanded(),
              borderRadius: BorderRadius.circular(24),
              hoverGlowColor: isOffline
                  ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                  : const Color(0xFF38BDF8).withValues(alpha: 0.4),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(24),
                color: isOffline ? const Color(0xFFDC2626) : const Color(0xFF0F3D78),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOffline ? 'OFFLINE (Queue: $pendingCount)' : 'SIH DEMO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.expand_less_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOffline ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOffline ? const Color(0xFF7F1D1D) : const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOffline ? 'OFFLINE SIMULATION' : 'ONLINE MODE',
                            style: TextStyle(
                              color: isOffline ? const Color(0xFFFCA5A5) : const Color(0xFF93C5FD),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            'SIH Demo Controls',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 32),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text(
                          'Open Demo Hub',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        onPressed: () {
                          demoCtrl?.toggleExpanded();
                          try {
                            context.read<VoiceController?>()?.stopAll();
                          } catch (_) {}
                          NavigationKeys.rootNavigatorKey.currentState?.pushNamed('/demo');
                        },
                      ),
                      const SizedBox(width: 8),
                      _SihDemoCloseButton(
                        onPressed: () => demoCtrl?.toggleExpanded(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Status message
              Text(
                demoCtrl.statusMessage,
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
              ),
              const SizedBox(height: 12),

              // Action buttons row 1: Network toggle & Sync
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOffline ? const Color(0xFF166534) : const Color(0xFF991B1B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: Icon(
                      isOffline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isOffline ? 'Reconnect Network' : 'Turn Off Network',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () async {
                      await demoCtrl?.toggleSimulatedOffline();
                      await syncCtrl?.refreshPendingCount();
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: Icon(
                      Icons.sync_rounded,
                      size: 18,
                      color: pendingCount > 0 ? const Color(0xFFFACC15) : Colors.white70,
                    ),
                    label: Text(
                      'Sync ($pendingCount Pending)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: pendingCount > 0 ? const Color(0xFFFACC15) : Colors.white,
                      ),
                    ),
                    onPressed: () async {
                      if (isOffline) {
                        NavigationKeys.rootScaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(
                            content: Text('Cannot synchronize while in Offline Mode. Please Reconnect Network first.'),
                            backgroundColor: Color(0xFF991B1B),
                          ),
                        );
                        return;
                      }
                      await syncCtrl?.triggerManualSync();
                      NavigationKeys.rootScaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text('Synchronized pending records to server successfully!'),
                          backgroundColor: Color(0xFF166534),
                        ),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      'Reset Demo Baseline',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () async {
                      await demoCtrl?.resetDemoData();
                      if (context.mounted) {
                        final cg = Provider.of<CaregiverController?>(context, listen: false);
                        cg?.initializeDashboard();
                        final home = Provider.of<ElderlyHomeController?>(context, listen: false);
                        home?.incrementGamesPlayed();
                        syncCtrl?.refreshPendingCount();

                        NavigationKeys.rootScaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(
                            content: Text('Demo baseline data reset: Patient, Caregiver, and 14 days of history restored.'),
                            backgroundColor: Color(0xFF0F3D78),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Quick jump navigation row
              const Text(
                'Demo Flow Shortcuts:',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildNavChip(context, '0. Demo Hub', '/demo'),
                  _buildNavChip(context, '1. Splash', '/'),
                  _buildNavChip(context, '2. Elderly Home', '/elderly_home'),
                  _buildNavChip(context, '3. Face Match', '/face_match'),
                  _buildNavChip(context, '4. Caregiver', '/caregiver'),
                  _buildNavChip(context, '5. Medication', '/medication'),
                  _buildNavChip(context, '6. Voice Settings', '/voice_settings'),
                  _buildNavChip(context, '7. Pattern Recall', '/pattern_completion'),
                  _buildNavChip(context, '8. Activity Sequence', '/activity_sequence'),
                  _buildNavChip(context, '9. Object Sorting', '/object_sorting'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavChip(BuildContext context, String label, String route) {
    return ActionChip(
      backgroundColor: const Color(0xFF1E293B),
      side: const BorderSide(color: Color(0xFF475569)),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
      onPressed: () {
        try {
          context.read<VoiceController?>()?.stopAll();
        } catch (_) {}
        NavigationKeys.rootNavigatorKey.currentState?.pushNamed(route);
      },
    );
  }
}

class _SihDemoCloseButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _SihDemoCloseButton({this.onPressed});

  @override
  State<_SihDemoCloseButton> createState() => _SihDemoCloseButtonState();
}

class _SihDemoCloseButtonState extends State<_SihDemoCloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.close_rounded,
            color: _isHovered ? Colors.white : Colors.white70,
            size: 20,
          ),
        ),
      ),
    );
  }
}
