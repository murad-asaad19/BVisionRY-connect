# UI/UX Audit — BVisionry Connect

_Audited 2026-05-24 against current `main` at commit `dfe7699` (web build at `http://localhost:8081`, mobile-width viewport 390×844)._

## Executive Summary

The product surface is already cohesive in **intent** — there is a clear navy/gold brand, a single set of UI primitives, and most screens reuse them. What separates the current build from "enterprise-grade" is **discipline**, not direction: typography drifts from a 6-step token set into ~14 inline px values across the codebase, four parallel surface-header patterns exist (`TopBar`, ad-hoc `pt-16` titles on Chats/Network/Sign-in, gradient hero, plain border-bottom), six screens render their own bespoke empty/error treatments instead of going through the shared primitive, and several flagship moments — the chat conversation header, the navy-on-gradient profile hero, the global "Sign out" button, and the meeting card — leak raw hex literals or off-token spacing. None of these are hard to fix; they're each a one-day cleanup. **The single biggest gap is the typography/spacing token system: the tokens exist (`@theme` in `global.css`), but components ignore them and reach for `text-[12px]`/`text-[13px]`/`text-2xl`/`font-semibold` indiscriminately.** Without a Tier-1 typography scale and a `Surface`/`SectionHeader`/`EmptyState`/`Skeleton` primitive set, every new feature will keep diverging.

A reasonable 30/60/90 shape: **30 days** — adopt a typography scale (`text-display-*`/`text-body-*`), publish 4 new primitives (EmptyState, Skeleton, ScreenHeader, SectionCard), and migrate the top 10 screens; **60 days** — replace native `Alert.alert` confirms with a branded `<ConfirmDialog>`, ship a `Toast` system, add skeleton loaders, fix the chat conversation header + composer + bottom-tab emoji icons; **90 days** — accessibility pass (aria/contrast/focus rings), microinteractions (transitions on tab change, intro accept), and the first real empty-state illustrations.

---

## P0 — Blockers (would prevent shipping)

### P0-1. Bottom tab bar uses emoji as icons — non-negotiable for enterprise
- **WHAT.** All 5 tabs render emoji glyphs (`🏠`, `📬`, `🤝`, `💼`, `💬`) instead of icons. Renders differently across Android/iOS/Web and Apple/Google/Microsoft emoji fonts — actively unprofessional.
- **WHERE.** `mobile/app/(app)/(tabs)/_layout.tsx:9-15` (the `ICONS` map) — visible in `01-home.png`, `02-inbox.png`, `03-network.png`, `04-opportunities.png`, `05-chats.png`.
- **WHY.** First thing a paying user sees on every screen. On the Windows-Chromium screenshot the icons render in segoe-emoji color, which clashes with the navy/gold palette and breaks the "calm, confident, trustworthy" intent.
- **HOW.** Install `lucide-react-native` (already pairs natively with NativeWind + RN-Web) and replace the map with `Home`, `Inbox`, `Users`, `Briefcase`, `MessageSquare`. Render via `<Icon size={20} color={focused ? colors.navy : colors.muted} />`. Same fix kills the `📷`/`+`/`→` glyphs in `MessageComposer.tsx:57,70,106`, the `🔔`/`🔇` in `ConversationScreen.tsx:282`, the `⋯` in `ProfileActionsMenu.tsx:43`, the `✉` in `EmptyInbox.tsx:13`, the `›` chevrons in `SettingsRow.tsx:73` / `ProfileEditForm.tsx:361`, and the `‹` / `←` back arrows in `TopBar.tsx:58` and `ConversationScreen.tsx:259`.

![home with emoji tabs](./.audit-screenshots/01-home.png)

### P0-2. Chat conversation header bypasses TopBar — divergent UX, no SafeArea inset
- **WHAT.** The conversation screen builds its own header in-file (`bg-white px-3 pt-3.5 pb-2.5 border-b border-border`) instead of using `TopBar`. Result: it loses the SafeArea `insets.top + 6` padding that `TopBar.tsx:46` adds, so on iPhone notch devices the avatar overlaps the status bar.
- **WHERE.** `mobile/src/features/chat/components/ConversationScreen.tsx:251-284`. See `11-chat-conversation.png` — note the header height differs from every other screen.
- **WHY.** The product has exactly one navigation pattern; chat being the exception makes the app feel like two apps stitched together. Status-bar overlap is a functional bug on real devices.
- **HOW.** Extend `TopBar` to accept a `subtitle` and a `leading` element large enough for an avatar (currently it only renders text leading). Replace the inline header with `<TopBar back leading={<AvatarCircle … size={32} />} title={peer.name} subtitle={'@'+peer.handle} actions={[{ icon: <Bell/>, ... }]} />`.

![chat conversation](./.audit-screenshots/11-chat-conversation.png)

### P0-3. `Alert.alert` used for destructive confirmations & action menus — looks like 2012 iOS
- **WHAT.** Sign-out, account delete, profile-discard, message edit/delete, profile-toggle errors, and "Forgot password?" all open a native `Alert.alert(...)`. On web this is `window.alert/confirm` — chrome-blue, modal-blocking, unbranded. On iOS it's the gray sheet that doesn't match the navy/gold language anywhere else in the app.
- **WHERE.** `mobile/app/(app)/settings/index.tsx:92-107` (Sign out), `mobile/src/features/settings/components/AccountSection.tsx:55-83` (Delete), `mobile/src/features/profile/components/ProfileEditForm.tsx:119-132` (Discard), `mobile/src/features/profile/components/ProfileView.tsx:40-43` (Share copied), `mobile/src/features/chat/components/MessageBubble.tsx:75-106` (Edit/Delete actionsheet), `mobile/src/features/auth/components/SignInForm.tsx:72-74` (Forgot pwd), `mobile/src/features/privacy/components/PrivacyTogglesSection.tsx:59-61` (Toggle error). 12+ call sites total.
- **WHY.** Destructive flows are exactly where brand consistency matters most — the system Alert is the user's last cue before they delete data. A branded confirm dialog reinforces trust ("yes, this is the real app, this is a real consequence").
- **HOW.** Build `<ConfirmDialog>` on top of `BottomSheet` (already exists). API: `confirm({ title, body, confirmLabel, destructive, onConfirm })`. Drop it behind a small `useConfirm()` hook so call sites stay one-liner. Replace `Alert.alert` toast-style notices (`shareCopiedTitle`, `exportReady`) with a new `<Toast>` primitive (see "Suggested net-new components").

