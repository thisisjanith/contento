# Contento

Internal app for **Tappyly Technologies** that manages the content team's day-to-day writing work: employees write Facebook post captions/descriptions against anonymized briefs, and admins review, approve/reject, schedule, and track the whole pipeline.

**Built with Flutter (Dart)** — one codebase targeting iOS, Android, and desktop web (Windows/Mac). This file is the project brief for implementation. The visual reference (all screens, states, and copy — web layout plus native-styled iOS and Android variants) lives in the companion Design canvas — build to match it pixel-for-pixel unless noted otherwise below.

## Core idea

Employees must **never** see which client or Facebook page their writing is actually going to. They only ever see anonymized, generic work items. Nothing in the UI — labels, filenames, placeholder text, anything — may reveal a real client/page name to an employee.

## Platforms & adaptive UI

Single Flutter app, three shells:

- **iOS** — Cupertino-flavored chrome: large titles, pill segmented control (Posts/Submissions), grouped list with chevrons and inset separators, plain-tint bottom tab bar (no active-pill background), push navigation with a leading back chevron + centered title.
- **Android** — Material chrome: elevated `AppBar` with shadow, underlined `TabBar`, elevated `Card`s with `Chip`-style status badges, `NavigationBar`/bottom nav with a pill/capsule indicator behind the active icon, filled pill-shaped buttons with uppercase labels, Material filled-text-field style inputs (floating label, bottom indicator border).
- **Web (desktop, Windows/Mac)** — the wide sidebar layout: persistent left nav, multi-column content, tables/queues for admin. This is the "full" experience and where the admin console lives.

Use `Platform.isIOS` / `kIsWeb` (or a `TargetPlatform`-aware adaptive widget layer) to switch chrome per platform rather than hand-rolling one look-and-feel everywhere — the Design canvas's iOS and Android boards are the literal reference for what each native shell should look like; the desktop/web boards are the reference for the wide layout. **Do not use Roboto or the default Material/Cupertino system font** — see Design system below, the brand fonts stay constant across all three shells; only chrome/layout idioms should differ per platform.

Screen coverage in the canvas:
- Web: Login, Admin (Overview, New Project, Content Calendar), Employee (My Project, Post detail, My Submissions, My Calendar), Employee mobile-web fallback.
- iOS: My Project, Post Detail, My Submissions, My Calendar (full employee flow).
- Android: My Project, Post Detail, My Submissions, My Calendar (full employee flow).

