import SwiftUI

/// Display-only harness. No account, networking, Bluetooth or vehicle commands.
@main struct MGControlPreviewApp: App {
    var body: some Scene {WindowGroup {PreviewHome()}}
}
struct PreviewHome: View {
    @State private var theme=CarTheme.pearl
    @State private var mode=ClimatePanelMode.temperature
    @State private var temperature=25
    var body: some View {
        NavigationStack {ScrollView {VStack(spacing:16) {
            Text("界面预览 · 全部为模拟数据，不连接车辆").font(.footnote)
            CarCard(car:.example(),theme:theme,appearance:.white)
            VehicleQuickActions(perform:{_ in})
            ClimateControlPanel(mode:$mode,temperature:$temperature,start:{},stop:{})
        }.padding()}.navigationTitle("MGControl 界面预览")}
    }
}
/// Presentation labels only; deliberately no API parameters or command encoding.
enum PreviewAction: String,CaseIterable,Identifiable {
    case lock,unlock,windowOpen,windowClose,findVehicle,normalAC,coolingOn,heatingOn
    var id: String {rawValue}
    var verificationLabel: String {"界面预览"}
    var title: String {switch self {
    case .lock:return "锁车";case .unlock:return "解锁";case .windowOpen:return "车窗通风"
    case .windowClose:return "关闭车窗";case .findVehicle:return "鸣笛寻车"
    case .normalAC:return "温控";case .coolingOn:return "制冷";case .heatingOn:return "制热"}}
    var symbol: String {switch self {
    case .lock:return "lock.fill";case .unlock:return "lock.open.fill"
    case .windowOpen,.windowClose:return "rectangle.portrait.and.arrow.right"
    case .findVehicle:return "speaker.wave.2.fill";case .heatingOn:return "sun.max.fill"
    case .normalAC,.coolingOn:return "snowflake"}}
}
