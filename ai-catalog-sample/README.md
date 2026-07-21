# AI Catalog Sample — End-to-End AI Supply-Chain Governance Demo

Covers the AI-related capabilities of the JFrog Platform in a single script-driven
demo: pull a HuggingFace model through **AI Catalog (HF proxy)** → Xray scan →
sign & attach evidence → **AppTrust** application version → multi-stage promotion →
use a **Unified Policy** to block promotions that don't meet the ML governance bar.

This sample deliberately mirrors [../apptrust-sample](../apptrust-sample/) — same
script layout, same evidence + policy scaffolding — the only substantive change
is the *subject* moves from a Docker image to an ML model.

> References
> - AI Catalog: https://jfrog.com/help/r/jfrog-artifactory-documentation/huggingfaceml-repositories
> - AppTrust: https://jfrog.com/help/r/jfrog-platform-administration-documentation/apptrust
> - Unified Policy (Rego + Template/Rule/Policy): `/unifiedpolicy/api/v1/`

---

## One-line elevator pitch

> "Nobody wants unaudited models from huggingface.co landing in production.
> With JFrog: proxy the pull, attach signed **model card**, **Xray ML scan**,
> and **red-team assessment** evidence to every version, and one policy
> blocks any model that lacks those three from reaching PROD. Same model,
> same version — evidence present → release; evidence missing → blocked."

---

## Directory layout

```
ai-catalog-sample/
├── evidence/                                    # 4 predicate templates
│   ├── model-card.json                          # Model card (governance/license/intended-use)
│   ├── xray-model-scan.json                     # Xray ML scan (pickle/CVE/license)
│   ├── red-team.json                            # OWASP-LLM + MITRE ATLAS red-team report
│   └── deployment-approval.json                 # PROD deployment sign-off
├── policy/
│   └── require-model-card-and-red-team.rego     # Unified Policy Rego logic
├── scripts/
│   ├── config.sh                                # Central config (override every value via env vars)
│   ├── 00-init.sh                               # ping + HF repos + app + signing key
│   ├── 01-pull-model.sh                         # pull distilbert through AI Catalog proxy
│   ├── 02-upload-and-scan.sh                    # upload + build-info + Xray build-scan
│   ├── 03-create-version.sh                    # AppTrust version-create from build
│   ├── 04-attach-evidence.sh                    # attach 3 signed evidence records
│   ├── 05-promote.sh                            # DEV → QA
│   ├── 06-approve-and-release.sh                # approval evidence → PROD release
│   ├── 07-create-policy.sh                      # Template + Rule + Policy (block PROD)
│   ├── 08-test-block.sh                         # end-to-end block-then-unblock verification
│   ├── 99-cleanup.sh                            # delete versions (optionally delete app)
│   └── run-all.sh                               # runs 00–06 in order (happy path)
└── README.md
```

---

## Prerequisites

| Item | Notes |
|---|---|
| `jf` CLI ≥ 2.100 | Needs both `jf apptrust` and `jf evd` |
| Python 3 | `01-pull-model.sh` sets up a local venv and installs `huggingface_hub` |
| `curl` + `jq` | REST calls and JSON parsing |
| **JFrog platform** must have AppTrust + Xray + Unified Policy enabled (demo tenant does) |
| **JFrog Project** | `alex` (default; override with `JF_PROJECT`) |
| **HF Remote Repo** | `alex-huggingfaceml-remote → https://hf-mirror.com` (fastest in Asia) |
| **HF Local Repos** | `alex-huggingfaceml-{dev,qa,prod}-local` (created automatically by 00-init if missing) |

---

## Quickstart

### 1. Point CLI at the AppTrust-enabled server
```bash
jf c use demo   # or export JF_SERVER_ID=demo
```

### 2. Run the happy path (~3 minutes)
```bash
cd ai-catalog-sample
./scripts/run-all.sh
```

### 3. Create the blocking policy and prove it fires
```bash
./scripts/07-create-policy.sh   # creates template + rule + policy (mode=block)
./scripts/08-test-block.sh      # new version without required evidence → blocked;
                                # add evidence → policy evaluates to pass
```

`08-test-block.sh` prints something like:
```
✓ Release BLOCKED as expected. Reason:
  "message":"Releasing version using keep failed due to policy violations"
  "decision":"fail"
  "explanation":"Release policy failed due to violated policies:
     [alex-ml-classifier-prod-release-gate]"
```

