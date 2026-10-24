import SwiftUI
import WidgetKit
struct CarEntry: TimelineEntry {
    let date: Date
    let car: CarSnapshot
    let theme: CarTheme
    var phase: WidgetLoadPhase = .ready
}
// Local cached data requires no App Intent configuration or network calls.
struct CarProvider: TimelineProvider {
    func placeholder(in context: Context) -> CarEntry {
        .init(date:.now,car:.missing,theme:.graphite,phase:.loading)
    }
    func getSnapshot(in context: Context, completion: @escaping (CarEntry) -> Void) {
        completion(entry(.snapshot))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<CarEntry>) -> Void) {
        let now = entry(.timeline)
        let later = CarEntry(date:now.date.addingTimeInterval(301),car:now.car,theme:now.theme,phase:now.phase)
        completion(Timeline(entries:[now,later],policy:.after(now.date.addingTimeInterval(900))))
    }
    private func entry(_ source: WidgetReadSource) -> CarEntry {
        let store = SharedVehicleStore.live
        let state = WidgetLoadState.load(from:store)
        try? store.recordWidgetRead(state.phase,source:source)
        return .init(date:.now,car:state.car,theme:.graphite,phase:state.phase)
    }
}
@main
struct MGControlWidgetBundle: WidgetBundle {
    var body: some Widget { MGControlWidget(); BLEMonitoringLiveActivity() }
}
struct MGControlWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MGControl.Car.Live.Static.V1", provider: CarProvider()) { entry in
            VehicleWidgetContent(entry: entry)
                .widgetURL(URL(string:"mgcontrol://dashboard"))
        }
        .configurationDisplayName("MG4 车况·兼容版")
        .description("主 App 最近同步的电量、续航、12V、胎压、里程、温度与车锁。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge]).contentMarginsDisabled()
    }
}

struct VehicleWidgetContent: View {
    let entry: CarEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    private var theme: CarTheme { colorScheme == .dark ? .graphite : .pearl }
    var body: some View {
        Group {
            if entry.phase != .ready {
                VStack(alignment:.leading,spacing:10) {
                    Label("MG4 车况",systemImage:"car.side.fill").font(.headline)
                    Text(entry.phase.title).font(.subheadline.bold())
                    Text(entry.phase.help).font(.caption).foregroundStyle(.secondary)
                }.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading).padding(16).unredacted()
            } else if family == .systemSmall {
                VStack(alignment: .leading, spacing: 8) {
                    Text(VehicleName.display(entry.car.customName)+" · 2026").font(.headline).lineLimit(1).minimumScaleFactor(0.6).privacySensitive()
                    Text(entry.car.updatedAt == nil ? "打开 App 同步车况" : "最近同步车况").font(.caption2)
                    Text(CarSnapshot.text(entry.car.validSOC, unit: "%"))
                        .font(.system(size: 30, weight: .bold)).foregroundStyle(theme.accent)
                    Text(CarSnapshot.text(entry.car.range, unit: " km")).font(.subheadline)
                    Text(entry.car.locked.map { $0 ? "已锁车" : "未锁车" } ?? "车锁未知").font(.caption)
                    Text(entry.car.isStale(at: entry.date) ? "数据缺失或已过期" : "非实时车况")
                        .font(.caption2).foregroundStyle(.secondary)
                    Text(entry.car.locationDisplay).font(.system(size:9)).lineLimit(1).privacySensitive()
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading).padding(14)
            } else if family == .systemLarge {
                VStack(spacing: 12) {
                    CarCard(car: entry.car, theme: theme, displayDate: entry.date)
                    Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                        GridRow {
                            detail("12V 电池", CarSnapshot.text(entry.car.voltage, decimals: 1, unit: " V"))
                            detail("总里程", CarSnapshot.text(entry.car.mileage, unit: " km"))
                        }
                        GridRow {
                            detail("左前 / 右前胎压", "\(entry.car.pressure(0)) / \(entry.car.pressure(1)) bar")
                            detail("左后 / 右后胎压", "\(entry.car.pressure(2)) / \(entry.car.pressure(3)) bar")
                        }
                        GridRow {
                            detail("车内温度", CarSnapshot.text(entry.car.temperature, unit: " ℃", minimum: -60))
                            detail("数据来源", entry.car.updatedAt == nil ? "暂无同步" : "主 App 同步")
                        }
                    }.padding(.horizontal, 14)
                    WidgetControlLinks()
                    WidgetVehicleAddress(car:entry.car)
                    Text("点击车控入口，在 App 确认操作")
                        .font(.system(size: 9)).foregroundStyle(.secondary)
                }.frame(maxHeight: .infinity)
            } else {
                VStack(spacing:0) {
                    GeometryReader { geometry in
                    CarCard(car: entry.car, theme: theme, displayDate: entry.date)
                        .frame(width: geometry.size.width, height: 160)
                        .scaleEffect(min(1, geometry.size.height / 160))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    WidgetControlLinks()
                    WidgetVehicleAddress(car:entry.car).padding(.bottom,3)
                }
            }
        }.foregroundStyle(theme.foreground).tint(theme.foreground)
            .containerBackground(theme.background, for: .widget)
    }
    private func detail(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption2).opacity(0.65)
            Text(value).font(.caption.bold()).lineLimit(1).minimumScaleFactor(0.7)
        }
    }
}

private struct WidgetControlLinks: View {
    var body: some View {
        HStack(spacing:8) {
            ForEach(WidgetControlRoute.allCases) { route in
                Link(destination:route.url) {
                    VStack(spacing:1) {
                        Image(systemName:route.symbol).font(.system(size:15))
                        Text(route.title).font(.system(size:8)).lineLimit(1)
                    }.frame(maxWidth:.infinity).padding(.vertical,3)
                        .background(.primary.opacity(0.09),in:RoundedRectangle(cornerRadius:7))
                }.accessibilityLabel(route.title+"，打开 App 确认")
            }
        }.padding(.horizontal,12).unredacted()
    }
}

private struct WidgetVehicleAddress: View {
    let car: CarSnapshot
    var body: some View {
        HStack(spacing:3) {
            Image(systemName:"location.fill")
            Text(car.locationDisplay).lineLimit(1).privacySensitive()
            if let time=car.locationUpdatedAt {Text(time,format:.dateTime.month().day().hour().minute()).lineLimit(1)}
        }.font(.system(size:9)).foregroundStyle(.secondary).padding(.horizontal,12)
            .accessibilityLabel("上次车辆定位地址："+car.locationDisplay)
    }
}