### P0-4. Two parallel "screen header" patterns produce visually different titles
- **WHAT.** Some screens use `<TopBar title=…>` with `font-display-bold text-[16px]` on a white bar + 6px-of-inset top padding. Others render their own `<Text className="text-body text-2xl font-semibold">` floating on the bg with `pt-16 px-6`. They look completely different.
- **WHERE.** TopBar pattern: home (`HomeScreen.tsx:54`), opportunities (`opportunities.tsx:16`), inbox (`InboxScreen.tsx:81`), settings detail screens (via `Stack.Screen options.title`). Inline pattern: chats (`ChatsListScreen.tsx:44-46`, see `05-chats.png`), network (`network.tsx:10-12`, see `03-network.png`), onboarding (`StepperLayout.tsx:44`), profile edit (`ProfileEditForm.tsx:240`).
- **WHY.** Compare `04-opportunities.png` (proper TopBar with bordered chrome) against `05-chats.png` (huge bold title floating on gray). Both are tabs — they should be twins.
- **HOW.** Pick one (TopBar is the more enterprise look) and migrate the 4 outliers. Add a `<ScreenHeader title=… subtitle=… size="lg|md">` primitive if you want the larger title for "marketing" screens like onboarding — but every tab + every settings detail should use the same chrome.

![chats with inline header](./.audit-screenshots/05-chats.png) ![opportunities with TopBar](./.audit-screenshots/04-opportunities.png)

### P0-5. Every list loading state is a single spinner — no skeleton, jarring on slow networks
- **WHAT.** `QueryState.tsx:30-39` renders a single `<ActivityIndicator>` in the middle of an empty `py-12` block for every loading case. There is no `<Skeleton>` primitive in `components/ui/`. Chats, inbox, opportunities, network, daily-matches strip, profile, settings, intros — every one flashes blank-then-spinner-then-content.
- **WHERE.** `mobile/src/components/ui/QueryState.tsx:30-39`; every consumer of `<QueryState>` inherits this.
- **WHY.** The defining "feels like a real product" detail. Skeletons are a 5-line component and they communicate "we know where the data goes" — spinners say "we have no idea yet."
- **HOW.** Add `<Skeleton>` (animated `bg-slate-100` block) and `<SkeletonUserCard>`, `<SkeletonOpportunityCard>`, `<SkeletonListRow>`, `<SkeletonProfile>` composites. Pass a `skeletonCount={5}` prop to `QueryState`, OR let callers pass `loadingFallback={<SkeletonOpportunityCard.List count={4} />}`. Wire the top 5 lists first (chats, inbox, opportunities feed, daily matches, network).

---

## P1 — High-impact polish (visible to every user)

### P1-1. Typography scale leaks raw px everywhere — no canonical sizes
- **WHAT.** Inline sizes in className strings: `text-[10px]`, `text-[11px]`, `text-[12px]`, `text-[13px]`, `text-[14px]`, `text-[16px]`, `text-[18px]`, `text-[20px]`, `text-[28px]`, `text-[32px]` AND legacy Tailwind tokens `text-xs`, `text-sm`, `text-base`, `text-lg`, `text-2xl` — both used simultaneously. The same "name" text shows up at `text-[13px]` (UserCard:51), `text-[14px]` (ConversationScreen:267, ComposeIntroSheet:121), `text-[16px]` (EmptyInbox:15), `font-semibold` size-unset (ChatsListScreen:45, ConversationListRow:59, IntroListRow:34).
- **WHERE.** ~80 files. See Grep output: every `src/features/**/*.tsx` has inline sizes.
- **WHY.** With ~14 distinct sizes in use, the visual rhythm is incoherent. Auditing in screenshots, the home title is `text-[16px]`, the chats title is `text-2xl`, the onboarding step title is `text-2xl`, the profile-edit title is `text-2xl`, the opportunity-detail title is `text-[20px]`. Same hierarchy level, four different sizes.
- **HOW.** Add a typography scale to `global.css` under `@theme`. Concrete proposal:
  ```css
  --text-display-xl:   28px;  /* hero wordmark only */
  --text-display-lg:   20px;  /* screen titles on marketing/onboarding */
  --text-display-md:   16px;  /* TopBar title, section card titles */
  --text-display-sm:   13px;  /* card titles, body emphasis */
  --text-display-xs:   11px;  /* pill, badge, label */
  --text-body-lg:      14px;  /* primary body / chat bubble */
  --text-body-md:      12px;  /* secondary body, descriptions */
  --text-body-sm:      11px;  /* metadata, captions */
  --text-body-xs:      10px;  /* uppercase eyebrows, fineprint */
  --text-mono-md:      12px;  /* handles in some flows */
  ```
  Then ban `text-[NNpx]` in new code via an ESLint rule. Migration is mechanical — start with `UserCard`, `Button`, `Pill`, `Input`, `TopBar`, `SettingsRow` (most-reused primitives).

### P1-2. Spacing scale is inconsistent — `mx-3`, `mx-4`, `mx-6`, `px-3.5`, `px-4`, `px-6` used arbitrarily
- **WHAT.** No canonical horizontal gutter. Examples of the same "screen horizontal padding" decision:
  - `ChatsListScreen.tsx:44` uses `pt-16 px-6`
  - `NetworkScreen` (`network.tsx:10`) uses `px-6 pt-16`
  - `HomeScreen` daily matches strip uses `px-3` (`DailyMatchesStrip.tsx:49`)
  - `OpportunityCard` uses `mx-3` (`OpportunityCard.tsx:48`)
  - `ConversationListRow` uses `mx-6` (`ConversationListRow.tsx:54`)
  - Section cards in `ProfileView.tsx:19` use `mx-3`
- **WHERE.** Pervasive. Most visible side-by-side in `01-home.png` (cards at `mx-3`) vs `05-chats.png` (row at `mx-6`).
- **WHY.** Compare daily-match cards (extending almost to the edge) with chat rows (deep indented). Looks like two different designers shipped different screens.
- **HOW.** Canonical scale: screen gutter = `px-4` (16px), card inset = `p-3` or `p-4`, sub-cards within a section = `p-3`. Add to `tailwind.config` / `@theme`:
  ```
  --spacing-gutter: 16px;   /* outer screen padding */
  --spacing-card-pad: 12px;  /* default card inner */
  --spacing-card-lg: 16px;   /* roomy cards (profile, opportunity detail) */
  ```
  Use `mx-gutter`/`p-card-pad`. Migrate `ChatsListScreen`, `NetworkScreen`, `OpportunityCard`, `ConversationListRow`, `IntroListRow`, `ProfileView` first.

