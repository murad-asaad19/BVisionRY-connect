import 'package:flutter/material.dart';

import 'sentry.dart' as telemetry;

/// Widget-tree-scoped error boundary that forwards uncaught build/runtime
/// errors to Sentry and renders a fallback UI.
///
/// Pair with `SentryFlutter.init`'s `appRunner` (which catches async/zone
/// errors) for full coverage. This widget catches errors that escape the
/// build phase via `ErrorWidget.builder` semantics.
///
/// Spec §11.1 — root layout is wrapped in this boundary.
class SentryErrorBoundary extends StatefulWidget {
  const SentryErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
    this.onError,
  });

  final Widget child;

  /// Custom fallback. Receives the captured error. Defaults to a centered
  /// generic message.
  final Widget Function(BuildContext context, Object error)? fallbackBuilder;

  /// Optional sink so tests can assert capture without a live Sentry.
  /// Production always forwards to `telemetry.captureException`.
  final void Function(Object error, StackTrace stack)? onError;

  @override
  State<SentryErrorBoundary> createState() => _SentryErrorBoundaryState();
}

class _SentryErrorBoundaryState extends State<SentryErrorBoundary> {
  ({Object error, StackTrace stack})? _captured;

  void _capture(Object error, StackTrace stack) {
    telemetry.captureException(error, stack);
    widget.onError?.call(error, stack);
    // The error fires DURING build (from ErrorWidget.builder) — calling
    // setState synchronously trips the !dirty assertion. Defer to the
    // next frame so the boundary repaints with the fallback safely.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _captured = (error: error, stack: stack));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ({Object error, StackTrace stack})? captured = _captured;
    if (captured != null) {
      return widget.fallbackBuilder?.call(context, captured.error) ??
          const _DefaultFallback();
    }
    return _ErrorListenerScope(
      onError: _capture,
      child: widget.child,
    );
  }
}

/// Installs a scoped `ErrorWidget.builder` shim that forwards build-phase
/// errors to [onError] and tears down on dispose.
class _ErrorListenerScope extends StatefulWidget {
  const _ErrorListenerScope({required this.onError, required this.child});
  final void Function(Object, StackTrace) onError;
  final Widget child;

  @override
  State<_ErrorListenerScope> createState() => _ErrorListenerScopeState();
}

class _ErrorListenerScopeState extends State<_ErrorListenerScope> {
  late final ErrorWidgetBuilder _previous;

  @override
  void initState() {
    super.initState();
    _previous = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      widget.onError(details.exception, details.stack ?? StackTrace.current);
      return _previous(details);
    };
  }

  @override
  void dispose() {
    ErrorWidget.builder = _previous;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DefaultFallback extends StatelessWidget {
  const _DefaultFallback();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Something went wrong.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
