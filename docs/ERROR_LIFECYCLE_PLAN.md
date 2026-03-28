# 🔧 Error Lifecycle Tracking — Implementation Plan

> **Date:** March 20, 2026
> **Scope:** Error Logging Service + Admin Errors Screen
> **Files:** `error_logging_service.dart`, `errors_screen.dart`

---

## 📌 Goal

Replace the current flat error list with a **3-category system** that tracks
error lifecycle from occurrence → resolution → recurrence monitoring, giving
the admin full visibility into which errors are truly fixed vs coming back.

---

## 🎨 Three Categories (Color-Coded Sections)

| # | Section | Color | Meaning |
|---|---------|-------|---------|
| 1 | **Active Errors** | 🔴 Red/Default (current) | Unresolved errors needing attention |
| 2 | **Resolved Now** | 🟢 Green container | Freshly resolved — admin just marked these as fixed |
| 3 | **Previously Resolved** | 🟡 Yellow/Amber container | Resolved in the past — monitoring for recurrence |

### Visual Layout (top → bottom)

```
┌─────────────────────────────────────────┐
│  Health Card (existing)                 │
├─────────────────────────────────────────┤
│  Uptime Trend (existing)                │
├─────────────────────────────────────────┤
│  Filter Bar (updated)                   │
├─────────────────────────────────────────┤
│                                         │
│  🔴 ACTIVE ERRORS (12)                  │  ← Red section header
│  ┌─ Error Card (white bg) ────────────┐ │
│  │ ⚠ [cloud_firestore/permission...]  │ │
│  │ ID: 8fnsvw · WEB · /notifications  │ │
│  │ 🔁 Recurring badge (if applicable) │ │
│  └────────────────────────────────────┘ │
│  ┌─ Error Card ───────────────────────┐ │
│  │ ...                                │ │
│  └────────────────────────────────────┘ │
│                                         │
│  🟢 RESOLVED NOW (3)                    │  ← Green section header
│  ┌─ Error Card (green tint bg) ───────┐ │
│  │ ✅ [firebase_messaging/token...]    │ │
│  │ ID: k2m8xp · Resolved 2h ago      │ │
│  │ Status: [Resolved ▼]              │ │
│  └────────────────────────────────────┘ │
│                                         │
│  🟡 PREVIOUSLY RESOLVED (8)             │  ← Yellow section header
│  ┌─ Error Card (amber tint bg) ───────┐ │
│  │ ☑ [cloud_firestore/unavailable]    │ │
│  │ ID: 3pw9vn · Resolved 5d ago      │ │
│  │ Status: [Never Recurred ▼]        │ │
│  └────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🔘 Three Resolution Status Options (Dropdown on Resolved Cards)

When an error is in the **Resolved Now** or **Previously Resolved** section,
the admin can tap the status dropdown in the card header to change its state:

| Option | Stored Value | When to Use | UI Effect |
|--------|-------------|-------------|-----------|
| **Resolved** | `resolved` | Default after clicking "Mark Resolved" | Card stays in green/yellow section |
| **Resolved but Recurred Again** | `recurred` | Admin sees the error has come back | Card moves back to 🔴 Active section, tagged with 🔁 badge |
| **Never Recurred** | `never_recurred` | Admin confirms error is permanently fixed | Card stays in 🟡 section, gets ✅✅ double-check badge |

### Status Flow Diagram

```
                    ┌──────────┐
    New error ────▶ │  ACTIVE  │ (red, unresolved)
                    └────┬─────┘
                         │
              Admin clicks "Mark Resolved"
                         │
                         ▼
                ┌────────────────┐
                │ RESOLVED NOW   │ (green, < 24h old)
                │ status=resolved│
                └───────┬────────┘
                        │
           After 24h auto-moves to ──────────────┐
                        │                         │
                        ▼                         ▼
          ┌──────────────────────┐   ┌────────────────────────┐
          │ PREVIOUSLY RESOLVED  │   │ PREVIOUSLY RESOLVED    │
          │ status=resolved      │   │ status=never_recurred  │
          │ (yellow, monitoring) │   │ (yellow, confirmed ✅✅)│
          └──────────┬───────────┘   └────────────────────────┘
                     │
         Admin selects "Recurred Again"
                     │
                     ▼
              ┌──────────┐
              │  ACTIVE  │ (red, 🔁 Recurring badge)
              │ resolved │
              │ =false   │
              └──────────┘
