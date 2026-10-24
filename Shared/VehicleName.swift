import Foundation
import CryptoKit

enum VehicleName {
    static func clean(_ value: String?) -> String? {
        guard let value else {return nil}
        let text=value.components(separatedBy:.controlCharacters).joined(separator:" ").trimmingCharacters(in:.whitespacesAndNewlines)
        return text.isEmpty ? nil : String(text.prefix(20))
    }
    static func display(_ value: String?) -> String {clean(value) ?? "MG4"}
}

struct VehicleNamePreferences {
    var defaults: UserDefaults = .standard
    private func key(_ vin: String) -> String {
        "MGControl.vehicleName.v1."+SHA256.hash(data:Data(vin.utf8)).map{String(format:"%02x",$0)}.joined()
    }
    func load(for vin: String) -> String? {vin.isEmpty ? nil : VehicleName.clean(defaults.string(forKey:key(vin)))}
    func save(_ value: String,for vin: String) {
        guard !vin.isEmpty else {return}
        if let text=VehicleName.clean(value) {defaults.set(text,forKey:key(vin))}
        else {defaults.removeObject(forKey:key(vin))}
    }
}
