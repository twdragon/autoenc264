#!/bin/bash
#H.264 encoding script for SATrips and general purpose.

#Default parameters
_version_="0.4.7.7"
commandline=""		#MEncoder command line after parsing of all specified options
commandaud=""		#FAAC standalone command line (if needed)
commandmkv=""		#mkvmerge command line (optional)
sq_opt="level=4.1:cabac=1:ref=12:deblock:analyse=0x3,0x113:me=umh:subme=10:psy=1:me_range=24:chroma_me=1:trellis=1:8x8dct=1:fast_pskip=0:chroma_qp_offset=-2:nr=0:interlaced=0:bframes=16:b_pyramid=2:b_adapt=2:weightp=2:weightb=1:keyint=240:keyint_min=23:constrained_intra=0:b_bias=0:scenecut=40:intra_refresh=0:rc_lookahead=150:mbtree=1:ratetol=1.0:qcomp=0.70:qpmin=4:qpmax=69:qpstep=4:cplxblur=20.0:qblur=0.5:nal_hrd=none:vbv_maxrate=50000:vbv_bufsize=62500"
hq_opt="level=4.1:cabac=1:ref=10:deblock=1,-2,-1:analyse=0x3,0x133:me=umh:subme=10:psy=1:psy_rd=1.00,0.00:me_range=48:chroma_me=1:trellis=2:8x8dct=1:fast_pskip=0:chroma_qp_offset=-2:nr=0:interlaced=0:bframes=12:b_pyramid=2:b_adapt=2:weightp=2:weightb=1:keyint=240:keyint_min=23:constrained_intra=0:b_bias=0:scenecut=40:intra_refresh=0:rc_lookahead=80:mbtree=1:ratetol=1.0:qcomp=0.60:qpmin=10:qpmax=51:qpstep=4:cplxblur=20.0:qblur=0.5:nal_hrd=none:vbv_maxrate=50000:vbv_bufsize=62500"
us_opt=""
add_opt=""		#Additional user defined options for libx264
pass=1
sq_aud="-b 96 -q 100 --tns --mpeg-vers 4 -P -R 48000 -C 2 -X"		#Audio options
hq_aud="-b 160 -q 100 --tns --mpeg-vers 4 -P -R 48000 -C 2 -X"
us_aud=""
def_bitrate=1700	#bitrate setting by default
deffilt="mcdeint,spp,harddup" #for SATrip by default [ mcdeint,spp,harddup ]
defthreads="auto"	#threading model by default
startpos=""		#Start position
endpos=""		#End position
defaudio="pcm"		#Default audio codec setting
defvideo="x264"		#Default video codec setting
addkeys=""		#Additional user specified options
mkv_aspect="16/9"	#Default aspect ratio for MKV rendering
mkv_fps="25p"		#Default FPS for MKV render
mkv_audlang="rus"	#Default MKV audio track name
mkv_file=""		#Default MKV filename

#Parameters defined by user
filt_before=""	#Preprocessing filters
filt_after=""	#Postprocessing filters

#Final parametric strings
filters=""		#Filtering string
out_v="video.264"	#Default outfile
in_v="video.ts"		#Default infile
out_a="audio.mp4"	#Default audio out
tmp_v="_video_"		#Temporary video out
tmp_a="_audio_"		#Temporary audio out

#Return codes (excepting MEncoder and FAAC codes encapsulated):
#		0	All success
#		1	Warnings (in compatibility check mode)
#		2	Terminated with no success (on error)
#		3	Terminated by user request (e. a. output file exists)

