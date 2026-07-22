# OCaml Coding Information

We are using [OCaml](https://ocaml.org) version 5.5.1. Please follow all instructions here to set up your coding environment.

## Installing OCaml 5.5.1 and associated tools

We require that you use the [opam packaging system](https://opam.ocaml.org) for installing OCaml and its extensions.  Once you get `opam` installed and working, everything else should be easy to install.

To get `opam`, please follow the following instructions for your operating system exactly to avoid any issues.

### Linux

At the time of writing, you only need to run

```
bash -c "sh <(curl -fsSL https://opam.ocaml.org/install.sh)"
```

See [the OPAM install page](https://opam.ocaml.org/doc/Install.html) for further installation instructions. We suggest curling the shell script like above because most system's packager managers do not support the latest version of `opam`.

### Mac

For Mac users it requires [Homebrew](https://brew.sh), a package manager for Linux-ish libraries.  If you don't have homebrew installed yet type the shell command

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

to install it.  Once you have it installed, type

```
brew update; brew install gpatch; brew install opam
```

to install opam using homebrew.

### Windows

Windows users should use WSL2 because Windows is not fully supported by OCaml. WSL2 creates a Linux-like system from within Windows.

You can follow the installation instructions [here](https://learn.microsoft.com/en-us/windows/wsl/install). They are as simple as running the following command from PowerShell as administrator:

```
wsl --install
```

Now start up WSL: you can just run `ubuntu` from inside PowerShell, or you may run the WSL app that is now on your PC.

From inside the WSL box, you need a few basic tools (e.g. a C compiler) before installing `opam`. Get them with this:

```
sudo apt install make m4 gcc zip unzip bubblewrap
```

Now you may follow the Linux instructions above to install `opam`.

## Initial setup of `opam`

Now that you have installed `opam`, you will need to run some terminal commands to set up the basics. Please follow these in order.

```
opam init
```

This will initialize OPAM. It should give a list of options 1/2/3/4/5, pick 1, `Yes update ~/.bash_profile` or something similar depending on your shell setup.

If you did not get that question, or you said to do nothing, you will need to add line, `eval $(opam env)`, to your `~/.bash_profile` or `~/.profile` or `~/.bashrc` shell init file (add to the first one of these files that exists already) as you would need to do that in every new terminal window otherwise. If you are using `zsh` on macs, add line ``eval `opam env` `` instead to your `~/.zshrc` file.

Now run

```
opam update
```

to make sure your `opam` is aware of all the latest versions of OCaml and its packages. Then you will install the latest version of the OCaml compiler:

```
opam switch create 5.5.1
```

You may now be asked to reset your path with some instructions like "Run `eval $(opam env --switch=5.5.1)` to update the current shell environment". If you get that message, then follow those instructions and copy/paste the command into the shell (if you are on a Mac you may be using `zsh`; replace the `$(...)` with back-quotes `` `...` ``).

If you already have an earlier version of OCaml installed via `opam`, then start at `opam switch create 5.5.1`.

### Required `opam` packages

Once you have `opam` and `ocaml` 5.5.1 installed, run the following `opam` command to install additional necessary packages for the class (just copy/paste this line into your shell and answer yes to all questions):

```sh
opam install ocaml-lsp-server ocamlformat utop dune ounit2 ppx_deriving cmdliner sexplib ppx_deriving_yojson qcheck ppx_deriving_qcheck
```

<!--
   TODO:
      We may want some of these:
         some community bisect    instead of   bisect_ppx
         ppx_deriving_yojson (added - SS)
         async?
         ppx_sexp_conv            instead of   hand-coding serializers

   Old install was this:
      opam install ocaml-lsp-server ocamlformat ocamlformat-rpc utop ounit2 base \
      base_quickcheck core async lwt ppx_jane ppx_deriving ppx_deriving_yojson bisect_ppx
 -->

Lastly, in order for the OCaml top loop to work properly, create or edit the file `~/.ocamlinit` to contain the line below.  All lines in this file are input to the top loop when it first starts.

This line goes in your `~/.ocamlinit`:

```
#use "topfind";;
```

Here is a shell command that you can run to make the above file for you:

```sh
(echo '#use "topfind";;') >~/.ocamlinit
```

<!-- This next instruction is out of date -->
<!-- To test that your install works, type the shell command `utop`, which will start up an interactive OCaml session (more later on that).  Type `Fn.id;;` into the `utop` prompt followed by return, this is just a test to make sure the `Core` libraries were properly loaded.  If you didn't get an error message you are all good!  Type control-D to quit `utop`. -->

## OCaml Documentation
[ocaml.org](https://ocaml.org) is the central repository of OCaml information.
### The OCaml Manual

The OCaml manual is [here](https://ocaml.org/manual/).
* We will cover most of the topics in Part I Chapters 1 and 2 from the manual.
* Manual Chapter 11 is the language reference where you can look up details if needed.
* We will be covering a few topics in the [language extensions](https://ocaml.org/manual/extn.html) chapter:
  * [locally abstract types](https://ocaml.org/manual/locallyabstract.html),
  * [First-class modules](https://ocaml.org/manual/firstclassmodules.html), and
  * [effect handlers](https://ocaml.org/manual/5.5/effects.html).
* Part III of the manual documents the tools. We will not be using much of this because third parties have improved on many of the tools, and we will instead use those improved versions.  See below in the Tools list where we give "our" list of tools.
* Part IV describes the standard libraries. These have historically been small (too small to rely on, some might say), but they have improved drastically in recent versions of OCaml. We will be using the OCaml standard library in this course, and this chapter is a good resource.

## The FPSE OCaml Toolbox

Here are all the tools we will be using.  You are required to have a build for which all these tools work, and the above `opam` one-liner should install them all.

* [`opam`](https://opam.ocaml.org) is the package management system.  See above for install and setup instructions.
* [`ocamlc`](https://ocaml.org/manual/comp.html) is the standalone compiler which we will be invoking via the `dune` build tool.
* [`utop`](https://opam.ocaml.org/blog/about-utop/) is the  read/eval/print loop.  It is a replacement for the original [`ocaml`](https://ocaml.org/manual/toplevel.html) command, with many more features such as command history, replay, etc.
* [`odoc`](https://ocaml.github.io/odoc/odoc/index.html) is the OCaml documentation generator, turning code comments into documentation webpages similar to JavaDoc etc.
* [`dune`](https://dune.build) is the build tool (think `make`) that we will be using.
* [OUnit](https://github.com/gildor478/ounit) is the unit tester for OCaml.  The opam package is called `ounit2` for obscure reasons.
* [`ppx_deriving`](https://github.com/ocaml-ppx/ppx_deriving) is a pre-process extension that derives useful functions from your types.

All of the above packages have documentation, but you may also want to try [sherlodoc](https://doc.sherlocode.com/) where you can find documentation on all opam packages in one spot.  For example typing `Sexplib.Conv` into the search will give all the documentation for the `Conv` module in `Sexplib`.

The above tools will be our "bread and butter", and we will be using them on many assignments.  There are also a few specialized tools used on some specific assignments.

<!-- * [Bisect](https://github.com/aantron/bisect_ppx) will be used for code coverage.
* [Lwt](https://ocsigen.org/lwt/latest/api/Lwt) is a non-preempting asychronous threads library. -->
* [QCheck](https://ocaml.org/p/qcheck-core/0.91) is a fuzz tester / automated test generator for OCaml.
* [`sexplib`](https://github.com/janestreet/sexplib) is a library for s-expression conversions, which we will use to serialize and deserialize data.
* [`cmdliner`](https://erratique.ch/software/cmdliner) is a useful tool for reading command line arguments from your OCaml programs.

### Development Environments for OCaml

We recommend VSCode since it has OCaml-specific features such as syntax highlighting, auto-indent, and lint analysis to make the coding process much smoother.

**[Visual Studio Code](https://code.visualstudio.com)**

VSCode has very good OCaml support and is the "officially recommended editor".

* To make VSCode OCaml-aware you will need to install the **OCaml Platform**.   To install it, from the `View` menu select `Extensions`, and type OCaml in the search box and this extension will show up: select **OCaml Platform** from the list.

* You can easily run a `utop` shell from within VSCode, just open up a shell from the `Terminal` menu and type `utop`.

* If you are on Windows and using WSL2, then we still suggest VSCode, and you can even use your Windows installation of it. Just install the [WSL VSCode extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) from the marketplace (the "extensions" tab in VSCode). Now from inside any directory in WSL, you can run `code .` to open up VSCode in that remote directory. You are now developing in a Linux environment but are connected to the Windows editor. Then install VSCode extensions like **OCaml Platform** from the extensions tab but as a remote extension.

**vim**: If you use `vim`, my condolances as it is woefully behind the times in spite of many band-aids added over the years.  Still, if you have been brainwashed to believe it is good, type shell commands `opam install merlin user-setup` and `opam user-setup install` after doing the above default `opam` install to set up syntax highlighting, tab completion, displaying types, etc. See [here](https://github.com/ocaml/merlin/blob/master/vim/merlin/doc/merlin.txt) for some dense documentation.

**emacs**: See vim. You will need to also `opam install tuareg` to get emacs to work, and follow the instructions the install prints out.

### Books

* The [Real World OCaml](https://dev.realworldocaml.org/index.html) book has a fairly good overlap with what we will cover and can be used as a supplementary resource. Note that it uses the `Core` standard library overlow, so its library functions may look different from yours.
* [Cornell cs3110 book](https://cs3110.github.io/textbook/cover.html) is the online text for a somewhat-related course at Cornell.  They have recently added many videos if you like watching videos to learn.
* [OCaml from the very beginning](https://johnwhitington.net/ocamlfromtheverybeginning/) is a free online book.
* [Learn Programming with OCaml](https://usr.lmf.cnrs.fr/lpo/) has an introduction to OCaml and several neat algorithms and data structures, but it does not emphasize learning _functional_ programming with OCaml. It is nevertheless an excellent resource.

### Coding Style

* The [FPSE Style Guide](/fpse/style-guide.html) is the standard we will adhere to in the class; it follows general best practices for modern OCaml.  It will be expected of your code from Assignment 3 and onward.

### Example Worked Exercises
One of the best ways to learn to write elegant OCaml is to study well-written OCaml code.

* [Exercism OCaml Track](https://exercism.io/tracks/ocaml/exercises) has a large set of programming problems to solve which have solutions by many other programmers as well.  We will reference some of these examples in lecture.
* [99 problems](https://ocaml.org/exercises) solves 99 basic OCaml tasks.
* [Learn OCaml](https://ocaml-sf.org/learn-ocaml-public/#activity%3Dexercises) has a large number of exercises to solve.  The [solutions are online](https://github.com/ocaml-sf/learn-ocaml-corpus/tree/master/exercises).
