import React from "react";
import ReactDOM from "react-dom/server";

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

function App() {
  return (
    <div>
      <React.Suspense fallback="Loading 1">
        <DeferredComponent seconds={1.0}>First</DeferredComponent>
      </React.Suspense>
      <React.Suspense fallback="Loading 2">
        <DeferredComponent seconds={2.0}>Second</DeferredComponent>
      </React.Suspense>
      <React.Suspense fallback="Loading 3">
        <DeferredComponent seconds={3.0}>Third</DeferredComponent>
      </React.Suspense>
    </div>
  );
}

ReactDOM.renderToReadableStream(<App />).then((stream) => {
	debug(stream);
});
