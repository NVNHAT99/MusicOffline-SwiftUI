# Documentation Index

Welcome to MusicOffline-SwiftUI documentation. Use this index to navigate project documentation.

## Quick Links

### For New Contributors
Start here to understand the project:
1. **[Project Overview & PDR](./project-overview-pdr.md)** — Vision, requirements, acceptance criteria
2. **[Codebase Summary](./codebase-summary.md)** — Architecture overview, directory structure, core components
3. **[Code Standards](./code-standards.md)** — Naming conventions, patterns, code organization guidelines

### For Architecture & Design
Understanding how the system is built:
1. **[System Architecture](./system-architecture.md)** — Detailed architecture, data flow, design patterns
2. **[Development Roadmap](./development-roadmap.md)** — Completed phases, planned features, timelines

### For Maintenance & Updates
Tracking what's changed and what's planned:
1. **[Project Changelog](./project-changelog.md)** — All changes by phase, version history, breaking changes
2. **[Development Roadmap](./development-roadmap.md)** — Upcoming phases, feature prioritization

---

## Document Descriptions

### project-overview-pdr.md (497 lines)
**Executive-level overview and Product Development Requirements.**

Contents:
- Project vision & market position
- Functional & non-functional requirements
- Acceptance criteria (Phase 04)
- Technical stack details
- Risks & mitigations
- Success metrics
- Timeline & resources

**Use this to:** Understand project scope, requirements, acceptance criteria, and success metrics.

**Audience:** Product managers, stakeholders, team leads.

---

### codebase-summary.md (277 lines)
**High-level overview of the codebase structure and core components.**

Contents:
- Architecture pattern (Clean Architecture + MVVM)
- Directory structure
- Core components (DI, Domain, Data, Presentation)
- Services overview
- Data flow examples
- Key patterns & conventions
- Phase 04 changes summary

**Use this to:** Get oriented in the codebase quickly, understand how pieces fit together.

**Audience:** New developers, code reviewers, architects.

---

### system-architecture.md (572 lines)
**Comprehensive architecture documentation with implementation details.**

Contents:
- Architectural layers (Presentation, Domain, Data)
- MVI pattern explanation with examples
- Use case organization & implementation
- Repository pattern & entity mapping
- Dependency injection setup
- Networking & services
- Event publishing system
- Threading model
- Phase 04 feature details (reorder, import)
- Testing architecture

**Use this to:** Deep dive into architecture, understand design decisions, implement new features.

**Audience:** Developers, architects, code reviewers.

---

### code-standards.md (692 lines)
**Coding guidelines, patterns, and best practices for the project.**

Contents:
- Naming conventions (PascalCase, camelCase, kebab-case)
- File organization templates
- Code style (spacing, comments, access control)
- Architectural patterns (Use Case, Repository, MVI, DI)
- Error handling patterns
- Testing standards & templates
- Performance guidelines
- Security checklist
- Code review checklist
- Common pitfalls & solutions

**Use this to:** Write code that fits the project style, understand best practices.

**Audience:** All developers, code reviewers.

---

### project-changelog.md (245 lines)
**Detailed record of all significant changes and version history.**

Contents:
- Phase 04 changes (new use cases, features, modifications)
- Phase 03-01 summaries
- Initial release features
- Version history table
- Breaking changes & migrations
- Known limitations

**Use this to:** Understand what changed and when, track project evolution.

**Audience:** All team members, users tracking updates.

---

### development-roadmap.md (378 lines)
**Long-term plan for features, improvements, and research phases.**

Contents:
- Current status & phase overview
- Phase 05 details (Playback improvements)
- Phase 06 details (Feature brainstorm)
- Completed phases (01-04) summary
- Long-term vision (6-12 months)
- Risk assessment & mitigation
- Metrics & success criteria
- Decision log
- References to related docs

**Use this to:** Understand what's planned, prioritize work, align with product vision.

**Audience:** Product managers, team leads, developers.

---

## Getting Started

### Step 1: Understand the Project (15 min)
Read: **project-overview-pdr.md** (executive summary section)

### Step 2: Explore the Codebase (30 min)
Read: **codebase-summary.md** (full document)

### Step 3: Learn Code Standards (45 min)
Read: **code-standards.md** (focus on relevant sections)

### Step 4: Deep Dive into Architecture (1 hour)
Read: **system-architecture.md** (relevant to your task)

### Step 5: Check What's Changed (15 min)
Read: **project-changelog.md** (Phase 04 section)

**Total Time: ~2 hours** for complete orientation

---

## Common Tasks

### "I want to add a new feature"
1. Read: **development-roadmap.md** (understand priorities)
2. Read: **code-standards.md** (naming, patterns)
3. Reference: **system-architecture.md** (layer requirements)
4. Follow: MVI pattern from **system-architecture.md** → Code example in **code-standards.md**

