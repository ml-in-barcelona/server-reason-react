import React from "react";
import * as ReactDOM from "react-dom/server";

const sleep = (seconds) =>
	new Promise((res) => setTimeout(res, seconds * 1000));

const DeferredComponent = async ({ by, children }) => {
	await sleep(by);
	return (
		<div>
			Sleep {by}s, {children}
		</div>
	);
};

const decoder = new TextDecoder();

const debug = (readableStream) => {
	const reader = readableStream.getReader();
	const debugReader = ({ done, value }) => {
		if (done) {
			console.log("Stream complete");
			return;
		}
		console.log(decoder.decode(value));
		console.log(" ");
		return reader.read().then(debugReader);
	};
	reader.read().then(debugReader);
};

/* const App = () => (
	<React.Suspense fallback="Fallback 1">
		<DeferredComponent by={1}>
			<React.Suspense fallback="Fallback 2">
				<DeferredComponent by={1}>"lol"</DeferredComponent>
			</React.Suspense>
		</DeferredComponent>
	</React.Suspense>
); */

/* const App = () => (
	<div>
		<React.Suspense fallback="Fallback 1">
			<DeferredComponent by={0}>"lol"</DeferredComponent>
		</React.Suspense>
	</div>
); */

/* const AlwaysThrow = () => {
	throw new Error("always throwing");
};

const App = () => (
	<React.Suspense fallback="Fallback 1">
		<DeferredComponent by={1}>
			<React.Suspense fallback="Fallback 2">
				<AlwaysThrow/>
			</React.Suspense>
		</DeferredComponent>
	</React.Suspense>
); */

/* function App() {
		return React.createElement(
			Suspense,
			{ fallback: "Fallback 1" },
			React.createElement(DeferredComponent,
				{ by: 0.02 },
				React.createElement(
					Suspense,
					{ fallback: "Fallback 2" },
					React.createElement(DeferredComponent,
						{ by: 0.02 },
						"lol"
					)
				)
			)
		);
	} */

/* function App() {
	return (
		<html>
			<body>
				<head>"asdf"</head>
				<div key="33">lol</div>
			</body>
		</html>
	);
}
 */

function App() {
	return (
		<>
			<html>
				<input
					id="sidebar-search-input"
					placeholder="Search"
					defaultValue={"L??"}
					onChange={() => { }}
				/>
				<div>Content inside body</div>
			</html>
		</>
	);
}

ReactDOM.renderToReadableStream(<App />, { bootstrap_modules: ["react", "react-dom"] }).then((stream) => {
	debug(stream);
});
