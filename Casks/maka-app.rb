# Homebrew Cask for Maka
#
# Maka is a local-first AI desktop assistant that runs entirely on your machine.
# It provides a desktop app (Electron + React), TUI/CLI, and headless mode.
#
# Installation:
#   brew tap unship/unships
#   brew install --cask maka
#
# After installation, launch Maka from Applications and configure your model
# connection under Settings → Models.
#
# Note: Currently only supports Apple Silicon macOS (arm64).
# Intel Macs, Windows, and Linux are not supported yet.

cask "maka-app" do
  version "0.1.3"
  sha256 "7949768ca2db9b54b9206a8c6cf48b19568100ff4d33013a1a7590f0e5078921"

  url "https://github.com/maka-agent/maka-agent/releases/download/v#{version}/Maka-#{version}-mac-arm64.dmg",
      verified: "github.com/maka-agent/maka-agent/"
  name "Maka"
  desc "Local-first AI desktop assistant"
  homepage "https://github.com/maka-agent/maka-agent"

  # Only supports Apple Silicon macOS
  depends_on macos: :big_sur
  depends_on arch: :arm64

  app "Maka.app"

  zap trash: [
    "~/Library/Application Support/maka",
    "~/Library/Caches/com.maka.desktop",
    "~/Library/Preferences/com.maka.desktop.plist",
  ]

  caveats <<~EOS
    Maka has been installed to /Applications.

    Requirements:
      - Apple Silicon Mac (M1/M2/M3/M4)
      - macOS Big Sur or later

    Optional:
      - Install ripgrep for Grep tool support: brew install ripgrep

    After launching Maka, configure your model connection under Settings → Models.
    Supported providers: Claude, Codex, GitHub Copilot, Cursor/Antigravity.
  EOS
end
