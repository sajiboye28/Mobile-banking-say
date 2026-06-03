# Changelog

All notable changes to the Real Banking project will be documented in this file.

## [3.3.0] - 2026-03-26

### Feature Additions & Improvements

#### Flutter — Transaction Ledger Search
- **`transactions_screen.dart`** — Added animated search bar: a search icon button in the header expands a full-width `AnimatedContainer` text field; searches across transaction description and related user name in real-time
- **`transactions_screen.dart`** — Fixed transaction row icons to match home screen: credit uses `south_rounded` with `success` green background, debit uses `north_rounded` with `primaryContainer` blue background, failed uses `error_outline_rounded` with error red background
- **`transactions_screen.dart`** — Empty state now shows tailored message for search ("No results for '…'") vs filter no-match

#### Flutter — Home Screen Monthly Stats Card
- **`home_screen.dart`** — Added `_buildMonthlyStatsCard` widget placed between hero balance card and quick actions grid; streams this month's transactions and computes Income / Spent / Net values in real-time; three color-coded stat pills using `AppColors.success`, `AppColors.error`, and `AppColors.primaryContainer`

#### Flutter — Live Notification Badge
- **`home_screen.dart`** — Notification bell now shows a live unread count badge via `StreamBuilder` on the `notifications` Firestore collection; shows count label for 1–99, "99+" for overflow, and hides the badge when count is 0

#### Admin Panel — Dashboard Analytics Section
- **`src/app/dashboard/page.tsx`** — Added a new analytics grid between stat cards and recent transactions:
  - **Transaction Volume card**: Credit vs Debit totals with color-coded summary tiles, a proportional gradient bar chart, and legend
  - **Activity Summary card**: Today's transaction count, all-time total, average transaction value, and failed transaction count

#### Admin Panel — Transaction Filters & CSV Export
- **`src/app/dashboard/transactions/page.tsx`** — Added Status filter dropdown (All/Success/Pending/Failed) alongside the existing Type filter
- **`src/app/dashboard/transactions/page.tsx`** — Added "Export CSV" button that downloads all currently-filtered transactions as a `.csv` file with all columns including timestamp; uses browser `Blob` API

#### Admin Panel — Send Notification to User
- **`src/app/dashboard/users/page.tsx`** — Added "Notify" button per user row that opens a modal for composing and sending a custom notification; writes to the `notifications` Firestore collection (type: `announcement`) so it immediately appears in the user's Flutter app notification center

---

## [3.2.0] - 2026-03-26

### Functional Fixes & Feature Completion

#### Flutter — Bug Fixes
- **`account_summary_screen.dart`** — Fixed `PrimaryScrollController` assertion: added `primary: false` to the `SingleChildScrollView` inside the `Expanded` StreamBuilder, preventing Flutter's primary scroll controller conflict when pressing arrow keys on web
- **`profile_screen.dart`** — Fixed inaccessible Settings screen: added `SettingsScreen` import and a "PREFERENCES" section with a Settings navigation row
- **`submit_ticket_screen.dart`** — Fixed Firestore field mismatch: renamed `description` → `message` and added `priority: 'medium'` to align with admin panel schema

#### Flutter — QR Scan Payment (Now Fully Functional)
- **`send_money_screen.dart`** — Added optional `initialRecipientUid`, `initialRecipientName`, `initialAmount` parameters; `initState` pre-populates fields and advances to TCC step when invoked from QR scan
- **`qr_scan_screen.dart`** — "Pay Now" button now navigates to `SendMoneyScreen` with pre-filled recipient data instead of showing a fake snackbar; added `send_money_screen.dart` import

#### Flutter — Design Improvements
- **`home_screen.dart`** — Improved transaction row icons: credit uses `south_rounded` with `success` green tinted background, debit uses `north_rounded` with `primaryContainer` tinted background, failed uses `error_outline` with error red background (replaced generic `trending_up/down` with neutral `surfaceContainerHigh` background)
- **Removed** unused `settings_screen` import from `home_screen.dart`

