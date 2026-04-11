# apfelpad - Project Instructions

## The Golden Goal

> **apfelpad turns a plain markdown document into a spreadsheet for thinking: every span can be text, math, or an on-device AI call, authored with one unified formula syntax, rendered inline in light green, reproducible via seeds, and 100% local.**

The full design rationale lives in `BRIEFING.md` - read it before touching code. This file is the operational playbook.

## Canonical reference repos - READ BEFORE BUILDING ANYTHING

| Repo | GitHub | Role for apfelpad |
|---|---|---|
| **apfel** | https://github.com/Arthur-Ficial/apfel | **The engine and the underlying technology.** On-device Foundation Models via the `FoundationModels` framework (macOS 26+), wrapped as a CLI + OpenAI-compatible HTTP server. apfelpad spawns `apfel --serve` on port 11450 at launch. All inference goes through apfel over HTTP. Do NOT import FoundationModels directly anywhere in apfelpad. |
| **apfel-chat** | https://github.com/Arthur-Ficial/apfel-chat | **The coding-style, TDD, release, and update-check template.** Copy the skeleton 1:1: SwiftUI `@main`, `@Observable` MVVM, protocol+mock TDD with swift-testing, `ServerManager`, `UpdateChecker`, `ChatControlServer`, SQLite raw C, `./scripts/release.sh`, Homebrew cask. Every pattern apfelpad needs is already proven in apfel-chat. **Whenever you are unsure how to do something, look at apfel-chat first.** |
| apfel-clip | https://github.com/Arthur-Ficial/apfel-clip | Color palette reference (pale green + dark green accent). |
| homebrew-tap | https://github.com/Arthur-Ficial/homebrew-tap | Where the apfelpad cask will live. |

**The two non-negotiables:**
1. **Underlying technology is apfel + FoundationModels.** Every LLM call in apfelpad is an HTTP POST to `localhost:11450/v1/chat/completions`, not a direct SDK call. This is how apfelpad gets all of apfel's hard work (context management, streaming, tool calling, retries) for free.
2. **Code style, TDD discipline, update-check process, release workflow: copied from apfel-chat.** Not "inspired by". Copied. Same file layout, same protocol+mock patterns, same `UpdateChecker` via GitHub releases API, same release script shape.

## Status

**Pre-implementation.** Only `BRIEFING.md`, `CLAUDE.md`, and `README.md` exist. No Swift code has been written yet. The first implementation pass scaffolds from `apfel-chat`.

## Language Rules

NEVER use the word "Apple" in user-visible strings. Use instead:
- "on-device" / "your Mac" / "Foundation Models on your Mac"
- "private AI" / "local AI"

Formulas are called **formulas**. Not cells, not blocks, not prompts, not AI calls. Formulas. Consistently.

## The core primitive: formulas

Every piece of computed content in apfelpad is a formula. The formula is the unit of authorship, the unit of caching, the unit of rendering, and the unit of reproducibility. If a feature does not fit into the formula model, it does not ship.

Six formulas in v1.0:

| Formula | Purpose |
|---|---|
| `=apfel(prompt, seed?)` | On-device LLM call with auto-scoped context |
| `=math(expression)` | Pure arithmetic, no LLM |
| `=ref(@anchor)` | Insert content of a named block/heading |
| `=count(@anchor?)` | Word count of doc or block |
| `=date(format?)` | Current date, optionally formatted |
| `=clip()` | Current clipboard snapshot |
| `=file(path)` | Local file content (sandboxed) |

**Auto-quoting is non-negotiable:** `=apfel(hello world)` must be canonicalized to `=apfel("hello world")` on commit. Users type English, the parser handles the quotes.

## Install & Run

(When built - currently pre-implementation.)

```bash
brew install Arthur-Ficial/tap/apfelpad
apfelpad
```

## Build from source

```bash
swift build -c release
make install
swift test                # run all tests
swift run apfelpad        # debug build
```

Requires Xcode command-line tools and `apfel` on your `PATH`.

## Architecture

1:1 clone of `apfel-chat`. Protocol-driven, TDD-first, every service has a protocol + mock.

