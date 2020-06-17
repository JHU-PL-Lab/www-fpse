## OCaml Coding Information

### Installing OCaml 4.10.0 and associated tools

We are using OCaml version 4.10.0.  We also require that you use the [OPAM packaging
system](https://opam.ocaml.org) for installing OCaml and its extensions.  Once you get `opam` installed and working, everything else should be easy .. so the only hard part can be the step.

-   For Linux or Mac see [The OPAM install page](https://opam.ocaml.org/doc/Install.html) for install instructions.  Depending on which method you use you may then need to run some terminal commands to set up the basics:
    1.  `opam init` to initialize OPAM;
    2.  `opam switch create 4.10.0` to build OCaml version 4.10.0 (the initial install is usually a slightly outdated version; also, if you already have an OPAM install you may need to `opam update`  to make sure OPAM is aware of the latest version before performing the `create`);
	3.  `` eval `opam env` `` to let the shell know where the OPAM files are; and
    4.  also add the very same line, `` eval `opam env` ``, to your`.profile`/`.bashrc`/`.zshrc` shell init file so you will not have to keep doing that over and over.
-   Windows Windows Windows.. the OCaml toolchain is unfortunately not good in straight Windows.
    -   If you are running a recent Windows install, we recommend installing [WSL 2](https://docs.microsoft.com/en-us/windows/wsl/) which once you have set up will allow you to follow the Linux Ubuntu install instructions to get `opam`. 
    -   Option 2 is to set up a Linux VM on your Windows box, and then set up a Linux install of OCaml within the VM.  There are many good tutorials on how to build a Linux VM, [here is one of them](https://www.lifewire.com/run-ubuntu-within-windows-virtualbox-2202098).Once your virtual Linux box is set up, you can follow the `opam` Linux install instructions.


#### Required OPAM Standard packages

Once you have the basics installed, run the following command to install additional necessary packages for the class:

    opam install merlin ocp-indent user-setup tuareg menhir utop base bisect_ppx


### The Official OCaml Manual

The manual is [here](http://caml.inria.fr/pub/docs/manual-ocaml/).
Let us give a high-level overview of sections of the manual we will be using in the course.
				
* We will cover most of Part I Chapters 1 and 2.
* Chapter 7 is the language reference where you can look up details if needed. 
* We will be covering a few topics in the [language extensions](http://caml.inria.fr/pub/docs/manual-ocaml/extn.html) chapter:
  * [locally abstract types](http://caml.inria.fr/pub/docs/manual-ocaml/locallyabstract.html),
  * [First-class modules](http://caml.inria.fr/pub/docs/manual-ocaml/firstclassmodules.html), and
  * [GADT's](http://caml.inria.fr/pub/docs/manual-ocaml/gadts.html).
  
* Part III documents the tools.  We will use some of the standard tools but third parties have improved on many of them.  See below in the Tools list where we give "our" list of tools.
* Part IV describes the standard libraries; we will mainly use Jane Street's base which replaces these, but we may look at a few of the [standard library modules](http://caml.inria.fr/pub/docs/manual-ocaml/stdlib.html).

### The FPSE OCaml Toolbox

Here are all the tools we will be using for the record.  You are required to have a build for which all these tools work, and the above `opam` one-liner should install them all.

* [`opam`](https://opam.ocaml.org) is the package management system which is required.  See above for install instructions.
* [`ocamlc`](http://caml.inria.fr/pub/docs/manual-ocaml/comp.html) is the standalone compiler which we will generally be invoking via the `dune` build tool.
* [`ocaml`](http://caml.inria.fr/pub/docs/manual-ocaml/toplevel.html) is the interactive REPL (read-eval-print loop) which we will generally be using via the more feature-laden `utop` extension.
* [`ocamldoc`](http://caml.inria.fr/pub/docs/manual-ocaml/ocamldoc.html) is the documentation generator, turning code comments into documentation webpages similar to JavaDoc etc.
* [`dune`](https://dune.build) is the build tool (think `make`) that we will be using.  `ocamlbuild` is the standard build tool but it is not very flexible.
* [`bisect_ppx`](https://github.com/aantron/bisect_ppx) will be used for code coverage.
* [Base](https://opensource.janestreet.com/base/) is a complete rewrite of the standard libraries that come built in to OCaml.  Think of it as a "more modern" version of lists, sets, hash tables, etc, with lots of little improvements in many places.  We are going to use Base as it is what real OCaml software engineers today are using.

### Other OCaml Resources

* [Real World OCaml](https://dev.realworldocaml.org/index.html) has recently been updated to a new edition and contains very nice tutorial descriptions of some of the newer features and also uses Jane Street's Base extensively.

 
