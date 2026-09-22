import '../../../../data/datasources/local/caregiver_local_data_source.dart';
import '../../../../domain/models/caregiver.dart';
import '../../../../domain/repositories/caregiver_repository.dart';

class CaregiverRepositoryImpl implements CaregiverRepository {
  final CaregiverLocalDataSource _caregiverDataSource;
  final RelationshipLocalDataSource _relationshipDataSource;

  CaregiverRepositoryImpl({
    required CaregiverLocalDataSource caregiverDataSource,
    required RelationshipLocalDataSource relationshipDataSource,
  })  : _caregiverDataSource = caregiverDataSource,
        _relationshipDataSource = relationshipDataSource;

  @override
  Future<Caregiver?> getCaregiverById(String id) async {
    return await _caregiverDataSource.getCaregiverById(id);
  }

  @override
  Future<Caregiver?> getCaregiverByUserId(String userId) async {
    return await _caregiverDataSource.getCaregiverByUserId(userId);
  }

  @override
  Future<void> saveCaregiver(Caregiver caregiver) async {
    await _caregiverDataSource.createCaregiver(caregiver);
  }

  @override
  Future<List<PatientCaregiverRelation>> getRelationships(String caregiverId) async {
    return await _relationshipDataSource.getRelationshipsForCaregiver(caregiverId);
  }

  @override
  Future<void> createRelationship(PatientCaregiverRelation relation) async {
    await _relationshipDataSource.createRelationship(relation);
  }
}
