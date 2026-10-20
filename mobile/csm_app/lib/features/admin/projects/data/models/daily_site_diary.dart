enum WeatherType {
  sunny,
  cloudy,
  rainy,
  windy,
  storm,
}

class DailySiteDiary {
  const DailySiteDiary({
    required this.id,
    required this.tenantId,
    required this.siteId,
    this.projectId,
    required this.diaryDate,
    required this.weather,
    required this.temperature,
    required this.workforceCount,
    required this.equipmentInUse,
    required this.workPerformed,
    this.delayReason,
    this.safetyObservation,
    this.siteName,
    this.projectName,
  });

  final String id;
  final String tenantId;
  final String siteId;
  final String? projectId;

  final DateTime diaryDate;
  final WeatherType weather;
  final double temperature;
  final int workforceCount;
  final int equipmentInUse;

  final String workPerformed;
  final String? delayReason;
  final String? safetyObservation;

  final String? siteName;
  final String? projectName;

  factory DailySiteDiary.fromJson(Map<String, dynamic> json) {
    return DailySiteDiary(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      siteId: json['siteId'] as String,
      projectId: json['projectId'] as String?,
      diaryDate: DateTime.parse(json['diaryDate'] as String),
      weather: (() {
        final value = json['weather'];

        if (value is int) {
          return WeatherType.values[value];
        }

        if (value is String) {
          return WeatherType.values.firstWhere(
                (e) => e.name.toLowerCase() == value.toLowerCase(),
            orElse: () => WeatherType.sunny,
          );
        }

        return WeatherType.sunny;
      })(),
      temperature: (json['temperature'] as num).toDouble(),
      workforceCount: json['workforceCount'] as int,
      equipmentInUse: json['equipmentInUse'] as int,
      workPerformed: json['workPerformed'] as String,
      delayReason: json['delayReason'] as String?,
      safetyObservation: json['safetyObservation'] as String?,
      siteName: json['siteName'] as String?,
      projectName: json['projectName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'siteId': siteId,
      'projectId': projectId,
      'diaryDate': diaryDate.toIso8601String().split('T').first,
      'weather': weather.name,
      'temperature': temperature,
      'workforceCount': workforceCount,
      'equipmentInUse': equipmentInUse,
      'workPerformed': workPerformed,
      'delayReason': delayReason,
      'safetyObservation': safetyObservation,
      'siteName': siteName,
      'projectName': projectName,
    };
  }
}