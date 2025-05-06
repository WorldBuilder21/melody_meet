import 'package:melody_meets/auth/schemas/account.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

StateProvider<Account> currentAccount = StateProvider<Account>((ref) {
  return Account(
    id: '',
    image_url: '',
    image_id: '',
    email: '',
    username: '',
    fcm_token: '',
    created_at: DateTime.now(),
    is_verified: false,
  );
});
