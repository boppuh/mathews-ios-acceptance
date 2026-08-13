# Trusted acceptance gate

`Trusted acceptance / pinned harness` runs with `pull_request_target`, so GitHub
loads its definition from the protected base branch rather than from the pull
request candidate. It checks out the exact untrusted head without credentials,
does not execute candidate code, authenticates the candidate manifest against
the trust root stored on the protected base branch, rejects files outside the
authenticated harness inventory, and then strictly verifies every checksum.

The job deploys to the `trusted-acceptance` environment. Configure that
environment to accept deployments only from protected branches, then require a
successful deployment to it in the `main` ruleset. This environment deployment,
not the job's visible status-check name, is the authoritative merge gate: a
candidate workflow can copy a job name, but it cannot deploy from an unprotected
pull-request ref. Keep `Acceptance / test` required as the separate execution
proof.

The `main` ruleset must also require branches to be up to date before merging.
That makes a trust-root change invalidate every open pull request until it is
updated and the protected workflow reruns against the new base commit.

When intentionally promoting a new acceptance-contract version:

1. Review the exact harness and fixture diff.
2. In a trust-root-only pull request, update
   `.github/trusted/acceptance-manifest.sha256` to the reviewed SHA-256 of the
   proposed manifest. Merge it after the existing acceptance gates pass.
3. Update the harness pull request with the reviewed files and
   `ACCEPTANCE_CONTRACT.sha256`, then bring it up to date with `main`.
4. Merge only after `Acceptance / test` passes and the protected workflow makes
   a successful `trusted-acceptance` deployment.

Do not add secrets, write permissions, or candidate-script execution to the
`pull_request_target` workflow.
