#!/bin/bash
# 在有 macOS 的机器上一键出未签名 ipa
# 用法： bash build-mac.sh
set -euo pipefail

echo "==> 检查 xcodegen"
if ! command -v xcodegen >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install xcodegen
  else
    echo "没有 xcodegen 也没 brew，先装 Homebrew："
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
  fi
fi

cd "$(dirname "$0")/ios"

echo "==> 生成 Xcode 工程"
xcodegen generate

echo "==> 编译 Release（不签名）"
xcodebuild \
  -project QingTV.xcodeproj \
  -scheme QingTV \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP="build/Build/Products/Release-iphoneos/QingTV.app"
echo "==> 产物：$APP"

echo "==> 打 ipa"
cd ..
rm -rf Payload QingTV.ipa
mkdir Payload
cp -R "ios/$APP" Payload/
zip -qry QingTV.ipa Payload
ls -lh QingTV.ipa

echo
echo "完成：$(pwd)/QingTV.ipa（未签名）"
echo "下一步：Sideloadly 拖进去，填 Apple ID 签一下，手机上信任证书即可"
