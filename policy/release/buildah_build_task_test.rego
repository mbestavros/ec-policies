package policy.release.buildah_build_task_test

import rego.v1

import data.lib
import data.lib.tkn_test
import data.policy.release.buildah_build_task

test_good_dockerfile_param if {
	attestation := _attestation("buildah", {"parameters": {"DOCKERFILE": "./Dockerfile"}}, _results)
	lib.assert_empty(buildah_build_task.deny) with input.attestations as [attestation]
	slsav1_attestation := _slsav1_attestation("buildah", [{"name": "DOCKERFILE", "value": "./Dockerfile"}], _results)
	lib.assert_empty(buildah_build_task.deny) with input.attestations as [slsav1_attestation]
}

# regal ignore:rule-length
test_buildah_tasks if {
	tasks := [
		{
			"name": "pipelineTask",
			"content": base64.encode(json.marshal(tkn_test.slsav1_attestation_local_spec)),
		},
		{
			"name": "pipelineTask",
			"content": base64.encode(json.marshal(tkn_test.slsav1_attestation_local_spec)),
		},
	]
	slsav1_attestation := json.patch(
		_slsav1_attestation(
			"buildah", [{
				"name": "DOCKERFILE",
				"value": "./Dockerfile",
			}],
			_results,
		),
		[{
			"op": "add",
			"path": "/statement/predicate/buildDefinition/resolvedDependencies",
			"value": tasks,
		}],
	)

	expected := {{
		"params": [
			{"name": "IMAGE", "value": "quay.io/jstuart/hacbs-docker-build"},
			{"name": "DOCKERFILE", "value": "./image_with_labels/Dockerfile"},
		],
		"podTemplate": {
			"imagePullSecrets": [{"name": "docker-chains"}],
			"securityContext": {"fsGroup": 65532},
		},
		"results": _results,
		"serviceAccountName": "default", "taskRef": {
			"kind": "Task",
			"name": "buildah",
		},
		"timeout": "1h0m0s", "workspaces": [
			{"name": "source", "persistentVolumeClaim": {"claimName": "pvc-bf2ed289ae"}},
			{"name": "dockerconfig", "secret": {"secretName": "docker-credentials"}},
		],
	}}
	lib.assert_equal(expected, buildah_build_task._buildah_tasks) with input.attestations as [slsav1_attestation]
}

test_dockerfile_param_https_source if {
	expected := {{
		"code": "buildah_build_task.buildah_uses_local_dockerfile",
		"msg": "DOCKERFILE param value (https://Dockerfile) is an external source",
	}}

	# attestation := _attestation("buildah", {"parameters": {"DOCKERFILE": "https://Dockerfile"}}, _results)
	# lib.assert_equal_results(expected, buildah_build_task.deny) with input.attestations as [attestation]

	slsav1_attestation := _slsav1_attestation("buildah", [{"name": "DOCKERFILE", "value": "https://Dockerfile"}], _results)
	lib.assert_equal_results(expected, buildah_build_task.deny) with input.attestations as [slsav1_attestation]
}

test_dockerfile_param_http_source if {
	expected := {{
		"code": "buildah_build_task.buildah_uses_local_dockerfile",
		"msg": "DOCKERFILE param value (http://Dockerfile) is an external source",
	}}
	attestation := _attestation("buildah", {"parameters": {"DOCKERFILE": "http://Dockerfile"}}, _results)
	lib.assert_equal_results(expected, buildah_build_task.deny) with input.attestations as [attestation]

	slsav1_attestation := _slsav1_attestation("buildah", [{"name": "DOCKERFILE", "value": "http://Dockerfile"}], _results)
	lib.assert_equal_results(expected, buildah_build_task.deny) with input.attestations as [slsav1_attestation]
}

test_task_not_named_buildah if {
	lib.assert_empty(buildah_build_task.deny) with input.attestations as [_attestation("java", [{}], _results)]
}

test_missing_pipeline_run_attestations if {
	attestation := {"statement": {"predicate": {"buildType": "something/else"}}}
	lib.assert_empty(buildah_build_task.deny) with input.attestations as [attestation]

	slsav1_attestation := {"statement": {"predicate": {"buildDefinition": {"buildType": "something/else"}}}}
	lib.assert_empty(buildah_build_task.deny) with input.attestations as [slsav1_attestation]
}

