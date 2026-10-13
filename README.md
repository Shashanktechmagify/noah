# Noah — Flutter frontend

Mobile app for **Karuna Sadan Ministries**: one account for the congregation —
events and passes, the daily reading, sermons, a social feed (Noahgram), and a
matchmaking space (Jodie).

> **Status: frontend only.** There is no backend yet. Every screen runs on demo
> data held in memory, and all payments are simulated. The places where the
> backend plugs in are listed in [Connecting the backend](#connecting-the-backend).

---

## Contents

- [Features](#features)
- [Getting started](#getting-started)
- [Project structure](#project-structure)
- [How it works](#how-it-works)
- [Languages and translation](#languages-and-translation)
- [Connecting the backend](#connecting-the-backend)
- [Testing](#testing)
- [Assets and branding](#assets-and-branding)
- [Known limitations](#known-limitations)
- [Roadmap](#roadmap)

---

## Features

### Onboarding
| Screen | What it does |
|---|---|
| **Splash** | Gradient background, Noah logo, animated dots, then fades to login. |
| **Login** | `+91` mobile number with live `XXXXX XXXXX` formatting; needs 10 digits. |
| **OTP** | 4-box code entry, 24 s resend timer, change number. Demo code: **4821**. |

### Main app (bottom navigation)
The nav bar has a purple circle that **slides to whichever tab is selected**.

| Tab | Description |
|---|---|
| **Home** | Auto-scrolling banner carousel (5 slides, loops forever, pauses while dragged), today's reading, category chips, feature tiles. |
| **Noahgram** | Instagram-style social space — see below. |
| **Noahtube** | Search, category filter chips, live card, Shorts row, latest videos. |
| **Events** | Booked pass (ticket with notches and dashed tear line), events open for booking (tap *Book* to toggle), bus routes. |
| **Jodie** | Matchmaking — see below. |
| **Me** | Profile, basic info, **language switcher**, settings, sign out. |

### Noahgram
- **Feed** with stories row, double-tap to like, comments sheet, share sheet, save.
- **Stories** full-screen with progress bars, auto-advance, tap left/right, swipe down to close.
- **Explore** with search (filters people and captions) and a grid of all posts.
- **Reels** — vertical full-screen pager with like / comment / share / follow.
- **Profile** — stats, bio, highlights, Grid / Reels / Saved tabs, edit profile, follow other people.
- **Create post** — pick a "look" and a caption; it appears in the feed and your grid.
- Your Noahgram profile and the **Me** page share the same user data.

### Jodie (matchmaking)
- **Discover** — swipe stack: right = like, left = pass, up = Super Like (costs credits). Buttons for each, plus Boost.
- **Suggestions** — only the opposite gender is shown, ranked by a **compatibility score** built from registration data (congregation, city, languages, interests, age). The profile screen explains *why* you match.
- **Likes** — people who liked you; blurred until **Premium** or spent credits.
- **Matches** — new matches and conversations.
- **Chat** — requires a **Premium subscription** (1 / 3 / 6 months).
- **Credits** — daily reward with a 7-day streak, earn-by-tasks, buy packs, spend on Super Like / Boost / revealing likes.
- **Payments** — a clearly marked demo checkout stands in for **Razorpay**.

---

## Getting started

### Requirements
- Flutter **3.47+** (Dart SDK `^3.13.5`)
- Android Studio / VS Code with the Flutter plugin
- An emulator or device

### Run

```bash
flutter pub get
flutter run
```

### Checks

```bash
flutter analyze
flutter test
```

### Regenerate the launcher icon
The icon comes from `assets/images/noah.png` (configured in `pubspec.yaml`).

```bash
dart run flutter_launcher_icons
```

> **Windows:** if you add a package that uses native plugins (for example
> `razorpay_flutter` or `shared_preferences`), enable **Developer Mode**
> (`start ms-settings:developers`) so Flutter can create symlinks. The project
> currently has no plugin dependencies, so it builds without it.

---

## Project structure

```
lib/
├── main.dart                     App entry, language provider
├── theme/app_theme.dart          Colours, gradients, ThemeData
├── l10n/app_strings.dart         All UI text in 6 languages + tr() helper
├── data/
│   ├── noahgram_data.dart        Demo users, posts, reels + NoahgramState
│   └── jodie_data.dart           Demo profiles, compatibility, credits,
│                                 premium, chat + JodieState
├── widgets/
│   ├── auth_scaffold.dart        Purple header + white sheet (login/OTP)
│   ├── event_carousel.dart       Auto-scrolling banner cards
│   ├── hex_pattern.dart          Honeycomb header pattern
│   └── page_scaffold.dart        Tab page header, cards, pills
└── screens/
    ├── splash_screen.dart · login_screen.dart · otp_screen.dart
    ├── main_shell.dart           Bottom nav with sliding circle
    ├── home_screen.dart · events_screen.dart
    ├── noahtube_screen.dart · me_screen.dart
    ├── noahgram/                 feed, stories, reels, explore, profile, sheets
    └── jodie/                    discover, likes, matches, chat, profile,
                                  payment / premium / credits sheets
assets/
├── images/noah.png               App logo + launcher icon source
└── fonts/PlusJakartaSans.ttf     Bundled font
test/widget_test.dart             End-to-end widget tests
```

---

## How it works

### State
There is no state-management package. Two small `ChangeNotifier` singletons own
the social data, and screens listen with `ListenableBuilder`:

| Object | File | Owns |
|---|---|---|
| `noahgram` | `data/noahgram_data.dart` | people, posts, reels, follows, saved, stories seen, *your profile* |
| `jodie` | `data/jodie_data.dart` | profiles, likes, matches, chat, credits, streak, premium, filters |

Screens never build demo data themselves — they call methods such as
`noahgram.toggleLike(post)` or `jodie.like(profile)`. **Replacing these methods
with API calls is the main job when the backend arrives.**

### Compatibility score (Jodie)
`jodie.compat(profile)` starts at 45 and adds points for the same congregation
(+15), same city (+10), shared languages (up to +16), shared interests (up to
+15) and age gap ≤ 4 years (+10). The result is clamped to 50–99 and the
matching reasons are returned for display.

### Credits and pricing
All numbers are constants at the top of `data/jodie_data.dart`:

| What | Value |
|---|---|
| Premium plans | 1 month ₹199 · 3 months ₹499 · 6 months ₹799 (with 10 / 40 / 100 bonus credits) |
| Credit packs | 50 → ₹49 · 150 → ₹129 · 500 → ₹349 |
| Costs | Super Like 5 · Boost 20 · Reveal a like 10 |
| Daily rewards | 5, 5, 10, 10, 15, 15, 30 (7-day cycle) |
| Task rewards | Complete profile 20 · Invite 30 · Verify with Aadhaar 25 |

---

## Languages and translation

The Me tab switches the **whole app** between **English, Hindi (हिन्दी),
Marathi (मराठी), Kannada (ಕನ್ನಡ), Malayalam (മലയാളം) and Telugu (తెలుగు)**.

- All fixed UI text lives in `lib/l10n/app_strings.dart` as
  `'key': [en, hi, mr, kn, ml, te]`.
- Use `tr(context, 'key')` in widgets. Placeholders: `tr(context, 'sent_to', args: {'phone': '98765 43210'})` fills `{phone}`.
- Missing translations fall back to English, then to the key itself.
- Proper names (Noah, Noahgram, Noahtube, Jodie, Karuna Sadan) stay in English.
- Use `spacing(context, value)` for `letterSpacing` — spacing breaks conjuncts in Indic scripts, so it is applied for English only.

**Translations were written without a native-speaker review. Have each language
checked before release.**

### Dynamic content (events, sermons, posts, …)
`app_strings.dart` only covers text that is fixed in the app. Content that comes
from the server must be translated on the server:

1. Store each language with the content, or accept `?lang=hi` / `Accept-Language`.
2. Translate **once when content is published** (e.g. Bhashini, Google or Azure
   Translate), let staff correct it, and store the result.
3. The app only displays what it receives, falling back to English.
4. User-written content (posts, comments) is *not* auto-translated; offer a
   "Translate" button that asks the backend and caches the result.
5. Scripture must come from a licensed Bible version in each language — never machine-translated.

---

## Connecting the backend

Everything below currently uses demo data or a simulation.

| Area | Where | Needs |
|---|---|---|
| Login / OTP | `login_screen.dart`, `otp_screen.dart` | Send OTP, verify, session token. The demo accepts code `4821`. |
| Registration data | — | Collect gender, age, city, congregation, languages, interests; this drives Jodie suggestions. |
| Home / Events / Noahtube | `home_screen.dart`, `event_carousel.dart`, `events_screen.dart`, `noahtube_screen.dart` | Replace the hard-coded lists with API data (including localised text). |
| Noahgram | `noahgram_data.dart` | Posts, stories, reels, follows, comments; media upload (the demo uses coloured placeholders instead of images). |
| Jodie | `jodie_data.dart` | Profiles/suggestions, likes, matches, real-time chat. |
| **Payments (Razorpay)** | `showPaymentSheet` in `screens/jodie/jodie_widgets.dart` | See below. |
| Persistence | — | Language choice and session are not saved yet (needs `shared_preferences` or secure storage). |

### Razorpay flow to implement
1. App asks the backend to **create an order** (amount, plan or credit pack, user).
2. App opens Razorpay Checkout with the returned order id (`razorpay_flutter`).
3. On success, app sends `payment_id`, `order_id` and `signature` to the backend.
4. Backend **verifies the signature**, then grants Premium or credits.
5. `showPaymentSheet` returns `true` only after the backend confirms.

> **Security:** Premium status, credit balances, Super Like / Boost spending and
> chat access **must be enforced on the server.** The checks in the app are for
> display only and can be bypassed.

---

## Testing

`test/widget_test.dart` contains three end-to-end widget tests:

1. **Onboarding → app → language** — splash, login, OTP, carousel auto-scroll,
   sliding nav, Noahtube, Events, switching the app to Hindi.
2. **Noahgram** — like, comment, reels, edit profile, and the new name showing on Me.
3. **Jodie** — match, paywall, demo payment, chat with auto-reply, daily reward.

The tests load the bundled font so text is laid out with real metrics (otherwise
Flutter falls back to a much wider test font and reports false overflows).

---

## Assets and branding

- **Logo / launcher icon:** `assets/images/noah.png` — update the file and run
  `dart run flutter_launcher_icons`.
- **App name** under the icon is set in `android/app/src/main/AndroidManifest.xml`
  and `ios/Runner/Info.plist`.
- **Font:** Plus Jakarta Sans (variable), bundled so no network is needed.
- **iOS:** the icon has transparency, which the App Store rejects. Before an
  App Store release add `remove_alpha_ios: true` to `flutter_launcher_icons` in `pubspec.yaml`.

---

## Known limitations

- No backend, authentication or persistence — everything resets on restart.
- Posts, reels, stories and profile "photos" are coloured placeholders.
- Payments are simulated; no money moves.
- Jodie chat replies are scripted demo replies.
- Noahgram direct messages, comment replies and comment likes are not built.
- "Aadhaar verification" and "Invite a friend" only mark the credit task as done.
- Translations need native review.

---

## Roadmap

- [ ] Backend integration (auth, content, Noahgram, Jodie, chat)
- [ ] Razorpay checkout and server-side verification
- [ ] Registration flow capturing the data used for Jodie suggestions
- [ ] Real image/video upload and playback
- [ ] Push notifications
- [ ] Persist language and session
- [ ] Giving, Polls and Sermons screens (tiles exist on Home)
- [ ] Moderation tools for Jodie and Noahgram (reporting, blocking, review queue)
