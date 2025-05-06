// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$songStateHash() => r'2d169353da67d532e076ff40c65913afb1c0f814';

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

abstract class _$SongState extends BuildlessAutoDisposeNotifier<Songs?> {
  late final String songId;

  Songs? build(String songId);
}

/// See also [SongState].
@ProviderFor(SongState)
const songStateProvider = SongStateFamily();

/// See also [SongState].
class SongStateFamily extends Family<Songs?> {
  /// See also [SongState].
  const SongStateFamily();

  /// See also [SongState].
  SongStateProvider call(String songId) {
    return SongStateProvider(songId);
  }

  @override
  SongStateProvider getProviderOverride(covariant SongStateProvider provider) {
    return call(provider.songId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'songStateProvider';
}

/// See also [SongState].
class SongStateProvider
    extends AutoDisposeNotifierProviderImpl<SongState, Songs?> {
  /// See also [SongState].
  SongStateProvider(String songId)
    : this._internal(
        () => SongState()..songId = songId,
        from: songStateProvider,
        name: r'songStateProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$songStateHash,
        dependencies: SongStateFamily._dependencies,
        allTransitiveDependencies: SongStateFamily._allTransitiveDependencies,
        songId: songId,
      );

  SongStateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.songId,
  }) : super.internal();

  final String songId;

  @override
  Songs? runNotifierBuild(covariant SongState notifier) {
    return notifier.build(songId);
  }

  @override
  Override overrideWith(SongState Function() create) {
    return ProviderOverride(
      origin: this,
      override: SongStateProvider._internal(
        () => create()..songId = songId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        songId: songId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<SongState, Songs?> createElement() {
    return _SongStateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SongStateProvider && other.songId == songId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, songId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SongStateRef on AutoDisposeNotifierProviderRef<Songs?> {
  /// The parameter `songId` of this provider.
  String get songId;
}

class _SongStateProviderElement
    extends AutoDisposeNotifierProviderElement<SongState, Songs?>
    with SongStateRef {
  _SongStateProviderElement(super.provider);

  @override
  String get songId => (origin as SongStateProvider).songId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
