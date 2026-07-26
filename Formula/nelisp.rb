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

  # Emacs (batch mode) is required for the pure-Elisp AOT build on Linux.
  # On macOS the standalone build is not yet supported by upstream
  # (Mach-O linker limitation: no RW sections in executables).
  # The formula still installs the Elisp sources for use within Emacs.
  # Install Emacs first if you don't have it, e.g.:
  #   brew install emacs          # homebrew/core
  #   brew install emacs-plus     # d12frosted/emacs-plus

  def install
    if OS.linux?
      target = Hardware::CPU.arm? ? "linux-aarch64" : "linux-x86_64"
      ENV["NELISP_STANDALONE_TARGET"] = target
      system "make", "standalone-reader"
      bin.install "target/nelisp"
    else
      # macOS: install Elisp sources for use within Emacs.
      # The standalone AOT build is blocked on nelisp's Mach-O linker
      # supporting read-write sections (tracked upstream).
      elisp = share/"emacs/site-lisp/nelisp"
      elisp.install Dir["lisp/*.el"]
      elisp.install Dir["src/*.el"]
      elisp.install Dir["packages/*/src/*.el"]
      # scripts/ has the build toolchain; useful for REPL-driven dev.
      (elisp/"scripts").install Dir["scripts/*.el"]
    end
  end

  def caveats
    if OS.mac?
      <<~EOS
        The standalone `nelisp` binary is not yet available on macOS
        (upstream Mach-O linker limitation).

        To use nelisp from within Emacs, add to your init.el:

          (add-to-list 'load-path "#{share}/emacs/site-lisp/nelisp")
          (add-to-list 'load-path "#{share}/emacs/site-lisp/nelisp/scripts")
          (require 'nelisp-bootstrap)
          (nelisp-bootstrap-init)
          (nelisp-eval-string "(+ 1 2 3)")  ; => 6
      EOS
    end
  end

  test do
    if OS.linux?
      assert_match "42", shell_output("#{bin}/nelisp --eval '(+ 40 2)'")
    else
      assert_match "42", shell_output(
        "emacs --batch -Q " \
        "-L #{share}/emacs/site-lisp/nelisp " \
        "-L #{share}/emacs/site-lisp/nelisp/scripts " \
        "--eval \"(setq load-prefer-newer t)\" " \
        "-l nelisp-bootstrap " \
        "--eval \"(nelisp-bootstrap-init)\" " \
        "--eval \"(princ (nelisp-eval-string \\\"(+ 40 2)\\\"))\" " \
        "2>&1"
      )
    end
  end
end
