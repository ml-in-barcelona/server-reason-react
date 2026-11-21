const React = require("react");
const ReactDOM = require("react-dom/server");

function DivWithId() {
	const id = React.useId();
	return React.createElement("div", { id: id });
}

function DivWithTwoIds() {
	const id1 = React.useId();
	const id2 = React.useId();
	return React.createElement("div", { "data-id1": id1, "data-id2": id2 });
}

function DivWithThreeIds() {
	const id1 = React.useId();
	const id2 = React.useId();
	const id3 = React.useId();
	return React.createElement("div", {
		"data-id1": id1,
		"data-id2": id2,
		"data-id3": id3,
	});
}

function Wrapper({ children }) {
	return React.createElement("div", { className: "wrapper" }, children);
}

function ParentWithId({ children }) {
	const id = React.useId();
	return React.createElement("div", { id: id }, children);
}

function Test1() {
	return React.createElement(DivWithId);
}

function Test2() {
	return React.createElement(
		"div",
		null,
		React.createElement(DivWithId),
		React.createElement(DivWithId),
	);
}

function Test3() {
	return React.createElement(
		ParentWithId,
		null,
		React.createElement(DivWithId),
	);
}

function Test4() {
	return React.createElement(DivWithTwoIds);
}

function Test5() {
	return React.createElement(DivWithThreeIds);
}

function Test6() {
	return React.createElement(
		"div",
		null,
		React.createElement(
			ParentWithId,
			null,
			React.createElement(DivWithId),
		),
		React.createElement(DivWithId),
	);
}

function Test7() {
	return React.createElement(
		ParentWithId,
		null,
		React.createElement(
			ParentWithId,
			null,
			React.createElement(DivWithId),
		),
	);
}

function Test8() {
	return React.createElement(
		Wrapper,
		null,
		React.createElement(DivWithId),
	);
}

function Test9() {
	return React.createElement(
		"div",
		null,
		React.createElement(DivWithId),
		React.createElement(DivWithId),
		React.createElement(DivWithId),
	);
}

function Test10() {
	return React.createElement(
		"div",
		null,
		React.createElement(
			ParentWithId,
			null,
			React.createElement(DivWithId),
			React.createElement(DivWithId),
		),
		React.createElement(
			ParentWithId,
			null,
			React.createElement(DivWithId),
		),
	);
}

function Test11() {
	const items = [0, 1, 2].map((i) =>
		React.createElement(DivWithId, { key: String(i) }),
	);
	return React.createElement("div", null, items);
}

function Test12a() {
	return React.createElement(DivWithId);
}
function Test12b() {
	return React.createElement(DivWithId);
}

const tests = [
	["Test 1: Single component with useId", Test1],
	["Test 2: Two sibling components", Test2],
	["Test 3: Nested components", Test3],
	["Test 4: Two useId calls in one component", Test4],
	["Test 5: Three useId calls in one component", Test5],
	["Test 6: Siblings with nested children", Test6],
	["Test 7: Deep nesting (3 levels)", Test7],
	["Test 8: Wrapper without useId", Test8],
	["Test 9: Three siblings", Test9],
	["Test 10: Complex siblings with nested", Test10],
	["Test 11: Array/list of components", Test11],
];

for (const [name, Component] of tests) {
	const html = ReactDOM.renderToString(React.createElement(Component));
	console.log(`${name}:`);
	console.log(`  ${html}`);
	console.log();
}

console.log("Test 12: Separate renders produce same IDs:");
const html12a = ReactDOM.renderToString(React.createElement(Test12a));
const html12b = ReactDOM.renderToString(React.createElement(Test12b));
console.log(`  render1: ${html12a}`);
console.log(`  render2: ${html12b}`);
console.log(`  same: ${html12a === html12b}`);
