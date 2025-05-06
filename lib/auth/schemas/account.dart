import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.g.dart';
part 'account.freezed.dart';

@freezed
abstract class Account with _$Account {
  const factory Account({
    required String? id,
    required String? image_url,
    required String? image_id,
    required String? email,
    required String? username,
    // for an artist to be verified, they need to have at least 100 followers.
    @Default(false)
    bool? is_verified, // check if the user is a verified artist or not
    required String? fcm_token,
    required DateTime? created_at,
    // will add a location field later
    String? bio,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}
