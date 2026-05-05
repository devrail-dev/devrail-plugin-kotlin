# devrail-plugin-kotlin

DevRail plugin: Kotlin language ecosystem (ktlint, detekt, Gradle, JDK 21).

This is the **reference plugin** extracted from `dev-toolchain` core during
[Story 13.7](https://github.com/devrail-dev/devrail-standards/blob/main/_bmad-output/implementation-artifacts/13-7-extract-kotlin-as-reference-plugin.md).
It demonstrates the v1 plugin model and serves as the template for other
languages that will follow the same extraction path in v2.0.0.

## What's included

- **JDK 21** (Eclipse Temurin) — copied from the `eclipse-temurin:21-jdk`
  builder stage by the dev-toolchain build pipeline (Story 13.4).
- **[ktlint](https://github.com/pinterest/ktlint) 1.5.0** — Kotlin linter
  and formatter using the official Kotlin coding conventions.
- **[detekt](https://github.com/detekt/detekt) 1.23.7** — configurable
  static analysis for Kotlin (complexity, potential bugs, code smells).
- **[Gradle](https://gradle.org/) 8.12** — the standard Kotlin build tool.
- **OWASP dependency-check** — Gradle plugin for scanning dependencies
  against the National Vulnerability Database (consumed via
  `gradle dependencyCheckAnalyze`).

## Consumer-side declaration

Add to your project's `.devrail.yml`:

```yaml
plugins:
  - source: github.com/devrail-dev/devrail-plugin-kotlin
    rev: v1.0.0
    languages: [kotlin]
```

Then:

```sh
make plugins-update    # resolves rev → SHA, writes .devrail.lock
make check             # builds the project-local extended image and runs all targets
```

> **Note:** While `dev-toolchain` v1.10.x and v1.11.x continue to ship
> Kotlin in core, declaring `kotlin` in `languages:` will hit the in-core
> path FIRST (per the loader's "core wins" precedence rule). To exercise
> this plugin, declare it in `plugins:` only — leave `kotlin` out of the
> top-level `languages:` list. v2.0.0 (Story 13.9) removes the in-core
> Kotlin path; from then on, this plugin is the only path.

## Targets

The plugin maps to the standard DevRail Makefile targets:

| Target          | Command                                                                 | Gate              |
|-----------------|-------------------------------------------------------------------------|-------------------|
| `lint`          | `ktlint && detekt-cli ...`                                              | `build.gradle.kts` |
| `format_check`  | `ktlint --format --dry-run`                                             | `build.gradle.kts` |
| `format_fix`    | `ktlint --format`                                                        | `build.gradle.kts` |
| `test`          | `gradle test --no-daemon`                                                | `build.gradle.kts` |
| `security`      | `gradle dependencyCheckAnalyze --no-daemon`                              | `build.gradle.kts` |

The `lint` target chains ktlint AND detekt with `&&` because the v1
plugin contract is one cmd per target. To override either tool
individually, use a per-language override in your `.devrail.yml`:

```yaml
kotlin:
  linter: "ktlint"          # drop detekt
  test: "gradle test --info" # extra Gradle flags
```

Override key map (per the [`.devrail.yml` schema](https://github.com/devrail-dev/devrail-standards/blob/main/standards/devrail-yml-schema.md)):
`lint→linter`, `format_check`/`format_fix→formatter`, `fix→fixer`,
`test→test`, `security→security`. Overrides take the cmd verbatim.

## Versioning

- **`schema_version: 1`** — the manifest format. v1.10.0 baseline.
- **`version`** — this plugin's own semver. Bumped on releases.
- **`devrail_min_version: 1.10.0`** — the oldest dev-toolchain version
  that supports this plugin (when the plugin loader first stabilized).

| Plugin version | dev-toolchain min | Notes                                                          |
|----------------|-------------------|----------------------------------------------------------------|
| `v1.0.0`       | `1.10.0`          | Initial extraction. ktlint 1.5.0, detekt 1.23.7, Gradle 8.12.  |

## Local development

To test changes to this plugin against a consumer workspace:

```yaml
# In the consumer's .devrail.yml
plugins:
  - source: file:///path/to/devrail-plugin-kotlin
    rev: v1.0.0
    languages: [kotlin]
```

```sh
make plugins-update
make check
```

## Contributing

This plugin follows DevRail standards. To work on it:

```sh
make check               # lint, format, test, security, scan
make install-hooks       # one-time pre-commit setup
```

All commits use [conventional commit format](https://github.com/devrail-dev/devrail-standards/blob/main/standards/git-workflow.md).

## License

[MIT](LICENSE)

## See also

- [Plugin architecture design doc](https://github.com/devrail-dev/dev-toolchain/blob/main/docs/plugin-architecture.md)
- [Contributing a Plugin guide](https://github.com/devrail-dev/devrail-standards/blob/main/standards/contributing.md#contributing-a-plugin)
- [`.devrail.yml` schema](https://github.com/devrail-dev/devrail-standards/blob/main/standards/devrail-yml-schema.md)
- [Release blog post](https://devrail.dev/blog/2026-05-05-plugin-architecture/)