### P1-3. Avatar "halo" double-ring is bespoke geometry, leaks raw colors, and is heavy
- **WHAT.** `AvatarCircle.tsx:40-95` builds a 3-View nested structure with hard-coded paddings (`padding: 1`, `padding: 2`) and inline `backgroundColor: haloOuter` (which is `colors.gold` or `colors.goldPale`). It then computes `(size + 6) / 2` and `(size + 4) / 2` for two rings. Every avatar on screen pays this cost.
- **WHERE.** `mobile/src/components/ui/AvatarCircle.tsx`. Used everywhere.
- **WHY.** (a) The halo is gold even for non-featured contexts, which fights the "calm" intent — it's visible in `01-home.png` on every card, drawing the eye away from the name/headline. (b) Inline `backgroundColor` bypasses NativeWind, so changing the brand palette won't update avatars without a code edit. (c) The featured-vs-default distinction is subtle (`goldPale` vs `gold`) and gets lost on small avatars.
- **HOW.** Default halo should be `colors.border` (neutral). Reserve gold halo for `featured` only. Replace the two `View` wrappers with a single `View` that uses `borderWidth: 2 + (featured ? 1 : 0)` and `borderColor` from tokens. Keep the structure but drive everything from `@theme` tokens via NativeWind classes (`border-2 border-border` for default, `border-2 border-gold` for featured).

### P1-4. ProfileHero gradient + tinted text → poor contrast for handle, headline, location
- **WHAT.** `ProfileHero.tsx:33` renders a navy → navy-light gradient with a gold radial overlay; text on it is `text-gold-light` (handle, headline) and `text-white/80` (location). Gold-light (`#ffe187`) on navy-light (`#1a4a80`) measures **3.4:1**, below WCAG AA's 4.5:1 for body text. The headline goes to `numberOfLines={2}` and is the user's pitch — it must read clearly.
- **WHERE.** `mobile/src/features/profile/components/ProfileHero.tsx:80,85,101`. Visible in `06-profile.png` and `14-public-profile.png`.
- **WHY.** Profile is a flagship surface — investor will see other users' profiles dozens of times a day. Sub-AA contrast on the headline is a real accessibility blocker and looks "design-ier than functional."
- **HOW.** Use `text-white` for the handle and headline; demote the gold accent to the verified-pill / brand-pill chips only. Drop the gold radial overlay (it adds noise without adding info), or restrict its opacity to ~0.12.

![profile gradient with gold-light text](./.audit-screenshots/06-profile.png)

### P1-5. Empty states are inconsistent and mostly text-only
- **WHAT.** Every list rolls its own empty:
  - Chats: plain centered text "No conversations yet. Accept an intro to start chatting." (`ChatsListScreen.tsx:53-55`)
  - Network/Connections: plain centered `{t('connections.empty')}` (`ConnectionsList.tsx:17`)
  - Opportunities: centered text + a navy button (`OpportunityFeed.tsx:41-55`)
  - Discoverable feed: plain text "We're picky for you…" (`DiscoverableFeed.tsx:53-55`)
  - Inbox: only one with branded treatment (`EmptyInbox.tsx`) — gold-pale circle + ✉ glyph + CTA
  - QueryState fallback: muted `<Banner variant="muted">Nothing here yet</Banner>` (`QueryState.tsx:69-72`)
- **WHERE.** See above + `02-inbox.png` (good treatment), `05-chats.png` (text only), `03-network.png` (text only).
- **WHY.** Empty states are the first impression for new users. They should sell the product, not apologize for the lack of data.
- **HOW.** Build `<EmptyState icon={Icon} title body actionLabel onAction>` primitive (see "Suggested net-new components"). Adopt across all 5 lists.

### P1-6. ProfileView and OtherProfileView have duplicated `Section` component — drift waiting to happen
- **WHAT.** `ProfileView.tsx:17-26` and `OtherProfileView.tsx:37-47` define the **same** local `Section` component, with the same `mx-3 mt-2.5 rounded-xl border border-border p-3.5` classes and the same `font-display-bold text-[10px] text-muted uppercase tracking-wide mb-1.5` eyebrow.
- **WHERE.** Both files. Plus `PublicProfileView.tsx:32-37` reimplements it inline a third time.
- **WHY.** Inevitable drift — one developer will tweak one, miss the other two. Also blocks adoption of a real spacing/typography scale because there's no central place to fix it.
- **HOW.** Promote to `~/components/ui/SectionCard.tsx`. API: `<SectionCard title="HEADLINE" testID="…">…</SectionCard>`. Replace 6 call sites.

### P1-7. "Sign out" button placement is duplicated and inconsistent
- **WHAT.** Sign out appears in two places: in `ProfileView.tsx:174-181` as a full-width outline button at the bottom of the profile, AND in `settings/index.tsx:88-111` as an `outline-danger` button at the bottom of settings, AND in the profile.tsx (settings page directly accessed) page shows red outline (see `07-settings.png`).
- **WHERE.** `mobile/src/features/profile/components/ProfileView.tsx:174-181`, `mobile/app/(app)/settings/index.tsx:88-111`.
- **WHY.** Two locations, two visual treatments (outline vs outline-danger), one with Alert.alert confirm, one without. Confusing — and the profile-bottom placement is unusual; settings is the conventional place.
- **HOW.** Keep sign-out in Settings only. Remove from ProfileView. Standardize to `outline-danger` everywhere; never trigger sign-out without the confirm dialog.

### P1-8. Buttons can't tell "primary on dark surface" from "primary on light surface"
- **WHAT.** On the public profile (`14-public-profile.png`), a navy-bg panel wraps a gold `Button variant="gold"`. On the gradient hero of the auth screen (`21-sign-in.png`), the white card holds a navy `Button variant="primary"`. There's no `variant="gold-on-dark"` vs `variant="primary-on-light"` convention — devs have to remember which color works on which surface.
- **WHERE.** `mobile/src/components/ui/Button.tsx:28-46`. Usage: `OtherProfileView.tsx:273-281` (the `bg-navy mx-3 mt-4 mb-8 p-3.5 rounded-xl` wrapper is a bespoke "lift the button onto navy" hack).
- **WHY.** That `bg-navy mx-3 mt-4 mb-8 p-3.5 rounded-xl` wrapper around the `Send Intro` button is a workaround for the missing "primary CTA in dark context" pattern. It produces the awkward heavy navy band visible in `14-public-profile.png`.
- **HOW.** Don't add more variants; instead, **remove** the navy wrapper entirely. A gold button reads fine on a white surface (see `14-public-profile.png` — the only reason it's on navy is to "emphasize"). Float the Send Intro CTA as a sticky bottom button with `<View className="px-4 py-3 border-t border-border bg-white"><Button variant="primary">…</Button></View>`. Same pattern can apply to "Express interest" on opportunity detail — both are bottom-of-screen primary actions.

