package curation.policies
import rego.v1

# ------------------------------------------------------------------------------
# AI-Catalog demo policy: an ML model version cannot promote past QA -> PROD
# unless BOTH of these evidence records are attached:
#   1. Model Card (predicateType: https://jfrog.com/evidence/model-card/v1)
#   2. Red-team assessment (predicateType: https://jfrog.com/evidence/red-team/v1)
#
# Rationale: technical scans (Xray) prove *what* is inside the model;
# model-card + red-team prove *how* it should be used and that it has been
# adversarially tested — the two ML governance gates security teams care about.
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

required_types := {
    "https://jfrog.com/evidence/model-card/v1",
    "https://jfrog.com/evidence/red-team/v1",
}

# Set of predicateTypes actually present on this version.
present_types contains t if {
    some e in all_evidence
    t := e.node.predicateType
}

missing := required_types - present_types

default should_allow := false
should_allow if { count(missing) == 0 }

default message := "OK: model-card + red-team evidence present"
message := sprintf("BLOCKED: missing required evidence types: %v", [missing]) if {
    not should_allow
}

allow := {"should_allow": should_allow, "message": message}
