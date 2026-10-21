# Rescu Assessment Solutions

## 1. Per Ticket / Feature Solutions

### RES-101 · Search shows results for the wrong query

- **Root Cause:**
  Caused by an **Asynchronous Race Condition** in the search function when a user types text rapidly (**Rapid Typing / Keystroke Burst**), triggering multiple overlapping **Asynchronous Requests**. Due to varying latencies in the simulated network layer, earlier requests (**Stale Requests**) finished processing after newer requests and overwritten the current search results via `results.assignAll(found)`, leading to **UI Inconsistency**.

- **Why this fix is correct & Alternatives considered:**
  - _Chosen Approach (Latest Query Tracking Mechanism):_
    Added an internal state variable (`_latestQuery`) to record a snapshot of the latest query and implemented a **Response Guard** (`if (_latestQuery == trimmedQuery)`) to verify state validity before updating the Reactive State (`RxList`). This guarantees **Data Integrity** without altering the underlying network structure and maintains smooth **UI Responsiveness**.
  - _Rejected Alternatives:_
    - **Loading Lock / Request Throttling:** Blocking user input until the pending request completes. Rejected because it negatively impacts **User Experience (UX)** by making the app feel sluggish.
    - **RxDart `switchMap` / Debounce Operator:** While powerful in reactive architectures, it adds unnecessary complexity for this scope. Tracking queries inside the controller is more **Cost-effective** and simplifies **Stream Subscription** management.

- **Edge Cases:**
  - **Empty Query / Fast Deletion:** When a user rapidly deletes search text resulting in an **Empty String**, the system clears cached results (`results.clear()`) and resets state (`hasSearched` and `isLoading`) immediately to prevent **Memory Leaks** and stale UI data.

---

### RES-102 · App crashes after leaving My Orders screen

- **Root Cause:**
  Caused by a **Lifecycle Mismatch / Asynchronous Gap** and a **Zombie Timer (Memory Leak)** inside the `PickupCountdown` sub-widget. Opening the Orders screen initiates a `Timer.periodic` to trigger screen refreshes every second (`setState()`). When navigating away quickly, the widget is **Disposed** without cancelling the timer. Consequently, the timer continues running in the **Background**, attempting to invoke `setState()` on a destroyed widget, causing a crash with `setState() called after dispose()`.

- **Why this fix is correct & Alternatives considered:**
  - _Chosen Approach:_
    Declared a `Timer?` reference variable inside the State Class, added a cancellation call (`_timer?.cancel()`) in `dispose()`, integrated a **Mounted Guard** (`if (!mounted) return`) before invoking `setState()`, and added `if (isClosed) return` checks in `OrdersController`. This halts background execution, resolves **Memory Leaks**, and ensures **UI Lifecycle** stability.
  - _Rejected Alternatives:_
    - **Checking `mounted` without Cancelling the Timer:** Prevents crashes during `setState()`, but leaves the timer running in a loop, consuming **CPU** and causing ongoing **Memory Leaks**.
    - **Wrapping with `try-catch`:** Masks symptoms without addressing the root cause or stopping memory leaks.

- **Edge Cases:**
  - **Rapid Screen Toggling:** Rapidly navigating in and out of the Orders screen is handled safely by cancelling existing timer references in `dispose()`, preventing **Multiple Active Timers / Zombie Timers** from accumulating in memory.

---

### RES-103 · Requests accumulate over time while browsing

- **Root Cause:**
  Caused by a **Ghost Listener / Unremoved Reactive Worker** inside `DealDetailsController`. In `onInit()`, a listener was bound to a global service (`cartService.itemCount`) via `ever(...)` to re-check stock in **Real-time**. Leaving the Deal Details screen destroys the controller via `onClose()` without **Unregistering / Disposing** the worker, leaving a **Zombie Controller / Ghost Listener** in memory. Subsequent cart changes triggered bursts of `GET /deals/:id` requests (fetching every deal viewed throughout the session), causing request accumulation and performance degradation.

- **Why this fix is correct & Alternatives considered:**
  - _Chosen Approach:_
    Declared a worker reference (`Worker? _cartWorker`) and added a disposal call (`_cartWorker?.dispose()`) in `onClose()`. This unbinds the listener immediately upon closing the screen, prevents **Memory Leaks**, and eliminates request accumulation while maintaining **Real-time** stock updates.
  - _Rejected Alternatives:_
    - **Removing `ever` and Fetching Data Once On Open:** Eliminates lingering listeners but violates the **Business Requirement** to display up-to-date stock whenever the cart changes (preventing **Stale Data**).

