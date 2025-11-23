import '../../core/repositories/base_repository.dart';
import '../../core/constants/database_constants.dart';
import '../../models/message.dart';

class MessageRepository extends BaseRepository {
  static final MessageRepository _instance = MessageRepository._internal();
  static MessageRepository get instance => _instance;
  MessageRepository._internal();

  // Create a new message
  Future<String?> createMessage(Message message) async {
    try {
      final messageData = {
        DatabaseConstants.messageId: message.id,
        DatabaseConstants.messageFromUserId: message.fromUserId,
        DatabaseConstants.messageFromUserName: message.fromUserName,
        DatabaseConstants.messageFromUserEmail: message.fromUserEmail,
        DatabaseConstants.messageToUserId: message.toUserId,
        DatabaseConstants.messageSubject: message.subject,
        DatabaseConstants.messageContent: message.content,
        DatabaseConstants.messageCreatedAt: message.createdAt.toIso8601String(),
        DatabaseConstants.messageIsRead: message.isRead ? 1 : 0,
        DatabaseConstants.messageReplyToMessageId: message.replyToMessageId,
      };

      await insert(DatabaseConstants.messagesTable, messageData);
      return message.id;
    } catch (e) {
      print('Error creating message: $e');
      return null;
    }
  }

  // Get messages for a specific user (usually admin)
  Future<List<Message>> getMessagesForUser(String userId, {
    int limit = 50,
    int offset = 0,
    bool? isRead,
  }) async {
    try {
      String? whereClause = '${DatabaseConstants.messageToUserId} = ?';
      List<Object?> whereArgs = [userId];

      if (isRead != null) {
        whereClause += ' AND ${DatabaseConstants.messageIsRead} = ?';
        whereArgs.add(isRead ? 1 : 0);
      }

      final results = await query(
        DatabaseConstants.messagesTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: '${DatabaseConstants.messageCreatedAt} DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((messageData) => Message.fromJson(messageData)).toList();
    } catch (e) {
      print('Error getting messages for user: $e');
      return [];
    }
  }

  // Get messages from a specific user
  Future<List<Message>> getMessagesFromUser(String fromUserId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final results = await query(
        DatabaseConstants.messagesTable,
        where: '${DatabaseConstants.messageFromUserId} = ?',
        whereArgs: [fromUserId],
        orderBy: '${DatabaseConstants.messageCreatedAt} DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((messageData) => Message.fromJson(messageData)).toList();
    } catch (e) {
      print('Error getting messages from user: $e');
      return [];
    }
  }

  // Get a specific message by ID
  Future<Message?> getMessageById(String messageId) async {
    try {
      final results = await query(
        DatabaseConstants.messagesTable,
        where: '${DatabaseConstants.messageId} = ?',
        whereArgs: [messageId],
      );

      if (results.isEmpty) return null;

      return Message.fromJson(results.first);
    } catch (e) {
      print('Error getting message by ID: $e');
      return null;
    }
  }

  // Mark message as read
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      final result = await update(
        DatabaseConstants.messagesTable,
        {DatabaseConstants.messageIsRead: 1},
        where: '${DatabaseConstants.messageId} = ?',
        whereArgs: [messageId],
      );

      return result > 0;
    } catch (e) {
      print('Error marking message as read: $e');
      return false;
    }
  }

  // Mark all messages as read for a user
  Future<bool> markAllMessagesAsRead(String toUserId) async {
    try {
      final result = await update(
        DatabaseConstants.messagesTable,
        {DatabaseConstants.messageIsRead: 1},
        where: '${DatabaseConstants.messageToUserId} = ?',
        whereArgs: [toUserId],
      );

      return result >= 0;
    } catch (e) {
      print('Error marking all messages as read: $e');
      return false;
    }
  }

  // Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final results = await query(
        DatabaseConstants.messagesTable,
        columns: ['COUNT(*) as count'],
        where: '${DatabaseConstants.messageToUserId} = ? AND ${DatabaseConstants.messageIsRead} = 0',
        whereArgs: [userId],
      );

      if (results.isEmpty) return 0;
      return results.first['count'] as int;
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }

  // Delete a message
  Future<bool> deleteMessage(String messageId) async {
    try {
      final result = await delete(
        DatabaseConstants.messagesTable,
        where: '${DatabaseConstants.messageId} = ?',
        whereArgs: [messageId],
      );

      return result > 0;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  // Get all messages (for admin to see all communications)
  Future<List<Message>> getAllMessages({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final results = await query(
        DatabaseConstants.messagesTable,
        orderBy: '${DatabaseConstants.messageCreatedAt} DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((messageData) => Message.fromJson(messageData)).toList();
    } catch (e) {
      print('Error getting all messages: $e');
      return [];
    }
  }
}