#Functions
print_help()
{
	clear
	cat<<EOF

autoenc264 the automated freeware video encoding script for GNU/Linux

===
HELP PAGE
===

Usage: sh autoenc264.sh [options and keys] <input filename>

autoenc264 is an automated script for encoding video files of all FFmpeg sup-
porting formats to muxing-ready raw H.264/AAC streams and [optionally] simple
automated MKV building. Script encodes the specified file in directory where it
is placed in. In addition, usage of any other video and audio codecs could be
achieved through special keys. As the result, the files with both video and au-
dio streams will be rendered separately.
===

REQUIREMENTS
===
	Free disk space		approx. 3x<input file size> on partition where
				directory with autoenc264 is placed.

	Software (for encoding)	MPlayer and MEncoder with libx264 support opti-
				on enabled
				FAAC standalone application

	Software (optional)	mkvmerge
				mediainfo

	File placement		Input file must be placed in the same directory
				than the script to avoid any naming problems
===

OPTIONS OVERVIEW
===
	autoenc264 supports three groups of options: keys (generalized Linux-
style options), general purpose options for process control and expert options
for fine tuning of the encoder. As autoenc264 is a wrap above MEncoder as the
script options represent or redefine some MPlayer/MEncoder options to process
the video. Script has two modes: standard quality mode (SQ) for typical video
recordings such as satellite TV rips or miniDV handycam tapes, and high quality
(HQ) mode for DVD rips or other high quality video sources. When no user over-
rides are set, script selects the video and audio encoding parameters automati-
cally.
	By default autoenc264 renders the temporary AVI file containing both
audio and video streams after encoding. That file would be deleted after stream
dump. But it also can be saved by user request.
===

KEYS
[defaults in brackets after descriptions]
===
Information:
	-c			check system compatibilities
	--check

	-h			print this help page
	--help

	-v			print version info
	--version

	--simulate		enter simulation mode (no encoding, just check
				all encoding options and conditions for report)
I/O:
	-in=<filename>		override default input file name [video.ts]
	-out=<filename>		override default output file name [video.264]

	-aout=<filename>	override default audio output file name
	--audio-out=<filename>	[audio.mp4]

	--audio-dump		set the script to audio dump mode [off]

	-mkv			turn MKV building mode on. File name postfix
	--build-mkv		is <output video file name>_.mkv

	-keep			keep the temporary AVI container on disk for
	--keep-avi		further usage [off]
===

OPTIONS FOR GENERAL PURPOSE
===
	-b=<value>		set the video stream bitrate (kbps) [1700]
	--bitrate=<value>

	-hq			turn HQ mode on. Enables 3-pass encoding [off]
	--high-quality

	-startpos=<secs>	set the starting position and duration of the
	-endpos=<duration>	stream to encode in <secs> or <HH:MM:SS> format

	--filters-override=<X>	set video filtering chain to X [mcdeint,spp,
				harddup]
	--filters-preprocess=	add specified filtering chain BEFORE defaults
	--filters-postprocess=	add specified filtering chain AFTER defaults

	-lanczos		use high-quality interpolation algorithm for
	--use-lanczos		scaling (Lanczos). This option is quite useful
				when 'crop' and 'scale' filters are used. [off,
				uses bicubic algorithm with weight factor 1.00]
===

EXPERT OPTIONS (use at your own risk!)
===
	--use-codec=<codec>	use <codec> (e. a. xvid) instead default H.264
	--audio-codec=<codec>	use <codec> audio encoder (e. a. mp3lame) in-
				stead default PCM

	--use-options=<string>	override default x264 option string
	--add-options=<string>	add <string> to x264 option string
	--audio-options=<opt>	override default FAAC option string with <opt>

	--threads=<X>		set number of encoding threads to <X> [auto]

	--mkv-language=<tag>	set the MKV audio track language <tag> [rus]
	--mkv-aspect=<aspect>	set MKV video stream <aspect> ratio [16/9]
	--mkv-fps=<X>		set MKV framerate and field mode to <X> [25p]

	--add-keys=<keys>	add any user specified keys to MEncoder command
				line. Useful for usage of non-default codecs
===

ROOT OPTIONS (super user privileges needed to use)
===
	-poweroff		halt the system down after encoding
	-reboot			reboot the system after encoding
===

ERROR CODES (excepting MEncoder and FAAC codes encapsulated)
===
	0			All success
	1			Warnings (in compatibility check mode)
	2			Terminated with no success (on error)
	3			Terminated by user request (e. a. output file
				exists)
===

EOF
exit 0
}

