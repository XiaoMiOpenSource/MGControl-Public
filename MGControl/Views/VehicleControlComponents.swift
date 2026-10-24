import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    static let preferenceKey="MGControl.appearance.v1"
    var id: String {rawValue}
    var title: String {switch self {case .system:return "跟随系统";case .light:return "浅色";case .dark:return "深色"}}
    var scheme: ColorScheme? {switch self {case .system:return nil;case .light:return .light;case .dark:return .dark}}
    static func resolve(_ raw: String) -> Self {Self(rawValue:raw) ?? .system}
}

struct VehicleSurface<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: ()->Content) {self.content=content()}
    var body: some View {
        content.padding(16).frame(maxWidth:.infinity,alignment:.leading)
            .background(Color(uiColor:.secondarySystemGroupedBackground),in:RoundedRectangle(cornerRadius:22))
            .overlay(RoundedRectangle(cornerRadius:22).stroke(.primary.opacity(0.05),lineWidth:1))
    }
}

struct VehicleOverviewPanel: View {
    let car: CarSnapshot
    let appearance: VehicleAppearance
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        VehicleSurface {
            VStack(alignment:.leading,spacing:12) {
                HStack(alignment:.top,spacing:8) {
                    Image(systemName:"mappin.and.ellipse").foregroundStyle(.teal)
                    VStack(alignment:.leading,spacing:4) {
                        Text("车辆停泊位置").font(.caption).foregroundStyle(.secondary)
                        Text(car.locationDisplay).font(.subheadline.weight(.medium)).privacySensitive().textSelection(.enabled)
                        if let time=car.locationUpdatedAt {Text(time,format:.dateTime.month().day().hour().minute()).font(.caption2).foregroundStyle(.secondary)}
                    }
                    Spacer(minLength:0)
                }
                Divider()
                CarCard(car:car,theme:scheme == .dark ? .graphite : .pearl,appearance:appearance)
                    .padding(-8)
            }
        }
    }
}

struct VehicleActionTile: View {
    let title: String
    let symbol: String
    let detail: String
    var body: some View {
        VStack(spacing:7) {
            Image(systemName:symbol).font(.system(size:21,weight:.medium)).frame(height:25)
            Text(title).font(.system(.subheadline,weight:.medium)).lineLimit(1).minimumScaleFactor(0.8)
            Text(detail).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }.frame(maxWidth:.infinity,minHeight:76).padding(.vertical,8)
            .background(Color(uiColor:.tertiarySystemGroupedBackground),in:RoundedRectangle(cornerRadius:16))
            .overlay(RoundedRectangle(cornerRadius:16).stroke(.primary.opacity(0.06),lineWidth:1))
            .contentShape(RoundedRectangle(cornerRadius:16))
    }
}

struct VehicleQuickActions: View {
    static let actions: [PreviewAction]=[.lock,.unlock,.windowOpen,.windowClose,.findVehicle]
    var disabled=false
    let perform: (PreviewAction)->Void
    var body: some View {
        VehicleSurface {
            VStack(alignment:.leading,spacing:12) {
                HStack {Text("远程快捷控车").font(.headline);Spacer();Text("操作前确认").font(.caption2).foregroundStyle(.secondary)}
                VStack(spacing:8) {
                    HStack(spacing:8) {ForEach(Array(Self.actions.prefix(2))) {tile($0)}}
                    HStack(spacing:8) {ForEach(Array(Self.actions.dropFirst(2))) {tile($0)}}
                }.disabled(disabled)
            }
        }
    }
    private func tile(_ action: PreviewAction) -> some View {
        Button {perform(action)} label: {VehicleActionTile(title:action.title,symbol:action.symbol,detail:action.verificationLabel)}
            .buttonStyle(.plain).accessibilityLabel(action.title+"，"+action.verificationLabel)
    }
}

enum ClimatePanelMode: String, CaseIterable, Identifiable {
    case temperature, cooling, heating
    var id: String {rawValue}
    var title: String {switch self {case .temperature:return "温控";case .cooling:return "制冷";case .heating:return "制热"}}
    var action: PreviewAction {switch self {case .temperature:return .normalAC;case .cooling:return .coolingOn;case .heating:return .heatingOn}}
}

struct ClimateControlPanel: View {
    @Binding var mode: ClimatePanelMode
    @Binding var temperature: Int
    var cabin: Double?
    var disabled=false
    let start: ()->Void
    let stop: ()->Void
    var body: some View {
        VehicleSurface {
            VStack(alignment:.leading,spacing:16) {
                HStack {
                    VStack(alignment:.leading,spacing:4) {
                        Text("空调温度").font(.headline)
                        Text("上报车内 "+CarSnapshot.text(cabin,unit:"℃",minimum:-60)).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label("10 分钟",systemImage:"clock").font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing:3) {
                    ForEach(ClimatePanelMode.allCases) {value in
                        Button {mode=value} label: {
                            Text(value.title).font(.subheadline.weight(mode == value ? .semibold : .regular))
                                .frame(maxWidth:.infinity,minHeight:36)
                                .background(mode == value ? Color(uiColor:.secondarySystemGroupedBackground) : .clear,in:RoundedRectangle(cornerRadius:9))
                        }.buttonStyle(.plain).accessibilityLabel(value.title+(mode == value ? "，已选择" : ""))
                    }
                }.padding(3).background(.primary.opacity(0.06),in:RoundedRectangle(cornerRadius:12))
                if mode == .temperature {
                    HStack(spacing:16) {
                        temperatureButton("minus",label:"降低目标温度",step:-1)
                        VStack(spacing:3) {
                            Text("\(temperature)°").font(.system(size:48,weight:.light,design:.rounded)).monospacedDigit()
                            Text("目标温度 · 温控测试").font(.caption2).foregroundStyle(.secondary)
                        }.frame(maxWidth:.infinity)
                        temperatureButton("plus",label:"提高目标温度",step:1)
                    }
                    Text("温控暂支持 25–29℃，待实车验证。调整温度不会自动发送指令。")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    HStack(spacing:14) {
                        Image(systemName:mode.action.symbol).font(.system(size:34)).foregroundStyle(mode == .heating ? .orange : .teal)
                        VStack(alignment:.leading,spacing:4) {
                            Text(mode.title).font(.title2.weight(.medium))
                            Text("使用车辆默认温度策略").font(.caption).foregroundStyle(.secondary)
                        }
                    }.frame(maxWidth:.infinity,minHeight:86,alignment:.center)
                }
                HStack(spacing:10) {
                    Button(action:stop) {Label("关闭空调",systemImage:"power").lineLimit(1).minimumScaleFactor(0.65).frame(maxWidth:.infinity,minHeight:36)}.buttonStyle(.bordered)
                    Button(action:start) {Text(mode.action.title).lineLimit(1).minimumScaleFactor(0.65).frame(maxWidth:.infinity,minHeight:36)}.buttonStyle(.borderedProminent)
                }.disabled(disabled)
                Text("开关操作均需确认；模式选择不代表车辆当前状态。")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
    private func temperatureButton(_ symbol: String,label: String,step: Int) -> some View {
        Button {temperature=min(29,max(25,temperature+step))} label: {
            Image(systemName:symbol).font(.title3).frame(width:44,height:44)
                .background(.teal.opacity(0.09),in:Circle())
        }.buttonStyle(.plain).accessibilityLabel(label)
            .disabled(disabled || (step < 0 ? temperature <= 25 : temperature >= 29))
    }
}
