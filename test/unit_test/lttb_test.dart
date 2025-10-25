import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/biometrics_model.dart';
import 'package:myapp/utils/lttb.dart';

void main() {
  test('LTTB reduces large dataset while preserving key points', () {
    final data = List.generate(
      10000,
      (i) => BiometricEntry(
        date: DateTime(2020).add(Duration(days: i)),
        hrv: i.toDouble(),
      ),
    );

    final reduced = lttbDownsample(data, 500);

    expect(reduced.length <= 500, true);
    expect(reduced.first.hrv, equals(0));
    expect(reduced.last.hrv, equals(9999));
  });
}
