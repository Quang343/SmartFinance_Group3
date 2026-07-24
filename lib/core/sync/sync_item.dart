import 'dart:convert';

enum SyncAction { create, update, delete }
enum SyncStatus { pending, error }

class SyncItem {
  final String id; // Unique ID for the queue item
  final String entityId; // The ID of the entity (e.g., transaction ID)
  final String collection; // e.g., 'transactions', 'invoices'
  final SyncAction action;
  final Map<String, dynamic> payload;
  final SyncStatus status;
  final String? errorMessage;
  final DateTime createdAt;

  SyncItem({
    required this.id,
    required this.entityId,
    required this.collection,
    required this.action,
    required this.payload,
    this.status = SyncStatus.pending,
    this.errorMessage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityId': entityId,
      'collection': collection,
      'action': action.name,
      'payload': jsonEncode(payload),
      'status': status.name,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SyncItem.fromMap(Map<String, dynamic> map) {
    return SyncItem(
      id: map['id'],
      entityId: map['entityId'],
      collection: map['collection'],
      action: SyncAction.values.firstWhere((e) => e.name == map['action']),
      payload: jsonDecode(map['payload']),
      status: SyncStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => SyncStatus.pending),
      errorMessage: map['errorMessage'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  SyncItem copyWith({
    SyncStatus? status,
    String? errorMessage,
  }) {
    return SyncItem(
      id: id,
      entityId: entityId,
      collection: collection,
      action: action,
      payload: payload,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt,
    );
  }
}
