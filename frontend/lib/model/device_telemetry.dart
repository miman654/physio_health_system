class DeviceLatestSnapshot {
  final String deviceId;
  final int? seq;
  final int? timestamp;
  final int? serverReceivedAt;
  final int? lastDeviceTimeMs;
  final double? temp;
  final int? heartRate;
  final double? spo2;
  final int? validTemp;
  final int? validHeartRate;
  final int? validSpo2;
  final String? reason;
  final int? contact;
  final double? signal;
  final int? updatedAt;

  const DeviceLatestSnapshot({
    required this.deviceId,
    this.seq,
    this.timestamp,
    this.serverReceivedAt,
    this.lastDeviceTimeMs,
    this.temp,
    this.heartRate,
    this.spo2,
    this.validTemp,
    this.validHeartRate,
    this.validSpo2,
    this.reason,
    this.contact,
    this.signal,
    this.updatedAt,
  });

  factory DeviceLatestSnapshot.fromJson(Map<String, dynamic> json) {
    return DeviceLatestSnapshot(
      deviceId: json['device_id']?.toString() ?? '',
      seq: _asInt(json['seq']),
      timestamp: _asInt(json['timestamp']),
      serverReceivedAt: _asInt(json['server_received_at']),
      lastDeviceTimeMs: _asInt(json['last_ts_device_ms']),
      temp: _asDouble(json['temp']),
      heartRate: _asInt(json['heart_rate']),
      spo2: _asDouble(json['spo2']),
      validTemp: _asInt(json['valid_temp']),
      validHeartRate: _asInt(json['valid_heart_rate']),
      validSpo2: _asInt(json['valid_spo2']),
      reason: json['reason']?.toString(),
      contact: _asInt(json['contact']),
      signal: _asDouble(json['signal']),
      updatedAt: _asInt(json['updated_at']),
    );
  }

  bool get hasHeartRate => heartRate != null;
  bool get hasSpo2 => spo2 != null;
  bool get hasTemp => temp != null;

  Map<String, dynamic> toMap() {
    return {
      'device_id': deviceId,
      'seq': seq,
      'timestamp': timestamp,
      'server_received_at': serverReceivedAt,
      'last_ts_device_ms': lastDeviceTimeMs,
      'temp': temp,
      'heart_rate': heartRate,
      'spo2': spo2,
      'valid_temp': validTemp,
      'valid_heart_rate': validHeartRate,
      'valid_spo2': validSpo2,
      'reason': reason,
      'contact': contact,
      'signal': signal,
      'updated_at': updatedAt,
    };
  }
}

class DeviceHistoryPoint {
  final int timestamp;
  final int? serverReceivedAt;
  final int? deviceTimeMs;
  final int? seq;
  final double? temp;
  final int? heartRate;
  final double? spo2;
  final int? validTemp;
  final int? validHeartRate;
  final int? validSpo2;
  final String? reason;
  final int? contact;
  final double? signal;

  const DeviceHistoryPoint({
    required this.timestamp,
    this.serverReceivedAt,
    this.deviceTimeMs,
    this.seq,
    this.temp,
    this.heartRate,
    this.spo2,
    this.validTemp,
    this.validHeartRate,
    this.validSpo2,
    this.reason,
    this.contact,
    this.signal,
  });

  factory DeviceHistoryPoint.fromJson(Map<String, dynamic> json) {
    return DeviceHistoryPoint(
      timestamp: _asInt(json['timestamp']) ?? 0,
      serverReceivedAt: _asInt(json['server_received_at']),
      deviceTimeMs: _asInt(json['device_time_ms']),
      seq: _asInt(json['seq']),
      temp: _asDouble(json['temp']),
      heartRate: _asInt(json['heart_rate']),
      spo2: _asDouble(json['spo2']),
      validTemp: _asInt(json['valid_temp']),
      validHeartRate: _asInt(json['valid_heart_rate']),
      validSpo2: _asInt(json['valid_spo2']),
      reason: json['reason']?.toString(),
      contact: _asInt(json['contact']),
      signal: _asDouble(json['signal']),
    );
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}
