# Trusted acceptance gate

`Trusted acceptance / pinned harness` runs with `pull_request_target`, so GitHub
loads its definition from the protected base branch rather than from the pull
request candidate. It checks out the exact untrusted head without credentials,
does not execute candidate code, authenticates the candidate manifest against
the repository-admin-controlled `MATHEWS_ACCEPTANCE_MANIFEST_SHA256` variable,
and then verifies every pinned harness and fixture file.

After this bootstrap PR merges, add `Trusted acceptance / pinned harness` to the
`main` ruleset's required status checks. The initial harness PR must then be
rebased or updated so the trusted base workflow runs against it. Keep the
existing `Acceptance / test` check required as the separate execution proof.

When intentionally promoting a new acceptance-contract version:

1. Review the exact harness and fixture diff.
2. Update `ACCEPTANCE_CONTRACT.sha256` on the candidate branch.
3. Set `MATHEWS_ACCEPTANCE_MANIFEST_SHA256` to the reviewed SHA-256 of that
   manifest through repository settings.
4. Require both the trusted pin check and `Acceptance / test` before merge.

Do not add secrets, write permissions, or candidate-script execution to the
`pull_request_target` workflow.