---

## Evidence types and predicate URIs

| Evidence | Predicate Type | Produced when | Signed by |
|---|---|---|---|
| Model Card | `https://jfrog.com/evidence/model-card/v1` | Governance review passes | ML Governance Lead |
| Xray ML Scan | `https://jfrog.com/evidence/ml-security-scan/v1` | Xray scan finishes | Security CI |
| Red-Team | `https://jfrog.com/evidence/red-team/v1` | Adversarial testing completes | Security team |
| Deployment Approval | `https://jfrog.com/evidence/approval/v1` | Manual PROD sign-off | AI Product Owner |

All records are signed by the same ECDSA P-256 key. `jf evd verify-evidence`
can verify against the platform's Trusted Keys offline.

---

## How the policy works

The Unified Policy Service is a three-layer model — **Template → Rule → Policy**:

- **Template** — Rego source + input schema declaration (`data_source_type: evidence`)
- **Rule** — an instance of a template, optionally parameterized (this demo passes no parameters)
- **Policy** — binds one or more rules to `{application, stage, gate, mode}`

The policy created by `07-create-policy.sh`:
- `scope.type = application`, `scope.application_keys = [alex-ml-classifier]`
- `action.type = certify_to_gate`
- `action.stage = { gate: release, key: PROD }` (evaluated at PROD's release gate)
- `mode = block` (violations reject the release)
- Rule logic: the version must have BOTH `model-card/v1` and `red-team/v1` predicates attached

---

## Diff vs. apptrust-sample

| Dimension | apptrust-sample | ai-catalog-sample |
|---|---|---|
| Subject | Node.js Docker image | HuggingFace model |
| Source type | `--source-type-builds` from `docker push` build | Same, but the build's artifacts are model files |
| Evidence types | SLSA / test / security-scan / approval | model-card / ML scan / red-team / approval |
| Policy focus | Security-scan evidence present? | Model-card AND red-team evidence present? |
| Policy gate | DEV entry_gate | PROD release_gate |

Both samples share the same evidence signing flow, AppTrust CLI usage, and
Unified Policy REST structure.

---

## Where things live in the UI

- Application version: **Application → alex-ml-classifier → 1.0.0**
- Model files: **Repositories → alex-huggingfaceml-{dev,qa,prod}-local**
- Evidence: **Application Version → Evidence tab**
- Policies: **Administration → Unified Policy → Policies** (`alex-ml-classifier-prod-release-gate`)

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `--project flag is not allowed` on `evd create` | Project is auto-inferred when `--application-key` is used | Drop `--project` |
| `promotion to release stage 'PROD' is not allowed` | PROD is a release stage | Use `version-release` instead of `version-promote` |
| `Build not found ... repository: artifactory-build-info` | The build lives in a project-scoped build-info repo, not the global one | Pass `repo-key=<project>-build-info` |
| `huggingface-cli: command not found` | huggingface_hub 1.0+ renamed the binary to `hf` | Script auto-falls back to `hf`; manually upgrade if needed |
| `Client error '404 Not Found' ... /api/models/...` | JFrog HF proxy validates `User-Agent`; curl's default UA is rejected | Use the `hf` CLI (correct UA baked in) or set `-H "User-Agent: huggingface_hub"` |
| HF proxy cannot fetch the model | The remote points at `huggingface.co`, which is unreachable from the demo tenant | Point the remote URL at `https://hf-mirror.com` |
| `Forbidden to copy/move artifacts from/to Release Bundles repository` | The internal `<project>-application-versions` repo is a Release-Bundle-typed store that rejects normal copy; heavy HF-model artifacts trigger this on promotion | Use `--promotion-type keep --include-repos <target>`; ensure the model is already in the DEV repo before promoting |
| `The first promotion cannot be 'no-op'` | Platform rule: a version's first promotion cannot be `keep` | Either ensure the files already exist in the target repo, or use `copy` (subject to the release-bundle-source restriction above) |
| Xray scan reports no findings | distilbert is a safe model | Swap in a known pickle-vulnerable model to make the contrast |
| `Build ... is not selected for indexing` | Xray hasn't been told to index this build | UI → Administration → Xray → Watches, add the build to a watch |
