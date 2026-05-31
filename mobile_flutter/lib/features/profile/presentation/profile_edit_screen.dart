import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/providers/profile_provider.dart';
import '../../onboarding/data/infer_goal_service.dart';
import '../../onboarding/domain/goal_type.dart';
import '../../onboarding/domain/onboarding_schemas.dart';
import '../domain/profile.dart';
import '../providers/own_profile_controller.dart';
import 'avatar_picker_field.dart';
import 'goal_refresh_card.dart';

/// Role kinds the form chip-selects from. Mirrors Phase-3's `RolesStep`
/// catalog — kept local here so this screen does not depend on Phase-3
/// presentation internals.
const List<String> _kRoleKinds = <String>[
  'founder',
  'leader',
  'builder',
  'investor',
];

/// Headline max length surfaced in the inline counter ("Headline · N/80",
/// mockup D3 line 1680). The shared [HeadlineInput.maxLength] schema currently
/// allows 120; we cap the form at 80 to match the mockup. NOTE: reconcile the
/// `HeadlineInput` schema bound (and any backend CHECK) to 80 so the form and
/// validation agree app-wide — that schema lives outside this feature dir.
const int _kHeadlineMaxLength = 80;

/// Profile edit form — gallery section D3.
///
/// All long-text fields use [AppInput]'s built-in counter / max-length
/// support, so the user sees the live `current/max` indicator without us
/// hand-rolling a counter row. Handle field is rendered with `enabled: false`
/// per spec §17.5 — handle changes are not currently supported.
///
/// The `goal_text` field debounces an inference call into Phase 3's
/// [InferGoalService] (800ms / gated at 20 chars) and auto-applies a high-
/// confidence result to the `goal_type` selector — same UX as the
/// onboarding `GoalStep`.
/// Form fields that can carry an inline validation error. Used to key the
/// per-field error map and the [GlobalKey]s we scroll into view on a failed
/// validate.
enum _Field { name, handle, headline, bio, goalText, city, country }

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  // Local form state — initialised lazily inside the QueryState data builder
  // so we never have to branch on a null profile inside the form widgets.
  late String _name;
  late String _handle;
  late String _originalHandle;
  late String _headline;
  late String _bio;
  late String _goalText;
  late String _city;
  late String _country;
  String? _goalType;
  String? _primaryRole;
  Set<String> _roles = <String>{};
  String? _photoUrl;
  // Role-specific structured details. Optional — never validated. Text and
  // list fields are held as plain strings (lists as their comma-joined form,
  // see [_formatList] / [_parseList]); `founder_hiring` is a tristate bool
  // that stays null until the user touches the switch.
  late String _builderDiscipline;
  late String _builderSeniority;
  late String _builderSkills;
  late String _builderOpenTo;
  late String _builderRateBand;
  late String _founderStage;
  late String _founderSector;
  late String _founderFunding;
  bool? _founderHiring;
  late String _investorType;
  late String _investorCheckSize;
  late String _investorSectors;
  late String _investorStage;
  // When the user removes the avatar we must send an explicit `photo_url: null`
  // on save (rather than omitting the key, which would leave the old value).
  bool _photoRemoved = false;

  bool _bound = false;
  bool _saving = false;
  // Localized banner copy for a true save/network failure (never the raw '$e').
  String? _saveError;
  // Per-field validation errors, keyed by [_Field]. Each maps to the relevant
  // [AppInput.errorText]. The goal-type / roles selectors surface their errors
  // through [_selectorError] since they aren't [AppInput]s.
  final Map<_Field, String> _fieldErrors = <_Field, String>{};
  String? _selectorError;
  GoalType? _lastAutoApplied;
  Timer? _inferDebounce;

  final ScrollController _scrollController = ScrollController();
  final Map<_Field, GlobalKey> _fieldKeys = <_Field, GlobalKey>{
    for (final _Field f in _Field.values) f: GlobalKey(),
  };

  void _bind(Profile p) {
    if (_bound) return;
    _bound = true;
    _name = p.name ?? '';
    _handle = p.handle ?? '';
    _originalHandle = p.handle ?? '';
    _headline = p.headline ?? '';
    _bio = p.bio ?? '';
    _goalText = p.goalText ?? '';
    _city = p.city ?? '';
    _country = p.country ?? '';
    _goalType = p.goalType;
    _primaryRole = p.primaryRole;
    _roles = p.roles.toSet();
    _photoUrl = p.photoUrl;
    _builderDiscipline = p.builderDiscipline ?? '';
    _builderSeniority = p.builderSeniority ?? '';
    _builderSkills = _formatList(p.builderSkills);
    _builderOpenTo = _formatList(p.builderOpenTo);
    _builderRateBand = p.builderRateBand ?? '';
    _founderStage = p.founderStage ?? '';
    _founderSector = p.founderSector ?? '';
    _founderFunding = p.founderFunding ?? '';
    _founderHiring = p.founderHiring;
    _investorType = p.investorType ?? '';
    _investorCheckSize = p.investorCheckSize ?? '';
    _investorSectors = _formatList(p.investorSectors);
    _investorStage = p.investorStage ?? '';
  }

  /// Formats a `text[]` column value into the comma-separated string the
  /// list-style [AppInput]s edit. Inverse of [_parseList].
  static String _formatList(List<String> items) => items.join(', ');

  /// Parses a comma-separated [AppInput] value back into the trimmed,
  /// blank-stripped `text[]` payload. Inverse of [_formatList].
  static List<String> _parseList(String raw) => raw
      .split(',')
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    // Fires once per screen open regardless of entry point (top-bar edit,
    // body Edit button, goal-refresh "Update", or a deep link).
    Analytics.log(AppEvent.profileEditOpened);
  }

  @override
  void dispose() {
    _inferDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onGoalTextChanged(String value) {
    setState(() {
      _goalText = value;
      _fieldErrors.remove(_Field.goalText);
    });
    _inferDebounce?.cancel();
    if (value.trim().length < 20) return;
    _inferDebounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        final InferGoalService svc = ref.read(inferGoalServiceProvider);
        final InferGoalResult result = await svc.infer(
          text: value,
          primaryRole: _primaryRole,
          roles: _roles.isEmpty ? null : _roles.toList(),
        );
        if (!mounted) return;
        if (result.confidence == InferConfidence.high &&
            result.goalType != null &&
            _lastAutoApplied != result.goalType) {
          _lastAutoApplied = result.goalType;
          setState(() => _goalType = result.goalType!.wire);
        }
      } catch (_) {
        // Best-effort — inference failures don't block the form.
      }
    });
  }

  /// Re-runs validation, populating [_fieldErrors] / [_selectorError] with
  /// localized messages. Returns the first errored field (form order) so the
  /// caller can scroll it into view, or null when the form is ready to submit.
  /// Mirrors the schema order so errors line up with the visual layout.
  _Field? _validate() {
    _fieldErrors.clear();
    _selectorError = null;

    if (NameInput.dirty(_name).error != null) {
      _fieldErrors[_Field.name] = context.t('profile.errors.nameLen');
    }
    // Handle: re-use the same regex enforced by the citext CHECK constraint
    // on `profiles.handle` (spec §3.1) so the form errors mirror the DB.
    if (HandleInput.dirty(_handle.trim()).error != null) {
      _fieldErrors[_Field.handle] = context.t('profile.errors.handleInvalid');
    }
    final String h = _headline.trim();
    if (h.isNotEmpty && (h.length < 5 || h.length > _kHeadlineMaxLength)) {
      _fieldErrors[_Field.headline] = context.t('profile.errors.headlineLen');
    }
    final String b = _bio.trim();
    if (b.isNotEmpty && (b.length < 10 || b.length > 1000)) {
      _fieldErrors[_Field.bio] = context.t('profile.errors.bioLen');
    }
    if (GoalTextInput.dirty(_goalText).error != null) {
      _fieldErrors[_Field.goalText] = context.t('profile.errors.goalLen');
    }
    if (_goalType == null) {
      _selectorError = context.t('profile.errors.goalTypeRequired');
    } else if (_roles.isEmpty) {
      _selectorError = context.t('profile.errors.rolesRequired');
    } else if (_primaryRole == null || !_roles.contains(_primaryRole)) {
      _selectorError = context.t('profile.errors.primaryRoleInRoles');
    }
    if (CityInput.dirty(_city).error != null) {
      _fieldErrors[_Field.city] = context.t('profile.errors.cityRequired');
    }
    if (CountryInput.dirty(_country).error != null) {
      _fieldErrors[_Field.country] =
          context.t('profile.errors.countryRequired');
    }

    // First errored field in form order — used to scroll it into view.
    for (final _Field f in _Field.values) {
      if (_fieldErrors.containsKey(f)) return f;
    }
    return null;
  }

  void _scrollFieldIntoView(_Field field) {
    final BuildContext? ctx = _fieldKeys[field]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }

  Future<void> _save() async {
    final _Field? firstError = _validate();
    if (firstError != null || _selectorError != null) {
      Haptics.error();
      setState(() {});
      if (firstError != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollFieldIntoView(firstError),
        );
      }
      return;
    }
    Haptics.medium();
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final String nextHandle = _handle.trim();
      await ref
          .read(ownProfileControllerProvider.notifier)
          .updateOwnProfile(<String, dynamic>{
        'name': _name.trim(),
        'headline': _headline.trim().isEmpty ? null : _headline.trim(),
        'bio': _bio.trim().isEmpty ? null : _bio.trim(),
        'goal_text': _goalText.trim(),
        'goal_type': _goalType,
        'roles': _roles.toList(),
        'primary_role': _primaryRole,
        'city': _city.trim(),
        'country': _country.trim(),
        // Send the photo when set, an explicit null when removed, and omit it
        // entirely on a no-op edit (avatar upload already patched the column).
        if (_photoRemoved)
          'photo_url': null
        else if (_photoUrl != null)
          'photo_url': _photoUrl,
        // Only send the handle when it actually changed — keeps the patch
        // smaller and avoids the 90-day redirect trigger on no-op edits.
        if (nextHandle.isNotEmpty && nextHandle != _originalHandle)
          'handle': nextHandle,
        // Role-specific structured details. All optional: empty text → null,
        // list fields → the parsed (possibly empty) array, founder_hiring →
        // the tristate bool. We always send them so clearing a field persists.
        'builder_discipline':
            _builderDiscipline.trim().isEmpty ? null : _builderDiscipline.trim(),
        'builder_seniority':
            _builderSeniority.trim().isEmpty ? null : _builderSeniority.trim(),
        'builder_skills': _parseList(_builderSkills),
        'builder_open_to': _parseList(_builderOpenTo),
        'builder_rate_band':
            _builderRateBand.trim().isEmpty ? null : _builderRateBand.trim(),
        'founder_stage':
            _founderStage.trim().isEmpty ? null : _founderStage.trim(),
        'founder_sector':
            _founderSector.trim().isEmpty ? null : _founderSector.trim(),
        'founder_funding':
            _founderFunding.trim().isEmpty ? null : _founderFunding.trim(),
        'founder_hiring': _founderHiring,
        'investor_type':
            _investorType.trim().isEmpty ? null : _investorType.trim(),
        'investor_check_size': _investorCheckSize.trim().isEmpty
            ? null
            : _investorCheckSize.trim(),
        'investor_sectors': _parseList(_investorSectors),
        'investor_stage':
            _investorStage.trim().isEmpty ? null : _investorStage.trim(),
      });
      Analytics.log(AppEvent.profileSaved);
      if (!mounted) return;
      ref.read(toastServiceProvider.notifier).showToast(
            title: context.t('profile.saveSuccess'),
            intent: AppIntent.success,
          );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/profile');
      }
    } catch (e) {
      if (!mounted) return;
      Haptics.error();
      setState(() => _saveError = messageForError(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Builds the conditional "Role details" section: a per-role subheading +
  /// the role's optional fields, shown only when that role is selected.
  /// Returns an empty list when no supported role is selected so the form
  /// collapses cleanly. All fields here are optional and never validated.
  List<Widget> _buildRoleDetails(BuildContext context, AppSpacing spacing) {
    final List<Widget> children = <Widget>[];
    if (_roles.contains('builder')) {
      children.addAll(<Widget>[
        Gap(spacing.card),
        _SelectorLabel(text: context.t('profile.roleDetails.builderTitle')),
        Gap(spacing.xs),
        _roleTextField(
          context,
          key: 'builderDiscipline',
          label: context.t('profile.roleDetails.discipline'),
          value: _builderDiscipline,
          onChanged: (String v) => _builderDiscipline = v,
        ),
        Gap(spacing.card),
        _roleTextField(
          context,
          key: 'builderSeniority',
          label: context.t('profile.roleDetails.seniority'),
          value: _builderSeniority,
          onChanged: (String v) => _builderSeniority = v,
        ),
        Gap(spacing.card),
        _roleListField(
          context,
          key: 'builderSkills',
          label: context.t('profile.roleDetails.skills'),
          value: _builderSkills,
          onChanged: (String v) => _builderSkills = v,
        ),
        Gap(spacing.card),
        _roleListField(
          context,
          key: 'builderOpenTo',
          label: context.t('profile.roleDetails.openTo'),
          value: _builderOpenTo,
          onChanged: (String v) => _builderOpenTo = v,
        ),
        Gap(spacing.card),
        _roleTextField(
          context,
          key: 'builderRateBand',
          label: context.t('profile.roleDetails.rateBand'),
          value: _builderRateBand,
          onChanged: (String v) => _builderRateBand = v,
        ),
      ]);
    }
    if (_roles.contains('founder')) {
      children.addAll(<Widget>[
        Gap(spacing.card),
        _SelectorLabel(text: context.t('profile.roleDetails.founderTitle')),
        Gap(spacing.xs),
        _roleTextField(
          context,
          key: 'founderStage',
          label: context.t('profile.roleDetails.stage'),
          value: _founderStage,
          onChanged: (String v) => _founderStage = v,
        ),
        Gap(spacing.card),
        _roleTextField(
          context,
          key: 'founderSector',
          label: context.t('profile.roleDetails.sector'),
          value: _founderSector,
          onChanged: (String v) => _founderSector = v,
        ),
        Gap(spacing.card),
        _roleTextField(
          context,
          key: 'founderFunding',
          label: context.t('profile.roleDetails.funding'),
          value: _founderFunding,
          onChanged: (String v) => _founderFunding = v,
        ),
        Gap(spacing.xs),
        SwitchListTile(
          key: const Key('profileEdit.founderHiring'),
          contentPadding: EdgeInsets.zero,
          title: Text(context.t('profile.roleDetails.currentlyHiring')),
          value: _founderHiring ?? false,
          onChanged: (bool v) {
            Haptics.selection();
            setState(() => _founderHiring = v);
          },
        ),
      ]);
    }
    if (_roles.contains('investor')) {
      children.addAll(<Widget>[
        Gap(spacing.card),
        _SelectorLabel(text: context.t('profile.roleDetails.investorTitle')),
        Gap(spacing.xs),
        _roleTextField(
          context,
          key: 'investorType',
          label: context.t('profile.roleDetails.type'),
          value: _investorType,
          onChanged: (String v) => _investorType = v,
        ),
        Gap(spacing.card),
        _roleTextField(
          context,
          key: 'investorCheckSize',
          label: context.t('profile.roleDetails.checkSize'),
          value: _investorCheckSize,
          onChanged: (String v) => _investorCheckSize = v,
        ),
        Gap(spacing.card),
        _roleListField(
          context,
          key: 'investorSectors',
          label: context.t('profile.roleDetails.sectors'),
          value: _investorSectors,
          onChanged: (String v) => _investorSectors = v,
        ),
        Gap(spacing.card),
        _roleTextField(
          context,
          key: 'investorStage',
          label: context.t('profile.roleDetails.stage'),
          value: _investorStage,
          onChanged: (String v) => _investorStage = v,
        ),
      ]);
    }
    return children;
  }

  /// Single-line optional role field. Writes straight to the backing string
  /// without a `_fieldErrors` entry — these fields are never validated.
  Widget _roleTextField(
    BuildContext context, {
    required String key,
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return AppInput(
      key: Key('profileEdit.$key'),
      label: label,
      value: value,
      maxLength: 60,
      onChanged: (String v) => setState(() => onChanged(v)),
    );
  }

  /// Comma-separated `text[]` role field — same chrome as [_roleTextField]
  /// but with the "Comma-separated" placeholder so the user knows how the
  /// value is split (see [_parseList] / [_formatList]).
  Widget _roleListField(
    BuildContext context, {
    required String key,
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return AppInput(
      key: Key('profileEdit.$key'),
      label: label,
      value: value,
      placeholder: context.t('profile.roleDetails.listHint'),
      onChanged: (String v) => setState(() => onChanged(v)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppSpacing spacing = Theme.of(context).extension<AppSpacing>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final AsyncValue<Profile?> asyncProfile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        // Custom top bar: the mockup (D3 line 1675) shows the Save action as
        // gold bold Dosis text, which the shared icon-only [TopBar.actions]
        // can't express, so we mirror TopBar's chrome here with a text action.
        child: _EditTopBar(
          title: context.t('profile.edit.title'),
          saveLabel: context.t('profile.edit.save'),
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
          onSave: _saving ? null : _save,
        ),
      ),
      body: QueryState<Profile?>(
        value: asyncProfile,
        data: (Profile? profile) {
          if (profile == null) {
            return Center(child: Text(context.t('profile.notFound')));
          }
          _bind(profile);
          return ListView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              spacing.gutter,
              spacing.card,
              spacing.gutter,
              spacing.section,
            ),
            // Field order follows mockup D3 (lines 1679-1700): identity-first —
            // Name → Handle → Headline → I am → I'm looking to → Roles → Photo.
            // The extra fields Flutter captures (goal type, primary role, city,
            // country) are grouped with their nearest mockup peer.
            children: <Widget>[
              if (profile.isGoalStale) ...<Widget>[
                GoalRefreshCard(
                  key: const Key('profileEdit.goalRefresh'),
                  profile: profile,
                  // Already on the edit screen — "Update" scrolls the goal
                  // field into view; "Yes, still accurate" confirms freshness
                  // so the nudge clears without forcing an edit.
                  onUpdate: () => _scrollFieldIntoView(_Field.goalText),
                  onDismiss: () async {
                    Haptics.light();
                    await ref
                        .read(ownProfileControllerProvider.notifier)
                        .confirmGoalFreshness();
                  },
                ),
                Gap(spacing.card),
              ],
              if (_saveError != null) ...<Widget>[
                AppBanner(
                  key: const Key('profileEdit.saveError'),
                  intent: AppIntent.danger,
                  title: context.t('profile.saveFailed'),
                  onClose: () => setState(() => _saveError = null),
                  child: Text(_saveError!),
                ),
                Gap(spacing.card),
              ],
              // 1) Name — identity leads the form.
              KeyedSubtree(
                key: _fieldKeys[_Field.name],
                child: AppInput(
                  key: const Key('profileEdit.name'),
                  label: context.t('profile.fields.name'),
                  value: _name,
                  maxLength: NameInput.maxLength,
                  errorText: _fieldErrors[_Field.name],
                  onChanged: (String v) => setState(() {
                    _name = v;
                    _fieldErrors.remove(_Field.name);
                  }),
                ),
              ),
              Gap(spacing.card),
              // 2) Handle + 90-day-then-410 redirect note
              KeyedSubtree(
                key: _fieldKeys[_Field.handle],
                child: AppInput(
                  key: const Key('profileEdit.handle'),
                  label: context.t('profile.fields.handle'),
                  value: _handle,
                  errorText: _fieldErrors[_Field.handle],
                  onChanged: (String v) => setState(() {
                    _handle = v;
                    _fieldErrors.remove(_Field.handle);
                  }),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: spacing.xs),
                child: Text(
                  context.t('profile.handleRedirectNote'),
                  style: typo.bodyXs.copyWith(color: colors.muted),
                ),
              ),
              Gap(spacing.card),
              // 3) Headline — the label carries the live char counter via
              //    AppInput's built-in maxLength counter (mockup
              //    "Headline · 47/80"), capped at 80.
              KeyedSubtree(
                key: _fieldKeys[_Field.headline],
                child: AppInput(
                  key: const Key('profileEdit.headline'),
                  label: context.t('profile.fields.headline'),
                  value: _headline,
                  maxLength: _kHeadlineMaxLength,
                  errorText: _fieldErrors[_Field.headline],
                  onChanged: (String v) => setState(() {
                    _headline = v;
                    _fieldErrors.remove(_Field.headline);
                  }),
                ),
              ),
              Gap(spacing.card),
              // 2) I am (bio)
              KeyedSubtree(
                key: _fieldKeys[_Field.bio],
                child: AppInput(
                  key: const Key('profileEdit.bio'),
                  label: context.t('profile.fields.bio'),
                  value: _bio,
                  multiline: true,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: BioInput.maxLength,
                  errorText: _fieldErrors[_Field.bio],
                  onChanged: (String v) => setState(() {
                    _bio = v;
                    _fieldErrors.remove(_Field.bio);
                  }),
                ),
              ),
              Gap(spacing.card),
              // 3) I'm looking to (goal text) + goal-type selector
              KeyedSubtree(
                key: _fieldKeys[_Field.goalText],
                child: AppInput(
                  key: const Key('profileEdit.goalText'),
                  label: context.t('profile.fields.goalText'),
                  value: _goalText,
                  multiline: true,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: GoalTextInput.maxLength,
                  errorText: _fieldErrors[_Field.goalText],
                  onChanged: _onGoalTextChanged,
                ),
              ),
              Gap(spacing.sm),
              _SelectorLabel(text: context.t('profile.fields.goalType')),
              Gap(spacing.xs),
              Wrap(
                spacing: spacing.xs,
                runSpacing: spacing.xs,
                children: <Widget>[
                  for (final GoalType g in GoalType.values)
                    AppFilterChip(
                      key: ValueKey<String>('profileEdit.goalType.${g.wire}'),
                      label: context.t(g.i18nLabelKey),
                      active: _goalType == g.wire,
                      onTap: () {
                        Haptics.selection();
                        setState(() {
                          _goalType = g.wire;
                          _selectorError = null;
                        });
                      },
                    ),
                ],
              ),
              Gap(spacing.card),
              // 4) Roles — selected chips carry a trailing ✓ (mockup line 1688).
              _SelectorLabel(text: context.t('profile.fields.roles')),
              Gap(spacing.xs),
              Wrap(
                spacing: spacing.xs,
                runSpacing: spacing.xs,
                children: <Widget>[
                  for (final String r in _kRoleKinds)
                    AppFilterChip(
                      key: ValueKey<String>('profileEdit.role.$r'),
                      label: _roles.contains(r)
                          ? '${context.t('onboarding.roles.$r')} ✓'
                          : context.t('onboarding.roles.$r'),
                      active: _roles.contains(r),
                      onTap: () {
                        Haptics.selection();
                        setState(() {
                          _selectorError = null;
                          if (_roles.contains(r)) {
                            _roles.remove(r);
                            if (_primaryRole == r) {
                              _primaryRole =
                                  _roles.isEmpty ? null : _roles.first;
                            }
                          } else {
                            _roles.add(r);
                            _primaryRole ??= r;
                          }
                        });
                      },
                    ),
                ],
              ),
              Gap(spacing.card),
              _SelectorLabel(text: context.t('profile.fields.primaryRole')),
              Gap(spacing.xs),
              Wrap(
                spacing: spacing.xs,
                runSpacing: spacing.xs,
                children: <Widget>[
                  for (final String r in _roles)
                    AppFilterChip(
                      key: ValueKey<String>('profileEdit.primaryRole.$r'),
                      label: _primaryRole == r
                          ? '${context.t('onboarding.roles.$r')} ✓'
                          : context.t('onboarding.roles.$r'),
                      active: _primaryRole == r,
                      onTap: () {
                        Haptics.selection();
                        setState(() {
                          _primaryRole = r;
                          _selectorError = null;
                        });
                      },
                    ),
                ],
              ),
              if (_selectorError != null) ...<Widget>[
                Gap(spacing.xs),
                Text(
                  _selectorError!,
                  key: const Key('profileEdit.selectorError'),
                  style: typo.bodyXs.copyWith(color: colors.danger),
                ),
              ],
              // 4b) Role details — conditional on the selected roles. Optional
              //     fields (never validated); each role's block only renders
              //     when that role is selected.
              ..._buildRoleDetails(context, spacing),
              Gap(spacing.card),
              // 5) Photo
              Center(
                child: AvatarPickerField(
                  name: _name,
                  currentUrl: _photoUrl,
                  onUploaded: (String url) => setState(() {
                    _photoUrl = url;
                    _photoRemoved = false;
                  }),
                  onRemoved: () => setState(() {
                    _photoUrl = null;
                    _photoRemoved = true;
                  }),
                ),
              ),
              Gap(spacing.card),
              KeyedSubtree(
                key: _fieldKeys[_Field.city],
                child: AppInput(
                  key: const Key('profileEdit.city'),
                  label: context.t('profile.fields.city'),
                  value: _city,
                  maxLength: CityInput.maxLength,
                  errorText: _fieldErrors[_Field.city],
                  onChanged: (String v) => setState(() {
                    _city = v;
                    _fieldErrors.remove(_Field.city);
                  }),
                ),
              ),
              Gap(spacing.card),
              KeyedSubtree(
                key: _fieldKeys[_Field.country],
                child: AppInput(
                  key: const Key('profileEdit.country'),
                  label: context.t('profile.fields.country'),
                  value: _country,
                  maxLength: CountryInput.maxLength,
                  errorText: _fieldErrors[_Field.country],
                  onChanged: (String v) => setState(() {
                    _country = v;
                    _fieldErrors.remove(_Field.country);
                  }),
                ),
              ),
              Gap(spacing.section),
              // Single Cancel affordance — the redundant bottom "Save" was
              // removed; Save now lives only in the top bar (mockup D3).
              AppButton(
                key: const Key('profileEdit.cancel'),
                label: context.t('profile.edit.cancel'),
                variant: AppButtonVariant.outline,
                onPressed: _saving
                    ? null
                    : () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/profile');
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Small caps-style section label used above the chip selectors (goal type,
/// roles, primary role). Dedupes the repeated muted-bold-tracked text style.
class _SelectorLabel extends StatelessWidget {
  const _SelectorLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    return Text(
      text,
      style: typo.bodyXs.copyWith(
        color: colors.muted,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

/// Edit-screen top bar — mirrors the shared [TopBar] chrome (white bg, bottom
/// border, displayMd navy title, back chevron) but renders the Save action as
/// gold bold Dosis text per mockup D3 (line 1675), which [TopBar]'s icon-only
/// actions can't express. A null [onSave] reads as disabled (greyed, no tap),
/// matching the in-flight save state.
class _EditTopBar extends StatelessWidget {
  const _EditTopBar({
    required this.title,
    required this.saveLabel,
    required this.onBack,
    required this.onSave,
  });

  final String title;
  final String saveLabel;
  final VoidCallback onBack;
  final VoidCallback? onSave;

  static const double _maxStatusBarInset = 64;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = Theme.of(context).extension<AppColors>()!;
    final AppTypography typo = Theme.of(context).extension<AppTypography>()!;
    final MediaQueryData? mq = MediaQuery.maybeOf(context);
    final double topInset =
        (mq?.padding.top ?? 0).clamp(0.0, _maxStatusBarInset);

    return Container(
      padding: EdgeInsets.fromLTRB(8, topInset + 6, 8, 8),
      decoration: BoxDecoration(
        color: colors.white,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          AppIconButton(
            icon: Icons.chevron_left,
            label: context.t('common.back'),
            size: AppIconButtonSize.md,
            onPressed: onBack,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typo.displayMd.copyWith(color: colors.navy),
              ),
            ),
          ),
          // Gold bold text Save action (Dosis 13px) — the mockup's chrome.
          Semantics(
            button: true,
            enabled: onSave != null,
            label: saveLabel,
            child: InkResponse(
              key: const Key('profileEdit.topBarSave'),
              onTap: onSave,
              radius: 28,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  saveLabel,
                  style: typo.displayXs.copyWith(
                    color: onSave == null ? colors.muted : colors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
