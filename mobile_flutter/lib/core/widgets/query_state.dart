import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'skeleton.dart';

/// Generic loading / error / data wrapper for Riverpod [AsyncValue]s.
///
/// Renders [data] when the value has resolved, falls back to [loading]
/// (or a centered list-row skeleton) while pending, and shows a centered
/// error block with an optional [onRetry] button when an error is thrown.
///
/// Designed to keep call sites declarative — every screen consuming an
/// async provider can swap the typical `.when(...)` boilerplate for a
/// single `QueryState(value, data: ...)` call.
class QueryState<T> extends StatelessWidget {
  const QueryState({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.onRetry,
  });

  /// The async value, usually from `ref.watch(...)`.
  final AsyncValue<T> value;

  /// Builder for the success state.
  final Widget Function(T data) data;

  /// Custom loading widget. Defaults to a centered [SkeletonListRow] stack.
  final Widget? loading;

  /// Custom error builder. Defaults to a centered icon + message + retry.
  final Widget Function(Object error, StackTrace stack)? error;

  /// Optional retry callback wired into the default error UI.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading ?? const _DefaultLoading(),
      error: (err, stack) {
        if (error != null) return error!(err, stack);
        return _DefaultError(error: err, onRetry: onRetry);
      },
    );
  }
}

class _DefaultLoading extends StatelessWidget {
  const _DefaultLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: ValueKey('query-state-loading'),
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          SkeletonListRow(),
          SkeletonListRow(),
          SkeletonListRow(),
        ],
      ),
    );
  }
}

class _DefaultError extends StatelessWidget {
  const _DefaultError({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      key: const ValueKey('query-state-error'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: c.danger, size: 32),
          const SizedBox(height: 12),
          Text(
            'Something went wrong.',
            textAlign: TextAlign.center,
            style: typo.displaySm.copyWith(color: c.body),
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: typo.bodySm.copyWith(color: c.muted),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            AppButton(
              label: 'Retry',
              variant: AppButtonVariant.outline,
              fullWidth: false,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
