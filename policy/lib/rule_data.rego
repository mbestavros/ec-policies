package lib

import future.keywords.if

# Values in data.rule_data_custom or data.rule_data
# will take precedence over these defaults.
#
rule_data_defaults := {
	#
	# Used in release/attestation_type
	"known_attestation_types": ["https://in-toto.io/Statement/v0.1"],
	#
	# Used in release/slsa_provenance_available
	"allowed_predicate_types": ["https://slsa.dev/provenance/v0.2"],
	#
	# Used in release/slsa_build_build_service
	"allowed_builder_ids": ["https://tekton.dev/chains/v2"],
	#
	# Used in release/test.rego
	"supported_tests_results": [
		"SUCCESS",
		"FAILURE",
		"ERROR",
		"SKIPPED",
		"WARNING",
	],
	"failed_tests_results": ["FAILURE"],
	"erred_tests_results": ["ERROR"],
	"skipped_tests_results": ["SKIPPED"],
	"warned_tests_results": ["WARNING"],
	#
	# Used in release/cve.go
	# Valid levels: "critical", "high", "medium", "low", and "unknown"
	"restrict_cve_security_levels": ["critical", "high"],
	"warn_cve_security_levels": [],
	"restrict_unpatched_cve_security_levels": [],
	"warn_unpatched_cve_security_levels": ["critical", "high"],
	# Used in policy/release/slsa_source_correlated.rego
	# According to https://pip.pypa.io/en/latest/topics/vcs-support/#vcs-support
	# and https://spdx.dev/spdx-specification-20-web-version/#h.49x2ik5
	"supported_vcs": ["git", "hg", "bzr", "svn"],
	# Used in policy/release/slsa_source_correlated.rego
	# Supported digests in DigestSet of SLSA Provenance v1.0
	# See https://github.com/in-toto/attestation/blob/main/spec/v1/digest_set.md
	"supported_digests": [
		"sha256",
		"sha224",
		"sha384",
		"sha512",
		"sha512_224",
		"sha512_256",
		"sha3_224",
		"sha3_256",
		"sha3_384",
		"sha3_512",
		"shake128",
		"shake256",
		"blake2b",
		"blake2s",
		"ripemd160",
		"sm3",
		"gost",
		"sha1",
		"md5",
		"gitCommit",
		"gitTree",
		"gitBlob",
		"gitTag",
	],
}

# Returns the "first found" of the following:
#   data.rule_data__configuration__[key_name]
#   data.rule_data_custom[key_name]
#   data.rule_data[key_name]
#   rule_data_defaults[key_name]
#
# And falls back to an empty list if the key is not found anywhere.
#
rule_data(key_name) := value if {
	# Expected to be defined under `configuration.rule_data` in the
	# ECP configuration data being used when EC is run.
	time.parse_ns("2024-01-01T00:00:00Z", rule_data_effective_on(data.rule_data__configuration__)) < time.now_ns()
	value := data.rule_data__configuration__[key_name]
} else := value if {
	# Expected to be defined in a users custom data source accessed
	# via an oci bundle or (more likely) a git url.
	value := data.rule_data_custom[key_name] if {
		time.parse_ns("2024-01-01T00:00:00Z", rule_data_effective_on(data.rule_data_custom)) < time.now_ns()
	}
} else := value if {
	# Expected to be defined in a default data source accessed via
	# an oci bundle or a maybe a git url. See example/data/rule_data.yml.
	value := data.rule_data[key_name] if {
		time.parse_ns("2024-01-01T00:00:00Z", rule_data_effective_on(data.rule_data)) < time.now_ns()
	}
} else := value if {
	# Default values defined in this file. See above.
	value := rule_data_defaults[key_name] if {
		time.parse_ns("2024-01-01T00:00:00Z", rule_data_effective_on(rule_data_defaults)) < time.now_ns()
	}
} else := value if {
	# If the key is not found, default to an empty list
	value := []
}

rule_data_effective_on(rule_data) := value if {
	# Check for the effective_on key in the specified rule_data dictionary
	value := rule_data["effective_on"]
} else := value if {
	# If the key is not found, default to an empty list
	value := []
}
