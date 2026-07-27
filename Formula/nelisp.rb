class Nelisp < Formula
  desc "Self-hosted Emacs Lisp VM with pure-Elisp runtime, JIT, and AOT compiler"
  homepage "https://github.com/zawatton/nelisp"
  url "https://github.com/zawatton/nelisp/archive/3b21de37b408141f75c580d06bf9309a3603d052.tar.gz"
  version "0.6.0"
  sha256 "cc1081b06e35c86f4498daa9495dbdcba7c2f26c78fc99583e590467aadf7bfc"
  license "GPL-3.0-only"
  head "https://github.com/zawatton/nelisp.git", branch: "main"
  revision 1

  # Use the user's PATH so `emacs` from a non-Homebrew install
  # (Emacs.app, emacs-plus, etc.) is visible during the build.
  env :std

  # Emacs (batch mode) is required for the pure-Elisp AOT build.
  # The standalone binary is built via `make standalone-reader` with
  # NELISP_STANDALONE_TARGET set to the platform triple.
  # On macOS arm64 the binary is ad-hoc codesigned after linking.
  depends_on "emacs" => :build

  def install
    target = if OS.mac?
      Hardware::CPU.arm? ? "macos-aarch64" : odie("macOS x86_64 is not supported by nelisp upstream")
    else
      Hardware::CPU.arm? ? "linux-aarch64" : "linux-x86_64"
    end
    ENV["NELISP_STANDALONE_TARGET"] = target
    system "make", "standalone-reader"
    bin.install "target/nelisp"
    # Also install Elisp sources so nelisp can be used within Emacs.
    elisp = share/"emacs/site-lisp/nelisp"
    elisp.install Dir["lisp/*.el"]
    elisp.install Dir["src/*.el"]
    elisp.install Dir["packages/*/src/*.el"]
    (elisp/"scripts").install Dir["scripts/*.el"]
  end

  def caveats
    <<~EOS
      To use nelisp from within Emacs, add to your init.el:

        (add-to-list 'load-path "#{share}/emacs/site-lisp/nelisp")
        (add-to-list 'load-path "#{share}/emacs/site-lisp/nelisp/scripts")
        (require 'nelisp-bootstrap)
        (nelisp-bootstrap-init)
        (nelisp-eval-string "(+ 1 2 3)")  ; => 6
    EOS
  end

  test do
    assert_match "42", shell_output("#{bin}/nelisp --eval '(+ 40 2)'")
  end
end
