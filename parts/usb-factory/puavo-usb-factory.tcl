#!/usr/bin/wish

package require json

wm attributes . -fullscreen 1

# XXX not a correct picture
set bg_image_path /usr/share/backgrounds/Blue_frost_by_ppaabblloo77.jpg

try {
  set support_logo_path [exec puavo-conf puavo.greeter.logo]
} on error {errmsg} {
  puts stderr "puavo-conf could not lookup puavo.greeter.logo: $errmsg"
  exit 1
}

set bg_image {
  width      -1
  height     -1
  new_width  0
  new_height 0
}

set image_info {
  image_size        ""
  latest_image_path ""
  status            ""
  version           ""
}

set ui_messages {}

set puavo_usb_factory_workpath "$::env(HOME)/.puavo/usb-factory"

set pci_path_dir /dev/disk/by-path

set diskdevices [dict create]

# These are only valid with 13-post Icybox, and maybe not even with that
# always... we should check that it is plugged in.
set diskdevice_list [list pci-0000:00:14.0-usb-0:4.1:1.0-scsi-0:0:0:0       \
                          pci-0000:00:14.0-usb-0:4.2:1.0-scsi-0:0:0:0       \
                          pci-0000:00:14.0-usb-0:4.3:1.0-scsi-0:0:0:0       \
                          pci-0000:00:14.0-usb-0:4.4.1:1.0-scsi-0:0:0:0     \
                          pci-0000:00:14.0-usb-0:4.4.2:1.0-scsi-0:0:0:0     \
                          pci-0000:00:14.0-usb-0:4.4.3:1.0-scsi-0:0:0:0     \
                          pci-0000:00:14.0-usb-0:4.4.4.1:1.0-scsi-0:0:0:0   \
                          pci-0000:00:14.0-usb-0:4.4.4.2:1.0-scsi-0:0:0:0   \
                          pci-0000:00:14.0-usb-0:4.4.4.3:1.0-scsi-0:0:0:0   \
                          pci-0000:00:14.0-usb-0:4.4.4.4.1:1.0-scsi-0:0:0:0 \
                          pci-0000:00:14.0-usb-0:4.4.4.4.2:1.0-scsi-0:0:0:0 \
                          pci-0000:00:14.0-usb-0:4.4.4.4.3:1.0-scsi-0:0:0:0 \
                          pci-0000:00:14.0-usb-0:4.4.4.4.4:1.0-scsi-0:0:0:0]

# XXX Deltaco 7-port usb-hub
# set diskdevice_list [list pci-0000:00:14.0-usb-0:4.1.1:1.0-scsi-0:0:0:0 \
#                           pci-0000:00:14.0-usb-0:4.1.2:1.0-scsi-0:0:0:0 \
#                           pci-0000:00:14.0-usb-0:4.1.3:1.0-scsi-0:0:0:0 \
#                           pci-0000:00:14.0-usb-0:4.1.4:1.0-scsi-0:0:0:0 \
#                           pci-0000:00:14.0-usb-0:4.2:1.0-scsi-0:0:0:0   \
#                           pci-0000:00:14.0-usb-0:4.3:1.0-scsi-0:0:0:0   \
#                           pci-0000:00:14.0-usb-0:4.4:1.0-scsi-0:0:0:0]

# XXX perhaps do not use cat, but open + read + close ?
proc read_file {path} { exec cat $path }

proc update_image {image imagepath new_width new_height} {
  set tmpfile [exec mktemp /tmp/puavo-usb-factory-image.XXXXXXX]
  set img_size "${new_width}x${new_height}!"
  exec -ignorestderr convert $imagepath -resize $img_size png:$tmpfile
  $image read $tmpfile -shrink
  exec rm -f $tmpfile
}

