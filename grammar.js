const { spawnSync } = require("node:child_process");

const [cmd, ...args] = [
  "nix",
  "--extra-experimental-features", "nix-command flakes",
  "eval",
  "--raw",
  ".#tree-sitter-grammar",
  "--show-trace",
];

const { stdout, status } = spawnSync(cmd, args, {
  stdio: ["ignore", "pipe", "inherit"],
});

if (status !== 0) {
  throw Error(`command failed: exit code ${status}`);
}

module.exports = {
  grammar: Object.assign({ name: null }, JSON.parse(stdout))
};
