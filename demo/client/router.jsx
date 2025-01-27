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

const App = ({ data }) => {
	return (
		<React.StrictMode>
			<Page data={data} />
		</React.StrictMode>
	);
};

const callServer = (_id, _args) => {
	throw new Error(`callServer is not supported yet`);
};

const element = document.getElementById("root");
const stream = window.srr_stream && window.srr_stream.readable_stream;

if (stream) {
	const data = ReactServerDOM.createFromReadableStream(stream, { callServer });
	React.startTransition(() => {
		ReactDOM.hydrateRoot(element, <App data={data} />);
	});
} else {
	/* when does stream not exist? */
	let { pathname, search } = window.location;
	navigate(pathname + search);
}

// Simple router's navigation. On navigate, fetch the RSC payload from the server,
// and in a React transition, stream in the new page. Once complete, we'll pushState to
// update the URL in the browser.
async function navigate(pathname, push) {
	if (abortController != null) {
		abortController.abort();
	}
	abortController = new AbortController();
	let res = fetch(pathname, {
		headers: {
			Accept: "text/x-component",
		},
		signal: abortController.signal,
	});
	let root = await ReactServerDOM.createFromFetch(res);
	React.startTransition(() => {
		updateRoot(root, () => {
			if (push) {
				history.pushState(null, "", pathname);
				push = false;
			}
		});
	});
}

// Intercept link clicks to perform RSC navigation.
document.addEventListener("click", (e) => {
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
		e.preventDefault();
		navigate(link.pathname, true);
	}
});

// When the user clicks the back button, navigate with RSC.
window.addEventListener("popstate", (e) => {
	navigate(location.pathname);
});