check_compatibility()
{
	COMPAT_PASSED=1
	COMPAT_WARN=0
	echo -e "Compatibility check mode is active\n\rRunning tests...\n\r==="
	which mencoder > /dev/null			#MEncoder accessibility
	if [ $? -eq 0 ]
	then
		echo -e "MEncoder\t:\tfound"
	else
		echo -e "MEncoder\t:\tnot found"
		echo -e "ERROR! MEncoder not found! Please install MPlayer or another containing package to obtain MEncoder of the proper version"
		COMPAT_PASSED=0
	fi
	which mplayer > /dev/null			#MPlayer accessibility
	if [ $? -eq 0 ]
	then
		echo -e "MPlayer\t\t:\tfound"
	else
		echo -e "MPlayer\t\t:\tnot found"
		echo -e "ERROR! MPlayer not found! Please install MPlayer or another containing package to obtain MPlayer of the proper version"
		COMPAT_PASSED=0
	fi
	mencoder -ovc help | grep "x264" > /dev/null	#libx264 accessibility
	if [ $? -eq 0 ]
	then
		echo -e "H.264 support\t:\ton"
	else
		echo -e "H.264 support\t:\toff"
		echo -e "ERROR! H.264 encoding support option if turned off. Please consider to recompile MEncoder or to reinstall ffmpeg of compatible build!"
		COMPAT_PASSED=0
	fi
	mencoder -oac help | grep "faac" > /dev/null	#libfaac accessibility
	if [ $? -eq 0 ]
	then
		echo -e "FAAC support\t:\ton"
	else
		echo -e "FAAC support\t:\toff"
		echo -e "WARNING! FAAC support is not accessible through MEncoder!"
		COMPAT_WARN=1
	fi
	which faac > /dev/null				#FAAC standalone accessibility
	if [ $? -eq 0 ]
	then
		echo -e "FAAC standalone\t:\tfound"
	else
		echo -e "FAAC standalone\t:\tnot found"
		echo -e "WARNING! FAAC standalone application is not accessible!"
		COMPAT_WARN=1
	fi
	which mkvmerge > /dev/null			#mkvmerge accessibility
	if [ $? -eq 0 ]
	then
		echo -e "mkvmerge\t:\tfound"
	else
		echo -e "mkvmerge\t:\tnot found"
		echo -e "WARNING! mkvmerge is not accessible. MKV building would be impossible!"
		COMPAT_WARN=1
	fi
	which mediainfo > /dev/null			#mkvmerge accessibility
	if [ $? -eq 0 ]
	then
		echo -e "MediaInfo\t:\tfound"
	else
		echo -e "MediaInfo\t:\tnot found"
	fi
	echo -e "==="
	mencoder -vf help | grep "pullup" > /dev/null	#Filters accessibility: pullup
	if [ $? -eq 0 ]
	then
		echo -e "VF pullup\t:\ton"
	else
		echo -e "VF pullup\t:\toff"
		echo -e "WARNING! Pullup filter is unaccessible. Inverse telecine for interlaced SAT recordings will be impossible"
		COMPAT_WARN=1
	fi
	mencoder -vf help | grep "softskip" > /dev/null	#Filters accessibility: softskip
	if [ $? -eq 0 ]
	then
		echo -e "VF softskip\t:\ton"
	else
		echo -e "VF softskip\t:\toff"
		echo -e "WARNING! Softskip filter is unaccessible. Frame skipping mode for A/V sync will be unaccessible"
		COMPAT_WARN=1
	fi
	mencoder -vf help | grep "harddup" > /dev/null	#Filters accessibility: harddup
	if [ $? -eq 0 ]
	then
		echo -e "VF harddup\t:\ton"
	else
		echo -e "VF harddup\t:\toff"
		echo -e "WARNING! Harddup filter is unaccessible. Frame duplication (hardcoded A/V sync) mode for libavformat-supported video containers will be unaccesible"
		COMPAT_WARN=1
	fi
	mencoder -vf help | grep "spp" > /dev/null	#Filters accessibility: spp
	if [ $? -eq 0 ]
	then
		echo -e "VF spp\t\t:\ton"
	else
		echo -e "VF spp\t\t:\toff"
		echo -e "WARNING! Standard postprocessing filter is unaccessible!"
		COMPAT_WARN=1
	fi
	mencoder -vf help | grep "mcdeint" > /dev/null	#Filters accessibility: mcdeint
	if [ $? -eq 0 ]
	then
		echo -e "VF mcdeint\t:\ton"
	else
		echo -e "VF mcdeint\t:\toff"
		echo -e "WARNING! mcdeint filter is unaccessible! Deinterlacing operation for interlaced TV stream will be unaccessible"
		COMPAT_WARN=1
	fi
	echo -e "==="
	if [ $COMPAT_PASSED -eq 0 ]			#Tests summary
	then
		echo -e "\n\rATTENTION! Compatibility check process was completed with some errors! It is strongly recommended to check all the required software packages are properly installed before you proceed!"
		exit 2
	else
		if [ $COMPAT_WARN -eq 1 ]
		then
			echo -e "\n\rCAUTION! Compatibility check process was completed with some warnings! See the warnings above to avoid possible encoding errors."
			exit 1
		else
			echo -e "NOTE: Compatibility check process has completed successfully. Now it is clear to proceed with encoding."
			exit 0
		fi
	fi
}

