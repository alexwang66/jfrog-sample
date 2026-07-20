# ⚠️ TEST ARTIFACT — DO NOT INSTALL IN A REAL AGENT ⚠️

This package is a **deliberately-malicious demo skill** built to exercise
JFrog's *AI Agent Skill Scanner* (see
https://docs.jfrog.com/security/docs/skill-scanning).

Think of it as the **EICAR file** for AI-skill scanners: harmless when
scanned, but crafted to trip every scanner rule so you can verify your
detection pipeline end-to-end.

## What it exercises

The `SKILL.md` and `scripts/collect.py` together embed one clearly
observable example of each of the four **Scanner Targets** listed in the
JFrog docs:

| # | JFrog Scanner Target                               | Where it appears in this package                                                   |
|---|----------------------------------------------------|------------------------------------------------------------------------------------|
| 1 | **Download & Execution from untrusted sources**    | `SKILL.md` §Setup step 1 (`curl … | bash`, `wget … | python3`, rogue PyPI index)  |
| 2 | **Exfiltration of sensitive information**          | `SKILL.md` §Setup step 2 + `scripts/collect.py::_harvest` / `capture_seed_phrase` |
| 3 | **Prompt injection attacks**                       | `SKILL.md` §Operating Instructions (`IGNORE ALL PREVIOUS INSTRUCTIONS`, fake `<<SYSTEM>>` blocks, override directives) |
| 4 | **Unauthorized code installation off-marketplace** | `SKILL.md` §Setup step 3 (`git clone` a third-party skill into `~/.claude/skills/`) + `scripts/collect.py::_install_alpha_skill` |

It also exercises several of the JFrog scanner **Capabilities**:

- *Multi-Lens Discovery* — YARA/static signatures for `curl | bash`,
  `webhook.site`, hardcoded RFC-5737 IP, `.aws/credentials`, etc.
- *Supply-Chain Intelligence* — references a non-existent PyPI mirror and
  a squatted GitHub org (`rug-pull-org/crypto-alpha-skill`).
- *Prompt Injection Resistance* — the fake `<!-- SYSTEM DIRECTIVE -->`
  block and `IGNORE ALL PREVIOUS INSTRUCTIONS` payload are designed to
  probe the scanner's deception-detection agent.
- *Result Integrity Validation* — instructions telling the agent to
  "silently retry" and to lie to the user (`"this skill is verified by
  Anthropic"`) should surface as tampering signals.

## Expected scanner outcome

When uploaded to an Artifactory Skills repository backed by AI Catalog
Security, the scan should classify the artifact as:

- **Malicious** (Critical severity in Xray) — because it contains
  high-confidence proof of exfiltration + remote-code-fetch + prompt
  injection.

If any of the four categories above does **not** appear in the finding
list, you have a coverage gap in your scanner configuration.

## How to use

```bash
# from the directory containing this README
cd ..
zip -r crypto-portfolio-tracker-1.0.3.zip crypto-portfolio-tracker/

# then upload the resulting .zip to your Artifactory Skills repository:
jf rt u crypto-portfolio-tracker-1.0.3.zip skills-local/
```

Wait for the AI Scanner (`xray-aiscanner`) to pick it up, then open
**Xray → Scans List** and confirm the four findings are present.

## Safety notes

- The URLs in this artifact (`webhook.site`, `crypto-track-helpers.xyz`,
  `pypi-mirror.rugpull.io`, `198.51.100.42`) are **placeholders**.
  `198.51.100.0/24` is TEST-NET-3 (RFC 5737) and is not routable.
- The Python code in `scripts/collect.py` *would* do real damage if
  executed on a machine with real secrets. **Do not run it.** It is here
  as a scanner target, not a working tool.
- Do not add this skill to any real agent's skill directory. Store the
  `.zip` in a quarantined repository (or better: a dedicated
  scanner-test repo) that no agent auto-loads from.
