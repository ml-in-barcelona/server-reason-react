import esbuild from 'esbuild';
import Fs from 'fs/promises';
import { execSync } from 'child_process';

let extractClientComponents = (config) => ({
  name: 'extract-client-components',
  setup(build) {
    build.onStart(async () => {
      if (!config.target) {
        console.error('target is required');
        return;
      }
      if (typeof config.target !== 'string') {
        console.error('target must be a string');
        return;
      }
      const target = config.target;
      let bootstrapContent = undefined;
      try {
        bootstrapContent = execSync(`server_reason_react.extract_client_components ${target}`, { encoding: 'utf8' });
        await Fs.writeFile(
          './boostrap.js',
          bootstrapContent,
          'utf8'
        )
      } catch (e) {
        console.log('Extraction of client components failed:');
        console.error(e);
        return;
      }
    })
  }
});

async function build(input, output) {
  let outdir = undefined;
  let outfile = undefined;
  let splitting = false;

  /* shitty way to check if output is a directory or a file */
  if (output.endsWith('/')) {
    outdir = output;
    splitting = true;
  } else {
    outfile = output;
    splitting = false;
  }
  try {
    const result = await esbuild.build({
      entryPoints: [input],
      bundle: true,
      platform: 'browser',
      format: 'esm',
      splitting,
      logLevel: 'error',
      outdir: outdir,
      outfile: outfile,
      plugins: [extractClientComponents({ target: 'app' })],
      write: true,
      metafile: true,
    });

    console.log('Build completed successfully for "' + input + '"');
    return result;
  } catch (error) {
    console.error('\nBuild failed:', error);
    process.exit(1);
  }
}

const input = process.argv[2];
const output = process.argv[3];

if (!input) {
  console.error('Please provide an input file path');
  process.exit(1);
}

build(input, output);
