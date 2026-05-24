// lib/data/models/monument_model.dart

import 'package:flutter/material.dart';

class MonumentGalleryItem {
  final String path;
  final String label;
  final int iconCode;
  final Color color;
  final List<Color> gradient;

  const MonumentGalleryItem({
    required this.path,
    required this.label,
    required this.iconCode,
    required this.color,
    required this.gradient,
  });

  IconData get icon {
    // ignore: non_const_argument_for_const_parameter
    return IconData(iconCode, fontFamily: 'MaterialIcons');
  }

  factory MonumentGalleryItem.fromJson(Map<String, dynamic> json) {
    Color parseHex(String hex) {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    }

    return MonumentGalleryItem(
      path: json['path'] as String,
      label: json['label'] as String,
      iconCode: json['icon_code'] as int,
      color: parseHex(json['hex_color'] as String),
      gradient: (json['hex_gradient'] as List)
          .map((h) => parseHex(h as String))
          .toList(),
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
    'nyatapola_temple': MonumentModel(
      id: 'nyatapola_temple',
      name: 'Nyatapola Temple',
      nepaliName: 'न्यातापोला मन्दिर',
      shortDescription: 'The tallest pagoda in Nepal — five tiers of timber and brick rising 30 m above Taumadhi Square.',
      fullHistory:
          'Built in 1702 by King Bhupatindra Malla in just seven months, Nyatapola is dedicated to the goddess Siddhi Lakshmi. '
          'Each of its five terraced plinths is guarded by a pair of figures — wrestlers, elephants, lions, griffins, and goddesses — '
          'each pair believed to be ten times more powerful than the one below. The temple survived the 2015 Gorkha earthquake with '
          'only minor damage, a testament to its masterful Newari earthquake-resistant construction.',
      architectureStyle: 'Newari Pagoda (Panchadewal)',
      builtYear: '1702 CE',
      builtBy: 'King Bhupatindra Malla',
      earthquakeNote: 'Sustained only superficial plaster cracks in the 2015 earthquake. Restoration completed by 2017.',
      heightLabel: '30 m',
      highlights: [
        '30 m tall – tallest pagoda in Nepal',
        '5 guardian pairs on ascending terraces',
        'Dedicated to Tantric goddess Siddhi Lakshmi',
        'Built in under 7 months',
        'UNESCO World Heritage Site component',
      ],
      imagePath: 'assets/images/monuments/nyatapola.jpg',
      gallery: [
        const MonumentGalleryItem(
          path: 'assets/images/monuments/nyatapola.jpg',
          label: 'CURRENT VIEW',
          iconCode: 62751, // Icons.account_balance_rounded
          color: Color(0x59C9A84C),
          gradient: [Color(0xFF1A0C06), Color(0xFF2A1A0A)],
        ),
      ],
      latitude: 27.6719,
      longitude: 85.4298,
    ),

    '55_window_palace': MonumentModel(
      id: '55_window_palace',
      name: '55-Window Palace',
      nepaliName: '५५ झ्याले दरबार',
      shortDescription: 'Royal palace facade featuring 55 intricately carved peacock windows — a masterpiece of Newari woodcraft.',
      fullHistory:
          'The Palace of 55 Windows (Pachpanna Jhyale Durbar) was the royal residence of the Malla kings. '
          'Its construction began under King Yaksha Malla in the 15th century and was expanded by Bhupatindra Malla, '
          'who added the iconic latticed and carved peacock windows. Each window is unique, featuring deities, '
          'animals, and geometric patterns carved in sal wood without a single nail.',
      architectureStyle: 'Newari Palace (Durbar)',
      builtYear: '1427 CE (expanded 1696 CE)',
      builtBy: 'King Yaksha Malla / King Bhupatindra Malla',
      earthquakeNote: 'The north wing collapsed in 2015. Reconstruction ongoing with original timber salvage.',
      heightLabel: '—',
      highlights: [
        '55 individually carved wooden windows',
        'No two windows share the same design',
        'Sal wood construction — no metal fasteners',
        'Former royal residence of Malla dynasty',
        'Active restoration project since 2016',
      ],
      imagePath: 'assets/images/monuments/55_window_palace.jpg',
      gallery: const [],
      latitude: 27.6716,
      longitude: 85.4289,
    ),

    'golden_gate': MonumentModel(
      id: 'golden_gate',
      name: 'Golden Gate (Lu Dhowka)',
      nepaliName: 'सुनको ढोका',
      shortDescription: 'Gilded copper gateway of the Palace — considered the finest example of its kind in the world.',
      fullHistory:
          'The Golden Gate, or Sun Dhoka ("Sun Door"), was erected in 1753 by King Ranjit Malla as the main entrance '
          'to the Palace of 55 Windows. Cast in gilded copper repousé, its surface is covered with a riot of deities, '
          'demons, and celestial beings arranged in a strict iconographic hierarchy. The central figure is Taleju Bhawani, '
          'the tutelary goddess of the Malla kings, framed by garuda, serpents, and tantric imagery.',
      architectureStyle: 'Repousé Gilded Copper Gateway',
      builtYear: '1753 CE',
      builtBy: 'King Ranjit Malla',
      earthquakeNote: 'The gate itself survived intact. The surrounding courtyard walls required significant rebuilding.',
      heightLabel: '~6 m',
      highlights: [
        'Cast gilded copper repousé — no painted gold',
        'Central deity: Taleju Bhawani (royal goddess)',
        'Considered finest gilded gate in the world',
        'Strictly hierarchical tantric iconography',
        'Torana (arch) features Garuda at apex',
      ],
      imagePath: 'assets/images/monuments/golden_gate.jpg',
      gallery: const [],
      latitude: 27.6717,
      longitude: 85.4290,
    ),

    'bhairavnath_temple': MonumentModel(
      id: 'bhairavnath_temple',
      name: 'Bhairavnath Temple',
      nepaliName: 'भैरवनाथ मन्दिर',
      shortDescription: 'Three-tiered pagoda dedicated to Bhairav — presiding deity of the famous Bisket Jatra festival.',
      fullHistory:
          'Originally a single-storey shrine, the Bhairavnath Temple was expanded to three storeys by King Jagat Prakash '
          'Malla in the early 18th century. It is the centre of the Bisket Jatra New Year festival (Nepali New Year, April), '
          'when a massive wooden chariot carrying the deity is pulled through the streets. '
          'The temple houses a small image of Bhairav, the terrifying form of Shiva.',
      architectureStyle: 'Newari Pagoda (Three-tiered)',
      builtYear: '1717 CE (current form)',
      builtBy: 'King Jagat Prakash Malla',
      earthquakeNote: 'Upper two storeys collapsed in 2015. Rebuilt brick-by-brick by 2019 using original materials.',
      heightLabel: '~12 m',
      highlights: [
        'Centre of Bisket Jatra New Year festival',
        'Houses a rare "hidden" Bhairav image',
        'Collapsed and fully rebuilt after 2015',
        'Chariot festival draws thousands yearly',
        'Located in Taumadhi Tole square',
      ],
      imagePath: 'assets/images/monuments/bhairavnath.jpg',
      gallery: const [],
      latitude: 27.6718,
      longitude: 85.4296,
    ),

    'lions_gate': MonumentModel(
      id: 'lions_gate',
      name: "Lion's Gate",
      nepaliName: 'सिंह द्वार',
      shortDescription: 'Stone entrance gate flanked by imposing lion statues — gateway to the Durbar Square precinct.',
      fullHistory:
          "The Lion's Gate marks the western entrance to the Palace complex. Its flanking stone lions, each ridden by a "
          "warrior figure, were carved during the reign of the Malla kings as protective guardians of the royal precinct. "
          "Nearby stand statues of King Bhupatindra Malla in a posture of worship, Ugrachandi Durga, and Bhairav — "
          "creating a layered protective threshold for the sacred inner palace.",
      architectureStyle: 'Stone Gateway (Dyochhen style)',
      builtYear: '~17th Century CE',
      builtBy: 'Malla Dynasty (attr.)',
      earthquakeNote: 'Gate pillars cracked but stood. Stone lions were stabilised and reset on their plinths in 2016.',
      heightLabel: '~5 m',
      highlights: [
        'Flanking lions symbolise royal protection',
        'Each lion carries a warrior-rider figure',
        'Adjacent to Ugrachandi and Bhairav statues',
        'Western threshold to the Durbar precinct',
        'Carved from single blocks of stone',
      ],
      imagePath: 'assets/images/monuments/lions_gate.jpg',
      gallery: const [],
      latitude: 27.6715,
      longitude: 85.4285,
    ),
  };

  static MonumentModel? findById(String id) => monuments[id];
}