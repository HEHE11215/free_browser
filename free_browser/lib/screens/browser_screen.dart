import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _savedVideoIds = {};
  int _selectedTab = 0;
  String _selectedCategory = 'All';

  List<_Video> get _visibleVideos {
    final query = _searchController.text.trim().toLowerCase();
    return _videos.where((video) {
      final matchesTab = _selectedTab != 2 || _savedVideoIds.contains(video.id);
      final matchesCategory =
          _selectedCategory == 'All' || video.category == _selectedCategory;
      final matchesSearch = query.isEmpty ||
          video.title.toLowerCase().contains(query) ||
          video.creator.toLowerCase().contains(query) ||
          video.category.toLowerCase().contains(query);
      return matchesTab && matchesCategory && matchesSearch;
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
    final isLibrary = _selectedTab == 2;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                children: [
                  Text(
                    isLibrary
                        ? 'Your library'
                        : _selectedTab == 1
                            ? 'Find something good'
                            : 'A little inspiration',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isLibrary
                        ? 'Videos you saved for later.'
                        : 'Great videos, ready when you are.',
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  if (!isLibrary) ...[
                    const SizedBox(height: 20),
                    _buildCategories(),
                  ],
                  const SizedBox(height: 18),
                  if (videos.isEmpty)
                    _buildEmptyState(isLibrary)
                  else ...[
                    Text(
                      isLibrary ? 'SAVED VIDEOS' : 'PICKED FOR YOU',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final video in videos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: _VideoCard(
                          video: video,
                          isSaved: _savedVideoIds.contains(video.id),
                          onTap: () => _openVideo(video),
                          onSave: () => _toggleSaved(video),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTab = index;
            _selectedCategory = 'All';
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Library',
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE94352),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text(
            'openwave',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search videos',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
                  fillColor: const Color(0xFF202127),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final category in _categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (_) => setState(() => _selectedCategory = category),
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: _selectedCategory == category
                      ? Colors.black
                      : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                selectedColor: const Color(0xFFF2F0EA),
                backgroundColor: const Color(0xFF202127),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isLibrary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 54),
      child: Column(
        children: [
          Icon(
            isLibrary ? Icons.bookmark_border_rounded : Icons.search_rounded,
            size: 42,
            color: Colors.white38,
          ),
          const SizedBox(height: 14),
          Text(
            isLibrary ? 'Nothing saved yet' : 'No videos found',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            isLibrary
                ? 'Tap the bookmark on a video to keep it here.'
                : 'Try another title, creator, or category.',
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
    required this.isSaved,
    required this.onTap,
    required this.onSave,
  });

  final _Video video;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: _VideoArtwork(video: video),
        ),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: video.accent.withOpacity(0.24),
              child: Icon(video.creatorIcon, size: 19, color: video.accent),
            ),
            const SizedBox(width: 10),
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
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${video.creator}  ·  ${video.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: isSaved ? 'Remove from library' : 'Save to library',
              onPressed: onSave,
              icon: Icon(
                isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: isSaved ? const Color(0xFFFF7883) : Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VideoArtwork extends StatelessWidget {
  const _VideoArtwork({required this.video});

  final _Video video;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
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
              right: 24,
              top: 10,
              bottom: 10,
              child: Icon(
                video.artworkIcon,
                size: 130,
                color: Colors.white.withOpacity(0.13),
              ),
            ),
            Positioned(
              left: 18,
              top: 16,
              child: Text(
                video.category.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            Center(
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.6)),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  late bool _isSaved = widget.isSaved;

  String get _playerHtml => '''
    <!doctype html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          html, body { margin: 0; width: 100%; height: 100%; background: #000; }
          video { display: block; width: 100%; height: 100%; object-fit: contain; }
        </style>
      </head>
      <body>
        <video controls playsinline preload="metadata">
          <source src="${widget.video.url}" type="video/mp4">
          Your browser does not support HTML5 video.
        </video>
      </body>
    </html>
  ''';

  @override
  Widget build(BuildContext context) {
    final video = widget.video;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now playing'),
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
            child: InAppWebView(
              initialData: InAppWebViewInitialData(data: _playerHtml),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: false,
                allowsInlineMediaPlayback: true,
                mediaPlaybackRequiresUserGesture: true,
                transparentBackground: true,
              ),
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

const List<String> _categories = [
  'All',
  'Animation',
  'Nature',
];

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
    url: 'https://media.w3.org/2010/05/sintel/trailer.mp4',
    description:
        'A sweeping animated fantasy trailer, presented here as a public '
        'sample video for the OpenWave player.',
    artworkIcon: Icons.auto_awesome_rounded,
    creatorIcon: Icons.auto_awesome,
    accent: Color(0xFFF4BB83),
    colors: [Color(0xFF873A35), Color(0xFFE68B48)],
  ),
  _Video(
    id: 'elephants-dream',
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
