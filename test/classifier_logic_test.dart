import 'package:ar_heritage/core/constants/app_constants.dart';
import 'package:ar_heritage/core/utils/classifier.dart';
import 'dart:typed_data';

import 'package:ar_heritage/core/utils/classifier_preprocess.dart';
import 'package:ar_heritage/data/models/monument_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Classifier.mapSigmoidOutput', () {
    test('low raw score maps to nyatapola_temple', () {
      final result = Classifier.mapSigmoidOutput(0.1);
      expect(result.label, 'nyatapola_temple');
      expect(result.confidence, closeTo(0.9, 0.001));
      expect(result.isConfident, isTrue);
    });

    test('high raw score maps to others', () {
      final result = Classifier.mapSigmoidOutput(0.9);
      expect(result.label, 'others');
      expect(result.confidence, closeTo(0.9, 0.001));
    });

    test('threshold boundary at 0.80', () {
      final confident = Classifier.mapSigmoidOutput(0.19);
      expect(confident.label, 'nyatapola_temple');
      expect(confident.confidence, greaterThanOrEqualTo(0.80));
      expect(confident.isConfident, isTrue);

      final notMonument = Classifier.mapSigmoidOutput(0.21);
      expect(notMonument.label, 'others');
      expect(notMonument.isConfident, isFalse);
    });

    test('weak monument score is not confident', () {
      final result = Classifier.mapSigmoidOutput(0.35);
      expect(result.label, 'others');
    });
  });

  group('MonumentRegistry', () {
    test('findById returns nyatapola', () {
      final m = MonumentRegistry.findById('nyatapola_temple');
      expect(m, isNotNull);
      expect(m!.name, 'Nyatapola Temple');
    });

    test('unknown id returns null', () {
      expect(MonumentRegistry.findById('unknown'), isNull);
    });
  });

  group('AppConstants', () {
    test('cvDetectableIds includes nyatapola only', () {
      expect(AppConstants.cvDetectableIds, contains('nyatapola_temple'));
      expect(AppConstants.cvDetectableIds.length, 1);
    });
  });

  group('preprocessImageBytes', () {
    test('invalid bytes return null', () {
      expect(preprocessImageBytes(Uint8List(0)), isNull);
    });
  });
}
