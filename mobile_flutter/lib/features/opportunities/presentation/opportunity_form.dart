import 'package:flutter/material.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/settings_row.dart';
import '../domain/opportunity.dart';
import '../domain/opportunity_kind.dart';
import '../domain/tag_input.dart';
import 'kind_picker.dart';
import 'tag_chip_input.dart';

/// Composer-time value object for the opportunity form. Used by both
/// [NewOpportunityScreen] and [EditOpportunityScreen].
@immutable
class OpportunityFormValue {
  const OpportunityFormValue({
    required this.kind,
    required this.title,
    required this.body,
    required this.tags,
    required this.locationCity,
    required this.locationCountry,
    required this.remoteOk,
    required this.expiresAt,
  });

  final OpportunityKind? kind;
  final String title;
  final String body;
  final TagInput tags;
  final String locationCity;
  final String locationCountry;
  final bool remoteOk;
  final DateTime expiresAt;

  /// Pre-populates the form from an existing [Opportunity] (edit flow).
  factory OpportunityFormValue.fromOpportunity(Opportunity o) {
    return OpportunityFormValue(
      kind: o.kind,
      title: o.title,
      body: o.body,
      tags: TagInput.dirty(List<String>.from(o.tags)),
      locationCity: o.locationCity ?? '',
      locationCountry: o.locationCountry ?? '',
      remoteOk: o.remoteOk,
      expiresAt: o.expiresAt,
    );
  }

  /// Empty composer state with `expiresAt = today + 30d` (UTC midnight).
  factory OpportunityFormValue.empty({DateTime? now}) {
    final DateTime ref = (now ?? DateTime.now()).toUtc();
    final DateTime expires = DateTime.utc(
      ref.year,
      ref.month,
      ref.day,
    ).add(const Duration(days: 30));
    return OpportunityFormValue(
      kind: null,
      title: '',
      body: '',
      tags: const TagInput.pure(),
      locationCity: '',
      locationCountry: '',
      remoteOk: false,
      expiresAt: expires,
    );
  }

