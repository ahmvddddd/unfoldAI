import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/biometrics_controller.dart';
import '../../controllers/charts_controller.dart';
import '../../models/biometrics_model.dart';
import 'widgets/biometric_chart.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(biometricsControllerProvider);
    final range = ref.watch(rangeProvider);
    final isLarge = ref.watch(largeDatasetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometrics Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Toggle large dataset',
            onPressed: () =>
                ref.read(largeDatasetProvider.notifier).state = !isLarge,
            icon: Icon(isLarge ? Icons.storage : Icons.storage_outlined),
          ),
          PopupMenuButton<RangeOption>(
            onSelected: (r) => ref.read(rangeProvider.notifier).state = r,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: RangeOption.days7,
                child: Text(rangeLabel(RangeOption.days7)),
              ),
              PopupMenuItem(
                value: RangeOption.days30,
                child: Text(rangeLabel(RangeOption.days30)),
              ),
              PopupMenuItem(
                value: RangeOption.days90,
                child: Text(rangeLabel(RangeOption.days90)),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Center(child: Text(rangeLabel(range))),
            ),
          ),
        ],
      ),

      // --- BODY ---
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 375;

          if (state.loading) {
            return _skeleton(context);
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load data.\n${state.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () => ref
                        .read(biometricsControllerProvider.notifier)
                        .reload(),
                  ),
                ],
              ),
            );
          }

          if (state.allData.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No biometric data available yet.\nPlease check again later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 8 : 16,
              vertical: 8,
            ),
            child: Column(
              children: [
                BiometricsChart(
                  title: 'Heart Rate Variability (HRV)',
                  valueSelector: (BiometricEntry e) => e.hrv,
                  showHrvBand: true,
                ),
                BiometricsChart(
                  title: 'Resting Heart Rate (RHR)',
                  valueSelector: (BiometricEntry e) => e.rhr?.toDouble(),
                  showHrvBand: false,
                ),
                BiometricsChart(
                  title: 'Steps',
                  valueSelector: (BiometricEntry e) => e.steps?.toDouble(),
                  showHrvBand: false,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _skeleton(BuildContext c) => Skeletonizer(
    enabled: true,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SizedBox(height: 220),
        SizedBox(height: 16),
        SizedBox(height: 220),
        SizedBox(height: 16),
        SizedBox(height: 220),
      ],
    ),
  );
}