#===
print_version()
{
	echo -e "Generic Linux H.264/AAC encoding and MKV building script version "$_version_
	echo -e "Developed for RuTracker.org by twdragon\n\rPublished under GNU GPL license"
	echo -e "Noncommercial media copying is not a crime!\n\r"
	exit 0
}

#===
commandline_build_video()
{
commandline="mencoder "
echo -e "Building command lines...\n\r"
commandline=$commandline" "$in_v" -o "$tmp_v

if [ $_START_SET_ -eq 1 ]
then
	commandline=$commandline" -ss "$startpos
fi
if [ $_END_SET_ -eq 1 ]
then
	commandline=$commandline" -endpos "$endpos
fi

commandline=$commandline" -vf "$filters

commandline=$commandline" -ovc "$defvideo

if [ $_CODEC_OVERRIDE_ -eq 0 ]
then
	if [ $_USER_OPT_OVERRIDE_ -eq 1 ]
	then
		commandline=$commandline" -x264encopts "$us_opt
	else
		if [ $_HIGH_QUALITY_ -eq 1 ]
		then
			commandline=$commandline" -x264encopts "$hq_opt
		else
			commandline=$commandline" -x264encopts "$sq_opt
		fi
	fi
	if [ $_USER_OPT_ADD_ -eq 1 ]
	then
		commandline=$commandline":"$add_opt
	fi
	commandline=$commandline":threads="$defthreads":bitrate="$def_bitrate":pass="$pass
fi

if [ $_USE_LANCZOS_ -eq 1 ]
then
	commandline=$commandline" -sws 9"
fi

commandline=$commandline" -oac "$defaudio

if [ $_USER_KEYS_ADD_ -eq 1 ]
then
	commandline=$commandline" "$addkeys
fi
}

#===

commandline_build_audio()
{
	echo -e "Building audio encoder command line...\n\r"
	commandaud=""
	if [ $_DUMP_AUDIO_ -eq 1 ]
	then
		echo -e "Audio dump mode activated!\n\r"
		commandaud="mplayer "$tmp_v" -vc dummy -vo /dev/null -dumpaudio -dumpfile "$out_a
	else
		echo -e "Audio dump mode is inactive\n\r"
		if [ $_AUDIO_CODEC_OVERRIDE_ -eq 1 ]
		then
			echo -e "FAAC unsupported input audio codec specified!\n\rEntering dump mode..."
			commandaud="mplayer "$tmp_v" -vc dummy -vo /dev/null -dumpaudio -dumpfile "$out_a
		else
			echo -e "FAAC supported audio stream detected\n\rEntering encoding mode...\n\rDumping to temporary file..."
			mplayer $tmp_v -vc dummy -vo /dev/null -dumpaudio -dumpfile $tmp_a
			if [ $_AUDIO_OPT_OVERRIDE_ -eq 1 ]
			then
				commandaud="faac "$us_aud" "$tmp_a" -o "$out_a
			else
				if [ $_HIGH_QUALITY_ -eq 1 ]
				then
					commandaud="faac "$hq_aud" "$tmp_a" -o "$out_a
				else
					commandaud="faac "$sq_aud" "$tmp_a" -o "$out_a
				fi
			fi
		fi
	fi
}

