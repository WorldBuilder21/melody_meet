// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userNotifierHash() => r'4600d93e6d6d38e5105d7cf9a85818705c0ade6b';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [userNotifier].
@ProviderFor(userNotifier)
const userNotifierProvider = UserNotifierFamily();

/// See also [userNotifier].
class UserNotifierFamily extends Family<AsyncValue<Account>> {
  /// See also [userNotifier].
  const UserNotifierFamily();

  /// See also [userNotifier].
  UserNotifierProvider call(String id) {
    return UserNotifierProvider(id);
  }

  @override
  UserNotifierProvider getProviderOverride(
    covariant UserNotifierProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userNotifierProvider';
}

/// See also [userNotifier].
class UserNotifierProvider extends StreamProvider<Account> {
  /// See also [userNotifier].
  UserNotifierProvider(String id)
    : this._internal(
        (ref) => userNotifier(ref as UserNotifierRef, id),
        from: userNotifierProvider,
        name: r'userNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$userNotifierHash,
        dependencies: UserNotifierFamily._dependencies,
        allTransitiveDependencies:
            UserNotifierFamily._allTransitiveDependencies,
        id: id,
      );

  UserNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    Stream<Account> Function(UserNotifierRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserNotifierProvider._internal(
        (ref) => create(ref as UserNotifierRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  StreamProviderElement<Account> createElement() {
    return _UserNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserNotifierProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserNotifierRef on StreamProviderRef<Account> {
  /// The parameter `id` of this provider.
  String get id;
}

class _UserNotifierProviderElement extends StreamProviderElement<Account>
    with UserNotifierRef {
  _UserNotifierProviderElement(super.provider);

  @override
  String get id => (origin as UserNotifierProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
