window.__webpack_require__ = (id) => {
	let component = window.__client_manifest_map[id];
	console.log("REQUIRE ---");
	console.log(id);
	console.log(component);
	console.log("---");
	return { __esModule: true, default: component };
};

window.__webpack_chunk_load__ = (id) => {
	console.log("CHUNK LOAD ---");
	console.log(id);
	console.log("---");
};

let React = require("react");
let ReactDOM = require("react-dom/client");
let ReactServerDOM = require("react-server-dom-webpack/client");

window.__client_manifest_map = {};

let register = (name, render) => {
	window.__client_manifest_map[name] = render;
};

register("Note_editor", () => {
	let { make: Note_editor } = import("./app/demo/universal/js/Note_editor.js");
	return Note_editor;
});

register("Counter", () => {
	let { make: Counter } = import("./app/demo/universal/js/Counter.js");
	return Counter;
});

class ErrorBoundary extends React.Component {
	constructor(props) {
		super(props);
		this.state = { hasError: false };
	}

	static getDerivedStateFromError(error) {
		// Update state so the next render will show the fallback UI.
		return { hasError: true };
	}

	componentDidCatch(error, errorInfo) {
		// You can also log the error to an error reporting service
		console.error(error, errorInfo);
	}

	render() {
		if (this.state.hasError) {
			return <h1>Something went wrong</h1>;
		}

		return this.props.children;
	}
}

function Use({ promise }) {
	let tree = React.use(promise);
	return tree;
}

try {
	const stream = window.srr_stream.readable_stream;
	const promise = ReactServerDOM.createFromReadableStream(stream);
	let element = document.getElementById("root");
	let app = (
		<ErrorBoundary>
			<Use promise={promise} />
		</ErrorBoundary>
	);
	React.startTransition(() => {
		ReactDOM.hydrateRoot(element, app);
	});
	console.log(__client_manifest_map);
} catch (e) {
	console.error(e);
}
