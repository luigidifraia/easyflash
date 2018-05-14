# EasyFlash's EasyAPI usage examples

This directory contains files to create a simple EasyFlash CRT image and a disk image with access to EasyAPI.\
You'll need the [ACME cross-assembler](https://sourceforge.net/projects/acme-crossass/) binary available on the PATH.\
If you have GNU `make`, just run it. Otherwise you may want to execute the commands from the `Makefile` manually.

## CRT image

It contains the standard start-up code which scans the keyboard for "Run/Stop", "C=" and "Q": If one of these keys is pressed, the cartridge becomes invisible and the Kernal's reset vector is called.\
To create the CRT image, the tool `bin2efcrt` is used. This is invoked with a relative path inside EasySDK. Simply build this tool first and then come back to this example.\
To test the cartridge in a *recent* version of [VICE Emulator](http://vice-emu.sourceforge.net), run `x64 -cartcrt test_crt.crt` or attach it using "File => Attach cartridge image... => CRT Image...". You can also write it to your EasyFlash.

## Disk image

If you make the cartridge invisible at start-up, you can load the first program from the disk image to use EasyAPI.
