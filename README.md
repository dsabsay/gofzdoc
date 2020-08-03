# gofzdoc
Use [fzf](https://github.com/junegunn/fzf) to fuzzy search go documentation.
![screenshot of gofzdoc](./screenshot.png)

## Features
* Search docs for standard library
* Search docs for third-party libraries (using `go.mod` of current directory)
* Preview as you search
* Open doc in browser by pressing `Ctrl-x`

## Prerequisites
To use `gofzdoc`, you need:

* bash
* [fzf](https://github.com/junegunn/fzf)
* [bat](https://github.com/sharkdp/bat) (optional) if you want syntax 
  highlighting

## Installation
### With Homebrew
```
brew tap dsabsay/homebrew-tap
brew install gofzdoc
```

### Without Homebrew
Download [gofzdoc](./gofzdoc) and place it somewhere on your PATH.

## Acknowledgements
`gofzdoc` is a simple wrapper around `fzf` providing logic to generate and 
manage "indexes" that are fed into fzf. I'm extremely grateful to the hard work 
of [Junegunn Choi](https://github.com/junegunn), the author of `fzf`. It is a 
fantastic tool.
