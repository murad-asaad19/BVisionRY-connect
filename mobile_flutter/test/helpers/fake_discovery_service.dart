import 'package:connect_mobile/features/discovery/data/discovery_service.dart';
import 'package:mocktail/mocktail.dart';

/// `mocktail`-driven double for the [DiscoveryService] used across the
/// Discovery feature's provider + widget tests.
class FakeDiscoveryService extends Mock implements DiscoveryService {}

/// Registers `mocktail` fallbacks shared by Discovery tests so `any()` /
/// `captureAny()` work with the typed argument positions on
/// [DiscoveryService] methods.
void registerDiscoveryFallbacks() {
  registerFallbackValue(DateTime.utc(2026, 1, 1));
  registerFallbackValue(<String>[]);
}
