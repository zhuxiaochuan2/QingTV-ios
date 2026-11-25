import SwiftUI

struct DetailView: View {
    @EnvironmentObject var store: Store
    let title: String
    let pic: String
    let rate: String

    @State private var lines: [PlayLine] = []
    @State private var msg = "正在搜源…"
    @State private var sel = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                AsyncImage(url: URL(string: pic)) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.white.opacity(0.06)
                }
                .frame(width: 96, height: 136)
                .clipped()
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.title3).bold().foregroundColor(.white)
                    if !rate.isEmpty {
                        Text("评分 \(rate)").font(.subheadline).foregroundColor(.orange)
                    }
                    Text(msg).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(16)

            if !lines.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(lines.enumerated()), id: \.element.id) { i, l in
                            Button("\(l.site)·\(l.name)") { sel = i }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(i == sel ? Color.blue : Color.white.opacity(0.08))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .font(.footnote)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(lines[sel].eps) { e in
                            NavigationLink(destination: PlayerView(urlString: e.url, title: "\(title) \(e.name)")) {
                                Text(e.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(Color.white.opacity(0.08))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(16)
                }
            }

            Spacer(minLength: 0)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await search() }
    }

    private func search() async {
        let kw = Douban.keyword(title)
        var acc: [PlayLine] = []
        await withTaskGroup(of: [PlayLine].self) { group in
            for s in store.sites.prefix(10) {
                group.addTask { await Cms.search(s, kw: kw) }
            }
            for await r in group {
                acc.append(contentsOf: r)
                let snap = acc
                await MainActor.run {
                    lines = snap
                    msg = snap.isEmpty ? "搜索中…" : "找到 \(snap.count) 条线路"
                }
            }
        }
        if acc.isEmpty {
            await MainActor.run { msg = "没搜到能播的，回首页换个片或直接搜索" }
        }
    }
}
