import SwiftUI

struct CarLiveActivitySummary: View {
    let state: BLEMonitoringAttributes.ContentState
    let stale: Bool
    var now=Date()
    var body: some View {
        VStack(alignment:.leading,spacing:5) {
            HStack {
                Label("MG 车况与钥匙",systemImage:"car.side.fill").font(.headline)
                Spacer(minLength:4)
                Text(state.connectionTitle(at:now)).font(.caption2).foregroundStyle(.teal)
            }
            if let feedback=state.feedback {
                HStack {
                    Label(feedback.title,systemImage:feedback.symbol).font(.caption.bold())
                        .foregroundStyle(feedback.confirmed ? .green : .orange)
                    Spacer(minLength:4)
                    Text(feedback.date,style:.time).font(.system(size:10)).foregroundStyle(.secondary)
                }
            } else {Text(state.message).font(.caption).lineLimit(2)}
            if let car=state.car {CarActivityCarRow(car:car,stale:stale,now:now)}
            else {Text("暂无同步车况 · 蓝牙回执与车况独立").font(.caption2).foregroundStyle(.secondary)}
            if let notice=state.vehicleNotice {
                HStack(spacing:4) {
                    Text(notice.title).lineLimit(1)
                    Text(notice.date,style:.time)
                }.font(.system(size:10)).foregroundStyle(.secondary)
            }
        }.padding(12).foregroundStyle(.white)
    }
}

struct CarActivityCarRow: View {
    let car: BLEActivityCar
    let stale: Bool
    var now=Date()
    var body: some View {
        VStack(alignment:.leading,spacing:3) {
            HStack(spacing:12) {
                Text(CarSnapshot.text(car.soc,unit:"%"))
                Text(CarSnapshot.text(car.range,unit:" km"))
                Text(CarSnapshot.text(car.voltage,decimals:1,unit:" V"))
                Text(car.locked.map{$0 ? "上报已锁" : "上报未锁"} ?? "车锁未知")
            }.font(.caption).privacySensitive()
            HStack(spacing:4) {
                Text(car.stale(at:now) ? "车况已过期" : "最近同步车况")
                if let time=car.updatedAt {Text(time,format:.dateTime.month().day().hour().minute())}
                if stale {Image(systemName:"clock")}
            }.font(.system(size:10)).foregroundStyle(.secondary)
        }
    }
}
