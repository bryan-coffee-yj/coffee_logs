# Cofi Logs ☕️

A local-first mobile companion built with Flutter for specialty coffee enthusiasts and coffee lover. Designed to track extractions, automate bean inventory, dynamically scale multi-step recipes, and monitor daily brewing analytics without cloud subscriptions.

## 🌟 Key Features

### 1. Global Timeline & Interactive Feed (Home)
- **Chronological Extraction Log:** A single unified stream of every coffee brewed across all your beans.
- **Palate Profile Bars:** Replaces vague text reviews with custom, segmented 1–5 visual indicators evaluating **Acidity**, **Sweetness**, and **Body**.

### 2. Smart Cellar & Lifetime Archive (Beans)
- **Automated Inventory Tracking:** Deducts your exact dose (in grams) from your active bag weight the moment you save a brew. Warns you when a bag drops below 15% capacity.
- **Active Stash vs. Archive:** Features an segment toggle separating active open bags from your finished collection.
- **Honest Review System:** When a bag is finished, archive it with custom ratings:
  - 🟢 **Enjoyed / Loved:** Highlighted green border.
  - ⚪ **Normal / Everyday:** Standard clean border.
  - 🔴 **Scam / Expired / Bad:** Highlighted red border with final review notes.

### 3. Multi-Step Recipe Book & Cumulative Scale Math (Methods)
- **Brewer & Method Clarity:** Prominently displays brew type and specific equipment (e.g., `POUR-OVER • SOLO DRIPPER`).
- **Cumulative Scale Targets:** Eliminates morning mental math by displaying both the individual pour weight and the real-time scale total (e.g., `Pour 110g ➔ Scale: 150g`).
- **Step Instructions:** Supports custom technique notes per step (e.g., *"Pour in slow concentric circles"*, *"Swirl vigorously"*).
- **Dynamic Step Builder:** A slide-up modal that adapts its inputs based on the step type (automatically hiding the water field for `Wait` or `Swirl` phases).

### 4. The Barista Toolkit & Financial Dashboard (Other)
- **Dynamic Ratio Scaler:** Adjust your bean dose for a sample brew, and the app mathematically scales the entire multi-step recipe—recalculating every individual pour volume and cumulative scale target while preserving the exact ratio.
- **Financial & Extraction Analytics:**
  - Total money spent (RM) on coffee beans.
  - Total specialty coffee consumed (kg).
  - Accurate **Cost-per-Cup** calculation.
  - Total bag count across your brewing journey.

### 5. Seamless Barista Workflow
- **Central Floating Action Button:** A circular notched bottom bar allowing one-tap access to log a brew from anywhere in the app.
- **Global Bean Selector:** Quickly choose which open bag you are brewing, auto-filling your 2x2 extraction dashboard with your saved method parameters.
- **Zero-Friction Offline Backup:** One-tap export to standard CSV format combining your beans, prices, and extraction logs for Google Sheets or Excel.

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (SDK 3.22+)
- **Language:** Dart
- **State Management:** [Riverpod](https://riverpod.dev/) (`AsyncNotifier` & `FutureProvider.family`)
- **Local Database:** SQLite via [`sqflite`](https://pub.dev/packages/sqflite) with normalized tables, foreign keys, and cascading deletes.
- **Branding & Native Assets:** 
  - Custom vector pour-over app icon generated via [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons).
  - Native fluid launch screen via [`flutter_native_splash`](https://pub.dev/packages/flutter_native_splash).
- **Typography:** [`google_fonts`](https://pub.dev/packages/google_fonts)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed on your machine.
- An Android device or emulator (tested on Xiaomi 14 running at 120Hz).

---

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/cofi_logs.git
   cd cofi_logs

---

## 📄 Database Architecture
The local SQLite schema operates on three normalized, relational tables:
- **coffee_beans:** Tracks active inventory, pricing, roast details, and archive statuses.
- **brew_methods:** Stores multi-step recipe parameters, target ratios, and serialized JSON pour steps.
- **brew_logs:** Historical extraction records linking bean IDs to method templates, grind settings, and palate ratings.
