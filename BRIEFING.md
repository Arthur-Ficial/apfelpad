# apfelpad - Design Briefing

> **A formula-driven notepad where on-device AI is just another function, like `=SUM` or `=VLOOKUP` but for language.**

**Status:** Pre-implementation design briefing. Nothing is built yet. This document is the single source of truth for the vision, so that the first implementation pass can land in one clean arc without re-litigating decisions.

**Audience:** Future-me (Arthur), Franz, and any Claude session that picks this up later.

**Canonical reference repos - READ BEFORE BUILDING ANYTHING:**

| Repo | GitHub | Role for apfelpad |
|---|---|---|
| `apfel` | https://github.com/Arthur-Ficial/apfel | **The engine.** Underlying technology: on-device Apple Foundation Models via the `FoundationModels` framework (macOS 26+), wrapped as a CLI and an OpenAI-compatible HTTP server. apfelpad talks to it over HTTP on port 11450 (spawning `apfel --serve` at launch). Do NOT reimplement any model logic - always go through apfel. |
| `apfel-chat` | https://github.com/Arthur-Ficial/apfel-chat | **The architectural template.** Copy the skeleton 1:1: SwiftUI `@main`, `@Observable` MVVM, protocol-driven TDD with swift-testing, SQLite via raw C, `ServerManager`, `UpdateChecker`, `ChatControlServer`, auto-title, release script, signing, notarisation, landing page. Every pattern apfelpad needs is already proven in apfel-chat. **Look at apfel-chat first whenever you are unsure how to do something.** |
| `apfel-clip` | https://github.com/Arthur-Ficial/apfel-clip | The color palette reference (pale green background `Color(red: 0.94, green: 0.98, blue: 0.93)`, dark green accent `Color(red: 0.16, green: 0.49, blue: 0.22)`). |
| `apfel-ecosystem` | https://github.com/Arthur-Ficial/apfel-ecosystem | Shared principles: 100% on-device, honest limits, TDD, German-named where appropriate. Note: the family-wide "zero external Swift deps" rule does NOT apply to apfelpad - apfelpad is allowed well-maintained Swift packages where they genuinely add value (see section 10.1). |

**The two non-negotiables:**
1. **Underlying technology is apfel + FoundationModels.** Nothing else. No Ollama, no llama.cpp, no cloud fallback. Ever. apfelpad is a proof that `apfel --serve` is a serious developer platform, not just a demo server.
2. **Coding style, TDD discipline, update-check process, release workflow - all copied from apfel-chat.** Not "inspired by". Copied. Same file structure, same protocol+mock pattern, same `UpdateChecker` approach (GitHub releases API), same release script shape. Consistency across the apfel family is the feature.

---

## 1. The Golden Goal

> **apfelpad turns a plain markdown document into a spreadsheet for thinking: every span can be text, math, or an on-device AI call, authored with one unified formula syntax, rendered inline in light green, reproducible via seeds, and 100% local.**

One sentence. Everything else in this briefing is in service of that.

---

## 2. First principles - why formulas?

This section exists because "notepad plus AI" has been built many times, and every previous attempt has felt wrong. The argument below is why apfelpad will not feel wrong.

### 2.1 Spreadsheets won

The most successful interface in the history of personal computing is a grid of cells where formulas compose. Hundreds of millions of people use formulas every day. The reason is not features - it is that formulas cleanly separate INPUT (the formula source) from OUTPUT (the computed value). That separation is the single thing that makes delegating work to a computer feel safe inside a document you own.

VisiCalc in 1979 did not win by being pretty. It won because `=A1+A2` was a contract: you could see the promise, you could see the result, you could re-run, and you could change the input. Everything since has been polish on that primitive.

### 2.2 AI in documents currently feels unsafe

Notion AI, Google Docs AI, Microsoft Copilot, Apple Writing Tools - they all silently inject text into your document. The boundary between "what you wrote" and "what the model wrote" dissolves. You cannot rerun a generation without selecting and deleting. You cannot see the prompt after the fact. You cannot change the input without also wiping the output. The model acts like a vandal with editor permissions.

People feel this, even if they cannot articulate it. They accept it for throwaway text (tweets, emails they do not care about). They reject it for anything that matters (essays, decision docs, emotional writing). The friction is trust, and the trust is broken by the lack of formula semantics.

### 2.3 Formulas fix this

When AI output lives in a formula span, the trust contract is restored:

- **The prompt is visible.** The source view shows `=apfel("love letter")`. You never forget what you asked for.
- **The output is visibly generated.** Light-green background. Not your voice. Not your words. Clearly a computed value.
- **You can rerun.** Change the seed, rerun. Change the prompt, rerun. Never destructively.
- **You can seed.** `=apfel("love letter", 42)` is deterministic within cache.
- **You can compose.** `=apfel("summarize", =ref(@intro))` is just a nested function call.
- **You can share.** The formula source travels with the file; anyone opening the same `.md` on another Mac with apfelpad gets the same semantics.

The AI becomes a first-class computable function, not a ghost with a cursor.

### 2.4 The mental model is VisiCalc, not Clippy

Clippy was an interruption. A spreadsheet formula is a tool. The difference is who is in charge - the human authoring the formula, or the software choosing when to speak. apfelpad is the former. The AI never volunteers. It runs when you call it, with the inputs you gave it, and it renders its output in a visibly distinct zone you control.

