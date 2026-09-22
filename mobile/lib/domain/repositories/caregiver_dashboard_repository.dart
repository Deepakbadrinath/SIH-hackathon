import '../models/caregiver_dashboard_models.dart';

abstract class CaregiverDashboardRepository {
  /// Fetches the list of authorized connected patients for [caregiverId].
  Future<List<ConnectedPatient>> getConnectedPatients(String caregiverId);

  /// Aggregates all cognitive and medication metrics for [patientId].
  /// Enforces backend authorization checks against [requestingCaregiverId].
  /// Throws [CaregiverUnauthorizedException] if [requestingCaregiverId] is not authorized.
  Future<CaregiverDashboardData> getDashboardData({
    required String requestingCaregiverId,
    required String patientId,
    required DateRangeFilter dateFilter,
  });
}