### P1-9. Bottom-tab unread badges visually conflict with the tab labels
- **WHAT.** The chat-unread badge is a `bg-danger-border` circle anchored `-top-1 -right-3` of the emoji icon (`(tabs)/_layout.tsx:74-86`). Combined with the emoji icons and the label below, the tab gets visually crowded. The danger-red doesn't match anything else in the navy/gold palette.
- **WHERE.** `mobile/app/(app)/(tabs)/_layout.tsx:74-86`. Currently not visible in screenshots (no unread), but the code path is wrong.
- **HOW.** After fixing P0-1 (real icons), use the brand gold for the dot (`bg-gold` with `text-navy` numerals) so the badge is brand-coherent. Or omit the count entirely and use a 6px dot (`<View className="absolute -top-0.5 -right-0.5 w-1.5 h-1.5 rounded-full bg-gold" />`) — Apple's preferred minimalist style.

### P1-10. Goal chips on home (`text-[12px]` "Hire" pill row) wrap into 2 cramped rows and run off-screen
- **WHAT.** Goal filters scroll horizontally but `FeedFilterBar.tsx` renders both "Role" and "Goal" rows; on a 390px viewport, the goal row truncates without an obvious affordance — see `01-home.png` where "Take investment" is partially clipped on the right.
- **WHERE.** `mobile/src/features/discovery/components/FeedFilterBar.tsx:67-84`. Visible in `01-home.png`.
- **WHY.** Discoverability — a user can't tell there are more filters off-screen.
- **HOW.** Add a fading right-edge mask (`<LinearGradient colors={['transparent', surface]} style={{ position: 'absolute', right: 0, top: 0, bottom: 0, width: 24 }} />`) over the ScrollView so the truncation reads as "scroll for more". Or drop the static row entirely in favor of a single `<Pressable className="self-start">+ Filters</Pressable>` that opens a BottomSheet — gives more room for the actual feed.

### P1-11. The "Sign out" red-outline button under Settings looks alarming and wastes space
- **WHAT.** `outline-danger` variant on the bottom Sign-out button is full-width with a thick red border (see `07-settings.png`). It's the visually dominant thing on the screen — but signing out is a frequent, non-destructive action.
- **WHERE.** `mobile/app/(app)/settings/index.tsx:88-111`.
- **WHY.** Color tax. Red is for irreversible actions (account delete). Sign out is reversible; use `outline` (navy) and let "Delete account" inside the Account screen carry the danger styling.
- **HOW.** Switch `outline-danger` → `outline` on the Settings sign-out button. Keep `Delete account` in `AccountSection.tsx` as `variant="danger"` (it already is).

### P1-12. Inputs lack focus state on web
- **WHAT.** `Input.tsx:82` uses `border-[1.5px] border-border` — no `focus:` modifier. NativeWind v5 supports focus selectors on web targets, but the primitive doesn't opt in.
- **WHERE.** `mobile/src/components/ui/Input.tsx:82`. Plus the bare `TextInput` in `OpportunityFilterBar.tsx:43-53`, `OpportunityComposer.tsx` (uses Input — inherits), `MessageComposer.tsx:74-92` (bare).
- **WHY.** On the web build (which the dev team uses every day), tabbing through forms shows no focus ring. On mobile, no visual hint that an input is active.
- **HOW.** Add `focus:border-navy focus:ring-2 focus:ring-gold-pale` (NativeWind v5 supports `focus:` on web). For native, use `onFocus`/`onBlur` to swap a `focused` boolean and conditionally set `border-navy` instead of `border-border`.

### P1-13. Public/own profile share copies `bvisionryconnect://` deeplink — meaningless when shared via clipboard
- **WHAT.** `ProfileView.tsx:41` copies `bvisionryconnect://p/${handle}` to clipboard. The recipient won't have the app installed (it's a marketing surface) and won't know what the scheme is.
- **WHERE.** `mobile/src/features/profile/components/ProfileView.tsx:40-43`.
- **WHY.** Share is one of the most viral surfaces in a network product. Pasting `bvisionryconnect://p/asaad` into LinkedIn or email is useless.
- **HOW.** Copy a web URL (e.g. `https://connect.bvisionry.com/p/asaad`) that 1) renders the public profile in a browser AND 2) deep-links to the native app if installed (universal/app links). Add a tiny banner "Link copied" via the new Toast primitive instead of Alert.alert.

### P1-14. Discoverable feed cards have no `pressed:` state — taps feel unresponsive on web
- **WHAT.** `UserCard.tsx` wraps a `<Card>` which renders `<Pressable>` but without a `pressed:` opacity/bg modifier. Tapping a card on web shows zero visual feedback before the route change.
- **WHERE.** `mobile/src/components/ui/Card.tsx:17-21`, `mobile/src/components/ui/UserCard.tsx:46`, `OpportunityCard.tsx:43-49`, `ConversationListRow.tsx:51`, `IntroListRow.tsx:22-25`.
- **WHY.** "Did my tap register?" is the most basic responsiveness signal.
- **HOW.** In `Card.tsx`, use `<Pressable>` with `({pressed}) => …` and conditionally apply `bg-slate-100` or `opacity-90` on press. Native RN `Pressable` does this with style functions; NativeWind v5 also supports `active:` modifier.

### P1-15. Form keyboard handling missing in opportunity composer & profile edit
- **WHAT.** Neither screen wraps its `ScrollView` in `KeyboardAvoidingView`. On iOS, the keyboard covers the bottom Save/Next button when editing the bio (multiline 4-line input) or the body (multiline 6-line input).
- **WHERE.** `mobile/src/features/opportunities/components/OpportunityComposer.tsx:155-326`, `mobile/src/features/profile/components/ProfileEditForm.tsx:237-512`.
- **WHY.** Functional bug on real iPhones — user can't see the button they're trying to tap.
- **HOW.** Wrap each `ScrollView` in `<KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1 }}>` like `ConversationScreen.tsx:244` already does.

### P1-16. Daily-matches strip uses raw inline pill (not the Pill primitive) for `reason`
- **WHAT.** `UserCard.tsx:75-81` renders a bespoke `View` for the match reason — `px-1.5 py-1 rounded-md` with conditional bg gold or gold-pale — instead of using `<Pill variant="default">` or `<Pill variant="solid">`.
- **WHERE.** `mobile/src/components/ui/UserCard.tsx:75-81`.
- **WHY.** Pills are the established chip primitive. Using a custom rectangle for the most prominent label on a featured card (visible in `01-home.png`, the "New on Connect" yellow rectangle) makes the visual language feel hand-rolled.
- **HOW.** Replace with `<Pill variant={variant === 'featured' ? 'solid' : 'default'}>{reason}</Pill>`. Pill already does the right rounded-full shape — the rectangular reason chip is the design outlier.

---

## P2 — Medium (worth doing before public launch)

