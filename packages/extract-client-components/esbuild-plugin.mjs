import Fs from 'fs/promises';
import { execSync } from 'child_process';

let generateBootstrapFile = async (output, content) => {
  let previousContent = undefined;
  try {
    previousContent = await Fs.readFile(output, 'utf8');
  } catch (e) {
    if (e.code !== 'ENOENT') {
      throw e;
    }
  }
  const contentHasChanged = previousContent !== content;
  if (contentHasChanged) {
    await Fs.writeFile(output, content, 'utf8');
  }
};

export function plugin(config) {
  return {
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
      if (config.output && typeof config.output !== 'string') {
        console.error('output must be a string');
        return;
      }
      const output = config.output || './bootstrap.js';
      const target = config.target;
      try {
        /* TODO: Make sure `server_reason_react.extract_client_components` is available in $PATH */
        const bootstrapContent = execSync(`server_reason_react.extract_client_components ${target}`, { encoding: 'utf8' });
        await generateBootstrapFile(output, bootstrapContent);
      } catch (e) {
        console.log('Extraction of client components failed:');
        console.error(e);
        return;
      }
    })
    }
  };
}
