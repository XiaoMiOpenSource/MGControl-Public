import Foundation

/// Navigation only: an incoming link never sends a vehicle command or supplies identity.
enum WidgetControlRoute: String, CaseIterable, Identifiable {
    case locks, windows, climate, find
    var id: String { rawValue }
    var title: String {
        switch self { case .locks:return "锁车／解锁"; case .windows:return "车窗"; case .climate:return "空调"; case .find:return "鸣笛寻车" }
    }
    var symbol: String {
        switch self { case .locks:return "lock.fill"; case .windows:return "rectangle.portrait.and.arrow.right"; case .climate:return "fan.fill"; case .find:return "speaker.wave.2.fill" }
    }
    var url: URL { URL(string:"mgcontrol://control/"+rawValue)! }
    static func parse(_ url: URL) -> Self? {
        guard let c=URLComponents(url:url,resolvingAgainstBaseURL:false),c.scheme == "mgcontrol",c.host == "control",
              c.user == nil,c.password == nil,c.port == nil,c.query == nil,c.fragment == nil,
              c.path == "/"+String(c.path.dropFirst()),c.percentEncodedPath == c.path else { return nil }
        return Self(rawValue:String(c.path.dropFirst()))
    }
}
