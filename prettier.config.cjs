/** @type {import('prettier').Config} */

const config = {
  // Shared with focuz-ai addon repos (e.g. odoo-enterprise). Per-repo overrides: add
  // prettier.config.cjs in the repo root; Prettier resolves the nearest config.
  plugins: [require.resolve("@prettier/plugin-xml")],
  bracketSpacing: false,
  printWidth: 120,
  proseWrap: "always",
  semi: true,
  trailingComma: "es5",
  xmlWhitespaceSensitivity: "preserve",
};

module.exports = config;
