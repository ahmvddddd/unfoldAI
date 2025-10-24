import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../controllers/biometrics_controller.dart';
import '../../../controllers/charts_controller.dart';
import '../../../models/biometrics_model.dart';

typedef ValueSelector = double? Function(BiometricEntry e);

class BiometricsChart extends ConsumerStatefulWidget {
  final String title;
  final ValueSelector valueSelector;
  final bool showHrvBand;

  const BiometricsChart({
    super.key,
    required this.title,
    required this.valueSelector,
    this.showHrvBand = false,
  });

  @override
  ConsumerState<BiometricsChart> createState() => _BiometricsChartState();
}

class _BiometricsChartState extends ConsumerState<BiometricsChart> {
  late TrackballBehavior _trackballBehavior;
  ZoomPanBehavior? _zoomPanBehavior;

  @override
  void initState() {
    super.initState();
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipSettings: const InteractiveTooltip(enable: true),
    );
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableMouseWheelZooming: true,
      zoomMode: ZoomMode.x,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(biometricsControllerProvider);
    final hover = ref.watch(chartHoverProvider);

    // 1. Loading state
    if (state.loading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Error state
    if (state.error != null) {
      return _errorCard('Error loading data: ${state.error}');
    }

    // 3. Validate data
    final data = state.allData;
    if (data.isEmpty) {
      return _emptyCard('No biometric data available');
    }

    // Map entries safely
    final seriesData = data
        .map((e) => _Point(e.date, widget.valueSelector(e)))
        .where((p) => p.y != null)
        .toList();

    if (seriesData.isEmpty) {
      return _emptyCard('No valid data points for ${widget.title}');
    }

    final hrvRolling = state.hrvRolling;
    final hasRolling = widget.showHrvBand && hrvRolling.isNotEmpty;

    // Determine a safe Y reference for annotations
    final safeY = (seriesData.isNotEmpty ? seriesData.first.y : 0) ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 240,
          child: SfCartesianChart(
            title: ChartTitle(text: widget.title),
            plotAreaBorderWidth: 0,
            zoomPanBehavior: _zoomPanBehavior,
            trackballBehavior: _trackballBehavior,
            primaryXAxis: DateTimeAxis(
              majorGridLines: const MajorGridLines(width: 0.2),
              dateFormat: null,
            ),
            primaryYAxis: NumericAxis(
              majorGridLines: const MajorGridLines(width: 0.2),
            ),

            // 4. Guarded annotations
            annotations: [
              for (final j in state.journals)
                CartesianChartAnnotation(
                  coordinateUnit: CoordinateUnit.point,
                  x: j.date,
                  y: safeY,
                  widget: GestureDetector(
                    onTap: () => _showJournalDialog(context, j),
                    child: const Icon(Icons.bookmark,
                        size: 14, color: Colors.orange),
                  ),
                ),
              if (hover != null)
                CartesianChartAnnotation(
                  coordinateUnit: CoordinateUnit.point,
                  x: hover,
                  y: safeY,
                  widget: Container(
                    width: 2,
                    height: 200,
                    color: Colors.blue.withOpacity(0.25),
                  ),
                ),
            ],

            // 5. Hover sync handling
            onCrosshairPositionChanging: (CrosshairRenderArgs args) {
              final val = args.value;
              if (val is DateTime) {
                ref.read(chartHoverProvider.notifier).state = val;
              } else if (val is num) {
                ref.read(chartHoverProvider.notifier).state =
                    DateTime.fromMillisecondsSinceEpoch(val.toInt());
              } else {
                ref.read(chartHoverProvider.notifier).state = null;
              }
            },

            // 6. Safe series
            series: <CartesianSeries>[
              LineSeries<_Point, DateTime>(
                dataSource: seriesData,
                xValueMapper: (_Point p, _) => p.x,
                yValueMapper: (_Point p, _) => p.y,
                color: Theme.of(context).colorScheme.primary,
                width: 2,
                markerSettings: const MarkerSettings(isVisible: false),
              ),

              if (hasRolling)
                RangeAreaSeries<RollingStat, DateTime>(
                  dataSource: hrvRolling,
                  xValueMapper: (RollingStat rs, _) => rs.date,
                  highValueMapper: (RollingStat rs, _) => rs.upper,
                  lowValueMapper: (RollingStat rs, _) => rs.lower,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.12),
                  borderWidth: 0,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Error fallback card
  Widget _errorCard(String message) {
    return Card(
      color: Colors.red.withOpacity(0.1),
      margin: const EdgeInsets.all(12),
      child: SizedBox(
        height: 220,
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
          ),
        ),
      ),
    );
  }

  /// Empty data fallback card
  Widget _emptyCard(String message) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: SizedBox(
        height: 220,
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      ),
    );
  }

  /// Journal annotation dialog
  void _showJournalDialog(BuildContext context, JournalEntry j) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Journal ${j.mood ?? ''}'),
        content: Text(j.note ?? 'No additional notes'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _Point {
  final DateTime x;
  final double? y;
  _Point(this.x, this.y);
}
