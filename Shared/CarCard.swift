import SwiftUI
import UIKit

enum CarTheme: String, CaseIterable, Identifiable {
    case graphite, ocean, pearl, violet
    var id: String { rawValue }
    var title: String {
        switch self { case .graphite: return "曜石黑"; case .ocean: return "深海蓝"; case .pearl: return "珍珠白"; case .violet: return "暮光紫" }
    }
    var background: Color {
        switch self {
        case .graphite: return Color(red: 0.09, green: 0.09, blue: 0.10)
        case .ocean: return Color(red: 0.03, green: 0.13, blue: 0.22)
        case .pearl: return Color(red: 0.94, green: 0.95, blue: 0.96)
        case .violet: return Color(red: 0.17, green: 0.10, blue: 0.25)
        }
    }
    var foreground: Color { self == .pearl ? .black : .white }
    var accent: Color { self == .pearl ? Color(red: 0, green: 0.44, blue: 0.25) : .green }
}

struct CarCard: View {
    let car: CarSnapshot
    let theme: CarTheme
    var displayDate = Date()
    var sourceLabel: String? = nil
    var appearance: VehicleAppearance? = nil
    private var closure: String {
        if car.doorsClosed == false || car.windowsClosed == false { return "门窗开" }
        if car.doorsClosed == true && car.windowsClosed == true { return "门窗关" }
        return "门窗未知"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(VehicleName.display(car.customName)).font(.system(size: 22, weight: .heavy))
                    .lineLimit(1).minimumScaleFactor(0.6).privacySensitive()
                Text("EV · 2026").font(.system(size: 10)).opacity(0.55)
                Spacer(minLength: 0)
                Text(sourceLabel ?? (car.demo ? "模拟数据" : "上次车况")).font(.system(size: 9)).opacity(0.65)
            }
            HStack(spacing: 7) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill").foregroundStyle(theme.accent)
                        Text(CarSnapshot.text(car.validSOC, unit: "%")).font(.system(size: 21, weight: .bold))
                        Text(CarSnapshot.text(car.range, unit: " km")).font(.system(size: 12, weight: .semibold))
                    }.lineLimit(1).minimumScaleFactor(0.65)
                    GeometryReader {geometry in
                        ZStack(alignment:.leading) {
                            Capsule().fill(theme.foreground.opacity(0.10))
                            Capsule().fill(theme.accent).frame(width:geometry.size.width*(car.validSOC ?? 0)/100)
                        }
                    }.frame(height:4).accessibilityLabel("电量 "+CarSnapshot.text(car.validSOC,unit:"%"))
                    HStack(spacing: 7) {
                        Label(CarSnapshot.text(car.mileage, unit: " km"), systemImage: "speedometer")
                        Text(CarSnapshot.text(car.temperature, unit: "°C", minimum: -60))
                    }.font(.system(size: 10)).opacity(0.65).lineLimit(1).minimumScaleFactor(0.7)
                    HStack(spacing: 7) {
                        Label(CarSnapshot.text(car.voltage, decimals: 1, unit: " V"), systemImage: "battery.100percent")
                        VStack(alignment: .leading, spacing: 1) {
                            Text("前 \(car.pressure(0)) / \(car.pressure(1))")
                            Text("后 \(car.pressure(2)) / \(car.pressure(3)) bar")
                        }.font(.system(size: 8))
                    }.font(.system(size: 10)).opacity(0.65)
                }.frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 4) {
                    VehicleAppearanceImage(appearance:appearance ?? .resolve(car.appearanceID))
                        .frame(height:61)
                    HStack(spacing: 3) {
                        badge(car.locked.map { $0 ? "已锁" : "未锁" } ?? "锁未知", safe: car.locked == true)
                        badge(closure, safe: car.doorsClosed == true && car.windowsClosed == true)
                    }
                }.frame(width: 116)
            }
            HStack(spacing: 3) {
                Image(systemName: "clock.arrow.circlepath")
                if let date = car.updatedAt { Text(date, style: .time) } else { Text("暂无更新时间") }
                if car.isStale(at: displayDate) { Text("· 已过期").foregroundStyle(.orange) }
                Spacer(minLength: 0)
                Text(car.demo ? "仅演示 · 非实时" : "非实时车况")
            }.font(.system(size: 9)).opacity(0.65)
        }.foregroundStyle(theme.foreground).padding(12)
    }
    private func badge(_ title: String, safe: Bool) -> some View {
        let color = safe && !car.isStale(at: displayDate) ? theme.accent : theme.foreground.opacity(0.6)
        return Text(title).font(.system(size: 9, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.6)
            .padding(.horizontal, 5).padding(.vertical, 4).foregroundStyle(color)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
    }
}
