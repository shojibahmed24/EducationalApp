// Google Play Billing ONLY. There is deliberately NO bKash/Nagad
// button anywhere in this app (Play Billing only, per locked rule).
// Price lives in Play Console; the locked display price ($5/month)
// is in AppConfig for the paywall only and is never used as a
// payment amount in code logic: buy() always buys by Play
// product id and lets Play show/charge its own price.
// FAIL-SAFE: a Play purchase is NEVER trusted in the app alone.
// Premium becomes true only when the server-verified
// subscription_entitlements row exists in Supabase (server verifies
// via the Play Developer API with SUPABASE_SERVICE_ROLE_KEY).
// Until that server exists, buy() can only open checkout; it
// never marks premium, in DEMO or in real mode.
import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'app_config.dart';
import 'local_store.dart';
import 'supabase_client.dart';

enum BillingOutcome { alreadyPremium, unavailable, purchaseStarted, error }

class BillingService {
  StreamSubscription<List<PurchaseDetails>>? _sub;
  String get productId => AppConfig.playProductId;
  String get displayPrice => AppConfig.premiumDisplayPrice;

  void _listen() {
    if (_sub != null) return;
    _sub = InAppPurchase.instance.purchaseStream.listen((details) {
      for (final d in details) {
        // Complete the Play transaction, but grant nothing here:
        // verification (and therefore premium) happens server-side.
        if (d.pendingCompletePurchase) {
          InAppPurchase.instance.completePurchase(d);
        }
      }
    }, onError: (_) {});
  }

  /// REAL premium only: a server-verified active
  /// subscription_entitlements row. The DEMO test flag is
  /// deliberately NEVER read here — not as a fallback, not on
  /// query error, not in DEMO/offline mode — so toggling the
  /// Settings DEMO test switch can never make buy(), restore()
  /// or the paywall treat the user as a premium member. In DEMO
  /// mode (no Supabase client) there is no verified premium, so
  /// this returns false; the DEMO voice-gate test path is the
  /// separate isDemoVoiceTestEnabled() below.
  Future<bool> isPremium() async {
    final client = supabaseOrNull;
    if (client == null) return false;
    try {
      final rows = await client
          .from('subscription_entitlements')
          .select('active')
          .eq('active', true)
          .limit(1);
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// DEMO-ONLY voice-gate test flag. True only when BOTH hold:
  /// the app is in DEMO mode (no Supabase backend configured)
  /// AND the Settings DEMO test switch is ON. A stale stored
  /// value is therefore ignored the moment a real backend is
  /// configured, and this flag is never a premium entitlement:
  /// only AiVoiceService's demo test path reads it, never
  /// isPremium(), buy(), restore() or the paywall.
  Future<bool> isDemoVoiceTestEnabled() async {
    if (!AppConfig.demoMode) return false;
    return LocalStore.isPremiumLocal();
  }

  Future<ProductDetails?> _product() async {
    try {
      if (!await InAppPurchase.instance.isAvailable()) return null;
      final r = await InAppPurchase.instance.queryProductDetails({productId});
      return r.productDetails.isEmpty ? null : r.productDetails.first;
    } catch (_) {
      return null;
    }
  }

  Future<bool> queryProduct() async => await _product() != null;

  /// Audit-fix F2: the real Play product (and its Play price)
  /// for the paywall. Null when Play has no product configured;
  /// callers fall back to AppConfig.premiumDisplayPrice then.
  /// This only reads the product — it never starts a purchase
  /// and never touches entitlements (isPremium() is unchanged).
  Future<ProductDetails?> queryProductDetails() async => _product();

  Future<BillingOutcome> buy() async {
    if (await isPremium()) return BillingOutcome.alreadyPremium;
    final product = await _product();
    if (product == null) return BillingOutcome.unavailable;
    try {
      _listen();
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      return BillingOutcome.purchaseStarted;
    } catch (_) {
      return BillingOutcome.error;
    }
  }

  /// Restores Play purchases, then re-checks the verified source.
  /// Returns true ONLY if a verified premium entitlement exists
  /// afterwards — never from the restore call alone.
  Future<bool> restore() async {
    try {
      if (!await InAppPurchase.instance.isAvailable()) return false;
      _listen();
      await InAppPurchase.instance.restorePurchases();
      return await isPremium();
    } catch (_) {
      return false;
    }
  }
}

final billingService = BillingService();
