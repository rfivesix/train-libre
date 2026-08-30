// lib/features/diary/domain/models/meal_entry.dart

/// Represents a logged meal event that groups food items logged together
/// and carries photo, origin, and capture metadata.
class MealEntry {
  final String id;
  final String? userId;
  final DateTime consumedAt;
  final String mealType; // Breakfast, Lunch, Dinner, Snack
  final String? title; // e.g. "Hähnchen mit Reis"
  final String source; // aiPhoto, aiVoice, aiText, barcode, manual, template
  final String? photoPath; // Relative to app support directory
  final String? photoThumbPath;
  final String? voiceTranscript;
  final String? captureMeta; // JSON: DepthScaleFacts, regions, provider
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MealEntry({
    required this.id,
    this.userId,
    required this.consumedAt,
    required this.mealType,
    this.title,
    required this.source,
    this.photoPath,
    this.photoThumbPath,
    this.voiceTranscript,
    this.captureMeta,
    this.createdAt,
    this.updatedAt,
  });

  MealEntry copyWith({
    String? id,
    String? userId,
    DateTime? consumedAt,
    String? mealType,
    String? title,
    String? source,
    String? photoPath,
    String? photoThumbPath,
    String? voiceTranscript,
    String? captureMeta,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      consumedAt: consumedAt ?? this.consumedAt,
      mealType: mealType ?? this.mealType,
      title: title ?? this.title,
      source: source ?? this.source,
      photoPath: photoPath ?? this.photoPath,
      photoThumbPath: photoThumbPath ?? this.photoThumbPath,
      voiceTranscript: voiceTranscript ?? this.voiceTranscript,
      captureMeta: captureMeta ?? this.captureMeta,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'consumed_at': consumedAt.toIso8601String(),
      'meal_type': mealType,
      'title': title,
      'source': source,
      'photo_path': photoPath,
      'photo_thumb_path': photoThumbPath,
      'voice_transcript': voiceTranscript,
      'capture_meta': captureMeta,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      consumedAt: DateTime.parse(map['consumed_at'] as String),
      mealType: map['meal_type'] as String,
      title: map['title'] as String?,
      source: map['source'] as String? ?? 'manual',
      photoPath: map['photo_path'] as String?,
      photoThumbPath: map['photo_thumb_path'] as String?,
      voiceTranscript: map['voice_transcript'] as String?,
      captureMeta: map['capture_meta'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