```
Sources/
├── App/              # @main, window lifecycle, server management
│   ├── ApfelPadApp.swift
│   ├── AppDelegate.swift
│   └── ServerManager.swift          (spawns apfel --serve on 11450)
├── Models/           # Data types (Document, FormulaSpan, CacheKey, etc.)
├── Protocols/        # Service protocols (LLMService, FormulaCache, etc.)
├── Services/         # Real implementations
│   ├── FormulaParser.swift          (auto-quoting parser)
│   ├── FormulaRuntime.swift         (dispatches to per-function evaluators)
│   ├── ApfelFormulaEvaluator.swift
│   ├── MathFormulaEvaluator.swift
│   ├── ... one evaluator per formula
│   ├── ApfelHTTPService.swift       (client for apfel --serve)
│   ├── SQLiteFormulaCache.swift
│   └── MarkdownDocumentStore.swift
├── ViewModels/       # @Observable state management
│   ├── DocumentViewModel.swift
│   ├── FormulaSidebarViewModel.swift
│   └── FormulaBarViewModel.swift
└── Views/            # SwiftUI views (thin, declarative)
    ├── DocumentView.swift
    ├── FormulaSpanView.swift        (the pale-green render)
    ├── FormulaSidebarView.swift
    ├── FormulaBarView.swift
    └── MarkdownRenderer.swift

Tests/
├── Mocks/
│   ├── MockLLMService.swift
│   ├── MockFormulaCache.swift
│   └── MockContextResolver.swift
└── *Tests.swift     # One test file per service / ViewModel
```

## Key Design Decisions (locked)

- **Pragmatic about dependencies.** apfelpad diverges from the rest of the apfel family (apfel, apfel-chat, apfel-clip) on this single point: well-maintained external Swift packages are allowed where they genuinely save correctness-critical work. Good candidates: markdown parsing/rendering, math expression evaluation for `=math`, SQLite helpers, attributed-text editors, syntax highlighting. Evaluate each dep on maintenance, license, binary size, surface area, and security. Do NOT reinvent a markdown parser or an expression evaluator if a known package already nails it. Do NOT pull in deps just because you can - every dep is a future maintenance bill.
- **Protocol-driven TDD.** Every service has a protocol + mock. Write the test first.
- **`@Observable` MVVM.** Views are thin; logic lives in ViewModels.
- **SwiftUI `@main`.** App Store compatible. No NSApplication wrapper.
- **apfel under the hood.** `ServerManager` spawns `apfel --serve --port 11450` at launch, or reuses an existing running instance.
- **Formula runtime is pure Swift.** `FormulaRuntime` and every individual evaluator are unit-testable with mocks - no FoundationModels or HTTP dependencies in the core runtime.
- **Context resolution is pure.** `ContextResolver` is tested against fake document text, not a real document view.
- **The markdown document is the source of truth.** The ViewModel is derived from it, not the other way around. Save on commit.
- **Auto-quoting parser.** See BRIEFING.md section 4 for the algorithm. Non-negotiable - this is the UX contract.

## Visual spec (locked)

- **Formula span background:** `Color(red: 0.94, green: 0.98, blue: 0.93)` - pale green from apfel-clip
- **Formula span left border:** 3px, `Color(red: 0.16, green: 0.49, blue: 0.22)` - dark green
- **Stale state border:** `.orange`
- **Error state background:** pale red, border `.red`
- **Streaming placeholder:** pulsing pale green with a progress dot
- **Hover:** background darkens ~5%, refresh icon appears top-right

## Port assignment

apfelpad claims **port range 11450-11459** in the ecosystem:
- apfel: 11434
- apfel-clip: 11435
- apfel-chat: 11440-11449
- **apfelpad: 11450-11459**

`ServerManager` scans this range and uses the first available port. `ApfelHTTPService` reads the selected port from the manager.

## Update and upgrade check (copy apfel-chat exactly)

