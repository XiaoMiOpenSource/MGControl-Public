import Foundation

enum WidgetLoadPhase: String, Codable {
    case loading, ready, notSynced, unavailable, invalid
    var title: String {
        switch self {
        case .loading: return "正在加载车况"
        case .ready: return "最近同步车况"
        case .notSynced: return "尚未同步车况"
        case .unavailable: return "小组件无法访问共享车况"
        case .invalid: return "同步车况暂时无法读取"
        }
    }
    var help: String {
        switch self {
        case .loading: return "若持续停留，请打开主 App 同步车况，再重新添加小组件。"
        case .ready: return "打开主 App 读取或刷新车况后更新。"
        case .notSynced: return "打开主 App，选择车辆并读取或刷新车况。"
        case .unavailable: return "请检查主 App 与小组件的签名是否保留同一 App Groups 共享权限。"
        case .invalid: return "请回到主 App 重新读取车况后再查看。"
        }
    }
}

struct WidgetLoadState {
    let car: CarSnapshot
    let phase: WidgetLoadPhase
    static func load(from store: SharedVehicleStore) -> Self {
        do {
            guard let car = try store.read(), car.updatedAt != nil else {
                return Self(car:.missing,phase:.notSynced)
            }
            return Self(car:car,phase:.ready)
        } catch SharedVehicleStore.StoreFailure.unavailable {
            return Self(car:.missing,phase:.unavailable)
        } catch {
            return Self(car:.missing,phase:.invalid)
        }
    }
}

enum WidgetReadSource: String, Codable {
    case snapshot, timeline
    var title: String { self == .snapshot ? "快照" : "时间线" }
}

extension SharedVehicleStore {
    private struct WidgetReceipt: Codable {
        let date: Date
        let phase: WidgetLoadPhase
        let source: WidgetReadSource?
        let readerVersion: String?
    }
    private func receiptURL() throws -> URL {
        guard let directory else { throw StoreFailure.unavailable }
        return directory.appendingPathComponent("widget-read-v1.json")
    }
    func recordWidgetRead(_ phase: WidgetLoadPhase, source: WidgetReadSource = .timeline) throws {
        let bytes = try JSONEncoder().encode(WidgetReceipt(date:.now,phase:phase,source:source,readerVersion:"0.3.6"))
        try bytes.write(to:receiptURL(),options:[.atomic,.completeFileProtectionUntilFirstUserAuthentication])
    }
    func widgetReadDescription() throws -> String {
        let url = try receiptURL()
        guard FileManager.default.fileExists(atPath:url.path) else { return "尚未收到小组件读取回执" }
        let handle = try FileHandle(forReadingFrom:url)
        defer { try? handle.close() }
        let bytes = try handle.read(upToCount:2049) ?? Data()
        guard bytes.count <= 2048 else { throw StoreFailure.invalid }
        let value = try JSONDecoder().decode(WidgetReceipt.self,from:bytes)
        return value.date.formatted(date:.abbreviated,time:.standard) + " · " + value.phase.title + " · " + (value.source?.title ?? "旧版读取") + (value.readerVersion == "0.3.6" ? " · 0.3.6" : "")
    }
}
