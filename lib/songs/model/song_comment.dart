import 'package:melody_meets/auth/schemas/account.dart';

class Comment {
  final String id;
  final String songId;
  final Account user;
  final String? content; // Optional for image-only comments
  final DateTime createdAt;
  final int likes;
  final bool isLiked;
  final String? image_url; // User's profile image
  final String? comment_image_url; // Attached image in comment
  final String? location;

  Comment({
    required this.id,
    required this.songId,
    required this.user,
    this.content,
    required this.createdAt,
    required this.likes,
    required this.isLiked,
    this.image_url,
    this.comment_image_url,
    this.location,
  });

  Comment copyWith({
    String? id,
    String? songId,
    Account? user,
    String? content,
    DateTime? createdAt,
    int? likes,
    bool? isLiked,
    String? image_url,
    String? comment_image_url,
    String? location,
  }) {
    return Comment(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      user: user ?? this.user,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      image_url: image_url ?? this.image_url,
      comment_image_url: comment_image_url ?? this.comment_image_url,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'song_id': songId,
      'user_id': user.id,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'image_url': image_url,
      'comment_image_url': comment_image_url,
      'location': location,
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json, {Account? user}) {
    return Comment(
      id: json['id'],
      songId: json['song_id'] ?? json['post_id'],
      user: user ?? Account.fromJson(json['user']),
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      likes: json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      image_url: json['image_url'],
      comment_image_url: json['comment_image_url'],
      location: json['location'],
    );
  }

  // Helper methods
  bool get hasContent => content != null && content!.isNotEmpty;
  bool get hasCommentImage =>
      comment_image_url != null && comment_image_url!.isNotEmpty;
}
