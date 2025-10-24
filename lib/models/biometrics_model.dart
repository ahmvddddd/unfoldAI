class BiometricEntry {
  final DateTime date;
  final double? hrv;
  final int? rhr;
  final int? steps;

  BiometricEntry({required this.date, this.hrv, this.rhr, this.steps});

  factory BiometricEntry.fromJson(Map<String, dynamic> j) => BiometricEntry(
    date: DateTime.parse(j['date'] as String),
    hrv: (j['hrv'] as num?)?.toDouble(),
    rhr: (j['rhr'] as num?)?.toInt(),
    steps: (j['steps'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'hrv': hrv,
    'rhr': rhr,
    'steps': steps,
  };
}

class JournalEntry {
  final DateTime date;
  final int? mood;
  final String? note;

  JournalEntry({required this.date, this.mood, this.note});

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
    date: DateTime.parse(j['date'] as String),
    mood: (j['mood'] as num?)?.toInt(),
    note: j['note'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'mood': mood,
    'note': note,
  };
}

class RollingStat {
  final DateTime date;
  final double mean;
  final double upper;
  final double lower;

  RollingStat({
    required this.date,
    required this.mean,
    required this.upper,
    required this.lower,
  });

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'mean': mean,
    'upper': upper,
    'lower': lower,
  };

  factory RollingStat.fromMap(Map<String, dynamic> m) => RollingStat(
    date: DateTime.parse(m['date'] as String),
    mean: (m['mean'] as num).toDouble(),
    upper: (m['upper'] as num).toDouble(),
    lower: (m['lower'] as num).toDouble(),
  );
}
