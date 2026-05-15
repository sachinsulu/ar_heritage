// lib/data/models/monument_model.dart

import 'package:flutter/material.dart';

class MonumentGalleryItem {
  final String path;
  final String label;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  const MonumentGalleryItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  factory MonumentGalleryItem.fromJson(Map<String, dynamic> json) {
    Color parseHex(String hex) {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    }

    return MonumentGalleryItem(
      path: json['path'] as String,
      label: json['label'] as String,
      icon: IconData(json['icon_code'] as int, fontFamily: 'MaterialIcons'),
      color: parseHex(json['hex_color'] as String),
      gradient: (json['hex_gradient'] as List).map((h) => parseHex(h as String)).toList(),
    );
  }
}

class MonumentModel {
  final String id;
  final String name;
  final String nepaliName;
  final String shortDescription;
  final String fullHistory;
  final String architectureStyle;
  final String builtYear;
  final String builtBy;
  final String earthquakeNote;
  final String heightLabel;
  final List<String> highlights;
  final String imagePath;
  final List<MonumentGalleryItem> gallery;
  final double latitude;
  final double longitude;

  const MonumentModel({
    required this.id,
    required this.name,
    required this.nepaliName,
    required this.shortDescription,
    required this.fullHistory,
    required this.architectureStyle,
    required this.builtYear,
    required this.builtBy,
    required this.earthquakeNote,
    required this.heightLabel,
    required this.highlights,
    required this.imagePath,
    required this.gallery,
    required this.latitude,
    required this.longitude,
  });

  factory MonumentModel.fromJson(Map<String, dynamic> json) {
    return MonumentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nepaliName: json['nepali_name'] as String,
      shortDescription: json['short_description'] as String,
      fullHistory: json['full_history'] ?? '',
      architectureStyle: json['architecture_style'] as String,
      builtYear: json['built_year'] as String,
      builtBy: json['built_by'] ?? '',
      earthquakeNote: json['earthquake_note'] ?? '',
      heightLabel: json['height_label'] as String,
      highlights: json['highlights'] != null 
          ? List<String>.from(json['highlights']) 
          : [],
      imagePath: json['image_path'] as String,
      gallery: json['gallery'] != null 
          ? (json['gallery'] as List).map((i) => MonumentGalleryItem.fromJson(i as Map<String, dynamic>)).toList() 
          : [],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class MonumentRegistry {
  MonumentRegistry._();

  static final Map<String, MonumentModel> monuments = {
   
  };

  static MonumentModel? findById(String id) => monuments[id];
}
