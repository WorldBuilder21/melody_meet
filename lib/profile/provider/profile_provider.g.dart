// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileHash() => r'27a4f111956ad197e4bc4ac79417dea8cc11e87b';

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

abstract class _$Profile extends BuildlessAsyncNotifier<ProfileState> {
  late final String userId;

  FutureOr<ProfileState> build(String userId);
}

/// See also [Profile].
@ProviderFor(Profile)
const profileProvider = ProfileFamily();

/// See also [Profile].
class ProfileFamily extends Family<AsyncValue<ProfileState>> {
  /// See also [Profile].
  const ProfileFamily();

  /// See also [Profile].
  ProfileProvider call(String userId) {
    return ProfileProvider(userId);
  }

  @override
  ProfileProvider getProviderOverride(covariant ProfileProvider provider) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'profileProvider';
}

/// See also [Profile].
class ProfileProvider extends AsyncNotifierProviderImpl<Profile, ProfileState> {
  /// See also [Profile].
  ProfileProvider(String userId)
    : this._internal(
        () => Profile()..userId = userId,
        from: profileProvider,
        name: r'profileProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$profileHash,
        dependencies: ProfileFamily._dependencies,
        allTransitiveDependencies: ProfileFamily._allTransitiveDependencies,
        userId: userId,
      );

  ProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  FutureOr<ProfileState> runNotifierBuild(covariant Profile notifier) {
    return notifier.build(userId);
  }

  @override
  Override overrideWith(Profile Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProfileProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<Profile, ProfileState> createElement() {
    return _ProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProfileRef on AsyncNotifierProviderRef<ProfileState> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _ProfileProviderElement
    extends AsyncNotifierProviderElement<Profile, ProfileState>
    with ProfileRef {
  _ProfileProviderElement(super.provider);

  @override
  String get userId => (origin as ProfileProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
