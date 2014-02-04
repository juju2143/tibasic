TI-BASIC Scripting Language
===========================
A reimplementation of the TI-83+ BASIC as a Linux scripting language. It aims to be as faithful as possible to the original TI-BASIC while retooling it to be useful on a Linux system instead of a graphing calculator.

This version does not emulate a graphic screen like on the original calc, displaying stuff to stdout instead, so it won't aim to be compatible with the language found on the TI-83+.

Compile
-------
You'll need ```flex```, ```bison``` and your distro's development tools installed (```build-essentials``` on Debian/Ubuntu or ```base-devel``` on Arch), or at least a C++ compiler, then it's as easy as running ```make```.

Run
---
If you don't give a TI-BASIC script as an argument, the executable will read from stdin.
```
tibasic < script.tib
tibasic script.tib
```

Tutorials
---------
You can learn more on TI-BASIC on sites such as [TI-BASIC Developer](http://tibasicdev.wikidot.com/). Obviously, some stuff might differ from the calc version, those technicalities will be described on the [wiki](https://github.com/juju2143/tibasic/wiki).

Links and credit
----------------
* [Support forum](http://omnimaga.org/)
* Created by [Juju](http://juju2143.ca)
* Original language by [Texas Instruments](http://education.ti.com)
