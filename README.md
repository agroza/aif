# Audio Interface

This project is also known as ```aif```.

## Synopsis
This repository contains the MS-DOS driver source code for my DIY [ISA Audio Interface](http://www.alexandrugroza.ro/microelectronics/system-design/isa-audio-interface/index.html) card that you cand find on the [Microelectronics](http://www.alexandrugroza.ro/microelectronics/index.html) page on my site.

The program allows the setup and initialization of the audio interface hardware while also providing a stereo volume mixer. I programmed all this into one single MS-DOS executable file of roughly 45 Kb. If this file is further compressed, then its size decreases to about 20 Kb. Which is pretty much awesome.

![Audio Interface](https://github.com/agroza/aif/blob/master/images/isa-audio-interface-driver1.jpg?raw=true)

Since this kind of hardware is well out of marketing purposes (my design is not for sale) and the datasheets are extensively describing how the software should be written, I believe there is no trade secret to program such a driver. Thus I am releasing my work under the GNU General Public License v3.0 terms and conditions, for educational and documentation purposes.

![Audio Interface](https://github.com/agroza/aif/blob/master/images/isa-audio-interface-driver2.jpg?raw=true)

I used the Pascal programming language and I wrote time-critical routines in assembly language. Initially I inspected the optimized OPTi 82c929 driver programmed by [Jan Knipperts](https://github.com/JKnipperts), thinking that I could do a quick and dirty adaptation. But I think that if it worth the effort to design all the hardware, then it definitely worths to do the software as well. So I quickly decided to write everything on my own.

![Audio Interface](https://github.com/agroza/aif/blob/master/images/isa-audio-interface-driver3.jpg?raw=true)

Thankfully the datasheets are very verbose in terms of register descriptions and principles of operation. I ended up using some of Jan's code for the Sound Blaster Pro interface and MPU-401 initialization -- thanks for allowing me to use your code! I had to rewrite large portions of that code to adapt it to my project. Furthermore I removed everything else that I wasn't planning to use while optimizing the remaining stuff.

### Program Usage

The following lines are taken directly from the commandline help screen.

```
Usage is:
  aif.exe [-help] [-setup] [-pnpsetup] [-mixer] [-init | -wss | -sb]
    [-quiet] [-status] [-lineout=on|off]

Where:
  -help     shows this screen; all other parameters are ignored
  -setup    starts the setup program; all other parameters are ignored
  -mixer    starts the volume mixer program
  -init     initializes the audio interface to preset mode
  -wss      initializes the audio interface to Windows Sound System mode
  -sb       initializes the audio interface to Sound Blaster mode
  -quiet    reduces text verbosity
  -status   displays the current audio interface configuration
  -lineout  enables or disabled line out; some parameters are ignored

Examples:
  aif.exe -init
  aif.exe -mixer -init -quiet -status
```
