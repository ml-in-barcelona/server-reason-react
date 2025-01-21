import React from "react";
import ReactDOM from "react-dom/server";

const sleep = (seconds) =>
	new Promise((res) => setTimeout(res, seconds * 1000));

const DefferedComponent = async ({ by, children }) => {
	return sleep(by).then(() => {
		return (
		<div>
			Sleep {by}s, {children}
		</div>
	);
	});
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
		<DefferedComponent by={1}>
			<React.Suspense fallback="Fallback 2">
				<DefferedComponent by={1}>"lol"</DefferedComponent>
			</React.Suspense>
		</DefferedComponent>
	</React.Suspense>
); */

/* const UsePromise = ({promise}) => {
	let data = React.use(promise);
	return <div>{data}</div>;
};

const App = () => {
	let promise = new Promise((resolve) => setTimeout(() => resolve("lol"), 1000));
	return (
		<div>
			<UsePromise promise={promise} />
		</div>
	);
}; */


/* const AlwaysThrow = () => {
	throw new Error("always throwing");
};

const App = () => (
	<React.Suspense fallback="Fallback 1">
		<AlwaysThrow/>
	</React.Suspense>
); */

/* const App = () => (
		<DefferedComponent by={1}>"lol"</DefferedComponent>
); */


const AlwaysThrow = () => {
	throw new Error("always throwing");
};

const App = () => (
	<React.Suspense fallback="Fallback 1">
		<DefferedComponent by={1}>
			<React.Suspense fallback="Fallback 2">
				<AlwaysThrow/>
			</React.Suspense>
		</DefferedComponent>
	</React.Suspense>
);

ReactDOM.renderToReadableStream(<App />).then((stream) => {
	debug(stream);
});
