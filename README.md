# QingTV（轻电视 iOS）

SwiftUI 写的影视客户端壳：豆瓣发现 + cms 搜索 + m3u8 解析 + AVPlayer + m3u 直播。

## 出 ipa

推上来之后 Actions 里 workflow **build-ipa** 会自动跑，产物在 Artifacts 的 QingTV-ipa。
是**未签名 ipa**，用 Sideloadly / 爱思助手 本机签一下就能装。

## 本地（有 Mac）

    brew install xcodegen
    cd ios && xcodegen generate
    open QingTV.xcodeproj   # Team 选你的 Apple ID，选真机，⌘R
