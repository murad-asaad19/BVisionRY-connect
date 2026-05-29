import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../data/meetings_service.dart';

/// Bottom-sheet used by the proposer to draft + send a meeting offer.
///
/// Layout (gallery G1):
/// - Chat-context header: peer avatar + name + role/handle line pinned to
///   the top so the proposer always sees who they're scheduling with.
/// - 3 slot rows in one connected bordered group (slot 1 required, 2/3
///   optional). Each row launches a date + time picker, shows the slot
///   duration as a sub-label, and exposes a trailing ★/☆ that toggles the
///   slot as the proposer's preferred time (mutually exclusive across rows).
/// - Duration stepper: default 30, ±15, range 15–240.
/// - Meeting URL `AppInput` (https-only — server enforces; client also
///   blocks non-https before round-trip) + a muted ".ics handoff" hint.
/// - Optional multi-line "Note (optional)" text field for context.
/// - Timezone hint: auto-detected via [FlutterTimezone.getLocalTimezone];
///   user can't override in v1 (the value is sent to the server so it can
///   render times in the proposer's tz for the recipient).
/// - Submit label: "Send proposal".
class ProposeMeetingSheet extends ConsumerStatefulWidget {
  const ProposeMeetingSheet({
    super.key,
    required this.conversationId,
    this.peerName,
    this.peerHandle,
    this.peerHeadline,
    this.peerPhotoUrl,
  });

  final String conversationId;
  final String? peerName;
  final String? peerHandle;

  /// Optional role/headline line shown under the peer name in the
  /// chat-context header (mockup G1 shows e.g. "Senior backend"). Falls
  /// back to the `@handle` when absent.
  final String? peerHeadline;
  final String? peerPhotoUrl;

  @override
  ConsumerState<ProposeMeetingSheet> createState() =>
      _ProposeMeetingSheetState();
}

