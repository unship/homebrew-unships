class AppleEventsMcp < Formula
  desc "MCP server integrating Apple Reminders and Calendar via EventKit"
  homepage "https://github.com/farmerajf/apple-events-mcp"
  url "https://github.com/farmerajf/apple-events-mcp/archive/5445d08ece0ba532775a0a43e057adccd4a28511.tar.gz"
  version "2026.03.23"
  sha256 "4303d104e9c37ea8e7c9c0766a4f5b0bf8e34349c7cf64d845f939296cd2f40b"
  license :cannot_represent

  depends_on macos: :sonoma
  depends_on xcode: ["16.0", :build]

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release"
    bin.install ".build/release/apple-events-mcp"
  end

  test do
    # Server is long-running; assert the binary launches and aborts cleanly
    # when stdin closes (stdio transport is the default).
    pid = spawn(bin/"apple-events-mcp", in: "/dev/null", out: "/dev/null", err: "/dev/null")
    sleep 1
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
