import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../features/caregiver/presentation/controllers/caregiver_controller.dart';
import '../../../features/demo/presentation/controllers/demo_controller.dart';
import '../../../features/elderly_home/presentation/controllers/elderly_home_controller.dart';
import '../../../features/offline_sync/presentation/controllers/sync_controller.dart';
import '../../../features/voice/presentation/controllers/voice_controller.dart';
import '../../common_widgets/accessible_card.dart';
import '../../common_widgets/disclaimer_banner.dart';
import '../../common_widgets/large_text.dart';
import '../../common_widgets/primary_button.dart';
import '../../common_widgets/responsive_scaffold.dart';
import '../../common_widgets/secondary_button.dart';
import '../../common_widgets/section_header.dart';

/// Dedicated Grand Finale SIH Demonstration Hub Screen.
/// Provides evaluators, judges, and presenters an interactive, deterministic walkthrough
/// of all system features: Regional Voice, Cognitive Games, Adaptive Difficulty, Offline-First SQLite,
/// Idempotent Cloud Synchronization, and Zero-Trust Caregiver Analytics.
class SihDemoScreen extends StatelessWidget {
  const SihDemoScreen({super.key});

  void _handleExit(BuildContext context) {
    try {
      context.read<VoiceController?>()?.stopAll();
    } catch (_) {}

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final demoCtrl = context.watch<DemoController?>();
    final syncCtrl = context.watch<SyncController?>();
    final voiceCtrl = context.watch<VoiceController?>();

    final isOffline = demoCtrl?.isOfflineSimulated ?? false;
    final pendingCount = syncCtrl?.pendingCount ?? 0;
    final activeLocale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SIH Grand Finale Demo Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          onPressed: () => _handleExit(context),
          tooltip: 'Return to application',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 28),
            tooltip: 'Reset Demo Baseline Data',
            onPressed: () async {
              await demoCtrl?.resetDemoData();
              if (context.mounted) {
                final cg = Provider.of<CaregiverController?>(context, listen: false);
                cg?.initializeDashboard();
                final home = Provider.of<ElderlyHomeController?>(context, listen: false);
                home?.incrementGamesPlayed();
                syncCtrl?.refreshPendingCount();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo baseline data reset: Patient, Caregiver, and 14 days of history restored.'),
                    backgroundColor: Color(0xFF0F3D78),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 30),
            tooltip: 'Exit SIH Demo',
            onPressed: () => _handleExit(context),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              const DisclaimerBanner(),
              const SizedBox(height: 12),

              // Live Simulation Status Banner
              AccessibleCard(
                backgroundColor: isOffline ? const Color(0xFF7F1D1D) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)),
                borderColor: isOffline ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                              color: isOffline ? const Color(0xFFFCA5A5) : const Color(0xFF38BDF8),
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isOffline ? 'OFFLINE SIMULATION ACTIVE' : 'ONLINE CONNECTED',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: isOffline ? const Color(0xFFFCA5A5) : (isDark ? Colors.white : const Color(0xFF0F3D78)),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: pendingCount > 0 ? const Color(0xFFFACC15) : const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pendingCount Pending Sync',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      demoCtrl?.statusMessage ?? 'SIH Demo Mode Active with Local SQLite database',
                      style: TextStyle(
                        fontSize: 14,
                        color: isOffline ? const Color(0xFFFECACA) : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOffline ? const Color(0xFF166534) : const Color(0xFF991B1B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: Icon(isOffline ? Icons.wifi_rounded : Icons.wifi_off_rounded, size: 18),
                          label: Text(
                            isOffline ? 'Reconnect Network' : 'Simulate Offline Drop',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () async {
                            await demoCtrl?.toggleSimulatedOffline();
                            await syncCtrl?.refreshPendingCount();
                          },
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F3D78),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.sync_rounded, size: 18),
                          label: Text(
                            'Trigger Server Sync ($pendingCount)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () async {
                            if (isOffline) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cannot sync while in Offline Mode. Please Reconnect Network first.'),
                                  backgroundColor: Color(0xFF991B1B),
                                ),
                              );
                              return;
                            }
                            await syncCtrl?.triggerManualSync();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sync completed: All records pushed with UUID idempotency tokens.'),
                                  backgroundColor: Color(0xFF166534),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const SectionHeader(
                title: 'Interactive Evaluation Stages',
                subtitle: 'Step-by-step walkthrough of the 6 core architectural pillars',
              ),
              const SizedBox(height: 8),

              // Stage 1: Regional Language & Speech AI
              _buildStageCard(
                context,
                stageNumber: '1',
                title: 'Regional Language & Speech AI',
                description: '14 Indian languages (Assamese, Manipuri, Hindi, Bengali) with Bhashini AI and native browser SpeechSynthesis fallback.',
                badgeText: 'Active: ${activeLocale.toUpperCase()}',
                badgeColor: const Color(0xFF0284C7),
                icon: Icons.record_voice_over_rounded,
                primaryActionLabel: 'Open Language Selector',
                onPrimaryAction: () => Navigator.pushNamed(context, '/language'),
                secondaryActionLabel: 'Test Regional Audio',
                onSecondaryAction: () {
                  final phrase = activeLocale == 'as'
                      ? 'নমস্কাৰ! স্মৃতি সেতুত আপোনাক স্বাগতম।'
                      : (activeLocale == 'hi'
                          ? 'नमस्ते! स्मृति सेतु में आपका स्वागत है।'
                          : 'Welcome to Smriti Setu cognitive support system.');
                  voiceCtrl?.speakText(phrase, languageCode: activeLocale);
                },
              ),

              const SizedBox(height: 12),

              // Stage 2: Elderly Cognitive Home
              _buildStageCard(
                context,
                stageNumber: '2',
                title: 'Elderly WCAG AAA Home Interface',
                description: 'Senior-first interface with 56dp+ touch targets, high contrast, zero cognitive overload, and multimodal audio guidance.',
                badgeText: 'Accessible UI',
                badgeColor: const Color(0xFF16A34A),
                icon: Icons.elderly_rounded,
                primaryActionLabel: 'Open Elderly Home',
                onPrimaryAction: () => Navigator.pushNamed(context, '/elderly_home'),
              ),

              const SizedBox(height: 12),

              // Stage 3: Cognitive Games & Micro-Telemetry
              _buildStageCard(
                context,
                stageNumber: '3',
                title: 'Dementia-Specific Cognitive Games',
                description: '4 neuro-psychologically grounded games without stress-inducing timers. Captures response latency, hesitation pauses, and trial accuracy.',
                badgeText: '4 Games',
                badgeColor: const Color(0xFF7E22CE),
                icon: Icons.psychology_rounded,
                primaryActionLabel: 'Play Family Face Match',
                onPrimaryAction: () => Navigator.pushNamed(context, '/face_match'),
                secondaryActionLabel: 'View All 4 Games',
                onSecondaryAction: () => Navigator.pushNamed(context, '/games'),
              ),

              const SizedBox(height: 12),

              // Stage 4: Explainable Adaptive Difficulty
              _buildStageCard(
                context,
                stageNumber: '4',
                title: 'Real-Time Adaptive Difficulty Engine',
                description: 'Deterministic heuristic scoring S in [0.0, 1.0]. Promotes at S >= 0.80, demotes at S < 0.60 to prevent frustration and preserve self-efficacy.',
                badgeText: 'Levels 1 - 5',
                badgeColor: const Color(0xFFB45309),
                icon: Icons.auto_graph_rounded,
                primaryActionLabel: 'Test Pattern Completion',
                onPrimaryAction: () => Navigator.pushNamed(context, '/pattern_completion'),
                secondaryActionLabel: 'Test Activity Sequence',
                onSecondaryAction: () => Navigator.pushNamed(context, '/activity_sequence'),
              ),

              const SizedBox(height: 12),

              // Stage 5: Offline-First SQLite Resilience
              _buildStageCard(
                context,
                stageNumber: '5',
                title: 'Offline-First SQLite Architecture',
                description: 'Autonomous on-device write with Write-Ahead Logging (WAL). When offline, sessions queue locally; when reconnected, sync occurs idempotently.',
                badgeText: isOffline ? 'Offline' : 'Online',
                badgeColor: isOffline ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                icon: Icons.storage_rounded,
                primaryActionLabel: 'Open Medication Tracker',
                onPrimaryAction: () => Navigator.pushNamed(context, '/medication'),
              ),

              const SizedBox(height: 12),

              // Stage 6: Zero-Trust Caregiver Portal
              _buildStageCard(
                context,
                stageNumber: '6',
                title: 'Caregiver Portal & IDOR Protection',
                description: 'Longitudinal cognitive slopes (7/30/90 days), medication adherence tracking, and strict OwnershipGuard authorization preventing unauthorized patient data access.',
                badgeText: 'Caregiver RBAC',
                badgeColor: const Color(0xFF0F3D78),
                icon: Icons.shield_rounded,
                primaryActionLabel: 'Open Caregiver Dashboard',
                onPrimaryAction: () => Navigator.pushNamed(context, '/caregiver'),
              ),

              const SizedBox(height: 24),

              // Primary Full Flow Action
              PrimaryButton(
                label: 'Start Guided Demonstration Flow',
                icon: Icons.play_arrow_rounded,
                height: 64.0,
                onPressed: () {
                  Navigator.pushNamed(context, '/elderly_home');
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Return to Welcome Screen',
                icon: Icons.home_rounded,
                height: 56.0,
                onPressed: () => _handleExit(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageCard(
    BuildContext context, {
    required String stageNumber,
    required String title,
    required String description,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required String primaryActionLabel,
    required VoidCallback onPrimaryAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AccessibleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  stageNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LargeText(
                  title,
                  type: LargeTextType.title,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF0F3D78) : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: Icon(icon, size: 18),
                label: Text(
                  primaryActionLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: onPrimaryAction,
              ),
              if (secondaryActionLabel != null && onSecondaryAction != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    side: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.touch_app_rounded, size: 18),
                  label: Text(
                    secondaryActionLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: onSecondaryAction,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
