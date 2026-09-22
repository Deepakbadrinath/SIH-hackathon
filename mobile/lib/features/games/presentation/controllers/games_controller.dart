import 'package:flutter/foundation.dart';
import '../../../../domain/models/game_models.dart';
import '../../../../domain/repositories/game_repository.dart';
import '../../domain/models/game_engine_contracts.dart';

class GamesController extends ChangeNotifier {
  final GameRepository _gameRepository;
  List<GameResult> _recentResults = [];
  bool _isLoading = false;
  GameType? _selectedGame;

  GamesController({required GameRepository gameRepository})
      : _gameRepository = gameRepository;

  List<GameMetadata> get availableGames => GameCatalog.availableGames;
  List<GameResult> get recentResults => _recentResults;
  bool get isLoading => _isLoading;
  GameType? get selectedGame => _selectedGame;

  void selectGame(GameType type) {
    _selectedGame = type;
    notifyListeners();
  }

  Future<void> loadRecentResults(String patientId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _recentResults = await _gameRepository.getRecentResults(patientId);
    } catch (e) {
      if (kDebugMode) print('Error loading game results: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> fetchDifficultyForGame(String patientId, GameType type) async {
    return await _gameRepository.getLatestDifficultyLevel(patientId, type);
  }
}
