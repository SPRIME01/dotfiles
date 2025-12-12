# Glossary

- chezmoi: A tool to manage your home directory across machines using a source directory of templates.
- template: A source file (e.g., `dot_zshrc.tmpl`) that chezmoi renders to a target (e.g., `~/.zshrc`).
- direnv: A tool that loads/unloads environment variables per directory via `.envrc` files.
- `direnv allow`: Trust an `.envrc` file so direnv can evaluate it.
- just: A command runner for declaring and invoking recipes (tasks).
- global justfile: The `~/.justfile` installed by chezmoi from `dot_justfile`.
- project justfile: The `justfile` in this repo; applies when you run `just` in the repo directory.
- WSL: Windows Subsystem for Linux; enables running Linux alongside Windows.
- Oh My Posh (OMP): A theme engine for your shell prompt.

