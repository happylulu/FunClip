import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "video.badge.checkmark")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("FunClip iOS")
                .font(.largeTitle.bold())
            Text("Ready to build!")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
