import Fs from "node:fs/promises";
import Path from "node:path";
import { execSync } from "node:child_process";

async function generateBootstrapFile(output, content) {
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
}

export function plugin(config) {
	return {
		name: "extract-client-components",
		setup(build) {
			if (
				config.bootstrapOutput &&
				typeof config.bootstrapOutput !== "string"
			) {
				console.error("bootstrapOutput must be a string");
				return;
			}
			const bootstrapOutput = config.bootstrapOutput || "./bootstrap.js";

			if (!config.target) {
				console.error("target is required");
				return;
			}
			if (typeof config.target !== "string") {
				console.error("target must be a string");
				return;
			}

			build.onStart(async () => {
				try {
					/* TODO: Make sure `server_reason_react.extract_client_components` is available in $PATH */
					const bootstrapContent = execSync(
						`server-reason-react.extract_client_components ${config.target}`,
						{ encoding: "utf8" },
					);
					await generateBootstrapFile(bootstrapOutput, bootstrapContent);
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

			build.onLoad({ filter: /.*/, namespace: "entrypoint" }, async (args) => {
				const filePath = args.path.replace(/^entrypoint:/, "");
				const entryPointContents = await Fs.readFile(filePath, "utf8");
				const relativeBootstrapOutput = Path.relative(
					Path.dirname(filePath),
					bootstrapOutput,
				);

				const contents = `
require("./${relativeBootstrapOutput}");
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
