import 'package:melody_meets/auth/schemas/account.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_stream.freezed.dart';
part 'live_stream.g.dart';

@freezed
abstract class LiveStream with _$LiveStream {
  const factory LiveStream({
    required String? id,
    required String? user_id,
    required String? title,
    String? description,
    required String? channel_name,
    required DateTime? created_at,
    DateTime? ended_at,
    required bool? is_active,
    String? thumbnail_url,
    required int? viewer_count,
    Account? user,
  }) = _LiveStream;

  factory LiveStream.fromJson(Map<String, dynamic> json) =>
      _$LiveStreamFromJson(json);
}
