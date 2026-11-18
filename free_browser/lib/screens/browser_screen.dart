import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _savedVideoIds = {};
  bool _showLibrary = false;

  List<_Video> get _visibleVideos {
    final query = _searchController.text.trim().toLowerCase();
    return _videos.where((video) {
      final matchesLibrary = !_showLibrary || _savedVideoIds.contains(video.id);
      final matchesSearch = query.isEmpty ||
          video.title.toLowerCase().contains(query) ||
          video.creator.toLowerCase().contains(query) ||
          video.category.toLowerCase().contains(query);
      return matchesLibrary && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSaved(_Video video) {
    setState(() {
      if (!_savedVideoIds.add(video.id)) {
        _savedVideoIds.remove(video.id);
      }
    });
  }

  void _openVideo(_Video video) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _VideoScreen(
          video: video,
          isSaved: _savedVideoIds.contains(video.id),
          onSave: () => _toggleSaved(video),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videos = _visibleVideos;
    final featuredVideo = !_showLibrary &&
            _searchController.text.trim().isEmpty &&
            videos.isNotEmpty
        ? videos.first
        : null;
    final listVideos = featuredVideo == null
        ? videos
        : videos.where((video) => video.id != featuredVideo.id).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Text(
                    _showLibrary ? 'Saved for later' : 'What are we watching?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _showLibrary
                        ? 'Your favorites, ready whenever you are.'
                        : 'A hand-picked collection, with nothing in the way.',
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  if (featuredVideo != null) ...[
                    const SizedBox(height: 24),
                    _buildFeaturedVideo(featuredVideo),
                  ],
                  const SizedBox(height: 28),
                  if (videos.isEmpty)
                    _buildEmptyState()
                  else ...[
                    Text(
                      _showLibrary ? 'YOUR VIDEOS' : 'MORE TO WATCH',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    for (final video in listVideos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _VideoCard(
                          video: video,
                          onTap: () => _openVideo(video),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 20),
      child: Column(
        children: [
          Row(
            children: [
              const _OpenWaveMark(),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OPENWAVE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'WATCH SOMETHING GOOD',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: _showLibrary ? 'Go home' : 'Saved videos',
                onPressed: () => setState(() => _showLibrary = !_showLibrary),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF242630),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(
                  _showLibrary
                      ? Icons.home_rounded
                      : Icons.bookmark_border_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by title or creator',
                prefixIcon: const Icon(Icons.search_rounded, size: 21),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: const Color(0xFF191B22),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(color: Color(0xFF2E3039)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(color: Color(0xFF2E3039)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(17),
                  borderSide: const BorderSide(
                    color: Color(0xFFE94352),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedVideo(_Video video) {
    return InkWell(
      onTap: () => _openVideo(video),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 314,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF191A20),
          border: Border.all(color: Colors.white.withOpacity(0.11)),
          boxShadow: [
            BoxShadow(
              color: video.colors.first.withOpacity(0.2),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 5,
              right: 3,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      video.colors.last.withOpacity(0.75),
                      video.colors.first.withOpacity(0.04),
                    ],
                  ),
                ),
                child: Icon(
                  video.artworkIcon,
                  size: 148,
                  color: Colors.white.withOpacity(0.68),
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'EDITOR\'S PICK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 22,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.high_quality_rounded, size: 15),
                    SizedBox(width: 4),
                    Text(
                      'MP4',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Watch now',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 54),
      child: Column(
        children: [
          Icon(
            _showLibrary
                ? Icons.bookmark_border_rounded
                : Icons.search_rounded,
            size: 42,
            color: Colors.white38,
          ),
          const SizedBox(height: 14),
          Text(
            _showLibrary ? 'Nothing saved yet' : 'No videos found',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _showLibrary
                ? 'Save a video from its player and it will appear here.'
                : 'Try another title or creator.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.video,
    required this.onTap,
  });

  final _Video video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF191B22),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: video.colors,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: -25,
                    bottom: -25,
                    child: Icon(
                      video.artworkIcon,
                      size: 180,
                      color: Colors.white.withOpacity(0.18),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        video.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.42),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'MP4',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 12, 13),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: video.accent.withOpacity(0.18),
                  child: Icon(video.creatorIcon, color: video.accent, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: InkWell(
                    onTap: onTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video.creator,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoArtwork extends StatelessWidget {
  const _VideoArtwork({required this.video});

  final _Video video;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: video.colors,
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Icon(
                video.artworkIcon,
                size: 70,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            Positioned(
              left: 8,
              top: 7,
              child: Text(
                video.category.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 29,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenWaveMark extends StatelessWidget {
  const _OpenWaveMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFE94352),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE94352).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CustomPaint(painter: _OpenWaveMarkPainter()),
    );
  }
}

class _OpenWaveMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 108);
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final ring = Path()
      ..moveTo(77, 34)
      ..cubicTo(71, 27, 63, 23, 54, 23)
      ..cubicTo(36, 23, 22, 37, 22, 54)
      ..cubicTo(22, 71, 36, 85, 54, 85)
      ..cubicTo(63, 85, 71, 81, 77, 74);
    canvas.drawPath(ring, ringPaint);

    final play = Path()
      ..moveTo(46, 40.5)
      ..lineTo(67, 52.3)
      ..quadraticBezierTo(69, 54, 67, 55.7)
      ..lineTo(46, 67.5)
      ..quadraticBezierTo(43, 69, 43, 65.8)
      ..lineTo(43, 42.2)
      ..quadraticBezierTo(43, 39, 46, 40.5);
    canvas.drawPath(
      play,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _OpenWaveMarkPainter oldDelegate) => false;
}

class _VideoScreen extends StatefulWidget {
  const _VideoScreen({
    required this.video,
    required this.isSaved,
    required this.onSave,
  });

  final _Video video;
  final bool isSaved;
  final VoidCallback onSave;

  @override
  State<_VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<_VideoScreen> {
  VideoPlayerController? _controller;
  late bool _isSaved = widget.isSaved;
  bool _isLoading = true;
  String? _playerError;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _playerError = null;
    });
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.url),
    );
    _controller = controller;

    try {
      await controller.initialize().timeout(const Duration(seconds: 30));
      if (!mounted) return;
      controller.addListener(_handlePlayerUpdate);
      setState(() => _isLoading = false);
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _controller = null;
        _isLoading = false;
        _playerError = 'This video could not be loaded. Check your connection and try again.';
      });
    }
  }

  void _handlePlayerUpdate() {
    final error = _controller?.value.errorDescription;
    if (error != null && _playerError == null && mounted) {
      setState(() {
        _playerError = 'Playback stopped. Check your connection and try again.';
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handlePlayerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildPlayer() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE94352)),
      );
    }

    if (_playerError != null || _controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white54,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                _playerError ?? 'Video player unavailable.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _initializePlayer,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller!;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 24, 12, 6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: controller.value.isPlaying ? 'Pause' : 'Play',
                  onPressed: () {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFFE94352),
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          video.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: _isSaved ? 'Remove from library' : 'Save to library',
            onPressed: () {
              widget.onSave();
              setState(() => _isSaved = !_isSaved);
            },
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: Colors.black,
              child: _buildPlayer(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${video.creator}  ·  ${video.category}  ·  Sample video',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 18),
                const Divider(color: Color(0xFF2A2B31)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: video.accent.withOpacity(0.24),
                      child: Icon(video.creatorIcon, color: video.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.creator,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${video.category} · Sample video',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  video.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.55,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Sample videos are streamed from a public demo library. '
                  'Playback requires an internet connection.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Video {
  const _Video({
    required this.id,
    required this.title,
    required this.creator,
    required this.category,
    required this.url,
    required this.description,
    required this.artworkIcon,
    required this.creatorIcon,
    required this.accent,
    required this.colors,
  });

  final String id;
  final String title;
  final String creator;
  final String category;
  final String url;
  final String description;
  final IconData artworkIcon;
  final IconData creatorIcon;
  final Color accent;
  final List<Color> colors;
}

const List<_Video> _videos = [
  _Video(
    id: 'big-buck-bunny',
    title: 'Big Buck Bunny — animated film trailer',
    creator: 'Blender Open Movies',
    category: 'Animation',
    url: 'https://media.w3.org/2010/05/bunny/trailer.mp4',
    description:
        'A playful animated film trailer about a gentle giant and a forest '
        'full of surprises, available as a public sample stream.',
    artworkIcon: Icons.forest_rounded,
    creatorIcon: Icons.movie_creation_outlined,
    accent: Color(0xFFB8F28B),
    colors: [Color(0xFF145A45), Color(0xFF7FA956)],
  ),
  _Video(
    id: 'sintel',
    title: 'Sintel — a cinematic animated short',
    creator: 'Blender Open Movies',
    category: 'Animation',
    url: 'https://media.w3.org/2010/05/sintel/trailer_hd.mp4',
    description:
        'A sweeping animated fantasy trailer, presented here as a public '
        'sample video for the OpenWave player.',
    artworkIcon: Icons.auto_awesome_rounded,
    creatorIcon: Icons.auto_awesome,
    accent: Color(0xFFF4BB83),
    colors: [Color(0xFF873A35), Color(0xFFE68B48)],
  ),
  _Video(
    id: 'flower',
    title: 'A quiet moment among the flowers',
    creator: 'Open Nature',
    category: 'Nature',
    url:
        'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
    description:
        'Take a short pause and watch flowers sway in the breeze. This public '
        'sample clip is ready to stream in the built-in player.',
    artworkIcon: Icons.local_florist_rounded,
    creatorIcon: Icons.eco_outlined,
    accent: Color(0xFFFFB4D2),
    colors: [Color(0xFF82436D), Color(0xFFB36B86)],
  ),
];
