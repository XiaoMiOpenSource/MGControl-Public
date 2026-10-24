import ActivityKit
import Foundation

struct BLEMonitoringAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var message: String
        var monitoring: Bool
        var connected: Bool? = nil
        var signalAt: Date? = nil
        var car: BLEActivityCar? = nil
        var feedback: BLEActivityFeedback? = nil
        var vehicleNotice: BLEActivityVehicleNotice? = nil
        func connectionTitle(at now: Date) -> String {
            guard monitoring else {return "蓝牙监测未运行"}
            guard let connected else {return "蓝牙状态待更新"}
            guard connected else {return "等待车辆连接"}
            guard let signalAt,(0...120).contains(now.timeIntervalSince(signalAt)) else {return "蓝牙状态待更新"}
            return "蓝牙已认证"
        }
    }
    var title: String
}

struct BLEActivityCar: Codable, Hashable {
    var soc: Double?
    var range: Double?
    var voltage: Double?
    var locked: Bool?
    var doorsClosed: Bool?
    var windowsClosed: Bool?
    var updatedAt: Date?
    init(_ value: CarSnapshot,now: Date = Date()) {
        func valid(_ x: Double?,_ range: ClosedRange<Double>) -> Double? {
            x.flatMap{$0.isFinite && range.contains($0) ? $0 : nil}
        }
        soc=valid(value.soc,0...100);range=valid(value.range,0...3000);voltage=valid(value.voltage,0...30)
        locked=value.locked
        doorsClosed=value.doorsClosed;windowsClosed=value.windowsClosed
        updatedAt=value.updatedAt.flatMap{$0.timeIntervalSince1970.isFinite && $0 <= now.addingTimeInterval(60) ? $0 : nil}
    }
    func stale(at now: Date) -> Bool {updatedAt.map{now.timeIntervalSince($0)>300 || $0>now.addingTimeInterval(60)} ?? true}
    func notice(comparedTo old: Self?) -> BLEActivityVehicleNotice? {
        guard let old,let before=old.updatedAt,let now=updatedAt,now>before else {return nil}
        if let a=old.doorsClosed,let b=doorsClosed,a != b {return .init(kind:b ? .doorsClosed : .doorsOpen,date:now)}
        if let a=old.windowsClosed,let b=windowsClosed,a != b {return .init(kind:b ? .windowsClosed : .windowsOpen,date:now)}
        if let a=old.locked,let b=locked,a != b {return .init(kind:b ? .locked : .unlocked,date:now)}
        return nil
    }
}

struct BLEActivityVehicleNotice: Codable, Hashable {
    enum Kind: String,Codable {case locked,unlocked,doorsOpen,doorsClosed,windowsOpen,windowsClosed}
    let kind: Kind
    let date: Date
    var title: String {
        switch kind {
        case .locked:return "较新车况上报：车锁已锁"
        case .unlocked:return "较新车况上报：车锁未锁"
        case .doorsOpen:return "较新车况上报：车门未全关"
        case .doorsClosed:return "较新车况上报：车门已全关"
        case .windowsOpen:return "较新车况上报：车窗未全关"
        case .windowsClosed:return "较新车况上报：车窗已全关"
        }
    }
}

struct BLEActivityFeedback: Codable, Hashable {
    enum Kind: String,Codable {case lock,unlock,climate,windowOpen,windowClose,find
        var title: String {
            switch self {
            case .lock:return "锁车"
            case .unlock:return "解锁"
            case .climate:return "空调操作"
            case .windowOpen:return "车窗通风"
            case .windowClose:return "关窗"
            case .find:return "鸣笛寻车"
            }
        }
    }
    let kind: Kind
    let confirmed: Bool
    let bluetooth: Bool
    let date: Date
    var title: String {(bluetooth ? "蓝牙" : "服务端报告")+kind.title+(confirmed ? "成功" : "未确认成功")}
    var symbol: String {confirmed ? (kind == .unlock ? "lock.open.fill" : "checkmark.circle.fill") : "questionmark.circle"}
    func recent(at now: Date) -> Bool {(0...30).contains(now.timeIntervalSince(date))}
}
