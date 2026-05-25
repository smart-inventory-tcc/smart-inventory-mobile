import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;

class ActivityLogger {
  static Future<void> logActivity({
    required int userId,
    required String username,
    required String role,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('user_activity_logs').add({
        'userId': userId,
        'username': username,
        'role': role,
        'action': action,
        'device_info': Platform.operatingSystem,
        'metadata': metadata ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Gagal mencatat log aktivitas: $e');
    }
  }

  static Future<void> logTempScanSession({
    required String sessionId,
    required int userId,
    required String barcode,
    required int itemId,
    required int quantity,
    required String lastAction,
    required String status,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('temp_scan_sessions').doc(sessionId).set({
        'scanSessionId': sessionId,
        'userId': userId,
        'barcode': barcode,
        'itemId': itemId,
        'quantity': quantity,
        'lastAction': lastAction,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Gagal mencatat temp scan session: $e');
    }
  }
}
