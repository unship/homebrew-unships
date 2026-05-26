# unships — a personal Homebrew tap

Homebrew formulas for projects that don't ship their own Homebrew support.

## Usage

```sh
brew tap unship/unships https://github.com/unship/homebrew-unships.git
brew install unship/unships/<formula>
```

> The repo is private, so the explicit URL is required and your local git must be
> authenticated to `github.com/unship` (SSH key or `gh auth setup-git`).

## Formulas

| Formula             | Upstream                                                  | Notes                                              |
| ------------------- | --------------------------------------------------------- | -------------------------------------------------- |
| `apple-events-mcp`  | https://github.com/farmerajf/apple-events-mcp             | MCP server for Apple Reminders & Calendar (Swift) |

## Adding a new formula

1. Create `Formula/<name>.rb` (see existing formulas as a template).
2. Pin to an upstream tag if one exists; otherwise pin to a commit SHA and set
   `version` to the commit date (`YYYY.MM.DD`).
3. Compute the tarball sha256:
   ```sh
   curl -sL https://github.com/<owner>/<repo>/archive/<ref>.tar.gz | shasum -a 256
   ```
4. Test locally:
   ```sh
   brew install --build-from-source ./Formula/<name>.rb
   brew test <name>
   brew audit --strict --new ./Formula/<name>.rb
   ```
