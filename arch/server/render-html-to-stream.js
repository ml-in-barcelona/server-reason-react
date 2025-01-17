import React from "react";
import ReactDOM from "react-dom/server";

const sleep = (seconds) =>
	new Promise((res) => setTimeout(res, seconds * 1000));

const DefferedComponent = async ({ by, children }) => {
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
		<DefferedComponent by={1}>
			<React.Suspense fallback="Fallback 2">
				<DefferedComponent by={1}>"lol"</DefferedComponent>
			</React.Suspense>
		</DefferedComponent>
	</React.Suspense>
); */

/* const App = () => (
	<div>
		<React.Suspense fallback="Fallback 1">
			<DefferedComponent by={0}>"lol"</DefferedComponent>
		</React.Suspense>
	</div>
); */

const App = () =>
<head>
	<main>
		<span>{"Hi"}</span>
		<link href="/static/demo/client/app.css" rel="stylesheet" />
	</main>
</head>


ReactDOM.renderToReadableStream(<App />).then((stream) => {
	debug(stream);
});
