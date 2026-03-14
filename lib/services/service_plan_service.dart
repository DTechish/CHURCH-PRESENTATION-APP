// ─────────────────────────────────────────────────────────────────────────────
// SERVICE PLAN SERVICE
// Handles JSON serialisation and file I/O for saved service plans.
// HomeScreen calls these methods; no widget ever touches the file system.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models.dart';

class ServicePlanService {
  // ── Directory ──────────────────────────────────────────────────────────────

  Future<Directory> _servicesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/ChurchPresenter/services');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  /// Serialise [plan] to disk as JSON.
  /// Returns the file path on success, null on failure.
  Future<String?> save({
    required String title,
    required DateTime date,
    required List<PlanSection> sections,
  }) async {
    try {
      final dir = await _servicesDir();
      final slug = title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final stamp = date.toIso8601String().split('T').first;
      final file = File('${dir.path}/${stamp}_$slug.json');

      final payload = {
        'title': title,
        'date': date.toIso8601String(),
        'sections': sections.map((s) => s.toJson()).toList(),
      };

      await file.writeAsString(jsonEncode(payload));
      return file.path;
    } catch (_) {
      return null;
    }
  }

  // ── Load list ──────────────────────────────────────────────────────────────

  /// Returns a list of saved plan files sorted newest-first.
  Future<List<File>> listSaved() async {
    final dir = await _servicesDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  // ── Load one ───────────────────────────────────────────────────────────────

  /// Read and deserialise a service plan from [file].
  /// Returns null if parsing fails.
  Future<ServicePlanData?> load(File file) async {
    try {
      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ServicePlanData.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> delete(File file) async {
    if (file.existsSync()) file.deleteSync();
  }
}

// ── Transfer object returned by ServicePlanService.load() ──────────────────

class ServicePlanData {
  const ServicePlanData({
    required this.title,
    required this.date,
    required this.sections,
  });

  final String title;
  final DateTime date;
  final List<PlanSection> sections;

  factory ServicePlanData.fromJson(Map<String, dynamic> json) {
    final rawSections = (json['sections'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return ServicePlanData(
      title: json['title'] as String? ?? 'Service',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      sections: rawSections.map((m) => PlanSection.fromJson(m)).whereType<PlanSection>().toList(),
    );
  }
}
