import 'package:flutter/material.dart';

/// Semantic category into which everyday objects are sorted.
class SortCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const SortCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortCategory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Standard categories tailored for North Eastern elderly memory care.
class DefaultSortCategories {
  static const SortCategory food = SortCategory(
    id: 'cat_food',
    name: 'Food & Fruits',
    description: 'Everyday meals, fresh fruits, and warm drinks',
    icon: Icons.restaurant_rounded,
    color: Color(0xFF166534), // Deep Green
  );

  static const SortCategory clothing = SortCategory(
    id: 'cat_clothing',
    name: 'Clothing & Wear',
    description: 'Traditional shawls, gamosas, and daily garments',
    icon: Icons.checkroom_rounded,
    color: Color(0xFF7E22CE), // Purple
  );

  static const SortCategory household = SortCategory(
    id: 'cat_household',
    name: 'Household Items',
    description: 'Pots, brass bells, lamps, and daily utilities',
    icon: Icons.home_repair_service_rounded,
    color: Color(0xFFB45309), // Warm Amber
  );

  static const SortCategory animals = SortCategory(
    id: 'cat_animals',
    name: 'Animals & Nature',
    description: 'Courtyard pets, gentle cows, and garden birds',
    icon: Icons.pets_rounded,
    color: Color(0xFF0284C7), // Blue
  );

  static const List<SortCategory> all = [
    food,
    clothing,
    household,
    animals,
  ];
}

/// Familiar everyday object to be categorized.
class SortableObject {
  final String id;
  final String name;
  final String description;
  final SortCategory category;
  final IconData icon;
  final Color color;

