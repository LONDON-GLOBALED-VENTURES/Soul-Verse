# iOS verse widget — Xcode setup (Mac required)

`VerseWidget.swift` is the complete widget: Home Screen (small, medium, large)
and Lock Screen (rectangular). Xcode has to create the extension target once;
these steps take about 10 minutes.

## 1. Create the widget extension target

1. Open `frontend/ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target… → Widget Extension → Next.**
3. Product Name: `VerseWidget`. Untick **Include Live Activity**,
   **Include Control** and **Include Configuration App Intent**. Finish.
4. If asked to activate the scheme, choose **Activate**.
5. Xcode generated some Swift files in the `VerseWidget` group. **Delete** them all
   (Move to Trash), e.g. `VerseWidget.swift`, `VerseWidgetBundle.swift`.
   Keep `Info.plist` and `Assets.xcassets`.
6. Drag this folder's `VerseWidget.swift` into the `VerseWidget` group, with
   **Target Membership: VerseWidget only** (not Runner).

## 2. Deployment target

Select the **VerseWidget** target → **General → Minimum Deployments → iOS 16.0**
(Lock Screen widgets need iOS 16).

## 3. App Group (shared storage between app and widget)

Do this for **both** the **Runner** and **VerseWidget** targets:

1. **Signing & Capabilities → + Capability → App Groups.**
2. Add `group.com.londonglobaledventures.soulverse`.

The ID must match `HomeWidgetService.iOSAppGroupId` in
`lib/features/home_widget/home_widget_service.dart` and `appGroupId` in
`VerseWidget.swift`. With automatic signing, Xcode registers it in your Apple
Developer account.

## 4. Bundle IDs

The widget's bundle ID must be the app's ID plus a suffix:
`com.londonglobaledventures.soulverse.VerseWidget` (Xcode sets this by default).

## 5. Run and check

1. Run the app on a device or simulator and let the Home screen load today's
   verse. That renders the widget images and reloads the widget.
2. Long-press the Home Screen → **+** → **SoulVerse** → add small, medium and
   large widgets.
3. Lock Screen: long-press the Lock Screen → **Customize** → **Lock Screen** →
   add the SoulVerse widget below the clock.

If a widget shows "Open SoulVerse…", open the app once more. If it still does,
the App Group is usually the cause: check it's enabled on both targets with the
exact same ID.
