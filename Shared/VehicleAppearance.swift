import Foundation
import CryptoKit

enum VehicleAppearance: String, CaseIterable, Identifiable, Codable {
    case iceBlue, almond, purple, jade, grey, white
    var id: String { rawValue }
    var title: String {
        switch self {
        case .iceBlue: return "冰晶蓝"
        case .almond: return "杏仁米"
        case .purple: return "东来紫"
        case .jade: return "青波翠"
        case .grey: return "星野灰"
        case .white: return "月光白"
        }
    }
    var assetName: String {
        switch self {
        case .iceBlue: return "MG4IceBlue"
        case .almond: return "MG4Almond"
        case .purple: return "MG4Purple"
        case .jade: return "MG4Jade"
        case .grey: return "MG4Grey"
        case .white: return "MG4White"
        }
    }
    static func resolve(_ raw: String?) -> Self { raw.flatMap(Self.init(rawValue:)) ?? .iceBlue }
}

struct VehicleAppearancePreferences {
    var defaults: UserDefaults = .standard
    private func key(for vin: String) -> String {
        let digest = SHA256.hash(data:Data(vin.utf8)).map { String(format:"%02x",$0) }.joined()
        return "MGControl.vehicleAppearance.v1." + digest
    }
    func selection(for vin: String) -> VehicleAppearance {
        guard !vin.isEmpty else { return .iceBlue }
        return .resolve(defaults.string(forKey:key(for:vin)))
    }
    func save(_ value: VehicleAppearance, for vin: String) {
        guard !vin.isEmpty else { return }
        defaults.set(value.rawValue,forKey:key(for:vin))
    }
}