- **Edge Cases:**
  - **Rapid Navigation:** Rapidly switching between deal screens is handled cleanly by disposing workers in `onClose()`, preventing **Multiple Accumulated Requests**.

---

### RES-104 · Duplicate deals shown in home feed

- **Root Cause:**
  Caused by **Pagination Concurrency / Concurrent Pagination Requests** in `HomeController`. While scrolling down to load more data (`loadMore()`) and awaiting network responses (`await dealRepo.fetchDeals(page: _page)`), real-time backend updates or order re-shuffling caused items on subsequent pages to overlap with previously loaded pages. Appending them directly via `deals.addAll(res.items)` resulted in duplicate deal cards on the feed.

- **Why this fix is correct & Alternatives considered:**
  - _Chosen Approach (Client-side Deduplication):_
    Added a client-side deduplication check before appending items to the reactive list. Verified existing unique identifiers (`deal.id`) from `existingIds` and filtered out duplicates (`uniqueNewItems`) before calling `deals.addAll(...)`. This ensures clean client-side data without relying solely on the backend.
  - _Rejected Alternatives:_
    - **Relying Solely on Backend Ordering:** In real-time streaming or deal systems, pagination overlaps can occur. A client-side guard provides the safest defense.

- **Edge Cases:**
  - **Rapid Scrolling:** Rapidly scrolling up and down the feed is protected by deduplication, preventing duplicate items from leaking into the UI.

---

### RES-105 · Home feed janky and memory usage grows over time

- **Root Cause:**
  Caused by **Excessive Rebuilds** and **Unbounded Memory Allocations** on the UI side—specifically wrapping `Obx` broadly around `Scaffold` in `HomeScreen`. Every scroll event (`scrollOffset` change) forced all widgets on the screen to rebuild continuously, overloading the **UI Thread** past frame budgets (>16.6ms), resulting in **Jank (Frame Drops)** and heavy Garbage Collection (GC) activity that continuously inflated memory usage.

- **Performance Comparison (Flutter DevTools):**
  - **Before Fix (Janky Frame Drops):**
    ![Before Fix Performance](./assets/screenshots/old_code_jank.png)
  - **After Fix (Optimized Render):**
    ![After Fix Performance](./assets/screenshots/new_code_smooth.png)

- **Why this fix is correct & Alternatives considered:**
  - _Chosen Approach (UI Optimization & Scoped Reactivity):_
    Narrowed `Obx` scopes strictly to reactive elements, optimized layout rendering structures, added `const` constructors for static widgets, and configured image cache limits to manage heap memory.
  - _Rejected Alternatives:_
    - **Fixing Only Controller Logic:** Insufficient, as the root cause of dropped frames stems from excessive UI widget rebuilds.

- **Edge Cases:**
  - **Rapid Fling Scrolling:** Rapid flinging is maintained cleanly through lazy loading and reduced rebuilds, preserving smooth frame rates.

---

### RES-106 · Wrong pickup times; "Pickup today" filter misses deals

- **Root Cause:**
  Caused by a **Timezone Mismatch (UTC vs Local Time)** and imprecise date comparison logic. `DateTime.parse()` converted ISO-8601 UTC strings from the backend (ending in `Z`) into UTC `DateTime` instances without adjusting to local time (`.toLocal()`). This shifted `start` and `end` times by local offset hours (e.g., UTC+7 in Thailand). Additionally, `isToday` checked only the `day` integer (`start.day == DateTime.now().day`) without matching year and month, miscalculating pickup days and incorrectly filtering out valid deals.

- **Why this fix is correct & Alternatives considered:**
  - _Chosen Approach (Local Time Conversion & Strict Date Matching):_
    Applied `.toLocal()` immediately upon parsing JSON dates in `PickupWindowModel` to match device local time zones, and updated `isToday` to validate `year`, `month`, and `day`. This displays accurate local pickup windows and ensures 100% filter accuracy without requiring backend modifications.
  - _Rejected Alternatives:_
    - **Requiring Backend Local Time Strings:** Prohibited by project guidelines against modifying backend files (`fake_api_service.dart` or original data schemas).
    - **Hardcoding Timezone Offsets (+7 Hours):** Fragile and limited to Thailand. Breaks when changing timezones or running internationally. Using Dart's `.toLocal()` is standard and robust.

