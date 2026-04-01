const React = require("react");
const ReactDOM = require("react-dom/server");

function DivWithId({ label }) {
	const id = React.useId();
	return React.createElement("div", { id, "data-label": label });
}

// ── Edge Case 1: useId inside Suspense children ──────────────────────
// (sync component, no actual suspension)
function SuspenseWithUseId() {
	return React.createElement(
		React.Suspense,
		{ fallback: React.createElement("div", null, "loading") },
		React.createElement(DivWithId, { label: "inside-suspense" }),
	);
}

// ── Edge Case 2: useId in Suspense fallback vs children ──────────────
// Does Suspense fork the tree context?
function FallbackWithId() {
	const id = React.useId();
	return React.createElement("div", { id, "data-label": "fallback" });
}

function SuspenseWithIdInBoth() {
	return React.createElement(
		"div",
		null,
		React.createElement(
			React.Suspense,
			{
				fallback: React.createElement(FallbackWithId),
			},
			React.createElement(DivWithId, { label: "content" }),
		),
		React.createElement(DivWithId, { label: "sibling" }),
	);
}

// ── Edge Case 3: Fragment wrapping ───────────────────────────────────
// Does Fragment affect tree context?
function FragmentTest() {
	return React.createElement(
		"div",
		null,
		React.createElement(
			React.Fragment,
			null,
			React.createElement(DivWithId, { label: "in-fragment" }),
		),
	);
}

// ── Edge Case 4: Fragment with multiple children ─────────────────────
function FragmentMultipleChildren() {
	return React.createElement(
		"div",
		null,
		React.createElement(
			React.Fragment,
			null,
			React.createElement(DivWithId, { label: "frag-child-1" }),
			React.createElement(DivWithId, { label: "frag-child-2" }),
		),
	);
}

// ── Edge Case 5: Nested fragments ────────────────────────────────────
function NestedFragments() {
	return React.createElement(
		"div",
		null,
		React.createElement(
			React.Fragment,
			null,
			React.createElement(
				React.Fragment,
				null,
				React.createElement(DivWithId, { label: "nested-frag" }),
			),
		),
	);
}

// ── Edge Case 6: Empty elements between components ───────────────────
function NullBetween() {
	return React.createElement(
		"div",
		null,
		React.createElement(DivWithId, { label: "before-null" }),
		null,
		React.createElement(DivWithId, { label: "after-null" }),
	);
}

// ── Edge Case 7: useId with conditional children ─────────────────────
function ConditionalChildren({ show }) {
	return React.createElement(
		"div",
		null,
		show ? React.createElement(DivWithId, { label: "conditional" }) : null,
		React.createElement(DivWithId, { label: "always" }),
	);
}

// ── Edge Case 8: useId with keyed fragments ──────────────────────────
function KeyedFragments() {
	return React.createElement(
		"div",
		null,
		React.createElement(
			React.Fragment,
			{ key: "a" },
			React.createElement(DivWithId, { label: "keyed-a" }),
		),
		React.createElement(
			React.Fragment,
			{ key: "b" },
			React.createElement(DivWithId, { label: "keyed-b" }),
		),
	);
}

// ── Edge Case 9: Deeply nested list (many siblings) ──────────────────
function ManySiblings() {
	const items = Array.from({ length: 10 }, (_, i) =>
		React.createElement(DivWithId, { key: String(i), label: `item-${i}` }),
	);
	return React.createElement("div", null, items);
}

// ── Edge Case 10: useId after Suspense boundary ─────────────────────
function UseIdAfterSuspense() {
	return React.createElement(
		"div",
		null,
		React.createElement(
			React.Suspense,
			{ fallback: React.createElement("div", null, "loading") },
			React.createElement(DivWithId, { label: "inside" }),
		),
		React.createElement(DivWithId, { label: "after-suspense" }),
	);
}

// ── Edge Case 11: Provider/Context with useId ────────────────────────
const MyContext = React.createContext("default");
function ProviderWithUseId() {
	return React.createElement(
		MyContext.Provider,
		{ value: "provided" },
		React.createElement(DivWithId, { label: "inside-provider" }),
	);
}

// ── Edge Case 12: Mixed: Provider, Fragment, Suspense ────────────────
function KitchenSink() {
	return React.createElement(
		"div",
		null,
		React.createElement(
			MyContext.Provider,
			{ value: "a" },
			React.createElement(
				React.Fragment,
				null,
				React.createElement(DivWithId, { label: "provider-frag-1" }),
				React.createElement(
					React.Suspense,
					{
						fallback: React.createElement("span", null, "..."),
					},
					React.createElement(DivWithId, { label: "provider-suspense" }),
				),
			),
		),
		React.createElement(DivWithId, { label: "outside" }),
	);
}

const tests = [
	["Edge 1: useId inside Suspense (sync)", SuspenseWithUseId],
	["Edge 2: Suspense with useId in content + sibling", SuspenseWithIdInBoth],
	["Edge 3: Fragment wrapping (single child)", FragmentTest],
	["Edge 4: Fragment with multiple children", FragmentMultipleChildren],
	["Edge 5: Nested fragments", NestedFragments],
	["Edge 6: Null between components", NullBetween],
	["Edge 8: Keyed fragments", KeyedFragments],
	["Edge 9: Many siblings (10)", ManySiblings],
	["Edge 10: useId after Suspense", UseIdAfterSuspense],
	["Edge 11: Provider with useId", ProviderWithUseId],
	["Edge 12: Kitchen sink", KitchenSink],
];

for (const [name, Component] of tests) {
	const html = ReactDOM.renderToString(React.createElement(Component));
	console.log(`${name}:`);
	console.log(`  ${html}`);
	console.log();
}

// Edge 7 needs two renders
console.log("Edge 7a: Conditional children (show=true):");
console.log(
	`  ${ReactDOM.renderToString(React.createElement(ConditionalChildren, { show: true }))}`,
);
console.log();
console.log("Edge 7b: Conditional children (show=false):");
console.log(
	`  ${ReactDOM.renderToString(React.createElement(ConditionalChildren, { show: false }))}`,
);
