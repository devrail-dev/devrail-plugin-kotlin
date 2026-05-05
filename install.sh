#!/usr/bin/env bash
# install.sh — Install Kotlin tooling inside the project-local extended image
#
# Purpose: Runs during `docker build` of the consumer's `Dockerfile.devrail`.
#          Downloads ktlint, detekt-cli, and Gradle into /usr/local/. The JDK
#          itself is COPY'd from the eclipse-temurin:21-jdk builder stage by
#          the manifest's container.copy_from_builder block.
#
# Usage:   bash install.sh
#
# Self-contained: NO dependency on dev-toolchain's lib/log.sh — plugin install
# scripts run during the docker build step before any DevRail libs are
# available in the image. Status messages go to stderr via plain printf.

set -euo pipefail

log() {
  printf '[install-kotlin] %s\n' "$*" >&2
}

# --- ktlint ---
if command -v ktlint >/dev/null 2>&1; then
  log "ktlint already installed; skipping"
else
  KTLINT_VERSION="1.5.0"
  log "installing ktlint ${KTLINT_VERSION}"
  curl -fsSL "https://github.com/pinterest/ktlint/releases/download/${KTLINT_VERSION}/ktlint" \
    -o /usr/local/bin/ktlint
  chmod +x /usr/local/bin/ktlint
fi

# --- detekt-cli ---
if [[ -f /usr/local/lib/detekt-cli.jar ]]; then
  log "detekt-cli already installed; skipping"
else
  DETEKT_VERSION="1.23.7"
  log "installing detekt-cli ${DETEKT_VERSION}"
  mkdir -p /usr/local/lib
  curl -fsSL "https://github.com/detekt/detekt/releases/download/v${DETEKT_VERSION}/detekt-cli-${DETEKT_VERSION}-all.jar" \
    -o /usr/local/lib/detekt-cli.jar
  cat >/usr/local/bin/detekt-cli <<'WRAPPER'
#!/usr/bin/env bash
exec java -jar /usr/local/lib/detekt-cli.jar "$@"
WRAPPER
  chmod +x /usr/local/bin/detekt-cli
fi

# --- Gradle ---
if command -v gradle >/dev/null 2>&1; then
  log "gradle already installed; skipping"
else
  GRADLE_VERSION="8.12"
  log "installing gradle ${GRADLE_VERSION}"
  TMPDIR_INSTALL="$(mktemp -d)"
  trap 'rm -rf "${TMPDIR_INSTALL}"' EXIT
  curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    -o "${TMPDIR_INSTALL}/gradle.zip"
  unzip -q "${TMPDIR_INSTALL}/gradle.zip" -d /opt
  ln -sf "/opt/gradle-${GRADLE_VERSION}/bin/gradle" /usr/local/bin/gradle
fi

# --- Verify ---
log "verifying installation"
java -version 2>&1 | head -1 >&2
ktlint --version 2>&1 | head -1 >&2
detekt-cli --version 2>&1 | head -1 >&2
gradle --version 2>&1 | grep '^Gradle' | head -1 >&2

log "kotlin plugin tools installed successfully"