### P2-1. No global toast/snackbar system
- **WHAT.** Successes & info messages today rely on either inline `<Banner>` (sometimes set via `useState`, then never auto-dismissed: `OtherProfileView.tsx:91,250-252`) or `Alert.alert` (P0-3) or local error text. There's no consistent "thing happened, here's a 3-second confirmation" surface.
- **WHERE.** `OtherProfileView.tsx:91,250`, `IntroDetailView.tsx:62,168-171`, `OfficeHoursSettingsForm.tsx:76-81,229-235`, `ProfileView.tsx:42` (Alert.alert).
- **HOW.** Add `<ToastProvider>` at the root, expose `useToast()` returning `{ show(message, kind?), success, error, info }`. Replace the inline state-toggled banners.

### P2-2. Onboarding back button is a `<Text>` "‹" — same primitive as TopBar but rebuilt
- **WHAT.** `StepperLayout.tsx:38-42` builds its own back affordance: `<Pressable…><Text className="text-muted">‹ {t('onboarding.back')}</Text></Pressable>`. TopBar has the same affordance built-in. Onboarding doesn't use TopBar at all.
- **WHERE.** `mobile/src/features/onboarding/components/StepperLayout.tsx:31-50`.
- **HOW.** Adopt `<TopBar back title=… />` for onboarding steps too. The big "What's your goal?" title can become the body content `<Text>` if the marketing intent is "make the step title huge."

### P2-3. Settings notification table doesn't fit at 390px
- **WHAT.** `NotificationPrefsSection.tsx:22-64` renders a 4-column table (label + push + email + in-app). Each toggle column is `w-16` (64px). 64 × 3 = 192, plus the label column (`flex-1`) plus padding — overflows on narrow widths and the toggles get crammed.
- **WHERE.** `mobile/src/features/settings/components/NotificationPrefsSection.tsx`. See `16-notifications.png`.
- **WHY.** Toggles overlap with the labels at 320px viewport; right edge of the in-app column nearly touches the screen edge at 390.
- **HOW.** Rebuild as one row per (kind, channel): expand each row into 3 toggle rows with the channel as a small label on each. Or: keep the table but use icons for the channel headers (smaller) and use `w-12` columns.

### P2-4. ProfileEditForm uses `pt-16` instead of TopBar
- **WHAT.** `ProfileEditForm.tsx:239` opens with `<View className="px-6 pt-16 pb-8"><Text…text-2xl>Edit profile</Text>` — bypassing TopBar and losing the standard back chevron, the SafeArea inset, and the consistent title size.
- **WHERE.** `mobile/src/features/profile/components/ProfileEditForm.tsx:237-242`.
- **HOW.** Mirror Opportunity composer (`OpportunityComposer.tsx:157`): `<TopBar back title={t('profile.edit.title')} />`. Keep the form in a `ScrollView` below it.

### P2-5. Voice/image composer buttons are tiny (`w-7 h-7`) — below 44pt touch target
- **WHAT.** `MessageComposer.tsx:50-72` renders 28×28pt buttons for propose-meeting (+), camera, and voice. Apple HIG and WCAG say 44pt minimum. Send button is also `w-7 h-7`.
- **WHERE.** `mobile/src/features/chat/components/MessageComposer.tsx:50-108`.
- **HOW.** Wrap each `Pressable` in `hitSlop={{ top: 12, bottom: 12, left: 8, right: 8 }}` (the visual chip can stay 28pt), OR bump to `w-9 h-9` (36) and visually balance with input padding.

### P2-6. Opportunity detail "Hiring" pill changes color per kind — gets unreadable for some
- **WHAT.** `KIND_VARIANT` in `OpportunityCard.tsx:15-24` and `OpportunityDetailView.tsx:17-26` maps each kind to a Pill variant: hiring→navy, seeking_role→solid (gold), fundraising→success(green), investing→default(gold pale), cofounder→warning(amber), advising→outline(navy outline), seeking_advisor→muted(slate), collaboration→default.
- **WHERE.** Both files. Visible in `13-opportunity-detail.png` (Hiring=navy, Remote only=green).
- **WHY.** Mixing brand colors (navy/gold) with semantic colors (success/warning) for non-semantic distinctions is muddled. A user can't intuit that "success-green = fundraising"; they're learning a private color code with 8 entries.
- **HOW.** Use a single neutral chip for kind (`<Pill variant="navy">` or `<Pill variant="outline">`) plus an optional icon. Keep semantic chips (success/warning) for actual status (remote-only, closed). Color the chip by the kind only when it carries semantic load (e.g., "closed" muted; otherwise navy).

### P2-7. Long-press to edit/delete a message is undiscoverable
- **WHAT.** `MessageBubble.tsx:222-244` uses `onLongPress` to open an `Alert.alert` with Edit/Delete options. No hint to the user — and the resulting Alert is unbranded (P0-3).
- **WHERE.** `mobile/src/features/chat/components/MessageBubble.tsx:75-106,222-244`.
- **HOW.** Add a small `⋯` button (one of the icons from P0-1) that's visible on a sender's own bubble; tap opens a branded bottom-sheet menu. Keeps long-press as a secondary discovery path.

### P2-8. Office hours form weekly availability lacks a "copy to weekdays" affordance
- **WHAT.** `OfficeHoursSettingsForm` shows one row per day with an "+ Add window" button (see `15-office-hours.png`). To set the same 9-10am window M-F, the user adds 5 separate windows.
- **WHERE.** `mobile/src/features/office-hours/components/WeeklyAvailabilityEditor.tsx` (and parent form).
- **HOW.** Add a "Copy Monday to weekdays" / "Copy to all days" link per day row. Common pattern in Calendly/Google Calendar.

### P2-9. Profile share button + Edit button placed in a right-aligned row, no clear hierarchy
- **WHAT.** `ProfileView.tsx:84-103` renders Share and Edit as twin outline buttons in a `flex-row justify-end`. Neither is the primary action; both look identical.
- **WHERE.** `mobile/src/features/profile/components/ProfileView.tsx:84-103`. See `06-profile.png`.
- **HOW.** Move both into the TopBar as icon actions (pencil + share icon), reclaim the body space for content.

### P2-10. Bio is `font-body` (Overlock_400Regular) which is a casual handwriting-style font — fights enterprise tone
- **WHAT.** Profile bios and opportunity bodies are rendered in `Overlock_400Regular` (`global.css:60`), a quirky casual sans-serif with rounded terminals. Compare to the `Dosis_700Bold` display font — they're an awkward pairing.
- **WHERE.** `mobile/global.css:60`.
- **WHY.** Looks like a craft-brewery menu, not a professional networking product. The pairing is "trying too hard."
- **HOW.** Swap `font-body` to `Inter_400Regular` (already on npm, well-supported, free) and `Inter_600SemiBold`. Pair with `Dosis_700Bold` for display sparingly, or move display to `Inter_700Bold` as well for one cohesive family. This is a single-line `@theme` change + an `expo-font` registration.

