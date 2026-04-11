# apfelpad

**A formula notepad for thinking. On-device AI as a first-class function, like `=SUM` but for language.**

Type `=apfel("a love letter")` anywhere in a document. Press Return. The formula evaluates on your Mac using Foundation Models, streams the result inline in a light-green span, and caches it deterministically so re-runs return the same output. Add a seed: `=apfel("love letter", 42)`. Compose with other formulas: `=apfel("summarize", =ref(@intro))`. Drop in arithmetic: `=math(365*24)`.

Markdown underneath. 100% local. No API keys. Nothing leaves your Mac.

**Built on [apfel](https://github.com/Arthur-Ficial/apfel)** — the CLI + OpenAI-compatible HTTP server that wraps Apple's on-device `FoundationModels` framework. All inference goes through `apfel --serve` on your machine. **Patterned after [apfel-chat](https://github.com/Arthur-Ficial/apfel-chat)** — same SwiftUI + `@Observable` MVVM + protocol-driven TDD + swift-testing + release workflow. apfelpad is the writing-tool sibling to apfel-chat's chat-client.

> **Status: Pre-implementation.** This repo currently contains the design briefing only. Nothing is built yet. Star the repo to follow along, or read [BRIEFING.md](BRIEFING.md) for the full vision.

---

## What it does

apfelpad is a native macOS markdown notepad that embeds a formula evaluator. Every formula is a cell. Every cell renders inline. Every cell caches. Every cell is reproducible.

Think spreadsheets, but for text, with on-device AI as one of the functions.

### The formulas

| Formula | Example | What it does |
|---|---|---|
| `=apfel(prompt, seed?)` | `=apfel("a love letter", 42)` | On-device LLM call, auto-scoped context |
| `=math(expression)` | `=math(42+2*3)` | Pure arithmetic, no model |
| `=ref(@anchor)` | `=ref(@intro)` | Insert content of a named block |
| `=count(@anchor?)` | `=count()` | Word count of doc or block |
| `=date(format?)` | `=date("YYYY-MM-DD")` | Current date |
| `=clip()` | `=apfel("fix", =clip())` | Current clipboard snapshot |
| `=file(path)` | `=apfel("summarize", =file("notes.md"))` | Local file content |

### Auto-quoting

You never have to remember quote syntax. If you type `=apfel(hello world)`, apfelpad canonicalizes it to `=apfel("hello world")` for you. Type English. apfelpad handles the parser.

### Inline rendering

Every evaluated formula renders as a light-green span in place, with a dark-green left border. The source is always one click away (formula bar at the top of the window, like Excel). Click to select, double-click to edit inline, ⌘Enter to run.

### Seeds and determinism

`=apfel("love letter", 42)` is reproducible. Same seed + same context + same model version → same output, via a composite cache key. Change the seed, regenerate. Change the prompt, regenerate. Never destructively.

### The formula sidebar

Type `=apfel(` and a sidebar slides in from the right with live argument help, context preview, token budget, seed picker, and recent-formulas history. Power users can close it and never see it again. Newcomers have a guided UX the first time they use the product.

---

## Requirements

| Requirement | How to check |
|---|---|
| **macOS 26 (Tahoe) or later** | Apple menu → About This Mac |
| **Apple Silicon (M1 or later)** | Apple menu → About This Mac — must say M1, M2, M3, or M4 |
| **Apple Intelligence enabled** | System Settings → Apple Intelligence & Siri |
| **apfel installed** | `brew install Arthur-Ficial/tap/apfel` (bundled in packaged builds) |

---

## Install

**Not yet available.** apfelpad is pre-implementation. When v0.1 ships, install will be:

```bash
brew install Arthur-Ficial/tap/apfelpad
```

Packaged builds (Homebrew, zip, one-liner installer) will bundle `apfel` so nothing extra is needed.

---

## Quick start (once built)

1. Open **apfelpad** from `/Applications`
2. Create a new document: `⌘N`
3. Type a heading: `# My first apfelpad doc`
4. Type `=apfel(hello world)` and press Return
5. Watch the formula span fill with light green as tokens stream in from your on-device model

---

## Why formulas?

Because every other "AI in documents" product dissolves the boundary between what you wrote and what the model wrote. Notion AI, Google Docs AI, Microsoft Copilot, Apple Writing Tools - they all silently inject text. You cannot rerun. You cannot see the prompt later. You cannot change the input without wiping the output. The model is a vandal with editor permissions.

Formulas fix this:

- **The prompt is visible.** The source shows `=apfel("love letter", 42)`. You never forget what you asked for.
- **The output is visibly generated.** Light-green background. Not your voice. Not your words.
- **You can rerun.** Change the seed. Change the prompt. Never destructively.
- **You can compose.** Nest formulas. Reference other blocks. Make the document self-referential.
- **You can share.** The formula source travels with the markdown file.

The AI becomes a first-class computable function, not a ghost with a cursor.

---

## Architecture

apfelpad is a SwiftUI app with a protocol-driven MVVM core and a pure Swift formula runtime. Full details in [BRIEFING.md](BRIEFING.md) and [CLAUDE.md](CLAUDE.md).

```
App → ServerManager (spawns apfel --serve on 11450)
    ↓
ViewModels (@Observable)
    ↓
FormulaRuntime → per-formula evaluators
    ↓ (for =apfel only)
ApfelHTTPService → apfel --serve → Foundation Models on your Mac
```

- Protocol + mock for every service
- SQLite for the formula cache
- swift-testing for the test suite
- Pragmatic about dependencies - well-maintained Swift packages are welcome for things like markdown parsing, math expression evaluation, and attributed-text editing (apfelpad diverges from the rest of the apfel family on this one point)
- Light-green visual language inherited from apfel-clip

---

## Related projects

- **[apfel](https://github.com/Arthur-Ficial/apfel)** - the on-device LLM CLI + OpenAI-compatible HTTP server. The engine apfelpad runs on.
- **[apfel-chat](https://github.com/Arthur-Ficial/apfel-chat)** - a native macOS chat client for Foundation Models. apfelpad's architectural template.
- **[apfel-clip](https://github.com/Arthur-Ficial/apfel-clip)** - menu bar clipboard actions (fix grammar, explain code, translate). apfelpad's visual language comes from here.
- **[apfel-gui](https://github.com/Arthur-Ficial/apfel-gui)** - the apfel debug GUI.
- **[apfel-quick](https://github.com/Arthur-Ficial/apfel-quick)** - quick-prompt menu bar utility.
- **[apfel-ecosystem](https://github.com/Arthur-Ficial/apfel-ecosystem)** - meta-repo documenting shared principles.

---

## Development

Pre-implementation. Once scaffolded:

```bash
swift build                # debug build
swift test                 # run tests
make app                   # build app bundle
make install               # build + copy to /Applications
make dist                  # build release zip + checksums
```

Tests cover the formula parser (auto-quoting is the single most important behaviour), the formula runtime, per-formula evaluators, context resolution, cache key hashing, and ViewModels. All via protocol+mock TDD - no UI tests, views are thin.

---

## Roadmap

- **v0.1** - Markdown editor + `=math` only. Proves the pipeline end-to-end without touching an LLM.
- **v0.2** - `=apfel(...)` inline, auto-quoting, seeds, streaming into the span.
- **v0.3** - Formula sidebar (the signature UX moment).
- **v0.4** - Named anchors + `=ref` + `=count`.
- **v0.5** - `=date`, `=clip`, `=file`.
- **v0.6** - Context strategy integration for long sections.
- **v0.7** - Cache management UI.
- **v0.8** - File format schema freeze.
- **v0.9** - Signing, notarisation, Homebrew cask.
- **v1.0** - Launch.

Each version is shippable. Full rationale in [BRIEFING.md](BRIEFING.md).

---

## Privacy

apfelpad makes **one** network call and it is not for inference: an optional daily check against `api.github.com` for new apfelpad releases (togglable in settings, on by default). Every language-model call goes to `localhost:11450` where `apfel --serve` runs on your machine, reading from the on-device `FoundationModels` framework. Documents are plain markdown files on your disk. The formula cache is a SQLite file in `~/Library/Application Support/apfelpad/cache/`. No telemetry. No accounts. No cloud inference. Ever.

Opt-in formulas like `=http(url)` (future, not v1.0) would require explicit per-formula consent and a loud warning. The default product runs offline.

## Updates

apfelpad checks for new releases on launch using the GitHub releases API (same pattern as [apfel-chat](https://github.com/Arthur-Ficial/apfel-chat)). If a newer version is available, a non-blocking banner offers to upgrade via `brew upgrade apfelpad` or a direct download. You can disable the check entirely in settings.

---

## License

MIT (planned). See [LICENSE](LICENSE) once the repo is scaffolded.

---

## Status

**Pre-implementation design.** Only the briefing exists right now. If you are reading this because Franz or Arthur told you to, start with [BRIEFING.md](BRIEFING.md) for the full design rationale. If you are a Claude session assigned to build v0.1, read [CLAUDE.md](CLAUDE.md) for the operational playbook.
