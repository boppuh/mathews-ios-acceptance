# Mathews acceptance contract

This repository contains the dedicated, deterministic iOS acceptance target for
the Mathews MVP release gate. Mathews must bind its repository configuration to
the exact files and values below. Any changed digest is a new contract version,
not an in-place edit to the active version.

The protected `pull_request_target` gate verifies `ACCEPTANCE_CONTRACT.sha256`
against the trust root stored on `main`. Pull-request code cannot update the
gate or its trust root alongside the files it changes.

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
| `MathewsAcceptance.xcworkspace/xcshareddata/xcschemes/MathewsAcceptance.xcscheme` | `9dd29a2894af4ec3843d1363a3ddacace1243f6602c1b397249eb0daea21232d` |
| `MathewsHarness.xcodeproj/project.pbxproj` | `bfaaa832bfb1072b7109711241c4721894226d218dae5e3affa982a0dab9d51d` |
| `MathewsAcceptanceUITests/GeneratedFixtures.swift` | `b3be66a520ea29648fe772cd3dbf67ffe592f37a51e5c025fc2fb64a666f1835` |
| `MathewsAcceptanceUITests/PrimaryJourneyTests.swift` | `0ee41273a1112f006cc54482b33b6429719b6981b7f83ed00dbe92540137da11` |
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
status. CI mints a non-sensitive, single-run account credential, resolves the
opaque account reference through macOS Keychain, and provisions the credential
with mode `0600` inside the freshly installed app's erased data container. The
deterministic POST is rejected unless the app resolves that credential, and the
UI test proves the authenticated account state. After the journey, CI queries
the simulator's unified log for the exact subsystem, `task` category, and
`task.completed` event. Fixture bytes are compiled into the otherwise
source-only harness; the protected gate proves that the generated source bytes
exactly match the authenticated repository fixtures. This preserves Mathews'
requirement that the harness resources phase is empty.
