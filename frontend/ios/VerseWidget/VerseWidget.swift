import SwiftUI
import WidgetKit

// Must match HomeWidgetService.iOSAppGroupId in lib/features/home_widget/home_widget_service.dart.
private let appGroupId = "group.com.londonglobaledventures.soulverse"

struct VerseEntry: TimelineEntry {
    let date: Date
    let text: String?
    let reference: String?
    /// Absolute paths to the images the Flutter app rendered, keyed by widget family.
    let imagePaths: [WidgetFamily: String]
}

struct VerseProvider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(
            date: Date(),
            text: "Be still, and know that I am God.",
            reference: "Psalm 46:10",
            imagePaths: [:]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        // The app reloads this widget whenever it renders a new day's verse.
        completion(Timeline(entries: [loadEntry()], policy: .never))
    }

    private func loadEntry() -> VerseEntry {
        let data = UserDefaults(suiteName: appGroupId)
        var paths: [WidgetFamily: String] = [:]
        paths[.systemSmall] = data?.string(forKey: "verse_image_small")
        paths[.systemMedium] = data?.string(forKey: "verse_image_medium")
        paths[.systemLarge] = data?.string(forKey: "verse_image_large")
        return VerseEntry(
            date: Date(),
            text: data?.string(forKey: "verse_text"),
            reference: data?.string(forKey: "verse_reference"),
            imagePaths: paths
        )
    }
}

struct VerseWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: VerseEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            lockScreen
        default:
            homeScreen
        }
    }

    /// Lock Screen widgets are drawn in a single tint by the system, so text only.
    private var lockScreen: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.text ?? "Open SoulVerse for today's verse")
                .font(.system(.body, design: .serif))
                .lineLimit(3)
                .minimumScaleFactor(0.8)
            if let reference = entry.reference {
                Text(reference)
                    .font(.caption2)
                    .widgetAccentable()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetBackground(Color.clear)
    }

    @ViewBuilder
    private var homeScreen: some View {
        if let path = entry.imagePaths[family], let image = UIImage(contentsOfFile: path) {
            // The rendered card already contains the background, verse and reference.
            Color.clear.widgetBackground(
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            )
        } else {
            VStack(spacing: 8) {
                Text(entry.text ?? "Open SoulVerse to load today's verse")
                    .font(.system(.headline, design: .serif))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                if let reference = entry.reference {
                    Text(reference).font(.caption)
                }
            }
            .foregroundStyle(.white)
            .padding()
            .widgetBackground(
                LinearGradient(
                    colors: [Color(red: 0.72, green: 0.53, blue: 0.29),
                             Color(red: 0.42, green: 0.29, blue: 0.17)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}

private extension View {
    /// iOS 17 requires `containerBackground` for widgets; earlier versions use a plain background.
    @ViewBuilder
    func widgetBackground<Background: View>(_ background: Background) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { background }
        } else {
            self.background(background)
        }
    }
}

struct VerseWidget: Widget {
    // Must match _iOSWidgetKind in lib/features/home_widget/home_widget_service.dart.
    let kind = "VerseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VerseProvider()) { entry in
            VerseWidgetView(entry: entry)
        }
        .configurationDisplayName("Verse of the day")
        .description("Today's Bible verse on your Home and Lock Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
        .contentMarginsDisabledIfAvailable()
    }
}

private extension WidgetConfiguration {
    /// Lets the rendered image fill the widget edge to edge on iOS 17+.
    func contentMarginsDisabledIfAvailable() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 17.0, *) {
            return contentMarginsDisabled()
        }
        return self
    }
}

@main
struct VerseWidgetBundle: WidgetBundle {
    var body: some Widget {
        VerseWidget()
    }
}
