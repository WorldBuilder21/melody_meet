import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:melody_meets/songs/schema/songs.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:math';

import 'package:melody_meets/songs/view/song_comment_screen.dart';

class SongPlayerModal extends StatefulWidget {
  final Songs song;
  final Function(Songs) onSongLiked;
  final Function(Songs) onSongBookmarked;

  const SongPlayerModal({
    super.key,
    required this.song,
    required this.onSongLiked,
    required this.onSongBookmarked,
  });

  @override
  State<SongPlayerModal> createState() => _SongPlayerModalState();
}

class _SongPlayerModalState extends State<SongPlayerModal> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isLiked = false;
  bool _isBookmarked = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    // Initialize like and bookmark state from song
    _isLiked = widget.song.isLiked ?? false;
    _isBookmarked = widget.song.isBookmarked ?? false;
  }

  Future<void> _initAudioPlayer() async {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Load the audio file
    try {
      if (widget.song.audio_url != null) {
        await _audioPlayer.setUrl(widget.song.audio_url!);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading audio: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.mediumGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Cover Art (larger)
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child:
                          widget.song.image_url != null
                              ? CachedNetworkImage(
                                imageUrl: widget.song.image_url!,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: AppTheme.mediumGrey,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppTheme.primaryColor,
                                              ),
                                        ),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color: AppTheme.mediumGrey,
                                      child: Center(
                                        child: Icon(
                                          Icons.music_note,
                                          size: 80,
                                          color: AppTheme.lightGrey,
                                        ),
                                      ),
                                    ),
                              )
                              : Container(
                                color: AppTheme.mediumGrey,
                                child: Center(
                                  child: Icon(
                                    Icons.music_note,
                                    size: 80,
                                    color: AppTheme.lightGrey,
                                  ),
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Song Title
                  Text(
                    widget.song.title ?? 'Untitled',
                    style: TextStyle(
                      color: AppTheme.whiteColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Artist Name
                  Text(
                    widget.song.artist ?? 'Unknown Artist',
                    style: TextStyle(color: AppTheme.lightGrey, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Genre Tag
                  if (widget.song.genre != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.darkColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.song.genre!,
                        style: TextStyle(
                          color: AppTheme.lightGrey,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                            activeTrackColor: AppTheme.primaryColor,
                            inactiveTrackColor: AppTheme.mediumGrey,
                            thumbColor: AppTheme.primaryColor,
                            overlayColor: AppTheme.primaryColor.withOpacity(
                              0.2,
                            ),
                          ),
                          child: Slider(
                            value: min(
                              _position.inMilliseconds.toDouble(),
                              _duration.inMilliseconds.toDouble(),
                            ),
                            max: _duration.inMilliseconds.toDouble(),
                            onChanged: (value) {
                              final position = Duration(
                                milliseconds: value.round(),
                              );
                              _audioPlayer.seek(position);
                            },
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position),
                                style: TextStyle(
                                  color: AppTheme.lightGrey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(_duration),
                                style: TextStyle(
                                  color: AppTheme.lightGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Player Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Rewind Button
                      IconButton(
                        icon: Icon(
                          Icons.replay_10,
                          color: AppTheme.whiteColor,
                          size: 32,
                        ),
                        onPressed: () {
                          final newPosition =
                              _position - const Duration(seconds: 10);
                          _audioPlayer.seek(newPosition);
                        },
                      ),

                      const SizedBox(width: 24),

                      // Play/Pause Button
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.accentColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isLoading
                                ? Icons.hourglass_empty
                                : (_isPlaying ? Icons.pause : Icons.play_arrow),
                            color: Colors.white,
                            size: 36,
                          ),
                          onPressed: _isLoading ? null : _playPause,
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Forward Button
                      IconButton(
                        icon: Icon(
                          Icons.forward_10,
                          color: AppTheme.whiteColor,
                          size: 32,
                        ),
                        onPressed: () {
                          final newPosition =
                              _position + const Duration(seconds: 10);
                          _audioPlayer.seek(newPosition);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Like and Bookmark Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Like Button with Counter
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              color:
                                  _isLiked
                                      ? AppTheme.primaryColor
                                      : AppTheme.lightGrey,
                              size: 28,
                            ),
                            onPressed: () {
                              setState(() {
                                _isLiked = !_isLiked;
                              });
                              widget.onSongLiked(widget.song);
                            },
                          ),
                          if ((widget.song.likes ?? 0) > 0)
                            Text(
                              '${widget.song.likes}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.lightGrey,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(width: 24),

                      // Bookmark Button
                      IconButton(
                        icon: Icon(
                          _isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color:
                              _isBookmarked
                                  ? AppTheme.primaryColor
                                  : AppTheme.lightGrey,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            _isBookmarked = !_isBookmarked;
                          });
                          widget.onSongBookmarked(widget.song);
                        },
                      ),
                      const SizedBox(width: 24),
                      // Modified Comments Button with Count
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.chat_bubble_outline,
                              color: AppTheme.lightGrey,
                              size: 28,
                            ),
                            onPressed: () {
                              // Navigate to comments screen
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          SongCommentsScreen(song: widget.song),
                                ),
                              );
                            },
                          ),
                          if ((widget.song.comments_count ?? 0) > 0)
                            Text(
                              '${widget.song.comments_count}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.lightGrey,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description (if available)
                  if (widget.song.description != null &&
                      widget.song.description!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About This Song',
                            style: TextStyle(
                              color: AppTheme.whiteColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.song.description!,
                            style: TextStyle(
                              color: AppTheme.lightGrey,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
