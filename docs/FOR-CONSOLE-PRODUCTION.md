# NOAH on Google Play: what the console / office team must do

The NOAH app (package `com.karunasadan.noah`) goes to Google Play as a NEW app next to the ministry's live apps. It uses its own
**Production** environment of the Catalyst project NoahApp. Nothing here changes the old apps.

**Production API (the app talks to this):** `https://noahapp-60093443705.catalystserverless.in/server/noah_api`
Public pages: `.../privacy-policy` and `.../account-deletion`.

> The production settings and secrets are NOT in this file or in git. The developer gives the new `ADMIN_API_KEY` privately (never by chat or email in clear).

## 1. Point the admin console at Production (first)
- The console must call the production URL above (not the development one) and use the **new** `ADMIN_API_KEY`.
- If the console reads or writes the Data Store directly, use the **Production** environment of the project NoahApp.
- The production Data Store starts **empty**: every member registers again in the new app. Nothing is copied from development or from the old apps.

## 2. Every new registration waits for the office
- A person signs in with their mobile number, then fills the registration (details, photo, ID proof, consent video).
- The office checks and **approves** it in the console; until then the member sees "waiting for approval".

## 3. Pastors and cell leaders (after they have registered)
- Set the member's `memberType` to `pastor` for each pastor.
- Link members to their cell leader as before (`connectedLeader`).
- Without this the Birthdays & Anniversaries list and the pastor inbox do not appear.

## 4. The test account for Google's reviewers
- Number **+91 9000000999**, fixed code **123456** (no SMS is sent for this number only; set in the production settings).
- Sign in once on a phone, fill the registration completely (a real-looking profile, a photo), and **approve** it as an ordinary member (not pastor, not admin).
- When Google has finished the review, tell the developer: the two settings are removed and the account can be deleted.

## 5. Content for the live app
Events, Daily Manna, prayers, confessions, Bible plans and so on that the app shows must be created in Production. Development data was not copied.

## 6. When someone deletes their account
- The app switches the account off at once and sends an email to the support address.
- The office must **remove the personal data within 30 days** (profile, photo, ID proof, consent video, family links, prayer requests, messages) and keep only what the law requires. The privacy pages promise this.
- Support address in the settings now: `noreply@karunasadan.com` (nobody reads replies). Better: make a real mailbox such as `support@karunasadan.com` and ask the developer to change `SUPPORT_EMAIL`. Google also writes to the contact email of the app.

## 7. Optional, later
- **Help assistant:** the four QuickML settings are empty in Production, so the help bot is off. To turn it on, follow `FOR-CONSOLE-HELP-BOT.md`, then give the four values to the developer.
- **Push in the member's language:** add the `language` column to `deviceTokens` (same document), then the developer sets `DEVICE_LANGUAGE_COLUMN=true`.
- **Google Play account:** the app is published from the ministry's organisation account. Declare the **trader status** (blue bar on the Play Console home) and keep the account verified.
