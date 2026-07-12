class RimeDaemon < Formula
  desc "Share one RIME engine and user dictionary across Emacs instances"
  homepage "https://github.com/unship/rime-daemon"
  url "https://github.com/unship/rime-daemon/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "72e4215d9c8f054519d958a8b625f756cb1540285b41db96bda2f04b2eb23237"
  license "BSD-3-Clause"
  head "https://github.com/unship/rime-daemon.git", branch: "main"

  depends_on "rust" => :build
  depends_on "librime"

  # liberime(GPL-3.0)仅在构建期取源码编出 emacs 模块,产物动态链接本包的 shim
  resource "liberime" do
    url "https://github.com/emacs-rime/liberime.git",
        revision: "482b7854b04169b348f3c943891f0895bd38bc4f"
  end

  def install
    ENV["RIME_INCLUDE_DIR"] = Formula["librime"].opt_include.to_s
    ENV["RIME_LIB_DIR"] = Formula["librime"].opt_lib.to_s
    system "cargo", "build", "--release"

    bin.install "target/release/rime-cli"

    shimdir = lib/"rime-daemon"
    shimdir.mkpath
    shim = shimdir/"librime.1.dylib"
    cp "target/release/librime_shim.dylib", shim
    # 必须在编 liberime-core 之前把 shim 的 LC_ID 显式改成 opt 路径。cargo 产物的
    # LC_ID 是构建期临时路径(.../target/release/deps/librime_shim.dylib);ld 会把
    # 被链接 dylib 当时的 LC_ID 记进 liberime-core 的依赖项(不是命令行传的路径)。
    # 交给 brew keg relocation 不行:shim 被改名(librime_shim→librime.1)又跨目录,
    # brew 只重写一半(shim 自身 id 的前缀),liberime-core 仍指向已删的临时路径 →
    # "Library not loaded"。这是 v0.2.1 相对 v0.1.0 删掉此行导致的回归。
    # 副作用:同一 Emacs 进程内跨版本热切换不可行(dyld 按路径去重)→ 升级后重启 Emacs。
    stable_shim = opt_lib/"rime-daemon/librime.1.dylib"
    system "install_name_tool", "-id", stable_shim, shim

    resource("liberime").stage do
      emacs_module = Dir["emacs-module/*"].max_by { |d| File.basename(d).to_i }
      system ENV.cc, "-shared", "-fPIC", "-O2", "-DHAVE_RIME_API",
             "-I", "src", "-I", emacs_module,
             "-I", Formula["librime"].opt_include.to_s,
             *Dir["src/*.c"], shim.to_s,
             "-o", (shimdir/"liberime-core.dylib").to_s
    end

    system "codesign", "-f", "-s", "-",
           shim, shimdir/"liberime-core.dylib", bin/"rime-cli"
  end

  def caveats
    <<~EOS
      Emacs(liberime/pyim)配置:

        (setq liberime-auto-build nil
              liberime-module-file "#{opt_lib}/rime-daemon/liberime-core.dylib")

      rime-cli 已在 PATH 上,shim 会自动懒启动 daemon,无需额外环境变量。
      改完配置后重启所有 Emacs 实例(旧实例内嵌的 librime 仍锁着用户词典)。
      详见 https://github.com/unship/rime-daemon/blob/main/docs/emacs-integration.md
    EOS
  end

  test do
    output = shell_output("#{bin}/rime-cli 2>&1", 2)
    assert_match "usage", output
  end
end
