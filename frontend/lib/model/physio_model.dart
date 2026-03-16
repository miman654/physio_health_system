/// 生理数据模型（与/data/query/physio返回的data数组项对应）
class PhysioModel {
  int? id;
  int? heartRate;
  int? spo2;
  double? temp;
  int? scene; // 0静息 1运动 2睡眠
  String? timestamp; // 接口时间字段

  PhysioModel({
    this.id,
    this.heartRate,
    this.spo2,
    this.temp,
    this.scene,
    this.timestamp,
  });

  PhysioModel.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    heartRate = json["heart_rate"];
    spo2 = json["spo2"];
    temp = json["temp"];
    scene = json["scene"];
    timestamp = json["timestamp"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["id"] = id;
    data["heart_rate"] = heartRate;
    data["spo2"] = spo2;
    data["temp"] = temp;
    data["scene"] = scene;
    data["timestamp"] = timestamp;
    return data;
  }

  // 场景数字转文字，方便页面展示
  String getSceneText() {
    switch (scene) {
      case 0:
        return "静息";
      case 1:
        return "运动";
      case 2:
        return "睡眠";
      default:
        return "未知";
    }
  }
}

/// 睡眠记录模型（与/data/query/sleep返回的data数组项对应）
class SleepModel {
  int? id;
  String? sleepStart;
  String? sleepEnd;
  int? sleepScore;
  int? deepSleepDuration;
  int? lightSleepDuration;

  SleepModel({
    this.id,
    this.sleepStart,
    this.sleepEnd,
    this.sleepScore,
    this.deepSleepDuration,
    this.lightSleepDuration,
  });

  SleepModel.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    sleepStart = json["sleep_start"];
    sleepEnd = json["sleep_end"];
    sleepScore = json["sleep_score"];
    deepSleepDuration = json["deep_sleep_duration"];
    lightSleepDuration = json["light_sleep_duration"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["id"] = id;
    data["sleep_start"] = sleepStart;
    data["sleep_end"] = sleepEnd;
    data["sleep_score"] = sleepScore;
    data["deep_sleep_duration"] = deepSleepDuration;
    data["light_sleep_duration"] = lightSleepDuration;
    return data;
  }
}

/// 运动记录模型（与/data/query/sport返回的data数组项对应）
class SportModel {
  int? id;
  String? sportType;
  String? sportStart;
  String? sportEnd;
  int? avgHeartRate;
  double? calorie;

  SportModel({
    this.id,
    this.sportType,
    this.sportStart,
    this.sportEnd,
    this.avgHeartRate,
    this.calorie,
  });

  SportModel.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    sportType = json["sport_type"];
    sportStart = json["sport_start"];
    sportEnd = json["sport_end"];
    avgHeartRate = json["avg_heart_rate"];
    calorie = json["calorie"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["id"] = id;
    data["sport_type"] = sportType;
    data["sport_start"] = sportStart;
    data["sport_end"] = sportEnd;
    data["avg_heart_rate"] = avgHeartRate;
    data["calorie"] = calorie;
    return data;
  }
}

/// AI分析结果模型
class AIAnalysisModel {
  String? analysisTime;
  List<String>? suggestions;
  String? sportType;
  int? sportDuration;
  List<String>? nutritionSuggestions;

  AIAnalysisModel({
    this.analysisTime,
    this.suggestions,
    this.sportType,
    this.sportDuration,
    this.nutritionSuggestions,
  });

  AIAnalysisModel.fromJson(Map<String, dynamic> json) {
    analysisTime = json["analysis_time"];
    suggestions = json["suggestions"]?.cast<String>();
    sportType = json["sport_type"];
    sportDuration = json["sport_duration"];
    nutritionSuggestions = json["nutrition_suggestions"]?.cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["analysis_time"] = analysisTime;
    data["suggestions"] = suggestions;
    data["sport_type"] = sportType;
    data["sport_duration"] = sportDuration;
    data["nutrition_suggestions"] = nutritionSuggestions;
    return data;
  }
}
