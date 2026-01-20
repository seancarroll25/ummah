import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'local_halal_database.dart';

class HalalScanResult {
  final bool isHalal;
  final String verdict;
  final List<String> ingredients;
  final List<String> halalIngredients;
  final List<String> haramIngredients;
  final List<String> questionableIngredients;
  final String reasoning;
  final String? certification;
  final double confidence;

  HalalScanResult({
    required this.isHalal,
    required this.verdict,
    required this.ingredients,
    required this.halalIngredients,
    required this.haramIngredients,
    required this.questionableIngredients,
    required this.reasoning,
    this.certification,
    required this.confidence,
  });
}

class HalalScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String> extractTextFromImage(String imagePath) async {


    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      String extractedText = recognizedText.text;

      if (extractedText.isNotEmpty) {
        final preview = extractedText.length > 200
            ? extractedText.substring(0, 200) + '...'
            : extractedText;
      }

      return extractedText;
    } catch (e, st) {
      throw Exception('Failed to extract text from image');
    }
  }

  // Analyze ingredients using LOCAL DATABASE
  Future<HalalScanResult> analyzeIngredients(String extractedText) async {


    try {
      final analysis = LocalHalalDatabase.analyzeText(extractedText);
      final haramFound = analysis['haram'] as List<String>;
      final questionableFound = analysis['questionable'] as List<String>;


      // Determine verdict based ONLY on ingredients
      bool isHalal = false;
      String verdict = 'Unknown';
      String reasoning = '';
      double confidence = 0.5;

      if (haramFound.isNotEmpty) {
        // Contains haram ingredients
        isHalal = false;
        verdict = 'Haram';
        reasoning = 'This product contains haram ingredients: ${haramFound.join(", ")}. These ingredients are prohibited in Islam and the product should NOT be consumed.';
        confidence = 0.9;
      } else if (questionableFound.isNotEmpty) {
        // Contains questionable ingredients
        isHalal = false;
        verdict = 'Doubtful';
        reasoning = 'This product contains questionable ingredients: ${questionableFound.join(", ")}. These ingredients may come from haram sources. It is recommended to avoid this product or verify the source of these ingredients.';
        confidence = 0.7;
      } else {
        // No haram or questionable ingredients found
        isHalal = true;
        verdict = 'Halal';
        reasoning = 'No haram or questionable ingredients were detected in this product. Based on the visible ingredients, this product appears to be halal for consumption.';
        confidence = 0.75;
      }

      // Extract all visible ingredients (simple word extraction)
      final words = extractedText.toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .split(' ')
          .where((w) => w.length > 3)
          .toSet()
          .toList();


      return HalalScanResult(
        isHalal: isHalal,
        verdict: verdict,
        ingredients: words,
        halalIngredients: [],
        haramIngredients: haramFound,
        questionableIngredients: questionableFound,
        reasoning: reasoning,
        certification: null,  // No certification checking
        confidence: confidence,
      );
    } catch (e, st) {
     rethrow;
    }
  }

  // Full scan process
  Future<HalalScanResult> scanProduct(String imagePath) async {

    try {
      final extractedText = await extractTextFromImage(imagePath);

      if (extractedText.isEmpty) {
       throw Exception('No text found in image. Please ensure the image is clear and contains product information.');
      }

      final result = await analyzeIngredients(extractedText);


      return result;
    } catch (e, st) {
 rethrow;
    }
  }

  void dispose() {
    _textRecognizer.close();
 }
}