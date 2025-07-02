module.exports = {
  branches: ["main"],
  plugins: [
    "@semantic-release/commit-analyzer", // Detects the release type (major, minor, patch)
    "@semantic-release/release-notes-generator", // Generates release notes
    "@semantic-release/changelog", // Updates CHANGELOG.md
    "@semantic-release/github", // Publishes to GitHub Releases
    "@semantic-release/git", // Commits CHANGELOG and bumps version if needed
  ],
  changelogFile: "CHANGELOG.md",
  preset: "conventionalcommits",
};
