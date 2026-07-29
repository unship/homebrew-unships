class Nelisp < Formula
  desc "Self-hosted Emacs Lisp VM with pure-Elisp runtime, JIT, and AOT compiler"
  homepage "https://github.com/zawatton/nelisp"
  url "https://github.com/zawatton/nelisp/archive/3b21de37b408141f75c580d06bf9309a3603d052.tar.gz"
  version "0.6.0"
  sha256 "cc1081b06e35c86f4498daa9495dbdcba7c2f26c78fc99583e590467aadf7bfc"
  license "GPL-3.0-only"
  revision 1
  head "https://github.com/zawatton/nelisp.git", branch: "main"

  # Use the user's PATH so `emacs` from a non-Homebrew install
  # (Emacs.app, emacs-plus, etc.) is visible during the build.
  #
  # We deliberately do NOT `depends_on "emacs" => :build`: doing so forces
  # Homebrew to install and `brew link` its own `emacs` formula, which
  # collides with users who already have Emacs.app / emacs-plus symlinks in
  # /opt/homebrew/bin/{emacs,emacsclient,ebrowse,etags} (the link step aborts
  # with "Could not symlink bin/ebrowse ... already exists").  With `env :std`
  # and `EMACS ?= emacs` in the Makefile, the user's PATH emacs is used instead.
  #
  # The standalone `nelisp` binary (make standalone-reader) is Linux-only:
  # nelisp's Mach-O linker path (nelisp-link-units-macho-exec in
  # lisp/nelisp-static-linker.el) rejects .data/.bss with
  # `:mach-o-exec-rw-sections-unsupported`, and the standalone reader emits
  # ~1.1 MB of .bss.  The Mach-O *writer* supports a writable __DATA segment,
  # but the standalone-reader linker path hasn't been wired to pass .data/.bss
  # through to it.  nelisp's own docs/runtime-limitations.md lists macOS
  # notarization as a placeholder and Linux x86_64 as the CI blocker; the
  # README's "5 targets" refers to the object-file writers / asm encoders,
  # not the standalone reader binary.  So on macOS we install only the Elisp
  # sources (usable inside Emacs per the caveats — the supported macOS path);
  # on Linux we build and install the standalone binary as before.
  env :std

  def install
    elisp = share/"emacs/site-lisp/nelisp"
    if OS.mac?
      # macOS: Elisp sources only; the standalone binary doesn't link here.
      elisp.install Dir["lisp/*.el"]
      elisp.install Dir["src/*.el"]
      elisp.install Dir["packages/*/src/*.el"]
      (elisp/"scripts").install Dir["scripts/*.el"]
      return
    end

    target = Hardware::CPU.arm? ? "linux-aarch64" : "linux-x86_64"
    ENV["NELISP_STANDALONE_TARGET"] = target
    system "make", "standalone-reader"
    bin.install "target/nelisp"
    # Also install Elisp sources so nelisp can be used within Emacs.
    elisp.install Dir["lisp/*.el"]
    elisp.install Dir["src/*.el"]
    elisp.install Dir["packages/*/src/*.el"]
    (elisp/"scripts").install Dir["scripts/*.el"]
  end

  def caveats
    on_macos = <<~EOS
      On macOS nelisp installs Elisp sources only (the standalone binary
      requires Linux; see docs/runtime-limitations.md).  To use nelisp from
      within Emacs, add to your init.el:

        (add-to-list 'load-path "#{share}/emacs/site-lisp/nelisp")
        (add-to-list 'load-path "#{share}/emacs/site-lisp/nelisp/scripts")
        (require 'nelisp-bootstrap)
        (nelisp-bootstrap-init)
        (nelisp-eval-string "(+ 1 2 3)")  ; => 6
    EOS
    on_linux = <<~EOS
      The standalone `nelisp` binary is installed at #{bin}/nelisp.
      To also use nelisp from within Emacs, add to your init.el:

        (add-to-list 'load-path "#{share}/emacs/site-lisp/nelisp")
        (add-to-list 'load-path "#{share}/emacs/site-lisp/nelisp/scripts")
        (require 'nelisp-bootstrap)
        (nelisp-bootstrap-init)
        (nelisp-eval-string "(+ 1 2 3)")  ; => 6
    EOS
    OS.mac? ? on_macos : on_linux
  end

  test do
    if OS.mac?
      # No standalone binary on macOS; verify the Elisp sources load in Emacs.
      output = shell_output(
        "emacs --batch -Q " \
        "-L #{share}/emacs/site-lisp/nelisp " \
        "--eval \"(setq load-prefer-newer t)\" " \
        "-l nelisp-bootstrap " \
        "--eval \"(princ (if (featurep 'nelisp-bootstrap) \\\"OK\\\" \\\"FAIL\\\"))\" " \
        "2>&1",
      )
      assert_match "OK", output
    else
      assert_match "42", shell_output("#{bin}/nelisp --eval '(+ 40 2)'")
    end
  end
end