  OpportunityFormValue copyWith({
    OpportunityKind? kind,
    String? title,
    String? body,
    TagInput? tags,
    String? locationCity,
    String? locationCountry,
    bool? remoteOk,
    DateTime? expiresAt,
  }) {
    return OpportunityFormValue(
      kind: kind ?? this.kind,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      locationCity: locationCity ?? this.locationCity,
      locationCountry: locationCountry ?? this.locationCountry,
      remoteOk: remoteOk ?? this.remoteOk,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isValid =>
      kind != null &&
      title.length >= 5 &&
      title.length <= 120 &&
      body.length >= 10 &&
      body.length <= 2000 &&
      tags.isValid;

  /// Field-by-field equality used to detect unsaved edits. Compares the tag
  /// *values* (not the `TagInput` wrapper, whose `pure`/`dirty` flag differs
  /// between the empty-composer and edit baselines).
  bool sameContentAs(OpportunityFormValue other) {
    return kind == other.kind &&
        title == other.title &&
        body == other.body &&
        locationCity == other.locationCity &&
        locationCountry == other.locationCountry &&
        remoteOk == other.remoteOk &&
        expiresAt == other.expiresAt &&
        _listEquals(tags.value, other.tags.value);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Single-screen composer for an opportunity (per master plan §17.11 the
/// 3-step RN wizard collapses into a single scrollable form on Flutter).
///
/// Sections (top → bottom): Kind → Content (title + body) → Tags →
/// Meta (city / country / remote / expires).
class OpportunityForm extends StatefulWidget {
  const OpportunityForm({
    super.key,
    this.initial,
    required this.onSubmit,
    required this.submitLabel,
    this.submitting = false,
    this.onDirtyChanged,
  });

  final OpportunityFormValue? initial;
  final Future<void> Function(OpportunityFormValue value) onSubmit;
  final String submitLabel;
  final bool submitting;

  /// Fired whenever the form's dirty state flips. The owning screen wires
  /// this into a `PopScope` so it can prompt to discard unsaved edits.
  final ValueChanged<bool>? onDirtyChanged;

  @override
  State<OpportunityForm> createState() => _OpportunityFormState();
}

class _OpportunityFormState extends State<OpportunityForm> {
  late OpportunityFormValue _value;
  late OpportunityFormValue _baseline;
  bool _touched = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _baseline = widget.initial ?? OpportunityFormValue.empty();
    _value = _baseline;
  }

  void _update(OpportunityFormValue next) {
    setState(() {
      _value = next;
      _touched = true;
    });
    final bool dirty = !next.sameContentAs(_baseline);
    if (dirty != _dirty) {
      _dirty = dirty;
      widget.onDirtyChanged?.call(dirty);
    }
  }

  Future<void> _pickExpiresAt() async {
    final DateTime now = DateTime.now();
    final DateTime min =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final DateTime max =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 90));
    final DateTime initial =
        _value.expiresAt.isBefore(min) ? min : _value.expiresAt;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: min,
      lastDate: max,
    );
    if (picked != null) {
      _update(
        _value.copyWith(
          expiresAt: DateTime.utc(picked.year, picked.month, picked.day),
        ),
      );
    }
  }

  String? _errorForKind() {
    if (!_touched) return null;
    if (_value.kind == null) {
      return context.t('opportunities.composer.errorKindRequired');
    }
    return null;
  }

  String? _errorForTitle() {
    if (!_touched || _value.title.isEmpty) return null;
    if (_value.title.length < 5 || _value.title.length > 120) {
      return context.t('opportunities.composer.errorTitle');
    }
    return null;
  }

  String? _errorForBody() {
    if (!_touched || _value.body.isEmpty) return null;
    if (_value.body.length < 10 || _value.body.length > 2000) {
      return context.t('opportunities.composer.errorBody');
    }
    return null;
  }

  String? _errorForTags() {
    if (!_value.tags.isValid) {
      return context.t('opportunities.composer.errorTags');
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    setState(() => _touched = true);
    if (!_value.isValid) return;
    await widget.onSubmit(_value);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: <Widget>[
        SectionCard(
          title: context.t('opportunities.composer.stepKind'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              KindPicker(
                value: _value.kind,
                onChanged: (OpportunityKind k) =>
                    _update(_value.copyWith(kind: k)),
              ),
              if (_errorForKind() != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  _errorForKind()!,
                  style: typo.bodyXs.copyWith(color: colors.danger),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: context.t('opportunities.composer.stepContent'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppInput(
                label: context.t('opportunities.composer.titleLabel'),
                placeholder:
                    context.t('opportunities.composer.titlePlaceholder'),
                value: _value.title,
                onChanged: (String v) => _update(_value.copyWith(title: v)),
                maxLength: 120,
                errorText: _errorForTitle(),
              ),
              const SizedBox(height: 12),
              AppInput(
                label: context.t('opportunities.composer.bodyLabel'),
                placeholder:
                    context.t('opportunities.composer.bodyPlaceholder'),
                value: _value.body,
                onChanged: (String v) => _update(_value.copyWith(body: v)),
                multiline: true,
                minLines: 4,
                maxLines: 8,
                maxLength: 2000,
                errorText: _errorForBody(),
              ),
              const SizedBox(height: 12),
              TagChipInput(
                label: context.t('opportunities.composer.tagsLabel'),
                placeholder:
                    context.t('opportunities.composer.tagsPlaceholder'),
                value: _value.tags,
                onChanged: (TagInput v) => _update(_value.copyWith(tags: v)),
                errorText: _errorForTags(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: context.t('opportunities.composer.stepMeta'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppInput(
                label: context.t('opportunities.composer.cityLabel'),
                value: _value.locationCity,
                onChanged: (String v) =>
                    _update(_value.copyWith(locationCity: v)),
                maxLength: 64,
              ),
              const SizedBox(height: 12),
              AppInput(
                label: context.t('opportunities.composer.countryLabel'),
                value: _value.locationCountry,
                onChanged: (String v) =>
                    _update(_value.copyWith(locationCountry: v)),
                maxLength: 64,
              ),
              const SizedBox(height: 12),
              SettingsRow(
                label: context.t('opportunities.composer.remoteLabel'),
                trailing: Switch(
                  value: _value.remoteOk,
                  onChanged: (bool v) => _update(_value.copyWith(remoteOk: v)),
                ),
              ),
              const SizedBox(height: 6),
              SettingsRow(
                label: context.t('opportunities.composer.expiresLabel'),
                description: context.t('opportunities.composer.expiresHint'),
                onTap: _pickExpiresAt,
                trailing: Text(
                  _formatDate(_value.expiresAt),
                  style: typo.displaySm.copyWith(color: colors.navy),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: widget.submitLabel,
          variant: AppButtonVariant.gold,
          loading: widget.submitting,
          onPressed: _value.isValid ? _handleSubmit : null,
        ),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}
