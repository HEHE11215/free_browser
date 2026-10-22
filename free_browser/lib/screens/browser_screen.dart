import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/ad_blocker_service.dart';

class YouTubeAppScreen extends StatefulWidget {
  const YouTubeAppScreen({super.key});

  @override
  State<YouTubeAppScreen> createState() => _YouTubeAppScreenState();
}

class _YouTubeAppScreenState extends State<YouTubeAppScreen> {
  InAppWebViewController? _webController;
  int _currentTabIndex = 0;
  int _adsBlockedCount = 0;
  bool _isLoading = false;
  double _progress = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  static const String _homeUrl = 'https://m.youtube.com/';
  static const String _shortsUrl = 'https://m.youtube.com/shorts';
  static const String _subsUrl = 'https://m.youtube.com/feed/subscriptions';
  static const String _libraryUrl = 'https://m.youtube.com/feed/library';
  static const String _loginUrl = 'https://accounts.google.com/ServiceLogin?service=youtube';

  static const String _userAgent =
      'Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.127 Mobile Safari/537.36';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadUrl(String url) {
    _webController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(url)),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentTabIndex = index;
      _isSearching = false;
    });

    switch (index) {
      case 0:
        _loadUrl(_homeUrl);
        break;
      case 1:
        _loadUrl(_shortsUrl);
        break;
      case 2:
        _loadUrl(_subsUrl);
        break;
      case 3:
        _loadUrl(_libraryUrl);
        break;
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    final encoded = Uri.encodeComponent(query.trim());
    _loadUrl('https://m.youtube.com/results?search_query=$encoded');
    setState(() {
      _isSearching = false;
    });
  }

  Future<void> _injectScripts(InAppWebViewController controller) async {
    try {
      await controller.injectCSSCode(source: AdBlockerService.getAdBlockCSS());
      await controller.evaluateJavascript(source: AdBlockerService.getAdBlockJS());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSearching) {
          setState(() => _isSearching = false);
          return false;
        }
        if (await _webController?.canGoBack() ?? false) {
          _webController?.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              if (_isLoading)
                LinearProgressIndicator(
                  value: _progress > 0 && _progress < 1 ? _progress : null,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF0000)),
                  minHeight: 2,
                ),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_homeUrl)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,
                    allowsInlineMediaPlayback: true,
                    mediaPlaybackRequiresUserGesture: false,
                    useWideViewPort: true,
                    loadWithOverviewMode: true,
                    userAgent: _userAgent,
                    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                    cacheEnabled: true,
                    hardwareAcceleration: true,
                    supportMultipleWindows: false,
                  ),
                  onWebViewCreated: (controller) {
                    _webController = controller;
                  },
                  onLoadStart: (controller, url) {
                    setState(() => _isLoading = true);
                    _injectScripts(controller);
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() => _progress = progress / 100);
                    _injectScripts(controller);
                  },
                  onLoadStop: (controller, url) async {
                    setState(() => _isLoading = false);
                    await _injectScripts(controller);
                  },
                  shouldInterceptRequest: (controller, request) async {
                    final url = request.url.toString();
                    if (AdBlockerService.isAdUrl(url)) {
                      if (mounted) {
                        setState(() => _adsBlockedCount++);
                      }
                      return WebResourceResponse(
                        contentType: 'text/plain',
                        statusCode: 200,
                        data: Uint8List(0),
                      );
                    }
                    return null;
                  },
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    if (_isSearching) {
      return Container(
        height: 52,
        color: const Color(0xFF0F0F0F),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _isSearching = false),
            ),
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search YouTube',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: _performSearch,
                  textInputAction: TextInputAction.search,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => _performSearch(_searchController.text),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 52,
      color: const Color(0xFF0F0F0F),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Center(
                  child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'YouTube',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0D220D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Color(0xFF4ADE80), size: 14),
                const SizedBox(width: 3),
                Text(
                  '$_adsBlockedCount',
                  style: const TextStyle(
                    color: Color(0xFF4ADE80),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 22),
            onPressed: () => setState(() => _isSearching = true),
          ),
          GestureDetector(
            onTap: () => _loadUrl(_loginUrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3EA6FF)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_circle_outlined, color: Color(0xFF3EA6FF), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Sign in',
                    style: TextStyle(
                      color: Color(0xFF3EA6FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 54,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(top: BorderSide(color: Color(0xFF222222), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home_filled, Icons.home_outlined, 'Home'),
          _navItem(1, Icons.bolt, Icons.bolt_outlined, 'Shorts'),
          _navItem(2, Icons.subscriptions, Icons.subscriptions_outlined, 'Subscriptions'),
          _navItem(3, Icons.video_library, Icons.video_library_outlined, 'You'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentTabIndex == index;
    return InkWell(
      onTap: () => _onTabSelected(index),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? Colors.white : Colors.white60,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
