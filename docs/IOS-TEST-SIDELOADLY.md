# Testing the app on an iPhone without a Mac (GitHub Actions + Sideloadly, free Apple ID)

## 1. Build the .ipa on GitHub
1. Push the repository (the workflow is `.github/workflows/ios-build.yml`).
2. GitHub > the repository > **Actions** > **iOS build (unsigned ipa)** > **Run workflow** (leave the API address, or change it).
3. Wait about 10 to 20 minutes. When it is green, open the run and download **noah-ios-ipa** under *Artifacts*. Unzip it: it holds `noah.ipa`.
4. Red? Open the failed step and copy its last lines.

## 2. Install it on the iPhone (Windows)
1. Install **iTunes** and **iCloud** from apple.com (the downloaded versions, not the Microsoft Store ones). Install **Sideloadly** (sideloadly.io).
2. Connect the iPhone by USB, unlock it, tap *Trust*.
3. Open Sideloadly, drag `noah.ipa` in, enter your **Apple ID**, press **Start**. (If it asks for the bundle id, a unique one such as `com.yourname.noah` avoids a clash.)
4. On the iPhone: Settings > Privacy & Security > **Developer Mode** > On (the phone restarts).
5. Settings > General > **VPN & Device Management** > your Apple ID > **Trust**.
6. Open Noah.

## 3. What works and what does not (free Apple ID)
Works: sign in, registration, email and WhatsApp codes, Noahgram, events, library, Tamil, camera and video.
Does not: push notifications, share links that open the app (these need a paid Apple Developer account, $99 a year).
The app stops opening after **7 days**: install it again with Sideloadly.
