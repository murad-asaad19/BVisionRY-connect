import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/i18n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
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

  bool _bound = false;
  bool _saving = false;
  String? _saveError;
  GoalType? _lastAutoApplied;
  Timer? _inferDebounce;

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
  }

  @override
  void dispose() {
    _inferDebounce?.cancel();
    super.dispose();
  }

  void _onGoalTextChanged(String value) {
    setState(() => _goalText = value);
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

  /// Returns the i18n key of the first validation failure, or null when the
  /// form is ready to submit. Mirrors the schema order so the message lines
  /// up with the visual layout of the form.
  String? _validate() {
    if (NameInput.dirty(_name).error != null) {
      return 'profile.errors.nameLen';
    }
    // Handle: re-use the same regex enforced by the citext CHECK constraint
    // on `profiles.handle` (spec §3.1) so the form errors mirror the DB.
    final String handle = _handle.trim();
    if (HandleInput.dirty(handle).error != null) {
      return 'profile.errors.handleInvalid';
    }
    final String h = _headline.trim();
    if (h.isNotEmpty && (h.length < 5 || h.length > 120)) {
      return 'profile.errors.headlineLen';
    }
    final String b = _bio.trim();
    if (b.isNotEmpty && (b.length < 10 || b.length > 1000)) {
      return 'profile.errors.bioLen';
    }
    if (GoalTextInput.dirty(_goalText).error != null) {
      return 'profile.errors.goalLen';
    }
    if (_goalType == null) return 'profile.errors.goalTypeRequired';
    if (_roles.isEmpty) return 'profile.errors.rolesRequired';
    if (_primaryRole == null || !_roles.contains(_primaryRole)) {
      return 'profile.errors.primaryRoleInRoles';
    }
    if (CityInput.dirty(_city).error != null) {
      return 'profile.errors.cityRequired';
    }
    if (CountryInput.dirty(_country).error != null) {
      return 'profile.errors.countryRequired';
    }
    return null;
  }

  Future<void> _save() async {
    final String? errKey = _validate();
    if (errKey != null) {
      setState(() => _saveError = context.t(errKey));
      return;
    }
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
        if (_photoUrl != null) 'photo_url': _photoUrl,
        // Only send the handle when it actually changed — keeps the patch
        // smaller and avoids the 90-day redirect trigger on no-op edits.
        if (nextHandle.isNotEmpty && nextHandle != _originalHandle)
          'handle': nextHandle,
      });
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
      setState(() => _saveError = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
        child: TopBar(
          title: context.t('profile.edit.title'),
          back: true,
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
          actions: <TopBarAction>[
            TopBarAction(
              key: const Key('profileEdit.topBarSave'),
              icon: Icons.check,
              label: context.t('profile.edit.save'),
              onPressed: _saving ? () {} : _save,
            ),
          ],
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
            padding: EdgeInsets.fromLTRB(14, spacing.card, 14, 32),
            children: <Widget>[
              if (profile.isGoalStale) ...<Widget>[
                GoalRefreshCard(
                  key: const Key('profileEdit.goalRefresh'),
                  profile: profile,
                  // Already on the edit screen — surface a passive cue by
                  // focusing the goal field is overkill; the banner copy is
                  // enough. Tapping "Update" is effectively a no-op confirm.
                  onUpdate: () {},
                ),
                SizedBox(height: spacing.card),
              ],
              Center(
                child: AvatarPickerField(
                  name: _name,
                  currentUrl: _photoUrl,
                  onUploaded: (String url) => setState(() => _photoUrl = url),
                ),
              ),
              SizedBox(height: spacing.card),
              if (_saveError != null) ...<Widget>[
                Text(
                  _saveError!,
                  style: typo.bodyMd.copyWith(color: colors.danger),
                ),
                SizedBox(height: spacing.card / 2),
              ],
              AppInput(
                key: const Key('profileEdit.name'),
                label: context.t('profile.fields.name'),
                value: _name,
                maxLength: NameInput.maxLength,
                onChanged: (String v) => setState(() => _name = v),
              ),
              SizedBox(height: spacing.card),
              AppInput(
                key: const Key('profileEdit.handle'),
                label: context.t('profile.fields.handle'),
                value: _handle,
                onChanged: (String v) => setState(() => _handle = v),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  context.t('profile.handleRedirectNote'),
                  style: typo.bodyXs.copyWith(color: colors.muted),
                ),
              ),
              SizedBox(height: spacing.card),
              AppInput(
                key: const Key('profileEdit.headline'),
                label: context.t('profile.fields.headline'),
                value: _headline,
                maxLength: HeadlineInput.maxLength,
                onChanged: (String v) => setState(() => _headline = v),
              ),
              SizedBox(height: spacing.card),
              AppInput(
                key: const Key('profileEdit.bio'),
                label: context.t('profile.fields.bio'),
                value: _bio,
                multiline: true,
                minLines: 3,
                maxLines: 6,
                maxLength: BioInput.maxLength,
                onChanged: (String v) => setState(() => _bio = v),
              ),
              SizedBox(height: spacing.card),
              AppInput(
                key: const Key('profileEdit.goalText'),
                label: context.t('profile.fields.goalText'),
                value: _goalText,
                multiline: true,
                minLines: 2,
                maxLines: 5,
                maxLength: GoalTextInput.maxLength,
                onChanged: _onGoalTextChanged,
              ),
              SizedBox(height: spacing.card / 2),
              Text(
                context.t('profile.fields.goalType'),
                style: typo.bodyXs.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final GoalType g in GoalType.values)
                    AppFilterChip(
                      key: ValueKey<String>('profileEdit.goalType.${g.wire}'),
                      label: context.t(g.i18nLabelKey),
                      active: _goalType == g.wire,
                      onTap: () => setState(() => _goalType = g.wire),
                    ),
                ],
              ),
              SizedBox(height: spacing.card),
              Text(
                context.t('profile.fields.roles'),
                style: typo.bodyXs.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final String r in _kRoleKinds)
                    AppFilterChip(
                      key: ValueKey<String>('profileEdit.role.$r'),
                      label: context.t('onboarding.roles.$r'),
                      active: _roles.contains(r),
                      onTap: () {
                        setState(() {
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
              SizedBox(height: spacing.card),
              Text(
                context.t('profile.fields.primaryRole'),
                style: typo.bodyXs.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final String r in _roles)
                    AppFilterChip(
                      key: ValueKey<String>('profileEdit.primaryRole.$r'),
                      label: context.t('onboarding.roles.$r'),
                      active: _primaryRole == r,
                      onTap: () => setState(() => _primaryRole = r),
                    ),
                ],
              ),
              SizedBox(height: spacing.card),
              AppInput(
                key: const Key('profileEdit.city'),
                label: context.t('profile.fields.city'),
                value: _city,
                maxLength: CityInput.maxLength,
                onChanged: (String v) => setState(() => _city = v),
              ),
              SizedBox(height: spacing.card),
              AppInput(
                key: const Key('profileEdit.country'),
                label: context.t('profile.fields.country'),
                value: _country,
                maxLength: CountryInput.maxLength,
                onChanged: (String v) => setState(() => _country = v),
              ),
              SizedBox(height: spacing.card * 2),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppButton(
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
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      key: const Key('profileEdit.save'),
                      label: context.t('profile.edit.save'),
                      loading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
