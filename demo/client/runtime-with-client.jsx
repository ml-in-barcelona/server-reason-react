window.__webpack_require__ = (id) => {
	let component = window.__client_manifest_map[id];
	console.log("REQUIRE ---");
	console.log(id);
	console.log(component);
	console.log("---");
	/* return { __esModule: true, default: component }; */
	return component;
};


let React = require("react");
let ReactDOM = require("react-dom/client");
let ReactServerDOM = require("react-server-dom-webpack/client");

/*
melange_manifest.json

[
	"Note_editor": ["./app/demo/universal/js/Note_editor.js", {"melange.belt/List"}],
	["Counter", "Counter.js"],
	["Promise_renderer", "Promise_renderer.js"],
]
*/

/* bootstrap.js */
/* const { make: Note_editor } = require("./app/demo/universal/js/Note_editor.js"); */
const { make: Counter } = require("./app/demo/universal/js/Counter.js");
const { make: PR } = require("./app/demo/universal/js/Promise_renderer.js");

window.__client_manifest_map = {};

let register = (name, render) => {
	window.__client_manifest_map[name] = render;
};

register(
	"Note_editor",
	React.lazy(() => import("./app/demo/universal/js/Note_editor.js")));
register(
	"Counter",
	React.lazy(() => import("./app/demo/universal/js/Counter.js"))
);
register(
	"Promise_renderer",
	React.lazy(() => import("./app/demo/universal/js/Promise_renderer.js"))
);

/* If lazy */
/* let { make: Counter } = import("./app/demo/universal/js/Counter.js"); */

/* end bootstrap.js */

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
} catch (e) {
	console.error(e);
}
