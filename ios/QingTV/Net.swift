import Foundation

enum NetError: Error { case badURL, http(Int), decode }

enum Net {
    static let ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    static func data(_ urlString: String, referer: String? = nil, timeout: TimeInterval = 15) async throws -> Data {
        guard let url = URL(string: urlString) else { throw NetError.badURL }
        var req = URLRequest(url: url, timeoutInterval: timeout)
        req.setValue(ua, forHTTPHeaderField: "User-Agent")
        req.setValue("*/*", forHTTPHeaderField: "Accept")
        if let r = referer { req.setValue(r, forHTTPHeaderField: "Referer") }
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 { throw NetError.http(http.statusCode) }
        return data
    }

    static func text(_ urlString: String, referer: String? = nil, timeout: TimeInterval = 15) async throws -> String {
        let d = try await data(urlString, referer: referer, timeout: timeout)
        if let s = String(data: d, encoding: .utf8), !s.contains("\u{FFFD}") { return s }
        let gbk = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        if let s = String(data: d, encoding: String.Encoding(rawValue: gbk)) { return s }
        return String(decoding: d, as: UTF8.self)
    }

    static func json(_ urlString: String, referer: String? = nil, timeout: TimeInterval = 15) async throws -> [String: Any] {
        let t = try await text(urlString, referer: referer, timeout: timeout)
        guard let i = t.firstIndex(of: "{") else { throw NetError.decode }
        let sub = String(t[i...])
        guard let d = sub.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else { throw NetError.decode }
        return obj
    }

    /// raw.githubusercontent 国内连不上，自动走镜像
    static func anyText(_ urlString: String) async -> String? {
        var cands = [urlString]
        if urlString.contains("raw.githubusercontent.com") {
            cands.append("https://gh-proxy.org/" + urlString)
            cands.append("https://ghfast.top/" + urlString)
            if let m = urlString.range(of: "raw.githubusercontent.com/") {
                let rest = urlString[m.upperBound...]
                let parts = rest.split(separator: "/", maxSplits: 3).map(String.init)
                if parts.count == 4 {
                    cands.append("https://cdn.jsdelivr.net/gh/\(parts[0])/\(parts[1])@\(parts[2])/\(parts[3])")
                }
            }
        }
        for c in cands {
            if let t = try? await text(c), t.count > 20 { return t }
        }
        return nil
    }
}
