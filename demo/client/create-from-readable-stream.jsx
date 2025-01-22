const React = require("react");
const ReactDOM = require("react-dom/client");
const ReactServerDOM = require("react-server-dom-webpack/client");
const ErrorBoundary = require("./error-boundary");
const Use = require("./use");

try {
	const stream = window.srr_stream.readable_stream;
	const promise = ReactServerDOM.createFromReadableStream(stream);
	const element = document.getElementById("root");

	React.startTransition(() => {
		const app = (
			<ErrorBoundary>
				<Use promise={promise} />
			</ErrorBoundary>
		);
		ReactDOM.hydrateRoot(element, app);
	});
} catch (e) {
	console.error("Error type:", e.constructor.name);
	console.error("Full error:", e);
	console.error("Stack:", e.stack);
}
