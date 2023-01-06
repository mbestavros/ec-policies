package lib

import data.lib

test_result_helper {
	expected_result := {
		"code": "oh.Hey",
		"effective_on": "2022-01-01T00:00:00Z",
		"msg": "Bad thing foo",
	}

	rule_annotations := {"custom": {
		"short_name": "Hey",
		"failure_msg": "Bad thing %s",
	}}

	chain := [
		{"annotations": rule_annotations, "path": []},
		{"annotations": {}, "path": ["ignored", "oh"]},
	]

	lib.assert_equal(expected_result, result_helper(chain, ["foo"]))
}

test_result_helper_with_collections {
	expected := {
		"code": "oh.Hey",
		"collections": ["spam"],
		"effective_on": "2022-01-01T00:00:00Z",
		"msg": "Bad thing foo",
	}

	rule_annotations := {"custom": {
		"collections": ["spam"],
		"short_name": "Hey",
		"failure_msg": "Bad thing %s",
	}}

	chain := [
		{"annotations": rule_annotations, "path": []},
		{"annotations": {}, "path": ["ignored", "oh"]},
	]

	lib.assert_equal(expected, result_helper(chain, ["foo"]))
}
