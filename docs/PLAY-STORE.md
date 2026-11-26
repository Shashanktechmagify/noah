# NOAH on Google Play: what is ready, and what is left

App id (permanent): **`com.karunasadan.noah`**. App name: **NOAH**. First version: `1.0.0+1` (`pubspec.yaml`).

## 1. What is already done in the code

| What | State |
|---|---|
| App id `com.karunasadan.noah` (was the placeholder `com.example...`, which Google Play refuses) | done, `MainActivity` moved, a signed bundle was built and checked (the id inside is the new one) |
| Signing with an upload key from `android/key.properties`; a bundle without it is refused (Play rejects the debug key) | done |
| Target SDK 36, min SDK 24, 64-bit libraries, native debug symbols in the bundle | done (Flutter's defaults; Play asks for 35 or more) |
| Permissions: camera, microphone, notifications, internet only. A plugin's open-ended storage permission is capped to Android 12 and older | done |
| **Delete my account** in the app (Me, last row) and a web page for it. Google requires both | done (`POST /me/delete-account`, `/account-deletion`) |
| **Privacy policy** web page with what the app collects (Google requires a public URL) | done (`/privacy-policy`), to be read by the ministry |
| A **test sign-in for Google's reviewers** (they cannot receive an SMS) | done, off until you set it (section 4) |
| Push notifications work only with the Firebase file of THIS package | the build works without it (no push) until you add the file |

## 2. What only you can do (in this order)

### 2.1 The Google Play developer account
* Play Console (https://play.google.com/console), one-time fee of USD 25, with the ministry's or the company's name.
* An **organisation** account needs a D-U-N-S number and verification of the organisation (days).
* A **personal** account made after November 2023 must first run a **closed test with at least 12 testers for 14 days** before it may publish to everyone. Plan for it.

### 2.2 The upload key (once; never commit it, never lose it)
```powershell
New-Item -ItemType Directory -Force C:\Users\user\noah-keys
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v -keystore C:\Users\user\noah-keys\noah-upload.jks -alias noah-upload -keyalg RSA -keysize 2048 -validity 10000
```
Then make `android\key.properties` (it is git-ignored):
```
storePassword=<the password you chose>
keyPassword=<the password you chose>
keyAlias=noah-upload
storeFile=C:/Users/user/noah-keys/noah-upload.jks
```
Keep the `.jks` file and both passwords in **two safe places** (a password manager and a copy elsewhere). In Play Console choose **Play App Signing** (the default): Google keeps the real signing key and this is only the key you upload with, so a lost upload key can be reset through Google support.

### 2.3 Firebase (push notifications) for the new package
1. Firebase console: use (or make) the **production** Firebase project. The one the app has now is `noah-b-test`, a test project.
2. Add an Android app there with the package **`com.karunasadan.noah`**. Download `google-services.json` into `android/app/`.
3. The backend sends push with a service account: `FCM_SERVICE_ACCOUNT` of the function in **Production** must be from the **same** Firebase project, or no push arrives.
Without the new file the app still builds and runs, only without push (the build prints a warning).

### 2.4 The production backend
Deploy `noah_api` to the **Production** environment of Catalyst and give it its own settings (see `noah-backend/README.md` and `docs/FOR-CONSOLE-HELP-BOT.md`): at least `NOAH_JWT_SECRET`, `NOAH_OTP_PEPPER`, `ADMIN_API_KEY`, the MSG91 settings (`SMS_PROVIDER=msg91`, ...; `docs/MSG91-SMS.md`), `OTP_DEV_ECHO=false`, `NOAH_DEBUG_ERRORS=false`, `FCM_SERVICE_ACCOUNT`, `SUPPORT_EMAIL`, and the mail settings. Then note the **Production URL** of the function.

### 2.5 Build the bundle
```powershell
flutter build appbundle --release --dart-define=NOAH_API=<the Production URL of noah_api>
```
The file is `build\app\outputs\bundle\release\app-release.aab`. A first build takes about 10 minutes.
* **Install the "Android SDK Command-line Tools (latest)"** (Android Studio, Settings, Android SDK, SDK Tools). Without them Flutter ends with "failed to strip debug symbols" although the `.aab` was made.
* **Every upload needs a higher version number**: change `version: 1.0.0+1` in `pubspec.yaml` to `1.0.0+2`, `+3`, and so on (the number after the plus).
* Without `NOAH_API` the app runs in demo mode (sample data, no server). Never upload such a build.

### 2.6 The pictures
* **App icon 512 x 512 PNG** (Play) and the launcher icon. `assets/images/noah.png` is only **160 x 160**: too small, it looks blurred on phones. Give a **1024 x 1024 PNG** (square, the logo with some margin), put it there and run `dart run flutter_launcher_icons`.
* **Feature graphic 1024 x 500** (the banner at the top of the listing).
* **Phone screenshots**: at least 2, best 4 to 8 (the Home, Daily Manna, Prayer Wall, Noahgram, Events, Help). Use a signed-in test member with real-looking content.

## 3. Play Console: the forms

### 3.1 Store listing (text to paste)
* **App name** (30): `NOAH: Karuna Sadan Ministries`
* **Short description** (80): `Your church family in one app: daily Manna, prayer, events and community.`
* **Full description** (4000):
```
NOAH is the app of Karuna Sadan Ministries. It keeps you close to your church family and to the Word, every day.

Every day
- Daily Manna, daily prayers and confessions to start your day
- Bible study plans with the King James text, a Bible commentary and a dream dictionary
- Everything in your own language: English, Hindi, Marathi, Telugu, Malayalam, Tamil and Kannada

Together
- Send a prayer request, and pray for the requests of other members on the Prayer Wall
- Noahgram: share photos and reels with your church family
- Events: see what is coming, book your pass and show the QR code at the door
- Message your pastor, your cell leader and the church office
- Birthday and anniversary greetings from your church

Your family
- Link your family and add your children; when a child turns 15 you can make them a member
- Your details, your photo and your documents stay private to you and the church office

Need help? Ask the built-in help assistant, or talk to the church office in one tap.

NOAH is for members of Karuna Sadan Ministries. You sign in with your mobile number.
```
* **Category**: Lifestyle (or Books & Reference). **Contact email**: the support email. **Website**: https://www.karunasadan.com
* **Privacy policy URL**: `<the Production URL>/privacy-policy`
* **Account deletion URL** (in the Data safety form): `<the Production URL>/account-deletion`

### 3.2 App access (reviewers must be able to sign in)
Choose "All or some functionality is restricted" and give the reviewers a number and a code. They cannot receive an SMS, so:
1. In the console, make an ordinary member for a spare number (for example `+919000000999`): approved registration, a name, a photo and a few details. **Not** a pastor or an admin.
2. Set in the Production function: `REVIEW_PHONE=+919000000999` and `REVIEW_OTP=<6 digits you choose>`. That number then gets that fixed code and no SMS; every other number is unchanged.
3. In Play Console, App access, write: "Open the app, enter the mobile number 9000000999 (India, +91) and the code <the 6 digits>."
4. When the review is over, remove both settings.

### 3.3 Data safety (what to declare)
Collected, encrypted in transit (https), the user can ask for deletion (the URL above). Nothing is sold; the services we use (Zoho Catalyst, MSG91, Firebase Cloud Messaging, Zoho ZeptoMail) work on our behalf, which Google does not count as "sharing". No advertising, no location, no contacts, no payments, no crash or analytics SDK, no advertising ID.

| Data type (Play's name) | What it is | Required? |
|---|---|---|
| Personal info: Name, Email address, Phone number, Address | registration and profile | name and phone required, the rest asked at registration |
| Personal info: Other info | date of birth, gender, marital status, wedding anniversary, occupation, education, languages | asked at registration |
| Personal info: Political or religious beliefs | religion (profile) | optional |
| Health and fitness: Health info | height, weight, diet (profile of the matching tab) | optional. Declare it if that tab ships |
| Photos and videos | profile photo, the consent video, Noahgram posts | photo and video required to register |
| Files and docs | ID proof picture | required to register |
| Messages: Other in-app messages | chat with pastor, leader, office | optional |
| App activity: Other user-generated content | prayer requests, posts, comments, likes | optional |
| App info and performance | none | |
| Device or other IDs | the push notification token | required for notifications |

Purposes: App functionality, Account management, Communications. Not for advertising or analytics.

### 3.4 The other declarations
* **Ads**: none. **Content rating** (IARC questionnaire): the app has user-generated content (Noahgram posts and comments) and members' chat; no violence, no gambling, no purchases. Answer honestly: the result is usually "Teen".
* **Target audience**: members from **15** can have their own account, so choose **13-15, 16-17 and 18+** and not "under 13" (that would bring the Families policy). The ministry should confirm.
* **User-generated content**: Google wants a way to report content and a moderation process. Noahgram posts wait for the office's approval and comments can be reported; see section 5 for what is still to check.
* **Permissions**: camera (profile photo, ID proof, the consent video and QR scanning), microphone (the sound of the consent video), notifications. No location, contacts or SMS permission is used.
* **Government, finance, health, news apps**: none of them.

### 3.5 Release steps
1. **Internal testing**: upload the `.aab` there first, add yourselves as testers, install from Play and sign in. Check push, the Help assistant, Delete my account (use a spare account!).
2. **Closed testing** (required for a new personal account: 12 testers for 14 days), then **Production**. A first review takes a few days.

## 4. Settings of the Production function for Play

| Setting | Value |
|---|---|
| `SUPPORT_EMAIL` | the office email: the deleted-account reports go there, and the privacy pages show it |
| `REVIEW_PHONE`, `REVIEW_OTP` | only while Google reviews (section 3.2) |
| `ANDROID_PACKAGE` | `com.karunasadan.noah` (the default now) |
| `APP_DOWNLOAD_URL` | `https://play.google.com/store/apps/details?id=com.karunasadan.noah` (Noahgram share pages link to it) |

## 5. Before you publish: check these

1. **Screens that still show sample content when signed in**: the **Jodie** tab (matching) and, in Me, **Drive**, **Store** and **Rewards** are not connected to the server yet and show made-up people and items. Real members and Google's reviewers would see them. Hide them until they are built (the menu entries that say "coming soon" are fine).
2. **Jodie is member-to-member chat**: if it ships, Google's rules need a way to report and block people. It does not exist yet.
3. **Deleting an account**: the account is switched off at once, but the **office removes the data by hand within 30 days** (the privacy pages promise it). Someone must do it, and keep the records the law requires.
4. **Read `/privacy-policy`** once: the first part is the ministry's own text from the app; the part about the app is a plain list of what the app does, to be checked by the ministry.
5. **Cell leaders** can see every member's contact details, address and marital status in the birthday list. Consider limiting it to their own cell.
6. The icon file is 160 x 160 (section 2.6).
