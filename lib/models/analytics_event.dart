import 'dart:convert';

class AnalyticsEvent {
  final String id;
  final String eventName;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final String? userId;

  AnalyticsEvent({
    required this.id,
    required this.eventName,
    this.data,
    required this.createdAt,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_name': eventName,
      'event_data': data != null ? jsonEncode(data) : null,
      'created_at': createdAt.toUtc().toIso8601String(),
      'user_id': userId,
    };
  }

  factory AnalyticsEvent.fromMap(Map<String, dynamic> map) {
    return AnalyticsEvent(
      id: map['id'],
      eventName: map['event_name'],
      data: map['event_data'] != null ? jsonDecode(map['event_data']) : null,
      createdAt: DateTime.parse(map['created_at']),
      userId: map['user_id'],
    );
  }
}
