# Maverick

**Maverick** is a web-based REPL and IDE for Ink, built on [September](https://github.com/thesephist/september). It compiles Ink code to JavaScript to run it locally in the browser without a native environment.

## Architecture

// TODO

### REPL environment

Currently, Ink's module system does not work within September-compiled bundles. So instead, these standard libraries are globally available in the REPL environment:

- `std`
- `str`
- `quicksort`
- `json`

## Development

// TODO
