# Truth or Dare: Party & Couples 🎉❤️

Truth or Dare is a fun and modern party game designed for friends and couples.
Play classic Truth & Dare with smart filters, daily prompts, favorites, and a clean, polished UI.

---

## ✨ Features

### 🎉 Party Mode (Free)
- Truth & Dare prompts
- Filters: Clean, Fun, Spicy
- Player rotation
- No-repeat shuffle system
- Save favorites
- Daily rotating prompts

### ❤️ Couples Mode (Premium)
- Exclusive couples-only prompts
- Categories designed for bonding & fun
- Streak tracking
- Daily couples prompt
- One-time purchase (lifetime access)

### 🚀 Premium Benefits
- Unlock Couples Mode
- Remove all ads
- Lifetime access (no subscription)

---

## 📲 Platforms
- iOS
- Android

---

## 🛠 Tech Stack

- **Flutter**
- **Riverpod** (state management)
- **Firebase**
  - Analytics
  - Remote Config
  - Crashlytics
- **Google AdMob**
- **In-App Purchases**
- **Remote Prompt Hosting (S3 / CDN)**
- **Local Caching & Offline Support**

---

## 🔐 Privacy & Security
- No account required
- No personal information collected
- Preferences stored locally
- Analytics data is anonymized

- [Privacy Policy](./PRIVACY_POLICY.md)
- [Terms of Use](./TERMS_OF_USE.md)

---

## 📦 Project Structure

```text
lib/
├── core/
│   ├── services/
│   ├── remote/
│   └── telemetry/
├── data/
│   ├── models/
│   ├── providers/
│   └── repositories/
├── features/
│   ├── party/
│   ├── couples/
│   ├── daily/
│   ├── favorites/
│   └── settings/
├── widgets/
└── main.dart
