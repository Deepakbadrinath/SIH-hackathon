import '../../../../domain/models/game_models.dart';

class GameMetadata {
  final GameType type;
  final String titleKey;
  final String descriptionKey;
  final String iconPath;
  final int baseDifficulty;
  final String targetCognitiveDomain;

  const GameMetadata({
    required this.type,
    required this.titleKey,
    required this.descriptionKey,
    required this.iconPath,
    this.baseDifficulty = 1,
    required this.targetCognitiveDomain,
  });
}

class GameCatalog {
  static const List<GameMetadata> availableGames = [
    GameMetadata(
      type: GameType.familyFaceMatch,
      titleKey: 'game.face_match.title',
      descriptionKey: 'game.face_match.instruction',
      iconPath: 'assets/images/face_match_icon.png',
      targetCognitiveDomain: 'Visual Memory & Social Association',
    ),
    GameMetadata(
      type: GameType.patternCompletion,
      titleKey: 'game.pattern.title',
      descriptionKey: 'game.pattern.instruction',
      iconPath: 'assets/images/pattern_icon.png',
      targetCognitiveDomain: 'Executive Function & Logic',
    ),
    GameMetadata(
      type: GameType.activitySequence,
      titleKey: 'game.sequence.title',
      descriptionKey: 'game.sequence.instruction',
      iconPath: 'assets/images/sequence_icon.png',
      targetCognitiveDomain: 'Daily Living Procedural Memory',
    ),
    GameMetadata(
      type: GameType.objectSorting,
      titleKey: 'game.sorting.title',
      descriptionKey: 'game.sorting.instruction',
      iconPath: 'assets/images/sorting_icon.png',
      targetCognitiveDomain: 'Working Memory & Categorization',
    ),
  ];
}
