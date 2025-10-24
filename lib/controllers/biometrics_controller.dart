import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/biometrics_loader.dart';
import '../models/biometrics_model.dart';
import 'charts_controller.dart';



class BiometricsState {
  final List<BiometricEntry> allData;
  final List<JournalEntry> journals;
  final List<RollingStat> hrvRolling;
  final bool loading;
  final Object? error;
  final bool isLargeDataset;

  const BiometricsState({
    this.allData = const [],
    this.journals = const [],
    this.hrvRolling = const [],
    this.loading = false,
    this.error,
    this.isLargeDataset = false,
  });

  BiometricsState copyWith({
    List<BiometricEntry>? allData,
    List<JournalEntry>? journals,
    List<RollingStat>? hrvRolling,
    bool? loading,
    Object? error,
    bool? isLargeDataset,
  }) {
    return BiometricsState(
      allData: allData ?? this.allData,
      journals: journals ?? this.journals,
      hrvRolling: hrvRolling ?? this.hrvRolling,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      isLargeDataset: isLargeDataset ?? this.isLargeDataset,
    );
  }
}

/// Riverpod controller
final biometricsControllerProvider =
    StateNotifierProvider<BiometricsController, BiometricsState>(
  (ref) => BiometricsController(ref),
);

class BiometricsController extends StateNotifier<BiometricsState> {
  final Ref ref;
  BiometricsController(this.ref) : super(const BiometricsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await Future.delayed(Duration(milliseconds: 700 + Random().nextInt(500)));

      final isLarge = ref.read(largeDatasetProvider);
      final (biometrics, journals) = await BiometricsLoader.loadAssets();

      var data = biometrics;
      if (isLarge) {
        data = BiometricsLoader.expandToLarge(biometrics);
        final reduced = await BiometricsLoader.lttbReduce(data);
        data = reduced
            .map((m) => BiometricEntry(
                  date: DateTime.fromMillisecondsSinceEpoch(m['t'] as int),
                  hrv: (m['v'] as num).toDouble(),
                ))
            .toList();
      }

      final rolling = BiometricsLoader.computeRollingStats(data);

      state = state.copyWith(
        allData: data,
        journals: journals,
        hrvRolling: rolling,
        isLargeDataset: isLarge,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e, loading: false);
    }
  }

  Future<void> reload() => load();

  void setHoveredDate(DateTime? dt) =>
      ref.read(chartHoverProvider.notifier).state = dt;
}
