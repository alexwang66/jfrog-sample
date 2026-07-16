package curation.policies
import rego.v1

# ------------------------------------------------------------------------------
# Rego for AppTrust Lifecycle Policy: "require security-scan evidence".
# Evaluated by the JFrog Unified Policy Service at promotion gates.
#
# Input shape (partial):
#   input.data.evidenceConnection.edges[*].node           # version-level evidence
#   input.data.artifactsConnection.edges[*].node.evidenceConnection.edges[*].node
#   input.data.fromBuilds[*].evidenceConnection.edges[*].node
# Each evidence node has fields: predicateType, predicateSlug, predicate, ...
#
# Output contract:
#   allow.should_allow (bool)
#   allow.message      (string)
# ------------------------------------------------------------------------------

release := input.data

release_evidence := [e | some e in object.get(release, "evidenceConnection", {"edges": []}).edges]

artifact_evidence := [ev |
    some a in object.get(release, "artifactsConnection", {"edges": []}).edges
    some ev in object.get(object.get(a, "node", {}), "evidenceConnection", {"edges": []}).edges
]

build_evidence := [ev |
    some b in object.get(release, "fromBuilds", [])
    some ev in object.get(b, "evidenceConnection", {"edges": []}).edges
]

all_evidence := array.concat(release_evidence, array.concat(artifact_evidence, build_evidence))

required_type := "https://jfrog.com/evidence/security-scan/v1"

default should_allow := false

should_allow if {
    some e in all_evidence
    e.node.predicateType == required_type
}

default message := "OK: required security-scan evidence found"
message := "BLOCKED: no evidence of predicate-type https://jfrog.com/evidence/security-scan/v1 attached to this version" if {
    not should_allow
}

allow := {"should_allow": should_allow, "message": message}