proc do_background_resizing {} {
  global bg_image bg_image_path support_logo_path

  if {[dict get $bg_image width] != [dict get $bg_image new_width]
        || [dict get $bg_image height] != [dict get $bg_image new_height]} {

    # XXX it would be better to use standard output
    set new_width  [dict get $bg_image new_width]
    set new_height [dict get $bg_image new_height]

    update_image bg_photo $bg_image_path $new_width $new_height
    # XXX hardcoded pixel sizes
    update_image support_photo $support_logo_path 966 64

    dict set bg_image width  $new_width
    dict set bg_image height $new_height
  }
}

proc queue_background_resizing {width height} {
  global bg_image
  dict set bg_image new_width  $width
  dict set bg_image new_height $height
  after 500 do_background_resizing
}

proc ui_msg {args} {
  global ui_messages
  dict get $ui_messages {*}$args
}

proc update_ui_info_state {} {
  global bg_image image_info

  set download_status [dict get $image_info status]
  set version         [dict get $image_info version]

  switch -- $download_status {
    up-to-date    -
    {in progress} -
    failed        -
    missing { set download_message [ui_msg {download state} $download_status] }
    default { set download_message [ui_msg {download state} undefined] }
  }
  .f.version_status.download_status configure -text $download_message

  if {$version ne ""} {
    set version_message $version
  } else {
    set version_message -
  }
  .f.version_status.version_number configure -text $version_message

  set bg_width  [dict get $bg_image width]
  set bg_height [dict get $bg_image height]

  after 10000 update_image_info
}