```

---

## 📐 Phase 1 — Data Layer Changes

### File: `lib/core/services/error_logging_service.dart`

### 1.1 New Enum: `ResolutionStatus`

```dart
enum ResolutionStatus {
  unresolved,      // Active error (default)
  resolved,        // Admin marked as resolved
  recurred,        // Was resolved, but came back → moves to Active
  neverRecurred,   // Confirmed permanently fixed
}
```

### 1.2 New Fields on `ErrorLogEntry`

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `resolvedAt` | `DateTime?` | `null` | Timestamp when admin resolved it |
| `resolutionStatus` | `ResolutionStatus` | `unresolved` | Current lifecycle status |
| `isRecurring` | `bool` | `false` | Auto-detected: same hash appeared after previous resolution |
| `previouslyResolvedAt` | `DateTime?` | `null` | When was the last resolution before it recurred |

Update: `toFirestore()`, `fromFirestore()`, `toCopyText()`

### 1.3 New Meta Document for Recurrence Detection

**Path:** `error_logs_meta/resolved_hashes`

```json
{
  "8fnsvw": { "resolvedAt": <Timestamp>, "status": "resolved" },
  "k2m8xp": { "resolvedAt": <Timestamp>, "status": "never_recurred" },
  ...
}
```

- Written by `markResolved()` and `updateResolutionStatus()`
- Read by `logError()` to detect recurrence
- In-memory cache with 5-minute refresh to avoid extra Firestore reads

### 1.4 Update `logError()`

After generating `errorHash`:
1. Check in-memory cache of resolved hashes
2. If hash found → set `isRecurring: true`, `previouslyResolvedAt: <timestamp>`
3. Log to Firestore with these fields populated

### 1.5 Update `markResolved(docId)` and `markAllResolvedByHash(hash)`

Change from:
```dart
{ 'resolved': true }
```

To:
```dart
{
  'resolved': true,
  'resolvedAt': FieldValue.serverTimestamp(),
  'resolutionStatus': 'resolved',
}
```

Also write to `error_logs_meta/resolved_hashes`:
```dart
{ errorHash: { 'resolvedAt': FieldValue.serverTimestamp(), 'status': 'resolved' } }
```

### 1.6 New Method: `updateResolutionStatus(docId, hash, status)`

```dart
static Future<void> updateResolutionStatus(
  String docId,
  String errorHash,
  ResolutionStatus status,
) async {
  // If status == recurred:
  //   → Set resolved=false, resolutionStatus='recurred', isRecurring=true
  //   → Remove hash from resolved_hashes meta doc
  //
  // If status == neverRecurred:
  //   → Keep resolved=true, resolutionStatus='never_recurred'
  //   → Update meta doc status to 'never_recurred'
  //
  // If status == resolved:
  //   → Keep resolved=true, resolutionStatus='resolved'
}
```

### 1.7 Update `GroupedError` Model

| New Field | Type | Source |
|-----------|------|--------|
| `isRecurring` | `bool` | Any entry in group has `isRecurring == true` |
| `resolvedAt` | `DateTime?` | Latest entry's `resolvedAt` |
| `resolutionStatus` | `ResolutionStatus` | Latest entry's status |

### 1.8 Update `getGroupedErrors()`

- Remove `hideResolved` parameter — always fetch all (client-side sectioning)
- Add `resolutionStatus` to `fromFirestore` parsing
- Populate new GroupedError fields

---

## 🎨 Phase 2 — UI Changes

### File: `lib/features/super_admin/screens/errors_screen.dart`

### 2.1 Remove `_hideResolved` State

Replace with always showing all three sections (each collapsible).

### 2.2 Split Errors into 3 Lists

```dart
final active = filtered.where((g) =>
    !g.latestEntry.resolved || g.resolutionStatus == ResolutionStatus.recurred
).toList();

final resolvedNow = filtered.where((g) =>
    g.latestEntry.resolved &&
    g.resolutionStatus == ResolutionStatus.resolved &&
    g.resolvedAt != null &&
    DateTime.now().difference(g.resolvedAt!).inHours < 24
).toList();

final previouslyResolved = filtered.where((g) =>
    g.latestEntry.resolved &&
    (g.resolutionStatus == ResolutionStatus.resolved ||
     g.resolutionStatus == ResolutionStatus.neverRecurred) &&
    (g.resolvedAt == null || DateTime.now().difference(g.resolvedAt!).inHours >= 24)
).toList();
```

### 2.3 Section Headers

```
🔴 Active Errors (12)        — Red accent bar, white background
🟢 Resolved Now (3)          — Green accent bar, green-tinted background
🟡 Previously Resolved (8)   — Amber accent bar, amber-tinted background
```

Each header is tappable to expand/collapse the section.

### 2.4 Card Color Coding

| Section | Card Background | Left Border |
|---------|----------------|-------------|
| Active (new) | `cs.surface` (default white) | 4px severity color |
| Active (recurring 🔁) | `Colors.amber.shade50` | 4px amber |
| Resolved Now | `Colors.green.shade50` | 4px green |
| Previously Resolved | `Colors.amber.shade50` | 4px amber |
| Previously Resolved (never recurred) | `Colors.green.shade50` | 4px green, ✅✅ badge |

### 2.5 Error ID Badge (Visible on Every Card)

In the subtitle row, after platform icon:

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
  decoration: BoxDecoration(
    color: cs.surfaceVariant,
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(
    'ID: ${e.errorHash ?? "—"}',
    style: TextStyle(
      fontFamily: 'monospace',
      fontSize: 9,
      color: cs.onSurfaceVariant,
    ),
  ),
)
```

