# Noah: Tier 1 data dictionary (legacy MySQL → Zoho Catalyst Data Store)

Maps the old Laravel/MySQL schema to the new Catalyst tables used by the Flutter app and the Next.js admin. Scope: **Tier 1** only (OTP login, registration, members, Home content, Events, prayer, Noahgram, messaging, files). Tier 2/3 come later.

> **Status: draft.** Anything marked **ENUM?** stores a meaning as a number in the old database. The real values are in the PHP code (constants/enums) and must be confirmed before migrating. Nothing below guesses them.

---

## 0. Conventions

| Topic | Rule |
|---|---|
| Tenancy | Single ministry (Karuna Sadan). **Drop `ministryId`** from every new table. The migration script filters `WHERE ministryId = <KSM id>`. |
| Names | Tables `PascalCase`, columns `camelCase`. |
| Ids | Catalyst gives every row a `ROWID`. Keep the old id as **`legacyId`** (BigInt, indexed) on every migrated table. Foreign keys in the new tables point to `ROWID`, resolved through `legacyId` during the load. |
| Audit | Catalyst adds `CREATEDTIME`, `MODIFIEDTIME`, `CREATORID`. Old `created/createdOn` → `legacyCreatedAt`, old `updated/updatedOn` → `legacyUpdatedAt` (DateTime). `createdBy/updatedBy` → `legacyCreatedBy/legacyUpdatedBy` (BigInt, member/user legacy id). |
| Soft delete | `archived / isArchived = 1` → **do not migrate** (except finance, Tier 3). New tables keep `isArchived` (Boolean) for future soft deletes. Drop `archivedOn/archivedBy` columns. |
| Dates | `0000-00-00` and invalid dates → `NULL`. MySQL `timestamp/datetime` are assumed IST (confirm), stored as UTC. |
| Booleans | `tinyint(1)` NULL/0 → `false`, 1 → `true`. |
| Text encoding | `members` and `locations` are `latin1` tables with `utf8mb4` columns. Export with `--default-character-set=utf8mb4` and spot-check Hindi, Marathi and Malayalam names for garbled text (mojibake) before loading. |
| `embed01…embed20` | Twenty `mediumtext` columns on content tables. → one `embeds` Text column holding a JSON array of the non-empty values. |
| Counters | `counter, likes, comments, shares, counterUpdatedOn` → keep `viewCount`, `likeCount`, `commentCount`. Rebuild from source tables where possible. |
| Language | `contentLanguage` (int) → `languageCode` (Text: `en, hi, mr, kn, ml, te, …`). **ENUM?** |
| Sensitive | Columns marked 🔒 go in **encrypted** columns (or are encrypted in the function). Never returned by list APIs. |
| Phone key | `phoneKey` = `+` + digits of `countryCode` + digits of the number, no spaces (e.g. `+919876543210`). Used for OTP login. Unique. |

---

## 1. Authentication and members

### 1.1 `Members` (core) ← `members`

