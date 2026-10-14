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
| **Login** | A **language dropdown** at the top; tapping it opens a "Choose your language" popup (all six languages), **country-code dropdown** (India +91 default, plus US, UK, UAE, Singapore, Australia), number formatting and validation per country. Demo: India `+91 98765 43210` is an existing member; any other number is a new member and goes through registration after the OTP. |
| **My information** (Me tab) | Every member detail in sections: personal, contact, address, correspondence address and other details (blood group, IDs, height, diet and more). Missing required details are flagged amber ("Please fill this in") with a banner on the Me page; optional ones say "Not added · tap to add". Tap a row to edit (date picker, choice list or validated text). Registration data is copied in after approval. Code: `lib/data/profile_data.dart`, `lib/screens/me/profile_info_screen.dart`. |
| **Registration** | Six steps for new members (purple theme): details, address, ID proof, photo, declaration with typed signature, video KYC (10–30 s read-aloud). Then a "Registration successful" status page with a success popup, office contact and **prototype controls** (*Simulate: admin approves* → Home, *admin returns the video* → back to step 6). ID proof and photo are **real uploads** (JPG/PNG/PDF up to 5 MB via file_picker/image_picker, camera on phones), and every field is validated (Aadhaar 12 digits, PAN, passport, driving licence, voter ID formats, PIN, email, age 18+). The video KYC is a real front-camera recording (camera + video_player), played back before submitting and from the status page; with no camera it falls back to a timer demo. Country, state and city come from every country in the world (bundled `assets/data/world.json`, searchable pickers, only the chosen country's states and cities are listed). The declaration can be read in English, Hindi or Marathi. After *admin approves*, a popup shows the registered number. The whole page scrolls with the keyboard open. Building with these plugins needs Windows Developer Mode. Code in `lib/screens/registration/`, state in `lib/data/registration_data.dart`. |
| **OTP** | 4-box code entry, 24 s resend timer, change number. Demo code: **4821**. Shows the number with its country code. |

### Main app (bottom navigation)
The nav bar is **Home · Menu · Noahgram · Events · Jodie · Me** (Noahgram uses an Instagram-style glyph), with a purple circle that **slides to whichever tab is selected**.

| Tab | Description |
|---|---|
| **Home** | Announcement carousel (loops, pauses while dragged; the cards **lift on hover / shrink on press** and open Events), **Today's Daily Manna** (*View all* → last four Mannas), tabs **Prayers / Confessions / Bible commentary** with gradient tiles and a dashed *View all* tile that opens *Daily prayers*, *Words of Faith* (by theme, Save / PDF) or *Commentary*, and a **Prayer request** card that opens the request popup (category chips, details, *Who should pray?* radio: Prayer warriors by default / Everyone). Demo content in `lib/data/word_data.dart`. |
| **Menu** | Opens a bottom popup with a searchable **icon grid** (My Information, Notifications, eBooks, Chat, Donations, Podcast, Daily Manna, Bible School, Live Video, Events, Praises, **Noahtube**, Bible Study, David's Shields, My Gallery, Daily Prayer, Dream Dictionary, Daily Confessions, **Prayer Request**, Testimonials, TV Listing, Bible Commentary, Prayer Wall, Obituaries). Items with a screen open it; the rest say *Coming soon*. The circle stays on Menu while Noahtube is open. Add or remove items in `kMenuItems` (`screens/menu_sheet.dart`) and handle them in `_openMenu` (`screens/main_shell.dart`). |
| **Noahgram** | Instagram-style social space — see below. |
| **Events** | Search by name, place or date; **My passes** carousel (swipe through ticket cards with seats, passes, gate and booking code); *Open for booking* list where tapping **Book** creates a new pass; Bus; and a **Book by date** calendar (dots on days with events, tap a day to see and book its events). Dates are generated relative to today. |
| **Jodie** | Matchmaking — see below. Opens on a **membership page** (₹300, once) until the member joins. |
| **Me** | Name, *member since · place · cell*; pastor (**Chat with pastor**), cell leader, family; **Your record**, **More** and **Settings** rows that open the inside pages below. The bottom bar stays visible on those pages. |

### Me tab inside pages
| Page | What it has |
|---|---|
| **Family** | Household card, linked members (verified / minor), family passes. *Add* is not built. |
| **Location** | Current location and a list to change it (with confirmation); events, passes, transport and giving follow it. |
| **Profile photo** | In-review status, rules, **upload** (demo: adds a review entry), review history (approved / returned). |
| **Identity & consent** | Three one-time steps with a progress bar: Aadhaar (already verified in the demo), **consent** (agree / read), **verification video** (demo: records 18 s). |
| **Everything** | Opens the Menu popup. |
| **Messages** | Pastor, cell leader and church office chats, with unread counts. |
| **Drive** | Folders and recent files; *Get* shows a demo toast. |
| **Store** | Category chips, products, cart bar and **Checkout** through the demo payment. |
| **Rewards** | Earnings from Noahgram activity (likes, comments, posts), **Withdraw** (minimum ₹50, one pending at a time) and payout history. |
| **Language** | All six languages, current one marked. |
| **Notifications**, **Terms and privacy** | Empty-state illustration + earlier items; community / data / giving terms (legal text to be supplied). |

Camera, photo picking and file downloads need plugins, so those actions are demo stand-ins marked in the code.

### Prayer requests
Opened from **Menu → Prayer Request**, or from a Daily Manna reading (then it is tied to that Manna). The popup has a category, the details, and two switches:
- **Share with everyone** — ON: visible to the whole congregation. OFF (default): visible to the **prayer warriors only**.
- **Share anonymously**.

The backend must enforce the audience: `everyone == false` is only visible to the prayer-warriors group.

### Noahgram
- **Feed** with stories row, double-tap to like, comments sheet, share sheet, save.
- **Stories** full-screen with progress bars, auto-advance, tap left/right, swipe down to close.
- **Explore** with search (filters people and captions) and a grid of all posts.
- **Reels** — vertical full-screen pager with like / comment / share / follow.
- **Profile** — stats, bio, highlights, Grid / Reels / Saved tabs, edit profile, follow other people.
- **Create post** — pick a "look" and a caption; it appears in the feed and your grid.
- Your Noahgram profile and the **Me** page share the same user data.

### Jodie (matchmaking)
- **Membership:** a one-time **₹300** (`kJodieMembershipRupees`) unlocks Jodie. Until then the tab shows the landing page (four-stage verification, number stays private, one sign-in, ₹300 once). *Become a member* goes through the demo payment, then opens the profile sheet.
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
│   ├── jodie_data.dart           Demo profiles, compatibility, credits,
│   │                             premium, chat + JodieState
│   ├── manna_data.dart           Daily Manna readings (demo)
│   ├── events_data.dart          Events, passes and booking (relative to today)
│   ├── ministry_data.dart        Pastor, cell leader, office + chats (Me tab)
│   ├── me_data.dart              Location, identity steps, photo, store, rewards
│   └── prayer_data.dart          Prayer requests (demo store)
├── widgets/
│   ├── auth_scaffold.dart        Purple header + white sheet (login/OTP)
│   ├── event_carousel.dart       Auto-scrolling banner cards
│   ├── hex_pattern.dart          Honeycomb header pattern
│   └── page_scaffold.dart        Tab page header, cards, pills
└── screens/
    ├── splash_screen.dart · login_screen.dart · otp_screen.dart
    ├── main_shell.dart           Bottom nav with sliding circle
    ├── home_screen.dart · events_screen.dart
    ├── noahtube_screen.dart · me_screen.dart · manna_screen.dart · menu_sheet.dart
    ├── me/                       Family, Location, Profile photo, Identity, Drive,
    │                             Store, Rewards, Language, Notifications, Terms,
    │                             Messages + ministry chat
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

### Navigation
The Events and Me tabs each have their own `Navigator` (`widgets/tab_navigator.dart`), so pages opened from them keep the bottom bar visible. Pages can reach the shell through `ShellScope` (open the Menu, jump to a tab by nav slot).

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
