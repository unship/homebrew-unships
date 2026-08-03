# typed: false
# frozen_string_literal: true

# Maka CLI - Local-first AI desktop assistant (CLI/TUI component)
#
# This formula installs the `maka` command-line tool from the Maka monorepo.
# For the desktop app, use: brew install --cask maka
#
# Maka is a TypeScript monorepo using npm workspaces. The CLI requires:
# - Node.js >= 22.19.0
# - Building multiple internal packages (@maka/core, @maka/runtime, etc.)
# - Native dependencies (node-pty, fs-native-extensions)
#
# The build process compiles TypeScript to JavaScript in each package's dist/
# directory. The CLI entry point is packages/cli/dist/cli.js.

class Maka < Formula
  desc "Local-first AI desktop assistant (CLI/TUI)"
  homepage "https://github.com/maka-agent/maka-agent"
  url "https://github.com/maka-agent/maka-agent/archive/refs/tags/v0.1.3.tar.gz"
  sha256 "a1eb5bcd3e2c8307198e2535276d273c7385609cb80d28ba9a843e6febeb617d"
  license "Apache-2.0"

  # Node.js 22.19.0+ required (engines field in package.json)
  depends_on "node@22" => :build

  # Native dependencies need to be rebuilt for the target Node version
  on_macos do
    depends_on "python@3.13" => :build # for node-gyp
  end

  on_linux do
    depends_on "gcc" => :build # for node-pty
    depends_on "python@3.13" => :build
  end

  def install
    # Skip postinstall (install-electron) - we only need the CLI
    # Build only CLI-related packages, not the desktop app
    system "npm", "ci", "--ignore-scripts", "--no-audit", "--no-fund"

    # Build packages in dependency order (skip ui and desktop)
    # Order: core -> storage -> mcp -> runtime -> runtime-host -> computer-use -> headless -> cli
    packages = %w[
      @maka/core
      @maka/storage
      @maka/mcp
      @maka/runtime
      @maka/runtime-host
      @maka/computer-use
      @maka/headless
      maka-agent
    ]

    packages.each do |pkg|
      system "npm", "run", "build", "--workspace", pkg
    end

    # Install the CLI package with its dependencies
    # The CLI needs the compiled dist/ files from all internal packages
    libexec.install "packages"
    libexec.install "node_modules"
    libexec.install "package.json"
    libexec.install "package-lock.json"

    # Create bin wrapper that sets up Node environment and runs the CLI
    (bin/"maka").write_env_script(
      libexec/"packages/cli/dist/cli.js",
      NODE_PATH: libexec/"node_modules",
    )

    # Also install as maka-agent (alias)
    bin.install_symlink "maka" => "maka-agent"
  end

  def caveats
    <<~EOS
      Maka CLI has been installed.

      For the desktop app, use:
        brew install --cask maka

      Optional dependencies:
        - ripgrep: for Grep tool support (brew install ripgrep)

      After running Maka for the first time, configure your model connection
      under Settings → Models. Supported providers: Claude, Codex, GitHub
      Copilot, Cursor/Antigravity.

      Note: Maka requires Node.js 22.19.0 or later.
    EOS
  end

  test do
    # Verify the CLI can at least start and show help
    assert_match "Usage", shell_output("#{bin}/maka --help 2>&1", 1)
  end
end