| Old column | New column | Type | Notes |
|---|---|---|---|
| `id` | `legacyId` | BigInt | |
| `userId` | `legacyUserId` | BigInt | link to `users` |
| `countryCode` | `countryCode` | Text | normalise to `+91` form |
| `mobileNumber1` | `mobileNumber` | Text | digits only |
| *(computed)* | `phoneKey` | Text, **unique** | see conventions; **duplicates must be resolved before load** |
| `language` | `appLanguage` | Text | **ENUM?** (1 = ?) |
| `isKid` | `isKid` | Boolean | |
| `salutation` | `salutation` | Text | app list: Mr, Mrs, Ms, Miss, Dr, Rev, Ps |
| `firstName`, `middleName`, `lastName` | same | Text | |
| `gender` | `gender` | Text | **ENUM?** → `male/female/other` |
| `bloodGroup` | `bloodGroup` | Text | validate against A+ … O− |
| `dateOfBirth` | `dob` | Date | |
| `maritalStatus` | `maritalStatus` | Text | **ENUM?** column comment says NULL=unmarried, 1=married but it is `varchar`. Check the real values. App values: `single, married, widow, widower, separated, divorced` |
| `anniversaryDate` | `anniversaryDate` | Date | required in the app when married |
| `dateOfJoining` | `joinedOn` | Date | read-only in the app; for new members set at registration |
| `landlineCountryCode`, `landlineNumber` | `landlineDial`, `landline` | Text | |
| `emailId1` | `email` | Text | validate format |
| `emailId2` | `email2` | Text | |
| `mobileNumber2CountryCode`, `mobileNumber2` | `phone2Dial`, `phone2` | Text | |
| `occupation` | `occupation` | Text | |
| `referBy`, `referById`, `referenceId` | `referenceName`, `referenceMemberLegacyId`, `referenceCode` | Text / BigInt / Text | new app also stores `referencePhone` (+ dial) |
| `memberId` (varchar) | `memberNumber` | Text | the visible member number |
| `photo` | `photoFileId` | BigInt | → `Files` |
| `status` | `status` | Text | **ENUM?** (active / deceased / …) |
| `deceasedDate` | `deceasedDate` | Date | |
| `specialGroup` | `specialGroup` | Text | |
| `aboutMe` | `aboutMe` | Text | |
| `tempAboutMe` | `pendingAboutMe` | Text | awaiting review |
| `created/createdBy/updated/updatedBy` | see conventions | | |
| `search` | **drop** | | full-text helper; rebuild search in the function (ZCQL `LIKE`) or a `searchText` column |
| `age` | **drop** | | computed from `dob` |
| `groupId`, `groupName`, `subGroupId`, `subGroupName` | **drop** | | replaced by `GroupMembers` (§1.8) |
| `archived`, `archivedOn` | filter only | | |

### 1.2 `Registrations` (**new**: replaces a set of flags on `members`)

One row per member. For existing verified members, create `status = approved`.

| Column | Type | Source / notes |
|---|---|---|
| `memberRowId` | BigInt (FK) | |
| `status` | Text | `pending / approved / rejected / videoReturned`. Legacy: `isUnVerified` null/0 → `approved`; `1` → `pending` |
| `reviewedAt`, `reviewedByLegacyId` | DateTime / BigInt | `verifiedOn`, `verifiedBy` |
| `declarationAccepted` | Boolean | legacy `form_submit` |
| `declarationLanguage`, `declarationAcceptedAt`, `signatureText` | Text / DateTime / Text | new |
| `videoConsentState` | Int | legacy `video_consent_submit` (0 = No, 1 = Yes, 2 = NA) |
| `videoFileId`, `videoSeconds`, `videoLanguage`, `videoBytes` | BigInt / Int / Text / BigInt | new (60–120 s, compressed) |
| `idProofFileId`, `idProofType` | BigInt / Text | legacy `document` (a path) → `Files` |
| `pendingPhotoFileId` | BigInt | legacy `tmpPhoto` |
| `profileVerified`, `profileVerifiedAt`, `profileVerifiedBy` | Boolean / DateTime / BigInt | legacy `profileVerified*` |
| `reviewNote` | Text | for *videoReturned* / rejected |

### 1.3 `MemberAddresses` ← `members` (two rows per member: `type = residence | correspondence`)

| Old (residence) | Old (correspondence) | New |
|---|---|---|
| `address` | `corrAddress` | `addressLine` |
| `locationId` | `corrLocationId` | `locationRowId` (→ `Locations`) |
| `area` | `corrArea` | `area` |
| `city` | `corrCity` | `city` |
| `state` | `corrState` | `state` |
| `pincode` | `corrPincode` | `pincode` |
| `country` | `corrCountry` | `country` |

