import React from "react";
import * as ReactDOM from "react-dom/server";

const sleep = (seconds) => new Promise((res) => setTimeout(res, seconds * 1000));

const DeferredComponent = async ({ by, children }) => {
	await sleep(by);
	return <div>Resolved after {by}s: {children}</div>;
};

const decoder = new TextDecoder();

const drain = async (readableStream, label) => {
	const reader = readableStream.getReader();
	let out = "";
	while (true) {
		const { done, value } = await reader.read();
		if (done) break;
		out += decoder.decode(value);
	}
	console.log(`\n===== ${label} =====`);
	console.log(out);
	console.log(`===== end ${label} (len=${out.length}) =====\n`);
};

const App = () => (
	<html>
		<body>
			<div>shell content</div>
			<React.Suspense fallback={<div>Loading A...</div>}>
				<DeferredComponent by={10}>A</DeferredComponent>
			</React.Suspense>
			<React.Suspense fallback={<div>Loading B...</div>}>
				<DeferredComponent by={10}>B</DeferredComponent>
			</React.Suspense>
		</body>
	</html>
);

// Case 1: abort() before boundaries resolve — what does React flush?
async function abortCase() {
	const controller = new AbortController();
	const stream = await ReactDOM.renderToReadableStream(<App />, {
		signal: controller.signal,
		onError(err) {
			console.log("[onError]", err && err.message ? err.message : err);
		},
	});
	// Abort shortly after the shell is produced, while boundaries are still pending.
	setTimeout(() => controller.abort(new Error("aborted by server")), 100);
	await drain(stream, "ABORT (boundaries pending)");
}

abortCase().catch((e) => console.error("fatal", e));
