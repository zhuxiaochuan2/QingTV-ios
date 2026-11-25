import SwiftUI
import AVKit

struct PlayerView: View {
    let urlString: String
    let title: String

    @State private var real: String?
    @State private var headers: [String: String] = [:]
    @State private var err: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let r = real, let u = URL(string: r) {
                VideoPlayer(url: u, headers: headers)
                    .ignoresSafeArea()
            } else if let e = err {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle").font(.largeTitle)
                    Text(e).font(.callout)
                }
                .foregroundColor(.secondary)
            } else {
                ProgressView("解析播放地址…").tint(.white)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await resolve() }
    }

    private func resolve() async {
        // 播放页大多是 html，里面藏着 m3u8；解析出来再交给 AVPlayer
        let m = await Resolver.m3u8(from: urlString)
        let h = Resolver.headers(for: urlString)
        await MainActor.run {
            if let m = m { real = m; headers = h }
            else { err = "这条线路解析不出来，返回换一条" }
        }
    }
}

/// 带 Referer 的 AVPlayer：防盗链源也能播
struct VideoPlayer: UIViewControllerRepresentable {
    let url: URL
    let headers: [String: String]

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        var options: [String: Any] = [:]
        if !headers.isEmpty {
            options["AVURLAssetHTTPHeaderFieldsKey"] = headers
        }
        let asset = AVURLAsset(url: url, options: options)
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        player.allowsExternalPlayback = true
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = true
        vc.entersFullScreenWhenPlaybackBegins = true
        player.play()
        return vc
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
