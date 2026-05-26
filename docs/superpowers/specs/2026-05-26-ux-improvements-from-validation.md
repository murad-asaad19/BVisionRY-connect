# UX improvements surfaced during manual validation

**Date:** 2026-05-26
**Source:** End-to-end walks of the Flutter app on emulator.

Running list of UX gaps I'm spotting as I exercise real flows. Each entry
captures the missing/poor behavior and a concrete proposal.

---

## Opportunities → Author awareness

### 1. No badge / indicator that someone expressed interest on your post

**Today.** When User B expresses interest in your opportunity, the only
surface that reflects it is the author's *detail* screen ("1 interested"
button). The Opportunities tab icon, the kebab menu, and the My
Opportunities list row carry no notification dot or count badge.

**Why it matters.** Posting an opportunity is high-intent. The author
needs an at-a-glance signal that someone responded — without diving into
"My opportunities" to scan each row.

**Proposed.**
- Add an *unread interest* counter on the Opportunities bottom-tab icon
  (gold dot with number, same pattern as the Chats "2" badge).
- On the **My opportunities** list, surface a small "*N new*" pill next
  to each row that has interests the author hasn't viewed yet. Clear
  it on InterestedListScreen visit.
- Wire via a new `unread_interest_counts` RPC keyed on
  `last_viewed_at` per `(author, opportunity)`.

### 2. No direct "Connect" path after expressed interest

**Today.** On `InterestedListScreen`, tapping a user routes only to their
public profile. From there the author must manually tap **Send intro**,
which opens the regular intro composer with no opportunity context.

**Why it matters.** The author and interested user just had a meaningful
matching event — there's strong signal both sides want to engage. The
current flow buries the next step.

**Proposed.**
- Add inline action buttons on each `_InterestedRow`:
  - **Send intro** (gold solid) — opens the existing intro sheet
    pre-filled with a reference like *"about your interest in '{title}'"*.
  - **Open chat** (outline) — if a conversation already exists between
    these two users, navigate to it; else, defer to the intro path.
- After a connection forms, replace the buttons with a *"Connected"*
  status pill so the row keeps tracking the relationship state.
- Optionally: mark the interest row as *engaged* once the author taps
  any CTA, so a follow-up "Reported by you / Engaged with" view can
  show conversion.

---

## Opportunities → State refresh after close

### 3. Close-opportunity does not refresh the detail screen

**Today.** Author taps the kebab → Close opportunity → confirm sheet →
Close. DB row flips to `status='closed'`, `closed_at` set. But the
detail screen the author is sitting on does *not* repaint — the
"Closed" muted pill the design specifies for `isClosed` cards never
appears, and the kebab still shows the Close option (`detail.withAuthor.opportunity.status == OpportunityStatus.open` is now false, so re-entry hides it, but the current view is stale).

**Why it matters.** Closing is a one-way intentional action. Without
visual confirmation the user wonders whether the tap registered.

**Proposed.**
- After `closeOpportunity` resolves, call `ref.invalidate(opportunityProvider(id))` *and* `await ref.read(...future)` so the next frame
  is fresh.
- Or, simpler: pop back to the My Opportunities list after a successful
  close, where the status overlay pill is already supported by
  `OpportunityCard(statusOverlay: true)`.

---

## Navigation → Own profile entry point

### 4. No entry point to own Profile from any tab

**Today.** After moving Settings off the Home top-bar (improvement #4 in
the prior PR), the **only** way to reach `/profile` is via deep-link.
The 5-tab nav (Home/Inbox/Network/Opportunities/Chats) has no Profile
slot, and no other surface carries a "you" affordance. This is a real
regression I introduced.

**Why it matters.** Users can't view their own profile, can't reach
settings (which moved under Profile), can't sign out, can't edit
headline / bio / goal — all entry points dead.

**Proposed (fixing now).**
- Add the viewer's [Avatar] as a `leading` slot on the **Home** top-bar.
  Tapping it pushes `/profile`. Cheap, on-pattern (Twitter, LinkedIn,
  Telegram all do this), and the avatar doubles as a glanceable "logged
  in as X" indicator.

---

## (Continue adding observations as validation walks more flows)
