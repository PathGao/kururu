# Backend responsibilities

The backend runs inside the macOS app. Existing services remain compiled into
the application; disabling a feature stops its work, but does not unload code
or provide process isolation.

## Lifecycle and task ownership

`FeatureRuntime` registers each resource owner with `FeatureLifecycle`, including
its feature members, permission dependencies, synchronization and termination
hooks. Shared capture and monitoring resources are registered with their owners
so a preference change synchronizes each registration once. Business behavior
remains in the individual services.

Environment inspection and Homebrew environment snapshots propagate cancellation
to bounded subprocesses. Generation checks reject stale results. Snapshot
completion settles once, including when cancellation races with a queued result.
These read-only tasks remain separate from user-initiated package mutations.

## Presentation, execution and storage

- `CommandBarPresentation` owns the panel, focus and input monitors.
- `CommandBarService` retains discovery, search and ranking.
- `CommandBarExecutor` captures action input and guards asynchronous destination
  results against a replaced or dismissed presentation.
- `ShelfImportStore` owns staged imports, security-scoped access, reference
  validation and transaction disposal. `ShelfService` retains live revisions
  and publication. Existing atomic persistence and rollback remain in use.

These boundaries allow execution and storage contracts to be tested without
constructing the entire user interface. They are not an external plugin API.
Views still access some singletons and preferences directly; the repository has
not completed a uniform dependency-injection migration.

## Display brightness

Display state distinguishes observed brightness, requested brightness,
confirmation status and failure. Accepted writes are read back before being
confirmed. Identity, route and request-version checks prevent stale results from
updating a replacement display or a newer request.

Built-in displays use the existing system brightness interface. External DDC
displays use serialized, paced requests with bounded retries and strict response
validation. A NULL reply carries no brightness, even if trailing buffer bytes
resemble an earlier value. Read failures must not create a measured midpoint.

Each GET attempt sends the request twice, with 10 ms before each write and
50 ms before reading. This matches the default repeat count in
[MonitorControl](https://github.com/MonitorControl/MonitorControl/blob/5ce1a252ad1bde8248d8e4bb69645b28ca4da3e5/MonitorControl/Support/Arm64DDC.swift#L96-L118)
and [m1ddc](https://github.com/waydabber/m1ddc/blob/04d949794102eb8df01ad3681afff6464a3eede2/sources/i2c.m).
On the tested Mi Monitor, a single request consistently returned NULL while two
returned a valid luminance response. The firmware's internal reason is unknown.

Panel and settings controls share the same state. Visible views request periodic
refresh; in-flight work prevents overlapping refresh. The retired page-level
brightness gate is consumed during preference and backup migration, preserving
previously disabled configurations.

## Verification and limits

The September 2026 local validation covered lifecycle ownership, process
cancellation, exactly-once completion, command execution, shelf import and
brightness response/state contracts. Full application builds and storage
selftests passed. Hardware checks on the current Mi Monitor connection produced
100 valid reads at 80/100 and 40 matching readbacks after alternating targets
79/80/81/80, then restored 80. A separate 30-sample interval run passed; another
run recorded one rejected checksum failure out of 30, with cause undetermined.
Application controls and built-in brightness adjustment/restoration were also
checked directly.

This does not establish compatibility with every display, adapter, sleep/wake
sequence or multi-display topology. CPU, memory and energy improvements have not
been measured under controlled before/after conditions. Audio, capture,
monitoring and input-distribution engines retain their existing architecture;
further restructuring should follow concrete failures or measured bottlenecks.
