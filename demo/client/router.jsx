import React from "react";
import ReactDOM from "react-dom/client";
import ReactServerDOM from "react-server-dom-webpack/client";

let updateRoot = null;
let abortController = null;

function Page({ data }) {
	// Store the current root element in state, along with a callback
	// to call once rendering is complete.
	let [[root, cb], setRoot] = React.useState([React.use(data), null]);
	updateRoot = (root, cb) => setRoot([root, cb]);
	React.useInsertionEffect(() => cb?.());
	return root;
}

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
const App = ({ data }) => {
	return (
		<ErrorBoundary>
			<Page data={data} />
		</ErrorBoundary>
	);
};

const callServer = (_id, _args) => {
	throw new Error(`callServer is not supported yet`);
};

const element = document.getElementById("root");
const stream = window.srr_stream && window.srr_stream.readable_stream;

if (stream) {
	console.log("__client_manifest_map", window.__client_manifest_map);
	const data = ReactServerDOM.createFromReadableStream(stream, { callServer });
	React.startTransition(() => {
		const app = <App data={data} />;
		ReactDOM.hydrateRoot(element, app);
	});
} else {
	/* when does stream not exist? */
	let { pathname, search } = window.location;
	navigate(pathname + search);
}

// Simple router's navigation. On navigate, fetch the RSC payload from the server,
// and in a React transition, stream in the new page. Once complete, we'll pushState to
// update the URL in the browser.
async function navigate(search) {
	let queryStrings = "?" + search;
	if (window.location.search === queryStrings) {
		return;
	}
	console.log("navigate", search);
	let origin = window.location.origin;
	let pathname = window.location.pathname;
	console.log("pathname", pathname);
	let url = new URL(origin + pathname + queryStrings);
	if (abortController != null) {
		abortController.abort();
	}
	abortController = new AbortController();
	let res = fetch(url.toString(), {
		headers: {
			Accept: "application/react.component",
		},
		signal: abortController.signal,
	});
	let root = await ReactServerDOM.createFromFetch(res);
	React.startTransition(() => {
		updateRoot(root, () => {
			history.pushState(null, "", url.pathname + url.search);
		});
	});
}

/* function useAction(endpoint, method) {
	console.log("useAction", endpoint, method);
	const { refresh } = useRouter();
	const [isSaving, setIsSaving] = React.useState(false);
	const [didError, setDidError] = React.useState(false);
	const [error, setError] = React.useState(null);

	if (didError) {
		// Let the nearest error boundary handle errors while saving.
		throw error;
	}

	async function performMutation(payload, requestedLocation) {
		setIsSaving(true);
		try {
			const response = await fetch(
				`${endpoint}?location=${encodeURIComponent(
					JSON.stringify(requestedLocation),
				)}`,
				{
					method,
					body: JSON.stringify(payload),
					headers: {
						"Content-Type": "application/json",
					},
				},
			);
			if (!response.ok) {
				throw new Error(await response.text());
			}
			refresh(response);
		} catch (e) {
			setDidError(true);
			setError(e);
		} finally {
			setIsSaving(false);
		}
	}

	return [performMutation, isSaving];
} */

/* Publish navigate to window, to avoid circular dependency. Once the implementation of router is migrated into a library, we can remove this and use "navigate" directly  */
window.__navigate = navigate;
/* window.__useAction = useAction; */
