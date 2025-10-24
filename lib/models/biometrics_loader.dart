import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/biometrics_model.dart';

final largeDatasetProvider = StateProvider<bool>((ref) => false);
class BiometricsLoader {
  
  static Future<(List<BiometricEntry>, List<JournalEntry>)> loadAssets() async {
    List<BiometricEntry> parsed = [];
    List<JournalEntry> journals = [];

    try {
      final bioRaw = await rootBundle.loadString('assets/biometrics_90d.json');
      final List<dynamic> decoded = jsonDecode(bioRaw);
      parsed = decoded
          .map((e) => BiometricEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      parsed = _generateSynthetic(90);
    }

    try {
      final journalRaw = await rootBundle.loadString('assets/journals.json');
      final List<dynamic> decoded = jsonDecode(journalRaw);
      journals = decoded
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      journals = [
        JournalEntry(
          date: DateTime.now().subtract(const Duration(days: 10)),
          mood: 4,
          note: 'Sample note',
        ),
        JournalEntry(
          date: DateTime.now().subtract(const Duration(days: 2)),
          mood: 2,
          note: 'Bad sleep',
        ),
      ];
    }

    return (parsed, journals);
  }


  static List<BiometricEntry> expandToLarge(
    List<BiometricEntry> input, {
    int targetCount = 10000,
  }) {
    if (input.length < 2) return input;
    final start = input.first.date;
    final end = input.last.date;
    final totalSeconds = end.difference(start).inSeconds;
    final step = max(1, (totalSeconds ~/ (targetCount - 1)));
    final rand = Random();

    return List.generate(targetCount, (i) {
      final ts = start.add(Duration(seconds: i * step));
      final idx = ((i / targetCount) * input.length)
          .floor()
          .clamp(0, input.length - 1);
      final base = input[idx];
      final hrv = ((base.hrv ?? 60) + (rand.nextDouble() - 0.5) * 2)
          .clamp(0.0, 200.0);
      return BiometricEntry(
        date: ts,
        hrv: double.parse(hrv.toStringAsFixed(2)),
        rhr: base.rhr,
        steps: base.steps,
      );
    });
  }

  /// Computes 7-day rolling mean and ±1σ
  static List<RollingStat> computeRollingStats(
    List<BiometricEntry> data, {
    int window = 7,
  }) {
    final List<RollingStat> stats = [];
    if (data.isEmpty) return stats;
    final values = data.map((e) => e.hrv ?? double.nan).toList();
    for (int i = 0; i < data.length; i++) {
      final start = max(0, i - window + 1);
      final windowValues = <double>[];
      for (int j = start; j <= i; j++) {
        final v = values[j];
        if (!v.isNaN) windowValues.add(v);
      }
      if (windowValues.isEmpty) continue;
      final mean = windowValues.reduce((a, b) => a + b) / windowValues.length;
      final variance = windowValues
              .map((v) => (v - mean) * (v - mean))
              .reduce((a, b) => a + b) /
          windowValues.length;
      final sd = sqrt(variance);
      stats.add(RollingStat(
        date: data[i].date,
        mean: mean,
        upper: mean + sd,
        lower: mean - sd,
      ));
    }
    return stats;
  }

  /// Downsampling using LTTB (in isolate)
  static Future<List<Map<String, dynamic>>> lttbReduce(
    List<BiometricEntry> data, {
    int threshold = 500,
  }) async {
    final result = await compute(_lttbIsolate, {
      'data': data
          .map((e) => {
                't': e.date.millisecondsSinceEpoch,
                'v': e.hrv ?? 0.0,
              })
          .toList(),
      'threshold': threshold,
    });

    return (result as List)
        .map((m) => {
              't': m['t'] as int,
              'v': m['v'] as double,
            })
        .toList();
  }


  static List<BiometricEntry> _generateSynthetic(int days) {
    final rand = Random();
    final start = DateTime.now().subtract(Duration(days: days - 1));
    final List<BiometricEntry> out = [];
    double hrv = 60;
    int rhr = 65;
    int steps = 7000;
    for (int i = 0; i < days; i++) {
      hrv += rand.nextDouble() * 4 - 2;
      rhr += rand.nextInt(3) - 1;
      steps += rand.nextInt(700) - 350;
      out.add(
        BiometricEntry(
          date: start.add(Duration(days: i)),
          hrv: double.parse(hrv.toStringAsFixed(1)),
          rhr: rhr,
          steps: steps,
        ),
      );
    }
    return out;
  }
}

List<Map<String, double>> _lttbRaw(
  List<Map<String, double>> data,
  int threshold,
) {
  final int len = data.length;
  if (threshold >= len || threshold < 3) return data;
  final sampled = <Map<String, double>>[];
  final double every = (len - 2) / (threshold - 2);
  int a = 0;
  sampled.add({'t': data[a]['t']!, 'v': data[a]['v']!});
  for (int i = 0; i < threshold - 2; i++) {
    final int rangeStart = ((i + 1) * every).floor() + 1;
    final int rangeEnd = ((i + 2) * every).floor() + 1;
    final int rangeEndClamped = min(rangeEnd, len);

    double avgX = 0, avgY = 0;
    int count = 0;
    for (int ii = rangeStart; ii < rangeEndClamped; ii++) {
      avgX += data[ii]['t']!;
      avgY += data[ii]['v']!;
      count++;
    }
    if (count == 0) count = 1;
    avgX /= count;
    avgY /= count;

    final double ax = data[a]['t']!, ay = data[a]['v']!;
    double maxArea = -1;
    int nextA = rangeStart;

    final int rangeOffs = (i * every).floor() + 1;
    final int rangeTo = ((i + 1) * every).floor() + 1;
    for (int j = rangeOffs; j < min(len - 1, rangeTo); j++) {
      final double bx = data[j]['t']!, by = data[j]['v']!;
      final double area =
          ((ax - avgX) * (by - ay) - (ax - bx) * (avgY - ay)).abs() * 0.5;
      if (area > maxArea) {
        maxArea = area;
        nextA = j;
      }
    }

    sampled.add({'t': data[nextA]['t']!, 'v': data[nextA]['v']!});
    a = nextA;
  }
  sampled.add({'t': data[len - 1]['t']!, 'v': data[len - 1]['v']!});
  return sampled;
}

Future<List<Map<String, dynamic>>> _lttbIsolate(Map args) async {
  final data = (args['data'] as List)
      .map((m) =>
          {'t': (m['t'] as num).toDouble(), 'v': (m['v'] as num).toDouble()})
      .toList();
  final threshold = args['threshold'] as int;
  return _lttbRaw(data, threshold)
      .map((m) => {'t': m['t']!.toInt(), 'v': m['v']!})
      .toList();
}
