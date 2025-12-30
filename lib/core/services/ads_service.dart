import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/ad_constants.dart';

class AdsService {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;

  bool _bannerLoaded = false;
  bool _interstitialLoaded = false;
  bool _isShowingInterstitial = false;

  final _bannerStream = StreamController<BannerAd?>.broadcast();

  Stream<BannerAd?> get bannerAdStream => _bannerStream.stream;
  bool get isBannerLoaded => _bannerLoaded;
  bool get isInterstitialLoaded => _interstitialLoaded;

  // ---- Banner ----
  void loadBanner() {
    // Avoid double loads
    if (_bannerAd != null) return;

    final adUnitId = AdConstants.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerLoaded = true;
          _bannerStream.add(_bannerAd);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _bannerAd = null;
          _bannerLoaded = false;
          _bannerStream.add(null);
        },
      ),
    )..load();
  }

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _bannerLoaded = false;
    _bannerStream.add(null);
  }

  // ---- Interstitial ----
  void preloadInterstitial() {
    if (_interstitialLoaded || _interstitialAd != null) return;

    final adUnitId = AdConstants.interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoaded = true;

          // Important: set callbacks each time we load
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdShowedFullScreenContent: (_) =>
                    _isShowingInterstitial = true,
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _interstitialAd = null;
                  _interstitialLoaded = false;
                  _isShowingInterstitial = false;
                  preloadInterstitial(); // auto-preload next
                },
                onAdFailedToShowFullScreenContent: (ad, err) {
                  ad.dispose();
                  _interstitialAd = null;
                  _interstitialLoaded = false;
                  _isShowingInterstitial = false;
                  preloadInterstitial();
                },
              );
        },
        onAdFailedToLoad: (err) {
          _interstitialAd = null;
          _interstitialLoaded = false;
        },
      ),
    );
  }

  Future<void> showInterstitialIfReady() async {
    if (_isShowingInterstitial) return;
    final ad = _interstitialAd;
    if (ad == null) return;

    _isShowingInterstitial = true;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    await ad.show();
    // dismissal callback will dispose + preload next
  }

  Future<void> dispose() async {
    disposeBanner();
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _interstitialLoaded = false;
    await _bannerStream.close();
  }
}
