import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/biometrics_controller.dart';
import '../../controllers/charts_controller.dart';
import '../../models/biometrics_loader.dart';
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
        title: const Text('Biometrics Dashboard',
        style: TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            tooltip: 'Toggle large dataset',
            onPressed: () async {
              try {
                ref.read(largeDatasetProvider.notifier).state = !isLarge;
                await ref.read(biometricsControllerProvider.notifier).reload();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error toggling dataset: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
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

      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 375;

          // 1. Loading skeleton
          if (state.loading) {
            return _buildSkeletonLoader(context);
          }

          // 2. Error state
          if (state.error != null) {
            return _buildErrorView(context, ref, state.error);
          }

          // 3. Empty data state
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

          // 4. Normal rendering with in-chart error guards
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 8 : 16,
              vertical: 8,
            ),
            child: Column(
              children: [
                _safeChart(
                  title: 'Heart Rate Variability (HRV)',
                  selector: (e) => e.hrv,
                  showBand: true,
                ),
                _safeChart(
                  title: 'Resting Heart Rate (RHR)',
                  selector: (e) => e.rhr?.toDouble(),
                  showBand: false,
                ),
                _safeChart(
                  title: 'Steps',
                  selector: (e) => e.steps?.toDouble(),
                  showBand: false,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Displays an inline error instead of crashing when chart data fails
  Widget _safeChart({
    required String title,
    required double? Function(BiometricEntry) selector,
    required bool showBand,
  }) {
    try {
      return BiometricsChart(
        title: title,
        valueSelector: selector,
        showHrvBand: showBand,
      );
    } catch (e) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        color: Colors.red.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Unable to render $title chart.\nError: $e',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
        ),
      );
    }
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildChartPlaceholder('Heart Rate Variability (HRV)'),
          const SizedBox(height: 16),
          _buildChartPlaceholder('Resting Heart Rate (RHR)'),
          const SizedBox(height: 16),
          _buildChartPlaceholder('Steps'),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            'Failed to load data.\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: () =>
                ref.read(biometricsControllerProvider.notifier).reload(),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder(String title) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
