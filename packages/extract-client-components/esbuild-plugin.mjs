import Fs from "node:fs/promises";
import Path from "node:path";
import { execSync } from "node:child_process";

async function generateBootstrapFile (output, content) {
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
				const isEntryPoint = args.kind === "entry-point";

				if (isEntryPoint) {
					return {
						path: args.path,
						namespace: "entrypoint",
					};
				}
				return null;
			});

			let webpackRequireMock = `
window.__webpack_require__ = window.__webpack_require__ || ((id) => {
  const component = window.__client_manifest_map[id];
  if (!component) {
    throw new Error(\`Could not find client component with id: \${id}\`);
  }
  return { __esModule: true, default: component };
});
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