### P2-11. Meeting card timezone formatting wraps awkwardly
- **WHAT.** `MeetingCard.tsx:73-83` formats slots as `${proposerLocal}\n(${yourTimeLabel}: ${yourLocal})`. The `\n` in a `<Text>` is a real newline — depending on locale, slots can wrap to 3+ lines per slot.
- **WHERE.** Visible in `11-chat-conversation.png` (single-line because same TZ) — but worst case is asymmetric TZs.
- **HOW.** Wrap the second clause in a smaller `<Text className="text-[11px] text-muted">` rendered below the primary line. Use two Text children inside a `View` instead of `\n` in a single Text.

### P2-12. "Send intro" is the only place the gold button variant is used in flows
- **WHAT.** Gold button (`variant="gold"`) is used for `Send intro` on `OtherProfileView.tsx:276`. Every other CTA in the app is `primary` (navy). Visual reward is fine but the asymmetry is confusing — why is this one button special?
- **WHERE.** `mobile/src/features/profile/components/OtherProfileView.tsx:273-282`.
- **HOW.** Either (a) use gold for **all** terminal/conversion CTAs (Send intro, Send message, Confirm meeting, Book slot, Submit opportunity) so it reads as "primary action" — OR (b) reserve gold for hero moments only and demote `Send intro` to navy `primary`. Pick one and apply consistently.

### P2-13. Cards-on-cards: OpportunityCard contains a UserCard
- **WHAT.** `OpportunityCard.tsx:94-105` mounts a `<UserCard>` inside its own card frame. Result: nested borders, double padding, and the user card looks orphaned. See `04-opportunities.png` where the E2E Tester block has its own border inside the parent card.
- **WHERE.** `mobile/src/features/opportunities/components/OpportunityCard.tsx:94-105`, mirrored in `OpportunityDetailView.tsx:93-106`.
- **HOW.** Render the author as a borderless row inside the opportunity card: `<View className="flex-row items-center gap-2 mt-3 pt-3 border-t border-slate-100"><AvatarCircle…size={32} /><View><Text>…name</Text><Text>@handle · role</Text></View></View>`. Keep `UserCard` for top-level feed contexts where it has its own surface.

### P2-14. Onboarding doesn't show progress percentages or step labels
- **WHAT.** `ProgressDots.tsx` renders 4 thin bars with no numeric label, no step name; the dot UI alone doesn't tell the user "step 2 of 4: Identity".
- **WHERE.** `mobile/src/components/ui/ProgressDots.tsx`, used by `StepperLayout.tsx:32-36`.
- **HOW.** Add a small `<Text className="text-body-xs text-muted mb-2">Step {current+1} of {total} · {stepName}</Text>` above the dots. Pass `stepName` through StepperLayout.

### P2-15. Bottom-sheet handle is the only dismissal hint; backdrop tap works but isn't obvious
- **WHAT.** `Modal.tsx:50` shows a 9×1pt drag handle. No close button. Tapping the dimmed area dismisses, but there's no affordance for that.
- **WHERE.** `mobile/src/components/ui/Modal.tsx:32-54`.
- **HOW.** Add an optional top-right `<Pressable onPress={onClose}><Icon name="x" /></Pressable>` in the sheet content area. Or include a "Done"/"Close" button in the BottomSheet itself when `dismissible`.

### P2-16. No animation on tab switch — feels static
- **WHAT.** Tab switches snap instantly; chat list → conversation has no transition; intro accept doesn't have a success state animation.
- **WHERE.** Pervasive. Expo Router supports `presentation: 'modal'` and built-in stack transitions.
- **HOW.** Stack already animates. For tab switches, native bottom-tabs cross-fades by default — verify it's enabled and tweak `screenOptions={{ animation: 'fade' }}`. For intro accept, add a Lottie checkmark or a 200ms scale-bounce on the badge.

---

## P3 — Nice-to-have (post-launch refinement)

### P3-1. Hero "BVisionRY Connect" wordmark mixes `font-display-bold` and `font-display-medium` — inconsistent weight inside one word
- **WHERE.** `AuthShell.tsx:30-34`. Visible in `21-sign-in.png`.
- **HOW.** Settle on one weight for the wordmark — `bold` reads more solid.

### P3-2. Banner doesn't expose a `closeable` action; ad-hoc dismissals reimplement the X
- **WHERE.** `PhotoNudgeBanner.tsx:48-56` adds its own X button.
- **HOW.** Add `onDismiss?: () => void` prop to `<Banner>`.

### P3-3. Send-message button uses `→` text glyph for arrow — kerning + font-family mismatch
- **WHERE.** `MessageComposer.tsx:106`.
- **HOW.** Replace with `<Send size={14} color={colors.white} />` after icon library is in.

### P3-4. Stepper progress bar fills with gold for completed steps, navy for current — inverted from convention
- **WHERE.** `ProgressDots.tsx:14`. Most progress bars use the brand primary for filled and a lighter shade for the active step. Currently gold = past, navy = current.
- **HOW.** Use navy for past, gold for current (active highlight), border for pending.

### P3-5. The "OR" divider in auth uses raw `<View className="flex-1 h-px bg-border" />` — could be a `Divider` primitive
- **WHERE.** `SignInForm.tsx:85-89`, repeated in `SignUpForm.tsx`.
- **HOW.** `<Divider label="OR" />` primitive.

### P3-6. "What's your goal?" onboarding step uses `text-body text-2xl font-display-bold` — the only `text-2xl` text on otherwise-13px screens
- **WHERE.** `StepperLayout.tsx:44`, `GoalStep.tsx` mockup. Visible in `20-onboarding-goal.png`.
- **HOW.** Use `text-display-lg` from the new typography scale (P1-1).

### P3-7. Verified badge is a `Pill` with a checkmark string `✓` — sits awkwardly next to the name
- **WHERE.** `UserCard.tsx:55`. The success-green chip on a small name line is visually loud.
- **HOW.** After icons are in (P0-1), render a tiny `BadgeCheck` icon in gold next to the name; drop the green pill.

### P3-8. Office-hours form inputs for "max bookings per week" are text inputs filtered via regex — should be steppers
- **WHERE.** `OfficeHoursSettingsForm.tsx:164-183`.
- **HOW.** `<Stepper min={1} max={50} step={1} value={state.maxBookingsPerWeek} onChange={…} />` primitive.

### P3-9. Profile bio uses `BioMarkdown` — fine — but the headline above it is `font-body text-[13px]` and renders the same as a normal sentence. The visual hierarchy between headline-as-tagline and bio-as-paragraph is too subtle.
- **WHERE.** `ProfileView.tsx:111-116`, `OtherProfileView.tsx:188-194`.
- **HOW.** Render the headline as `text-display-md italic text-body` (or just keep it `display-sm` larger than the bio).