---

## 3. The formula language (v1.0)

apfelpad is, at its core, a **formula evaluator embedded in a markdown editor**. The document is the sheet. The cells are inline formula spans. The evaluator understands a small, extensible set of functions.

### 3.1 The built-in functions

| Formula | What it does | Example |
|---|---|---|
| `=apfel(prompt, seed?)` | Runs the on-device LLM with the given prompt, plus surrounding-context auto-attached. Returns generated text. | `=apfel("a love letter", 42)` |
| `=math(expression)` | Evaluates an arithmetic expression. No language model involved. | `=math(42+2*7)` |
| `=ref(@anchor)` | Inserts the content of a named block/heading. Cheap, no model call. | `=ref(@intro)` |
| `=count(@anchor?)` | Word count of the whole doc or a named block. | `=count()` / `=count(@intro)` |
| `=date(format?)` | Current date, optionally formatted. | `=date("YYYY-MM-DD")` |
| `=clip()` | Current clipboard content (one-shot, cached at formula evaluation time). | `=apfel("fix this", =clip())` |
| `=file(path)` | Inserts content of a local file (sandboxed to user-chosen folders). | `=apfel("summarize", =file("~/notes.md"))` |

### 3.2 Why this specific set

- `=apfel` is the whole product. Everything else exists so `=apfel` can compose.
- `=math` earns its place because a notepad without arithmetic is useless, and because it proves the formula runtime is not LLM-only (which is important for the mental model - formulas are the primitive, AI is one function among several).
- `=ref` and `=count` make the document self-referential, which is what makes formulas more powerful than raw prompts.
- `=date`, `=clip`, `=file` are the minimum "hooks into the world" that unlock real use cases (dated journals, paste-then-rewrite, summarise-my-file) without opening the door to unsafe side effects.

### 3.3 Future formulas (not v1.0, but natural extensions)

These are named here so the architecture anticipates them, not built in v1:

- `=ocr(image)` - via `auge` (Vision framework) from the ecosystem
- `=embed(text)` - via `kern` (embeddings) from the ecosystem
- `=stt(audio)` - via `ohr` (speech) from the ecosystem
- `=env(name)` - environment variable access
- `=http(url)` - fetch (opt-in, off by default, the door to "network" in an otherwise local-only product)
- `=shell(command)` - off by default, guarded by explicit consent per formula

Any formula that touches the network or shell must be off by default and require explicit opt-in in settings. apfelpad's privacy story is the product; we do not compromise it for convenience.

---

## 4. Auto-quoting - the single most important UX decision

**The user should never have to remember quote syntax.**

Rule: if the content inside a formula's parens cannot be parsed as a valid formula expression (number, nested formula call, quoted string, or identifier), it is treated as a single string literal and auto-quoted canonically on commit.

### 4.1 Examples

| User types | Stored canonical | Rendered |
|---|---|---|
| `=apfel(hello world)` | `=apfel("hello world")` | a love letter... (light green) |
| `=apfel("hello world")` | `=apfel("hello world")` | same |
| `=apfel(loveletter, 42)` | `=apfel("loveletter", 42)` | ... |
| `=math(42+2)` | `=math(42+2)` | `44` |
| `=math(forty two)` | error: not a valid expression | red error span |
| `=apfel(summarize this, =ref(intro))` | `=apfel("summarize this", =ref(@intro))` | ... |

### 4.2 The parsing algorithm (sketch)

Inside the parens:
1. Tokenize on top-level commas (respecting nested parens and quotes).
2. For each argument token:
   - If it is a valid number literal → keep as number
   - If it is a quoted string → keep as string
   - If it starts with `=` → recursively parse as a sub-formula
   - If it starts with `@` → treat as a named anchor
   - **Otherwise → wrap in double quotes as a string literal** (auto-quoting)
3. Canonicalize the formula source and replace the user's typed form with the canonical form on commit.

### 4.3 Why this matters

This rule is the difference between "a notepad for developers" and "a notepad for humans". Without it, every user would be punished for not typing quotes. With it, users type English and formulas just work.

This is also why the formula language must be small and unambiguous. A large language would have too many valid ways to parse "hello world" and auto-quoting would become brittle.

---

## 5. The inline rendering model

When a formula evaluates, its output replaces the formula source **in the rendered view**, with unmistakable visual separation.

### 5.1 Visual spec

- **Background:** `Color(red: 0.94, green: 0.98, blue: 0.93)` - the pale green from `apfel-clip`
- **Left border bar:** 3px, `Color(red: 0.16, green: 0.49, blue: 0.22)` - the dark accent
- **Text color:** default document text color (not tinted - it is still readable prose)
- **Hover:** background darkens ~5% and a tiny refresh icon appears at top-right of the span
- **Streaming state:** span shows a pulsing light-green placeholder with a progress dot while tokens stream in
- **Stale state:** left border bar turns amber when the formula's inputs have changed since the cached value was computed
- **Error state:** background is pale red, left border is `.red`, click to see error tooltip

### 5.2 Click-to-edit

One click on a rendered formula span does NOT immediately dive into edit mode (that would be disruptive). Instead:

