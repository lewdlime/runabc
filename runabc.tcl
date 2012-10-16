#package provide app-runabc 1.0

#!/bin/sh
# the next line restarts using wish \
exec wish8.5 "$0" "$@"
#
# runabc.tcl - by seymour.shlien@crc.ca
# This is graphics user interface to the abc2midi and abc2ps programs.
# This script and the above programs are public domain.
# multiple select by ste_mi@yahoo.com
#

# runabc.tcl: a graphical user interface to abcMIDI and other packages
#
# Copyright (C) 1998-2011 Seymour Shlien
#
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# Original page:
#      http://ifdo.pugmarks.com/~seymour/runabc/top.html


set runabc_version 1.751
set runabc_date "(September 04  2012 08:35)"
set tcl_version [info tclversion]
set startload [clock clicks -milliseconds]
#lappend auto_path /usr/share/tcltk/tk8.5

package require Tk
if {[catch {package require Ttk} error]} {
    puts $error
    puts "I am looking for this package in $auto_path"
    puts "Be sure you are running Tcl/Tk 8.5 or higher"
}

# Part 1.0                Tooltip
# Part 2.0                Start up
# Part 3.0                images
# Part 4.0                Control Buttons
# Part 5.0                TOC
# Part 6.0                Core Functions
# Part 7.0                TOC creator
# Part 8.0                Extract Tune
# Part 9.0                Functions for Manipulating abc tune file
# Part 10.0               Abc Editor Functions
# Part 10.1		  Bar Picker
# Part 10.2               Guitar Chord ToolBox
# Part 10.3               Transposition ToolBox
# Part 10.4               Note Length ToolBox
# Part 10.5               Editor Clean Functions
# Part 10.6               Process Editor Buffer
# Part 10.7               Grace Notes Toolbox
# Part 10.8               Chords ToolBox
# Part 11.0               Show Summary Sheet ,tmpfile and message sheet
# Part 12.0               Property Sheets -- titles, voice, style, abc2abc, midi2abc etc
# Part 13.0               Help texts
# Part 14.0               Drum Editor
# Part 15.0               Title Search functions
# Part 16.0               Abcmatcher interface
# Part 17.0               Grouper interface
# Part 18.0               Diagnostic Support Functions
# Part 19.0               Abc Editor Filter functions
# Part 20.0               Bar Alignment
# Part 21.0               Console Page Support Functions
# Part 22.0               Midi2abc interface
# Part 23.0               Voice Support Functions for midi2abc
# Part 24.0               Chord substitution functions for Abc Editor
# Part 25.0               Midishow
# Part 26.0               Midi Statistics for Midishow
# Part 27.0               Graphics Namespace
# Part 28.0               File type registration
# Part 29.0               Mftext interface
# Part 30.0               Incipits file support functions
# Part 31.0               Beat Graph and Unique Chords for Midishow
# Part 32.0               Solfege vocalization for abc editor
# Part 33.0               Drum Editor
# Part 34.0               Gchord to voice
# Part 35.0               Drum to voice
# Part 36.0		  Refactor



# Important global variables:
# midi() -- array storing states in runabc.ini
# df             font
# abc_open       file name path of input abc file
# active_sheet   property sheet overlain on main window
# exec_out       passes output messages from executables
# fileseek       byte position of each tune in abc file
# keyorder       CDEFGAB
# keymap         flat and sharps map
# gchordtypes    aug dim  maj7 etc.
# m(1)-m(16)     names of 128 Midi programs
# drumpatches    names of percussion instruments
# note(0)-(11)   C C# D etc.

#  Graphical User Interface


# Part 1.0                Tooltip


# tooltip.tcl --
#
#       Balloon help
#
# Copyright (c) 1996-2003 Jeffrey Hobbs
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# RCS: @(#) $Id: tooltip.tcl,v 1.5 2005/11/22 00:55:07 hobbs Exp $
#
# Initiated: 28 October 1996


package require Tk 8.5
package provide tooltip 1.1


#------------------------------------------------------------------------
# PROCEDURE
#	tooltip::tooltip
#
# DESCRIPTION
#	Implements a tooltip (balloon help) system
#
# ARGUMENTS
#	tooltip <option> ?arg?
#
# clear ?pattern?
#	Stops the specified widgets (defaults to all) from showing tooltips
#
# delay ?millisecs?
#	Query or set the delay.  The delay is in milliseconds and must
#	be at least 50.  Returns the delay.
#
# disable OR off
#	Disables all tooltips.
#
# enable OR on
#	Enables tooltips for defined widgets.
#
# <widget> ?-index index? ?-item id? ?message?
#	If -index is specified, then <widget> is assumed to be a menu
#	and the index represents what index into the menu (either the
#	numerical index or the label) to associate the tooltip message with.
#	Tooltips do not appear for disabled menu items.
#	If message is {}, then the tooltip for that widget is removed.
#	The widget must exist prior to calling tooltip.  The current
#	tooltip message for <widget> is returned, if any.
#
# RETURNS: varies (see methods above)
#
# NAMESPACE & STATE
#	The namespace tooltip is used.
#	Control toplevel name via ::tooltip::wname.
#
# EXAMPLE USAGE:
#	tooltip .button "A Button"
#	tooltip .menu -index "Load" "Loads a file"
#
#------------------------------------------------------------------------

namespace eval ::tooltip {
    namespace export -clear tooltip
    variable tooltip
    variable G
    
    array set G {
        enabled		1
        DELAY		500
        AFTERID		{}
        LAST		-1
        TOPLEVEL	.__tooltip__
    }
    
    # The extra ::hide call in <Enter> is necessary to catch moving to
    # child widgets where the <Leave> event won't be generated
    bind Tooltip <Enter> [namespace code {
        #tooltip::hide
        variable tooltip
        variable G
        set G(LAST) -1
        if {$G(enabled) && [info exists tooltip(%W)]} {
            set G(AFTERID) \
                    [after $G(DELAY) [namespace code [list show %W $tooltip(%W) cursor]]]
        }
    }]
    
    bind Menu <<MenuSelect>>	[namespace code { menuMotion %W }]
    bind Tooltip <Leave>	[namespace code hide]
    bind Tooltip <Any-KeyPress>	[namespace code hide]
    bind Tooltip <Any-Button>	[namespace code hide]
}

proc ::tooltip::tooltip {w args} {
    variable tooltip
    variable G
    switch -- $w {
        clear	{
            if {[llength $args]==0} { set args .* }
            clear $args
        }
        delay	{
            if {[llength $args]} {
                if {![string is integer -strict $args] || $args<50} {
                    return -code error "tooltip delay must be an\
                            integer greater than 50 (delay is in millisecs)"
                }
                return [set G(DELAY) $args]
            } else {
                return $G(DELAY)
            }
        }
        off - disable	{
            set G(enabled) 0
            hide
        }
        on - enable	{
            set G(enabled) 1
        }
        default {
            set i $w
            if {[llength $args]} {
                set i [uplevel 1 [namespace code "register [list $w] $args"]]
            }
            set b $G(TOPLEVEL)
            if {![winfo exists $b]} {
                toplevel $b -class Tooltip
                if {[tk windowingsystem] eq "aqua"} {
                    ::tk::unsupported::MacWindowStyle style $b help none
                } else {
                    wm overrideredirect $b 1
                }
                wm positionfrom $b program
                wm withdraw $b
                label $b.label -highlightthickness 0 -relief solid -bd 1 \
                        -background lightyellow -fg black
                pack $b.label -ipadx 1
            }
            if {[info exists tooltip($i)]} { return $tooltip($i) }
        }
    }
}

proc ::tooltip::register {w args} {
    variable tooltip
    set key [lindex $args 0]
    while {[string match -* $key]} {
        switch -- $key {
            -index	{
                if {[catch {$w entrycget 1 -label}]} {
                    return -code error "widget \"$w\" does not seem to be a\
                            menu, which is required for the -index switch"
                }
                set index [lindex $args 1]
                set args [lreplace $args 0 1]
            }
            -item	{
                set namedItem [lindex $args 1]
                if {[catch {$w find withtag $namedItem} item]} {
                    return -code error "widget \"$w\" is not a canvas, or item\
                            \"$namedItem\" does not exist in the canvas"
                }
                if {[llength $item] > 1} {
                    return -code error "item \"$namedItem\" specifies more\
                            than one item on the canvas"
                }
                set args [lreplace $args 0 1]
            }
            default	{
                return -code error "unknown option \"$key\":\
                        should be -index or -item"
            }
        }
        set key [lindex $args 0]
    }
    if {[llength $args] != 1} {
        return -code error "wrong \# args: should be \"tooltip widget\
                ?-index index? ?-item item? message\""
    }
    if {$key eq ""} {
        clear $w
    } else {
        if {![winfo exists $w]} {
            return -code error "bad window path name \"$w\""
        }
        if {[info exists index]} {
            set tooltip($w,$index) $key
            #bindtags $w [linsert [bindtags $w] end "TooltipMenu"]
            return $w,$index
        } elseif {[info exists item]} {
            set tooltip($w,$item) $key
            #bindtags $w [linsert [bindtags $w] end "TooltipCanvas"]
            enableCanvas $w $item
            return $w,$item
        } else {
            set tooltip($w) $key
            bindtags $w [linsert [bindtags $w] end "Tooltip"]
            return $w
        }
    }
}

proc ::tooltip::clear {{pattern .*}} {
    variable tooltip
    foreach w [array names tooltip $pattern] {
        unset tooltip($w)
        if {[winfo exists $w]} {
            set tags [bindtags $w]
            if {[set i [lsearch -exact $tags "Tooltip"]] != -1} {
                bindtags $w [lreplace $tags $i $i]
            }
            ## We don't remove TooltipMenu because there
            ## might be other indices that use it
        }
    }
}

proc ::tooltip::show {w msg {i {}}} {
    # Use string match to allow that the help will be shown when
    # the pointer is in any child of the desired widget
    if {![winfo exists $w] || ![string match $w* [eval [list winfo containing] [winfo pointerxy $w]]]} {
        return
    }
    
    variable G
    
    set b $G(TOPLEVEL)
    $b.label configure -text $msg
    update idletasks
    if {$i eq "cursor"} {
        set y [expr {[winfo pointery $w]+20}]
        if {($y+[winfo reqheight $b])>[winfo screenheight $w]} {
            set y [expr {[winfo pointery $w]-[winfo reqheight $b]-5}]
        }
    } elseif {$i ne ""} {
        set y [expr {[winfo rooty $w]+[winfo vrooty $w]+[$w yposition $i]+25}]
        if {($y+[winfo reqheight $b])>[winfo screenheight $w]} {
            # show above if we would be offscreen
            set y [expr {[winfo rooty $w]+[$w yposition $i]-\
                        [winfo reqheight $b]-5}]
        }
    } else {
        set y [expr {[winfo rooty $w]+[winfo vrooty $w]+[winfo height $w]+5}]
        if {($y+[winfo reqheight $b])>[winfo screenheight $w]} {
            # show above if we would be offscreen
            set y [expr {[winfo rooty $w]-[winfo reqheight $b]-5}]
        }
    }
    if {$i eq "cursor"} {
        set x [winfo pointerx $w]
    } else {
        set x [expr {[winfo rootx $w]+[winfo vrootx $w]+\
                    ([winfo width $w]-[winfo reqwidth $b])/2}]
    }
    # only readjust when we would appear right on the screen edge
    if {$x<0 && ($x+[winfo reqwidth $b])>0} {
        set x 0
    } elseif {($x+[winfo reqwidth $b])>[winfo screenwidth $w]} {
        set x [expr {[winfo screenwidth $w]-[winfo reqwidth $b]}]
    }
    if {[tk windowingsystem] eq "aqua"} {
        set focus [focus]
    }
    wm geometry $b +$x+$y
    wm deiconify $b
    raise $b
    if {[tk windowingsystem] eq "aqua" && $focus ne ""} {
        # Aqua's help window steals focus on display
        after idle [list focus -force $focus]
    }
}

proc ::tooltip::menuMotion {w} {
    variable G
    
    if {$G(enabled)} {
        variable tooltip
        
        set cur [$w index active]
        # The next two lines (all uses of LAST) are necessary until the
        # <<MenuSelect>> event is properly coded for Unix/(Windows)?
        if {$cur == $G(LAST)} return
        set G(LAST) $cur
        # a little inlining - this is :hide
        after cancel $G(AFTERID)
        catch {wm withdraw $G(TOPLEVEL)}
        if {[info exists tooltip($w,$cur)] || \
                    (![catch {$w entrycget $cur -label} cur] && \
                    [info exists tooltip($w,$cur)])} {
            set G(AFTERID) [after $G(DELAY) \
                    [namespace code [list show $w $tooltip($w,$cur) $cur]]]
        }
    }
}

proc ::tooltip::hide {args} {
    variable G
    
    after cancel $G(AFTERID)
    catch {wm withdraw $G(TOPLEVEL)}
}

proc ::tooltip::wname {{w {}}} {
    variable G
    if {[llength [info level 0]] > 1} {
        # $w specified
        if {$w ne $G(TOPLEVEL)} {
            hide
            destroy $G(TOPLEVEL)
            set G(TOPLEVEL) $w
        }
    }
    return $G(TOPLEVEL)
}

proc ::tooltip::itemTip {w args} {
    variable tooltip
    variable G
    
    set G(LAST) -1
    set item [$w find withtag current]
    if {$G(enabled) && [info exists tooltip($w,$item)]} {
        set G(AFTERID) [after $G(DELAY) \
                [namespace code [list show $w $tooltip($w,$item) cursor]]]
    }
}

proc ::tooltip::enableCanvas {w args} {
    $w bind all <Enter> [namespace code [list itemTip $w]]
    $w bind all <Leave>		[namespace code hide]
    $w bind all <Any-KeyPress>	[namespace code hide]
    $w bind all <Any-Button>	[namespace code hide]
}





# Part 2.0       Start up


wm protocol . WM_DELETE_WINDOW {confirm_save; write_runabc_ini; exit}
wm resizable . 1 1
global df
global abc_file_mod
set abc_file_mod 0; # flag indicate that file midi(abc_open) was changed

# the user can pass as argument the .abc file to open
if {$argc == 1} {
    set filename [file normalize [lindex $argv 0]]
    #    puts $filename
    set abc_open $filename
}
# For abc files associated with runabc on Windows PC
# we need the following
if {$argc == 2} {
    set abc_open [file normalize [lindex $argv 1]]
}

# Avoid multiple runabc processes, use DDE to find if another
# instance of runabc is running
if {$tcl_platform(platform) == "windows"} {
    # get DDE support if available, if not keep going
    if {![catch {package require dde}]} {
        # Now check if runabc is already running: as you can see in the
        # else case below if we don't find an active 'runabc' topic
        # for 'TclEval' service we will start the DDE service and proceed.
        if {[dde services TclEval runabc] != {}} {
            # runabc was started earlier so this process asks the
            # existing (previous) process to call 'open_abc_file'
            # (only if it is a valid file)
            if {[info exist abc_open] && [file exists $abc_open]} {
                # send a message to open the .abc file,
                # take care of special chars
                regsub {\[} [set abc_open] {\[} abc_open
                dde eval runabc "open_abc_file \"$abc_open\""
            }
            # Now we can terminate the new process, the previous will
            # open the file for us and we avoid race conditions on .ini
            # /temp and /workfolder
            exit 0
        } else {
            # We did not find an instance of runabc running, so
            # we register this as the 'runabc' topic and proceed
            dde servername runabc
        }
    }
}


proc messages {msg} {
    global df
    if {[winfo exists .msg] != 0} {destroy .msg}
    toplevel .msg
    message .msg.out -text $msg -font $df
    pack .msg.out
}

proc greetings {msg} {
    global df midi
    if {[winfo exists .greetings] != 0} {destroy .greetings}
    toplevel .greetings
    message .greetings.out -text $msg -font $df
    pack .greetings.out
    checkbutton .greetings.switch -text "do not show this message next time" -variable midi(donotshow) -font $df
    pack .greetings.switch
}

proc check_integrity {} {
    global midi tcl_platform
    
    set msg ""
    if {$tcl_platform(platform) == "windows"} {
        set msg "You are running runabc.tcl under the Windows operating system.\n"
        set abcmidi 0
        set result [check_file path_abc2midi]
        if {[string first "not found" $result] >= 0} {
            append msg "$midi(path_abc2midi) was not found\n"
            set abcmidi 1
        }
        set result [check_file path_abc2abc]
        if {[string first "not found" $result] >= 0} {
            append msg "$midi(path_abc2abc) was not found\n"
            set abcmidi 1
        }
        set result [check_file path_midi2abc]
        if {[string first "not found" $result] >= 0} {
            append msg "$midi(path_midi2abc) was not found\n"
            set abcmidi 1
        }
        if {$abcmidi == 1} {
            append msg "\nYou can find the abcmidi_win32 executables for windows on\
                    http://ifdo.ca/~seymour/runabc/top.html\n\
                    You should put these executables in the same folder where runabc is found.\
                    If the executables are in a different folder you need to specify their location\
                    by going to the options/abc executables menu item (wrench icon).\n"
        }
        set result [check_file path_abcm2ps]
        if {[string first "not found" $result] >= 0} {
            append msg "\n$midi(path_abcm2ps) was not found\n"
            append msg "\nIt is recommended that you use abcm2ps rather than yaps.\
                    abcm2ps is also included with the abcmidi_win32 executables that you can\
                    download from http://ifdo.ca/~seymour/runabc/top.html.\n"
        }
        set result [check_file path_gs]
        if {[string first "not found" $result] >= 0} {
            append msg "\n$midi(path_gs) was not found\n"
            append msg "\n$midi(path_gs) is a PostScript file viewer. You can get \
                    the install package from http://blog.kowalczyk.info/software/sumatrapdf/free-pdf-reader.html\n"}
        if {[file exist "c:/Program Files/gs/"] != 1} {
            append msg " You will also need Ghostview which you can get from http://www.cs.wisc.edu/~ghost/index.htm\n\
                    This should create a folder gs in your c:/program files/ directory."
        }
    } else {
        set msg "You are running runabc.tcl under the Unix operating system.\n"
        set abcmidi 0
        set result [check_file path_abc2midi]
        if {[string first "not found" $result] >= 0} {
            append msg "$midi(path_abc2midi) was not found\n"
            set abcmidi 1
        }
        set result [check_file path_abc2abc]
        if {[string first "not found" $result] >= 0} {
            append msg "$midi(path_abc2abc) was not found\n"
            set abcmidi 1
        }
        set result [check_file path_midi2abc]
        if {[string first "not found" $result] >= 0} {
            append msg "$midi(path_midi2abc) was not found\n"
            set abcmidi 1
        }
        if {$abcmidi == 1} {append msg "\nIf the abcmidi executables are\
                    already on your system, then you need to indicate their location by\
                    going to the options/abc executables menu item (wrench icon) and specifying\
                    their location. If you do not have the executables, you will need to\
                    build them from the source code which you can find on\
                    http://ifdo.ca/~seymour/runabc/top.html or on sourceforge.net.\n"}
        
        set result [check_file path_abcm2ps]
        if {[string first "not found" $result] >= 0} {
            append msg "\n$midi(path_abcm2ps) was not found\n"
            append msg "\nIt is recommended that you use abcm2ps rather than yaps.\
                    Source code for abcm2ps may be found on the web page http://moinejf.free.fr/ \
                    Either the stable or development versions are fine."
        }
        
        set result [check_file path_gs]
        if {[string first "not found" $result] >= 0} {
            append msg "\n$midi(path_gs) was not found\n\n"
            append msg "\nYou all need ghostview and a PostScript file viewer.\
                    on unix there is gs, gv, and evince. One of these should work."
        }
        
        set result [check_file path_midiplay]
        if {[string first "not found" $result] >= 0} {
            append msg "\n\n$midi(path_midiplay) was not found\n"
            append msg "\nYou also need a midi player like TiMidity. The\
                    quality of the reproduction depends upon the SoundFont pages it uses.\
                    Free soundfont files are available from http://www.personalcopy.com/sfarkfonts1.htm."
        }
    }
    foreach path {path_abc2midi path_abc2abc path_abcm2ps path_gs path_midiplay} {
        #  set msg "$midi($path)\t [check_file $path]"
    }
    
    
    greetings $msg
}


proc check_file {execname} {
    global midi tcl_platform
    if {[file exist $midi($execname)]} {
        set msg [format "found"]
    } elseif {$tcl_platform(platform) != "windows"} {
        set cmd "exec which $midi($execname)"
        catch {eval $cmd} loc
        if {[string first "abnorm" $loc] > 0} {set msg [format "not found"]} else {
            set msg [format "found"]}} else {
        set msg [format "not found"]}
    return $msg
}


# default values for options
proc midi_init {} {
    global midi df sf dfreset tocf
    global runabc_version
    global defaultdrumpat
    global tcl_platform
    set midi(version) $runabc_version
    set midi(font_family) [font actual helvetica -family]
    set midi(font_family_toc) courier
    #set midi(font_size) [font actual . -size]
    set midi(font_size) 10
    if {$midi(font_size) <10} {set midi(font_size) 10}
    #set midi(font_weight) [font actual . -weight]
    set midi(font_weight) bold
    set df [font create -family $midi(font_family) -size $midi(font_size) \
            -weight $midi(font_weight)]
    set sf [font create -family $midi(font_family) -size $midi(font_size) \
            -weight $midi(font_weight)]
    set dfreset [font create -family $midi(font_family) -size $midi(font_size) \
            -weight $midi(font_weight)]
    set tocf [font create -family $midi(font_family_toc) -size $midi(font_size) \
            -weight $midi(font_weight)]
    set midi(dir_abcmidi) .
    set midi(path_abc2ps) abc2ps
    set midi(path_yaps) yaps
    set midi(path_otherps) jcabc2ps
    if {$tcl_platform(platform) == "windows"} {
        #set midi(path_gs) c:/gstools/gsview/gsview32
        set midi(path_yaps) yaps.exe
        set midi(path_abcm2ps) abcm2ps.exe
        set midi(path_abcmatch) abcmatch.exe
        set midi(path_abc2midi) abc2midi.exe
        set midi(path_abc2abc) abc2abc.exe
        set midi(path_midi2abc) midi2abc.exe
        set midi(path_midicopy) midicopy.exe
        set midi(path_gs) "C:/Program Files/SumatraPDF/SumatraPDF.exe"
        set midi(path_midiplay) "C:/Program Files/Windows Media Player/wmplayer.exe"
        set midi(alt_path_midiplay) C:/Music/Winamp/Winamp.exe
        set midi(alt_path_options) ""
        set midi(midiplay_options) "/play /close"
        set midi(path_internet) "c:/Program Files/Internet Explorer/iexplore.exe"} else {
        set midi(path_yaps) yaps
        set midi(path_abcm2ps) abcm2ps
        set midi(path_abcmatch) abcmatch
        set midi(path_abc2midi) abc2midi
        set midi(path_abc2abc) abc2abc
        set midi(path_midi2abc) midi2abc
        set midi(path_midicopy) midicopy
        set midi(path_midiplay) timidity
        set midi(midiplay_options) "-A 50 -ik"
        set midi(path_internet) firefox
        set midi(path_gs) evince
    }
    set midi(gs_options) ""
    set midi(midi_dir) "tmp"
    set midi(path_editor) ""
    set midi(player) 0
    set midi(transfer_prot_1) 0
    set midi(transfer_prot_2) 0
    set midi(no_clipboard) 1
    set midi(summary_enabled) 1
    set midi(bell_on) 1
    set midi(buttonlabels) 0
    set midi(noconfirmsave) 0
    
    # abc2midi default parameters
    set midi(channel) 1
    set midi(program) 0
    set midi(chordprog) 0
    set midi(bassprog) 0
    set midi(beat_a) 105
    set midi(beat_b) 95
    set midi(beat_c) 80
    set midi(beat_n) 4
    set midi(beat2_a) 105
    set midi(beat2_b) 95
    set midi(beat2_c) 80
    set midi(double) 0
    set midi(octave) 0
    set midi(octave2) 0
    set midi(program2) 0
    set midi(chord_octave) 0
    set midi(bass_octave) 0
    set midi(melvol) 127
    set midi(doublevol) 127
    set midi(beat_offset) 10
    set midi(ratio_m) 1
    set midi(ratio_n) 2
    set midi(drummap) 1
    set midi(chordvol) 127
    set midi(bassvol) 127
    set midi(transpose) 0
    set midi(gracedivider) 4
    set midi(tempo) 120
    set midi(drone) 0
    set midi(tenordrone) 80
    set midi(bassdrone) 80
    set midi(drumvar) 0
    set midi(drumon) 0
    set midi(mydrum) 0
    set midi(drumpat) "dddd 35 40 35 41"
    
    # ab2ps default parameters
    set midi(ps_creator) abcm2ps
    set midi(ps_scale) 0.8
    set midi(ps_width) 500
    set midi(ps_lmargin) 20
    set midi(ps_glue) fill
    set midi(ps_shrink) 0.9
    set midi(ps_staffsep) 50
    set midi(ps_c) 0
    set midi(ps_fmt_flag) 0
    set midi(ps_fmt_file) letter.fmt
    set midi(ps_maxvent) 4
    set midi(ps_maxsent) 800
    set midi(bpsvoice) 0
    set midi(psvoice) ""
    set midi(ps_bbar) 0
    set midi(ps_bnumb) 0
    set midi(ps_bppage) 0
    set midi(ps_bxref) 0
    set midi(ps_bhist) 0
    set midi(ps_nolyric) 0
    set midi(ps_noslur) 0
    set midi(ps_other_options) ""
    
    
    # yaps default parameters
    set midi(papersize) 0
    set midi(yaps_voice) 0
    set midi(yaps_scale) 0.7
    set midi(yaps_lmargin) 50
    set midi(yaps_tmargin) 50
    set midi(yapsx) 0
    set midi(yaps_landscape) 0
    set midi(yaps_bbar) 0
    
    # other ps default parameters
    set midi(otherps) " > Out.ps"
    set midi(barflymode) 0
    set midi(stressmodel) 2
    
    # open/save parameters
    set midi(abc_open) samples.abc
    set midi(midi_save) sample.mid
    set midi(history_length) 0
    for {set i 0} {$i < 10} {incr i} {set midi(history$i) ""}
    set midi(abc_default_file) edit.abc
    set midi(abc_work_folder)  workfold
    
    for {set i 1} {$i <= 16} {incr i} {
        set midi(lvoice$i) 64
        set midi(voice$i) 0
        set midi(pvoice$i) 64
    }
    set midi(ignoreQ) 0
    set midi(ignoremidi) 0
    set midi(blank_lines) 1
    #
    #editor settings
    set midi(edit_body_colour) red3
    set midi(edit_field_colour) green4
    set midi(edit_comment_colour) blue2
    set midi(edit_barline_colour) purple
    set midi(edit_guitar_colour) deeppink1
    set midi(edit_selectbackground) orange
    set midi(edit_initial_width) 66
    set midi(startnumber) 1
    
    #find setting
    set midi(searchdir) "../abcfiles"
    
    #match settings
    set midi(match_timesig) 2/4
    set midi(match_keysig) G
    set midi(match_length) 1/8
    set midi(match_body) GABC|
    set midi(match_resolution) 12
    set midi(match_selection) all
    set midi(match_method) sig
    set midi(grouper_thresh) 3
    
    # extract settings
    set midi(remove_voice) 1
    set midi(remove_backslashes) 1
    set midi(condense_on) 1
    set midi(condense_method) 1
    
    # midi2abc settings
    set midi(midifilein) Choose_input_midi_file.mid
    set midi(midifileout) test.abc
    set midi(midichannel) ""
    set midi(unitval) ""
    set midi(anaval) ""
    set midi(tsigval) ""
    set midi(ksigval) ""
    set midi(anamethod) 0
    set midi(unitmethod) 2
    set midi(chan_method) 1
    set midi(tsig_method) 2
    set midi(ksig_method) 1
    set midi(save_shorts) 0
    set midi(no_triplets) 0
    set midi(no_grouping) 0
    set midi(interleave) 0
    set midi(splits) 0
    set midi(midibpl) 1
    set midi(midibps) 4
    set midi(midippu) 2
    set midi(midilden) 0
    set midi(midirest) 0
    
    # midishow
    set midi(midishow_sep) track
    set midi(midishow_follow) 1
    
    # grace notes
    set midi(grname1) cut
    set midi(grname2) strike
    set midi(grname3) mordnt
    set midi(grname4) rmordnt
    set midi(grname5) slide
    set midi(grname6) trill
    set midi(grseq1) "1"
    set midi(grseq2) "-1"
    set midi(grseq3) "0 1"
    set midi(grseq4) "0 -1"
    set midi(grseq5) "-3 -2 -1 0"
    set midi(grseq6) "0 1 0 1"
    
    #  for drumeditor.tcl
    set midi(selected_drums) ""
    set midi(dstrong) 110
    set midi(dmedium) 90
    set midi(dweak)  70
    
    #  for drumtool
    set midi(drumpatfile) drumpatterns.drum
    set defaultdrumpat(4) "dzzzdzzz 43 60 90 90"
    set defaultdrumpat(6) "dzzdzz 43 60 90 90"
    set defaultdrumpat(2) "dzzzdzzz 43 60 90 90"
    set defaultdrumpat(3) "dzdzdz 43 60 60 90 90 90"
    set defaultdrumpat(C|) "dzzzdzzz 43 60 90 90"
    
    #  g2v
    set midi(g2v_clipboard) 0
    
    set midi(donotshow) 0
}

# save all options, current abc file
proc write_runabc_ini {} {
    global midi
    
    set handle [open runabc.ini w]
    foreach item [lsort [array names midi]] {
        puts $handle "$item $midi($item)"
    }
    close $handle
}

# read all options
proc read_runabc_ini {} {
    global midi df tocf
    set handle [open runabc.ini r]
    while {[gets $handle line] >= 0} {
        set error_return [catch {set n [llength $line]} error_out]
        if {$error_return} continue
        set contents ""
        set param [lindex $line 0]
        for {set i 1} {$i < $n} {incr i} {
            set contents [concat $contents [lindex $line $i]]
        }
        #if param is not already a member of the midi array (set by midi_init),
        #then we ignore it. This prevents midi array filling up with obsolete
        #parameters used in older versions of the program.
        set member [array names midi $param]
        if [llength $member] { set midi($param) $contents }
    }
    font configure $df -family $midi(font_family) -size $midi(font_size) \
            -weight $midi(font_weight)
    font configure $tocf -family $midi(font_family_toc) -size $midi(font_size) \
            -weight $midi(font_weight)
}

proc is_runabc_here {} {
    # return 1 if runabc.exe or runabc.tcl is in the
    # current directory
    if {[file exist runabc.tcl]} {return 1}
    if {[file exist runabc.exe]} {return 1}
    return 0
}


# init global variables
set types {{{abc files} {*.abc}}
    {{all} {*}}}
set miditype {{{midi files} {*.mid *.MID *.midi *.kar *.KAR}}}
set exec_out "This window shows messages produced by play and display commands."

if {[is_runabc_here] == 0} {
    # If runabc is started from a file association in Windows,
    # the current directory will be the directory where the
    # abc file was double clicked. We want the current directory to
    # be the same directory where runabc was installed so
    # that we can load the correct runabc.ini file. For Windows,
    # we cache the install directory (runabcpwd) in the registry
    # and then cd to that directory (assuming runabc was found
    # there). If no registry install dir was found (because
    # no abc file association was set to runabc), we do
    # nothing and assume we are in the correct directory.
    if {$tcl_platform(platform) == "windows"} {
        package require registry
        if {[regexp runabc [registry keys "HKEY_LOCAL_MACHINE\\Software"]]} {
            set runabcpwd [registry get "HKEY_LOCAL_MACHINE\\Software\\runabc" \
                    InstallDir]
            # is the registry entry correct or did it change dir?
            if {[glob -nocomplain $runabcpwd/runabc*] != ""} {
                # ok we found runabc dir
                cd $runabcpwd
            } else {
                # remove invalid entry
                registry delete "HKEY_LOCAL_MACHINE\\Software\\runabc"
            }
        }
        
        # for other operating systems look at environment variables
    } else {
        if {[info exist env(RUNABCPATH)]} {
            cd $env(RUNABCPATH)}
    }
}



midi_init


if [file exists runabc.ini] {
    read_runabc_ini
    set midi(version) $runabc_version
}

if {$midi(donotshow) == 0} check_integrity

# Part 3.0               images


#######################
#     Tk Interface    #
#######################

#The following images were obtained from http://wiki.tcl.tk/icons

image create photo kmidi-16 -data {
    R0lGODlhEAAQAIEAAPwCBAQCBPz+/Lz+/CH5BAEAAAAALAAAAAAQABAAAAIz
    hI+By7oBo5RH2GvDRRhre0xiVHXZVpqfEI5iKkQxalzQIIPGhI+pSAN4cjqA
    68VIHvwFACH+aENyZWF0ZWQgYnkgQk1QVG9HSUYgUHJvIHZlcnNpb24gMi41
    DQqpIERldmVsQ29yIDE5OTcsMTk5OC4gQWxsIHJpZ2h0cyByZXNlcnZlZC4N
    Cmh0dHA6Ly93d3cuZGV2ZWxjb3IuY29tADs=
}


image create photo misc-22 -data {
    R0lGODlhFgAWAIUAAAT+BMyaBMSSBPz+BMyWBPz6BPz2BMSOBLyKBLSCBPzm
    BPziBPzuBPzqBLyGBPzeBLR+BPzyBPzaBMySBPzWBLR6BLyCBPzSBKx6BKx2
    BPzOBKRyBKRuBMSKBKxyBJxmBKRqBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAAALAAAAAAWABYAAAa+
    QIBwSCwaj8SAAMkUCgaDZVMYCAwJBcNhiEgcA1ACQCAwaBGAhGLhLYKhTzOD
    0XAoHg/IkQAdGCIRdGsPEnpIE1mADQ2DeUxxf4ILeBQUFUZkZYoNFg6UFBcY
    GRlDT1kGc5xCBxKgGq8aG05+qIIOQhMUsLAcQwcdCJILZK6vHhy9RQ6Mk63F
    r8lHFgvNzxrRRmqElbu8R9oPFdYcsB9GFniXo9C9IK/mRhCXQh7QQx/wU/XX
    U0gcIP0CHjEQBAAh/mhDcmVhdGVkIGJ5IEJNUFRvR0lGIFBybyB2ZXJzaW9u
    IDIuNQ0KqSBEZXZlbENvciAxOTk3LDE5OTguIEFsbCByaWdodHMgcmVzZXJ2
    ZWQuDQpodHRwOi8vd3d3LmRldmVsY29yLmNvbQA7
}
image create photo exec-22 -data {
    R0lGODlhGAAYAIQAAPwCBISChAQCBAwubBw+fCRKhCxSjERmnFR2rFyCtGyW
    xISm1JS65KTO7JzC7BQ2dDRalExupGSKvHyezPz+9Pz+/FxaXKSipPz69Pz6
    7MTCxAAAAAAAAAAAAAAAAAAAACH5BAEAAAAALAAAAAAYABgAAAXBICCOZGme
    aEoGbOu+sCAGw0AUhnEcSJIoisWCwWg4AjIA7XEzQA6RnkQxWVAEFSxyNmDi
    ntHENCgol7dKi3rNbrMvyYClQq9QMJQMJsPv9zVxFhl1hBR2d34ZgDNzhHQY
    FRiSdH6LaZB1kHiReYN/gY6RnHuUn4yDopp4e4mKoJmjmK2Wcqipq3wVibQW
    mJp3urqzgaiSq6Stroy+ornJymmDkneSz3y8j3aQns+0Gt/g4eLiSWbm5+jm
    Kuvs7SMGIQAh/mhDcmVhdGVkIGJ5IEJNUFRvR0lGIFBybyB2ZXJzaW9uIDIu
    NQ0KqSBEZXZlbENvciAxOTk3LDE5OTguIEFsbCByaWdodHMgcmVzZXJ2ZWQu
    DQpodHRwOi8vd3d3LmRldmVsY29yLmNvbQA7
}
image create photo content-22 -data {
    R0lGODlhFgAWAIYAAAQCBAQiNPwCBCSW/Dye/BxefBQWJPz6/NzK/FxSZBSe
    /PT2/Pz2/Bya/Pz+/PTy/GRWbAxSbOS2/Ozi/GxadIxyzMSu/PTq/ASe9Ozu
    /MyW3GxafOzq/IRutHRejLSi/PTu/Aya5Ozm/IxyvNSy/GxehAyS1IxyrBSK
    xNzW/IxypOze/Pzy/HRenBSCrNTG/IRunPTm/AxujOTa/Oza/My2/IxunHxi
    pMSe/OTO/OTW/HxqrNSe/NzC/IRqjKR+5IRypIxyxIxy/LyO9MSS/IxylIxu
    9KSC/Lym/LSC9IxujMSW1JR2tLSO1KSCrIx6/JR23HxmhBRylBxunAQeLAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAIA
    LAAAAAAWABYAAAf/gAABAoSFhoeHAAMAiI2IAAQFjI6EAAaJkQeTjwAICYkK
    BQcLm5WdBwyfhgANBQ4OmoWnBwcPEAC4lQoRrw6kAgASE7QMBxQVFheMABiu
    B7AZABrCC68PG8gcEbjNz68ZHdMTD7QZHhUfINsAIc6wIiMaJOMLDw8l6Nq4
    JqK9EyfiQIDIAOLchwvrUIhiwABEChXTVoB4wIJDi3zrXBTgwOHChBcwpokQ
    EYODiIvJ1skosGIGDRo1bEybEYNkjBsYcRUogCOHjhwkZEoQsWKCiAk7sm0D
    JiMCjx4kePiIqGPCDyBBhHzQV6npEB5Eish7USOpkSNIEKjbBKBpkiFKO5ZI
    OMHkR9oLIC5wldW0SVwYTo48GUwYytJVTaP48CBlSuMpkCHLKNU1QoTJuDJr
    pkwoQAAqVCgRMhAIACH+aENyZWF0ZWQgYnkgQk1QVG9HSUYgUHJvIHZlcnNp
    b24gMi41DQqpIERldmVsQ29yIDE5OTcsMTk5OC4gQWxsIHJpZ2h0cyByZXNl
    cnZlZC4NCmh0dHA6Ly93d3cuZGV2ZWxjb3IuY29tADs=
}
image create photo help-22 -data {
    R0lGODlhFgAWAIUAAPwCBHx6BPz6vPTutKSidJSKLPz6BPz+BMzKjMS6vJya
    XMTCpOzqBLSqlNTOVPzyFLy2DGxqBBQOBOzqLMzKBKSiBLy6BOTaBAQCBJya
    BExKBMzCBFxaBMS+BHRqBLSudKyqBNTOBIyGBLy2jDw+BJSSNNzaBERCNBQW
    BCQeBFRSTFxaRERGHFxeXJySLLSypKSeNIyKjAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAAALAAAAAAWABYAAAa6
    QIBwKAwYj0aicmgUOJ0DAiGwJAYKhkN2i0goqNWAYmEomw2MxRdsbTgejLP5
    AYlIlgHHpEypBCwXZQwWERh4DHEGGRoYERtmhIZKAYmKjBgZgpF4GJ2dQhwd
    kB6SVUQfIBdxISIabKYAIwFnIiQasEMlIGgGJgF3uLm7Zb7AwQAFwwzFx0K6
    DFoXv80AJygp2CgSKtQAKyTgLC3dAB8i5y4v3bpmzM3saO7HHzAZGRWt3NQx
    np9LBkEAACH+aENyZWF0ZWQgYnkgQk1QVG9HSUYgUHJvIHZlcnNpb24gMi41
    DQqpIERldmVsQ29yIDE5OTcsMTk5OC4gQWxsIHJpZ2h0cyByZXNlcnZlZC4N
    Cmh0dHA6Ly93d3cuZGV2ZWxjb3IuY29tADs=
}
image create photo print-22 -data {
    R0lGODlhGAAYAIYAAPwCBIx+bIR2ZHxuZHRqXGReVFxWVFRWVPz6/PTy7Ozm
    5NzW1MS+tOzq5Ozu5Ozm3MTCxGRiZOzq3PTu7OTi3NzWzGRmZNzSxOzi1OTe
    1FxaXExKRNTKvMzCtMS2rKSelFRSVGxiXPTu5OTezNTCrLSunIR+fHRydOze
    zOTazOTWxOTWvNTKtERGRHx6fHx+fLS2tNTW1DxWdAwOPMTGxLy6vMS6tLy2
    rDxSbMTGzERefDRCXERifFRaXExqjDRKZDRCZExKXMzKzLy+vHx6hHyavIyi
    tJSitJSmtJyqtGxudFRSTKyqrIyKjJSWlJyanHyyjFyqNIyOjHTeVLTydDw2
    NDQ2NCQmJCQqLCwuLEw+NGymfLSupLSmlJyGfLyqlBwaHOzexOzaxNzOtFRO
    RNzKrDw6NOTSvOTStNzKtDQuLDQyLAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAAA
    LAAAAAAYABgAAAf/gACCg4SFhoeCAQICAwQFBQYHiIcBCAkJCgsMBA2Sk4SV
    lw4PEBEPEp6fAAKXCRMUFRYXGKiqAAOXExISGRobBxGpkwQTEw27DxwdHh8g
    tiEOIsgYIxckJcKEJicFBwUPFOAjKCkqKywHLd4ugy8wMTIzBTQ1NvYMDDU3
    HwczODEwTAgyUSOHjhkzdihcyBAhD3ovBJ2gx6OHDx04fiwE8uMHDx9BeNSo
    cUJQBCFDiJwoUsTIESRJYh45YqSIkomlBC2BUINJkxMRIlgISjToiSYlaghZ
    IqiFkydOnkqFSnUqlChNWjRt0sRJEylduXr9KmXsFComtAKoYsKEiw1Wca7I
    xSI3i1y5WrZMsWBFUJYgQa9k0celBJcuHxB3sdsjQosrgwTHbZHiAAQXBjx4
    EUDgywYwcSEf0oDhwbgwI8SsGOPBgK0NGAIc0DyAjBcCZdR+MmPuzBg0Y9KU
    KUOiii01a7KoUZ5FOXI1tqIXkhEIACH+aENyZWF0ZWQgYnkgQk1QVG9HSUYg
    UHJvIHZlcnNpb24gMi41DQqpIERldmVsQ29yIDE5OTcsMTk5OC4gQWxsIHJp
    Z2h0cyByZXNlcnZlZC4NCmh0dHA6Ly93d3cuZGV2ZWxjb3IuY29tADs=
}
image create photo config-22 -data {
    R0lGODlhFgAWAIQAAPwCBAQCBISChFxaXNze3NTS1Ly6vKSipNTO1Ly2vNza
    3Pz+/MzOzOTe5DQyNOzu7MTCxGRmZMTGxPTy9Ozm7Hx6fPTu9MzGzGxmbAAA
    AAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAAALAAAAAAWABYAAAW1ICCOZGme
    aEoGbBsI6joMRGEcbQwESDIrtVtAF1gwDLNaAmfKiVgLBJKgwB1KxQZrBHU0
    FAXmavFoQLYiB6TxFXMj5AZBwnJI2I3wcNWALyYEcgoKXxRhOHs7XxEVCwsW
    FgoUDRYUFwwQB25ZCxiNjo6GkwUXN2NsCxEYqhUHoQ0MEglYRQQXErcHrI55
    FycuB2YSmoyOBTEtB2sXuhU6XAENC2a6z9AKCwq+1tAN3E2J3ySkIQAh/mhD
    cmVhdGVkIGJ5IEJNUFRvR0lGIFBybyB2ZXJzaW9uIDIuNQ0KqSBEZXZlbENv
    ciAxOTk3LDE5OTguIEFsbCByaWdodHMgcmVzZXJ2ZWQuDQpodHRwOi8vd3d3
    LmRldmVsY29yLmNvbQA7
}
image create photo edit-22 -data {
    R0lGODlhFgAWAIYAAAT+BIxSLPyuXFRShPzqrPz+/PT6/PT2/Oz2/Ozy/MzK
    /OSaVPyWNPz6/OTu/IxeNPzavPyKBNzq/PyCBPyGBOTq/JxmNPzOpLx6PNRq
    BMSCRNySTPyCDPSGBMxiBKROBOTy/PS2lOyydMxmBJxKBAwODPzevPzm1Oya
    bNzm/Pzy5PTGrOyOXPR+DJxGBPzmzNxuPORqLMReFNTm/Pzq1PSylMyCXKxi
    NIRKHPzixJRaPFxONMTW/MyCZCwqJDQyLLzW9NTi/HRmTLSKbHROPFxKPMTa
    /LzW/LTO9MyuhEQuJFRSVLzS9DQyNFRGNLTS9AAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAAA
    LAAAAAAWABYAAAf/gACCg4SFhQEChAOLjI2Lg4gEigUGlQcICAkJAwoDAAEL
    BAyTDQ0GBwcJCA4DDgoPCxAMEYqWl5oJrBKwshMUtaiZmg4VAxYLFwy+tIMD
    mLgO0RIYyAwU1xmKqbnRDhIaG8kcFB0eH4ogCSDRFRIhIsnXFCMkJYoJFezu
    Jico4+X1CrUiJkFCigsqVrBowWGEC3sCCaZIEeIFBBQwYsh46ElghRkFZ1yg
    UcPGjQA4SnQyNODjxxo5SuoIsKMEj5UCZ+gUuaKHjh0+fvAAglORziBChtgg
    UuSHER5HkBRtZmRGEiE+lCwxYgQIECZHpgoaMMMI1iZDnn6NKrWjIq5OHtIa
    YQIEyZEnSNqyVMC3r1+/bps5GtzIkOHDgwwEAgAh/mhDcmVhdGVkIGJ5IEJN
    UFRvR0lGIFBybyB2ZXJzaW9uIDIuNQ0KqSBEZXZlbENvciAxOTk3LDE5OTgu
    IEFsbCByaWdodHMgcmVzZXJ2ZWQuDQpodHRwOi8vd3d3LmRldmVsY29yLmNv
    bQA7
}
image create photo exit-22 -data {
    R0lGODlhFgAWAIQAAPwCBMyaBPz6BPz+BMyWBMSSBPzyBPz2BMSOBPzuBPzq
    BMSKBLyKBPziBLyCBPzmBPzeBLyGBLSCBPzWBPzaBPzSBLR6BLR+BKxyBKx6
    BKx2BAAAAAAAAAAAAAAAAAAAACH5BAEAAAAALAAAAAAWABYAAAW7ICCOZGme
    Y6AGaAsEwsC6aToIM0C08Bzcs4KgcPoNZK+BgVU4HAwIk9F3SBABBQO09MPN
    CAbFFbAwJBgkGFJUUDTGi0TCkRIIDrnCA7IYRRIKChIiAU47IwUQE30jDgoP
    gy9OY2QUFREkDg8PFiIETgZwDBGYIhcPDQ2dbGZRLRcNDxgkBXKMKBYNEBkl
    cQqkdCMWwxAQGicRgZsXzBbFxccoEbGpqc8Usy7Mutca2TQAwxre3+Dm5y4G
    IQAh/mhDcmVhdGVkIGJ5IEJNUFRvR0lGIFBybyB2ZXJzaW9uIDIuNQ0KqSBE
    ZXZlbENvciAxOTk3LDE5OTguIEFsbCByaWdodHMgcmVzZXJ2ZWQuDQpodHRw
    Oi8vd3d3LmRldmVsY29yLmNvbQA7
}
image create photo kmix-16 -data {
    R0lGODlhEAAQAIMAAPwCBJxmBNSeBHx+fPz+JLy+vPz+RPz+/Pz+VPz+bPz+
    fPz+hPz+nAAAAAAAAAAAACH5BAEAAAAALAAAAAAQABAAAARXEMgJQqCYihFG
    xgIRFMU3CcYwFIcnuZKAIOPRvqeQ7PUNywnFQmGxwWKIxIKxGAVumqSQyPGp
    OJtdogilWGQ0VhcTQPU8x0lZZcRlyqMCLC2B0z+Wjz8CACH+aENyZWF0ZWQg
    YnkgQk1QVG9HSUYgUHJvIHZlcnNpb24gMi41DQqpIERldmVsQ29yIDE5OTcs
    MTk5OC4gQWxsIHJpZ2h0cyByZXNlcnZlZC4NCmh0dHA6Ly93d3cuZGV2ZWxj
    b3IuY29tADs=
}
image create photo settings-22 -data {
    R0lGODlhFgAWAIMAAASC/JRmBPz+lPzKBAQCBHx+fPz+/Ly+vPyWBJQCBPzK
    ZPwCZMyWBAAAAAAAAAAAACH5BAEAAAAALAAAAAAWABYAAAR3EMhJq7040wAC
    11YgiAMBbkJJpObZCa1IFEBh25csyUZxGEBDazMYiQIEw2GpXA4ngeKIQDhQ
    fQXqEypAmKiSamu7Y1USCjLKe16ouaX2u8ymJNwa0vY+f9UnfHlmdngZIn8S
    gYaDgIUYAQwMewl9AGAVWi6adhEAIf5oQ3JlYXRlZCBieSBCTVBUb0dJRiBQ
    cm8gdmVyc2lvbiAyLjUNCqkgRGV2ZWxDb3IgMTk5NywxOTk4LiBBbGwgcmln
    aHRzIHJlc2VydmVkLg0KaHR0cDovL3d3dy5kZXZlbGNvci5jb20AOw==
}
image create photo fileopen-16 -data {
    R0lGODlhEAAQAIMAAPwCBASCBMyaBPzynPz6nJxmBPzunPz2nPz+nPzSBPzq
    nPzmnPzinPzenAAAAAAAACH5BAEAAAAALAAAAAAQABAAAARTEMhJq724hp1n
    8MDXeaJgYtsnDANhvkJRCcZxEEiOJDIlKLWDbtebCBaGGmwZEzCQKxxCSgQ4
    Gb/BbciTCBpOoFbX9X6fChYhUZYU3vB4cXTxRwAAIf5oQ3JlYXRlZCBieSBC
    TVBUb0dJRiBQcm8gdmVyc2lvbiAyLjUNCqkgRGV2ZWxDb3IgMTk5NywxOTk4
    LiBBbGwgcmlnaHRzIHJlc2VydmVkLg0KaHR0cDovL3d3dy5kZXZlbGNvci5j
    b20AOw==
}

image create photo find-22 -data {
    R0lGODlhFgAWAIYAAPwCBBQSFJSWlFxaXJyanKy2tLzCxDw+PHyChNTa3Nzq
    7Nz29NTy9Mzu9OT29Nzi5Oz6/Mzy9Kzi7Jze5Lze5Nzy9JyenIyKjHR2dMTu
    9Kzm7JzW3ITW3ISChGxubERGROz+/Lzq9IzW5HzK1LTm7FRSVHTS3GS+zLTS
    1DQ2NMzOzMTq7Lzq7ITW5FS2vMTi5ExOTKTm7EzCzEy2vEyutJTa5FTK1ESi
    rGy+zMzi5ESerESmtITa5OTy9KTe5KyqrAz+/Azi3ASutERCRExKTFRWVAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAAA
    LAAAAAAWABYAAAf/gACCggGFhYOIAAIDiYUEBQYFAoeJAweKhAgJCgsLDA0O
    CAGJg4wBCA8QDhENEhMUFaKDFhcYgwEJCxAQDBkaGxwSFaMAFh0eAx8AAQIK
    ECAODCEaIiMjJJMAtQMlygEGEBkVva4mJycTKKMYJd0pyyoOKyssGhMtIycu
    Gi/EMB/vlhmoQEFDjHsmZMygUUMdqWUCGgCbYMKEjRk3cEjI9jBADg3Wzs3Q
    sYOHA2IdO1SQkI/GjRMtFhBA2RFBDwk+OASrMPMHkIe3AhBA8QLFzAAHgvyg
    2dEQMSEHPCwltQgooSFSmVpSxKjjh6wPtwINgHVqsVpWESEFeywZ17RkED2s
    40YEgFirlIq4SwvUQCAAIf5oQ3JlYXRlZCBieSBCTVBUb0dJRiBQcm8gdmVy
    c2lvbiAyLjUNCqkgRGV2ZWxDb3IgMTk5NywxOTk4LiBBbGwgcmlnaHRzIHJl
    c2VydmVkLg0KaHR0cDovL3d3dy5kZXZlbGNvci5jb20AOw==
}



# Part 4.0   Control Buttons


###     Control Functions    ######

set tunenote ""
global tunenote

frame .abc
frame .abc.file
frame .abc.functions -borderwidth 2
frame .abc.titles

# file entry and button
entry .abc.file.entry -width 62 -relief sunken -textvariable midi(abc_open) \
        -font $df
bind .abc.file.entry <Return> {
    title_index $midi(abc_open)
    focus .abc.titles
}

set w .abc.file.menu
menubutton .abc.file.menu -text file -image fileopen-16 -relief raised  -menu $w.type -font $df
menu $w.type -tearoff 0
$w.type add radiobutton  -label "browse" -command file_browser  -font $df

for {set i 0} {$i < $midi(history_length)} {incr i} {
    $w.type add radiobutton  -label $midi(history$i) \
            -value $i -variable history_index -command process_history -font $df
}
pack .abc.file.menu -side left  -fill x
pack .abc.file.entry -side left  -fill x
pack .abc.file -side top -fill x

# first row of buttons
button .abc.functions.quit -text exit -image exit-22 \
        -command {confirm_save; write_runabc_ini; exit}\
        -font $df -borderwidth 2
button .abc.functions.play -text play -font $df -image kmix-16  -command play_action -borderwidth 2
button .abc.functions.disp -text display -font $df -image print-22 -command display_action -borderwidth 2

set w .abc.functions.editmenu
menubutton $w -text edit -font $df -image edit-22 -relief raised  -menu $w.type -font $df -borderwidth 2
menu $w.type -tearoff 0
$w.type add command -label "edit file" -command  {
    . config -cursor watch
    update
    abc_edit midi(abc_open)
    set abc_file_mod 1
    . config -cursor arrow
    update}  -font $df
$w.type add command  -label "edit selection" -command  {
    set outfile [extract_title_of_first_tune [title_selected] $midi(abc_open)]
    set outfile [file join $midi(abc_work_folder) $outfile.abc]
    copy_selection_to_file [title_selected] $midi(abc_open) $midi(abc_default_file)
    file mkdir "[pwd]/$midi(abc_work_folder)"
    file rename -force $midi(abc_default_file) $outfile
    abc_edit outfile
} -font $df
$w.type add command  -label "TclAbcEditor"\
        -command {startup_tcl_abc_edit 1} -font $df
$w.type add command -label "TclMultiVoiceEditor"\
        -command {startup_tcl_abc_edit 0} -font $df

$w.type add command -label "new tune"       -command edit_new_tune -font $df
$w.type add command -label "new file"       -command edit_empty_file -font $df


set w .abc.functions.utilmenu
menubutton $w -text edit -font $df -image misc-22 -relief raised  -menu $w.type -font $df -borderwidth 2
menu $w.type -tearoff 0
$w.type add command -label "abc2abc"        -command show_abc2abc_page -font $df
$w.type add command -label "gchords/drums to voice" -command g2v_startup -font $df
$w.type add command -label "reformat"   -command show_reformat_page -font $df
$w.type add command -label "extract part"   -command show_extract_page -font $df
$w.type add command -label "drum tool"    -command {drumtool_gui_setup} -font $df
$w.type add command -label "view X.tmp"     -command show_tmpfile -font $df
$w.type add command -label "save X.tmp as an abc file" -command save_tmpfile -font $df
$w.type add command -label "save midi file(s)" -command midisave -font $df
$w.type add command -label "copy incipits" -command show_incipits_page -font $df
$w.type add cascade -label "copy to file" -menu $w.type.copy -font $df
menu $w.type.copy -tearoff 0
$w.type.copy add command -label "copy" -font $df \
        -command {start_copy_selected_files w 0}
$w.type.copy add command -label "copy and renumber" -font $df \
        -command {start_copy_selected_files w 1}
$w.type.copy add command -label "append" -font $df \
        -command {start_copy_selected_files a 0}
$w.type.copy add command -label "append and renumber" -font $df \
        -command {start_copy_selected_files a 1}
$w.type.copy add command -label "combine parts" -font $df \
        -command {combine_parts}
$w.type.copy add command -label "separate tunes" -command split_abc_file  -font $df
$w.type.copy add command -label help -font $df \
        -command {show_message_page $hlp_copy word}

button .abc.functions.console -text console -image exec-22 -command {show_console_page $exec_out char} -borderwidth 2 -font $df
menubutton .abc.functions.search -text search -image find-22 -relief raised -menu .abc.functions.search.type -font $df
menu .abc.functions.search.type -tearoff 0
.abc.functions.search.type add command -label "find title" -font $df  -command {find_window}
.abc.functions.search.type add command -label "find bars"  -font $df  -command match_window
.abc.functions.search.type add command -label "grouper"    -font $df  -command grouper_window

menubutton .abc.functions.midi -text midimenu -image kmidi-16 -relief raised -menu .abc.functions.midi.type -font $df
menu .abc.functions.midi.type -tearoff 0
.abc.functions.midi.type add command -label "midi2abc"   -font $df  -command show_midi2abc_page
.abc.functions.midi.type add command -label "midishow"   -font $df  -command piano_window
.abc.functions.midi.type add command -label "mftext"     -font $df  -command mftextwindow

# second row of buttons
button .abc.functions.toc -text toc -image content-22 -command show_titles_page -borderwidth 2 -font $df
set w .abc.functions.playopt
menubutton $w -text "play options" -image settings-22 -relief raised -font $df -menu $w.type -borderwidth 2
menu $w.type -tearoff 0
$w.type add command  -label tempo/pitch  -command {show_midi_page 1} -font $df
$w.type add command  -label arrangement  -command {show_midi_page 2} -font $df
$w.type add command  -label "advanced settings" -command {show_midi_page 8} -font $df
$w.type add command  -label  drumkit     -command drum_editor -font $df
$w.type add command  -label voices       -command show_voice_page  -font $df


set w .abc.functions.yaps
menubutton $w  -text "yaps opts" -menu $w.type -font $df -relief raised -pady 6 -borderwidth 2
menu $w.type -tearoff 0
$w.type add command -label options -command {show_ps_page yaps} -font $df
$w.type add cascade -label "ps converter" -menu $w.type.selector -font $df
menu $w.type.selector -tearoff 0
$w.type.selector add radiobutton -label abc2ps  -variable midi(ps_creator) \
        -value abc2ps  -font $df -command switch_ps_button
$w.type.selector add radiobutton -label abcm2ps  -variable midi(ps_creator) \
        -value abcm2ps  -font $df -command switch_ps_button
$w.type.selector add radiobutton -label yaps  -variable midi(ps_creator) \
        -value yaps  -font $df -command switch_ps_button
$w.type.selector add radiobutton -label other  -variable midi(ps_creator) \
        -value other -font $df -command switch_ps_button



set w .abc.functions.abc2ps
menubutton $w   -text "abc2ps options" -menu $w.type -font $df -relief raised -pady 6 -borderwidth 2
menu $w.type -tearoff 0
$w.type add command -label style  -command {show_ps_page psstyle} -font $df
$w.type add command -label format -command {show_ps_page psform}  -font $df
$w.type add cascade -label "ps converter" -menu $w.type.selector -font $df

menu $w.type.selector -tearoff 1
$w.type.selector add radiobutton -label abc2ps  -variable midi(ps_creator) \
        -value abc2ps  -font $df -command switch_ps_button
$w.type.selector add radiobutton -label abcm2ps  -variable midi(ps_creator) \
        -value abcm2ps  -font $df -command switch_ps_button
$w.type.selector add radiobutton -label yaps  -variable midi(ps_creator) \
        -value yaps  -font $df -command switch_ps_button
$w.type.selector add radiobutton -label other  -variable midi(ps_creator) \
        -value other -font $df -command switch_ps_button


set w .abc.functions.otherps
menubutton $w   -text "other ps" -menu $w.type -font $df -relief raised -pady 6 -borderwidth 2
menu $w.type -tearoff 0
$w.type add  radiobutton -label "options" -font $df  -command show_other_ps
$w.type add cascade -label "ps converter" -menu $w.type.selector -font $df
menu $w.type.selector -tearoff 0
$w.type.selector add radiobutton -label abc2ps  -variable midi(ps_creator) \
        -value abc2ps  -font $df -command switch_ps_button
$w.type.selector add radiobutton -label abcm2ps  -variable midi(ps_creator) \
        -value abcm2ps  -font $df -command switch_ps_button
$w.type.selector add radiobutton -label yaps  -variable midi(ps_creator) \
        -value yaps  -font $df -command switch_ps_button
$w.type.selector add radiobutton -label other  -variable midi(ps_creator) \
        -value other -font $df -command switch_ps_button


set w .abc.functions.cfg
menubutton $w -image config-22 -text cfg -relief raised -menu $w.type -font $df -borderwidth 2
menu $w.type -tearoff 0
$w.type add command  -label "abc executables" -command {show_config_page 1} -font $df
$w.type add command  -label "player"        -command {show_config_page 2} -font $df
$w.type add command  -label "font"            -command {show_config_page 4} -font $df
$w.type add command  -label "greetings"       -command check_integrity -font $df
$w.type add command  -label "sanity check"    -command {runabc_diagnostic}  -font $df
$w.type add checkbutton -label "ignore blank lines" -variable midi(blank_lines)  -font $df
$w.type add checkbutton -label "bell on file write" -variable midi(bell_on)  -font $df
$w.type add checkbutton -label "no confirm for unsaved file" -variable midi(noconfirmsave)  -font $df
$w.type add checkbutton -label "reveal button labels" -variable midi(buttonlabels) -command button_label_action -font $df
if {$tcl_platform(platform) == "windows"} {
    $w.type add command  -label "Register .abc files" -command associate_abc -font $df}

button .abc.functions.help -image help-22 -text help -command contexthelp -font $df -borderwidth 2


tooltip::tooltip .abc.functions.toc  "TOC"
tooltip::tooltip .abc.functions.editmenu "Edit menu"
tooltip::tooltip .abc.functions.utilmenu "Utilities"
tooltip::tooltip .abc.functions.play  "Play selection"
tooltip::tooltip .abc.functions.playopt "Play Option Menu"
tooltip::tooltip .abc.functions.disp  "Display"
tooltip::tooltip .abc.functions.console "Console"
tooltip::tooltip .abc.functions.midi "Midi Menu"
tooltip::tooltip .abc.functions.search "Search Menu"
tooltip::tooltip .abc.functions.cfg   "Options"
tooltip::tooltip .abc.functions.help  "Help"
tooltip::tooltip .abc.functions.quit  "Quit"

pack .abc.functions.toc .abc.functions.editmenu \
        .abc.functions.utilmenu .abc.functions.play .abc.functions.playopt \
        .abc.functions.disp -side left -fill y
pack .abc.functions.console .abc.functions.search .abc.functions.midi -side left -fill y

if {$midi(ps_creator) == "yaps"} {
    pack .abc.functions.yaps .abc.functions.cfg -side left -fill y
} else {
    pack .abc.functions.abc2ps .abc.functions.cfg  -side left -fill y
    if {$midi(ps_creator) == "abcm2ps"} {
        .abc.functions.abc2ps configure -text abcm2ps}
}

pack .abc.functions.help -side left -fill y
pack .abc.functions.quit -side left -fill y

pack .abc.functions -side top

set w .abc.titles.sliders
frame $w
label $w.tempolab -text bpm -width 3 -font $df
scale $w.tempo -from 0 -to 320 -length 180  \
        -width 10 -orient horizontal  -showvalue true -troughcolor darkred\
        -variable midi(tempo)   -font $df
pack $w.tempo $w.tempolab  -side left -fill y
pack $w -side top

frame .abc.titles.notes -borderwidth 3
button .abc.titles.notes.but -text "" -font $df\
        -background lightyellow -command {Refactor::header_window}  -borderwidth 3 -relief raised
tooltip::tooltip .abc.titles.notes.but  "Reveal field commands"
pack .abc.titles.notes.but -fill x
pack .abc.titles.notes -fill x


# Part 5.0          TOC

###    Table of Contents  - title index   ###
ttk::style configure Treeview.Heading -font $df
ttk::treeview .abc.titles.t -columns {refno key meter title}  -height 15\
        -show headings  \
        -selectmode extended -yscrollcommand {.abc.titles.ysbar set}
foreach col {refno key meter}  name {refnumb keysignature meter}  {
    .abc.titles.t heading $col -text $col
    .abc.titles.t heading $col -command [list SortBy $col 0]
    .abc.titles.t column $col -width [expr [font measure $df $name] +3]
}
.abc.titles.t heading title -text title
.abc.titles.t heading title -command [list SortBy title 0]
.abc.titles.t column title -width [font measure $df "WWWWWWWWWWWWWWWWWWWWWWWW"]

bind .abc.titles.t <<TreeviewSelect>> {extract_tune_info}

scrollbar .abc.titles.ysbar -bd 2 -command {.abc.titles.t yview}
pack .abc.titles.ysbar -side right -fill y
pack .abc.titles.t  -expand y -fill both
pack .abc           -expand y -fill both
focus .abc.titles.t

menu .actionmenu
.actionmenu add command -label play -command {play_action}
.actionmenu add command -label display -command {display_action}
.actionmenu add command -label summary -command {show_summary $i}


bind .abc.titles.t <Button-3> {
    .abc.titles.t selection set {}
    .abc.titles.t selection set [.abc.titles.t identify row %x %y]
    set i [.abc.titles.t selection]
    #show_summary $i
    tk_popup .actionmenu %X %Y
}

if {[winfo exists .msg] != 0} {raise .msg .abc}

#####  Bindings  #####
bind . <Next>  { .abc.titles.t yview scroll +1 page }
bind . <Prior> { .abc.titles.t yview scroll -1 page }
bind . <Down>  { .abc.titles.t yview scroll +1 units }
bind . <Up>    { .abc.titles.t yview scroll -1 units }

bind .abc.titles.t  <d>   { if {$active_sheet == "titles"} {display_action}}
bind .abc.titles.t  <p>   { if {$active_sheet == "titles"} {play_action}}
bind .abc.titles.t <space> { if {$active_sheet == "titles"} {play_action}}
bind .abc.titles.t <E>  {if {$active_sheet == "titles"} {
        abc_edit midi(abc_open)
        set abc_file_mod 1
    }}
bind .abc.titles.t <e> {if {$active_sheet == "titles"} {startup_tcl_abc_edit 1}}


proc startup_progress {message} {
    wm title . $message
    update
}

proc button_label_action {} {
    global midi
    if {$midi(buttonlabels)} {
        show_button_labels top
    } else {show_button_labels none}
}

proc show_button_labels {loc} {
    .abc.file.menu configure -compound $loc
    .abc.functions.quit configure -compound $loc
    .abc.functions.play configure -compound $loc
    .abc.functions.disp configure -compound $loc
    .abc.functions.editmenu configure -compound $loc
    .abc.functions.console configure -compound $loc
    .abc.functions.toc configure -compound $loc
    .abc.functions.playopt configure -compound $loc
    .abc.functions.midi configure -compound $loc
    .abc.functions.otherps configure -compound $loc
    .abc.functions.cfg configure -compound $loc
    .abc.functions.help configure -compound $loc
    .abc.functions.utilmenu configure -compound $loc
    .abc.functions.search configure -compound $loc
}


startup_progress "loading core functions"
button_label_action


# Part 6.0	Core Functions

proc show_error_message {text} {
    global df
    set p .error_msg
    if [winfo exist $p] {
        $p.t configure -state normal -font $df
        $p.t delete 1.0 end
        $p.t insert end $text
        $p.t configure -state disabled -wrap word
    } else {
        toplevel $p
        text $p.t -height 6 -width 50 -wrap word -font $df -foreground darkred
        pack $p.t -in $p -fill both -expand true
        $p.t insert end $text
        $p.t configure -state disabled
    }
    raise $p .
}


proc abcmidi_no_such_error {exefile} {
    set pathname [file dirname $exefile]
    set tail [file tail $exefile]
    puts $pathname
    puts $tail
    set msg "Runabc could not find the executable $tail in the folder $pathname.\
            $tail is part of the abcMIDI package. If the package\
            is already on your system, then you need to indicate the path to the\
            package by going to the config/abc executables menu item (see wrench\
            icon)."
    show_error_message $msg
}

#####  Functions to Play, Display, Edit #####

# The variable console_clock is used to determine whether
# the displayed X.tmp file is not superceded. It is called
# when X.tmp file is updated. console_clock is copied to
# tmp_clock whenever the tmpfile window is displayed or updated.
# We need to do this so that the error messages in the
# console window are in sync with the tmpfile window.

proc play_action {} {
    global midi exec_out
    global files
    global console_clock
    global active_sheet
    global nvoices
    set console_clock [clock seconds]
    set dir "[pwd]/$midi(midi_dir)"
    set cmd "file delete [glob -nocomplain $dir/*.mid]"
    catch {eval $cmd}
    
    set sel [title_selected]
    if {$midi(double)} {
        if {$nvoices == 0} {set sel [create_tmp_voiced_abc $sel]
        } else {
            midi1_msg "cannot duplicate voice in multivoiced tune"
            set sel [tune_picked $sel $midi(abc_open)]
        }
    } else {
        set sel [tune_picked $sel $midi(abc_open)]
    }
    set cmd "exec [list $midi(path_abc2midi)] [list $midi(midi_dir)/X.tmp]"
    if {$midi(barflymode)} {append cmd " -BF $midi(stressmodel)"}
    catch {eval $cmd} exec_out
    if {[string first "no such" $exec_out] >= 0} {abcmidi_no_such_error $midi(path_abc2midi)}
    set exec_out $cmd\n\n$exec_out
    set files ""
    foreach tune [lsort -integer $sel] {
        lappend files $dir/X$tune.mid
    }
    play_midis $sel
    update_console_page
}


proc play_midis {sel} {
    global midi exec_out files
    
    set dir "[pwd]/$midi(midi_dir)"
    if {$midi(player)} {
        # player 2
        set cmd "exec [list $midi(alt_path_midiplay)] $midi(alt_midi_options) "
        switch -- $midi(transfer_prot_2) {
            0 {set cmd [concat $cmd [list $dir/X[lindex $sel 0].mid]]}
            1 {set cmd [concat $cmd $files]}
            2 {set cmd [concat $cmd $dir]}
        }
    } else {
        # player 1
        set cmd "exec [list $midi(path_midiplay)] $midi(midiplay_options) "
        switch -- $midi(transfer_prot_1) {
            0 {set cmd [concat $cmd [list $dir/X[lindex $sel 0].mid]]}
            1 {set cmd [concat $cmd $files]}
            2 {set cmd [concat $cmd $dir]}
        }
    }
    set cmd [concat $cmd &]
    set exec_out $exec_out\n\n$cmd
    #puts $cmd
    eval $cmd
}


set yaps_ptsize {612x792 792x1224 1224x792 612x1008 396x612 540x720 \
            840x1189 594x840  419x594 727x1030 515x727 612x936 \
            612x777  720x1008}


proc display_action {} {
    global midi
    global console_clock
    global active_sheet
    global exec_out
    set console_clock [clock seconds]
    set sel [title_selected]
    copy_selected_files $sel w 0 [list $midi(midi_dir)/X.tmp]
    display_tunes [list $midi(midi_dir)/X.tmp]
    update_console_page
}



proc display_tunes {abcfile} {
    global midi
    global yaps_ptsize exec_out
    if {$midi(ps_creator) == "yaps"} {
        # YAPS
        set M $midi(yaps_lmargin)x$midi(yaps_tmargin)
        set yapsopt ""
        append yapsopt " -N -o Out.ps \
                -P [lindex $yaps_ptsize $midi(papersize)] -s $midi(yaps_scale) -M $M"
        if {$midi(yaps_voice)} {append yapsopt " -V"}
        if {$midi(yapsx)} {append yapsopt " -x"}
        if {$midi(yaps_landscape)} {append yapsopt " -l"}
        if {$midi(yaps_bbar)} {append yapsopt " -k"}
        set cmd "exec [list $midi(path_yaps)] [list $abcfile] $yapsopt"
        catch {eval $cmd} exec_out
        if {[string first "no such" $exec_out] >= 0} {abcmidi_no_such_error $midi(path_yaps)}
        
    } elseif {$midi(ps_creator) == "other"} {
        set cmd "exec [list $midi(path_otherps)] [list $abcfile] $midi(otherps)"
        catch {eval $cmd} exec_out
        
    } else {
        # abc2ps and abcm2ps
        set abc2psopt ""
        switch -- $midi(ps_fmt_flag) {
            0  {append abc2psopt " -s $midi(ps_scale) \
                        -a $midi(ps_shrink) -m $midi(ps_lmargin) \
                        -w $midi(ps_width)  \
                        -d $midi(ps_staffsep)"}
            1  {append abc2psopt " -p"}
            2  {append abc2psopt " -P"}
            3  {append abc2psopt " -F [list $midi(ps_fmt_file)]"}
            4  {append abc2psopt " -l "}
        }
        
        if {$midi(ps_c)}     {append abc2psopt " -c"}
        if {$midi(ps_bxref)} {append abc2psopt " -x"}
        if {$midi(ps_bhist)} {append abc2psopt " -n"}
        if {$midi(ps_bbar)}  {append abc2psopt " -k 1"}
        if {$midi(ps_bnumb)} {append abc2psopt " -N"}
        if {$midi(ps_bppage)} {append abc2psopt " -1"}
        if {$midi(ps_creator) == "abc2ps"} {
            set abc2psopt [concat $abc2psopt " -g $midi(ps_glue)"]
            if {[string length $midi(ps_maxvent)] > 0} {
                set abc2psopt [concat $abc2psopt -maxv $midi(ps_maxvent)]}
            if {[string length $midi(ps_maxsent)] > 0} {
                set abc2psopt [concat $abc2psopt -maxs $midi(ps_maxsent)]}
            if {$midi(bpsvoice)} {append $abc2psopt " -V $midi(psvoice)"}
        }
        if {$midi(ps_creator) == "abcm2ps"} {
            if {$midi(ps_nolyric)} {
                set abc2psopt [concat $abc2psopt -M]}
            if {$midi(ps_noslur)} {
                set abc2psopt [concat $abc2psopt -G]}
        }
        
        if {$midi(ps_creator) == "abcm2ps" \
                    && [string length $midi(ps_other_options)] > 1} {
            set abc2psopt [concat $abc2psopt $midi(ps_other_options)]}
        
        if {$midi(ps_creator) == "abcm2ps"} {
            set cmd "exec [list $midi(path_abcm2ps)] \
                    [list $abcfile] $abc2psopt"} else {
            set cmd "exec [list $midi(path_abc2ps)] \
                    [list $abcfile] $abc2psopt -o"}
        
        catch {eval $cmd} exec_out
    }
    set exec_out "$cmd\n\n$exec_out"
    set cmd "exec [list $midi(path_gs)] Out.ps &"
    set exec_out "$exec_out\n\n$cmd"
    eval $cmd
}

proc display_tunes_thru_x_tmp {abcfile} {
    global midi console_clock
    file copy -force $abcfile  $midi(midi_dir)/X.tmp
    set console_clock [clock seconds]
    display_tunes [list $midi(midi_dir)/X.tmp]
}

proc midisave {} {
    global midi
    global sel ;# sel is passed around to other midisave_.. proc
    set sel [title_selected]
    if {[llength $sel] < 2} {
        midisave_single} else {
        midisave_list}
    if {$midi(bell_on)} bell
}

proc midisave_single {} {
    global midi miditype
    global nvoices
    set sel [title_selected]
    if {$midi(double)} {
        if {$nvoices == 0} {set xsel [create_tmp_voiced_abc $sel]
        } else {
            midi1_msg "cannot duplicate voice in multivoiced tune"
            set xsel [tune_picked $sel $midi(abc_open)]
        }
    } else {
        set xsel [tune_picked $sel $midi(abc_open)]
    }
    set cmd "exec [list $midi(path_abc2midi)] [list $midi(midi_dir)/X.tmp]"
    if {$midi(barflymode)} {append cmd " -BF $midi(stressmodel)"}
    catch {eval $cmd} exec_out
    set filedir [file dirname $midi(midi_save)]
    set filename [tk_getSaveFile -initialdir $filedir -filetypes $miditype]
    #  remove mid extension if present
    set namesplit [split $filename .]
    set mid [lsearch $namesplit mid]
    if {$mid != -1} {
        set namesplit [lreplace $namesplit $mid $mid]}
    set mid [lsearch $namesplit MID]
    if {$mid != -1} {
        set namesplit [lreplace $namesplit $mid $mid]}
    set filename ""
    foreach elem $namesplit {
        set filename $filename$elem}
    if {$filename != ""} {
        set midi(midi_save) $filename
        file rename -force $midi(midi_dir)/X$xsel.mid $filename.mid
    }
    update_console_page
}

proc midisave_list {} {
    global midi
    midisave_tool
}

proc midisave_list_continue {} {
    global midi
    global nvoices
    set dirname [tk_chooseDirectory]
    if {[string length $dirname] < 1} return
    file mkdir $dirname
    set sel [title_selected]
    if {$midi(double)} {
        if {$nvoices == 0} {set xsel [create_tmp_voiced_abc $sel]
        } else {
            midi1_msg "cannot duplicate voice in multivoiced tune"
            set xsel [tune_picked $sel $midi(abc_open)]
        }
    } else {
        set xsel [tune_picked $sel $midi(abc_open)]
    }
    set cmd "exec [list $midi(path_abc2midi)] [list $midi(midi_dir)/X.tmp]"
    if {$midi(barflymode)} {append cmd " -BF $midi(stressmodel)"}
    catch {eval $cmd} exec_out
    set i 0
    foreach tune $sel {
        set title [extract_title_of_tune $tune $midi(abc_open)]
        set title [string range $title 0 $midi(namelen)]
        set n [lindex $xsel $i]
        set m [format "%04d" $n]
        if {$midi(name)} {
            file rename -force $midi(midi_dir)/X$n.mid $dirname/$title.mid} else {
            file rename -force $midi(midi_dir)/X$n.mid $dirname/$midi(nameroot)$m.mid}
        incr i
    }
    pack forget .abc.midisavetool
    update_console_page
}

proc midisave_tool {} {
    global midi
    global df
    global sel
    set p .abc.midisavetool
    set midi(nameroot) [file root [file tail $midi(abc_open)]]
    set n [llength $sel]
    $p.1 configure -text "You are creating $n midi files" -font $df
    pack $p
}


################################
#      Support Functions       #
################################

startup_progress "loading support functions"

proc update_history {openfile} {
    global midi history_index df
    
    #check if file is in history
    for {set i 0} {$i < $midi(history_length)} {incr i} {
        if {[string compare $midi(history$i) $openfile] ==  0} return
    }
    
    if {$midi(history_length) == 0}  {
        .abc.file.menu.type add radiobutton  -value 0 -font $df\
                -variable history_index -command process_history
    }
    
    # push history down open stack
    for {set i $midi(history_length)} {$i > 0} {incr i -1}  {
        set j [expr $i -1]
        set k [expr $i +1]
        set midi(history$i) $midi(history$j)
        if {$midi(history_length) < 10 && $i == $midi(history_length)} {
            .abc.file.menu.type add radiobutton  -label $midi(history$i) \
                    -value $i -variable history_index\
                    -font $df -command process_history
        } else {
            .abc.file.menu.type entryconfigure $k -label $midi(history$j)
        }
    }
    set midi(history0) $openfile
    .abc.file.menu.type entryconfigure 1 -label $midi(history0)
    if {$midi(history_length) < 10} {incr midi(history_length)}
}

proc process_history {} {
    global midi history_index active_sheet
    if {![file exist $midi(history$history_index)]} {
        show_message_page\
                "can't read input abc file\n$midi(history$history_index)" word
        return
    }
    set midi(abc_open) $midi(history$history_index)
    .abc.file.entry xview moveto 1.0
    title_index $midi(abc_open)
    if {$active_sheet != "titles"} {show_titles_page}
    if {[winfo exist .abcedit]} {
        .abcedit.func.file.actions entryconfigure 3 -state disable}
    update
}


proc file_browser {} {
    global midi types
    global active_sheet
    
    set filedir [file dirname $midi(abc_open)]
    set openfile [tk_getOpenFile -initialdir $filedir \
            -filetypes $types]
    open_abc_file $openfile
}


proc open_abc_file {filename} {
    global midi active_sheet
    if {[string length $filename] > 0} {
        #       if {[string equal $filename $midi(abc_open)]} return
        set midi(abc_open) $filename
        if {[winfo exist .abcedit]} {
            .abcedit.func.file.actions entryconfigure 3 -state disable}
        .abc.file.entry xview moveto 1.0
        title_index $midi(abc_open)
        update_history $filename
        if {$active_sheet != "titles"} {show_titles_page}
    }
}

# Part 7.0       TOC creator

#
# the function scans the entire abcfile making a list of titles and
# storing the file location of each tune. Code X: T: must begin on the
# first character position of a line.
#
proc title_index {abcfile} {
    global fileseek midi
    global abc_file_mod
    global item_id
    global index_done
    global df
    if {[info exist first_title_item]} {unset first_title_item}
    #    puts "title_index [info level 0]"
    set abc_file_mod 0
    #    puts "title_index abc_file_mod reset"
    set srch X
    set pat {[0-9]+}
    #.abc.titles.t selection set {}
    .abc.titles.t delete [.abc.titles.t children {}]
    set titlehandle [open $abcfile r]
    set filepos 0
    set meter 4/4
    set i 0
    .abc.titles.t tag configure tune -font $df
    while {[gets $titlehandle line] >= 0} {
        if {!$midi(blank_lines) && [string length $line] < 1} {set srch X}
        if {[string index $line 0] == "M"} {
            set meter [string range $line 2 end]
            set meter [string trim $meter]
        }
        switch -- $srch {
            X {if {[string compare -length 2 $line "X:"] == 0} {
                    regexp $pat $line  number
                    set srch T
                } else {
                    set filepos [tell $titlehandle]
                }
            }
            T {
                if {[string index $line 0] == "T" || [string index $line 0] == "P"} {
                    set name [string range $line 2 end]
                    set name [string trim $name]
                    set srch K
                }
            }
            K {
                if {[string index $line 0] == "K"} {
                    set keysig [string range $line 2 end]
                    set keysig [string trim $keysig]
                    set keysig [string range $keysig 0 15]
                    set outline [format "%4s  %-5s %s %s" $number [list $keysig] $meter [list $name]]
                    set toc_index [.abc.titles.t insert {}  end -values $outline -tag tune]
                    set item_id($i) $toc_index
                    set fileseek($toc_index) $filepos
                    if {![info exist first_title_item]} {
                        .abc.titles.t focus $toc_index
                        .abc.titles.t selection set $toc_index
                        set first_title_item $toc_index
                        update
                    }
                    
                    
                    set srch X
                    incr i
                    if {[expr $i % 20] == 0} update
                }
            }
        }
    }
    close $titlehandle
    if {$i == 0} {show_error_message "corrupted file $midi(abc_open)\nno K:,X:,T: found in file."
                  return}
    if {$i < 15} {
        .abc.titles.t configure -height [expr $i + 1]
        set midi(abc_save) $midi(abc_open)
    } else {
        .abc.titles.t configure -height 15
        set midi(abc_save) edit.abc
    }
    .abc.titles.t see $first_title_item
    update
}

proc SortBy {col direction} {
    set data {}
    foreach row [.abc.titles.t children {}] {
        lappend data [list [.abc.titles.t set $row $col] $row]
    }
    
    set dir [expr {$direction ? "-decreasing" : "-increasing"}]
    set r -1
    
    
    
    # Now reshuffle the rows into the sorted order
    foreach info [lsort -dictionary -index 0 $dir $data] {
        .abc.titles.t  move [lindex $info 1] {} [incr r]
    }
    # Switch the heading so that it will sort in the opposite direction
    .abc.titles.t heading $col -command [list SortBy  $col [expr {!$direction}]]
    
}


# returns position in list
proc title_selected {} {
    global abc_file_mod
    global midi
    if {$abc_file_mod}  {title_index $midi(abc_open)}
    set index [.abc.titles.t selection]
    return $index
}


proc get_nonblank_line {handle} {
    set line ""
    while {[string length $line] == 0 && [eof $handle] != 1} {
        gets $handle line
    }
    return $line
}

proc get_next_line {handle} {
    gets $handle line
    return $line
}



# Part 8.0              Extract Tune


# finds X: command or else returns nothing if eof
proc find_X_code {handle} {
    set line 1
    while {[string index $line 0] != "X" && [eof $handle] !=1} {
        set line [get_nonblank_line $handle]
    }
    return $line
}


proc get_title {handle} {
    set line 1
    while {[string index $line 0] != "T" && [string index $line 0] != "P" && [eof $handle] !=1} {
        set line [get_nonblank_line $handle]
    }
    return [string range $line 2 end]
}


# The next two functions are used to map a string in V: to a number.
proc  init_voicecodebook {} {
    global voicecodes
    array unset voicecode
    set voicecodes 0
}

proc vcode2numb {code} {
    global voicecodes voicecode
    if {[info exist voicecode($code)]} {
        return $voicecode($code)} else {
        incr voicecodes
        set voicecode($code) $voicecodes}
    return $voicecodes
}


#
# The function copies the selected tunes into an abc
# file called X.tmp (in midi(midi_dir)).
# After the X:n command, all the %%MIDI commands are
# sent as well as a Q: tempo # command.
# Depending upon options any %%MIDI commands
# in the input file or any tempo commands will be
# ignored.  When a M: command is encountered the
# program may issue a %%MIDI gchord command.
#
# The function returns a list with the selected tune numbers
#
proc tune_picked {tunes abcfile} {
    global fileseek
    global midi
    global defaultdrumpat
    
    set inp_fd [open $abcfile r]
    set out_fd [open $midi(midi_dir)/X.tmp w]
    set pat {[0-9]+|C|C\|}
    set outlist ""
    set dronestatus 0
    
    init_voicecodebook
    foreach i $tunes {
        set loc $fileseek($i)
        #    puts "tune_picked seeking to $loc for $i"
        seek $inp_fd $loc
        
        for {set j 0} {$j < 17} {incr j} {set voice($j) 0}
        
        # The procedure expects to see an X command here. Otherwise it is
        # an error.
        set line [find_X_code $inp_fd]
        if {[string index $line 0] == "X"} {
            puts $out_fd $line
            scan $line "X:%d" track
            lappend outlist $track
            write_midi_codes $out_fd
            puts $out_fd "Q:1/4 = $midi(tempo)"
            set line [get_nonblank_line $inp_fd]
            set body 0
        } else {
            puts "tune picked did not find X_code"
            title_index $midi(abc_open)
            return $outlist
        }
        
        while {[string length $line] > 0 && [string index $line 0] != "X"} {
            set code [string range $line 0 1]
            switch -- $code {
                M: {regexp $pat $line meter
                    puts $out_fd $line
                    if {$midi(bmychord) && [info exist midi(mychord)]} {
                        puts $out_fd "%%MIDI gchord $midi(mychord)"
                    }
                }
                Q: {if {$midi(ignoreQ) == 0} {
                        puts $out_fd $line}
                }
                %% {if {$midi(ignoremidi) == 1} {
                        # %%MIDI command: suppress only program, bassprog, and chordprog
                        # the rest including gchord, drum etc goes through
                        set midicommandlist [split $line]
                        set cmnd [lindex $midicommandlist 1]
                        if {$cmnd == "program" || $cmnd == "bassprog" \
                                    || $cmnd == "chordprog" || $cmnd == "chordvol" \
                                    || $cmnd == "bassvol"}  {
                            set suppress 1} else {
                            set suppress 0}
                        if {!$suppress} {puts $out_fd $line}
                    } else {
                        puts $out_fd $line
                    }
                }
                V: {set payload [string range $line\
                            [expr [string first : $line] +1] end]
                    set payload [string trimleft $payload]
                    set vcode [lindex [split $payload] 0]
                    puts $out_fd $line
                    if {[string is integer $vcode] != 1} {
                        set vc [vcode2numb $vcode]
                    } else {
                        scan $line "V:%d" vc}
                    if {$vc < 17} {
                        if {$voice($vc) == 0} {
                            puts $out_fd "%%MIDI program $midi(voice$vc)"
                            puts $out_fd "%%MIDI control 7 $midi(lvoice$vc)"
                            puts $out_fd "%%MIDI control 10 $midi(pvoice$vc)"
                            puts $out_fd "%%MIDI beat $midi(beat_a) $midi(beat_b) \
                                    $midi(beat_c) $midi(beat_n)"
                            set voice($vc) 1
                        }
                    }
                }
                K:  {
                    if {$midi(octave) != 0} {append line " octave=$midi(octave)"}
                    puts $out_fd $line
                    set payload [string range $line\
                            [expr [string first : $line] +1] end]
                    set payload [string trimleft $payload]
                    set payload [string toupper $payload]
                    if {!$body && $midi(drone) && [string compare $payload "HP"]==0} {
                        puts $out_fd "%%MIDI drone 70 45 33 $midi(tenordrone) $midi(bassdrone)"
                        set dronestatus 1
                        puts $out_fd "%%MIDI droneon"}
                    if {!$body && $midi(drumon)} {
                        if {$midi(mydrum)} {
                            puts $out_fd "%%MIDI drum $midi(drumpat)"} else {
                            if {[info exist defaultdrumpat($meter)]} {
                                puts $out_fd "%%MIDI drum $defaultdrumpat($meter)"
                                set midi(drumpat) $defaultdrumpat($meter)}
                            if {[string length $midi(drumpat)] > 50} {
                                set drumcodelabel [string range $midi(drumpat) 0 50]...} else {
                                set drumcodelabel $midi(drumpat)}
                            .abc.midi1.drumpat.pat configure\
                                    -text $drumcodelabel
                        }
                        puts $out_fd "%%MIDI drumon"}
                    set body 1
                }
                default { puts $out_fd $line }
            }
            if {$midi(blank_lines)} {
                set line [get_nonblank_line $inp_fd]} else {
                set line [get_next_line $inp_fd]}
        }
        if {$dronestatus} {puts $out_fd "%%MIDI droneoff"}
        puts $out_fd "\n"
    }
    close $inp_fd
    close $out_fd
    return $outlist
}

proc eliminate_guitar_chords {line} {
    regsub -all  {"[^"]*"} $line "" result
    return $result
}

proc suppress_midicommand {line} {
    set midicommandlist [split $line]
    set cmnd [lindex $midicommandlist 1]
    if {$cmnd == "program" || $cmnd == "bassprog" \
                || $cmnd == "chordprog" || $cmnd == "chordvol" \
                || $cmnd == "bassvol" || $cmnd == "gchord"}  {
        set suppress 1} else {
        set suppress 0}
    return $suppress
}

proc create_tmp_voiced_abc {tunes} {
    #This is another version of tunepicked {} function customized
    #to create two voices from one. The main complexity is handling
    #multipart tunes. We need to keep the voices separate in each
    #part.
    global  fileseek
    global  midi
    global titlename
    global defaultdrumpat
    set pat {[0-9]+|C|C\|}
    set rhythm ""
    set output_handle [open $midi(midi_dir)/X.tmp w]
    set xreflist {}
    
    
    set edit_handle [open $midi(abc_open) r]
    foreach ref $tunes {
        set inbody 0
        set loc  $fileseek($ref)
        seek  $edit_handle $loc
        gets $edit_handle line
        if {[string index $line 0] == "X"} {
            scan $line "X:%d" xref
            lappend xreflist $xref
        }
        puts $output_handle X:$xref
        write_midi_codes $output_handle
        puts $output_handle "Q:1/4=$midi(tempo)"
        set block(0) ""
        set bn 0
        
        while {[string length $line] > 0} {
            gets $edit_handle line
            if {$midi(ignoremidi) == 1 && [string range $line 0 1] == "%%"} {
                set donotwrite [suppress_midicommand $line]
            } else {set donotwrite 0}
            if {[string length $line] < 1} break;
            if {!$inbody && !$donotwrite} {puts $output_handle $line}
            if {[string first R: $line] == 0} {
                set rhythm [string range $line 2 end]
                set rhythm [string trimleft $rhythm]
            }
            if {[string first M: $line] == 0} {
                regexp $pat $line meter
            }
            if {$inbody} {
                if {[string first P: $line] == 0} {
                    incr bn
                    set block($bn) ""
                    set blockname($bn) [string range $line 2 end]
                } elseif {!$donotwrite} {
                    append block($bn) $line\n}
            }
            if {[string first K: $line] == 0 && $inbody == 0} {
                set inbody 1
                set block($bn) ""
                set blockname($bn) ""
                if {$midi(bmychord) && [info exist midi(mychord)]} {
                    puts $output_handle "%%MIDI gchord $midi(mychord)"
                }
                if {$midi(drumon)} {
                    if {$midi(mydrum)} {
                        puts $output_handle "%%MIDI drum $midi(drumpat)"} else {
                        if {[info exist defaultdrumpat($meter)]} {
                            puts $output_handle "%%MIDI drum $defaultdrumpat($meter)"
                            set midi(drumpat) $defaultdrumpat($meter)}
                        if {[string length $midi(drumpat)] > 50} {
                            set drumcodelabel [string range $midi(drumpat) 0 50]...} else {
                            set drumcodelabel $midi(drumpat)}
                        .abc.midi1.drumpat.pat configure\
                                -text $drumcodelabel
                    }
                    puts $output_handle "%%MIDI drumon"}
            }
        }
        # finished reading tune
        if {$bn == "0"} {
            puts $output_handle "V:1 octave=$midi(octave)"
            puts -nonewline $output_handle $block($bn)
            
            if {$midi(octave2) !=0} {
                puts $output_handle "V:2 octave=$midi(octave2)"} else {
                puts $output_handle "V:2"}
            puts $output_handle "%%MIDI program $midi(program2)"
            puts $output_handle "%%MIDI beat $midi(beat2_a) $midi(beat2_b) $midi(beat2_c) $midi(beat_n)"
            set block($bn) [eliminate_guitar_chords $block($bn)]
            puts $output_handle $block($bn)
        }  else {
            if {[info exist block(0)]} {
                puts -nonewline $output_handle $block(0)
            }
            for {set i 1} {$i <= $bn} {incr i} {
                puts $output_handle P:$blockname($i)
                puts $output_handle V:1
                puts -nonewline $output_handle $block($i)
                puts $output_handle V:2
                if ($i==1) {
                    puts $output_handle "%%MIDI program $midi(program2)"
                    puts $output_handle "%%MIDI beat $midi(beat2_a) $midi(beat2_b) $midi(beat2_c) $midi(beat_n)"
                    if {$midi(octave2) !=0} {
                        puts $output_handle "V:2 octave=$midi(octave2)"} else {
                        puts $output_handle "V:2"}
                }
                set block($i) [eliminate_guitar_chords $block($i)]
                puts -nonewline $output_handle $block($i)
            }
        }
    }
    close $output_handle
    close $edit_handle
    #if {[string length $rhythm] > 1} {append titlename " - $rhythm"}
    
    return $xreflist
}


proc write_midi_codes {outfd} {
    global midi
    global m
    
    set i1 [expr int(1 + $midi(program)/8)]
    set i2 [expr $midi(program)  % 8 ]
    set mel_instrum [lindex $m($i1) $i2]
    set i1 [expr int(1 + $midi(bassprog)/8)]
    set i2 [expr $midi(bassprog)  % 8 ]
    set bass_instrum [lindex $m($i1) $i2]
    set i1 [expr int(1 + $midi(chordprog)/8)]
    set i2 [expr $midi(chordprog)  % 8 ]
    set chord_instrum [lindex $m($i1) $i2]
    
    set mid "%%MIDI"
    puts $outfd "$mid channel $midi(channel)"
    puts $outfd "$mid chordprog $midi(chordprog) octave=$midi(chord_octave) % $chord_instrum"
    puts $outfd "$mid bassprog $midi(bassprog) octave=$midi(bass_octave) % $bass_instrum "
    puts $outfd "$mid program $midi(program) % $mel_instrum"
    puts $outfd "$mid beat $midi(beat_a) $midi(beat_b) \
            $midi(beat_c) $midi(beat_n)"
    puts $outfd "$mid ratio $midi(ratio_n) $midi(ratio_m)"
    puts $outfd "$mid chordvol $midi(chordvol)"
    puts $outfd "$mid bassvol $midi(bassvol)"
    puts $outfd "$mid transpose $midi(transpose)"
    puts $outfd "$mid gracedivider $midi(gracedivider)"
}


startup_progress "loading editor functions"


# Part 9.0                     Functions for Manipulating abc tune file

# Tcl Editor and Support Functions


proc copy_selection_to_file {tunes abcfile outfile} {
    global fileseek midi exec_out
    global copyfromloc copytoloc
    
    if {[string compare [file tail $abcfile] [file tail $outfile]] == 0} return
    set edithandle [open $abcfile r]
    set outhandle [open $outfile w]
    
    set exec_out "copying $tunes to $outfile"
    foreach i $tunes {
        set loc $fileseek($i)
        set copyfromloc $loc
        seek $edithandle $loc
        set line [find_X_code $edithandle]
        puts $outhandle $line
        while {[string length $line] > 0 } {
            set copytoloc [tell $edithandle]
            if {$midi(blank_lines)} {
                set line  [get_nonblank_line $edithandle]} else {
                set line  [get_next_line $edithandle]}
            if {[string index $line 0] == "X"} break;
            puts $outhandle $line
        }
        puts $outhandle ""
    }
    
    close $edithandle
    close $outhandle
    if {$midi(bell_on)} bell
}




proc extract_title_of_first_tune {tunes abcfile} {
    set tune [lindex $tunes 0]
    extract_title_of_tune $tune $abcfile
}


proc extract_title_of_tune {tune abcfile} {
    global fileseek midi
    set loc $fileseek($tune)
    set edithandle [open $abcfile r]
    seek $edithandle $loc
    set title [get_title $edithandle]
    close $edithandle
    set title [string trimleft $title]
    set comloc [string first "%" $title]
    if {$comloc > 3} {set title [string range $title 0 [expr $comloc-1]]}
    set title [string trimright $title]
    if {[string length $title] <1} {set title notitle}
    set pat \[\"\/\\\*:\;\?\.\^\]
    regsub -all $pat $title "" result
    set title [string map {\040 _ \\ ""} $result]
    
}

proc split_abc_file {} {
    #separates selected tunes and puts them in separate
    #files in the folder with the filename called $midi(abc_open)
    global midi fileseek
    set abcfile $midi(abc_open)
    set filedir [file rootname $abcfile]
    set pat \[\"\/\\\*:\;\?\.\^\]
    set numpat {[0-9]+}
    set sel [title_selected]
    file mkdir $filedir
    set edithandle [open $abcfile r]
    foreach i $sel {
        set loc $fileseek($i)
        seek $edithandle $loc
        set title [get_title $edithandle]
        set title [string trimleft $title]
        regsub -all $pat $title "" result
        set title [string map {\040 _ \\ ""} $result]
        set title [string trimright $title]
        seek $edithandle $loc
        set line [find_X_code $edithandle]
        regexp $numpat $line  number
        if {[file exist $filedir/$title.abc]} {set title $title-$number}
        set outhandle [open [file join  $filedir $title.abc ] w]
        puts $outhandle $line
        while {[string length $line] > 0 } {
            if {$midi(blank_lines)} {
                set line  [get_nonblank_line $edithandle]} else {
                set line  [get_next_line $edithandle]}
            if {[string index $line 0] == "X"} break;
            puts $outhandle $line
        }
        puts $outhandle ""
        close $outhandle
    }
    close $edithandle
    set acknowledge "[llength $sel] files created in the folder $filedir"
    messages $acknowledge
}


proc edit_new_tune {} {
    global midi
    
    set outfd [open $midi(abc_default_file) w]
    puts $outfd "X: 1"
    puts $outfd "T: Title"
    puts $outfd "C: Composer"
    puts $outfd "M: 2/4"
    puts $outfd "L: 1/8"
    puts $outfd "K: G"
    close $outfd
    abc_edit midi(abc_default_file)
}


proc edit_empty_file {} {
    global midi
    set outfd [open $midi(abc_default_file) w]
    close $outfd
    tcl_abc_edit $midi(abc_default_file) 1
}


proc start_copy_selected_files {access renumber} {
    global midi
    set sel [title_selected]
    if {$sel == -1} return
    set types {{{abc files} {*.abc}}
        {{all} {*}}}
    set filedir [file dirname $midi(abc_default_file)]
    set filename [tk_getSaveFile -initialdir $filedir \
            -filetypes $types]
    if {[string length $filename] == 0} return
    if {[string compare  $midi(abc_open) $filename] == 0} {
        tk_messageBox -message "do not even think of writing over the input file" \
                -type ok
        return
    }
    copy_selected_files $sel $access $renumber $filename
}

proc copy_message {} {
    set w .abc.copy
    toplevel $w
    focus $w
    message $w.msg -text "The program will renumber the x ref sequentially \
            starting from" -width 200
    frame $w.fr
    entry $w.fr.ent -width 5 -textvariable midi(startnumber)
    button $w.fr.ok -text ok -command {destroy .abc.copy}
    pack $w.msg -side top
    pack $w.fr.ent $w.fr.ok -side left
    pack $w.fr
    grab $w
    tkwait window $w
}


proc copy_selected_files {sel access renumber filename} {
    #copies or appends all selected tunes to an output file
    global fileseek midi exec_out
    if {$renumber} copy_message
    set edithandle [open $midi(abc_open) r]
    set outhandle [open $filename $access]
    set n $midi(startnumber)
    set exec_out "copying $sel to $filename"
    foreach i $sel {
        set loc $fileseek($i)
        seek $edithandle $loc
        set line [find_X_code $edithandle]
        if {$renumber} {puts $outhandle "X: $n"} else {puts $outhandle $line}
        incr n
        while {[string length $line] > 0 } {
            if {$midi(blank_lines)} {
                set line  [get_nonblank_line $edithandle]} else {
                set line  [get_next_line $edithandle]}
            if {[string index $line 0] == "X"} break;
            puts $outhandle $line
        }
        puts $outhandle "\n"
    }
    close $edithandle
    close $outhandle
}


# These are special procedures designed to take
# Laura Conrads renaissance music in her allparts.abc
# files and reformat them so each part is a separate voice
# instead of a separate tune. The procedure eliminates
# multiple copies of the lyrics, replaces the X:
# with a V: and eliminates and T: fields occurring
# in the other voices. Unfortunately, the functions
# do not do everything and some hand editing may
# necessary.

proc concat_parts {tunes abcfile outfile} {
    global fileseek midi
    set body 0
    set first_tune 1
    set edithandle [open $midi(abc_open) r]
    set outhandle [open $outfile w]
    foreach i $tunes {
        
        #   either put a X:n field or a V:n field for the tune depending
        #   on whether this is the first selection or not. The variable
        #   body signals the first time we reach the body of one of
        #   the abc tunes.
        set loc $fileseek($i)
        seek $edithandle $loc
        set line [find_X_code $edithandle]
        if {$first_tune} {puts $outhandle $line} else {
            puts $outhandle V:[expr 1+$i]}
        
        #   for the rest of the tune we strip out the lyrics (w:) and
        #   title, if it is not the first part. For the first selection
        #   we find the start of the body, (prior to K:) and insert a
        #   V:1 field
        #
        while {[string length $line] > 0 } {
            if {$midi(blank_lines)} {
                set line  [get_nonblank_line $edithandle]} else {
                set line  [get_next_line $edithandle]}
            if {[string index $line 0] == "X"} break;
            if {$first_tune} {
                #           first part
                if {[string index $line 0] == "K" && $body == 0} {
                    puts $outhandle "V:1"
                    set body 1}
                puts $outhandle $line} else   {
                #           remaining parts
                if {[string index $line 0] == "w" || \
                            [string index $line 0] == "T" } {continue} else {
                    puts $outhandle $line}
            }
        }
        set first_tune 0
    }
    puts $outhandle ""
    close $edithandle
    close $outhandle
    if {$midi(bell_on)} bell
}


proc combine_parts {} {
    global midi
    set sel [title_selected]
    if {$sel == -1} return
    set types {{{abc files} {*.abc}}
        {{all} {*}}}
    set filedir [file dirname $midi(abc_default_file)]
    set filename [tk_getSaveFile -initialdir $filedir \
            -filetypes $types]
    concat_parts $sel $midi(abc_open) $filename
}

proc abc_edit {varname} {
    upvar #0 $varname abcfile
    global midi exec_out
    
    if {[string length $midi(path_editor)] > 1} {
        set cmd "exec [list $midi(path_editor)] [list $abcfile] &"
        catch {eval $cmd} exec_out
        set exec_out $cmd\n\n$exec_out
        update_console_page
    } else {
        tcl_abc_edit $abcfile 1
    }
}


# Part 10.0            Abc Editor Functions

set hlp_editor \
        "TclAbcEditor\n\n\
        The program edits either the selected tune or the entire abc file. If \
        your computer is slow and the abc file is very large, it is recommended\
        that you limit your selection to one or a few tunes. The editor syntax\
        highlights the different abc components, (field commands like X:, comments\
        and body). The highlighting is done in real time while you are editing\
        the text; however, if for some reason the highlighting appears incorrect,\
        you can restore the correct colours by clicking the clean/retag button.\
        The choice of colours for syntax highlighting can be changed by\
        editing the variables edit_body_colour, edit_field_colour etc in\
        the runabc.ini file.)\n\n\
        The editor does not display the global headers in the source file;\
        however, you have the option of importing them using the file\
        menu item in the abcedit window.\n\n\
        The undo button or the <cntl-z> key will undo\
        any of your changes. You have unlimited undo's provided there is sufficient\
        memory in your computer. The redo button or the <cntl-y> keys on Windows\
        or the <cntl-Z> keys on all other platforms, will redo your changes.\n\n\
        When you edit selected tunes, the program makes a copy\
        of these tunes in a temporary file specified by the variable abc_default_file \
        in your runabc.ini file. (By default it is called edit.abc but you are able to\
        change it by editing the runabc.ini file.) The file edit.abc is then renamed to\
        a new file name based on the title of the first tune  and placed in your\
        abc_work_folder directory also specified in runabc.ini. (Initially it is\
        set to the name workfold.) Note that if a file of the same name already\
        exists in that work folder, it will be overwritten without warning.\n\n\
        A guitar toolbox and a grace notes toolbox are displayed to the\
        left of the edit window. Separate help buttons on these toolboxes\
        describe their operation. You may shift the toolboxes out to the\
        right, if they are in your way.\n\n\
        Description of menu options:\n\n\
        The play button is designed to play a small \
        portion of the file. You can either play a single text line positioned \
        at your insert cursor or else you play a selected area. To designate a \
        selected area,  hold the left mouse button down and sweep an \
        area with your cursor in the edit window.  Avoid selecting an area \
        starting with a line feed.  The tcl/tk script will search backwards \
        for the X: and other field commands occurring before your highlighted \
        area and also use this  information for creating the midi file.\n\n\
        The 'play all' item allows you to play the edit window exactly as\
        written (verbatim) or to also include the MIDI indications that\
        you set under abcmidi/options. If the window already has MIDI\
        indications, they may not be overridden depending on your settings.\n\n\
        It is recommended that you use a midi player which either \
        automatically closes when the selection completes playing or one which \
        stays open and automatically captures other selections when you click \
        the play button again. On Microsoft Windows, I use either Winamp or \
        the new Windows Media Player. On Unix, I use timidity without any \
        user interface. If for some reason the play button does not produce \
        audio output but normally works when you do not run the editor, check \
        the console window or the X.tmp file to determine what has happened.\n\n\
        If you save over an existing abc file, it is a good idea to ensure \
        that you have a backup of this file since I cannot guarantee the software \
        is bug free.\n\n\
        The editor provides several  other features specificly designed for \
        abc files. These are accessible through the menu items clean and tools \
        for which there are other help messages. In particular there is a find \
        tool for searching for particular strings in editor window starting from\
        the current cursor position. Enter the string in the entry box and search \
        either forwards  or backwards. This search is case sensitive. To find \
        a particular barline, enter its sequence number starting from 1 in the \
        entry box and press the barline button. Barlines or double barlines are \
        counted from the first X: reference number preceding the insert cursor \
        position.\n\n\
        The tools/align bars improves the appearance and readablity\
        by putting spaces before the bar lines so that they line up\
        vertically. If the algorithm works correctly, the formatting\
        should  not change the way the music is converted to a postscript\
        file or midi file. The function is applied on the entire contents\
        of the edit window; therefore, you should only load a single tune.\n\
        The tools/squeeze bars does the reverse of above. It replaces\
        any sequence of spaces with a single space. The tune is harder to\
        read but otherwise it is the same as before.\n\n\n\n\
        Text Widget standard binding.
<Button-1> Set the insert point, clear the selection, set focus.
<B1-Motion> Sweep out a selection from insert point.
<Shift-Button-1> Adjust the end of the selection closest to the mouse.
<Shift-Left> Move cursor and extend selection.
<Button-2> Paste the selection, or set the scrolling anchor.
<Button-2 motion> Scroll the window.
<Arrow keys> Shift insert point.
<Shift Arrow keys> Shift insert point and extend or clear selection.
<Cntl n> Shift insert point to next line.
<Cntl p> Shift insert point to previous line.
<Cntl f> Shift insert point one character to the right.
<Cntl b> Shift insert point one character to the left.
<Alt f>  Shift insert point one bar line to the left.
<Alt b>  Shift insert point one bar line to the right.
<Cntl d> Deletes character to right of the cursor.
<Cntl k> Deletes from cursor to end of the line.
<Cntl o> Inserts a new line but does not advance cursor.
<Cntl t> Transposes two characters.
<Cntl z> Undo last insert or delete. Unlimited undo's available.
<Cntl slash> Selects everything in the text widget
<Cntl backslash> Clears the selection.
<Shift arrow keys> Alter the selection.
<Delete> Delete selection if any, otherwise delete character to the right.
<Backspace> Delete selection if any, otherwise delete character to the left.

<Alt r> will raise the pitch of a note following the cursor.
<Alt l> will lower the pitch of a note following the cursor.
<Alt e> will increase (expand) the duration of the note.
<Alt c> will decrease (contract) the duration of the note.
<Alt s> will do a save as.
<Alt S> will do a save.
<Alt d> display

If you right click the mouse in the edit window, a small pop-up menu\
allows you to display or play the edited tune. If part of the tune,\
is highlighted, the play function will play just the highlighted portion.

There are many more bindings... see Tcl documentation for text widget.

On Windows you can use <cntl-c>, <cntl-x> <cntl-v> to copy, cut and \
        paste the selections. For other systems use <cntl-y> instead of <cntl-v>. \
        On some unix systems use <Cntl _> for undo."

set hlp_copy "The copy function\n\n The function will copy the\
        selected tunes in the table of contents to a designated abc\
        file. If the file does not already exist, it will create\
        a new file; otherwise, it will destroy the existing file\
        and overwrite it with the selected tunes. The X: numbers will be\
        preserved.\n\nCopy and renumber will do the same as above but it will\
        renumber the selected tunes increasing sequentially from a selected\
        number.\n\n Append will append the selected tunes to an existing file,\
        preserving the original numbering.\n\nAppend and renumber will do the\
        same but renumber the selected tunes.\n\nThe copy combine parts function is\
        specificly designed to reformat Laura Conrads renaissance music in\
        her allparts.abc files. Each part is written as a separate tune rather\
        than a separate voice. Therefore it is not possible to create a midi\
        file with all parts playing simultaneously. This function combines all\
        the parts into one tune, giving each part a separate voice.\
        Duplicate titles, and lyrics are removed. When using this function, you must\
        first select (highlight) all the tunes that you wish to combine. Like other\
        copy functions, you will prompted for the name of an output file.\n\n\
        Caution: do not try to copy over the source file already displayed in\
        the table of contents.\n\nThe function 'separate tunes' splits a multitune\
        abc file into separate files each containing one tune and puts the files\
        into a directory with the same name as the input file (without the abc\
        extension). You should select all the tunes that you want to extract\
        in the TOC before using this function. To select all tunes below the
selected tune hold the shift button while clicking on that tune."



proc confirm_save {} {
    global midi
    global abctxtw
    set choice no
    if {$midi(noconfirmsave)} {
        destroy .abcedit
        return}
    if {![winfo exist .abcedit]} return
    if {[$abctxtw edit modified]} {
        set choice [tk_messageBox -type yesno -default yes \
                -message "You have unsaved work. Do you wish to save before closing?"\
                -icon question]
    }
    if {$choice == yes} {
        set_abc_save
        if {[llength $midi(abc_save)] >0} {Text_Dump $abctxtw}
    }
    destroy .abcedit
}

proc startup_tcl_abc_edit {opt} {
    global midi
    global barpickerflag
    set barpickerflag [expr 1 - $opt]
    set outfile [extract_title_of_first_tune [title_selected] $midi(abc_open)]
    set outfile [file join $midi(abc_work_folder) $outfile.abc]
    set selected_tunes [title_selected]
    copy_selection_to_file $selected_tunes $midi(abc_open) $midi(abc_default_file)
    file mkdir "[pwd]/$midi(abc_work_folder)"
    file rename -force $midi(abc_default_file) $outfile
    if {$opt} {
      tcl_abc_edit $outfile $opt
      } else {
      tcl_abc_edit_with_voices $outfile $opt
      }      
    if {[llength $selected_tunes] > 1} {
        .abcedit.func.file.actions entryconfigure 3 -state disable}
}


proc tcl_abc_edit {abcfile toolbox} {
    global midi df
    global abctxtw
    global barpickerflag
    
    if {[winfo exists .abcedit] != 0} {
        confirm_save
        destroy .abcedit
    }
    
    toplevel .abcedit
    
    
    panedwindow .abcedit.pane -orient horizontal
    wm protocol .abcedit WM_DELETE_WINDOW confirm_save
    set midi(abc_save) $abcfile
    frame .abcedit.pane.right
    set abctxtw .abcedit.pane.right.t
    text $abctxtw -width $midi(edit_initial_width) -wrap none \
            -yscrollcommand {.abcedit.pane.right.ysbar set} \
            -xscrollcommand {.abcedit.pane.right.xsbar set} \
            -font "[list $midi(font_family_toc)] $midi(font_size) $midi(font_weight)"
    scrollbar .abcedit.pane.right.ysbar -orient vertical -command {$abctxtw yview}
    scrollbar .abcedit.pane.right.xsbar -orient horizontal -command {$abctxtw xview}
    
    entry .abcedit.file  -textvariable midi(abc_save) -width 60 -font $df
    
    tcl_abc_edit_menu_bar $abcfile
    
    
    pack .abcedit.file -side top -anchor w -fill x -expand 1
    pack .abcedit.pane.right.ysbar -side right -fill y -expand 0
    pack .abcedit.pane.right.xsbar -side bottom -fill x
    pack $abctxtw -fill both -expand 1 -side right
    
    
    if {[file exist $abcfile]} {
        set edit_handle [open $abcfile r]
        if {[eof $edit_handle] !=1} {gets $edit_handle line}
        $abctxtw insert end $line\n
        while {[eof $edit_handle] != 1} {
            gets $edit_handle line
            $abctxtw insert end $line\n
        }
        close $edit_handle
    }
    
    $abctxtw  tag configure blue -foreground blue
    
    
    $abctxtw configure -undo 1
    $abctxtw edit modified 0
    
    focus .abcedit
    # do not tag text if barpickerflag is on or else blue tag
    # will not show.
    if {!$barpickerflag} tag_text
    
    
    frame .abcedit.pane.toolbox
    .abcedit.pane add .abcedit.pane.toolbox .abcedit.pane.right
    
    pack .abcedit.pane -fill both -expand 1
    guitar_chord
    grace_toolbox
    bind $abctxtw <KeyRelease> "tag_line"

  bind $abctxtw <Button-3> {
        tk_popup .actionmenu2 %X %Y}

    if {[winfo exist .actionmenu2] != 1} {
       menu .actionmenu2
       .actionmenu2 add command -label play -command {edit_play_context}
       .actionmenu2 add command -label display -command {display_entire_edit_window}
      }
}

proc tcl_abc_edit_with_voices {abcfile toolbox} {
    global midi df
    global abctxtw
    global barpickerflag
    
    if {[winfo exists .abcedit] != 0} {
        confirm_save
        destroy .abcedit
    }
    
    toplevel .abcedit
    
    
    #panedwindow .abcedit.pane
    frame .abcedit.pane -background blue
    wm protocol .abcedit WM_DELETE_WINDOW confirm_save
    set midi(abc_save) $abcfile
    frame .abcedit.pane.tframe -background red
    set abctxtw .abcedit.pane.tframe.t
    text $abctxtw -width $midi(edit_initial_width) -wrap none \
            -xscrollcommand {.abcedit.pane.tframe.xsbar set} \
            -yscrollcommand {.abcedit.pane.tframe.ysbar set} \
            -font "[list $midi(font_family_toc)] $midi(font_size) $midi(font_weight)"
    scrollbar .abcedit.pane.tframe.ysbar -orient vertical -command {$abctxtw yview}
    scrollbar .abcedit.pane.tframe.xsbar -orient horizontal -command {$abctxtw xview}

    
    entry .abcedit.file  -textvariable midi(abc_save) -width 60 -font $df
    
    tcl_abc_edit_menu_bar $abcfile
    
    
    pack .abcedit.file -side top -anchor w -fill x
    pack .abcedit.pane.tframe.ysbar -side right -fill y
    pack .abcedit.pane.tframe.xsbar -side bottom -fill x
    pack $abctxtw -fill both -expand 1 -side right

    
    
    if {[file exist $abcfile]} {
        set edit_handle [open $abcfile r]
        if {[eof $edit_handle] !=1} {gets $edit_handle line}
        $abctxtw insert end $line\n
        while {[eof $edit_handle] != 1} {
            gets $edit_handle line
            $abctxtw insert end $line\n
        }
        close $edit_handle
    }
    
    $abctxtw  tag configure blue -foreground blue
    
    Refactor::refactor_textcontents
    Barpicker::create_picker_interface
    
    $abctxtw configure -undo 1
    $abctxtw edit modified 0
    
    focus .abcedit
    # do not tag text if barpickerflag is on or else blue tag
    # will not show.
    
    
    pack .abcedit.pane -expand 1 -fill both
    if {$barpickerflag} {
        pack .abcedit.pane.tframe\
                .abcedit.pane.picker -side bottom -expand 1 -fill both } else {
        pack .abcedit.pane.tframe -expand 1 -fill both}
    
    bind $abctxtw <KeyRelease> "tag_line"

  bind $abctxtw <Button-3> {
        tk_popup .actionmenu2 %X %Y}

    if {[winfo exist .actionmenu2] != 1} {
       menu .actionmenu2
       .actionmenu2 add command -label play -command {edit_play_context}
       .actionmenu2 add command -label display -command {display_entire_edit_window}
      }
}

proc edit_play_context {} {
 global abctxtw
 set point [$abctxtw index insert]
 set selrange [$abctxtw tag ranges sel]
 if {[llength $selrange] < 2} {
       play_entire_edit_window 0} else {
       play_from_edit_window sel
       }
}


proc tcl_abc_edit_menu_bar {abcfile} {
    global df
    global abctxtw
    global fileseek
    global hlp_barpicker
    frame [set w .abcedit.func]
    menubutton $w.file -text file -font $df -menu $w.file.actions
    menu $w.file.actions -tearoff 0
    $w.file.actions add command -label "insert global header" -font $df \
            -command tcl_abc_edit_copy_global_header
    $w.file.actions add command -label save -font $df \
            -command  tcl_abc_edit_save
    $w.file.actions add command -label "save as" -font $df \
            -command  tcl_abc_edit_save_as
    $w.file.actions add command -label "replace tune in collection" -font $df\
            -command replace_edited_tune
    $w.file.actions add command -label "quit" -font $df\
            -command confirm_save
    bind .abcedit <Alt-s> tcl_abc_edit_save_as
    bind .abcedit <Alt-S> tcl_abc_edit_save
    #fix    if {$fileseek(0) < 8} {$w.file.actions entryconfigure 0 -state disable}
    
    
    menubutton $w.clean -text clean -font $df \
            -menu $w.clean.type
    menu $w.clean.type -tearoff 0
    $w.clean.type add command -label retag -font $df \
            -command {. config -cursor watch
                update
                tag_text
                . config -cursor arrow
                update}
    $w.clean.type add command -label "erase all" -font $df \
            -command erase_all
    $w.clean.type add command -label "remove redundant guitar chords" \
            -font $df -command {process_buffer remove_redundant_guitar_chords 0}
    $w.clean.type add command -label "remove all guitar chords" \
            -font $df -command {process_buffer remove_guitar_chords 0}
    $w.clean.type add command -label "remove all grace notes" \
            -font $df -command {process_buffer remove_grace_notes 0}
    $w.clean.type add command -label "remove inline voice fields" \
            -font $df -command {process_buffer remove_voice_fields 0}
    $w.clean.type add command -label "remove backslash continuations" \
            -font $df -command {process_buffer remove_backslashes 0}
    $w.clean.type add command -label "remove tab chars" \
            -font $df -command {process_buffer remove_tab_chars 0}
    $w.clean.type add command -label "help" -font $df\
            -command {show_message_page $hlp_clean word
                focus .abc
                raise .abc .abcedit
            }
    
    menubutton  $w.play  -text play -font $df \
            -menu $w.play.type
    menu $w.play.type -tearoff 0
    $w.play.type add command -label line -accelerator <Alt-p><Alt-l> \
            -command {play_from_edit_window line} -font $df
    $w.play.type add command -label selection -accelerator <Alt-p><Alt-s> \
            -command {play_from_edit_window sel} -font $df
    $w.play.type add command -label all \
            -command {play_entire_edit_window 0} -font $df
    $w.play.type add command -label "all verbatim" \
            -command {play_entire_edit_window 1} -font $df
    bind .abcedit <Alt-p><Alt-l> {play_from_edit_window line}
    bind .abcedit <Alt-p><Alt-s> {play_from_edit_window sel}
    
    button $w.undo -text "undo" -relief flat -font $df \
            -command {$abctxtw edit undo; tag_text}
    button $w.redo -text "redo" -relief flat -font $df \
            -command {$abctxtw edit redo; tag_text}
    menubutton $w.tools -text tools -font $df -menu $w.tools.type
    menu $w.tools.type -tearoff 0
    $w.tools.type add cascade     -label transpose  -menu $w.tools.transpose -font $df
    $w.tools.type add cascade -label chords -menu $w.tools.chords -font $df
    $w.tools.type add cascade -label "replace chords" -menu $w.tools.replacechords\
            -font $df
    $w.tools.type add cascade -label "x replace chords" -menu $w.tools.xreplacechords\
            -font $df
    $w.tools.type add command -label "solfege vocalization" -command solfege_vocalization \
            -font $df
    $w.tools.type add command -label drum   -command drum_editor -font $df
    $w.tools.type add command -label "align bars <Alt-a>" -command bar_align  -font $df
    bind .abcedit <Alt-a> {bar_align}
    $w.tools.type add command -label "squeeze bars" -command bar_squeeze -font $df
    $w.tools.type add command -label "find similar music" -font $df\
            -command transfer_editor_buffer_to_abcmatch
    
    menu $w.tools.transpose -tearoff 0
    $w.tools.transpose add command -label "octave up" -font $df\
            -command {process_buffer shift_all_notes 7}
    $w.tools.transpose add command -label "seventh up" -font $df\
            -command {process_buffer shift_all_notes 6}
    $w.tools.transpose add command -label "sixth up" -font $df\
            -command {process_buffer shift_all_notes 5}
    $w.tools.transpose add command -label "fifth up" -font $df\
            -command {process_buffer shift_all_notes 4}
    $w.tools.transpose add command -label "fourth up" -font $df\
            -command {process_buffer shift_all_notes 3}
    $w.tools.transpose add command -label "third up" -font $df\
            -command {process_buffer shift_all_notes 2}
    $w.tools.transpose add command -label "second up" -font $df\
            -command {process_buffer shift_all_notes 1}
    $w.tools.transpose add command -label "second down" -font $df\
            -command {process_buffer shift_all_notes -1}
    $w.tools.transpose add command -label "third down" -font $df\
            -command {process_buffer shift_all_notes -2}
    $w.tools.transpose add command -label "fourth down" -font $df\
            -command {process_buffer shift_all_notes -3}
    $w.tools.transpose add command -label "fifth down" -font $df\
            -command {process_buffer shift_all_notes -4}
    $w.tools.transpose add command -label "sixth down" -font $df\
            -command {process_buffer shift_all_notes -5}
    $w.tools.transpose add command -label "seventh down" -font $df\
            -command {process_buffer shift_all_notes -6}
    $w.tools.transpose add command -label "octave down" -font $df\
            -command {process_buffer shift_all_notes -7}
    $w.tools.transpose add command -label "help" -font $df\
            -command {show_message_page $hlp_transpose word
                focus .abc
                raise .abc .abcedit
            }
    
    menu $w.tools.chords -tearoff 0
    $w.tools.chords add command -label "2nd" -font $df\
            -command {process_buffer notes2chords -1}
    $w.tools.chords add command -label "3rd" -font $df\
            -command {process_buffer notes2chords -2}
    $w.tools.chords add command -label "4th" -font $df\
            -command {process_buffer notes2chords -3}
    $w.tools.chords add command -label "5th" -font $df\
            -command {process_buffer notes2chords -4}
    $w.tools.chords add command -label "6th" -font $df\
            -command {process_buffer notes2chords -5}
    $w.tools.chords add command -label "7th" -font $df\
            -command {process_buffer notes2chords -6}
    $w.tools.chords add command -label "8th" -font $df\
            -command {process_buffer notes2chords -7}
    $w.tools.chords add command -label "help" -font $df\
            -command {show_message_page $hlp_chords word
                focus .abc
                raise .abc .abcedit
            }
    
    menu $w.tools.replacechords -tearoff 0
    $w.tools.replacechords add command -label "with top note" -font $df\
            -command {process_buffer replace_chord 0}
    $w.tools.replacechords add command -label "with 2nd note" -font $df\
            -command {process_buffer replace_chord 1}
    $w.tools.replacechords add command -label "with 3rd note" -font $df\
            -command {process_buffer replace_chord 2}
    $w.tools.replacechords add command -label "with 4th note" -font $df\
            -command {process_buffer replace_chord 3}
    $w.tools.replacechords add command -label "help" -font $df\
            -command {show_message_page $hlp_replacechord word
                focus .abc
                raise .abc .abcedit
            }
    
    menu $w.tools.xreplacechords -tearoff 0
    $w.tools.xreplacechords add command -label "with top note" -font $df\
            -command {process_buffer replace_chord_x 0}
    $w.tools.xreplacechords add command -label "with 2nd note" -font $df\
            -command {process_buffer replace_chord_x 1}
    $w.tools.xreplacechords add command -label "with 3rd note" -font $df\
            -command {process_buffer replace_chord_x 2}
    $w.tools.xreplacechords add command -label "with 4th note" -font $df\
            -command {process_buffer replace_chord_x 3}
    $w.tools.xreplacechords add command -label "help" -font $df\
            -command {show_message_page $hlp_replacechord word
                focus .abc
                raise .abc .abcedit
            }
    
    
    $w.tools.type add cascade     -label multi-rests  -menu $w.tools.multirests -font $df
    menu $w.tools.multirests -tearoff 0
    $w.tools.multirests add command -label "multi-rests nztoZn" \
            -command {process_buffer multi_rests_nz2Z 0} -font $df
    $w.tools.multirests add command -label "multi-rests Zntonz" \
            -command {process_region multi_rests_Z2nz 0} -font $df
    $w.tools.multirests add command -label "condense whole rests to Zn" \
            -command {process_region edit_condense_whole_rests 0} -font $df
    $w.tools.multirests add command -label "condense whole rests to \"n\"z" \
            -command {process_region edit_condense_whole_rests 1} -font $df
    $w.tools.multirests add command -label "help" \
            -font $df -command {show_message_page $hlp_multirests word
                focus .abc
                raise .abc .abcedit
            }
    
    button $w.find -text "find" -font $df -relief flat -command find_frame
    
    button $w.display -text "display" -font $df -relief flat -command \
            display_entire_edit_window
    bind .abcedit <Alt-d> display_entire_edit_window
    
    button $w.help  -text help -font $df -relief flat
    pack $w.file $w.clean $w.undo $w.redo $w.play \
            $w.find $w.tools $w.display $w.help -side left -anchor w
    pack $w -side top -anchor w
    
    bind .abcedit.func.help <Button> {
        if {$barpickerflag} {
            show_message_page $hlp_barpicker word
        } else {
            show_message_page $hlp_editor word}
        focus .abc
        raise .abc .abcedit}
    bind .abcedit <Alt-f> shift_to_next_bar
    bind .abcedit <Alt-b> shift_to_previous_bar
    bind .abcedit <Alt-t> transfer_editor_buffer_to_abcmatch
    bind .abcedit <Alt-r> shift_note_up
    bind .abcedit <Alt-l> shift_note_down
    bind .abcedit <Alt-e> {expand_contract_note 1}
    bind .abcedit <Alt-c> {expand_contract_note 0}
    #    bind .abcedit <Alt-Key-Up> shift_note_up
    #    bind .abcedit <Alt-Key-Down> shift_note_down
    #    bind .abcedit <Alt-Key-Right> {expand_contract_note 1}
    #    bind .abcedit <Alt-Key-Left> {expand_contract_note 0}
}

# Part 10.1           Bar Picker 

namespace eval Barpicker {
    
    proc create_picker_interface {} {
        global alreadyloaded
        global df
        set alreadyloaded 1
        set w .abcedit.pane.picker
        if {[winfo exists $w]} {
            voicelist_buttons
            barpicker_buttons
            barselector_control
           return
           }
        frame $w
        pack $w
        #toplevel $w
        voicelist_interface
        barpicker_interface
        frame $w.piece
        entry $w.piece.entry -width 55 -textvariable barpiece -bg "light goldenrod" -font $df
        button $w.piece.update -text update -command Barpicker::update_barpiece -font $df
        label $w.piece.mesg -text "" -font $df
        pack $w.piece.mesg $w.piece.entry $w.piece.update -side left
        pack $w.piece -fill x -expand true
        make_pattern_button_set
        barselector_interface
        clear_pattern_buttons 
        if {$alreadyloaded} {
            voicelist_buttons
            barpicker_buttons
            barselector_control
        }
    tooltip::tooltip $w.piece.update  "Paste the contents of entry box into the highlighted\n bar and update the internal representation."
    }
    
    
    proc voicelist_interface {} {
        global nbars voicelist df
        global nvoices_exposed
        set w .abcedit.pane.picker.voicepicker
        frame $w
        pack $w -fill x
        label $w.lab -text voice: -font $df
        grid $w.lab -row 0 -column 0
        set nvoices_exposed 0
    }
    
    proc voicelist_buttons {} {
        global nvoices_exposed
        global voicelist
        global voicepick
        global nvoices
        global df
        if {$nvoices == 0} {set voicelist {0}}
        #create_picker_interface
        set w .abcedit.pane.picker.voicepicker
        #remove all exposed voices (they may have different names)
        for {set i 1} {$i <$nvoices_exposed} {incr i} {
            destroy $w.$i
        }
        #place new voice selectors
        set i 1
        foreach voice $voicelist {
            radiobutton $w.$i -text $voice -variable voicepick -value $voice\
                    -command "Barpicker::switch_voice" -font $df
            grid $w.$i -row 0 -column $i
            incr i
        }
        set nvoices_exposed $i
        # to avoid potential problems
        if {$i > 1} {$w.1 invoke
            set voicepick [lindex $voicelist 0]
        } else {set voicepick 0}
    }
    
    proc barpicker_interface {} {
        global nbars_exposed
        set w .abcedit.pane.picker.barpicker
        # we cannot scroll a frame but we can scroll a canvas. We embed a
        # frame with the radiobuttons into the canvas since gridding the
        # radiobuttons directly into the canvas causes scrolling to fail.
        frame $w -borderwidth 3 -relief sunken
        pack $w -fill x
        frame $w.c
        pack $w.c -side left -fill both -anchor nw 
        set nbars_exposed 0
    }
    
    proc barpicker_buttons {} {
        global nbars_exposed
        global nbars
        global df
        
        set w .abcedit.pane.picker
        pack forget $w.barpicker
        pack $w.barpicker -after $w.voicepicker -expand 1 -fill both
        set w $w.barpicker.c
        if {$nbars_exposed > $nbars} {
            for {set i $nbars} {$i < $nbars_exposed} {incr i} {
                destroy $w.$i
            }
            set nbars_exposed $nbars
        } else {
            for {set i $nbars_exposed} {$i < $nbars} {incr i} {
                radiobutton $w.$i -text $i -width 3 -variable barpick -value $i \
                        -command "Barpicker::show_picked_bar $i" -font $df
                set r [expr $i / 10]
                set c [expr $i % 10]
                grid $w.$i -row $r -column $c
            }
            set nbars_exposed $i
        }
    }
    
    
    proc make_pattern_button_set {} {
        global df
        set w .abcedit.pane.picker
        frame $w.patterns
        pack $w.patterns -fill x -expand true
        for {set n 0} {$n < 8} {incr n} {
            button $w.patterns.$n -text p$n -state disabled -background lightblue -font $df
            pack $w.patterns.$n -side left
        }
        button $w.patterns.clear -text clear -command Barpicker::clear_pattern_buttons -font $df
        button $w.patterns.import -text import  -font $df -command Barpicker::import_drumpatterns
        pack $w.patterns.clear -side left
        pack $w.patterns.import -side left
        tooltip::tooltip $w.patterns.clear  "Initialize all pattern buttons (Pn)"
        tooltip::tooltip $w.patterns.import  "Import drum patterns from drum tool"
    }
    
    proc clear_pattern_buttons {} {
        global npat
        set w .abcedit.pane.picker
        for {set n 0} {$n < 8} {incr n} {
            $w.patterns.$n configure -state disabled
            tooltip::tooltip clear $w.$n
        }
        set npat 0
    }

   proc import_drumpatterns {} {
        global npat last_drumpattern
        global pattern drumpatterns
        set npat last_drumpattern
        for {set i 0}  {$i <$last_drumpattern} {incr i} {
         set pattern($i) "$drumpatterns(D$i) |"
        .abcedit.pane.picker.patterns.$i configure -state normal 
        .abcedit.pane.picker.patterns.$i configure -state normal -command "Barpicker::putpattern $i"
        tooltip::tooltip .abcedit.pane.picker.patterns.$i $pattern($i)
         }
    } 

    set npat 0
    
    proc barselector_interface {} {
        global df
        set w .abcedit.pane.picker.barselector
        frame $w -borderwidth 3 -relief sunken
        pack $w -fill x -expand true
        set  w .abcedit.pane.picker.barselector.fun
        frame $w
        pack $w -fill x -expand true
        button $w.resync -text resync -font $df -command {
           Refactor::refactor_textcontents 
           Barpicker::create_picker_interface
           }
        button $w.play -text play -command play_section -font $df
        button $w.display -text display -command display_section -font $df
        button $w.save -text save -command Refactor::output_file_direct -font $df
        button $w.debug -text debug -command Refactor::dump_tunepieces -font $df
        grid  $w.resync $w.play $w.display $w.save $w.debug
        tooltip::tooltip $w.resync  "Re-identify all components of the\n noated tune in the text frame."
        tooltip::tooltip $w.play  "Play the section delineated by\nthe sliders below."
        tooltip::tooltip $w.display  "Display the section delineated by\nthe sliders below."
        tooltip::tooltip $w.save  "Save delineated section in the file\n tmp/X.tmp as an abc file."
        tooltip::tooltip $w.debug "Display all the fragments of the tune\n in a separate window."
    }
    
    
    proc barselector_control {} {
        global nbars_exposed
        global nbars
        global firstbar lastbar
        global df
        set w .abcedit.pane.picker.barselector
        if {[winfo exist $w.lab1]} {
            $w.end configure -from 0 -to $nbars
            set lastbar $nbars
            return
        }
        label $w.lab1 -text "start bar" -font $df
        label $w.lab2 -text "end bar" -font $df
        set firstbar 0
        set lastbar $nbars
        scale $w.start -from 0 -to $nbars -length 150 -width 10\
                -orient horizontal -variable firstbar -font $df
        scale $w.end -from 0 -to $nbars -length 150 -width 10\
                -orient horizontal -variable lastbar -font $df
        pack $w.lab1 $w.start $w.lab2 $w.end -side left
    }
    
    proc barclick {varname} {
        global tag_id abctxtw
        global barpiece
        global voicelist
        global clickedbar clickedvoice
        if {[info exist tag_id]} {remove_blue_tag $tag_id}
        set tag_id $varname
        add_blue_tag $tag_id
        .abcedit.pane.picker.piece.mesg configure -text "$tag_id" -fg red
        set rangev [$abctxtw tag range $tag_id]
        set apiece ""
        foreach {i1 i2} $rangev {
            append apiece [$abctxtw get $i1 $i2]
        }
        update_barpiece_entry_box $apiece
        if {$tag_id == "head"} return
        set splitag [split $tag_id -]
        if {[lindex $splitag 0] != "x"} {
          set clickedvoice [lindex $splitag 0]
          set clickedbar [lindex $splitag 1]
          set n [lsearch $voicelist $clickedvoice]
          incr n
          .abcedit.pane.picker.voicepicker.$n invoke
          .abcedit.pane.picker.barpicker.c.$clickedbar invoke
        }
    }
    
    
    proc add_blue_tag {tag_id} {
        global abctxtw
        set rangev [$abctxtw tag range $tag_id]
        foreach {ind1 ind2} $rangev {
            $abctxtw tag add blue $ind1 $ind2
        }
        $abctxtw see [lindex $rangev 1]
    }
    
    proc remove_blue_tag {tag_id} {
        global abctxtw
        set rangev [$abctxtw tag range $tag_id]
        foreach {ind1 ind2} $rangev {
            $abctxtw tag remove blue $ind1 $ind2
        }
    }
    
    
    
    
    
    proc show_picked_bar {i} {
        global tunepieces
        global abctxtw
        global tag_id
        global voicepick
        global pickedbar
        if {[info exist tag_id]} {remove_blue_tag $tag_id}
        set tag_id $voicepick-$i
        set range [$abctxtw tag range $tag_id]
        set apiece ""
        foreach {i1 i2} $range {
            append apiece [$abctxtw get $i1 $i2]
        }
        Barpicker::update_barpiece_entry_box  $apiece
        $abctxtw see [lindex $range 1]
        add_blue_tag $tag_id
        set pickedbar $i
        .abcedit.pane.picker.piece.mesg configure -text "$tag_id" -fg red
    }
    
    proc switch_voice {} {
        global pickedbar
        if {[info exist pickedbar]} {Barpicker::show_picked_bar $pickedbar}
    }
    
    proc update_barpiece {} {
        #this function handles the button press update in the .picker window.
        #Please see the comments in update_barpiece_entry_box.
        global barpiece
        global tag_id
        #global oldbarpiece oldloc1 oldloc2
        global aoldbarpiece aoldloc1 aoldloc2
        activate_pattern_button $barpiece
        set newpiece $barpiece
        set anewpiece $barpiece
        if {[info exist aoldbarpiece] == 0} return
        if {$aoldbarpiece != ""} {
            set anewpiece [string replace $aoldbarpiece $aoldloc1 $aoldloc2 $barpiece]
        }
        replace_tagged_bar $newpiece $anewpiece
    }
    
    proc replace_tagged_bar {piece apiece} {
        global tag_id
        global abctxtw
        global tunepieces
        #puts "replacing_tagged_bar"
        #puts "apiece = $apiece"
        set range [$abctxtw tag range $tag_id]
        set ind1 [lindex $range 0]
        set ind2 [lindex $range 1]
        $abctxtw replace $ind1 $ind2 $apiece $tag_id
        set tunepieces($tag_id) $apiece
        add_blue_tag $tag_id
    }
    
    proc update_barpiece_entry_box {apiece} {
        global barpiece
        global oldbarpiece oldloc1 oldloc2
        global aoldbarpiece aoldloc1 aoldloc2
        #Anything in the global variable barpiece will show up in the
        #entry box .picker.piece.entry.
        #In the event that piece contains field commands and MIDI comments
        #before the music bar, we wish to trim off the extraneous information
        #prior to placing it in the entry box. We still have to save the
        #original piece, because we must preserve the leading info before
        #putting it back into the tunepieces array and text windows. This
        #is a complication because a bar fragment contain other information
        #that we do not want to destroy when we replace it by one of the
        #patterns in putpattern.
        set abarpiecelist [split $apiece \n]
        if {[llength $abarpiecelist] < 2} {
          set abarpiece [lindex $abarpiecelist end]
          set aoldloc1 [string first $abarpiece $apiece]
          set aoldloc2 [expr $aoldloc1 + [string length $barpiece]]
          set aoldbarpiece $apiece
          #puts "aoldloc= $aoldloc1 $aoldloc2"
          set barpiece $apiece
          .abcedit.pane.picker.piece.update configure -state normal
          } else {
          set barpiece ""
          .abcedit.pane.picker.piece.update configure -state disable
          }
    }
    
    set npat 0
    
    proc activate_pattern_button {barpiece} {
        # after doing an update in the .picker window, we save the new bar
        # in a pattern button Pn that we create. This allows us to repeat
        # this pattern in other bars if we wish.
        global npat
        global pattern
        if {$npat > 7} return
        set pattern($npat) $barpiece
        .abcedit.pane.picker.patterns.$npat configure -state normal -command "Barpicker::putpattern $npat"
        tooltip::tooltip .abcedit.pane.picker.patterns.$npat $barpiece
        incr npat
    }
    
    proc putpattern {n} {
        #This function handles pressing one of the pattern button P1,P2, etc
        #in the .picker window.
        global pattern
        global barpiece
        global aoldbarpiece
        global oldloc1 oldloc2 aoldloc1 aoldloc2
        set barpiece $pattern($n)
        set newpiece $barpiece
        set anewpiece $barpiece
        if {[info exist aoldbarpiece] == 0} return
        if {$aoldbarpiece != ""} {
            set anewpiece [string replace $aoldbarpiece $aoldloc1 $aoldloc2 $barpiece]
        }
        replace_tagged_bar $newpiece $anewpiece
    }
    
}

#end of namespace barpicker


set hlp_barpicker "TclMultiVoice Editor\n\n\
        The intent of this editor is to provide a tool for modifying the\
        contents of a voice that is used as an accompaniment to the\
        melody line. These voices would be created using the 'ghchords/drums\
        to voice' toolbox that is accessible through the utilities menu item.\
        The editor allows you to find a particular bar and replace it with\
        another bar which could be part of a small library of bars.\
        Though this was the original intention, the editor is fairly general\
        and could be used for many other purposes as it shares many\
        of the functions of the TclAbcEditor.\n\n\
        When you start the editor, the program fragments the tune into\
        smaller pieces mostly corresponding to individual bars and displays\
        the tune in a editable text window. (You can view this internal\
        representation by clicking on the debug button near the bottom\
        of the window.) The representation in the text window should match\
        the original file with perhaps a few exceptions. For example if a\
        bar is incomplete at the end of a text line (i.e. a | does not\
        end it) then the representation on the screen may be somewhat\
        different. Left clicking the mouse while the pointer is\
        inside any item or bar in the text window will cause that item\
        to be highlighted in blue. If that item is also a bar, then it\
        will also be displayed in the orange entry box below. Though you\
        can edit the contents of the item directly in the text window, the\
        recommended procedure is to change it in the orange entry box\
        and then press the update button. This will also enable one of\
        the blueish p buttons which will store the contents of the entry\
        for future reference. If you wish to replace another\
        bar with the same contents, you would highlight that bar in blue\
        in the same manner and then press the corresponding p button.\
        (You can view the contents of the active p button by hovering\
        the mouse pointer over that button.)\n\n\
        Note if you decide to edit the abc tune directly in the text\
        window, the internal representation of the tune will be out of\
        sync. It is necessary to press the 'resync' button to update the\
        internal representation.\n\n\
        The editor has several other convenient features which allow you\
        to find a particular bar or its matching bar in another voice.\
        There is an array of radio buttons designating the voices and bars\
        occuring below the edit window. When you highlight\
        a particular bar, the voice and bar number is also invoked in the\
        set of radio buttons. If you activate a different radio button,\
        then a different bar will be highlighted in the edit window and\
        placed in the orange entry box.\n\n\
        All the contents of the p memory buttons can be cleared using the\
        'clear' button. The 'import' button works in conjuction with the\
         'drum tool' which should be exposed before pressing that\
        button. The import button will transfer the contents of the D\
        memory buttons to the p buttons. A plain bar marker like | will\
        be added. When repeat markings are needed, you will have to\
        add them manually in the entry window.\n\n\
        The set of buttons and the sliders at the bottom of the window\
        is used to display, play or save a particular section of the\
        tune indicated by the sliders. This is a convenience when you\
        wish to test out only a particular section of the tune.\n\n\
        Finally, if you right click the mouse while the pointer is\
        anywhere in the text window, a small pop up menu will appear.\
        This saves you the effort of having to move the mouse button\
        to one of the top menu buttons.      
        "



proc tcl_abc_edit_copy_global_header {} {
    global abctxtw
    global fileseek
    global midi
    set handle [open $midi(abc_open) r]
    set header [read $handle $fileseek(0)]
    puts $header
    $abctxtw insert 1.0 $header
    close $handle
}

proc tcl_abc_edit_save {} {
    global midi
    global abctxtw
    if {[string compare $midi(abc_save) $midi(abc_default_file)] == 0 \
                || [llength $midi(abc_save)] == 0} set_abc_save
    if {[llength $midi(abc_save)] >0} {
        Text_Dump $abctxtw
        $abctxtw edit modified 0
    }
}

proc tcl_abc_edit_save_as {} {
    global midi
    global abctxtw
    set_abc_save
    if {[llength $midi(abc_save)] >0} {
        Text_Dump $abctxtw
        $abctxtw edit modified 0}
}


proc find_forwards {} {
    global findstring
    global abctxtw
    set point [$abctxtw index insert]
    set lastline [$abctxtw index end]
    if {[$abctxtw compare $point >= $lastline]} {
        set point 1.0} else {
        set point "$point+1 chars"}
    set point [$abctxtw search -forwards $findstring $point]
    if {[llength $point]>0} {
        $abctxtw mark set insert $point
        $abctxtw see $point
        focus $abctxtw
    }
}


proc find_backwards {} {
    global findstring
    global abctxtw
    set point [$abctxtw index insert]
    set lastline [$abctxtw index end]
    if {[$abctxtw compare $point >= $lastline]} {
        set point 1.0}
    set point [$abctxtw search -backwards $findstring $point]
    if {[llength $point]>0} {
        $abctxtw mark set insert $point
        $abctxtw see $point
        focus $abctxtw
    }
}


proc locate_barnum {} {
    #returns the position of the findbarnum barline
    global findbarnum body_start body_end
    global abctxtw
    set p {\|+}
    set point [$abctxtw index insert]
    set selstart [lindex [split $point .] 0]
    if {$selstart > $body_end} {
        set point $body_start.0
        set selstart [lindex [split $point .] 0]
    }
    set selstart $selstart.0
    set start [$abctxtw search -backwards X: $selstart]
    set start [lindex [split $start .] 0]
    set linend [$abctxtw index "end -1 char"]
    set linend [lindex [split $linend .] 0]
    incr start
    set bcount 1;
    for {set index $start} {$index < $linend} {incr index} {
        set value [$abctxtw get $index.0 $index.end]
        if {[string length $value] < 2} continue
        set initial [string index $value 0]
        set next [string index $value 1]
        if {[string first $initial ABCDEFGHIKLMNOPQRSTUVWwXZ]
            >= 0 && $next == ":" } {
            if {[string equal $initial X] == 1} break else continue
        }
        set begin 0
        set result 1
        while {$result} {
            set result [regexp -start $begin -indices $p $value loc]
            if {$result} {set begin [lindex $loc 1]
                if {$bcount == $findbarnum} {return $index.$begin}
                incr begin
                incr bcount
            }
        }
    }
    return $index.$begin
}


proc find_barnum {} {
    global abctxtw
    set point [locate_barnum]
    $abctxtw mark set insert $point
    $abctxtw see $point
    focus $abctxtw
}


proc find_frame {} {
    global findstring df
    global findbarnum
    set findbarnum 1
    set p .abcedit.find
    if {[winfo exists .abcedit.find] == 0} {
        frame $p
        entry $p.en -textvariable findstring -width 24 -font $df
        button $p.forwards -text forwards -font $df
        button $p.backwards -text backwards -font $df
        button $p.bar -text barline -font $df
        entry  $p.barnum -textvariable findbarnum -width 3 -font $df
        button $p.close -text close -font $df \
                -command {destroy .abcedit.find}
        pack $p.en $p.forwards $p.backwards $p.bar $p.barnum $p.close -side left -anchor w
        pack .abcedit.find -after .abcedit.func -anchor w
        bind .abcedit.find.en  <Return> find_forwards
        bind .abcedit.find.forwards <Button> find_forwards
        bind .abcedit.find.backwards <Button> find_backwards
        bind .abcedit.find.bar <Button> find_barnum
    } else {
        focus .abcedit.find
    }
}

proc shift_to_next_bar {} {
    global abctxtw
    set nextbar [$abctxtw search | insert]
    $abctxtw mark set insert "$nextbar+1 char"
}

proc shift_to_previous_bar {} {
    global abctxtw
    set nextbar [$abctxtw search -backwards | insert]
    $abctxtw mark set insert "$nextbar-1 char"
    set nextbar [$abctxtw search -backwards | insert]
    $abctxtw mark set insert "$nextbar+1 char"
}

proc erase_all {} {
    global abctxtw
    $abctxtw delete 1.0 end
}

proc set_abc_save {} {
    global midi types
    set filedir [file dirname $midi(abc_save)]
    set midi(abc_save) [tk_getSaveFile -initialdir $filedir -filetypes $types]
}


proc Text_Dump {t {start 1.0} {end end}} {
    global midi
    
    set outhandle [open $midi(abc_save) w]
    foreach {key value index} [$t dump $start $end] {
        if {$key == "text"} {
            puts -nonewline $outhandle $value}
    }
    close $outhandle
    if {$midi(bell_on)} bell
}


proc tag_text {} {
    global body_start body_end midi
    global abctxtw
    global midi
    set t $abctxtw
    set body_start {}
    set tocfb [font create -family $midi(font_family_toc)\
            -size $midi(font_size)  -weight bold]
    $t configure -selectbackground $midi(edit_selectbackground)
    $t tag delete "field" "body" "comment" "barline" "guitar"
    $t  tag configure "body"  -foreground $midi(edit_body_colour)
    $t  tag configure "field" -foreground $midi(edit_field_colour)
    $t  tag configure "comment" -foreground $midi(edit_comment_colour)
    $t  tag configure "barline" -foreground $midi(edit_barline_colour)  -font $tocfb
    $t  tag configure "guitar" -foreground $midi(edit_guitar_colour)
    set index [$t index "end -1 char"]
    set lines [lindex [split $index .] 0]
    for {set index 1} {$index < $lines} {incr index} {
        tag_text_line $index
        if {[llength $body_start] == 0} {set body_start $index}
        set body_end $index
    }
}

proc tag_line {} {
    global abctxtw
    set loc [$abctxtw index insert]
    set lineloc [lindex [split $loc .] 0]
    tag_text_line $lineloc
}

proc tag_text_line {no} {
    global abctxtw
    set t $abctxtw
    set value [$t get $no.0 $no.end]
    if {[string length $value] < 2} return
    set initial [string index $value 0]
    set next [string index $value 1]
    if {[string first $initial ABCDEFGHIKLMNOPQRSTUVWwXZ]
        >= 0 && $next == ":" } {
        $t tag add "field" $no.0 $no.end
        set inbody 0
    } elseif {$initial == "%"} {
        $t tag add "comment" $no.0 $no.end
        set inbody 0
    } else {
        $t tag add "body" $no.0 $no.end
        set inbody 1
    }
    # tag bar lines
    if {$inbody} {tag_bar_lines $no $value
        tag_guitar_chords $no $value}
}


proc tag_bar_lines {lineno line} {
    global abctxtw
    set start 0
    set loc 0
    while {$loc >= 0} {
        set loc [string first "|" $line $start]
        if {$loc <0} break
        set start [expr $loc +1]
        set loc1 [expr $loc-1]
        set loc2 [expr $loc+1]
        if {[string index $line $loc1] == ":"} {set loc $loc1}
        if {[string index $line $loc2] == ":"} {set loc2 [expr $loc2 +1]}
        $abctxtw tag add "barline" $lineno.$loc $lineno.$loc2
    }
}

proc tag_guitar_chords {lineno line} {
    global abctxtw
    set start 0
    set loc 0
    $abctxtw tag remove "guitar" $lineno.0 "$lineno.0 lineend"
    while {$loc >= 0} {
        set loc [string first "\"" $line $start]
        if {$loc <0} break
        set start [expr $loc +1]
        set loc2 [string first "\"" $line $start]
        if {$loc2 > 0} {
            set loc2 [expr $loc2+1]
            $abctxtw tag add "guitar" $lineno.$loc $lineno.$loc2
            set start [expr $loc2 +1]
        }
    }
}



proc play_from_edit_window {mode} {
    # The function is designed to play a short extract from
    # which has been selected from the editor. It searches
    # for the X: code preceding the selected region and
    # copies all the field commands preceding into the
    # X.tmp file. The rest of the body is ignored and
    # the selected portion of pasted in. abc2midi is
    # executed to produce a midi file X1.mid which is then
    # using the selected protocol played.
    # We check that the user has selected a region or
    # indicated an insert point in the body; otherwise
    # we just play the first line in the body.
    global midi exec_out files
    global body_start body_end
    global abctxtw
    set dir "[pwd]/$midi(midi_dir)"
    set files ""
    lappend files $dir/X1.mid
    set cmd "file delete [glob -nocomplain $dir/X*.mid]"
    catch {eval $cmd}
    set out_fd [open $midi(midi_dir)/X.tmp w]
    
    if {[info exists body_end] == 0} tag_text
    
    if {[string compare $mode line] == 0} {
        set point [$abctxtw index insert]
        set selstart [lindex [split $point .] 0]
        if {$selstart > $body_end} {
            set point $body_start.0
            set selstart [lindex [split $point .] 0]
        }
        set selend $selstart.end
        set selstart $selstart.0
        $abctxtw tag add sel $selstart $selend
        update
    } else {
        set selrange [$abctxtw tag ranges sel]
        if {[llength $selrange] < 2} {
            set selrange [list $body_start.0 $body_start.end]
            set selstart [lindex $selrange 0]
            set selend [lindex $selrange 1]
            $abctxtw tag add sel $selstart $selend
            update
        } else {
            set selstart [lindex $selrange 0]
            set selend [lindex $selrange 1]
        }
    }
    set linend [lindex [split $selend .] 0]
    set start [$abctxtw search -backwards X: $selstart]
    set start [lindex [split $start .] 0]
    puts $out_fd "X: 1"
    write_midi_codes $out_fd
    for {set index $start} {$index < $linend} {incr index} {
        set value [$abctxtw get $index.0 $index.end]
        set initial [string index $value 0]
        set next [string index $value 1]
        if {[string first $initial ABCDEFGHIKLMNOPQRSTUVWwXZ]
            > 0 && $next == ":" } {
            if {[string compare $initial "X"] != 0} {puts $out_fd $value}
        } elseif {$initial == "%"} {
            puts $out_fd $value}
    }
    set value [$abctxtw get $selstart $selend]
    puts $out_fd $value
    puts $out_fd "\n\n"
    close $out_fd
    set cmd "exec $midi(path_abc2midi) $midi(midi_dir)/X.tmp"
    catch {eval $cmd} exec_out
    set exec_out $cmd\n\n$exec_out
    play_midis 1
    update_console_page
}


# Part 10.2               Guitar Chord ToolBox


#source guitar.tcl

set keyorder CDEFGABCDEFGAB
global keyorder


proc setkeymap {sf} {
    # work out accidentals to be applied to each note
    # sf; /* number of sharps in key signature -7 to +7
    global keymap
    array set keymap {C C D D E E F F G G A A B B}
    if {$sf >= 1} {set keymap(F) F# }
    if {$sf >= 2} {set keymap(C) C# }
    if {$sf >= 3} {set keymap(G) G# }
    if {$sf >= 4} {set keymap(D) D# }
    if {$sf >= 5} {set keymap(A) A# }
    if {$sf >= 6} {set keymap(E) E# }
    if {$sf >= 7} {set keymap(B) B# }
    if {$sf <= -1} {set keymap(B) Bb }
    if {$sf <= -2} {set keymap(E) Eb }
    if {$sf <= -3} {set keymap(A) Ab }
    if {$sf <= -4} {set keymap(D) Db }
    if {$sf <= -5} {set keymap(G) Gb }
    if {$sf <= -6} {set keymap(C) Cb }
    if {$sf <= -7} {set keymap(F) Fb }
}


proc showkeys {from} {
    global keyorder keymap
    for {set i 0} {$i < 8} {incr i} {
        set key [string index $keyorder [expr $i +$from]]
        set key $keymap($key)
        puts $key
    }
}


proc keytosf {keysig} {
    #from key signature computes number of sharps/flats, mode
    #and first key in scale.
    global mode tonic
    set s [regexp {([A-G]|none)(#*|b*)(.*)} $keysig match tonic sub2 sub3]
    if {$s < 1} {puts "can't understand key signature $keysig"
        return}
    #puts "$tonic $sub2 $sub3"
    if {[string compare $tonic "none"] == 0} {set tonic C}
    set sf [expr [string first $tonic FCGDAEB] -1]
    if {$sub2 == "#"} {set sf [expr $sf + 7]}
    if {$sub2 == "b"} {set sf [expr $sf - 7]}
    if {[string length $sub3] > 0} {set sub3 [string tolower $sub3]}
    if {[string length $sub3] > 3} {set sub3 [string range $sub3 0 2 ]}
    set mode [lsearch -exact "maj min m aeo loc ion dor phr lyd mix" $sub3]
    if {$mode == -1} {set mode 0}
    #puts "mode = $mode"
    if {$mode >= 0} {set sf \
                [expr $sf - [lindex "0 3 3 3 5 0 2 4 -1 1" $mode]]}
    #puts $sf
}



proc shift_note_wrap {note shift} {
    global notekey
    set n [string first [string index $note 0] $notekey]
    set n [expr $n + $shift]
    if {$n > 6} {set n [expr $n - 7]}
    set result [string index $notekey $n]
    return $result
}


proc guitar_toolbox {keysig} {
    global df
    global keyorder keymap
    global tonic mode
    global rootname triadname chordno
    global progression
    # thanks to James Allwright for writing the original code in C
    # (parsekey and event_key see parseabc.c and store.c).
    set chordtype {0 1 1 0 0 1 2 0 1 1 0 0 1 1}
    set modeloc {0 5 5 5 6 0 1 2 3 4}
    set progression(0) {any}
    set progression(1) {6 4}
    set progression(2) {3 5}
    set progression(3) {2 4 6 0}
    set progression(4) {0}
    set progression(5) {1 3}
    set progression(6) {0}
    if {[string compare $keysig HP] == 0} {set keysig A}
    if {[string compare $keysig hp] == 0} {set keysig A}
    if {[string compare $keysig none] ==0} {set keysig C}
    set sf  [keytosf $keysig]
    setkeymap $sf
    set i1 [string first $tonic $keyorder]
    set i2 [lindex $modeloc $mode]
    set g .abcedit.pane.toolbox.guitartool
    if {[winfo exists $g]} {destroy $g}
    frame $g -borderwidth 2 -relief sunken
    
    # create list of harmonic triads for this key signature
    for {set i 0} {$i < 7} {incr i} {
        set k [string index $keyorder [expr $i1+$i]]
        set majmin ""
        if {[lindex $chordtype [expr $i2+$i]] == 1} {set majmin m}
        if {[lindex $chordtype [expr $i2+$i]] == 2} {set majmin dim}
        #  puts "$i2+$i $majmin"
        set rootname($i) $keymap($k)
        set key $keymap($k)
        set triadname($i) $key$majmin
    }
    
    
    #create chord type menu
    set gchordtypes { " " m  7  m7  maj7\
                M7  6  m6  aug  +\
                aug7  dim  dim7  9\
                m9  maj9  M9 11  dim9\
                sus  sus9  7sus4  7sus9  5}
    
    menubutton $g.ctypes -menu $g.ctypes.items -text types -font $df -relief raised
    menu $g.ctypes.items -tearoff 0
    set i 0
    set flag 0
    foreach item $gchordtypes {
        $g.ctypes.items add radiobutton -label $item -columnbreak $flag -font $df\
                -value $i -variable gtype -command "qualifychord $item"
        incr i
        set flag [expr $i % 5 == 0]
    }
    
    
    menubutton $g.invert -menu $g.invert.items -text inversion -font $df\
            -relief raised
    menu $g.invert.items -tearoff 0
    $g.invert.items add radiobutton -label none -font $df -command {invertchord 0}
    $g.invert.items add radiobutton -label first -font $df -command {invertchord 1}
    $g.invert.items add radiobutton -label second -font $df -command {invertchord 2}
    
    set gl $g.cframe
    labelframe $gl -text "guitar chords\nfor $keysig" -font $df
    grid $gl -rowspan 20
    
    set chordno 0
    radiobutton $gl.0 -text $triadname(0) -font $df  -indicatoron 1\
            -command "insert_chord $triadname(0)" -padx 1 -value 0 -variable chordno
    
    grid $gl.0 -sticky w
    for {set i 1} {$i < 7} {incr i} {
        radiobutton $gl.$i -text $triadname($i)  -font $df\
                -command "insert_chord $triadname($i)" -value $i -variable chordno
        grid $gl.$i -sticky w
    }
    
    button $g.help -text help -width 5 -font $df\
            -command {show_message_page $hlp_guitar word
                focus .abc
                raise .abc .abcedit
            }
    label $g.prog -text "" -font $df
    grid $g.help -row 1 -column 2
    button $g.refresh -text refresh -font $df -command guitar_chord
    grid $g.refresh -row 2 -column 2
    grid $g.ctypes  -row 3 -column 2
    grid $g.invert  -row 4 -column 2
    grid $g.prog    -row 5 -column 2
    possible_progression
}


proc qualifychord {{typeno ""}} {
    #appends chordtype to triad and updates chord selector
    global keyorder keymap
    global rootname triadname chordno
    set triadname($chordno) $rootname($chordno)$typeno
    set g .abcedit.pane.toolbox.guitartool.cframe
    $g.$chordno configure -text $triadname($chordno) -command "insert_chord $triadname($chordno)"
}


proc invertchord order {
    global triadname rootname chordno
    global keymap
    set key $rootname($chordno)
    set key [shift_note_wrap $key [expr $order*2]]
    set key $keymap($key) ;# add sharps or flats for key signature
    set g .abcedit.pane.toolbox.guitartool.cframe
    if {$order == 0} {
        $g.$chordno configure -text $triadname($chordno)\
                -command "insert_chord $triadname($chordno)" } else {
        $g.$chordno configure -text $triadname($chordno)/$key\
                -command "insert_chord $triadname($chordno)/$key"
    }
}

proc possible_progression {} {
    global triadname chordno
    global progression
    set output ""
    if {[string equal any $progression($chordno)]} {set output "any chord"} else {
        foreach chord $progression($chordno) {
            set output "$output $triadname($chord)\n"
        }
    }
    .abcedit.pane.toolbox.guitartool.prog configure -text $output
}


proc insert_chord {chord} {
    #puts or replaces a chord in the TclAbcEditor editor text.
    #is there a guitar code already there?
    global abctxtw
    set notepat {(\^*|_*|=?)([A-G]\,*|[a-g]\'*|z)(/?[0-9]*|[0-9]*/*[0-9]*)}
    #puts "insert_chord"
    possible_progression
    set nextbar [$abctxtw search | insert]
    set nextnote [$abctxtw search  -regexp  -- $notepat insert]
    set chordbegin [$abctxtw search \"  insert $nextbar]
    #puts "nextbar = $nextbar"
    #puts "nextnote = $nextnote"
    #puts "chordbegin = $chordbegin"
    
    if {[info exists nextbar] == 0} {
        $abctxtw insert insert "\"$chord\" " guitar
        return}

    if {$chordbegin == ""} {
        set lastinsert [$abctxtw index insert]
        $abctxtw insert insert "\"$chord\""  guitar
        $abctxtw mark set insert $lastinsert
        return}

    if {$chordbegin && $nextnote && [$abctxtw compare $nextnote < $chordbegin]} {
        set lastinsert [$abctxtw index insert]
        $abctxtw insert insert "\"$chord\""  guitar
        $abctxtw mark set insert $lastinsert
        return}

    set chordend [$abctxtw search \" "$chordbegin+1 char" $nextbar]
    #puts $chordend
    $abctxtw delete $chordbegin "$chordend +1 char"
    $abctxtw mark set insert $chordbegin
    $abctxtw insert insert "\"$chord\"" guitar
    $abctxtw mark set insert $chordbegin
}

set hlp_guitar "Guitar tool box\n\n\
        The tool box assists you in inserting guitar chords \
        (eg. \"Cm\") into the tune. When the tool box is created, the program \
        examines the preceding key signature and displays some of the guitar \
        chords that are appropriate for this key signature. The program recognizes \
        the major and minor key signatures as well as the various modes (eg. Ddor).\n\n\
        Instructions: to insert a guitar chord, position the insert \
        point of the editor where the chord is to be inserted \
        and then click the radio button of the desired chord. To replace\
        an existing guitar chord, position the insert before the guitar\
        chord and click the button of the desired chord. The `type' menubutton\
        allows you to change the type of chord that was selected. This will\
        remain the default as long as you don't do a refesh or move to another\
        file. After changing the type of chord, you should click on that chord\
        again in order to replace this chord in the text window. Note that\
        not all chords in the menu may be appropriate (ie. major versus minor);\
        however, these are all the chord types which abc2midi understand. The\
        inversion button allows you to invert the chord and make it a default.\
        The first inversion is indicated with a slash followed by the lowest note\
        in that chord (eg. C/E).\n\n\
        Following the chords is a list of other chords\
        which would follow in the progression. This is only for your information.\n\n\
        You can also move the insert point one bar at a time\
        using the <alt-f> and <alt-b> keys on your keyboard. You can listen to\
        the chord by using the <alt-p>  <alt-l> keys.\n\n\Note: if the key signature\
        changes and you wish to update the tool bar, merely position the insert\
        marker after the key change (indicated by the K: field command), and\
        click the refresh button. The chords in the toolbox will be replaced\
        with the new chords appropriate for this key signature."

#end of guitar.tcl


proc guitar_chord {} {
    #identifies key signature and puts up appropriate chord toolbar.
    global abctxtw
    global body_start body_end
    set point [$abctxtw index insert]
    if {![info exist body_end]} return
    if {$point > $body_end} {set point $body_start.0}
    set keysig none
    set kfield [$abctxtw search -backwards K: $point]
    if {[string length $kfield] > 1} {
        set kfield [$abctxtw get $kfield  "$kfield lineend"]
        set keysig [string range $kfield 2 end]
        set keysig [string trimright $keysig]
    }
    if {[string equal [string trimleft $keysig] none]} {set keysig C}
    guitar_toolbox $keysig
    grid .abcedit.pane.toolbox.guitartool -row 0 -sticky w
}



# Part 10.3             Transposition ToolBox


#transpose.tcl

set notekey "CDEFGABcdefgab"

proc shift_note_up {} {
    shift_single_note 1
}

proc shift_note_down {} {
    shift_single_note -1
}


proc shift_single_note {shift} {
    global abctxtw
    #method: grab line, find note, change note, replace line
    #this is a messy method but I could not figure out a simpler way.
    set note {[A-G]\,*|[a-g]\'*}
    set point [$abctxtw index insert]
    set selstart [lindex [split $point .] 0]
    set charstart [lindex [split $point .] 1]
    set to $selstart.end
    set from  $selstart.0
    set tmp [$abctxtw get $from $to]
    set success [regexp  -start $charstart -indices  $note $tmp match]
    if {!$success} return
    set pos1 [lindex $match 0]
    set pos2 [lindex $match 1]
    set key [string range $tmp  $pos1 $pos2]
    set newkey [shift_note $key $shift]
    set tmp [string replace $tmp $pos1 $pos2 $newkey]
    $abctxtw delete $from $to
    $abctxtw insert $from $tmp body
    $abctxtw mark set insert $point
}


proc shift_all_notes {buffer shift} {
    #scans line for musical notes and shifts it up or down.
    #In order to continue from where we left off, we strip
    #off the part of string that we have already scanned,
    #and keep track of the amount we stripped in the variable
    #offset plus any expansion or contraction of note (eg. b to c').
    set note {[A-G]\,*|[a-g]\'*}
    # decorations regex explained:
    # (?n) - honor lines:  ^ and $
    # (\![^\!]*\!)           - !decoration!
    # (^[ \t]*%.*$)          - comment lines (lines beginning with %)
    # (^[ \t]*[A-Za-z]:.*$)  - keyword lines
    # (\![^\!]*\!)           - !decoration!
    # (\[[ \t]*\"[^\"]*\"))  - part strings "part1"   (probably should be any strings, including guitar chords)
    #   (\"[^\"]*\")	   - guitar chords
    #   (\[.:[^]]*\])       - inline field command like [K: Gm]
    set decoration {(?n)((\![^\!]*\!)|(^[ \t]*%.*$)|(^[ \t]*[A-Za-z]:.*$)|(\[[ \t]*\"[^\"]*\"))|(\"[^\"]*\")|(\[.:[^]]*\])}
    set tmp $buffer
    set success 1
    set offset 0
    while {$success} {
        set success [regexp -indices $note $tmp match]
        if {!$success} break
        set skip [regexp -indices $decoration $tmp match_skip]
        # if the decoration comes before the note then skip the decoration
        if {$skip && [lindex $match_skip 0] < [lindex $match 0]} {
            set pos2 [lindex $match_skip 1]
            set offset [expr $offset + $pos2 + 1]
            set tmp [string range $buffer $offset end]
        } else {
            set pos1 [lindex $match 0]
            set pos2 [lindex $match 1]
            set key [string range $tmp  $pos1 $pos2]
            set newkey [shift_note $key $shift]
            #      puts "$key $newkey"
            set tmp [string range $tmp [expr $pos2 +1] end]
            set apos1 [expr $pos1 + $offset]
            set apos2 [expr $pos2 + $offset]
            set buffer [string replace $buffer $apos1 $apos2 $newkey]
            set offset [expr $offset + $pos1 + [string length $newkey]]
            #      puts "$offset $pos1 $pos2"
        }
    }
    return $buffer
}




proc shift_note {note shift} {
    # shift note by a given musical interval,up or down.
    # 1 or -1 is second
    # 2 or -2 is third...
    global notekey
    set n [string first [string index $note 0] $notekey]
    set m [expr [string length $note] - 1]
    if {$n < 7 && $m >0} {set m [expr -$m] }
    set n [expr $n + $shift]
    if {$n>13} {set n [expr $n - 7]
        incr m
    } elseif {$n<0} {set n [expr $n + 7]
        incr m -1
    }
    if {$n < 7 && $m>0} {
        set n [expr $n + 7]
        incr m -1
    } elseif {$n > 6 && $m<0} {
        set n [expr $n - 7]
        incr m
    }
    set result [string index $notekey $n]
    if {$m > 0} {set suffix [string repeat "'" $m]
        set result $result$suffix
    } elseif {$m < 0} { set m [expr -$m]
        set suffix [string repeat "," $m]
        set result $result$suffix
    }
    return $result
}


# Part 10.4             Note Length ToolBox


proc note_length_value {len} {
    set pat1 {(\d)}
    set pat2 {/(\d)}
    set pat3 {(\d)/(\d)}
    if {[regexp $pat3 $len match n1 n2]} {
        return  $len}
    if {[regexp $pat2 $len match n1]} {
        #   puts $match
        return 1$len}
    if {[regexp $pat1 $len match n1]} {
        #   puts $match
        return $len/1}
    switch $len {
        / {return 1/2}
        // {return 1/4}
        /// {return 1/8}
        default {return $len}
    }
}


proc combinefractions {frac1 frac2 dir} {
    # adds or subtracts fraction1 to fraction2 and returns a fraction
    set pat3 {([0-9]+)/([0-9]+)}
    #puts "combinefraction $frac1 $frac2"
    if {![regexp $pat3 $frac1 match n1 n2]} {return $frac1}
    if {![regexp $pat3 $frac2 match m1 m2]} {return $frac1}
    set k1 [expr $n1*$m2+$dir*$n2*$m1]
    set k2 [expr $n2*$m2]
    return [euclid $k1 $k2]
}


proc euclid {a b} {
    if {$a > $b} {
        set n $a
        set m $b} else {
        set n $b
        set m $a}
    
    while {$m != 0} {
        set t [expr $n % $m]
        set n $m
        set m $t
    }
    
    set a [expr $a/$n]
    set b [expr $b/$n]
    return [list $a $b]
}


proc expand_notelength {length} {
    set pat3 {([0-9]+)/([0-9]+)}
    set success [regexp $pat3 $length match n1 n2]
    #puts "expand_notelength $length $match $n1 $n2"
    if {$success} {
        if {$n1 == 1} {
            set incre 1/[expr $n2*2]} else {
            set incre 1/$n2}
        set newlength [combinefractions $length $incre 1]
        #  puts "newlength $newlength"
        set num [lindex $newlength 0]
        set denom [lindex $newlength 1]
        #  skip invalid multipliers
        switch $num {
            5 {return [list 6 $denom]}
            9 -
            10 -
            11 {return [list 12 $denom]}
            13 {return [list 14 $denom]}
            default {return $newlength}
        }
    }
}


proc contract_notelength {length} {
    set pat3 {([0-9]+)/([0-9]+)}
    set success [regexp $pat3 $length match n1 n2]
    #puts "contract_notelength = $n1 $n2"
    if {$success} {
        if {$n1 == 1} {
            set incre 1/[expr 4*$n2]} else {
            set incre 1/$n2}
        set newlength [combinefractions $length $incre -1]
        set num [lindex $newlength 0]
        set denom [lindex $newlength 1]
        #  skip invalid multipliers
        switch $num {
            5 {return [list 4 $denom]}
            9 -
            10 -
            11 {return [list 8 $denom]}
            13 {return [list 12 $denom]}
            default {return $newlength}
        }
    }
}



proc expand_contract_note {dir} {
    global abctxtw
    #method: grab line, find note, change note, replace line
    #this is a messy method but I could not figure out a simpler way.
    #set note {[A-G]\,*|[a-g]\'*}
    set notepat {(\^*|_*|=?)([A-G]\,*|[a-g]\'*|z)(/?[0-9]*|[0-9]*/*[0-9]*)}
    set point [$abctxtw index insert]
    set selstart [lindex [split $point .] 0]
    set charstart [lindex [split $point .] 1]
    set to $selstart.end
    set from  $selstart.0
    set tmp [$abctxtw get $from $to]
    set success [regexp  -start $charstart -indices  $notepat $tmp match]
    if {!$success} {puts "no note found"; return}
    set pos1 [lindex $match 0]
    set pos2 [lindex $match 1]
    
    #puts "note = $match"
    set keystr [string range $tmp $pos1 $pos2]
    regexp $notepat $keystr match acc key len
    if {$len == ""} {set len 1}
    #puts "extracted length = $len"
    set len [note_length_value $len]
    #puts "expand_contract_note: len = $len"
    
    #set len [expand_notelength $len]
    if {$dir} {set len [expand_notelength $len]
    } else {
        set len [contract_notelength $len]
    }
    #puts "new notelength $len"
    if {[lindex $len 1] == 1} {
        set len [lindex $len 0]
    } elseif {[lindex $len 0] == 1} {
        set len /[lindex $len 1]
    } else {
        set len [lindex $len 0]/[lindex $len 1]
    }
    #puts "expanded length $len"
    
    #set key [string range $tmp  $pos1 $pos2]
    if {$len != 1} {set newkey $acc$key$len
    } else {set newkey $acc$key}
    set tmp [string replace $tmp $pos1 $pos2 $newkey]
    $abctxtw configure -autoseparators False
    $abctxtw edit separator
    $abctxtw delete $from $to
    $abctxtw insert $from $tmp body
    $abctxtw configure -autoseparators True
    $abctxtw mark set insert $point
}



set hlp_transpose "Transpose function\n\n\
        The purpose of this function is to assist you in \
        creating a harmony line. First copy the music body and make it into \
        a separate voice. Then select a section of the voice by highlighting \
        it and then transpose it a certain number of intervals up or down. The \
        colour of the transposed section will be turned to black to make \
        it stand out. If you click the retag window it will be back to normal.\n\n\
        The function should ignore anything that is not a note, for example\
        guitar chords, comments and field commands however it may occasionally\
        make a mistake."


# Part 10.5           Editor Clean Functions

set hlp_clean "	Clean functions\n\n\
        retag:   color the comments, field comments and body of the edit window.\n\
        erase all:  clear the contents of the edit window.\n\n\
        The remaining functions require you to first select a region in the \
        body of the abc file (usually displayed as red).\n\
        remove redundant guitar chords: repeated guitar chords are deleted\
        in the selected area.\n\
        remove all guitar chords: all guitar chords enclosed in double quotes\
        are deleted in the selected area.\n\
        remove all grace notes: all ornaments and grace notes enclosed in\
        curly braces are removed.\n\
        remove inline voice fields: removes all occurring \[V:n\] indications\
        inside the selected area.\n\
        remove backslash continuations: removes the backslashes (typically at\
        the end of line) in the selected area.\n\
        remove tab chars: removes tabs in selected area.\n\n
Caution: guitar chords are recognized as pairs of double quotes. If your \
        selected area begins in the middle of a guitar chord, the function will \
        probably remove everything accept the guitar chords. The same also applies \
        to grace notes."

proc remove_guitar_chords {line dummy} {
    regsub -all  {"[^"]*"} $line "" result
    return $result
}

proc remove_redundant_guitar_chords {buffer dummy} {
    set pat {"[^"]*"}
    set tmp $buffer
    set success 1
    set offset 0
    set oldguitarchord ""
    while {$success} {
        set success [regexp -indices $pat $tmp match]
        if {!$success} break
        set pos1 [lindex $match 0]
        set pos2 [lindex $match 1]
        set guitarchord [string range $tmp  $pos1 $pos2]
        #puts $guitarchord
        set tmp [string range $tmp [expr $pos2 +1] end]
        set apos1 [expr $pos1 + $offset]
        set apos2 [expr $pos2 + $offset]
        if {[string compare $guitarchord $oldguitarchord] == 0} {
            set buffer [string replace $buffer $apos1 $apos2 ""]
            set offset [expr $offset - [string length $guitarchord]]}
        set offset [expr $offset + $pos2 +1]
        set oldguitarchord $guitarchord
    }
    return $buffer
}


# Part 10.6           Process Editor Buffer

proc process_buffer {action param} {
    global abctxtw
    set selrange [$abctxtw tag ranges sel]
    if {[llength $selrange] < 2} {
        messages "Please select an area in the body of the tune \
                and then try again. To select a region, hold the left mouse button \
                down and sweep an area."
        return
    } else {
        set selstart [lindex $selrange 0]
        set selend [lindex $selrange 1]
        set value [$abctxtw get $selstart $selend]
        set cmd [list $action $value $param]
        set value [eval $cmd]
        $abctxtw configure -autoseparators False
        $abctxtw edit separator
        $abctxtw delete $selstart $selend
        $abctxtw insert $selstart $value
        $abctxtw configure -autoseparators True
    }
    tag_text
}

proc process_region {action param} {
    global abctxtw
    set selrange [$abctxtw tag ranges sel]
    if {[llength $selrange] < 2} {
        messages "Please select an area in the body of the tune \
                and then try again. To select a region, hold the left mouse button \
                down and sweep an area."
        return
    } else {
        set selstart [lindex $selrange 0]
        set selend [lindex $selrange 1]
        set cmd [list $action [list $selstart $selend] $param]
        set value [eval $cmd]
        $abctxtw tag remove sel $selstart $selend
    }
    tag_text
}

# end of transpose.tcl


# Part 10.7                Grace Notes ToolBox

# source grace.tcl

proc grace_toolbox {} {
    global df
    global midi
    set g .abcedit.pane.toolbox.grace
    if {[winfo exist $g]} {destroy $g}
    frame $g -borderwidth 2 -relief sunken
    grid $g -row 1 -sticky w
    frame $g.0
    frame $g.1
    frame $g.2
    label $g.0.lab -text "Grace notes" -font $df
    button $g.0.help -text help -font $df -width 4 -padx 0\
            -command {show_message_page $hlp_grace word
                focus .abc
                raise .abc .abcedit}
    button $g.0.cfg -text cfg -font $df -width 3 -padx 0 -command grace_cfg
    button   $g.1.1 -text $midi(grname1) -font $df -width 7\
            -command "grace_note [list $midi(grseq1)]" -padx 0
    button   $g.1.2 -text $midi(grname2) -font $df -width 7\
            -command "grace_note [list $midi(grseq2)]" -padx 0
    button   $g.1.3 -text $midi(grname3) -font $df -width 7\
            -command "grace_note [list $midi(grseq3)]" -padx 0
    button   $g.2.1 -text $midi(grname4) -font $df -width 7\
            -command "grace_note [list $midi(grseq4)]" -padx 0
    button   $g.2.2 -text $midi(grname5) -font $df -width 7\
            -command "grace_note [list $midi(grseq5)]" -padx 0
    button   $g.2.3 -text $midi(grname6) -font $df -width 7\
            -command "grace_note [list $midi(grseq6)]" -padx 0
    
    pack $g.0.lab $g.0.help $g.0.cfg -side left -anchor w
    pack $g.1.1 $g.1.2 $g.1.3 -side left -anchor w
    pack $g.2.1 $g.2.2 $g.2.3 -side left -anchor w
    pack $g.0 $g.1 $g.2 -side top -anchor w
}


proc grace_cfg {} {
    global midi df
    set p .gracecfg
    if {[winfo exist $p]} return
    toplevel $p
    label $p.lab -text "grace notes configuration" -font $df
    grid $p.lab -columnspan 2
    for {set i 1} {$i < 7} {incr i} {
        entry $p.grname$i -width 7 -textvariable midi(grname$i) -font $df
        entry $p.grseq$i -width 12 -textvariable midi(grseq$i) -font $df
        grid $p.grname$i $p.grseq$i
        bind $p.grseq$i <Return> {focus .gracecfg.lab}
        bind $p.grname$i <Return> {focus .gracecfg.lab
            grace_toolbox}
    }
    button $p.reset -text "reset" -font $df -command reset_grace_cfg
    button $p.help -text help -font $df  -command {
        show_message_page $hlp_grace_cfg word
        focus .abc
        raise .abc .abcedit}
    grid $p.reset $p.help
}


proc reset_grace_cfg {} {
    global midi
    set midi(grname1) cut
    set midi(grname2) strike
    set midi(grname3) mordnt
    set midi(grname4) rmordnt
    set midi(grname5) slide
    set midi(grname6) trill
    set midi(grseq1) "1"
    set midi(grseq2) "-1"
    set midi(grseq3) "0 1"
    set midi(grseq4) "0 -1"
    set midi(grseq5) "-3 -2 -1 0"
    set midi(grseq6) "0 1 0 1"
    grace_toolbox
}


proc make_grace {base sequence} {
    set res ""
    foreach action $sequence {
        set note [shift_note $base $action]
        set res $res$note
    }
    return $res
}


proc grace_note {sequence} {
    global abctxtw
    set note {[A-G]|[a-g]}
    remove_these_grace_notes_if_any
    set loc [$abctxtw search  -regexp  -- $note insert]
    #  puts "loc = $loc"
    set base [$abctxtw get $loc]
    # check for transpose
    set next [$abctxtw index "$loc+1 char"]
    #  puts "next = $next"
    set t [$abctxtw get $next]
    if {$t == "," | $t == "'"} {set base $base$t}
    set grace [make_grace $base $sequence]
    set lastinsert [$abctxtw index insert]
    $abctxtw insert insert "\{$grace\}"
    $abctxtw mark set insert $lastinsert
}

proc remove_grace_notes {buffer dummy} {
    regsub -all  {\{[^\}]*\}} $buffer "" result
    return $result
}

proc remove_these_grace_notes_if_any {} {
    global abctxtw
    set t [$abctxtw get insert]
    if {$t == "\{" } {
        set grace_end [$abctxtw search \}  insert]
        $abctxtw delete insert "$grace_end +1 char"
    }
}


set hlp_grace "Grace toolbox\n\n\
        This toolbox is used for creating and inserting a grace \
        note sequence before a specific note in the music body. For example, for \
        if the cursor is placed before the note C, clicking 'trill'
will insert {DCDC}. n\n\
        Instructions: place the insert marker just before the note and click \
        the desired ornament you wish to insert. If you change your mind, use \
        <cntl-z> or undo to remove it.\n\nThe program looks at the following \
        note and computes the grace sequence appropriate for this note. If the \
        note is preceded by an accidental, it may be necessary for you to edit \
        the grace sequence.\n\n\
        Caution: if you are not careful in placing the \
        insert marker, you can create a syntacticly meaningless abc file."

set hlp_grace_cfg "Grace notes configuration\n\n\
        This frame allows you to change the names and grace sequence\
        of the grace buttons in the grace tool box of TclAbcEditor.\
        The names should be restricted to 7 or less letters. Enter a\
        carriage return to activate the change and remove the focus from\
        the entry box. The sequence of numbers in the entry box to the\
        right specify the pitches of the notes in the grace sequence relative\
        to the note it is being applied.\n\n\
        The changes that you make will be stored in runabc.ini. Clicking\
        the reset button will return the grace settings to their initial\
        defaults."


# end of grace.tcl

# Part 10.8                   Chords ToolBox

#source chords.tcl

proc notes2chords {buffer shift} {
    #scans line for musical notes and shifts it up or down.
    #In order to continue from where we left off, we strip
    #off the part of string that we have already scanned,
    #and keep track of the amount we stripped in the variable
    #offset plus any expansion or contraction of note (eg. b to c').
    set note {(\^*|_*|=?)([A-G]\,*|[a-g]\'*)(/?[0-9]*|[0-9]*/*[0-9])}
    # see proc shift_all_notes for description of decoration
    set decoration {(?n)((\![^\!]*\!)|(^[ \t]*%.*$)|(^[ \t]*[A-Za-z]:.*$)|(\[[ \t]*\"[^\"]*\"))|(\"[^\"]*\")|(\[.:[^]]*\])}
    set tmp $buffer
    set success 1
    set offset 0
    while {$success} {
        set success [regexp -indices $note $tmp match]
        if {!$success} break
        set skip [regexp -indices $decoration $tmp match_skip]
        if {$skip && [lindex $match_skip 0] < [lindex $match 0]} {
            set pos2 [lindex $match_skip 1]
            set offset [expr $offset + $pos2 + 1]
            set tmp [string range $buffer $offset end]
        } else {
            set pos1 [lindex $match 0]
            set pos2 [lindex $match 1]
            set keystr [string range $tmp  $pos1 $pos2]
            regexp $note $keystr match acc key len
            #puts "$keystr $acc $key $len"
            set newkey [shift_note $key $shift]
            set chord "\[$acc$key$len$acc$newkey$len\]"
            #puts $chord
            set tmp [string range $tmp [expr $pos2 +1] end]
            set apos1 [expr $pos1 + $offset]
            set apos2 [expr $pos2 + $offset]
            set buffer [string replace $buffer $apos1 $apos2 $chord]
            set offset [expr $offset + $pos1 + [string length $chord]]
            #    puts "$offset $pos1 $pos2"
        }
    }
    return $buffer
}

set hlp_chords "Note to chord\n\n\
        The function replaces the notes in the selected \
        area with chords, going a specified interval down from the given note. \
        Thus G2 would be replaced with \[G2E2\] if a third is requested.\
        Note that abc2midi does not handle the syntax \[AC\] > \[GB\].\
        You should spell out C>B to C3/2B/ before applying the \
        chord operator."


#end chords.tcl

# Part 11.0                   Show Summary Sheet ,tmpfile and message sheet

proc show_tmpfile {} {
    global midi df
    set p .tmpfile
    set num 0
    if [winfo exist $p] {destroy $p}
    toplevel $p
    text $p.t -height 15 -width 80 -wrap char \
            -font $df -yscrollcommand ".tmpfile.ysbar set"
    scrollbar $p.ysbar -orient vertical -command {.tmpfile.t yview}
    pack $p.ysbar -side right -fill y -in $p
    pack $p.t -in $p -expand y -fill both
    $p.t tag configure grey -background grey80
    set handle [open $midi(midi_dir)/X.tmp]
    while {[eof $handle] != 1} {
        gets $handle line
        incr num
        $p.t insert end "$num: $line\n"
    }
    close $handle
}

proc save_tmpfile {} {
    global midi
    global types
    set filedir [file dirname $midi(midi_save)]
    set midi(abc_save) [tk_getSaveFile -initialdir $filedir -filetypes $types]
    file copy -force  $midi(midi_dir)/X.tmp $midi(abc_save)
    puts "copied X.tmp to $midi(abc_save)"
}

proc make_summary_toplevel {} {
    global df
    set p .summary
    toplevel $p
    text $p.t -height 8 -width 60 -wrap char -bg #f4ece0 \
            -font $df -yscrollcommand ".summary.ysbar set"
    scrollbar $p.ysbar -orient vertical -command {.summary.t yview}
    pack $p.ysbar -side right -fill y -in $p
    pack $p.t -in $p -expand y -fill both
}

proc show_summary {i} {
    global midi df fileseek
    global abc_file_mod
    set p .summary
    if [winfo exist $p] {.summary.t delete 1.0 end} else make_summary_toplevel
    if {$abc_file_mod}  {title_index $midi(abc_open)}
    set loc $fileseek($i)
    set abcfile $midi(abc_open)
    set edithandle [open $abcfile r]
    seek $edithandle $loc
    set line [find_X_code $edithandle]
    $p.t insert end "$line\n"
    while {[string length $line] > 0 } {
        set line  [get_nonblank_line $edithandle]
        if {[string index $line 0] == "X"} break;
        $p.t insert end "$line\n"
        if {$midi(summary_enabled)<2 && [string index $line 0] == "K"} break;
    }
    close $edithandle
}

proc show_message_page {text wrapmode} {
    global active_sheet df
    #remove_old_sheet
    set p .notice
    if [winfo exist .notice] {
        $p.t configure -state normal -font $df
        $p.t delete 1.0 end
        $p.t insert end $text
        #   $p.t configure -state disabled -wrap $wrapmode
    } else {
        toplevel $p
        text $p.t -height 15 -width 50 -wrap $wrapmode -font $df -yscrollcommand {.notice.ysbar set}
        scrollbar $p.ysbar -orient vertical -command {.notice.t yview}
        pack $p.ysbar -side right -fill y -in $p
        pack $p.t -in $p -fill both -expand true
        $p.t insert end $text
        #   $p.t configure -state disabled
    }
    raise $p .
}


proc run_abc2abc {} {
    global midi df
    global abc2abc_s  abc2abc_u  abc2abc_d  abc2abc_t abc2abc_n abc2abc_V
    global abc2abc_e abc2abc_n_val  abc2abc_t_val abc2abc_V_val
    global abc2abc_P abc2abc_P_val
    global abc2abc_v abc2abc_nk abc2abc_useflats
    global abc2abc_usekey
    set abc2abc_tofile 1
    set abc2abc_opt ""
    if {$abc2abc_s} {append abc2abc_opt "-s "}
    if {$abc2abc_e} {append abc2abc_opt "-e "}
    if {$abc2abc_v} {append abc2abc_opt "-v "}
    if {$abc2abc_u} {append abc2abc_opt "-u "}
    if {$abc2abc_d} {append abc2abc_opt "-d "}
    if {$abc2abc_nk} {
        if {!$abc2abc_usekey} {
            if {$abc2abc_useflats}  {append abc2abc_opt "-nokeyf "
            } else {append abc2abc_opt "-nokeys "}
        } else {
            append abc2abc_opt "-usekey $abc2abc_usekey "
        }
    }
    if {$abc2abc_t} {append abc2abc_opt "-t $abc2abc_t_val "}
    if {$abc2abc_n} {append abc2abc_opt "-n $abc2abc_n_val "}
    if {$abc2abc_V} {append abc2abc_opt "-V $abc2abc_V_val "}
    if {$abc2abc_P} {append abc2abc_opt "-P $abc2abc_P_val "}
    copy_selection_to_file [title_selected] $midi(abc_open) $midi(midi_dir)/X.tmp
    if {$midi(no_clipboard)} {
        set cmd "exec [list $midi(path_abc2abc)] \
                [list $midi(midi_dir)/X.tmp] $abc2abc_opt > [list $midi(abc_default_file)]"
        catch {eval $cmd} exec_out
        if {[string first "no such" $exec_out] >= 0} {abcmidi_no_such_error $midi(path_abc2abc)}
        tcl_abc_edit $midi(abc_default_file) 1
        .abc.abc2abc.10 configure -font $df -text "$cmd\n$exec_out"
    } else {
        set cmd "exec [list $midi(path_abc2abc)]  [list $midi(midi_dir)/X.tmp] $abc2abc_opt"
        catch {eval $cmd} exec_out
        if {[string first "no such" $exec_out] >= 0} {abcmidi_no_such_error $midi(path_abc2abc)}
        clipboard clear
        clipboard append $exec_out
        .abc.abc2abc.10 configure -font $df -text "$cmd\nThe results are in the clipboard."
    }
    #puts $cmd
    update_console_page
}




startup_progress "loading property sheets"


#Part 12.0  Property Sheets -- titles, voice, style, abc2abc, midi2abc etc

######################
#   Property Sheets  #
######################


set active_sheet none

proc remove_old_sheet {} {
    global active_sheet
    switch -- $active_sheet {
        none   {pack forget .abc.titles}
        midi   {remove_midi_page}
        voice  {pack forget .abc.voice}
        psstyle {pack forget .abc.psstyle}
        psform {pack forget .abc.psform}
        extract {remove_extract_page}
        yaps   {pack forget .abc.yaps}
        config {remove_cfg_page}
        titles {pack forget .abc.titles}
        abc2abc {pack forget .abc.abc2abc}
        midi2abc {pack forget .midi2abc}
        otherps {pack forget .abc.otherps}
        incipits {pack forget .abc.incipits}
        g2v {pack forget .abc.g2v}
        reformat {pack forget .abc.reformat}
    }
}

proc show_other_ps {} {
    global active_sheet midi
    remove_old_sheet
    pack .abc.otherps -side left
    set active_sheet otherps
}

proc show_ps_page {type} {
    global active_sheet midi
    
    remove_old_sheet
    if {$active_sheet == $type} {
        set active_sheet "none"
    } else {
        if {$midi(ps_creator)=="yaps"} {
            pack .abc.yaps -side left
            set active_sheet yaps
        } else {
            pack .abc.$type
            set active_sheet $type
        }
    }
}

proc show_abc2abc_page {} {
    global active_sheet
    remove_old_sheet
    if {$active_sheet == "abc2abc"} {
        set active_sheet none
    }  else {
        pack .abc.abc2abc -side left
        set active_sheet abc2abc
        .abc.abc2abc.10 configure -text ""
    }
}


set midi_subsection 0

proc show_midi_page {subsection} {
    global active_sheet midi_subsection
    
    remove_old_sheet
    if {$active_sheet == "midi" && $subsection == $midi_subsection} {
        set active_sheet "none"
        set midi_subsection 0
    } else {
        switch -- $subsection {
            1 { set w_list {tempo transpose} }
            2 { set w_list {melody double chord bass beat over gchord drum drumpat drone msg} }
            8 { set w_list {player grace divider broken barfly drummethod reset} }
            13 { set w_list {drone}}
            default { set w_list "" }
        }
        foreach i $w_list {
            pack .abc.midi1.$i -side top
        }
        set midi_subsection $subsection
        pack .abc.midi1
        set active_sheet midi
    }
}


proc remove_midi_page {} {
    global midi_subsection
    
    switch -- $midi_subsection {
        1 { set w_list {tempo transpose} }
        2 { set w_list {melody double chord bass beat over gchord drum drumpat drone msg}}
        8 { set w_list {player grace divider barfly broken reset} }
        13 { set w_list {drone}}
        default { set w_list "" }
    }
    foreach i $w_list {
        pack forget .abc.midi1.$i
    }
    pack forget .abc.midi1
}


proc show_voice_page {} {
    global active_sheet
    
    remove_old_sheet
    if {$active_sheet == "voice"} {
        set active_sheet "none"
    } else {
        pack .abc.voice
        set f .abc.voice.canvas.f
        set child $f.pan1
        tkwait visibility $child
        set bbox [grid bbox $f 0 0]
        #      puts $bbox
        set width [winfo reqwidth .abc]
        set height [winfo reqheight $f]
        set incr [lindex $bbox 3]
        .abc.voice.canvas config -scrollregion "0 0 $width $height"
        .abc.voice.canvas config -yscrollincrement $incr
        set height [expr $incr * 10]
        .abc.voice.canvas  config -width $width -height $height
        set active_sheet voice
    }
}


proc show_titles_page {} {
    global active_sheet
    
    remove_old_sheet
    if {$active_sheet == "titles"} {
        set active_sheet "none"
    } else {
        pack .abc.titles -expand y -fill both
        set active_sheet titles
    }
    focus .abc.titles.t
}


set cfg_subsection 0


proc show_config_page {subsection} {
    global active_sheet
    global cfg_subsection
    
    remove_old_sheet
    if {$active_sheet == "config" && $subsection == $cfg_subsection} {
        set active_sheet "none"
        set cfg_subsection 0
    } else {
        switch -- $subsection {
            1 { set w_list {26 1 20 4 10 23 29 22 12} }
            2 { set w_list {5 6 13 7 8 14 19} }
            4 { set w_list {9 18 15 16 17 27} }
            default { set w_list "" }
        }
        foreach i $w_list {
            pack .abc.cfg.$i -side top
        }
        set cfg_subsection $subsection
        pack .abc.cfg
        set active_sheet config
    }
}

proc show_configure_abcmidi_packages {} {
    # abc2midi, abc2abc, yaps, midi2abc, and midicopy.
    pack .abc.cfg.3  -side top -after .abc.cfg.26
    pack .abc.cfg.21 -side top -after .abc.cfg.3
    pack .abc.cfg.2 -side top -after .abc.cfg.21
    pack .abc.cfg.24 -side top -after .abc.cfg.2
    pack .abc.cfg.25 -side top -after .abc.cfg.24
}

proc show_extract_page {} {
    global active_sheet
    
    remove_old_sheet
    if {$active_sheet == "extract"} {
        set active_sheet "none"
    } else {
        pack .abc.extract
        set active_sheet extract }
}

proc show_reformat_page {} {
    global active_sheet
    global df 
    remove_old_sheet
    if {$active_sheet == "reformat"} {
        set active_sheet "none"
    } else {
        pack .abc.reformat
        set active_sheet reformat
        .abc.reformat.mesg configure -text "" -font $df}
}


proc show_g2v_page {} {
    global active_sheet
    
    remove_old_sheet
    if {$active_sheet == "g2v"} {
        set active_sheet "none"
    } else {
        pack .abc.g2v
        set active_sheet g2v }
}




proc remove_cfg_page {} {
    global cfg_subsection
    
    switch -- $cfg_subsection {
        1 { set w_list {26 1 20 2 21 24 3 25 4 10 23 29 22 12} }
        2 { set w_list {5 6 13 7 8 14 19} }
        4 { set w_list {9 18 15 16 17 27} }
        default { set w_list "" }
    }
    foreach i $w_list {
        pack forget .abc.cfg.$i
    }
    pack forget .abc.cfg
}

proc remove_extract_page {} {
    pack forget .abc.extract
}

proc setpath {path_var} {
    global midi
    
    set filedir [file dirname $midi($path_var)]
    set openfile [tk_getOpenFile -initialdir $filedir]
    if {[string length $openfile] > 0} {
        set midi($path_var) $openfile
        update
    }
}

proc locate_abcmidi_executables {} {
    global midi
    global exec_out
    set exec_out ""
    set dirname [tk_chooseDirectory]
    if {[string length $dirname] < 1} return
    set midi(dir_abcmidi) $dirname
    foreach exec {abc2midi abc2abc yaps midi2abc midicopy abcmatch} {
        if {[file exist $dirname/$exec.exe]} {
            set midi(path_$exec) $dirname/$exec.exe
        } elseif {[file exist $dirname/$exec]} {
            set filename $exec
            set midi(path_$exec) $dirname/$exec} else {
            append exec_out "cannot find $dirname/$exec or $dirname/$exec.exe\n" }
    }
    show_checkversion_summary
    show_configure_abcmidi_packages
    update_console_page
}


#	Abc2ps Property Sheet

set w .abc.psform
frame $w
label $w.heading -text "abc2ps/abcm2ps options" -font $df
grid $w.heading

radiobutton $w.pretty1 -text "pretty 1" \
        -variable midi(ps_fmt_flag) -value 1 -command show_my_style -font $df
radiobutton $w.pretty2 -text "pretty 2" \
        -variable midi(ps_fmt_flag) -value 2 -command show_my_style -font $df
radiobutton $w.myown -text "use my own style" \
        -variable midi(ps_fmt_flag) -value 0  -command show_my_style -font $df
radiobutton $w.ulayout -text "use layout file" \
        -variable midi(ps_fmt_flag) -value 3 -command show_my_style -font $df
button $w.browselayout -text "browse layout file" -font $df\
        -command {setpath ps_fmt_file}
radiobutton $w.landscape -text "landscape" \
        -variable midi(ps_fmt_flag) -value 4 -command show_my_style -font $df
entry $w.layoutfile -width 24 -textvariable midi(ps_fmt_file) -font $df
$w.layoutfile xview moveto 1.0


label $w.glue -text glue  -font $df
set glmenu [tk_optionMenu $w.gluemenu midi(ps_glue) shrink space stretch fill]
$w.gluemenu configure -font $df
$glmenu configure -font $df
label $w.scalebut -text scale  -font $df
entry $w.scaleent -width 10 -relief sunken -textvariable midi(ps_scale) -font $df
label $w.widthbut -text width -font $df
entry $w.widthent -width 10 -relief sunken -textvariable midi(ps_width) -font $df
label $w.lmargbut -text "left margin" -font $df
entry $w.lmargent -width 10 -relief sunken -textvariable midi(ps_lmargin) -font $df
label $w.shrinkbut -text shrinkage -font $df
entry $w.shrinkent -width 10 -relief sunken -textvariable midi(ps_shrink) -font $df
label $w.staffseplab -text "staff separation" -font $df
entry $w.staffsepent -width 10 -relief sunken -textvariable midi(ps_staffsep) -font $df
label $w.other_opts -text "other options" -font $df
entry $w.other_optsent -width 24 -relief sunken -textvariable midi(ps_other_options) -font $df

grid $w.pretty1 $w.pretty2   -sticky w
grid $w.myown   $w.landscape -sticky w
grid $w.ulayout $w.layoutfile -sticky w
grid $w.browselayout -sticky w

bind $w.layoutfile <Return> {focus .abc.psform.heading}
bind $w.scaleent   <Return> {focus .abc.psform.heading}
bind $w.widthent   <Return> {focus .abc.psform.heading}
bind $w.lmargent   <Return> {focus .abc.psform.heading}
bind $w.shrinkent  <Return> {focus .abc.psform.heading}
bind $w.staffsepent <Return> {focus .abc.psform.heading}
bind $w.other_optsent <Return> {focus .abc.psform.heading}


set w .abc.psstyle
frame $w
checkbutton $w.bref -text "reference numbers" -variable midi(ps_bxref) -font $df
checkbutton $w.bar  -text "number bar lines"  -variable midi(ps_bbar) -font $df
checkbutton $w.hist -text "show history"      -variable midi(ps_bhist) -font $df
checkbutton $w.bnumb -text "page numbers"     -variable midi(ps_bnumb) -font $df
checkbutton $w.bppage -text "one tune/page"   -variable midi(ps_bppage) -font $df
checkbutton $w.nolyric -text "no lyrics"      -variable midi(ps_nolyric) -font $df
checkbutton $w.noslur -text "no slurs"        -variable midi(ps_noslur) -font $df

label $w.maxvlab -text "Maximum voices" -font $df
label $w.maxslab -text "Maximum symbols" -font $df
entry $w.maxvent -width 10 -relief sunken -textvariable midi(ps_maxvent) -font $df
entry $w.maxsent -width 10 -relief sunken -textvariable midi(ps_maxsent) -font $df
checkbutton $w.ps_c -text "ignore line ends" -variable midi(ps_c) -font $df
checkbutton $w.voices -text "select voices" -variable midi(bpsvoice) -font $df
entry $w.voicesent -width 10 -textvariable midi(psvoice) -font $df

grid $w.bref    $w.bar       -sticky w
grid $w.ps_c    $w.hist      -sticky w
grid $w.bnumb   $w.bppage    -sticky w
grid $w.nolyric $w.noslur    -sticky w
#grid $w.voices  $w.voicesent -sticky w
#grid $w.maxvlab $w.maxvent   -sticky w
#grid $w.maxslab $w.maxsent   -sticky w


#       reformat property sheet
set w .abc.reformat
frame $w
frame $w.1
frame $w.2
frame $w.4
label $w.1.1 -text "Reformat" -font $df
pack $w.1.1 -side left
pack $w.1
checkbutton $w.2.interleave -text "voice interleave" \
        -variable midi(interleave) -font $df
label $w.2.bpllab -text "bars per line" -font $df
entry $w.2.bplent -textvariable midi(midibpl) -width 2 -font $df
bind $w.2.bplent <Return> {focus .abc.reformat.1}
label $w.2.bpslab -text "bars per staff" -font $df
entry $w.2.bpsent -textvariable midi(midibps) -width 2 -font $df
bind $w.2.bpsent <Return> {focus .abc.reformat.1}
pack $w.2.bpllab $w.2.bplent $w.2.bpslab $w.2.bpsent $w.2.interleave\
        -side left -anchor w
pack $w.2
button $w.4.1 -text "reformat" -font $df\
        -command {tcl_abc_edit edit.abc 0
            set tunestring [return_selected_tune]
            Refactor::process_tune $tunestring
            Refactor::reconstitute
            tag_text
        }
pack $w.4.1 -side left
pack $w.4
label $w.mesg -text ""
pack $w.mesg


#	extract property sheet

set w .abc.extract
frame $w
frame $w.1
frame $w.2
frame $w.3
frame $w.4
set extract_v 1
set extract_t 0
label $w.1.2 -text "Voice:" -font $df
entry $w.1.3 -width 2 -relief sunken -textvariable extract_v -font $df
label $w.1.4 -text "Transpose:" -font $df
entry $w.1.5 -width 2 -relief sunken -textvariable extract_t -font $df
pack  $w.1.2 $w.1.3 $w.1.4 $w.1.5 -padx 3 -pady 3 -side left -anchor w

label $w.2.lab -text remove -font $df
checkbutton $w.2.chk1 -text "voice fields" -font $df -variable midi(remove_voice)
checkbutton $w.2.chk3 -text "backslashes" -font $df -variable midi(remove_backslashes)
pack $w.2.lab $w.2.chk1 $w.2.chk3 -side left -anchor w

checkbutton $w.3.chk1 -text "condense rests" -font $df -variable midi(condense_on)
radiobutton $w.3.rad1 -text "using Zn" -font $df -variable midi(condense_method) -value 0
radiobutton $w.3.rad2 -text "using \"n\"z" -font $df -variable midi(condense_method) -value 1
radiobutton $w.3.rad3 -text "auto" -font $df -variable midi(condense_method) -value 2
pack $w.3.chk1 $w.3.rad1 $w.3.rad2 $w.3.rad3 -side left -anchor w



button $w.4.0 -text "Display"      -font $df -borderwidth 3  -command {extract_action display}
button $w.4.1 -text "Save to file" -font $df -borderwidth 3  -command {extract_action save}
button $w.4.2 -text "To editor"    -font $df -borderwidth 3  -command {extract_action edit}
pack $w.4.0 $w.4.1 $w.4.2  -padx 15 -pady 3 -side left -anchor w

label $w.5
pack $w.1 $w.2 $w.3 $w.4  -side top
pack $w.5



#      g2v property sheet

set chosenvoice 1
set gchordvoiceid 2
set drumsvoiceid 3

set w .abc.g2v
frame $w
frame $w.1
frame $w.2
frame $w.3
frame $w.4
frame $w.5
frame $w.6
frame $w.7
frame $w.8
frame $w.9
frame $w.msg

label $w.0 -text "gchords/drums to voice" -font $df
label $w.1.lab -text "default gchord string" -font $df
entry $w.1.ent -width 24 -textvariable gvchordstring -font $df
label $w.5.lab -text "default drum string" -font $df
entry $w.5.ent -width 32 -textvariable midi(drumpat) -font $df
label $w.6.lab -text "input voice name or number" -font $df
entry $w.6.ent -width 10 -textvariable chosenvoice -font $df
button $w.4.go -text "create tune" -font $df -command g2v
label $w.7.lab -text "gchord voice id" -font $df
label $w.8.lab -text "drums voice id" -font $df
entry $w.7.ent -width 10 -textvariable gchordvoiceid -font $df
entry $w.8.ent -width 10 -textvariable drumsvoiceid -font $df
checkbutton $w.9.but -text "use drum map" -font $df -variable midi(drummap)

label $w.msg.txt -text "" -font $df
radiobutton $w.2.0 -text "output to clipboard"  -variable midi(g2v_clipboard) \
        -relief flat -value 1  -font $df
radiobutton $w.2.1 -text "output to editor"     -variable midi(g2v_clipboard) \
        -relief flat -value 0  -font $df
radiobutton $w.3.0 -text "gchords only" -font $df -variable dvoice -value 1
radiobutton $w.3.1 -text "drums  only" -font $df -variable dvoice -value 2
radiobutton $w.3.2 -text "gchords and drums" -font $df -variable dvoice -value 0
pack $w.0
pack $w.1.lab  $w.1.ent -side left -anchor w
pack $w.5.lab $w.5.ent -side left -anchor w
pack $w.6.lab $w.6.ent -side left -anchor w
pack $w.7.lab $w.7.ent -side left -anchor w
pack $w.8.lab $w.8.ent -side left -anchor w
pack $w.9.but -side left -anchor w
pack $w.2.0 $w.2.1 -side left
pack $w.3.0 $w.3.1 $w.3.2 -side left
pack $w.4.go -side left
pack $w.msg.txt -side left
pack $w.1 $w.5 $w.6 $w.2 $w.3 $w.7 $w.8 $w.9 $w.4 $w.msg -side top -anchor w
bind .abc.g2v.1.ent   <Return> {focus .abc.g2v.1.lab}
bind .abc.g2v.5.ent   <Return> {focus .abc.g2v.1.lab}





# midisave_tool property sheet

set p .abc.midisavetool
set midi(namelen) 8
set midi(name) 1
frame $p
label $p.1
label $p.2 -text "You will need to specify a directory" -font $df
radiobutton $p.t -text "get filename from title" -variable midi(name) -value 1 -font $df
radiobutton $p.x -text "get filename from xref" -variable midi(name) -value 0 -font $df
entry $p.te -width 2 -textvariable midi(namelen) -font $df
label $p.char -text char -font $df
entry $p.xr -width 10 -textvariable midi(nameroot) -font $df
button $p.co -text continue -font $df -command {midisave_list_continue}
button $p.ca -text cancel -font $df -command {pack forget .abc.midisavetool}
button $p.he -text help -font $df -command {show_message_page $hlp_midisave word}
grid $p.1
grid $p.2
grid $p.t $p.te $p.char
grid $p.x $p.xr
grid $p.co $p.ca $p.he




#	yaps property sheet

set yaps_size {"Letter 8.5 x 11 in" "Tabloid 11 x 17 in" "Ledger 17 x 11 in" \
            "Legal 8.5 x 14 in" "Statement 5.5 x 8.5 in" "Executive 7.5 x 10 in" \
            "A3 297 x 420 mm" "A4 210 x 297 mm" "A5 148 x 210 mm" "B4 257 x 364 mm" \
            "B5 182 x 257 mm" "Folio 8.5 x 13 mm" "Quarto 8.5 x 10.8 in" \
            "10 x 14 10 x14 in"}

set w .abc.yaps
frame $w
label $w.heading -text "yaps options" -font $df
grid $w.heading  -sticky w
label $w.scalebut -text scale  -font $df
entry $w.scaleent -width 10 -relief sunken -textvariable midi(yaps_scale) -font $df
grid $w.scalebut $w.scaleent -sticky w
label $w.lmargbut -text "left margin" -font $df
entry $w.lmargent -width 10 -relief sunken -textvariable midi(yaps_lmargin) -font $df
label $w.lmargunits -text "points" -font $df
grid $w.lmargbut $w.lmargent $w.lmargunits -sticky w
label $w.tmargbut -text "top margin" -font $df
entry $w.tmargent -width 10 -relief sunken -textvariable midi(yaps_tmargin) -font $df
label $w.tmargunits -text "points" -font $df
grid $w.tmargbut $w.tmargent $w.tmargunits -sticky w
label $w.papersizelab -text "paper size" -font $df
set v $w.papersizemenu
menubutton $v -text [lindex $yaps_size $midi(papersize)]   \
        -relief raised  -menu $v.type -font $df
menu $v.type -tearoff 0
set i 0
foreach item $yaps_size {
    $v.type add command -label $item -command "yaps_papersize $i" -font $df
    incr i
}
grid $w.papersizelab $w.papersizemenu -sticky w
checkbutton $w.voicechk -text "separate voices" -font $df \
        -variable midi(yaps_voice)

checkbutton $w.xchk -text "X tune number" -font $df \
        -variable midi(yapsx)
grid $w.voicechk $w.xchk -sticky w

checkbutton $w.land -text "Landscape" -font $df \
        -variable midi(yaps_landscape)

checkbutton $w.bar  -text "number bar lines"  -variable midi(yaps_bbar) -font $df
grid $w.land $w.bar -sticky w

set w .abc.otherps
frame $w
label $w.heading -text "other postscript converters" -font $df
pack $w.heading -side top
frame $w.exc
label $w.exc.lab -text executable -font $df
entry $w.exc.ent -textvariable midi(path_otherps) -width 36 -font $df
pack $w.exc.lab $w.exc.ent -side left
pack $w.exc -side top
frame $w.opt
label $w.opt.lab -text "exec options" -font $df
entry $w.opt.ent -width 36 -relief sunken -textvariable midi(otherps) -font $df
pack $w.opt.lab $w.opt.ent -side left
pack $w.opt -side top





proc yaps_papersize {size} {
    global midi yaps_size df
    
    .abc.yaps.papersizemenu config -text [lindex $yaps_size $size] -font $df
    set midi(papersize) $size
}


proc show_my_style {} {
    global midi
    
    set w .abc.psform
    if {$midi(ps_fmt_flag) == 0} {
        grid $w.scalebut $w.scaleent -sticky w
        grid $w.widthbut $w.widthent -sticky w
        grid $w.lmargbut $w.lmargent -sticky w
        grid $w.shrinkbut $w.shrinkent -sticky w
        grid $w.staffseplab $w.staffsepent -sticky w
        if {$midi(ps_creator) == "abc2ps"} {
            grid $w.glue $w.gluemenu -sticky w}
        if {$midi(ps_creator) == "abcm2ps"} {
            grid $w.other_opts $w.other_optsent -sticky w}
    } else {
        grid forget $w.scalebut $w.scaleent
        grid forget $w.widthbut $w.widthent
        grid forget $w.lmargbut $w.lmargent
        grid forget $w.shrinkbut $w.shrinkent
        grid forget $w.staffseplab $w.staffsepent
        grid forget $w.glue $w.gluemenu
        grid forget $w.other_opts $w.other_optsent
    }
}

show_my_style

proc change_font {usesamplefont} {
    global midi df sf samplefont tocf
    if {[info exist samplefont] && $usesamplefont} {
        set midi(font_family) $samplefont}
    font configure $df -family $midi(font_family) -size $midi(font_size) \
            -weight $midi(font_weight)
    font configure $sf -size $midi(font_size) -weight $midi(font_weight)
    font configure $tocf -family $midi(font_family_toc)  -size $midi(font_size)\
            -weight $midi(font_weight)
    #.abc.titles.t configure -font $tocf
    .abc.titles.t tag configure tune -font $df
}

proc reset_font {} {
    global midi df
    set midi(font_family) helvetica
    font configure $df -family $midi(font_family) -size $midi(font_size) \
            -weight $midi(font_weight)
}



#	Midi Property Sheet

set w .abc.midi1
frame $w

frame $w.tempo
label $w.tempo.0 -text tempo -width 8 -font $df
scale $w.tempo.1 -from 0 -to 320 -length 240  \
        -width 10 -orient horizontal  -showvalue true \
        -variable midi(tempo)   -font $df
pack $w.tempo.0 $w.tempo.1  -side left

frame $w.transpose
label $w.transpose.0 -text transpose -font $df
scale $w.transpose.1 -from -24 -to 24 -length 240 -width 10 \
        -orient horizontal  -showvalue true -variable midi(transpose)   -font $df
pack $w.transpose.0 $w.transpose.1 -side left


frame $w.over
checkbutton $w.over.1 -text "override tempo " \
        -variable midi(ignoreQ)  -font $df

checkbutton $w.over.2 -text "override  midi " \
        -variable midi(ignoremidi) -font $df

button $w.over.random -text "random" -font $df -command random_arrangement

#label $w.randlab -text "randomize instruments for melody, chords, and bass" -font $df

#set w .abc.midi1.reset

#label $w.over.3 -text indications -font $df
pack $w.over.1 $w.over.2 $w.over.random -side left
tooltip::tooltip $w.over.1 "overrides tempo indications\nif any embedded in the tune"
tooltip::tooltip $w.over.2 "overrides MIDI indications\nif any embedded in the tune"
tooltip::tooltip $w.over.random "randomize the instrument assignments\nto the melody, chords and bass"

frame $w.player
label $w.player.lab -text "midi player" -font $df
radiobutton $w.player.b0 -text "player 1"  -variable midi(player) \
        -relief flat -value 0  -font $df
radiobutton $w.player.b1 -text "player 2"  -variable midi(player) \
        -relief flat -value 1  -font $df
pack  $w.player.lab $w.player.b0 $w.player.b1 -side left


set melody 1
set chords 1



# program property page

set m(1) {"0 Acoustic Grand" "1 Bright Acoustic" "2 Electric Grand" \
            "3 Honky-Tonk" "4 Electric Piano 1" "5 Electric Piano 2" "6 Harpsichord" \
            "7 Clav" }

set m(2) {" 8 Celesta" " 9 Glockenspiel" "10 Music Box" "11 Vibraphone" "12 Marimba" \
            "13 Xylophone" "14 Tubular Bells" "15 Dulcimer"}

set m(3) {"16 Drawbar Organ" "17 Percussive Organ" "18 Rock Organ" \
            "19 Church Organ" "20 Reed Organ" "21 Accordian" "22 Harmonica" "23 Tango Accordian"}

set m(4) { "24 Acoustic Guitar (nylon)" "25 Acoustic Guitar (steel)" \
            "26 Electric Guitar (jazz)" "27 Electric Guitar (clean)" \
            "28 Electric Guitar (muted)" "29 Overdriven Guitar" \
            "30 Distortion Guitar" "31 Guitar Harmonics"}

set m(5) {"32 Acoustic Bass" "33 Electric Bass (finger)" \
            "34 Electric Bass (pick)" "35 Fretless Bass" "36 Slap Bass 1" \
            "37 Slap Bass 2" "38 Synth Bass 1" "39 Synth Bass 2" }

set m(6) { "40 Violin" "41 Viola" "42 Cello" "43 Contrabass" "44 Tremolo Strings" \
            "45 Pizzicato Strings" "46 Orchestral Strings" "47 Timpani" }

set m(7) { "48 String Ensemble 1" "49 String Ensemble 2" "50 SynthStrings 1" \
            "51 SynthStrings 2" "52 Choir Aahs" "53 Voice Oohs" "54 Synth Voice" "55 Orchestra Hit" }

set m(8) { "56 Trumpet" "57 Trombone" "58 Tuba" "59 Muted Trumpet" "60 French Horn" \
            "61 Brass Section" "62 SynthBrass 1" "63 SynthBrass 2"}

set m(9) { "64 Soprano Sax" "65 Alto Sax" "66 Tenor Sax" "67 Baritone Sax" \
            "68 Oboe" "69 English Horn" "70 Bassoon" "71 Clarinet" }

set m(10) { "72 Piccolo" "73 Flute" "74 Recorder" "75 Pan Flute" "76 Blown Bottle" \
            "77 Skakuhachi" "78 Whistle" "79 Ocarina" }

set m(11) { "80 Lead 1 (square)" "81 Lead 2 (sawtooth)" "82 Lead 3 (calliope)" \
            "83 Lead 4 (chiff)" "84 Lead 5 (charang)" "85 Lead 6 (voice)" \
            "86 Lead 7 (fifths)" "87 Lead 8 (bass+lead)"}

set m(12) { "88 Pad 1 (new age)" "89 Pad 2 (warm)" "90 Pad 3 (polysynth)" \
            "91 Pad 4 (choir)" "92 Pad 5 (bowed)" "93 Pad 6 (metallic)" "94 Pad 7 (halo)" \
            "95 Pad 8 (sweep)" }

set m(13) { " 96 FX 1 (rain)" " 97 (soundtrack)" " 98 FX 3 (crystal)" \
            " 99 FX 4 (atmosphere)" "100 FX 5 (brightness)" "101 FX 6 (goblins)" \
            "102 FX 7 (echoes)" "103 FX 8 (sci-fi)" }

set m(14) { "104 Sitar" "105 Banjo" "106 Shamisen" "107 Koto" "108 Kalimba" \
            "109 Bagpipe" "110 Fiddle" "111 Shanai"}

set m(15) { "112 Tinkle Bell" "113 Agogo" "114 Steel Drums" "115 Woodblock" \
            "116 Taiko Drum" "117 Melodic Tom" "118 Synth Drum" "119 Reverse Cymbal" }

set m(16) { "120 Guitar Fret Noise" "121 Breath Noise" "122 Seashore" \
            "123 Bird Tweet" "124 Telephone ring" "125 Helicopter" "126 Applause" "127 Gunshot" }

proc make_octave_menubutton {widget widgetcmd} {
    global df
    set ww $widget.menu
    menubutton $widget -menu $ww -text 0 -relief raised -font $df -width 2
    menu $ww -tearoff 0
    $ww add command -label -2 -command "$widgetcmd  $widget -2" -font $df
    $ww add command -label -1 -command "$widgetcmd  $widget -1" -font $df
    $ww add command -label  0 -command  "$widgetcmd  $widget 0" -font $df
    $ww add command -label  1 -command  "$widgetcmd  $widget 1" -font $df
    $ww add command -label  2 -command  "$widgetcmd  $widget 2" -font $df
}

proc label_octave {octave val} {
    global midi
    set midi($octave) $val
    return $val
}


proc midi1_msg {msg} {
    global exec_out
    set exec_out $exec_out\n$msg
    .abc.midi1.msg.txt configure -text $msg -foreground red
}


frame $w.msg
label $w.msg.txt -foreground red -text ""
pack $w.msg.txt

frame $w.melody

label $w.melody.label -text melody -font $df -width 10
scale $w.melody.vol -from 0 -to 127 -length 100  \
        -width 10 -orient horizontal -command setabclev\
        -variable midi(melvol)  -font $df
tooltip::tooltip $w.melody.vol "loudness level of\nmelody line"

set i1 [expr int(1 + $midi(program)/8)]
set i2 [expr $midi(program)  % 8 ]
button $w.melody.melodybut -text [lindex $m($i1) $i2]  -font $df -width 20

proc update_octave {widget val} {
    $widget configure -text [label_octave octave $val]}

make_octave_menubutton $w.melody.octave update_octave
tooltip::tooltip $w.melody.octave "octave shift for melody"

pack $w.melody.label $w.melody.vol $w.melody.melodybut $w.melody.octave -side left


proc update_double_octave {widget val} {
    $widget configure -text [label_octave octave2 $val]}

set i1 [expr int(1 + $midi(program2)/8)]
set i2 [expr $midi(program2)  % 8 ]
frame $w.double
checkbutton $w.double.but -text double -font $df -width 8 -variable midi(double)
tooltip::tooltip $w.double.but "also play melody line
on a separate instrument"
scale $w.double.vol -from 0 -to 127 -length 100  \
        -width 10 -orient horizontal -command setdoublelev\
        -variable midi(doublevol)  -font $df
tooltip::tooltip $w.double.vol "loudness level of\ndoubled melody"
button $w.double.doublebut -text [lindex $m($i1) $i2]  -font $df -width 20
make_octave_menubutton $w.double.octave update_double_octave
tooltip::tooltip $w.double.octave "octave shift for\ndoubled instrument"
pack $w.double.but $w.double.vol $w.double.doublebut $w.double.octave -side left

proc update_bass_octave {widget val} {
    $widget configure -text [label_octave bass_octave $val]}

set i1 [expr int(1 + $midi(bassprog)/8)]
set i2 [expr $midi(bassprog)  % 8 ]
frame $w.bass
label $w.bass.basslab -text "bass"  -font $df -width 10
scale $w.bass.basscal -from 0 -to 127 -length 100 -width 10 \
        -orient horizontal -showvalue true -variable midi(bassvol)  -font $df
tooltip::tooltip $w.bass.basscal "loudness level of\n chordal accompaniment"
button $w.bass.bassbut -text [lindex $m($i1) $i2]  -font $df -width 20
make_octave_menubutton $w.bass.octave update_bass_octave
tooltip::tooltip $w.bass.octave "octave shift for\nbass accompaniment"
pack $w.bass.basslab $w.bass.basscal $w.bass.bassbut $w.bass.octave -side left


proc update_chord_octave {widget val} {
    $widget configure -text [label_octave chord_octave $val]}

set i1 [expr int(1 + $midi(chordprog)/8)]
set i2 [expr $midi(chordprog) % 8 ]
frame $w.chord
label $w.chord.chordlab -text "chord" -font  $df -width 10
scale $w.chord.chordscal -from 0 -to 127 -length 100  -width 10\
        -orient horizontal -showvalue true -variable midi(chordvol)  -font $df
tooltip::tooltip $w.chord.chordscal "loudness level of\nchordal accompaniment"
button $w.chord.chordbut -text [lindex $m($i1) $i2]  -font $df -width 20
make_octave_menubutton $w.chord.octave update_chord_octave
tooltip::tooltip $w.chord.octave "octave shift for\nchordal accompaniment"

pack $w.chord.chordlab $w.chord.chordscal $w.chord.chordbut $w.chord.octave -side left

update_octave $w.melody.octave $midi(octave)
update_double_octave $w.double.octave $midi(octave2)
update_chord_octave $w.chord.octave $midi(chord_octave)
update_bass_octave $w.bass.octave $midi(bass_octave)



frame $w.drum
label $w.drum.lab -text "drum output" -font $df
radiobutton $w.drum.off -text off -font $df -value 0 -variable midi(drumvar) -command {drumradio 0}
radiobutton $w.drum.auto -text auto -font $df -value 1 -variable midi(drumvar) -command {drumradio 1}
radiobutton $w.drum.custom -text custom -font $df -value 2 -variable midi(drumvar) -command {drumradio 2}


set d2_4 {dd dzdz dzzzdzzz dzdzdzdz dzzzzzzd}
set d3_4 {ddd dzdzdz z2dzdz d2z4}
set d6_8 {d3ddd dddd3 d2dd3 d3d2d}
set d7_8 {d3d2d2 d2d2d3}
set d4_4 {dddd dzdzdzdz d4d2d2}
set d9_8 {ddd d3d2d2d2 d2d3d2d2 d2d2d3d2}

menubutton $w.drum.menu -text drumpattern -relief raised\
        -menu $w.drum.menu.type -font $df
menu $w.drum.menu.type -tearoff 0
set w $w.drum.menu
$w.type add cascade  -label "2/4" -menu $w.type.1 -font $df
$w.type add cascade  -label "3/4" -menu $w.type.2 -font $df
$w.type add cascade  -label "6/8" -menu $w.type.3 -font $df
$w.type add cascade  -label "7/8" -menu $w.type.4 -font $df
$w.type add cascade  -label "4/4" -menu $w.type.5 -font $df
$w.type add cascade  -label "9/8" -menu $w.type.6 -font $df

menu $w.type.1 -tearoff 0
foreach code $d2_4 {
    $w.type.1 add radiobutton -label $code\
            -font $df -command "drumpattern_select $code"
}

menu $w.type.2 -tearoff 0
foreach code $d3_4 {
    $w.type.2 add radiobutton -label $code\
            -font $df -command "drumpattern_select $code"
}

menu $w.type.3 -tearoff 0
foreach code $d6_8 {
    $w.type.3 add radiobutton -label $code\
            -font $df -command "drumpattern_select $code"
}

menu $w.type.4 -tearoff 0
foreach code $d7_8 {
    $w.type.4 add radiobutton -label $code\
            -font $df -command "drumpattern_select $code"
}

menu $w.type.5 -tearoff 0
foreach code $d4_4 {
    $w.type.5 add radiobutton -label $code\
            -font $df -command "drumpattern_select $code"
}

menu $w.type.6 -tearoff 0
foreach code $d9_8 {
    $w.type.6 add radiobutton -label $code\
            -font $df -command "drumpattern_select $code"
}

set w .abc.midi1
pack $w.drum.lab $w.drum.off $w.drum.auto $w.drum.custom $w.drum.menu  -side left

frame $w.drumpat
label $w.drumpat.pat -text [string range $midi(drumpat) 0 40] -font $df
button $w.drumpat.cfg -text drumkit -font $df -command drum_editor

pack $w.drumpat.pat $w.drumpat.cfg -side left

proc drumradio {cmdval} {
    global midi
    switch $cmdval {
        0 {set midi(drumon) 0
            .abc.midi1.drum.menu configure -state disable
            .abc.midi1.drumpat.cfg configure -state disable}
        1 {set midi(drumon) 1
            set midi(mydrum) 0
            .abc.midi1.drum.menu configure -state disable
            .abc.midi1.drumpat.cfg configure -state disable}
        2 {set midi(drumon) 1
            set midi(mydrum) 1
            .abc.midi1.drum.menu configure -state normal
            .abc.midi1.drumpat.cfg configure -state normal}
    }
}

drumradio $midi(drumvar)

proc  drumpattern_select {code} {
    global midi df
    set midi(drumpat) [create_random_drum_command  $code]
    .abc.midi1.drumpat.pat configure -text [patlabel]
}

proc patlabel {} {
    global midi
    set l [string length $midi(drumpat)]
    if {$l > 25} {set s [string range $midi(drumpat) 0 25]...} else {
        set s $midi(drumpat)}
    return $s
}

proc random_drum {} {
    global midi
    set n [llength $midi(selected_drums)]
    set m [expr int(rand()*$n)]
    return [lindex $midi(selected_drums) $m]
}

proc parse_drum_string {input} {
    set charlist [split $input ""]
    set result {}
    set item ""
    foreach letter $charlist {
        switch -regexp $letter {
            d {
                set result [concat $result $item]
                set item d}
            z {
                set result [concat $result $item]
                set item z}
            [0-9]
            {set item [append item $letter]}
        }
    }
    set result [concat $result $item]
}

proc create_random_drum_command {code} {
    global midi drumvel
    set drumlist [parse_drum_string $code]
    set drumcmd  $code
    set i 0
    foreach elem $drumlist {
        set initialchar [string index $elem 0]
        if {$initialchar != "d"} continue
        set n [expr [random_drum] + 35]
        set drumcmd "$drumcmd $n"
        set drumvel($i) dmedium
        incr i
    }
    set drumcmd [append_drum_velocities $drumcmd]
    set midi(drumpat) $drumcmd
    if {[winfo exist .drumkit]} {prepare_drumentry $drumcmd}
    return $drumcmd
}

proc append_drum_velocities {drumcmd} {
    global drumvel midi
    set drumcmd "$drumcmd "
    #puts $drumcmd
    set drumproglist [lrange $drumcmd 1 end]
    set i 0
    foreach elem $drumproglist {
        set n $midi($drumvel($i))
        set drumcmd "$drumcmd $n"
    }
    #puts $drumcmd
    return $drumcmd
}


frame $w.gchord
label $w.gchord.lab -text "custom gchord string" -font $df
checkbutton $w.gchord.mychordchk -text "my gchord" -variable midi(bmychord) -font $df -command mygchordcmd
label $w.gchord.sample -text "" -font $df
tooltip::tooltip $w.gchord.mychordchk "overrides abc2midi defaults"

proc mygchordcmd {} {
    global midi
    if {![winfo exist .abc.midi1.gchord.gchord]} return
    if $midi(bmychord) {
        .abc.midi1.gchord.gchord configure -state normal} else {
        .abc.midi1.gchord.gchord configure -state disable}
    .abc.midi1.gchord.sample configure -text ""
}


set c2_4 {f2z2 fzfz f2f2 c2c2 gi gI gihi}
set c3_4 {f2z4 f2f2f2 c2c2c2 ghihgh}
set c6_8 {f3z3 f3f3 c3c3 ghihgh hg}
set c7_8 {f2z5 f2f2c3 f2f2f3 f3c2c2 f3f2f2}
set c4_4 {f4f4 c4c4 gi gI ghhi ghih gHIH}
set c9_8 {f2z6 f3f3f3 c3c3c3}
set c3_2 {f4c4c4 f4f4f4 f2z2c2z2c2z2 c4c4c4}

set w .abc.midi1.gchord.gchord
menubutton $w -text gchord -menu $w.type -relief raised -font $df -state disable
menu $w.type -tearoff 0
$w.type add cascade  -label "2/4" -menu $w.type.1 -font $df
$w.type add cascade  -label "3/4" -menu $w.type.2 -font $df
$w.type add cascade  -label "6/8" -menu $w.type.3 -font $df
$w.type add cascade  -label "7/8" -menu $w.type.4 -font $df
$w.type add cascade  -label "4/4" -menu $w.type.5 -font $df
$w.type add cascade  -label "9/8" -menu $w.type.6 -font $df
$w.type add cascade  -label "3/2" -menu $w.type.7 -font $df

set w .abc.midi1.gchord.gchord.type

menu $w.1 -tearoff 0
set i 0
foreach inst $c2_4 {
    $w.1 add radiobutton -label $inst -command "gchord_select 1 $i" -font $df
    incr i
}

menu $w.2 -tearoff 0
set i 0
foreach inst $c3_4 {
    $w.2 add radiobutton -label $inst -command "gchord_select 2 $i" -font $df
    incr i
}

menu $w.3 -tearoff 0
set i 0
foreach inst $c6_8 {
    $w.3 add radiobutton -label $inst -command "gchord_select 3 $i" -font $df
    incr i
}

menu $w.4 -tearoff 0
set i 0
foreach inst $c7_8 {
    $w.4 add radiobutton -label $inst -command "gchord_select 4 $i" -font $df
    incr i
}

menu $w.5 -tearoff 0
set i 0
foreach inst $c4_4 {
    $w.5 add radiobutton -label $inst -command "gchord_select 5 $i" -font $df
    incr i
}

menu $w.6 -tearoff 0
set i 0
foreach inst $c9_8 {
    $w.6 add radiobutton -label $inst -command "gchord_select 6 $i" -font $df
    incr i
}

menu $w.7 -tearoff 0
set i 0
foreach inst $c3_2 {
    $w.7 add radiobutton -label $inst -command "gchord_select 7 $i" -font $df
    incr i
}

array set gchordtranslate {f C,, c \[C,E,G,\] g C, h E, i G, j B, G C,, H E,, I G,, J B,}

proc gchord_select {p1 p2} {
    global midi df
    global gchordtranslate
    
    set name [.abc.midi1.gchord.gchord.type.$p1 entrycget $p2 -label]
    .abc.midi1.gchord.gchord configure -text $name  -font $df
    set midi(mychord) $name
    set nametrans ""
    for {set i 0} {$i < [string length $name]} {incr i} {
        set c [string index $name $i]
        if {[info exist gchordtranslate($c)]} {set n $gchordtranslate($c)
        } else {set n $c}
        append nametrans $n
    }
    set s "\"C\" = $nametrans"
    .abc.midi1.gchord.sample configure -text $s
}

proc setabclev {vol} {
    global midi
    set midi(beat_a) $vol
    set midi(beat_b) [expr $vol -$midi(beat_offset)]
    set midi(beat_c) [expr $vol -2*$midi(beat_offset)]
    if {$midi(beat_b) < 0} {set midi(beat_b) 0}
    if {$midi(beat_c) < 0} {set midi(beat_c) 0}
}

proc setdoublelev {vol} {
    global midi
    set midi(beat2_a) $vol
    set midi(beat2_b) [expr $vol -$midi(beat_offset)]
    set midi(beat2_c) [expr $vol -2*$midi(beat_offset)]
    if {$midi(beat2_b) < 0} {set midi(beat_b) 0}
    if {$midi(beat2_c) < 0} {set midi(beat_c) 0}
}

grid .abc.midi1.gchord.lab .abc.midi1.gchord.mychordchk .abc.midi1.gchord.gchord .abc.midi1.gchord.sample -sticky w


# advanced midi features
set w .abc.midi1.beat
frame $w
label $w.lab1 -text "on beat" -font $df
label $w.lab2 -text "off beat" -font $df
label $w.lab3 -text "other" -font $df
entry $w.a -width 4 -textvariable midi(beat_a) -font $df
entry $w.b -width 4 -textvariable midi(beat_b) -font $df
entry $w.c -width 4 -textvariable midi(beat_c) -font $df
pack  $w.lab1 $w.a $w.lab2  $w.b $w.lab3 $w.c -side left
bind .abc.midi1.beat.a   <Return> {focus .abc.midi1.beat.lab1}
bind .abc.midi1.beat.b   <Return> {focus .abc.midi1.beat.lab1}
bind .abc.midi1.beat.c   <Return> {focus .abc.midi1.beat.lab1}

set w .abc.midi1.grace
frame $w
label $w.grace -text "grace divider" -font $df
entry $w.graceval -width 2 -font $df -textvariable midi(gracedivider)
pack  $w.grace $w.graceval -side left
bind .abc.midi1.grace.graceval   <Return> {focus .abc.midi1.grace.grace}

set w .abc.midi1.broken
frame $w
label $w.lab2 -text "broken rhythm ratio" -font $df
entry $w.ent1 -width 1 -font $df -textvariable midi(ratio_n)
entry $w.ent2 -width 1 -font $df -textvariable midi(ratio_m)
pack  $w.lab2 $w.ent1 $w.ent2 -side left
bind .abc.midi1.broken.ent1   <Return> {focus .abc.midi1.grace.grace}
bind .abc.midi1.broken.ent2   <Return> {focus .abc.midi1.grace.grace}

set w .abc.midi1.barfly
frame $w
checkbutton $w.but -text "BarFly mode" -variable midi(barflymode) -font $df
radiobutton $w.rad1 -text "1" -variable midi(stressmodel) -font $df \
        -value 1
radiobutton $w.rad2 -text "2" -variable midi(stressmodel) -font $df \
        -value 2
label $w.lab -text "Stress Model" -font $df
pack $w.but $w.lab $w.rad1 $w.rad2 -side left


set w .abc.midi1.drummethod
frame $w
checkbutton $w.but -text "use drummap" -variable midi(drummap) -font $df
pack $w.but

set w .abc.midi1.divider
frame $w
label $w.lab1 -text "beat divider" -font $df
entry $w.n -width 3 -textvariable midi(beat_n) -font $df
pack $w.lab1 $w.n -side left -anchor w
bind .abc.midi1.divider.n   <Return> {focus .abc.midi1.divider.lab1}


set w .abc.midi1.reset
frame $w
button $w.default -text "reset default settings" -font $df -command reset_advanced_midi
pack  $w.default -side left -anchor w

set w .abc.midi1.drone
frame $w
checkbutton $w.drone -text "bagpipe drone on" -variable midi(drone) -font $df
pack $w.drone -side left -anchor w
scale $w.tenordrone -from 0 -to 127 -length 128  \
        -width 10 -orient horizontal  -showvalue true \
        -variable midi(tenordrone)   -font $df
scale $w.bassdrone -from 0 -to 127 -length 128  \
        -width 10 -orient horizontal  -showvalue true \
        -variable midi(bassdrone)   -font $df
tooltip::tooltip $w.bassdrone "bass level"
tooltip::tooltip $w.tenordrone "tenor level"
pack $w.tenordrone $w.bassdrone -side left -anchor w


proc enable_disable_drone {status} {
    if {$status} {
        .abc.midi1.drone.drone configure -state normal
        .abc.midi1.drone.bassdrone configure -state normal
        .abc.midi1.drone.tenordrone configure -state normal
    } else {
        .abc.midi1.drone.drone configure -state disabled
        .abc.midi1.drone.bassdrone configure -state disabled
        .abc.midi1.drone.tenordrone configure -state disabled
    }
}

proc reset_advanced_midi {} {
    global midi
    set midi(beat_a) 105
    set midi(beat_b) 95
    set midi(beat_c) 80
    set midi(beat_n) 4
    set midi(gracedivider) 4
    set midi(ratio_n) 2
    set midi(ratio_m) 1
}

# voice Property Sheet

frame .abc.voice
canvas .abc.voice.canvas -width 80 -height 20 \
        -yscrollcommand [list .abc.voice.yscroll set]
scrollbar .abc.voice.yscroll -orient vertical \
        -command [list .abc.voice.canvas yview]
pack  .abc.voice.yscroll -side right -fill y
pack  .abc.voice.canvas -side left -fill both -expand true

set w [frame .abc.voice.canvas.f -bd 0]
.abc.voice.canvas create window 0 0 -anchor nw -window $w

label $w.head0 -text V: -font $df
label $w.head1 -text program -font $df
label $w.head2 -text level -font $df
label $w.head3 -text pan -font $df

for {set i 1} {$i <17} {incr i} {
    label $w.lab$i -text $i -font $df
    set i1 [expr int(1 + $midi(voice$i)/8)]
    set i2 [expr $midi(voice$i) % 8 ]
    button $w.prog$i -text [lindex $m($i1) $i2]  -font $df -width 15 -pady 1
    eval {bind $w.prog$i <Button> [list voice_button $i %X %Y]}
    scale $w.pan$i -from 0 -to 127 -length 64  \
            -width 8 -orient horizontal  -showvalue true \
            -variable midi(pvoice$i) -font $df
    scale $w.vol$i -from 0 -to 127 -length 64  \
            -width 8 -orient horizontal  -showvalue true \
            -variable midi(lvoice$i) -font $df
}

proc voice_button {num X Y} {
    global window chan
    set window .abc.voice.canvas.f.prog$num
    set chan voice$num
    program_popup $X $Y}

grid   $w.head0 $w.head1 $w.head2 $w.head3
for {set i 1} {$i < 17} {incr i} {
    grid   $w.lab$i  $w.prog$i  $w.vol$i  $w.pan$i -sticky w
}


proc program_popup {rootx rooty} {
    global m df
    
    if {![winfo exists .patchmap]} {
        set instrum_family {piano "chrom percussion" organ guitar bass \
                    strings ensemble brass reed pipe "synth lead" "synth pad" \
                    "synth effects" ethnic percussive "sound effects"}
        set w .patchmap
        menu $w -tearoff 0
        set i 1
        foreach class $instrum_family {
            $w add cascade  -label $class -menu $w.$i -font $df
            set w2 .patchmap.$i
            menu $w2 -tearoff 0
            set j 0
            foreach inst $m($i) {
                $w2 add radiobutton -label $inst \
                        -command "program_select  $i $j " -font $df
                incr j
            }
            incr i
        }
    }
    tk_popup .patchmap $rootx $rooty
}

proc program_select {p1 p2} {
    global midi chan window m
    
    #  puts "program_select $p1 $p2"
    set midi($chan) [expr ($p1-1)*8 + $p2]
    #  set name [.patchmap.$p1 entrycget $p2 -label]
    set name [lindex $m($p1) $p2]
    $window configure -text $name
}


bind .abc.midi1.melody.melodybut <Button> {set window .abc.midi1.melody.melodybut
    set chan program
    program_popup %X %Y}
bind .abc.midi1.chord.chordbut <Button> {set window .abc.midi1.chord.chordbut
    set chan chordprog
    program_popup %X %Y}
bind .abc.midi1.bass.bassbut <Button> {set window .abc.midi1.bass.bassbut
    set chan bassprog
    program_popup %X %Y}
bind .abc.midi1.double.doublebut <Button> {set window .abc.midi1.double.doublebut
    set chan program2
    program_popup %X %Y}


# abc2abc property page
set abc2abc_e 1
set w .abc.abc2abc
set abc2abc_useflats 0
frame $w
frame $w.1
checkbutton $w.1.1 -text "new spacing" -variable abc2abc_s  -font $df
checkbutton $w.1.2 -text "no error report" -variable abc2abc_e -font $df
pack $w.1.1 $w.1.2 -anchor w -side left
checkbutton $w.2 -text "use [] () for chords and slurs" -font $df -variable abc2abc_u
checkbutton $w.3 -text "double note length" -font $df -variable abc2abc_d
checkbutton $w.4 -text "halve note length" -font $df -variable abc2abc_v
frame $w.40
checkbutton $w.40.1 -text "force key to" -font $df -variable abc2abc_nk
menubutton $w.40.2 -menu $w.40.2.type -text none -font $df -relief raised
set p $w.40.2
menu $p.type -tearoff 0
$p.type add command -label Db -font $df -command "forcekeymenu -5"
$p.type add command -label Ab -font $df -command "forcekeymenu -4"
$p.type add command -label Eb -font $df -command "forcekeymenu -3"
$p.type add command -label Bb -font $df -command "forcekeymenu -2"
$p.type add command -label F -font $df -command "forcekeymenu -1"
$p.type add command -label none -font $df -command "forcekeymenu 0"
$p.type add command -label G -font $df -command "forcekeymenu 1"
$p.type add command -label D -font $df -command "forcekeymenu 2"
$p.type add command -label A -font $df -command "forcekeymenu 3"
$p.type add command -label E -font $df -command "forcekeymenu 4"
$p.type add command -label B -font $df -command "forcekeymenu 5"

set abc2abc_usekey 0
global abc2abc_usekey

radiobutton $w.40.3 -text "use sharps" -variable abc2abc_useflats \
        -relief flat -value 0 -font $df
radiobutton $w.40.4 -text "use flats" -variable abc2abc_useflats \
        -relief flat -value 1 -font $df
pack $w.40.1 $w.40.2 $w.40.3 $w.40.4 -side left
frame $w.5
checkbutton $w.5.1 -text "transpose" -font $df -variable abc2abc_t
entry $w.5.2 -width 3 -textvariable abc2abc_t_val -font $df
bind $w.5.2 <Return> {focus .abc.abc2abc.5}
label $w.5.3 -text semitones -font $df
pack $w.5.1 $w.5.2 $w.5.3 -side left
frame $w.6
checkbutton $w.6.1 -text "linebreaks every " -font $df -variable abc2abc_n
entry $w.6.2 -width 2 -textvariable abc2abc_n_val
label $w.6.3 -text "bars" -font $df
pack $w.6.1 $w.6.2 $w.6.3 -side left
frame $w.7
checkbutton $w.7.1 -text "extract only voice " -font $df -variable abc2abc_V
entry $w.7.2 -width 2 -textvariable abc2abc_V_val -font $df
pack $w.7.1 $w.7.2 -side left
frame $w.11
checkbutton $w.11.1 -text "apply to only voice " -font $df -variable abc2abc_P
entry $w.11.2 -width 2 -textvariable abc2abc_P_val -font $df
pack $w.11.1 $w.11.2 -side left
frame $w.8
radiobutton $w.8.0 -text "output to clipboard"  -variable midi(no_clipboard) \
        -relief flat -value 0  -font $df
radiobutton $w.8.1 -text "output to editor"     -variable midi(no_clipboard) \
        -relief flat -value 1  -font $df
pack $w.8.0 $w.8.1 -side left
frame $w.9
button $w.9.1 -text "abc2abc" -font $df -command run_abc2abc
button $w.9.2 -text "help" -font $df -command contexthelp
pack $w.9.1 $w.9.2 -side left
label $w.10 -text "" -font $df
pack $w.1 $w.2 $w.3 $w.4 $w.40 $w.5 $w.6 $w.7 $w.11 $w.8 $w.9 $w.10 -side top -anchor w

proc forcekeymenu {fsf} {
    #fsf force sharps/flats
    global abc2abc_usekey
    set key [lindex {Db Ab Eb Bb F none G D A E B} [expr $fsf+5]]
    .abc.abc2abc.40.2 configure -text $key
    set abc2abc_usekey $fsf
    if {$fsf == 0} {
        .abc.abc2abc.40.3 configure -state normal
        .abc.abc2abc.40.4 configure -state normal
    } else {
        .abc.abc2abc.40.3 configure -state disabled
        .abc.abc2abc.40.4 configure -state disabled
    }
}



# Config property page

set fontfamily [lsort [font families]]

set w .abc.cfg
frame $w
for {set i 1} {$i <= 29} {incr i} {
    frame $w.$i
}
button $w.1.0 -text abc2ps -width 14 -command {setpath path_abc2ps}  -font $df
entry $w.1.1 -width 30 -relief sunken -textvariable midi(path_abc2ps) -font $df
pack $w.1.0 $w.1.1  -side left
bind .abc.cfg.1.1 <Return> {focus .abc.cfg.1}

button $w.20.0 -text abcm2ps -width 14 -command {setpath path_abcm2ps}  -font $df
entry $w.20.1 -width 30 -relief sunken -textvariable midi(path_abcm2ps) -font $df
pack $w.20.0 $w.20.1  -side left
bind .abc.cfg.20.1 <Return> {focus .abc.cfg.20}

button $w.21.0 -text abc2abc -width 14 -command {setpath path_abc2abc}  -font $df
entry $w.21.1 -width 30 -relief sunken -textvariable midi(path_abc2abc) -font $df
pack $w.21.0 $w.21.1  -side left
bind .abc.cfg.21.1 <Return> {focus .abc.cfg.21}

button $w.24.0 -text midi2abc -width 14 -command {setpath path_midi2abc} -font $df
entry $w.24.1 -width 30 -relief sunken -textvariable midi(path_midi2abc) -font $df
pack $w.24.0 $w.24.1 -side left
bind .abc.cfg.24.1 <Return> {focus .abc.cfg.24}

button $w.25.0 -text midicopy -width 14 -command {setpath path_midicopy} -font $df
entry $w.25.1 -width 30 -relief sunken -textvariable midi(path_midicopy) -font $df
pack $w.25.0 $w.25.1 -side left
bind .abc.cfg.25.1 <Return> {focus .abc.cfg.25}

button $w.26.0 -text "abcmidi folder" -width 14 -command {locate_abcmidi_executables} -font $df
entry $w.26.1 -width 30 -relief sunken -textvariable midi(dir_abcmidi) -font $df
pack $w.26.0 $w.26.1 -side left
bind .abc.cfg.26.1 <Return> {focus .abc.cfg.26}


button $w.22.0 -text abcmatch -width 14 -command {setpath path_abcmatch}  -font $df
entry $w.22.1 -width 30 -relief sunken -textvariable midi(path_abcmatch) -font $df
pack $w.22.0 $w.22.1  -side left
bind .abc.cfg.22.1 <Return> {focus .abc.cfg.22}

button $w.2.0 -text yaps -width 14  -command {setpath path_yaps} -font $df
entry $w.2.1 -width 30 -relief sunken -textvariable midi(path_yaps) -font $df
pack $w.2.0 $w.2.1  -side left
bind .abc.cfg.2.1 <Return> {focus .abc.cfg.22}

button $w.3.0 -text abc2midi -width 14  -command {setpath path_abc2midi} -font $df
entry $w.3.1 -width 30 -relief sunken -textvariable midi(path_abc2midi) -font $df
pack $w.3.0 $w.3.1  -side left
bind .abc.cfg.3.1 <Return> {focus .abc.cfg.3}

button $w.4.0 -text ghostview -width 14  -command {setpath path_gs} -font $df
entry $w.4.1 -width 30 -relief sunken -textvariable midi(path_gs) -font $df
pack $w.4.0 $w.4.1  -side left
bind .abc.cfg.4.1 <Return> {focus .abc.cfg.4}

button $w.5.0 -text "midiplayer 1" -width 14  -command {setpath path_midiplay} -font $df
entry $w.5.1 -width 36 -relief sunken -textvariable midi(path_midiplay) -font $df
pack $w.5.0 $w.5.1  -side left
bind .abc.cfg.5.1 <Return> {focus .abc.cfg.5}

button $w.6.0 -text "player 1 opts" -width 14 -command {}  -font $df
entry $w.6.1 -width 36 -relief sunken -textvariable midi(midiplay_options) -font $df
pack $w.6.0 $w.6.1  -side left
bind .abc.cfg.6.1 <Return> {focus .abc.cfg.6}

button $w.7.0 -text "midiplayer 2" -width 14 -command {setpath alt_path_midiplay} -font $df
entry $w.7.1 -width 36 -relief sunken -textvariable midi(alt_path_midiplay) -font $df
pack $w.7.0 $w.7.1  -side left
bind .abc.cfg.7.1 <Return> {focus .abc.cfg.7}

button $w.8.0 -text "player 2 options" -width 14 -command {} -font $df
entry $w.8.1 -width 36 -relief sunken -textvariable midi(alt_midi_options) -font $df
pack $w.8.0 $w.8.1  -side left
bind .abc.cfg.8.1 <Return> {focus .abc.cfg.8}

label $w.9.0 -text "gui font" -width 10  -font $df
entry $w.9.1 -width 24 -relief sunken -textvariable midi(font_family) -font $df
pack $w.9.0 $w.9.1 -side left
bind $w.9.1 <Return> {
    change_font 0
    focus .abc.cfg.9.0}

button $w.10.0 -text editor -width 14  -command {setpath path_editor} -font $df
entry $w.10.1 -width 30 -relief sunken -textvariable midi(path_editor) -font $df
pack $w.10.0 $w.10.1  -side left
bind .abc.cfg.10.1 <Return> {focus .abc.cfg.10}

label $w.23.0 -text "work folder" -width 16 -padx 2  -font $df
entry $w.23.1 -width 30 -relief sunken -textvariable midi(abc_work_folder) -font $df
pack $w.23.0 $w.23.1  -side left
bind .abc.cfg.23.1 <Return> {focus .abc.cfg.23}

button $w.29.0 -text "internet browser" -width 14  -font $df -command {setpath path_internet}
entry $w.29.1 -width 30 -relief sunken -textvariable midi(path_internet) -font $df
pack $w.29.0 $w.29.1 -side left
bind .abc.cfg.29.1 <Return> {focus .abc.cfg.29}

#frame $w.11 not used


label $w.13.lab -text "transfer protocol 1" -font $df
radiobutton $w.13.b0 -text "one file"  -variable midi(transfer_prot_1) \
        -relief flat -value 0  -font $df
radiobutton $w.13.b1 -text "file list"  -variable midi(transfer_prot_1) \
        -relief flat -value 1  -font $df
radiobutton $w.13.b2 -text "folder"  -variable midi(transfer_prot_1) \
        -relief flat -value 2  -font $df
pack $w.13.lab $w.13.b0 $w.13.b1 $w.13.b2 -side left

label $w.14.lab -text "transfer protocol 2" -font $df
radiobutton $w.14.b0 -text "one file"  -variable midi(transfer_prot_2) \
        -relief flat -value 0  -font $df
radiobutton $w.14.b1 -text "file list"  -variable midi(transfer_prot_2) \
        -relief flat -value 1  -font $df
radiobutton $w.14.b2 -text "folder"  -variable midi(transfer_prot_2) \
        -relief flat -value 2  -font $df
pack $w.14.lab $w.14.b0 $w.14.b1 $w.14.b2 -side left

label $w.15.lab -text size -font $df
radiobutton $w.15.b0 -text 7  -variable midi(font_size) \
        -relief flat -value 7  -command {change_font 0} -font $df
radiobutton $w.15.b1 -text 8  -variable midi(font_size) \
        -relief flat -value 8  -command {change_font 0} -font $df
radiobutton $w.15.b2 -text 9  -variable midi(font_size) \
        -relief flat -value 9  -command {change_font 0} -font $df
radiobutton $w.15.b3 -text 10  -variable midi(font_size) \
        -relief flat -value 10  -command {change_font 0} -font $df
radiobutton $w.15.b4 -text 11  -variable midi(font_size) \
        -relief flat -value 11  -command {change_font 0} -font $df
radiobutton $w.15.b5 -text 12  -variable midi(font_size) \
        -relief flat -value 12  -command {change_font 0} -font $df
radiobutton $w.15.b6 -text 13  -variable midi(font_size) \
        -relief flat -value 13  -command {change_font 0} -font $df
radiobutton $w.15.b7 -text 14  -variable midi(font_size) \
        -relief flat -value 14  -command {change_font 0} -font $df
radiobutton $w.15.b8 -text 18  -variable midi(font_size) \
        -relief flat -value 18  -command {change_font 0} -font $df
pack $w.15.lab $w.15.b0 $w.15.b1 $w.15.b2 $w.15.b3 $w.15.b4 $w.15.b5 $w.15.b6 $w.15.b7 $w.15.b8 -side left

label $w.16.lab -text weight -font $df
radiobutton $w.16.b1 -text normal -font $df -variable midi(font_weight) -value normal -command {change_font 0}
radiobutton $w.16.b2 -text bold   -font $df -variable midi(font_weight) -value bold   -command {change_font 0}
pack $w.16.lab $w.16.b1 $w.16.b2 -side left

button $w.17.1 -text apply -command {change_font 1} -font $df
button $w.17.2 -text reset -font $dfreset -command reset_font
label $w.27.1 -text abcdeABCDE -font $sf
pack $w.27.1 -side left

set samplefont $midi(font_family)
ttk::combobox $w.17.4 -width 16  -textvariable samplefont\
        -font $df -values $fontfamily

pack $w.17.1 $w.17.2 -side left
pack $w.17.4 -side left

bind $w.17.4 <<ComboboxSelected>> {font configure $sf -family $samplefont}
bind $w.17.4 <Enter> {focus .abc.cfg}

#bind $w.17.4 <<ComboSelected>> { abc.cfg.27.1 configure -font [get .abc.cfg.17.4]}

label $w.18.0 -text "editor font" -width 10  -font $df
entry $w.18.1 -width 24 -relief sunken -textvariable midi(font_family_toc) -font $df
bind $w.18.1 <Return> {
    change_font 0
    focus .abc.cfg.18.0}
pack $w.18.0 $w.18.1 -side left

message $w.19.0 -aspect 300 -font $df
pack $w.19.0


set active_ps_sheet abc2ps
global active_ps_sheet

proc switch_ps_button {} {
    global midi
    global active_ps_sheet
    if {$midi(ps_creator)=="yaps"} {
        pack forget .abc.functions.$active_ps_sheet
        pack .abc.functions.yaps -after .abc.functions.playopt -side left
        set active_ps_sheet yaps
    } elseif {$midi(ps_creator)=="other"} {
        pack forget .abc.functions.$active_ps_sheet
        pack .abc.functions.otherps -after .abc.functions.playopt -side left
        set active_ps_sheet otherps
    } else {
        pack forget .abc.functions.$active_ps_sheet
        pack .abc.functions.abc2ps -after .abc.functions.playopt -side left
        set active_ps_sheet abc2ps
        if {$midi(ps_creator)=="abcm2ps"} {
            .abc.functions.abc2ps config -text abcm2ps
            grid forget .abc.psstyle.maxvlab .abc.psstyle.maxvent
            grid forget .abc.psstyle.maxslab .abc.psstyle.maxsent
            grid forget .abc.psstyle.voices  .abc.psstyle.voicesent
            grid .abc.psstyle.nolyric .abc.psstyle.noslur -sticky w
            if {$midi(ps_fmt_flag) == 0} {
                grid forget .abc.psform.glue .abc.psform.gluemenu}
            grid .abc.psform.other_opts .abc.psform.other_optsent -sticky w
        } else {
            .abc.functions.abc2ps config -text abc2ps
            grid forget .abc.psstyle.nolyric .abc.psstyle.noslur
            grid .abc.psstyle.voices .abc.psstyle.voicesent -sticky w
            grid .abc.psstyle.maxvlab .abc.psstyle.maxvent  -sticky w
            grid .abc.psstyle.maxslab .abc.psstyle.maxsent  -sticky w
            if {$midi(ps_fmt_flag) == 0} {
                grid .abc.psform.glue .abc.psform.gluemenu -sticky w
                grid forget .abc.psform.other_opts .abc.psform.other_optsent}
            bind .abc.psstyle.maxvent    <Return> {focus .abc.psstyle.maxvlab}
            bind .abc.psstyle.maxsent    <Return> {focus .abc.psstyle.maxvlab}
            bind .abc.psstyle.voicesent  <Return> {focus .abc.psstyle.maxvlab}
        }
    }
}



# Part 13.0                  Help texts


set hlp_overview "You are running runabc.tcl version $runabc_version $runabc_date\n\n\
        This is a graphical user interface to abc2ps, yaps, abcmidi, a \
        PostScript file viewer and midi file player and many other executables.\
        If you are running the program for the first time, you need to specify\
        the path name to these executables in the configuration property sheet. \
        Click the config/abc executables button and then the help button for\
        further instructions.\n\n\
        Once you have properly configured the program, use the 'file' \
        button to select the input abc file. This is a button with a picture\
        of a file on the top left corner.) Click the browse menu to\
        to browse through you file structure. Alternatively, you may\
        enter the relative or absolute path name in the adjoining entry\
        box followed with a carriage return to activate. (This works only if\
        a table of contents is already displayed.) For many entry boxes\
        pressing a carriage return will remove the focus (cursor) from\
        that box.\n\n  The abc file may consist of \
        compilation of many tunes. The list of tune titles will be displayed \
        in the listbox below. Select one or tunes and then click one \
        of the buttons described below. To select several tunes, either sweep \
        the mouse cursor over the tunes holding the left button down, or else \
        click on each tune while holding either the shift or control key down.\n\n\
        Quit		Will write the runabc.ini to disk and exit the program.\n\n\
        Play selection	Will run abc2midi on the selected tune and play the resulting \
        midi file.\n\n\
        Display		Will run abc2ps on the selected tune and display the output \
        PostScript file.\n\n\
        Edit/menu	Will allow you to edit the selected tune and save only this tune \
        in a separate  file.\n\n\
        Console		Will display any error messages originating from abc2ps or \
        abc2midi.\n\n\
        The remaining buttons 'TOC', 'Play options', 'Display options' and \
        'Options' will replace the current sheet with a property sheet that allows \
        you to modify how the midi file or postscript file is created. There are \
        separate help pages for each button. Click the button once for the page \
        to appear. Click the same button again to remove that sheet. \
        Clicking a different button will bring up a different property page. \
        There are two possible property pages associated with the 'postscript' \
        button. The appropriate page will displayed depending on whether abc2ps \
        or yaps was selected in the 'config' property page. \
        Click the help button for further instructions when \
        one of these property pages is in view.\n\n

Three scale controls (sliders) in dark red appear below the buttons.\
        The right most scale, is used to vary the tempo (in beats per minute)\
        of the tune to be played. The other scales allow you to play or display\
        a section from the tune given the starting and ending bar numbers.\
        This is useful when you are editing a new tune.\n\n
Other bindings\n\n
The arrow, page up/down, home, end keys allow you to scroll up and\
        down the table of contents. The <cntl>-slash and <cntl>-backslash allow\
        you to select or deselect all titles in the table of contents.\
        The p key  or <space> will play the current selection and the d key will \
        display this selection. The E key will edit the file; the e key will\
        start up TclAbcEditor.\n\n\
        When you right click any tune in the table of contents list box, a short\
        descriptor of the tune will appear in a separate and resizeable window.\
        If you want the entire tune shown then set 'summary_enabled' to 2.\n\n


Seymour.Shlien@crc.ca, 624 Courtenay Ave,  Ottawa, K2A 3B5, Canada, \
        Sept 9 2001."


set hlp_config_1 "Configuration Property Sheet\n\n\This page is\
        used to specify the file path names to the various executables called\
        by this program. It is probably most convenient to put these\
        executables (except for ghostview) in the same folder as runabc.\
        In particular all the executables in the abcmidi package should be in the\
        same folder.  When you start up runabc.tcl for the first time, the\
        entry boxes will \ be configured for my own computer. This is probably\
        not the way things are set up on your own computer but it at least\
        provides you with an example.\n\n\
        For convenience, clicking one of the left buttons on this property \
        sheet will pop up a file browser, which will allow you to find and \
        indicate the location of the desired executable. Once you have located \
        this file, click on 'open' to save this path name in the entry box. The \
        contents of the entry box can also be modified by clicking to the \
        position in the box using the regular keys on your keyboard. The left \
        and right arrow keys will move the entry cursor. Though Tcl/Tk supports \
        long file names it may get confused if the path name includes blanks or \
        the backward slash. If the filename or folder where the executable is \
        found contains embedded spaces, it may be necessary to substitute the \
        DOS filename instead.\n\n\
        The executables in the abcmidi package form the core of the program.\
        You specify the folder where all these executables are found, and\
        runabc will attempt to open these files and determine their version\
        numbers. This will be displayed in a separate window labeled 'summary'.\
        The last column in that display specifies the minimum version number\
        expected in order for the program to run properly. Runabc will also\
        append additional buttons and entries in the options page, in case\
        you need to tune up the pathnames to the individual abcmidi executables.\
        This should really not be necessary. \n\n\
        If runabc is running on Windows (98,ME,NT etc.) you can\
        associate the abc files to runabc through the registry. Click that\
        button and then the help button in the new window for more information.\n\n
If you are going to play your midi files on a midi player you should \
        also go to the config/player 1 configuration page. Go to this page \
        and click the help button for more instructions.\n\n"

set hlp_config_2 "Midi Player\n\n\
        This configuration page is used to specify the path name \
        to the midi player, any required run time options and the protocol for \
        passing the midi files to the midi player. All midi players handle single \
        files.  Others can accommodate a list of midi files, while some will even \
        accept a folder of midi files. The manner of passing the midi file(s) \
        to the player is specified by the protocol. You may use any of the three \
        protocols even if you are only passing one midi file to the player, provided \
        the player supports this method. If you are passing a \
        folder then the folder name should be given in the options entry \
        box and the 'folder' radio button should be selected. It is necessary \
        to do this manually since some midi players require the folder name \
        to be preceded by a flag. Note that in some operating systems there may \
        be a limit in the length of the string containing the list of midi files. \n\n\
        When you click the play button, runabc creates \
        a file called X.tmp containing the selected abc tunes and puts it \
        in a tmp folder in the same folder from which runabc.tcl is \
        invoked. (If  you wish to use a different subdirectory name instead of \
        tmp, you should edit the contents of the midi_dir parameter \
        in the runabc.ini file.)  Prior to running abc2midi, any midi files \
        beginning with the letter X are removed from the tmp directory. Then \
        abc2midi is executed with the file X.tmp and it creates a new set of \
        midi files. These midi files are sent to a designated midi player using one \
        of three protocols. You are allowed to designate up to two possible midi \
        players which have their own option entry box and protocol.\
        The selected midi player is indicated in the midi options page.\n\n\
        A convenient way for viewing the X.tmp file is to click the edit/view X.tmp \
        menu item. Line numbers are added so it is easy to review the error \
        messages from abc2midi."


set hlp_config_3 "Font Selector\n\n\
        This feature allows you to specify the \
        default font, size and weight used by the program. This is a useful \
        feature if your monitor is running in a high resolution and you find the \
        text difficult to read. Increasing the font size will cause Tcl/Tk to \
        automatically readjust the size of all the buttons, entry boxes and \
        other widgets.  There are numerous possible fonts available. If you\
        are running Tcl/Tk version 8.4 a spinbox with the fonts available on\
        your system will appear. Clicking the apply button will make this font\
        the default gui font on your system. Alternatively, you can type the\
        name of the font in the gui font or editor font entry box followed with a <return>.\
        Or else you can enter the font family name in the spinbox entry window\
        and press the apply button.\n\n\
        For other systems you can see the list of available fonts by running\
        your Tcl/Tk interpreter (usually called 'wish') and \
        type 'font families' without the quotes.\n\n If you run into problems and \
        all the controls become unreadable or not usable, you can return to the \
        default font by clearing the family entry box and clicking the apply \
        button or alternatively click the button labeled Reset. In the worst\
        case, edit the runabc.ini file and delete the \
        offending font name associated with the variable font_family. (In \
        other words, leave it blank.)\n\nClicking any radio button causes an \
        immediate action; however if you change the font names in the entry box, \
        it is necessary to click the apply button in order to make the new \
        font immediately effective.\n\nThere is a separate font family assigned \
        to the table of contents (toc). The table of contents (toc) will proper \
        alignment if you use a fixed spacing font (eg Terminal which exists on \
        both Windows and Unix systems) rather than a  variable width spacing.\n\n\
        On Windows system, I prefer the System or Fixedsys font while on Linux \
        I use the fixed font."


set hlp_ps "Abc2ps and Abcm2ps Property Sheet\n\n\
        This property page is used to select the options for the program \
        abc2ps which converts the designated tune in the abc file into a \
        PostScript file and then displays the resulting file. The first three \
        check boxes allow you to indicate whether you want the X: reference \
        numbers, numbered bar numbers and historic notes appearing in the \
        output score. Abc2ps usually uses the layout of the abc file for \
        determining the number of bars in a line; however, if you check the box \
        'ignore line ends', then it will fit in as many bars as possible.\n\
        Normally, abc2ps will display all voices included in the abc file. \
        It is possible to choose a subset of these voices by ticking the 'select \
        voices' check box and indicating in the entry box which voices are \
        desired (eg. 1-2, 5). The next time the 'display' button is clicked \
        only those voices will be presented. Note: abc2ps will complain of an \
        error and refuse to run if the selection box is ticked but there is nothing \
        in the entry box.\n\n\
        For best results, it is recommended that you use a layout file like \
        letter.fmt which is provided with the distribution. This is a text \
        file which can be edited and which allows you to control the font and size of \
        many of the headings. Alternatively, you can try to control the layout \
        using the other options provided by abc2ps which become available when \
        you untick the check box labeled 'use layout file'. The factory \
        settings were chosen for a low resolution screen. See the abc2ps.readme \
        file which comes with the abc2ps distribution for more details. I \
        recommend that you use the 'fill' 'glue' mode, but there may be cases \
        where the other modes may be preferable.\n\n\
        Some of the new abc files, in particular the multivoiced files, may be \
        too large for abc2ps in its standard settings. Since abc2ps must store the \
        entire score in memory, enough dynamic memory needs to be \
        allocated for all the voices and symbols. Abc2ps normally returns a \
        message (which you can view when you press the 'console' button) when it \
        runs out of space. You can increase the amount of dynamic memory \
        allocated using the entry boxes provided.\n\n\
        If you are running abcm2ps, there is an extra entry box where you\
        include any missing run time parameters. For example, you may need\
        to add --pslevel 1 in the entry box labeled other options."

set hlp_yaps "Yaps Property Sheet\n\n
The page sizes, correspond to the choices available in \
        gsview (ghostview). For multivoice abc tunes, you can choose between \
        combining the voices on an array of staves or displaying each voice \
        separately."

set hlp_otherps "Other abc to postscript converters\n\n
There are too many postscript converters for me to support and\
        furthermore new options are introduced every now and then.\
        Fortunately most of the converters are clones of abc2ps and adopt\
        similar parameter conventions.\
        To handle other converters, you need to specify a path to\
        the executable in the top entry  box and the list of options\
        used by the converter. The program no longer uses the xsel variable\
        to pass the selected tunes. Instead all the selected tunes are\
        copied to a file X.tmp in the tmp subdirectory and the entire file\
        X.tmp is processed.\
        Runabc expects the output postscript file to be called Out.ps.\
        Thus if you are using John Chamber's jcabc2ps, the minimal\
        option list would look like:\n
> Out.ps\n
For other converters the output file is specified using the\
        -o parameter. Thus the minimal option list would be\n
-o Out.ps\n\n
If things do not work out the first time, look at the console\
        output to see what is going wrong.\
        I have not tried this out on all converters, so if you are\
        having a problem, send me an e-mail and I will see what I can do."



set hlp_midi1 "Midi tempo/transpose\n\n\
        Many abc have no tempo indications so that by default\
        they are played too slowly. Runabc allows you to change the tempo\
        without forcing you to modify the input abc file. Similarly you can\
        transpose the music up or down by a specific number of semitones.\
        This is applied to all MIDI channels.\n\n\
        If you need to override the tempo indications see the Play Options/\
        arrangement menu item."

set hlp_midi2 "Midi melody bass/chord controls\n\n\
        Abc2midi will provide bass/chordal accompaniment when guitar\
        chords are indicated in the score. By default the accompaniment\
        is played on a piano and the pattern is determined by the time\
        signature. This page allows you to change these defaults.\
        Furthermore, you can play the melody on two different instruments\
        if the double checkbox is checked. This does not apply for tunes\
        which already define the voices with the V: command.\
        To provide more variety you can also transpose by one\
        or more octaves any of these parts.\n\n\
        There is a separate control page for multivoiced abc files.\n\n
The volume level of the melody is controled by 3 numbers\
        which specify the levels of the notes on the on beat, off beat,\
        or neither. These levels should not exceed 127. It is recommended\
        that you use the slider to adjust all three levels unless you\
        know what you are doing. To turn off the melody, set the volume\
        level to 0.\n\n
If you click the random button, a random set of instruments will\
        be chosen for the melody and accompaniment.\n\n

Gchord and drum accompaniment\n\n\
        Abc2midi chooses the chordal accompaniment based on the meter of the \
        piece. (See %%MIDI ghcord in the abcguide.txt for writing abc files for \
        abc2midi.)\n\nIn some cases a different chordal accompaniment\
        may be preferable. To access the other choices, tick the my gchord \
        check box and choose the desired pattern from the gchord menu. The 'f','c' \
        and 'z' indicate bass (fundamental), chords and rest respectively. The \
        number following the letter indicates duration. Do not \
        forget to untick the 'my gchord' check box when you move on to another \
        tune with a different meter.\n\n\
        Unlike guitar chords, drum accompaniment is very rare in notated abc tunes.\
        If you wish to add drum accompaniment, select auto or custom. In\
        auto mode, the program will automatically add an accompaniment which\
        fits the current time signature of the tune. In custom mode, the\
        drumpattern menu button is activated and you can choose your own\
        accompaniment.  You can get finer control by clicking the drumkit button.\
        The drum string in use is shown in the next line. An explanation of\
        the codes is given in the abc2midi guide.\n\n

Midi drone control\n\n\
        This setting applies only to bagpipe music which has an Hp key signature.\
        A drone in the keys of A,, and A,,, are played for music in the key signature\
        HP or Hp. You may specify the loudness (velocity) of the two drones.\
        For your information both HP and Hp imply the A major scale where\
        F and C are sharp and G is natural. By convention, if HP is\
        indicated no key signature is indicated in the score. It is indicated\
        for Hp."


set hlp_midi4 " Advanced settings\n\n\
        If you have specified an alternate midi player in the configuration \
        property page, you can select the desired midi player to use here.\n\n\
        These changes take effect, the next time the play button is clicked.\n\n\
        The parameter beat divider determines which notes are \
        strong. If the time signature is x/y then each note is given a position \
        0,1,2,..x-1. If k is a multiple of n, then the note is strong.\n\n\Gracedivider\
        sets the length of the note to be used as a grace. The length is obtained\
        by dividing the unit length set by the L: field by the given factor. \
        For example for L:1/8, a factor of 4 would make all grace notes 32nd\
        notes. The time used by the grace notes are stolen from the following\
        note. If the following note is not long enough, no grace notes are\
        played.\n\n\
        Broken rhythm ratio adjusts the times for > and < indications \
        in the music body (eg. B > c). The default is 2 to 1, meaning the notes \
        are played as B4/3 c2/3 even though it is printed as B3/2 c1/2. If you want \
        it to be played as written then you should set the ratio to 3 to 1.\n\n\
        Drummaps are used when a separate drum voice is created. If less than 10\
        drum instruments are used, using drummaps produces a cleaner music score.\n\n\
        The default button resets all these values to their initial settings."







set hlp_voice "Voice / MIDI Property Sheet\n\n
The widgets on this sheet provide a means of controlling the\
        way abc2midi handles multivoiced abc tunes.  If the tune\
        already assigns MIDI instruments to the voices\
        in a syntax that abc2midi understands then any changes\
        that you make here are disregarded unless you had ticked the\
        check box 'override all midi indications' in the abc2midi\
        option/ tempo/pitch page. Otherwise, you can set your own\
        assignments, without actually modifying the file.\
        In addition you can change the volume level and panning\
        using the two scale widgets associated with the voice.\n\n\
        The level scale provides an additional method of adjusting the\
        volume level for a particular voice. This can be useful because\
        the audio level for a particular instrument also depends on the\
        MIDI synthesizer and the patches it uses. In some cases you may\
        wish to turn off one of the voices so you can concentrate on the\
        remaining lines of music.\n\n\
        The pan scale controls the mapping to the left or right speaker.\
        For some music this helps you to separate the different voices."


set hlp_abc2abc "Abc2abc Property Sheet\n\n\
        Check the desired options and click the abc2abc button. The \
        program will copy the selected files in the Table of Contents page (TOC) \
        to the X.tmp file and will run abc2abc on this file. Depending on the\
        radio button settings, the results will either be placed on a \
        clipboard or recorded on the abc_default_file (e.g. edit.abc) which\
        is automatically opened by an edit window. If you make the latter\
        choice, the contents of the abc_default_file will automatically be\
        overwritten each time you click the abc2abc button. If you use\
        clipboard instead, then open a blank abc file (using edit/new file)\
        and paste the contents of the clipboard using <cntl-v> on Windows\
        operating system or <cntl-y> on Unix and Linux systems.\n\n\
        The new spacing option, may introduce spaces between the notes in the \
        abc file in order for the notes to line up on beats. If you tick the \
        transpose box, you need to indicate the number of semitones to shift in \
        the adjoining entry box. Positive and negative numbers are accepted by \
        abc2abc. Note that if you have forgotten to tick the transpose box, \
        this action will not be taken. Similarly for the linebreaks box. \n\n
Checking the `force key to' box will produce a tune with the specified\
        key signature. The music will not be transposed but accidentals will be\
        added to override the specified key signature. Specifying a key\
        signature `none' is equivalent to the C key key signature and all\
        accidentals will be shown explicitly. You have a choice of using sharps\
        or flats.  The transpose function also works with K:none.\n\n\
        For multivoiced music, you can apply one of these functions to a\
        specific voice leaving the other voices intact. Check the button\
        'apply to only voice' and indicate the voice number. Note for\
        transpose to work correctly, the selected voice requires its own K:\
        field so that it will be modified.\n\n\
        See the readme.txt file in the abcMIDI.zip distribution for any additional\
        documentations."

set hlp_extr "Extract and Transpose Part from Score\n\n\
        A score typically consists of many voices often interleaved every few\
        bars. The functions in this page allow you to extract a single voice from\
        a tune and transpose it using abc2abc. It is generally necessary to clean up\
        the results to print a part for an individual musician. For example, the\
        score usually explicitly lists every bar of rests for an individual voice.\
        Musicians, prefer to have it indicated with a multibar rest. This is\
        performed by the condense function implemented in this program. The condense\
        function is not very smart, so it expects a single bar of rest to be\
        indicated by zn where n is exactly the number of time units (eg. eigth notes\
        if L: 1/8) for that bar and time signature. For example if L: 1/8 and\
        M: 4/4 a whole bar rest is z8.\n\n\
        Abc music notation is not completely standardized with regard to the\
        representation of multibar rests. Abc2ps expects it to be in the format,\
        \"n\"zm where n denotes the number of bars and zm denotes the whole bar rest.\
        Abcm2ps expects it to be in the format Zn where n is the number of bars.\
        Yaps and others programs in the abcMIDI package accept both formats.\n\n\
        Like the edit/abc2abc function, the part is automatically written to the\
        default abc output file, typically edit.abc. The display button produces a\
        postscript file from this file and calls the postscript viewer. \
        The save file button, will allow you to rename the output file to something else.\
        The \"To editor\" button, will automatically show the resulting abc file using\
        TclAbcEditor.\n\n\
        Thanks to Luis Pablo Gasparotto for the suggestion and initial implementation."

set hlp_multirests "Multirest tool functions\n\n\
        There are two conventions for representing multiple bars of rests\
        in abc notation. If you are using abc2ps then you need to use the older notation\
        (e.g. \"4\"z8 which means 4 bars of rests where each bar is 8 L: units). If you\
        are using abcm2ps then you should use the Zn notation (eg. Z4 indicates 4 bars\
        of rests). The functions in this sub-menu allow you to convert from one convention\
        to another. Like many other tools in this editor, the function only acts on the\
        region that you have highlighted. If you are converting to the older notation,\
        then the function determines the whole rest size by searching for previous L: and M:\
        indications.\n\n\
        Two other tools are available for condensing a sequence of whole rest bars. You\
        can also do the same thing in the edit/extract part menu page but sometimes things\
        do not work out automatically and you may need more control."

set hlp_midisave "This tool makes it easier to create multiple midi files\
        from a selection in the TOC. The midi files are created and placed in\
        a separate directory that you choose. You have a choice of two ways\
        of naming the new midi files. Either the name is generated from the title\
        of the tune or else it is generated from the xref number. If the name\
        is generated from the title of the tune, you should specify the maximum\
        number of characters that can be used (by default it  is 8). If the\
        name is generated from the xref number, then you should specify the\
        root name. By default the root name is derived from the current open\
        abc file. For example, if the root name is jigs and you selected tunes\
        1 to 2, then the midi files would be named jigs1.mid, jigs2.mid. Pressing\
        the continue button, will start the operation. Pressing cancel will close\
        this property sheet."

set hlp_drumkit "Drumkit Configuration\n\n\
        This window allows you to specify the %%MIDI drum sequence to be\
        inserted into the abc file. A pallette of several drums is given\
        by an array of buttons at the bottom of the window. To change the\
        pallette, click on the selector button.\n\n\
        To enter your own drum\
        sequence, type it in the entry box at the top and click the enter\
        button or press the return key. Alternatively, you could change it\
        using the drumpattern menu if it is exposed in a separate window.\n\n\
        The drum assignments for each hit (d) can be viewed by hovering the\
        the mouse cursor over the particular hit 'd'. The loudness of the\
        drum (strong, medium and weak) are indicated by the colours (red, black\
        or blue).\n\n\
        To change the assignment of the hits (d) \
        click on on one or more hits so that they are selected. You can deselect\
        a hit by clicking on the hit again. The deselect\
        button is a convenience for clearing all the selections.) Then click on the\
        the desired drum or loudness to use.\n\n\
        The play button will play this drum pattern several times. The\
        paste button is applicable if you editing an abc file using TclAbcEditor."

set hlp_drumtool "Drum Tool\n\n\
        The tool is used to edit a percussion voice \
        included in an abc tune. The tool allows you to create up to 8\
        drum patterns which is stored in the slots D0, D1, D2, and etc.\
        Each pattern represents a musical measure or bar.\
        These patterns can be imported into the TclMultiVoiceEditor where\
        they can be used to replace existing bars in the drum voice of\
        te abc file.\
        The drum pattern is specified graphically using a rectangular array\
        of squares. Each row represents a particular drum instrument and\
        each column represents a specific time unit in the bar. Clicking\
        any one of the squares in the array will flip its state from off to\
        on or vice-versa. The abc representation corresponding to the graphic\
        representation is given in the abc bar entry box.\
        (It is assumed you have some understanding on how abc represents\
        the percussion voice.) Once you have decided on the pattern, pressing,\
        the 'new' button will store the pattern in one of the available D\
        slots.\n\n\
        Prior to specifying the patterns you should press the  configure\
        button in order to specify the meter, rhythm structure, unit length\
        and other essential parameters. If you change your mind in the middle,\
        it invalidates all your previous work stored in the D buttons.\
        Please read the configure help file before for more details.\n\n\
        Each row of rectangles is labeled with the name of a percussion\
        instrument. If you click on the name of the\
        instrument, you should be able to preview its sound. You can change\
        the selection of percussion instruments (adding or subtracting) by\
        going to the selector menu button however you should do this before\
        recording any of the patterns in the D buttons.\n\n\
        Pressing the 'clear everything' button starts you at the beginning.\
        All the D buttons are wiped clean including the rectangular array\
        of squares. Since there is nothing stored in the D buttons, they\
        are all disabled. Clicking the 'new' button will enable the next\
        available button and store the drum pattern in that slot corresponding\
        to the graphical representation. It is possible to go back and\
        change the pattern in one of the slots.  Merely, press the\
        corresponding button and that pattern will be loaded in both the\
        abc bar entry box and the rectangular array.\n\n\
        The 'save' button will save your work in a file that you designate\
        in the configure menu. By default, the file name is drumpatterns.drum\
        which is a regular text file. The next time you start up the drumtool,\
        this information will be loaded automatically.\n\n\
        More documentation is on the web (http:\\\\ifdo.ca\\~seymour\\runabc\\top.html)."

set hlp_drumtool_cfg "DrumTool Configuration\n\n\
        Configuration information and the specified drum patterns are stored\
        in a user selected file which by convention should have a drum\
        extension. By default the file is given the name drumpatterns.drum.\
        The configuration file is automatically loaded each time the\
        drumtool Window is created assuming that this file exists. You can\
        update this file by clicking\
        the 'save' button in the drumtool window.\n\n\
        To allow you to handle more than one configuration file, you may\
        specify the name of the configuration file in the entry box.\n\n\
        The M: and L: entry boxes specify the meter and unit length to\
        be used in the abc representation of the drum patterns.\n\n\
        The beat entry box specifies how the beats are divided\
        into subbeats in the rectangular array of rectangles in the drumtool\
        window. The total number of columns in this array should be\
        either n, 2*n, 4*n, or 8*n where the meter is specified as n/m.\
        The configuration of the vertical columns mainly has impact\
        on how the notes are grouped in the bar. The groupings are mainly\
        a convenience for visualizing the drum patterns. The program does not\
        handle triplets, so factors of 3 and other primes should be avoided.\
        For example, if M:3/4, it may be convenient us a beat 2 2 2. Also\
        choosing L:1/8 would produce a more compact abc representation.\
        For complex meters such as M:7/8, you may choose the beat to be\
        3 2 2 or 2 2 3.\n\n\
        The beatstring specifies where the accents should be placed for\
        each of the subbeats. f stands for forte, m stands for mezzo, and\
        p for piano. The velocities associated for each of these indications\
        are specified in the entry boxes below.\n\n\
        The tempo scale only applies to the 'play', 'to abc file' buttons\
        as well as the preview function when you right click on one of the\
        pattern codes p0, p1, etc in the drumtool window.\n\n\
        Clicking any of the enter buttons will activate the change\
        in the entry box and cause the program to check that the values\
        in the entry box are self-consistent. If a discrepancy is detected\
        it will be reported at the bottom of the configuration window.
"


set hlp_g2v "Gchords/Drums to Voice\n\n\
        This function expands the guitar chords and drum strings into separate\
        voices. The output abc file should sound like the input file. Thus if\
        no gchord string is present in the tune it will use the default string for\
        the current key signature or the gchord string specified in the\
        Play Options/gchord&drums toolbox. If the drum output button is not\
        checked and there is no %%MIDI drum command in the input tune,\
        then there will not be any drum output. Similarly, the input file\
        should have guitar chord indications (in double quotes).\n\n\
        Assuming that output to editor is selected, the new tune is\
        displayed in the TclAbcEdit window and is stored in the\
        default file edit.abc.  The program is not as robust as\
        abc2midi so that it may be necessary to edit the output in some cases.\
        Like abc2midi, the gchord string determines how the guitar chords\
        are expressed. The gchord string may be indicated in the abc notated\
        tune using the %%MIDI gchord command. If it is not indicated, then\
        both abc2midi and this program uses the default gchord string based\
        on the time signature, assuming it is a common signature.\n\n\
        You may change the default gchord string for that time signature\
        by entering it in the entry box. The new string will remain the\
        default until you exit the program. Legal codes are\
        z,c,f,b,g,h,i,j,G,H,I,and J. (See abcguide.txt in the\
        doc folder.) Note to use J or j, the guitar chord\
        must be a 7th. In order to be able to express the\
        gchord into notes, the length of the gchord string should divide\
        evenly into the time signature so that each unit can be expressed\
        by a note. For example: for 3/4 time, the strings zfc, zfzczc are\
        fine but zf2c2 would not work since the gchord string is 5 units\
        long which could not be split up into 3 beats.\n\n\
        Important messages are shown at the bottom of the window; however,\
        more detailed messages are put in the console window.\n\n\
        If output to clipboard is selected, then just the gchord voice\
        is placed in the clipboard. You can now paste the contents\
        of the clipboard into any file. This method is more flexible, since\
        you can expand the abc tune with different gchord accompaniment\
        tracks. However, this method requires more editing. You need\
        to insert V: commands in the right places. If the input file\
        was multipart, then you need to move the different parts into\
        the right places. Furthermore, you need to look at the console\
        window for any warnings and errors.

If the tune contains a %%MIDI drum command the program can also\
        expand the drum pattern into a sequence of notes that form a bar\
        which is repeated in a separate voice. Like the gchord sequence,\
        the drum pattern should fit evenly in the bar. If no %%MIDI drum\
        pattern is given but drum output is selected in the Play options\
        /gchord&drums page, then the program would create the drum voice\
        using the default %%MIDI drum command appropriate for the time\
        signature of the piece. Alternatively, you can specify your own\
        drum pattern by clicking going to the drumkit window. Or you can\
        just enter the %%MIDI drum command in the entry box provided\
        in the ghcords/drums to voice window.

For most single voiced abc tunes, the input voice name or number\
        should be the numeral 1. If the abc tune contains more than one voice\
        then you should choose the voice which has embedded guitar chords.\
        "



# Help
proc contexthelp {} {
    global active_sheet cfg_subsection midi_subsection
    global hlp_overview hlp_config_1 hlp_config_2
    global hlp_config_3 hlp_ps
    global hlp_midi1 hlp_midi2 hlp_midi3 hlp_midi4
    global hlp_midi5
    global hlp_voice
    global hlp_yaps hlp_abc2abc hlp_midi2abc
    global hlp_extr
    global hlp_otherps
    global hlp_incipits
    global hlp_g2v
    global hlp_reformat
    
    switch -- $active_sheet {
        none   {show_message_page $hlp_overview word}
        titles {show_message_page $hlp_overview word}
        config {switch -- $cfg_subsection {
                1 {show_message_page $hlp_config_1 word}
                2 {show_message_page $hlp_config_2 word}
                3 {show_message_page $hlp_config_2 word}
                4 {show_message_page $hlp_config_3 word}
            }
        }
        psstyle {show_message_page $hlp_ps word}
        psform {show_message_page $hlp_ps word}
        yaps   {show_message_page $hlp_yaps word}
        midi   {switch -- $midi_subsection {
                1 {show_message_page $hlp_midi1 word}
                2 {show_message_page $hlp_midi2 word}
                8 {show_message_page $hlp_midi4 word}
                10 {show_message_page $hlp_midi5 word}
                default {puts $midi_subsection}
            }
        }
        voice  {show_message_page $hlp_voice word}
        abc2abc {show_message_page $hlp_abc2abc word}
        midi2abc {show_message_page $hlp_midi2abc word}
        extract {show_message_page $hlp_extr word}
        otherps {show_message_page $hlp_otherps word}
        incipits {show_message_page $hlp_incipits word}
        g2v {show_message_page $hlp_g2v word}
        reformat {show_message_page $hlp_reformat word}
    }
}

# Part 14.0           Drum Editor


set drumpatches {
    {35	B,,,	{Acoustic Bass Drum}}
    {36	C,,	{Bass Drum 1}}
    {37	^C,,	{Side Stick}}
    {38	D,,	{Acoustic Snare}}
    {39	^D,,	{Hand Clap}}
    {40	E,,	{Electric Snare}}
    {41	F,,	{Low Floor Tom}}
    {42	^F,,	{Closed Hi Hat}}
    {43	G,,	{High Floor Tom}}
    {44	^G,,	{Pedal Hi-Hat}}
    {45	A,,	{Low Tom}}
    {46	^A,,	{Open Hi-Hat}}
    {47	B,,	{Low-Mid Tom}}
    {48	C,	{Hi Mid Tom}}
    {49	^C,	{Crash Cymbal 1}}
    {50	D,	{High Tom}}
    {51	^D,	{Ride Cymbal 1}}
    {52	E,	{Chinese Cymbal}}
    {53	F,	{Ride Bell}}
    {54	^F,	Tambourine}
    {55	G,	{Splash Cymbal}}
    {56	^G,	Cowbell}
    {57	A,	{Crash Cymbal 2}}
    {58	^A,	Vibraslap}
    {59	B,	{Ride Cymbal 2}}
    {60	C	{Hi Bongo}}
    {61	^C	{Low Bongo}}
    {62	D	{Mute Hi Conga}}
    {63	^D	{Open Hi Conga}}
    {64 	E	{Low Conga}}
    {65 	F	{High Timbale}}
    {66	^F	{Low Timbale}}
    {67	G	{High Agogo}}
    {68	^G	{Low Agogo}}
    {69	A	Cabasa}
    {70	^A	Maracas}
    {71	B	{Short Whistle}}
    {72	c	{Long Whistle}}
    {73	^c	{Short Guiro}}
    {74	d	{Long Guiro}}
    {75	^d	{Claves}}
    {76	e	{Hi Wood Block}}
    {77	f	{Low Wood Block}}
    {78	^f	{Mute Cuica}}
    {79	g	{Open Cuica}}
    {80	^g	{Mute Triangle}}
    {81	a	{Open Triangle}}
}


# needed for proc drum_bar_to_drumhits
foreach patch $drumpatches {
    set midino [lindex $patch 0]
    set notename [lindex $patch 1]
    set revpatch($notename) $midino
}




proc drum_editor {} {
    global midi df
    global drumpatches
    global drumpat
    if {[winfo exists .drumkit] == 1} {focus .drumkit; return} else {
        toplevel .drumkit
        
        set w .drumkit.input
        frame $w -borderwidth 2
        entry $w.ent -width 20 -textvariable drumentry -font $df
        button $w.enter -text enter -font $df \
                -command {get_drumentry $drumentry
                    focus .drumkit}
        pack $w.ent $w.enter -anchor w -side left
        pack $w
        
        set w .drumkit.ctl
        frame $w -borderwidth 2 -relief raised
        button $w.select -text "drum selector" -font $df -command drumkey
        button $w.play -command play_drum_test -text play -font $df
        button $w.paste -command paste_drumstring -text paste -font $df
        button $w.help -text help -font $df\
                -command {show_message_page $hlp_drumkit word}
        
        pack $w.select $w.play $w.paste $w.help -anchor w -side left
        pack $w
        
    }
    
    # remove repeated blanks if any
    set regpat "\[ \]+"
    regsub -all $regpat $midi(drumpat) " " res
    set midi(drumpat) $res
    
    set w .drumkit.pat
    frame $w -borderwidth 2
    pack $w -side top
    
    set w .drumkit.accent
    frame $w -borderwidth 3
    pack $w -side top
    button $w.1 -text strong -font $df -fg red -command "change_drum_vel dstrong"
    button $w.2 -text medium -font $df  -command "change_drum_vel dmedium"
    button $w.3 -text weak -font $df -fg blue -command "change_drum_vel dweak"
    pack $w.1 $w.2 $w.3 -side left
    
    
    
    # create drum patches selector
    frame .drumkit.patches -borderwidth 2 -relief raised
    pack .drumkit.patches -side top
    refresh_drumkit_patches
    
    prepare_drumentry $midi(drumpat)
    
}

proc refresh_drumkit_patches {} {
    global npatches midi
    global drumpat
    set npatches 0
    if {[winfo exist .drumkit]} destroy_all_drumkit_patches
    if {[winfo exist .dk]} {set midi(selected_drums) [return_selected_drumsel]}
    foreach patindex $midi(selected_drums) {
        add_selected_drum $patindex
    }
    if {$midi(drummap)} {drum2map $midi(drumpat)}
}

proc add_selected_drum {patindex} {
    global drumpatches
    global npatches
    global midi df
    if {[winfo exist .drumkit]} {
        set pat [lindex $drumpatches $patindex]
        set name [lindex $pat 2]
        button .drumkit.patches.$npatches -text $name -font $df\
                -width 16 -command "change_drum_prog $patindex"
        set c [expr $npatches % 2]
        set r [expr $npatches / 2]
        grid .drumkit.patches.$npatches -column $c -row $r
        incr npatches
    }
}


proc destroy_all_drumkit_patches {} {
    foreach w [winfo children .drumkit.patches] {
        destroy $w
    }
}


proc change_drum_prog {j} {
    global drumpatches w drumprog
    # global drumproglist drumpat
    global midi
    set selection [make_list_of_dndex_on]
    set selected_drums [lindex $selection 0]
    set positions [lindex $selection 1]
    foreach drumindex $selected_drums pos $positions {
        set pat [lindex $drumpatches $j]
        set name [lindex $pat 2]
        set cmd "tooltip::tooltip .drumkit.pat.$drumindex [list $name]"
        set drumprog($drumindex) [expr $j+35]
        set p  [expr $pos + 1]
        set midi(drumpat) [lreplace $midi(drumpat) $p $p [expr $j +35]]
        eval $cmd
    }
    .abc.midi1.drumpat.pat configure -text [patlabel]
}

proc change_drum_vel {vel} {
    global drumvel drumindex drumlist midi
    #puts "change_drum_vel $midi(drumpat)"
    set selection [make_list_of_dndex_on]
    set selected_drums [lindex $selection 0]
    set positions [lindex $selection 1]
    foreach drumindex $selected_drums pos $positions {
        set drumvel($drumindex) $vel
        switch $vel {
            dstrong {.drumkit.pat.$drumindex configure -fg red}
            dmedium {.drumkit.pat.$drumindex configure -fg black}
            dweak {.drumkit.pat.$drumindex configure -fg blue}
        }
        #puts "change_drum_vel $drumproglist"
        set l [llength $midi(drumpat)]
        set p [expr 1+$pos +($l-1)/2]
        set midi(drumpat) [lreplace $midi(drumpat) $p $p $midi($vel)]
        #puts $midi(drumpat)
        .abc.midi1.drumpat.pat configure -text [patlabel]
    }
}


proc drumkey {} {
    #produces a selector for the desired drum patches
    global drumpatches drumsel df
    if {[winfo exist .dk] != 1} {toplevel .dk
        set j 0
        load_drumsel
        foreach d $drumpatches  {
            set name "[lindex $d 0] [lindex $d 2]"
            checkbutton .dk.$j -text $name -variable drumsel($j)\
                    -command {refresh_drumkit_patches
                        setup_drum_grid} -font $df
            set k [expr $j % 3]
            set r [expr $j / 3]
            grid .dk.$j -row $r -column $k -sticky w
            incr j
        }
    }
}


proc clear_drumsel {} {
    global drumsel
    for {set i 0} {$i < 47} {incr i} {
        set drumsel($i) 0
    }
}

proc load_drumsel {} {
    global drumsel midi
    clear_drumsel
    foreach item $midi(selected_drums) {
        set drumsel($item) 1
    }
}

proc return_selected_drumsel {} {
    global midi
    set selected_drums {}
    global drumsel
    for {set i 0} {$i < 47} {incr i} {
        if $drumsel($i) {lappend selected_drums $i}
    }
    set midi(selected_drums) $selected_drums
    return $selected_drums
}


proc get_drumentry {drumentry} {
    global midi
    prepare_drumentry $drumentry
    set midi(drumpat) [append_drum_velocities $midi(drumpat)]
    .abc.midi1.drumpat.pat configure -text [patlabel]
    #puts "get_drumentry $midi(drumpat)"
}



proc prepare_drumentry {drumentry} {
    global midi drumvel drumproglist
    global drumpatches df
    global drumpat drumlist
    global drumprog
    
    #puts "prepare_drumentry $drumentry"
    set midi(drumpat) $drumentry
    set splitpat [split $midi(drumpat)]
    set drumpat [lindex $splitpat 0]
    set loc [string first "{}" $splitpat]
    if {$loc > 0} {set loc2 [expr $loc+1]
        set splitpat [string replace $splitpat $loc $loc2 ""]
    }
    
    
    set drumproglist [lrange $splitpat 1 end]
    set drumlist [parse_drum_string $drumpat]
    
    
    # create drumprog and drumvel arrays
    set ndrums 0
    foreach elem $drumlist {
        set initialchar [string index $elem 0]
        if {$initialchar != "d"} continue
        if {[llength $drumproglist] > $ndrums} {
            set n [lindex $drumproglist $ndrums]
            set drumprog($ndrums) $n
            set drumvel($ndrums) dmedium
        } elseif {[info exist drumprog($ndrums)]} {
            set n $drumprog($ndrums)
            lappend drumproglist $drumprog($ndrums)
        } else {
            set drumprog($ndrums) [pick_random_drum]
            set drumvel($ndrums) dmedium
            lappend drumproglist $drumprog($ndrums)
        }
        incr ndrums
    }
    
    
    set w .drumkit.pat
    foreach w2 [winfo children $w] {
        destroy $w2
    }
    set i 0
    set i1 0
    button $w.desel -text deselect -font $df -command drumkit_deselect_all
    pack $w.desel -side left
    foreach elem $drumlist {
        checkbutton $w.$i -text $elem  -indicatoron 0\
                -variable dndex($i) -font $df
        pack $w.$i -side left
        set initial [string index $elem 0]
        if {$initial != "d"} {incr i; continue}
        set j [expr $drumprog($i1) -35]
        set pat [lindex $drumpatches $j]
        set name [lindex $pat 2]
        set cmd "tooltip::tooltip $w.$i [list $name]"
        eval $cmd
        incr i
        incr i1
    }
    set midi(drumpat) "$drumpat $drumproglist"
    .abc.midi1.drumpat.pat configure -text [patlabel]
    #puts "prepare_drum_entry $drumproglist"
}

proc drumkit_deselect_all {} {
    global drumlist
    set i 0
    set w .drumkit.pat
    foreach elem $drumlist  {
        $w.$i deselect
        incr i
    }
}


proc make_list_of_dndex_on {} {
    global drumlist dndex
    set n [llength $drumlist]
    set dlist {}
    set dloc {}
    set dcount 0
    for {set i 0} {$i < $n} {incr i} {
        set elem [lindex $drumlist $i]
        set initial [string index $elem 0]
        if {$initial == "d" && $dndex($i) == 1} {
            lappend dlist $i
            lappend dloc $dcount
        }
        if {$initial == "d"}  {
            incr dcount
        }
    }
    return [list $dlist $dloc]
}



proc make_trial_abc_file {} {
    global midi
    set outfd [open $midi(midi_dir)/X.tmp w]
    puts $outfd "X: 1\nT: drum trial\nM: 2/4\nL: 1/8\nK: G"
    puts $outfd "%%MIDI drum $midi(drumpat)"
    puts $outfd "%%MIDI drumon"
    puts $outfd "z4|z4|z4|z4|z4|z4|z4|z4\n\n"
    close $outfd
}

proc play_drum_test {} {
    global midi exec_out drumentry
    global files
    make_trial_abc_file
    set dir "[pwd]/$midi(midi_dir)"
    set cmd "file delete [glob -nocomplain $dir/X*.mid]"
    catch {eval $cmd}
    set cmd "exec $midi(path_abc2midi) $midi(midi_dir)/X.tmp"
    catch {eval $cmd} exec_out
    set exec_out $cmd\n\n$exec_out
    set files $midi(midi_dir)/X1.mid
    update_console_page
    play_midis 1
}

proc paste_drumstring {} {
    global abctxtw midi
    set drumstring $midi(drumpat)
    set point [$abctxtw index insert]
    $abctxtw insert $point  "%%MIDI drum $drumstring\n"
}




set hlp_drums "This drum tool is designed to help you create a \
        drum string which is used by abc2midi. For a good explanation of \
        the drum string, you should refer to the file abcguide.txt \
        that is included with the abcMIDI.zip distribution.\n\n\
        The top  text line window shows the default drum string d2dz2d. \
        To change it, click on the entry box in the line below and enter \
        your desired string. You must complete the string with a \
        carriage return or click the enter button. \
        \n\nThere are two scrolled listboxes that are used to map the \
        individual drum hits (eg d2) to particular drum patches. The left \
        box shows the current mapping for each drum hit. \
        To change, the mapping select a particular drum \
        hit in the left listbox and then click on a desired patch \
        shown in the right list box. The mapping should change immediately. \
        The beige label immediately above the list box shows the \
        last selected patch. Whenever you click the enter button, all the drum \
        hits will be changed to that patch. \n\nThe play button will allow \
        you to listen to the particular drumstring. It will create and play \
        a midi file with 8 bars of this drumstring. The paste button will \
        paste the drumstring in your file being edited in the abcedit window. \
        The %%MIDI drum command will be pasted at the position of the insert \
        cursor. (Don't forget to insert the %%MIDI drumon command in the\
        body of the music.)"
#end of drumedit.tcl



# Part 15.0           Title Search functions


startup_progress "loading search functions"




#source abcsearch.tcl

# abcsearch.tcl
# The program searches for all abc tunes whose
# title contains a specific string.
# The search is started from the given directory
# and all abc files found in this directory or
# subdirectories are scanned.
#
#

proc find_window {} {
    set p .abcsearch
    global df midi
    if {[winfo exist $p]} return
    toplevel $p
    frame $p.1
    frame $p.2
    label $p.lab -width 30 -text "" -font $df
    label $p.1.dirlab -text "top directory" -font $df
    entry $p.1.dirbox -width 30 -textvariable midi(searchdir) -font $df
    bind $p.1.dirbox <Return> {focus .abcsearch.1.dirlab}
    button $p.1.dir -text "browse" -font $df -command match_dir_browser
    label $p.2.strlab -text "search string" -font $df
    entry $p.2.strbox -width 30 -textvariable searchstring -font $df
    bind $p.2.strbox <Return> {focus .abcsearch.1.dirlab
        title_match}
    button $p.2.but -text search -command title_match -font $df
    button $p.2.help -text help -font $df
    listbox $p.list -width 50 -bg #f4ece0 \
            -yscrollcommand {.abcsearch.ysbar set} \
            -xscrollcommand {.abcsearch.xsbar set} \
            -font $df -exportselection false
    scrollbar $p.ysbar -orient vertical -command {.abcsearch.list yview}
    scrollbar $p.xsbar -orient horizontal -command {.abcsearch.list xview}
    
    
    pack $p.1.dirlab $p.1.dirbox $p.1.dir -side left
    pack $p.2.strlab $p.2.strbox $p.2.but $p.2.help -side left
    pack $p.1
    pack $p.2
    pack $p.ysbar -side right   -fill y -in $p
    pack $p.xsbar -side bottom  -fill x -in $p
    pack $p.list -fill both -expand y -in $p
    
    bind .abcsearch.list <Button> {show_file [.abcsearch.list nearest %y]}
    bind .abcsearch.2.help <Button> {show_message_page $hlp_find word
        focus .abc
        raise .abc .abcsearch}
    
}

set hlp_find "This tool is used for searching for tunes whose title\
        contains a specific string (eg. word or sequence of words). The search\
        is performed on all abc files contained in a specific directory including\
        all its subdirectories. This tool is useful if you have a large collection\
        of abc files some of which are compilations of many tunes. Before using\
        tool you should enter the path to this directory in the top entry box.\
        You may use the browser button on the left for finding the directory.\
        This directory will be stored in the runabc.ini file, so you will not\
        have to type it in each time you run this tool. Next enter a specific\
        string that you think is in the title. The program does not distinguish\
        upper and lower case letters. Avoid punctuation marks and other special\
        symbols as this string is actually interpreted as a regular Tcl expression\
        using the regexp function. You can actually specify fairly complex\
        patterns in the title if you know about the regexp function. For\
        example: \n\mary | john 	will return any title containing either\
        the word mary or john.\n\
        (CT \[0-9\]+)	will return any title containing something like (CT 140).\n\
        fairies$		will return any title ending with fairies.\n\
        ^some		will return any title starting with the string some.\n\n\
        After you enter a carriage return or click the search button, the\
        program will cd to this directory and locate all abc files using a\
        recursive glob.  For each file with an abc extension, the title line\
        of every tune will be scanned for the specified string. Whenever a\
        match is found, the title and source will be added to the listbox below.\
        If you feel you have enough matches, you can stop the search by clicking\
        on the stop button.\n\n\ All the identified titles in the listbox are\
        mouse sensitive. If you click on one of the titles, the selected file\
        will be automatically opened, the table of contents of that file will\
        appear and the listbox will automatically scroll so that the selected\
        tune will be visible.  Note that some tunes may have more\
        than one title. The match is done on all titles, but only the first\
        title appears in the table of contents. If it selects a title past the\
        one you wanted, it probably indicates that some tunes are missing a T:\
        field in the abc file. Correct the abc file so you do not miss some tunes."



# This function lists the X: index number, titles and key signature
# of every tune found in the specified abcfile. The function expects
# every tune to begin with an X: index specifier and the title to
# found in the T: field command. More than one title may belong to
# a specific tune.

# Method: search for an X: field and then all the associated T:
# fields. When a K: field is encountered, grab the key signature
# and output all the title, key information to the open output file
# referenced by the outhandle variable;  ignore everything else
# that follows until the next X: field is found. Stop when an
# eof is encountered.


proc search_string_in_title {abcfile filenum} {
    global searchstring
    global listbox_line
    global file_index locator
    global stopsearch
    set srch X
    set blank_lines 0
    set titlehandle [open $abcfile r]
    set loc -1
    while {[gets $titlehandle line] >= 0 && $stopsearch == 0} {
        if {!$blank_lines && [string length $line] < 1} {set srch X}
        set initialchar [string index $line 0]
        switch -- $srch {
            X {
                if { $initialchar == "X"} {
                    set number [string range $line 2 10]
                    set srch T
                    incr loc
                }
            }
            T {
                if { $initialchar == "T"} {
                    set name [string range $line 2 end]
                    set name [string trim $name]
                    if {[regexp -nocase  $searchstring $name] > 0} {
                        set match   [format "%s %s   %s" $number $name $abcfile]
                        .abcsearch.list insert end $match
                        update
                        set file_index($listbox_line) $filenum
                        set locator($listbox_line) $loc
                        .abcsearch.list see $listbox_line
                        incr listbox_line
                    } elseif {$initialchar == "K"} {
                        #		    set keysig [string range $line 2 end]
                        #		    set keysig [string trim $keysig]
                        set srch X
                    }
                }
            }
        }
    }
    close $titlehandle
}


proc show_file {loc} {
    global midi
    global file_index gfiles locator
    global item_id
    if {$loc < 0} return
    .abc.titles.t selection set {}
    open_abc_file $midi(searchdir)/$gfiles($file_index($loc))
    set toc_index $item_id($locator($loc))
    .abc.titles.t selection set $toc_index
    .abc.titles.t focus $toc_index
    .abc.titles.t see $toc_index
    update
}


#
#---------------------------------------------------------------------------
#  rglob, Performs a recursive glob
#
#  Copyright (C) 2000 Agnar Renolen
#     email: agnar@organizer.net
#
#  This module is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  .................
#---------------------------------------------------------------------------

##
#   rglob - recursive glob
#
# SYNOPSIS
#   [rglob <pattern>]
#
# DESCRIPTION
#   Executes a recursive /glob/ returning a list of all files matching
#   a <pattern>.  If the search is to be started in a particular
#   directory, this is obtained by prefixing the <pattern> with the
#   directory name as e.g., [rglob "c:/develop/tclproject/*.tcl"].
#
#   The globbing is executed using the [-nocomplain] option, so if
#   [rglob] finds no matches, an empty list is returned.
##

proc rglob {pattern} {
    set fileList {}
    foreach fname [glob -nocomplain $pattern] {
        if {![file isdirectory $fname]} {
            lappend fileList $fname
        }
    }
    foreach fname [glob -nocomplain -types d "[file dirname $pattern]/*"] {
        set fileList [concat $fileList [rglob "$fname/[file tail $pattern]"]]
    }
    return $fileList
}


proc title_match {} {
    global midi
    global gfiles
    global file_index
    global listbox_line
    global locator
    global stopsearch
    global searchstring
    if {[string length $searchstring] < 1} return
    set home [pwd]
    cd $midi(searchdir)
    pack .abcsearch.lab
    .abcsearch.2.but configure -text stop -command stopsearching
    .abc.functions.play  configure -state disabled
    .abc.functions.disp  configure -state disabled
    .abcsearch.list delete 0 end
    set file_list [rglob *.abc]
    set i 0
    set listbox_line 0
    if {[info exist file_index]} {unset file_index}
    if {[info exist locator]} {unset locator}
    set stopsearch 0
    foreach filename $file_list {
        if {$stopsearch} break;
        set gfiles($i) $filename
        .abcsearch.lab configure -text $filename
        update
        search_string_in_title $filename $i
        incr i
    }
    cd $home
    stopsearching
}

proc stopsearching {} {
    global stopsearch
    set stopsearch 1
    .abcsearch.2.but configure -text search -command title_match
    .abc.functions.play  configure -state normal
    .abc.functions.disp  configure -state normal
}
#end of abcsearch.tcl


proc get_version_number {executable} {
    set cmd "exec [list $executable] -ver"
    catch {eval $cmd} result
    return $result}



# Part 16.0        Abcmatcher interface


#source abcmatch.tcl

proc check_abcmatch_version {version} {
    global midi
    global exec_out
    if {[file exist $midi(path_abcmatch)] != 1} {
        messages "runabc requires the executable abcmatch.exe to run this \
                function. You need to specify the path to this executable using the \
                config/executables menu item."
        return}
    set result [get_version_number $midi(path_abcmatch)]
    set exec_out $result
    if {$result < [expr $version + 0.1] && $result >= $version} {return 1}
    #version difference of 0.1 implies new version not compatible with runabc
    messages "runabc was expecting abcmatch version $version. Instead it \
            found version $result" 0
    update_console_page
    return 0
}


proc match_window {} {
    global midi df hlp_match
    set f .matcher
    if {[winfo exist $f]} return
    toplevel $f
    frame $f.1
    label $f.1.inputfilelab -text "path" -font $df
    entry $f.1.inputfilevar -width 50 -textvariable midi(searchdir) -font $df
    button $f.1.filebrowse -text browse -command match_file_browser -font $df
    bind $f.1.inputfilevar <Return> {focus .matcher.1.inputfilelab}
    
    frame $f.2
    label $f.2.keylab -text K: -font $df
    label $f.2.meterlab -text M: -font $df
    label $f.2.lengthlab -text L: -font $df
    entry $f.2.keyent -width 5 -textvariable midi(match_keysig) -font $df
    bind $f.2.keyent <Return> {focus .matcher.2.keylab}
    entry $f.2.meterent -width 5 -textvariable midi(match_timesig) -font $df
    bind $f.2.meterent <Return> {focus .matcher.2.meterlab}
    entry $f.2.lengthent -width 5 -textvariable midi(match_length) -font $df
    bind $f.2.lengthent <Return> {focus .matcher.2.lengthlab}
    frame $f.body
    label $f.body.bodylab -text body -font $df
    entry $f.body.bodyent -width 60 -textvariable midi(match_body) -font $df \
            -xscrollcommand "$f.scroll set"
    bind $f.body.bodyent <Return> {focus .matcher.body.bodylab
        create_match.abc
        start_matcher}
    pack $f.body.bodylab $f.body.bodyent -side left -anchor w
    scrollbar $f.scroll -relief sunken -orient horiz \
            -command "$f.body.bodyent xview"
    
    frame $f.con
    button $f.con.start -text match -font $df -command {create_match.abc
        start_matcher}
    button $f.con.play -text play -font $df -command play_match.abc
    button $f.con.transfer -text transfer -font $df -command transfer_editor_buffer_to_abcmatch
    button $f.con.dump -text "save results" -font $df -command dump_to_abc
    button $f.con.help -text help -font $df \
            -command {
                show_message_page $hlp_match word
                focus .abc
                raise .abc}
    pack $f.con.start $f.con.play $f.con.transfer $f.con.dump $f.con.help\
            -side left -anchor w
    
    pack  $f.2.keylab $f.2.keyent $f.2.meterlab $f.2.meterent $f.2.lengthlab \
            $f.2.lengthent -side left -anchor w
    
    
    frame $f.3
    label $f.3.reslab -text exact -font $df
    set p $f.3.resbut
    menubutton $p -menu $p.type -text "resolution" -relief raised -font $df
    menu $p.type -tearoff 0
    $p.type add command -label "exact"  -command "setres 0" -font $df
    $p.type add command -label "1/16 note" -command "setres 6" -font $df
    $p.type add command -label "1/8 note"  -command "setres 12" -font $df
    $p.type add command -label "1/4 note"  -command "setres 24" -font $df
    $p.type add command -label "3/8 note"  -command "setres 36" -font $df
    $p.type add command -label "1/2 note"  -command "setres 48" -font $df
    $p.type add command -label "3/4 note"  -command "setres 72" -font $df
    $p.type add command -label "whole note" -command "setres 96" -font $df
    
    set p  $f.3.selectionmenu
    menubutton $p -menu $p.type -text selection -relief raised -font $df
    menu $p.type -tearoff 0
    
    $p.type add radiobutton -label all -variable midi(match_selection) -value all\
            -font $df -command "set_match_selection all"
    $p.type add radiobutton -label any -variable midi(match_selection) -value any \
            -font $df -command "set_match_selection any"
    
    label  .matcher.3.selection -text "all bars" -font $df
    
    
    set p $f.3.transpositionmenu
    menubutton $p -menu $p.type -text method -relief raised -font $df
    menu $p.type -tearoff 0
    
    $p.type add radiobutton -label "absolute"      -command "set_match_method abs"\
            -font $df -variable midi(match_method) -value abs
    $p.type add radiobutton -label "contour"  -command "set_match_method con"\
            -font $df -variable midi(match_method) -value con
    $p.type add radiobutton -label "quantized contour"  -command "set_match_method qcon"\
            -font $df -variable midi(match_method) -value qcon
    
    label .matcher.3.transposition -text "key signature" -font $df
    
    pack $f.3.resbut $f.3.reslab $f.3.selectionmenu $f.3.selection \
            $f.3.transpositionmenu $f.3.transposition  -side left -anchor w
    
    pack  $f.1.inputfilelab  $f.1.inputfilevar $f.1.filebrowse -side left -anchor w
    pack $f.1 $f.2 $f.3 $f.body -side top -anchor w
    pack $f.scroll -side top -fill x
    pack $f.con -side top -anchor w
    
    
    frame $f.msg
    label $f.msg.lab -width 40 -text "" -font $df
    setres $midi(match_resolution)
    set_match_selection $midi(match_selection)
    set_match_method $midi(match_method)
    pack $f.msg.lab -side left
    pack $f.msg -side top
}


proc setres {value} {
    global midi
    set w .matcher.3.reslab
    switch $value {
        0 {set midi(match_resolution) 0
            $w configure -text exact }
        6 {set midi(match_resolution) 6
            $w configure -text "1/16 note" }
        12 {set midi(match_resolution) 12
            $w configure -text "1/8 note" }
        24 {set midi(match_resolution) 24
            $w configure -text "1/4 note" }
        36 {set midi(match_resolution) 36
            $w configure -text "3/8 note" }
        48 {set midi(match_resolution) 48
            $w configure -text "1/2 note" }
        72 {set midi(match_resolution) 72
            $w configure -text "3/4 note" }
        96 {set midi(match_resolution) 96
            $w configure -text "whole note" }
    }
}

proc set_match_selection {value} {
    set w .matcher.3.selection
    switch $value {
        all {$w configure -text "all bars"}
        any {$w configure -text "any bars"}
    }
}

proc set_match_method {value} {
    set w .matcher.3.transposition
    switch $value {
        abs  {$w configure -text "absolute"}
        con  {$w configure -text "contour"}
        qcon {$w configure -text "quantized contour"}
    }
}



proc pop_matcher_results {} {
    global df
    set p .matcher.notice
    if [winfo exist .matcher.notice] {
        $p.t configure -state normal
        $p.t delete 1.0 end
    } else {
        frame $p
        text $p.t -height 25 -width 70 -wrap word -yscrollcommand {.matcher.notice.ysbar set} -font $df
        scrollbar $p.ysbar -orient vertical -command {.matcher.notice.t yview}
        pack $p.ysbar -side right -fill y -in $p
        pack $p.t -in $p
        pack $p}
}



proc create_match.abc {} {
    global midi
    set handle [open match.abc w]
    puts $handle  X:1
    puts $handle  T:match_template
    puts $handle  M:$midi(match_timesig)
    puts $handle  L:$midi(match_length)
    puts $handle  K:$midi(match_keysig)
    puts $handle  $midi(match_body)
    close $handle
    set last [string index $midi(match_body) [expr [string length $midi(match_body)] -1]]
    if {[string equal $last |] != 1} {
        messages "body should end with a bar line"}
}

proc start_matcher {} {
    global midi
    global stopsearch
    global match_index
    if {[file exist $midi(searchdir)] != 1} {
        messages "The file or directory $midi(searchdir) could not be \
                found. Searching was aborted."
        return
    }
    set match_index 0
    set stopsearch 0
    .matcher.con.start configure -text stop -command stop_matcher
    .abc.functions.play  configure -state disabled
    .abc.functions.disp  configure -state disabled
    update
    if {[file isdirectory $midi(searchdir)]} run_glob_matcher else run_matcher
}


proc stop_matcher {} {
    global stopsearch
    .matcher.con.start configure -text match -command {create_match.abc
        start_matcher}
    .abc.functions.play  configure -state normal
    .abc.functions.disp  configure -state normal
    set stopsearch 1
}

proc run_matcher {} {
    global matchlist
    global midi
    global exec_out
    set cmd "exec [list $midi(path_abcmatch)]  [list $midi(searchdir)] -r $midi(match_resolution)"
    if {$midi(match_selection) == "any"} {set cmd [concat $cmd -a]}
    if {$midi(match_method) == "con"} {set cmd [concat $cmd -con]}
    if {$midi(match_method) == "qcon"} {set cmd [concat $cmd "-con -qnt"]}
    set cmd [concat $cmd -ign]
    catch {eval $cmd} result
    set exec_out $cmd\n$result
    set matchlist [split $result \n"]
    pop_matcher_results
    record_matched_tunes $midi(searchdir) 1
    stop_matcher
    update_console_page
}


proc run_glob_matcher {} {
    global midi
    global matchlist
    global exec_out
    global stopsearch
    set home [pwd]
    cd $midi(searchdir)
    set file_list [rglob *.abc]
    cd $home
    set stopsearch 0
    pop_matcher_results
    set i 0
    foreach filename $file_list {
        .matcher.msg.lab configure -text $filename"
        update
        set filepath [file join $midi(searchdir) $filename]
        set cmd "exec [list $midi(path_abcmatch)] [list $filepath] \
                -r $midi(match_resolution)"
        if {$midi(match_selection) == "any"} {set cmd [concat $cmd -a]}
        if {$midi(match_method) == "con"} {set cmd [concat $cmd -con]}
        if {$midi(match_method) == "qcon"} {set cmd [concat $cmd "-con -qcon"]}
        catch {eval $cmd} result
        set exec_out $cmd\n$result
        set matchlist [split $result \n"]
        record_matched_tunes [file join $midi(searchdir) $filename] 1
        if {$stopsearch} break;
        set gfiles($i) $filename
        incr i
        update
    }
    stop_matcher
    update_console_page
}


proc record_matched_tunes {filename minlength} {
    # for each tune in matchlist, if there are more than or equal
    # to minlength matched bars, the tune is copied to the .matcher.notice.t
    # window and the matched bars are highlighted.
    global matchlist mlocator
    set lastxref -1
    set abchandle [open $filename r]
    foreach matchpair $matchlist {
        set matches [lrange $matchpair 2 [llength $matchpair]]
        if {[llength $matches] < $minlength} continue
        set xref [lindex $matchpair 1]
        if {[string is integer $xref] != 1} continue
        set mlocator [lindex $matchpair 0]
        if {$xref != $lastxref} {
            find_xref_in_file $abchandle $xref $filename
            highlight_selected_bars $matches
            set lastxref $xref
            
        }
    }
    close $abchandle
}




proc copy_tune {abchandle} {
    # copies tune from file and locates all bar lines in
    # body which are stored in the array barloc
    global barloc df
    set line [gets $abchandle]
    set bcount 1;
    .matcher.notice.t tag configure bl  -foreground red
    .matcher.notice.t insert end $line\n
    set p {\|+}
    if {[info exist barloc]} {unset barloc}
    while {[string length $line] > 0 } {
        set line  [gets $abchandle]
        if {[string index $line 0] == "X"} break;
        .matcher.notice.t insert end $line
        
        set initial [string index $line 0]
        set next [string index $line 1]
        if {[string first $initial ABCDEFGHIKLMNOPQRSTUVWwXZ]
            >= 0 && $next == ":" } {
            .matcher.notice.t insert end \n
            continue
        }
        
        set begin 0
        set result 1
        set index [.matcher.notice.t index "end -1 char"]
        set linenum [lindex [split $index .] 0]
        while {$result} {
            set result [regexp -start $begin -indices $p $line loc]
            if {$result} {set begin [lindex $loc 1]
                set barloc($bcount) $linenum.$begin
                if {$bcount==1} {set barloc(0) $linenum.0}
                incr begin
                incr bcount
            }
        }
        .matcher.notice.t insert end \n
    }
}


proc highlight_selected_bars {bars} {
    global barloc
    .matcher.notice.t tag configure bl  -foreground red
    foreach bar $bars {
        if {[string is integer $bar] == 0} break;
        set bar2 [expr $bar + 1]
        if {[info exist barloc($bar2)]} {
            .matcher.notice.t tag add bl $barloc($bar) $barloc($bar2)
        }
    }
}




proc find_xref_in_file {abchandle xref filename} {
    # for the tune with reference number xref, the tune is
    # copied to the .matcher.notice.t text box
    global match_index
    global mlocator
    while {[gets $abchandle line] >= 0 } {
        set initialchar [string index $line 0]
        if {[string equal $initialchar X]} {
            set number [string range $line 2 10]
            if {$number == $xref} {
                .matcher.notice.t tag configure m$match_index -foreground darkblue
                .matcher.notice.t insert end  %$filename\n m$match_index
                .matcher.notice.t tag bind m$match_index <1> "show_match_file [list $filename] $xref"
                incr match_index
                .matcher.notice.t insert end \n$line\n
                copy_tune $abchandle
                break}
        }
    }
}


#set types {{{abc files} {*.abc}}
#           {{all} {*}}}

proc match_file_browser {} {
    global types midi
    set filename [tk_getOpenFile -filetypes $types]
    if {[string length $filename] > 0} {set midi(searchdir) $filename}
}

proc match_dir_browser {} {
    global midi
    set filename  [tk_chooseDirectory]
    if {[string length $filename] > 0} {set midi(searchdir) $filename}
}



proc show_match_file {filename loc} {
    global midi
    global item_id
    global locator
    if {$loc < 0} return
    open_abc_file $filename
    .abc.titles.t selection set {}
    #set toc_index $item_id($locator($loc))
    set toc_index $item_id([expr $loc -1])
    .abc.titles.t selection set $toc_index
    .abc.titles.t focus $toc_index
    .abc.titles.t see $toc_index
    update
}


proc transfer_editor_buffer_to_abcmatch {} {
    global midi
    global body_start body_end
    global abctxtw
    if {[winfo  exist .abcedit] == 0} {
        messages "You need to run TclAbcEditor\
                and highlight several complete bars of the music body\
                of a specific tune before using this function."
        return
    }
    
    set selrange [$abctxtw tag ranges sel]
    if {[llength $selrange] < 2} {
        messages "Please select an area in the body of the tune \
                and then try again. To select a region, hold the left mouse button \
                down and sweep an area."
        return
    } else {
        set selstart [lindex $selrange 0]
        set selend [lindex $selrange 1]
        set value [$abctxtw get $selstart $selend]
        set value [remove_guitar_chords $value 0]
        set value [remove_grace_notes $value 0]
        # throw out \n
        set value [string map {\n \040} $value]
        set midi(match_body) $value
        
        set point [$abctxtw index insert]
        if {$point > $body_end} {set point $body_start.0}
        set kfield [$abctxtw search -backwards K: $point]
        set kfield [$abctxtw get $kfield  "$kfield lineend"]
        set midi(match_keysig) [string range $kfield 2 end]
        set lfield [$abctxtw search -backwards L: $point]
        if {[string length $lfield] > 0} {
            set lfield [$abctxtw get $lfield  "$lfield lineend"]
            set midi(match_length) [string range $lfield 2 end]
        } else {
            set midi(match_length) 1/8}
        
        
        set mfield [$abctxtw search -backwards M: $point]
        set mfield [$abctxtw get $mfield  "$mfield lineend"]
        set midi(match_timesig) [string range $mfield 2 end]
        match_window
    }
}



proc play_match.abc {} {
    global midi exec_out
    global files
    set dir "[pwd]/$midi(midi_dir)"
    set cmd "file delete [glob -nocomplain $dir/X*.mid]"
    catch {eval $cmd}
    set out_fd [open $midi(midi_dir)/X.tmp w]
    puts $out_fd "X: 1"
    write_midi_codes $out_fd
    puts $out_fd "M: $midi(match_timesig)"
    puts $out_fd "L: $midi(match_length)"
    puts $out_fd "K: $midi(match_keysig)"
    puts $out_fd "$midi(match_body)\n"
    close $out_fd
    set cmd "exec $midi(path_abc2midi) $midi(midi_dir)/X.tmp"
    catch {eval $cmd} exec_out
    set exec_out $cmd\n\n$exec_out
    set files $midi(midi_dir)/X1.mid
    play_midis 1
}


proc dump_to_abc {} {
    global types midi
    set filename [tk_getSaveFile -filetypes $types]
    set line ""
    if {$filename != ""} {
        set outhandle [open $filename w]
        puts $outhandle X:100000
        puts $outhandle "T:Matcher Input"
        puts $outhandle "N: abcmatcher output at [clock format [clock seconds]] using"
        puts $outhandle  "M:$midi(match_timesig)"
        puts $outhandle  "L:$midi(match_length)"
        puts $outhandle  "K:$midi(match_keysig)"
        puts $outhandle  "$midi(match_body)\n\n"
        foreach {key value index} [.matcher.notice.t  dump -text 1.0 end] {
            set value [string trimright $value "\n"]
            #a matching bar is tagged and sent in a separate line.
            #we need  to combine those lines
            set charnum [lindex [split $index .] 1]
            if {$charnum == 0} {
                puts $outhandle $line
                set line $value} else {
                set line $line$value}
        }
        puts $outhandle $line
        close $outhandle
        if {$midi(bell_on)} bell
    }
}


set hlp_match \
        "This function searches for any tune having music bars with\
        a specific pattern. The search is performed on either a specific\
        abc file (which is usually a compilation of many tunes) or on a\
        folder containing abc files. The file or folder is specified in\
        the path entry box. The browse button allows you to use the tcl/tk\
        file browser to search for the file, but unfortunately it does not\
        allow you to specify  a folder. (It is necessary to edit the\
        contents of the path entry box to specify a folder.) If you\
        specify a folder, the program will search recursively for all abc\
        files starting from this folder.\n\nTo specify the music pattern\
        that you are searching for, you edit the contents of the K: M: L:\
        and body entry boxes. The contents of the first three boxes are\
        identical to the corresponding field entries in an abc formated file.\
        The body should contain 1 or a few complete bars. It is not necessary\
        to start a bar with a bar line, but the last bar must end with a\
        bar line.\n\nClicking the `play' button allows you to hear the bar or\
        bars that you have specified. The button labeled `transfer' allows\
        you to fill in the K: M: L: and body fields rapidly, assuming that\
        the specific bar or bars is already highlighted in a the tcl abc\
        editor (called TclAbcEditor). Thus you are able to search for\
        other tunes which include those highlighted bars. When you transfer\
        these highlighted bars, guitar chords and grace notes are automatically\
        removed. The searching function ignores this information as well as\
        decorations, slurs and rolls. Instead of clicking the transfer button\
        you may also use the <Alt-t> key when the focus is on the abcedit\
        window.\n\nIt is possible to transfer the entire body of the tune\
        to the entry box. New lines are automatically converted to spaces so\
        the text string can be read properly in the runabc.ini file.\
        Though not everything is visible, the horizontal\
        scroll bar below allows you to scroll through the entry box.\n\n\
        To start the matching process click\
        the button labeled `match'. Matches will appear in a scrolled text\
        window appearing below and all bars that match the criterion will be\
        displayed in red. In addition the file where the match occurred will\
        appear above in blue. If you click on the blue file name, then the\
        selected tune will be loaded into the table of contents window and\
        the specific tune will be selected and centered in that window. This\
        allows you to get to that tune rapidly, assuming you wish to either\
        display the music notation or play the tune.\n\nOther menu buttons such\
        as resolution, and method, control how the matching process is\
        performed. They allow you to perform an exact or loose match and are\
        explained in detail in the documentation included with the abcmatch.zip\
        distribution.\n\nIf you plan to analyze the results in detail, it\
        may be convenient to save all the output in an abc format file. You\
        can do this by clicking on the  button 'save results'. You can\
        then open this file like any other regular abcfile."

#end of abcmatch.tcl



# Part 17.0              Grouper interface


#beginning of source grouper.tcl


proc grouper_window {} {
    global midi df hlp_grouper
    if {[check_abcmatch_version 1.35] == 0} return
    set f .grouper
    if {[winfo exist $f]} return
    toplevel $f
    frame $f.1
    label $f.1.inputfilelab -text "input file" -font $df
    entry $f.1.inputfilevar -width 50 -textvariable midi(abc_open) -font $df
    bind $f.1.inputfilevar <Return> {focus .grouper.1.inputfilelab
        run_grouper}
    button $f.1.filebrowse -text browse -font $df -command file_browser
    pack $f.1.inputfilelab $f.1.inputfilevar $f.1.filebrowse -side left -anchor w
    pack $f.1 -anchor w
    frame $f.2
    button $f.2.start -text group -font $df -command run_grouper
    label $f.2.minthr -text "min bars" -font $df
    scale $f.2.thresh -from 1 -to 10 -length 80 -width 10 \
            -orient horizontal  -showvalue true -variable midi(grouper_thresh) \
            -font $df
    button $f.2.save -text "save output" -font $df -command dump_grouper_output
    button $f.2.help -text help -font $df\
            -command {
                show_message_page $hlp_grouper word
                focus .abc
                raise .abc}
    pack $f.2.start $f.2.minthr $f.2.thresh $f.2.save\
            $f.2.help -side left -anchor w
    pack $f.2 -anchor w
    frame $f.msg
    label $f.msg.lab -width 60 -text "" -font $df
    pack $f.msg.lab -side left
    pack $f.msg -side top
    update
}


proc pop_grouper_results {} {
    global df
    set p .grouper.notice
    if [winfo exist .grouper.notice] {
        $p.t configure -state normal
        $p.t delete 1.0 end
    } else {
        frame $p
        text $p.t -height 25 -width 70 -wrap word -yscrollcommand {.grouper.notice.ysbar set} -font $df
        scrollbar $p.ysbar -orient vertical -command {.grouper.notice.t yview}
        pack $p.ysbar -side right -fill y -in $p
        pack $p.t -in $p
        pack $p}
    update
}



proc grouper_title_index {abcfile} {
    global fileseek tuneid
    
    set srch X
    #   i is the next file sequence number to search for X:
    #   when found we save it in i1 and incr i for next search
    #   We do it this way because a few tunes do not have a
    #   T: or P: indication (see John Chamber's site, maybe
    #   it is fixed by now :-) ).
    set i  0
    set pat {[0-9]+}
    set titlehandle [open $abcfile r]
    set fileseek(0) 0
    while {[gets $titlehandle line] >= 0} {
        if {[string length $line] < 1} {set srch X}
        switch -- $srch {
            X {if {[string compare -length 2 $line "X:"] == 0} {
                    regexp $pat $line  number
                    set srch T
                    set i1 $i
                    incr i
                    set tuneid($i1) ""
                } else {
                    set fileseek($i) [tell $titlehandle]}
            }
            T {
                if {[string index $line 0] == "T" || [string index $line 0] == "P"} {
                    set name [string range $line 2 end]
                    set name [string trim $name]
                    set tuneid($i1) [format "%s %s" $number $name]
                    set srch X
                }
            }
        }
    }
    close $titlehandle
    return $i
}



proc list_titles {n} {
    global fileseek tuneid
    for {set i 0} {$i <$n} {incr i} {
        puts "$fileseek($i) $i $tuneid($i)"
    }
}

proc start_grouper {} {
    global stopgrouper
    set stopgrouper 0
    .grouper.2.start configure -text stop -command stop_grouper
    update
}

proc stop_grouper {} {
    global stopgrouper
    set stopgrouper 1
    .grouper.2.start configure -text group -command run_grouper
}


proc create_matcher_template_for {grouper_handle seqno} {
    #overwrite match.abc file with the next tune
    global fileseek
    seek $grouper_handle $fileseek($seqno)
    set line [get_nonblank_line $grouper_handle]
    set outhandle [open match.abc w]
    #   replace xrefno with sequence number for match.abc in case
    #   they are not in sequence in abcfile.
    puts $outhandle "X: $seqno"
    while {[string length $line] > 0} {
        set line [get_nonblank_line $grouper_handle]
        if {[string index $line 0] == "X"} break;
        puts $outhandle $line
    }
    puts $outhandle ""
    close $outhandle
}


proc group_tunes {n abcfile} {
    global fileseek tuneid midi
    global stopgrouper
    set p .grouper.notice
    start_grouper
    set cmd "exec [list $midi(path_abcmatch)] [list $abcfile] -br $midi(grouper_thresh)"
    pop_grouper_results
    set grouper_handle [open $abcfile r]
    for {set i 0} {$i <$n} {incr i} {
        if {$stopgrouper} break
        create_matcher_template_for $grouper_handle $i
        .grouper.msg.lab configure -text "$i/$n $tuneid($i)"
        update
        # now run abcmatch.exe
        catch {eval $cmd} result
        
        # grab the output of abcmatch.exe if any and
        # convert it into a list.
        if {[string length $result] > 0} {
            set grouplist [split $result \n]
            set mbars [lindex $result 0]
            # display the output in a text window.
            $p.t insert end "\nfor $tuneid($i) ($mbars bars)   "
            $p.t tag configure m$i -foreground darkblue
            $p.t tag bind m$i <1> "grouper_findbars_for $i"
            $p.t insert end details\n m$i
            set grouplist [lrange $grouplist 1 end]
            set k 0
            foreach item $grouplist {
                set xref [lindex $item 0]
                set count [lindex $item 1]
                $p.t insert end "$tuneid($xref) ($count bars)\n"
                incr k
                if {$k > 30} {$p.t insert end "   and etc......\n"
                    break;
                }
            }
        }
        update
    }
    stop_grouper
    close $grouper_handle
}

proc grouper_findbars_for {seqno} {
    global midi
    global matchlist
    global match_index
    global exec_out
    match_window
    set match_index 0
    set cmd "exec [list $midi(path_abcmatch)]  [list $midi(abc_open)] -r 0 -a"
    set grouper_handle [open $midi(abc_open) r]
    create_matcher_template_for $grouper_handle $seqno
    catch {eval $cmd} result
    set exec_out "$cmd\n$result"
    set matchlist [split $result \n"]
    pop_matcher_results
    record_matched_tunes $midi(abc_open) $midi(grouper_thresh)
}


proc run_grouper {} {
    global midi
    set ntunes [grouper_title_index $midi(abc_open)]
    #              list_titles $ntunes
    group_tunes $ntunes $midi(abc_open)
}



proc dump_grouper_output {} {
    global types midi
    set filename [tk_getSaveFile -filetypes $types]
    set line ""
    if {$filename != ""} {
        set outhandle [open $filename w]
        puts $outhandle "grouper output at [clock format [clock seconds]]\nfor $midi(abc_open)"
        foreach {key value index} [.grouper.notice.t  dump -text 1.0 end] {
            set charnum [lindex [split $index .] 1]
            set line [string trimright $value "\n"]
            if {$charnum == 0} {puts $outhandle $line}
        }
        close $outhandle
        if {$midi(bell_on)} bell
    }
}


set hlp_grouper \
        "Given a file composed of a collection of abc tunes, the function\
        is designed to identify groups of tunes sharing common bars of music.\
        It is useful for identifying duplicates, or groups of tunes that\
        may form a medley.\n\n Essentially, the function runs \
        abcmatch repeatedly on every tune in the file. For each tune the\
        entire body of the tune is made a template and compared with\
        all the tunes in the file. The number of bars in the tune\
        that are common with the template are counted. If the number is\
        greater than a threshold then that tune is reported as well as\
        the number of common bars. This threshold may be adjusted using\
        the scale widget labeled 'min bars'. The threshold controls the\
        amount of output.  When the number of common bars\
        is almost equal to the number of bars in the template tune,\
        it is likely that the tunes are the same. Otherwise, the\
        tunes probably share similar nuances. The button labeled\
        'save results' allows you to save the output of this function\
        in a separate text file.\n\n Some of the bars\
        may be very simple (eg. one note) and matches everything,\
        so there may be a lot of false positives.\n\n The 'input file' entry\
        box is linked to the entry box in the runabc window so modifying\
        its contents also modifies the other box.\n\nIf you click on the\
        blue text marked details, then the group of tunes will be displayed\
        in a separate window labeled matcher (the same one used by find bars)\
        and all the matching bars will be highlighted in red. Essentially,\
        the find bars function is run using the selected tune as a template\
        on the active file. The function is not run with the same parameters\
        indicated in the matcher window so the output is not the same that\
        you would get if you clicked on the match button on the matcher window."

#end of source grouper.tcl



# Part 18.0                  Diagnostic Support Functions


#source diag.tcl
#Check configuration of runabc

bind . <Alt-s> {runabc_diagnostic}
bind . <Alt-S> {runabc_diagnostic}

set abcmidilist {path_abc2midi 2.76\
            path_abc2abc 1.65\
            path_yaps 1.52\
            path_midi2abc 2.91\
            path_midicopy 1.08\
            path_abcmatch 1.42}
global abcmidilist

proc runabc_diagnostic {} {
    global midi
    global tcl_platform
    global abcmidilist
    set diag_output [open  runabc.out   w ]
    set plat $tcl_platform(platform)
    set os $tcl_platform(os)
    set osver $tcl_platform(osVersion)
    set machine $tcl_platform(machine)
    set tclversion [info tclversion]
    set msg [format "runabc version $midi(version) running on $machine $plat/$os $osver tcl/tk $tclversion\n"]
    puts $diag_output $msg
    set msg  "The current directory is [pwd]"
    puts $diag_output $msg
    set msg "The program [info nameofexecutable] is running"
    puts $diag_output $msg
    set msg "The script [info script] is running"
    puts $diag_output $msg
    set msg "\nThe following verifies the existence of an executable at
    the specific location specified in the config/executables property
    sheet. Note that executable may still be accessible using the
    PATH environment variable if only the filename is given.\n\n"
    puts $diag_output $msg
    
    foreach {path ver} $abcmidilist {
        set msg "$midi($path)\t [get_version_number $midi($path)]\t$ver"
        puts $diag_output $msg}
    foreach path {path_abc2ps path_abcm2ps path_gs path_midiplay} {
        set msg "$midi($path)\t\t [check_file $path]"
        puts $diag_output $msg}
    
    close $diag_output
    messages "Results of the sanity check are recorded in the\
            file runabc.out. You may view these results using any text\
            editor or word processor."
    show_checkversion_summary
}


proc show_checkversion_summary {} {
    global abcmidilist
    global midi
    set p .summary
    if [winfo exist $p] {.summary.t delete 1.0 end} else make_summary_toplevel
    foreach {path ver} $abcmidilist {
        set msg "$midi($path)\t [get_version_number $midi($path)]\t$ver"
        $p.t insert end "$msg\n"
    }
}


#end of diag.tcl


startup_progress "loading extract functions"




# Part 19.0           Abc Editor Filter functions


# filter.tcl
# includes various filters first implemented by
# Luis Pablo Gasparotto

proc remove_voice_fields {buffer dummy} {
    regsub -all {(\[)( )*(V:)( )*([0-9]+)( )*(\])} $buffer {} result
    return $result
}

proc remove_backslashes {buffer dummy} {
    regsub -all {\\} $buffer { } result
    return $result
}

proc remove_tab_chars {buffer dummy} {
    regsub -all \t $buffer { } result
    return $result
}

proc interp_M_field {line} {
    set pattern {(M:)( )*([0-9]+)*([/])*([0-9]+)}
    if { [regexp $pattern $line meas_line meas1 white num meas2 den] == 1 } {
        return [list $num $den]} else {return [list 4 4]}
}


proc interp_L_field {line} {
    set pattern {(L:)( )*([0-9]+)*([/])*([0-9]+)}
    if { [regexp $pattern $line beat_line beat1 white num beat2 den] == 1 } {
        return [list $num $den]} else {return [list 1 8]}
}


proc compute_bar_rest {Lfield Mfield} {
    set Lnum [lindex $Lfield 0]
    set Lden [lindex $Lfield 1]
    set Mnum [lindex $Mfield 0]
    set Mden [lindex $Mfield 1]
    set duration [expr $Lden * $Mnum / $Lnum / $Mden]
    return $duration
}


proc multi_rests_nz2Z {line dummy} {
    set pattern {(\")([0-9]+)(\")(z)([0-9]+)}
    while { [regexp $pattern $line mr_string sign1 meas_num sign2 \
                sign3 sign4] == 1 } {
        regsub {(\")([0-9]+)(\")(z)([0-9]+)} $line "Z$meas_num" line}
    return $line
}


proc whole_rest_from_region {start end} {
    #search backwards for any L: or M:
    global abctxtw
    global L_field M_field
    set Lpos [$abctxtw search -backwards L: $start 1.0]
    if {[string length $Lpos] > 0} {
        set Lline [$abctxtw get $Lpos "$Lpos lineend"]
        set L_field [interp_L_field $Lline]
    } else {set L_field [list 1 8]}
    set Mpos [$abctxtw search -backwards M: $start 1.0]
    if {[string length $Mpos] > 0} {
        set Mline [$abctxtw get $Mpos "$Mpos lineend"]
        set M_field [interp_M_field $Mline]
    } else {set M_field [list 4 4]}
    set whole_rest z[compute_bar_rest $L_field $M_field]
}

proc update_rest_duration {line} {
    #checks for an M: or L: field in the body line and
    #updates these fields and recomputes rest_duration.
    global L_field M_field
    set patternM {(M:)( )*([0-9]+)*([/])*([0-9]+)}
    set patternL {(L:)( )*([0-9]+)*([/])*([0-9]+)}
    set update 0
    if {[regexp $patternL $line] == 1} {set L_field [interp_L_field $line]
        incr update}
    if {[regexp $patternM $line] == 1} {set M_field [interp_M_field $line]
        incr update}
    set duration [compute_bar_rest $L_field $M_field]
    if {$update >0} {return $duration}
    return 0
}


proc multi_rests_Z2nz {region dummy} {
    global abctxtw
    set update 0
    set pattern {(Z)([0-9]+)}
    set start [lindex $region 0]
    set end   [lindex $region 1]
    set whole_rest [whole_rest_from_region $start $end]
    set lstart [expr int($start)]
    set lend   [expr int($end)]
    for {set linenum $lstart} {$linenum <= $lend} {incr linenum} {
        set line [$abctxtw get $linenum.0 "$linenum.0 lineend"]
        set ret [update_rest_duration $line]
        if {$ret} {set whole_rest z$ret}
        while  { [regexp $pattern $line mr_string meas_type meas_num] == 1 } {
            regsub {(Z)([0-9]+)} $line "\"$meas_num\"$whole_rest" line
            incr update
        }
        if {$update} {
            $abctxtw delete $linenum.0 "$linenum.0 lineend"
            $abctxtw insert $linenum.0  $line
        }
    }
}

proc remove_blank_lines {blanks} {
    # removes blank lines starting with last line number in list
    global abctxtw
    set size [llength $blanks]
    if {$size < 1} return
    incr size -1
    for {set i $size} {$i >= 0} {incr i -1} {
        set line [lindex $blanks $i]
        set pos $line.0
        $abctxtw delete $pos "$pos lineend+1 char"
    }
}

proc edit_condense_whole_rests  {region type} {
    #condense a sequence of whole rests to one bar.
    #this version is called by TclAbcEditor
    global cond_output_buffer cond_measures cond_running
    global wr_length whole_rest
    global abctxtw
    set blanks {}
    set start [lindex $region 0]
    set end   [lindex $region 1]
    set whole_rest [whole_rest_from_region $start $end]
    set wr_length [string length $whole_rest]
    set lstart [expr int($start)]
    set lend   [expr int($end)]
    set cond_running 0
    for {set linenum $lstart} {$linenum <= $lend} {incr linenum} {
        set line [$abctxtw get $linenum.0 "$linenum.0 lineend"]
        set ret [update_rest_duration $line]
        if {$ret} {set whole_rest z$ret}
        if { [string match *$whole_rest* $line] != 1 } continue
        set output_line [condense_line $line $type]
        $abctxtw delete $linenum.0 "$linenum.0 lineend"
        if {[string length $output_line] > 0} {
            $abctxtw insert $linenum.0 $output_line
        } else {
            set blanks [concat $blanks $linenum]
        }
    }
    remove_blank_lines $blanks
}

proc condense_whole_rest {buffer type} {
    #condense a sequence of whole rests to one bar.
    #this version is called by extract_action
    global midi
    global cond_running
    global L_field M_field
    global wr_length whole_rest
    set whole_rest z8
    set L_field [list 1 8]
    set M_field [list 4 4]
    set wr_length [string length $whole_rest]
    set cond_running 0
    set outfile [open $midi(abc_default_file) w]
    set music [split $buffer \n]
    foreach line $music {
        set ret [update_rest_duration $line]
        if {$ret} {set whole_rest z$ret}
        if {$type >= 0} {set outline [condense_line $line $type]} else {
            set outline $line}
        if {[string length $outline] > 0} {puts $outfile $outline}
        if {[string length $line] == 0} {puts $outfile $line}
    }
    close $outfile
}


proc condense_line {line type} {
    # The function processes a single line of abc tune, character
    # by character. If no whole rest is found, the function
    # just returns the same line back. If it detects a whole rest
    # then it sets the global variable cond_running to 1 to indicate that
    # it is now in the mode of counting bars with whole rests. Nothing
    # is returned while it is in this mode. There are various
    # rules for breaking a sequence of whole rests. When the
    # sequence is broken, the function returns back to the mode
    # cond_running 0. The various global variables are used
    # to maintain the state of the function between calls.
    #
    global cond_output_buffer cond_measures cond_running
    global wr_length whole_rest multimeasures barline
    set strlength [string length $line]
    if {$cond_running == 0} {
        set cond_output_buffer ""
    }
    set i 0
    while {$i < $strlength} {
        if {$cond_running == 0} {
            if  {[string range $line $i [expr $wr_length+$i-1]] == $whole_rest \
                        &&  [string index $line [expr $i-1] ] != "\"" \
                        &&  [string index $line [expr $i-1] ] != "!" } {
                set cond_running 1
                set i [expr $i + $wr_length]
                set barline "|"
                set cond_measures 1
                set multimeasures 1
            } else  {
                set cond_output_buffer $cond_output_buffer[string index $line $i ]
            }
        }
        # end of initialization after first whole_rest
        
        if {$cond_running == 1} {
            while {$multimeasures != 0 && $i < $strlength} {
                set multimeasures -1
                if {[string index $line $i] == "\\"} {incr i; continue}
                if {[string index $line $i] == "|"} {set multimeasures 1}
                # check for bar lines which break sequence
                set token [string range $line $i [expr $i +1]]
                if {$token == ":|" || $token == "|:" || $token == "||" || $token == "|]"} {
                    set barline $token
                    set multimeasures 0
                    incr i
                }
                # pass over spaces and tabs
                if {[string is space [string index $line $i]]} {
                    set multimeasures 1
                }
                # check for another whole_rest
                if { [string range $line $i [expr $i+$wr_length-1]] == $whole_rest } {
                    incr cond_measures
                    set multimeasures  $wr_length
                }
                # anything else breaks the sequence
                if {$multimeasures < 0} {
                    incr i -1
                    set multimeasures 0
                }
                incr i $multimeasures
            }
            # finished scanning either because we got to the end of the line or the
            # whole note sequence was broken. If multimeasures is non zero then we
            # we have a multirest to output.
            if {$multimeasures == 0} {
                if {$cond_measures != 1} {
                    if {$type} {
                        set cond_output_buffer $cond_output_buffer\"$cond_measures\"$whole_rest } else {
                        set cond_output_buffer $cond_output_buffer\Z$cond_measures}
                } else {
                    set cond_output_buffer $cond_output_buffer$whole_rest
                }
                
                # Adding a barline closing the multimeasure rest
                if { $barline == ":|" || $barline == "|:" || $barline == "||" || $barline == "|]" } {
                    set cond_output_buffer "$cond_output_buffer $barline"
                } elseif { $barline == "|" } {
                    set cond_output_buffer "$cond_output_buffer $barline"
                }
            }
            # finished multirest output.
            ####### puts "output: $cond_output_buffer"
            if {$multimeasures == 0} {set cond_running 0}
            #end cond_running == 1
        }
        
        incr i
        #######puts $cond_output_buffer
    }
    #end of loop over line
    #######puts "$cond_running final output: $cond_output_buffer"
    if {$cond_running == 0} {return $cond_output_buffer}
}


proc extract_action {action} {
    global midi df
    global abc2abc_e extract_t extract_v
    
    set abc2abc_opt ""
    if {$abc2abc_e} {append abc2abc_opt "-e "}
    append abc2abc_opt "-t $extract_t "
    append abc2abc_opt "-V $extract_v "
    copy_selection_to_file [title_selected] $midi(abc_open) $midi(midi_dir)/X.tmp
    if {![file exist $midi(path_abc2abc)]} {messages "can't find $midi(path_abc2abc)"}
    set cmd "exec $midi(path_abc2abc) $midi(midi_dir)/X.tmp $abc2abc_opt"
    catch {eval $cmd} exec_out
    .abc.extract.5 configure -font $df -text $cmd
    
    # we have to call condense_whole_rest even if it does nothing (with type = -1)
    # because it sends the output to edit.abc. If condense indeed does its job, be sure
    # there are no voice fields in the body line.
    set type $midi(condense_method)
    if {$midi(condense_on) == 0} {set type -1} else {
        set midi(remove_voice) 1}
    
    # If condense method is in automatic mode, then select the multirest respresentation
    # which suits the postscript file creator.
    if {$midi(condense_method) == 2 && $midi(condense_on)} {
        if {$midi(ps_creator) == "abc2ps" } {set type 1}
        if {$midi(ps_creator) == "abcm2ps"} {set type 0}
    }
    
    if {$midi(remove_voice)} {set exec_out [remove_voice_fields $exec_out 0]}
    if {$midi(remove_backslashes)} {set exec_out [remove_backslashes $exec_out 0]}
    condense_whole_rest $exec_out $type
    switch -- $action {
        display {display_tunes_thru_x_tmp $midi(abc_default_file)}
        edit    {tcl_abc_edit $midi(abc_default_file) 1}
        save    {set_abc_save
            file rename -force $midi(abc_default_file) $midi(abc_save)}
    }
    update_console_page
}

startup_progress "loading bar align functions"



#Part 20.0             Bar Alignment


# bar_align.tcl
#The procedures attempt to line up the bar lines and music
#
# The abc tune is stored in the text structure
# $abctxtw. which is scanned and modified by
# bar_align.
#
# Important variables:
# music_start, numbars and linebar are arrays
# indexed by the line number in the text structure.
# numbars stores the number of barlines or | in each line
# linebar stores a list of the position of barlines for each line
# music_start indicates the position where the music begins
# ignoring | , |: or |[.
#
# Algorithm:
# -We scan $abctxtw locating the bar lines and
# begining of music for each abc line.
# -We find the maximum amount the music is indented
# far all  the abc text lines and then indent
# all the music lines by this amount.
# Going left to right we start aligning the bar
# lines for all the music. i.e. We line up the
# first bar line for all the music, then the second
# bar line etc. We can only shift a bar line to
# right by adding blanks just before the bar line.
# Whenever we insert spaces in the abc line
# all the bar lines in linebar get shifted so
# we need update the linebar list.
#
proc bar_align {} {
    global music_start numbars linebar
    global abctxtw
    set keypat {[^|: ]}
    set index [$abctxtw index "end -1 char"]
    set lines [lindex [split $index .] 0]
    # for each line count number of bars, store their position and
    # find start of music notes or chords indications
    for {set line 1} {$line < $lines} {incr line} {
        set nbars 0
        set barloc ""
        set loc [$abctxtw search "|" $line.0 $line.end]
        set firstsym [$abctxtw search -regexp $keypat $line.0 $line.end]
        set firstsym [lindex [split $firstsym .] 1]
        while {[llength $loc] > 0} {
            set barpos [lindex [split $loc .] 1]
            if {$barpos > $firstsym} {
                set barloc [concat $barloc $barpos]
                incr nbars
            }
            set loc [$abctxtw search "|" "$loc+1 chars" $line.end]
        }
        set linebar($line) $barloc
        set music_start($line) $firstsym
        set numbars($line) $nbars
    }
    # Now indent all music so they start on the same column
    set maxindent [music_indent $lines]
    indent_music $lines $maxindent
    # Get the position where we shall align the first barline
    # for all lines
    set align_pos [next_bar_pos $lines]
    # Now loop as long as we have bar lines to align
    while {$align_pos > 0} {
        align_next_bar $lines $align_pos
        remove_next_bar $lines
        set align_pos [next_bar_pos $lines]
    }
}

proc music_indent {lines} {
    # determines the number of spaces to indent the music
    global music_start numbars
    set maxindent 0
    for {set line 1} {$line < $lines} {incr line} {
        if {$numbars($line) > 0} {
            if {$music_start($line) > $maxindent} {set maxindent $music_start($line)}
        }
    }
    return $maxindent
}


proc indent_music {lines numchar} {
    # indent the music by numchar spaces
    global numbars music_start linebar
    global abctxtw
    for {set line 1} {$line < $lines} {incr line} {
        if {$numbars($line) > 0} {
            set numblanks [expr $numchar - $music_start($line)]
            if {$numblanks > 0} {
                set pos $line.$music_start($line)
                $abctxtw insert $pos [string repeat " " $numblanks]
                set linebar($line) [add_num_to_list $numblanks $linebar($line)]
            }
        }
    }
}

proc add_num_to_list {num numlist} {
    set newlist {}
    foreach val $numlist {
        set val [expr $num+$val]
        set newlist [concat $newlist $val]
    }
    return $newlist
}

proc next_bar_pos {lines} {
    # Finds the maximum of the first entry of all
    # the lists.
    global numbars linebar
    set maxloc 0
    for {set line 1} {$line < $lines} {incr line} {
        if {$numbars($line) > 0} {
            set loc [lindex $linebar($line) 0]
            if {$loc > $maxloc} {set maxloc $loc}
        }
    }
    return $maxloc
}

proc align_next_bar {lines bar_align_pos} {
    # Insert spaces in each abc line before the barline
    # if necessary for aligning.
    global numbars linebar
    global abctxtw
    for {set line 1} {$line < $lines} {incr line} {
        if {$numbars($line) > 0} {
            set loc [lindex $linebar($line) 0]
            set loc1 [expr $loc -1]
            if {[$abctxtw get $line.$loc1] == ":"} {set loc $loc1}
            if {$loc < $bar_align_pos} {
                set numblanks [expr  $bar_align_pos -$loc]
                set pos $line.$loc
                $abctxtw insert $pos [string repeat " " $numblanks]
                set linebar($line) [add_num_to_list $numblanks $linebar($line)]
            }
        }
    }
}

proc remove_next_bar {lines} {
    # Removes the first entry from a list.
    global numbars linebar
    for {set line 1} {$line < $lines} {incr line} {
        if {$numbars($line) > 0} {
            incr numbars($line) -1
            set linebar($line) [lreplace $linebar($line) 0 0]
        }
    }
}

proc bar_squeeze {} {
    global abctxtw
    set pat "\[ \]+"
    set index [$abctxtw index "end -1 char"]
    set lines [lindex [split $index .] 0]
    # for each line replace multiple spaces with single space
    for {set line 1} {$line < $lines} {incr line} {
        set value [$abctxtw get $line.0 $line.end]
        regsub -all $pat $value " " result
        $abctxtw delete $line.0 $line.end
        $abctxtw insert $line.0 $result
    }
    tag_text
}


# Part 21.0           Console Page Support Functions

#source warning.tcl

proc update_console_page {} {
    global exec_out
    if {[winfo exist .notice]} {show_console_page $exec_out char}
}

proc show_console_page {text wrapmode} {
    global active_sheet df
    #remove_old_sheet
    set p .notice
    set pat1 {Error in line ([0-9]+)}
    set pat2 {Warning in line ([0-9]+)}
    if [winfo exist .notice] {
        $p.t configure -state normal -font $df
        $p.t delete 1.0 end
        set taglist [$p.t tag names]
        foreach t $taglist {$p.t tag delete $t}
    } else {
        toplevel $p
        text $p.t -height 15 -width 50 -wrap $wrapmode -font $df -yscrollcommand {
            .notice.ysbar set}
        scrollbar $p.ysbar -orient vertical -command {.notice.t yview}
        pack $p.ysbar -side right -fill y -in $p
        pack $p.t -in $p -expand true -fill both
    }
    $p.t tag configure grey -background grey80
    set textlist [split $text \n]
    set lkount 1
    foreach textline $textlist {
        set ln 0
        if {[regexp $pat1 $textline result sub]} {set ln $sub}
        if {[regexp $pat2 $textline result sub]} {set ln $sub}
        if {$ln} {
            $p.t tag configure m$lkount -foreground darkblue
            $p.t insert end $textline\n m$lkount
            $p.t tag bind m$lkount <1> "highlight_line $lkount $ln"
        } else {
            $p.t insert end $textline\n
        }
        incr lkount
    }
    #$p.t configure -state disabled
    #set active_sheet notice
    #pack $p
    raise $p .
}

proc highlight_line {line1 line2} {
    .notice.t tag remove grey 0.0 end
    .notice.t tag  add grey $line1.0 $line1.end
    highlight_xtmp_line $line2
}

proc highlight_xtmp_line {line} {
    global tmp_clock console_clock
    if {[winfo exist .tmpfile] == 0\
                || $tmp_clock != $console_clock} show_tmpfile
    .tmpfile.t tag remove grey 0.0 end
    .tmpfile.t tag add grey $line.0 $line.end
    set viewline [expr $line -5]
    if {$viewline < 1} {set $viewline 1}
    .tmpfile.t yview $viewline
    set tmp_clock $console_clock
}
# end of source.tcl


# Part 22.0           Midi2abc interface


startup_progress "loading midi2abc interface"

#source midi2abcimport.tcl

#midi2abc parameters

proc midi2abc_defaults {} {
    global midi
    set midi(midichannel) ""
    set midi(unitval) ""
    set midi(anaval) ""
    set midi(tsigval) ""
    set midi(ksigval) ""
    set midi(anamethod) 0
    set midi(unitmethod) 2
    set midi(chan_method) 1
    set midi(tsig_method) 2
    set midi(ksig_method) 1
    set midi(save_shorts) 0
    set midi(no_triplets) 0
    set midi(interleave) 0
    set midi(midibpl) 1
    set midi(midibps) 4
    set midi(midippu) 2
    set midi(midilden) 0
    set midi(midirest) 0
    set midi(splits) 0
    show_midi2abc_settings
}


# interface
set p .midi2abc
frame $p

set p .midi2abc.file
frame $p -relief ridge -borderwidth 2
label $p.fileinlab -text  "input midi file" -font $df
label $p.fileoutlab -text "output abc file" -font $df
button $p.fileinbr -text "browse" -command midi_file_browser -font $df
button $p.fileoutbr -text "browse" -command save_browser -font $df
entry $p.fileinent -width 28 -textvariable midi(midifilein) -font $df
bind $p.fileinent <Return> {focus .midi2abc.file.fileinlab}
entry $p.fileoutent -width 28 -textvariable midi(midifileout) -font $df
bind $p.fileoutent <Return> {focus .midi2abc.file.fileoutlab}
.midi2abc.file.fileinent xview moveto 1.0
grid $p.fileinlab -sticky w
grid $p.fileinent -row 0 -column 1 -columnspan 3  -sticky w
grid $p.fileinbr -row 0 -column 4 -sticky w
grid $p.fileoutlab -sticky w
grid $p.fileoutent -row 1 -column 1 -columnspan 3  -sticky w
grid $p.fileoutbr -row 1 -column 4 -sticky w
pack .midi2abc.file




set p .midi2abc.0
frame $p
set p .midi2abc.1
frame $p
set p .midi2abc.1.unitmenu
menubutton $p -text "unit length" -relief raised -menu $p.type \
        -direction right -width 14  -font $df
menu $p.type -tearoff 0
$p.type add command -label "from entry box"  \
        -command {unit_cmd 1} -font $df
$p.type add command -label "from midi file"  \
        -command {unit_cmd 2} -font $df
$p.type add command -label "by minimizing quantization error"  \
        -command {unit_cmd 3} -font $df
$p.type add command -label "from tempo in entry box" \
        -command {unit_cmd 4} -font $df
$p.type add command -label "from expected bars in entry box" \
        -command {unit_cmd 5} -font $df


frame  .midi2abc.2
set p .midi2abc.2.anacrusis
menubutton $p -text "anacrusis" -relief raised -menu $p.type \
        -direction right -width 14  -font $df
menu $p.type -tearoff 0
$p.type add command -label "no anacrusis"  -command {anacrusis_cmd 0}\
        -font $df
$p.type add command -label "from entry box"  -command {anacrusis_cmd 1}\
        -font $df
$p.type add command -label "by minimizing tied notes" \
        -command {anacrusis_cmd 2} -font $df
$p.type add command -label "by finding strong beat"  \
        -command {anacrusis_cmd 3} -font $df

frame .midi2abc.3
set p .midi2abc.3.keysig
menubutton $p -text "key signature" -relief raised -menu $p.type \
        -direction right -width 14 -font $df
menu $p.type -tearoff 0
$p.type add command -label "from midi file"\
        -command {keysig_cmd 1} -font $df
$p.type add command -label "minimize accidentals" \
        -command {keysig_cmd 2} -font $df
$p.type add cascade -menu $p.type.sig  \
        -label "key signature" -font $df
menu $p.type.sig -tearoff 0
set keysiglist {"7# C# A#m" "6# F# D#m" "5# B G#m" "4# E C#m" \
            "3# A f#m" "2# D Bm" "# G Em" "C Am" "b F Dm" "2b Bb Gm" \
            "3b Eb Cm" "4b Ab F#" "5b Db Bbm" "6b Gb Ebm" "7b Cb Abm"}
set i3 0
foreach item $keysiglist {
    $p.type.sig add command -label $item \
            -command "keysig_select $i3" -font $df
    incr i3
}



frame .midi2abc.4
set p .midi2abc.4.timesig
menubutton $p -text "time signature" -relief raised -menu $p.type \
        -direction right -width 14 -font $df
menu $p.type -tearoff 0
$p.type add command -label "from entry box" \
        -command {timesig_cmd 1} -font $df
$p.type add command -label "extracted from midi file" \
        -command {timesig_cmd 2} -font $df

frame .midi2abc.5
set p .midi2abc.5.channel
menubutton $p -text "channel" -relief raised -menu $p.type \
        -direction right -width 14  -font $df
menu $p.type -tearoff 0
$p.type add command -label "all channels" \
        -command {channel_cmd 1} -font $df
$p.type add command -label "selected channel" \
        -command {channel_cmd 2} -font $df

frame .midi2abc.6
checkbutton .midi2abc.6.short -text "save short notes"\
        -variable midi(save_shorts) -font $df -command disable_playabc
checkbutton .midi2abc.6.triplets -text "no triplets"\
        -variable midi(no_triplets) -font $df -command disable_playabc
checkbutton .midi2abc.6.group -text "no grouping"\
        -variable midi(no_grouping) -font $df -command disable_playabc


set p .midi2abc.1
label $p.unitlab -width 28  -anchor w
entry $p.unitent -width 6 -textvariable midi(unitval) -font $df
bind $p.unitent <Return> {focus .midi2abc.1.unitlab}
pack  $p.unitmenu $p.unitlab $p.unitent -side left -anchor w
pack $p -side top -anchor w


set p .midi2abc.2
label $p.analab -width 28  -anchor w
$p.analab configure
entry $p.anaent -width 6 -textvariable midi(anaval) -font $df
bind $p.anaent <Return> {focus .midi2abc.2.analab}
pack  $p.anacrusis $p.analab $p.anaent -side left -anchor w
pack $p -side top -anchor w

set p .midi2abc.3
label $p.keysiglab  -width 28 -anchor w
label $p.keysigsel -width 9
pack $p.keysig $p.keysiglab $p.keysigsel -side left -anchor w
pack $p -side top -anchor w


set p .midi2abc.4
label $p.timsiglab -width 28 -anchor w
entry $p.timsigent -width 6 -textvariable midi(tsigval) -font $df
bind $p.timsigent <Return> {focus .midi2abc.4.timsiglab}
pack $p.timesig $p.timsiglab $p.timsigent -side left -anchor w
pack $p -side top -anchor w

set p .midi2abc.5
label $p.chanlab -width 28 -anchor w
entry $p.chanent -width 6 -textvariable midi(midichannel) -font $df
bind $p.chanent <Return> {focus .midi2abc.5.chanlab}
pack $p.channel $p.chanlab $p.chanent -side left -anchor w
pack .midi2abc.5 -side top -anchor w

pack .midi2abc.6.short .midi2abc.6.triplets .midi2abc.6.group\
        -side left -anchor w
pack .midi2abc.6 -side top -anchor w

set p .midi2abc.7
frame $p
checkbutton $p.interleave -text "voice interleave" \
        -variable midi(interleave) -font $df -command disable_playabc
label $p.bpllab -text "bars per line" -font $df
entry $p.bplent -textvariable midi(midibpl) -width 2 -font $df
bind $p.bplent <Return> {focus .midi2abc.7.bpllab}
label $p.bpslab -text "bars per staff" -font $df
entry $p.bpsent -textvariable midi(midibps) -width 2 -font $df
bind $p.bpsent <Return> {focus .midi2abc.7.bpslab}
pack $p.bpllab $p.bplent $p.bpslab $p.bpsent $p.interleave\
        -side left -anchor w
pack $p -side top -anchor w

set p .midi2abc.8
frame $p
label $p.ppulab -text "parts/unit" -font $df
entry $p.ppuent -textvariable midi(midippu) -width 2 -font $df
bind $p.ppuent <Return> {focus .midi2abc.8.ppulab}
label $p.ldenlab -text "L: denominator" -font $df
entry $p.ldenent -textvariable midi(midilden) -width 2 -font $df
bind $p.ldenent <Return> {focus .midi2abc.8.ldenlab}
label $p.minrestlab -text "minimum rest" -font $df
entry $p.minrestent -textvariable midi(midirest) -width 2 -font $df
bind $p.minrestent <Return> {focus .midi2abc.8.minrestlab}
pack $p.ppulab $p.ppuent $p.ldenlab $p.ldenent $p.minrestlab\
        $p.minrestent  -side left -anchor w
pack $p -side top -anchor w

set p .midi2abc.9
frame $p
radiobutton $p.nosplits -text "no splits" -value 0 -font $df -variable midi(splits)
radiobutton $p.barsplits -text "bar splits" -value 1 -font $df -variable midi(splits)
radiobutton $p.voicesplits -text "voice splits" -value 2 -font $df -variable midi(splits)
pack $p.nosplits $p.barsplits $p.voicesplits -side left -anchor w
pack $p -side top -anchor w

set p .midi2abc.last
frame $p
button $p.go -text midi2abc -font $df -command midi2abc
button $p.default -text "defaults" -font $df -command midi2abc_defaults
button $p.playorig -text "play orig" -font $df -command play_original_midi
button $p.playabc -text "play abc" -font $df -command play_generated_abc
button $p.display -text "display" -font $df \
        -command  {display_tunes [list $midi(midifileout)]
            update_console_page}
button $p.view -text view -font $df -command {tcl_abc_edit $midi(midifileout) 1}

pack $p.go $p.default $p.playorig $p.playabc $p.display $p.view  -side left -anchor w
pack $p -side top -anchor w

proc disable_playabc {} {
    .midi2abc.last.playabc configure -state disabled
    .midi2abc.last.display configure -state disabled
    .midi2abc.last.view configure -state disabled
}

proc anacrusis_cmd {sel} {
    global midi df
    disable_playabc
    switch -- $sel {
        0 {.midi2abc.2.analab configure -text "none" -font $df
            .midi2abc.2.anaent configure -state disable
            set midi(anamethod) 0
            set midi(anaval) ""
            update}
        1 {.midi2abc.2.analab configure -text "in units from entry box" -font $df
            .midi2abc.2.anaent configure -state normal
            set midi(anamethod) 1}
        2 {.midi2abc.2.analab configure -text "by minimizing tied notes" -font $df
            .midi2abc.2.anaent configure -state disable
            set midi(anamethod) 2}
        3 {.midi2abc.2.analab configure -text "by locating the strong beat" -font $df
            .midi2abc.2.anaent configure -state disable
            set midi(anamethod) 3}
    }
}

proc unit_cmd {sel} {
    global midi df
    switch -- $sel {
        1 {.midi2abc.1.unitlab configure -text "from entry box" -font $df
            .midi2abc.1.unitent configure -state normal
            set midi(unitmethod) 1}
        2 {.midi2abc.1.unitlab configure -text "from midi file" -font $df
            .midi2abc.1.unitent configure -state disable
            set midi(unitmethod) 2
            set midi(unitval) ""}
        3 {.midi2abc.1.unitlab configure -text "by minimizing quantization error"\
                    -font $df
            .midi2abc.1.unitent configure -state disable
            set midi(unitmethod) 3
            set midi(unitval) ""
        }
        4 {.midi2abc.1.unitlab configure -text "from tempo in entry box" -font $df
            .midi2abc.1.unitent configure -state normal
            set midi(unitmethod) 4
            set midi(unitval) ""
        }
        5 {.midi2abc.1.unitlab configure -text "from expected bars in entry box"\
                    -font $df
            .midi2abc.1.unitent configure -state normal
            set midi(unitmethod) 5
            set midi(unitval) ""
        }
    }
    disable_playabc
}

proc keysig_cmd {sel} {
    global keysiglist
    global midi df
    switch -- $sel {
        1 {.midi2abc.3.keysiglab configure -text "from midi file" -font $df
            set midi(ksig_method) 1
            .midi2abc.3.keysigsel configure -text ""
        }
        2 {.midi2abc.3.keysiglab configure -text "by minimizing accidentals" -font $df
            set midi(ksig_method) 2
            .midi2abc.3.keysigsel configure -text ""
        }
        3 {set sel [expr 7 - $midi(ksigval)]
            .midi2abc.3.keysiglab configure -text "specified key" -font $df
            .midi2abc.3.keysigsel configure -text [lindex $keysiglist $sel] -font $df
        }
    }
    disable_playabc
}

proc keysig_select {sel} {
    global keysiglist
    global midi df
    set midi(ksig_method) 3
    set midi(ksigval) [expr 7 - $sel]
    .midi2abc.3.keysigsel configure -text [lindex $keysiglist $sel] -font $df
    .midi2abc.3.keysiglab configure -text "specified key" -font $df
    disable_playabc
}

proc timesig_cmd {sel} {
    global midi df
    switch -- $sel {
        1 {.midi2abc.4.timsiglab configure -text "from entry box" -font $df
            .midi2abc.4.timsigent configure -state normal
            set midi(tsig_method) 1}
        2 {.midi2abc.4.timsiglab configure -text "extracted from midi file" -font $df
            .midi2abc.4.timsigent configure -state disable
            set midi(tsig_method) 2
            set midi(tsigval) ""
            update}
    }
    disable_playabc
}

proc channel_cmd {sel} {
    global midi df
    switch -- $sel {
        1 {.midi2abc.5.chanlab configure -text "all channels" -font $df
            .midi2abc.5.chanent configure -state disable
            set midi(chan_method) 1
            set midi(midichannel) ""}
        2 {.midi2abc.5.chanlab configure -text "selected channel in entry box" -font $df
            .midi2abc.5.chanent configure -state normal
            set midi(chan_method) 2
        }
    }
    disable_playabc
}


proc show_midi2abc_settings {} {
    global midi
    anacrusis_cmd $midi(anamethod)
    unit_cmd $midi(unitmethod)
    timesig_cmd $midi(tsig_method)
    keysig_cmd $midi(ksig_method)
    channel_cmd $midi(chan_method)
}


proc show_midi2abc_page {} {
    global active_sheet midi
    remove_old_sheet
    if {$active_sheet == "midi2abc"} {
        set active_sheet none
    }  else {
        pack .midi2abc -side left
        set active_sheet midi2abc
    }
}


#check input parameters

proc unit_input {} {
    global midi midi2abc_options
    switch -- $midi(unitmethod) {
        1 {if {[string length $midi(unitval)] > 0} {
                set midi2abc_options \
                        [concat $midi2abc_options "-u $midi(unitval)"]} else {
                show_message_page "You need to enter unit length in the midimenu/midi2abc \
                        entry box or else change unit length option to `from midi file'.\n" word
                return 1
            }
        }
        3 {set midi2abc_options [concat $midi2abc_options -gu]}
        4 {if {[string length $midi(unitval)] > 0} {
                set midi2abc_options \
                        [concat $midi2abc_options "-Q $midi(unitval)"]} else {
                show_message_page "You need to enter estimated tempo in the \
                        midimenu/midi2abc entry box\n" word
                return 1
            }
        }
        5 {if {[string length $midi(unitval)] > 0} {
                set midi2abc_options \
                        [concat $midi2abc_options "-b $midi(unitval)"]} else {
                show_message_page "You need to enter expected number of bars \
                        in the midimenu/midi2abc entry box\n" word
                return 1
            }
        }
    }
    return 0
}


proc anacrusis_input {} {
    global midi midi2abc_options
    switch -- $midi(anamethod) {
        1  {if {[string length $midi(anaval)] > 0} {
                set midi2abc_options \
                        [concat $midi2abc_options "-a $midi(anaval)"]} else {
                show_message_page "You need to enter the number of units for anacrusis \
                        in the midimenu/midi2abc entry box\n" word
                return 1
            }
        }
        2  {set midi2abc_options [concat $midi2abc_options "-xa"]}
        3  {set midi2abc_options [concat $midi2abc_options "-ga"]}
    }
    return 0
}


proc timesig_input {} {
    global midi midi2abc_options
    switch -- $midi(tsig_method) {
        1 {if {[string length $midi(tsigval)] > 0} {
                set midi2abc_options \
                        [concat $midi2abc_options "-m $midi(tsigval)"]} else {
                show_message_page "You need to enter the time signature in the \
                        midimenu/midi2abc entry box\n" word
                return 1
            }
        }
    }
    return 0
}


proc keysig_input {} {
    global midi midi2abc_options
    if {$midi(ksig_method) == 3} {
        set midi2abc_options \
                [concat $midi2abc_options "-k $midi(ksigval)"]}
    if {$midi(ksig_method) == 2} {
        set midi2abc_options \
                [concat $midi2abc_options "-gk"]}
    return 0
}


proc channel_input {} {
    global midi midi2abc_options
    if {$midi(chan_method) == 2} {
        if {[string length $midi(midichannel)] > 0} {
            set midi2abc_options [concat $midi2abc_options "-c $midi(midichannel)"]} else {
            show_message_page "You need to enter the channel in the \
                    midimenu/midi2abc entry box\n" word
            return 1}
    }
    return 0
}

proc fileeq {pathmidi pathopen} {
    # determines whether pathnames reference the same file
    if {[file exist $pathopen] == 0} {return 1}
    if {[file exist $pathmidi] == 0} {return 0}
    file stat $pathopen stat1
    file stat $pathmidi stat2
    expr $stat1(ino) == $stat2(ino) && \
            $stat1(dev) == $stat2(dev)
}

proc powerof2 {num max} {
    set n 1
    for {set i 0} {$i < 8} {incr i} {
        if {$n == $num} {return 1}
        set n [expr $n*2]
        if {$n > $max} break;
    }
    return 0
}

proc check_midi2abc_options {filein} {
    global midi midi2abc_options
    global abc_file_mod
    if {[file exists $filein] == 0} {
        show_message_page "Unable to open input file $filein. Select one using \
                the browse button on the top.\n" word
        return 1}
    if {[string length $midi(midifileout)] < 1} {
        show_message_page "You need to specify an output abc file.\n" word
        return 1
    }
    if {[powerof2 $midi(midippu) 8] == 0} {
        show_message_page "parts/unit must be a power of 2 less than 16.\n" word
        return 1
    }
    if {$midi(midilden) != 0 && [powerof2 $midi(midilden) 32] == 0} {
        show_message_page "L: denominator must be a power of 2 less than 64.\n" word
        return 1
    }
    set midi2abc_options "-f [list $filein]"
    set midi2abc_options [concat $midi2abc_options]
    if {[unit_input] > 0} {return 1}
    if {[anacrusis_input] > 0} {return 1}
    if {[timesig_input] > 0} {return 1}
    if {[keysig_input] > 0} {return 1}
    if {[channel_input] > 0} {return 1}
    if {$midi(midirest)>0} {set midi2abc_options \
                [concat $midi2abc_options "-sr $midi(midirest)"]}
    if {$midi(midilden) != 0} {set midi2abc_options \
                [concat $midi2abc_options "-aul $midi(midilden)"]}
    if {$midi(save_shorts)} {set midi2abc_options \
                [concat $midi2abc_options "-s"]}
    if {$midi(no_triplets)} {set midi2abc_options \
                [concat $midi2abc_options "-nt"]}
    if {$midi(no_grouping)} {set midi2abc_options \
                [concat $midi2abc_options "-nogr"]}
    if {$midi(splits) == 1} {set midi2abc_options \
                [concat $midi2abc_options "-splitbars"]}
    if {$midi(splits) == 2} {set midi2abc_options \
                [concat $midi2abc_options "-splitvoices"]}
    if {$midi(midibpl) > 16 || $midi(midibpl) < 1} {set midi(midibpl) 1}
    if {$midi(midibps) > 16 || $midi(midibps) < 1} {set midi(midibps) 4}
    set midi2abc_options [concat $midi2abc_options "-bpl $midi(midibpl)"]
    set midi2abc_options [concat $midi2abc_options "-bps $midi(midibps)"]
    set midi2abc_options [concat $midi2abc_options "-sum -o $midi(midifileout)"]
    if {[fileeq $midi(midifileout) $midi(abc_open)]} {
        set abc_file_mod 1
        #   puts "abc_file_mod set by check_midi_options"
    }
    return 0
}


proc save_browser {} {
    global midi types
    set savefile [tk_getSaveFile -filetypes $types]
    if {[string length $savefile] > 0} {set midi(midifileout) $savefile}
    disable_playabc
}



proc midi_file_browser {} {
    # contains Bob Sheskey's Windows 95 fix for double click problem
    # i.e. wm withdraw .. destroy .temp
    # comp.lang.tcl 1997/12/07
    #
    global midi tcl_platform
    global active_sheet
    global miditype
    set filedir [file dirname $midi(midifilein)]
    set str "Windows 95"
    set os $tcl_platform(os)
    if {[string compare $os $str] == 0} {
        wm withdraw [toplevel .temp]
        grab .temp}
    set openfile [tk_getOpenFile -initialdir $filedir \
            -filetypes $miditype]
    if {[string compare $os $str] == 0} {
        update
        destroy .temp
    }
    
    if {[string length $openfile] > 0} {
        set midi(midifilein) $openfile
        .midi2abc.file.fileinent xview moveto 1.0
    }
    disable_playabc
}

proc midi2abc {} {
    global midi2abc_options midi
    global exec_out
    set err [check_midi2abc_options $midi(midifilein)]
    if {$err} return
    update
    if {$err == 0} {set exec_out $midi2abc_options
        set cmd "exec [list $midi(path_midi2abc)] $midi2abc_options"
        catch {eval $cmd} exec_out
        if {[string first "no such" $exec_out] >= 0} {abcmidi_no_such_error $midi(path_midi2abc)}
        #show_message_page $exec_out char
        #update
    }
    set exec_out $cmd\n\n$exec_out
    if {$midi(interleave)} abc_voice_interleave
    .midi2abc.last.playabc configure -state normal
    .midi2abc.last.display configure -state normal
    .midi2abc.last.view configure -state normal
    update_console_page
}


proc play_midi_file {name} {
    global midi
    global exec_out
    #set exec_out ""
    if {$midi(player)} {
        # player 2
        set cmd "exec [list $midi(alt_path_midiplay)] $midi(alt_midi_options) "
        set cmd [concat $cmd [list $name] ]
    } else {
        # player 1
        set cmd "exec [list $midi(path_midiplay)] $midi(midiplay_options) "
        set cmd [concat $cmd [list $name] ]
    }
    set cmd [concat $cmd &]
    eval $cmd
    set exec_out $exec_out\n\n$cmd
    update_console_page
}

proc play_original_midi {} {
    global midi
    play_midi_file $midi(midifilein)
}


proc play_generated_abc {} {
    global midi
    global exec_out
    set exec_out ""
    set cmd "exec [list $midi(path_abc2midi)] [list $midi(midifileout)] \
            -o [list $midi(midi_dir)/tmp.mid]"
    catch {eval $cmd} exec_out1
    set exec_out1 $cmd\n\n$exec_out1
    set console_clock [clock seconds]
    set dir "[pwd]/$midi(midi_dir)"
    set cmd "file delete [glob -nocomplain $dir/X*.mid]"
    catch {eval $cmd}
    
    if {$midi(player)} {
        # player 2
        set cmd "exec [list $midi(alt_path_midiplay)] $midi(alt_midi_options) "
        set cmd [concat $cmd [list [pwd]/$midi(midi_dir)/tmp.mid]]
    } else {
        # player 1
        set cmd "exec [list $midi(path_midiplay)] $midi(midiplay_options) "
        set cmd [concat $cmd [list [pwd]/$midi(midi_dir)/tmp.mid]]
    }
    set cmd [concat $cmd &]
    catch {eval $cmd} exec_out
    set exec_out $cmd\n$exec_out
    set exec_out $exec_out1\n\n$exec_out
    update_console_page
}


set hlp_midi2abc "Midi2abc\n\n\
        
The menu buttons on this page are used to control the manner by which \
        midi2abc computes the unit length, anacrusis, key signature and other \
        important characteristics of the abc file.  By default the program \
        uses the options which produce the best results with the least user \
        input. If the results are not satisfactory, it may be necessary \
        to fiddle around with these run time parameters. Here is a brief \
        description of some of these options.\n\n\
        
Unit length: midi2abc quantizes the MIDI time units into quantum\
        units usually corresponding to 1/16 or 1/32 notes. The number\
        of MIDI units corresponding to a quantum unit is specified here\
        and corresponds to the xunit parameter in midi2abc.  If the midi file was \
        created using music notation software, this length is already contained \
        in the headers of the midi file so it is unnecessary to specify it.\
        This is the case for almost all MIDI files available on the Web.\
        On the other hand, you may have recorded the midi file\
        from a midi instrument and the header information may\
        not be entirely relevant. The midi2abc program offers several alternatives\
        for estimating the conversion factor from MIDI time units to\
        quantum units as described below.\n\n\
        from entry box: You enter the length of the standard unit in the\
        entry box. This unit is referred to as xunit which displayed each\
        time you run midi2abc.(You view this information by clicking\
        the console button after clicking midi2abc.)  Typically xunit is\
        somewhere between 32 and 128.\
        Large unit lengths produces a score with many short notes while small\
        unit lengths produce a score with longer notes.\n\n\
        from midi file: the current default. The unit length is extracted from\
        the information in the midi header file and time signature indication\
        in this file.\n\n\
        by minimization quantization error. Midi2abc tries out different unit\
        lengths withen a certain range and chooses the one that produces the\
        least quantization error.\n\n\
        from tempo in entry box. This refers to the tempo that you think the\
        midi file is playing at. Changing its value will not change the actual\
        tempo of the output, (there is another way to do this from the midi option\
        property sheet). However, changing its value will tell midi2abc what \
        time duration corresponds to a beat (usually a quarter note).\n\n\
        from expected bars in entry box. You tell midi2abc how many measures\
        you expect in the output. Note that these last two methods may not work\
        well if the midi file has more than one tempo indication.\n\n
Anacrusis: a lot of music does not begin with a complete measure, but\
        instead has several leading notes. Midi2abc provides two methods for\
        computing the anacrusis, or else you can specify this yourself. The\
        anacrusis is specified in terms of quantum units.\n\n\
        Many midi files indicate the time signature or key signature; however,\
        there may be reasons for which you may have to specify it or change\
        it.\n\n\
        Advanced features; Some midi files have short rests between all notes\
        in order to improve the articulation. Though preserving these rests\
        results in a more accurate representation of the midi file, this results\
        in a very messy abc file as well as music notation display which is\
        hard to read. You can eliminate these short rests by specifying\
        a minimum rest specified in number of quantum units.\
        If the minimum rest is 0, nothing is done. For larger values,\
        those rests are absorbed into the preceding notes. (In other\
        words the preceding note is larger to include the rest.)\n\n\
        Notes shorter than the quantum unit are usually ignored by\
        midi2abc. This sometimes poses problems for percussion instruments\
        which assign a minimum duration for such notes. You may preserve\
        them by ticking save shorts check box. In this case the short notes\
        are expanded to the basic quantum unit\n\n\
        Midi2abc creates an abc file with the\
        voices all separate. This may be difficult to edit. As an option,\
        you may request runabc to interleave the voices.\n\n\
        Midi2abc by default chooses the L: unit length based on the\
        time signature (either 1/8 or 1/16). The quantum unit by default\
        is one half of this unit. Later versions of midi2abc allow you to\
        override these defaults. The options parts/unit and L: denominator\
        allow you to change these options. These specified values\
        must be powers of 2 (2,4,8,16 etc.). These features are not\
        fully tested.\n\n\
        Most chords are homomorphic, i.e. all the notes in the chord\
        are the same length and share a common onset. Polyphonic music,\
        in particular keyboard music does not share this characteristic\
        and notes in chords may begin at any time and end at any time.\
        If these notes are in the same voice, this poses an awkward\
        problem in abc notation. Midi2abc addresses this problem by\
        breaking such chords into tied chords where some notes in\
        the chords are tied to the adjacent chord. This leads to a\
        bloated abc file which is difficult to edit and read.\
        Bar splits and voice splits are new features which\
        provides an alternative way of handling polyphonic music.\
        If bar splits is selected, a measure may be split into separate\
        lines of notes using the & sign. If voice splits is selected,\
        an entire voice may be split into several voices to avoid\
        polyphonic chords."

show_midi2abc_settings
#end source midi2abcimport.tcl



# Part 23.0         Voice Support Functions for midi2abc


#source voiceproc.tcl

proc extract_all_voices {tunes abcfile} {
    
    # The function separates the voice information and
    # puts it into a global array called voicedata. The
    # index of this array addresses the separate lists
    # of voice information.
    # This function is not very smart (for example it
    # does not handle inline voices commands or voice
    # indications in the header. It only works with the
    # output of midi2abc.
    global fileseek midi
    global voicedata
    global outhandle
    
    array unset voicedata
    set pat {V:([0-9])}
    set edithandle [open [list $abcfile] r]
    set sel [lindex $tunes 0]
    set loc $fileseek($sel)
    seek $edithandle $loc
    set line [find_X_code $edithandle]
    puts $outhandle $line
    set vappend 0
    
    while {[string length $line] > 0 } {
        if {$midi(blank_lines)} {
            set line  [get_nonblank_line $edithandle]} else {
            set line  [get_next_line $edithandle]}
        if {[string index $line 0] == "X"} break;
        # search for voice id
        if {[regexp $pat $line result sub]} {
            if {![info exist voicedata($sub)]} {
                set voicedata($sub) ""}
            set vappend 1
            continue}
        if {$vappend} {
            set voicedata($sub) $voicedata($sub)$line\n
        } else {
            puts $outhandle $line}
    }
    
    
    close $edithandle
}



proc getnonblank_bar {id} {
    global voicedata voicelen voiceind
    # There may blank entries in the voicedata list that
    # we do not want to retrieve.
    set bar ""
    while {[string length $bar] < 2} {
        set bar [lindex $voicedata($id) $voiceind($id)]
        incr voiceind($id)
        if {$voiceind($id) >= $voicelen($id)} break;
    }
    return $bar
}



proc interleave_voices {} {
    # once all the voicedata has been separated, we
    # output the data interleaving each voice
    global voicedata voicelen voiceind
    global outhandle
    set ids [array names voicedata]
    set ids [lsort $ids]
    set maxlen 0
    
    foreach id $ids {
        set voicedata($id) [split $voicedata($id) \n]
        set voicelen($id) [llength $voicedata($id)]
        set voiceind($id) 0
        if {$voicelen($id) > $maxlen} {set maxlen $voicelen($id)}
    }
    set remainingbars 1
    set barcount 0
    while {$remainingbars} {
        set min_index 10000
        foreach id $ids {
            set bar [getnonblank_bar $id]
            if {[string index $bar 0] == "%"} {
                puts $outhandle "V:$id"
                puts $outhandle $bar
                while {[string index $bar 0] == "%"} {
                    set bar [getnonblank_bar $id]
                    if {[string index $bar 0] != "%"} {
                        incr voiceind($id) -1
                        break
                    }
                    puts $outhandle $bar
                }
            } elseif {[string compare -length 2 $bar "K:"] ==0 ||\
                        [string compare -length 2 $bar "L:"] ==0 ||\
                        [string compare -length 2 $bar "M:"] ==0} {
                puts $outhandle V:$id\n$bar
            } else {
                if {$bar != ""} {puts $outhandle "\[V:$id\] $bar"}
            }
            if {$min_index > $voiceind($id)} {set min_index $voiceind($id)}
        }
        if {$min_index >= $maxlen} {set remainingbars 0}
    }
    #foreach id $ids {
    # puts "$id $voiceind($id) $voicelen($id)"
    # }
}


proc abc_voice_interleave {} {
    global midi
    global outhandle
    global abc_file_mod
    set outhandle [open [list $midi(midi_dir)/X.tmp] w]
    set sel [title_selected]
    extract_all_voices $sel $midi(midifileout)
    interleave_voices
    close $outhandle
    file rename -force [list $midi(midifileout)] [list $midi(midi_dir)/interleave.abc]
    file rename -force [list $midi(midi_dir)/X.tmp] [list $midi(midifileout)]
    if {[fileeq $midi(midifileout) $midi(abc_open)]} {
        set abc_file_mod 1
        #   puts "abc_file_mod set by abc_voice_interleave"
    }
}

#end of source voiceproc.tcl


# Part 24.0  Chord substitution functions for Abc Editor

#source chordclean.tcl

proc replace_chord {buffer level} {
    # replaces chord eg [A2d2f2] with single note from chord
    # where level indicates note position starting from higher
    # pitch to lower pitch. This is done for all chords in
    #the input string.
    set pat {\[[^\]\[]*\]}
    set success 1
    set offset 0
    set tmp $buffer
    while {$success} {
        set success [regexp -indices $pat $tmp match]
        if {!$success} break
        set pos1 [lindex $match 0]
        set pos2 [lindex $match 1]
        set chord [string range $tmp [expr $pos1 +1] [expr $pos2 -1]]
        set tmp [string range $tmp [expr $pos2+1] end]
        set firstchar [string index $chord 0]
        set apos1 [expr $pos1 + $offset]
        set apos2 [expr $pos2 + $offset]
        #    puts "chord=$chord"
        #   ignore [1 [2 [V: [K: [M: [L
        if {[string first $firstchar "123VKML"] < 0} {
            set brokenchord [split_chord $chord]
            #    puts $brokenchord
            set note [pick_chord_note $brokenchord $level]
            #    puts "selected note $note"
            set buffer [string replace $buffer $apos1 $apos2 $note]
            set offset [expr $offset - $pos2 + $pos1 + [string length $note]]
        }
        set offset [expr $offset + $pos2]; #from replacing $tmp
        #    puts $buffer
        #    puts "tmp = $tmp"
    }
    return $buffer
}


proc notesubstitute {note} {
    set pat \[A-Ga-g|z\]
    #puts "notesubstitute $note"
    regexp -indices $pat $note indices
    set nchar [string length $note]
    set s [lindex $indices 0]
    set stripnote [string range $note $s $nchar]
    set notespace [string replace $stripnote 0 0 x]
    #puts $notespace
}

proc replace_chord_x {buffer level} {
    # The function sweeps through the buffer string replacing
    # notes with x rests and chords with one of the notes
    # in the chord (determined by level).
    
    set chordpat {\[[^\]\[]*\]}
    set notepat {(\.|M|R|T|~?)(\^*|_*|=?)([0-9]?)(/?)([0-9]?)([A-G]\,*|[a-g]\'*|z)(/?[0-9]*|[0-9]*/*[0-9])}
    set success 1
    set offset 0
    set tmp $buffer
    while {$success} {
        #   find first note or first chord in tmp string
        #    puts "tmp =$tmp"
        set success_note [regexp -indices $notepat $tmp notematch]
        set success_chord [regexp -indices $chordpat $tmp chordmatch]
        set success [expr $success_note | $success_chord]
        if {!$success} break
        
        #   which came first?
        # set match to whatever comes first -notematch or chordmatch
        if {!$success_note} {
            set match $chordmatch
            set type chord
        } elseif {!$success_chord} {
            set match $notematch
            set type note
        } elseif {[lindex $notematch 0] < [lindex $chordmatch 0]} {
            set match $notematch
            set type note
        } else {set match $chordmatch
            set type chord}
        
        #   chord match
        if {$type == "chord"} {
            set pos1 [lindex $match 0]
            set pos2 [lindex $match 1]
            set chord [string range $tmp [expr $pos1 +1] [expr $pos2 -1]]
            set tmp [string range $tmp [expr $pos2+1] end]
            set firstchar [string index $chord 0]
            set apos1 [expr $pos1 + $offset]
            set apos2 [expr $pos2 + $offset]
            #    puts "chord=$chord"
            #   ignore [1 [2 [V: [K: [M: [L
            if {[string first $firstchar "123VKML"] < 0} {
                set brokenchord [split_chord $chord]
                #    puts $brokenchord
                set note [pick_chord_note $brokenchord $level]
                #    puts "selected note $note"
                set buffer [string replace $buffer $apos1 $apos2 $note]
                set offset [expr $offset - $pos2 + $pos1 + [string length $note]]
            }
            set offset [expr $offset + $pos2]; #from replacing $tmp
            #    puts $buffer
            #    puts "tmp = $tmp"
        }
        
        if {$type == "note"} {
            set pos1 [lindex $match 0]
            set pos2 [lindex $match 1]
            #puts "pos1 pos2 $pos1 $pos2"
            set note [string range $tmp $pos1 $pos2]
            #puts "note $note"
            set tmp [string range $tmp [expr $pos2+1] end]
            set notespace [notesubstitute $note]
            set apos1 [expr $pos1 + $offset]
            set apos2 [expr $pos2 + $offset]
            #puts "offset pos1 pos2 $offset $pos1 $pos2"
            #puts "before buffer =$buffer"
            set buffer [string replace $buffer $apos1 $apos2 $notespace]
            #puts "after  buffer =$buffer"
            set offset [expr $offset + $pos1   + [string length $notespace]]
        }
        #puts $buffer
    }
    #puts $buffer
    return $buffer
}



proc split_chord {string} {
    # given a chord eg [A2c2] it returns a list {{A2 n1} {c2 n2}}
    # where n1 reflects the pitch of the note. The list is
    # sorted in order of decreasing pitch.
    set notepat {(\^*|_*|=?)([A-G]\,*|[a-g]\'*)(/?[0-9]*|[0-9]*/*[0-9])}
    set success 1
    set tmp $string
    set notelist ""
    while {$success} {
        set success [regexp -indices $notepat $tmp match]
        if {!$success} break
        set pos1 [lindex $match 0]
        set pos2 [lindex $match 1]
        #    puts "$pos1 $pos2"
        set note [string range $tmp $pos1 $pos2]
        set priority [note2pitch $note]
        lappend notelist [list $note $priority]
        set tmp [string range $tmp [expr $pos2+1] end]
    }
    lsort -index 1 -decreasing -integer  $notelist
}

proc pick_chord_note {notelist notenumber} {
    set size [expr [llength $notelist] -1]
    #  if {$notenumber > $size} {set notenumber $size}
    if {$notenumber > $size} {return x}
    return [lindex [lindex $notelist $notenumber] 0]
}

global fullnotekey
set fullnotekey "C,D,E,F,G,A,B,C.D.E.F.G.A.B.c.d.e.f.g.a.b.c'd'e'f'g'a'b'c'"

proc note2pitch {note} {
    global fullnotekey
    set barenotepat {[A-G]\,*|[a-g]\'*}
    regexp $barenotepat $note match
    if {[string length $match] < 2} {set match $match.}
    set priority [string first $match $fullnotekey]
    #  puts "   $match $priority"
    return $priority
}

set hlp_replacechord "    Replace chord\n\n\
        This tool replaces chords, eg \[CEG\] \[DFA\] etc with one\
        of the notes in the chords, eg G A. The notes in the\
        chords are sorted by pitch. For example, if you select\
        top note, then the highest pitch note in the chord\
        replaces the chord. The program tries to avoid touching\
        anything else in the music including inline field\
        commands such as \[K: Am] or repeat part indications\
        such as \[1 or \[2, but it may not be perfect: so check\
        the results before commiting them to a file.\n\n
There are two version of this function. The first version\
        without the x just copies notes which are not inside chords.\
        The second version (with the x) replaces the note with an x\
        which acts like an invisible rest in abcm2ps.\n\n
To use this tool you must first select a region in\
        the file to operate."

#end of source chordclean.tcl




# Part 25.0           Midishow


#source midishow.tcl

#global variables

# needed by show_events. switch been tracks or chan.
set pixels_per_file 2000

set trkchan 1
# flag to to separate by track or channel

set exec_out ""
#run time messages
set piano_yview_pos 0.35 ;# scroll position for piano roll display
set pianoresult {} ;# midilyze output for compute_pianoroll or get_midi_stats
#flag to cause pianoroll to be regenerated
#counter for  channel program indications in midi file

global activechan
global trksel
global highlighted_trk
global trkchan
global exec_out
global piano_yview_pos

# This array stores the selected tracks for generating a wav
# file using create_wav_file. We initialize them to 0 to indicate
# that no tracks have been selected yet.
for {set i 0} {$i < 32} {incr i} {
    set trksel($i) 0
    update_console_page
}



proc check_midi2abc_and_midicopy_versions {} {
    global midi
    
    set result [get_version_number $midi(path_midi2abc)]
    #puts $result
    set err [scan $result "%f" ver]
    set msg "You need midi2abc.exe version 2.78 or higher"
    if {$err == 0} {return $msg}
    if {$ver < 2.78} {return $msg}
    
    set result [get_version_number $midi(path_midicopy)]
    #puts $result
    set err [scan $result "%f" ver]
    set msg "You need midicopy.exe version 1.01 or higher"
    if {$err == 0} {return $msg}
    if {$ver < 1.01} {return $msg}
    return pass
}




proc piano_window {} {
    global df
    if {[winfo exist .piano]} return
    toplevel .piano
    #Create top level menu bar.
    set p .piano.f
    frame $p
    
    #buttons for zooming in and zooming out
    menubutton $p.config -text config -width 8 -menu $p.config.items -font $df
    menu $p.config.items -tearoff 0
    $p.config.items add radiobutton -label "separate by track" -font $df\
            -value track -variable midi(midishow_sep) -command compute_pianoroll
    $p.config.items add radiobutton -label "separate by channel" -font $df\
            -value channel -variable midi(midishow_sep) -command compute_pianoroll
    $p.config.items add checkbutton -label "follow while playing" -font $df\
            -variable midi(midishow_follow)
    $p.config.items add command -label "ppqn adjustment" -font $df\
            -command ppqn_adjustment_window
    
    
    button $p.zoom -text zoom -relief flat -command piano_zoom -font $df
    menubutton $p.unzoom -text unzoom -width 8 -menu $p.unzoom.items -font $df
    menu $p.unzoom.items -tearoff 0
    $p.unzoom.items add command -label "Unzoom 1.5" -font $df \
            -command {piano_unzoom 1.5}
    $p.unzoom.items add command -label "Unzoom 3.0" -font $df \
            -command {piano_unzoom 3.0}
    $p.unzoom.items add command -label "Unzoom 5.0" -font $df \
            -command {piano_unzoom 5.0}
    $p.unzoom.items add command -label "Total unzoom" -command piano_total_unzoom -font $df
    
    menubutton $p.action -text action -menu $p.action.items -font $df
    menu $p.action.items -tearoff 0
    $p.action.items add command  -label "create abc file" -command create_abc_file -font $df
    $p.action.items add command  -label "display abc" -font $df \
            -command create_abc_file_and_display
    $p.action.items add command  -label "play abc" -font $df \
            -command create_abc_file_and_play
    $p.action.items add command  -label "velocity distribution" -font $df \
            -command {pianoroll_statistics velocity
                plotmidi_velocity_or_pitch_distribution velocity}
    $p.action.items add command  -label "pitch distribution" -font $df \
            -command {pianoroll_statistics pitch
                plotmidi_velocity_or_pitch_distribution pitch
                show_note_distribution}
    $p.action.items add command  -label "velocity map" -font $df \
            -command plot_velocity_map
    $p.action.items add command  -label "beat graph" -font $df \
            -command beat_graph
    $p.action.items add command  -label "unique chords" -font $df \
            -command unique_chords
    $p.action.items add command  -label "create midi" -font $df \
            -command create_abc_and_midi
    $p.action.items add command  -label "create PostScript file" -font $df \
            -command piano_window_ps_output
    $p.action.items add command -label "help" -font $df\
            -command {show_message_page $hlp_midishow_actions word}
    
    button $p.help -text help -relief flat -font $df\
            -command {show_message_page $hlp_midishow word}
    
    grid  $p.config $p.zoom $p.unzoom $p.action $p.help -sticky news
    grid $p -column 1
    
    set p .piano.file
    frame $p -relief ridge -borderwidth 2
    label $p.fileinlab -text  "input midi file" -font $df
    button $p.fileinbr -text "browse" -relief flat -font $df\
            -command {midi_file_browser
                show_events}
    entry $p.fileinent -width 28 -textvariable midi(midifilein) -font $df
    $p.fileinent xview moveto 1.0
    bind $p.fileinent <Return> {focus .piano.file.roll
        show_events}
    button $p.roll -text replot -relief flat -command show_events -font $df
    grid $p.fileinlab $p.fileinent $p.fileinbr $p.roll
    grid $p -column 0 -columnspan 3
    
    
    set p .piano
    
    # create frame for displaying canvas of piano roll.
    
    scrollbar $p.hscroll -orient horiz -command [list BindXview [list $p.can\
            $p.canx]]
    scrollbar $p.vscroll -command BindYview
    
    canvas $p.can -width 400 -height 300 -border 3 -relief sunken -scrollregion\
            {0 0 2500 500} -xscrollcommand "$p.hscroll set" -yscrollcommand\
            "$p.vscroll set" -border 3 -bg white
    canvas $p.canx -width 400 -height 20 -border 3 -relief sunken -scrollregion\
            {0 0 2500 20}
    canvas $p.cany -width 20 -height 300 -border 3 -relief sunken -scrollregion\
            {0 0 20 724}
    grid $p.cany $p.can $p.vscroll -sticky news
    grid $p.canx -sticky news -column 1
    label $p.txt -text midishow
    grid $p.hscroll -sticky ew -column 1
    grid $p.txt -column 1
    #bind $p.can <Button> {button_press %x %y}
    grid rowconfig $p 2 -weight 1 -minsize 0
    grid columnconfig $p 1 -weight 1 -minsize 0
    
    frame .piano.trkchn
    grid .piano.trkchn -columnspan 3
    
    for {set i 0} {$i < 24} {incr i} {
        checkbutton .piano.trkchn.$i -text $i -variable trksel($i)
    }
    label .piano.trkchn.lab
    pack .piano.trkchn.lab -side left -anchor w
    
    
    bind $p.can <ButtonPress-1> {piano_Button1Press %x %y}
    bind $p.can <ButtonRelease-1> {piano_Button1Release}
    bind $p.can <Double-Button-1> piano_ClearMark
    bind $p.can <Button-3> {
        set miditime [midi_to_midi 0]
        piano_play_midi_extract
        startup_playmark_motion $miditime
    }
    set result [check_midi2abc_and_midicopy_versions]
    if {[string equal $result pass]} {show_events} else {
        .piano.txt configure -text $result -foreground red -font $df}
}

proc ppqn_adjustment_window {} {
    global df
    if {[winfo exist .ppqn]} return
    toplevel .ppqn
    button .ppqn.1 -text "increase ppqn" -font  $df -repeatdelay 500\
            -repeatinterval 50 -command {qnote_spacing_adjustment 1}
    button .ppqn.2 -text "decrease ppqn" -font $df -repeatdelay 500\
            -repeatinterval 50 -command {qnote_spacing_adjustment -1}
    button .ppqn.3 -text "+ pulse offset" -font $df -repeatdelay 500\
            -repeatinterval 50 -command {qnote_offset_adjustment 1}
    button  .ppqn.4 -text "- pulse offset" -font $df -repeatdelay 500\
            -repeatinterval 50 -command {qnote_offset_adjustment -1}
    pack .ppqn.1 .ppqn.2 .ppqn.3 .ppqn.4
}


set hlp_midishow "In order to use this tool you require midi2abc\
        version 2.75 or higher and midicopy 1.02 or higher. Be sure to\
        specify the path to midicopy in the config/abc executables page.\n\n\
        The function will display the selected MIDI file in piano\
        roll form in a resizeable separate window.\n\n\
        Vertical lines indicate beat numbers as determined by the\
        the conversion factor PPQN (pulses per quarter note) in the\
        header of the MIDI file. If you place the mouse pointer on\
        any one of the MIDI notes as indicated by a black horizontal\
        arrow, this note and all other notes belonging to the same\
        track will appear in red, and the parameters of this note will\
        appear in a short text line below the scroll bar of this display.\
        If you click the right mouse button, while the notes in the\
        track are highlighted, then these notes will be sent to the\
        MIDI player you have designated. If you right click elsewhere\
        in the piano roll display, then all displayed notes will be\
        sent to the midi player. Note that if any of these functions\
        do not seem to run correctly, you should click the console\
        button and view the messages.\n\n The program attempts to follow\
        the playing with a vertical red line based on the estimated duration\
        of the output. Due to possible latencies in the midiplayer there may\
        be some loss of synchronization for some players. Pressing any key on\
        the keyboard while the focus is on the piano canvas will stop the tracker.\
        Unfortunately, I have not found a way of stopping the midi player from\
        runabc. You can turn off the tracker from the options menu.\n\n\
        The zoom and unzoom buttons will magnify or scale down the display.\
        You can specify an area to zoom into by holding down the mouse left\
        mouse button and sweeping an area. This area will be highlighted.\
        (A double click will clear the highlighted area marker -- yellow stipple.)\
        Clicking the zoom button will zoom into the highlighted area.\
        Clicking the right mouse button while a zoom area is highlighted\
        will send only the highlighted area to the MIDI player.\n\n\
        You may configure the program to either distinguish tracks\
        or channels. A sequence of radio buttons at the bottom of the\
        window allows you to select particular channels or tracks for\
        further processing available from the action menu. If nothing\
        is selected then all channels/tracks are processed.\
        If you are creating an abc file from the displayed portion of\
        the MIDI file. The midi2abc option string is shared with the\
        midi2abc frame (obtained from midimenu/midi2abc) or a default\
        string is used if the midi2abc was not run from midi2abc window.\n\n
It is possible to shift or change the spacing of the vertical quarter\
        note line indications by selecting the config/ppqn adjustment item.\
        This temporarily changes the ppqn value of the MIDI file which\
        also affects the output of action/beat graph."

set hlp_midishow_actions "The action menu provides miscellaneous\
        functions that can be applied on the exposed temporal part of the\
        MIDI file.\n\n\
        create abc file - will copy the exposed part of the MIDI file to\
        tmp/tmp.mid (possibly selecting specific tracks or channels) and call\
        midi2abc to make an abc file.\n\n\
        display abc  - does the above but also displays the new abc file.\n\n\
        play abc     - does the above but also plays the new abc file.\n\n\
        create midi  - creates tmp/tmp.mid and renames it to whatever you select.\n\n\
        velocity distribution - produces a histogram of the velocity values\
        of the notes in the exposed area.\n\n\
        pitch distribution - produces both a histogram of the MIDI pitch values\
        and the pitch classes of the exposed area.\n\n\
        velocity map - plots the velocity of the notes versus beat number.\n\n\
        beat graph - plots the onset time relative to the start of a beat\
        versus the beat number for each note. You should see horizontal lines\
        if the note onset times follow exact musical positions in a measure.\n\n\
        unique chords - lists a histogram of all the distinct chords.\n\n\
        create PostScript file - produces a PostScript file called piano.ps showing\
        the visible portion of the piano roll."



#        Support functions

proc piano_Button1Press {x y} {
    set xc [.piano.can canvasx $x]
    .piano.can raise mark
    .piano.can coords mark $xc 0 $xc 720
    bind .piano.can <Motion> { piano_Button1Motion %x }
    update_piano_txt $x $y
}

proc piano_Button1Motion {x} {
    set xc [.piano.can canvasx $x]
    if {$xc < 0} { set xc 0 }
    set co [.piano.can coords mark]
    .piano.can coords mark [lindex $co 0] 0 $xc 720
}

proc piano_Button1Release {} {
    bind .piano.can <Motion> {}
    set co [.piano.can coords mark]
}

proc piano_ClearMark {} {
    .piano.can coords mark -1 -1 -1 -1
}



# for handling x scrolling of piano roll
proc BindXview {lists args} {
    foreach l $lists {
        eval {$l xview} $args
    }
}

# for handling y scrolling of piano roll
proc BindYview {args} {
    global piano_yview_pos
    eval .piano.can yview $args
    eval .piano.cany yview $args
    set piano_yview_pos [lindex [.piano.can yview] 0]
}







proc unpack_mthd_header {} {
    # read binary header block of midi file to get
    # format type and number of tracks. Saves having
    # to call a C program.
    global mthd_header id mlen mformat ntrk ppqn trkchan
    binary scan $mthd_header a4ISSS id mlen mformat ntrk ppqn
    set trkchan $mformat
}


proc read_midifile_header {openfile} {
    global ntrk
    global ppqn
    global midihandle
    global mthd_header
    global mlen mformat ppqn
    global piano_qnote_offset
    if {[string length $openfile] > 0} {
        set midihandle [open $openfile r]
    }
    fconfigure $midihandle -translation binary
    set mthd_header [read $midihandle 14]
    unpack_mthd_header
    close $midihandle
    set piano_qnote_offset 0
}


# This procedure is associated with the piano roll button.
# It calls the midi2abc executable to do most of the work.
proc show_events {} {
    global midi trkchan
    global trk
    global pianoresult
    global midilength
    global piano_yview_pos
    global exec_out
    global pixels_per_file
    global df
    focus .
    
    
    if {[file exist $midi(midifilein)] == 0} {
        .piano.txt configure -text "can't open file $midi(midifilein)"\
                -foreground red -font $df
        return
    }
    
    read_midifile_header $midi(midifilein); # read midi header
    
    set exec_options "[list $midi(midifilein)] -midigram"
    
    set cmd "exec [list $midi(path_midi2abc)] $exec_options"
    #    puts $cmd
    catch {eval $cmd} pianoresult
    if {[string first "no such" $pianoresult] >= 0} {abcmidi_no_such_error $midi(path_midi2abc)}
    set exec_out show_events:\n$cmd\n\n$pianoresult
    set nrec [llength $pianoresult]
    set midilength [lindex $pianoresult [expr $nrec -1]]
    if {[string is integer $midilength] != 1} {
        .piano.txt configure -text "$midilength ??"
        return
    }
    
    set pixels_per_file 2000
    compute_pianoroll
    .piano.can yview moveto $piano_yview_pos
    .piano.cany yview moveto $piano_yview_pos
    piano_horizontal_scroll 0
    update_console_page
}


#horizontal zoom of piano roll
proc piano_zoom {} {
    global pixels_per_file
    set co [.piano.can coords mark]
    set zoomregion [expr [lindex $co 2] - [lindex $co 0]]
    set displayregion [winfo width .piano.can]
    set scrollregion [.piano.can cget -scrollregion]
    if {$zoomregion > 5} {
        set mag [expr $displayregion/$zoomregion]
        set pixels_per_file [expr $pixels_per_file*$mag]
        compute_pianoroll
        set xv [expr double([lindex $co 0])/double([lindex $scrollregion 2])]
        piano_horizontal_scroll $xv
    } else {
        set pixels_per_file [expr $pixels_per_file*1.5]
        if {$pixels_per_file > 250000} {
            set $pixels_per_file 250000}
        set xv [lindex [.piano.can xview] 0]
        set xv [expr $xv*1.5]
        compute_pianoroll
        piano_horizontal_scroll $xv
    }
}


proc piano_unzoom {factor} {
    global pixels_per_file
    set pixels_per_file [expr $pixels_per_file /$factor]
    set xv [.piano.can xview]
    set xvl [lindex $xv 0]
    set xvr [lindex $xv 1]
    set growth [expr ($factor - 1.0)*($xvr - $xvl)]
    set xvl [expr $xvl - $growth/2.0]
    if {$xvl < 0.0} {set xv 0.0}
    #set xv [expr $xv/$factor]
    compute_pianoroll
    piano_horizontal_scroll $xvl
}

proc piano_total_unzoom {} {
    global pixels_per_file
    set pixels_per_file 1000
    compute_pianoroll
    .piano.can configure -scrollregion [.piano.can bbox all]
}



# procedure for drawing on the piano roll canvas.
proc compute_pianoroll {} {
    global midi
    global midilength
    global pixels_per_file
    global pianoresult pianoxscale
    global activechan
    global ppqn
    global piano_vert_lines
    
    
    if {[llength $pianoresult] < 1} {
        return
    }
    
    
    set p .piano
    set pianoxscale [expr ($midilength / double($pixels_per_file))]
    
    set qnspacing  [expr $pixels_per_file*$ppqn/double($midilength)]
    set piano_vert_lines [expr round(40/$qnspacing)]
    if {$piano_vert_lines <1} {set piano_vert_lines 1}
    
    set xvright [expr round($midilength/$pianoxscale +20)]
    $p.can delete all
    
    $p.can create rect -1 -1 -1 -1 -tags mark -fill yellow -stipple gray25
    #      -width 1 -outline red
    
    if [info exist activechan] {
        unset activechan
    }
    for {set i 0} {$i <89} {incr i} {
        set j [expr ($i+8)%12]
        switch -- $j {
            1 -
            3 -
            6 -
            8 -
            10 {
                $p.can create rectangle 0 [expr 724-$i*8] $xvright\
                        [expr 716-$i*8] -fill gray80 -outline ""
            }
            default {
                $p.can create rectangle 0 [expr 724-$i*8] $xvright\
                        [expr 716-$i*8] -fill white -outline ""
            }
        }
        if {$j == 0} {
            set octave [expr $i/12 + 1]
            set legend [format "C%d" $octave]
            $p.cany create text 10 [expr 724-$i*8] -text $legend
        }
        if {$j == 5} {
            set octave [expr $i/12 + 1]
            set legend [format "F%d" $octave]
            $p.cany create text 10 [expr 724-$i*8] -text $legend
        }
    }
    .piano.txt configure -text "" -foreground Black
    
    piano_qnotelines
    
    set i 0
    foreach line [split $pianoresult \n] {
        incr i
        if {[llength $line] != 6} continue
        set begin [lindex $line 0]
        if {[string is double $begin] != 1} continue
        set end [lindex $line 1]
        set t [lindex $line 2]
        set c [lindex $line 3]
        if {$midi(midishow_sep) == "track"} {set sep $t} else {set sep $c}
        set note [lindex $line 4]
        set ix1 [expr $begin/$pianoxscale]
        set ix2 [expr $end/$pianoxscale]
        set iy [expr 720 - ($note-20)*8]
        $p.can create line $ix1 $iy $ix2 $iy -width 2 -tag trk$sep -arrow last\
                -arrowshape {2 2 2}
        set activechan($sep) 1
    }
    bind_tracks
    set bounding_box [$p.can bbox all]
    set top [lindex $bounding_box 1]
    set bot [lindex $bounding_box 3]
    
    
    
    
    set bounding_boxx [list [lindex $bounding_box 0] 0 [lindex $bounding_box\
            2] 20]
    set bounding_boxy [list 0 [lindex $bounding_box 1] 20\
            [lindex $bounding_box 3]]
    $p.can configure -scrollregion $bounding_box
    $p.canx configure -scrollregion $bounding_boxx
    $p.cany configure -scrollregion $bounding_boxy
    put_trkchan_selector
}

proc piano_qnotelines {} {
    global ppqn midilength pianoxscale piano_vert_lines
    global piano_qnote_offset vspace
    set p .piano
    $p.canx delete all
    set bounding_box [$p.can bbox all]
    set top [lindex $bounding_box 1]
    set bot [lindex $bounding_box 3]
    $p.can delete -tag  barline
    if {$piano_vert_lines > 0} {
        set vspace [expr $ppqn*$piano_vert_lines]
        set txspace $vspace
        while {[expr $txspace/$pianoxscale] < 40} {
            set txspace [expr $txspace + $vspace]
        }
        
        
        for {set i $piano_qnote_offset} {$i < $midilength} {incr i $vspace} {
            set ix1 [expr $i/$pianoxscale]
            if {$ix1 < 0} continue
            $p.can create line $ix1 $top $ix1 $bot -width 1 -tag barline
        }
        
        for {set i $piano_qnote_offset} {$i < $midilength} {incr i $txspace} {
            set ix1 [expr $i/$pianoxscale]
            if {$ix1 < 0} continue
            $p.canx create text $ix1 5 -text [expr $piano_vert_lines*int($i/$vspace)]
        }
    }
}

proc qnote_spacing_adjustment {ppqn_incr} {
    global ppqn piano_qnote_offset
    #change ppqn and adjust piano_qnote_offset so that
    #the qnote line near left edge remains almost stationary.
    set limits [midi_limits]
    set leftedge [lindex $limits 0]
    set leftedgeqnote [expr double($leftedge - $piano_qnote_offset)/$ppqn]
    incr ppqn $ppqn_incr
    set leftedgeqnote2 [expr double($leftedge - $piano_qnote_offset)/$ppqn]
    set deltaqnote [expr $leftedgeqnote2 - $leftedgeqnote]
    set offset_adjustment [expr int($deltaqnote*$ppqn)]
    incr piano_qnote_offset $offset_adjustment
    piano_qnotelines
    .piano.txt configure -text [format "ppqn = %d" $ppqn] -foreground Black
    if {[winfo exists .beatgraph]} {beat_graph}
}

proc qnote_offset_adjustment {offset} {
    global piano_qnote_offset
    incr piano_qnote_offset $offset
    piano_qnotelines
    if {[winfo exists .beatgraph]} {beat_graph}
}

proc put_trkchan_selector {} {
    global activechan midi
    if {$midi(midishow_sep)=="track"} {
        .piano.trkchn.lab configure -text "selected tracks"} else {
        .piano.trkchn.lab configure -text "selected channels"}
    for {set i 0} {$i < 24} {incr i} {
        pack forget .piano.trkchn.$i
        if {[info exist activechan($i)]} {
            pack .piano.trkchn.$i -side left -anchor w}
    }
}





proc piano_horizontal_scroll {val} {
    .piano.can xview moveto $val
    .piano.canx xview moveto $val
}



# set binding when mouse pointer enters or leaves a note on/off bar.
proc bind_tracks {} {
    global activechan
    foreach {num} [array names activechan] {
        .piano.can bind trk$num <Enter> "highlight_track $num %x %y"
        .piano.can bind trk$num <Leave> "unhighlight_track $num"
    }
}


# change color and thickness of all note on/off bar belonging to
# the track. We need different thickness when two channels (tracks)
# overlap same note and time.
proc highlight_track {num x y} {
    global highlighted_trk
    .piano.can itemconfigure trk$num -fill red -width 3
    set highlighted_trk $num
    update_piano_txt $x $y
}


proc unhighlight_track {num} {
    global highlighted_trk
    .piano.can itemconfigure trk$num -fill black -width 2
    set highlighted_trk 0
}

#array set note {0 C  1 C#  2 D  3 D#  4 E  5 F  6 F#  7 G  8 G#  9 A   10 A# \
#  11 B } all ready done


proc midi_to_key {midipitch} {
    global note
    set midipitch [expr round($midipitch)]
    set octave [expr $midipitch/12 -1]
    set keyname $note([expr $midipitch % 12])
    return $keyname$octave
}


proc update_piano_txt {x y} {
    global pianoxscale ppqn
    global trkchan
    global midi
    focus .piano.can
    set x [.piano.can canvasx $x]
    set y [.piano.can canvasy $y]
    set pos [expr $x*$pianoxscale]
    set beat [expr $pos/$ppqn]
    set pitch [expr int(32 +(628 - $y)/8)]
    set note [midi_to_key $pitch]
    set id [.piano.can find withtag current]
    set taglist [.piano.can gettag $id]
    set trk [lindex $taglist [lsearch -glob $taglist trk*]]
    if {$midi(midishow_sep) == "channel"} {
        set trk [string replace $trk 0 2 chan]
    }
    .piano.txt configure -text [format "%s = %6.0f pulses = %4.0f beats \
            %s" $note $pos $beat $trk] -foreground Black
}


proc midi_limits {} {
    global pianoxscale
    set co [.piano.can coords mark]
    #   is there a marked region of reasonable extent ?
    set extent [expr [lindex $co 2] - [lindex $co 0]]
    if {$extent > 10} {
        set xvleft [lindex $co 0]
        set xvright [lindex $co 2]
    } else {
        #get start and end time of displayed area
        set xv [.piano.can xview]
        #puts $xv
        set scrollregion [.piano.can cget -scrollregion]
        #puts $scrollregion
        set xvleft [lindex $xv 0]
        set xvright [lindex $xv 1]
        set width [lindex $scrollregion 2]
        set xvleft [expr $xvleft*$width]
        set xvright [expr $xvright*$width]
    }
    #    puts "xvleft = $xvleft xvright=$xvright"
    
    set begin [expr round($xvleft*$pianoxscale)]
    set end [expr round($xvright*$pianoxscale)]
    if {$begin < 0} {
        set $begin 0
    }
    return [list $begin $end]
}

proc count_selected_midi_tracks {} {
    set tsel 0
    global trksel
    for {set i 0} {$i <32} {incr i} {
        if {$trksel($i)} {
            incr tsel
        }
    }
    return $tsel
}



proc midi_to_midi {sel} {
    # creates midi.tmp containing an extract from the open midi file.
    # if highlight_track selected, then only that track is copied.
    # otherwise if sel == 0 everything in the time interval is copied.
    # if sel == 1 only the selected tracks and channels are copied.
    
    global highlighted_trk
    global  midi
    global exec_out
    global trkchan
    global trksel
    global midi
    global midipulse_limits
    
    set midipulse_limits [midi_limits]
    set begin [lindex $midipulse_limits 0]
    set end   [lindex $midipulse_limits 1]
    
    if {$sel} {
        set tsel 0
        #always include track 1 because it contains the tempo and other stuff
        set trkstr "1"
        for {set i 0} {$i <32} {incr i} {
            if {$trksel($i)} {
                incr tsel
                set trkstr $trkstr,$i
            }
        }
        
        
        
    } {
        set tsel 0
    }
    
    # create tmp.mid file
    # Alway include track 1 since it includes tempo info.
    # We first delete the old file in case winamp is still playing it.
    set cmd "file delete -force -- $midi(midi_dir)/tmp.mid"
    catch {eval $cmd} pianoresult
    if {[info exist highlighted_trk] == 0} {set highlighted_trk 0}
    if {$highlighted_trk != 0} {
        # highlighted track / channel only
        if {$midi(midishow_sep) == "track"} {
            if {$highlighted_trk != 1} {
                set selvoice "-trks 1,$highlighted_trk"} else {
                set selvoice "-trks 1"}
        } else  {
            set selvoice "-chns $highlighted_trk"
        }
        
        set cmd "exec [list $midi(path_midicopy)]  $selvoice  -from $begin\
                -to $end [list $midi(midifilein)] $midi(midi_dir)/tmp.mid"
    } else {
        # all selected tracks and channels
        set cmd "exec [list $midi(path_midicopy)] -from $begin -to $end"
        if {$tsel > 0} {
            if {$midi(midishow_sep) == "track"} {
                lappend cmd -trks $trkstr} else {
                lappend cmd -chns $trkstr}
        }
        lappend cmd $midi(midifilein) $midi(midi_dir)/tmp.mid
    }
    
    #    puts $cmd
    catch {eval $cmd} miditime
    #    puts $miditime
    set exec_out midi_to_midi:\n$cmd\n\n$miditime
    #    puts $exec_out
    update_console_page
    return $miditime
}

proc startup_playmark_motion {miditime} {
    global midipulse_limits
    global playtime
    global pianoplayend
    global advance_per_50ms
    global midi
    if {!$midi(midishow_follow)} return
    if {[string length $miditime] ==  0 } return
    if {![string is double $miditime]} return
    if {$miditime < 0.01} return
    set begin [lindex $midipulse_limits 0]
    set end   [lindex $midipulse_limits 1]
    set rate [expr ($end - $begin)/$miditime]
    set advance_per_50ms [expr $rate/20.0]
    #puts "startup_playmark_motion $advance_per_50ms"
    set playtime $begin
    set pianoplayend $end
    #puts "playtime $playtime playend $pianoplayend"
    .piano.can create line -1 -1 -1 -1 -fill red -tags playmark
    
    bind .piano.can  <KeyPress> stop_playmarker
    move_playmark
}



proc move_playmark {} {
    global advance_per_50ms
    global playtime
    global pianoxscale
    global pianoplayend
    set ix [expr int($playtime/$pianoxscale)]
    .piano.can coords playmark $ix 0 $ix 720
    #puts "$playtime $ix"
    set playtime [expr $playtime + $advance_per_50ms]
    if {$playtime > $pianoplayend} {
        .piano.can coords playmark -1 -1 -1 -1
        after 0
        return
    }
    after 50 move_playmark
}

proc stop_playmarker {} {
    global pianoplayend
    global playtime
    set pianoplayend $playtime
}



proc piano_play_midi_extract {} {
    global midi
    play_midi_file  [pwd]/$midi(midi_dir)/tmp.mid
}


proc create_midi_file {} {
    midi
    midi_to_midi 1
    set filename [tk_getSaveFile]
    if {[string length $filename] > 1} {
        file rename -force $midi(midi_dir)/tmp.mid $filename
    }
}


proc create_abc_file {} {
    # This function is called by one of the action functions
    # in the midishow window.
    global midi df midi2abc_options
    global ppqn
    global exec_out
    midi_to_midi 1
    if {[winfo exist .ppqn]} {
        set midi(unitval) [expr $ppqn/2]
        unit_cmd 1
        set midi(midilden) 8
    }
    set err [check_midi2abc_options $midi(midi_dir)/tmp.mid]
    set highlighted_trk 0 ;# the track number highlighted in piano roll view
    set cmd "exec [list $midi(path_midi2abc)] $midi2abc_options"
    eval $cmd
    catch {eval $cmd} pianoresult
    set exec_out $exec_out\n$cmd\n\n$pianoresult
    #    puts $exec_out
    if {$err == 0} {
        .piano.txt configure -text "created $midi(midifileout)" -foreground red -font $df
    } else {
        .piano.txt configure -text "unable to create $midi(midifileout)" -foreground red -font $df
    }
    update_console_page
}

proc create_abc_file_and_display {} {
    global midi
    create_abc_file
    display_tunes [list $midi(midifileout)]
}

proc create_abc_file_and_play {} {
    global midi
    create_abc_file
    play_generated_abc
}

proc create_abc_and_midi {} {
    global midi exec_out miditype
    midi_to_midi 1
    set filedir [file dirname $midi(midi_save)]
    set filename [tk_getSaveFile -initialdir $filedir -filetypes $miditype]
    file rename -force $midi(midi_dir)/tmp.mid $filename
    set exec_out "$exec_out\nand renamed to $filename"
}


#end of source midishow.tcl


# Part 26.0        Midi Statistics for Midishow


#source midistats.tcl

proc pianoroll_statistics {choice} {
    global pianoresult midi
    global histogram
    global ppqn
    global trksel
    global total
    global start stop
    for {set i 0} {$i < 128} {incr i} {set histogram($i) 0}
    set limits [midi_limits]
    set start [lindex $limits 0]
    set stop  [lindex $limits 1]
    set tsel [count_selected_midi_tracks]
    
    foreach line [split $pianoresult \n] {
        if {[llength $line] != 6} continue
        set begin [lindex $line 0]
        if {[string is double $begin] != 1} continue
        if {$begin < $start} continue
        set end [lindex $line 1]
        if {$end   > $stop}  continue
        set t [lindex $line 2]
        set c [lindex $line 3]
        if {$midi(midishow_sep) == "track"} {set sep $t} else {set sep $c}
        if {$tsel != 0 && $trksel($sep) == 0} continue
        set note [lindex $line 4]
        set vel [lindex $line 5]
        switch $choice {
            pitch {set histogram($note) [expr $histogram($note)+1]}
            velocity {set histogram($vel) [expr $histogram($vel)+1]}
            duration {set index [expr int(($end - $begin)*32)]
                if {$index > 127} {set index 127}
                set histogram($index) [expr $histogram($index)+1]
            }
        }
    }
    set total 0;
    for {set i 0} {$i <128} {incr i} {
        set total [expr $total+$histogram($i)]
    }
    #puts "total = $total"
    if {$total < 1} return
    for {set i 0} {$i <128} {incr i} {
        set histogram($i) [expr double($histogram($i))/$total]
    }
}


set plotwidth 300
set plotheight 200
set xlbx 60; # left margin of bounding box
set ytbx 10; # top margin of bounding box
set xrbx [expr $xlbx + $plotwidth]
set ybbx [expr $ytbx + $plotheight]
set scanwidth [expr $xrbx+20]
set scanheight [expr $ybbx+30]

global statc

proc plotmidi_velocity_or_pitch_distribution {type} {
    global scanwidth scanheight
    global xlbx ytbx xrbx ybbx
    global histogram
    global statc
    set hgraph ""
    set maxhgraph 0.0
    for {set i 0} {$i < 128} {incr i} {
        lappend hgraph $i
        lappend hgraph $histogram($i)
        if {$histogram($i) > $maxhgraph} {set maxhgraph $histogram($i)}
    }
    set maxhgraph [expr $maxhgraph + 0.1]
    if {[winfo exists .midistats] == 0} {
        toplevel .midistats
        pack [set statc [canvas .midistats.c -width $scanwidth -height $scanheight]]\
                -expand yes -fill both
    } else {
        .midistats.c delete all}
    wm title .midistats "$type distribution"
    $statc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2 -fill white
    Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx 0.0 130 0.0 $maxhgraph
    Graph::draw_x_ticks $statc 0.0 128.0 10.0 2 0 %4.0f
    Graph::draw_y_ticks $statc 0.0 $maxhgraph 0.05 2 %3.1f
    Graph::draw_impulses_from_list .midistats.c $hgraph
}

proc show_note_distribution {} {
    global histogram
    global scanwidth scanheight
    global xlbx ytbx xrbx ybbx
    global exec_out total
    global start stop
    set exec_out "Pitch Class Distribution\n\n"
    append exec_out "from $start to $stop\n\n"
    set xpos [expr $xrbx -40]
    set notes {C C# D D# E F F# G G# A A# B}
    for {set i 0} {$i < 13} {incr i} {
        set notedist($i) 0}
    for {set i 0} {$i <128} {incr i} {
        set index [expr $i % 12]
        set notedist($index) [expr $notedist($index) + $histogram($i)]
    }
    set maxgraph 0.0
    for {set i 0} {$i < 13} {incr i} {
        if {$notedist($i) > $maxgraph} {set maxgraph $notedist($i)}
    }
    
    set maxgraph [expr $maxgraph + 0.2]
    set pitchc .pitchclass.c
    if {[winfo exists .pitchclass] == 0} {
        toplevel .pitchclass
        pack [canvas $pitchc -width $scanwidth -height $scanheight]\
                -expand yes -fill both
    } else {.pitchclass.c delete all}
    
    $pitchc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2 -fill white
    Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx 0.0 12.0 0.0 $maxgraph
    Graph::draw_y_ticks $pitchc 0.0 $maxgraph 0.1 2 %3.1f
    
    set iy [expr $ybbx +10]
    set i 0
    foreach note $notes {
        set ix [Graph::ixpos [expr $i +0.5]]
        $pitchc create text $ix $iy -text $note
        set iyb [Graph::iypos $notedist($i)]
        set count [expr round($notedist($i)*$total)]
        append exec_out  "$note $count\n"
        set ix [Graph::ixpos [expr double($i)]]
        set ix2 [Graph::ixpos [expr double($i+1)]]
        $pitchc create rectangle $ix $ybbx $ix2 $iyb -fill blue
        incr i
    }
    $pitchc create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2
    if {[winfo exist .notice]} {show_message_page $exec_out word}
}


# Part 27.0      Graphics Namespace


###   Graph ### support functions

namespace eval Graph {
    
    variable x_scale
    variable y_scale
    variable x_shift
    variable  y_shift
    variable left_edge
    variable bottom_edge
    variable top_edge
    variable right_edge
    
    
    
    namespace export set_xmapping
    proc set_xmapping {left right xleft xright} {
        variable x_scale
        variable x_shift
        variable left_edge
        variable right_edge
        set left_edge $left
        set right_edge $right
        set x_scale [expr double($right - $left) / double($xright - $xleft)]
        set x_shift [expr $left - $xleft*$x_scale]
    }
    
    namespace export set_ymapping
    proc set_ymapping {bottom top ybot ytop} {
        variable y_scale
        variable  y_shift
        variable bottom_edge
        variable top_edge
        set bottom_edge $bottom
        set top_edge $top
        set y_scale [expr double($top - $bottom) / double($ytop - $ybot)]
        set y_shift [expr $bottom - $ybot*$y_scale]
    }
    
    
    namespace export save_transform
    proc save_transform { } {
        variable x_scale
        variable x_shift
        variable y_scale
        variable y_shift
        list $x_scale $y_scale $x_shift $y_shift
    }
    
    
    namespace export restore_transform
    proc restore_transform {xfm} {
        variable x_scale
        variable x_shift
        variable y_scale
        variable y_shift
        foreach {x_scale y_scale x_shift y_shift} $xfm {}
    }
    
    
    namespace export alter_transformation
    proc alter_transformation {left right bottom top xleft xright ybot ytop} {
        set_xmapping $left $right $xleft $xright
        set_ymapping $bottom $top $ybot $ytop
    }
    
    namespace export ixpos
    proc ixpos xval {
        variable x_scale
        variable x_shift
        return [expr $x_shift + $xval*$x_scale]
    }
    
    namespace export iypos
    proc iypos yval {
        variable y_scale
        variable y_shift
        return [expr $y_shift + $yval*$y_scale]
    }
    
    
    namespace export pix_to_x
    proc pix_to_x ix {
        variable x_scale
        variable x_shift
        return [expr ($ix - $x_shift)/$x_scale]
    }
    
    namespace export pix_to_y
    proc pix_to_y iy {
        variable y_scale
        variable y_shift
        return [expr ($iy - $y_shift)/$y_scale]
    }
    
    
    namespace export draw_x_ticks
    proc draw_x_ticks {can xstart xend xstep nskip labindex fmt} {
        global df
        variable bottom_edge
        set xticks {}
        set i 0
        for {set x $xstart} {$x < $xend} {set x [expr $x + $xstep]} {
            set ix [ixpos $x]
            set xticks [concat $xticks [$can create line $ix $bottom_edge $ix \
                    [expr $bottom_edge - 5]]]
            if {[expr $i % $nskip] == $labindex} {
                set str [format $fmt $x]
                set xticks [concat $xticks [$can create text $ix \
                        [expr $bottom_edge + 20] -text $str -font $df]]
                set xticks [concat $xticks [$can create line $ix $bottom_edge $ix \
                        [expr $bottom_edge - 10]]]
            }
            incr i
        }
        set xticks
    }
    
    namespace export draw_y_ticks
    proc draw_y_ticks {can ystart yend ystep nskip fmt} {
        global df
        variable left_edge
        set i 0
        set yticks {}
        for {set y $ystart} {$y < $yend} {set y [expr $y + $ystep]} {
            set iy [iypos $y]
            set yticks [concat $yticks [$can create line  $left_edge \
                    $iy [expr $left_edge + 5] $iy]]
            if {[expr $i % $nskip] == 0} {
                set str [format $fmt $y]
                set yticks [concat $yticks [$can create text \
                        [expr $left_edge - 33] $iy -text $str -font $df]]
                set yticks [concat $yticks [$can create line \
                        $left_edge $iy [expr $left_edge + 10] $iy]]
            }
            incr i
        }
        set yticks
    }
    
    namespace export draw_x_log10ticks
    proc draw_x_log10ticks {can  start end fmt} {
        variable bottom_edge
        set xstart [expr floor($start)]
        set xend [expr floor($end)]
        for {set x $xstart} {$x<$xend} {set x [expr $x +1.0]} {
            set xval [expr pow(10.0,$x)]
            set ix [ixpos $x]
            $can create line $ix $bottom_edge $ix [expr $bottom_edge -10]
            set str [format $fmt $xval]
            $can create text $ix [expr $bottom_edge+20] -text $str
            for {set i 2} {$i<10} {incr i} {
                set xman [expr log10($i)]
                set ix [ixpos [expr $xman + $x]]
                $can create line $ix $bottom_edge $ix [expr $bottom_edge -5]
            }
        }
    }
    
    
    namespace export draw_graph_from_arrays
    proc draw_graph_from_arrays {can xvals yvals npoints} {
        upvar $xvals xdata
        upvar $yvals ydata
        set points {}
        for {set i 0} {$i < $npoints} {incr i} {
            set ix [ixpos $xdata($i)]
            set iy [iypos $ydata($i)]
            lappend points $ix
            lappend points $iy
        }
        eval {$can create line} $points
    }
    
    
    namespace export draw_graph_from_list
    proc draw_graph_from_list {can datalist} {
        #can canvas
        #datalist {x y x y x y ...}
        set points {}
        foreach {xdata ydata} $datalist {
            set ix [ixpos $xdata]
            set iy [iypos $ydata]
            lappend points $ix
            lappend points $iy
        }
        eval {$can create line} $points
    }
    
    namespace export draw_impulses_from_list
    proc draw_impulses_from_list {can datalist} {
        #can canvas
        #datalist {x y x y x y ...}
        foreach {xdata ydata} $datalist {
            if {$ydata != 0.0} {
                set points {}
                set ix [ixpos $xdata]
                set iy [iypos $ydata]
                lappend points $ix
                lappend points [iypos 0]
                lappend points $ix
                lappend points $iy
                eval {$can create line} $points
            }
        }
    }
} ;# end of namespace declaration

namespace import Graph::*


#end of midistats.tcl

#source velocitymap.tcl

proc plot_velocity_map {} {
    global pianoresult midi ppqn
    global trksel
    set velmap .midivelocity.c
    if {[winfo exists .midivelocity] == 0} {
        toplevel .midivelocity
        pack [canvas $velmap]
    } else {
        .midivelocity.c delete all}
    set limits [midi_limits]
    set start [expr double([lindex $limits 0])/$ppqn]
    set stop  [expr double([lindex $limits 1])/$ppqn]
    set delta_tick [expr int(($stop - $start)/10.0)]
    if {$delta_tick < 1} {set delta_tick 1}
    set tsel [count_selected_midi_tracks]
    $velmap create rectangle 50 20 350 200 -outline black\
            -width 2 -fill white
    Graph::alter_transformation 50 350 200 20 $start $stop 0.0 132
    Graph::draw_x_ticks $velmap $start $stop $delta_tick 2  0 %4.0f
    Graph::draw_y_ticks $velmap 0.0 132.0 8.0 2 %3.0f
    foreach line [split $pianoresult \n] {
        if {[llength $line] != 6} continue
        set begin [expr double([lindex $line 0])/$ppqn]
        if {[string is double $begin] != 1} continue
        if {$begin < $start} continue
        set end [expr double([lindex $line 1])/$ppqn]
        if {$end   > $stop}  continue
        set v [lindex $line 5]
        set t [lindex $line 2]
        set c [lindex $line 3]
        if {$midi(midishow_sep) == "track"} {set sep $t} else {set sep $c}
        if {$tsel != 0 && $trksel($sep) == 0} continue
        set ix1 [Graph::ixpos $begin]
        set ix2 [Graph::ixpos $end]
        set iy [Graph::iypos $v]
        $velmap create line $ix1 $iy $ix2 $iy -arrow last
    }
}

#end of velocitymap.tcl



#end of source stats.tcl



# Part 28.0             File type registration


#start of source abc_register.tcl

#----------------------------------------------------------------------
#
# RegisterFileType --
#
#       Register a file type on Windows
#
# Author:
#       Kevin Kenny <kennykb@acm.org>.
#       Last revised: 27 Nov 2000, 22:35 UTC
#
# Parameters:
#       extension -- Extension (e.g., .tcl) of the new type
#                    being registered.
#       className -- Class name (e.g., "tclfile") of the new type
#       textName  -- Textual name (e.g. "Tcl Script") of the
#                    new type.
#       script    -- Name of the file containing a Tcl script
#                    to run when a file of the given type is
#                    opened.  The script will receive the name
#                    of the file in [lindex $argv 0].
#
# Options:
#       -icon FILENAME,NUMBER
#               Set the icon for files of the new type
#               to be the NUMBER'th icon in the given file.
#               The file must be a full path name.
#       -mimetype TYPE
#               Set the MIME type corresponding to the new
#               file type to the specified string.
#       -new BOOLEAN
#               If BOOLEAN is true, set things up so that
#               the new file type appears in the "New" menu
#               in the Explorer and the system tray.
#       -text BOOLEAN
#               If BOOLEAN is true, the new file type contains
#               plain ASCII text of some sort.  Set the
#               Edit and Print actions to open and print
#               ASCII files.
#
# Results:
#       None.
#
# Side effects:
#       Adds the following keys to the system registry:
#
#       HKEY_CLASSES_ROOT
#         (Extension)           (Default value)         ClassName
#                               "Content Type"          MimeType        [1]
#           ShellNew            "NullFile"              ""              [2]
#         (ClassName)           (Default value)         TextName
#           DefaultIcon         (Default value)         IconName,#      [3]
#           Shell
#             Open
#               command         (Default value)         -SEE BELOW-
#             Edit
#               command         (Default value)         -SEE BELOW-     [4]
#             Print
#               command         (Default value)         -SEE BELOW-     [4]
#         MIME
#           Database
#             Content Type
#               (MimeType)      (Default value)         Extension       [1]
#
#       [1] These values are added only if the -mimetype option is used.
#       [2] This value is added only if the -new option is true.
#       [3] This value is added only if the -icon option is used.
#       [4] These values are added only if the -text option is true.
#
#       The command to open the file consists of three arguments.
#       The first is the name of the current Tcl executable.  The
#       second is the script name, and the third is "%1", which causes
#       the target file to be passed as a command-line argument.
#       The edit command is the command that opens text files, and the
#       print command is the command that prints text files.
#
#   Modified by Seymour Shlien to register abc files
#   for freewrapped scripts (i.e. *.exe files)
#----------------------------------------------------------------------


proc RegisterFileType { extension className textName script args } {
    
    set scriptype [file extension $script]
    
    package require registry
    
    # extPath is the class path for the file's extension
    
    set extPath HKEY_CLASSES_ROOT\\$extension
    registry set $extPath {} $className sz
    
    # classPath is the class path for the file's class
    
    set classPath HKEY_CLASSES_ROOT\\$className
    registry set $classPath {} $textName sz
    
    # shellPath is the shell key within classPath
    
    set shellPath $classPath\\Shell
    
    # Set up the 'Open' action
    
    set openCommand {}
    
    puts $scriptype
    if {[string equal $scriptype ".tcl"]} {
        append openCommand \" \
                [file nativename [info nameofexecutable]] \
                \" { } \" [file nativename $script] \" { } \"\$1\" { } \"%1\"
    }
    
    if {[string equal $scriptype ".exe"]} {
        append openCommand \
                \" [file nativename $script] \" { } \"\$1\" { } \"%1\"
    }
    
    #     puts "openCommand = $openCommand"
    
    registry set $shellPath\\open\\command {} $openCommand sz
    
    # Process optional args
    
    foreach {key val} $args {
        switch -exact -- $key {
            
            -mimetype {
                
                # Set up the handler for the MIME content type,
                # and add the content type item to the database
                
                registry set $extPath "Content Type" $val sz
                set mimeDbPath \
                        "HKEY_CLASSES_ROOT\\MIME\\Database"
                append mimeDbPath "\\Content Type\\" $val
                registry set $mimeDbPath Extension \
                        $extension sz
            }
            
            -icon {
                
                # Add the file icon to the shell database
                
                if {![regexp {^(.*),([^,]*)} $val \
                            junk file icon]} {
                    error "-icon option requires\
                            fileName,iconNumber"
                }
                registry set $classPath\\DefaultIcon {} \
                        [file nativename $file],$icon sz
            }
            
            -text {
                if {$val} {
                    
                    # Copy the Print action for text files
                    # into the Print action for the new type
                    
                    set textPath \
                            HKEY_CLASSES_ROOT\\txtfile\\Shell
                    if {![catch {
                            registry get \
                                    $textPath\\print\\command {}
                        } pCmd]} {
                        registry set \
                                $shellPath\\print\\command \
                                {} $pCmd sz
                        registry set \
                                $shellPath\\print {} \
                                &Print sz
                        
                    }
                    
                    # Copy the Open action for text files
                    # into the Edit action for the new type.
                    
                    if {![catch {
                            registry get \
                                    $textPath\\open\\command {}
                        } eCmd]} {
                        registry set \
                                $shellPath\\edit\\command \
                                {} $eCmd sz
                        registry set \
                                $shellPath\\edit {} \
                                &Edit sz
                    }
                }
            }
            
            -new {
                if {$val} {
                    
                    # Add the 'NullFile' action to the
                    # shell's New menu
                    
                    registry set $extPath\\ShellNew NullFile \
                            {} sz
                }
            }
            
            default {
                error "unknown option $key, must be -icon,\
                        -mimetype, -new or -text"
            }
        }
    }
}

proc associate_abc {} {
    global df
    if {[winfo exist .assoc]} return
    toplevel .assoc
    frame .assoc.1
    label .assoc.1.lab -text "associate abc files with " -font $df
    button .assoc.1.tcl -text "runabc.tcl" -font $df
    button .assoc.1.exe -text "runabc.exe" -font $df
    pack .assoc.1.lab .assoc.1.tcl .assoc.1.exe -side left
    pack .assoc.1
    frame .assoc.2
    button .assoc.2.exit -text exit -font $df -command {destroy .assoc}
    button .assoc.2.help -text help -font $df -command {
        show_message_page $hlp_associate word
        focus .abc
        raise .abc
    }
    pack .assoc.2.exit .assoc.2.help -side left
    pack .assoc.2
    
    
    bind .assoc.1.tcl <Button> {
        #puts "for assoc.tcl"
        if {$tcl_platform(platform) == "windows"} {
            if {[glob -nocomplain runabc.tcl] != ""} {
                registry set "HKEY_LOCAL_MACHINE\\Software\\runabc" \
                        InstallDir "[pwd]"
                RegisterFileType .abc "ABCfile" "ABC Music File" [pwd]/runabc.tcl \
                        -text 1 -icon [file normalize [pwd]/runabc.ico],0
                .assoc.2.exit configure -text "File Association done, click to exit"
            } else {
                .assoc.2.exit configure -text "Run this script in the same dir as runabc.tcl"
            }
        } else {
            .assoc.2.exit configure -text "Only for Windows! Click to Exit"
        }
    }
    
    bind .assoc.1.exe <Button> {
        #puts "for assoc.exe"
        if {$tcl_platform(platform) == "windows"} {
            if {[glob -nocomplain runabc.exe] != ""} {
                registry set "HKEY_LOCAL_MACHINE\\Software\\runabc" \
                        InstallDir "[pwd]"
                RegisterFileType .abc "ABCfile" "ABC Music File" [pwd]/runabc.exe \
                        -text 1 -icon [file normalize [pwd]/runabc.ico],0
                .assoc.2.exit configure -text "File Association done, click to exit"
            } else {
                .assoc.2.exit configure -text "Run this script in the same dir as runabc.exe"
            }
        } else {
            .assoc.2.exit configure -text "Only for Windows! Click to Exit"
        }
    }
}

set hlp_associate "For Windows only -- associate abc files with runabc\n\n\
        This function modifies the windows registry in order to set up an association\
        between an abc file and either runabc.tcl or runabc.exe. Once this is done,\
        the abc files will have a new icon displaying runabc and double clicking on an\
        abc file will automaticly start up runabc and load up this abc file.\
        If runabc is already running, then double clicking on an abc file\
        will load that file in the current running process.\n\n\
        Normally it is only necessary to create this association once. The\
        association remains permanent (unless changed by another abc application).\
        If you later decide to move runabc to a new directory, then it is necessary\
        to reestablish the association the same way. If at sometime you wish to \
        destroy or change this association, you can do this by going to\
        'Folder Options' which is accessed from the file manager under the menu\
        item view or toolbar or somthing else (depending on which version \
        of Windows you are running -- 95,98,ME,etc.); then select 'File Types'\
        find ABC, select it and take the appropriate action (eg remove).\n\n\
        When you double click on abc file, windows starts up runabc and loads up\
        the selected abc file. However, the current directory is the same directory\
        where the abc file was found. This poses a problem, since the runabc.ini and\
        tmp directory is normally in the same directory as where runabc was installed.\
        To fix this problem, this function also stores the path name to the runabc\
        install directory in the registry. Runabc determines whether runabc.tcl or\
        runabc.exe are found in the current directory. If they are not found, then\
        runabc looks in the registry to find out where they are located and changes\
        the current directory to this location. Now it is possible to load and\
        store the correct runabc.ini file."

#end of source abc_register.tcl


# Part 29.0         Mftext interface

#source mftextwin.tcl

proc mftextwindow {} {
    global midi df
    global mfnotes mftouch mfcntl mfprog mfmeta
    set f .mftext
    if {[winfo exist $f] == 0} {
        toplevel $f
        frame $f.1
        entry $f.1.filent -text midi(midifilein) -font $df -width 30
        $f.1.filent xview moveto 1.0
        button $f.1.browse -text browse -font $df -command {midi_file_browser
            .mftext.1.filent xview moveto 1.0
            output_mftext}
        button $f.1.help -text help -font $df\
                -command {show_message_page $hlp_mftext word}
        pack $f.1.filent $f.1.browse $f.1.help -side left
        frame $f.2
        pack $f.1 $f.2 -side top
        bind .mftext.1.filent <Return> {focus .mftext.1
            output_mftext}
        set f .mftext.4
        frame $f
        label $f.lab -text hide -font $df
        set mfnotes 0
        set mftouch 0
        set mfprog  0
        set mfmeta  0
        set mfcntl  0
        checkbutton $f.note -variable mfnotes  -text notes      -font $df\
                -command mfnotescmd
        checkbutton $f.touch -variable mftouch -text aftertouch -font $df\
                -command mftouchcmd
        checkbutton $f.prog  -variable mfprog  -text program    -font $df\
                -command mfprogcmd
        checkbutton $f.meta  -variable mfmeta  -text metatext   -font $df\
                -command mfmetacmd
        checkbutton $f.cntl  -variable mfcntl  -text cntl       -font $df\
                -command mfcntlcmd
        pack $f.lab $f.note $f.touch $f.prog $f.meta $f.cntl -side left
        pack $f -side top -anchor w
    }
    output_mftext
}


proc output_mftext {} {
    global midi exec_out
    global df elidetrk
    global mfnotes mftouch mfcntl mfprog mfmeta
    set mfnotes 0
    set mftouch 0
    set mfprog  0
    set mfmeta  0
    set mfcntl  0
    if {[winfo exist .mftext.3]} {
        destroy .mftext.3
        .mftext.2.txt tag delete everywhere
        destroy .mftext.2.txt .mftext.2.scroll
        if {[info exist elidetrk]} {unset elidetrk}
    }
    if {[winfo exist .mftext.31]} {destroy .mftext.31}
    text .mftext.2.txt -yscrollcommand {.mftext.2.scroll set} -width 52 -font $df
    scrollbar .mftext.2.scroll -orient vertical -command {.mftext.2.txt yview}
    pack .mftext.2.txt .mftext.2.scroll -side left -fill y
    frame .mftext.3
    frame .mftext.31
    label .mftext.3.lab -text hide -font $df
    pack .mftext.3.lab -side left
    pack .mftext.3 -side top -anchor w
    pack .mftext.31 -side top -anchor w
    set f .mftext.2.txt
    set cmd "exec [list $midi(path_midi2abc)] [list $midi(midifilein)] -mftext"
    catch {eval $cmd} mftextresults
    set exec_out $mftextresults
    if {[string first "no such" $exec_out] >= 0} {abcmidi_no_such_error $midi(path_midi2abc)}
    #$f delete 1.0 end
    set mflines [split $mftextresults \n]
    foreach line $mflines {
        tag_and_insert_mftext_line $line
    }
}


proc tag_and_insert_mftext_line {line} {
    global df
    global trktag
    global elidetrk
    set f .mftext.2.txt
    set pat \[A-Za-z\]+
    set linelist [split $line]
    set type ""
    .mftext.2.txt tag configure blue -foreground blue
    if {[string equal [lindex $linelist 0] "Track"]} {
        set trk [lindex $linelist 1]
        set trktag t$trk
        $f insert end $line\n blue
        if {$trk < 10} {
            checkbutton .mftext.3.$trk -text $trktag -font $df\
                    -command [list elide_reveal_track $trk]  -variable elidetrk($trk)
            pack .mftext.3.$trk -side left
        } else {
            checkbutton .mftext.31.$trk -text $trktag -font $df\
                    -command [list elide_reveal_track $trk]  -variable elidetrk($trk)
            pack .mftext.31.$trk -side left
        }
    } else {
        regexp $pat $linelist keyword
        switch $keyword {
            Note {set type note}
            Pressure {set type touch}
            Pitchbnd {set type touch}
            Metatext {set type meta}
            Program  {set type prog}
            Chanpres {set type touch}
            CntlParm {set type cntl}
        }
        if {[info exist trktag]} {
            $f insert end $line\n [list $trktag $type]
        } else {
            $f insert end $line\n $type
        }
        #puts $keyword
    }
}


proc elide_reveal_track no {
    global elidetrk
    .mftext.2.txt tag configure t$no -elide $elidetrk($no)
    .mftext.2.txt tag raise t$no
    #puts "elidetrk($no) = $elidetrk($no)"
}

proc mfnotescmd {} {
    global mfnotes
    .mftext.2.txt tag configure note -elide $mfnotes
    .mftext.2.txt tag raise note
}

proc mftouchcmd {} {
    global mftouch
    .mftext.2.txt tag configure touch -elide $mftouch
    .mftext.2.txt tag raise touch
}

proc mfprogcmd {} {
    global mfprog
    .mftext.2.txt tag configure prog -elide $mfprog
    .mftext.2.txt tag raise  prog
}

proc mfmetacmd {} {
    global mfmeta
    .mftext.2.txt tag configure meta -elide $mfmeta
    .mftext.2.txt tag raise meta
}

proc mfcntlcmd {} {
    global mfcntl
    .mftext.2.txt tag configure cntl -elide $mfcntl
    .mftext.2.txt tag raise cntl
}

set hlp_mftext "mftext window\n\n\
        This window shows a textual representation of the MIDI\
        file specified in the entry box. This should look similar\
        to the mftext output of a MIDI file. If you see a midi2abc\
        output of the MIDI file instead, then you probably do not\
        have midi2abc.exe version 2.87 or higher. You can determine\
        which version you are linked to my running config/sanity check.\n\n\
        The checkbuttons at the bottom of the screen allow you\
        to hide or reveal the output for the specified tracks\
        (t1, t2, etc) or specified MIDI commands.  Tcl/tk elides either\
        tracks or MIDI command types. Combinations of both yield\
        strange results.\n\n The number on the left is the beat number,\
        usually quarter notes. The channel number is usually placed after\
        the MIDI command. Aftertouch commands include pitchbend and pressure\
        MIDI commands."

#end of source mftextwin.tcl


# Part 30.0             Incipits file support functions


#source copybar.tcl

proc copy_tunes {abchandle nbars outhandle noX} {
    # copies the first nbars of every voice
    # in a abc file. Method: count number
    # of bars in each voice and suppress output
    # for bar numbers greater than nbars.
    
    # to handle any header text
    set no 0
    set barcount($no) 0
    set firstX 1
    set nchars 0 ;# protection file file runover
    set barmax $nbars
    set p {\|+}
    while {![eof $abchandle]} {
        set line  [gets $abchandle]
        if {[string length $line] > 0 } {
            if {[string equal [string range $line 0 1] "X:"]} {
                if {[info exist barcount]} {unset barcount}
                set no 0
                set barcount($no) 0
                if {!$noX || $firstX} {
                    puts $outhandle ""
                    puts $outhandle $line; incr nchars 10
                    set firstX 0
                }
                incr nchars
                continue
            }
            set vindex [string first V: $line]
            if {$vindex > -1} {
                set remainline [string range $line [expr $vindex+2] end]
                regexp {\w+} $remainline no
                if {![info exist barcount($no)]} {set barcount($no) 0}
            }
            
            # allow field commands to go through if bar count less than barmax
            set initial [string index $line 0]
            set next [string index $line 1]
            if {[string first $initial ABCDEFGHIKLMNOPQRSTUVWwXZ]
                >= 0 && $next == ":" } {
                if {$barcount($no) < $barmax} {puts $outhandle $line; incr nchars 10}
                if {$nchars > 500000} return
                continue
            }
            
            # handle body one character at a time
            if   {$barcount($no) >= $barmax} {continue} else {
                for {set i 0} {$i < [string length $line]} {incr i} {
                    set char [string index $line $i]
                    if {$char == "|"} {incr barcount($no)}
                    puts -nonewline $outhandle $char
                    incr nchars
                    if {$nchars > 500000} return
                    if {$barcount($no) >= $barmax} {
                        break
                    }
                }
                #           gets stdin
                puts $outhandle ""
                if {$nchars > 500000} return
                incr nchars
            }
        }
        
    }
}

#set filehandle [open [lindex $argv 0] "r"]
#copy_tune $filehandle 6

set incipits_length 8
set incipits_noX 0
set w .abc.incipits
frame $w
frame $w.1
label $w.1.2 -text "Create file of incipits" -font $df
frame $w.2
label $w.2.1 -text "number of bars" -font $df
scale $w.2.2 -from 0 -to 16 -length 100 -orient horizontal \
        -font $df -variable incipits_length
checkbutton $w.2.3 -text "to single tune" -variable incipits_noX -font $df
frame $w.3
button $w.3.1 -text "to file" -font $df -command incipits_to_file
button $w.3.2 -text "to TclAbcEditor" -font $df -command incipits_to_TclAbcEditor
pack $w.1.2 -side left
pack $w.2.1 $w.2.2 $w.2.3 -side left -anchor w
pack $w.3.1 $w.3.2 -side left -anchor w
pack $w.1 $w.2 $w.3 -side top

set hlp_incipits "Create file of incipits\n\n\
        The function will copy the first few bars of all the tunes\
        in the table of contents to a designated file or place it\
        in the TclAbcEditor buffer. If the checkbox 'to single tune'\
        is ticked, all the incipits will be stuffed into a single\
        tune. This produces the most compact Postscript file when\
        abcm2ps is executed on the output file and also allows you\
        to put all the incipits in one MIDI file. If the checkbox is\
        not ticked then each incipit goes into a separate tune and\
        all the X: reference numbers are preserved. The number of\
        bars in the incipit can be configured using the scale widget.\n\n\
        For multivoiced files, the first few bars of each voice will be\
        copied. The function handles inline voice commands eg \[V:2\]\
        but they should be placed at the beginning of the line.\n\n\
        If you want to produce incipits for any a selection of tunes,\
        first copy the selected tunes to a separate abc file using\
        runabc edit/copy command and then load that file into the TOC."

proc show_incipits_page {} {
    global active_sheet
    remove_old_sheet
    if {$active_sheet == "incipits"} {
        set active_sheet "none"
    } else {
        pack .abc.incipits
        set active_sheet incipits}
}

proc incipits_to_TclAbcEditor {} {
    global midi incipits_length incipits_noX
    set outhandle [open $midi(abc_default_file) w]
    set inhandle  [open $midi(abc_open) r]
    copy_tunes $inhandle $incipits_length $outhandle $incipits_noX
    close $outhandle
    close $inhandle
    tcl_abc_edit $midi(abc_default_file) 1
}

proc incipits_to_file {} {
    global midi incipits_length incipits_noX
    set types {{{abc files} {*.abc}}
        {{all} {*}}}
    set filedir [file dirname $midi(abc_default_file)]
    set filename [tk_getSaveFile -initialdir $filedir \
            -filetypes $types]
    if {[string length $filename] == 0} return
    if {[string compare  $midi(abc_open) $filename] == 0} {
        tk_messageBox -message "do not even think of writing over the input file" \
                -type ok
        return
    }
    set outhandle [open $filename w]
    set inhandle  [open $midi(abc_open) r]
    copy_tunes $inhandle $incipits_length $outhandle $incipits_noX
    close $outhandle
    close $inhandle
}
#end of source copybar.tcl



# source playall.tcl

proc play_entire_edit_window {verbatim} {
    global midi exec_out files
    global body_start body_end
    global abctxtw
    set dir "[pwd]/$midi(midi_dir)"
    set files ""
    set sel ""
    lappend files $dir/X1.mid
    set cmd "file delete [glob -nocomplain $dir/X*.mid]"
    catch {eval $cmd}
    set out_fd [open $midi(midi_dir)/X.tmp w]
    set nlines [lindex [split [$abctxtw index end] .] 0]
    for {set i 1} {$i <= $nlines} {incr i} {
        set value [$abctxtw get $i.0 $i.end]
        puts $out_fd $value
        if {[string equal [string range $value 0 1] "X:"]} {
            regexp {[0-9]+} $value number
            lappend sel $number
            if {!$verbatim} {write_midi_codes $out_fd
                puts $out_fd "Q:1/4 = $midi(tempo)"
            }
        }
    }
    close $out_fd
    set cmd "exec $midi(path_abc2midi) $midi(midi_dir)/X.tmp"
    catch {eval $cmd} exec_out
    set exec_out $cmd\n\n$exec_out
    set files [glob $dir/X*.mid]
    play_midis $sel
    update_console_page
}

#end of source playall.tcl


# Part 31.0            Beat Graph and Unique Chords for Midishow

#source beatgraph.tcl

proc beat_graph {} {
    global scanwidth scanheight
    global xlbx ytbx xrbx ybbx
    global pianoresult ppqn
    
    set nrec [llength $pianoresult]
    set midilength [lindex $pianoresult [expr $nrec -6]]
    
    set limits [midi_limits]
    set start [expr double([lindex $limits 0])/$ppqn]
    set stop  [expr double([lindex $limits 1])/$ppqn]
    set tsel [count_selected_midi_tracks]
    
    set bgraph .beatgraph.c
    if {[winfo exists .beatgraph] == 0} {
        toplevel .beatgraph
        pack [canvas .beatgraph.c -width $scanwidth -height $scanheight]\
                -expand yes -fill both
    } else {.beatgraph.c delete all}
    
    if {$start > 1.0} {set start [expr $start -1.0]}
    set delta_tick [expr int(($stop - $start)/10.0)]
    if {$delta_tick < 1} {set delta_tick 1}
    $bgraph create rectangle $xlbx $ytbx $xrbx $ybbx -outline black\
            -width 2 -fill white
    Graph::alter_transformation $xlbx $xrbx $ybbx $ytbx $start $stop -0.0625 1.0
    Graph::draw_x_ticks $bgraph $start $stop $delta_tick 2 0 %3.0f
    Graph::draw_y_ticks $bgraph 0.0 1.0 0.125 2 %3.2f
    
    set i 0
    foreach line [split $pianoresult \n] {
        set onset [expr double([lindex $line 0])/$ppqn]
        if {$onset < $start} continue
        if {$onset > $stop} break
        set beat [expr floor($onset)]
        set frac [expr $onset - $beat]
        #  puts "$beat $frac"
        incr i
        set ix [Graph::ixpos $beat]
        set iy [Graph::iypos $frac]
        $bgraph create rectangle $ix $iy [expr $ix +1] [expr $iy +1] -fill black
    }
}
# end source beatgraph.tcl


#source uniquechords.tcl

#wuniquechords.tcl
#list combination notes which are on at the same time

set maxchordlength 3

proc list_unique_chords_window {} {
    global df
    
    if {[winfo exist .chordstats]} return
    set w .chordstats
    toplevel $w
    
    frame $w.file
    button $w.file.list -text chordlist -font $df  -command "make_and_display_chords 0"
    button $w.file.class -text chordclasses  -font $df -command "make_and_display_chords 1"
    scale $w.file.size -variable maxchordlength -orient vertical -length 40\
            -from 1 -to 10 -label "max chord size" -font $df
    pack  $w.file.size $w.file.list $w.file.class -side left
    pack $w.file
    
    frame $w.chords
    text $w.chords.t -width 70 -height 20 -yscrollcommand {.chordstats.chords.ysbar set} -font $df
    scrollbar $w.chords.ysbar -orient vertical -command {.chordstats.chords.t yview}
    pack $w.chords.t -side left
    pack $w.chords.ysbar -side left -fill y
    pack $w.chords
    
    
    $w.chords.t configure -tabs "180 left 360 left 540 left 720 left"
}


proc compare_onset {a b} {
    set a_onset [lindex $a 0]
    set b_onset [lindex $b 0]
    if {$a_onset > $b_onset} {
        return 1}  elseif {$a_onset < $b_onset} {
        return -1} else {return 0}
}

array set note {0 C  1 C#  2 D  3 D#  4 E  5 F  6 F#  7 G  8 G#  9 A   10 A# \
            11 B }


proc midi_to_pitchclass {midipitch} {
    global note
    set midipitch [expr round($midipitch)]
    set keyname $note([expr $midipitch % 12])
    return $keyname
}



proc label_notelist {notelist} {
    set labeled_list ""
    foreach elem $notelist {
        set labeled_list "$labeled_list [midi_to_key $elem]"
    }
    return $labeled_list
}

proc label_pitchlist {pitchlist} {
    set labeled_list ""
    foreach elem $pitchlist {
        set labeled_list "$labeled_list [midi_to_pitchclass $elem]"
    }
    return $labeled_list
}

set notelist {}



proc count_chords {chord} {
    global chordcount
    global total_chordcount
    if {[info exist chordcount($chord)]} {
        incr chordcount($chord)
    } else {
        set chordcount($chord) 1
    }
    incr total_chordcount
}

proc chord_instants {chord instant} {
    global chordtimes
    if {[info exist chordtimes($chord)]} {
        lappend chordtimes($chord) $instant
    } else {
        set chordtimes($chord) $instant
    }
}


proc print_chordcount_by_size {} {
    global chordcount
    global total_chordcount
    set chordcountlist [array get chordcount]
    #puts "$total_chordcount chords [expr [llength $chordcountlist]/2] unique chords"
    for {set i 0} {$i < 6} {incr i} {
        set chordlist {}
        foreach {chord count} $chordcountlist {
            if {[llength [split $chord " "]] == $i} {
                lappend chordlist $chord $count
            }
        }
        foreach {chord count} $chordlist {
            puts "$chord $count"
            
        }
    }
}

proc print_chordcount_by_key {w} {
    global chordcount
    global total_chordcount
    set chordcountlist [array get chordcount]
    #puts "$total_chordcount chords [expr [llength $chordcountlist]/2] unique chords"
    
    set chordlist {}
    foreach {chord count} $chordcountlist {
        lappend chordlist $chord
    }
    
    set sortedchordlist [lsort $chordlist]
    set i 0
    set nrows [expr 1+ [llength $sortedchordlist] /2]
    foreach chord $sortedchordlist {
        set j [expr ($i % $nrows)+1]
        set n [expr $i/ $nrows]
        if {$n == 0} {
            $w.chords.t insert $j.0  "$chord $chordcount($chord)\n"
        } else {
            $w.chords.t insert $j.end  "\t$chord $chordcount($chord)"
        }
        incr i
    }
}

proc print_chordinstants {} {
    global chordtimes
    set chordtimeslist [array get chordtimes]
    puts "[llength $chordtimeslist] distinct chord instances"
    foreach {chord instants} $chordtimeslist {
        puts "$chord $instants"
    }
}

proc reorganize_midicmd {} {
    global midicmds
    global sorted_midiactions
    set midiactions {}
    foreach midi $midicmds {
        set onset [lindex $midi 0]
        set stop  [lindex $midi 1]
        set pitch [lindex $midi 4]
        lappend midiactions [list $onset $pitch 1]
        lappend midiactions [list $stop  $pitch 0]
    }
    set sorted_midiactions [lsort -command compare_onset $midiactions]
}


proc turn_off_all_notes {} {
    global notestatus
    for {set i 0} {$i < 128} {incr i } {
        set notestatus($i) 0}
}

proc turn_off_all_pitches {} {
    global pitchstatus
    for {set i 0} {$i < 12} {incr i} {
        set pitchstatus($i) 0}
}


proc list_on_notes {maxlength} {
    global notestatus
    set notelist {}
    set j 0
    for {set i 0} {$i < 128} {incr i } {
        if {$j >= $maxlength} break
        if {$notestatus($i)} {lappend notelist $i
            incr j}
    }
    return $notelist
}

proc list_on_pitches {} {
    global pitchstatus
    set notelist {}
    for {set i 0} {$i < 12} {incr i} {
        if {$pitchstatus($i)} {lappend notelist $i}
    }
    return $notelist
}



proc switch_note_status {midicmd} {
    global notestatus
    set notestatus([lindex $midicmd 1]) [lindex $midicmd 2]
    #puts "notestatus([lindex $midicmd 1]) = $notestatus([lindex $midicmd 1])"
}

proc set_pitch_status {} {
    global notestatus pitchstatus
    turn_off_all_pitches
    for {set i 0} {$i < 128} {incr i} {
        if {$notestatus($i)} {
            set pitch [expr $i % 12]
            set pitchstatus($pitch) 1
        }
    }
}

proc make_and_display_chords {pitchclass} {
    global midi
    global sorted_midiactions
    global total_chordcount
    global midicmds
    global chordcount
    global maxchordlength
    global ppqn
    
    set limits [midi_limits]
    set start [lindex $limits 0]
    set stop  [lindex $limits 1]
    #puts "start stop = $start $stop"
    set tsel [count_selected_midi_tracks]
    
    set exec_options  "-midigram"
    set cmd "exec [list $midi(path_midi2abc)] [list $midi(midifilein)]  $exec_options"
    set w .chordstats
    $w.chords.t delete 0.0 end
    
    catch {eval $cmd} midi2abc_output
    #puts $cmd
    #puts $midi2abc_output
    set midicmds [split $midi2abc_output \n]
    reorganize_midicmd
    turn_off_all_notes
    turn_off_all_pitches
    array unset chordcount
    
    set last_time 0.0
    set i 0
    set total_chordcount 0
    global total_chordcount
    
    
    foreach midiunit $sorted_midiactions {
        set begin [lindex $midiunit 0]
        if {[string is double $begin] != 1} continue
        if {$begin < $start} continue
        set end [lindex $midiunit 0]
        if {$end   > $stop}  continue
        
        #  if {$i > 40} break
        incr i
        set present_time [lindex $midiunit 0]
        if {[expr $present_time - $last_time] > 0.2} {
            if {$pitchclass} {
                set onlist [list_on_pitches]
                set chordstring [label_pitchlist $onlist]
            } else {
                set onlist [list_on_notes $maxchordlength]
                set chordstring [label_notelist $onlist]
            }
            
            count_chords $chordstring
            set last_time $present_time
        }
        
        switch_note_status $midiunit
        if {$pitchclass} set_pitch_status
    }
    print_chordcount_by_key $w
}


proc unique_chords {} {
    list_unique_chords_window
    make_and_display_chords 0
}

#end of source uniquechords.tcl

proc display_entire_edit_window {} {
    global midi exec_out files
    global body_start body_end
    global abctxtw
    set dir "[pwd]/$midi(midi_dir)"
    set files ""
    set sel ""
    lappend files $dir/X1.mid
    set cmd "file delete [glob -nocomplain $dir/X*.mid]"
    catch {eval $cmd}
    set out_fd [open $midi(midi_dir)/X.tmp w]
    set nlines [lindex [split [$abctxtw index end] .] 0]
    for {set i 1} {$i <= $nlines} {incr i} {
        set value [$abctxtw get $i.0 $i.end]
        puts $out_fd $value
    }
    close $out_fd
    display_tunes [list $midi(midi_dir)/X.tmp]
}

#source pianops.tcl

proc piano_window_ps_output {} {
    #This function creates a postscript file of the exposed
    #piano roll display. It temporarily annotates the vertical
    #and horizontal scale. Creates the postscript file and
    #then erases the annotation. Most of the global variables
    #are shared with the functions compute_pianoroll and
    #piano_qnote listes
    global piano_qnote_offset midilength pianoxscale vspace
    global piano_vert_lines vspace
    global df
    set pdf [list Helvetica 14]
    set fontMap($df) $pdf
    
    set xv [.piano.can xview]
    #puts $xv
    set scrollregion [.piano.can cget -scrollregion]
    #puts $scrollregion
    set xvleft [lindex $xv 0]
    set xvright [lindex $xv 1]
    set width [lindex $scrollregion 2]
    set height [lindex $scrollregion 3]
    set xvleft [expr $xvleft*$width]
    set xvright [expr $xvright*$width]
    set yv [.piano.can yview]
    set ytop [lindex $yv 0]
    set ybot [lindex $yv 1]
    
    set ytop [expr $ytop * $height]
    set ybot [expr $ybot * $height]
    #puts $scrollregion
    #puts "$xvleft $xvright"
    #puts "$ytop $ybot"
    set ixleft [expr int($xvleft)]
    set iybot [expr int($ybot+1)]
    set ixright [expr int($xvright)]
    set ixright2 [expr $xvright +6]
    set iybot2 [expr $iybot -20]
    set iybot3 [expr $iybot -10]
    set iytop [expr int($ytop-1)]
    set iytop2 [expr $ytop -9]
    set ixleft2 [expr $ixleft + 22]
    #clear some space for the annotation
    .piano.can create rectangle $ixleft $iybot $ixright $iybot2 \
            -fill white -outline "" -tag ps
    .piano.can create rectangle $ixleft $iybot $ixleft2 $iytop  \
            -fill white -outline "" -tag ps
    .piano.can create rectangle $ixleft $iytop $ixright $iytop2 \
            -fill white -outline "" -tag ps
    .piano.can create rectangle $ixright $iybot $ixright2 $iytop  \
            -fill white -outline "" -tag ps
    #put everything in a box
    .piano.can create rectangle $ixleft2 $iybot2 $ixright $iytop -outline black -width 2 -tag ps
    
    #label x axis
    set txspace $vspace
    for {set i $piano_qnote_offset} {$i < $midilength} {incr i $txspace} {
        set ix1 [expr $i/$pianoxscale]
        if {$ix1 < 0} continue
        .piano.can create text $ix1 $iybot3 -text [expr $piano_vert_lines*int($i/$vspace)] -tag ps -font $df
    }
    
    #label y axis
    set ix [expr $ixleft +10]
    for {set i 0} {$i <89} {incr i} {
        set j [expr ($i+8)%12]
        
        set iy [expr 724 -$i*8]
        if {$iy >$iybot} continue
        if {$iy <$iytop} continue
        
        if {$j == 0} {
            set octave [expr $i/12 + 1]
            set legend [format "C%d" $octave]
            .piano.can create text $ix $iy -text $legend -tag ps -font $df
        }
        if {$j == 5} {
            set octave [expr $i/12 + 1]
            set legend [format "F%d" $octave]
            .piano.can create text $ix $iy -text $legend -tag ps -font $df
        }
    }
    
    
    set height [expr $iybot - $iytop +1]
    set width [expr $ixright -$ixleft ]
    .piano.can postscript -file piano.ps -y [expr $iytop - 1] \
            -height $height -fontmap fontMap -x [expr $ixleft +2] -width $width
    .piano.can delete -tag ps
    .piano.txt configure -text [format "piano.ps was created"] -foreground Black
}
# source pianops.tcl ends here




# Part 32.0         Solfege vocalization for abc editor

#source vocalize.tcl
# vocalize.tcl
#adds vocalization in w: lyrics.
#does not support accidentals.

set notekey "CDEFGABcdefgab"


proc solfege_vocalization {} {
    global abctxtw
    global body_start body_end
    set point [$abctxtw index insert]
    if {![info exist body_end]} return
    if {$point > $body_end} {set point $body_start.0}
    set keysig none
    set kfield [$abctxtw search -backwards K: $point]
    if {[string length $kfield] > 1} {
        set kfield [$abctxtw get $kfield  "$kfield lineend"]
        set keysig [string range $kfield 2 end]
        set keysig [string trimright $keysig]
    }
    #puts "keysig = $keysig"
    set tonic [key2number $keysig]
    
    set selrange [$abctxtw tag ranges sel]
    if {[llength $selrange] < 2} {
        messages "Please select an area in the body of the tune \
                and then try again. To select a region, hold the left mouse button \
                down and sweep an area."
        return
    } else {
        set selstart [lindex $selrange 0]
        set selend [lindex $selrange 1]
        
        set lselstart [lindex [split $selstart .] 0]
        set lselend  [lindex [split $selend .] 0]
        
        #puts "region $lselstart to $lselend"
        for {set linenum $lselend} {$linenum >= $lselstart} {incr linenum -1} {
            set line [$abctxtw get $linenum.0 $linenum.end]
            #puts $line
            if {[string length $line] < 2} continue
            set vocalization [vocalize_all_notes $line $tonic]
            $abctxtw insert [expr $linenum+1].0 $vocalization
        }
        $abctxtw tag remove sel 0.0 end
    }
}

proc vocalize_all_notes {buffer tonic} {
    #scans line for musical notes and shifts it up or down.
    #In order to continue from where we left off, we strip
    #off the part of string that we have already scanned,
    #  puts vocalize_all_notes
    set note_or_bar {[|]|[A-G]\,*|[a-g]\'*}
    # decorations regex explained:
    # (?n) - honor lines:  ^ and $
    # (\![^\!]*\!)           - !decoration!
    # (^[ \t]*%.*$)          - comment lines (lines beginning with %)
    # (^[ \t]*[A-Za-z]:.*$)  - keyword lines
    # (\![^\!]*\!)           - !decoration!
    # (\[[ \t]*\"[^\"]*\"))  - part strings "part1"   (probably should be any strings, including guitar chords)
    #   (\"[^\"]*\")         - guitar chords
    #   (\[.:[^]]*\])       - inline field command like [K: Gm]
    set decoration {(?n)((\![^\!]*\!)|(^[ \t]*%.*$)|(^[ \t]*[A-Za-z]:.*$)|(\[[ \t]*\"[^\"]*\"))|(\"[^\"]*\")|(\[.:[^]]*\])}
    set success 1
    set offset 0
    set result "w: "
    set space " "
    set start 0
    #  puts $buffer
    while {$success} {
        set success [regexp -indices $note_or_bar $buffer match]
        if {!$success} break
        set skip [regexp -indices $decoration $buffer match_skip]
        # if the decoration comes before the note then skip the decoration
        if {$skip && [lindex $match_skip 0] < [lindex $match 0]} {
            #    puts "match match_skip $match $match_skip"
            set pos2 [lindex $match_skip 1]
            set offset [expr $pos2 + 1]
            set buffer [string range $buffer $offset end]
        } else {
            set pos1 [lindex $match 0]
            set pos2 [lindex $match 1]
            set key [string range $buffer  $pos1 $pos2]
            #    puts $key
            if {$key != "|"}  {
                set result $result[vocalize_note $key $tonic]$space
                set start 1
            } else {
                # suppress bar line prior to first note
                if {$start > 0}  {
                    set result $result$key$space
                }
            }
            #puts "$key $vocal"
            set buffer [string range $buffer [expr $pos2 +1] end]
        }
    }
    # puts $result
    return $result\n
}


proc vocalize_note {note tonic} {
    global notekey
    set vocalization "do re me fa so la ti"
    set n1 [string first [string index $note 0] $notekey]
    set n [expr $n1 % 7]
    set n [expr $n - $tonic]
    if {$n < 0} {set n [expr $n + 7]}
    #puts "$note $n1 $n"
    set result [lindex $vocalization $n]
    return $result
}


proc key2number {keysig} {
    #from key signature computes number of sharps/flats, mode
    #and first key in scale.
    global notekey
    set s [regexp {([A-G]|none)(#*|b*)(.*)} $keysig match tonic sub2 sub3]
    if {$s < 1} {puts "can't understand key signature $keysig"
        return}
    #puts "$tonic $sub2 $sub3"
    set n1 [string first [string index $tonic 0] $notekey]
    set n [expr $n1 % 7]
    #puts "unadjusted tonic $n"
    if {[string compare $tonic "none"] == 0} {set tonic C}
    if {[string length $sub3] > 0} {set sub3 [string tolower $sub3]}
    if {[string length $sub3] > 3} {set sub3 [string range $sub3 0 2 ]}
    set mode [lsearch -exact "maj min m aeo loc ion dor phr lyd mix" $sub3]
    if {$mode == -1} {set mode 0}
    #puts "mode = $mode"
    if {$mode >= 0} {set tonic \
                [expr $n -  [lindex "0 5 5 5 6 0 1 2 3 4" $mode]]
        set tonic [expr $tonic % 7]
    }
    
    #puts "tonic is $tonic"
    return $tonic
}
#end of source vocalize.tcl


# Part 33.0        Drum Editor



#source drumeditor.tcl



proc get_drumpattern {} {
    global active_drumpattern
    global drumpatterns
    global cabcbar
    set cabcbar $drumpatterns(D$active_drumpattern)
    drum_bar_to_drumhits $cabcbar
}



set invfactor(*2) 1/2
set invfactor(*1) 1
set invfactor(/2) 2
set invfactor(/4) 4
global invfactor

proc drum_bar_to_drumhits {bar} {
    global revpatch drumtoolfactor midi
    global invdrummap
    global invfactor
    set notepat {(\^*|_*|=?)([A-G]\,*|[a-g]|\]|\[|z)(/?[0-9]*|[0-9]*/*[0-9]*)}
    set selected_drums $midi(selected_drums)
    set i 0
    set col 0
    set chord "off"
    clear_all
    while {$i < [string length $bar]} {
        set success [regexp -indices -start $i $notepat $bar location]
        # search for notes
        if {$success} {
            set loc1  [lindex $location 0]
            set loc2  [lindex $location 1]
            #puts [string range $bar $loc1 $loc2]
            regexp -start $i $notepat $bar var acc key dur
            if {$key == "\["} {set chord on}
            if {$dur == "" && $chord == "off"} {set dur 1}
            if {$key == "z" || $key == "]"} {
                set chord "off"
                set midino "none"} elseif {$key != "\["}  {
                if {$midi(drummap)} {
                    set midino [expr $invdrummap($acc$key) -35] } else {
                    set midino [expr $revpatch($acc$key) - 35]
                }
                set row [lsearch $selected_drums $midino]
                if {$row != -1} {
                    set r  r$row
                    set c  c$col
                    flipcolor $r$c
                }
            }
            if {$key == "]" && $dur == ""} {set dur 1}
            if {$dur != ""} {
                set timeunit [expr $dur*$invfactor($drumtoolfactor)]
                if {$timeunit == 0} {set timeunit [expr $invfactor($drumtoolfactor)*$dur]}
                incr col $timeunit
            }
            set i [expr $loc2+1]} else {incr i}
    }
}

proc setdpatno {n} {
    global active_drumpattern
    set active_drumpattern $n
    highlight_selected_drum_pattern $n
    get_drumpattern
}

proc highlight_selected_drum_pattern {sel} {
    for {set i 0} {$i < 8} {incr i} {
        if {$i != $sel} {
            .drumtool.pat.$i configure -borderwidth 2}
    }
    .drumtool.pat.$sel configure -borderwidth 5
}

proc new_drumpattern {} {
    global active_drumpattern
    global last_drumpattern
    global df
#    set w .drumtool.ctl
    if {$last_drumpattern <= 7} {
        set active_drumpattern $last_drumpattern
        .drumtool.pat.$active_drumpattern configure -state normal
        highlight_selected_drum_pattern $active_drumpattern
        set token [.drumtool.pat.$active_drumpattern cget -text]
     #   button $w.$last_drumpattern -text $token -command "add_drumvoice_token $token" -font $df
#        pack $w.$last_drumpattern -side left
        incr last_drumpattern
    }
}

proc save_drumpatterns {} {
    global last_drumpattern
    global drumpatterns
    global midi
    global drumtoolmeter drumtoollength drumbeatstring drumtoolfactor
    global rhythmpattern
    global drum_f drum_m drum_p
    set handle [open $midi(drumpatfile) w]
    puts $handle "set rhythmpattern \"$rhythmpattern\""
    puts $handle "set midi(selected_drums) \"$midi(selected_drums)\""
    puts $handle "set drumtoolmeter $drumtoolmeter"
    puts $handle "set drumtoollength $drumtoollength"
    puts $handle "set drumtoolfactor $drumtoolfactor"
    puts $handle "set drumbeatstring $drumbeatstring"
    puts $handle "set drum_f $drum_f"
    puts $handle "set drum_m $drum_m"
    puts $handle "set drum_p $drum_p"
    
    for {set i 0} {$i < $last_drumpattern} {incr i} {
        set s $drumpatterns(D$i)
        set s [string map {\[ \\\[ \] \\\]} $s] 
        puts $handle "set drumpatterns(D$i) \"$s\""
    }
    close $handle
    drumvoice_msg "$midi(drumpatfile) was updated"
}

proc drumtool_gui_setup {} {
    # Graphics User Interface
    global p
    global df midi
    global drumpatterns
    global active_drumpattern
    global last_drumpattern
    global files
    global drumtoolmeter drumtoollength drumtoolfactor
    global drumbeatstring
    global drum_f drum_m drum_p
    global cabcbar
    global drumtempo
    global rhythmpattern
    set drumtoolfactor *1
    set drum_f $midi(beat_a)
    set drum_m $midi(beat_b)
    set drum_p $midi(beat_c)
    set drumtempo 160
    set rhythmpattern "4 4"
    set drumbeatstring ""
    set files $midi(midi_dir)/X1.mid
    if {[winfo exist .drumtool]} return
    toplevel .drumtool
    set p .drumtool.f
    frame $p
    button $p.save -text save -font $df -command save_drumpatterns
    button $p.select -text selector -font $df -command drumkey
    button $p.cfg -text configure -font $df -command config_drumtool
    button $p.clear -text "clear everything" -command clear_everything -font $df
    button $p.help -text help -font $df\
            -command {show_message_page $hlp_drumtool word}
    
    pack $p.save  $p.clear $p.select  $p.cfg $p.help -side left
    
    
    
    set p .drumtool.cav
    frame $p
    canvas $p.can -width 400
    canvas $p.cany -width 140
    pack $p.cany $p.can -side left -anchor w
    
    
    set p .drumtool.abcbar
    frame $p
    label $p.barlab -text "abc bar" -font $df
    entry $p.bar -textvariable cabcbar -width 60 -font $df
    pack $p.barlab $p.bar -side left
    
    
    set p .drumtool.pat
    frame $p
    button $p.new -text new -command new_drumpattern -font $df
    pack  $p.new  -side left
    
    for {set i 0} {$i < 8} {incr i} {
        button $p.$i -text D$i -font $df -command "setdpatno $i" -state disabled
        pack  $p.$i -side left
        set drumpatterns(D$i) ""
        bind $p.$i <3> {play_bar 2}
    }
    
    pack .drumtool.f -side top -anchor w
    pack .drumtool.cav -side top -anchor w
    pack .drumtool.abcbar -side top -anchor w
    pack .drumtool.pat -side top -anchor w
    
    $p.0 configure -state normal
    label .drumtool.msg  -text "" -font $df
    pack .drumtool.msg
    
    set active_drumpattern 0
    set last_drumpattern 0
    set drumtoolmeter 4/4
    set drumtoollength 1/8
    
    load_drumsel
    setup_drum_grid
    init_drum_hits
    #drumvoice_gui
    load_drumpatterns
    if {$midi(drummap)} {drum2map $midi(drumpat)}
}


global lineindex
set lineindex 0

proc drumvoice_msg {msg} {
    .drumtool.msg configure -text $msg
}

proc config_drumtool {} {
    global df midi drumtempo
    global drumtoolmeter drumtoollength drumbeatstring drumtoolfactor
    global rhythmpattern
    global last_drumpattern
    if {![winfo exist .cfg_drumtool]} {
        toplevel .cfg_drumtool
        set p .cfg_drumtool
        button $p.help -font $df -text help\
                -command {show_message_page $hlp_drumtool_cfg word}
        label $p.filelabel -font $df -text file
        entry $p.fileent -width 18 -textvariable midi(drumpatfile) -font $df
        button $p.filebut -text enter -font $df -command {clear_everything
            set last_drumpattern [load_drumpatterns]
            focus .cfg_drumtool.filelabel
            setup_drum_grid}
        label $p.meterlab -font $df -text "meter M:"
        entry $p.meterent -font $df -width 5 -textvariable drumtoolmeter
        button $p.meterbut -font $df -text enter -command drumtool_consistency
        label $p.lengthlab -font $df -text "unit length L:"
        entry $p.lengthent -font $df -width 5 -textvariable drumtoollength
        button $p.lengthbut -font $df -text enter -command drumtool_consistency
        scale $p.tempo -from 0 -to 400 -length 100 -width 4 -resolution 10 -orient horizontal -variable drumtempo -font $df
        label $p.beatlab -text beat -font $df
        label $p.tempolab -text tempo -font $df
        entry $p.rhythm -textvariable rhythmpattern -width 12 -font $df
        button $p.rhythmbut -text enter -font $df -command {drumtool_consistency
            setup_drum_grid}
        label $p.beatstringlab -text beatstring -font $df
        entry $p.beatstring -width 20 -font $df -textvariable drumbeatstring
        button $p.beatbut -text enter -font $df -command drumtool_consistency
        label $p.msg -text "" -font $df
        frame $p.beat
        label $p.beat.f -text f -font $df
        entry $p.beat.fe -width 3 -font $df -textvariable drum_f
        label $p.beat.m -text m -font $df
        entry $p.beat.me -width 3 -font $df -textvariable drum_m
        label $p.beat.p -text p -font $df
        entry $p.beat.pe -width 3 -font $df -textvariable drum_p
        pack $p.beat.f $p.beat.fe $p.beat.m $p.beat.me $p.beat.p $p.beat.pe -side left
        label $p.midibeatlab -text "MIDI beat" -font $df
        
        
        grid $p.help
        grid $p.filelabel $p.fileent $p.filebut
        grid $p.meterlab $p.meterent $p.meterbut
        grid $p.lengthlab $p.lengthent $p.lengthbut
        grid $p.beatlab $p.rhythm $p.rhythmbut
        grid $p.beatstringlab $p.beatstring $p.beatbut
        grid $p.midibeatlab $p.beat
        grid $p.tempolab $p.tempo
        grid $p.msg -columnspan 3
        bind $p.rhythm  <Return> {setup_drum_grid
            drumtool_consistency}
        bind $p.meterent <Return> drumtool_consistency
        bind $p.lengthent <Return> drumtool_consistency
        bind $p.beatstring <Return> drumtool_consistency
    }
}

proc check_beatstring {input length} {
    set charlist [split $input ""]
    set beatstringlength [string length $input]
    if {$beatstringlength != 0 && $beatstringlength !=  $length} {
        cfg_drumtool_msg "beatstring length is $beatstringlength
        it should be $length"
        return 1
    }
    foreach letter $charlist {
        if {$letter == "f"} continue
        if {$letter == "m"} continue
        if {$letter == "p"} continue else {
            puts "letter = $letter"
            cfg_drumtool_msg "only f,m, and p are allowed in the beastring"
            return 1
        }
    }
    return 0
}

proc drumtool_consistency {} {
    global df drumtoolfactor
    global drumtoolmeter drumtoollength drumbeatstring
    global rhythmpattern
    focus .cfg_drumtool.filelabel
    scan $drumtoolmeter "%d/%d" num denom
    set rhythm $rhythmpattern
    set subbeats 0
    foreach n $rhythm {
        incr subbeats $n
    }
    set ratio [expr $subbeats/double($num)]
    if {!($ratio == 1 || $ratio == 2 || $ratio == 4)} {
        set msg "summation of beat $rhythm = $subbeats should be $num, [expr 2*$num], or [expr 4 *$num]"
        cfg_drumtool_msg $msg
        return
    }
    set ratio1 [expr 32 * $drumtoollength * $subbeats /32.0]
    set ratio2 [expr 32 * $drumtoolmeter /32.0]
    set ratio [expr $ratio2/$ratio1]
    switch $ratio {
        0.25 {set drumtoolfactor /4}
        0.5 {set drumtoolfactor /2}
        1.0 {set drumtoolfactor *1}
        2.0 {set drumtoolfactor *2}
        4.0 {set drumtoolfactor *4}
    }
    if {[check_beatstring $drumbeatstring $subbeats]} return
    set msg ""
    cfg_drumtool_msg $msg
    #puts "drumtoolfactor= $drumtoolfactor"
}

proc cfg_drumtool_msg {msg} {
    .cfg_drumtool.msg configure -text $msg
}

proc add_drumvoice_token {token} {
    global lineindex
    global drlinetok
    global font df
    set selected [make_selected_drumvoice_list]
    if {[llength $selected]} {
        foreach i $selected {
            .drumtool.line.$i configure -text $token
        }
    } else {
        checkbutton .drumtool.line.$lineindex -text $token -indicatoron 0 -variable drlinetok($lineindex) -font $df
        pack .drumtool.line.$lineindex -side left
        incr lineindex
    }
    drumvoice_msg ""
}

proc delete_last_drumvoice_token {} {
    global lineindex
    incr lineindex -1
    destroy .drumtool.line.$lineindex
    drumvoice_msg ""
}

proc make_selected_drumvoice_list {} {
    global lineindex drlinetok
    set drumvoice_list ""
    for {set i 0} {$i < $lineindex} {incr i} {
        if {$drlinetok($i) == 1} {
            set drumvoice_list [lappend drumvoice_list $i]
        }
    }
    return $drumvoice_list
}


proc load_drumpatterns {} {
    global drumpatterns df
    global midi
    global drumtoolmeter drumtoollength drumbeatstring drumtoolfactor
    global drum_f drum_m drum_p
    global rhythmpattern
    global last_drumpattern
    if {![file exist $midi(drumpatfile)]} {return 0}
    set handle [open $midi(drumpatfile) r]
    set n 0
    set line " "
    while {[eof $handle] != 1} {
        if {[string length $line] < 1} break
        gets $handle line
        eval $line
        if {[string first "drumpatterns" $line] > 0} {incr n}
    }
    create_abc_drum_rep 
    
    for {set i 0} {$i < $n} {incr i} {
        .drumtool.pat.$i configure -state normal
        set name p$i
    }
    close $handle
    drumvoice_msg "$midi(drumpatfile) was loaded"
    set last_drumpattern $n
    return [expr $i]
}


proc createdrumfile {filename} {
    global drumtoolmeter drumtoollength drumbeatstring drumtempo
    global drum_f drum_m drum_p
    global midi
    set outhandle [open $filename w]
    puts $outhandle "X:1\nT:1 drum tune\nM:$drumtoolmeter\nL:$drumtoollength\nQ:1/4=$drumtempo\nK:C"
    if {$drumbeatstring != ""} {
        puts $outhandle "%%MIDI beatstring $drumbeatstring"
        puts $outhandle "%%MIDI beat $drum_f $drum_m $drum_p 2"
    }
    if {$midi(drummap)} {puts -nonewline $outhandle [output_drummap]}
    set body [create_drumbody]
    puts $outhandle $body
    close $outhandle
    drumvoice_msg "$filename was created"
}

proc create_drumbody {} {
    global drumpatterns
    set body "%%MIDI channel 10\n"
    set tokenlist [create_drum_token_list]
    foreach token $tokenlist {
        if {$token == ":|"} {
            set last [expr [string length $body] -2]
            set body [string replace $body $last end]
            set body "$body $drumpatterns($token)"
        } elseif {[string index $token 0] == "p"} {
            set body "$body $drumpatterns($token)|\n"
        } else {
            set body "$body $drumpatterns($token)"
        }
    }
    return $body
}


proc drum_to_clipboard {} {
    global drumtoollength drumbeatstring drumtoolmeter
    global drum_f drum_m drum_p
    global midi
    clipboard clear
    set body [create_drumbody]
    clipboard append "V: drum\n"
    clipboard append "M: $drumtoolmeter\n"
    clipboard append "L: $drumtoollength\n"
    if {$drumbeatstring != ""} {clipboard append "%%MIDI $drumbeatstring\n"
        clipboard append "%%MIDI beat $drum_f $drum_m $drum_p 2\"
    }
    if {$midi(drummap)} {clipboard append [output_drummap]}
    clipboard append $body
    drumvoice_msg "drum voice was saved in the clipboard"
}

proc play_drumline {} {
    global midi files
    createdrumfile $midi(midi_dir)/X.tmp
    set dir "[pwd]/$midi(midi_dir)"
    set cmd "file delete [glob -nocomplain $dir/X*.mid]"
    catch {eval $cmd}
    set cmd "exec $midi(path_abc2midi) $midi(midi_dir)/X.tmp"
    catch {eval $cmd} exec_out
    set exec_out $cmd\n\n$exec_out
    set files $midi(midi_dir)/X1.mid
    update_console_page
    play_midis 1
}

proc create_drum_token_list {} {
    global lineindex
    set tokenlist ""
    for {set i 0} {$i < $lineindex} {incr i} {
        set token [.drumtool.line.$i cget -text]
        set tokenlist [lappend tokenlist $token]
    }
    return $tokenlist
}




proc drum_abchead {} {
    global drumtoolmeter drumtoollength drumbeatstring drumtoolfactor drumtempo
    global drum_f drum_m drum_p
    set abchead "X:1\nT:drum\nM:$drumtoolmeter\nL:$drumtoollength\nQ:1/4=$drumtempo\nK:C\n%%MIDI channel 10\n%%MIDI chordattack 50\n"
    if {[info exist drumbeatstring]} {
        set abchead "$abchead%%MIDI beatstring $drumbeatstring\n%%MIDI beat $drum_f $drum_m $drum_p 2\n"
    }
    return $abchead
}


proc make_random_drumsel {n max} {
    global drumsel midi
    for {set i 0} {$i < $n} {incr i} {
        set j [expr int($max*rand())]
        set drumsel($j) 1
    }
    set midi(selected_drums) [return_selected_drumsel]
}


proc pick_random_drum {} {
    global midi
    set size [llength $midi(selected_drums)]
    set n [expr int(rand()*$size)]
    set m [lindex $midi(selected_drums) $n]
    return [expr $m + 35]
}


proc flipcolor {tagid} {
    global  drumhits
    global drumpatterns active_drumpattern
    global cabcbar
    
    scan $tagid "r%dc%d" row col
    #puts "flipcolor drumhits($col) = $drumhits($col)"
    set index [lsearch $drumhits($col) $row]
    #puts $index
    if {$index >= 0} {
        set drumhits($col) [lreplace $drumhits($col) $index $index]
        .drumtool.cav.can itemconfigure $tagid -fill white
    } else {
        lappend drumhits($col) $row
        .drumtool.cav.can itemconfigure $tagid -fill black
    }
    set abcbar [create_abc_drum_rep]
    set cabcbar [compress_rests $abcbar]
    set drumpatterns(D$active_drumpattern) $cabcbar
}

proc clear_all {} {
    global  drumhits
    global active_drumpattern
    global cabcbar ntatum
    for {set k 0} {$k < $ntatum} {incr k} {
        set col c$k
        set drumhits($k) ""
        for {set j 0} {$j < 47} {incr j} {
            set row r$j
            .drumtool.cav.can itemconfigure $row$col -fill white
        }
    }
    set abcbar [create_abc_drum_rep]
    set cabcbar [compress_rests $abcbar]
    set drumpatterns(D$active_drumpattern) $cabcbar
}



proc clear_everything {} {
    global  drumhits cabcbar ntatum
    global last_drumpattern
    for {set i 0} {$i < $last_drumpattern} {incr i} {
        for {set k 0} {$k < $ntatum} {incr k} {
            set col c$k
            set drumhits($k) ""
            for {set j 0} {$j < 47} {incr j} {
                set row r$j
                .drumtool.cav.can itemconfigure $row$col -fill white
            }
        }
        set abcbar [create_abc_drum_rep]
        set cabcbar [compress_rests $abcbar]
        set drumpatterns(D$i) $cabcbar
        .drumtool.pat.$i configure -state disable
        destroy .drumtool.ctl.$i
    }
    set last_drumpattern 0
}


proc setup_drum_grid {} {
    global drumhits midi drumsel drumpatches df ntatum
    global rhythmpattern
    set p .drumtool.cav
    if {![winfo exist $p]} return
    $p.can delete all
    $p.cany delete all
    set m 0
    set selected_drums ""
    set k 0
    for {set j 0} {$j < 47} {incr j} {
        if $drumsel($j) {
            lappend selected_drums $j
            set iy [expr $m*20 + 10]
            set iy2 [expr $iy +12]
            set ix 5
            set str [lindex [lindex $drumpatches $j] 2]
            $p.cany create text 5 $iy -text $str -anchor w -tag p$j -font $df
            $p.cany bind p$j <1> "play_patch $j"
            $p.cany configure -height $iy2
            $p.can configure -height $iy2
            set k 0
            foreach tatum $rhythmpattern {
                for {set i 0} {$i < $tatum} {incr i} {
                    set ix2 [expr $ix + 12]
                    set col c$k
                    set row r$m
                    $p.can create rect $ix $iy $ix2 $iy2 -tag $row$col -fill white
                    $p.can bind $row$col <1> "flipcolor $row$col"
                    set drumhits($k) ""
                    incr k
                    incr ix 20
                }
                incr ix 5
            }
            incr m
        }
    }
    set ntatum $k
    set midi(selected_drums) $selected_drums
}




proc play_patch {no} {
    global drumpatches
    global midi
    set abchead [drum_abchead]
    #  puts "play $no"
    set note [lindex [lindex $drumpatches $no] 1]
    #  puts $note
    set abcfile $abchead$note
    set outfd [open $midi(midi_dir)/X.tmp w]
    puts $outfd $abcfile
    close $outfd
    set cmd "exec $midi(path_abc2midi) $midi(midi_dir)/X.tmp"
    catch {eval $cmd} exec_out
    set exec_out $cmd\n\n$exec_out
    catch {eval $cmd} exec_out
    set files $midi(midi_dir)/X1.mid
    play_midis 1
}


proc init_drum_hits {} {
    global drumhits ntatum
    for {set i 0} {$i <$ntatum} {incr i} {set drumhits($i) ""}
}


proc create_abc_drum_rep {} {
    global midi tat ntatum
    global drumhits
    global drumpatches
    global drumsel
    global drummap
    set length ""
    set backbracket \]
    set abcbar ""
    set selected_drums [return_selected_drumsel]
    set midi(selected_drums) $selected_drums
    #puts "selected_drums $selected_drums"
    for {set i 0} {$i <$ntatum} {incr i} {
        #puts "drumhits($i) = $drumhits($i)"
        set ldrumhits [llength $drumhits($i)]
        if {!$ldrumhits} {
            set abcbar [concat $abcbar "z$length "]
        } elseif {$ldrumhits == 1} {
            set note_index $drumhits($i)
            if {$note_index >= 0} {
                set patch_index [lindex $selected_drums $note_index]
                if {$midi(drummap)} {
                    set note $drummap([expr $patch_index+35])} else {
                    set note [lindex [lindex $drumpatches $patch_index] 1]
                }
                set note $note$length
            } else {set note z}
            #puts "note = $note"
            set abcbar [concat $abcbar $note ]
        } else {
            set chord "\["
            foreach note_index $drumhits($i) {
                if {$note_index >= 0} {
                    set patch_index [lindex $selected_drums $note_index]
                    if {$midi(drummap)} {
                        set note $drummap([expr $patch_index+35])} else {
                        set note [lindex [lindex $drumpatches $patch_index] 1]
                    }
                    set note $note$length } else  {set note ""}
                set chord  $chord$note
            }
            set chord $chord$backbracket
            #puts "chord = $chord"
            set abcbar [concat $abcbar "$chord "]
        }
    }
    #puts "abcbar = $abcbar"
    return $abcbar
}

proc reduce {fraction} {
    set lfraction [split $fraction /]
    set a [lindex $lfraction 0]
    set b [lindex $lfraction 1]
    if {$a > $b} {
        set n  $a
        set m  $b
    } else {
        set n $b
        set m $a
    }
    while {$m != 0} {
        set t [expr $n % $m]
        set n $m
        set m $t
    }
    set a [expr $a/$n]
    set b [expr $b/$n]
    return $a/$b
}

proc evalmath {mathexp} {
    if {[string first * $mathexp ] != -1} {
        return [expr $mathexp]
    } elseif {[string first / $mathexp ] != -1} {
        set lexp [split $mathexp /]
        set a [lindex $lexp 0]
        set b [lindex $lexp 1]
        if {[expr $a % $b] == 0} {
            return [expr $a/$b]
        } else {
            set val [reduce $mathexp]
            return $val
        }
    } else {return $mathexp}
}



proc compress_rests {drumbar} {
    global midi drumtoolfactor
    global rhythmpattern
    #puts "compress_rests $drumbar"
    set i 0
    set s " "
    set compressedbar ""
    foreach beat $rhythmpattern {
        set note [lindex $drumbar $i]
        set count 1
        for {set j 1} {$j <$beat} {incr j} {
            incr i
            set nextnote [lindex $drumbar $i]
            if {$nextnote == "z"} {
                incr count
            } else {
                set value [evalmath $count$drumtoolfactor]
                if {$value == 1} {set value ""}
                set compressedbar $compressedbar$note$value
                set note  $nextnote
                set count 1}
        }
        set value [evalmath $count$drumtoolfactor]
        if {$value == 1} {set value ""}
        set compressedbar $compressedbar$note$value
        incr i
        set compressedbar $compressedbar$s
    }
    return $compressedbar
}

proc play_drum_pattern {bar times} {
    global midi files
    set abchead [drum_abchead]
    if {$midi(drummap)} {set abchead $abchead[output_drummap]}
    set abcfile $abchead$bar|
    if {$times > 1} {set abcfile $abcfile$bar|}
    if {$times > 2} {set abcfile $abcfile$bar|}
    #puts $abcfile
    set outfd [open $midi(midi_dir)/X.tmp w]
    puts $outfd $abcfile
    close $outfd
    set cmd "exec $midi(path_abc2midi) $midi(midi_dir)/X.tmp"
    catch {eval $cmd} exec_out
    set exec_out $cmd\n\n$exec_out
    set files $midi(midi_dir)/X1.mid
    play_midis 1
}

proc play_bar {times} {
    set bar [create_abc_drum_rep]
    set bar [compress_rests $bar]
    play_drum_pattern $bar $times
    return $bar
}



proc convert_drumhits_to_list {} {
    global drumhits
    global ntatum
    set drumhitslist {}
    for {set i 0} {$i < $ntatum} {incr i} {
        lappend drumhitslist $drumhits($i)
    }
    puts "drumhitslist $drumhitslist"
    return $drumhitslist
}






#end of source drumeditor.tcl

proc random_arrangement {} {
    global chan window
    set chan program
    set num [expr int(rand()*128)]
    set p1 [expr 1 + $num/8]
    set p2 [expr $num % 8]
    set window .abc.midi1.melody.melodybut
    program_select $p1 $p2
    set chan chordprog
    set num [expr int(rand()*128)]
    set p1 [expr 1 + $num/8]
    set p2 [expr $num % 8]
    set window .abc.midi1.chord.chordbut
    program_select $p1 $p2
    set chan bassprog
    set num [expr int(rand()*128)]
    set p1 [expr 1 + $num/8]
    set p2 [expr $num % 8]
    set window .abc.midi1.bass.bassbut
    program_select $p1 $p2
}


proc replace_edited_tune {} {
    global midi
    set abcfile $midi(abc_open)
    global copyfromloc copytoloc
    set inhandle [open $abcfile r]
    set outhandle [open runabc_out.abc w]
    set done 0
    while {[eof $inhandle] != 1} {
        set loc [tell $inhandle]
        gets $inhandle line
        if {$loc < $copyfromloc || $loc >= $copytoloc} {
            puts $outhandle $line
        } else {
            if {!$done} { paste_abcedit_text $outhandle
                set done 1
            }
        }
    }
    close $inhandle
    close $outhandle
    set backup_abcfile $abcfile.bak
    file rename -force $abcfile $backup_abcfile
    file rename -force runabc_out.abc $abcfile
    destroy .abcedit
    show_console_page "backup copy stored in $backup_abcfile" char
    title_index $midi(abc_open)
}

proc paste_abcedit_text {outhandle} {
    global midi
    global abctxtw
    set start 1.0
    set end end
    foreach {key value index} [$abctxtw dump $start $end] {
        if {$key == "text"} {
            puts -nonewline $outhandle $value}
    }
    if {$midi(bell_on)} bell
}



# Part 34.0               Gchord to voice

#abcg2v.tcl

# The functions in this file scan a tune in a
# abc file and produce a new tune with the
# guitar chords (gchords) replaced with a separate
# voice where they have been replaced by notes.
# For example the body:
#
# %%MIDI gchord fzcz
# |: cB | "F"A2F2 FAGF |
# "C7"EGB2 BdcB |"F"Acde "Dm"fagf :|
#
# is replaced with
#
# V:1
# |: cB | A2F2 FAGF |
# EGB2 BdcB |Acde fagf :|
# V:chords
# |: z2 |F,,z[F,A,C]z |
# C,,z[C,E,G,B,]z |F,,z[D,F,A,]z :|

# The guitar chords are expanded into accompaniment
# using the same convention as abc2midi; however,
# the gchord string cannot be arbitrary so that they
# can be represented by musical symbols. (See abcguide.txt
# which comes with the abcMIDI package for more details
# regarding guitar chords.)

# Method: we need the key signature, time signature,
# unit length (L:1/?) and gchord string to determine
# how to expand the guitar chords. In the music body,
# we only care about the note durations. All other
# information is ignored. For each note in the body
# we call gchord_generator, which decides whether
# to add another note or chord sequence into the
# chord voice (stored in chordvoice).
#
# For each music part (P:A, P:B etc,) we store the
# music bodytext and the expanded chords in separate
# strings. When we finish we dump everything out
# producing a new abc file.



#key.tcl

# this array is used to determine the key equivalency of the
# different modes, dorian, phrygian, etc.
array set modeshift {
    maj 0
    min -3
    m -3
    aeo -3
    loc -5
    ion 0
    dor -2
    phr -4
    lyd 1
    mix -1
}

# sequence of notes in a chromatic scale assuming sharps
array set sharpnotes {
    0 C
    1 ^C
    2 D
    3 ^D
    4 E
    5 F
    6 ^F
    7 G
    8 ^G
    9 A
    10 ^A
    11 B
}

# sequence of notes in a chromatic scale assuming flats
array set flatnotes {
    0 C
    1 _D
    2 D
    3 _E
    4 E
    5 F
    6 _G
    7 G
    8 _A
    9 A
    10 _B
    11 B
}

# key2sf {keysig}
# It interprets the key signature string in the K: command
# and determines the number of sharps/flats that are placed
# on the staff. For example Bb major has two flats so sf = -2
proc key2sf {keysig} {
    global modeshift
    set key "FCGDAEB"
    set s [regexp {([A-G]|none)(#*|b*)(.*)} $keysig match tonic accid mode]
    if {$s < 1} {puts "can't understand key signature $keysig"
        return}
    set sf [string first [string index $tonic 0] $key]
    incr sf -1
    if {$accid == "#"} {incr sf 7}
    if {$accid == "b"} {incr sf -7}
    set mode [string tolower $mode]
    if {[info exist modeshift($mode)]} {
        set sf \ [expr $sf + $modeshift($mode)]  }
    return $sf
}


# setupkey {sf}
# sets up table to convert MIDI pitches to
# notes taking into account the key signature
proc setupkey {sf} {
    global basekeytable
    global sharpnotes flatnotes
    #if {$sf == 0} return
    if {$sf >= 0} {
        for {set i 0} {$i < 12} {incr i} {
            set basekeytable($i) $sharpnotes($i)
        }
        for {set i 1} {$i <= $sf} {incr i} {
            switch $i {
                1 {set basekeytable(5) =F
                    set basekeytable(6) F}
                2 {set basekeytable(0) =C
                    set basekeytable(1) C}
                3 {set basekeytable(7) =G
                    set basekeytable(8) G}
                4 {set basekeytable(2) =D
                    set basekeytable(3) D}
                5 {set basekeytable(9) =A
                    set basekeytable(10) A}
                6 {set basekeytable(4) =E
                    set basekeytable(5) E}
                7 {set basekeytable(11) =B
                    set basekeytable(0) B}
            }
        }
        return
    }
    if {$sf < 0} {
        for {set i 0} {$i < 12} {incr i} {
            set basekeytable($i) $flatnotes($i)
        }
        for {set i -1} {$i >= $sf} {incr i -1} {
            switch -- $i {
                -1 {set basekeytable(10) B
                    set basekeytable(11) =B
                }
                -2 {set basekeytable(3) E
                    set basekeytable(4) =E}
                -3 {set basekeytable(8) A
                    set basekeytable(9) =A}
                -4 {set basekeytable(1) D
                    set basekeytable(2) =D}
                -5 {set basekeytable(6) G
                    set basekeytable(7) =G}
                -6 {set basekeytable(11) C
                    set basekeytable(0) =C}
                -7 {set basekeytable(4) F
                    set basekeytable(5) =F}
                default {puts "nothing done for $i"}
            }
        }
        return
    }
}

proc resetkeytable {} {
    # copies basekeytable to keytable
    global keytable basekeytable
    array set keytable [array get basekeytable]
}


#converts MIDI pitch to abc music notation note
proc midi2key {midipitch} {
    global keytable
    set midi12 [expr $midipitch % 12]
    set octave [expr $midipitch / 12]
    set note $keytable($midi12)
    #propagate accidentals across the bar
    if {[string index $note 0] == "^"} {
        set keytable($midi12) [string index $note 1]
        set keytable([expr $midi12 -1]) "=[string index $note 1]"
    } elseif {
        [string index $note 0] == "_"} {
        set keytable($midi12) [string index $note 1]
        set keytable([expr $midi12 +1]) "=[string index $note 1]"
    } elseif {
        [string index $note 0] == "="} {
        set keytable($midi12) [string index $note 1]
    }
    
    if {$octave == 3} {return $note,,}
    if {$octave == 4} {return $note,}
    return $note
}

#end of key.tcl



#tempo.tcl

namespace eval gchordsetup {
    
    variable default_gchord
    variable gchordstring
    variable barunits
    variable noteunits
    
    set default_gchord(2/2) fzczfzcz
    set default_gchord(2/4) fzczfzcz
    set default_gchord(4/4) fzczfzcz
    set default_gchord(3/4) fzczcz
    set default_gchord(6/8) fzcfzc
    set default_gchord(12/8) fzcfzcfzcfzc
    
    # setup_meter {line}
    # Handles M: command
    proc setup_meter {line} {
        variable default_gchord
        variable gchordstring
        variable barunits
        variable noteunits
        if {[string first "C|" $line] >= 0} {
            set m1 2
            set m2 2} elseif {
            [string first "C" $line] >= 0} {
            set m1 4
            set m2 4} else {
            set r [scan $line "M:%d/%d" m1 m2]}
        set barunits [expr 4*384 * $m1 /$m2]
        set meter $m1/$m2
        if {[info exist default_gchord($meter)]} {
            set gchordstring $default_gchord($meter)
            set gcstring::gcstringlist [gcstring::scangchordstring $gchordstring]
        } else {
            g2v_errormsg  "no default gchord string for this meter"
            puts "no default"
        }
        if {[info exists noteunits]} return
        if {[expr double($m1)/$m2] < 0.75} {
            setup_unitlength L:1/16} else {
            setup_unitlength L:1/8}
        
    }
    
    #Handles L: command
    proc setup_unitlength {line} {
        variable noteunits
        set r [scan $line "L:%d/%d" m1 m2]
        set noteunits [expr 384 *4* $m1 /$m2]
    }
}

#end tempo.tcl




namespace eval gchordspace {
    #gchord.tcl
    
    # The guitar chord indications in the body of the abc file
    # need to be translated in actual notes. Guitar chords
    # can be quite complex and contain inversions (eg GM7/D).
    # Also the notes need to be translated to the current
    # key signature to avoid a proliferation of accidentals.
    # (We do not account for propagation of accidentals
    # inside a bar.)
    
    # The results are stored in the lists midichord and
    # gchordnotes. bassnote is the note corresponding to
    # f in the gchord string.
    
    
    # This array indicates the offsets in semitones of the notes
    # in the different chords
    
    variable chordnames
    
    array set chordnames {
        Maj  {0 4 7}
        m {0 3 7}
        7 {0 4 7 10}
        m7 {0 3 7 10}
        m7b5 {0 3 6 10}
        maj7 {0 4 7 11}
        M7 {0 4 7 11}
        6 {0 4 7 9}
        m6 {0 3 7 9}
        aug {0 4 8}
        plus {0 4 8}
        aug7 {0 4 8 10}
        dim {0 3 6}
        dim7 {0 3 6 9}
        9 {0 4 7 10 2}
        m9 {0 3 7 10 2}
        maj9 {0 4 7 11 2}
        M9 {0 4 7 11 2}
        11 {0 4 7 10 2 5}
        dim9 {0 4 7 10 13}
        sus {0 5 7}
        sus9 {0 2 7}
        7sus4 {0 5 7 10}
        7sus9 {0 2 7 10}
        5 {0 7}
    }
    
    # expandgchord {gchord}
    # The function interprets a gchord (enclosed by a pair of double quotes) in
    # the music body and returns the equivalent notes forming the bass/chordal
    # accompaniment in the variables bassnote and gchordnotes.
    proc expandgchord {gchord} {
        global notekey
        variable chordnames
        global notescale
        global gchordnotes
        global bassnote
        set chord {}
        set inverpat {(.+)/(.+)}
        # check for inversion
        set inversion -1
        if {[regexp $inverpat $gchord match a b]} {
            set gchord $a
            set invert $b
            set s [regexp {([A-G]|[a-g]|)(#*|b*)} $invert match note accid]
            if {$s <1} {puts "cannot understand inversion"}
            set n1 [string first [string index $note 0] $notekey]
            set n [expr $n1 % 7]
            set inversion [lindex $notescale $n]
            if {$accid == "#"} {incr inversion}
            if {$accid == "b"} {incr inversion -1}
        }
        
        set s [regexp {([A-G]|[a-g]|none)(#*|b*)(.*)} $gchord match bass accid type]
        if {$s < 1} {puts "can't understand chord $gchord"
            return}
        set n1 [string first [string index $bass 0] $notekey]
        set n [expr $n1 % 7]
        if {[string compare $bass "none"] == 0} {set bass C}
        set basspitch [lindex $notescale $n]
        if {$accid == "#"} {incr basspitch}
        if {$accid == "b"} {incr basspitch -1}
        #if {[string length $sub3] > 3} {set type [string range $type 0 2 ]}
        if {$type == ""} {set type Maj}
        
        if {![info exist chordnames($type)]} {
            g2v_errormsg "no such chord $type"
            return
        }
        set midichordnotes {}
        foreach pitch $chordnames($type) {
            set midipitch [expr $pitch + $basspitch]
            lappend midichordnotes $midipitch
        }
        
        set inchord 0
        set j 0
        if {$inversion != -1} {
            foreach pitch $midichordnotes {
                if {$pitch == $inversion} {set inchord $j}
                incr j
            }
        }
        
        # Converts the gchord representation to the
        # bassnote and the list of notes in the chord.
        # For example Gmaj translates to bassnote G,,
        # and gchordnotes {G, B, D}.
        set gchordnotes {}
        set j 0
        set bassnote [midi2key [expr $basspitch + 36]]
        foreach pitch $midichordnotes {
            set midipitch [expr $pitch +48]
            if {$j < $inchord} {incr midipitch 12}
            lappend gchordnotes [midi2key $midipitch]
            incr j
        }
    }
}

#end gchord.tcl






#gcstring.tcl
namespace eval gcstring {
    variable gcstringlist
    variable gchordunitlength
    variable gc_string_length
    
    proc process_MIDI_gchord_command line {
        variable gcstringlist
        variable gchordunitlength
        global expandedchords
        # Interpret the %%MIDI gchord command, eg. %%MIDI gchord fzcz.
        g2v_errormsg  "using gchord string embedded in tune"
        set words [regexp -inline -all -- {\S+} $line]
        set cmd [lindex $words 1]
        set gchordstring [lindex $words 2]
        set gcstringlist [scangchordstring $gchordstring]
        gcgen::setup_gchord_generator
        set gchordunitlength [return_gchord_unitlength]
        if {[info exist expandedchord]} {
            set expandedchords $expandedchords$gchordunitlength\n} else {
            set expandedchords $gchordunitlength\n}
    }
    
    proc process_MIDI_drum_command line {
        global midi
        global expandeddrums
        variable drumunitlength
        g2v_errormsg  "using drum string embedded in tune"
        set pos [string first "drum" $line]
        set pos [expr $pos +5]
        set line [string range $line $pos end]
        set midi(drumpat) $line
        drumgen::setup_drum_generator $midi(drumpat)
        set drumunitlength [return_d_unitlength]
        set expandeddrums $expandeddrums$drumunitlength\n
        if {$midi(drummap)} {
            set expandeddrums $expandeddrums[output_drummap]
        }
    }
    
    
    proc scangchordstring {gc} {
        # Expands a gchord string (eg. fzc2fzc2 to
        # f z c2 f z c2) and stores it in gcstringlist.
        # Also computes the gchord string length (here 8).
        variable gc_string_length
        set gc_string_length 0
        set gclength [string length $gc]
        set pat {[zcfbghijGHIJ]\d*}
        set i 0
        set gcstringlist {}
        while {$i < $gclength} {
            set s [regexp  -indices -start $i $pat $gc r]
            if {!$s} break
            set loc1 [lindex $r 0]
            set loc2 [lindex $r 1]
            # puts "[string range $gc $loc1 $loc2]  $i $loc1 $loc2"
            if {$i != $loc1} {
                g2v_errormsg  "[string index $gc $i] is not a legal gchord code"}
            set gchordelem  [string range $gc $loc1 $loc2]
            lappend gcstringlist $gchordelem
            if {[string length $gchordelem] > 1} {
                set n [string index $gchordelem 1]
            } {set n 1}
            incr gc_string_length $n
            set i [expr $loc1+1]
        }
        #puts "gc_string_length=$gc_string_length"
        #puts $gcstringlist
        return $gcstringlist
    }
    
    
    proc interpret_gcstringlist {gcstringlist} {
        # Converts the gchord string to an actual
        # sequence of notes to place in the measure.
        # This is stored in gchord_output.
        global gchordnotes
        global bassnote
        global gchord_output
        set gchord_output {}
        foreach gcmd $gcstring::gcstringlist {
            set g [string index $gcmd 0]
            if {[string length $g] > 0} {
                set n [string index $gcmd 1]} else {
                set n ""}
            #  puts "g $g $n"
            switch $g {
                z {lappend gchord_output $gcmd}
                c {set chordstr \[
                    foreach note $gchordnotes {
                        set chordstr $chordstr$note
                    }
                    set chordstr $chordstr\]
                    #      puts $chordstr
                    lappend gchord_output $chordstr$n
                }
                f {
                    set bass $bassnote
                    lappend gchord_output $bass$n
                }
                b {
                    set chordstr \[$bassnote
                    foreach note $gchordnotes {
                        set chordstr $chordstr$note
                    }
                    set chordstr $chordstr\]
                    lappend gchord_output $chordstr$n
                }
                g {lappend gchord_output [lindex $gchordnotes 0]$n}
                h {lappend gchord_output [lindex $gchordnotes 1]$n}
                i {lappend gchord_output [lindex $gchordnotes 2]$n}
                j {if {[llength $gchordnotes] < 4} {g2v_errormsg "guitar chord is not a 7th"
                    } else {
                        lappend gchord_output [lindex $gchordnotes 3]$n}}
                G {lappend gchord_output [lindex $gchordnotes 0],$n}
                H {lappend gchord_output [lindex $gchordnotes 1],$n}
                I {lappend gchord_output [lindex $gchordnotes 2],$n}
                J {if {[llength $gchordnotes] < 4} {g2v_errormsg "guitar chord is not a 7th"
                    } else {
                        lappend gchord_output [lindex $gchordnotes 3]$n}}
                default {puts "cannot recognize $g"}
            }
        }
        #puts "interpret_gcstringlist: gchord_output $gchord_output"
        #puts "gstringlist $gcstringlist"
        return $gchord_output
    }
    #end gcstring.tcl
}



namespace eval gcgen {
    
    variable gchordindex
    variable gchordaccumulator
    variable expandedchords_for_line
    variable gchordunit
    #gcgen.tcl
    
    # The notes in the expanded gchord are placed in the
    # voice chord track note by note as the body of the
    # abc file is scanned. This allows handling of incomplete
    # measures and chord changes occurring inside a bar.
    #
    # gchord_generator is called each time a note in the
    # body is scanned. Anytime the gchord string (eg fczfcz)
    # is changed, setup_gchord() is called.
    #
    # At the end of each bar, we call process_barline
    # to ensure that the corresponding bar in the gchord
    # track matches the length of the bar in the abc body.
    #
    # gchordindex keeps track of the index in the
    # gchord string.
    #
    # gchordunit is a time unit for each gchord string
    # element.
    
    # gchordaccumulator and bar_accumulator accumulate
    # the time units.
    
    
    # When a measure ends we make any adjustments to the expandedchords
    # so it completes the measure. We reinitialize counters.
    
    proc setup_gchord_generator {} {
        variable gchordunit
        variable gchordaccumulator
        variable gchordindex
        if {[info exist gcstring::gc_string_length]} {
            if {$gcstring::gc_string_length == 0} return
            set gchordunit [expr $gchordsetup::barunits/$gcstring::gc_string_length]
            #puts "setup_gchord_generator:  gchordunit = $gchordunit gchordlength=$gcstring::gc_string_length barunits=$gchordsetup::barunits"
            set gchordindex 0
            set gchordaccumulator 0
        }
    }
    
    # gchord_generator is called after each note is
    # scanned. The function keeps time with the
    # scanned notes and issues another note in the
    # gchord sequence when appropriate.
    proc gchord_generator {} {
        global bar_accumulator
        variable gchordunit
        variable gchordindex
        variable gchordaccumulator
        global gchord_output
        variable expandedchords_for_line
        set space " "
        if {![info exist gcstring::gcstringlist]} return
        if {![info exist gchord_output]} return
        #puts "gchordaccumulator bar_accumulator = $gchordaccumulator $gchordindex $bar_accumulator"
        if {$bar_accumulator < $gchordaccumulator} return
        while {[set dif [expr $bar_accumulator - $gchordaccumulator]] > 0} {
            if {$gchordindex >= [llength $gcstring::gcstringlist]} return
            set gchord_output_elem [lindex $gchord_output $gchordindex]
            set gchordelem [lindex $gcstring::gcstringlist $gchordindex]
            if {[string length $gchordelem] == 1} {
                set ginc $gchordunit
            }  else {
                set n [string index $gchordelem 1]
                set ginc [expr $gchordunit*$n]
            }
            if {$ginc > $dif} break
            if {[string index $gchord_output_elem 0] == "\["} {
                set expandedchords_for_line $expandedchords_for_line$space$gchord_output_elem$space} else {
                set expandedchords_for_line "$expandedchords_for_line$gchord_output_elem"
            }
            incr  gchordaccumulator $ginc
            incr gchordindex
        }
    }
}


#end gcgen.tcl


# When a measure ends we make any adjustments to the expandedchords
# and drumnotes so it completes the measure. We reinitialize counters.
proc process_barline {token} {
    global bar_accumulator
    global dvoice
    if {[info exist gcgen::gchordaccumulator]} {
        if { $gcgen::gchordaccumulator < $bar_accumulator} {
            
            set numerator [expr $bar_accumulator - $gcgen::gchordaccumulator]
            set adjust [expr $numerator/$gcgen::gchordunit]
            if {$adjust == 0 && $numerator > 0} {
                set adjust $numerator/$gcgen::gchordunit
                set adjust  [reduce $adjust]}
            set adjustelem z$adjust
            set gcgen::expandedchords_for_line $gcgen::expandedchords_for_line\ $adjustelem
        }
        set gcgen::gchordindex 0
        set gcgen::gchordaccumulator 0
        set gcgen::expandedchords_for_line $gcgen::expandedchords_for_line\ $token
        #puts "expandedchords_for_line = $gcgen::expandedchords_for_line"
    }
    if {$dvoice != 1 && [info exist drumgen::drumaccumulator]} {
        if { $drumgen::drumaccumulator < $bar_accumulator} {
            
            set numerator [expr $bar_accumulator - $drumgen::drumaccumulator]
            set adjust [expr $numerator/$drumgen::drumunit]
            if {$adjust == 0 && $numerator > 0} {
                set adjust $numerator/$drumgen::drumunit
                set adjust  [reduce $adjust]}
            set adjustelem z$adjust
            set drumgen::drumnotes_for_line $drumgen::drumnotes_for_line\ $adjustelem
        }
        set drumgen::drumindex 0
        set drumgen::drumaccumulator 0
        set drumgen::drumnotes_for_line $drumgen::drumnotes_for_line\ $token
    }
    set bar_accumulator 0
}

# Part 35.0               Drum to voice
#start of drumgen

proc scandrumstring {dstring} {
    # Expands a drum string (eg. zd2dz to
    # z d2 d z) and stores it in dstringlist.
    # Also computes the dstring length (here 5).
    global d_string_length
    set d_string_length 0
    set dlength [string length $dstring]
    set pat {[zd]\d*}
    set i 0
    set dstringlist {}
    while {$i < $dlength} {
        set s [regexp  -indices -start $i $pat $dstring r]
        if {!$s} break
        set loc1 [lindex $r 0]
        set loc2 [lindex $r 1]
        if {$i != $loc1} {
            g2v_errormsg  "[string index $gc $i] is not a legal drum code"}
        set delem  [string range $dstring $loc1 $loc2]
        lappend dstringlist $delem
        if {[string length $delem] > 1} {
            set n [string index $delem 1]
        } else  {set n 1}
        incr d_string_length $n
        set i [expr $loc2+1]
    }
    #puts "d_string_length=$gc_string_length"
    #puts $dstringlist
    return $dstringlist
}


proc get_drum_notes {drumcmd} {
    set last [llength $drumcmd]
    return [lrange $drumcmd 1 $last]
}


proc drum2notes {drumpat} {
    global drumpatches
    global dstring
    global midi
    set drumcodes [scandrumstring [lindex $drumpat 0]]
    set notes [get_drum_notes $drumpat]
    set i 0
    set drumnotes {}
    set dstring {}
    foreach elem $drumcodes  {
        if {[string index $elem 0] == "d"} {
            if {[string length $elem] > 1} {
                set n [string index $elem 1]
            } {set n ""}
            set indx [expr [lindex $notes $i] -35]
            if {$indx > 46} {g2v_errormsg "$indx is not a legal drum patch number"}
            lappend drumnotes [lindex [lindex $drumpatches $indx] 1]$n
            lappend dstring $elem
            incr i
        } else {
            lappend drumnotes $elem
            lappend dstring $elem
        }
    }
    return $drumnotes
}

#set drumsymbols {A c F e E f B G d D g}
set drumsymbols {^A ^c ^F ^e _E _f _B _G _d _D _g}




proc drum2map {drumpat} {
    #creates a drum map for all the drum patch numbers
    #in the drum string.
    #also adds any selected drums in midi(selected_drums)
    global drumsymbols
    global drummap invdrummap
    global dstring
    global midi
    if {[info exist drummap]} {unset drummap}
    set drumcodes [scandrumstring [lindex $drumpat 0]]
    set notes [get_drum_notes $drumpat]
    set i 0
    set drumnotes {}
    set dstring {}
    
    set k 0
    foreach elem $drumcodes  {
        if {[string length $elem] > 1} {
            set n [string index $elem 1]
        } {set n ""}
        set indx [lindex $notes $i]
        if {[string index $elem 0] == "d"} {
            if {$indx > 81} {g2v_errormsg "$indx is not a legal drum patch number"}
            if {![info exist drummap($indx)]} {
                set drummap($indx) [lindex $drumsymbols $k]
                set invdrummap([lindex $drumsymbols $k]) $indx
                if {$k < 10} {incr k}
            }
            lappend drumnotes $drummap($indx)$n
            lappend dstring $elem
            incr i
        } else {
            lappend drumnotes $elem
            lappend dstring $elem
        }
    }
    
    # now search through midi(selected_drums) and add anything missing
    foreach elem $midi(selected_drums) {
        set indx [expr $elem + 35]
        if {![info exist drummap($indx)]} {
            set drummap($indx) [lindex $drumsymbols $k]
            set invdrummap([lindex $drumsymbols $k]) $indx
            if {$k < 10} {incr k}
            lappend drumnotes $drummap($indx)$n
        }
    }
    return $drumnotes
}

proc output_drummap {} {
    global drummap
    global drumpatches
    set drummaplist [array get drummap]
    set map ""
    foreach {p n} $drummaplist {
        set m [expr $p - 35]
        #  puts [lindex [lindex $drumpatches $m] 2]
        append map  "%%MIDI drummap $n $p % [lindex [lindex $drumpatches $m] 2]\n"
    }
    return $map
}


proc return_d_unitlength {} {
    set dunit $drumgen::drumunit
    if {![info exist dunit]} {
        return "L:1/1"} elseif {
        $dunit == 768} {
        return "L:1/2"} elseif {
        $dunit == 384} {
        return "L:1/4"} elseif {
        $dunit  == 192} {
        return "L:1/8"} elseif {
        $dunit  == 96} {
        return "L:1/16"} elseif {
        $dunit == 48} {
        return "L:1/32"} else {
        g2v_errormsg "drum string does not divide into meter"
    }
}






#drumgen
namespace eval drumgen {
    
    variable drumindex
    variable drumaccumulator
    variable drumnotes_for_line
    variable drumunit
    
    # The notes in the drum command  are placed in the
    # voice chord track note by note as the body of the
    # abc file is scanned. This allows handling of incomplete
    # measures and chord changes occurring inside a bar.
    #
    # drum_generator is called each time a note in the
    # body is scanned. Anytime the drum string
    # is changed, setup_dchord() is called.
    #
    # At the end of each bar, we call process_barline
    # to ensure that the corresponding bar in the gchord
    # track matches the length of the bar in the abc body.
    #
    # drumindex keeps track of the index in the
    # drum string.
    #
    # drumunit is a time unit for each gchord string
    # element.
    
    # drumaccumulator and bar_accumulator accumulate
    # the time units.
    
    
    
    proc setup_drum_generator {drumpat} {
        global d_string_length barunits
        variable drumunit
        variable drumaccumulator
        variable drumindex
        global  drumstringlist d_string_length
        global midi
        if {$midi(drummap)} {
            set drumstringlist [drum2map $drumpat]
        } else {
            set drumstringlist [drum2notes $drumpat]
        }
        if {[info exist d_string_length]} {
            set drumunit [expr $gchordsetup::barunits/$d_string_length]
            #puts "setup_drum_generator:  drumunit = $drumunit drumlength=$d_string_length "
            set drumindex 0
            set drumaccumulator 0
        }
    }
    
    # drum_generator is called after each note is
    # scanned. The function keeps time with the
    # scanned notes and issues another note in the
    # drum sequence when appropriate.
    proc drum_generator {} {
        global bar_accumulator
        global drumstringlist
        global dstring
        variable drumunit
        variable drumindex
        variable drumaccumulator
        global drum_output
        variable drumnotes_for_line
        if {![info exist drumstringlist]} return
        if {![info exist dstring]} return
        #puts "drumaccumulator bar_accumulator = $drumaccumulator $bar_accumulator"
        if {$bar_accumulator < $drumaccumulator} return
        while {[set dif [expr $bar_accumulator - $drumaccumulator]] > 0} {
            if {$drumindex >= [llength $drumstringlist]} return
            set d_elem [lindex $dstring $drumindex]
            set drum_output_elem [lindex $drumstringlist $drumindex]
            if {[string length $d_elem] == 1} {
                set dinc $drumunit}    else {
                set n [string index $d_elem 1]
                set dinc [expr $drumunit*$n]
            }
            # add drum_output_elem only if it is not too long. process_bar will
            # look after the leftovers.
            if {$dinc > $dif} break
            incr drumaccumulator $dinc
            set drumnotes_for_line "$drumnotes_for_line$drum_output_elem"
            incr drumindex
        }
    }
}


set dvoice 0

global chordnames



proc appendtext {line} {
    global fieldtext bodytext body
    if {$body} {
        set bodytext $bodytext$line\n
    } else {
        set fieldtext $fieldtext$line\n
    }
}


proc return_selected_tune {} {
    global fieldtext bodytext
    global midi fileseek
    set sel [title_selected]
    set inputhandle [open $midi(abc_open) r]
    set loc $fileseek($sel)
    seek $inputhandle $loc
    # copy tune to tunestring
    gets $inputhandle line
    set tunestring $line\n
    while {[gets $inputhandle line] >0}  {
        set tunestring $tunestring$line\n
    }
    close $inputhandle
    return $tunestring
}



set partlabel(0)  "none"

proc gv_process_post_P {line} {
    #To handle multiple parts, we save the body and chord voice
    #for each part  in separate strings which are put in
    #bodyvoicelist and chordvoicelist lists respectively.
    global expandedchords bodytext expandeddrums
    global chordvoice bodyvoice drumvoice
    global partlabel
    global npart
    # the P: always precedes the body.
    if {[string length $bodytext] < 1} {
        set partlabel($npart) $line
        return}
    set expandedchords [string trimright $expandedchords \n]
    set chordvoice($npart) $expandedchords
    set expandeddrums [string trimright $expandeddrums \n]
    set drumvoice($npart) $expandeddrums
    set bodyvoice($npart) $bodytext
    set expandedchords ""
    set expandeddrums ""
    set bodytext ""
    incr npart
    set partlabel($npart) $line
}

proc process_voice {line} {
    #global activevoice
    global voicelab voicelist
    global barnum nvoices
    global nbarsv
    set tline [string range $line 2 end]
    set tline [string trimleft $tline]
    set tline [split $tline]
    set voicelab [lindex $tline 0]
    if {[lsearch $voicelist $voicelab] == -1} {
        lappend voicelist $voicelab
        set barnum 0
        incr nvoices
        set nbarsv($voicelab) 0
    } else {
        set barnum $nbarsv($voicelab)
    }
    Refactor::make_component_name
    #set activevoice [lindex $tline 0]
}


proc process_line {line} {
    # processes the notes in a single line of the body in sequence.
    # We only care about the duration of the note and position of
    # the guitar chord indications. Thus we need to recognize
    # barlines eg. | || :| |: |[1 |[2
    # chords eg. [CEG]
    # triplets eg. (3CDD
    # gchords (anything enclosed by double quotes)
    # notes eg. A3/2 A/ A3 A
    # Each of these entities are handled by different functions.
    # When we finish the line, the string expandedchords_for_line
    # contains line of music containing the gchord accompaniment.
    # This string is appended to the string expandedchords.
    #set barpat {\||:\|\[\d|:\||\|:|\|\[\d|\||::}
    set barpat {\|\||\|[0-9]?|:\|\[\d|:\|[0-9]?|:\||\|:|\|\[\d|\||::}
    set notepat {(\^*|_*|=?)([A-G]\,*|[a-g]\'*|z|x)(/?[0-9]*|[0-9]*/*[0-9]*)}
    set gchordpat {\"[^\"]+\"}
    set curlypat {\{[^\}]*\}}
    set chordpat {(\[[^\]\[]*\])(/?[0-9]*|[0-9]*/*[0-9]*)}
    set instructpat {![^!]*!}
    set tripletpat {\(3}
    set sectpat {\[[0-9]+}
    
    global expandedchords
    global expandeddrums
    global bodytext
    global activevoice
    global preservegchord
    global dvoice
    global chosenvoice chosenvoicefound
    
    set gcgen::expandedchords_for_line ""
    set drumgen::drumnotes_for_line ""
    if {$preservegchord == 1} {
        set bodytext $bodytext$line\n
    } else {
        # remove all guitar chords and print the result.
        regsub -all  {"[^"]*"} $line "" result
        set bodytext $bodytext$result\n
    }
    
    # scan through the whole line (including gchords)
    set i 0
    while {$i < [string length $line]} {
        # search for bar lines
        set success [regexp -indices -start $i $barpat $line location]
        if {$success} {
            set loc1  [lindex $location 0]
            set loc2  [lindex $location 1]
            if {$loc1 == $i} {
                if {$activevoice == $chosenvoice} {process_barline [string range $line $loc1 $loc2]}
                set i [expr $loc2+1]
                resetkeytable
                continue}
        }
        
        # for repeat sections
        set success [regexp -indices -start $i $sectpat $line location]
        if {$success} {
            set loc1  [lindex $location 0]
            set loc2  [lindex $location 1]
            if {$loc1 == $i} {
                set sect [string range $line $loc1 $loc2]
                set gcgen::expandedchords_for_line  $gcgen::expandedchords_for_line$sect
                set i [expr $loc2+1]
                continue
            }
        }
        
        
        
        set success [regexp -indices -start $i $gchordpat $line location]
        # search for guitar chords
        if {$success} {
            set loc1  [lindex $location 0]
            set loc2  [lindex $location 1]
            if {$loc1 == $i} {process_gchord [string range $line $loc1 $loc2]
                set i [expr $loc2+1]
                continue}
        }
        
        set success [regexp -indices -start $i $curlypat $line location]
        # search for grace note sequences
        if {$success} {
            set loc1  [lindex $location 0]
            set loc2  [lindex $location 1]
            #  ignore grace notes in curly brackets
            if {$loc1 == $i} {
                set i [expr $loc2+1]
                continue}
        }
        
        
        set success [regexp -indices -start $i $tripletpat $line location]
        # search for triplet indication
        if {$success} {
            set loc1  [lindex $location 0]
            set loc2  [lindex $location 1]
            if {$loc1 == $i && $activevoice == $chosenvoice} {gv_process_triplet
                set i [expr $loc2+1]
                continue}
        }
        
        set success [regexp -indices -start $i $instructpat $line location]
        # search for embedded instructions like !fff!
        if {$success} {
            set loc1  [lindex $location 0]
            set loc2  [lindex $location 1]
            if {$loc1 == $i} {
                #    skip !fff! and similar instructions embedded in body
                set i [expr $loc2+1]
                continue}
        }
        
        set success [regexp -indices -start $i $notepat $line location]
        # search for notes
        if {$success} {
            set loc1  [lindex $location 0]
            set loc2  [lindex $location 1]
            if {$loc1 == $i} {
                set i [expr $loc2+1]
                if {$activevoice == $chosenvoice} {
                    set chosenvoicefound 1
                    gv_process_note [string range $line $loc1 $loc2]
                    gcgen::gchord_generator
                    if {$dvoice != 1} {
                        drumgen::drum_generator
                    }
                }
                continue
            }
        }
        
        set success [regexp -indices -start $i $chordpat $line location]
        # search for chords
        if {$success} {
            set loc1  [lindex $location 0]
            set loc2  [lindex $location 1]
            if {$loc1 == $i} {gv_process_chord [string range $line $loc1 $loc2]
                set i [expr $loc2+1]
                if {$activevoice == $chosenvoice} {gcgen::gchord_generator}
                if {$activevoice == 1 && $dvoice != 1} {
                    drumgen::drum_generator}
                continue}
        }
        
        incr i
    }
    if {$activevoice == $chosenvoice} {
        set expandedchords $expandedchords$gcgen::expandedchords_for_line\n
    }
    
    if {$dvoice != 1 && $activevoice == $chosenvoice} {
        set expandeddrums $expandeddrums$drumgen::drumnotes_for_line\n
    }
}




# set flag to adjust the duration of the next three notes
proc gv_process_triplet {} {
    global triplet_running
    set triplet_running 1
}

# determine the duration of the note. We ignore broken
# notes (eg A > C) because the two notes usually complete
# a beat. We also do not need to pay attention to tied
# notes.
proc gv_process_note {token} {
    global triplet_running
    global bar_accumulator
    set durpatf {([0-9])\/([0-9])}
    set durpatn {[0-9]}
    set durpatd {\/([0-9])}
    set dur2 {/+}
    if {[regexp $durpatf $token match val1 val2]} {
        set increment  [expr $gchordsetup::noteunits*$val1/$val2]
    } elseif {
        [regexp $durpatd $token val1 val2]} {
        set increment  [expr $gchordsetup::noteunits/$val2]
    } elseif {
        [regexp $durpatn $token val]} {
        set increment  [expr $gchordsetup::noteunits*$val]
    } elseif {
        [regexp $dur2 $token val]} {
        set increment  [expr $gchordsetup::noteunits/2]
    } else {
        set increment $gchordsetup::noteunits
    }
    if {$triplet_running} {
        set increment [expr 2 * $increment/3]
        incr triplet_running
        if {$triplet_running > 3} {set triplet_running 0}
    }
    incr bar_accumulator $increment
    return
}

# separate the guitar chord from the double quotes
# determine the type of chord and find the equivalent
# notes.
proc process_gchord {token} {
    global gchordstring gchord_output gcstringlist
    set token [string trimleft $token \"]
    set token [string trimright $token \"]
    gchordspace::expandgchord $token
    set gchord_output [gcstring::interpret_gcstringlist $gcstring::gcstringlist]
}

# We hope all the notes in the chord are of equal.
# We get the time value of the chord from the time
# value of the first note in the chord.
proc gv_process_chord {token} {
    gv_process_note $token
}


# This is the function which processes the tune.
# Assume only one tune per file.
proc gv_process_tune {tunestring} {
    global expandedchords
    global expandeddrums
    global triplet_running
    global npart
    global body
    global debug
    global activevoice
    global nvoices
    global dvoice
    global chosenvoice chosenvoicefound
    
    global recover_key key_change
    global recover_meter meter_change
    global bar_accumulator
    
    global midi
    
    set npart 0
    set nvoices 0
    set activevoice 1
    set fieldpat {^X:|^T:|^C:|^O:|^A:|^Q:|^Z:|^N:|^H:|^S:|^F:}
    set triplet_running 0
    set expandedchords "%%MIDI program $midi(chordprog)\n"
    set expandeddrums ""
    set body 0
    set chosenvoicefound 0
    
    foreach line [split $tunestring \n]  {
        if {$debug > 0} {puts ">>$line"}
        if {[string length $line] < 1} continue
        if {[string first "%%MIDI" $line] >= 0} {
            if {[string first "gchord" $line] >=0} {
                gcstring::process_MIDI_gchord_command $line
                appendtext $line
            } elseif {[string first "drum " $line] >=0} {
                gcstring::process_MIDI_drum_command $line
                appendtext %$line
            }
        } elseif {
            [string index $line 0] == "I"} {
            appendtext $line
            continue
        } elseif {
            [string index $line 0] == "R"} {
            appendtext $line
            continue
        } elseif {
            [string index $line 0] == "%"} {
            appendtext $line
            continue
        } elseif {
            [regexp $fieldpat $line] } {
            appendtext $line
        } elseif {
            [string first "K:" $line] == 0} {
            appendtext $line
            if {$body} {
                set expandedchords $expandedchords$line\n}
            set kfield [string range $line 2 end]
            setupkey [key2sf $kfield]
            resetkeytable
            set key_change 1
            set bar_accumulator 0
            if {!$body} {
                set body 1
                set recover_key $line
                set key_change 0
                appendtext "%%MIDI program $midi(voice1)"
                appendtext "%%MIDI bassprog $midi(bassprog)"
                appendtext "%%MIDI chordprog $midi(chordprog)"
            }
        } elseif {
            [string first "M:" $line] == 0} {
            appendtext $line
            if {$body} {
                set expandedchords $expandedchords$line\n
                set meter_change 1} else {
                set recover_meter $line
                set meter_change 0}
            gchordsetup::setup_meter $line
            if {$dvoice != 2} gcgen::setup_gchord_generator
            set gchordunitlength [return_gchord_unitlength]
            set expandedchords $expandedchords$gchordunitlength\n
            #       global dvoice
            if {$dvoice != 1} {
                if {$midi(drumon)} {
                    drumgen::setup_drum_generator $midi(drumpat)
                } else {drumgen::setup_drum_generator "zz"}
                set drumunitlength [return_d_unitlength]
                set expandeddrums $expandeddrums$drumunitlength\n
                set expandeddrums "$expandeddrums%%MIDI channel 10\n"
                if {$midi(drummap) && $midi(drumon)} {
                    set expandeddrums $expandeddrums[output_drummap]
                }
            }
        } elseif {
            [string first "L:" $line] == 0} {
            appendtext $line
            gchordsetup::setup_unitlength $line
        } elseif {
            [string first "P:" $line] == 0} {
            gv_process_post_P $line
        } elseif {
            [string first "V:" $line] == 0} {
            process_voice $line
            appendtext $line
            incr nvoices
        } elseif {
            $body==1} {
            process_line $line
        } else {g2v_errormsg *-*-*$line }
        
    }
    if {$chosenvoicefound == 0} {g2v_errormsg "could not find voice $chosenvoice"}
}



# for translating notes C,D, etc to MIDI pitches
set  notescale  {0  2  4  5  7  9  11}
set  key "cdefgab";
set notekey "CDEFGABcdefgab"





proc return_gchord_unitlength {} {
    #puts "return_gchord_unitlength $gcgen::gchordunit"
    if {![info exist gcgen::gchordunit]} {
        return "L:1/1"} elseif {
        $gcgen::gchordunit == 768} {
        return "L:1/2"} elseif {
        $gcgen::gchordunit == 384} {
        return "L:1/4"} elseif {
        $gcgen::gchordunit == 192} {
        return "L:1/8"} elseif {
        $gcgen::gchordunit == 96} {
        return "L:1/16"} elseif {
        $gcgen::gchordunit == 48} {
        return "L:1/32"} else {
        g2v_errormsg "gchordstring does not divide into meter"
    }
}





set debug 0
set preservegchord 1

proc g2v_startup {} {
    global gvchordstring gvmeter
    global tunestring
    global gvmsg
    global midi
    set gvmsg ""
    g2v_clear_errormsg
    show_g2v_page
    set tunestring [return_selected_tune]
    set index [string first "M:" $tunestring ]
    set index2 [expr $index + 10]
    set line [string range $tunestring $index $index2]
    if {[string first "C|" $line] >= 0} {
        set m1 2
        set m2 2} elseif {
        [string first "C" $line] >= 0} {
        set m1 4
        set m2 4} else {
        set r [scan $line "M:%d/%d" m1 m2]}
    set gvmeter $m1/$m2
    if  {$midi(bmychord)}  {
        set gvchordstring $midi(mychord)} else {
        if {[info exist gchordsetup::default_gchord($gvmeter)]} {
            set gvchordstring $gchordsetup::default_gchord($gvmeter)
        } else {
            g2v_errormsg  "no default gchord string for this meter"
        }
    }
    .abc.g2v.1.lab configure -text "default gchord string for $gvmeter"
}

proc g2v_errormsg {msg} {
    global gvmsg exec_out
    set exec_out $exec_out\n$msg
    if {[string length $gvmsg] < 1} {set gvmsg $msg}
    .abc.g2v.msg.txt configure -text $gvmsg -foreground red
}

proc g2v_clear_errormsg {} {
    global gvmsg exec_out
    set exec_out "running g2v..."
    set gvmsg ""
    .abc.g2v.msg.txt configure -text $gvmsg
}



proc g2v {} {
    global tunestring
    global midi
    global inputfile fieldtext
    global bodyvoice
    global abctxtw
    global npart
    global partlabel
    global chordvoice
    global drumvoice dvoice
    global fieldtext bodytext
    global gvchordstring gvmeter
    global gchordvoiceid drumsvoiceid
    
    global recover_key key_change
    global recover_meter meter_change
    
    set fieldtext ""
    set bodytext ""
    
    set gchordsetup::default_gchord($gvmeter) $gvchordstring
    g2v_clear_errormsg
    gv_process_tune $tunestring
    gv_process_post_P "none"
    
    # output
    if {$midi(g2v_clipboard)} {
        
        clipboard clear
        for {set i 0} {$i <$npart} {incr i} {
            if {$partlabel($i) != "none"} {
                #puts $partlabel($i)
                clipboard append  "%$partlabel($i)\n"
            }
            clipboard append $chordvoice($i)\n
            if {$dvoice != 1} {clipboard append \ndrums\n$drumvoice($i)\n}
        }
        .abc.g2v.msg.txt configure  -text "The results are in the clipboard."
    } else {
        
        set vc "V:$gchordvoiceid clef=bass\n"
        set vd "V:$drumsvoiceid name=drum clef=perc stafflines=4\nK: none\n"
        edit_empty_file
        $abctxtw insert end $fieldtext
        for {set i 0} {$i <$npart} {incr i} {
            if {$partlabel($i) != "none"} {
                $abctxtw insert end $partlabel($i)\n part
            }
            $abctxtw insert end V:1\n$bodyvoice($i)
            #puts "bodyvoice($i) = $bodyvoice($i)"
            if {$dvoice != 2} {
                $abctxtw insert end $vc
                $abctxtw insert end $chordvoice($i)\n
            }
            if {$dvoice != 1} {
                $abctxtw insert end $vd
                $abctxtw insert end $drumvoice($i)\n}
        }
    }
    
    update_console_page
}

#end of abcg2v.tcl


# Part 36.0 Refactor
proc extract_tune_info {} {
    global fileseek
    global midi
    global nbars
    global firstbar lastbar
    global hasfield
    global barpickerflag
    midi1_msg ""
    set sel [title_selected]
    #puts "extract_tune_info for $sel"
    if {[llength $sel] != 1} {return}
    set loc $fileseek($sel)
    set handle [open $midi(abc_open) r]
    seek $handle $loc
    gets $handle line
    #set tunestring $line\n
    set tunestring "X: $sel\n"
    while {[gets $handle line]> 0} {
        set tunestring $tunestring$line\n
    }
    close $handle
    #puts $tunestring
    set barpickerflag 0
    extract_tune_features $tunestring
    if {[info exist hasfield(MIDI)]} {midi1_msg "The tune already has MIDI directives. You would\n need to override them if you wish to change them."}
}


proc extract_tune_features {tunestring} {
    global hasfield
    array unset hasfield
    
    foreach line [split $tunestring \n]  {
        #if {$debug > 0} {puts ">>$line"}
        if {[string length $line] < 1} continue
        if {[string first "B:" $line] == 0 } {
            append hasfield(B) $line\n}
        if {[string first "C:" $line] == 0 } {
            append hasfield(C) $line\n}
        if {[string first "O:" $line] == 0 } {
            append hasfield(O) $line\n}
        if {[string first "P:" $line] == 0 && ![info exist hasfield(P)]} {
            append hasfield(P) $line\n}
        if {[string first "Z:" $line] == 0 } {
            append hasfield(Z) $line\n}
        if {[string first "N:" $line] == 0 } {
            append hasfield(N) $line\n}
        if {[string first "S:" $line] == 0 } {
            append hasfield(S) $line\n}
        if {[string first "R:" $line] == 0 } {
            append hasfield(R) $line\n}
        if {[string first "F:" $line] == 0 } {
            append hasfield(F) $line\n}
        if {[string first "Q:" $line] == 0 } {
            append hasfield(Q) $line\n}
        if {[string first "T:" $line] == 0 } {
            append hasfield(T) $line\n}
        if {[string first "%%MIDI" $line] == 0} {
            append hasfield(MIDI) $line\n}
        if {[string first "\"" $line] >= 0} {
            append hasfield(gc) $line\n}
        
        
    }
    finish_tune
}

proc finish_tune {} {
    global hasfield tunenote
    global nvoices nbars
    set tunenote {}
    set codelist ""
# set nvoices to 0 so voice doubling works
    set nvoices 0
    foreach  code {T B C O P Z N S R F Q gc MIDI} {
        if {[info exist hasfield($code)]} {
            #if {[string length $tunenote] >  0} {set tunenote $tunenote\n}
            set tunenote $tunenote$hasfield($code)
            if {$code != "MIDI"} {
                set codelist "$codelist$code: "
            } else {
                set codelist "$codelist%%MIDI "
            }
        }
    }
    .abc.titles.notes.but configure -text $codelist
    if {[winfo exist .headers]} Refactor::header_window
}


proc play_section {} {
    global midi exec_out
    global console_clock
    global files
    global midiname
    set console_clock [clock seconds]
    set dir "[pwd]/$midi(midi_dir)"
    set cmd "file delete [glob -nocomplain $dir/*.mid]"
    catch {eval $cmd}
    
    Refactor::output_file_direct
    set cmd "exec [list $midi(path_abc2midi)] [list $midi(midi_dir)/X.tmp] -Q $midi(tempo)"
    if {$midi(barflymode)} {append cmd " -BF $midi(stressmodel)"}
    catch {eval $cmd} exec_out
    set exec_out $cmd\n\n$exec_out
    set files $dir/X$midiname.mid
    play_midis $midiname
    update_console_page
}


proc display_section {} {
    global midi
    global console_clock
    global active_sheet
    global exec_out
    set console_clock [clock seconds]
    Refactor::output_file_direct
    display_tunes [list $midi(midi_dir)/X.tmp]
    update_console_page
}



namespace eval Refactor {
    
    proc process_line {line} {
        # This function breaks a body line into bars and save
        # each bar into the array tune_pieces using the functions
        # make_component_name and appendtext.
        # Complications occur when (1) a line begins with a bar line
        # (2) a bar is incomplete at the end of a line (3) comments
        # like %%MIDI commands and (4) field commands  occur in
        # the body.
        #
        # The following are considered as bar separators
        # | |: || :| :: |[1 |[2 etc. If a MIDI command (%%MIDI ...)
        # is encountered or a field command, it is also included
        # with the bar.
        
        set barpat {\|\||\|[0-9]?|:\|\[\d|:\|[0-9]?|:\||\|:|\|\[\d|\||::|\|\]}
        global barnum
        global nbars
        global nbarsv
        global voicelab
        global incomplete
        global component
        global barpickerflag
        global abctxtw
        
        set newline  1
        
        if {[string index $line 0] == "%"} {
            appendx $line\n
            return
        }
        if {[string first "P:" $line] == 0} {
            # do not append P: because it is put in the wrong place
            return
        }
        if  {[string first "V:" $line] == 0} {
            process_voice $line
            appendx $line\n
            return
        }
        if   {[string first "L:" $line] == 0} {
            appendx $line\n
            return
        }
        if   {[string first "M:" $line] == 0} {
            appendx $line\n
            return
        }
        if   {[string first "Q:" $line] == 0} {
            appendx $line\n
            return
        }
        if   {[string first "K:" $line] == 0} {
            appendx $line\n
            return
        }
        
        if  {[string first "\[V:" $line] == 0} {
            set i2 [string first "\]" $line]
            incr i2 -1
            set vline [string range $line 1 $i2]
            process_voice $vline
            appendtext $vline\n
            incr i2 2
            set line [string range $line $i2 end]
        }
        
        
        # eliminate any indentation
        set line [string trimleft $line]
        
        # scan through the whole line
        set i 0
        set start 0
        if {[string first "\\" $line] > 0} {set backslash 1
        } else {set backslash 0}
        set line [string trimright $line \\]
        while {$i < [string length $line]} {
            # search for bar lines
            set success [regexp -indices -start $i $barpat $line location]
            if {$success} {
                set loc1  [lindex $location 0]
                set loc2  [lindex $location 1]
                set start $i
                #in case a line starts with a bar line type we include the contents
                #preceding this bar line (in the previous line) if any.
                if {[expr $loc2] < 3 && $loc1 == 0 } {
                    if {[string length $incomplete] > 0} {
                        append incomplete [string range $line $start $loc2]
                        appendtext $incomplete
                        set incomplete ""
                        incr barnum
                        set i [expr $loc2 +1]
                        set start $i
                        if {$barnum > $nbars} {set nbars $barnum}
                        if {$barnum > $nbarsv($voicelab)} {set nbarsv($voicelab) $barnum}
                        # previous line is now complete add a \n
                    } else {
                        # nothing precedes scan to the next bar line
                        set success [regexp -indices -start $i $barpat $line location]
                        if {$success} {
                            set loc1  [lindex $location 0]
                            set loc2  [lindex $location 1]
                            appendtext [string range $line $start $loc2]
                            incr barnum
                            if {$barnum > $nbars} {set nbars $barnum}
                            if {$barnum > $nbarsv($voicelab)} {set nbarsv($voicelab) $barnum}
                        } else {
                            # bar line still not found, save everything before end of line
                            append incomplete [string range $line 0  end]
                            set loc2 [string length $line]
                            set newline 0
                        }
                    }
                } else {
                    #  if there is anything left over from the last line, send it
                    if {[string length $incomplete] > 0} {
                        appendtext $incomplete
                        set incomplete ""
                    }
                    appendtext [string range $line $start $loc2]
                    incr barnum
                    if {$barnum > $nbars} {set nbars $barnum}
                    if {$barnum > $nbarsv($voicelab)} {set nbarsv($voicelab) $barnum}
                }
                set i $loc2
                make_component_name
            } else {
                # failed to find bar object. Maybe it is found in the next line.
                # we need to increment start before getting incomplete or else
                # we will get a double bar.
                set incomplete [string range $line $start end]
                # get rid of trailing white spaces
                set incomplete [string trimright $incomplete]
                return}
            incr i
            set start $i
        }
        if {$barpickerflag} {
            if {$newline} {
                if {$backslash} {$abctxtw insert end \\\n
                } else   {$abctxtw insert end \n}
            }
        }
    }
    
    
    
    proc appendtext {piece} {
        global abctxtw
        global component
        global tunepieces
        global barpickerflag
        #set piece [string trimright $piece \\ ]
        append tunepieces($component) $piece
        if {$barpickerflag} {
            $abctxtw insert end $piece $component
            $abctxtw tag bind $component <ButtonPress-1> [list Barpicker::barclick $component]
        }
    }

    proc appendx {piece} {
        global abctxtw
        global xcomponent
        global tunepieces
        global barpickerflag
        if {$barpickerflag} {
           $abctxtw insert end $piece $xcomponent
           $abctxtw tag bind $xcomponent <ButtonPress-1> [list Barpicker::barclick $xcomponent]
           }
        append tunepieces($xcomponent) $piece
    }

    
    proc make_component_name {} {
        global partname
        global voicelab
        global barnum
        global component
        global xcomponent
        set component $voicelab-$barnum
        set xcomponent x-$voicelab-$barnum
    }
    
    global hasfield
    
    
    # This is the function which processes the tune.
    # Assume only one tune per file.
    proc process_tune {tunestring} {
        global partname
        global voicelab
        global voicelist
        global barnum
        global nbars
        global body
        global debug
        # global activevoice
        global nvoices
        global tunepieces
        global component
        global incomplete
        global nbarsv
        global crlf
        
        array unset tunepieces
        set partname Z
        set voicelab 0
        set barnum 0
        set nbars 0
        set npart 0
        set nvoices 0
        set voicelist {}
        set component head
        set body 0
        set incomplete ""
        set nbarsv(0) 0
        
        
        foreach line [split $tunestring \n]  {
            if {$debug > 0} {puts ">>$line"}
            if {[string length $line] < 1} continue
            
            
            if {!$body} {
                if {[string first "K:" $line] == 0} {
                    set keystring [string range $line 2 end]
                    if {[string first "Hp" $line] > 0 ||
                        [string first "HP" $line] > 0
                    } {enable_disable_drone 1} else {
                        enable_disable_drone 0}
                    
                    set body 1
                    appendtext $line\n
                    make_component_name
                } else {
                    appendtext $line\n
                }
            } else {
                process_line $line
            }
        }
    }
    
    proc header_window {} {
        global tunenote midi
        set p .headers
        global df
        if {![winfo exist $p]} {
            toplevel $p
            text $p.t -width 50 -height 10 -bg #f4ece0 \
                    -yscrollcommand {.headers.ysbar set} \
                    -xscrollcommand {.headers.xsbar set} \
                    -font $df -exportselection false
            scrollbar $p.ysbar -orient vertical -command {.headers.t yview}
            scrollbar $p.xsbar -orient horizontal -command {.headers.t xview}
            pack $p.ysbar -side right   -fill y -in $p
            pack $p.xsbar -side bottom  -fill x -in $p
            pack $p.t -fill both -expand y -in $p
        }
        $p.t delete 0.0 end
        #$p.t tag configure link -foreground darkblue
        set linkindex 0
        foreach line [split $tunenote \n] {
            if {[string first "F:" $line] == 0} {
                $p.t tag configure m$linkindex -foreground darkblue
                $p.t insert end $line\n m$linkindex
                set url [string range $line 2 end]
                $p.t tag bind m$linkindex <1> "exec [list $midi(path_internet)] $url &"
                incr linkindex
            } else {
                $p.t insert end $line\n
            }
        }
    }
    
    
    
    proc myputs {out_fd mydata} {
        # this version saves the last output character in case
        # we need it.
        global lastoutputchar
        set l [string length $mydata]
        incr l -1
        set lastoutputchar [string index $mydata $l]
        puts -nonewline $out_fd $mydata
    }
    
   proc extract_comments_for_voice {i} {
    # extracts comments like %%MIDI program command
    # and field commands like L:1/8 from tunepieces()
    global tunepieces
    global firstbar lastbar
    set saved_elements {}
    for {set j 0} {$j < $firstbar} {incr j} {
        if {[info exist tunepieces(x-$i-$j)]} {
                lappend saved_elements $tunepieces(x-$i-$j)
                }
        }
    return $saved_elements
}

 
    
    proc output_file_direct {} {
        # creates a tmp.abc file from the info in tunepieces
        # between bars firstbar and lastbar.
        global tunepieces
        global nvoices nbars voicelist
        global lastoutputchar
        global firstbar lastbar
        global midi
        global midiname
        set fieldpat {^L:|^M:|^K:|^Q:|V:}
        set barsperline 4
        # to address problem with Windows Media Player we give the
        # MIDI file a random name
        set xhead [lindex [split $tunepieces(head) \n] 0]
        set midiname [expr int(rand()*100000)]
        set tunepieces(head) [string replace $tunepieces(head) 0 [string length $xhead] "X:$midiname\n"]
        set out_fd [open [list $midi(midi_dir)/X.tmp] w]
        myputs  $out_fd $tunepieces(head)
        set barsminus1 [expr $barsperline - 1]
        # cause problem for plain abc tune with no voices
        #if {[info exist tunepieces(0-0)]} {
        #   myputs  $out_fd $tunepieces(0-0)}
        if {$nvoices >= 1} {
            # for multivoiced tunes
            for {set n 0} {$n < $nvoices} {incr n} {
                set voice [lindex $voicelist $n]
                set vital_info [extract_comments_for_voice $voice]
                #puts $out_fd V:$voice
                foreach elem $vital_info {
                    puts $out_fd $elem
                }
                for {set i $firstbar} {$i < $lastbar} {incr i} {
                    if {![info exist tunepieces($voice-$i)]} continue
                    set firstchar [string index $tunepieces($voice-$i) 0]
                    if {$firstchar == "%"} {
                        if {$lastoutputchar != "\n"} {myputs  $out_fd "\n"}
                        myputs  $out_fd $tunepieces($voice-$i)
                        continue} elseif {
                        [regexp $fieldpat $tunepieces($voice-$i)]} {
                        if {$lastoutputchar != "\n"} {myputs  $out_fd "\n"}
                        myputs  $out_fd $tunepieces($voice-$i)
                        continue}
                    myputs  $out_fd $tunepieces($voice-$i)
                    if {[expr $i % $barsperline] == $barsminus1} {
                        myputs  $out_fd \n
                    }
                }
                if {$lastoutputchar != "\n"} {myputs  $out_fd "\n"}
            }
        } else {
            # for tunes with no voices
            set vital_info [extract_comments_for_voice 0]
            foreach elem $vital_info {
                puts $out_fd $elem
            }
            for {set i $firstbar} {$i < $lastbar} {incr i} {
                if {![info exist tunepieces(0-$i)]} continue
                set firstchar [string index $tunepieces(0-$i) 0]
                if {$firstchar == "%"} {
                    if {$lastoutputchar != "\n"} {myputs  $out_fd "\n"}
                    myputs  $out_fd $tunepieces(0-$i)
                    continue} elseif {
                    [regexp $fieldpat $tunepieces(0-$i)]} {
                    if {$lastoutputchar != "\n"} {myputs  $out_fd "\n"}
                    myputs  $out_fd $tunepieces(0-$i)
                    continue}
                myputs  $out_fd $tunepieces(0-$i)
                if {[expr $i % $barsperline] == $barsminus1} {
                    myputs  $out_fd "\n"
                }
            }
        }
        close $out_fd
        #puts "[list $midi(midi_dir)/X.tmp] written"
    }
    
    proc dump_tunepieces {} {
        global tunepieces
        global exec_out
        set exec_out ""
        set clist [array names tunepieces]
        set clist [lsort $clist]
        foreach elem $clist {
           # puts "$elem $tunepieces($elem)"
           append exec_out "$elem\t $tunepieces($elem)\n"
        }
    show_console_page $exec_out char
    }
    
    
    
    proc reconstitute {} {
        global midi
        global abctxtw
        global barsperline barsperstaff
        set barsperline $midi(midibpl)
        set barsperstaff $midi(midibps)
        $abctxtw delete 1.0 end
        if {$midi(interleave)} {
            reconstitute_pieces_voice_interleaved
        } else {
            reconstitute_pieces_separate_voices
        }
    }
    
    
    proc reconstitute_pieces_voice_interleaved {} {
        global abctxtw
        global tunepieces
        global nvoices nbars nbarsv voicelist
        global barsperline barsperstaff
        set fieldpat {^L:|^M:|^K:|^Q:|^w:|V:}
        
        if {$barsperline < 1} {set barsperline 1}
        
        #check_nbarsv
        $abctxtw insert end $tunepieces(head) head
       # $abctxtw tag bind head <ButtonPress-1> [list barclick head]
        if {$nvoices < 1} {.abc.reformat.mesg configure -text "no voices are present"
            reconstitute_pieces_separate_voices
            return
        }
        if {[info exist tunepieces(0-0)]} {
            $abctxtw insert end $tunepieces(0-0)}
        set i 0
        while {$i < $nbars} {
            for {set n 0} {$n < $nvoices} {incr n} {
                set voice [lindex $voicelist $n]
                if {$i >= $nbarsv($voice)} continue
                # each line should have a voice command.
                if {[string first "V:" $tunepieces($voice-$i)] <0} {
                    set lastchar [$abctxtw get "end -2 chars"]
                    if {$lastchar != "\n"} {
                        if {$i % $barsperstaff == 0} {
                            $abctxtw insert end "\n"} else {
                            $abctxtw insert end "\\\n"}
                        $abctxtw insert end "V:$voice\n"
                        set lastchar  "\n"
                    }
                }
                for {set j 0} {$j < $barsperline} {incr j} {
                    set k [expr $i + $j]
                    if {$k >= $nbarsv($voice)} break
                   # put any comments or field commands on a new line
                    if {[info exist tunepieces(x-$voice-$k)]} {
                       if {$lastchar != "\n"} {
                        $abctxtw insert end "\n"
                        set lastchar "\n"}
                        $abctxtw insert end $tunepieces(x-$voice-$k) x-$voice-$k
#                        $abctxtw tag bind x-$voice-$k <ButtonPress-1> [list barclick x-$voice-$k]
                        }
                }
                    $abctxtw insert end $tunepieces($voice-$k) $voice-$k
#                    $abctxtw tag bind $voice-$k <ButtonPress-1> [list barclick $voice-$k]
            }

            incr i $barsperline
        }
    }
    
    
    proc reconstitute_pieces_separate_voices {} {
        global abctxtw
        global tunepieces
        global nvoices nbars voicelist
        global barsperline barsperstaff
        set fieldpat {^L:|^M:|^K:|^Q:|^w:}
        $abctxtw delete 1.0 end
        $abctxtw insert end $tunepieces(head) head
#        $abctxtw tag bind head <ButtonPress-1> [list barclick head]
        set barsminus1 [expr $barsperline - 1]
        if {$nvoices >= 1} {
            # for multivoiced tunes
            for {set n 0} {$n <= $nvoices} {incr n} {
                set nlines 0
                set voice [lindex $voicelist $n]
                for {set i 0} {$i < $nbars} {incr i} {
                    if {![info exist tunepieces($voice-$i)]} continue
                    set lastchar [$abctxtw get "end -2 chars"]
                    if {[info exist tunepieces(x-$voice-$i)]} {
                      if {$lastchar != "\n"} {
                        $abctxtw insert end "\n"
                        set lastchar "\n"}
                      $abctxtw insert end $tunepieces(x-$voice-$i) x-$voice-$i
                        }

                     $abctxtw insert end $tunepieces($voice-$i) $voice-$i
                     set lastchar [$abctxtw get "end -2 chars"]

                    $abctxtw insert end $tunepieces($voice-$i) $voice-$i
                    set lastchar [$abctxtw get "end -2 chars"]
                    if {[expr $i % $barsperstaff] == 0 && $lastchar != "\n"} {
                        $abctxtw insert end "\n"
                        set lastchar "\n"} elseif {
                        [expr $i % $barsperline] == $barsminus1} {
                        if {[expr $i % $barsperstaff] == 0 && $lastchar != "\n"} {$abctxtw insert end "\n"
                        } else {
                            $abctxtw insert end "\\\n"
                            set lastchar  "\n"
                        }
                    }
                }
                set lastchar [$abctxtw get "end -2 chars"]
                if {$lastchar != "\n"} {$abctxtw insert end "\n"
                    incr nlines
                    set lastchar  "\n"}
            }
        } else {
            # for tunes with no voices
            set nlines 0
            for {set i 0} {$i < $nbars} {incr i} {
                if {![info exist tunepieces(0-$i)]} continue
                set firstchar [string index $tunepieces(0-$i) 0]
                set lastchar [$abctxtw get "end -2 chars"]
                if {$firstchar == "%" && $lastchar != "\n"} {
                    $abctxtw insert end "\n"
                    incr nlines}
                # put any field commands on a new line
                set success [regexp -indices  $fieldpat $tunepieces(0-$i) location]
                if {$success} {
                    set f  [lindex $location 0]} else {
                    set f -1}
                if {$f == 0  && $nlines != 0} {$abctxtw insert end "\n"
                    incr nlines}
                $abctxtw insert end $tunepieces(0-$i) 0-$i
                if {[expr $i % $barsperline] == $barsminus1} {$abctxtw insert end "\n"
                    incr nlines}
            }
            set lastchar [$abctxtw get "end -2 chars"]
            if {$lastchar != "\n"} {$abctxtw insert end "\n"
                incr nlines}
        }
    }
    
    proc refactor_textcontents {} {
        global abctxtw
        global alreadyloaded
        foreach {key value index} [$abctxtw dump 1.0 end] {
            if {$key == "text"} {
                append tunestring $value}
        }
        erase_all
        Refactor::process_tune $tunestring
        set alreadyloaded 1
        #reconstitute
    }
    
    
    
}

# end of namespace Refactor

#end of Refactor

set hlp_reformat "Reformat\n\n\
        The function is designed for multivoiced abc notated files. It will\
        reorganize the tune in one of two ways. If voice interleave is not\
        selected, then all the lines for a voice are grouped together.\
        If voice interleave is selected, the different voices are expressed\
        for each line of music. Both representations have their advantages\
        and disadvantages. For example, it is easier to remove a voice if all\
        the lines are grouped together.\n\n\
        Other parameters control the number of bars on a text line or on\
        a musical staff.\n\n\
        The function does not handle multipart tunes correctly and there are\
        probably other limitations.
"






# main program starts here


set tmp_clock [clock seconds]
global tmp_clock ;# this variable is used to determine whether .tmpfile
#needs to be refreshed.



if {[info exist abc_open]} {set midi(abc_open) $abc_open
}

set midi(loadtime) [expr [clock clicks -milliseconds] - $startload]

# open last used file
if [file exists $midi(abc_open)] {
    title_index $midi(abc_open)
    # fix   set titles_size [.abc.titles.t index end]
    #   puts $titles_size
    update_history $midi(abc_open)
    show_titles_page
}

# create tmp directory if it doesn't exists
file mkdir "[pwd]/$midi(midi_dir)"


switch_ps_button
focus .abc

startup_progress "runabc"

