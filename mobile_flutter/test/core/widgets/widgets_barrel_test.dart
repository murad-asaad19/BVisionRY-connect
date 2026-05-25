import 'package:connect_mobile/core/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test for the barrel re-export. Every primitive is referenced via
/// a typedef from the barrel — if any export disappears, this fails to
/// compile (no runtime assertion needed). Adding a new primitive should
/// also add a typedef here.
typedef _BannerSig = AppBanner;
typedef _BottomSheetSig = AppBottomSheet;
typedef _ButtonSig = AppButton;
typedef _CardSig = AppCard;
typedef _DividerSig = AppDivider;
typedef _FilterChipSig = AppFilterChip;
typedef _IconButtonSig = AppIconButton;
typedef _InputSig = AppInput;
typedef _StepperSig = AppStepper;
typedef _AvatarSig = Avatar;
typedef _AvatarCircleSig = AvatarCircle;
typedef _EmptyStateSig = EmptyState;
typedef _PillSig = Pill;
typedef _ProgressDotsSig = ProgressDots;
typedef _QueryStateSig = QueryState<String>;
typedef _SectionCardSig = SectionCard;
typedef _SegmentedControlSig = SegmentedControl<String>;
typedef _SettingsRowSig = SettingsRow;
typedef _SkeletonSig = Skeleton;
typedef _SkeletonListRowSig = SkeletonListRow;
typedef _SkeletonProfileSig = SkeletonProfile;
typedef _ToastHostSig = ToastHost;
typedef _TopBarSig = TopBar;
typedef _UserCardSig = UserCard;
typedef _IntentSig = AppIntent;
typedef _ConfirmServiceSig = ConfirmService;

void main() {
  test('widgets barrel exposes every public primitive', () {
    expect(_BannerSig, isNotNull);
    expect(_BottomSheetSig, isNotNull);
    expect(_ButtonSig, isNotNull);
    expect(_CardSig, isNotNull);
    expect(_DividerSig, isNotNull);
    expect(_FilterChipSig, isNotNull);
    expect(_IconButtonSig, isNotNull);
    expect(_InputSig, isNotNull);
    expect(_StepperSig, isNotNull);
    expect(_AvatarSig, isNotNull);
    expect(_AvatarCircleSig, isNotNull);
    expect(_EmptyStateSig, isNotNull);
    expect(_PillSig, isNotNull);
    expect(_ProgressDotsSig, isNotNull);
    expect(_QueryStateSig, isNotNull);
    expect(_SectionCardSig, isNotNull);
    expect(_SegmentedControlSig, isNotNull);
    expect(_SettingsRowSig, isNotNull);
    expect(_SkeletonSig, isNotNull);
    expect(_SkeletonListRowSig, isNotNull);
    expect(_SkeletonProfileSig, isNotNull);
    expect(_ToastHostSig, isNotNull);
    expect(_TopBarSig, isNotNull);
    expect(_UserCardSig, isNotNull);
    expect(_IntentSig, isNotNull);
    expect(_ConfirmServiceSig, isNotNull);
  });
}
