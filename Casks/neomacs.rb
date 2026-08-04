# Homebrew Cask for Neomacs
#
# Neomacs is a Rust rewrite of Emacs with a GPU display engine.
# It provides a modern, high-performance Emacs experience while maintaining
# compatibility with the Emacs ecosystem (init.el, packages, muscle memory).
#
# This cask installs Neomacs.app alongside emacs-plus without conflicts:
# - App name: neomacs.app (not Emacs.app)
# - Binary name: neomacs (not emacs)
# - Bundle ID: org.neomacs (not org.gnu.emacs)
#
# Installation:
#   brew tap unship/unships
#   brew install --cask neomacs
#
# After installation, launch Neomacs from Applications or run `neomacs` in terminal.
#
# Note: Currently only supports Apple Silicon macOS (arm64).

cask "neomacs" do
  version "0.0.14"
  sha256 "8ad503aa532879e9890dcbfc81d854ec70f6024ff4ff3fcaf1251a2b6f63d992"

  url "https://github.com/eval-exec/neomacs/releases/download/v#{version}/neomacs-#{version}-aarch64-apple-darwin.dmg",
      verified: "github.com/eval-exec/neomacs/"
  name "Neomacs"
  desc "Emacs rewritten in Rust with GPU display engine"
  homepage "https://github.com/eval-exec/neomacs"

  depends_on macos: :monterey
  depends_on arch: :arm64
  depends_on formula: "gstreamer"

  app "neomacs.app"

  # Create wrapper scripts to avoid conflicts with emacs-plus
  # Default `neomacs` uses isolated config (~/.neomacs.d)
  # `neomacs-shared` uses standard config (~/.emacs.d)
  postflight do
    neomacs_bin = "#{appdir}/neomacs.app/Contents/MacOS/neomacs"
    neomacsclient_bin = "#{appdir}/neomacs.app/Contents/MacOS/neomacsclient"

    # Wrapper for isolated config (default)
    (HOMEBREW_PREFIX/"bin/neomacs").write <<~EOS
      #!/bin/bash
      exec "#{neomacs_bin}" --init-directory="$HOME/.neomacs.d" "$@"
    EOS
    (HOMEBREW_PREFIX/"bin/neomacs").chmod 0755

    # Wrapper for shared config
    (HOMEBREW_PREFIX/"bin/neomacs-shared").write <<~EOS
      #!/bin/bash
      exec "#{neomacs_bin}" "$@"
    EOS
    (HOMEBREW_PREFIX/"bin/neomacs-shared").chmod 0755

    # Client for isolated config
    (HOMEBREW_PREFIX/"bin/neomacsclient").write <<~EOS
      #!/bin/bash
      exec "#{neomacsclient_bin}" --server-name=neomacs "$@"
    EOS
    (HOMEBREW_PREFIX/"bin/neomacsclient").chmod 0755
  end

  uninstall_preflight do
    # Clean up wrapper scripts
    ["neomacs", "neomacs-shared", "neomacsclient"].each do |script|
      (HOMEBREW_PREFIX/"bin/#{script}").unlink if (HOMEBREW_PREFIX/"bin/#{script}").exist?
    end
  end

  zap trash: [
    "~/.neomacs.d",
    "~/Library/Application Support/neomacs",
    "~/Library/Caches/org.neomacs",
    "~/Library/Preferences/org.neomacs.plist",
  ]

  caveats <<~EOS
    Neomacs has been installed to /Applications.

    Requirements:
      - Apple Silicon Mac (M1/M2/M3/M4)
      - macOS Monterey or later

    配置隔离（避免与 emacs-plus 冲突）：
      - `neomacs` 使用独立配置 (~/.neomacs.d)
      - `neomacs-shared` 使用标准配置 (~/.emacs.d)
      - `neomacsclient` 连接到独立配置的 server

    从 Applications 启动或使用命令行 `neomacs`。
  EOS
end
