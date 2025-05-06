import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melody_meets/auth/providers/account_provider.dart';
import 'package:melody_meets/config/theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:melody_meets/profile/provider/profile_provider.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:melody_meets/songs/schema/songs.dart';

// Provider for Supabase client
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Provider to fetch a specific song by ID
final songProvider = FutureProvider.family<Songs?, String>((ref, songId) async {
  final supabase = ref.read(supabaseProvider);

  final response =
      await supabase.from('songs').select().eq('id', songId).limit(1).single();

  return Songs.fromJson(response);
});

class EditSongScreen extends ConsumerStatefulWidget {
  final String songId;

  const EditSongScreen({super.key, required this.songId});

  @override
  ConsumerState<EditSongScreen> createState() => _EditSongScreenState();
}

class _EditSongScreenState extends ConsumerState<EditSongScreen> {
  // Controllers and variables
  final _songTitleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedCoverImage;
  bool _coverImageChanged = false;
  String? _selectedGenre;
  String _username = "";
  String _userId = "";
  bool _isLoading = true;
  bool _isUpdating = false;
  double _updateProgress = 0.0;

  // Song data
  Songs? _song;

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
    // Fetch user data and song data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData();
      _fetchSongData();
    });
  }

  void _fetchUserData() {
    try {
      final currentUser = ref.read(currentAccount);
      setState(() {
        _username = currentUser.username ?? "Artist";
        _userId = currentUser.id ?? "";
      });
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      setState(() {
        _username = "Artist";
        _userId = "";
      });
    }
  }

  Future<void> _fetchSongData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final songData = await ref.read(songProvider(widget.songId).future);

      if (songData != null) {
        setState(() {
          _song = songData;
          _songTitleController.text = songData.title ?? "";
          _descriptionController.text = songData.description ?? "";
          _selectedGenre = songData.genre;
          _isLoading = false;
        });
      } else {
        // Handle song not found
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Song not found')));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error fetching song data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading song: $e')));
      setState(() {
        _isLoading = false;
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
          _coverImageChanged = true;
        });
      }
    } catch (e) {
      debugPrint('Error picking cover image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  // Update song in Supabase
  Future<void> _updateSong() async {
    // Validate input fields
    if (_songTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a song title')),
      );
      return;
    }

    if (_selectedGenre == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a genre')));
      return;
    }

    // Set updating state
    setState(() {
      _isUpdating = true;
      _updateProgress = 0.0;
    });

    try {
      final supabase = ref.read(supabaseProvider);
      final uuid = const Uuid();

      // Variables to store updated file URLs and IDs
      String? imageUrl = _song?.image_url;
      String? imageId = _song?.image_id;

      // Update progress
      setState(() {
        _updateProgress = 0.2;
      });

      // 1. Upload new cover image if selected
      if (_coverImageChanged && _selectedCoverImage != null) {
        // Delete old image if it exists
        if (_song?.image_id != null) {
          final String oldImagePath =
              '$_userId/${_song?.image_id}${path.extension(_song?.image_url ?? "")}';
          try {
            await supabase.storage.from('song_covers').remove([oldImagePath]);
          } catch (e) {
            debugPrint('Error removing old cover image: $e');
            // Continue even if delete fails
          }
        }

        // Upload new image
        final String fileExt = path.extension(_selectedCoverImage!.path);
        imageId = uuid.v4();
        final String filePath = '$_userId/$imageId$fileExt';

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
      }

      // Update progress
      setState(() {
        _updateProgress = 0.7;
      });

      // 2. Update record in songs table
      await supabase
          .from('songs')
          .update({
            'title': _songTitleController.text,
            'image_url': imageUrl,
            'image_id': imageId,
            'genre': _selectedGenre,
            'description': _descriptionController.text,
          })
          .eq('id', widget.songId);

      // Update progress
      setState(() {
        _updateProgress = 1.0;
      });

      // Reset state after successful update
      setState(() {
        _isUpdating = false;
        _coverImageChanged = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Song updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      // get the current user id
      final currentUser = ref.read(currentAccount);
      final userId = currentUser.id;

      ref.invalidate(songProvider(widget.songId));
      ref.invalidate(profileProvider(userId!));

      // Navigate back to profile screen
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error updating song: $e');
      setState(() {
        _isUpdating = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Song'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body:
          _isLoading
              ? _buildLoadingView()
              : (_isUpdating
                  ? _buildUpdatingView()
                  : _buildEditSongForm(context)),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildUpdatingView() {
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
                  value: _updateProgress,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                  strokeWidth: 8.0,
                ),
              ),
              Text(
                '${(_updateProgress * 100).toInt()}%',
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
            'Updating your song...',
            style: TextStyle(color: AppTheme.whiteColor, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            _getUpdateStageText(),
            style: TextStyle(color: AppTheme.lightGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _getUpdateStageText() {
    if (_updateProgress < 0.7) {
      return _coverImageChanged
          ? 'Uploading new cover image...'
          : 'Preparing update...';
    } else {
      return 'Saving song details...';
    }
  }

  Widget _buildEditSongForm(BuildContext context) {
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

          // Artist Name (Username) - read-only
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

          // Audio File Info (read-only, can't change audio)
          Text(
            'Audio File',
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
                Icon(Icons.audio_file, color: AppTheme.primaryColor, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Original audio file',
                        style: TextStyle(
                          color: AppTheme.whiteColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cannot be changed',
                        style: TextStyle(
                          color: AppTheme.lightGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

          // Update Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _updateSong,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Update Song',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.lightGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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
              (_selectedCoverImage != null)
                  ? DecorationImage(
                    image: FileImage(_selectedCoverImage!),
                    fit: BoxFit.cover,
                  )
                  : (_song?.image_url != null)
                  ? DecorationImage(
                    image: NetworkImage(_song!.image_url!),
                    fit: BoxFit.cover,
                  )
                  : null,
        ),
        child:
            (_selectedCoverImage == null && _song?.image_url == null)
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
                : Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // Transparent overlay for better text visibility
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),
                    // Edit icon
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
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
}