- **Edge Cases:**
  - **Midnight Crossings / Late Night Deals:** Deals spanning across midnight are properly evaluated by comparing full year, month, and day fields.

---

### RES-107 · Deep link opens to a crash

- **Root Cause:**
  Caused by **Missing Route Arguments / State Mismatch**. Opening a deal from the homepage passes data via `arguments` (`Get.toNamed(..., arguments: deal)`), allowing the details screen to parse it immediately. Opening via Deep Links (e.g., push notifications or `rescu://open/deal?id=42&source=push`) navigates via URL parameters without an attached object. `Get.arguments` evaluates to `null`, and casting it directly (`Get.arguments as DealModel`) throws `type 'Null' is not a subtype of type 'DealModel'`, crashing the app in debug builds.

- **Why this fix is correct & Alternatives considered:**
  - _Chosen Approach (Fallback Data Fetching & Dual-source Resolution):_
    Updated `DealDetailsController` and `DealDetailsScreen` to support both pathways. If `Get.arguments` exists, it uses the passed object. If `null`, it extracts the `id` from route or query parameters (`?id=42`) and fetches data via `dealRepo.fetchById(dealId)` into a reactive state (`Rxn<DealModel>`) with loading indicators (`isLoading`). This resolves deep links safely and meets requirements.
  - _Rejected Alternatives:_
    - **Displaying an Error or Fallback Screen:** Violates project requirements stating error/fallback screens are unacceptable solutions; deep links must land on a working deal page.
    - **Forcing Object Payloads over Deep Links:** Technically impossible for external deep link launchers (e.g., push notifications or URL intents).

- **Edge Cases:**
  - **Invalid or Expired Deal ID:** If an invalid deal ID is provided, errors are caught gracefully, displaying a user-friendly error message within the screen without crashing.

---

## [F-1] Live Flash-Sale Countdowns

### Problem

1. **Live Countdown & Persistence:** Countdown timers must sync with real time (`DateTime.now()`) so remaining durations remain accurate upon re-opening the app or switching screens.
2. **Expired Deal Handling:** Expired flash deals (`Expired`) must disable purchasing/adding to bag, and any expired items remaining in the bag must be removed automatically with clear notifications.
3. **UI & State Render Bug:** Removing cart items or triggering `Get.snackbar` during widget build phases causes `ErrorSummary` build exceptions and unnecessary rebuild loops.

### Solution

1. **Absolute Time Comparison:** Calculated remaining durations by comparing `flashSaleEndsAt` with `DateTime.now()` inside a `Timer.periodic` within `FlashCountdownBadge`, guaranteeing precise timer updates across app lifecycle states.
2. **Controller-Level Initialization:** Executed expired item cleanup in `CartController.onInit()` using `Future.microtask` to safely remove expired items and display alerts outside active `build` frames.
3. **UI State & Action Lockdown:** Updated `DealDetailsScreen` and `CartScreen` to disable purchase buttons and style card backgrounds in grey tones upon expiry, preventing transactions on expired deals.

---

## [F-2] Impression Tracking with Batch Analytics

### Problem

1. **Visibility & Tracking:** Required view analytics tracking on deal cards in `HomeScreen` without duplicate logging (`Deduplication`) within the same session.
2. **Network Optimization (Batching):** Dispatching analytics single-item HTTP requests overheads network resources during fast scrolling.

### Solution

1. **Visibility Detection:** Wrapped `DealCard` with `visibility_detector` configured with `visibleFraction >= 0.5` to track impressions once a card is at least 50% visible for 1 second continuously.
2. **Controller-Level Queue & Batching:**
   - Tracked impression state via `_trackedImpressions` (Set) to avoid duplicates.
   - Built a queue (`_pendingAnalyticsEvents`) capped at **10 events** (`_batchSize = 10`).
   - Dispatched events via `DealRepo.sendAnalyticsBatch` to `FakeApiService.sendAnalyticsBatch`.
   - Flushed unsent queued events automatically upon refresh or screen closure (`onClose`) via `_flushAnalyticsBatch()`.

---

## [F-3] Stock Reservations with Optimistic UI & Automatic Rollback

### Problem