### P3-10. Pressable feedback on settings rows: none. Tapping doesn't highlight before nav.
- **WHERE.** `SettingsRow.tsx:38-76`.
- **HOW.** Add `active:bg-slate-100` to the rendered className.

---

## Design system gaps

A consolidated list of what's missing or inconsistent at the primitive layer.

### Typography
- **No scale.** Inline sizes (`text-[10px]` through `text-[32px]`) and legacy tokens (`text-xs`/`text-sm`/`text-2xl`) coexist. Recommend the scale in P1-1.
- **Two weight conventions.** `font-display-bold` / `font-display-semibold` / `font-display-medium` AND `font-semibold` (Tailwind default) used interchangeably. Pick one.
- **Body font is too casual** for the brand intent (P2-10).

### Spacing
- **No screen-gutter token.** `px-3` vs `px-4` vs `px-6` chosen arbitrarily (P1-2).
- **Card padding varies.** `p-3` (Card.tsx), `p-3.5` (SettingsRow), `p-4` (some bespoke), `px-3.5 py-3` (settings row). Standardize on `p-3` (cards) and `p-4` (section cards).
- **Vertical rhythm between sections.** `mt-2.5`, `mt-3`, `mt-4`, `mb-2`, `my-2` all in use. Pick a 4/8/12/16 rhythm and stick to it.

### Color tokens
- **Tokens are well-defined** in `global.css` (`--color-*`) and mirrored in `theme/colors.ts`. Good.
- **But raw hex literals leak in** wherever NativeWind classes don't reach — `ActivityIndicator color="#0f3460"` appears in 8 files (should be `color={colors.navy}` which already exists), `placeholderTextColor="#94a3b8"` in MessageComposer (should be `colors.muted`), gradient color tuples in ProfileHero `['#0f3460', '#1a4a80']` (should reference colors). Easy lint rule: forbid `#[0-9a-f]{3,6}` in `.tsx` outside `theme/` and `global.css`.
- **Missing semantic tokens** for "primary action surface", "elevated card", "subtle background". Today devs reach for `bg-white` (primary surface) or `bg-surface` (page bg) — works but undocumented.

### Component variants
- **Button** — 7 variants cover most cases (primary, gold, outline, outline-danger, danger, disabled, apple). Missing: `ghost` (text-only, used for "Forgot password?", "Don't have an account?"), `link` (inline within text). Both currently rendered as raw `<Pressable><Text className="text-navy underline">…`.
- **Button** — no `size="lg"` for hero CTAs (sign-in, complete onboarding).
- **Pill** — 8 variants, but the brand vs semantic split is encoded in two places (BRAND_STYLES + SEMANTIC_VARIANT_TO_INTENT, `Pill.tsx:24-36`). Works but suggests this should be `variant + intent` (two props) rather than one merged enum.
- **Input** — no `prefix`/`suffix` slot (would help for `@` handle prefix, search-icon, etc.); no `focus:` state (P1-12); no `loading` state (would help for handle-availability check).
- **Card** — only `default`/`featured`. No `interactive` (hover/press), `compact`, or `outlined-only`.
- **Modal/BottomSheet** — only one (BottomSheet). No alert/confirm dialog, no full-screen modal, no inline tooltip/popover. P0-3 calls this out.

### Touch targets
- **Composer buttons** at 28pt fail 44pt minimum (P2-5).
- **TopBar back chevron** is `<Text>` with hitSlop 8 — total tap area ~36pt. Borderline.
- **Pill chips** (used as filter selectors throughout) are `px-2 py-0.5` — visual height ~20pt. They're tapped frequently. Increase to `px-3 py-1.5` for selectable contexts.

---

## Suggested net-new components

| Primitive | Rough API | Why |
|---|---|---|
| `<EmptyState>` | `{ icon: ReactNode; title: string; body?: string; action?: { label: string; onPress: () => void } }` | Replaces the 5 bespoke empty-state implementations (P1-5). |
| `<Skeleton>` + composites | `<Skeleton w={…} h={…} radius={…} />`; `<SkeletonUserCard count={4} />` | Eliminates the spinner-only loading state (P0-5). |
| `<ScreenHeader>` | `{ title: string; subtitle?: string; back?: boolean; actions?: Action[]; size?: 'lg' \| 'md' }` | Unifies the 4 parallel header patterns (P0-4). Could be a TopBar extension. |
| `<SectionCard>` | `{ title?: string; testID?: string; children: ReactNode }` | Extracted from 3 duplicated `Section` components in profile views (P1-6). |
| `<ConfirmDialog>` + `useConfirm()` | `confirm({ title, body, confirmLabel, destructive, onConfirm })` | Replaces `Alert.alert` for destructive flows (P0-3). |
| `<Toast>` + `useToast()` | `toast.success(msg)`, `toast.error(msg)`, `toast.info(msg)` | Replaces Alert.alert for non-destructive notifications and the inline-banner-with-setState pattern (P2-1). |
| `<Divider>` | `{ label?: string; orientation?: 'horizontal' \| 'vertical' }` | The OR divider in auth + section dividers elsewhere (P3-5). |
| `<IconButton>` | `{ icon: IconComponent; onPress; label: string; size?: 'sm' \| 'md' \| 'lg'; variant?: 'plain' \| 'subtle' }` | Standardizes the ad-hoc Pressable+icon pattern used for back chevrons, composer +/📷/voice, profile actions menu, banner dismiss X. |
| `<Stepper>` (numeric) | `{ value; onChange; min; max; step }` | Office hours numeric inputs (P3-8); could be reused for any quota/count setting. |
| `<Avatar>` (rename from `<AvatarCircle>`) | Same API but with `tone="default" \| "featured" \| "muted"` and cleaner ring logic (P1-3). | One avatar primitive, no halo geometry math. |
| `<SegmentedControl>` | `{ options: {value, label}[]; value; onChange }` | The InboxTabs (Received/Sent), OpportunityComposer kind picker, OfficeHours slot duration picker, and the segmented Language picker in account settings all reinvent this. |
| `<FilterChip>` | `{ active; onPress; label; icon? }` | The Pill-as-filter-with-pressable pattern is used in FeedFilterBar, OpportunityFilterBar, ProfileEditForm role chips. Currently each call site wraps a `<Pressable>` around a `<Pill>`. |

---

## Per-screen notes

### Sign-in (`21-sign-in.png`, `mobile/src/features/auth/components/SignInForm.tsx`)
- Apple button is `bg-black` — fine on iOS, but on Android it should be the official "Continue with Google" white-on-stroke pattern; currently both are full-bleed which looks DIY.
- "Forgot password?" opens an Alert.alert with a generic body — should route to a real flow or at least show a more helpful response.
- The double-CTA (Sign in + Send magic link) is brave — works but visually dominant. Consider hiding the magic-link CTA behind a "More options" link to reduce decision fatigue.
- Wordmark mixes `font-display-bold` and `font-display-medium` within one word (P3-1).

