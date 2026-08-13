# Mathews acceptance contract

This repository contains the dedicated, deterministic iOS acceptance target for
the Mathews MVP release gate. Mathews must bind its repository configuration to
the exact files and values below. Any changed digest is a new contract version,
not an in-place edit to the active version.

CI first verifies `ACCEPTANCE_CONTRACT.sha256` against the protected repository
variable `MATHEWS_ACCEPTANCE_MANIFEST_SHA256`. Pull-request code cannot update
that trust root alongside the files it changes.

## Pinned execution

- Workspace: `MathewsAcceptance.xcworkspace`
- Scheme: `MathewsAcceptance`
- Harness project: `MathewsHarness.xcodeproj`
- Harness target ID: `A11CE0000000000000000001`
- Runner: `MathewsAcceptanceUITests/PrimaryJourneyTests/testPrimaryJourney`
- App bundle: `com.mathewstechnologies.mathews-ios-acceptance`
- Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-26-2`
- Device: `com.apple.CoreSimulator.SimDeviceType.iPhone-17`
- Locale and time zone: `en_US_POSIX`, `UTC`
- Test account: `keychain://com.boppuh.mathews.test/primary-account`

The simulator E2E operation is exactly:

```text
xcodebuild test -workspace MathewsAcceptance.xcworkspace -scheme MathewsAcceptance -destination MATHEWS_CONFIGURED_SIMULATOR -only-testing:MathewsAcceptanceUITests/PrimaryJourneyTests/testPrimaryJourney
```

Before every run, the host must shut down, erase, boot, and install the exact
candidate app. The workflow performs the same sequence and retains the xcresult
for seven days.

## Pinned files

| Path | SHA-256 |
| --- | --- |
| `MathewsAcceptance.xcworkspace/contents.xcworkspacedata` | `4e0583096ca6fd40aa32aa1492c5fb82b3c5a4dcd80474df2e28ff9322dfcefd` |
| `MathewsAcceptance.xcworkspace/xcshareddata/xcschemes/MathewsAcceptance.xcscheme` | `6acb5b3e0d33fd1ce9461163b5c68bcaf13435a5b6cc3ea54019efd5804076c2` |
| `MathewsHarness.xcodeproj/project.pbxproj` | `cf2975e9955ad1d9be187c0b59ab8045ae529f9a6145596341a499e2de008c18` |
| `MathewsAcceptanceUITests/PrimaryJourneyTests.swift` | `5cb35850b039145f5c61e168ca067c77c5a251afc6d837f91bf773fd4da0925b` |
| `Fixtures/primary.json` | `c799658e413345b176cabf11b6206774efd3b3b9d140b0823d06ea7af545b36d` |
| `Fixtures/primary-account.json` | `faceb89ac7da966aa5be1c5ab05616fd7523e435e22c38bde8260d3790d65acc` |

Configure the fixture as `primary_fixture` version 1 and the account recipe as
`primary_account` version 1 with the corresponding `sha256:`-prefixed digests.

## Assertion signals

The required baseline assertion catalog covers every bounded verifier kind:

| Assertion ID | Kind | Catalog key | Verifier signal |
| --- | --- | --- | --- |
| `task_title` | `ELEMENT_VALUE_PRESENT` | `task.title` | Accessibility ID `task.title`; fixture key `task.title` |
| `terminal_state` | `NAVIGATION_STATE_REACHED` | `task.completed` | State and accessibility ID `task.completed` |
| `network_response` | `EXPECTED_NETWORK_RESPONSE` | `task.created.response` | Endpoint class `task.created`, `POST`, status `201` |
| `log_event` | `EXPECTED_LOG_EVENT` | `task.completed.log` | App subsystem, category `task`, event `task.completed` |
| `no_crash` | `NO_CRASH` | `app.process` | Acceptance app bundle remains foreground-running |

The same catalog should include task-selectable element, navigation, and no-crash
assertions for accepted briefs. Mathews must prohibit task mutation of both
fixture files, the complete `MathewsAcceptanceUITests` source root, the workspace
control files, and `MathewsHarness.xcodeproj/project.pbxproj`.

The acceptance app uses a deterministic `URLProtocol` recorder and emits the
response accessibility signal only after observing the configured POST and 201
status. CI resolves the opaque account reference through macOS Keychain and
provisions it with mode `0600` inside the freshly installed app's erased data
container; the deterministic POST is rejected unless the app resolves that
credential, and the UI test proves the authenticated account state. After the journey, CI queries the
simulator's unified log for the exact subsystem, `task` category, and
`task.completed` event. Fixture bytes are compiled into the otherwise source-only
harness and checked against the repository fixture digests before decoding;
this preserves Mathews' requirement that the harness resources phase is empty.
