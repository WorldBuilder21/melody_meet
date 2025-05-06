import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:melody_meets/video_call/api/live_stream_repository.dart';
import 'package:melody_meets/video_call/model/live_stream.dart';
import 'package:melody_meets/video_call/model/stream_message.dart';
import 'package:melody_meets/video_call/service/agora_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BroadcasterScreen extends ConsumerStatefulWidget {
  final LiveStream liveStream;

  const BroadcasterScreen({super.key, required this.liveStream});

  @override
  ConsumerState<BroadcasterScreen> createState() => _BroadcasterScreenState();
}

class _BroadcasterScreenState extends ConsumerState<BroadcasterScreen> {
  final AgoraService _agoraService = AgoraService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<StreamMessage> _messages = [];
  StreamSubscription<List<StreamMessage>>? _messageSubscription;
  bool _isMuted = false;
  bool _isChatVisible = true;
  bool _isEnding = false;

  @override
  void initState() {
    super.initState();
    _initializeStream();
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _agoraService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeStream() async {
    await _agoraService.initialize();
    bool streamInitialized = false;

    try {
      // Start the broadcast first
      await _agoraService.startBroadcast(
        widget.liveStream.channel_name!,
        '', // Empty string for no authentication
      );
      streamInitialized = true;

      // Debug the stream ID to make sure it's correct
      debugPrint(
        '🔴 Updating host connection for stream ID: ${widget.liveStream.id}',
      );

      // Update host connection status with better error handling
      try {
        await ref
            .read(liveStreamRepositoryProvider)
            .updateHostConnectionStatus(widget.liveStream.id!, true);

        // Verify the update worked by fetching the stream record
        final updatedStream =
            await Supabase.instance.client
                .from('live_streams')
                .select()
                .eq('id', widget.liveStream.id!)
                .single();

        final hostConnected = updatedStream['has_host_connected'] as bool;
        debugPrint('🔴 Host connection status after update: $hostConnected');

        if (!hostConnected) {
          debugPrint(
            '🔴 WARNING: Failed to update has_host_connected flag to TRUE',
          );

          // Try again with a direct update (bypassing user_id check)
          await Supabase.instance.client
              .from('live_streams')
              .update({'has_host_connected': true})
              .eq('id', widget.liveStream.id!);

          debugPrint('🔴 Attempted direct update without user_id check');
        }
      } catch (e) {
        debugPrint('🔴 Error updating host connection status: $e');

        // Try a direct update as a fallback
        try {
          await Supabase.instance.client
              .from('live_streams')
              .update({'has_host_connected': true})
              .eq('id', widget.liveStream.id!);
          debugPrint('🔴 Used fallback direct update');
        } catch (fallbackError) {
          debugPrint('🔴 Fallback update also failed: $fallbackError');
        }
      }
    } catch (e) {
      debugPrint('Error initializing stream: $e');
      if (!streamInitialized) {
        try {
          await ref
              .read(liveStreamRepositoryProvider)
              .endLiveStream(widget.liveStream.id!);
          debugPrint('Stream marked as inactive due to initialization error');
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await ref
          .read(liveStreamRepositoryProvider)
          .getStreamMessages(widget.liveStream.id!);

      setState(() {
        _messages = messages;
      });

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  void _subscribeToMessages() {
    try {
      final messageStream = ref
          .read(liveStreamRepositoryProvider)
          .subscribeToMessages(widget.liveStream.id!);

      // Store the subscription to prevent garbage collection
      _messageSubscription = messageStream.listen(
        (newMessages) {
          debugPrint('Received ${newMessages.length} messages from stream');
          if (mounted) {
            setState(() {
              _messages = newMessages;
            });
            _scrollToBottom();
          }
        },
        onError: (error) {
          debugPrint('Error in message subscription: $error');
        },
      );
    } catch (e) {
      debugPrint('Error setting up message subscription: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    try {
      await ref
          .read(liveStreamRepositoryProvider)
          .sendMessage(widget.liveStream.id!, message);
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    }
  }

  Future<void> _endStream() async {
    setState(() {
      _isEnding = true;
    });

    try {
      await _agoraService.leaveChannel();
      await ref
          .read(liveStreamRepositoryProvider)
          .endLiveStream(widget.liveStream.id!);
    } catch (e) {
      debugPrint('Error ending stream: $e');
      if (mounted) {
        setState(() {
          _isEnding = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to end stream: $e')));
      }
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _agoraService.toggleMicrophone(_isMuted);
  }

  void _toggleChat() {
    setState(() {
      _isChatVisible = !_isChatVisible;
    });
  }

  void _switchCamera() {
    _agoraService.toggleCamera();
  }

  // Show confirmation dialog and handle ending stream
  Future<bool> _confirmEndStream() async {
    // Show confirmation dialog
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.darkGrey,
            title: Text(
              'End Live Stream?',
              style: TextStyle(color: AppTheme.whiteColor),
            ),
            content: Text(
              'Ending the stream will stop broadcasting to all viewers. Are you sure?',
              style: TextStyle(color: AppTheme.lightGrey),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.lightGrey),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text(
                  'End Stream',
                  style: TextStyle(color: AppTheme.primaryColor),
                ),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          ),
    );

    // If user confirmed, end the stream
    if (result == true) {
      // Show loading indicator
      if (mounted) {
        setState(() {
          _isEnding = true;
        });
      }

      try {
        await _agoraService.leaveChannel();
        await ref
            .read(liveStreamRepositoryProvider)
            .endLiveStream(widget.liveStream.id!);
        return true;
      } catch (e) {
        debugPrint('Error ending stream: $e');
        if (mounted) {
          setState(() {
            _isEnding = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to end stream: $e')));
        }
        return false;
      }
    }

    // If dialog was dismissed or canceled
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // When back button is pressed, show dialog and confirm ending stream
        bool shouldPop = await _confirmEndStream();
        return shouldPop;
      },
      child: Scaffold(
        backgroundColor: Colors.black,

        appBar: AppBar(
          title: const Text('Broadcaster'),
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              onPressed: () {
                // End the stream properly instead of just leaving
                _endStream().then((_) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                });
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Video view
              Center(
                child:
                    _agoraService.localUserJoined
                        ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _agoraService.engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                        : const CircularProgressIndicator(),
              ),

              // Top bar with info and controls
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Live indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Stream title
                      Expanded(
                        child: Text(
                          widget.liveStream.title ?? 'Live Stream',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Viewer count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.visibility,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.liveStream.viewer_count ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Chat area (conditionally visible)
              if (_isChatVisible)
                Positioned(
                  right: 0,
                  bottom: 80,
                  width: MediaQuery.of(context).size.width * 0.4,
                  top: 70,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Chat messages
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(8),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User avatar
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundImage:
                                          message.user?.image_url != null
                                              ? NetworkImage(
                                                message.user!.image_url!,
                                              )
                                              : null,
                                      child:
                                          message.user?.image_url == null
                                              ? const Icon(
                                                Icons.person,
                                                size: 12,
                                              )
                                              : null,
                                    ),
                                    const SizedBox(width: 8),
                                    // Message content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message.user?.username ?? 'User',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            message.message ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // Chat input
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          color: Colors.black45,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Say something...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[800],
                                  ),
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                                onPressed: _sendMessage,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Bottom controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute button
                      _buildControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        onPressed: _toggleMute,
                        label: _isMuted ? 'Unmute' : 'Mute',
                      ),

                      // Switch camera
                      _buildControlButton(
                        icon: Icons.flip_camera_ios,
                        onPressed: _switchCamera,
                        label: 'Flip',
                      ),

                      // Toggle chat visibility
                      _buildControlButton(
                        icon:
                            _isChatVisible
                                ? Icons.chat_bubble
                                : Icons.chat_bubble_outline,
                        onPressed: _toggleChat,
                        label: _isChatVisible ? 'Hide Chat' : 'Show Chat',
                      ),

                      // End stream button
                      // End stream button
                      _buildControlButton(
                        icon: Icons.call_end,
                        onPressed:
                            _isEnding
                                ? null
                                : () async {
                                  bool shouldEnd = await _confirmEndStream();
                                  if (shouldEnd && mounted) {
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
                        label: 'End',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),

              // Loading overlay when ending stream
              if (_isEnding)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Ending stream...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String label,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? Colors.grey[800],
          ),
          child: IconButton(
            icon: Icon(icon),
            color: Colors.white,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