### Sign-up (`22-sign-up.png`)
- Same issues as sign-in.
- "8+ characters" hint is plain `text-muted` — should be a real password-strength meter, or at minimum live-validate length as the user types.

### Home (`01-home.png`)
- `ThinPoolBanner` "We're being picky for you. Only 2 strong matches…" copy is gentle but verbose; users will see it daily. Tighten to "2 strong picks today — quality over quantity."
- Goal filter chips clip off-screen with no scroll affordance (P1-10).
- Daily-match cards use the bespoke "reason" pill that doesn't match the Pill primitive (P1-16).
- The avatar in the top-right TopBar action goes to profile — needs a hover/press treatment on web.

### Inbox (`02-inbox.png`)
- Empty-state IS branded (gold-pale circle + ✉ glyph) — this is the right model for the other empty states.
- Tab indicator (gold underline on selected) is good. Tab labels are `text-[13px] font-display-bold` — consistent.
- Connected pill on the row stands out (good) but reads navy-on-navy at small text — verify contrast.

### Network (`03-network.png`)
- Title is `text-2xl font-semibold` — different from every other tab title (P0-4).
- ConnectionsList row is bare-bones (avatar + name + handle, no last-message preview, no shared context). Compare to ChatList row — it should at least show what brought them into the network (intro vs office hours vs meeting).
- Tapping a row jumps to `/chats/{conversationId}` — surprising; the user expected a profile view. Either label the screen "Conversations" or make the row click open the profile and add an explicit "Message" affordance.

### Opportunities (`04-opportunities.png`)
- TopBar title is right; filter bar is dense but reasonable.
- "Post opportunity" button is a full-width primary at the top of the feed — fine on the empty state, but on a populated feed it pushes feed content down. Consider a sticky bottom CTA, or move to a `+` icon in the TopBar actions (after P0-1).
- Cards have nested-card-in-card (the author UserCard sits inside the OpportunityCard) — P2-13.
- The "Hiring" pill is navy-solid; "Remote only" is success-green. Per P2-6 these compete for attention without semantic justification.

### Chats list (`05-chats.png`)
- Inline `text-2xl font-semibold` title — P0-4.
- Row has avatar + name + handle + preview but no timestamp; users with active inboxes need "2m" / "yesterday".
- No search affordance — a future "search conversations" pattern is missing.

### Chat conversation (`11-chat-conversation.png`)
- Bespoke header — P0-2.
- Composer button trio (+/📷/voice) is 28pt — P2-5; emoji glyphs — P0-1.
- "Meeting confirmed" cards use a bordered-white card with a small label, while the "Couldn't generate prep" yellow warning sits between two confirmed-meeting cards with no clear scope — is it for the upcoming meeting or the historical one? Add an icon and a less ambiguous title.
- The send arrow `→` is a Unicode glyph; cuts off / shifts depending on font fallback.

### Intro detail (`12-intro-detail.png`)
- Sparse — most of the screen is white space. The accept/decline CTA (which is what the user came here for) is hidden because the intro is already in "connected" state. Add a "Open chat with User B" CTA + recap of what was agreed.
- "USER B SAYS" eyebrow is muted; OK.

### Opportunity detail (`13-opportunity-detail.png`)
- Decent. Title is `text-[20px]` (good emphasis). Tags as `#muted` pills are fine.
- "Express interest" is the only CTA — should be sticky to the bottom of the viewport, not inline scrolled.
- No "more from this author" / "similar opportunities" — but this is a P3 content-discovery concern.

### Public profile (`14-public-profile.png`)
- Send Intro button awkwardly wrapped in a navy panel (P1-8).
- Bio section is empty for this user (the seeded user only has a headline). Other-profile section cards (HEADLINE / BIO / GOAL / ROLES / LOCATION / VERIFICATION) are six rectangles stacked vertically — could merge into two columns on tablet widths (`md:grid-cols-2`).
- Gradient hero text contrast issue (P1-4).

### Profile own (`06-profile.png`)
- Same hero contrast (P1-4).
- Edit + Share buttons are right-aligned outlines (P2-9).
- Six cards stacked vertically — same density issue as public profile.
- The "Founder" role chip on the navy hero is gold-pill on navy — that one IS readable. Good.

### Profile edit (`08-profile-edit.png`)
- No TopBar (P2-4); the large "Edit profile" floating title is out of place.
- Long form, multiple multiline inputs (Bio 4-line, Goal 3-line) without KeyboardAvoidingView (P1-15).
- Goal type uses a custom Pressable trigger that opens a BottomSheet to pick from 8 chips — works, but the chevron `›` is a text character (P0-1).

### Opportunity new (`09-opportunity-new.png`)
- Step 1: list of 8 rectangular Pressable rows. Each is a `border-[1.5px]` rectangle with a single label. Visually heavy. Could be a 2-column grid of icon-tiles for faster scanning.
- "STEP 1 OF 3" eyebrow is muted gray — works.
- The form is a 3-step wizard with `<Next>`/`<Back>` at the bottom — good pattern; the back button only renders from step 2 onward — good UX.

### Settings (`07-settings.png`)
- Row chevrons are `›` text glyphs (P0-1).
- "Sign out" red-outline button is alarming (P1-11) AND duplicated in ProfileView (P1-7).

### Account settings (`10-settings-account.png`)
- Language picker uses two segmented buttons (English / Español) — works, but is reimplemented inline; could be a `<SegmentedControl>`.
- Toggles for Analytics/Crash reports are plain-text + Switch rows — consistent with other settings.
- "Delete account" is red-filled (`variant="danger"`) — visually too aggressive for a setting screen even though the action is destructive. Move under an "Advanced" disclosure or at the very bottom with a more neutral chrome until confirmed.

### Notifications (`16-notifications.png`)
- Table is too wide for 390px viewport; columns crowd (P2-3).
- Header row eyebrow uppercase tracking is consistent with other section labels.

### Office hours (`15-office-hours.png`)
- "Enable" toggle card is good.
- Slot duration uses a 4-button segmented control — good visual; the navy-bg-active state is the convention for "selected".
- Weekly availability requires per-day "+ Add window" — no copy-to-weekdays (P2-8).

### Onboarding (`20-onboarding-goal.png`)
- Title is `text-2xl` — needs to land in the new scale (P3-6).
- Goal type uses gold-pale pills, not the standard Pill variants — works but a third style of pill in the codebase.
- No SafeArea inset; the `pt-16` is a magic number for "below the status bar".

---

_End of audit._

