import WidgetKit
import SwiftUI

struct PrayerTimesPayload: Codable {
    let date: String
    let prayers: [Prayer]
}

struct Prayer: Codable {
    let name: String
    let time: String
}

struct PrayerEntry: TimelineEntry {
    let date: Date
    let prayers: [Prayer]
    let city: String
    let country: String
    let debugInfo: String
}

struct PrayerTimesProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(
            date: Date(),
            prayers: [
                Prayer(name: "Fajr", time: "05:30"),
                Prayer(name: "Dhuhr", time: "12:15"),
                Prayer(name: "Asr", time: "15:45"),
                Prayer(name: "Maghrib", time: "18:20"),
                Prayer(name: "Isha", time: "19:45")
            ],
            city: "San Fran",
            country: "USA",
            debugInfo: "Placeholder"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> ()) {
        let entry = loadEntry()
        
        // Next midnight
        let now = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let nextMidnight = calendar.nextDate(after: now,
                                             matching: DateComponents(hour: 0, minute: 0, second: 0),
                                             matchingPolicy: .nextTime)!
        
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }


    private func loadEntry() -> PrayerEntry {
        var debugLog = ""
        
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.getsilat.silat") else {
            debugLog = "❌ Cannot access UserDefaults"
            return PrayerEntry(date: Date(), prayers: [], city: "Unknown", country: "", debugInfo: debugLog)
        }
        
        // Read city/country properly
        let city = sharedDefaults.string(forKey: "user_city") ?? "Unknown"
        let country = sharedDefaults.string(forKey: "user_country") ?? ""
        
        debugLog += "✅ UserDefaults OK\n"
        
        guard let jsonString = sharedDefaults.string(forKey: "today_prayers") else {
            debugLog += "❌ No 'today_prayers' key found"
            return PrayerEntry(date: Date(), prayers: [], city: city, country: country, debugInfo: debugLog)
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            debugLog += "❌ Cannot convert to data"
            return PrayerEntry(date: Date(), prayers: [], city: city, country: country, debugInfo: debugLog)
        }
        
        do {
            let payload = try JSONDecoder().decode(PrayerTimesPayload.self, from: jsonData)
            return PrayerEntry(date: Date(), prayers: payload.prayers, city: city, country: country, debugInfo: debugLog)
        } catch {
            debugLog += "❌ Parse error: \(error.localizedDescription)"
            return PrayerEntry(date: Date(), prayers: [], city: city, country: country, debugInfo: debugLog)
        }
    }


}
struct PrayerTimesWidgetView: View {
    var entry: PrayerEntry

    var body: some View {
        if entry.prayers.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("ERROR OCCURED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
            }
            .padding(8)
        } else {
            VStack(spacing: 4) {
                // Display city and country at top
                Text("\(entry.city), \(entry.country)")
                     .font(.caption)
                     .fontWeight(.bold)

                 Text(formattedDate(entry.date))
                     .font(.system(size: 10))
                     .foregroundColor(.secondary)
                
                ForEach(entry.prayers, id: \.name) { prayer in
                    HStack {
                        Image(systemName: iconName(for: prayer.name))
                            .font(.system(size: 12))
                        Text(prayer.name)
                            .font(.system(size: 11))
                        Spacer()
                        Text(prayer.time)
                            .font(.system(size: 11, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                }
            }
            .padding(8)
        }
    }
    
    private func iconName(for prayer: String) -> String {
        switch prayer {
        case "Fajr": return "sunrise.fill"
        case "Dhuhr": return "sun.max.fill"
        case "Asr": return "sun.min.fill"
        case "Maghrib": return "sunset.fill"
        case "Isha": return "moon.stars.fill"
        default: return "sun.max"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM" // Tue 2 Jan
        return formatter.string(from: date)
    }
}


struct PrayerTimesWidget: Widget {
    let kind: String = "PrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
            PrayerTimesWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Prayer Times")
        .description("Today's prayer schedule")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
