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

class ViewerScreen extends ConsumerStatefulWidget {
  final LiveStream liveStream;

  const ViewerScreen({super.key, required this.liveStream});

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  final AgoraService _agoraService = AgoraService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<StreamMessage> _messages = [];
  bool _isChatVisible = true;
  bool _isExiting = false;
  bool _isHostConnected = false;
  StreamSubscription? _hostStatusSubscription;
  Timer? _hostWaitingTimer;

  @override
  void initState() {
    super.initState();
    _isHostConnected = widget.liveStream.has_host_connected ?? false;
    _initializeStream();
    _loadMessages();
    _subscribeToMessages();
    _subscribeToHostStatus();

    // If host is not connected, start a timer to check status
    if (!_isHostConnected) {
      _startHostWaitingTimer();
    }
  }

  @override
  void dispose() {
    _agoraService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _hostStatusSubscription?.cancel();
    _hostWaitingTimer?.cancel();
    super.dispose();
  }

  void _subscribeToHostStatus() {
    _hostStatusSubscription = Supabase.instance.client
        .from('live_streams')
        .stream(primaryKey: ['id'])
        .eq('id', widget.liveStream.id!)
        .listen((data) {
          if (data.isNotEmpty) {
            final updatedStream = LiveStream.fromJson(data.first);
            setState(() {
              _isHostConnected = updatedStream.has_host_connected ?? false;
            });

            // If host disconnects while viewing, show a message and navigate back
            if (!_isHostConnected &&
                mounted &&
                _agoraService.remoteUids.isEmpty) {
              _handleHostDisconnect();
            }
          }
        });
  }

  void _startHostWaitingTimer() {
    // Wait for 30 seconds - if host hasn't connected, go back
    _hostWaitingTimer = Timer(const Duration(seconds: 30), () {
      if (!_isHostConnected && mounted && _agoraService.remoteUids.isEmpty) {
        _handleHostDisconnect();
      }
    });
  }

  void _handleHostDisconnect() {
    // Show a message and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stream ended: Host is not available'),
        backgroundColor: Colors.red,
      ),
    );

    // Navigate back after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _initializeStream() async {
    await _agoraService.initialize();
    await _agoraService.joinBroadcast(
      widget.liveStream.channel_name!,
      '', // Token goes here if using Agora token authentication
    );

    // Update viewer count
    try {
      await ref
          .read(liveStreamRepositoryProvider)
          .updateViewerCount(
            widget.liveStream.id!,
            (widget.liveStream.viewer_count ?? 0) + 1,
          );
    } catch (e) {
      debugPrint('Error updating viewer count: $e');
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
    final messageStream = ref
        .read(liveStreamRepositoryProvider)
        .subscribeToMessages(widget.liveStream.id!);

    messageStream.listen((newMessages) {
      setState(() {
        _messages = newMessages;
      });
      _scrollToBottom();
    });
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

  Future<void> _leaveStream() async {
    setState(() {
      _isExiting = true;
    });

    try {
      await _agoraService.leaveChannel();

      // Update viewer count
      await ref
          .read(liveStreamRepositoryProvider)
          .updateViewerCount(
            widget.liveStream.id!,
            (widget.liveStream.viewer_count ?? 0) - 1,
          );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error leaving stream: $e');
      if (mounted) {
        setState(() {
          _isExiting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to leave stream: $e')));
      }
    }
  }

  void _toggleChat() {
    setState(() {
      _isChatVisible = !_isChatVisible;
    });
  }

  Widget _buildWaitingForHostView() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            const Text(
              'Waiting for host...',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 16),
            Text(
              'The stream will begin shortly',
              style: TextStyle(color: AppTheme.lightGrey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamView() {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _agoraService.engine!,
        canvas: VideoCanvas(uid: _agoraService.remoteUids.first),
        connection: RtcConnection(channelId: widget.liveStream.channel_name!),
      ),
    );
  }

  Widget _buildStreamAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _leaveStream,
          ),
          // Live indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          // Artist name
          Text(
            widget.liveStream.user?.username ?? 'Artist',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(' • ', style: TextStyle(color: Colors.white)),
          // Stream title
          Expanded(
            child: Text(
              widget.liveStream.title ?? 'Live Stream',
              style: const TextStyle(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Viewer count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.visibility, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${widget.liveStream.viewer_count ?? 0}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Chat area (conditionally visible)
          if (_isChatVisible)
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 80),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
              child: Column(
                children: [
                  // Chat header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Live Chat',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _toggleChat,
                        ),
                      ],
                    ),
                  ),

                  // Chat messages
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
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
                                        ? NetworkImage(message.user!.image_url!)
                                        : null,
                                child:
                                    message.user?.image_url == null
                                        ? const Icon(Icons.person, size: 12)
                                        : null,
                              ),
                              const SizedBox(width: 8),
                              // Message content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              hintStyle: TextStyle(color: Colors.grey[400]),
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
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Bottom controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Toggle chat visibility
                _buildControlButton(
                  icon:
                      _isChatVisible
                          ? Icons.chat_bubble
                          : Icons.chat_bubble_outline,
                  onPressed: _toggleChat,
                  label: _isChatVisible ? 'Hide Chat' : 'Show Chat',
                ),

                // Leave stream button
                _buildControlButton(
                  icon: Icons.call_end,
                  onPressed: _isExiting ? null : _leaveStream,
                  label: 'Leave',
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showStream =
        _isHostConnected || _agoraService.remoteUids.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video view - show waiting screen or stream depending on host connection
            Center(
              child:
                  showStream && _agoraService.remoteUids.isNotEmpty
                      ? _buildStreamView()
                      : _buildWaitingForHostView(),
            ),

            // Stream app bar with info
            _buildStreamAppBar(),

            // Chat and controls section
            _buildChatSection(),

            // Loading overlay when exiting
            if (_isExiting)
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
                        'Leaving stream...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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
