# R1Delta Installer

Automatically detects Titanfall's installation directory and installs R1Delta.

## Setup
* Copy ``config.cmd.example`` to ``config.cmd``.
* Edit ``config.cmd`` with the required dependency paths.
* Run ``build.bat`` to package the installer. The executable will be generated in ``./bin/r1delta_installer.exe``.

## Dependencies
* [Love2D 12.0](https://github.com/love2d/megasource) (Currently in beta, you need to compile it yourself)
* [7-Zip](https://www.7-zip.org/) and [SFX modules from the LZMA SDK](https://www.7-zip.org/sdk.html)(download the SDK, copy ``/bin/7z*.sfx`` to the 7-Zip install directory)
* [Resource Hacker](https://www.angusj.com/resourcehacker/)

## Acknowledgments
This project uses 7-Zip SFX and Love2D, and would not be possible without them.