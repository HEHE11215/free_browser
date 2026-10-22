class AdBlockerService {
  static String getAdBlockCSS() => r'''
    ytm-promoted-sparkles-web-renderer,
    ytm-promoted-video-renderer,
    ytm-ad-slot-renderer,
    ytd-ad-slot-renderer,
    .ytp-ad-module,
    .ytp-ad-overlay-container,
    .video-ads,
    #player-ads,
    #masthead-ad,
    [class*="ad-slot"],
    ins.adsbygoogle {
      display: none !important;
      visibility: hidden !important;
      height: 0 !important;
    }
    ytm-mobile-topbar-renderer,
    ytm-pivot-bar-renderer {
      display: none !important;
    }
    body {
      padding-top: 0 !important;
      padding-bottom: 0 !important;
      background: #0f0f0f !important;
    }
  ''';

  static String getAdBlockJS() => r'''
    (function() {
      'use strict';
      if (window.__freeYTAdBlockInit) return;
      window.__freeYTAdBlockInit = true;

      function skipVideoAds() {
        try {
          const skipSelectors = [
            '.ytp-skip-ad-button',
            '.ytp-ad-skip-button',
            '.ytp-ad-skip-button-modern',
            '.videoAdUiSkipButton',
            'button.ytp-ad-skip-button'
          ];
          for (const sel of skipSelectors) {
            const btn = document.querySelector(sel);
            if (btn && typeof btn.click === 'function') {
              btn.click();
              return;
            }
          }
          const isAdPlaying = !!document.querySelector('.ad-showing, .ad-interrupting, .ytp-ad-player-overlay');
          const video = document.querySelector('video');
          if (video && isAdPlaying) {
            video.muted = true;
            if (isFinite(video.duration) && video.duration > 0) {
              video.currentTime = video.duration;
            }
          }
        } catch (e) {}
      }
      setInterval(skipVideoAds, 350);
    })();
  ''';

  static final List<String> adDomains = [
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'adservice.google.com',
    'pagead2.googlesyndication.com',
    'adnxs.com',
    'criteo.com',
    'taboola.com',
    'outbrain.com',
  ];

  static bool isAdUrl(String url) {
    final lower = url.toLowerCase();
    for (final domain in adDomains) {
      if (lower.contains(domain)) return true;
    }
    if (lower.contains('/pagead/') ||
        lower.contains('/ptracking') ||
        lower.contains('/api/stats/ads') ||
        lower.contains('googleads.g.doubleclick.net')) {
      return true;
    }
    return false;
  }
}
