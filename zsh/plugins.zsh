# Plugin configuration for zsh
#
# Sourced by `.zshrc` to configure Oh My Zsh plugins. Build the list
# dynamically so missing custom plugins don't break startup when strict
# options are enabled upstream.

# Start with safe built-ins
plugins=(
	git
	docker
	kubectl
	npm
	node
	python
	pip
	ubuntu
	command-not-found
	history-substring-search
	colored-man-pages
	direnv
)
# Include community plugins only if installed
# _zsh_custom_plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
# if [[ -d "$_zsh_custom_plugins_dir/zsh-autosuggestions" ]]; then
#     plugins+=(zsh-autosuggestions)
# fi
#
# # zsh-syntax-highlighting should be last
# if [[ -d "$_zsh_custom_plugins_dir/zsh-syntax-highlighting" ]]; then
#     plugins+=(zsh-syntax-highlighting)
# fi
#
# unset _zsh_custom_plugins_dir
