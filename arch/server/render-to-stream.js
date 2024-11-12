import React from "react";
import ReactDOM from "react-dom/server";

const DefferedComponent = async ({ sleep, children }) => {
	await new Promise((res) => setTimeout(() => res(), sleep * 1000));
	return (
		<div>
			Sleep {sleep}s, {children}
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

/* const app = () => (
	<div>
		<React.Suspense fallback="Fallback 1">
			<DefferedComponent sleep={1}>"lol"</DefferedComponent>
		</React.Suspense>
	</div>
); */

const sleep = (seconds) =>
	new Promise((res) => setTimeout(res, seconds * 1000));

/* const App = () => (
	<div>
		<React.Suspense fallback="Fallback 1">"lol"</React.Suspense>
	</div>
); */
const Always_throw = () => {
	throw new Error("Always throw");
};

const App = () => (
	<div>
		<React.Suspense fallback="Fallback 1">
			<Always_throw />
		</React.Suspense>
	</div>
);

ReactDOM.renderToReadableStream(<App />).then((stream) => {
	debug(stream);
});