commandline_build_mkv()
{
	echo -e "Building mkvmerge command line...\n\r"
	commandmkv="mkvmerge -o "$mkv_file" --default-track 0:yes --forced-track 0:yes --aspect-ratio 0:"$mkv_aspect
	commandmkv=$commandmkv" --default-duration 0:"$mkv_fps" --compression 0:none -d 0 -A -S -T --no-global-tags"
	commandmkv=$commandmkv" --no-chapters ( "$out_v" ) --language 0:"$mkv_audlang""
	commandmkv=$commandmkv" --default-track 0:yes --forced-track 0:no --compression 0:none -a 0 -D -S -T"
	commandmkv=$commandmkv" --no-global-tags --no-chapters ( "$out_a" ) --track-order 0:0,1:0"
}

#Entrance
echo -e "\n\rautoenc264 v. "$_version_" video encoding utility by twdragon\n\r==="

#Command line parser

_HIGH_QUALITY_=0
_DUMP_AUDIO_=0
_SIMULATION_=0
_MKV_BUILD_=0

_PRE_=0		#Preprocess on
_POST_=0	#Postprocess on

_START_SET_=0	#Start position set
_END_SET_=0	#End position set

_CODEC_OVERRIDE_=0
_FILTERS_OVERRIDE_=0
_AUDIO_CODEC_OVERRIDE_=0
_AUDIO_OUT_OVERRIDE_=0
_AUDIO_OPT_OVERRIDE_=0
_USER_OPT_OVERRIDE_=0
_USER_OPT_ADD_=0
_USER_KEYS_ADD_=0
_USE_LANCZOS_=0
_KEEP_AVI_=0

_REBOOT_AFTER_=0
_POWEROFF_AFTER_=0

echo -e "Parsing options...\n\r"

for opt do
	optarg="${opt#*=}"
	case "$opt" in
		--filters-override=*)		#Full override of the filtering chain
			deffilt="$optarg"
			_FILTERS_OVERRIDE_=1
#			echo -e "Custom filters\t:\ton "$deffilt
		;;
		--filters-preprocess=*)		#User defined preprocessing
			filt_before="$optarg"
#			echo -e "Adding preprocessing filters: "$filt_before"\n\r"
			_PRE_=1
		;;
		--filters-postprocess=*)	#User defined postprocessing
			filt_after="$optarg"
