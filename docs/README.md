# Documentation Hub

This directory is the canonical documentation set for **ROOM 407: THE LAST SHIFT**.
The game and source comments are in English; the Vietnamese guide is a curated player and
release aid, not an in-game UI, subtitle, or voice localization.

## Start Here

| Audience | Recommended reading |
|---|---|
| Players downloading the Windows build | [Release v0.9.0](release-v0.9.0.md) and [Vietnamese guide](vi/README.md) |
| Players building from source | [Deployment guide](deployment-guide.md) |
| Contributors | [Contributing](../CONTRIBUTING.md), [Code standards](code-standards.md), and [Testing](testing.md) |
| Reviewers | [Project overview and PDR](project-overview-pdr.md), [Limitations](limitations.md), and [Asset credits](asset-credits.md) |

## Documentation Map

| Document | Purpose |
|---|---|
| [Release v0.9.0](release-v0.9.0.md) | Windows ZIP contents, checksum verification, startup guidance, and release limits |
| [Vietnamese guide](vi/README.md) | Vietnamese player/release guide; English technical evidence remains canonical |
| [Project overview and PDR](project-overview-pdr.md) | Product requirements, accepted risks, and delivery boundaries |
| [Architecture](architecture.md) | Runtime ownership, data flow, and extension points |
| [Codebase summary](codebase-summary.md) | Repository layout and delivery surfaces |
| [Code standards](code-standards.md) | GDScript, scene ownership, testing, and documentation conventions |
| [Testing](testing.md) | Commands, automated coverage, and manual-QA boundaries |
| [Deployment guide](deployment-guide.md) | Source launch, export, CI, container suite, and release operations |
| [Limitations](limitations.md) | Distribution, verification, and support boundaries |
| [Project roadmap](project-roadmap.md) | Completed work, historical evidence, and optional future QA |
| [Asset credits and provenance](asset-credits.md) | Project media, attribution, licensing, and documentation capture provenance |

## Documentation Conventions

- Treat English technical documents as the authoritative source for code contracts,
  test evidence, hashes, and release mechanics.
- Keep dated plans and journals as historical records. Do not rewrite their claims when
  a newer release supersedes them; add the durable current state to an evergreen guide.
- GitHub Release assets are available only when they are listed on the tag's release
  page. A link in documentation describes the intended artifact name, not proof that an
  upload has completed.
- The public GHCR image is a headless CI/test package. It is not the Windows game and
  must never be presented as a gameplay download.

## Language Navigation

[English repository README](../README.md) | [Hướng dẫn tiếng Việt](vi/README.md)