#### Admin Panel — Support Tickets Page
- **`src/app/dashboard/support-tickets/page.tsx`** — New full-featured support ticket management page: real-time Firestore listener, stats row (open/in_progress/resolved/closed counts), filter tabs, expandable ticket cards with customer info, message content, admin note textarea, and one-click status update buttons
- **`src/components/Sidebar.tsx`** — Added "Support Tickets" nav item with `MessageSquare` icon
- **`src/app/dashboard/layout.tsx`** — Added `/dashboard/support-tickets` page title; updated tab title to "Nexus Admin — Control Panel"

#### Admin Panel — Favicon
- **`public/favicon.svg`** — New Electric Blue gradient "N" lettermark SVG favicon
- **`src/app/layout.tsx`** — Added favicon metadata pointing to `/favicon.svg`; updated title/description

---

## [3.1.0] - 2026-03-26

### Redesigned — Sovereign Vault UI System: Remaining Screens (Flutter)
Complete second wave of the Sovereign Vault redesign, bringing every remaining Flutter screen into full compliance with the `AppColors` design token system. Zero hardcoded hex colors remain across the customer app.

#### Auth Screens
- **`register_screen.dart`** — Full rewrite: FadeTransition + SlideTransition entry, 72px Electric gradient icon tile, "NEXUS" wordmark in `primaryContainer`, `surfaceContainerLow` form card (borderRadius 28), Electric gradient CTA, admin-approval warning notice, `surfaceContainerHighest` Google sign-up button
- **`forgot_password_screen.dart`** — Full rewrite: Same header pattern as register screen, two-state layout (form / email-sent success), Electric gradient "Send Reset Link" and "Back to Login" CTAs, success state with gradient check circle + email display in `primary` lavender

#### Hub & Status Screens
- **`notifications_screen.dart`** — Full rewrite: `SliverAppBar` + `SliverList`, 10px uppercase section headers, `surfaceContainerLow` notification cards with 3px unread accent bar + `primaryContainer` dot indicator, swipe-to-dismiss with `AppColors.error` red background
- **`settings_screen.dart`** — Full rewrite: `SliverAppBar`, custom `_tile` / `_toggleTile` helpers using `surfaceContainerLow`, custom pill toggle (`AnimatedContainer`/`AnimatedAlign`) in place of Material `Switch`, dialogs use `surfaceContainerLow` + Electric gradient action button
- **`support_screen.dart`** — Full rewrite: Electric gradient hero card, 3-chip contact row (`primaryContainer`/`success`/`secondary`), `surfaceContainerLow` FAQ `ExpansionTile`s, Electric gradient "Submit a Support Ticket" CTA, ticket cards with `AppColors` status color map
- **`submit_ticket_screen.dart`** — Full rewrite: `SliverAppBar`, `surfaceContainerLow` dropdown, Electric gradient submit button, AppColors snackbars
- **`account_summary_screen.dart`** — Full rewrite: Safe-area custom header, `surfaceContainerLow` month picker, income/expense summary cards with color-tinted backgrounds, BarChart with `primaryContainer→primary` gradient rods, PieChart with `success`/`error` sections

#### Utility & Feature Screens
- **`bill_pay_screen.dart`** — AppColors token migration: all `const Color(0xFF…)` and `Colors.white.withOpacity()` replaced; success screen uses `success` green; step connector uses `primaryContainer`; TCC cells use `surfaceContainerLow`/`High`
- **`savings_goals_screen.dart`** — AppColors token migration: removed private `_primaryBlue/_green/_red` constants, replaced throughout with `AppColors.primaryContainer`/`success`/`error`; FAB uses `primaryContainer`
- **`currency_converter_screen.dart`** — AppColors token migration: result card gradient replaced with `surfaceContainerLow` fill; swap icon uses `primaryContainer`; Convert button uses `electricGradient`; currency picker sheet uses `surfaceContainerLow`
- **`qr_generate_screen.dart`** — Full rewrite: safe-area custom header, animated glow using `primaryContainer`/`secondary`, `surfaceContainerLow` QR card, `primary` lavender account badge, Electric gradient Share button; removed duplicate `AnimatedBuilder` class that shadowed Flutter's built-in
- **`qr_scan_screen.dart`** — Full rewrite: safe-area custom header, `surfaceContainerLow` scanner frame with `primaryContainer` corner marks and animated scan line, Electric gradient "Pay Now" CTA in bottom sheet, `surfaceContainerLow` demo-scan button; removed duplicate `AnimatedBuilder` class
- **`identity_verification_screen.dart`** — AppColors token migration: removed `_bgPrimary/_bgSecondary/_bgTertiary/_blue/_green/_red` private constants; step indicator uses `primaryContainer`; document type cards use `surfaceContainerLow`; submit button uses `electricGradient`
- **`request_money_screen.dart`** — AppColors token migration: `TabBar` indicator uses `primaryContainer`; error containers use `AppColors.error`; amount input box uses `surfaceContainerLow`; request status badges use `AppColors` color map
- **`card_settings_screen.dart`** — AppColors token migration: removed all private color constants (`_blue/_green/_red/_amber/_textPrimary/_textSecondary/_divider`); card preview gradient updated to `primaryContainer → primary`

