import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String barcode;
  final int currentStock;
  final bool isRead;
  final int itemId;
  final String itemName;
  final String level;
  final String message;
  final int minStock;
  final String? scanSessionId;
  final String type;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.barcode,
    required this.currentStock,
    required this.isRead,
    required this.itemId,
    required this.itemName,
    required this.level,
    required this.message,
    required this.minStock,
    this.scanSessionId,
    required this.type,
    this.createdAt,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return NotificationModel(
      id: docId,
      barcode: data['barcode']?.toString() ?? '',
      currentStock: data['currentStock'] as int? ?? 0,
      isRead: data['isRead'] as bool? ?? false,
      itemId: data['itemId'] as int? ?? 0,
      itemName: data['itemName']?.toString() ?? '',
      level: data['level']?.toString() ?? 'info',
      message: data['message']?.toString() ?? '',
      minStock: data['minStock'] as int? ?? 0,
      scanSessionId: data['scanSessionId']?.toString(),
      type: data['type']?.toString() ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }
}