# regal ignore:rule-length
test_multiple_buildah_tasks if {
	attestation := {"statement": {"predicate": {
		"buildType": lib.tekton_pipeline_run,
		"buildConfig": {"tasks": [
			{
				"name": "b1",
				"ref": {"kind": "Task", "name": "buildah", "bundle": _bundle},
				"invocation": {"parameters": {"DOCKERFILE": "one/Dockerfile"}},
			},
			{
				"name": "b2",
				"ref": {"kind": "Task", "name": "buildah", "bundle": _bundle},
				"invocation": {"parameters": {"DOCKERFILE": "two/Dockerfile"}},
			},
		]},
	}}}
	lib.assert_empty(buildah_build_task.deny) with input.attestations as [attestation]

	tasks := [
		{
			"name": "task",
			"content": base64.encode(json.marshal(json.patch(tkn_test.slsav1_attestation_local_spec, [{
				"op": "add",
				"path": "/taskRef/name",
				"value": "task1",
			}]))),
		},
		{
			"name": "pipelineTask",
			"content": base64.encode(json.marshal(json.patch(tkn_test.slsav1_attestation_local_spec, [{
				"op": "add",
				"path": "/taskRef/name",
				"value": "task1",
			}]))),
		},
		{
			"name": "pipeline",
			"content": base64.encode(json.marshal(json.patch(tkn_test.slsav1_attestation_local_spec, [{
				"op": "add",
				"path": "/taskRef/name",
				"value": "task1",
			}]))),
		},
	]
	slsav1_attestation := json.patch(_slsav1_attestation("buildah", [{}], _results), [{
		"op": "add",
		"path": "/statement/predicate/buildDefinition/resolvedDependencies",
		"value": tasks,
	}])
	lib.assert_empty(buildah_build_task.deny) with input.attestations as [slsav1_attestation]
}

# regal ignore:rule-length
test_multiple_buildah_tasks_one_with_external_dockerfile if {
	attestation := {"statement": {"predicate": {
		"buildType": lib.tekton_pipeline_run,
		"buildConfig": {"tasks": [
			{
				"name": "b1",
				"ref": {"kind": "Task", "name": "buildah", "bundle": _bundle},
				"invocation": {"parameters": {"DOCKERFILE": "one/Dockerfile"}},
				"results": _results,
			},
			{
				"name": "b2",
				"invocation": {"parameters": {"DOCKERFILE": "http://Dockerfile"}},
				"ref": {"kind": "Task", "name": "buildah", "bundle": _bundle},
				"results": _results,
			},
		]},
	}}}
	expected := {{
		"code": "buildah_build_task.buildah_uses_local_dockerfile",
		"msg": "DOCKERFILE param value (http://Dockerfile) is an external source",
	}}
	lib.assert_equal_results(expected, buildah_build_task.deny) with input.attestations as [attestation]

	tasks := [
		{
			"name": "task",
			"content": base64.encode(json.marshal(json.patch(tkn_test.slsav1_attestation_local_spec, [{
				"op": "add",
				"path": "params",
				"value": [{"name": "DOCKERFILE", "value": "Dockerfile"}],
			}]))),
		},
		{
			"name": "pipelineTask",
			"content": base64.encode(json.marshal(json.patch(tkn_test.slsav1_attestation_local_spec, [{
				"op": "add",
				"path": "/params",
				"value": [{"name": "DOCKERFILE", "value": "http://Dockerfile"}],
			}]))),
		},
	]
	slsav1_attestation := json.patch(_slsav1_attestation("buildah", {}, _results), [{
		"op": "add",
		"path": "/statement/predicate/buildDefinition/resolvedDependencies",
		"value": tasks,
	}])

	lib.assert_equal_results(expected, buildah_build_task.deny) with input.attestations as [slsav1_attestation]
}

_attestation(task_name, params, results) := {"statement": {"predicate": {
	"buildType": lib.tekton_pipeline_run,
	"buildConfig": {"tasks": [{
		"name": task_name,
		"ref": {"kind": "Task", "name": task_name, "bundle": _bundle},
		"invocation": params,
		"results": results,
	}]},
}}}

_slsav1_attestation(task_name, params, results) := attestation if {
	content := base64.encode(json.marshal(json.patch(tkn_test.slsav1_task(task_name), [
		{
			"op": "replace",
			"path": "/spec/params",
			"value": params,
		},
		{
			"op": "add",
			"path": "/status/taskResults",
			"value": results,
		},
	])))
	attestation := {"statement": {
		"predicateType": "https://slsa.dev/provenance/v1",
		"predicate": {"buildDefinition": {
			"buildType": "https://tekton.dev/chains/v2/slsa-tekton",
			"externalParameters": {"runSpec": {"pipelineSpec": {}}},
			"resolvedDependencies": [{
				"name": "pipelineTask",
				"content": content,
			}],
		}},
	}}
}

_bundle := "registry.img/spam@sha256:4e388ab32b10dc8dbc7e28144f552830adc74787c1e2c0824032078a79f227fb"

_results := [
	{
		"name": "IMAGE_DIGEST",
		"type": "string",
		"value": "sha256:hash",
	},
	{
		"name": "IMAGE_URL",
		"type": "string",
		"value": "quay.io/jstuart/hacbs-docker-build:tag@sha256:hash",
	},
]
