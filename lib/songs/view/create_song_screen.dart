import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/auth/providers/account_provider.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:melody_meets/profile/provider/profile_provider.dart'
    show profileProvider;
import 'package:path/path.dart' as path;
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// Provider for Supabase client
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

class CreateSongScreen extends ConsumerStatefulWidget {
  const CreateSongScreen({super.key});

  @override
  ConsumerState<CreateSongScreen> createState() => _CreateSongScreenState();
}

class _CreateSongScreenState extends ConsumerState<CreateSongScreen> {
  // Controllers and variables
  final _songTitleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedCoverImage;
  File? _selectedAudioFile;
  String? _selectedGenre;
  String _username = "";

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // List of music genres
  final List<String> _genres = [
    'Pop',
    'Rock',
    'Hip Hop',
    'R&B',
    'Jazz',
    'Electronic',
    'Classical',
    'Country',
    'Indie',
    'Afrobeat',
    'Gospel',
    'Soul',
    'Blues',
    'Reggae',
  ];

  @override
  void initState() {
    super.initState();
    // Get username from auth repository
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUsername();
    });
  }

  void _fetchUsername() {
    try {
      final currentUser = ref.read(currentAccount);
      setState(() {
        _username = currentUser.username ?? "Artist";
      });
    } catch (e) {
      debugPrint('Error fetching username: $e');
      setState(() {
        _username = "Artist";
      });
    }
  }

  @override
  void dispose() {
    _songTitleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Pick cover image
  Future<void> _pickCoverImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedCoverImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      debugPrint('Error picking cover image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  // Pick audio file
  Future<void> _pickAudioFile() async {
    try {
      // Add a small delay to prevent multiple requests
      await Future.delayed(const Duration(milliseconds: 300));

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      // Check if result is not null and the user didn't cancel the picker
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null) {
        setState(() {
          _selectedAudioFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      debugPrint('Error picking audio file: $e');

      // Only show error if not a cancellation
      if (!e.toString().contains('Cancelled')) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting audio: $e')));
      }
    }
  }

  // Upload song method
  Future<void> _uploadSong() async {
    // Validate input fields
    if (_songTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a song title')),
      );
      return;
    }

    if (_selectedAudioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an audio file')),
      );
      return;
    }

    if (_selectedGenre == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a genre')));
      return;
    }

    // Set uploading state
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final supabase = ref.read(supabaseProvider);
      final uuid = const Uuid();
      final currentUser = ref.read(currentAccount);
      final userId = currentUser.id;

      // Variables to store file URLs and IDs
      String? imageUrl, imageId, audioUrl, audioId;

      // Update progress
      setState(() {
        _uploadProgress = 0.1;
      });

      // 1. Upload cover image if selected
      if (_selectedCoverImage != null) {
        final String fileExt = path.extension(_selectedCoverImage!.path);
        imageId = uuid.v4();
        final String filePath = '$userId/$imageId$fileExt';

        // Upload to Supabase Storage
        await supabase.storage
            .from('song_covers')
            .upload(
              filePath,
              _selectedCoverImage!,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );

        // Get public URL
        imageUrl = supabase.storage.from('song_covers').getPublicUrl(filePath);

        // Update progress
        setState(() {
          _uploadProgress = 0.4;
        });
      }

      // 2. Upload audio file (required)
      final String audioExt = path.extension(_selectedAudioFile!.path);
      audioId = uuid.v4();
      final String audioPath = '$userId/$audioId$audioExt';

      // Upload to Supabase Storage
      await supabase.storage
          .from('audio_files')
          .upload(
            audioPath,
            _selectedAudioFile!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      audioUrl = supabase.storage.from('audio_files').getPublicUrl(audioPath);

      // Update progress
      setState(() {
        _uploadProgress = 0.7;
      });

      // 3. Insert record into songs table
      final songId = uuid.v4();
      await supabase.from('songs').insert({
        'id': songId,
        'title': _songTitleController.text,
        'artist': _username,
        'user_id': userId,
        'image_url': imageUrl,
        'image_id': imageId,
        'audio_url': audioUrl,
        'audio_id': audioId,
        'genre': _selectedGenre,
        'description': _descriptionController.text,
      });

      // Update progress
      setState(() {
        _uploadProgress = 1.0;
      });

      // Reset form after successful upload
      setState(() {
        _isUploading = false;
        _songTitleController.clear();
        _descriptionController.clear();
        _selectedCoverImage = null;
        _selectedAudioFile = null;
        _selectedGenre = null;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Song uploaded successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      // get the current user id

      ref.invalidate(profileProvider(userId!));

      // Navigate back to home/profile screen
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error uploading song: $e');
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create New Song'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isUploading ? _buildLoadingView() : _buildCreateSongForm(context),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: _uploadProgress,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                  strokeWidth: 8.0,
                ),
              ),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: TextStyle(
                  color: AppTheme.whiteColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            'Uploading your song...',
            style: TextStyle(color: AppTheme.whiteColor, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            _getUploadStageText(),
            style: TextStyle(color: AppTheme.lightGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _getUploadStageText() {
    if (_uploadProgress < 0.4) {
      return 'Uploading cover image...';
    } else if (_uploadProgress < 0.7) {
      return 'Uploading audio file...';
    } else {
      return 'Saving song details...';
    }
  }

  Widget _buildCreateSongForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Song Cover
          Text(
            'Song Cover',
            style: TextStyle(
              color: AppTheme.whiteColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildCoverSelector(),
          const SizedBox(height: 24),

          // Artist Name (Username)
          Text(
            'Artist',
            style: TextStyle(
              color: AppTheme.whiteColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: AppTheme.lightGrey),
                const SizedBox(width: 12),
                Text(
                  _username,
                  style: TextStyle(color: AppTheme.whiteColor, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Song Title
          Text(
            'Song Title',
            style: TextStyle(
              color: AppTheme.whiteColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _songTitleController,
            style: TextStyle(color: AppTheme.whiteColor),
            decoration: InputDecoration(
              hintText: 'Enter song title',
              filled: true,
              fillColor: AppTheme.darkGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.music_note, color: AppTheme.lightGrey),
            ),
          ),
          const SizedBox(height: 24),

          // Genre Selection
          Text(
            'Genre',
            style: TextStyle(
              color: AppTheme.whiteColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildGenreDropdown(),
          const SizedBox(height: 24),

          // Audio File Selection
          Text(
            'Audio File',
            style: TextStyle(
              color: AppTheme.whiteColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildAudioFileSelector(),
          const SizedBox(height: 24),

          // Description (Optional)
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
              hintText: 'Share something about your song...',
              filled: true,
              fillColor: AppTheme.darkGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Upload Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _uploadSong,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Upload Song',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        ],
      ),
    );
  }

  Widget _buildCoverSelector() {
    return GestureDetector(
      onTap: _pickCoverImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.darkGrey,
          borderRadius: BorderRadius.circular(12),
          image:
              _selectedCoverImage != null
                  ? DecorationImage(
                    image: FileImage(_selectedCoverImage!),
                    fit: BoxFit.cover,
                  )
                  : null,
        ),
        child:
            _selectedCoverImage == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: AppTheme.lightGrey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add Cover Image',
                      style: TextStyle(color: AppTheme.lightGrey, fontSize: 16),
                    ),
                  ],
                )
                : null,
      ),
    );
  }

  Widget _buildGenreDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedGenre,
          hint: Text(
            'Select genre',
            style: TextStyle(color: AppTheme.lightGrey),
          ),
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.lightGrey),
          dropdownColor: AppTheme.darkGrey,
          style: TextStyle(color: AppTheme.whiteColor, fontSize: 16),
          onChanged: (String? newValue) {
            setState(() {
              _selectedGenre = newValue;
            });
          },
          items:
              _genres.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildAudioFileSelector() {
    return GestureDetector(
      onTap: _pickAudioFile,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.audio_file,
              color:
                  _selectedAudioFile != null
                      ? AppTheme.primaryColor
                      : AppTheme.lightGrey,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child:
                  _selectedAudioFile != null
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Audio file selected',
                            style: TextStyle(
                              color: AppTheme.whiteColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedAudioFile!.path.split('/').last,
                            style: TextStyle(
                              color: AppTheme.lightGrey,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                      : Text(
                        'Select Audio File',
                        style: TextStyle(
                          color: AppTheme.lightGrey,
                          fontSize: 16,
                        ),
                      ),
            ),
            Icon(Icons.upload_file, color: AppTheme.lightGrey),
          ],
        ),
      ),
    );
  }
}
