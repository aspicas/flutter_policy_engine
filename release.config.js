const fs = require("fs");

module.exports = {
  branches: ["main"],
  plugins: [
    [
      "@semantic-release/commit-analyzer", // Detects the release type (major, minor, patch)
      {
        preset: "conventionalcommits",
        releaseRules: [
          // Ignore merge commits
          { subject: "*Merge pull request*", release: false },
          { subject: "*Merge branch*", release: false },
          // Ignore chore commits (they won't trigger releases)
          { type: "chore", release: false },
          // You can also ignore other types if needed
          { type: "docs", release: false },
          { type: "style", release: false },
          { type: "refactor", release: false },
          { type: "test", release: false },
          // Standard rules for releases
          { type: "feat", release: "minor" },
          { type: "fix", release: "patch" },
          { type: "perf", release: "patch" },
          // Breaking changes always trigger major
          { breaking: true, release: "major" },
        ],
      },
    ],
    [
      "@semantic-release/release-notes-generator", // Generates release notes,
      {
        preset: "conventionalcommits",
        presetConfig: {
          types: [
            { type: "feat", section: "Features" },
            { type: "fix", section: "Bug Fixes" },
            { type: "perf", section: "Performance Improvements" },
            // Exclude chore from release notes
            { type: "chore", hidden: true },
            { type: "docs", hidden: true },
            { type: "style", hidden: true },
            { type: "refactor", hidden: true },
            { type: "test", hidden: true },
          ],
        },
      },
    ],
    "@semantic-release/changelog", // Updates CHANGELOG.md
    [
      {
        // Hook to update pubspec.yaml
        prepare: (pluginConfig, context) => {
          const version = context.nextRelease.version;
          const filePath = "pubspec.yaml";

          let pubspec = fs.readFileSync(filePath, "utf8");
          pubspec = pubspec.replace(/^version: .*/m, `version: ${version}`);
          fs.writeFileSync(filePath, pubspec);

          context.logger.log(
            `✅ pubspec.yaml actualizado a version: ${version}`
          );
        },
      },
    ],
    [
      "@semantic-release/git", // Commits CHANGELOG and bumps version if needed
      {
        assets: ["CHANGELOG.md", "pubspec.yaml"],
        message: "chore(release): ${nextRelease.version} [skip ci]",
      },
    ],
    "@semantic-release/github", // Publishes to GitHub Releases
  ],
  changelogFile: "CHANGELOG.md",
  preset: "conventionalcommits",
};
