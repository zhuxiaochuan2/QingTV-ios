import SwiftUI

struct LiveView: View {
    @EnvironmentObject var store: Store
    @State private var chs: [Channel] = []
    @State private var msg = "读取直播源…"
    @State private var playing: Channel?

    var body: some View {
        NavigationView {
            ZStack {
                List(chs) { c in
                    Button {
                        playing = c
                    } label: {
                        HStack {
                            Text(c.name).foregroundColor(.white)
                            Spacer()
                            Image(systemName: "play.circle").foregroundColor(.blue)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .listStyle(.plain)

                if chs.isEmpty {
                    Text(msg).foregroundColor(.secondary)
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("直播")
            .toolbar {
                Button {
                    Task { await load() }
                } label: { Image(systemName: "arrow.clockwise") }
            }
            .task { if chs.isEmpty { await load() } }
            .sheet(item: $playing) { c in
                NavigationView {
                    PlayerView(urlString: c.url, title: c.name)
                }
            }
        }
    }

    private func load() async {
        msg = "读取直播源…"
        let r = await Live.channels(from: store.lives)
        await MainActor.run {
            chs = r
            msg = r.isEmpty ? "直播源没拉到，稍后再试" : ""
        }
    }
}
