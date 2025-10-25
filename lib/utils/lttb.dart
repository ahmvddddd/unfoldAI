import '../models/biometrics_model.dart';

/// Performs Largest-Triangle-Three-Buckets downsampling to reduce large datasets
/// while preserving key visual trends.
///
/// [data] - The list of BiometricEntry objects sorted by date.
/// [threshold] - Desired number of output points.
List<BiometricEntry> lttbDownsample(List<BiometricEntry> data, int threshold) {
  if (threshold >= data.length || threshold == 0) return data;
  final sampled = <BiometricEntry>[];
  final bucketSize = (data.length - 2) / (threshold - 2);

  int a = 0; // First point index
  sampled.add(data[a]);

  for (int i = 0; i < threshold - 2; i++) {
    final rangeStart = (1 + (i * bucketSize)).floor();
    final rangeEnd = ((i + 1) * bucketSize).floor();
    final range = data.sublist(
      rangeStart,
      rangeEnd < data.length ? rangeEnd : data.length - 1,
    );

    final avgRangeStart = rangeEnd;
    final avgRangeEnd = ((i + 2) * bucketSize).floor().clamp(0, data.length - 1);
    final avgRange = data.sublist(avgRangeStart, avgRangeEnd);
    final avgX = avgRange.isEmpty
        ? 0.0
        : avgRange.map((e) => e.date.millisecondsSinceEpoch).reduce((a, b) => a + b) /
            avgRange.length;
    final avgY = avgRange.isEmpty
        ? 0.0
        : avgRange.map((e) => e.hrv ?? 0).reduce((a, b) => a + b) /
            avgRange.length;

    double maxArea = -1.0;
    int nextA = rangeStart;

    for (int j = 0; j < range.length; j++) {
      final pointA = data[a];
      final pointB = range[j];

      final area = ((pointA.date.millisecondsSinceEpoch - avgX) *
                  ((pointB.hrv ?? 0) - avgY) -
              (pointA.hrv ?? 0 - avgY) *
                  (pointB.date.millisecondsSinceEpoch - avgX))
          .abs() *
          0.5;

      if (area > maxArea) {
        maxArea = area;
        nextA = rangeStart + j;
      }
    }

    sampled.add(data[nextA]);
    a = nextA;
  }

  sampled.add(data.last);
  return sampled;
}
