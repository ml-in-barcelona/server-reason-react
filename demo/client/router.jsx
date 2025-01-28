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
			<React.StrictMode>
				<Page data={data} />
			</React.StrictMode>
		</ErrorBoundary>
	);
};

const callServer = (_id, _args) => {
	throw new Error(`callServer is not supported yet`);
};

const element = document.getElementById("root");
const stream = window.srr_stream && window.srr_stream.readable_stream;

if (stream) {
	console.log("Client manifest map:", window.__client_manifest_map);
	const data = ReactServerDOM.createFromReadableStream(stream, { callServer });
	React.startTransition(() => {
		const app = <App data={data} />;
		console.log(app);
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
	let pathname = window.location.pathname;
	let url = new URL(window.location.href + "?" + search);
	console.log("url", url);
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
			/* if (push) {
				history.pushState(null, "", pathname);
				push = false;
			} */
		});
	});
}

/* Publish navigate to window, to avoid circular dependency. Once the implementation of router is migrated into a library, we can remove this and use "navigate" directly  */
window.__navigate_rsc = navigate;

// Intercept link clicks to perform RSC navigation.
/* document.addEventListener("click", (e) => {
	console.log("event click");
	if (e.target.closest("button")) {
		console.log("event BUTTON!");
	}
	let link = e.target.closest("a");
	if (
		link &&
		link instanceof HTMLAnchorElement &&
		link.href &&
		(!link.target || link.target === "_self") &&
		link.origin === location.origin &&
		!link.hasAttribute("download") &&
		e.button === 0 && // left clicks only
		!e.metaKey && // open in new tab (mac)
		!e.ctrlKey && // open in new tab (windows)
		!e.altKey && // download
		!e.shiftKey &&
		!e.defaultPrevented
	) {
		if (!link.pathname.startsWith("/demo/router")) {
			return;
		}
		e.preventDefault();
		navigate(link.pathname, true);
	}
});

// When the user clicks the back button, navigate with RSC.
window.addEventListener("popstate", (e) => {
	navigate(location.pathname);
});
 */
