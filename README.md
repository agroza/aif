# aif

Audio Interface Program

## Synopsis
This repository contains the MS-DOS(R) AIF driver source code for my DIY [ISA Audio Interface](http://www.alexandrugroza.ro/microelectronics/system-design/isa-audio-interface/index.html) card that you can find on the [Microelectronics](http://www.alexandrugroza.ro/microelectronics/index.html) page on my site.

The program allows the setup and initialization of the audio interface hardware while also providing a stereo volume mixer. In addition, there is the CD Player feature. I programmed all this into one single MS-DOS executable file of roughly 58 Kb. If this file is further compressed, then its size decreases to about 27 Kb. Which is pretty much awesome.

Since this kind of hardware is well out of marketing purposes (my design is not for sale) and the datasheets extensively describe how the software should be written, I believe there is no trade secret to programming such a driver. Thus, I am releasing my work under the GNU General Public License v3.0 terms and conditions, for educational and documentation purposes.

I used the Pascal programming language and I wrote time-critical routines in assembly language. Initially, I inspected the optimized OPTi 82c929 driver programmed by [Jan Knipperts](https://github.com/JKnipperts), thinking that I could do a quick and dirty adaptation. But I think that if it is worth the effort to design all the hardware, then it is definitely worth doing the software as well. So I quickly decided to write everything on my own.

Thankfully, the datasheets are very verbose in terms of register descriptions and principles of operation. I ended up using some of Jan's code for the Sound Blaster Pro interface and MPU-401 initialization -- thanks for allowing me to use your code! I had to rewrite large portions of that code to adapt it to my project. Furthermore, I removed everything else that I wasn't planning to use while optimizing the remaining stuff. In the end, I wrote everything from scratch.

Here are some pictures of the software, starting with the initialization screen.

![Audio Interface](https://github.com/agroza/aif/blob/master/images/isa-audio-interface-driver1.jpg?raw=true)

The embedded Setup sub-program looks like this.

![Audio Interface](https://github.com/agroza/aif/blob/master/images/isa-audio-interface-driver2.jpg?raw=true)

And finally the embedded Mixer sub-program appears like this.

![Audio Interface](https://github.com/agroza/aif/blob/master/images/isa-audio-interface-driver3.jpg?raw=true)

The VersaVision framework evolved a bit in the last 25 years of existence.

![Audio Interface](https://github.com/agroza/aif/blob/master/images/isa-audio-interface-driver4.jpg?raw=true)

The CD Player sub-program was introduced in 2025.

![Audio Interface](https://github.com/agroza/aif/blob/master/images/isa-audio-interface-driver5.jpg?raw=true)

I had a lot of fun programming this driver. And I remembered the chaos of procedural programming. I also tried to keep global variables to a minimum.
I (re-)learned a lot of (forgotten) programming tricks in the process, and refreshed my memories from the early 1990s.

### Spin-off Software

Working on AIF triggered me to develop another computer program ([DISPLAY.COM](https://github.com/agroza/display/)), something that I've been thinking of since 1994 or so.

To improve the program versioning, I finally invested time into defining a version structure. Then I programed my own commandline tool that automatically increments the build number in a specific ```version.inc``` file. This program is called [UVERSION.EXE](#) and will soon be available to the public.
I added it to the Borland Pascal 7.0 Tools menu, with its own keyboard shortcut (Shift+F10). I run it before each full rebuild. I wish there was a way to run it automatically before a full rebuild command.

And finally, I found motivation to write official documentation for my programs, starting with ```AIF```, of course.

### Program Usage

The following lines are taken directly from the commandline help screen.

```
Usage is:
  aif.exe [-?|-help] [-romsetup] [-pnpsetup] [-setup] [-mixer]
     [-lineout=on|off] [-noinit|-init|-wss|-sb] [-quiet] [-cdplayer] [-status]

Where:
  -?|-help  shows this screen; ignores other parameters
  -romsetup starts the (EEP)ROM setup sub-program; ignores other parameters
  -pnpsetup starts the PnP setup sub-program; ignores other parameters
  -setup    starts the setup sub-program
  -mixer    starts the volume mixer sub-program
  -lineout  enables or disables line out relay
  -noinit   skips the audio interface initialization sequence
  -init     initializes the audio interface to preset mode
  -wss      initializes the audio interface to Windows Sound System mode
  -sb       initializes the audio interface to Sound Blaster mode
  -status   displays the current audio interface configuration
  -cdplayer starts the CD player sub-program
  -quiet    reduces text verbosity

Examples:
  aif.exe -init
  aif.exe -mixer -init -quiet -status
```
