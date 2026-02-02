import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:flutter/services.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String description;
  final List<Map<String, String>>? resources; 

  const VideoPlayerScreen({
    Key? key,
    required this.videoId,
    required this.title,
    required this.description,
    this.resources,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlaying = true; 
  double _currentSpeed = 1.0;
  String _currentQuality = 'auto';
  
  // Progress tracking
  double _currentTime = 0;
  double _totalDuration = 0;
  Timer? _progressTimer;
  bool _isDragging = false; 
  bool _isPlayerReady = false; // New state for loading
  bool _isSplashTimerStarted = false;
  bool _showEndSplash = false;

  @override
  void initState() {
    super.initState();
    
    // Register the protective HTML overlay for Web
    ui_web.platformViewRegistry.registerViewFactory(
      'video-protector',
      (int viewId) => html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = 'transparent'
        ..style.cursor = 'default',
    );

    _initController();
    _startTimer();
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _initController() {
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: _isPlaying,
      params: const YoutubePlayerParams(
        showControls: true, 
        showFullscreenButton: false, 
        strictRelatedVideos: true,
        playsInline: true,
        enableJavaScript: true,
        mute: false,
      ),
    )..seekTo(seconds: _currentTime);

    _controller.listen((state) {
      if (mounted) {
        // Force play if cued (to ensure it starts behind splash)
        if (state.playerState == PlayerState.cued) {
          _controller.playVideo();
        }

        // DETECT READINESS - Keep splash for 5 seconds AFTER video starts playing
        if (state.playerState == PlayerState.playing) {
          if (!_isPlayerReady && !_isSplashTimerStarted) {
             _isSplashTimerStarted = true;
             // Hide start splash after 5 seconds of playing
             Future.delayed(const Duration(seconds: 5), () {
               if (mounted) {
                 setState(() { _isPlayerReady = true; });
               }
             });
          }
        }
        
        // Duration sync
        final newDuration = state.metaData.duration.inSeconds.toDouble();
        if (newDuration > 0 && _totalDuration != newDuration) {
          setState(() {
            _totalDuration = newDuration;
          });
        }

        // AUTO-UPDATE PLAY/PAUSE STATE
        final isPlaying = state.playerState == PlayerState.playing || state.playerState == PlayerState.buffering;
        if (_isPlaying != isPlaying) {
          setState(() {
            _isPlaying = isPlaying;
          });
          if (isPlaying) {
            _startTimer();
          } else {
            _stopTimer();
          }
        }
      }
    });
  }

  void _startTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (mounted && !_isDragging) {
        final time = await _controller.currentTime;
        if (_currentTime != time) {
          setState(() {
            _currentTime = time;
          });

          // END SPLASH LOGIC
          if (_totalDuration > 0) {
             // Show if within last 10 seconds
             bool shouldShowEnd = _currentTime >= (_totalDuration - 10);
             if (_showEndSplash != shouldShowEnd) {
               setState(() {
                 _showEndSplash = shouldShowEnd;
               });
             }
          }
        }
      }
    });
  }

  void _stopTimer() {
    _progressTimer?.cancel();
  }

  String _formatDuration(double seconds) {
    Duration duration = Duration(seconds: seconds.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String remainingSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$minutes:$remainingSeconds";
    }
    return "$minutes:$remainingSeconds";
  }

  final List<double> _speeds = [1.0, 1.25, 1.5, 2.0];
  final List<String> _qualities = ['auto', 'small', 'medium', 'hd720'];

  @override
  void dispose() {
    _stopTimer();
    _controller.close();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Dars"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16), 

            // 1. OVAL FRAME
            Center(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 14.0), 
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24), 
                  border: Border.all(color: Colors.white10, width: 1), 
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: -2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AbsorbPointer(
                          child: YoutubePlayer(
                            controller: _controller,
                            aspectRatio: 16 / 9,
                          ),
                        ),
                        
                        // HTML NATIVE PROTECTIVE LAYER (Blocks everything on Web)
                        const Positioned.fill(
                          child: HtmlElementView(
                            viewType: 'video-protector',
                          ),
                        ),

                        // PERMANENT WATERMARK LOGO
                        Positioned(
                          top: 16,
                          left: 16,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/logo.png',
                                    height: 30, // Increased size
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "UNITY4",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14, // Increased slightly
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // PREMIUM SPLASH SCREEN / LOADING OVERLAY
                        AnimatedOpacity(
                          opacity: (!_isPlayerReady || _showEndSplash) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOut,
                          onEnd: () {
                            // Can't effectively hide/ignore pointer here due to OR condition logic
                          },
                          child: IgnorePointer(
                            ignoring: !(!_isPlayerReady || _showEndSplash),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.shade900,
                                    Colors.black,
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Brand Logo / Icon
                                  Icon(
                                    Icons.school_rounded,
                                    size: 60,
                                    color: Colors.blue.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "UNITY4 ACADEMY",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Content Switcher
                                  if (!_isPlayerReady) ...[
                                    SizedBox(
                                      width: 140,
                                      child: LinearProgressIndicator(
                                        backgroundColor: Colors.white10,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                                        minHeight: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Video yuklanmoqda...",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ] else ...[
                                     // End Splash Content (Logo only / Different text)
                                     const SizedBox(height: 10),
                                     Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        "Dars Yakunlandi",
                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                     ),
                                  ]
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. VIDEO SEEK BAR & DURATION
            _buildProgressBar(),

            // 3. VIDEO ACTION BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Left Spacer to help center the play button
                  const Expanded(child: SizedBox()),
                  
                  // CENTER: PLAY/PAUSE
                  _buildMainPlayButton(),
                  
                  // RIGHT: CONTROLS
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildSpeedToggle(),
                        const SizedBox(width: 8),
                        _buildQualityToggle(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. CONTENT SECTION
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Title
                   Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Metadata Chips
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildMetaChip(Icons.calendar_today_rounded, "Bugun"),
                      _buildMetaChip(Icons.play_circle_outline_rounded, "Dars"),
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(thickness: 1, height: 1),
                  ),

                  // Description
                  Text(
                    "Mavzu haqida ma'lumot",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      widget.description,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.6,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Resources / Links (Dynamic)
                  if (widget.resources != null && widget.resources!.isNotEmpty) ...[
                    Text(
                      "Qo'shimcha Materiallar",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.resources!.map((r) => Column(
                      children: [
                        _buildResourceItem(
                          r['title'] ?? 'Link', 
                          Icons.link, 
                          Colors.blue, 
                          r['url'] ?? '',
                        ),
                        const SizedBox(height: 8),
                      ],
                    )),
                  ],
                 
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildResourceItem(String title, IconData icon, Color color, String url) {
    return ModernCard(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () => _launchURL(url),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: Colors.red,
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: Colors.red,
            overlayColor: Colors.red.withOpacity(0.2),
          ),
          child: Container(
            height: 30, // Area for slider
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Slider(
              value: _currentTime.clamp(0, _totalDuration),
              max: _totalDuration > 0 ? _totalDuration : 1.0,
              onChangeStart: (value) {
                setState(() => _isDragging = true);
              },
              onChanged: (value) {
                setState(() => _currentTime = value);
              },
              onChangeEnd: (value) async {
                setState(() => _isDragging = false);
                await _controller.seekTo(seconds: value, allowSeekAhead: true);
                if (_isPlaying) {
                  _controller.playVideo();
                }
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "${_formatDuration(_currentTime)} / ${_formatDuration(_totalDuration)}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainPlayButton() {
    return GestureDetector(
      onTap: () {
        // Optimistic Update
        setState(() {
          _isPlaying = !_isPlaying;
        });

        if (_isPlaying) {
          _controller.playVideo();
        } else {
          _controller.pauseVideo();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade700,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _isPlaying ? "Durdur" : "Oynat",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedToggle() {
    return GestureDetector(
      onTap: () {
        int nextIndex = (_speeds.indexOf(_currentSpeed) + 1) % _speeds.length;
        setState(() {
          _currentSpeed = _speeds[nextIndex];
        });
        _controller.setPlaybackRate(_currentSpeed);
      },
      child: _buildToggleContainer(
        Icons.speed_rounded,
        "${_currentSpeed}x",
        Colors.orange.shade700,
      ),
    );
  }

  Widget _buildQualityToggle() {
    return GestureDetector(
      onTap: () {
        int nextIndex = (_qualities.indexOf(_currentQuality) + 1) % _qualities.length;
        setState(() {
          _currentQuality = _qualities[nextIndex];
        });
        // Note: Direct quality selection is often restricted by YouTube in iFrames.
        // We keep the UI state for user experience.
      },
      child: _buildToggleContainer(
        Icons.high_quality_rounded,
        _currentQuality.toUpperCase(),
        Colors.teal.shade700,
      ),
    );
  }

  Widget _buildToggleContainer(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMetaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.blue.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