### "I need to fix a bug"
1. Check: **project-changelog.md** (related fixes)
2. Reference: **system-architecture.md** (affected layers)
3. Read: **code-standards.md** (error handling, testing)

### "I need to understand Phase 04 changes"
1. Read: **project-changelog.md** (Phase 04 section)
2. Read: **codebase-summary.md** (Phase 04 summary)
3. Deep dive: **system-architecture.md** (Phase 04 features section)

### "I want to review someone's code"
1. Reference: **code-standards.md** (code review checklist)
2. Reference: **system-architecture.md** (architecture expectations)
3. Check: **project-changelog.md** (any relevant breaking changes)

### "I'm writing tests"
1. Read: **code-standards.md** (testing standards section)
2. Reference: **system-architecture.md** (testing architecture)
3. Example: **code-standards.md** (test templates)

---

## File Organization

```
docs/
├── README.md                      ← You are here
├── project-overview-pdr.md        # Requirements & vision
├── codebase-summary.md            # Architecture overview
├── system-architecture.md         # Detailed architecture
├── code-standards.md              # Coding guidelines
├── project-changelog.md           # Change history
└── development-roadmap.md         # Future planning
```

All docs are in Markdown format. No external tools needed to read them.

---

## Key Concepts Quick Reference

### Architecture Layers
```
Presentation (Views, ViewModels, State)
    ↓ depends on
Domain (Use Cases, Entities, Protocols)
    ↓ depends on
Data (Repositories, CoreData, Mappers)
```

### MVI Pattern
```
User Action → Intent → ViewModel → UseCase → Repository 
    ↑                                              ↓
    ←─────────── State Update ←─ Reducer ←─────←
```

### Dependency Flow
```
Concrete Services (GCDWebServer, CoreDataManager)
    ↓ injected via protocols
Use Cases (AddPlaylistUseCase, ImportSongUseCase)
    ↓ injected via protocols
ViewModels (PlaylistDetailViewModel)
    ↓ environment-injected
Views (PlaylistDetailView)
```

---

## Phase Context

**Current Phase:** Phase 04 - Playlist Management ✅ Complete (2026-04-29)

**What's New in Phase 04:**
- Reorder songs via drag & drop
- Import audio files from iOS Files app
- Sort playlists (name, date, count)
- Enhanced validation (trim, length, uniqueness)
- Bulk delete songs

**See:** 
- Phase 04 details: `project-changelog.md` → Phase 04 section
- Implementation: `system-architecture.md` → Phase 04 section

**Next Phase:** Phase 05 - Playback Improvements (Planned May 13-27)

**See:** `development-roadmap.md` → Phase 05 section

---

## Maintenance Notes

| Document | Last Updated | Maintainer | Next Review |
|----------|-------------|-----------|------------|
| project-overview-pdr.md | 2026-04-29 | Dev Team | 2026-05-13 |
| codebase-summary.md | 2026-04-29 | Dev Team | 2026-05-13 |
| system-architecture.md | 2026-04-29 | Dev Team | 2026-05-13 |
| code-standards.md | 2026-04-29 | Dev Team | 2026-05-15 |
| project-changelog.md | 2026-04-29 | Dev Team | 2026-05-27 |
| development-roadmap.md | 2026-04-29 | Dev Team | 2026-05-13 |

All documents are kept in sync with Phase 04 completion.

---

## How to Contribute

### Updating Documentation
1. Edit relevant document in `docs/`
2. Keep line count under 800 per file
3. Update "Last Updated" date
4. Update "Maintenance Notes" table
5. Cross-reference related docs
6. Test Markdown rendering (code blocks, tables, links)

### Adding New Documentation
1. Check if topic fits existing documents
2. If new topic: create new file with descriptive name
3. Add entry to this README.md
4. Keep files focused and under 800 lines
5. Link from relevant existing documents

### Documentation Standards
- Clear, concise writing (explain "why", not "what")
- Code examples are always correct
- Links are tested before committing
- Markdown is properly formatted
- No absolute paths in docs (use relative or conceptual)

---

## Feedback & Issues

Found outdated docs? Incorrect information? Missing details?

1. **Quick fix:** Edit the document directly (follow contribution guidelines)
2. **Discussion:** Open an issue with context
3. **Major change:** Discuss in team channel before updating

---

## Legal & Licensing

This documentation is part of MusicOffline-SwiftUI. Follow the same license as the codebase.

---

**Documentation Status:** ✅ Complete & Current  
**Last Updated:** 2026-04-29  
**Maintained by:** Development Team  
**Next Review:** 2026-05-13