Note: iOS/Android boards currently cover the **employee flow only** (that's the surface area interns/employees touch day to day on their phones). Admin is desktop/web-first — if a native admin view is ever needed, extend the same Material/Cupertino adaptive pattern to the Overview/Queue/Calendar screens.

## Data model & terminology

This is the one thing to get right before writing any code — every screen depends on it.

- **Employee** — a content writer (formerly called "intern" in early drafts; the product now uses "Employee" everywhere, both in UI copy and in code/DB naming).
- **Admin** — reviews and manages the pipeline; not anonymized, sees everything.
- **Project** — the top-level container. **Each project belongs to exactly one employee** (one project ↔ one employee, 1:1). A project has a number (`Project #12`), a generic title (e.g. "Wildlife & Recovery Series"), and is what an admin creates and assigns.
- **Post** — an individual piece of work *under* a project. A project can contain many posts over time. Each post has its own number (`Post #133`), title, source brief, due date, status, and submission. This is the unit an employee actually opens, writes, and submits.

Display convention: `Project #12 · Post #133 — Wildlife topic`. Admin views usually show both numbers; employee views show the project once (as context/banner) and then just posts.

### Post status

Four states, color-coded consistently everywhere (web, iOS, Android):

| Status | Meaning | Color |
|---|---|---|
| Pending | Assigned, not yet started/submitted | Neutral gray |
| Submitted | Employee submitted, awaiting admin review | Indigo (primary) |
| Needs Revision | Admin sent it back with feedback | Orange (accent) |
| Approved | Admin approved | Green |

Admin can additionally mark an approved post **Scheduled** once it's been manually posted live (a simple checkbox/toggle on the row — this app does not auto-post to Facebook).

## Roles & screens

### Auth
- Single login screen, email + password, with an Employee/Admin toggle that determines which dashboard loads after sign-in. No self-serve signup — accounts are provisioned by an admin (out of scope for UI, just note it in a "forgot password? contact your admin" line). Web-only for now; native shells assume an already-issued session (add a native login later if needed).

### Employee
- **My Project** (dashboard/home) — shows a banner for the employee's one active project, then a list of posts under it (status badge, due date, "Source brief attached" indicator, Open/View/Revise action). This is the daily-use screen — optimize for minimal taps to get into a post. Native: grouped list (iOS) / elevated cards (Android).
- **Post detail / submission form** — opened from a post card. Reference material section (source link, fact-check notes, style notes) supplied by the admin, read-only. Submission section: caption/description text field with a live character counter, optional image upload, optional notes-to-reviewer field, Save Draft / Submit for Review actions. Native: sticky bottom action bar with Submit + Save Draft.
- **My Submissions** — history of everything the employee has turned in, with status and, for anything sent back, the admin's feedback inline plus a "Revise" shortcut back into the post.
- **My Calendar** — month view of just this employee's own posts (their one project), plotted by due date. Web: full grid with text chips. Native (narrower width): compact dot-indicator grid + a scrollable "Upcoming" agenda list below it, since a 390–412px screen can't fit text chips per cell.
- Web also needs a responsive/mobile fallback layout (bottom tab bar instead of sidebar) for browser use on a phone, independent of the native iOS/Android apps.

### Admin (web only)
- **Overview** — top-line stats (pending review count, approved this week, needs-revision count, active employees) + a submissions queue: a filterable, expandable table (filter by status / employee / date) where each row expands to show the full caption, image preview, source link, and the employee's name, with Approve / Reject (+ feedback textbox) / Edit-inline actions right there. A "Mark as Scheduled" checkbox appears on approved rows. This should feel like a queue you can clear quickly, not a chore — minimize clicks per review decision.
- **New Project** — the creation form for a project. One employee per project (single-select assignment, not multi-select — this is a common bug risk if copied from a "multi-assign" pattern). Captures: project title, assigned employee, source link/brief, first post due date, content batch/category. Shows a live "what the employee will see" preview so admins can sanity-check that nothing identifying leaked into the title/brief.
- **Content Calendar** — month view across *all* employees/projects, posts plotted by due date, color-coded by status, with employee name shown per event chip (unlike the employee's own calendar, which omits names since it's already scoped to one person).
- (Sidebar also lists Submissions Queue / Employees / Settings as nav destinations — Employees and Settings are not yet designed in detail; treat as straightforward list/CRUD screens when built.)

## Design system

- **Primary (dominant UI color):** Indigo `#5B4FE5` — buttons, links, active nav state, submitted-status color.
- **Accent (use sparingly):** Warm orange `#F2703C` — only for things that need attention: Needs Revision badges, revision feedback callouts, notification dots. Do not use as a general primary color.
- **Text / dark:** `#1E2140`
- **Background:** warm off-white `#F8F6F1` (not pure white/gray) with `#FFFFFF` cards on top.
- **Approved:** green `#1F8A4C` / `#2FAE64` (not a brand color, used only for the status semantic).
- **Type:** Space Grotesk for headings/display, IBM Plex Sans for body/UI — deliberately not Inter/Roboto/Arial/system-default. Bundle both as Flutter fonts (`pubspec.yaml` `fonts:` section) and apply them in `ThemeData`/`CupertinoThemeData` so they're consistent across all three shells — don't fall back to platform default fonts on iOS/Android.
- Rounded corners (~9–14px), no heavy shadows (Android cards use a light `boxShadow`/elevation ~1-3, not deep Material default shadows), no left-border cards, no gradients — flat, warm, minimal.

## Suggested stack & structure

Flutter (Dart), single codebase, adaptive per platform via a thin platform-detection layer rather than separate apps.

```
/lib
  /app.dart              – MaterialApp/CupertinoApp switch, theming, routing
  /theme
    colors.dart           – brand palette + status color map
    typography.dart       – Space Grotesk / IBM Plex Sans text themes
    adaptive.dart          – platform-detection helpers (isIOS/isAndroid/isWeb/isDesktop)
  /auth
    login_screen.dart      – web-first login, role-based redirect
  /employee
    project_home_screen.dart      – "My Project" (adaptive: Cupertino list / Material cards / web table)
    post_detail_screen.dart       – submission form (adaptive chrome, shared form logic)
    my_submissions_screen.dart
    my_calendar_screen.dart       – adaptive: full grid (web) / dot-grid + agenda (native)
  /admin
    overview_screen.dart          – stats + submissions queue (web only)
    new_project_screen.dart
    content_calendar_screen.dart
    employees_screen.dart         – (stub)
    settings_screen.dart          – (stub)
  /widgets
    status_badge.dart      – one shared status-color component, used everywhere
    post_card.dart
    project_banner.dart
    calendar_grid.dart
    adaptive_scaffold.dart – picks Cupertino/Material/web sidebar shell per platform
  /models
    employee.dart
    project.dart
    post.dart
  /state                   – Riverpod/Provider/Bloc (pick one; Riverpod recommended for
                              this kind of role-gated, multi-shell app)
```

Data model sketch (for whatever backend/DB is chosen — Dart classes should mirror this 1:1):

```
Employee   { id, name, email, role }
Project    { id, number, title, employeeId, sourceBrief, createdAt }
Post       { id, number, projectId, title, dueDate, status, caption, imageUrl, notes, feedback, scheduled }
```

## Shared UI requirements

- Adaptive navigation shell: persistent sidebar on web/desktop, bottom tab bar on iOS/Android — built once as `adaptive_scaffold.dart`, not reimplemented per screen.
- Toast/snackbar notifications for key actions (submitted, approved, rejected, scheduled) — `SnackBar` on Android/web, a Cupertino-style transient banner on iOS (don't use Material `SnackBar` verbatim on iOS, it reads as un-native).
- Status badges: one shared `StatusBadge` widget with the color mapping from the table above — consumed by every screen on every platform, never reimplemented.
- Responsive layout on web (must work down to a mobile browser width) plus genuinely native-feeling iOS/Android shells — not just a shrunk web view.
- Accessible by default: semantic widgets (`ElevatedButton`, `TextButton`, `TextField` + label, not bare `GestureDetector`s pretending to be buttons), minimum 44x44 tap targets, `Semantics`/`tooltip` labels on icon-only buttons.

## Reference

The Design canvas alongside this file contains high-fidelity mockups of every screen listed above — web/desktop layout, plus dedicated native-styled iOS and Android boards for the employee flow — with real sample data, so treat it as the source of truth for layout, copy tone, and exact spacing/color per platform. This document is the "why" and the data model; the canvas is the "what it looks like," broken out by shell.
