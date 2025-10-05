#!/usr/bin/env bash
# 说明：构建并打包 macOS 应用（arm64 / x86_64 / universal 三种架构）
# 要求：
# - 已安装 Flutter 与 Xcode
# - 在项目根目录执行本脚本
# - 如需签名/公证，请在“可选：签名与公证”段落按需启用并配置
set -euo pipefail

# ---------------------------
# 基本配置（可按需修改）
# ---------------------------
APP_SCHEME="Runner"                                 # Xcode Scheme 名称（Flutter 默认 Runner）
WORKSPACE="macos/Runner.xcworkspace"                # Xcode Workspace 路径
CONFIG="Release"                                    # 编译配置
DERIVED_ROOT="$(pwd)/build/macos"                   # 派生数据输出目录
OUTPUT_DIR="$(pwd)/dist/macos"                      # 产物输出目录
VOL_NAME="Decibel Meter Mac Installer"              # DMG 卷名
APP_NAME_DMG_PREFIX="Decibel Meter"                 # DMG 文件名前缀
DMG_FORMAT="UDZO"                                   # DMG 压缩格式：UDZO（压缩）/UDRO（只读）等

# 可选：签名与公证（按需启用）
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"          # 例如："Developer ID Application: Your Name (TEAMID)"
TEAM_ID="${TEAM_ID:-}"                              # 例如："ABCDE12345"
ENABLE_CODESIGN="${ENABLE_CODESIGN:-0}"             # 1 启用签名；0 关闭
ENABLE_NOTARIZE="${ENABLE_NOTARIZE:-0}"             # 1 启用公证；0 关闭
NOTARY_APPLE_ID="${NOTARY_APPLE_ID:-}"              # Apple ID
NOTARY_TEAM_ID="${NOTARY_TEAM_ID:-}"                # Team ID
NOTARY_APP_PASSWORD="${NOTARY_APP_PASSWORD:-}"      # app 专用密码或钥匙串引用

# ---------------------------
# 前置检查
# ---------------------------
command -v flutter >/dev/null 2>&1 || { echo "未找到 flutter 命令，请先安装 Flutter SDK"; exit 1; }
command -v xcodebuild >/dev/null 2>&1 || { echo "未找到 xcodebuild，请先安装 Xcode 命令行工具"; exit 1; }
command -v hdiutil >/dev/null 2>&1 || { echo "未找到 hdiutil（macOS 自带），请在 macOS 上运行"; exit 1; }

mkdir -p "$OUTPUT_DIR"

# ---------------------------
# 函数：构建指定架构
# 参数：$1 架构标识：arm64 | x86_64 | universal
# ---------------------------
build_for_arch() {
  local arch_label="$1"
  local derived="$DERIVED_ROOT/$arch_label"
  local archs_value=""
  case "$arch_label" in
    arm64) archs_value="arm64" ;;
    x86_64) archs_value="x86_64" ;;
    universal) archs_value="arm64 x86_64" ;;
    *) echo "未知架构：$arch_label"; exit 1 ;;
  esac

  echo "==> [准备] Flutter 生成工程/Pods（首次或配置变更时需要）"
  # 说明：这里跑一次 flutter build macos 确保 Pods/ephemeral 准备好
  flutter build macos --release

  echo "==> [构建] $arch_label （ARCHS='${archs_value}'）"
  # 使用 xcodebuild 指定 ARCHS；ONLY_ACTIVE_ARCH=NO 以确保多架构构建
  # 使用 -derivedDataPath 定向输出，避免互相覆盖
  xcodebuild \
    -workspace "$WORKSPACE" \
    -scheme "$APP_SCHEME" \
    -configuration "$CONFIG" \
    -derivedDataPath "$derived" \
    ONLY_ACTIVE_ARCH=NO \
    ARCHS="$archs_value" \
    EXCLUDED_ARCHS="" \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGN_IDENTITY="" \
    clean build | xcpretty || true

  # xcodebuild 可能返回 0 以外但产物已生成，使用 xcpretty 时容忍非零并继续检查产物
  local products_dir="$derived/Build/Products/$CONFIG"
  if [ ! -d "$products_dir" ]; then
    echo "未找到构建产物目录：$products_dir"
    exit 1
  fi
  # 查找 .app
  local app_path
  app_path="$(/usr/bin/find "$products_dir" -maxdepth 1 -name "*.app" -print -quit)"
  if [ -z "${app_path:-}" ]; then
    echo "未找到 .app 产物，请检查 xcodebuild 日志。"
    exit 1
  fi

  # 可选：签名（仅当启用）
  if [ "$ENABLE_CODESIGN" = "1" ]; then
    if [ -z "$CODESIGN_IDENTITY" ]; then
      echo "已启用签名但未设置 CODESIGN_IDENTITY"
      exit 1
    fi
    echo "==> [签名] $app_path"
    codesign --force --deep --options runtime --sign "$CODESIGN_IDENTITY" "$app_path"
    codesign --verify --deep --strict "$app_path"
  fi

  # 拷贝标准化命名的 .app 到输出目录
  local dest_app="$OUTPUT_DIR/${APP_NAME_DMG_PREFIX}-${arch_label}.app"
  rm -rf "$dest_app"
  cp -R "$app_path" "$dest_app"

  # 打包 DMG
  package_dmg "$arch_label" "$dest_app"
}

# ---------------------------
# 函数：打包 DMG
# 参数：$1 架构标识；$2 .app 路径
# ---------------------------
package_dmg() {
  local arch_label="$1"
  local app_src="$2"
  local stage_dir="$(pwd)/build/macos_stage_$arch_label"
  local dmg_path="$OUTPUT_DIR/${APP_NAME_DMG_PREFIX}-${arch_label}.dmg"

  echo "==> [打包] 生成 DMG（$arch_label）"
  rm -rf "$stage_dir"
  mkdir -p "$stage_dir"
  ln -sf /Applications "$stage_dir/Applications"
  cp -R "$app_src" "$stage_dir/"

  # 生成 DMG
  hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$stage_dir" \
    -ov -format "$DMG_FORMAT" \
    "$dmg_path" >/dev/null

  # 可选：公证
  if [ "$ENABLE_NOTARIZE" = "1" ]; then
    if [ -z "$NOTARY_APPLE_ID" ] || [ -z "$NOTARY_TEAM_ID" ] || [ -z "$NOTARY_APP_PASSWORD" ]; then
      echo "已启用公证但未设置 NOTARY_APPLE_ID / NOTARY_TEAM_ID / NOTARY_APP_PASSWORD"
      exit 1
    fi
    echo "==> [公证] 上传 DMG 到 Apple Notary Service（$dmg_path）"
    xcrun notarytool submit "$dmg_path" \
      --apple-id "$NOTARY_APPLE_ID" \
      --team-id "$NOTARY_TEAM_ID" \
      --password "$NOTARY_APP_PASSWORD" \
      --wait
    echo "==> [附加公证票据] stapler"
    xcrun stapler staple "$dmg_path"
  fi

  echo "==> [完成] $dmg_path"
}

# ---------------------------
# 主流程
# ---------------------------
echo "输出目录：$OUTPUT_DIR"
echo "开始构建：arm64、x86_64、universal 三个变体"

build_for_arch "arm64"
build_for_arch "x86_64"
build_for_arch "universal"

echo "全部完成。产物位于：$OUTPUT_DIR"
echo "文件示例："
ls -lh "$OUTPUT_DIR" || true

# 使用方法：
# 1) 赋予执行权限：chmod +x scripts/build_macos_pkgs.sh
# 2) 运行脚本：    ./scripts/build_macos_pkgs.sh
# 可选环境变量：
#   ENABLE_CODESIGN=1 CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
#   ENABLE_NOTARIZE=1 NOTARY_APPLE_ID="apple@id.com" NOTARY_TEAM_ID="ABCDE12345" NOTARY_APP_PASSWORD="@keychain:AC_PASSWORD"