1. **Perceived Latency & Slow UX:** Waiting for synchronous network responses (350-1100ms latency) before updating UI state makes the app feel sluggish.
2. **Race Condition & Overbooking:** When stock is contended, server-side reservation attempts may fail with 409 Conflict/Out of Stock errors, requiring client-side state reconciliation.
3. **State Consistency:** Failed backend reservations require rolling back on-screen stock counts and removing items from the cart automatically while notifying the user.

### Solution

1. **Optimistic UI Pattern:**
   - Added `copyWith` to `DealModel` for instant local `quantityLeft` state mutation.
   - Updated UI on `DealDetailsScreen` and added items to `CartService` immediately without waiting for network responses.
2. **Background API & Reservation Association:**
   - Initiated `reserveDeal` API calls in the background with `isReserving` guards to prevent double-tapping.
   - Attached reservation details (`reservation`) to `CartItemModel` in the cart for checkout processing.
3. **Automatic Rollback & Error Handling:**
   - Caught `ApiException` on reservation failures, restored original `quantityLeft` state, removed items via `cartService.remove(deal.id)`, and displayed server error messages via snackbars.

### Underspecified Product Decision

- **Scenario:** Reservation expires (duration > 5 minutes) while the user is actively in the app or preparing for checkout.
- **Decision:** Display an explicit "Reservation expired" banner on cart item cards, disable the checkout button, and block submitting expired `reservationId` instances.
- **Justification:**
  1. Prevents confusing `410 Reservation Expired` backend errors post-checkout attempt.
  2. Enhances UX transparency by clearly informing users when holds expire, enabling immediate cart management (removal or re-reservation).

---

## 2. AI Usage Log

- **Tools Used:**
  - **Gemini:** Utilized during development for architecture analysis, diagnosing **Asynchronous Race Conditions** and **Memory Leaks**, and designing **Widget Lifecycle** and **GetX Workers** management.

- **Concrete Examples of Misleading AI Suggestions:**
  1. _Example 1 (Over-engineered Race Condition Fix - RES-101):_
     - **Misleading Suggestion:** Recommended installing third-party packages and rewriting the controller with RxDart `switchMap` to cancel old stream requests.
     - **Detection:** Identified as an unnecessary external dependency that adds risk to the core GetX setup.
     - **Correction:** Implemented a **Latest Query Tracking** (`_latestQuery`) guard inside the controller, resolving the issue cleanly without new packages.
  2. _Example 2 (Masking Crash without Fixing Memory Leak - RES-102):_
     - **Misleading Suggestion:** Suggested wrapping `setState(...)` in `Timer.periodic` with `if (mounted)`.
     - **Detection:** Profiling via **DevTools** revealed that while crashes stopped, timers continued running in the background, accumulating **Zombie Timers**.
     - **Correction:** Stored a `Timer?` reference and cancelled it in `dispose()` via `_timer?.cancel()`, adhering to **Flutter Lifecycle** best practices.

---

## 3. Design Questions

- **Q1: In this codebase, what is the difference between a `GetxController`'s lifecycle and a widget `State`'s lifecycle? Name one bug from Part A that exists because of confusion between the two.**
  A `GetxController` persists across screens via GetX DI/Routing until manually deleted from memory, whereas a widget `State` is tied to the UI tree and destroyed upon leaving the screen (`dispose`). Bug **RES-103** stems from this confusion: workers were not disposed in `onClose()`, leaving the controller alive in memory and firing duplicate requests on cart updates[cite: 2].

- **Q2: When does wrapping a large subtree in a single `Obx` hurt you? How do you decide how tightly to scope reactivity?**
  Wrapping a large subtree in a single `Obx` forces Flutter to rebuild all child widgets whenever a state changes, causing frame drops (Jank). Reactivity should be scoped as tightly as possible by isolating dynamic UI elements into small sub-widgets and wrapping `Obx` strictly around the specific text or component that updates[cite: 2].

- **Q3: How would you write an automated test that would have caught RES-106 before release? What (if anything) would you change in the code to make such a test possible?**
  Write a Unit or Widget Test using a Mock Clock to verify the "Pickup today" filter across different local timezones[cite: 2]. In the codebase, abstract `DateTime.now()` calls into a Clock Provider or use Parameter Injection so automated tests can inject controlled timestamps and timezones[cite: 2].

---

## 4. Time Spent & Next Steps

- **Time Spent:** Approximately 12–16 hours.
- **What I would do next with one more day:**
  Write automated test suites (Unit Tests for controller logic and Widget Tests for timer lifecycles) and optimize image caching for smoother feed scrolling performance.
