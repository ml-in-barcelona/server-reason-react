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
); */

/* const App = () => (
	<div>
		<React.Suspense fallback="Fallback 1">
			<DefferedComponent sleep={1}>"lol"</DefferedComponent>
		</React.Suspense>
	</div>
); */

  const App = () =>
        <>
<main>
		<span>{"Hi"} {"chat"}</span>
	</main>
</>


ReactDOM.renderToReadableStream(<App />).then((stream) => {
	debug(stream);
});
