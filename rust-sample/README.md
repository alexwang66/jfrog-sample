# Rust (Cargo) Project with JFrog Artifactory Integration

This sample shows how to build a Rust crate and publish / deploy it to a
JFrog Artifactory **Cargo** repository, then verify it with the JFrog CLI.

## Prerequisites

1. Rust toolchain (`cargo` 1.68+ for the sparse index; sample built with 1.96)
2. JFrog CLI (`jf`) installed and a server configured (`jf config show`)
3. A Cargo repository on Artifactory (this sample uses `alex-cargo-local` on
   the `demo` server — `https://demo.jfrogchina.com`)

## Project structure

```
rust-sample/
├── Cargo.toml
├── Cargo.lock
├── src/
│   └── lib.rs
├── .cargo/
│   ├── config.toml              # registry pointing at the Artifactory Cargo repo
│   └── credentials.toml.example # token template (copy to ~/.cargo/credentials.toml)
├── deploy.sh                    # build + jf CLI deploy + verify
└── README.md
```

## 1. Create the Cargo repositories (one-time, on Artifactory)

```bash
# Local (host your own crates)
jf rt curl -XPUT /api/repositories/alex-cargo-local  -H "Content-Type: application/json" \
  -d '{"rclass":"local","packageType":"cargo","repoLayoutRef":"cargo-default"}' --server-id demo

# Remote (proxy crates.io — recommended to also create) and Virtual (aggregate) as needed.
```

## 2A. Deploy with the JFrog CLI (`jf rt upload`) — verification path

Fastest way to get a `.crate` into the repo and verify with `jf`:

```bash
./deploy.sh              # uses JF_SERVER_ID=demo, REPO=alex-cargo-local by default
# or: JF_SERVER_ID=demo REPO=alex-cargo-local ./deploy.sh
```

It runs `cargo package`, `jf rt upload` (tagging `cargo.name` / `cargo.version`
properties), then an AQL query to confirm the artifact is present.

> This deploys and stores the crate (verifiable via `jf`), which is what the
> WEEX POC verification used. It does **not** by itself register the crate in
> the Cargo sparse index — for developer-facing `cargo add` / `cargo build`,
> publish through the registry API (2B).

## 2B. Publish with `cargo publish` — developer path (index-registered)

For a crate that `cargo` can actually resolve, publish through the Artifactory
Cargo registry:

```bash
cp .cargo/credentials.toml.example ~/.cargo/credentials.toml
#   then edit ~/.cargo/credentials.toml and paste a real "Bearer <token>"
cargo publish --registry artifactory --allow-dirty --no-verify
```

`.cargo/config.toml` in this project already points the `artifactory` registry
at the repo's sparse index and enables the `cargo:token` credential provider
(required by newer Cargo for authenticated registries).

> **Known issue observed on this POC (Artifactory 7.146.17):** `cargo publish`
> authenticates but the publish `PUT` returns **HTTP 415 Unsupported Media
> Type**. If you hit this: try the **git** index instead of `sparse+`, confirm
> the repo's *Enable Sparse Index* setting, check Cargo/Artifactory version
> compatibility, and open a JFrog support ticket if it persists. Until then,
> use path 2A for verification.

## 3. Verify

```bash
# List what's in the repo
jf rt curl -s -XPOST /api/search/aql -H "Content-Type: text/plain" \
  -d 'items.find({"repo":"alex-cargo-local"}).include("path","name")' --server-id demo | jq

# Resolve as a dependency (only works once 2B / the index is populated)
#   [dependencies]
#   samplecode = { version = "0.1.0", registry = "artifactory" }
```

## Vulnerable dependency (Xray / Curation demo)

`Cargo.toml` pins an intentionally vulnerable crate so scans reliably surface a
**HIGH** finding:

| Crate | Advisory | CVE | Severity |
|-------|----------|-----|----------|
| `smallvec = "=1.6.0"` | RUSTSEC-2021-0003 | CVE-2021-25900 | Buffer overflow — **CRITICAL 9.8** (RustSec) / **HIGH 7.5** (NVD CVSS 3.1); fixed in 1.6.1 |

Verify (run in this directory):

```bash
cargo audit          # RustSec — flags smallvec 1.6.0 / RUSTSEC-2021-0003 (9.8 critical)
```

To show the "fixed" path, bump to `smallvec = "1.6.1"` and re-run — the finding disappears.

> **JFrog CLI note:** `jf audit` in CLI 2.103 does **not** support Cargo/Rust SCA
> (only `--go/--mvn/--npm/--pnpm/...`), so it reports *"couldn't determine a
> package manager"* on a Rust project. For a JFrog-native Rust scan, confirm a
> CLI/Xray version with Cargo support, or scan server-side via build-info/Xray.
> Separately, in a memory-constrained shell the JAS scanners (Secrets/SAST/IaC)
> may be OOM-killed (`signal: killed`) — run on a machine with adequate RAM, or
> pass `--sca` to skip JAS.

## Security notes

- **Never commit real tokens.** `~/.cargo/credentials.toml` stays out of the
  repo; only `credentials.toml.example` (placeholder) is tracked.
- `deploy.sh` takes credentials from your `jf config` / environment, not from
  the file.
