import 'dart:async';
import 'package:flutter/material.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:luna_chat/functions/luna_scan.dart';

class OnboardingScanningLunaScreen extends StatefulWidget {
  final VoidCallback? onDeviceFound;
  final VoidCallback? onScanFailed;
  
  const OnboardingScanningLunaScreen({
    super.key,
    this.onDeviceFound,
    this.onScanFailed,
  });

  @override
  State<OnboardingScanningLunaScreen> createState() => _OnboardingScanningLunaScreenState();
}

class _OnboardingScanningLunaScreenState extends State<OnboardingScanningLunaScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _spinnerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _spinnerAnimation;
  
  bool _isScanning = false;
  bool _deviceFound = false;
  bool _showTroubleshootOption = false;
  String _statusMessage = 'Initializing scanner...';
  
  Timer? _scanTimer;
  Timer? _troubleshootTimer;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _spinnerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _spinnerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_spinnerController);

    // Start sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Start main content animation
    _fadeController.forward();
    
    // Start spinner animation
    _spinnerController.repeat();
    
    // Wait a bit, then start scanning
    await Future.delayed(const Duration(milliseconds: 800));
    _startDeviceScanning();
    
    // Show troubleshoot option after 30 seconds
    _troubleshootTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && !_deviceFound) {
        setState(() {
          _showTroubleshootOption = true;
        });
      }
    });
  }

  void _startDeviceScanning() async {
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
      _statusMessage = 'Great! Now I\'m looking for Luna on your computer.';
    });

    // Periodic scanning every 3 seconds
    _scanTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_deviceFound) {
        timer.cancel();
        return;
      }
      
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        setState(() {
          _statusMessage = 'Scanning for Luna device... ${DateTime.now().toIso8601String().substring(17, 22)}';
        });
        
        final luna = await LunaScanner.findLuna(timeoutSeconds: 2)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
          
        if (luna != null) {
          setState(() {
            _deviceFound = true;
            _statusMessage = 'Luna device found at ${luna.ip}!';
          });
          
          // Stop spinner and show success
          _spinnerController.stop();
          
          // Small delay before continuing
          await Future.delayed(const Duration(seconds: 2));
          
          if (mounted && widget.onDeviceFound != null) {
            widget.onDeviceFound!();
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Still looking for Luna... Please wait.';
          });
        }
      }
    });
  }

  void _handleNeedHelp() {
    if (widget.onScanFailed != null) {
      widget.onScanFailed!();
    }
  }

  void _retryScanning() {
    setState(() {
      _showTroubleshootOption = false;
      _deviceFound = false;
      _isScanning = false;
    });
    
    // Restart spinner
    _spinnerController.repeat();
    
    // Restart scanning
    _startDeviceScanning();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _spinnerController.dispose();
    _scanTimer?.cancel();
    _troubleshootTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Main content with animations
                      AnimatedBuilder(
                        animation: _fadeController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 600),
                                child: Column(
                                  children: [
                                    // Title
                                    Text(
                                      'Looking for Your Luna Device',
                                      style: headingText.copyWith(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF2d3748),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    
                                    const SizedBox(height: 40),
                                    
                                    // Loading animation
                                    _buildLoadingAnimation(),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // Status and instructions
                                    _buildStatusSection(),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // Troubleshoot option (if needed)
                                    if (_showTroubleshootOption) _buildTroubleshootSection(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    return Container(
      width: 80,
      height: 80,
      child: AnimatedBuilder(
        animation: _spinnerAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _spinnerAnimation.value * 2 * 3.14159,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: const Color(0xFFe2e8f0),
                  width: 4,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFF38b2ac),
                      width: 4,
                    ),
                    left: BorderSide.none,
                    right: BorderSide.none,
                    bottom: BorderSide.none,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFf7fafc),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF38b2ac), width: 4),
      ),
      child: Column(
        children: [
          // Status message
          Text(
            _statusMessage,
            style: mainText.copyWith(
              fontSize: 18,
              color: const Color(0xFF2d3748),
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (!_deviceFound) ...[
            const SizedBox(height: 16),
            
            Text(
              'This is automatic - I\'m checking if your computer can "see" Luna through the cable you just connected.',
              style: mainText.copyWith(
                fontSize: 16,
                color: const Color(0xFF4a5568),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'This usually takes 10-30 seconds. Just wait and don\'t unplug anything!',
              style: mainText.copyWith(
                fontSize: 14,
                color: const Color(0xFF718096),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          if (_deviceFound) ...[
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF68d391),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Device Found!',
                    style: mainText.copyWith(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTroubleshootSection() {
    return AnimatedOpacity(
      opacity: _showTroubleshootOption ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFfef5e7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFf6ad55), width: 2),
        ),
        child: Column(
          children: [
            Text(
              'Taking longer than expected?',
              style: mainText.copyWith(
                fontSize: 16,
                color: const Color(0xFF2d3748),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _handleNeedHelp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFe2e8f0),
                    foregroundColor: const Color(0xFF4a5568),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(
                        color: Color(0xFFcbd5e0),
                        width: 1,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Need Help',
                    style: mainText.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                ElevatedButton(
                  onPressed: _retryScanning,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38b2ac),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Keep Trying',
                    style: mainText.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}