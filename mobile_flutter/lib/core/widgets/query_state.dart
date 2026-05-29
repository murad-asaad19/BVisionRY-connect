import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/error_messages.dart';
import '../i18n/i18n.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'skeleton.dart';

/// Generic loading / error / data wrapper for Riverpod [AsyncValue]s.
///
/// Renders [data] when the value has resolved, falls back to [loading]
/// (or a centered list-row skeleton) while pending, and shows a centered
/// localized error block with an optional [onRetry] button when an error is
/// thrown.
///
/// The default error UI derives its message from [messageForError] (so a
/// typed `AppException` shows its localized copy and nothing else leaks the
/// raw `toString()`), and is always-scrollable so a surrounding
/// `RefreshIndicator` can still fire on the error state.
///
/// Designed to keep call sites declarative — every screen consuming an async
/// provider can swap the typical `.when(...)` boilerplate for a single
/// `QueryState(value, data: ...)` call.
class QueryState<T> extends StatelessWidget {
  const QueryState({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.onRetry,
    this.errorTitle,
    this.errorMessage,
  });

  /// The async value, usually from `ref.watch(...)`.
  final AsyncValue<T> value;

  /// Builder for the success state.
  final Widget Function(T data) data;

  /// Custom loading widget. Defaults to a centered [SkeletonListRow] stack.
  final Widget? loading;

  /// Custom error builder. Defaults to a centered icon + localized message +
  /// retry.
  final Widget Function(Object error, StackTrace stack)? error;

  /// Optional retry callback wired into the default error UI.
  final VoidCallback? onRetry;

  /// Optional localized override for the default error title.
  final String? errorTitle;

  /// Optional localized override for the default error body. When omitted the
  /// body is derived from the error via [messageForError] — never
  /// `error.toString()`.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading ?? const _DefaultLoading(),
      error: (err, stack) {
        if (error != null) return error!(err, stack);
        return _DefaultError(
          error: err,
          title: errorTitle,
          message: errorMessage,
          onRetry: onRetry,
        );
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
  const _DefaultError({
    required this.error,
    this.title,
    this.message,
    this.onRetry,
  });

  final Object error;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: c.danger, size: 32),
          const SizedBox(height: 12),
          Text(
            title ?? context.t('errors.title'),
            textAlign: TextAlign.center,
            style: typo.displayMd.copyWith(color: c.body),
          ),
          const SizedBox(height: 4),
          Text(
            message ?? messageForError(context, error),
            textAlign: TextAlign.center,
            style: typo.bodyLg.copyWith(color: c.muted),
          ),
          // Raw diagnostic text is dev-only; users never see toString().
          if (kDebugMode) ...[
            const SizedBox(height: 4),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: typo.bodyXs.copyWith(color: c.muted),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            AppButton(
              label: context.t('common.retry'),
              variant: AppButtonVariant.outline,
              fullWidth: false,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
    return LayoutBuilder(
      key: const ValueKey('query-state-error'),
      builder: (context, constraints) {
        // When height is bounded (Scaffold body / Expanded), make the error
        // always-scrollable + vertically centered so a parent RefreshIndicator
        // can fire pull-to-refresh on the error state.
        if (!constraints.hasBoundedHeight) return content;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}
