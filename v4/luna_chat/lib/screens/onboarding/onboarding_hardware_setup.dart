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
  late final Player player = Player();
  late final VideoController controller = VideoController(player);
  bool _isInitialized = false;
  bool _hasVideoError = false;
  bool _isPlaying = true;
  bool _isScanning = false;
  bool _deviceFound = false;
  String _statusMessage = 'Initializing...';
  
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Timer for periodic scanning
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideo();
    _startDeviceScan();
  }
  
  @override
  void dispose() {
    _scanTimer?.cancel();
    player.dispose();
    _animController.dispose();
    super.dispose();
  }
  
  Future<void> _startDeviceScan() async {
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for Luna device...';
    });
    
    // Start periodic scanning
    _scanTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_deviceFound) {
        timer.cancel();
        return;
      }
      
      try {
        final luna = await LunaScanner.findLuna(timeoutSeconds: 2);
        if (luna != null && mounted) {
          setState(() {
            _deviceFound = true;
            _statusMessage = 'Luna device found!';
          });
          // Wait a moment to show the success message
          await Future.delayed(const Duration(seconds: 1));
          if (widget.onContinue != null) {
            widget.onContinue!();
          }
        } else if (mounted) {
          setState(() {
            _statusMessage = 'Scanning for Luna device...';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Error scanning: ${e.toString()}';
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

  Future<void> _initializeVideo() async {
    try {
      await player.open(Media('asset:///assets/onboarding/setup_mock.mp4'));
      await player.setPlaylistMode(PlaylistMode.loop);
      
      player.stream.buffering.listen((buffering) {
        if (!buffering && mounted && !_isInitialized) {
          setState(() {
            _isInitialized = true;
          });
        }
      });

      player.stream.error.listen((error) {
        debugPrint('Video player error: $error');
        if (mounted) {
          setState(() {
            _hasVideoError = true;
          });
        }
      });
      
    } catch (e) {
      debugPrint('Error initializing video: $e');
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              whiteAccent,
              buttonColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                // Left side - Content
                Expanded(
                  flex: 5,
                  child: AnimatedBuilder(
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
                              // Header Text
                              Text(
                                'Connect Your Luna',
                                style: headingText.copyWith(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Main Text
                              Text(
                                'To begin your journey with Luna, let\'s get her connected.\n\nSimply plug Luna into power and connect her to your laptop. The guide on the right will help you through each step.',
                                style: headingText.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  height: 1.6,
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Status indicator
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
                                                valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
                                              ),
                                            )
                                          : const Icon(Icons.error_outline, color: Colors.orange, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    _statusMessage,
                                    style: headingText.copyWith(
                                      fontSize: 16,
                                      color: _deviceFound ? Colors.green : Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              
                              if (_deviceFound) ...[
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: widget.onContinue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Continue',
                                    style: headingText.copyWith(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(width: 48),
                
                // Right side - Video Player
                Expanded(
                  flex: 4,
                  child: _buildVideoSection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    if (_hasVideoError) {
      return Container(
        decoration: BoxDecoration(
          color: whiteAccent.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: buttonColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load video',
                style: headingText.copyWith(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (!_isInitialized) {
      return Container(
        decoration: BoxDecoration(
          color: whiteAccent.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: buttonColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: buttonColor,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading video...',
                style: headingText.copyWith(
                  fontSize: 16,
                  color: buttonColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return _buildVideoPlayer();
  }

  Widget _buildVideoPlayer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: GestureDetector(
            onTap: _togglePlayPause,
            child: Video(
              controller: controller,
              controls: NoVideoControls,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await player.pause();
    } else {
      await player.play();
    }
    if (mounted) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }
}