import {
	createResponse,
	getRoot,
	reportGlobalError,
	processBinaryChunk,
	close,
} from "@matthamlin/react-client/flight";

function startReadingFromStream(response, stream) {
	const reader = stream.getReader();
	function progress({ done, value }) {
		if (done) {
			close(response);
			return;
		}
		const buffer = value;
		processBinaryChunk(response, buffer);
		return reader.read().then(progress).catch(error);
	}
	function error(e) {
		reportGlobalError(response, e);
	}
	reader.read().then(progress).catch(error);
}

export function createFromReadableStream(stream, options) {
	const response = createResponse(
		null, // bundlerConfig
		null, // serverReferenceConfig
		null, // moduleLoading
		callCurrentServerCallback,
		undefined, // encodeFormAction
		undefined, // nonce
		options && options.temporaryReferences
			? options.temporaryReferences
			: undefined,
		undefined, // TODO: findSourceMapUrl
		__DEV__ ? (options ? options.replayConsoleLogs !== false : true) : false, // defaults to true
		__DEV__ && options && options.environmentName
			? options.environmentName
			: undefined,
	);
	startReadingFromStream(response, stream);
	return getRoot(response);
}

export const hydrateRoot = (container, initialChildren) => {
	console.log("hydrateRoot", container, initialChildren);
	// Delegate to react-dom
	import("react-dom/client").then(({ hydrateRoot }) => {
		hydrateRoot(container, initialChildren);
	});
};

async function parseRSCStream(stream) {
	console.log("parseRSCStream", stream);
	const chunks = [];
	const reader = stream.getReader();
	while (true) {
		const { done, value } = await reader.read();
		if (done) break;
		chunks.push(new TextDecoder().decode(value));
	}
	const data = chunks
		.join("")
		.split("\n")
		.map((line) => JSON.parse(line));
	return data.map((item) => {
		if (item["$"] === "react.client.reference") {
			return resolveClientReference(item.id);
		}
		return item; // Server component placeholder
	});
}

export const createFromFetch = (fetch) => {
	console.log("createFromFetch", fetch);
	return fetch.then((res) => parseRSCStream(res.body));
};

async function resolveClientReference(id) {
	console.log("resolveClientReference", id);
	const component = window.__client_manifest_map[id];
	if (!component) {
		throw new Error(`Could not find client component with id: ${id}`);
	}
	return { __esModule: true, default: component };
}
