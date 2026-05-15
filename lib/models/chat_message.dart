import 'package:cloud_firestore/cloud_firestore.dart';

/// يمثل هيكل "الرسالة المفردة" داخل غرف المحادثة المباشرة.
/// يدير هوية المرسل [senderId] والوقت [timestamp] وما إذا كانت الرسالة تحتوي على مرفقات.
class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final bool isUser; // لتحديد جهة عرض الرسالة (يمين للمستخدم / يسار للمحامي)
  final DateTime timestamp;
  final bool hasAttachments;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.isUser,
    required this.timestamp,
    this.hasAttachments = false,
  });

  factory ChatMessage.fromMap(
      Map<String, dynamic> map, String docId, String currentUserId) {
    return ChatMessage(
      id: docId,
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      isUser: map['senderId'] == currentUserId,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasAttachments: map['hasAttachments'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
      'hasAttachments': hasAttachments,
    };
  }
}
