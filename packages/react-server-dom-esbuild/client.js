export function createFromReadableStream(stream) {
	// Placeholder for parsing RSC stream
	return new Promise((resolve) => {
		const reader = stream.getReader();
		reader.read().then(function process({ done, value }) {
			if (done) {
				resolve(/* parsed component tree */);
				return;
			}
			// Decode chunk (e.g., JSON-like RSC format)
			return reader.read().then(process);
		});
	});
}

export function hydrateRoot(container, initialChildren) {
	// Delegate to react-dom
	import("react-dom/client").then(({ hydrateRoot }) => {
		hydrateRoot(container, initialChildren);
	});
}

async function parseRSCStream(stream) {
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

async function resolveClientReference(id) {
	const manifest = await fetch("/dist/manifest.json").then((res) => res.json());
	const url = manifest[id];
	if (!url) throw new Error(`Client component ${id} not found`);
	return import(url).then((module) => module.default);
}
