import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:melody_meets/video_call/api/live_stream_repository.dart';
import 'package:melody_meets/video_call/model/live_stream.dart';
import 'package:melody_meets/video_call/model/stream_message.dart';
import 'package:melody_meets/video_call/service/agora_service.dart';


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
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video view
            Center(
              child:
                  _agoraService.remoteUids.isNotEmpty
                      ? AgoraVideoView(
                        controller: VideoViewController.remote(
                          rtcEngine: _agoraService.engine!,
                          canvas: VideoCanvas(
                            uid: _agoraService.remoteUids.first,
                          ),
                          connection: RtcConnection(
                            channelId: widget.liveStream.channel_name!,
                          ),
                        ),
                      )
                      : Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Text(
                            'Waiting for host...',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                      ),
            ),

            // Top bar with info
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
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
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
                                            ? const Icon(Icons.person, size: 12)
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
            ),

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