#### Bug Fixes
- Fixed `QrEyeShape.roundedRect` / `QrDataModuleShape.roundedRect` invalid enum values → replaced with `.square` in `transaction_receipt_screen.dart`
- Fixed `AppColors.tertiary` undefined getter in `settings_screen.dart` → replaced with `AppColors.secondary`
- Removed duplicate `class AnimatedBuilder extends AnimatedWidget` from `qr_generate_screen.dart` and `qr_scan_screen.dart` (shadowed Flutter's built-in, causing silent runtime issues)

---

## [3.0.0] - 2026-03-26

### Redesigned — Sovereign Vault UI System (Flutter)
Complete overhaul of the Flutter customer app to match the **"Sovereign Vault"** design system from the stitch design files. All screens now use Organic Brutalism — glassmorphism, tonal layering, and the Electric Blue (#0052FF → #b7c4ff) gradient.

#### New Design Tokens (`lib/theme/app_colors.dart`)
- Added `AppColors` class with the complete Sovereign Vault color palette:
  - Obsidian backgrounds: `background` (#0A0A0A), `surface` (#131313), four container tiers (#0E0E0E → #353534)
  - Electric primary: `primaryContainer` (#0052FF), `primary` (#B7C4FF)
  - Semantic: `success`, `warning`, `error` and their containers
  - `electricGradient` and `glassGradient` LinearGradient constants

#### Home Screen (`home_screen.dart`) — Full Redesign
- **Brand bar**: "NEXUS" logotype in Electric Blue, greeting + first name, notification badge
- **Hero balance card**: Glassmorphic container (BackdropFilter blur 20px), ambient glow circles, ExtraBold 46px balance with "$" in primary lavender, visibility toggle (show/hide)
- **Status badge**: Live dot indicator (green/amber/red) showing account status
- **CTA buttons**: "Add Money" uses Electric gradient; "Send" uses glass secondary style
- **Quick actions bento grid**: 3-column grid on `surfaceContainerLow` background, no borders
- **Recent activity feed**: Transactions grouped in a single container card using color-shift separation (no dividers), status dot + uppercase status label, trending icons
- **Nexus Pro promo card**: Asymmetric layout with gradient icon block and upgrade CTA

#### Bottom Navigation (`_SovereignBottomNav`)
- Replaced standard `BottomNavigationBar` with custom glassmorphic nav bar
- Active tab: Electric Blue (#0052FF) pill background, white icon + bold label
- Inactive: `onSurface` at 45% opacity
- BackdropFilter blur 24px + rounded top corners (24px radius)

#### Transactions Screen (`transactions_screen.dart`) — Full Redesign
- Custom header with back button and "Transaction Ledger" title
- Filter pills: Active = Electric Blue filled; Inactive = `surfaceContainerHigh`
- Transactions grouped by date in `surfaceContainerLow` containers with no explicit dividers
- Status dot (green/amber/red) + uppercase status label + related user name
- Amount: credit = `primary` lavender, debit = `onSurface`, failed = line-through grey

#### Send Money Screen (`send_money_screen.dart`) — Full Redesign
- Custom header + gradient step indicator bar
- Recipient lookup card with green success state
- Amount input: Large 46px ExtraBold hero input in `surfaceContainerLow` box
- All form inputs use `surfaceContainerHighest` fill with ghost border
- TCC digit boxes: 6 individual cells using `surfaceContainerHighest`, Electric Blue focus ring
- Primary CTA: Electric gradient button; Secondary: `surfaceContainerHigh` grey
- Success screen: Gradient circle check icon, clean typography

#### Profile Screen (`profile_screen.dart`) — Full Redesign
- Hero header on `surfaceContainerLow` with circular avatar + gradient camera button
- Inline name editing with save/cancel dot buttons
- Stats row: Account Status card + Transaction Ability card with colored icons
- Info sections: `surfaceContainerLow` containers with icon-color-coded rows, no dividers
- Sign Out: Error-tinted ghost button

#### App Theme (`main.dart`) — Updated
- App title changed to `'Nexus Digital'`
- Full `ColorScheme.dark` mapped to Sovereign Vault tokens
- Text theme: ExtraBold (w800) for display/headline, matching design system weights
- `BottomSheetTheme`, `DialogTheme`, `SnackBarTheme` aligned to dark surface containers
- Splash screen redesigned: "NEXUS / DIGITAL BANKING" wordmark with small loader
- Setup and Closed Account screens redesigned to match overall aesthetic
- `systemNavigationBarColor` set to `surfaceContainerLow`

## [2.1.0] - 2026-03-24

### Added
- **Flutter — Transaction Detail Screen**: Tapping any transaction (home or history) opens a detailed view with amount, date, status badge, type, description, related user, and copyable transaction ID.
- **Flutter — Forgot Password Screen**: Full password reset flow accessible from login screen. Gradient header, email input with validation, success state with confirmation, and error handling for invalid emails/rate limits.
- **Flutter — Profile Photo Update**: Camera icon on profile screen now opens a dialog to set a profile picture URL, which persists to Firestore and displays across all screens.
- **Flutter — Forgot Password Link**: "Forgot Password?" link added between password field and Sign In button on login screen.

### Fixed
- **Flutter — Firebase Package Compatibility**: Upgraded all Firebase packages to latest versions compatible with Flutter 3.41.5/Dart 3.11.3:
  - `firebase_core` 2.x → 4.6.0
  - `firebase_auth` 4.x → 6.3.0
  - `cloud_firestore` 4.x → 6.2.0
  - `firebase_storage` 11.x → 13.2.0
  - `google_sign_in` 6.x → 7.2.0
- **Flutter — Google Sign-In 7.x Migration**: Updated auth service for new singleton API (`GoogleSignIn.instance`), `authenticate()` method, and `idToken`-only credential flow.
- **Flutter — CardTheme → CardThemeData**: Fixed Material 3 API rename in main.dart theme configuration.
- **Flutter — Web Platform Support**: Added web platform configuration for Chrome/Edge deployment.

## [2.0.0] - 2026-03-23

### Redesigned — Premium UI Overhaul
- **Admin Panel — Full Visual Redesign**: Upgraded all 14 source files to a premium fintech-grade dashboard aesthetic.
  - Split-screen login with dark gradient branding panel, floating decorative shapes, security badges (256-bit, 99.9%, SOC 2), and clean white form.
  - Dark slate-950 sidebar with gradient logo, lucide-react icons, active indicator bars, and admin role badge.
  - Top header bar in dashboard layout showing current page title and admin email.
  - Dashboard stat cards with distinct gradient backgrounds (blue, amber, rose, emerald) and frosted glass icon containers.
  - Glassmorphism card design with backdrop-blur throughout.
  - Gradient buttons with hover scale and glow effects.
  - Pill-shaped status badges with dot indicators.
  - Focus-glow input fields and styled toggle switches.
  - Custom scrollbar styling and smooth animations (fadeIn, slideUp, slideInLeft).
  - Time Travel badge highlights on transaction pages.
  - Danger zone styling for maintenance mode in system config.
- **Flutter — Full Visual Redesign**: Upgraded all 10 Flutter screens to premium Material 3 design.
  - Premium gradient login screen with bank icon branding and white card form area.
  - Glassmorphism balance card on home screen with decorative overlay and masked account number.
  - Gradient SliverAppBar with greeting, date display, and avatar.
  - Circular quick-action buttons (Send, History, Profile).
  - Step indicator in send money flow with PIN-style TCC input boxes.
  - Date-grouped transaction sections (Today, Yesterday, Earlier) with filter chips and colored accent bars.
  - Profile hero section with gradient background and grouped info cards.
  - Animated pulsing shield icon on suspended screen with support contact card.
  - Animated rotating hourglass and progress dots on pending screen.
  - Premium theme with indigo color scheme, custom text theme, card theme, and input decoration theme.

### Added
- **Flutter — Google Sign-In**: Added `google_sign_in` dependency and `signInWithGoogle()` method in AuthService. Login and register screens now feature "Continue with Google" button.
- **Flutter — Anonymous Login**: Added `signInAnonymously()` method that creates a guest user document in Firestore. Login screen features "Continue as Guest" button.
- **Flutter — Independent Auth Loading States**: Each authentication method (email, Google, anonymous) has its own loading indicator.

## [1.2.0] - 2026-03-23

### Added
- **Firebase Configuration — Admin Panel**: Created `.env.local` with real Firebase project credentials (API key, auth domain, project ID, storage bucket, messaging sender ID, app ID) for the `realbanking` project.
- **Firebase Configuration — Flutter**: Created `firebase_options.dart` with `DefaultFirebaseOptions` supporting all platforms (Web, Android, iOS, macOS, Windows, Linux) using the `realbanking` Firebase project credentials.
- **Flutter — Firebase Initialization**: Updated `main.dart` to use `DefaultFirebaseOptions.currentPlatform` for proper multi-platform Firebase initialization.

## [1.1.0] - 2026-03-23

### Added
- **Admin Panel — Create Transaction Page**: Manually create Credit/Debit transactions for any user with custom timestamp (Time Travel), auto-balance adjustment toggle, and user UID lookup.
- **Admin Panel — Create User Page**: Create new user accounts directly from the dashboard with configurable initial balance, account status, and transaction ability.
- **Admin Panel — System Config Page**: Global configuration panel with maintenance mode, registration toggle, transaction limits (min/max), fee percentage, support contact info, and announcement banner management.
- **Admin Panel — Status Logs Viewer**: Real-time table of all account status transitions (pending → active, active → suspended, etc.) logged by Cloud Functions.
- **Admin Panel — Expanded Sidebar**: Navigation now includes Create Transaction, Create User, Status Logs, and System Config links with appropriate icons.
- **Flutter — Profile Screen**: Editable user profile with inline name editing, account info cards (balance, status, transaction ability, member since), sign-out confirmation dialog.
- **Flutter — Profile Navigation**: Profile icon button added to home screen app bar.
- **Root `.gitignore`**: Comprehensive ignore rules for Node, Flutter, Firebase, IDE, and OS files.
- **Preview Server Config**: `.claude/launch.json` for streamlined dev server management.

## [1.0.0] - 2026-03-23

### Added
- **Project Structure**: Monorepo with `/mobile_app` (Flutter), `/admin_panel` (Next.js), and `/firebase` (shared backend).
- **Firestore Data Architecture**: Users, Transactions, and System Config collections with full schema definitions.
- **Firestore Security Rules**: Role-based access — customers read/write own data; admins have full override via firebase-admin SDK.
- **Cloud Functions**: `onUserCreated` (initializes new user documents), `processTransaction` (handles money transfers with TCC validation), `onAccountStatusChange` (logs status transitions).
- **Admin Panel (Next.js + Tailwind CSS)**:
  - User Oversight: Table view with inline editing of balance and fullName.
  - Time Travel: Edit transaction timestamps from the admin UI.
  - Account Lifecycle: Approve, Suspend, and Close account buttons.
  - Transaction Interception: Toggle to enable/disable a user's ability to send money (`canTransact`).
  - Approval Queue: Dedicated view for new users awaiting account activation.
  - TCC Management: View and regenerate Transaction Confirmation Codes per user.
- **Customer Mobile App (Flutter)**:
  - Real-time UI via `StreamBuilder` listening to user document changes.
  - Transaction flow with 4-6 digit TCC code prompt.
  - Account Suspended overlay that blocks all navigation when `accountStatus == 'suspended'`.
  - Dashboard with balance display, recent transactions, and send money functionality.
  - Firebase Auth integration for session handling.
