import 'package:melody_meets/video_call/model/live_stream.dart';
import 'package:melody_meets/video_call/model/stream_message.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

part 'live_stream_repository.g.dart';

@Riverpod(keepAlive: true)
LiveStreamRepository liveStreamRepository(LiveStreamRepositoryRef _) =>
    LiveStreamRepository();

class LiveStreamRepository {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // Get active live streams - only return streams with active hosts
  Future<List<LiveStream>> getActiveLiveStreams() async {
    try {
      final response = await _supabase
          .from('live_streams')
          .select('''
            *,
            accounts!inner(
              id, 
              username, 
              email, 
              image_url, 
              created_at
            )
          ''')
          .eq('is_active', true)
          .eq('has_host_connected', true) // Add host connection check
          .order('created_at', ascending: false);

      return response.map((data) => LiveStream.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error getting active live streams: $e');
      throw Exception('Failed to get active live streams: $e');
    }
  }

  // Get live streams by user (for following feed) - only with active hosts
  Future<List<LiveStream>> getLiveStreamsByUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      final response = await _supabase
          .from('live_streams')
          .select('''
            *,
            accounts!inner(
              id, 
              username, 
              email, 
              image_url, 
              created_at
            )
          ''')
          .eq('is_active', true)
          .eq('has_host_connected', true) // Add host connection check
          .inFilter('user_id', userIds)
          .order('created_at', ascending: false);

      return response.map((data) => LiveStream.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error getting followed live streams: $e');
      throw Exception('Failed to get followed live streams: $e');
    }
  }

  // Create a new live stream
  Future<LiveStream> createLiveStream({
    required String title,
    String? description,
    String? thumbnailUrl,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Generate a unique channel name
    final channelName = _uuid.v4();

    try {
      final response =
          await _supabase
              .from('live_streams')
              .insert({
                'user_id': userId,
                'title': title,
                'description': description,
                'channel_name': channelName,
                'thumbnail_url': thumbnailUrl,
                'created_at': DateTime.now().toIso8601String(),
                'is_active': true,
                'has_host_connected':
                    false, // Initialize as false until host connects
              })
              .select('''
            *,
            accounts!inner(
              id, 
              username, 
              email, 
              image_url, 
              created_at
            )
          ''')
              .single();

      return LiveStream.fromJson(response);
    } catch (e) {
      debugPrint('Error creating live stream: $e');
      throw Exception('Failed to create live stream: $e');
    }
  }

  // Update host connection status
  Future<void> updateHostConnectionStatus(
    String streamId,
    bool isConnected,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _supabase
          .from('live_streams')
          .update({'has_host_connected': isConnected})
          .eq('id', streamId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error updating host connection status: $e');
      throw Exception('Failed to update host connection status: $e');
    }
  }

  // End a live stream or mark as inactive if host disconnects
  Future<void> endLiveStream(String streamId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _supabase
          .from('live_streams')
          .update({
            'is_active': false,
            'has_host_connected': false,
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', streamId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error ending live stream: $e');
      throw Exception('Failed to end live stream: $e');
    }
  }

  // Auto-end stream if host disconnects unexpectedly
  Future<void> handleHostDisconnect(String streamId) async {
    try {
      await _supabase
          .from('live_streams')
          .update({
            'has_host_connected': false,
            // You can decide whether to also mark is_active as false
            // 'is_active': false,
            'host_disconnected_at': DateTime.now().toIso8601String(),
          })
          .eq('id', streamId);
    } catch (e) {
      debugPrint('Error handling host disconnect: $e');
      // Don't throw - this is a background operation
    }
  }

  // Update viewer count
  Future<void> updateViewerCount(String streamId, int count) async {
    try {
      await _supabase
          .from('live_streams')
          .update({'viewer_count': count})
          .eq('id', streamId);
    } catch (e) {
      debugPrint('Error updating viewer count: $e');
      // Don't throw - this is a non-critical operation
    }
  }

  // Get messages for a stream
  Future<List<StreamMessage>> getStreamMessages(String streamId) async {
    try {
      final response = await _supabase
          .from('live_stream_messages')
          .select('''
            *,
            accounts!inner(
              id, 
              username, 
              email, 
              image_url, 
              created_at
            )
          ''')
          .eq('stream_id', streamId)
          .order('created_at', ascending: true);

      return response.map((data) => StreamMessage.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Error getting stream messages: $e');
      throw Exception('Failed to get stream messages: $e');
    }
  }

  // Send a message
  Future<StreamMessage> sendMessage(String streamId, String message) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response =
          await _supabase
              .from('live_stream_messages')
              .insert({
                'stream_id': streamId,
                'user_id': userId,
                'message': message,
                'created_at': DateTime.now().toIso8601String(),
              })
              .select('''
            *,
            accounts!inner(
              id, 
              username, 
              email, 
              image_url, 
              created_at
            )
          ''')
              .single();

      return StreamMessage.fromJson(response);
    } catch (e) {
      debugPrint('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Subscribe to new messages
  Stream<List<StreamMessage>> subscribeToMessages(String streamId) {
    return _supabase
        .from('live_stream_messages')
        .stream(primaryKey: ['id'])
        .eq('stream_id', streamId)
        .map((data) {
          debugPrint('Received ${data.length} messages from subscription');
          return data.map((item) {
            if (item['accounts'] == null) {
              return StreamMessage.fromJson(item);
            }
            return StreamMessage.fromJson(item);
          }).toList();
        });
  }

  // Add a method to check stream status periodically
  // This can be used in conjunction with a timer to clean up abandoned streams
  Future<void> cleanupAbandonedStreams() async {
    try {
      // Find streams that have been waiting for host for more than 2 minutes
      final cutoffTime = DateTime.now().subtract(const Duration(minutes: 2));

      await _supabase
          .from('live_streams')
          .update({
            'is_active': false,
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('is_active', true)
          .eq('has_host_connected', false)
          .lt('created_at', cutoffTime.toIso8601String());
    } catch (e) {
      debugPrint('Error cleaning up abandoned streams: $e');
      // Don't throw - this is a background operation
    }
  }
}
