// Conditional URL strategy wrapper.
// Uses the real web implementation when compiled for web, otherwise
// provides a no-op implementation to avoid importing web-only libraries
// on desktop/mobile platforms.
import 'url_strategy_stub.dart'
    if (dart.library.html) 'url_strategy_web.dart';

// Expose a single function used by `main.dart`.
void setUrlStrategy() => setUrlStrategyImpl();
