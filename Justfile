export JUST := just_executable()

alias gen := generate
generate:
    tree-sitter generate

alias compile := build
build wasm="": generate
    tree-sitter build {{ if wasm != "" { "--wasm" } else { "" } }}


alias play := playground
playground open_browser="":
    @"$JUST" build y
    tree-sitter playground {{ if open_browser == "" { "-q" } else { "" } }}
