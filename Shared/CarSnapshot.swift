import Foundation

struct CarSnapshot: Codable {
    var soc: Double?
    var range: Double?
    var mileage: Double?
    var voltage: Double?
    var temperature: Double?
    // Order: front-left, front-right, rear-left, rear-right. Unit: bar.
    var tires: [Double?] = [nil, nil, nil, nil]
    var locked: Bool?
    var doorsClosed: Bool?
    var windowsClosed: Bool?
    var updatedAt: Date?
    var appearanceID: String?
    var customName: String?
    var locationAddress: String?
    var locationUpdatedAt: Date?
    var locationState: VehicleLocationState?
    var locationDisplay: String { locationAddress ?? locationState?.title ?? "暂无定位地址" }
    var demo = false
    static func example(at date: Date = Date()) -> Self {
        .init(soc: 82, range: 349, mileage: 12680, voltage: 12.6, temperature: 23,
              tires: [2.4, 2.4, 2.4, 2.4], locked: true, doorsClosed: true,
              windowsClosed: true, updatedAt: date, demo: true)
    }
    static var missing: Self { .init() }
    var stale: Bool { isStale(at: Date()) }
    func isStale(at date: Date) -> Bool {
        updatedAt.map { date.timeIntervalSince($0) > 300 || $0.timeIntervalSince(date) > 60 } ?? true
    }
    var validSOC: Double? { soc.flatMap { $0.isFinite && (0...100).contains($0) ? $0 : nil } }
    static func text(_ value: Double?, decimals: Int = 0, unit: String = "", minimum: Double = 0) -> String {
        guard let value, value.isFinite, value >= minimum else { return "—" }
        return String(format: "%.*f", decimals, value) + unit
    }
    func pressure(_ index: Int) -> String { Self.text(tires.indices.contains(index) ? tires[index] : nil, decimals: 1) }
}

enum VehicleLocationState: String, Codable {
    case ready, unauthorized, missingPosition, invalidCoordinates, invalidTimestamp, addressUnavailable
    var title: String {
        switch self {
        case .ready:return "暂无定位地址"
        case .unauthorized:return "车辆定位未授权或授权状态未知"
        case .missingPosition:return "车辆尚未返回定位"
        case .invalidCoordinates:return "车辆定位坐标无效"
        case .invalidTimestamp:return "车辆定位时间无效"
        case .addressUnavailable:return "已取得车辆定位，地址解析暂不可用"
        }
    }
}