`sameAddAsResidence = 1` → do not create a correspondence row. The `current*` columns (`currentLocationId`, `currentName`, `currentAddress`, `currentArea`, `currentCity`, `currentState`, `currentCountry`, `currentLat`, `currentLng`, `currentLocationData`) are a live GPS location: **drop**, or move to a `MemberLiveLocation` table if the admin really uses it.

### 1.4 `MemberIdentity` 🔒 ← `members`

`panNo → pan`, `aadharNo → aadhaar`, `emiratesID → emiratesId`, `passportNumber → passport`, `voterId → voterId`, `drivingLicense → drivingLicence`. All **encrypted**. Validate with the formats the app uses (Aadhaar 12 digits, PAN `AAAAA9999A`, Emirates `784-YYYY-NNNNNNN-C`, …) and report rows that do not match. Do not reject them.

### 1.5 `MemberProfile` ← `members`

`religion, height, weight, diet, smoking, drink, annualIncome, complexion, educationDetail → education, employedIn`, plus `professionalOrganization, professionalProfession, professionalDesignation, professionalOfficeAddress, professionalOfficePhone, professionalWebsite`.
`smoking` / `drink`: NULL → `no`, 1 → `yes` (the app also allows `occasionally`).

### 1.6 `MemberRoles` ← `members` (flags and ministry roles)

`isPartner, partnershipExpireOn, isLeader, isPrayerWarrior, isBlockedFromComment, isChurchMember, isVIPMember, isBaptised, isAvailableForMatrimony, isPassScan, isBusCoordinator, isAlertList, alertListComment, isCorporateAccount, isVendor, isTranslator, translatingLanguages, translationRatePerWord, isYoungPartnerForPrayer, ypLastPrayedByMemberId, ypLastPrayedOn, addToYoungPartnerProgram, connectedLeader, connectedPastor, memberType, tags, serviceOfferingIds, allowRewards, rewardStartFrom, taskColor`.
`connectedLeader / connectedPastor` → member legacy ids, resolve to `ROWID`. `memberType` **ENUM?**.

### 1.7 `MemberPreferences` ← `members` and `users`

`alertType` (1 SMS, 2 Email, 3 Both), `DNDTime`, `disableWeeklyDigest`, `isNoahGramWishEnable`, `noahGramPostWizardEnable`, `whatsAppBirthdayWish`, `whatsAppAnniversaryWish`, `birthdayBouquet/Cake(+Note)`, `anniversaryBouquet/Cake(+Note)`, `lastWishDate`, `throwBackPostDate`; from `users`: `isNotificationEnable`, `pushNotification`.

### 1.8 `Groups`, `GroupMembers` ← `groups`, `groupsConnect`

`Groups`: `name, parentId → parentGroupRowId, includingAttendanceReport, languageCode`.
`GroupMembers`: `groupRowId, memberRowId` (migrate only `isArchived` null/0).

### 1.9 `MemberRelations`, `Kids`, `KidLinks`

- `membersRelations` → `MemberRelations(memberARowId, memberBRowId, relationAtoB, relationBtoA)`. **ENUM?** for `relationshipA2B / B2A`.
- `kids` → `Kids(salutation, firstName, middleName, lastName, gender, bloodGroup, dob, photoPath)`; `kidsConnect` → `KidLinks(kidRowId, memberRowId, relationship)` **ENUM?**.

### 1.10 `Locations` ← `locations`

`locationId` (Google place id) → `placeId`; `name, area, city, state, country, lat, lng`; `groupId` → `locationGroupRowId` (↔ `locationGroup`, Tier 2).

### 1.11 Admin staff: `AdminUsers`, `AdminPermissions` ← `users`, `employees`, `userPermissions`

For the Next.js admin. Create an `AdminUsers` row for each `users` row with `is_super_admin / is_admin / is_employee = 1`: `phoneKey, email, role (superAdmin|admin|employee), employeeLegacyId, blockLogin`. `userPermissions(componentId, permission)` → `AdminPermissions(adminRowId, component, permission)` **ENUM?** for `componentId`.
**Do not migrate** `passCode`, `otp`, `otpTime`, `otpAttempts`.

