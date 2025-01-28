import Fs from "fs/promises";
import Path from "path";
import { execSync } from "child_process";

let generateBootstrapFile = async (output, content) => {
	let previousContent = undefined;
	try {
		previousContent = await Fs.readFile(output, "utf8");
	} catch (e) {
		if (e.code !== "ENOENT") {
			throw e;
		}
	}
	const contentHasChanged = previousContent !== content;
	if (contentHasChanged) {
		await Fs.writeFile(output, content, "utf8");
	}
};

function pathsAreEqual(path1, path2) {
	const normalized1 = Path.normalize(path1);
	const normalized2 = Path.normalize(path2);
	return normalized1 === normalized2;
}

const isTheEntryPoint = (entryPoints, path) => {
	return entryPoints.some((entryPoint) => pathsAreEqual(path, entryPoint));
};

export function plugin(config) {
	return {
		name: "extract-client-components",
		setup(build) {
			if (config.output && typeof config.output !== "string") {
				console.error("output must be a string");
				return;
			}
			const output = config.output || "./bootstrap.js";

			build.onStart(async () => {
				if (!config.target) {
					console.error("target is required");
					return;
				}
				if (typeof config.target !== "string") {
					console.error("target must be a string");
					return;
				}

				const target = config.target;
				try {
					/* TODO: Make sure `server_reason_react.extract_client_components` is available in $PATH */
					const bootstrapContent = execSync(
						`server_reason_react.extract_client_components ${target}`,
						{ encoding: "utf8" },
					);
					await generateBootstrapFile(output, bootstrapContent);
				} catch (e) {
					console.log("Extraction of client components failed:");
					console.error(e);
					return;
				}
			});

			build.onResolve({ filter: /.*/ }, (args) => {
				/* question: not sure if this is enough or even a solid approach to detect the entrypoint */
				const isEntryPoint = isTheEntryPoint(
					build.initialOptions.entryPoints,
					args.path,
				);

				if (isEntryPoint) {
					return {
						path: args.path,
						namespace: "entrypoint",
					};
				}
				return null;
			});

			let webpackRequireMock = `
window.__webpack_require__ = (id) => {
  const component = window.__client_manifest_map[id];
  if (!component) {
    throw new Error(\`Could not find client component with id: \${id}\`);
  }
  return { __esModule: true, default: component };
};
window.__client_manifest_map = window.__client_manifest_map || {};`;

			build.initialOptions.banner = {
				js: webpackRequireMock,
			};

			build.onLoad({ filter: /.*/, namespace: "entrypoint" }, async (args) => {
				const filePath = args.path.replace(/^entrypoint:/, "");
				const entryPointContents = await Fs.readFile(filePath, "utf8");

				const contents = `
require("${output}");
${entryPointContents}`;

				return {
					loader: "jsx",
					contents,
					resolveDir: Path.dirname(Path.resolve(process.cwd(), filePath)),
				};
			});
		},
	};
}
