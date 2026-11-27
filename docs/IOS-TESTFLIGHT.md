# NOAH on iPhone: TestFlight and the App Store (built on GitHub, no Mac)

The app id (bundle id) is **`com.karunasadan.noah`**, a NEW app next to the ministry's live `com.gdiz.noah`. The workflow
`.github/workflows/ios-testflight.yml` builds a signed app on a GitHub macOS machine and sends it to TestFlight.
(The older `ios-build.yml` makes an unsigned `.ipa` for Sideloadly; it cannot do push notifications.)

## One-time setup (in this order)

### 1. Apple (App Store Connect and developer.apple.com), with an Admin account
1. The **Account Holder** accepted the latest Program License Agreement and the **Paid Applications Schedule** (Business > Agreements).
2. **Identifiers**: developer.apple.com > Certificates, IDs & Profiles > Identifiers > + > App IDs > App. Bundle ID `com.karunasadan.noah`,
   capability **Push Notifications** on.
3. **APNs key**: Keys > + > "Apple Push Notifications service (APNs)". Download the `.p8` once, write down its **Key ID**.
4. **Team ID**: developer.apple.com > Membership details (10 characters).
5. **App Store Connect API key**: Users and Access > Integrations > App Store Connect API (the Account Holder clicks "Request Access" once).
   Generate a key, access **App Manager**. Write down the **Issuer ID** and **Key ID**; download the `.p8` once.
6. **The app**: App Store Connect > Apps > + > New App. iOS, a name nobody else uses on the App Store, bundle id `com.karunasadan.noah`, SKU `noah-ios`.

### 2. Firebase (project NOAH, noah-203605)
1. Add an **iOS app**, bundle id `com.karunasadan.noah`. Download **GoogleService-Info.plist**.
2. Project settings > Cloud Messaging > the Apple app > **APNs authentication key**: upload the push `.p8` with its Key ID and the Team ID.

### 3. GitHub secrets (repository > Settings > Secrets and variables > Actions)
| Secret | Value |
|---|---|
| `APPLE_TEAM_ID` | the Team ID |
| `ASC_KEY_ID` | Key ID of the App Store Connect API key |
| `ASC_ISSUER_ID` | its Issuer ID |
| `ASC_KEY_P8` | the whole text of `AuthKey_XXXX.p8` (open it in a text editor, copy everything) |
| `GOOGLE_SERVICE_INFO_PLIST_B64` | GoogleService-Info.plist in base64 (PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\GoogleService-Info.plist")) \| Set-Clipboard`) |

Never put these files or values in the repository or in a chat.

## Every build
GitHub > Actions > **iOS TestFlight** > Run workflow (leave the API address). About 20 to 30 minutes. The build number is the run number.
In App Store Connect > the app > TestFlight, the build appears after Apple has processed it (10 to 30 minutes). Add testers
(internal: your team, no review; external: Apple reviews the first build).

## Notes
* Push on iPhone needs: the entitlement (`ios/Runner/Runner.entitlements`, done), the APNs key in Firebase (step 2) and a real device
  (not the simulator). The app asks for the permission, then Apple gives its token, then Firebase gives its own.
* A macOS runner costs 10 times the minutes: on a private repository the free plan (2000 minutes) allows about 8 to 10 builds a month.
* Apple also wants, before review: a privacy policy URL (`.../privacy-policy`), the account deletion inside the app (Me > Delete my account),
  screenshots (6.9 and 6.5 inch iPhone), and a reviewer login (`9000000999` / `123456` while the review settings are on).
