# typed: false
# frozen_string_literal: true

class Cream < Formula
  desc "Native binary that runs full JVM Clojure with fast startup using GraalVM Crema"
  homepage "https://github.com/borkdude/cream"
  version "dev"
  license "EPL-1.0"

  on_macos do
    on_arm do
      url "https://github.com/borkdude/cream/releases/download/dev/cream-macos-aarch64.tar.gz"
      sha256 "c0c6feee1ac439f388a17748cafad4b17e0d795e4997f4c68682e39e218248b1"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/borkdude/cream/releases/download/dev/cream-linux-amd64.tar.gz"
      sha256 "9c2239f0b60f8bc61abdadca44fdafcca34bcdece83b6452dd9e7a894a1d115b"
    end
  end

  def install
    bin.install "cream"
  end

  test do
    assert_match "6", shell_output("#{bin}/cream -M -e '(+ 1 2 3)'")
  end
end