- **Single click:** selects the span (visible highlight outline), opens the formula bar at the top of the window showing the formula source. Arrow keys still move the cursor normally elsewhere.
- **Double click / ⌘E:** enters edit mode in place - the span transforms into the formula source text with a blinking cursor inside it. The light-green background persists to remind you that this is a formula being edited, not free prose.
- **Return while editing:** runs the formula, re-caches, re-renders.
- **Esc while editing:** reverts to the last-rendered value.

### 5.3 The formula bar (top of the window)

Like Excel's formula bar. Always visible, always shows the source of the currently-selected formula. Editing the formula bar is equivalent to editing inline. Novice users who do not know about click-to-edit can still discover this.

---

## 6. The seed parameter and determinism

`=apfel("love letter", 42)` takes a seed as its second argument. The seed is what makes `=apfel` behave like a function, not a random-text generator.

### 6.1 What "deterministic" means here

Two calls to `=apfel("love letter", 42)` with the same context should return the same output. Users do not care whether the determinism comes from the model sampler or from the cache - they care that re-running a formula does not change the output unless they ask for it.

### 6.2 Implementation layers

1. **Always:** cache every evaluation by a composite key: `hash(formula_source, resolved_context, model_version, seed)`. Cache is persistent (SQLite sidecar) and survives restarts.
2. **If FoundationModels SDK supports seeds:** pass the seed through. Re-running clears the cache entry for that key and regenerates.
3. **If FoundationModels SDK does NOT support seeds:** temperature=0 on all `=apfel` calls, and the seed becomes a cache-key-only parameter. From the user's perspective the determinism is identical: re-running returns the same cached value.
4. **If the seed is omitted:** a per-document random seed is assigned on first evaluation, stored in frontmatter, and reused on re-runs. The user can explicitly override it later with `=apfel("...", <seed>)`.

### 6.3 Open question (flagged for research)

Does Apple's FoundationModels SDK on macOS 26+ expose a sampler seed? This must be verified before v0.2 ships. If not, layers 1+3 deliver the user-visible behaviour anyway, so this is a UX refinement question, not a blocker.

---

## 7. Context scoping - what does `=apfel` "see"?

Formulas inherit context from their position in the document. The default is clever, but transparent.

### 7.1 Default scoping rules

