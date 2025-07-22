import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:luna_chat/themes/color.dart';
import 'package:luna_chat/functions/luna_scan.dart';

class OnboardingHardwareSetupScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  
  const OnboardingHardwareSetupScreen({
    Key? key,
    this.onContinue,
  }) : super(key: key);

  @override
  State<OnboardingHardwareSetupScreen> createState() => _OnboardingHardwareSetupScreenState();
}

class _OnboardingHardwareSetupScreenState extends State<OnboardingHardwareSetupScreen>
    with SingleTickerProviderStateMixin {
  Player? player;
  VideoController? controller;
  bool _isInitialized = false;
  bool _hasVideoError = false;
  bool _isPlaying = true;
  bool _isScanning = false;
  bool _deviceFound = false;
  String _statusMessage = 'Initializing...';
  
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Timer? _scanTimer;
  StreamSubscription? _bufferingSubscription;
  StreamSubscription? _errorSubscription;
  
  // Debug timing
  late DateTime _widgetInitTime;

  @override
  void initState() {
    super.initState();
    _widgetInitTime = DateTime.now();
    debugPrint('🎬 [VIDEO_DEBUG] Widget initState started');
    
    _initializeAnimations();
    
    // Initialize video loading asynchronously without blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideoAsync();
    });
    
    _startDeviceScan();
    debugPrint('🎬 [VIDEO_DEBUG] initState completed, video loading in background');
  }
  
  @override
  void dispose() {
    debugPrint('🎬 [VIDEO_DEBUG] Disposing resources');
    _scanTimer?.cancel();
    _bufferingSubscription?.cancel();
    _errorSubscription?.cancel();
    player?.dispose();
    _animController.dispose();
    super.dispose();
  }
  
  Future<void> _startDeviceScan() async {
    if (_isScanning) {
      debugPrint('[LUNA_SCAN] Scan already in progress');
      return;
    }
    
    debugPrint('[LUNA_SCAN] Starting device scan...');
    setState(() {
      _isScanning = true;
      _statusMessage = 'Initializing scanner...';
    });

    // Add a small delay to ensure network is ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    _scanTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_deviceFound) {
        debugPrint('[LUNA_SCAN] Device already found, stopping scan');
        timer.cancel();
        return;
      }
      
      if (!mounted) {
        debugPrint('[LUNA_SCAN] Widget not mounted, stopping scan');
        timer.cancel();
        return;
      }
      
      try {
        debugPrint('[LUNA_SCAN] Attempting to find Luna...');
        final luna = await LunaScanner.findLuna(timeoutSeconds: 2)
          .timeout(const Duration(seconds: 3), onTimeout: () {
            debugPrint('[LUNA_SCAN] Scan timed out after 3 seconds');
            return null;
          });
          
        debugPrint('[LUNA_SCAN] Scan completed, result: ${luna != null ? 'Found' : 'Not found'}');
        
        if (luna != null) {
          debugPrint('[LUNA_SCAN] Luna found at ${luna.ip}');
          if (mounted) {
            setState(() {
              _deviceFound = true;
              _statusMessage = 'Luna device found at ${luna.ip}!';
            });
            
            // Small delay before continuing to show feedback
            await Future.delayed(const Duration(seconds: 1));
            
            if (mounted && widget.onContinue != null) {
              widget.onContinue!();
            }
          }
        } else if (mounted) {
          setState(() {
            _statusMessage = 'Scanning for Luna device... (${DateTime.now().toIso8601String().substring(11, 19)})';
          });
        }
      } catch (e, stackTrace) {
        debugPrint('[LUNA_SCAN] Error during scan: $e');
        debugPrint('Stack trace: $stackTrace');
        
        if (mounted) {
          setState(() {
            _statusMessage = 'Error: ${e.toString().split('\n').first}';
          });
        }
      }
    });
  }

  void _initializeAnimations() {
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  // NON-BLOCKING video initialization
  Future<void> _initializeVideoAsync() async {
    final videoInitStart = DateTime.now();
    debugPrint('🎬 [VIDEO_DEBUG] Starting async video initialization');
    
    try {
      // Create player instance
      player = Player();
      controller = VideoController(player!);
      
      debugPrint('🎬 [VIDEO_DEBUG] Player and controller created');
      
      // Set up error handling first
      _errorSubscription = player!.stream.error.listen((error) {
        debugPrint('🎬 [VIDEO_DEBUG] ❌ Video error: $error');
        if (mounted) {
          setState(() {
            _hasVideoError = true;
          });
        }
      });
      
      // Set up buffering listener
      _bufferingSubscription = player!.stream.buffering.listen((buffering) {
        final now = DateTime.now();
        debugPrint('🎬 [VIDEO_DEBUG] Buffering: $buffering at ${now.difference(videoInitStart).inMilliseconds}ms');
        
        if (!buffering && mounted && !_isInitialized) {
          final totalTime = now.difference(videoInitStart);
          debugPrint('🎬 [VIDEO_DEBUG] ✅ Video ready! Total time: ${totalTime.inMilliseconds}ms');
          
          setState(() {
            _isInitialized = true;
          });
        }
      });
      
      // Configure player
      await player!.setPlaylistMode(PlaylistMode.loop);
      await player!.setVolume(0.0);  // Mute the audio
      debugPrint('🎬 [VIDEO_DEBUG] Player configured and muted, opening media...');
      
      // Open media - this might take time but won't block UI
      await player!.open(
        Media('asset:///assets/onboarding/setup_480p.mp4'),
        play: true,
      );
      
      debugPrint('🎬 [VIDEO_DEBUG] Media open command completed');
      
    } catch (e) {
      final errorTime = DateTime.now();
      final totalErrorTime = errorTime.difference(videoInitStart);
      debugPrint('🎬 [VIDEO_DEBUG] ❌ Error after ${totalErrorTime.inMilliseconds}ms: $e');
      
      if (mounted) {
        setState(() {
          _hasVideoError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[100]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  return Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildContentSection(),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        flex: 3,
                        child: _buildVideoSection(),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildContentSection(),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 4,
                        child: Container(
                          constraints: const BoxConstraints(
                            maxHeight: 400,
                            maxWidth: 600,
                          ),
                          child: _buildVideoSection(),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Connect Your Luna',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                
                Text(
                  'To begin your journey with Luna, let\'s get her connected.\n\nSimply plug Luna into power and connect her to your laptop. The guide on the right will help you through each step.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    _deviceFound
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                        : _isScanning
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              )
                            : const Icon(Icons.error_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 16,
                          color: _deviceFound ? Colors.green : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Auto-continue when device is found
                if (_deviceFound && widget.onContinue != null) ...[
                  const SizedBox(height: 24),
                  // Removed continue button as per request
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoSection() {
    if (_hasVideoError) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load video',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasVideoError = false;
                    _isInitialized = false;
                  });
                  _initializeVideoAsync();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (!_isInitialized || controller == null) {
      debugPrint('🎬 [VIDEO_DEBUG] Showing loading state');
      
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    debugPrint('🎬 [VIDEO_DEBUG] ✅ Rendering video player');
    return _buildVideoPlayer();
  }

  Widget _buildVideoPlayer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Video(
                controller: controller!,
                controls: NoVideoControls,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _togglePlayPause() async {
    if (player == null) return;
    
    final toggleStart = DateTime.now();
    debugPrint('🎬 [VIDEO_DEBUG] Toggle play/pause - current state: $_isPlaying');
    
    try {
      if (_isPlaying) {
        await player!.pause();
      } else {
        await player!.play();
      }
      if (mounted) {
        setState(() {
          _isPlaying = !_isPlaying;
        });
      }
      
      final toggleDuration = DateTime.now().difference(toggleStart);
      debugPrint('🎬 [VIDEO_DEBUG] Toggle completed in: ${toggleDuration.inMilliseconds}ms');
    } catch (e) {
      debugPrint('🎬 [VIDEO_DEBUG] Error toggling playback: $e');
    }
  }
}