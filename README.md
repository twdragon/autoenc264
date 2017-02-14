# autoenc264
automated freeware video encoding script for GNU/Linux

Usage: `./autoenc264.sh [options and keys] [input filename]`
`autoenc264` is an automated script for encoding video files of all FFmpeg-supported formats to muxing-ready raw H.264/AAC streams and [optionally] simple automated MKV building. Script encodes the specified file in directory where it
is placed in. In addition, usage of any other video and audio codecs could be achieved through special keys. As the result, the files with both video and audio streams will be rendered separately.

REQUIREMENTS
===
- Free disk space  approx. 3x(input file size) on partition where directory with autoenc264 is placed.
- Software (for encoding):
	- MPlayer and MEncoder with libx264 support option enabled
	- FAAC standalone application
- Software (optional):
	- mkvmerge
	- mediainfo
- File placement:
	- Input file must be placed in the same directory
    than the script to avoid any naming problems

OPTIONS OVERVIEW
===
`autoenc264` supports three groups of options: **keys** (generalized Linux-
style options), **general purpose options** for process control and **expert options**
for fine tuning of the encoder. As autoenc264 is a wrap above MEncoder as the
script options represent or redefine some MPlayer/MEncoder options to process
the video. 

Script has two modes: standard quality mode (SQ) for typical video
recordings such as satellite TV rips or miniDV handycam tapes, and high quality
(HQ) mode for DVD rips or other high quality video sources. When no user over-
rides are set, script selects the video and audio encoding parameters automati-
cally.

 By default autoenc264 renders the temporary AVI file containing both
audio and video streams after encoding. That file would be deleted after stream
dump. But it also can be saved by user request.

KEYS [default values shown in brackets]
===
## Information:
- `-c --check` - check system compatibilities
- `-h --help` - print help page
- `-v --version` -print version info
- `--simulate` - enter simulation mode (no encoding, just check
    all encoding options and conditions for report)
		
## I/O:
- `-in=<filename>` - overrides default input file name [video.ts]
- `-out=<filename>` - overrides default output file name [video.264]
- `-aout=<filename> --audio-out=<filename>` - overrides default audio output file name [audio.mp4]
- `--audio-dump` - sets the script to audio dump mode [off]
- `-mkv --build-mkv` - turns MKV building mode on. File name postfix is `<output video file name>_.mkv`
- `-keep --keep-avi` - keeps the temporary AVI container on disk for further usage [off]

## General Purpose options:
- `-b=<value> --bitrate=<value>` - sets the video stream bitrate (kbps) [1700]
- `-hq --high-quality` - turns HQ mode on. Enables 3-pass encoding [off]
- `-startpos=<secs> -endpos=<duration>` - sets the starting position and duration of the stream to encode in `<secs>` or `<HH:MM:SS>` format
- `--filters-override=<X>` - sets video filtering chain to X [mcdeint,spp,harddup]
- `--filters-preprocess=<X>` - adds specified filtering chain BEFORE defaults
- `--filters-postprocess=<X>` add specified filtering chain AFTER defaults
- `-lanczos --use-lanczos` uses high-quality interpolation algorithm for scaling (Lanczos). This option is quite useful when `crop` and `scale` filters are used. [off, uses bicubic algorithm with 1.00 weight factor]

EXPERT OPTIONS (use at your own risk!)
===
- `--use-codec=<codec>` - uses `<codec>` (e. a. xvid) instead default H.264
- `--audio-codec=<codec>`- uses `<codec>` audio encoder (e. a. mp3lame) instead default PCM
- `--use-options=<string>` - overrides default x264 option string
- `--add-options=<string>` - adds `<string>` to x264 option string
- `--audio-options=<opt>` overrides default FAAC option string with `<opt>`
- `--threads=<X>` - sets number of encoding threads to `<X>` [auto]
- `--mkv-language=<tag>` sets the MKV audio track language `<tag>` [rus]
- `--mkv-aspect=<aspect>` sets MKV video stream `<aspect>` ratio [16/9]
- `--mkv-fps=<X>` - sets MKV framerate and field mode to `<X>` [25p]
- `--add-keys=<keys>` adds any user specified keys to MEncoder command line. Useful for usage of non-default codecs

ROOT OPTIONS (super user privileges needed to use)
===
- `-poweroff` - halts the system down when encoding ends
- `-reboot` - reboots the system when encoding ends

ERROR CODES (excepting MEncoder and FAAC codes encapsulated)
===
0. Success
1. Warnings (in compatibility check mode)
2. Terminated with no success (on error)
3. Terminated by user request (e. a. output file exists)

