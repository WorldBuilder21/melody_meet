import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  // Your Agora App ID - replace with your actual ID
  static const String appId = '4c62c84dd2684d408e47a7a81f8987b1';

  RtcEngine? _engine;
  bool _initialized = false;
  final Set<int> _remoteUids = {};
  bool _localUserJoined = false;
  int? _localUid;

  RtcEngine? get engine => _engine;
  bool get initialized => _initialized;
  Set<int> get remoteUids => _remoteUids;
  bool get localUserJoined => _localUserJoined;
  int? get localUid => _localUid;

  // Initialize the Agora engine
  Future<void> initialize() async {
    if (_initialized) return;

    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Create RTC engine instance
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(appId: appId));

    // Setup event handlers
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint('Local user joined: ${connection.localUid}');
          _localUserJoined = true;
          _localUid = connection.localUid;
        },
        onUserJoined: (connection, uid, elapsed) {
          debugPrint('Remote user joined: $uid');
          _remoteUids.add(uid);
        },
        onUserOffline: (connection, uid, reason) {
          debugPrint('Remote user left: $uid, reason: $reason');
          _remoteUids.remove(uid);
        },
      ),
    );

    // Enable video
    await _engine!.enableVideo();
    await _engine!.startPreview();

    _initialized = true;
  }

  // Start a broadcast as host
  Future<void> startBroadcast(String channelName, String token) async {
    if (!_initialized) await initialize();

    // Set channel profile and client role
    await _engine!.setChannelProfile(
      ChannelProfileType.channelProfileLiveBroadcasting,
    );
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // Join channel
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  // Join a broadcast as audience
  Future<void> joinBroadcast(String channelName, String token) async {
    if (!_initialized) await initialize();

    // Set channel profile and client role
    await _engine!.setChannelProfile(
      ChannelProfileType.channelProfileLiveBroadcasting,
    );
    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

    // Join channel
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  // Leave channel
  Future<void> leaveChannel() async {
    if (!_initialized || _engine == null) return;

    _remoteUids.clear();
    _localUserJoined = false;
    _localUid = null;

    await _engine!.leaveChannel();
  }

  // Toggle camera
  Future<void> toggleCamera() async {
    if (!_initialized || _engine == null) return;
    await _engine!.switchCamera();
  }

  // Toggle microphone
  Future<void> toggleMicrophone(bool muted) async {
    if (!_initialized || _engine == null) return;
    await _engine!.muteLocalAudioStream(muted);
  }

  // Dispose resources
  Future<void> dispose() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
    }
    _initialized = false;
    _remoteUids.clear();
    _localUserJoined = false;
    _localUid = null;
  }
}
