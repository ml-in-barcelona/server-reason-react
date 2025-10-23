import React from "react";
import { renderToPipeableStream } from "react-server-dom-webpack/server";
import { prefetchDNS, preconnect, preload, preinit } from 'react-dom'

const DefferedComponent = async ({ sleep, children }) => {
	await new Promise((res) => setTimeout(() => res(), sleep * 1000));
	return (
		<span>
			Sleep {sleep}s, {children}
		</span>
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

const reject = (_) =>
	new Promise((_res, rej) => { return rej(0) });

const AlwaysError = () => {
	throw new Error("lol");
};

let Await_tick = ({ num }) => {
	return num
}

const Bar = () => {
	return (
		<div>
			Bar
		</div>
	)
}

const Foo = () => {
	return (
		<Bar />
	)
}
// Mimic of @file_context_0 – suspense with two “Text” children.

const Text = ({ children }) => <span>{children}</span>;

const App = () => (
	<React.Suspense fallback={"Loading..."}>
		<div>
			<Text>hi</Text>
			<Text>hola</Text>
		</div>
	</React.Suspense>
);
const { pipe } = renderToPipeableStream(<React.Suspense fallback={"Loading..."}>
	<div>
		<Text>hi</Text>
		<Text>hola</Text>
	</div>
</React.Suspense>);

pipe(process.stdout);

/* https://codesandbox.io/p/sandbox/vibrant-voice-hdrlzt?file=%2Fsrc%2FApp.js */
