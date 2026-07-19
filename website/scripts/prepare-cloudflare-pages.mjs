import { cp, mkdir, rm, writeFile } from "node:fs/promises";

const distDirectory = new URL("../dist/", import.meta.url);
const clientDirectory = new URL("client/", distDirectory);
const serverDirectory = new URL("server/", distDirectory);
const pagesDirectory = new URL("pages/", distDirectory);
const workerDirectory = new URL("_worker/", pagesDirectory);
const wranglerConfig = new URL("../wrangler.pages.jsonc", import.meta.url);

await rm(pagesDirectory, { force: true, recursive: true });
await mkdir(pagesDirectory, { recursive: true });
await cp(clientDirectory, pagesDirectory, { recursive: true });
await mkdir(workerDirectory, { recursive: true });
await cp(serverDirectory, workerDirectory, { recursive: true });
await rm(new URL("wrangler.json", workerDirectory), { force: true });
await writeFile(
  new URL("_worker.js", pagesDirectory),
  'export { default } from "./_worker/index.js";\n',
);
await cp(wranglerConfig, new URL("wrangler.jsonc", pagesDirectory));
await writeFile(
  new URL(".assetsignore", pagesDirectory),
  "wrangler.json\nwrangler.jsonc\n_worker\n.dev.vars\n",
);
await rm(new URL("../.wrangler/deploy/config.json", import.meta.url), {
  force: true,
});
