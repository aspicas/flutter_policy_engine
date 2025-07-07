module.exports = {
  branches: ["main"],
  plugins: [
    "@semantic-release/commit-analyzer", // Detects the release type (major, minor, patch)
    "@semantic-release/release-notes-generator", // Generates release notes
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
        message:
          "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}",
      },
    ],
    "@semantic-release/github", // Publishes to GitHub Releases
  ],
  changelogFile: "CHANGELOG.md",
  preset: "conventionalcommits",
};
