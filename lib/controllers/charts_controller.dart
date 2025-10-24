import 'package:flutter_riverpod/legacy.dart';

final chartHoverProvider = StateProvider<DateTime?>((ref) => null);
final largeDatasetProvider = StateProvider<bool>((ref) => false);

enum RangeOption { days7, days30, days90 }

final rangeProvider = StateProvider<RangeOption>((ref) => RangeOption.days90);

String rangeLabel(RangeOption r) {
  switch (r) {
    case RangeOption.days7:
      return '7d';
    case RangeOption.days30:
      return '30d';
    case RangeOption.days90:
      return '90d';
  }
}
