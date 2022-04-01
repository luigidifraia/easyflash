# EasyFlash
Thomas ’skoe’ Giesel's EasySDK with EasyAPI usage examples, including embedding the latter into a CRT image.

## Notes
- Assemble source files with [ACME cross-assembler](https://sourceforge.net/projects/acme-crossass/). Version 0.96.4 has been successfully tested. A Windows executable is provided for user convenience.
- The `c1541` tool is available from VICE's [Web page](http://vice-emu.sourceforge.net/index.html#download). A Windows executable is provided for user convenience.
- To use the provided `Makefile` you need GNU `make`. A Windows executable is provided for user convenience.
- Under Windows you might want to run `win32/efvar.bat` to setup your build environment.

## Fixes
- The EAPI test example was adjusted to work with version 1.4 of the API.

## Official SDK reference code
Thomas' EasyFlash code repository is accessible [here](https://bitbucket.org/skoe/easyflash).
