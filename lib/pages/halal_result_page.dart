import 'dart:io';
import 'package:flutter/material.dart';
import '../services/halal_scanner_service.dart';

class HalalScanResultPage extends StatefulWidget {
  final String imagePath;
  final HalalScannerService scannerService;

  const HalalScanResultPage({
    super.key,
    required this.imagePath,
    required this.scannerService,
  });

  @override
  State<HalalScanResultPage> createState() => _HalalScanResultPageState();
}

class _HalalScanResultPageState extends State<HalalScanResultPage> {
  bool _isAnalyzing = true;
  HalalScanResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _analyzeProduct();
  }

  Future<void> _analyzeProduct() async {
    debugPrint('[RESULT_PAGE] Starting analysis...');
    try {
      final result = await widget.scannerService.scanProduct(widget.imagePath);
      if (mounted) {
        setState(() {
          _result = result;
          _isAnalyzing = false;
        });
        debugPrint('[RESULT_PAGE] ✓ Analysis complete, showing results');
      }
    } catch (e) {
      debugPrint('[RESULT_PAGE] ❌ Analysis failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results'),
        backgroundColor: const Color(0xFF13A694),
      ),
      body: _isAnalyzing
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Analyzing product...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            Text(
              'This may take a few seconds',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      )
          : _errorMessage != null
          ? _buildErrorView()
          : _buildResultView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Error',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF13A694),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Product Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: FileImage(File(widget.imagePath)),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Verdict Card
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _result!.isHalal ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _result!.isHalal ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _result!.isHalal ? Icons.check_circle : Icons.cancel,
                  size: 64,
                  color: _result!.isHalal ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _result!.verdict,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _result!.isHalal ? Colors.green[700] : Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confidence: ${(_result!.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Ingredients Breakdown
          if (_result!.haramIngredients.isNotEmpty)
            _buildIngredientsSection(
              'Haram Ingredients',
              _result!.haramIngredients,
              Colors.red,
            ),

          if (_result!.questionableIngredients.isNotEmpty)
            _buildIngredientsSection(
              'Questionable Ingredients',
              _result!.questionableIngredients,
              Colors.orange,
            ),

          // Reasoning
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _result!.reasoning,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),

          // Disclaimer
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This scan is based on ingredient analysis only. It cannot verify slaughter methods or cross-contamination. For certainty, look for official Halal certification.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Scan Another'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF13A694),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(String title, List<String> ingredients, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                title.contains('Haram')
                    ? Icons.cancel
                    : title.contains('Questionable')
                    ? Icons.help
                    : Icons.check_circle,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color == Colors.red
                      ? Colors.red[700]
                      : color == Colors.orange
                      ? Colors.orange[700]
                      : Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ingredients
                .map((ingredient) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                ingredient,
                style: TextStyle(
                  fontSize: 12,
                  color: color == Colors.red
                      ? Colors.red[800]
                      : color == Colors.orange
                      ? Colors.orange[800]
                      : Colors.green[800],
                ),
              ),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }
}