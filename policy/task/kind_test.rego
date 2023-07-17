package policy.task.kind

import data.lib

test_unexpected_kind {
	lib.assert_equal_results(deny, {{
		"code": "kind.unexpected_kind",
		"msg": "Unexpected kind 'Foo'",
	}}) with input.kind as "Foo"
}

test_expected_kind {
	lib.assert_empty(deny) with input as {"kind": "Task"}
}

test_kind_not_found {
	lib.assert_equal_results(deny, {{
		"code": "kind.kind_not_found",
		"msg": "Required field 'kind' not found",
	}}) with input as {"bad": "Foo"}
}
