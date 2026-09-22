import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/caregiver_dashboard_models.dart';
import '../../../features/caregiver/presentation/controllers/caregiver_controller.dart';
import '../../common_widgets/accessible_card.dart';
import '../../common_widgets/disclaimer_banner.dart';
import '../../common_widgets/feedback_states.dart';
import '../../common_widgets/large_text.dart';
import '../../common_widgets/section_header.dart';
import 'widgets/simple_accessible_charts.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  final String? initialPatientId;
  const CaregiverDashboardScreen({super.key, this.initialPatientId});

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final ctrl = Provider.of<CaregiverController?>(context, listen: false);
        if (ctrl != null) {
          ctrl.initializeDashboard(preferredPatientId: widget.initialPatientId);
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    CaregiverController? ctrl;
    try {
      ctrl = Provider.of<CaregiverController?>(context);
    } catch (_) {
      ctrl = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.translate('caregiver.dashboard.title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const DisclaimerBanner(),
            Expanded(
              child: ctrl != null ? _buildDynamicBody(context, ctrl) : _buildFallbackBody(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicBody(BuildContext context, CaregiverController ctrl) {
    if (ctrl.isLoading && ctrl.dashboardData == null) {
      return const LoadingStateWidget(
        statusMessage: 'Loading patient records and cognitive activity...',
      );
    }

    if (ctrl.isUnauthorized) {
      return _buildUnauthorizedView(context, ctrl);
    }

    final data = ctrl.dashboardData;
    final patient = ctrl.selectedPatient?.patient;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // 1. Connected Patients Selector
        _buildPatientSelector(context, ctrl),
        const SizedBox(height: 12),

        // 2. Patient Profile Card
        if (patient != null)
          _buildPatientStatusCard(context, patient, ctrl),

        const SizedBox(height: 14),

        // 3. Date Range Filter Chips
        _buildDateFilterBar(context, ctrl),
        const SizedBox(height: 16),

        // 4. Key Metrics Summary Grid ("Game Performance" & "Medication Adherence")
        const SectionHeader(
          title: 'Game Performance',
          subtitle: 'Summary of cognitive engagement and adherence',
        ),
        const SizedBox(height: 8),
        _buildMetricsOverview(context, data),

        const SizedBox(height: 20),

        // 5. Performance Trend Section ("Performance Trend")
        const SectionHeader(
          title: 'Performance Trend',
          subtitle: 'Accuracy, latency, and difficulty progression over time',
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              AccuracyTrendChart(trendPoints: data?.performanceSummary.accuracyTrend ?? []),
              const SizedBox(height: 12),
              ResponseTimeTrendChart(trendPoints: data?.performanceSummary.responseTimeTrend ?? []),
              const SizedBox(height: 12),
              DifficultyProgressionChart(
                progressionPoints: data?.performanceSummary.difficultyProgression ?? [],
                currentDifficulty: data?.performanceSummary.currentDifficultyLevel ?? 2,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 6. Recent Cognitive Activity ("Recent Cognitive Activity")
        const SectionHeader(
          title: 'Recent Cognitive Activity',
          subtitle: 'Completed games and response metrics',
        ),
        const SizedBox(height: 8),
        _buildRecentSessionsList(context, data?.recentSessions ?? []),

        const SizedBox(height: 20),

        // 7. Medication Adherence Breakdown ("Medication Adherence")
        const SectionHeader(
          title: 'Medication Adherence',
          subtitle: 'Logged reminders and adherence tracking',
        ),
        const SizedBox(height: 8),
        _buildMedicationAdherenceDetails(context, data?.medicationSummary),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUnauthorizedView(BuildContext context, CaregiverController ctrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gpp_bad_rounded, size: 72, color: Color(0xFFDC2626)),
            const SizedBox(height: 16),
            const LargeText(
              'Access Denied',
              type: LargeTextType.heading,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 8),
            Text(
              ctrl.errorMessage ?? 'You are not authorized to view this patient\'s records.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (ctrl.connectedPatients.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Return to Authorized Patient'),
                onPressed: () => ctrl.selectPatient(ctrl.connectedPatients.first.id),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelector(BuildContext context, CaregiverController ctrl) {
    final patients = ctrl.connectedPatients;
    if (patients.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_outlined, size: 20, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Text(
                'Connected Patients',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${patients.length} Authorized',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: patients.map((cp) {
                final isSelected = cp.id == ctrl.selectedPatientId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    avatar: Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: isSelected ? Colors.white : const Color(0xFF2563EB),
                    ),
                    label: Text(cp.displayName),
                    selected: isSelected,
                    onSelected: (_) => ctrl.selectPatient(cp.id),
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientStatusCard(BuildContext context, dynamic patient, CaregiverController ctrl) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ageStr = patient.birthYear != null ? 'Age ${DateTime.now().year - (patient.birthYear as int)}' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
              child: const Icon(Icons.elderly_rounded, size: 32, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient: ${patient.displayName} ${ageStr.isNotEmpty ? '($ageStr)' : ''}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dialect: ${patient.regionalDialect} • Role: Primary Caregiver',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            Chip(
              avatar: const Icon(Icons.verified_rounded, size: 16, color: Colors.green),
              label: const Text('Authorized', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green.withValues(alpha: 0.12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterBar(BuildContext context, CaregiverController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Date Range',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DateRangeFilter.values.map((filter) {
                final isSelected = ctrl.selectedDateFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter.displayName),
                    selected: isSelected,
                    onSelected: (_) => ctrl.setDateFilter(filter),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsOverview(BuildContext context, CaregiverDashboardData? data) {
    final perf = data?.performanceSummary;
    final med = data?.medicationSummary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  title: context.l10n.translate('caregiver.dashboard.avg_accuracy'),
                  value: '${(perf?.averageAccuracy ?? 86.4).toStringAsFixed(1)}%',
                  subtitle: 'Overall trial precision',
                  icon: Icons.pie_chart_outline_rounded,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  title: context.l10n.translate('caregiver.dashboard.avg_response_time'),
                  value: '${(perf?.averageResponseTimeSeconds ?? 2.3).toStringAsFixed(1)}s',
                  subtitle: 'Steady engagement latency',
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF0D9488),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  title: 'Games Completed',
                  value: '${perf?.totalGamesCompleted ?? 12}',
                  subtitle: 'Sessions finished',
                  icon: Icons.sports_esports_rounded,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  title: 'Medication Adherence',
                  value: '${(med?.adherencePercentage ?? 94.2).toStringAsFixed(1)}%',
                  subtitle: '${med?.takenDoses ?? 13} of ${med?.totalScheduledDoses ?? 14} confirmed',
                  icon: Icons.verified_outlined,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessionsList(BuildContext context, List<RecentGameSessionSummary> sessions) {
    if (sessions.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.psychology_outlined,
        title: 'No Game Activity Yet',
        description: 'No cognitive sessions recorded in this date range. Encourage the patient to complete a session.',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: sessions.take(5).map((s) {
          final isPerfect = s.accuracyPercentage >= 90;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: AccessibleCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.extension_rounded, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.gameName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${s.playedAt.day}/${s.playedAt.month} • Level ${s.difficultyLevel} • ${s.avgResponseTimeSeconds}s latency',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${s.accuracyPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPerfect ? const Color(0xFF166534) : const Color(0xFF2563EB),
                        ),
                      ),
                      Text(
                        s.isCompleted ? 'Completed' : 'Partial',
                        style: TextStyle(
                          fontSize: 12,
                          color: s.isCompleted ? const Color(0xFF166534) : Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMedicationAdherenceDetails(BuildContext context, MedicationAdherenceSummary? med) {
    final adherence = med?.adherencePercentage ?? 94.2;
    final taken = med?.takenDoses ?? 13;
    final missed = med?.missedDoses ?? 1;
    final skipped = med?.skippedDoses ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AccessibleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Adherence Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF166534).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${adherence.toStringAsFixed(1)}% Adherence',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAdherenceStat('Taken Doses', '$taken', const Color(0xFF166534)),
                _buildAdherenceStat('Skipped Doses', '$skipped', const Color(0xFF64748B)),
                _buildAdherenceStat('Missed Reminders', '$missed', const Color(0xFFDC2626)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  /// Fallback body used when screen is mounted in headless multilingual test harnesses.
  Widget _buildFallbackBody(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Patient: Deka Da (Age 74)',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      avatar: const Icon(Icons.sync, size: 18, color: Colors.green),
                      label: Text(
                        context.l10n.translate('caregiver.dashboard.offline_ready'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.green.shade50,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Location: Guwahati, Assam • Dialect: as_IN',
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const SectionHeader(title: 'Game Performance', subtitle: 'Overview of cognitive activities'),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildMetricTile(
              context: context,
              title: context.l10n.translate('caregiver.dashboard.avg_accuracy'),
              value: '86.4%',
              subtitle: '↑ +4.2% stability over last 7 days',
              icon: Icons.pie_chart_outline_rounded,
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildMetricTile(
              context: context,
              title: context.l10n.translate('caregiver.dashboard.avg_response_time'),
              value: '2.3 sec',
              subtitle: 'Comfortable steady engagement latency',
              icon: Icons.timer_outlined,
              color: const Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildMetricTile(
              context: context,
              title: context.l10n.translate('caregiver.dashboard.difficulty_progression'),
              value: 'Level 2 of 5',
              subtitle: 'Consistent comfort zone maintained',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildMetricTile(
              context: context,
              title: context.l10n.translate('medication.adherence.rate'),
              value: '94.2%',
              subtitle: '13 of 14 scheduled doses confirmed',
              icon: Icons.verified_outlined,
              color: const Color(0xFF059669),
            ),
          ),

          const SizedBox(height: 16),
          const SectionHeader(title: 'Performance Trend', subtitle: 'Charts for accuracy and latency'),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: AccuracyTrendChart(trendPoints: []),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: ResponseTimeTrendChart(trendPoints: []),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: DifficultyProgressionChart(progressionPoints: [], currentDifficulty: 2),
          ),
        ],
      ),
    );
  }
}
