#!/bin/sh
# the next line restarts using wish \
exec wish "$0" "$@"
##
# abcindex.tcl
# The program creates an index of all the titles of the
# abc files found in the specified folder and all its
# subfolders. The index is put in the ascii file called
# abcindex.dat stored in the same specified folder. 
# Using a regular text editor to view abcindex.dat,
# you can search for a specific title.
#
#
set abcfolder "../abcfiles"
frame .index
label .index.lab -width 30 -text ""
entry .index.ent -width 30 -textvariable abcfolder
button .index.but -text start -command create_index
pack  .index.ent
pack  .index.but
pack  .index

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
proc title_index {abcfile outhandle} {

    set srch X 
    set blank_lines 0
    set i 0
    set pat {[0-9]+}
    set titlehandle [open $abcfile r]
    set fileseek(0) 0
    puts $abcfile
    while {[gets $titlehandle line] >= 0} {
	if {!$blank_lines && [string length $line] < 1} {set srch X}
        set initialchar [string index $line 0]
	switch -- $srch {
	X {
		if { $initialchar == "X"} {
		    regexp $pat $line number
		    set srch T
                    set i 0
		}
	    }
	T {
		if { $initialchar == "T"} {
		    set name($i) [string range $line 2 end]
		    set name($i) [string trim $name($i)]
                    incr i
		    } elseif {$initialchar == "K"} {
		    set keysig [string range $line 2 end]
		    set keysig [string trim $keysig]
                    for {set j 0} {$j < $i} {incr j} {
		      set outline \
                        [format "%4d  %-6s %s" $number $keysig $name($j)]
		      puts $outhandle $outline
                      }
		    set srch X
		    }
	    }
    }
  }
  close $titlehandle
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
#   Executes a recursive /glob/ returning a list of all files mathing
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


proc create_index {} {
global abcfolder
cd $abcfolder
pack forget .index.but
pack .index.lab
set file_list [rglob *.abc]
set output_handle [open abcindex.dat w]
foreach filename $file_list {
    puts $output_handle "\n\n$filename\n\n"
    .index.lab configure -text $filename
    update
    title_index $filename $output_handle
}
close $output_handle
destroy .index
}