1. **If the formula is inline (within a paragraph):** context is the current heading section (text between the most recent H1/H2/H3 and the next one, or top of doc and next heading).
2. **If the formula is block-level (its own line):** same, but includes the section up to (but not after) the formula itself.
3. **If the resolved section exceeds the model context window:** apply `ContextStrategy` (reusing apfel's existing strategies) to trim. Show a badge "`context trimmed`" on the span.
4. **If the user explicitly passes a context reference:** `=apfel("rewrite", =ref(@intro))` uses only that, no section auto-scoping.
5. **If the formula sidebar shows the context preview, the user can click "expand to whole doc" per call.**

### 7.2 Transparency requirements

- The formula sidebar (see section 8) always shows what context will be sent, as a scrollable preview, BEFORE the user hits Run.
- After evaluation, hovering a rendered formula span shows a tooltip with the exact context that was used and its token count.
- apfelpad never silently truncates without telling the user.

---

## 8. The formula sidebar - the killer UX feature

**As soon as the user types `=apfel(` anywhere in the document, a right-hand sidebar slides in with a complete formula authoring experience.**

This is the single most important UX element. If it works well, apfelpad feels magical. If it works badly, apfelpad is just a markdown editor with autocomplete.

### 8.1 Trigger conditions

The sidebar opens when:
- The user types `=<funcname>(` where `<funcname>` is any known formula
- The user clicks an existing formula span (for editing)
- The user invokes `⌘K` to insert a formula

The sidebar closes when:
- The formula is committed (Return on the closing paren)
- Esc is pressed
- The cursor moves outside the formula span

### 8.2 Sidebar layout

```
┌─ Formula ──────────────────────┐
│ =apfel(                        │  ← formula being authored, sync'd with doc
│                                │
├─ Function: apfel ──────────────┤
│ On-device LLM call             │  ← short help
│                                │
├─ Arguments ────────────────────┤
│ prompt:  [text field     ]     │  ← live-editable, echoes into doc
│ seed:    [42        ] 🎲        │  ← optional, dice = randomize
├─ Context ──────────────────────┤
│ Section: "Chapter 3"           │
│ [Current section ▼]            │  ← dropdown: Section / Doc / Custom
│ ┌───────────────────────────┐  │
│ │ ...context preview text... │  │  ← scrollable, what will be sent
│ └───────────────────────────┘  │
│ Tokens: 342 / 4096             │
├─ Run ──────────────────────────┤
│ [  Run (⌘↵)  ] [ Run + Pin ]   │  ← pin = cache forever, no re-run
├─ Recent ───────────────────────┤
│ =apfel("summarize", 42)        │  ← clickable history, per-document
│ =apfel("translate", 7)         │
└────────────────────────────────┘
```

### 8.3 Design principles for the sidebar

- **The sidebar mirrors the document, never replaces it.** Editing the prompt field in the sidebar also edits the formula source in the document. They are one thing.
- **It is discoverable, not imposed.** The sidebar appears as a gentle slide-in (200ms ease-out), never a modal. Keyboard users can ignore it entirely.
- **It is closeable.** Power users who know the formula syntax can close the sidebar and never see it again. Preference persists.
- **It shows the token budget.** Users who care about context windows see exactly what they are spending. Users who do not care see a small number.
- **It shows recent formulas (per document, not global).** This is the "I wrote this formula once, I want to tweak it" affordance.
- **It never blocks.** Generation happens in the background. The sidebar shows progress. The document stays editable.

---

## 9. Document model

### 9.1 File format: plain markdown + YAML frontmatter

```markdown
---
apfelpad: 1.0
seed: 1337           # default seed for unseeded formulas
cache: abc123.sqlite # sidecar cache reference
---

# Love letter to Franz

Dear Franz,

=apfel("write the opening of a love letter, warm and witty", 42)

Everything you do for apfel is worth =math(365*24) hours a year.
```

- The file extension is `.md` by default. Optionally `.apfel` for explicit branding.
- apfelpad files open cleanly in any markdown editor - formulas are visible as plain text. Graceful degradation is the feature.
- YAML frontmatter holds the document-level settings: schema version, default seed, cache sidecar path.

### 9.2 Cache sidecar

- Stored at `~/Library/Application Support/apfelpad/cache/<doc-hash>.sqlite`
- Schema: `formulas(key TEXT PRIMARY KEY, value TEXT, context_hash TEXT, model_version TEXT, created_at DATETIME)`
- Keyed by `sha256(formula_source || resolved_context || model_version)`
- Survives app restarts so rendered values persist without recomputing
- Never embedded in the markdown file - keeps the file clean and diff-friendly

### 9.3 Re-run semantics

- Cache hit: render instantly, show cached value.
- Cache stale (inputs changed): render the stale value with an amber "stale" indicator, wait for user action.
- Cache miss: run the formula, stream output into the span, cache on completion.
- Explicit re-run (⌘R on a selected formula, or hover-refresh icon): forces recomputation, overwrites cache entry.
- Pin (from sidebar "Run + Pin"): marks a cache entry as pinned, exempt from stale detection.

---

## 10. Architecture (mirrors apfel-chat 1:1)

The architecture is deliberately a carbon copy of `apfel-chat` so the TDD patterns, protocols, and build tooling carry over without friction.

```
Sources/
├── App/
│   ├── ApfelPadApp.swift          # SwiftUI @main, scene setup
│   ├── AppDelegate.swift          # menu, window lifecycle
│   └── ServerManager.swift        # spawns apfel --serve on 11450
├── Models/
│   ├── Document.swift             # the whole document state
│   ├── FormulaSpan.swift          # one formula span (source + value + state)
│   ├── FormulaResult.swift        # evaluated output + metadata
│   ├── NamedAnchor.swift          # heading anchors (@intro)
│   ├── CacheKey.swift             # composite hash for cache lookup
│   └── ApfelPadError.swift
├── Protocols/
│   ├── FormulaEvaluator.swift     # abstract formula evaluator
│   ├── LLMService.swift           # wrapper around apfel --serve
│   ├── DocumentPersistence.swift  # .md read/write
│   ├── FormulaCache.swift         # SQLite cache access
│   └── ContextResolver.swift      # figures out what context a formula sees
├── Services/
│   ├── FormulaParser.swift        # parses =apfel("...", 42) with auto-quoting
│   ├── FormulaRuntime.swift       # dispatches to per-function evaluators
│   ├── ApfelFormulaEvaluator.swift   # =apfel implementation (LLM via HTTP)
│   ├── MathFormulaEvaluator.swift    # =math implementation (pure Swift)
│   ├── RefFormulaEvaluator.swift     # =ref implementation
│   ├── ... other formula evaluators
│   ├── ApfelHTTPService.swift     # HTTP client for apfel --serve
│   ├── SQLiteFormulaCache.swift   # raw SQLite cache
│   └── MarkdownDocumentStore.swift# file read/write
├── ViewModels/
│   ├── DocumentViewModel.swift    # @Observable, holds the doc and all spans
│   ├── FormulaSidebarViewModel.swift  # sidebar state
│   └── FormulaBarViewModel.swift  # top-of-window formula bar
└── Views/
    ├── DocumentView.swift         # the main editor
    ├── FormulaSpanView.swift      # one rendered formula (light green)
    ├── FormulaSidebarView.swift   # right-hand sidebar
    ├── FormulaBarView.swift       # top formula bar (Excel-style)
    └── MarkdownRenderer.swift     # reused/copied from apfel-chat

Tests/
├── Mocks/
│   ├── MockLLMService.swift
│   ├── MockFormulaCache.swift
│   ├── MockContextResolver.swift
│   └── MockDocumentPersistence.swift
├── FormulaParserTests.swift        # the auto-quoting parser
├── FormulaRuntimeTests.swift
├── ApfelFormulaEvaluatorTests.swift
├── MathFormulaEvaluatorTests.swift
├── DocumentViewModelTests.swift
├── FormulaSidebarViewModelTests.swift
├── CacheKeyTests.swift
├── ContextResolverTests.swift
└── SQLiteFormulaCacheTests.swift
```

### 10.1 Key design decisions (locked in at briefing time)

- **Pragmatic about dependencies.** apfelpad deliberately diverges from apfel / apfel-chat / apfel-clip on this one point: external Swift packages are welcome where they genuinely add value. Good candidates include markdown parsing/rendering, syntax highlighting, an expression evaluator for `=math`, SQLite helpers, attributed-string editors, etc. Evaluate each dep on: maintenance, license, surface area, binary size, and security posture. The bar is "will this save us three days of correct work and is it well-maintained?" - not "can we live without it?" Do NOT reinvent a markdown parser, a math expression parser, or a robust attributed-text editor if a well-known Swift package already nails it.
- **Protocol-driven, TDD-first.** Every service has a protocol + mock. Every feature lands as test-first.
- **`@Observable` MVVM.** Views are thin; all logic in ViewModels. Same as apfel-chat.
- **SwiftUI `@main`.** App Store compatible. No NSApplication wrapper.
- **apfel under the hood.** Spawns `apfel --serve` on port 11450 at launch. Falls back to existing server if already running.
- **Formula runtime is pure.** `FormulaRuntime` and every individual evaluator are unit-testable with mocks - no FoundationModels or HTTP dependencies in the core runtime.
- **Context resolution is pure.** `ContextResolver` is tested against a fake document, not a real one.
- **The markdown document is the source of truth.** The ViewModel is derived from it, not the other way around. Save on every commit.

### 10.2 Port assignment

- apfel default: 11434
- apfel-clip: 11435
- apfel-chat: 11440-11449
- **apfelpad: 11450-11459** (new, claim this range in this briefing so future tools do not collide)

### 10.3 Update and upgrade check (copy apfel-chat's pattern exactly)

apfelpad checks for new releases via the GitHub API, using the same protocol + mock + concrete-implementation pattern as [`apfel-chat/Sources/Services/UpdateChecker.swift`](https://github.com/Arthur-Ficial/apfel-chat/blob/main/Sources/Services/UpdateChecker.swift).

Reference skeleton (adapted from apfel-chat, do not paraphrase - just change the repo path):

```swift
// Sources/Protocols/UpdateChecking.swift
protocol UpdateChecking {
    @MainActor
    func fetchLatestRelease(currentVersion: String) async throws -> LatestReleaseInfo
}

// Sources/Models/LatestReleaseInfo.swift
struct LatestReleaseInfo: Equatable { let version: String }

// Sources/Services/GitHubReleaseUpdateChecker.swift
struct GitHubReleaseUpdateChecker: UpdateChecking {
    let session: URLSession
    let apiURL: URL  // → https://api.github.com/repos/Arthur-Ficial/apfelpad/releases/latest
    // hits GH API, 10s timeout, User-Agent "apfelpad/<version>", strips leading "v"
}
```

Mock implementation lives in `Tests/Mocks/MockUpdateChecker.swift` returning a pre-configured `LatestReleaseInfo`. Unit tests verify: (1) version comparison logic, (2) error handling on non-2xx responses, (3) tag-name normalization (`v1.2.3` → `1.2.3`).

**Behavior:**
- On startup, if "check for updates on launch" is enabled (default: on, togglable in settings), `DocumentViewModel` (or a dedicated `StartupViewModel`) calls `updateChecker.fetchLatestRelease(currentVersion:)` on a background task.
- If the latest release version is greater than the current version, a non-blocking banner appears at the top of the window: `"apfelpad <x.y.z> is available. Install via 'brew upgrade apfelpad' or download from GitHub."`
- Users dismiss the banner for the session with one click. Preference to disable the check entirely lives in settings.
- The update check is a normal HTTPS call to `api.github.com`. This is the single network call apfelpad makes - it is not used for inference. Document this honestly in the README's privacy section.

This behaviour and file layout must match apfel-chat exactly so future changes to the pattern propagate cleanly across the family.

---

## 11. TDD plan

Following the apfel-chat pattern. Every feature lands in three commits:

1. **Protocol + mock** - define the interface, build the test double
2. **Test** - write the failing test against the mock
3. **Implementation** - make it pass

### 11.1 The first ten tests (in order)

These are the tests to write on day one. They cover the critical path and force the architecture to solidify before any UI is built.

1. **`FormulaParser: plain string literal`** - `=apfel("hello")` parses to `.apfelCall(prompt: "hello", seed: nil)`
2. **`FormulaParser: auto-quotes a bare word`** - `=apfel(hello)` parses identically to `=apfel("hello")`
3. **`FormulaParser: auto-quotes a bare phrase`** - `=apfel(hello world)` parses to `=apfel("hello world")`
4. **`FormulaParser: seed as second argument`** - `=apfel("hello", 42)` parses to `.apfelCall(prompt: "hello", seed: 42)`
5. **`FormulaParser: canonicalizes on commit`** - the stored string for `=apfel(hi)` is `=apfel("hi")`
6. **`MathEvaluator: arithmetic`** - `=math(42+2*3)` returns `"48"`
7. **`CacheKey: deterministic hash`** - same inputs produce same key, different inputs produce different keys
8. **`ApfelFormulaEvaluator: calls LLM service and caches result`** - using `MockLLMService`, verify the HTTP call shape and the cache write
9. **`ApfelFormulaEvaluator: cache hit skips LLM call`** - using `MockFormulaCache` with a pre-seeded entry
10. **`ContextResolver: current section only`** - a document with three headings, formula in section 2, resolver returns section 2 text only

No UI tests in the first pass. The UI is thin glue around the VM; the VM is what matters.

### 11.2 The integration test that proves the product works

One end-to-end test that nobody writes until the CLI skeleton exists:

> Open a blank document. Type `=apfel(hello world)`. Commit. Assert that the document now contains a rendered formula span, that the cache has one entry, that re-running from the sidebar produces the same value (seeded), and that changing the seed invalidates the cache and produces a new call.

If this test passes, the product is real. Everything else is polish.

---

## 12. Staged rollout

Each version is shippable. Each version adds one clear capability. No version is allowed to depend on a feature from a future version.

### v0.1 - Markdown editor + `=math` only
The whole formula pipeline end-to-end for the simplest possible function. No LLM. Proves parser, cache, renderer, click-to-edit, and the light-green span rendering. This is the skeleton that `=apfel` will hang on.

### v0.2 - `=apfel` inline, no sidebar
Adds the LLM formula, calling `apfel --serve` on 11450. Auto-quoting works. Seed parameter works. Cache works. Streaming into the span works. Still no sidebar. Users can already use it.

### v0.3 - Formula sidebar
The signature UX moment. Type `=apfel(`, watch the sidebar slide in. Context preview. Token budget. Recent formulas. Run/Pin buttons.

### v0.4 - Named anchors + `=ref` + `=count`
The document becomes self-referential. `=apfel("summarize", =ref(@intro))` works. Formulas compose.

### v0.5 - `=date`, `=clip`, `=file`
Hooks into the world. `=apfel("fix", =clip())` becomes the day-to-day power move.

### v0.6 - Context strategy integration
When sections overflow 4096 tokens, context is trimmed intelligently using apfel's existing `ContextStrategy`, with a visible badge.

### v0.7 - Document cache UI
Show the cache size, allow clearing stale entries, allow "rebuild everything" for when the model updates.

### v0.8 - File format spec freeze
Frontmatter schema locked. Migration path for future versions. First stable `.apfelpad` format.

### v0.9 - Polish, signing, notarisation
Release-quality. Homebrew cask. Install from zip. Landing page.

### v1.0 - Launch
The first version we are willing to tell strangers about.

---

## 13. Hard problems (named, not hidden)

These are the problems that will bite if we do not think about them up front. Each is flagged so future sessions can find them.

### 13.1 Parsing nested formulas with auto-quoting

`=apfel(summarize this, =ref(intro))` is ambiguous: is `summarize this` a bare string or an attempted call? The rule must be: if a token starts with `=`, it is a sub-formula; if it starts with `@`, it is an anchor; everything else is an auto-quoted string. This is unambiguous but it must be the only rule, consistently applied. The parser needs a fuzz test suite.

### 13.2 Cache invalidation on edit

When does a cached value become stale? Inputs that matter: formula source, resolved context, model version, seed. Inputs that do not matter: surrounding text not in the resolved context, user scroll position, sidebar state. The `ContextResolver` must return a stable serialization of "what the formula sees" and the cache must hash it. Tricky edge case: if the user edits a sentence OUTSIDE the current section, the formula is NOT stale. Getting this right is what separates "feels magical" from "feels random".

### 13.3 Latency and flow state

The document must never feel laggy. Strategy: formula evaluation is fully async, streams into the span, never blocks the cursor. The parser runs on debounce (150ms after last keystroke). The sidebar mirrors the formula in real time, but the LLM call happens only on commit. If any keystroke ever triggers a sync LLM call, the product is broken.

### 13.4 The render-vs-source toggle

Is the source view global (⌘R shows all formula sources) or per-span (click to see one)? Both. Global toggle for "show me all the formula sources in this doc" (power move, great for copy-pasting a template). Per-span click for "I want to edit this one". The formula bar at the top is always showing the selected span's source so novices who never toggle can still see and edit sources.

### 13.5 Determinism without a real seed API

If FoundationModels does not expose a seed, we fall back to temperature=0 + cache-key-only seeds. Users cannot tell the difference until they try the same seed on two different Macs with different models - at which point the cache miss regenerates and they get different outputs. This is acceptable but it must be documented honestly in the README. No fake determinism.

### 13.6 The "reader model" feature (from the earlier brainstorm)

The left-panel live reader model (thesis drift, contradictions, questions a reader would ask) is NOT in v1.0. It is a v1.x or v2.0 feature. The v1.0 scope is the formula model. Adding the reader model on top later is easy; adding formulas on top of a reader model is not. Scope discipline.

### 13.7 Mobile story

iOS is not in v1.0. The architecture (SwiftUI + ApfelCore + protocol-driven) is iOS-portable by construction, and `apfel --serve` on iOS is blocked by the sandbox, so the iOS port would talk to FoundationModels directly via a thin adapter conforming to `LLMService`. This is a v2.0 project, not a v1.0 project. Flag and move on.

---

## 14. The killer demo (what sells the idea in 30 seconds)

A 30-second screen recording. No narration. Caption says: "A notepad where AI is just a formula."

1. Empty document, cursor blinking. (1s)
2. User types a heading: `# Love letter to Franz`. (2s)
3. User types a sentence: `Dear Franz,` then newline. (2s)
4. User types `=apfel(something warm and witty about apfelpad)`. The sidebar slides in from the right. (3s)
5. User presses ⌘Enter. The formula span fills with light green. Tokens stream in character by character into the span. The sidebar shows "342 / 4096 tokens" and the model running. (8s)
6. User presses ⌘Enter again with a new seed showing `7`. The span regenerates with different words but the same pale green background. (5s)
7. User clicks on the rendered span. The formula bar at the top shows `=apfel("something warm and witty about apfelpad", 7)`. User edits the prompt in the formula bar to `"more playful"`. Presses Return. The span regenerates. (6s)
8. Final frame: the document with three versions of the love letter, each a formula span, each seeded, each a first-class artefact. Text appears: "apfelpad - a formula notepad for thinking". (3s)

If that demo lands in 30 seconds, apfelpad is a real product. Everything else is scaffolding around that moment.

---

## 15. Open questions (to resolve before v0.2)

1. **Does FoundationModels SDK expose a sampler seed?** If yes, seed is pass-through. If no, seed is cache-key-only with temperature=0 fallback. Either way, user-visible behaviour is the same. Verify before v0.2.
2. **Should `.apfelpad` be a distinct extension or always `.md`?** Defaulting to `.md` for graceful degradation, but a visible "save as .apfelpad" option lets power users opt into a distinct file type. Revisit if users complain.
3. **How does the formula bar behave when no formula is selected?** Empty state? Last-selected? Placeholder hint? Probably empty with a placeholder `"click a formula span to edit its source"`.
4. **Where does the cache sidecar live?** `~/Library/Application Support/apfelpad/cache/<doc-hash>.sqlite` by default. Global cache? Per-doc? Per-doc seems right but needs thought.
5. **iCloud sync of documents:** works trivially for the `.md` file. The cache sidecar does not sync (it can be regenerated). Document this in the README.
6. **Undo/redo across formula evaluations:** ⌘Z on a generation event should revert the span to its previous cached value, not undo the evaluation itself. Nontrivial to implement. Needs a design pass before v0.3.
7. **Multi-window:** one document per window? Tabs? Split view (source + rendered)? Start with one window per document. Add split view in v0.5 if the need is felt.

---

## 16. Related repos - where apfelpad fits in the ecosystem

apfelpad is a **consumer app built on apfel**, in the same family as `apfel-chat`, `apfel-clip`, and `apfel-quick`. It is NOT a new CLI tool and it does NOT add to the OpenAI API surface. It is a Mac-native writing tool that happens to embed an on-device LLM via the `apfel --serve` HTTP API.

| Repo | GitHub | Relationship to apfelpad |
|---|---|---|
| `apfel` | https://github.com/Arthur-Ficial/apfel | **The engine and the underlying technology.** On-device Foundation Models via the `FoundationModels` framework, wrapped in a CLI and an OpenAI-compatible HTTP server. apfelpad spawns `apfel --serve` on port 11450 at launch. All inference goes through apfel. No direct FoundationModels imports in apfelpad's own code. |
| `apfel-chat` | https://github.com/Arthur-Ficial/apfel-chat | **The architectural and coding-style template.** Every pattern apfelpad uses is already shipped and tested in apfel-chat: SwiftUI `@main`, protocol-driven TDD with swift-testing, `@Observable` MVVM, `ServerManager` for spawning apfel, `UpdateChecker` for GitHub releases, SQLite via raw C, `./scripts/release.sh` for sign+notarise+tag+upload, Homebrew cask in `Arthur-Ficial/homebrew-tap`. When in doubt, read apfel-chat. |
| `apfel-clip` | https://github.com/Arthur-Ficial/apfel-clip | The color palette reference. Pale green background + dark green accent. Copy the exact RGB values. |
| `apfel-ecosystem` | https://github.com/Arthur-Ficial/apfel-ecosystem | The shared principles: 100% local, honest, UNIX-first where applicable, TDD, German-named where appropriate. **apfelpad diverges from the family-wide "zero external deps" rule** - see section 10.1 for the pragmatic dep story. Every other principle still applies. |
| `apfel-gui` | https://github.com/Arthur-Ficial/apfel-gui | The debug GUI. Separate concern. No overlap. |
| `apfel-quick` | https://github.com/Arthur-Ficial/apfel-quick | Menu bar quick-prompt. Different product, different scope. |
| `homebrew-tap` | https://github.com/Arthur-Ficial/homebrew-tap | Where the apfelpad cask will live. Same tap as the rest of the family. |

### 16.1 What to copy from apfel-chat, verbatim or near-verbatim

When scaffolding v0.1, these files from apfel-chat should be used as starting points. Not studied, not re-imagined - copied, renamed, and adapted to apfelpad's formula domain:

| apfel-chat file | apfelpad equivalent | What to change |
|---|---|---|
| `Sources/App/ApfelChatApp.swift` | `Sources/App/ApfelPadApp.swift` | Window content, scene title |
| `Sources/App/ServerManager.swift` | `Sources/App/ServerManager.swift` | Port range 11450-11459, same spawning logic |
| `Sources/App/ChatControlServer.swift` | (optional) `Sources/App/PadControlServer.swift` | Local HTTP control API for automation, same shape |
| `Sources/Services/UpdateChecker.swift` | `Sources/Services/UpdateChecker.swift` | Change `apfel-chat` to `apfelpad` in API URL + User-Agent |
| `Sources/Services/SQLitePersistence.swift` | `Sources/Services/SQLiteFormulaCache.swift` | Schema: formulas table instead of conversations+messages |
| `Sources/Protocols/*.swift` | `Sources/Protocols/*.swift` | Same idioms, different domain types |
| `Tests/Mocks/*.swift` | `Tests/Mocks/*.swift` | Same mock patterns |
| `Tests/*ViewModelTests.swift` | `Tests/*ViewModelTests.swift` | Same `@Suite`/`@Test`/`#expect` style |
| `scripts/release.sh` | `scripts/release.sh` | Change app name, bundle ID, release notes template |
| `Makefile` | `Makefile` | Same targets: `build`, `test`, `app`, `install`, `dist`, `release` |
| `Info.plist`, entitlements | same | Update bundle ID to `com.fullstackoptimization.apfelpad` |
| Landing page (apfel-chat.franzai.com) | apfelpad.franzai.com | Separate Cloudflare Pages project |

### 16.2 Underlying technology — explicit statement

apfelpad does not contain any on-device inference code. It does not `import FoundationModels` anywhere. It does not call `SystemLanguageModel` or `LanguageModelSession` directly. Every language model call in apfelpad goes through an HTTP POST to `http://localhost:11450/v1/chat/completions`, where `apfel --serve` is the listener. This is deliberate:

- It keeps apfelpad small and portable (the architecture is ready for iOS one day).
- It lets apfel own all the hard problems: context window management, streaming, tool calling, retries, MCP integration, schema conversion, token counting.
- It means every improvement Franz ships in apfel is immediately available in apfelpad without code changes in apfelpad.
- It keeps the testing story clean: `LLMService` is one protocol with one mock; the HTTP transport is tested once, not per feature.

The full technology story and Foundation Models details live in apfel's README: https://github.com/Arthur-Ficial/apfel. Read it before doing anything clever with context windows or tool calling.

---

## 17. Naming and language rules (locked in)

- **App name:** `apfelpad` (all lowercase in text, capitalized "apfelpad" is fine at sentence starts)
- **Binary name:** `apfelpad` (same)
- **Bundle ID:** `com.franzai.apfelpad` or `com.fullstackoptimization.apfelpad` - choose before v0.1 ships
- **NEVER use the word "Apple" in user-visible strings.** Use "on-device", "your Mac", "Foundation Models on your Mac", "private AI", "local AI". Same rule as apfel-chat. This is non-negotiable.
- **"Formula" is the primary noun.** Not "cell", not "block", not "AI prompt". Formula. Consistently.
- **"Span" is the rendered thing** (the light-green rectangle) in code and internal docs only. Users see "formula" in UI.
- **Marketing tagline candidates:**
  - "A formula notepad for thinking."
  - "Your Mac just learned =apfel()."
  - "Spreadsheets for words, running on your Mac."

---

## 18. What apfelpad is NOT

Scope discipline. Every "no" below is a "yes" to the core vision.

- **Not a rich-text editor.** Markdown only. No tables, no images embedded, no fonts. The formula IS the rich feature.
- **Not Obsidian / Notion / Roam.** No graph view, no backlinks-as-DB, no plugins. One file, one window, one purpose.
- **Not a collaboration tool.** Single user, local only. `git` is the collaboration layer if you need one.
- **Not a chat app.** `apfel-chat` exists for that.
- **Not a clipboard tool.** `apfel-clip` exists for that.
- **Not a menu bar utility.** `apfel-quick` exists for that.
- **Not a cloud product.** Ever.
- **Not a first-reader / thesis-drift critic in v1.0.** That is a v2.0 feature. v1.0 ships the formula primitive and nothing else. Scope discipline.

---

## 19. Summary

apfelpad is a markdown notepad that embeds on-device AI as a first-class formula (`=apfel(prompt, seed?)`), alongside `=math`, `=ref`, `=count`, `=date`, `=clip`, and `=file`. Formulas auto-quote bare arguments, render inline in a pale-green span with a dark-green border, support click-to-edit and a live formula sidebar, and cache deterministically via composite keys. The architecture mirrors `apfel-chat`: SwiftUI + protocol-driven MVVM + TDD with swift-testing + SQLite + the same `UpdateChecker` + release workflow. Unlike the rest of the apfel family, apfelpad is pragmatic about external Swift packages - well-maintained deps are welcome where they genuinely add value. The engine is always `apfel --serve` talking to the on-device `FoundationModels` framework. The staged rollout lands `=math` first (v0.1), `=apfel` inline second (v0.2), and the sidebar third (v0.3). The product is a spreadsheet for thinking, running entirely on your Mac.

The north star question for every design decision: **"Does this make the formula primitive feel more or less like a real function?"** If more, ship it. If less, cut it.

---

*End of briefing. Next action: review this document, resolve open questions in section 15, then scaffold v0.1 following `apfel-chat`'s structure.*
