# Container: github-publisher

A container for publishing releases to GitHub.

This container bundles together the following tools:
* ghr
* git-chglog
* git-semver

A helper script, `create_release`, is included to perform an automated release.
Using the tools above, it generates a CHANGELOG, commits it to the repository,
and publishes release notes automatically to GitHub.

## Usage

Use github-publisher from GitHub Actions:

```yaml
jobs:
  release:
    runs-on: ubuntu-latest
    container: ghcr.io/stonesoupkitchen/github-publisher:latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Release
        env:
          GIT_USER: mybotuser
          GIT_EMAIL: mybotuser@email.com
          GITHUB_TOKEN: ${{ github.token }}
        run: create_release
```

## Configuration

Environment variables:

* **GIT_USER**: Username for the bot account that will update the CHANGELOG.
* **GIT_EMAIL**: Email for the bot account that will update the CHANGELOG.
* **GIT_CLIFF_CONFIG**: Path to git-cliff configuration file. Defaults to
  `/opt/ssk/git-cliff/cliff.toml`.
* **GITHUB_REPOSITORY**: String with format "<user>/<repo>". Automatically set
  by GitHub Actions. Required.
* **GITHUB_TOKEN**: Personal Access Token for pushing release notes.
  Automatically set by GitHub Actions. Required.
* **GITHUB_SHA**: The commit reference to tag. Automatically set by GitHub
  Actions. Defaults to "HEAD" if not defined.

## Development

Build the container with:

    make build

## License

See LICENSE.