#			echo -e "Adding postprocessing filters: "$filt_after"\n\r"
			_POST_=1
		;;
		-c)					#Check for compatibilities
			check_compatibility
		;;
		--check)				#Check for compatibilities mode 2
			check_compatibility
		;;
		-in=*)					#Infile specification
			in_v="$optarg"
		;;
		-out=*)					#Outfile specification
			out_v="$optarg"
		;;
		-hq)					#High quality mode
			_HIGH_QUALITY_=1
		;;
		--high-quality)				#High quality mode 2
			_HIGH_QUALITY_=1
		;;
		-b=*)					#Bitrate setting
			def_bitrate="$optarg"
		;;
		--bitrate=*)				#Bitrate setting 2
			def_bitrate="$optarg"
		;;
		-aout=*)				#Audio output file
			out_a="$optarg"
			_AUDIO_OUT_OVERRIDE_=1
		;;
		--audio-out=*)				#Audio output file 2
			out_a="$optarg"
			_AUDIO_OUT_OVERRIDE_=1
		;;
		--audio-dump)				#Dump audio without AAC encoding
			_DUMP_AUDIO_=1
		;;
		--threads=*)				#Threading model specification
			defthreads="$optarg"
		;;
		-startpos=*)				#Start and end points positioning
			startpos="$optarg"
			_START_SET_=1
		;;
		-endpos=*)
			endpos="$optarg"
			_END_SET_=1
		;;
		--audio-codec=*)			#Use user specified audio codec instead of standard PCM
			defaudio="$optarg"
			_AUDIO_CODEC_OVERRIDE_=1
		;;
		--audio-options=*)			#Override FAAC options with user specified option string
			us_aud="$optarg"
			_AUDIO_OPT_OVERRIDE_=1
		;;
		--use-codec=*)				#Use user specified video codec instead of standard libx264
			defvideo="$optarg"
			_CODEC_OVERRIDE_=1
		;;
		--use-options=*)			#Override default libx264 option string by user specified one
			us_opt="$optarg"
			_USER_OPT_OVERRIDE_=1
		;;
		--add-options=*)			#Use an additional option string for libx264
			add_opt="$optarg"
			_USER_OPT_ADD_=1
		;;
		--add-keys=*)				#Add any needed keys to the encoder command line
			addkeys="$optarg"
			_USER_KEYS_ADD_=1
		;;
		-keep)					#Keep an AVI temporary container
			_KEEP_AVI_=1
		;;
		--keep-avi)
			_KEEP_AVI_=1
		;;
		--use-lanczos)				#Use high-quality scaling algorhythm
			_USE_LANCZOS_=1
		;;
		-lanczos)
			_USE_LANCZOS_=1
		;;
		--simulate)				#Simulate only (info mode with no encoding)
			_SIMULATION_=1
		;;
		-v)					#Print current version
			print_version
		;;
		--version)
			print_version
		;;
		-mkv)					#Render an output as MKV (Matroska)
			_MKV_BUILD_=1
		;;
		--build-mkv)
			_MKV_BUILD_=1
		;;
		--mkv-language=*)			#Audio track language for MKV
			if [ $_MKV_BUILD_ -eq 0 ]
			then
				echo -e "--mkv-language - option ignored: MKV building mode is not enabled!\n\r"
			fi
			mkv_audlang=$optarg
		;;
		--mkv-aspect=*)
			if [ $_MKV_BUILD_ -eq 0 ]
			then
				echo -e "--mkv-aspect - option ignored: MKV building mode is not enabled!\n\r"
			fi
			mkv_aspect=$optarg
		;;
		--mkv-fps=*)
			if [ $_MKV_BUILD_ -eq 0 ]
			then
				echo -e "--mkv-fps - option ignored: MKV building mode is not enabled!\n\r"
			fi
			mkv_fps=$optarg
		;;
		-h)					#Print help page
			print_help
		;;
		--help)
			print_help
		;;
		-poweroff)				#Power off after encoding
			_POWEROFF_AFTER_=1
		;;
		-reboot)				#Reboot after encoding
			_REBOOT_AFTER_=1
		;;
		*)					#Input filename override
			in_v=$opt
		;;
	esac
done

if [ $_SIMULATION_ -eq 1 ]
then
	echo -e "Simulation mode activated!\n\rBeginning simulation...\n\r==="
fi
echo -e ""
#Filtering chain definition
if [ $_FILTERS_OVERRIDE_ -eq 1 ]
then
	echo -e "Building filtering chain (!to override defaults!)...\n\r==="
else
	echo -e "Building filtering chain (from defaults)...\n\r==="
fi
if [ $_PRE_ -eq 1 ]
then
	filters=""$filt_before","$deffilt
	echo -e "\tPreprocessing\t:\ton"
else
	filters=$deffilt
	echo -e "\tPreprocessing\t:\toff"
fi
if [ $_POST_ -eq 1 ]
then
	filters=""$filters","$filt_after
	echo -e "\tPostprocessing\t:\ton"
else
	echo -e "\tPostprocessing\t:\toff"
fi
echo -e "===\n\rFinal filtering chain: "$filters"\n\r"

#Input and output stream setting
echo -e "Loading files...\n\r==="
ls | grep -x "$in_v" > /dev/null
if [ $? -eq 0 ]
then
	echo -e "FOUND\tInput stream\t:\t"$in_v
	echo -e "\tOutput stream\t:\t"$out_v
else
	echo -e "EMPTY\tInput stream\t:\t"$in_v
	echo -e "\tOutput stream\t:\t"$out_v
	echo -e "===\n\r"
	echo -e "ERROR! Input file not found!"
	exit 2
fi
ls | grep -x "$out_v" > /dev/null
if [ $? -eq 0 ]
then
	echo -e "NOTE: the specified output file exists. It will be overwrited if you proceed. Do you really want to overwrite the file?"
	read _ANSWER_
	echo -e "$_ANSWER_" | grep "n" > /dev/null
	if [ $? -eq 0 ]
	then
		echo -e "Operation terminated.\n\rExiting..."
		exit 3
	fi
