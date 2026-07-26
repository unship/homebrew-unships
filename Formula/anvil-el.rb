class AnvilEl < Formula
  desc "Token-efficient MCP toolkit for AI agents, built on Emacs primitives"
  homepage "https://github.com/zawatton/anvil.el"
  url "https://github.com/zawatton/anvil.el/archive/574568a95a2bd8fceca6c9cd3bec0f94ecf0e6a9.tar.gz"
  version "1.3.0"
  sha256 "40785e03e7ca25f7b59f71e239bebb896ea2f547c1e47cfcddab800ae86bfb85"
  license "GPL-3.0-only"
  head "https://github.com/zawatton/anvil.el.git", branch: "master"

  # Emacs 28.2+ is required at runtime.
  # Install Emacs first if you don't have it, e.g.:
  #   brew install emacs          # homebrew/core
  #   brew install emacs-plus     # d12frosted/emacs-plus

  def install
    elisp = share/"emacs/site-lisp/anvil"
    elisp.install Dir["*.el"]
  end

  def caveats
    <<~EOS
      To load anvil.el in Emacs, add to your init.el:

        (add-to-list 'load-path "#{share}/emacs/site-lisp/anvil")
        (require 'anvil)

      Then start the MCP server with M-x anvil-server-start.
      See https://github.com/zawatton/anvil.el for client setup
      (Claude Code, Codex CLI, Claude Desktop, etc.).
    EOS
  end

  test do
    output = shell_output(
      "emacs --batch -Q " \
      "-L #{share}/emacs/site-lisp/anvil " \
      "--eval \"(setq load-prefer-newer t)\" " \
      "-l anvil " \
      "--eval \"(princ (if (featurep 'anvil) \\\"OK\\\" \\\"FAIL\\\"))\" " \
      "2>&1"
    )
    assert_match "OK", output
  end
end
