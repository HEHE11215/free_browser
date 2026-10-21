import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Service that provides ad-blocking logic:
/// - Content blockers (blocks ad domains at the network level)
/// - CSS injection (hides ad containers visually)
/// - JavaScript injection (auto-skips YouTube ads, blocks popups)
class AdBlockerService {
  // ──────────────────────────────────────────────────────────────────────────
  // Content Blockers (Network level – blocks requests to ad servers)
  // ──────────────────────────────────────────────────────────────────────────

  static List<ContentBlocker> getContentBlockers() {
    return _adDomains.map((domain) {
      final escaped = domain.replaceAll('.', r'\.');
      return ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: '.*$escaped.*',
        ),
        action: ContentBlockerAction(
          type: ContentBlockerActionType.BLOCK,
        ),
      );
    }).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CSS Injection – hides ad containers visually
  // ──────────────────────────────────────────────────────────────────────────

  static String getAdBlockCSS() => r'''
    /* ===== YouTube Ads ===== */
    ytd-display-ad-renderer,
    .ytd-display-ad-renderer,
    #masthead-ad,
    ytd-ad-slot-renderer,
    .ytd-ad-slot-renderer,
    ytd-promoted-sparkles-web-renderer,
    ytd-banner-promo-renderer,
    .ytd-banner-promo-renderer,
    #player-ads,
    .video-ads,
    .ytp-ad-module,
    .ytp-ad-overlay-container,
    .ytp-ad-image-overlay,
    .ytp-ad-text-overlay,
    ytd-action-companion-ad-renderer,
    ytd-watch-next-secondary-results-renderer ytd-compact-promoted-video-renderer,
    ytd-rich-item-renderer.ytd-ad-slot-renderer,
    ytd-statement-banner-renderer,
    ytd-in-feed-ad-layout-renderer,
    .ytd-in-feed-ad-layout-renderer,
    ytd-merch-shelf-renderer,
    /* ===== General Ads ===== */
    .ad-banner,
    .ad-container,
    .ad-wrapper,
    .advertisement,
    .ads-container,
    [class*="AdBox"],
    [class*="ad-box"],
    [class*="ad-slot"],
    [id*="google_ads"],
    [id*="div-gpt-ad"],
    [class*="goog-ad"],
    ins.adsbygoogle,
    iframe[src*="doubleclick"],
    iframe[src*="googlesyndication"],
    iframe[src*="adnxs"],
    /* ===== Taboola / Outbrain ===== */
    .taboola-widget,
    .trc_related_container,
    [class*="taboola"],
    [class*="outbrain"],
    [class*="OUTBRAIN"],
    /* ===== Cookie / Popup Banners ===== */
    .popup-ad,
    [class*="popup-ad"],
    [id*="popup-ad"] {
      display: none !important;
      visibility: hidden !important;
      height: 0 !important;
      max-height: 0 !important;
      width: 0 !important;
      opacity: 0 !important;
      pointer-events: none !important;
      overflow: hidden !important;
    }
  ''';

  // ──────────────────────────────────────────────────────────────────────────
  // JavaScript Injection – auto-skip YouTube ads & block popups
  // ──────────────────────────────────────────────────────────────────────────

  static String getAdBlockJS() => r'''
    (function () {
      'use strict';

      // ── YouTube ad skipper ──────────────────────────────────────────────
      function skipYouTubeAds() {
        // 1. Click any visible skip button
        const skipSelectors = [
          '.ytp-skip-ad-button',
          '.ytp-ad-skip-button',
          '.ytp-ad-skip-button-modern',
          '.ytp-skip-ad-button__text',
        ];
        skipSelectors.forEach(sel => {
          const btn = document.querySelector(sel);
          if (btn) btn.click();
        });

        // 2. Fast-forward through video ads
        const video = document.querySelector('video');
        const isAd = !!document.querySelector('.ad-showing, .ytp-ad-player-overlay');
        if (video && isAd && isFinite(video.duration)) {
          video.currentTime = video.duration;
          if (video.playbackRate !== 16) video.playbackRate = 16;
        }

        // 3. Remove overlay ads
        [
          '.ytp-ad-overlay-container',
          '.ytp-ad-image-overlay',
          '.ytp-ad-text-overlay',
          '.ytp-ad-overlay-close-button',
        ].forEach(sel => {
          document.querySelectorAll(sel).forEach(el => el.remove());
        });
      }

      // ── Remove ad iframes ───────────────────────────────────────────────
      const adSrcPatterns = [
        'doubleclick', 'googlesyndication', 'googleadservices',
        'adnxs', 'advertising', 'ads.twitter', 'adform',
        'casalemedia', 'rubiconproject', 'pubmatic', 'openx',
        'taboola', 'outbrain',
      ];

      function removeAdIframes() {
        document.querySelectorAll('iframe, script[src]').forEach(el => {
          const src = el.src || el.getAttribute('src') || '';
          if (adSrcPatterns.some(p => src.includes(p))) {
            el.remove();
          }
        });
      }

      // ── Block window.open popups ────────────────────────────────────────
      window.open = function () { return null; };

      // ── Polling ─────────────────────────────────────────────────────────
      setInterval(skipYouTubeAds, 400);
      setInterval(removeAdIframes, 1000);

      // ── MutationObserver for dynamic content ────────────────────────────
      const observer = new MutationObserver(() => {
        skipYouTubeAds();
        removeAdIframes();
      });

      const target = document.body || document.documentElement;
      if (target) {
        observer.observe(target, { childList: true, subtree: true });
      }

      console.log('[FreeBrowser] ✅ Ad Blocker Active');
    })();
  ''';

  // ──────────────────────────────────────────────────────────────────────────
  // Ad Domain Blocklist (50+ networks)
  // ──────────────────────────────────────────────────────────────────────────

  static const List<String> _adDomains = [
    // Google Ads
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'pagead2.googlesyndication.com',
    'googletagservices.com',
    'adservice.google.com',
    'adservice.google.co.in',
    'adservice.google.co.uk',
    'adservice.google.com.au',
    'adservice.google.ca',
    'adservice.google.de',
    'adservice.google.fr',
    // Analytics (tracking)
    'google-analytics.com',
    'analytics.google.com',
    'googletagmanager.com',
    'stats.g.doubleclick.net',
    // Major Ad Networks
    'adnxs.com',
    'appnexus.com',
    'advertising.com',
    'adform.net',
    'amazon-adsystem.com',
    'bidswitch.net',
    'casalemedia.com',
    'criteo.com',
    'criteo.net',
    'rlcdn.com',
    'rubiconproject.com',
    'openx.net',
    'pubmatic.com',
    'media.net',
    'contextweb.com',
    'triplelift.com',
    'sovrn.com',
    'lijit.com',
    '33across.com',
    'sharethrough.com',
    'adsafeprotected.com',
    'moatads.com',
    'yieldmo.com',
    // Content Discovery (Taboola / Outbrain)
    'taboola.com',
    'outbrain.com',
    'revcontent.com',
    'mgid.com',
    // Social Tracking
    'ads.twitter.com',
    'static.ads-twitter.com',
    'ads.linkedin.com',
    'snap.licdn.com',
    'connect.facebook.net',
    // Misc
    'adroll.com',
    'scorecardresearch.com',
    'quantserve.com',
    'bluekai.com',
    'addthis.com',
    'zedo.com',
    'trafficjunky.net',
    'exoclick.com',
    'juicyads.com',
    'trafficstars.com',
    'adbrite.com',
    'adsrvr.org',
    'adtech.de',
    'smartadserver.com',
    'smaato.net',
    'ybotx.com',
    'ads.yahoo.com',
  ];
}
