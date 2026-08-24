# 👷 Sahakarya — Worker App (Flutter)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Cooperative Gig Services Marketplace — Worker Mobile Interface**  
> Empowering certified Labour Cooperative Federation members with **guaranteed minimum rates, institutional welfare fund management, transparent job dispatch, and real-time earnings tracking.**

---

## 🌟 Key Features

* **One-Tap Availability Toggle:** Switch between `Online` and `Offline` states to control working hours and dispatch eligibility.
* **30-Second Real-Time Job Dispatch Dialog:** Transparent job offers displaying customer distance, service type, fixed price, and guaranteed net earnings with an interactive countdown timer.
* **Turn-by-Turn Active Job Flow:** Step-by-step progress tracking: `Accepted` ➔ `En Route` ➔ `In Progress` ➔ `Completed` with OTP verification.
* **Institutional Welfare Fund Dashboard:** Dedicated ledger tracking automated social security contributions, emergency health assistance, and claim management.
* **Daily / Weekly Earnings Analytics:** Transparent payout breakdown showing completed jobs, base pay, tips, and welfare deductions without hidden cuts.
* **Background GPS Location Stream:** Low-power periodic coordinate updates ensuring accurate geospatial customer matching via MongoDB `$geoNear`.

---

## 🏗️ Tech Stack & Architecture

* **Framework:** [Flutter](https://flutter.dev) (iOS, Android)
* **State Management:** [Riverpod](https://riverpod.dev)
* **Navigation:** [GoRouter](https://pub.dev/packages/go_router)
* **Real-time Dispatch:** `socket_io_client` with automatic reconnection & room subscriptions
* **Geolocation:** [Geolocator](https://pub.dev/packages/geolocator) for background & active tracking
* **Theme:** High-contrast, worker-friendly UI with accessible typography and touch targets.

---

## 📂 Project Structure

```text
worker_app/
├── lib/
│   ├── main.dart                      # App entry point & background service initialization
│   ├── router.dart                     # Declarative GoRouter routing configuration
│   ├── models/                         # Data transfer models (Job, WorkerProfile, WelfareTransaction)
│   ├── providers/                      # Riverpod state providers
│   │   ├── auth_provider.dart          # Worker authentication & credential store
│   │   ├── availability_provider.dart  # Online/Offline status synchronization
│   │   ├── incoming_job_provider.dart  # Real-time job offer modal state & countdown
│   │   ├── active_job_provider.dart    # Ongoing job lifecycle (En Route, Start, Complete)
│   │   ├── earnings_provider.dart      # Real-time earnings aggregation
│   │   └── welfare_provider.dart       # Welfare fund balance & claims
│   ├── screens/                        # UI screens
│   │   ├── onboarding/                 # Federation member registration & verification
│   │   ├── home/                       # Dashboard, availability toggle, active metrics
│   │   ├── incoming_job/               # Job offer dialog with timer
│   │   ├── active_job/                 # Real-time customer navigation & OTP completion
│   │   ├── earnings/                   # Daily & weekly income analytics
│   │   ├── welfare/                    # Social security balance & claim submission
│   │   └── profile/                    # Skills, federation details & ratings
│   ├── services/                       # API clients, Job WebSockets, & Location streamers
│   ├── theme/                          # Color palettes & worker-optimized typography
│   └── widgets/                        # Availability toggles, job cards, & summary widgets
└── pubspec.yaml                        # Dependencies and platform plugins
```

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (`>= 3.3.0`)
* Dart SDK (`>= 3.0.0`)
* Android Device / Emulator with location permissions enabled

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Sahakaryaa/Worker-App.git
   cd Worker-App
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Backend Endpoint:**
   Set backend URL in `.env` or `lib/services/api_client.dart`:
   ```env
   API_BASE_URL=http://10.0.2.2:8000  # Android Emulator loopback
   # API_BASE_URL=http://localhost:8000 # iOS Simulator or Physical device IP
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 🛡️ Fairness & Social Security Guarantee

Every booking fulfilled through this app automatically deposits a non-extractable contribution into the federation-governed **Worker Welfare Fund**, providing health insurance, pension accumulation, and emergency aid.