  const SortableObject({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortableObject && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Library of culturally authentic everyday items for sorting.
class DefaultSortableObjects {
  // Food & Fruits
  static const SortableObject tea = SortableObject(
    id: 'food_tea',
    name: 'Assam Tea',
    description: 'Warm cup of fragrant morning tea',
    category: DefaultSortCategories.food,
    icon: Icons.emoji_food_beverage_rounded,
    color: Color(0xFFB45309),
  );

  static const SortableObject apple = SortableObject(
    id: 'food_apple',
    name: 'Sweet Apple',
    description: 'Fresh red seasonal fruit',
    category: DefaultSortCategories.food,
    icon: Icons.apple_rounded,
    color: Color(0xFFDC2626),
  );

  static const SortableObject rice = SortableObject(
    id: 'food_rice',
    name: 'Bowl of Rice',
    description: 'Steamed white everyday lunch rice',
    category: DefaultSortCategories.food,
    icon: Icons.rice_bowl_rounded,
    color: Color(0xFF166534),
  );

  static const SortableObject banana = SortableObject(
    id: 'food_banana',
    name: 'Fresh Banana',
    description: 'Ripe yellow fruit from the tree',
    category: DefaultSortCategories.food,
    icon: Icons.lunch_dining_rounded,
    color: Color(0xFFCA8A04),
  );

  // Clothing & Wear
  static const SortableObject gamosa = SortableObject(
    id: 'cloth_gamosa',
    name: 'Assam Gamosa',
    description: 'Traditional red and white cotton scarf',
    category: DefaultSortCategories.clothing,
    icon: Icons.dry_cleaning_rounded,
    color: Color(0xFFBE185D),
  );

  static const SortableObject shawl = SortableObject(
    id: 'cloth_shawl',
    name: 'Woolen Shawl',
    description: 'Warm winter shoulder wrap',
    category: DefaultSortCategories.clothing,
    icon: Icons.checkroom_rounded,
    color: Color(0xFF7E22CE),
  );

  static const SortableObject kurta = SortableObject(
    id: 'cloth_kurta',
    name: 'Cotton Kurta',
    description: 'Comfortable everyday daytime shirt',
    category: DefaultSortCategories.clothing,
    icon: Icons.accessibility_new_rounded,
    color: Color(0xFF0F3D78),
  );

  static const SortableObject slippers = SortableObject(
    id: 'cloth_slippers',
    name: 'Home Slippers',
    description: 'Soft indoor walking footwear',
    category: DefaultSortCategories.clothing,
    icon: Icons.snowshoeing_rounded,
    color: Color(0xFF475569),
  );

  // Household Items
  static const SortableObject pot = SortableObject(
    id: 'house_pot',
    name: 'Clay Pitcher',
    description: 'Earthen pot for cool drinking water',
    category: DefaultSortCategories.household,
    icon: Icons.coffee_rounded,
    color: Color(0xFF7C2D12),
  );

  static const SortableObject bell = SortableObject(
    id: 'house_bell',
    name: 'Temple Bell',
    description: 'Brass bell used for prayer and morning puja',
    category: DefaultSortCategories.household,
    icon: Icons.notifications_rounded,
    color: Color(0xFFD97706),
  );

  static const SortableObject lamp = SortableObject(
    id: 'house_lamp',
    name: 'Table Lamp',
    description: 'Gentle bedside reading light',
    category: DefaultSortCategories.household,
    icon: Icons.light_rounded,
    color: Color(0xFF0284C7),
  );

  static const SortableObject stool = SortableObject(
    id: 'house_stool',
    name: 'Sitting Stool',
    description: 'Low wooden courtyard stool',
    category: DefaultSortCategories.household,
    icon: Icons.chair_rounded,
    color: Color(0xFF57534E),
  );

  // Animals & Nature
  static const SortableObject cow = SortableObject(
    id: 'anim_cow',
    name: 'Courtyard Cow',
    description: 'Gentle farm cow that gives fresh milk',
    category: DefaultSortCategories.animals,
    icon: Icons.pets_rounded,
    color: Color(0xFF059669),
  );

  static const SortableObject bird = SortableObject(
    id: 'anim_bird',
    name: 'Singing Myna',
    description: 'Feathered songbird chirping in the garden',
    category: DefaultSortCategories.animals,
    icon: Icons.flutter_dash_rounded,
    color: Color(0xFF2563EB),
  );

  static const SortableObject cat = SortableObject(
    id: 'anim_cat',
    name: 'Friendly Cat',
    description: 'Courtyard pet that purrs softly',
    category: DefaultSortCategories.animals,
    icon: Icons.cruelty_free_rounded,
    color: Color(0xFFEA580C),
  );

  static const SortableObject fish = SortableObject(
    id: 'anim_fish',
    name: 'Pond Fish',
    description: 'Swims peacefully in the freshwater pond',
    category: DefaultSortCategories.animals,
    icon: Icons.water_drop_rounded,
    color: Color(0xFF0891B2),
  );

  static const List<SortableObject> all = [
    tea,
    apple,
    rice,
    banana,
    gamosa,
    shawl,
    kurta,
    slippers,
    pot,
    bell,
    lamp,
    stool,
    cow,
    bird,
    cat,
    fish,
  ];
}

/// Difficulty configuration for Object Sorting decoupled from UI widgets.
class SortingDifficultyConfig {
  final int difficultyLevel;
  final int activeCategoriesCount;
  final int objectCount;
  final String description;

  const SortingDifficultyConfig({
    required this.difficultyLevel,
    required this.activeCategoriesCount,
    required this.objectCount,
    required this.description,
  });

  /// Factory scaling categories and object counts across levels 1 to 5.
  factory SortingDifficultyConfig.forLevel(int level) {
    final clamped = level.clamp(1, 5);
    switch (clamped) {
      case 1:
        return const SortingDifficultyConfig(
          difficultyLevel: 1,
          activeCategoriesCount: 2,
          objectCount: 4,
          description: '2 distinct categories (Food vs Clothing), 4 objects',
        );
      case 2:
        return const SortingDifficultyConfig(
          difficultyLevel: 2,
          activeCategoriesCount: 2,
          objectCount: 6,
          description: '2 categories (Household vs Animals), 6 objects',
        );
      case 3:
        return const SortingDifficultyConfig(
          difficultyLevel: 3,
          activeCategoriesCount: 3,
          objectCount: 6,
          description: '3 categories (Food, Clothing, Animals), 6 objects',
        );
      case 4:
        return const SortingDifficultyConfig(
          difficultyLevel: 4,
          activeCategoriesCount: 3,
          objectCount: 8,
          description: '3 categories (Food, Household, Animals), 8 objects',
        );
      case 5:
      default:
        return const SortingDifficultyConfig(
          difficultyLevel: 5,
          activeCategoriesCount: 4,
          objectCount: 10,
          description: 'All 4 categories with subtle semantic overlap, 10 objects',
        );
    }
  }
}

/// Single trial presentation in Object Sorting: one item to categorize.
class ObjectSortingTrial {
  final int trialNumber;
  final SortableObject targetObject;
  final List<SortCategory> activeCategories;
  final int correctCategoryIndex;

  const ObjectSortingTrial({
    required this.trialNumber,
    required this.targetObject,
    required this.activeCategories,
    required this.correctCategoryIndex,
  });
}

/// Pure generator producing object sorting trials without UI dependencies.
class ObjectSortingGenerator {
  static List<ObjectSortingTrial> generateTrials({
    required SortingDifficultyConfig config,
    List<SortableObject>? customObjects,
    List<SortCategory>? customCategories,
    bool isDeterministic = false,
  }) {
    final categoryPool = customCategories ?? DefaultSortCategories.all;
    final objectPool = customObjects ?? DefaultSortableObjects.all;

    // Pick active categories for this difficulty
    List<SortCategory> activeCategories;
    if (config.activeCategoriesCount == 2) {
      if (config.difficultyLevel == 1) {
        // Food & Clothing
        activeCategories = [DefaultSortCategories.food, DefaultSortCategories.clothing];
      } else {
        // Household & Animals
        activeCategories = [DefaultSortCategories.household, DefaultSortCategories.animals];
      }
    } else if (config.activeCategoriesCount == 3) {
      if (config.difficultyLevel == 3) {
        activeCategories = [
          DefaultSortCategories.food,
          DefaultSortCategories.clothing,
          DefaultSortCategories.animals,
        ];
      } else {
        activeCategories = [
          DefaultSortCategories.food,
          DefaultSortCategories.household,
          DefaultSortCategories.animals,
        ];
      }
    } else {
      activeCategories = List<SortCategory>.from(categoryPool.take(4));
    }

    final activeCatIds = activeCategories.map((c) => c.id).toSet();

    // Filter objects that belong to the active categories
    final eligibleObjects = objectPool.where((o) => activeCatIds.contains(o.category.id)).toList();

    List<SortableObject> chosenObjects;
    if (!isDeterministic) {
      eligibleObjects.shuffle();
      chosenObjects = eligibleObjects.take(config.objectCount).toList();
    } else {
      // Deterministic round-robin selection from eligible objects
      chosenObjects = [];
      for (int i = 0; i < config.objectCount; i++) {
        chosenObjects.add(eligibleObjects[i % eligibleObjects.length]);
      }
    }

    final trials = <ObjectSortingTrial>[];
    for (int i = 0; i < chosenObjects.length; i++) {
      final obj = chosenObjects[i];
      final correctIdx = activeCategories.indexWhere((c) => c.id == obj.category.id);

      trials.add(
        ObjectSortingTrial(
          trialNumber: i + 1,
          targetObject: obj,
          activeCategories: activeCategories,
          correctCategoryIndex: correctIdx,
        ),
      );
    }

    return trials;
  }
}

/// Trial result measuring accuracy, response time, and hesitation for one item.
class ObjectSortingTrialResult {
  final int trialNumber;
  final String objectId;
  final String targetCategoryId;
  final String selectedCategoryId;
  final bool isCorrect;
  final int responseTimeMs;
  final int hesitationMs;

  const ObjectSortingTrialResult({
    required this.trialNumber,
    required this.objectId,
    required this.targetCategoryId,
    required this.selectedCategoryId,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.hesitationMs,
  });
}

/// Overall session score outcome for Object Sorting.
class SortingSessionScore {
  final int totalTrials;
  final int correctCount;
  final int errorCount;
  final double accuracyPercentage;
  final double avgResponseTimeMs;
  final double totalHesitationMs;
  final int calculatedScore;
  final int maxPossibleScore;
  final int stars;
  final String encouragementMessage;

  const SortingSessionScore({
    required this.totalTrials,
    required this.correctCount,
    required this.errorCount,
    required this.accuracyPercentage,
    required this.avgResponseTimeMs,
    required this.totalHesitationMs,
    required this.calculatedScore,
    this.maxPossibleScore = 100,
    required this.stars,
    required this.encouragementMessage,
  });
}

/// Deterministic, respectful score calculator for Object Sorting.
class ObjectSortingScoreCalculator {
  static SortingSessionScore calculate(
    List<ObjectSortingTrialResult> results, {
    int difficultyLevel = 1,
  }) {
    if (results.isEmpty) {
      return const SortingSessionScore(
        totalTrials: 0,
        correctCount: 0,
        errorCount: 0,
        accuracyPercentage: 0.0,
        avgResponseTimeMs: 0.0,
        totalHesitationMs: 0.0,
        calculatedScore: 0,
        stars: 1,
        encouragementMessage: 'Thank you for categorizing objects today!',
      );
    }

    final totalTrials = results.length;
    final correctCount = results.where((r) => r.isCorrect).length;
    final errorCount = totalTrials - correctCount;
    final accuracyPercentage = (correctCount / totalTrials) * 100.0;

    final totalResponseMs = results.fold<int>(0, (sum, r) => sum + r.responseTimeMs);
    final avgResponseTimeMs = totalResponseMs / totalTrials;
    final totalHesitationMs = results.fold<int>(0, (sum, r) => sum + r.hesitationMs).toDouble();

    // Base accuracy contributes up to 80 points
    final baseAccuracy = (accuracyPercentage * 0.80).round();

    // Leisurely pacing bonus up to 20 points
    int paceBonus = 0;
    if (correctCount > 0) {
      final clampedResponse = avgResponseTimeMs.clamp(1000.0, 6000.0);
      paceBonus = (((6000.0 - clampedResponse) / 5000.0) * 20.0).round().clamp(0, 20);
    }

    final totalScore = (baseAccuracy + paceBonus).clamp(0, 100);

    int stars;
    if (accuracyPercentage >= 80.0) {
      stars = 3;
    } else if (accuracyPercentage >= 50.0) {
      stars = 2;
    } else {
      stars = 1;
    }

    String message;
    if (stars == 3) {
      message = 'Brilliant organization! You grouped every object into its true home!';
    } else if (stars == 2) {
      message = 'Good work! Sorting familiar items keeps mental focus clear and active.';
    } else {
      message = 'Well done for practicing! Gentle sorting exercises stimulate daily memory.';
    }

    return SortingSessionScore(
      totalTrials: totalTrials,
      correctCount: correctCount,
      errorCount: errorCount,
      accuracyPercentage: double.parse(accuracyPercentage.toStringAsFixed(1)),
      avgResponseTimeMs: double.parse(avgResponseTimeMs.toStringAsFixed(1)),
      totalHesitationMs: totalHesitationMs,
      calculatedScore: totalScore,
      stars: stars,
      encouragementMessage: message,
    );
  }
}
