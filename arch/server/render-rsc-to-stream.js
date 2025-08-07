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

const App = () => {
	return (
		<div className="container">
			<link rel="stylesheet" href="bootstrap.min.css" precedence="high" /></div>
	)
};
const { pipe } = renderToPipeableStream(<App />);

pipe(process.stdout);

/* https://codesandbox.io/p/sandbox/vibrant-voice-hdrlzt?file=%2Fsrc%2FApp.js */
