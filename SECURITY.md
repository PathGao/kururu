# Security Policy

Thanks for helping keep kururu and the people who use it safe.

## Reporting a vulnerability

Please report security vulnerabilities in private. Do not open a public issue, pull request or discussion for them.

Private vulnerability reporting is not currently enabled for this repository.
There is no dedicated security email published here. Until a private channel
is available, do not post vulnerability details in public issues. You can ask
for a private reporting channel without including the vulnerability itself.
This page will link to that channel once it is configured.

When you write it up, please include as much as you can.

- A description of the issue and the impact it could have.
- Steps to reproduce, or a proof of concept.
- The kururu version from Settings under About and your macOS version.

## What to expect

- This is a community project looked after on a best effort basis, so please allow reasonable time for a reply and a fix.
- Please give the maintainer a chance to ship a fix before you talk about the issue in public. That is what coordinated disclosure means.
- Credit goes gladly to reporters who want it.

## Supported versions

Security fixes land on the latest released version. Before you report, please make sure you can reproduce the issue on the most recent release.

## Scope

kururu runs locally. The current release is locally signed and has not been notarized by Apple; self-updates are disabled pending kururu’s own release configuration. The reports that matter most are the ones that could affect the integrity of the app or that could let the app's permissions be misused. Issues in the outside services the app merely talks to, like GitHub's releases API or the speed test endpoint, are best taken to those providers.
