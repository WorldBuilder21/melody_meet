import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:melody_meets/video_call/api/live_stream_repository.dart';
import 'package:melody_meets/video_call/service/agora_service.dart';
import 'package:melody_meets/video_call/view/broad_caster_screen.dart';

class StartStreamScreen extends ConsumerStatefulWidget {
  const StartStreamScreen({super.key});

  @override
  ConsumerState<StartStreamScreen> createState() => _StartStreamScreenState();
}

class _StartStreamScreenState extends ConsumerState<StartStreamScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _startStream() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create live stream in database
      final liveStream = await ref
          .read(liveStreamRepositoryProvider)
          .createLiveStream(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
          );

      if (!mounted) return;

      // Navigate to broadcaster screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BroadcasterScreen(liveStream: liveStream),
        ),
      );
    } catch (e) {
      debugPrint('Error starting stream: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start stream: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Start Live Stream'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Stream Title',
                      style: TextStyle(
                        color: AppTheme.whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      style: TextStyle(color: AppTheme.whiteColor),
                      decoration: InputDecoration(
                        hintText: 'Enter stream title',
                        filled: true,
                        fillColor: AppTheme.darkGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      'Description (Optional)',
                      style: TextStyle(
                        color: AppTheme.whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      style: TextStyle(color: AppTheme.whiteColor),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe your stream...',
                        filled: true,
                        fillColor: AppTheme.darkGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Start button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startStream,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Go Live',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