### 1.12 Sessions and OTP (**new**: nothing comes across)

- `OtpRequests`: `phoneKey, otpHash, expiresAt, attempts, sendCount, usedAt, ip`.
- `Sessions`: `memberRowId, refreshTokenHash, deviceId, deviceName, expiresAt, revokedAt` (replaces `userTokens`).
- `DeviceTokens`: `memberRowId, deviceId (udid), pushToken, platform (isAndroid), lastSeenAt`. Legacy `deviceTokens` has 12M rows: migrate **only the newest row per `udid`**.

---

## 2. Home content

All content tables share: `languageCode`, `translatingParentId → translatedFromRowId`, `translatorRowId`, `visibleTo / onlyForPartners → partnersOnly`, `published / isPublished`, `publishDate`, `image/photo → imageFileId`, `embeds` (from `embed01…20`), `viewCount, likeCount, commentCount`, `legacy*` audit columns.

| New table | Old | Notes |
|---|---|---|
| `DailyManna` | `dailyMana` | `title, content, prayer, publishDate, writerRowId, categoryIds → DailyMannaCategoryLinks, mediaType, video/youtubeUrl/youtubeId/youtubeThumbnail, numberOfWords, shares, showOnObituary`. Drop `isConfession` (covered by `DailyConfessions`), `weeklyDigest*`, `digestFeaturedAt` → `featuredAt`. |
| `DailyMannaCategories` | `dailyMannaCategories` | `title, description, color, photo, publishStart/End, status` |
| `DailyPrayers` | `dailyPrayers` | `title, content, publishedDate, showOnObituary` |
| `DailyConfessions` | `dailyConfessions` | `title, content, prayer, publishDate, writerRowId` |
| `Favorites` | `dailyConfessionsFavorites`, `dailyPrayersFavorites`, `dreamDictionaryFavorites` | one table: `memberRowId, component, componentRowId` (the app's *Save* buttons) |
| `BibleCommentary` | `bibleCommentary` | `bibleBookId, startChapter, endChapter, title, content, mediaType, video…` ; `bibleBookId` **ENUM?** (a book list: needs `bible_english` / the book names) |
| `Praises` | `praises` | `praise → text, bibleVerse, verse, category` **ENUM?** |
| `PraiseReports` | `praiseReport` | the Praises tab in the app: `memberRowId, memberName, text, videoLink, photo1…5 → Files, location, isFeatured, isClosed, isComplete`. Contact fields (`phoneNumber`, `email`) stay private. |
| `Books`, `BookCategories`, `BookChapters` | `books`, `bookCategories`, `bookChapters` | eBooks: `name, author, type** ENUM?**, description, photo, source (file), size, downloads, minDonationAmt(+USD), categoryIds` |
| `Videos`, `VideoCategories`, `LiveVideos` | `videos`, `videoCategories`, `liveVideos` | `videoSourceType` **ENUM?** (YouTube / Vimeo / Cloudflare), `videoId, videoUrl, thumb, videoLength, featured`; live: `startTime, videoType ENUM?, type ENUM?, commentApprovalType` |
| `Ads`, `DashboardBanners` | `ads`, `dashboard` | the Home announcement carousel: `landscapeImage, portraitImage, caption, url, expiryTime, order, eventRowId, hideFromPublic` |

---

## 3. Events and payments

| New table | Old | Notes |
|---|---|---|
| `Events` | `events` | `name, description, formattedDescription (HTML), terms, photo, startTime, endTime, startTimeUtc, endTimeUtc, timezone, eventType ENUM?, recurrenceType ENUM?, recurrenceValue, isRecurrence, locationName/Address/Lat/Lon, hallRowId, eventGroupRowId, passRequired, passExpiryTime, availableFor ENUM? (NULL = everyone, 1 = partners), passFeeType (NULL free, 1 paid), feesForPartners/NonPartners (+USD), passAvailable, passUsed, maxQuantityPerMember, allowMaxAge, preacherIds, showOnDashboard, zoom/meeting link, waitListCount, publishDateTime, filters (JSON)`. **Drop** the finance/target/result columns (`expense*, salesReceipts, target*, result*, tallyLegderTitle`); they belong to Tier 3. |
| `EventGroups` | `eventGroup`, `eventLanguageGroups` | `name, description, isOnlyForKids, connectedEmployees, scanningTeam, languageGroup` |
| `Halls`, `EventSeats` | `halls`, `eventSeatConnect` | `designJSON, seatLabels, blockedSeatLabels`; seats: `seatLabel, memberRowId, state (vacant/occupied/blocked)`. Skip `isBeingBooked*` (rebuild holds in the booking function). |
| `Passes` | `passes` | `memberRowId, eventRowId, seatLabel, type ENUM?, passCost, passCurrency, inactive, isExpired, passIsUsed(+Time/+EmployeeId), receiptRowId`. 437k rows: migrate for events from the last 12 months and future events. |
| `Payments` | `receipts` | `status` (0 pending, 1 success, 2 failed, 3 cancelled), `paymentType ENUM?`, `amount, currency, razorpayOrderId, paymentId, onlinePaymentMode, refundId, eventRowId, component/componentId, member snapshot fields (name, address…), note, comment, donationDate, partnership old/new expiry`. Keep the gateway request/response payloads in a separate `PaymentLogs` table. |

---

## 4. Prayer and community

| New table | Old | Notes |
|---|---|---|
| `PrayerRequests` | `prayerRequest` | `memberRowId, type ENUM?, content, isApproved(+By/On), prayerCount, urgentCount, reportedCount, closed(+By/On)`. The app's audience (*Prayer warriors* / *Everyone*) maps to `type` **ENUM?**. 300-character limit is enforced by the app. Backend should too. |
| `PrayerSessions` | `prayerConnect` | 4.4M rows. Migrate the **last 12 months** only, or keep totals in `prayerCount`. |
| `PrayerPosts`, `PrayerBackgrounds` | `prayerRequestPosts`, `prayerRequestBackgroundImages` | |
| `Posts` (Noahgram) | `noahGram` | `memberRowId, caption, photo (JSON list → Files), videoImage, cloudflare* (video), link, location*, category, isPinned/priority/pinExpiry, isApproved(+By/Time), scheduleDate, throwBack*, interactive* (card posts), pollRowId, competitionRowId, addToReels`. |
| `PostComments` | `comments` | `memberRowId, component ENUM?, componentRowId, content, parentRowId, likes, flagged, notApproved, hide, type, attachmentData`. Guest fields (`firstName, lastName, email, mobileNumber, isVerified`) kept for website comments. |
| `Reactions` | `likes` | 4.7M rows. `memberRowId, component ENUM?, componentRowId, reactionId ENUM?`. Migrate counts always; individual rows for the last 12 months. |
| `Followers`, `SavedPosts` | `followers`, `noahgramSavedPosts` | |
| `Polls`, `PollVotes` | `noahgramPoll`, `noahgramPollResults` | `question, answer1–6 → options (JSON), endDate` |
| `Tags` | `NoahGramTags` | |

---

## 5. Messaging and notifications

| New table | Old | Notes |
|---|---|---|
| `Threads` | `threads` | `sourceType ENUM?, sourceId, name, picture, isOpen, lastMessage, lastMessageUserLegacyId, tweetId` |
| `ThreadMembers` | `threadUserConnect` | `unread, lastRead, delivered, pinnedTime, pushNotification` |
| `ThreadMessages` | `threadMessages` | 4.6M rows: **last 12 months** + the full history of pastor/ministry threads. `isFromMinistry, isStaffOnly, message, attachmentId, replyTo, systemGenerated, sourceType ENUM?`. Drop `ip`, `emailMessageId`. |
| `MinistryMessages` | `chat` | member ↔ ministry messages (`message, isFromMinistry, isRead, hasSms, hasEmail, broadcastId, receiptId, component(Id)`) |
| `Notifications` | `notifications` (Laravel) | optional: rebuild instead of migrating |
| `Broadcasts` | `broadcasts`, `broadcastList(+Message)`, `interactiveNotifications` | Tier 3 admin tool; **skip for now** |

---

## 6. Files

`files` + `filesConnect` + `attachments` + `albums` → two tables:

- **`Files`**: `legacyFileId, name, path (old), catalystFileId (File Store), extension, size, width, height, hash, isPublic`.
- **`Attachments`**: `fileRowId, component ENUM?, componentRowId, attachmentType ENUM?, caption, albumRowId, attachmentInfo (JSON), width, height`.
- Copy the actual bytes to Catalyst File Store and write back `catalystFileId`. Never expose raw paths: the API returns signed download links.

---

## 7. Settings and secrets

- `globalSettings` → `AppSettings(key, value)`.
- `ministries` → `AppSettings` for **non-secret** values only: `name, email, phoneNumber, address, website, whatsapp, social links, colors, minPartnershipAmt, perDayPartnershipAmt, birthdayAlert/anniversaryAlert templates, donation* texts, default event picture, receipt header/footer`.
- 🔒 **Never copy into the database** (move to Catalyst environment variables / secrets, then rotate): `razorPayKey, razorPayApiSecret, razorPayWebhookSecret, stripeKey, stripeApiSecretKey, paytmMerchantKey, mailgunKey, plivoKey, zoom*Key/Secret, vimeo*, streamAccessToken, incomingFbIdToken, incomingTwitter*`.

---

## 8. New tables the app needs (no legacy source)

| Table | Purpose |
|---|---|
| `OtpRequests`, `Sessions` | see §1.12 |
| `Registrations` | see §1.2 |
| `ProfileChangeRequests` | member asks the admin to change a detail: `memberRowId, fieldId, oldValue, newValue, status (pending/approved/rejected), reviewedBy, reviewedAt, note` |
| `AccountDeletionRequests` | store-compliance; maps legacy `isDeleteRequest` |
| `Jodie*` (profiles, likes, matches, credits, subscriptions, chats) | **not in the old database** (only `isAvailableForMatrimony`). To be designed. |

---

## 9. ENUM checklist (need the PHP constants)

| Column(s) | Needed for |
|---|---|
| `members.gender`, `employees.gender`, `kids.gender`, `*.gender` stats | `Members.gender` |
| `members.language`, every `contentLanguage` | `languageCode` |
| `members.maritalStatus`, `members.status`, `members.memberType`, `users.userType` | member state |
| `membersRelations.relationshipA2B/B2A`, `kidsConnect.relationship` | relations |
| `component` (likes, comments, attachments, receipts, favourites) | polymorphic links: which entity a row belongs to |
| `likes.reactionId` | reactions |
| `events.eventType`, `recurrenceType`, `availableFor`; `passes.type` | events |
| `receipts.paymentType` (+`createdByType`) | payments |
| `prayerRequest.type` | audience |
| `videos.videoSourceType`, `liveVideos.videoType/type`, `books.type`, `*.mediaType`, `attachments.attachmentType` | media |
| `threads.sourceType`, `threadMessages.sourceType` | messaging |
| `bibleCommentary.bibleBookId`, `praises.category` | lists |

---

## 10. Data-quality checks before loading

1. Members with no phone, or duplicate `phoneKey` (list both ids, pick a winner).
2. Invalid emails, impossible dates, `dob` in the future, minors flagged `isKid`.
3. Members whose `photo`, `document` or attachment path points to a missing file.
4. Orphans: `groupsConnect`, `membersRelations`, `passes` pointing to deleted members/events.
5. Identity numbers that do not match their format (report only).
6. Row counts per table: old versus new after the load.