apfelpad checks for new releases via the GitHub API, using the same pattern as [`apfel-chat/Sources/Services/UpdateChecker.swift`](https://github.com/Arthur-Ficial/apfel-chat/blob/main/Sources/Services/UpdateChecker.swift). Do not re-invent this - just copy it and change the repo path.

Files to create (mirror apfel-chat 1:1):

| File | Purpose |
|---|---|
| `Sources/Protocols/UpdateChecking.swift` | `protocol UpdateChecking { fetchLatestRelease(currentVersion:) async throws -> LatestReleaseInfo }` |
| `Sources/Models/LatestReleaseInfo.swift` | `struct LatestReleaseInfo: Equatable { let version: String }` |
| `Sources/Services/GitHubReleaseUpdateChecker.swift` | Concrete implementation. API URL: `https://api.github.com/repos/Arthur-Ficial/apfelpad/releases/latest`. Timeout: 10s. User-Agent: `apfelpad/<version>`. Strips leading `v` from tag name. |
| `Tests/Mocks/MockUpdateChecker.swift` | Test double returning a pre-configured `LatestReleaseInfo` |
| `Tests/UpdateCheckerTests.swift` | Unit tests for tag-name normalization, error handling on non-2xx, mock verification |

### Behaviour

- On startup, if "check for updates on launch" is enabled (default: on, togglable in settings), a background task calls `updateChecker.fetchLatestRelease(currentVersion:)`.
- If the latest version is greater than the current version, show a non-blocking banner at the top of the window: `"apfelpad <x.y.z> is available. Install via 'brew upgrade apfelpad' or download from GitHub."`
- Clicking dismisses for the session. Settings toggle disables future checks.
- This is the **only** network call apfelpad makes. It is not for inference. Document this honestly in the README privacy section. See apfel-chat's `SettingsPanel.swift` and `ChatViewModel.swift` for the exact UI/VM wiring.

### User-facing setting

Settings panel has:
- `[x] Check for updates on launch` (default: on)
- A visible "Check now" button that calls the same method imperatively

Mirror the wording and placement from apfel-chat's settings panel.

## Testing

```bash
swift test                                          # all tests
swift test --filter ApfelPadTests.FormulaParserTests  # specific test class
```

### The first ten tests to write (critical path)

Write these before any UI. They pin down the architecture:

1. `FormulaParser: plain string literal` - `=apfel("hello")` → `.apfelCall(prompt: "hello", seed: nil)`
2. `FormulaParser: auto-quotes a bare word` - `=apfel(hello)` parses identically to `=apfel("hello")`
3. `FormulaParser: auto-quotes a bare phrase` - `=apfel(hello world)` → `=apfel("hello world")`
4. `FormulaParser: seed as second argument` - `=apfel("hello", 42)` → seed 42
5. `FormulaParser: canonicalizes on commit` - stored string for `=apfel(hi)` is `=apfel("hi")`
6. `MathEvaluator: arithmetic` - `=math(42+2*3)` returns `"48"`
7. `CacheKey: deterministic hash` - same inputs produce same key, different inputs differ
8. `ApfelFormulaEvaluator: calls LLM service and caches result` - using `MockLLMService`
9. `ApfelFormulaEvaluator: cache hit skips LLM call` - using `MockFormulaCache` pre-seeded
10. `ContextResolver: current section only` - formula in section 2 sees section 2 text, not sections 1 and 3

No UI tests in the first pass. Views are thin; ViewModels are what matter.

## Staged rollout

- **v0.1** - Markdown editor + `=math` only. Proves the whole pipeline (parser, cache, render, click-to-edit) without any LLM.
- **v0.2** - `=apfel(...)` inline, auto-quoting, seed, cache, streaming. No sidebar yet.
- **v0.3** - Formula sidebar (the signature UX moment).
- **v0.4** - Named anchors + `=ref` + `=count`.
- **v0.5** - `=date`, `=clip`, `=file`.
- **v0.6** - Context strategy integration for overflow sections.
- **v0.7** - Cache management UI.
- **v0.8** - File format schema freeze.
- **v0.9** - Signing, notarisation, Homebrew cask.
- **v1.0** - Launch.

Each version is shippable. No version depends on a future version.

## Handling GitHub Issues

When a new issue comes in:

1. **Fetch** the full issue: `gh issue view <n> --repo Arthur-Ficial/apfelpad --json body,comments,title,author,labels`
2. **Vet** - is it aligned with the golden goal (formula-first, 100% local, no scope creep into reader-model / chat / clipboard territory)?
3. **Fix** if valid:
   - Write tests first (TDD) for bugs
   - Keep changes minimal
   - Run `swift test` - all tests must pass
4. **Release** if code changed - `./scripts/release.sh`
5. **Close** with a short, truthful comment:
   - What was the problem
   - What was fixed (or why closed)
   - How to update (`brew upgrade apfelpad`)
6. **Homebrew tap:** cask files live in `Casks/` in `Arthur-Ficial/homebrew-tap`.

## Scope boundaries (what to reject)

- **Reader model / thesis-drift feedback** - v2.0 territory, not v1.0. Reject in v1.x.
- **Rich text, tables, embedded images** - markdown only.
- **Plugins / extensibility API** - reject in v1.x. Maybe v2.0.
- **Collaboration / cursors / comments** - single-user, local-only.
- **Graph view / backlinks-as-DB** - this is not Obsidian.
- **Chat sidebar** - apfel-chat exists.
- **Clipboard actions** - apfel-clip exists.
- **Menu bar utility** - apfel-quick exists.
- **Any network call other than to localhost `apfel --serve`** - privacy is the product.

## Release

(Once implemented, same pattern as apfel-chat.)

```bash
./scripts/release.sh
```

1. Checks clean `main`, valid Developer ID cert
2. Runs `swift test` - all tests must pass
3. Builds release binary, assembles `.app`
4. Signs with `Developer ID Application: Franz Enzenhofer (7D2YX5DQ6M)` + entitlements
5. Notarises with Apple and staples the ticket
6. Creates versioned ZIP, stable ZIP, SHA256SUMS, Homebrew cask
7. Tags and pushes to GitHub
8. Creates GitHub release
9. Deploys landing page to Cloudflare Pages
10. Runs post-deploy sanity checks

## North star

Every design question reduces to: **"Does this make the formula primitive feel more or less like a real function?"** More, ship it. Less, cut it.
