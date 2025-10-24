import 'package:flutter_riverpod/legacy.dart';

enum RangeType { days7, days30, days90 }

final rangeProvider = StateProvider<RangeType>((ref) => RangeType.days90);

String rangeLabel(RangeType r) {
  switch (r) {
    case RangeType.days7:
      return '7d';
    case RangeType.days30:
      return '30d';
    case RangeType.days90:
      return '90d';
  }
}
