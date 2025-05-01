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
  tree-sitter playground (
    if (not $open_browser) {
      "-q"
    } else {
      "--"
    }
  )
}

def "main generate-compilation-db" [] {
  checks --generate-db
  bear -- tree-sitter build
}
