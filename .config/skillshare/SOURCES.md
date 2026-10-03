# Vendored skill sources

- `lua-config-api` is copied verbatim from
  [`bresilla/dot`](https://github.com/bresilla/dot/tree/98009daf76af6e36d731533444c4ef3c36b56169/.config/skillshare/skills/lua-config-api)
  at commit `98009daf76af6e36d731533444c4ef3c36b56169`, with the author's
  permission. It is intentionally a local skill rather than an upstream-tracked
  Skillshare install.
- `skillshare` is adapted from
  [`runkids/skillshare`](https://github.com/runkids/skillshare/tree/v0.20.27/skills/skillshare)
  at tag `v0.20.27` under that repository's MIT license. Its optional
  Claude-style `argument-hint` frontmatter is omitted so the same skill passes
  Codex validation. Keep it aligned with the CLI version pinned in
  `versions.toml`.