fi
if [ $_DUMP_AUDIO_ -eq 0 ]
then
	ls | grep -x "$out_a" > /dev/null
	if [ $? -eq 0 ]
	then
		echo -e "FOUND\tAudio output\t:\t"$out_a
		echo -e "NOTE: the specified output audio file exists. It will be overwrited if you proceed. Do you really want to overwrite the file?"
		read _ANSWER_
		echo -e "$_ANSWER_" | grep "n" > /dev/null
		if [ $? -eq 0 ]
		then
			echo -e "Operation terminated.\n\rExiting..."
			exit 3
		fi
	else
		echo -e "EMPTY\tAudio output\t:\t"$out_a
	fi
echo -e "===\n\r"
fi

#Threading model
echo -e "$defthreads" | grep "auto" > /dev/null
if [ $? -eq 0 ]
then
	echo -e "Setting codec threading model: "$defthreads"\n\r"
else
	echo -e "Setting codec threading model: noauto [threads="$defthreads"]\n\r"
fi

#Positioning
echo -e "Positioning input stream...\n\r==="
if [ $_START_SET_ -eq 0 ]
then
	echo -e "\tStart encoding\t:\tat first frame"
else
	echo -e "\tStart encoding\t:\tat point [-ss "$startpos"]"
fi
if [ $_END_SET_ -eq 0 ]
then
	echo -e "\tTerminate\t:\tat last frame"
else
	echo -e "\tTerminate\t:\tat point [-endpos "$endpos"]"
fi
echo -e "===\n\r"

#Codec setup
echo -e "Loading encoder information and options...\n\r==="
if [ $_CODEC_OVERRIDE_ -eq 1 ]
then
	echo -e "\tVideo codec\t:\tuser specified [-ovc "$defvideo"]"
	echo -e "\t"$defvideo" options\t:\tassistance needed [use '--add-keys' option]"
else
	echo -e "\tVideo codec\t:\tdefault [-ovc "$defvideo"]"
	if [ $_USER_OPT_OVERRIDE_ -eq 1 ]
	then
		echo -e "\tH.264 options\t:\tuser specified [-x264encopts "$us_opt"]"
	else
		if [ $_HIGH_QUALITY_ -eq 1 ]
		then
			echo -e "\tH.264 options\t:\thigh quality mode [-x264encopts "$hq_opt"]"
		else
			echo -e "\tH.264 options\t:\tstandard quality mode [-x264encopts "$sq_opt"]"
		fi
		if [ $_USER_OPT_ADD_ -eq 1 ]
		then
			echo -e "\tAdditional\t:\t"$add_opt
		else
			echo -e "\tAdditional\t:\toff"
		fi
	fi
	echo -e "\tVideo bitrate\t:\t"$def_bitrate" kbps"
fi

if [ $_USE_LANCZOS_ -eq 1 ]
then
	echo -e "\tLanczos scaling\t:\tyes"
else
	echo -e "\tLanczos scaling\t:\tno"
fi
echo -e ""
if [ $_DUMP_AUDIO_ -eq 1 ]
then
	echo -e "\tAudio codec\t:\tstream dump mode ["$defaudio"]"
else
	if [ $_AUDIO_CODEC_OVERRIDE_ -eq 1 ]
	then
		echo -e "\tAudio codec\t:\tuser specified [-oac "$defaudio"]"
		echo -e "\tAudio options\t:\tassistance needed [use '--add-keys' option]"
	else
		echo -e "\tAudio codec\t:\tdefault for FAAC encoding [-oac "$defaudio"]"
		if [ $_AUDIO_OPT_OVERRIDE_ -eq 1 ]
		then
			echo -e "\tFAAC options\t:\tuser defined [faac "$us_aud"]"
		else		
			if [ $_HIGH_QUALITY_ -eq 1 ]
			then
				echo -e "\tFAAC options\t:\thigh quality mode [faac "$hq_aud"]"
			else
				echo -e "\tFAAC options\t:\tstandard quality mode [faac "$sq_aud"]"
			fi
		fi
	fi
fi
echo -e "===\n\r"

