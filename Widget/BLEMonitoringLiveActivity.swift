import ActivityKit
import WidgetKit
import SwiftUI

struct BLEMonitoringLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for:BLEMonitoringAttributes.self) { context in
            CarLiveActivitySummary(state:context.state,stale:context.isStale)
                .activityBackgroundTint(.black).activitySystemActionForegroundColor(.teal)
                .widgetURL(URL(string:"mgcontrol://bluetooth"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Image(systemName:"car.side.fill").foregroundStyle(.teal) }
                DynamicIslandExpandedRegion(.trailing) { Text(context.state.connectionTitle(at:Date())).font(.caption) }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment:.leading,spacing:4) {
                        if let feedback=context.state.feedback {
                            Label(feedback.title,systemImage:feedback.symbol).foregroundStyle(feedback.confirmed ? .green : .orange)
                            Text(feedback.date,style:.time).font(.caption2)
                        } else {Text(context.state.message).lineLimit(2)}
                        if let car=context.state.car {CarActivityCarRow(car:car,stale:context.isStale)}
                        if let notice=context.state.vehicleNotice {Text(notice.title).font(.caption2)}
                    }.font(.caption)
                }
            } compactLeading: { Image(systemName:"car.side.fill").foregroundStyle(.teal) }
              compactTrailing: {
                  if let feedback=context.state.feedback,feedback.recent(at:Date()) {
                      Image(systemName:feedback.symbol).foregroundStyle(feedback.confirmed ? .green : .orange)
                  } else if let soc=context.state.car?.soc {Text("\(Int(soc))%").font(.caption2).foregroundStyle(.teal)}
                  else {Image(systemName:context.isStale ? "clock" : "antenna.radiowaves.left.and.right").foregroundStyle(.teal)}
              }
              minimal: {
                  Image(systemName:context.state.feedback.flatMap{$0.recent(at:Date()) ? $0.symbol : nil} ?? "car.side.fill").foregroundStyle(.teal)
              }
              .widgetURL(URL(string:"mgcontrol://bluetooth"))
        }
    }
}