Tapping copies the ID to clipboard.

### 2.6 Resolution Status Dropdown (On Resolved Cards Only)

Replaces the current "Resolved" chip. Shows in the card's action row:

```dart
DropdownButton<ResolutionStatus>(
  value: group.resolutionStatus,
  items: [
    DropdownMenuItem(
      value: ResolutionStatus.resolved,
      child: Row(children: [
        Icon(Icons.check_circle, color: Colors.green, size: 16),
        SizedBox(width: 6),
        Text('Resolved'),
      ]),
    ),
    DropdownMenuItem(
      value: ResolutionStatus.recurred,
      child: Row(children: [
        Icon(Icons.replay, color: Colors.orange, size: 16),
        SizedBox(width: 6),
        Text('Resolved but Recurred Again'),
      ]),
    ),
    DropdownMenuItem(
      value: ResolutionStatus.neverRecurred,
      child: Row(children: [
        Icon(Icons.verified, color: Colors.green.shade800, size: 16),
        SizedBox(width: 6),
        Text('Never Recurred'),
      ]),
    ),
  ],
  onChanged: (status) => _updateStatus(group, status),
)
```

### 2.7 Recurring Badge (On Active Cards)

When `isRecurring == true`:

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: BoxDecoration(
    color: Colors.amber.shade100,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.amber.shade400),
  ),
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.replay, size: 12, color: Colors.amber.shade800),
    SizedBox(width: 3),
    Text('Recurring', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
  ]),
)
```

Tooltip: `"Previously resolved on {date}, but reappeared"`

### 2.8 Filter Bar Update

Replace the `Hide Resolved` toggle with:

```
[All] [Android] [Web] [Windows]   [Critical] [Error] [Warning]   [Recurring]
```

- New **Recurring** filter chip: shows only errors where `isRecurring == true`
- Sections themselves handle resolved/unresolved visibility

### 2.9 "Mark Resolved" Button (Active Cards Only)

Keep existing button. On tap:
1. Call `markResolved()` (now writes `resolvedAt` + meta doc)
2. Card animates → moves to "Resolved Now" (green) section
3. Refresh provider

---

## 🗄️ Phase 3 — Firestore Rules

**No changes needed.** The existing rules already cover:
- `error_logs/{docId}` — create (auth), read/update/delete (admin)
- `error_logs_meta/{docId}` — create/update (auth), read/delete (admin)

---

## 📊 Summary of Changes

### `lib/core/services/error_logging_service.dart`

| Change | Lines (est.) |
|--------|-------------|
| Add `ResolutionStatus` enum | +8 |
| Add 4 new fields to `ErrorLogEntry` | +12 |
| Update `toFirestore()` | +4 |
| Update `fromFirestore()` | +8 |
| Update `toCopyText()` | +6 |
| Update `GroupedError` model | +6 |
| Resolved-hashes cache + recurrence check in `logError()` | +35 |
| Update `markResolved()` + `markAllResolvedByHash()` | +15 |
| New `updateResolutionStatus()` method | +40 |
| Update `getGroupedErrors()` | +10 |
| **Total** | **~144 lines** |

### `lib/features/super_admin/screens/errors_screen.dart`

| Change | Lines (est.) |
|--------|-------------|
| Remove `_hideResolved`, add section collapse state | +5 |
| 3-way list split logic | +20 |
| Section header widgets (3×) | +45 |
| Card background/border color logic | +20 |
| Error ID badge on every card | +15 |
| Resolution status dropdown | +40 |
| Recurring badge | +20 |
| Filter bar: add Recurring chip, remove Hide Resolved | +8 |
| `_updateStatus()` action method | +20 |
| **Total** | **~193 lines changed** |

### No New Files Needed

---

## ✅ Acceptance Criteria

1. ✅ Active errors appear in **red/default** section at top
2. ✅ Clicking "Mark Resolved" moves error to **green "Resolved Now"** section
3. ✅ After 24h, resolved errors auto-shift to **yellow "Previously Resolved"** section
4. ✅ Every card shows a visible **Error ID** (e.g., `ID: 8fnsvw`)
5. ✅ Resolved cards have a dropdown with three options:
   - **Resolved** — stays in resolved section
   - **Resolved but Recurred Again** — moves back to Active with 🔁 badge
   - **Never Recurred** — stays resolved with ✅✅ confirmed badge
6. ✅ If the same `errorHash` appears after resolution, it auto-tags as `isRecurring`
7. ✅ Recurring errors show a 🔁 amber badge so admin can tell old vs new
8. ✅ Filter bar includes a "Recurring" chip to find comeback errors quickly
