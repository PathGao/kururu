## Summary

Describe the change and, for a fix, what was wrong. For a feature, explain why
it belongs in kururu and how it fits the [roadmap](../ROADMAP.md).

## Verification

List the checks you ran, your Mac and macOS version, and anything you could
not verify. For app changes, include the build, unit tests and self-checks:

```sh
./build.sh
"./build/stage/kururu.app/Contents/MacOS/kururu" --selftest
./build.sh --test
```

For user-facing text, check the affected languages and English fallback as
described in [Contributing](CONTRIBUTING.md).

## Refs

Use one `Refs #123` line per related issue. If this covers only part of an
issue, say which part. Include `Depends on #123` for a prerequisite PR.
