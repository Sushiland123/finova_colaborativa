import 'package:uuid/uuid.dart';

// Nivel del usuario
enum UserLevel {
  novato,        // 0-9 puntos
  principiante,  // 10-29 puntos
  intermedio,    // 30-59 puntos
  avanzado,      // 60-99 puntos
  experto,       // 100+ puntos
}

// Modelo de Curso
class Course {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String videoUrl;
  final int durationMinutes;
  final String language;
  final String category;
  final List<QuizQuestion> questions;
  final int maxPoints;
  final String difficulty; // Fácil, Medio, Difícil

  Course({
    String? id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.durationMinutes,
    this.language = 'Español',
    required this.category,
    required this.questions,
    this.maxPoints = 5,
    required this.difficulty,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'durationMinutes': durationMinutes,
      'language': language,
      'category': category,
      'maxPoints': maxPoints,
      'difficulty': difficulty,
    };
  }

  String getDifficultyIcon() {
    switch (difficulty.toLowerCase()) {
      case 'fácil':
        return '🟢';
      case 'medio':
        return '🟡';
      case 'difícil':
        return '🔴';
      default:
        return '⚪';
    }
  }

  String getCategoryIcon() {
    switch (category.toLowerCase()) {
      case 'ahorro':
        return '💰';
      case 'presupuesto':
        return '📊';
      case 'inversión':
        return '📈';
      case 'deudas':
        return '💳';
      case 'básicos':
        return '📚';
      default:
        return '📖';
    }
  }
}

// Modelo de Pregunta del Quiz
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    String? id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options.join('|'),
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'],
      question: map['question'],
      options: map['options'].split('|'),
      correctAnswerIndex: map['correctAnswerIndex'],
      explanation: map['explanation'],
    );
  }
}

// Modelo de Progreso del Usuario en un Curso
class CourseProgress {
  final String id;
  final String userId;
  final String courseId;
  final bool isCompleted;
  final int score;
  final int totalQuestions;
  final int pointsEarned;
  final DateTime? completedAt;
  final DateTime startedAt;
  final int watchedSeconds;
  final List<int> userAnswers;

  CourseProgress({
    String? id,
    required this.userId,
    required this.courseId,
    this.isCompleted = false,
    this.score = 0,
    this.totalQuestions = 5,
    this.pointsEarned = 0,
    this.completedAt,
    DateTime? startedAt,
    this.watchedSeconds = 0,
    this.userAnswers = const [],
  })  : id = id ?? const Uuid().v4(),
        startedAt = startedAt ?? DateTime.now();

  double get percentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;
  
  String get grade {
    final percent = percentage;
    if (percent >= 90) return 'A';
    if (percent >= 80) return 'B';
    if (percent >= 70) return 'C';
    if (percent >= 60) return 'D';
    return 'F';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'courseId': courseId,
      'isCompleted': isCompleted ? 1 : 0,
      'score': score,
      'totalQuestions': totalQuestions,
      'pointsEarned': pointsEarned,
      'completedAt': completedAt?.toIso8601String(),
      'startedAt': startedAt.toIso8601String(),
      'watchedSeconds': watchedSeconds,
      'userAnswers': userAnswers.join(','),
    };
  }

  factory CourseProgress.fromMap(Map<String, dynamic> map) {
    return CourseProgress(
      id: map['id'],
      userId: map['userId'],
      courseId: map['courseId'],
      isCompleted: map['isCompleted'] == 1,
      score: map['score'],
      totalQuestions: map['totalQuestions'],
      pointsEarned: map['pointsEarned'],
      completedAt: map['completedAt'] != null 
          ? DateTime.parse(map['completedAt'])
          : null,
      startedAt: DateTime.parse(map['startedAt']),
      watchedSeconds: map['watchedSeconds'] ?? 0,
      userAnswers: map['userAnswers'] != null && map['userAnswers'].isNotEmpty
          ? map['userAnswers'].split(',').map<int>((e) => int.parse(e)).toList()
          : [],
    );
  }
}

// Modelo de Estadísticas del Usuario
class UserEducationStats {
  final String userId;
  final int totalPoints;
  final int completedCourses;
  final int perfectScores;
  final UserLevel level;
  final DateTime lastActivityDate;

  UserEducationStats({
    required this.userId,
    this.totalPoints = 0,
    this.completedCourses = 0,
    this.perfectScores = 0,
    UserLevel? level,
    DateTime? lastActivityDate,
  })  : level = level ?? _calculateLevel(totalPoints),
        lastActivityDate = lastActivityDate ?? DateTime.now();

  static UserLevel _calculateLevel(int points) {
    if (points >= 100) return UserLevel.experto;
    if (points >= 60) return UserLevel.avanzado;
    if (points >= 30) return UserLevel.intermedio;
    if (points >= 10) return UserLevel.principiante;
    return UserLevel.novato;
  }

  String get levelName {
    switch (level) {
      case UserLevel.novato:
        return 'Novato';
      case UserLevel.principiante:
        return 'Principiante';
      case UserLevel.intermedio:
        return 'Intermedio';
      case UserLevel.avanzado:
        return 'Avanzado';
      case UserLevel.experto:
        return 'Experto';
    }
  }

  String get levelIcon {
    switch (level) {
      case UserLevel.novato:
        return '🌱';
      case UserLevel.principiante:
        return '🌿';
      case UserLevel.intermedio:
        return '🌳';
      case UserLevel.avanzado:
        return '🏆';
      case UserLevel.experto:
        return '👑';
    }
  }

  int get pointsToNextLevel {
    switch (level) {
      case UserLevel.novato:
        return 10 - totalPoints;
      case UserLevel.principiante:
        return 30 - totalPoints;
      case UserLevel.intermedio:
        return 60 - totalPoints;
      case UserLevel.avanzado:
        return 100 - totalPoints;
      case UserLevel.experto:
        return 0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'completedCourses': completedCourses,
      'perfectScores': perfectScores,
      'level': level.index,
      'lastActivityDate': lastActivityDate.toIso8601String(),
    };
  }

  factory UserEducationStats.fromMap(Map<String, dynamic> map) {
    return UserEducationStats(
      userId: map['userId'],
      totalPoints: map['totalPoints'],
      completedCourses: map['completedCourses'],
      perfectScores: map['perfectScores'],
      level: UserLevel.values[map['level']],
      lastActivityDate: DateTime.parse(map['lastActivityDate']),
    );
  }
}