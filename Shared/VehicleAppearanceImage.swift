import SwiftUI

struct VehicleAppearanceImage: View {
    let appearance: VehicleAppearance
    var body: some View {
        Image(appearance.assetName).resizable().scaledToFit()
            .accessibilityLabel("2026 款 MG4 · " + appearance.title)
    }
}
