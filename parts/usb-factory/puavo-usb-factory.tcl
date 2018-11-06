#!/usr/bin/wish

wm attributes . -fullscreen 1

# XXX not a correct picture
set bg_image_path /usr/share/backgrounds/Blue_frost_by_ppaabblloo77.jpg

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

set pci_path_dir /dev/disk/by-path

set diskdevices [dict create]

# These are only valid with 13-post Icybox, and maybe not even with that
# always... we should check that it is plugged in.
set diskdevice_list [list pci-0000:00:14.0-usb-0:4.1:1.0-scsi-0:0:0:0        \
                          pci-0000:00:14.0-usb-0:4.2:1.0-scsi-0:0:0:0        \
                          pci-0000:00:14.0-usb-0:4.3:1.0-scsi-0:0:0:0        \
                          pci-0000:00:14.0-usb-0:4.4.1:1.0-scsi-0:0:0:0      \
                          pci-0000:00:14.0-usb-0:4.4.2:1.0-scsi-0:0:0:0      \
                          pci-0000:00:14.0-usb-0:4.4.3:1.0-scsi-0:0:0:0      \
                          pci-0000:00:14.0-usb-0:4.4.4.1:1.0-scsi-0:0:0:0    \
                          pci-0000:00:14.0-usb-0:4.4.4.2:1.0-scsi-0:0:0:0    \
                          pci-0000:00:14.0-usb-0:4.4.4.3:1.0-scsi-0:0:0:0    \
                          pci-0000:00:14.0-usb-0:4.4.4.4.1:1.0-scsi-0:0:0:0  \
                          pci-0000:00:14.0-usb-0:4.4.4.4.2:1.0-scsi-0:0:0:0  \
                          pci-0000:00:14.0-usb-0:4.4.4.4.3:1.0-scsi-0:0:0:0  \
                          pci-0000:00:14.0-usb-0:4.4.4.4.4:1.0-scsi-0:0:0:0]

proc do_background_resizing {} {
  global bg_image bg_image_path

  if {[dict get $bg_image width] != [dict get $bg_image new_width]
        || [dict get $bg_image height] != [dict get $bg_image new_height]} {

    # XXX it would be better to use standard output
    set tmpfile [exec mktemp /tmp/puavo-usb-factory-bg-image.XXXXXXX]
    set new_width  [dict get $bg_image new_width]
    set new_height [dict get $bg_image new_height]
    set img_size "${new_width}x${new_height}!"
    exec -ignorestderr convert $bg_image_path -resize $img_size png:$tmpfile
    bg_photo read $tmpfile -shrink
    exec rm -f $tmpfile

    dict set bg_image width  [dict get $bg_image new_width]
    dict set bg_image height [dict get $bg_image new_height]
  }
}

proc queue_background_resizing {width height} {
  global bg_image
  dict set bg_image new_width  $width
  dict set bg_image new_height $height
  after 500 do_background_resizing
}

proc update_ui_info_state {} {
  global bg_image image_info

  set download_status [dict get $image_info status]
  set version         [dict get $image_info version]

  switch -- $download_status {
    ok            { set download_message "Image is up-to-date." }
    {in progress} { set download_message "Downloading new version" }
    failed        { set download_message "Downloading new version failed" }
    default       { set download_message "No image to write" }
  }
  .f.download_status configure -text $download_message

  if {$version ne ""} {
    set version_message $version
  } else {
    set version_message "(DOWNLOADING IMAGE)"
  }
  .f.version configure -text $version_message

  set bg_width  [dict get $bg_image width]
  set bg_height [dict get $bg_image height]

  after 10000 update_image_info
}

