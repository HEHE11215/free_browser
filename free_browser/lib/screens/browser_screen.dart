import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/ad_blocker_service.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  InAppWebViewController? _webController;
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();

  double _progress = 0;
  bool _isLoading = false;
  bool _canGoBack = false;
  bool _canGoForward = false;
  String _pageTitle = 'YouTube';
  int _adsBlocked = 0;

  static const String _homeUrl = 'https://m.youtube.com';

  // Mobile Chrome User-Agent so sites render in mobile mode
  static const String _userAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Mobile Safari/537.36';

  @override
  void initState() {
    super.initState();
    _urlController.text = _homeUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _go(String input) {
    String url = input.trim();
    if (url.isEmpty) return;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Looks like a domain?
      if (RegExp(r'^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}').hasMatch(url) &&
          !url.contains(' ')) {
        url = 'https://$url';
      } else {
        // Google search
        url =
            'https://www.google.com/search?q=${Uri.encodeComponent(url)}&client=android';
      }
    }

    _webController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    _urlFocusNode.unfocus();
  }

  Future<void> _refreshNavState() async {
    final back = await _webController?.canGoBack() ?? false;
    final forward = await _webController?.canGoForward() ?? false;
    if (mounted) setState(() { _canGoBack = back; _canGoForward = forward; });
  }

  // ── Ad-block helpers ──────────────────────────────────────────────────────

  Future<void> _injectAdBlock(InAppWebViewController ctrl) async {
    try {
      await ctrl.injectCSSCode(source: AdBlockerService.getAdBlockCSS());
      await ctrl.evaluateJavascript(source: AdBlockerService.getAdBlockJS());
    } catch (_) {}
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildProgressBar(),
            Expanded(child: _buildWebView()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      height: 56,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // App icon / home
          _iconBtn(
            icon: Icons.play_circle_filled_rounded,
            color: const Color(0xFFFF0000),
            size: 30,
            onTap: () => _go(_homeUrl),
            tooltip: 'YouTube Home',
          ),
          const SizedBox(width: 6),

          // URL bar
          Expanded(
            child: GestureDetector(
              onTap: () {
                _urlFocusNode.requestFocus();
                _urlController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _urlController.text.length,
                );
              },
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: _urlFocusNode.hasFocus
                        ? const Color(0xFFFF0000).withOpacity(0.6)
                        : Colors.transparent,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: _urlController,
                  focusNode: _urlFocusNode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Search or enter URL…',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: _go,
                  textInputAction: TextInputAction.go,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Reload / Stop
          _iconBtn(
            icon: _isLoading ? Icons.close_rounded : Icons.refresh_rounded,
            color: Colors.white70,
            onTap: () {
              if (_isLoading) {
                _webController?.stopLoading();
              } else {
                _webController?.reload();
              }
            },
            tooltip: _isLoading ? 'Stop' : 'Reload',
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    if (!_isLoading) return const SizedBox(height: 2);
    return LinearProgressIndicator(
      value: _progress,
      minHeight: 2,
      backgroundColor: Colors.transparent,
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF0000)),
    );
  }

  // ── WebView ───────────────────────────────────────────────────────────────

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_homeUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
        supportZoom: true,
        useWideViewPort: true,
        loadWithOverviewMode: true,
        transparentBackground: false,
        useShouldOverrideUrlLoading: true,
        useShouldInterceptRequest: true,
        userAgent: _userAgent,
        contentBlockers: AdBlockerService.getContentBlockers(),
      ),
      onWebViewCreated: (ctrl) => _webController = ctrl,
      onLoadStart: (ctrl, url) {
        setState(() {
          _isLoading = true;
          _urlController.text = url?.toString() ?? '';
        });
      },
      onLoadStop: (ctrl, url) async {
        setState(() {
          _isLoading = false;
          _urlController.text = url?.toString() ?? '';
        });
        await _injectAdBlock(ctrl);
        await _refreshNavState();
      },
      onProgressChanged: (ctrl, progress) {
        setState(() => _progress = progress / 100);
      },
      onTitleChanged: (ctrl, title) {
        if (title != null && title.isNotEmpty && mounted) {
          setState(() => _pageTitle = title);
        }
      },
      onReceivedError: (ctrl, req, err) {
        setState(() => _isLoading = false);
      },
      // Block ad resources at the WebView level
      shouldInterceptRequest: (ctrl, request) async {
        final url = request.url.toString();
        final isAd = AdBlockerService.getContentBlockers().any((blocker) {
          final pattern = blocker.trigger.urlFilter;
          if (pattern == null) return false;
          return RegExp(pattern).hasMatch(url);
        });

        if (isAd) {
          if (mounted) setState(() => _adsBlocked++);
          // Return empty response to block
          return WebResourceResponse(
            contentType: 'text/plain',
            httpStatusCode: 200,
            data: Uint8List(0),
          );
        }
        return null; // Allow
      },
      onNavigationResponse: (ctrl, response) async =>
          NavigationResponseAction.ALLOW,
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      height: 56,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            enabled: _canGoBack,
            onTap: () => _webController?.goBack(),
          ),
          _navBtn(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: _canGoForward,
            onTap: () => _webController?.goForward(),
          ),
          _navBtn(
            icon: Icons.home_rounded,
            enabled: true,
            color: const Color(0xFFFF0000),
            onTap: () => _go(_homeUrl),
          ),
          // Ads blocked counter
          _adsBlockedBadge(),
          _navBtn(
            icon: Icons.more_vert_rounded,
            enabled: true,
            onTap: _showMenu,
          ),
        ],
      ),
    );
  }

  Widget _adsBlockedBadge() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield_rounded, color: Colors.greenAccent, size: 20),
        const SizedBox(height: 1),
        Text(
          '$_adsBlocked',
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Menu ──────────────────────────────────────────────────────────────────

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _menuTile(
              icon: Icons.copy_rounded,
              label: 'Copy URL',
              onTap: () {
                Clipboard.setData(ClipboardData(text: _urlController.text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL copied!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            _menuTile(
              icon: Icons.open_in_new_rounded,
              label: 'Open in YouTube App',
              onTap: () {
                Navigator.pop(context);
                // Optionally launch intent
              },
            ),
            _menuTile(
              icon: Icons.shield_rounded,
              label: 'Ads blocked this session: $_adsBlocked',
              color: Colors.greenAccent,
              onTap: () => Navigator.pop(context),
            ),
            _menuTile(
              icon: Icons.home_rounded,
              label: 'Go to YouTube Home',
              onTap: () { Navigator.pop(context); _go(_homeUrl); },
            ),
            _menuTile(
              icon: Icons.refresh_rounded,
              label: 'Reload Page',
              onTap: () { Navigator.pop(context); _webController?.reload(); },
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white70,
    double size = 24,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }

  Widget _navBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: enabled ? (color ?? Colors.white70) : Colors.white24,
          size: 22,
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white70,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(color: color, fontSize: 14)),
      onTap: onTap,
    );
  }
}
