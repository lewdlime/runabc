#extractformat.tcl
#creates m2psdef.tcl using abcm2ps-*/format.txt


set m2pschoices(alignbars) {1 2 3 4 5 6 7 8}
set m2pschoices(aligncomposer) {-1 0 1}
set m2pschoices(annotationfont) {"Times-Roman 12" "Time-Bold 12" "Times-Roman 14" "Times-Bold 14" "Times-Italic 12" "Times-BoldItalic 12" "Helvetica 10" "Helvetica-Bold 10" "Helvetica-Oblique" "Courier" "Platino" "Platino-Bold" }
set m2pschoices(barsperstaff) {1 2 3 4 5 6 7 8}
set m2pschoices(breaklimit) {0.5 0.6 0.7 0.8 0.9 1.0}
set m2pschoices(bgcolor) {white yellow pink \#faf0e6}
set m2pschoices(botmargin) {0.0cm 1.0cm 2.0cm 3.0cm 4.0cm 5.0cm}
set m2pschoices(combinevoices) {-1 0 1 2}
set m2pschoices(composerfont) $m2pschoices(annotationfont)
set m2pschoices(composerspace) {0.0cm 0.2cm 0.4cm 0.6cm 0.8cm 1.0cm}
set m2pschoices(dateformat) {"%F" "%D" "%A %F"}
set m2pschoices(decoration) {"!" "+"}
set m2pschoices(dblrepbar) {"::" ":|:" ":||:"}
set m2pschoices(dynamic) {0 1 2 3 4}
set m2pschoices(encoding) {native us-ascii utf-8 iso-8859-1}
set m2pschoices(footerfont) $m2pschoices(annotationfont)
set m2pschoices(gchord) {0 1 2 3}
set m2pschoices(gracespace) {{8.0 8.0 10.0} {4.0 8.0 6.0}}
set m2pschoices(gstemdir) {0 1 2}
set m2pschoices(headerfont) $m2pschoices(annotationfont)
set m2pschoices(historyfont) $m2pschoices(annotationfont)
set m2pschoices(indent) {0.5cm 1.0cm 1.5cm 2.0cm 3.0cm}
set m2pschoices(infofont) $m2pschoices(annotationfont)
set m2pschoices(infospace) $m2pschoices(indent)
set m2pschoices(leftmargin) $m2pschoices(botmargin)
set m2pschoices(lineskipfac) {0.2 0.4 0.6 0.8 1.0}
set m2pschoices(maxshrink) $m2pschoices(lineskipfac)
set m2pschoices(measurefont) $m2pschoices(annotationfont)
set m2pschoices(measurenb) {0 2 4 -1}
set m2pschoices(musicspace) $m2pschoices(botmargin)
set m2pschoices(notespacingfactor) {1.0 1.2 1.4 1.6 1.8 2.0}
set m2pschoices(ornament) {0 1 2 3}
set m2pschoices(parskipfac) $m2pschoices(lineskipfac)
set m2pschoices(partsfont) $m2pschoices(annotationfont)
set m2pschoices(partsspace) $m2pschoices(indent)
set m2pschoices(repeatfont) $m2pschoices(annotationfont)
set m2pschoices(rightmargin) $m2pschoices(leftmargin)
set m2pschoices(scale) {0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2}
set m2pschoices(shiftunison) $m2pschoices(ornament)
set m2pschoices(slurheight) {0.8 0.9 1.1 1.2}
set m2pschoices(staffscale) $m2pschoices(scale)
set m2pschoices(staffsep) {1.4cm 1.5cm 1.6cm 1.7cm}
set m2pschoices(staffwidth) {15.0cm 16.0cm 17.0cm 18.0cm 19.0cm}
set m2pschoices(stemdir) $m2pschoices(gstemdir)
set m2pschoices(stemheight) {17.0 19.0 21.0 23.0}
set m2pschoices(stretchlast) $m2pschoices(lineskipfac)
set m2pschoices(subtitlefont) $m2pschoices(annotationfont)
set m2pschoices(subtitlespace) {0.2cm 0.3cm 0.4cm}
set m2pschoices(sysstaffsep) $m2pschoices(notespacingfactor)
set m2pschoices(tempofont) $m2pschoices(annotationfont)
set m2pschoices(textfont) $m2pschoices(annotationfont)
set m2pschoices(textoption) {obeylines justify fill center skip right}
set m2pschoices(textspace) $m2pschoices(subtitlespace)
set m2pschoices(titlefont) $m2pschoices(annotationfont)
set m2pschoices(titlespace) $m2pschoices(subtitlespace)
set m2pschoices(topmargin) $m2pschoices(botmargin)
set m2pschoices(topspace) $m2pschoices(botmargin)
set m2pschoices(voicefont) $m2pschoices(annotationfont)
set m2pschoices(vocalspace) $m2pschoices(botmargin)
set m2pschoices(voicescale) {0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2}
set m2pschoices(volume) {0 1 2 3}
set m2pschoices(wordsfont) $m2pschoices(annotationfont)


proc process_specialchars {line} {
    set fixedline ""
    set linelen [string length $line]
    set spec "\[\]\{\}\"\$\\"
    set b "\\"
    for {set i 0} {$i < $linelen} {incr i} {
        set c [string index $line $i]
        if {[string first $c $spec] >= 0} {
            set fixedline $fixedline$b$c
        } else {
            set fixedline $fixedline$c
        }
    }
    #puts $line
    #puts $fixedline
    return  $fixedline
}

proc splitcommand {line} {
    set loc [string first " " $line]
    if {$loc < 0} return ""
    set loc1 [expr $loc - 1]
    set loc2 [expr $loc + 1]
    set one [string range $line 0 $loc1]
    set two [string range $line $loc2 end]
    #puts "loc = $loc"
    #puts "one  = $one"
    #puts "two = $two"
    return $two
}


proc load_format.txt {} {
    global fmtcmdlist
    global m2psarg
    global m2psdefault
    global m2pshelp
    global m2psscope
    
    set handle [open "format.txt" r]
    set fmtcmdlist {}
    set fmtcmd ""
    while {[gets $handle line] >= 0} {
#		check for end of pseudo-commands
                    if {$fmtcmd == "break"} break
        if {[string range $line 0 1] == "  "} {
             set cmdline $line
            # puts $cmdline
            set cmdline [string trimleft $cmdline]
            set cmdlist [split $cmdline]
            set fmtcmd [lindex $cmdlist 0]
            #puts $fmtcmd
            #set cmdopt [lrange $cmdlist 1 end]
            set cmdopt [splitcommand $cmdline]
            lappend fmtcmdlist $fmtcmd
             set m2psarg($fmtcmd) $cmdopt
            #puts $cmdopt
            set descript ""
        }
        if {[string range $line 0 3] == "\tDef"} {
            set line [string trimleft $line]
            set defaults [string range $line 9 end]
            #set defaults [list $defaults]
            set m2psdefault($fmtcmd) $defaults
        }

        if {[string range $line 0 3] == "\tSco"} {
            set line [string trimleft $line]
            set scope [split $line]
            set scope [lrange $scope 1 end]
            set scope [list $scope]
            set m2psscope($fmtcmd) $scope
            #puts $scope
        }
        
        if {[string range $line 0 3] == "\tDes"} {
            while {[gets $handle line] >= 0} {
                set prefix [string range $line 0 1]
                if {$prefix ==  "\t\t"} {
                    set descript "$descript$line\n"
                } elseif {$prefix == "  "} {
                    #puts $descript
                    set m2pshelp($fmtcmd) $descript
                    #  now process new command line
#                    set cmdline [process_specialchars $line]
		    set cmdline $line
                    set cmdline [string trimleft $cmdline]
                    set cmdlist [split $cmdline]
                    set fmtcmd [lindex $cmdlist 0]
#		check for end of pseudo-commands
                    if {$fmtcmd == "break"} break
                    #puts $fmtcmd
                    #set cmdopt [lrange $cmdlist 1 end]
                    set cmdopt [splitcommand $cmdline]
                    lappend fmtcmdlist $fmtcmd
                    set m2psarg($fmtcmd) $cmdopt
                    #puts $cmdopt
                    set descript ""
                    break;}
            }
        }
    }
    
    # now process all the pseudo comments and pseudo commands commands
    set m2psarg($fmtcmd) ""
    
    # we already have to command or comment get the descriptor
    set m2psdefault($fmtcmd) ""
    while {![eof $handle]} {
        gets $handle line
        if {[string range $line 0 1] != "  "} {
            set descript "$descript [process_specialchars $line]\n"
        } else {
            set m2pshelp($fmtcmd) $descript
            #  now process new command line
            set cmdline [process_specialchars $line]
            set cmdline [string trimleft $cmdline]
            set cmdlist [split $cmdline]
            set fmtcmd [lindex $cmdlist 0]
            if {$fmtcmd == "<symbol"} break;
            lappend fmtcmdlist $fmtcmd
            set cmdopt [splitcommand $cmdline]
            set m2psarg($fmtcmd) $cmdopt
            #puts $cmdline
            #puts "list = $cmdlist"
            #puts "opt = $cmdopt"
            #puts $m2psarg($fmtcmd)
            set m2psdefault($fmtcmd) ""
            set descript ""
        }
    }
    
    close $handle
    #puts $fmtcmdlist
    #puts [llength $fmtcmdlist]
    #puts $m2pshelp(alignbars)
    set m2pshelp(Examples:) ""
    set m2pshelp(postscript) $m2pshelp(ps)
    set m2pshelp(setfont-1) $m2pshelp(setfont-4)
    set m2pshelp(setfont-2) $m2pshelp(setfont-4)
    set m2pshelp(setfont-3) $m2pshelp(setfont-4)
    set m2psdefault(postscript) $m2psdefault(ps)
    set m2psdefault(setfont-1) $m2psdefault(setfont-4)
    set m2psdefault(setfont-2) $m2psdefault(setfont-4)
    set m2psdefault(setfont-3) $m2psdefault(setfont-4)
}

load_format.txt

proc load_abcm2ps_defaults {} {
global m2psdefault
set cmd "exec abcm2ps -H"
catch {eval $cmd} defaults
set defaultlines [split $defaults "\n"]
foreach line $defaultlines {
 set firstspace [string first " " $line]
 set fmtcmd [string range $line 0 [expr $firstspace -1]]
 set line [string replace $line 0 $firstspace ""]
 set def [string trimleft $line]
 if {$def == "true"} {set def 1}
 if {$def == "no"} {set def 0}
 if {$def == "yes"} {set def 1}
 #puts "$fmtcmd / $def"
 if {[info exist m2psdefault($fmtcmd)]} {
     if {$m2psdefault($fmtcmd) != $def} {
       puts "$fmtcmd : before $m2psdefault($fmtcmd) - after $def"
       }
    } else {
     puts "$fmtcmd **missing** default = $def"
    }
 set m2psdefault($fmtcmd) $def
  }
}

if {[file exist abcm2ps]} {
  #load_abcm2ps_defaults
  } else {
  puts "cannot find abcm2ps to get defaults"
  }


proc writelist {handle var fmtlist} {
    global fmtcmdlist
    puts -nonewline $handle "set $var \{"
    for {set i 0} {$i < [llength $fmtlist]} {incr i} {
        puts -nonewline $handle " [lindex $fmtlist $i]"
        if {[expr $i % 5] == 4} {puts $handle ""}
    }
    puts $handle "\}"
}

proc arraywrite {handle var} {
    global fmtcmdlist
    global m2psarg m2psdefault m2pschoices
    global m2psscope
    puts -nonewline $handle "array set $var \{"
    for {set i 0} {$i < [llength $fmtcmdlist]} {incr i} {
        set fmtcmd [lindex  $fmtcmdlist $i]
        puts -nonewline $handle "[array get $var $fmtcmd] "
        if {[expr $i % 5] == 4} {puts $handle ""}
    }
    puts $handle "\}"
}


proc writedef {handle fmtcmd descriptor} {
    puts -nonewline $handle "set m2pshelp($fmtcmd)  \{"
    set j 0
    for {set i 0} {$i < [string length $descriptor]} {incr i} {
        puts -nonewline $handle [string index $descriptor $i]
    }
    puts -nonewline $handle \}
    puts $handle ""
    puts $handle ""
}


set handle [open "m2psdef.tcl" w]


writelist $handle fmtcmdlist $fmtcmdlist
puts $handle ""
puts $handle ""

arraywrite $handle m2psarg
puts $handle ""
puts $handle ""

arraywrite $handle m2psdefault
puts $handle ""
puts $handle ""

#arraywrite $handle m2psscope

arraywrite $handle m2pschoices

foreach fmtcmd $fmtcmdlist {
    writedef $handle $fmtcmd $m2pshelp($fmtcmd)
}

close $handle