proc get_content_dir {} {
  global puavo_usb_factory_workpath

  if {[catch { glob ${puavo_usb_factory_workpath}/* } res]} {
    error "${puavo_usb_factory_workpath}/* did not match any files: $res"
  }
  set workpath_dirs $res

  set dir_count [llength $workpath_dirs]
  if {$dir_count == 0} {
    error "no disk image to write"
  } elseif {$dir_count > 1} {
    error "only one disk image is supported for now"
  }

  lindex $workpath_dirs 0
}

proc update_image_info {} {
  global image_info

  dict set image_info image_size        ""
  dict set image_info latest_image_path ""
  dict set image_info status            ""
  dict set image_info version           ""

  try {
    set content_dir [get_content_dir]
  } on error {} {
    update_ui_info_state
    return false
  }

  set content_name [file tail $content_dir]

  if {![catch { read_file "${content_dir}/DOWNLOAD_STATUS" } res]} {
    dict set image_info status [string trim $res]
  } else {
    dict set image_info status missing
  }

  if {![catch { read_file "${content_dir}/LATEST_IMAGE" } res]} {
    set latest_image_path "${content_dir}/[string trim $res]"
    if {[file exists $latest_image_path]} {
      dict set image_info image_size [file size $latest_image_path]
      dict set image_info latest_image_path $latest_image_path
    }
  }

  if {![catch { read_file "${content_dir}/VERSION" } res]} {
    dict set image_info version [string trim $res]
  }

  update_ui_info_state
}

proc get_port_num {devpath} {
  global diskdevice_list
  expr { 1 + [lsearch $diskdevice_list $devpath] }
}

proc close_if_open {devpath} {
  global diskdevices

  set fh [dict get $diskdevices $devpath fh]
  if {$fh ne ""} {
    catch { close $fh }
  }
  dict set diskdevices $devpath fh ""
}

proc start_preparation {devpath countdown} {
  global diskdevices

  if {[dict get $diskdevices $devpath state] ne "starting"} {
    return
  }

  set port [get_port_num $devpath]

  if {$countdown == 0} {
    set_devstate $devpath writing
    return
  }

  .f.disks.port_${port}.info.status configure \
    -text "[ui_msg messages starting] $countdown"

  incr countdown -1
  after 1000 [list start_preparation $devpath $countdown]
}

proc start_writing {devpath} {
  global diskdevices image_info pci_path_dir

  set image_size [dict get $image_info image_size]
  set srcfile    [dict get $image_info latest_image_path]

  if {$image_size eq "" || $srcfile eq ""} {
    set_devstate $devpath error
    return ""
  }

  dict set diskdevices $devpath image_size $image_size

  set fh [open "| pv -b -n $srcfile | dd of=${pci_path_dir}/${devpath} conv=fsync,nocreat status=none 2>@1"]
  fconfigure $fh -buffering line
  fileevent $fh readable [list handle_fileevent $devpath]
  return $fh
}

proc set_device_eta {devpath bytes_written} {
  global diskdevice_list diskdevices image_info

  set image_size [dict get $diskdevices $devpath image_size]

  set current_time_in_ms [clock milliseconds]

  set progress_list [dict get $diskdevices $devpath progress_list]
  lappend progress_list $current_time_in_ms $bytes_written
  dict set diskdevices $devpath progress_list $progress_list

  set time_cutpoint [expr { $current_time_in_ms - 30000 }]

  set cut_progress_times [list]
  set progress_list [dict get $diskdevices $devpath progress_list]
  foreach {old_time_in_ms old_bytes_written} $progress_list {
    if {$old_time_in_ms >= $time_cutpoint} {
      lappend cut_progress_times $old_time_in_ms $old_bytes_written
    }
  }
  dict set diskdevices $devpath progress_list $cut_progress_times

  lassign $cut_progress_times first_time first_bytes_written

  set eta -
  if {$first_time ne "" && $first_bytes_written ne ""} {
    set bytes_diff [expr { $bytes_written - $first_bytes_written }]
    set time_diff  [expr { $current_time_in_ms - $first_time }]
    set bytes_left [expr { $image_size - $bytes_written }]

    if {$time_diff > 0} {
      set speed [expr { $bytes_diff / $time_diff }]
      if {$speed > 0} {
        set eta_in_ms [expr { $bytes_left / $speed }]
        set eta_in_s [expr { round($eta_in_ms / 1000.0) }]
        set eta "[expr { $eta_in_s / 60 }]min [expr { $eta_in_s % 60 }]s"
      }
    }
  }

  set percentage [expr { round(100.0 * $bytes_written / $image_size) }]

  set_devstate $devpath progress $eta $percentage
}

proc handle_fileevent {devpath} {
  global diskdevices

  set fh [dict get $diskdevices $devpath fh]
  set progressline [gets $fh]

  if {[eof $fh]} {
    if {[catch { close $fh }]} {
      set_devstate $devpath error
    } else {
      set_devstate $devpath finished
    }
    return
  }

  set bytes_written [string trim $progressline]
  # $bytes_written might be an error string, do not handle that
  if {[string is integer -strict $bytes_written]} {
    set_device_eta $devpath $bytes_written
  }
}

proc update_disklabel {devpath {label "LOOKUP"}} {
  global diskdevices

  set port [get_port_num $devpath]

  if {$label ne "LOOKUP"} {
    set device_label $label
  } else {
    set device_label "???"
    try {
      if {![regexp {usb-0:(.*?):} $devpath _ pci_devpath]} {
        error "$devpath is in unexpected format"
      }

      set matches [glob "/sys/bus/usb/devices/\[0-9\]-${pci_devpath}"]
      if {[llength $matches] != 1} {
        error "multiple paths match when looking path under $pci_devpath"
      }

      set device_infodir [lindex $matches 0]

      set manufacturer [read_file "${device_infodir}/manufacturer"]
      set product      [read_file "${device_infodir}/product"]
      set device_size_in_bytes [get_device_size $devpath]

      set device_size "?"
      if {$device_size_in_bytes ne ""} {
        set device_size_in_gigabytes [
          expr { (0.0 + $device_size_in_bytes) / (10**9) }
        ]
        set device_size [format "%.1fGB" $device_size_in_gigabytes]
      }

      set device_label "$manufacturer / $product ($device_size)"
    } on error {errmsg} {
      puts stderr "could not lookup path for $devpath: $errmsg"
    }
  }

  .f.disks.port_${port}.info.disklabel configure -text $device_label
}

proc set_ui_status_to_nomedia {devpath} {
  global diskdevices

  set port [get_port_num $devpath]
  if {[dict get $diskdevices $devpath state] eq "nomedia"} {
    .f.disks.port_${port}.info.status  configure -text  ""
    .f.disks.port_${port}.pb_frame.bar configure -value 0
  }
}

proc set_devstate {devpath state args} {
  global diskdevices

  set port [get_port_num $devpath]

  switch -- $state {
    error {
      close_if_open $devpath
      dict set diskdevices $devpath state error

      .f.disks.port_${port}.info.status configure \
         -text [ui_msg messages error]
      .f.disks.port_${port}.pb_frame.bar configure -value 0
    }

    finished {
      close_if_open $devpath
      dict set diskdevices $devpath state finished

      .f.disks.port_${port}.info.status configure \
         -text [ui_msg messages finished]
      .f.disks.port_${port}.pb_frame.bar configure -value 100
    }

    nomedia {
      close_if_open $devpath
      set current_state [dict get $diskdevices $devpath state]

      if {$current_state ne "nomedia"} {
        dict set diskdevices $devpath [
          dict create fh            ""       \
                      image_size    ""       \
                      progress_list [list]   \
                      state         nomedia]

        update_disklabel $devpath ""

        if {$current_state eq "error"} {
          # show error message for ten seconds in UI
          after 10000 [list set_ui_status_to_nomedia $devpath]
        } else {
          set_ui_status_to_nomedia $devpath
        }
      }
    }

    nospaceondevice {
      close_if_open $devpath
      dict set diskdevices $devpath state nospaceondevice
      update_disklabel $devpath
      .f.disks.port_${port}.info.status configure \
        -text [ui_msg messages nospaceondevice]
      .f.disks.port_${port}.pb_frame.bar configure -value 0
    }

    progress {
      lassign $args eta percentage
      .f.disks.port_${port}.info.status  configure -text  $eta
      .f.disks.port_${port}.pb_frame.bar configure -value $percentage
    }

    starting {
      dict set diskdevices $devpath state starting
      update_disklabel $devpath
      start_preparation $devpath 10
    }

    writing {
      set fh [start_writing $devpath]
      dict set diskdevices $devpath fh $fh

      if {$fh ne ""} {
        dict set diskdevices $devpath state writing

        .f.disks.port_${port}.info.status  configure -text  -
        .f.disks.port_${port}.pb_frame.bar configure -value 0
      }
    }
  }
}

proc get_device_size {devpath} {
  global pci_path_dir

  set device_size ""
  set full_devpath "${pci_path_dir}/${devpath}"

  if {[catch { set f [open $full_devpath r] }]} {
    return $device_size
  }
  catch {
    seek $f 0 end
    set device_size [tell $f]
  }

  catch { close $f }
  return $device_size
}

proc check_for_space_in_device {devpath} {
  global image_info

  set device_size [get_device_size $devpath]
  set image_size [dict get $image_info image_size]

  if {$device_size eq ""} { error "could not get device size" }
  if {$image_size  eq ""} { error "could not get image size"  }

  expr { $device_size >= $image_size }
}

proc check_files {} {
  global diskdevices pci_path_dir

  dict for {devpath devstate} $diskdevices {
    set full_devpath "${pci_path_dir}/${devpath}"
    if {[file exists $full_devpath]} {
      if {[dict get $devstate state] eq "nomedia"} {
        if {[catch { check_for_space_in_device $devpath } res]} {
          set_devstate $devpath error
        } elseif {$res} {
          set_devstate $devpath starting
        } else {
          set_devstate $devpath nospaceondevice
        }
      }
    } else {
      set_devstate $devpath nomedia
    }
  }

  after 250 check_files
}

foreach devpath $diskdevice_list {
  dict set diskdevices $devpath [
    dict create fh            ""     \
                image_size    ""     \
                progress_list [list] \
                state         nomedia]
}

#
# setup UI
#

# style options

# ttk::style theme Instructions Instructions -background black -foreground lightgrey

# XXX theme ?
puts "available themes: [ttk::style theme names]"
# ttk::style theme use clam
puts "used theme: [ttk::style theme use]"

font create titleFont       -family Arial -size 32 -weight bold
font create descriptionFont -family "Domestic Manners" -size 20 -weight bold
font create infoFont        -family FreeSans -size 14

# ui messages

try {
  set ui_messages [
    ::json::json2dict [read_file "[get_content_dir]/UI.json"]
  ]
} on error {} {
  puts stderr "could not read ui messages from UI.json"
  exit 1
}

# ui elements

ttk::frame .f

pack .f

# images
# XXX using ttk for image?
image create photo bg_photo
label .f.bg -image bg_photo
image create photo support_photo
label .f.support_photo -image support_photo

ttk::frame .f.instructions -width 600 -height 200

ttk::label .f.instructions.title -text [ui_msg title] \
                                 -wraplength 600      \
                                 -padding 20          \
                                 -font titleFont
ttk::label .f.instructions.description -text [ui_msg description] \
                                       -wraplength 600            \
                                       -padding 20                \
                                       -font descriptionFont
ttk::label .f.instructions.steps -text [ui_msg instructions] \
                                 -wraplength 600             \
                                 -padding 20                 \
                                 -font descriptionFont

ttk::frame .f.version_status
ttk::label .f.version_status.version_label \
           -text [ui_msg "version label"] -font infoFont
ttk::label .f.version_status.version_number -font infoFont
ttk::label .f.version_status.download_status_label \
           -text [ui_msg "download status label"] -font infoFont
ttk::label .f.version_status.download_status -font infoFont
ttk::label .f.version_status.hostname_label \
           -text [ui_msg "hostname label"] -font infoFont
ttk::label .f.version_status.hostname -text [exec hostname -f] \
                                      -font infoFont

ttk::frame .f.disks

foreach devpath $diskdevice_list {
  set port [get_port_num $devpath]

  ttk::frame .f.disks.port_${port} -borderwidth 1
  ttk::frame .f.disks.port_${port}.info
  ttk::frame .f.disks.port_${port}.pb_frame -height 8

  ttk::label .f.disks.port_${port}.info.number -text $port -width 3 \
             -font infoFont
  ttk::label .f.disks.port_${port}.info.disklabel -text "" \
             -font infoFont
  ttk::label .f.disks.port_${port}.info.status -width 20 \
             -font infoFont
  ttk::progressbar .f.disks.port_${port}.pb_frame.bar \
                   -orient horizontal -maximum 100 -value 0

  # XXX grid?
  pack .f.disks.port_${port}.info.number    \
       .f.disks.port_${port}.info.status    \
       .f.disks.port_${port}.info.disklabel \
       -side left -padx 16
  pack .f.disks.port_${port}.info \
       .f.disks.port_${port}.pb_frame -expand 1 -fill x
  place .f.disks.port_${port}.pb_frame.bar -in .f.disks.port_${port}.pb_frame \
        -relwidth 1.0 -relheight 1.0
  pack .f.disks.port_${port} -expand 1 -fill x
}

place .f.instructions -relx 0.02 -rely 0.05
pack .f.instructions.title \
     .f.instructions.description \
     .f.instructions.steps -anchor w

place .f.version_status -relx 0.1 -rely 0.7

grid .f.version_status.version_label         \
     .f.version_status.version_number -sticky w
grid .f.version_status.download_status_label \
     .f.version_status.download_status -sticky w
grid .f.version_status.hostname_label \
     .f.version_status.hostname -sticky w

place .f.disks -relx 0.49 -rely 0.05

place .f.support_photo -relx 0.16 -rely 0.88

pack .f .f.bg -fill both -expand 1

bind . <Configure> {
  if {"%W" eq [winfo toplevel %W]} {
    queue_background_resizing %w %h
  }
}

update_image_info
check_files
