class Message {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String fromUserEmail;
  final String toUserId; // Usually admin ID
  final String subject;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final String? replyToMessageId;

  Message({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserEmail,
    required this.toUserId,
    required this.subject,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.replyToMessageId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      fromUserName: json['fromUserName'] as String,
      fromUserEmail: json['fromUserEmail'] as String,
      toUserId: json['toUserId'] as String,
      subject: json['subject'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] is int 
          ? (json['isRead'] as int) == 1 
          : (json['isRead'] as bool? ?? false),
      replyToMessageId: json['replyToMessageId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserEmail': fromUserEmail,
      'toUserId': toUserId,
      'subject': subject,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'replyToMessageId': replyToMessageId,
    };
  }

  Message copyWith({
    String? id,
    String? fromUserId,
    String? fromUserName,
    String? fromUserEmail,
    String? toUserId,
    String? subject,
    String? content,
    DateTime? createdAt,
    bool? isRead,
    String? replyToMessageId,
  }) {
    return Message(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserEmail: fromUserEmail ?? this.fromUserEmail,
      toUserId: toUserId ?? this.toUserId,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    );
  }
}
