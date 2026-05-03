import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final bool isUser;
  final DateTime timestamp;
  final bool hasAttachments; // 👈 أضفنا هذا السطر

  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.isUser,
    required this.timestamp,
    this.hasAttachments = false, // 👈 جعلناه اختيارياً بقيمة افتراضية
  });

  factory ChatMessage.fromMap(
      Map<String, dynamic> map, String docId, String currentUserId) {
    return ChatMessage(
      id: docId,
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      isUser: map['senderId'] == currentUserId,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasAttachments:
          map['hasAttachments'] ?? false, // 👈 قراءة الحالة من الفايربيس
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
      'hasAttachments': hasAttachments, // 👈 إرسال الحالة للفايربيس
    };
  }
}
