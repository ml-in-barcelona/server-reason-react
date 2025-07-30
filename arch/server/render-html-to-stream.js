import React from "react";
import * as ReactDOM from "react-dom/server";
import { prefetchDNS, preconnect, preload, preinit } from 'react-dom'

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

/* function App() {
		return React.createElement(
			Suspense,
			{ fallback: "Fallback 1" },
			React.createElement(DeferredComponent,
				{ by: 0.02 },
				React.createElement(
					Suspense,
					{ fallback: "Fallback 2" },
					React.createElement(DeferredComponent,
						{ by: 0.02 },
						"lol"
					)
				)
			)
		);
	} */

/* function App() {
	return (
		<html>
			<body>
				<head>"asdf"</head>
				<div key="33">lol</div>
			</body>
		</html>
	);
}
 */


/* const AnotherComponent = async () => {
	preinit('analytics.js', { as: 'script' });
	await sleep(1);
	return <><script async={true} src="analytics.js" />
		<div>AnotherComponent</div></>;
}; */

const App = () => (
	<html>
		<head>
			<meta charSet="utf-8" />
		</head>
		<body>
			<div>
				<script src="https://unpkg.com/jquery@3.7.1/dist/jquery.min.js" async />
				<link rel="stylesheet" href="styles.css" async />
				<title>Hola!</title>
				<base href="${host}/${context}/${language}/" />
				<template>Hola!</template>
				<noscript>Hola!</noscript>
				<style>
					{"* {display: none}"}
				</style>
			</div>
		</body>
	</html>
);


ReactDOM.renderToReadableStream(<App />, { bootstrapModules: ["react", "react-dom"] }).then((stream) => {
	debug(stream);
});
