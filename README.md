# nix-nageru
A flake to build [Sesse's nageru](https://nageru.sesse.net) for various target systems. 

My target systems are some more modest laptops and SBCs so would be interesting to try this out.

---

## nageru's Readme:

Nageru is a live video mixer, based around the standard M/E workflow.
Futatabi is a multicamera slow motion video server.


Nageru features:

 - High performance on modest hardware (720p60 with two input streams
   on my Thinkpad X240[1]); almost all pixel processing is done on the GPU.

 - High output quality; Lanczos3 scaling, subpixel precision everywhere,
   white balance adjustment, mix of 16- and 32-bit floating point
   for intermediate calculations, dithered output, optional 10-bit input
   and output support.

 - Proper sound support: Syncing of multiple unrelated sources through
   high-quality resampling, multichannel mixing with separate effects
   per-bus, cue out for headphones, dynamic range compression,
   three-band graphical EQ (pluss a fixed low-cut), level meters conforming
   to EBU R128, automation via MIDI controllers.

 - Theme engine encapsulating the design demands of each individual
   event; Lua code is responsible for setting up the pixel processing
   pipelines, running transitions etc., so that the visual look is
   consistent between operators.

 - HTML rendering (through Chromium Embedded Framework), for high-quality
   and flexible overlay or other graphics.

 - Comprehensive monitoring through Prometheus metrics.

[1] For reference, that is: Core i7 4600U (dualcore 2.10GHz, clocks down
to 800 MHz after 30 seconds due to thermal constraints), Intel HD Graphics
4400 (ie., without the extra L4 cache from Iris Pro), single-channel DDR3 RAM
(so 12.8 GB/sec theoretical memory bandwidth, shared between CPU and GPU).


Nageru currently needs:

 - An Intel processor with Intel Quick Sync, or otherwise some hardware
   H.264 encoder exposed through VA-API. Note that you can use VA-API over
   DRM instead of X11, to use a non-Intel GPU for rendering but still use
   Quick Sync (Nageru does this automatically for you if needed).

 - Two or more Blackmagic USB3 or PCI cards, either HDMI or SDI.
   The PCI cards need Blackmagic's own drivers installed. The USB3 cards
   are driven through the “bmusb” driver, using libusb-1.0. If you want
   zerocopy USB, you need libusb 1.0.21 or newer, as well as a recent
   kernel (4.6.0 or newer). Zerocopy USB helps not only for performance,
   but also for stability. You need at least version 0.7.4.

 - Movit, my GPU-based video filter library (https://movit.sesse.net).
   You will need at least version 1.5.2.

 - Qt 5.5 or newer for the GUI.

 - libmicrohttpd for the embedded web server.

 - x264 for encoding high-quality video suitable for streaming to end users.

 - FFmpeg for muxing, and for encoding audio. You will need at least
   version 5.0.

 - Working OpenGL; Movit works with almost any modern OpenGL implementation.
   Nageru has been tested with Intel on Mesa (you want 11.2 or newer, due
   to critical stability bugfixes), and with NVIDIA's proprietary drivers.
   The status of AMD's proprietary drivers is currently unknown.

 - libzita-resampler, for resampling sound sources so that they are in sync
   between sources, and also for oversampling for the peak meter.

 - LuaJIT, for driving the theme engine. You will need at least version 2.1.

 - libjpeg, for encoding MJPEG streams when VA-API JPEG support is not
   available.

 - Protocol Buffers (protobuf), for storing various forms of settings and
   state.

 - Meson, for building.

 - Optional: CEF (Chromium Embedded Framework), for HTML graphics.
   If you build without CEF, the HTMLInput class will not be available from
   the theme. You can get binary downloads of CEF from

     http://opensource.spotify.com/cefbuilds/index.html

   Simply download the right build for your platform (the “minimal” build
   is fine) and add -Dcef_dir=<path>/cef_binary_X.XXXX.XXXX.XXXXXXXX_linux64
   on the meson command line (substituting X with the real version as required).

 - Optional: libsrt, for SRT inputs (by default, Nageru will listen on
   port 9710, although you can change this port on the command line,
   turn it off with --srt-port -1, or turn it off live in the UI).
   SRT can also be used for output in addition to listening for HTTP
   (see --srt-destination). If you build with libsrt, make sure it is not
   linked to OpenSSL, for license reasons.

 - Optional: SVT-AV1, for encoding high-quality video suitable for streaming to
   end users (higher quality than using x264, but not nearly as mature).
   You will need at least version 1.5.0.


Futatabi also needs:

 - A fast GPU with OpenGL 4.5 support (GTX 1080 or similar recommended for
   best quality at HD resolutions, although 950 should work).

 - SQLite, for storing state.


If on Debian bullseye or something similar, you can install everything you need
with:

  apt install qtbase5-dev libqt5opengl5-dev qt5-default \
    pkg-config libmicrohttpd-dev libusb-1.0-0-dev libluajit-5.1-dev \
    libzita-resampler-dev libva-dev libavcodec-dev libavformat-dev \
    libswscale-dev libavresample-dev libmovit-dev libegl1-mesa-dev \
    libasound2-dev libx264-dev libbmusb-dev protobuf-compiler \
    libprotobuf-dev libsqlite3-dev meson libjpeg-dev libsrt-gnutls-dev

Exceptions as of July 2022:

  - Debian does not carry CEF (but it is optional). You can get experimental
    (and not security-supported) CEF Debian packages built for unstable at
    http://storage.sesse.net/cef/, and then configure Nageru with

     meson obj -Dcef_dir=/usr/lib/x86_64-linux-gnu/cef -Dcef_build_type=system -Dcef_no_icudtl=true

  - Debian's SVT-AV1 is too old, so you will need to compile it yourself
    if you wish to use it for streaming.


The patches/ directory contains a patch that helps zita-resampler performance.
It is meant for upstream, but was not in at the time Nageru was released.
It is taken to be by Steinar H. Gunderson <sesse@google.com> (ie., my ex-work
email), and under the same license as zita-resampler itself.

Nageru and Futatabi use Meson to build. For a default build (building both),
type

  meson obj && cd obj && ninja

To start Nageru, just hook up your equipment, and then type “./nageru”.
For Futatabi documentation, please see https://nageru.sesse.net/doc/.

It is strongly recommended to have the rights to run at real-time priority;
it will make the USB3 threads do so, which will make them a lot more stable.
(A reasonable hack for testing is probably just to run it as root using sudo,
although you might not want to do that in production.) Note also that if you
are running a desktop compositor, it will steal significant amounts of GPU
performance. The same goes for PulseAudio.

Nageru will open a HTTP server at port 9095, where you can extract a live
H264+PCM signal in nut mux (e.g. http://127.0.0.1:9095/stream.nut).
It is probably too high bitrate (~25 Mbit/sec depending on content) to send to
users, but you can easily send it around in your internal network and then
transcode it in e.g. VLC. A copy of the stream (separately muxed) will also
be saved live to local disk.

If you have a fast CPU (typically a quadcore desktop; most laptops will spend
most of their CPU on running Nageru itself), you can use x264 for the outgoing
stream instead of Quick Sync; it is much better quality for the same bitrate,
and also has proper bitrate controls. Simply add --http-x264-video on the
command line. (You may also need to add something like "--x264-preset veryfast",
since the default "medium" preset might be too CPU-intensive, but YMMV.)
The stream saved to disk will still be the Quick Sync-encoded stream, as it is
typically higher bitrate and thus also higher quality. Note that if you add
".metacube" at the end of the URL (e.g. "http://127.0.0.1:9095/stream.ts.metacube"),
you will get a stream suitable for streaming through the Cubemap video reflector
(cubemap.sesse.net). A typical example would be:

  ./nageru --http-x264-video --x264-preset veryfast --x264-tune film \
      --http-mux mp4 --http-audio-codec libfdk_aac --http-audio-bitrate 128

If you are comfortable with using all your remaining CPU power on the machine
for x264, try --x264-speedcontrol, which will try to adjust the preset
dynamically for maximum quality, at the expense of somewhat higher delay.

See --help for more information on options in general.

The name “Nageru” is a play on the Japanese verb 投げる (nageru), which means
to throw or cast. (I also later learned that it could mean to face defeat or
give up, but that's not the intended meaning.)

The name “Futatabi” comes from the Japanese adverb 再び (futatabi), which means
“again” or “for the second time”.


Nageru's home page is at https://nageru.sesse.net/, where you can also find
contact information, full documentation and link to the latest version.


Legalese: TL;DR: Everything is GPLv3-or-newer compatible, and see
Intel's copyright license at quicksync_encoder.h.


Nageru is Copyright (C) 2015 Steinar H. Gunderson <steinar+nageru@gunderson.no>.
Portions Copyright (C) 2003 Rune Holm.
Portions Copyright (C) 2010-2015 Fons Adriaensen <fons@linuxaudio.org>.
Portions Copyright (C) 2012-2015 Fons Adriaensen <fons@linuxaudio.org>.
Portions Copyright (C) 2008-2015 Fons Adriaensen <fons@linuxaudio.org>.
Portions Copyright (c) 2007-2013 Intel Corporation. All Rights Reserved.
Portions Copyright (C) 2019 Yngve Molnes.


This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.


Portions of quicksync_encoder.h and quicksync_encoder.cpp:

Copyright (c) 2007-2013 Intel Corporation. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sub license, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice (including the
next paragraph) shall be included in all copies or substantial portions
of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT.
IN NO EVENT SHALL PRECISION INSIGHT AND/OR ITS SUPPLIERS BE LIABLE FOR
ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


All files in decklink/:

Copyright (c) 2009 Blackmagic Design
Copyright (c) 2015 Blackmagic Design

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

#### footnote:
