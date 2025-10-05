#!/usr/bin/env bash
# 说明：在 Linux 上构建并打包 Flutter 桌面应用为 .deb 和 .rpm
# 使用前提：
#   - 在 Linux 环境执行（打包需 Linux 工具链）
#   - 已安装 Flutter，并能正常 flutter build linux
#   - 可选：安装 fpm 以简化 rpm 打包（gem install fpm 或 apt/yum 安装）
# 运行示例：
#   chmod +x scripts/build_linux_pkgs.sh
#   ./scripts/build_linux_pkgs.sh
# 可配置环境变量（可选，均有默认值）：
#   VERSION=1.0.0
#   ARCH=auto               # auto 将自动探测 (x86_64/aarch64)
#   APP_ID=com.example.decibel_meter
#   APP_NAME="Decibel Meter"
#   BIN_NAME=decibel-meter
#   MAINTAINER="you@example.com"
#   VENDOR="Your Company"
#   DESCRIPTION="Cross-platform Flutter SPL meter"
#   LICENSE="Apache-2.0"
#   OUTPUT_DIR=dist/linux
#   FLUTTER_BUILD_DIR=build/linux
set -euo pipefail

command -v uname >/dev/null
OS="$(uname -s || true)"
if [[ "${OS}" != "Linux" ]]; then
  echo "此脚本需在 Linux 上执行（当前：${OS})"
  exit 1
fi

# 基本配置
VERSION="${VERSION:-1.0.0}"
ARCH_IN="${ARCH:-auto}"
APP_ID="${APP_ID:-com.example.decibel_meter}"
APP_NAME="${APP_NAME:-Decibel Meter}"
BIN_NAME="${BIN_NAME:-decibel-meter}"
PKG_NAME_DEB="decibel-meter"
PKG_NAME_RPM="decibel-meter"
MAINTAINER="${MAINTAINER:-you@example.com}"
VENDOR="${VENDOR:-Your Company}"
DESCRIPTION="${DESCRIPTION:-Cross-platform Flutter SPL meter}"
LICENSE_TXT="${LICENSE:-Apache-2.0}"
OUTPUT_DIR="${OUTPUT_DIR:-dist/linux}"
FLUTTER_BUILD_DIR="${FLUTTER_BUILD_DIR:-build/linux}"

# 依赖（Deb/RPM 名称可能因发行版不同略有差异，可按需调整）
DEB_DEPENDS="libc6, libstdc++6, libgtk-3-0, libgl1, libpulse0"
RPM_DEPENDS="glibc, libstdc++, gtk3, mesa-libGL, pulseaudio-libs"

# 探测架构
detect_arch() {
  local mach
  mach="$(uname -m)"
  case "$mach" in
    x86_64) echo "amd64" ;;         # Debian/Ubuntu 架构名
    aarch64|arm64) echo "arm64" ;;
    *) echo "$mach" ;;
  esac
}
detect_rpm_arch() {
  local mach
  mach="$(uname -m)"
  case "$mach" in
    x86_64) echo "x86_64" ;;
    aarch64|arm64) echo "aarch64" ;;
    *) echo "$mach" ;;
  esac
}

ARCH_DEB="$([[ "$ARCH_IN" == "auto" ]] && detect_arch || echo "$ARCH_IN")"
ARCH_RPM="$([[ "$ARCH_IN" == "auto" ]] && detect_rpm_arch || echo "$ARCH_IN")"

echo "版本：$VERSION"
echo "Deb 架构：$ARCH_DEB"
echo "RPM 架构：$ARCH_RPM"
echo "输出目录：$OUTPUT_DIR"

# 构建 Flutter Linux Release
echo "==> 构建 Flutter Linux Release"
command -v flutter >/dev/null 2>&1 || { echo "未找到 flutter，请先安装 Flutter SDK"; exit 1; }
flutter --version >/dev/null 2>&1 || true
flutter build linux --release

# 定位 bundle 目录（Flutter 默认路径）
# 典型路径：build/linux/x64/release/bundle
BUNDLE_DIR=""
if [[ -d "${FLUTTER_BUILD_DIR}/x64/release/bundle" ]]; then
  BUNDLE_DIR="${FLUTTER_BUILD_DIR}/x64/release/bundle"
elif [[ -d "${FLUTTER_BUILD_DIR}/arm64/release/bundle" ]]; then
  BUNDLE_DIR="${FLUTTER_BUILD_DIR}/arm64/release/bundle"
else
  # 尝试扫描
  BUNDLE_DIR="$(find "${FLUTTER_BUILD_DIR}" -type d -path "*/release/bundle" | head -n1 || true)"
fi

if [[ -z "${BUNDLE_DIR}" || ! -d "${BUNDLE_DIR}" ]]; then
  echo "未找到 Flutter Linux bundle 目录，请检查构建输出：${FLUTTER_BUILD_DIR}"
  exit 1
fi
echo "Bundle 目录：${BUNDLE_DIR}"

# 准备打包根目录（pkgroot 表示模拟安装到系统的根）
WORK_DIR="$(pwd)/build/linux_pkgwork"
PKGROOT="${WORK_DIR}/pkgroot"
DESKTOP_DIR="${PKGROOT}/usr/share/applications"
ICON_DIR="${PKGROOT}/usr/share/icons/hicolor/512x512/apps"
BIN_DIR="${PKGROOT}/usr/bin"
APP_DIR="${PKGROOT}/opt/decibel_meter"

rm -rf "${WORK_DIR}"
mkdir -p "${OUTPUT_DIR}" "${PKGROOT}" "${DESKTOP_DIR}" "${ICON_DIR}" "${BIN_DIR}" "${APP_DIR}"

# 拷贝应用内容到 /opt/decibel_meter
echo "==> 安装应用文件到 ${APP_DIR}"
cp -a "${BUNDLE_DIR}/." "${APP_DIR}/"

# 可执行文件名（Flutter 可执行在 bundle 根目录，通常同工程名；尝试自动探测）
EXE_PATH="$(find "${APP_DIR}" -maxdepth 1 -type f -perm -111 -printf "%f\n" 2>/dev/null | head -n1 || true)"
if [[ -z "${EXE_PATH}" ]]; then
  # 尝试匹配 Runner 名称
  if [[ -f "${APP_DIR}/decibel_meter" ]]; then
    EXE_PATH="decibel_meter"
  else
    echo "未能自动定位可执行文件，请手动检查 ${APP_DIR}，并调整脚本 EXE_PATH 检测逻辑"
    exit 1
  fi
fi
echo "检测到可执行：${EXE_PATH}"

# 创建 /usr/bin 启动器软链
ln -sf "/opt/decibel_meter/${EXE_PATH}" "${BIN_DIR}/${BIN_NAME}"

# Desktop 文件
DESKTOP_FILE="${DESKTOP_DIR}/${PKG_NAME_DEB}.desktop"
cat > "${DESKTOP_FILE}" <<EOF
[Desktop Entry]
Name=${APP_NAME}
Comment=${DESCRIPTION}
Exec=${BIN_NAME}
Icon=${PKG_NAME_DEB}
Terminal=false
Type=Application
Categories=AudioVideo;Utility;
EOF

# 图标：若项目存在 512 图标则拷贝；若没有则尝试从 bundle 中寻找
ICON_SRC_CANDIDATES=(
  "web/icons/Icon-512.png"
  "web/icons/icon-512.png"
  "assets/icon.png"
)
ICON_COPIED=0
for p in "${ICON_SRC_CANDIDATES[@]}"; do
  if [[ -f "$p" ]]; then
    cp "$p" "${ICON_DIR}/${PKG_NAME_DEB}.png"
    ICON_COPIED=1
    break
  fi
done
if [[ "${ICON_COPIED}" -eq 0 ]]; then
  # 从 bundle 寻找 png
  found="$(find "${APP_DIR}" -type f -name "*.png" | head -n1 || true)"
  if [[ -n "${found}" ]]; then
    cp "${found}" "${ICON_DIR}/${PKG_NAME_DEB}.png" || true
    ICON_COPIED=1
  fi
fi
if [[ "${ICON_COPIED}" -eq 0 ]]; then
  echo "未找到 512x512 图标，继续打包但应用菜单可能无图标"
fi

# ========== 构建 DEB ==========
build_deb() {
  echo "==> 构建 .deb 包"
  local DEB_ROOT="${WORK_DIR}/debroot"
  local DEBIAN_DIR="${DEB_ROOT}/DEBIAN"
  rm -rf "${DEB_ROOT}"
  mkdir -p "${DEB_ROOT}${PKGROOT}" "${DEBIAN_DIR}"

  # 拷贝 pkgroot 到 debroot（去掉前置 /）
  (cd "${PKGROOT}" && tar cf - .) | (cd "${DEB_ROOT}" && tar xpf -)

  # 生成 control
  cat > "${DEBIAN_DIR}/control" <<EOF
Package: ${PKG_NAME_DEB}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH_DEB}
Maintainer: ${MAINTAINER}
Description: ${DESCRIPTION}
Depends: ${DEB_DEPENDS}
Homepage: https://example.com/decibel_meter
EOF
  # 维护者脚本可选（postinst 更新缓存）
  cat > "${DEBIAN_DIR}/postinst" <<'EOF'
#!/bin/sh
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q /usr/share/icons/hicolor || true
fi
exit 0
EOF
  chmod 0755 "${DEBIAN_DIR}/postinst"

  # 构建
  local OUT_DEB="${OUTPUT_DIR}/${PKG_NAME_DEB}_${VERSION}_${ARCH_DEB}.deb"
  dpkg-deb --build "${DEB_ROOT}" "${OUT_DEB}"
  echo "DEB 产物：${OUT_DEB}"
}

# ========== 构建 RPM ==========
build_rpm_with_fpm() {
  echo "==> 使用 fpm 构建 .rpm"
  local OUT_RPM="${OUTPUT_DIR}/${PKG_NAME_RPM}-${VERSION}.${ARCH_RPM}.rpm"
  fpm -s dir -t rpm \
    -n "${PKG_NAME_RPM}" \
    -v "${VERSION}" \
    --license "${LICENSE_TXT}" \
    --vendor "${VENDOR}" \
    --maintainer "${MAINTAINER}" \
    --description "${DESCRIPTION}" \
    --rpm-os linux \
    --rpm-summary "${APP_NAME}" \
    --depends "${RPM_DEPENDS}" \
    --category "Utilities" \
    --url "https://example.com/decibel_meter" \
    --architecture "${ARCH_RPM}" \
    --prefix / \
    -C "${PKGROOT}" \
    --package "${OUT_RPM}" .
  echo "RPM 产物：${OUT_RPM}"
}

build_rpm_with_rpmbuild() {
  echo "==> 使用 rpmbuild 构建 .rpm"
  command -v rpmbuild >/dev/null 2>&1 || { echo "未安装 rpmbuild（rpm-build），无法生成 RPM"; return 1; }

  local RPMROOT="${WORK_DIR}/rpmroot"
  local SPEC_DIR="${RPMROOT}/SPECS"
  local BUILDROOT="${RPMROOT}/BUILDROOT"
  local SOURCES_DIR="${RPMROOT}/SOURCES"
  local RPMS_DIR="${RPMROOT}/RPMS"
  local SRPMS_DIR="${RPMROOT}/SRPMS"
  rm -rf "${RPMROOT}"
  mkdir -p "${SPEC_DIR}" "${BUILDROOT}" "${SOURCES_DIR}" "${RPMS_DIR}" "${SRPMS_DIR}"

  # 将 pkgroot 打包成 tar.gz 以供 rpmbuild 使用
  local SRC_TGZ="${SOURCES_DIR}/${PKG_NAME_RPM}-${VERSION}.tar.gz"
  (cd "${PKGROOT}" && tar czf "${SRC_TGZ}" .)

  # 生成 spec
  local SPEC_FILE="${SPEC_DIR}/${PKG_NAME_RPM}.spec"
  cat > "${SPEC_FILE}" <<EOF
Name:           ${PKG_NAME_RPM}
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        ${APP_NAME}
License:        ${LICENSE_TXT}
URL:            https://example.com/decibel_meter
Vendor:         ${VENDOR}
Packager:       ${MAINTAINER}
Requires:       ${RPM_DEPENDS}
BuildArch:      ${ARCH_RPM}

%description
${DESCRIPTION}

%prep
%setup -q -c -T -a 0

%build

%install
mkdir -p %{buildroot}
tar xzf %{SOURCE0} -C %{buildroot}

%files
/opt/decibel_meter
/usr/bin/${BIN_NAME}
/usr/share/applications/${PKG_NAME_DEB}.desktop
/usr/share/icons/hicolor/512x512/apps/${PKG_NAME_DEB}.png

%post
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -q /usr/share/icons/hicolor || true
fi

%changelog
* $(date +"%a %b %d %Y") ${MAINTAINER} ${VERSION}-1
- Initial RPM release
EOF

  rpmbuild \
    --define "_topdir ${RPMROOT}" \
    --define "_target_cpu ${ARCH_RPM}" \
    -bb "${SPEC_FILE}" \
    --define "SOURCE0 ${SRC_TGZ}"

  # 拷贝输出
  find "${RPMROOT}/RPMS" -type f -name "*.rpm" -exec cp {} "${OUTPUT_DIR}/" \;
  echo "RPM 产物位于：${OUTPUT_DIR}"
}

# 执行打包
# .deb 优先使用 dpkg-deb（原生）
if command -v dpkg-deb >/dev/null 2>&1; then
  build_deb
else
  echo "未找到 dpkg-deb，尝试使用 fpm 生成 .deb"
  command -v fpm >/dev/null 2>&1 || { echo "未安装 fpm，无法生成 .deb"; }
  if command -v fpm >/dev/null 2>&1; then
    fpm -s dir -t deb \
      -n "${PKG_NAME_DEB}" \
      -v "${VERSION}" \
      --license "${LICENSE_TXT}" \
      --vendor "${VENDOR}" \
      --maintainer "${MAINTAINER}" \
      --description "${DESCRIPTION}" \
      --deb-compression xz \
      --category "utils" \
      --url "https://example.com/decibel_meter" \
      --architecture "${ARCH_DEB}" \
      --depends "${DEB_DEPENDS}" \
      --prefix / \
      -C "${PKGROOT}" \
      --package "${OUTPUT_DIR}/${PKG_NAME_DEB}_${VERSION}_${ARCH_DEB}.deb" .
  fi
fi

# .rpm：优先使用 fpm，若无则尝试 rpmbuild
if command -v fpm >/dev/null 2>&1; then
  build_rpm_with_fpm || true
else
  build_rpm_with_rpmbuild || true
fi

echo "完成。产物目录：${OUTPUT_DIR}"
ls -lah "${OUTPUT_DIR}" || true

# 常见依赖安装提示（不同发行版略有差异）：
# Debian/Ubuntu：
#   sudo apt-get update
#   sudo apt-get install -y dpkg-dev rpm ruby ruby-dev rubygems build-essential
#   sudo gem install --no-document fpm
# Fedora/CentOS/RHEL：
#   sudo dnf install -y rpm-build ruby rubygems gcc make
#   sudo gem install --no-document fpm