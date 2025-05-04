#!/usr/bin/env nu

const current_dir = (path self  .)

def has [x: string] {
  if ((which x) != []) {
    error make -u {
      msg: $"cannot find ($x) command"
      help: "try installing it from package manager or check the source"
    }
  }
}

def checks [
  --compiles-to-wasm
  --generate-db
] {
  has tree-sitter
  has cc
  if ($compiles_to_wasm) {
    has emcc
  }
  if ($generate_db) {
    has bear
  }
}

def "main" [] {}

def --wrapped "main gen" [...args] {
  tree-sitter generate ...$args
}

def "main playground" [
  --open-browser,
] {
  checks --compiles-to-wasm
  tree-sitter generate
  tree-sitter build --wasm

  let id = job spawn {
    tree-sitter playground (
      if (not $open_browser) {
        "-q"
      } else {
        "--"
      }
    )
  }
  let paths = [grammar.nix src/scanner.c] | path expand

  try {
    watch . { |_, path|
      if ($path in $paths) {
        print "Rebuilding..."
        tree-sitter generate
        tree-sitter build --wasm
      }
    }
  } catch {||}

  job kill $id
}

def "main gen-compilation-db" [] {
  checks --generate-db
  bear -- tree-sitter build
}
