# Yoni Journal

Yoni Journal is a **local-first iOS app** (SwiftUI + SwiftData) for privately tracking romantic and sexual connections. Create entries per person, attach photos or voice memos, tag what happened, and use filters + views (Home, Calendar, Achievements) to reflect on patterns over time.

## What you can do

- **Create & edit entries** with:
  - a person name/alias and **connection type** (e.g. hookup/date/sexy time/future)
  - **notes**, **rating**, and quick boolean “signals” (e.g. would meet again, green/red flags)
  - **tags** and other structured fields to make filtering easy
- **Attach media**
  - photos saved locally on-device
  - voice memos you can play back in-app
- **Browse in multiple ways**
  - **Home**: browse threads by person, search, sort, and filter (tags / flags / connection type)
  - **Calendar**: see which days have entries (heart = one entry, flame = multiple) and plan future entries
  - **Achievements**: unlock achievements based on your history
- **Optional biometric lock** (Face ID / Touch ID) for an extra layer of privacy

## Preview

### App icon / theme

<p align="left">
  <img src="BloomJournal/Resources/Assets.xcassets/profile-avatar-6.imageset/profile-avatar-6.png" alt="Profile avatar" width="160" />
</p>

> Tip: GitHub renders PNGs directly from the repo, but `.xcassets` is primarily meant for Xcode.
> For UI screenshots, it’s usually cleaner to add a top-level `assets/` folder (e.g. `assets/screenshots/`).

## Tech notes

- **Language/UI:** Swift + SwiftUI
- **Storage:** SwiftData models (e.g. `JournalEntry`, `EntryPhoto`, `UserProfile`, `AppSettings`, `AchievementUnlock`) with migrations
- **Media:** local file storage services for photos and audio memos

## Privacy

Yoni Journal is designed to be **local-first**: entries, photos, and voice memos are stored **on-device**.

This repository is public for learning/open-source purposes. Publishing the source code does **not** publish any user data.

### Notes
- If you enable iCloud device backups, your device may back up app data depending on your settings.
- If you fork this project and add analytics, logging, cloud sync, or third-party SDKs, you should clearly disclose that to users.
