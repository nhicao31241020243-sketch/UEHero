import 'package:flutter/material.dart';

class MentorModel {
  const MentorModel({
    required this.name,
    required this.jobTitle,
    required this.rating,
    required this.menteeCount,
    required this.avatarAsset,
    required this.bio,
    required this.avatarColor,
  });

  final String name;
  final String jobTitle;
  final double rating;
  final int menteeCount;
  final String avatarAsset;
  final String bio;
  final Color avatarColor;
}