proc update_image_info {} {
  global image_info

  set puavo_usb_factory_workpath "$::env(HOME)/.puavo/usb-factory"

  dict set image_info image_size        ""
  dict set image_info latest_image_path ""
  dict set image_info status            ""
  dict set image_info version           ""

  if {[catch { glob ${puavo_usb_factory_workpath}/* } res]} {
    puts stderr "${puavo_usb_factory_workpath}/* did not match any files"
    update_ui_info_state
    return false
  }
  set workpath_dirs $res

  set dir_count [llength $workpath_dirs]
  set errmsg ""
  if {$dir_count == 0} {
    set errmsg "no disk image to write"
  } elseif {$dir_count > 1} {
    set errmsg "only one disk image is supported for now"
  }
  if {$errmsg ne ""} {
    puts stderr $errmsg
    update_ui_info_state
    return false
  }

  set content_dir  [lindex $workpath_dirs 0]
  set content_name [file tail $content_dir]

  if {![catch { exec cat "${content_dir}/DOWNLOAD_STATUS" } res]} {
    dict set image_info status [string trim $res]
  }

  if {![catch { exec cat "${content_dir}/LATEST_IMAGE" } res]} {
    set latest_image_path "${content_dir}/[string trim $res]"
    if {[file exists $latest_image_path]} {
      dict set image_info image_size [file size $latest_image_path]
      dict set image_info latest_image_path $latest_image_path
    }
  }

  if {![catch { exec cat "${content_dir}/VERSION" } res]} {
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

  .f.disks.port_${port}.status configure -text "Starting $countdown"

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

    if {$bytes_diff > 0 && $time_diff > 0} {
      set eta_in_ms [expr { $bytes_left / ($bytes_diff / $time_diff) }]
      set eta_in_s [expr { round($eta_in_ms / 1000.0) }]
      set eta "[expr { $eta_in_s / 60 }]min [expr { $eta_in_s % 60 }]s"
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
    if {[catch { close $fh } cres e]} {
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

proc set_ui_status_to_nomedia {devpath} {
  global diskdevices

  set port [get_port_num $devpath]
  if {[dict get $diskdevices $devpath state] eq "nomedia"} {
    .f.disks.port_${port}.progress configure -value 0
    .f.disks.port_${port}.status   configure -text  ""
  }
}

proc set_devstate {devpath state args} {
  global diskdevices

  set port [get_port_num $devpath]

  switch -- $state {
    error {
      close_if_open $devpath
      dict set diskdevices $devpath state error

      .f.disks.port_${port}.progress configure -value 0
      .f.disks.port_${port}.status   configure -text  "Error"
    }

    finished {
      close_if_open $devpath
      dict set diskdevices $devpath state finished

      .f.disks.port_${port}.progress configure -value 100
      .f.disks.port_${port}.status   configure -text  "OK"
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
      .f.disks.port_${port}.progress configure -value 0
      .f.disks.port_${port}.status   configure -text  "No space on device"
    }

    progress {
      lassign $args eta percentage
      .f.disks.port_${port}.progress configure -value $percentage
      .f.disks.port_${port}.status   configure -text  $eta
    }

    starting {
      dict set diskdevices $devpath state starting
      start_preparation $devpath 10
    }

    writing {
      set fh [start_writing $devpath]
      dict set diskdevices $devpath fh $fh

      if {$fh ne ""} {
        dict set diskdevices $devpath state writing

        .f.disks.port_${port}.progress configure -value 0
        .f.disks.port_${port}.status   configure -text -
      }
    }
  }
}

proc get_device_size {full_devpath} {
  set device_size ""

  if {[catch { set f [open $full_devpath r] }]} {
    return $device_size
  }
  catch {
    seek $f 0 end
    set device_size [tell $f]
  }

  close $f
  return $device_size
}

proc check_for_space_in_device {full_devpath} {
  global image_info

  set device_size [get_device_size $full_devpath]
  set image_size [dict get $image_info image_size]

  expr {
    ($device_size ne "" && $device_size > 0)
      && ($image_size ne "" && $image_size > 0)
      && ($device_size >= $image_size)
  }
}

proc check_files {} {
  global diskdevices pci_path_dir

  dict for {devpath devstate} $diskdevices {
    set full_devpath "${pci_path_dir}/${devpath}"
    if {[file exists $full_devpath]} {
      if {[dict get $devstate state] eq "nomedia"} {
        if {[check_for_space_in_device $full_devpath]} {
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

frame .f
image create photo bg_photo
label .f.bg -image bg_photo

label .f.download_status
label .f.version

frame .f.disks

foreach devpath $diskdevice_list {
  set port [get_port_num $devpath]

  frame .f.disks.port_${port}

  label .f.disks.port_${port}.number -text $port -width 3
  # XXX -length 500 does not scale
  ttk::progressbar .f.disks.port_${port}.progress \
                   -orient horizontal -maximum 100 -length 500 -value 0
  label .f.disks.port_${port}.status -width 10

  # XXX constant 8 does not scale
  pack .f.disks.port_${port}
  pack .f.disks.port_${port}.number   \
       .f.disks.port_${port}.progress \
       .f.disks.port_${port}.status \
       -side left -pady 8
}

place .f.download_status -relx 0.1  -rely 0.8
place .f.version         -relx 0.2  -rely 0.5
place .f.disks           -relx 0.52 -rely 0.145

pack .f .f.bg -fill both -expand 1

bind . <Configure> {
  if {"%W" eq [winfo toplevel %W]} {
    queue_background_resizing %w %h
  }
}

update_image_info
check_files
