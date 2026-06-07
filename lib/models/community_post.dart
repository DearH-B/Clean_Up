import 'package:flutter/material.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.name,
    required this.place,
    required this.message,
    required this.likes,
    required this.colorValue,
    required this.iconCodePoint,
  });

  final String id;
  final String name;
  final String place;
  final String message;
  final int likes;
  final int colorValue;
  final int iconCodePoint;

  Color get color => Color(colorValue);

  IconData get icon => Icons.auto_awesome;

  factory CommunityPost.fromJson(Map<String, Object?> json) {
    return CommunityPost(
      id: json['id'] as String,
      name: json['name'] as String,
      place: json['place'] as String,
      message: json['message'] as String,
      likes: json['likes'] as int,
      colorValue: json['colorValue'] as int,
      iconCodePoint: json['iconCodePoint'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'place': place,
      'message': message,
      'likes': likes,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
    };
  }
}
