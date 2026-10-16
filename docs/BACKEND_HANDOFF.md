# Noah — backend hand-off

The Flutter app is complete on the front end and runs on **demo data held in
memory**. This file lists every place the backend must plug in, so a backend
developer can build the API without reading the UI code.

- Screens never build data themselves. They call small state objects
  (`noahgram`, `jodie`, `meState`, `ministry`, `eventsState`, `prayer`) that live in `lib/data/`.
- **To connect the backend, replace the seed data and the action methods in those
  files with API calls.** The screens need no change.
- All user-visible text is in `lib/l10n/app_strings.dart` (6 languages). Content
  from the server must arrive **already translated** (see [Languages](#languages)).

---

## 1. Rules the server must enforce

The app only *displays* these. Anyone can bypass the app, so the server decides.

| Rule | Why |
|---|---|
| Jodie membership (₹300, once) | Gate every Jodie endpoint on a verified payment. |
| Jodie chat subscription and credit balance | Spending credits (Super Like 5, Boost 20, Reveal 10) and chat access are checked server-side. |
| Prayer request audience | `everyone == false` is visible to the prayer-warriors group **only**. |
| Withdrawals | Minimum ₹50, one pending at a time, paid by the finance office. |
| Consent and identity records | Store the consent version, timestamp and signed copy on the server. |
| Moderation | Posts, comments, prayer requests and praise reports are approved by moderators before they appear (see Terms page). |
| Data residency | Terms promise the record is held in India. |

## 2. Authentication

| Screen | Needs |
|---|---|
| Login (`login_screen.dart`) | Send OTP to `+<country><number>`. Countries offered: IN +91, US +1, UK +44, UAE +971, SG +65, AU +61. |
| OTP (`otp_screen.dart`) | Verify code; return a session token and whether the member **exists** (go to Home) or is **new** (go to registration). The demo accepts `4821` and always goes to Home. |
| Registration | **Not built yet.** Must collect the data that drives Jodie suggestions: gender, age, city, congregation, languages, interests. |
| Log out | Invalidate the session (the app returns to Login via the root navigator). |

## 3. Data by feature

Suggested resources, in the order of the bottom bar. Field names match the demo models.

### Home
| Data | Source in app | Notes |
|---|---|---|
| Banner slides | `widgets/event_carousel.dart` | id, label, title, body, cta, icon, colours. Localised. |
| Daily Manna | `data/manna_data.dart` | `id, title, ref, minutes, daysAgo, verse, reflection, prayer`. Scripture must come from a **licensed Bible per language**, never machine-translated. |
| Prayer request (`data/prayer_data.dart`) | `prayer.add(...)` | `category, text, anonymous, everyone, mannaId?`. |

### Menu
`screens/menu_sheet.dart` lists 25 destinations. Only Noahtube, Daily Manna,
Prayer Request, Events and My Information open a screen today; the rest show *Coming soon*.

### Noahtube
Videos (`id, title, category, minutes, views, thumbnail, url`), live stream, shorts. Currently coloured placeholders.

### Noahgram (`data/noahgram_data.dart`)
| Action | Method to replace |
|---|---|
| Feed, stories, reels | `posts`, `reels`, `storyFrames()` |
| Like / save / comment | `toggleLike`, `toggleSave`, `addComment` |
| Follow | `toggleFollow` |
| Create post | `addPost(look, caption)` → needs **media upload** |
| Edit profile | `updateProfile(name, bio)` |

`Post: id, author, media, caption, likes, createdAt, isReel, comments[]`.
Posts and comments are **user-written**: do not auto-translate; offer a per-post translate action.

### Events (`data/events_data.dart`)
| Data | Notes |
|---|---|
| Events | `id, title, place, start, endsOn?, seatsLeft?, special, soon`. Dates are generated relative to today in the demo. |
| My passes | `event, seats, passes, gate, code, bookedOn`. Newest first = "Latest". |
| Book | `eventsState.book(event)` → create a pass, decrement seats, return seats/gate/code. |
| Search | Done client-side on title, place and date; move server-side when the list grows. |
| Bus routes | Static text today. |

### Jodie (`data/jodie_data.dart`)
| Data / action | Method |
|---|---|
| Profiles + suggestions | `deck` — opposite gender, age filter, **ranked by compatibility** |
| Compatibility | `compat(profile)`: same congregation +15, same city +10, shared languages up to +16, shared interests up to +15, age gap ≤ 4 years +10 (score clamped 50–99; reasons returned for display) |
| Swipe | `like`, `pass`; a like on someone who already liked you returns a **match** |
| Likes you | `likesYou`; visible with Premium or after `reveal` (10 credits) |
| Credits | `credits, streak, claimDaily()` (rewards 5,5,10,10,15,15,30), tasks `profile 20 / invite 30 / verify 25` |
| Membership | `isMember`, `join()`; fee `kJodieMembershipRupees = 300` |
| Premium | `kPlans`: 1 month ₹199 (+10 credits), 3 months ₹499 (+40), 6 months ₹799 (+100) |
| Credit packs | `kCreditPacks`: 50 → ₹49, 150 → ₹129, 500 → ₹349 |
| Chat | `sendMessage` → needs real-time delivery (the demo auto-replies after 2 s) |

### Me tab (`data/me_data.dart`, `data/ministry_data.dart`)
| Page | Data | Actions |
|---|---|---|
| Header + card | member since, place, cell, pastor, cell leader, family count | — |
| Messages / chat | contacts (pastor, cell leader, office), messages, unread | `ministry.send`, `markRead` |
| Family | household members: name, relation, since / guardian, minor, verified | add member |
| Location | list `name, group, members`; current | `setLocation` |
| Profile photo | history `title, date, status (review/approved/returned), by` | `uploadPhoto` → image upload + review queue |
| Identity & consent | Aadhaar status + last 4, consent `version, at`, video `seconds, status` | `agreeConsent`, `submitVideo` → camera upload |
| Drive | folders `name, items, size`; files `name, size, date` | signed download links |
| Store | products `id, name, category, rupees`; cart | `addToCart`; checkout → order + payment |
| Rewards | counts (likes, comments, posts), rates, payouts `amount, date, batch, paid` | `withdraw()` |
| Notifications | list `type, text, createdAt` | mark read |
| Terms | version + three sections; full legal text | — |

Rewards rates in the demo: 0.5 paise per like, 2 per comment, 3 per post (set by the ministry).

### Registration (`data/registration_data.dart`, `screens/registration/`)
After OTP verify the client needs to know whether the number is an **existing member** (go to Home), a **new member** (registration), or **registered but awaiting approval** (status page). Return that from the OTP-verify endpoint.

New-member data to persist: name parts, email, gender, date of birth, marital status, reference person; address (lines, city, country, 6-digit PIN); ID type + number + **ID image upload**; **profile photo upload**; declaration acceptance with typed signature and signing timestamp (store the declaration text version too); **video KYC upload** (10–30 s, read-aloud script containing name/place/date). Validate everything server-side, including that the signature matches the full name and the video length.

The video KYC is recorded on the device (front camera, 10–30 s, mp4) and must be uploaded; the app plays back the local file. Country/state/city values come from a bundled dataset (`assets/data/world.json`); the server should validate against its own list. The declaration is shown in English, Hindi and Marathi: store which language was displayed with the acceptance.

Step 1 also collects salutation (Mr, Mrs, Ms, Miss, Dr, Rev, Ps), nationality (a country) and, when marital status is *married*, a mandatory anniversary date (after the member turned 18, not in the future). The declaration text is the ministry's *Form of Declaration* in English, Hindi and Marathi, filled with the member's name, age and place; store the language shown and the signing time.

Video length: the member reads the whole declaration aloud in English, Hindi or Marathi. The app accepts 1 to 2 minutes (60–120 s); store the language and validate the same limits on the server.

Profile changes: members cannot edit their details (Me → My information). They tap a detail, enter the new value and press *Request admin*; the app sends a change request `{fieldId, oldValue, newValue}` (status `pending`). The detail stays unchanged until the admin accepts (status `approved`, the server applies `newValue`) or rejects (status `rejected`, nothing changes). One open request per field: a new one replaces it. The app lists them under *My requests*; its *Simulate: admin accepts / rejects* buttons are prototype controls to be replaced by a real admin queue and push/e-mail notification. Prayer requests are limited to 300 characters (enforce on the server too).

Video size: the app re-encodes the recording to 480p / 24 fps before upload (`video_compress`, phones only). The backend must not rely on that: enforce a maximum file size and duration, and re-encode server-side (e.g. ffmpeg in a Catalyst function) before keeping it in File Store.

Office workflow: status is `pending` → `approved` or `videoReturned` (re-record). The app's "Prototype controls" (*Simulate: admin approves / returns the video*) must be removed and replaced by polling or a push notification. Access to the app must stay locked server-side until approved. Office phone/contact (`kOfficePhone`) should come from config.

## 4. Payments (Razorpay)

All payments go through one function: `showPaymentSheet` in
`lib/screens/jodie/jodie_widgets.dart`. It is a **demo sheet today**.

Used for: Jodie membership, Jodie premium plans, credit packs, Store checkout.

Real flow:
1. App asks the backend to **create an order** (amount, purpose, item, user).
2. App opens Razorpay Checkout with the returned order id (`razorpay_flutter`).
3. On success the app sends `payment_id`, `order_id`, `signature` to the backend.
4. Backend **verifies the signature**, then grants membership / credits / order.
5. `showPaymentSheet` returns `true` only after the backend confirms.

## 5. Languages

- Six languages: English, Hindi, Marathi, Kannada, Malayalam, Telugu.
- Static UI text lives in the app. **Dynamic content** (events, Mannas, notifications, videos) should be translated **once at publish time** on the server, reviewed by staff, and returned per language (`Accept-Language` or `?lang=hi`). Fall back to English when missing.
- The UI translations were written without native review; have each language checked before release.

## 6. Plugins that need Windows Developer Mode

The project builds without plugins today. Adding any of these needs
**Developer Mode** (`start ms-settings:developers`) for symlinks:

| Need | Package (suggested) |
|---|---|
| Payments | `razorpay_flutter` |
| Persist language / session | `shared_preferences`, `flutter_secure_storage` |
| Photo / video capture | `image_picker`, `camera` |
| File downloads | `dio` or `flutter_downloader` |
| Push notifications | `firebase_messaging` |
| Real-time chat | WebSocket or Firebase |

## 7. Not built yet

- Registration flow (new members after OTP)
- Giving, Polls, Sermons, and most Menu destinations
- Noahgram direct messages, comment replies
- Persisted language and session
- Push notifications
- Real images and video
