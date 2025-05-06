import 'package:melody_meets/auth/schemas/account.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stream_message.freezed.dart';
part 'stream_message.g.dart';

@freezed
abstract class StreamMessage with _$StreamMessage {
  const factory StreamMessage({
    required String? id,
    required String? stream_id,
    required String? user_id,
    required String? message,
    required DateTime? created_at,
    Account? user,
  }) = _StreamMessage;

  factory StreamMessage.fromJson(Map<String, dynamic> json) =>
      _$StreamMessageFromJson(json);
}