#MKV building setup
if [ $_MKV_BUILD_ -eq 1 ]
then
	echo -e "Setting up MKV builder...\n\r==="
	mkv_file=$out_v"_.mkv"
	ls | grep "$mkv_file" > /dev/null
	if [ $? -eq 0 ]
	then
		echo -e "FOUND\tMKV file name\t:\t"$mkv_file
		echo -e "NOTE: the specified output file exists. It will be overwrited if you proceed. Do you really want to overwrite the file?"
		read _ANSWER_
		echo -e "$_ANSWER_" | grep "n" > /dev/null
		if [ $? -eq 0 ]
		then
			echo -e "Operation terminated.\n\rExiting..."
			exit 3
		fi
	else
		echo -e "EMPTY\tMKV file name\t:\t"$mkv_file
	fi

	echo -e "\tAudio language\t:\t"$mkv_audlang
	echo -e "\tAspect ratio\t:\t"$mkv_aspect
	echo -e "\tFrame rate\t:\t"$mkv_fps
	echo -e "===\n\r"
fi

if [ $_SIMULATION_ -eq 1 ]
then
	echo -e "Simulation mode activated. Info is given.\n\rSimulation ends...\n\r"
	exit 3
fi

#Command line builds
commandline_build_video
echo -e "Command line for MEncoder has successfully built!\n\r===\n\r'"$commandline"'\n\r===\n\r"

#Encoding
echo -e "Running video encoder...\n\r==="
if [ $_CODEC_OVERRIDE_ -eq 0 ]
then
	if [ $_HIGH_QUALITY_ -eq 1 ]
	then
		time $commandline
		echo -e "===\n\rHigh quality mode: 1st pass completed!\n\r==="
		pass=3
		commandline_build_video
		time $commandline
		echo -e "===\n\rHigh quality mode: 2nd pass completed!\n\r==="
		time $commandline
		echo -e "===\n\rHigh quality mode: 3rd pass completed!\n\r==="
	else
		time $commandline
		echo -e "===\n\rStandard quality mode: 1st pass completed!\n\r==="
		pass=2
		commandline_build_video
		time $commandline
		echo -e "===\n\rStandard quality mode: 2nd pass completed!\n\r==="
	fi
else
	time $commandline
	echo -e "===\n\rExternal encoder mode: encoding completed!\n\r==="
fi

#Dumps
echo -e "\n\rDumping audio...\n\r==="
commandline_build_audio
echo -e "Command line for audio encoder has successfully built!\n\r===\n\r'"$commandaud"'\n\r===\n\r"
echo -e "Running audio encoder...\n\r==="
time $commandaud
ls | grep -x "$tmp_a" > /dev/null
if [ $? -eq 0 ]
then
	echo -e "Flushing temporarities..."
	rm "$tmp_a"
fi
echo -e "===\n\rAudio encoding process completed!\n\r"

echo -e "Dumping video...\n\r==="
if [ $_CODEC_OVERRIDE_ -eq 0 ]
then
	mplayer $tmp_v -dumpvideo -dumpfile $out_v
	ls | grep -x "$tmp_v" > /dev/null
	if [ $? -eq 0 ]
	then
		if [ $_KEEP_AVI_ -eq 0 ]
		then
			echo -e "Flushing temporarities..."
			rm "$tmp_v"
		fi
	fi
else
	echo -e "Flushing temporarities..."
	mv "$tmp_v" "$out_v"
fi
echo -e "===\n\r"
echo -e "Process completed!\n\rVideo stream is now ready for container building!\n\r"

#MKV builder
if [ $_MKV_BUILD_ -eq 1 ]
then
	echo -e "Trying to build an MKV containment...\n\r==="
	commandline_build_mkv
	echo -e "Command line for mkvmerge has successfully built!\n\r===\n\r'"$commandmkv"'\n\r===\n\r"
	echo -e "Running muxer...\n\r==="
	time $commandmkv
	echo -e "===\n\r"
	echo -e "MKV built!\n\rFlushing temporarities..."
	rm "$out_v"
	rm "$out_a"
fi

#Ending
echo -e "\n\rProcessing completed!\n\rExiting core..."
if [ $_POWEROFF_AFTER_ -eq 1 ]
then
	poweroff
fi
if [ $_REBOOT_AFTER_ -eq 1 ]
then
	shutdown -r now
fi
exit 0
