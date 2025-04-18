import React from "react";
import { renderToPipeableStream } from "react-server-dom-webpack/server";

const DefferedComponent = async ({ sleep, children }) => {
	await new Promise((res) => setTimeout(() => res(), sleep * 1000));
	return (
		<span>
			Sleep {sleep}s, {children}
		</span>
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

const sleep = (seconds) =>
	new Promise((res) => setTimeout(res, seconds * 1000));

/* const App = () => (
	<React.Suspense fallback="Fallback 1">
		<DefferedComponent sleep={1}>
			<React.Suspense fallback="Fallback 2">
				<DefferedComponent sleep={1}>"lol"</DefferedComponent>
			</React.Suspense>
		</DefferedComponent>
	</React.Suspense>
);
 */

function Comp() {
	return <h1>Hello</h1>;
}

function App() {
	let value = "asdfasdf";
	return (
		<>
			<input id="sidebar-search-input" placeholder="Search" value={value} />
			<Comp />
		</>
	);
}

const { pipe } = renderToPipeableStream(<App />);

pipe(process.stdout);