class _ProposeMeetingSheetState extends ConsumerState<ProposeMeetingSheet> {
  final List<DateTime?> _slots = [null, null, null];
  int _duration = 30;
  String _url = '';
  String _note = '';
  String _tz = 'UTC';
  int? _preferredSlot;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _resolveTimezone();
  }

  Future<void> _resolveTimezone() async {
    try {
      final tz = await FlutterTimezone.getLocalTimezone();
      if (mounted) setState(() => _tz = tz);
    } catch (_) {
      // Keep UTC fallback — non-fatal.
    }
  }

  Future<void> _pickSlot(int index) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _slots[index] = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _togglePreferred(int index) {
    setState(() {
      _preferredSlot = _preferredSlot == index ? null : index;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final toast = ref.read(toastServiceProvider.notifier);
    final sentTitle = context.t('meetings.propose.sent');
    final selected = _slots.whereType<DateTime>().toList();
    // The preferred-slot index references the full _slots array; remap it
    // to the compacted [selected] list (skip rows the user left empty).
    int? preferredCompactIndex;
    if (_preferredSlot != null && _slots[_preferredSlot!] != null) {
      preferredCompactIndex = 0;
      for (var i = 0; i < _preferredSlot!; i++) {
        if (_slots[i] != null) {
          preferredCompactIndex = preferredCompactIndex! + 1;
        }
      }
    }
    try {
      await ref.read(meetingsServiceProvider).proposeMeeting(
            conversationId: widget.conversationId,
            slots: selected,
            durationMinutes: _duration,
            meetingUrl: _url.isEmpty ? null : _url,
            timezone: _tz,
            preferredSlotIndex: preferredCompactIndex,
            note: _note.isEmpty ? null : _note,
          );
      Analytics.log(AppEvent.meetingProposed);
      Haptics.medium();
      navigator.pop();
      toast.showToast(title: sentTitle, intent: AppIntent.success);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = context.t(e.i18nKey));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = context.t('meetings.propose.errors.submitFailed'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    final radii = Theme.of(context).extension<AppRadii>()!;
    final fmt = DateFormat.MMMd().add_jm();
    final peerDisplay = (widget.peerName != null && widget.peerName!.isNotEmpty)
        ? widget.peerName!
        : (widget.peerHandle ?? '');
    // Role/handle subtitle for the chat-context header. Prefer an explicit
    // headline (mockup's "Senior backend"); fall back to the @handle.
    final headerSubtitle =
        (widget.peerHeadline != null && widget.peerHeadline!.isNotEmpty)
            ? widget.peerHeadline!
            : (widget.peerHandle != null &&
                    widget.peerHandle!.isNotEmpty &&
                    widget.peerHandle != peerDisplay
                ? '@${widget.peerHandle}'
                : null);
    final hasPeer = peerDisplay.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pinned chat-context header (mockup G1): peer avatar + name +
              // role/handle line so the proposer always sees who they're
              // scheduling with.
              Row(
                children: [
                  Avatar(
                    name: hasPeer ? peerDisplay : '?',
                    photoUrl: widget.peerPhotoUrl,
                    size: 38,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasPeer)
                          Text(
                            peerDisplay,
                            style: typo.displayMd.copyWith(color: colors.navy),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (headerSubtitle != null)
                          Text(
                            headerSubtitle,
                            style: typo.bodySm.copyWith(color: colors.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                context.t('meetings.propose.title'),
                style: typo.displayMd.copyWith(color: colors.navy),
              ),
              const SizedBox(height: 4),
              Text(
                hasPeer
                    ? context.t(
                        'meetings.propose.subtitle',
                        vars: {'name': peerDisplay},
                      )
                    : context.t('meetings.propose.subtitleGeneric'),
                style: typo.bodyMd.copyWith(color: colors.muted),
              ),
              const SizedBox(height: 16),
              // Three slots rendered as one connected bordered group:
              // rounded top on row 0, rounded bottom on row 2, shared
              // borders between (mockup G1).
              for (var i = 0; i < 3; i++)
                _SlotRow(
                  key: Key('propose-slot-$i'),
                  index: i,
                  value: _slots[i],
                  fmt: fmt,
                  durationMinutes: _duration,
                  isFirst: i == 0,
                  isLast: i == 2,
                  isPreferred: _preferredSlot == i,
                  onTap: _busy ? null : () => _pickSlot(i),
                  onTogglePreferred: (_busy || _slots[i] == null)
                      ? null
                      : () => _togglePreferred(i),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t('meetings.propose.durationLabel'),
                      style: typo.bodyLg.copyWith(color: colors.body),
                    ),
                  ),
                  IconButton(
                    key: const Key('propose-duration-minus'),
                    tooltip: context.t('meetings.propose.durationDecrease'),
                    onPressed: (_busy || _duration <= 15)
                        ? null
                        : () => setState(() => _duration -= 15),
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    context.t(
                      'meetings.propose.durationOption',
                      vars: {'minutes': _duration},
                    ),
                    style: typo.bodyLg.copyWith(color: colors.body),
                  ),
                  IconButton(
                    key: const Key('propose-duration-plus'),
                    tooltip: context.t('meetings.propose.durationIncrease'),
                    onPressed: (_busy || _duration >= 240)
                        ? null
                        : () => setState(() => _duration += 15),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppInput(
                key: const Key('propose-url'),
                value: _url,
                label: context.t('meetings.propose.urlLabel'),
                placeholder: context.t('meetings.propose.urlPlaceholder'),
                keyboardType: TextInputType.url,
                autocorrect: false,
                enabled: !_busy,
                onChanged: (v) => _url = v,
              ),
              const SizedBox(height: 6),
              Text(
                context.t('meetings.propose.icsHelper'),
                style: typo.bodyXs.copyWith(color: colors.muted),
              ),
              const SizedBox(height: 12),
              AppInput(
                key: const Key('propose-note'),
                value: _note,
                label: context.t('meetings.propose.noteLabel'),
                placeholder: context.t('meetings.propose.notePlaceholder'),
                multiline: true,
                minLines: 2,
                maxLines: 4,
                enabled: !_busy,
                onChanged: (v) => _note = v,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(radii.pill),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.globe, size: 14, color: colors.muted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        context.t(
                          'meetings.propose.inputTimeZoneHint',
                          vars: {'tz': _tz},
                        ),
                        style: typo.bodyXs.copyWith(color: colors.muted),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: typo.bodyMd.copyWith(color: colors.danger),
                ),
              ],
              const SizedBox(height: 16),
              // Single full-width primary CTA (mockup G1). The sheet is
              // swipe-/scrim-dismissible, so a redundant Cancel button is
              // dropped in favour of the single-CTA layout.
              AppButton(
                key: const Key('propose-submit'),
                label: context.t('meetings.propose.sendProposal'),
                loading: _busy,
                onPressed: _busy ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row in the connected slot group (mockup G1). Tapping the row opens
/// the date/time picker; the trailing ★/☆ toggles this slot as preferred.
///
/// Rounding is applied only on the group's top ([isFirst]) and bottom
/// ([isLast]) corners; the shared border between rows is collapsed by
/// dropping the top border on every row after the first.
class _SlotRow extends StatelessWidget {
  const _SlotRow({
    super.key,
    required this.index,
    required this.value,
    required this.fmt,
    required this.durationMinutes,
    required this.isFirst,
    required this.isLast,
    required this.isPreferred,
    required this.onTap,
    required this.onTogglePreferred,
  });

  final int index;
  final DateTime? value;
  final DateFormat fmt;
  final int durationMinutes;
  final bool isFirst;
  final bool isLast;
  final bool isPreferred;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePreferred;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final typo = Theme.of(context).extension<AppTypography>()!;
    const r = Radius.circular(10);
    final borderRadius = BorderRadius.only(
      topLeft: isFirst ? r : Radius.zero,
      topRight: isFirst ? r : Radius.zero,
      bottomLeft: isLast ? r : Radius.zero,
      bottomRight: isLast ? r : Radius.zero,
    );
    final defaultLabel = context.t('meetings.propose.slot${index + 1}Label');
    final starLabel = context.t(
      isPreferred
          ? 'meetings.propose.preferredSlotOn'
          : 'meetings.propose.preferredSlot',
    );
    return Material(
      color: colors.white,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border(
              left: BorderSide(color: colors.border),
              right: BorderSide(color: colors.border),
              top: BorderSide(color: colors.border),
              bottom:
                  isLast ? BorderSide(color: colors.border) : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value == null ? defaultLabel : fmt.format(value!),
                      style: typo.bodyLg.copyWith(
                        color: value == null ? colors.muted : colors.body,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.t(
                        'meetings.propose.durationOption',
                        vars: {'minutes': durationMinutes},
                      ),
                      style: typo.bodyXs.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Trailing preferred-slot star toggle. Disabled until the row
              // has a value picked.
              IconButton(
                key: Key('propose-slot-$index-star'),
                tooltip: starLabel,
                visualDensity: VisualDensity.compact,
                onPressed: onTogglePreferred,
                icon: Icon(
                  isPreferred ? Icons.star : Icons.star_border,
                  color: isPreferred ? colors.gold : colors.muted,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
