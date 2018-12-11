#!/usr/bin/env wish

package require json
package require json::write

wm attributes . -fullscreen 1
# wm minsize  . 800 600
# wm maxsize  . 1440 900
wm protocol . WM_DELETE_WINDOW { }      ;# do not allow window close

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
array set rotating_usb_labels ""
array set usb_labels ""
set writable_labels false

array set paths [list \
  flash_drive_blue      /usr/share/puavo-usb-factory/flash-drive-blue.png    \
  flash_drive_green     /usr/share/puavo-usb-factory/flash-drive-green.png   \
  flash_drive_grey      /usr/share/puavo-usb-factory/flash-drive-grey.png    \
  flash_drive_magenta   /usr/share/puavo-usb-factory/flash-drive-magenta.png \
  flash_drive_red       /usr/share/puavo-usb-factory/flash-drive-red.png     \
  flash_drive_white     /usr/share/puavo-usb-factory/flash-drive-white.png   \
  flash_drive_yellow    /usr/share/puavo-usb-factory/flash-drive-yellow.png  \
  puavo_usb_factory_workdir $::env(HOME)/.puavo/usb-factory                  \
]

set pci_path_dir /dev/disk/by-path

set diskdevices [dict create]
set usbhubs     [dict create]
set new_usbhubs [dict create]

# XXX perhaps do not use cat, but open + read + close ?
proc read_file {path} { exec cat $path }

proc update_image {image imagepath new_width new_height} {
  # XXX it would be better to use standard output
  set tmpfile [exec mktemp /tmp/puavo-usb-factory-image.XXXXXXX]
  set img_size "${new_width}x${new_height}!"
  exec -ignorestderr convert $imagepath -resize $img_size png:$tmpfile
  $image read $tmpfile -shrink
  exec rm -f $tmpfile
}

proc do_background_resizing {} {
  global bg_image bg_image_path canvas_image_index

  set size_diff [ expr {
    max(abs([dict get $bg_image width]  - [dict get $bg_image new_width]),
        abs([dict get $bg_image height] - [dict get $bg_image new_height]))
  }]

  if {$size_diff >= 4} {
    set new_width  [dict get $bg_image new_width]
    set new_height [dict get $bg_image new_height]

    update_image bg_photo $bg_image_path $new_width $new_height
    .f coords $canvas_image_index [expr { int($new_width/2)  }]  \
                                  [expr { int($new_height/2) }]

    dict set bg_image width  $new_width
    dict set bg_image height $new_height
  }
}

set bg_resizing_event ""
proc queue_background_resizing {width height} {
  global bg_image bg_resizing_event

  dict set bg_image new_width  $width
  dict set bg_image new_height $height

  if {$bg_resizing_event ne ""} { after cancel $bg_resizing_event }
  set bg_resizing_event [after 500 do_background_resizing]
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
  .f.version_status.download.status configure -text $download_message

  if {$version ne ""} {
    set version_message $version
  } else {
    set version_message -
  }
  .f.version_status.version.number configure -text $version_message

  set bg_width  [dict get $bg_image width]
  set bg_height [dict get $bg_image height]

  after 10000 update_image_info
}

proc get_content_dir {} {
  global paths

  if {[catch { glob $paths(puavo_usb_factory_workdir)/* } res]} {
    error "$paths(puavo_usb_factory_workdir)/* did not match any files: $res"
  }
  set workpath_dirs [
    lmap path $res { expr { [file isdirectory $path] ? $path : [continue] } }
  ]

  set dir_count [llength $workpath_dirs]
  if {$dir_count == 0} {
    error "no disk image to write"
  } elseif {$dir_count > 1} {
    error "only one disk image is supported for now"
  }

  lindex $workpath_dirs 0
}

proc update_image_info {} {
  global content_dir image_info

  dict set image_info image_size        ""
  dict set image_info latest_image_path ""
  dict set image_info status            ""
  dict set image_info version           ""

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

  if {![dict exists $diskdevices $devpath]} {
    return
  }
  if {[dict get $diskdevices $devpath state] ne "start_writing"} {
    return
  }

  set port_ui [dict get $diskdevices $devpath ui]

  set_rotating_label $port_ui messages [list [ui_msg messages start_writing]]

  if {$countdown == 0} {
    set_devstate $devpath writing
    return
  }

  if {$countdown % 2 == 0} {
    set_usbport_image $port_ui flash_drive_magenta [expr { 1.0/4 }]
  } else {
    set_usbport_image $port_ui flash_drive_white
  }

  incr countdown -1
  after 250 [list start_preparation $devpath $countdown]
}

proc start_operating {devpath cmd} {
  global diskdevices image_info

  set image_size [dict get $image_info image_size]
  set srcfile    [dict get $image_info latest_image_path]
  set version    [dict get $image_info version]

  if {$image_size eq "" || $srcfile eq "" || $version eq ""} {
    set_devstate $devpath error
    return ""
  }

  dict set diskdevices $devpath image_size $image_size
  dict set diskdevices $devpath version    $version

  set fh [open "| $cmd"]
  fconfigure $fh -buffering line
  fileevent $fh readable [list handle_fileevent $devpath]
  return $fh
}

proc start_verifying {devpath} {
  global image_info pci_path_dir
  set image_size [dict get $image_info image_size]
  set srcfile     [dict get $image_info latest_image_path]
  set cmd "nice -n 20 ionice -c 3 pv -b -n $srcfile | nice -n 20 ionice -c 3 cmp -n $image_size ${pci_path_dir}/${devpath} - 2>@1"
  start_operating $devpath $cmd
}

proc start_writing {devpath} {
  global image_info pci_path_dir
  set srcfile [dict get $image_info latest_image_path]
  set cmd "nice -n 20 ionice -c 3 pv -b -n $srcfile | nice -n 20 ionice -c 3 dd of=${pci_path_dir}/${devpath} conv=fsync,nocreat status=none 2>@1"
  start_operating $devpath $cmd
}

proc set_device_eta {devpath bytes_handled} {
  global diskdevices image_info

  set image_size [dict get $diskdevices $devpath image_size]

  set current_time_in_ms [clock milliseconds]

  set progress_list [dict get $diskdevices $devpath progress_list]
  lappend progress_list $current_time_in_ms $bytes_handled
  dict set diskdevices $devpath progress_list $progress_list

  set time_cutpoint [expr { $current_time_in_ms - 60000 }]

  set cut_progress_times [list]
  set progress_list [dict get $diskdevices $devpath progress_list]
  foreach {old_time_in_ms old_bytes_handled} $progress_list {
    if {$old_time_in_ms >= $time_cutpoint} {
      lappend cut_progress_times $old_time_in_ms $old_bytes_handled
    }
  }
  dict set diskdevices $devpath progress_list $cut_progress_times

  lassign $cut_progress_times first_time first_bytes_handled

  set percentage [expr { round(100.0 * $bytes_handled / $image_size) }]

  if {[dict get $diskdevices $devpath state] eq "writing"} {
    # When we are in writing phase, we do some tricks in the ETA
    # calculation, because the initial estimates are too optimistic
    # and there will be a verification step afterwards.
    set eta_image_size [expr {
      int($image_size + ((0.3 * ($image_size - 0.95 * $bytes_handled))))
    }]
  } else {
    set eta_image_size $image_size
  }

  set eta ""
  if {$first_time ne "" && $first_bytes_handled ne ""} {
    set bytes_diff [expr { $bytes_handled - $first_bytes_handled }]
    set time_diff  [expr { $current_time_in_ms - $first_time }]
    set bytes_left [expr { $eta_image_size - $bytes_handled }]

    if {$time_diff > 0} {
      set speed [expr { $bytes_diff / $time_diff }]
      if {$speed > 0} {
        set eta_in_ms [expr { $bytes_left / $speed }]
        set eta_in_s [expr { round($eta_in_ms / 1000.0) }]
        set eta "[expr { $eta_in_s / 60 }]min [expr { $eta_in_s % 60 }]s"
      }
    }
  }

  set_devstate $devpath progress $percentage $eta
}

proc handle_fileevent {devpath} {
  global diskdevices

  set fh [dict get $diskdevices $devpath fh]
  set progressline [gets $fh]

  if {[eof $fh]} {
    if {[catch { close $fh }]} {
      set state [dict get $diskdevices $devpath state]
      if {$state eq "verifying"} {
        set_devstate $devpath start_writing
      } else {
        set_devstate $devpath error
      }
    } else {
      switch -- [dict get $diskdevices $devpath state] {
        writing { set_devstate $devpath verifying_after_write }
        verifying -
        verifying_after_write {
          set_devstate $devpath finished
        }
      }
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

  if {![dict exists $diskdevices $devpath]} {
    return
  }

  set port_ui [dict get $diskdevices $devpath ui]
  if {[dict get $diskdevices $devpath state] eq "nomedia"} {
    set_rotating_label $port_ui messages [list]
    set_usbport_image $port_ui flash_drive_white
  }
}

proc quick_verify_check {devpath} {
  global image_info pci_path_dir

  # A heuristic, not exact... check if first and last megabytes match
  # on device with image.  If this succeeds we must verify the whole
  # disk image on device, and if that fails we will start writing.

  set image_path [dict get $image_info latest_image_path]
  set image_size [dict get $image_info image_size]

  if {$image_path eq ""} { error "could not lookup image path" }
  if {$image_size eq ""} { error "could not lookup image size" }

  set chk_bytecount   [expr { min($image_size, 1048576) }]
  set end_block_start [expr { $image_size - $chk_bytecount }]

  set full_devpath "${pci_path_dir}/${devpath}"

  try {
    exec cmp -n $chk_bytecount $full_devpath $image_path
  } on error {} { return false }

  try {
    exec cmp -i $end_block_start -n $chk_bytecount $full_devpath $image_path
  } on error {} { return false }

  return true
}

proc set_devstate {devpath state args} {
  global diskdevices image_info

  set port_ui [dict get $diskdevices $devpath ui]

  switch -- $state {
    error {
      close_if_open $devpath
      dict set diskdevices $devpath state error

      set_rotating_label $port_ui messages [list [ui_msg messages error]]
      set_usbport_image $port_ui flash_drive_red
    }

    finished {
      close_if_open $devpath
      dict set diskdevices $devpath state finished

      set version [dict get $diskdevices $devpath version]

      set_rotating_label $port_ui messages \
                         [list "[ui_msg messages finished] $version"]
      set_usbport_image $port_ui flash_drive_green
    }

    nomedia {
      close_if_open $devpath
      set current_state [dict get $diskdevices $devpath state]

      if {$current_state ne "nomedia"} {
        # preserve the ui attribute
        dict set diskdevices $devpath fh            ""
        dict set diskdevices $devpath image_size    ""
        dict set diskdevices $devpath progress_list [list]
        dict set diskdevices $devpath state         nomedia
        dict set diskdevices $devpath version       ""

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
      set_rotating_label $port_ui messages \
                         [list [ui_msg messages nospaceondevice]]
      set_usbport_image $port_ui flash_drive_red
    }

    progress {
      lassign $args percentage eta
      set state [dict get $diskdevices $devpath state]
      switch -- $state {
        verifying -
        verifying_after_write -
        writing { set_ui_progress $port_ui $state $percentage $eta }
      }
    }

    start_writing {
      dict set diskdevices $devpath state start_writing
      start_preparation $devpath 41
    }

    verifying_after_write -
    verifying {
      if {[quick_verify_check $devpath]} {
        set fh [start_verifying $devpath]
        dict set diskdevices $devpath fh $fh
        if {$fh ne ""} {
          dict set diskdevices $devpath state $state
          set_rotating_label $port_ui messages \
                             [list [ui_msg messages verifying]]
        }
      } else {
        # if image is not in disk, move on to start_writing
        set_devstate $devpath start_writing
      }
    }

    writing {
      set fh [start_writing $devpath]
      dict set diskdevices $devpath fh $fh

      if {$fh ne ""} {
        dict set diskdevices $devpath state writing
        set_rotating_label $port_ui messages \
                           [list [ui_msg messages writing]]
      }
    }
  }
}

proc get_device_size {devpath} {
  global pci_path_dir

  set device_size ""
  set full_devpath "${pci_path_dir}/${devpath}"

  if {[catch { set f [open $full_devpath r] } err]} {
    puts stderr "error while opening $full_devpath: $err"
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
  set image_size  [dict get $image_info image_size]

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
          puts stderr "error while checking for space in device: $res"
          set_devstate $devpath error
        } elseif {$res} {
          set_devstate $devpath verifying
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

proc roll_rotating_usb_labels {list_index} {
  global diskdevices rotating_usb_labels writable_labels

  if {!$writable_labels} {
    dict for {devpath devstate} $diskdevices {
      set port_ui [dict get $devstate ui]
      set i [expr { $list_index % [llength $rotating_usb_labels($port_ui)] }]
      set labeltext [lindex $rotating_usb_labels($port_ui) $i]
      $port_ui itemconfigure port_label -text $labeltext
    }
  }

  if {$list_index % (2 * 3 * 5 * 7) == 0} {
    set list_index 0
  }

  incr list_index
  after 1500 [list roll_rotating_usb_labels $list_index]
}

proc set_rotating_label {port_ui type messages} {
  global rotating_usb_labels

  if {$type eq "port"} {
    set list_start [list {*}$messages {*}$messages]
    if {[info exists rotating_usb_labels($port_ui)]} {
      set list_end [lrange $rotating_usb_labels($port_ui) 2 3]
    } else {
      set list_end [list]
    }
  } else {
    set list_start [lrange $rotating_usb_labels($port_ui) 0 1]
    switch -- [llength $messages] {
      0 { set list_end $list_start }
      1 { set list_end [list {*}$messages {*}$messages] }
      2 {
          if {[lindex $messages 1] eq ""} {
            set list_end [list [lindex $messages 0] [lindex $messages 0]]
          } else {
            set list_end $messages
          }
        }
      default { error "unsupported rotating usb labels count" }
    }
  }

  set rotating_usb_labels($port_ui) [list {*}$list_start {*}$list_end]
}

proc make_usbport_label {devpath port_id port_ui {update false}} {
  global default_background_color rotating_usb_labels usb_labels writable_labels

  if {$update} { destroy $port_ui }

  set labelvar "port/${port_id}"
  set usb_labels($labelvar) [get_label $labelvar $port_id]

  set_rotating_label $port_ui port $usb_labels($labelvar)

  if {$writable_labels} {
    ttk::entry $port_ui -textvariable usb_labels($labelvar) \
                        -font smallInfoFont -justify center -width 14
  } else {
    canvas $port_ui -background $default_background_color -height 42 \
                    -highlightthickness 0 -width 215
    $port_ui create image 0 22 -image flash_drive_white -anchor w

    set_usbport_image $port_ui flash_drive_white
    $port_ui create image 0 22 -image "${port_ui}_overlay_image" -anchor w
    $port_ui create text  120 18 -font smallInfoFont -tags port_label \
             -text $usb_labels($labelvar)
  }
}

proc set_usbport_image {port_ui imagename {new_width {}}} {
  global flash_drive_image_width paths
  set ui_image "${port_ui}_overlay_image"

  if {$new_width ne ""} {
    set new_width_in_pixels [
      expr { int($new_width * $flash_drive_image_width) }
    ]

    set current_width [$ui_image cget -width]
    if {$current_width != $new_width_in_pixels} {
      image create photo $ui_image -file $paths($imagename) \
                                   -width $new_width_in_pixels
    }
  } else {
    image create photo $ui_image -file $paths($imagename)
  }
}

proc set_ui_progress {port_ui state percentage eta} {
  # Make writing progress go from 1/4 to 7/8,
  # the rest is verification progress (and change colour to indicate that).

  set initial_offset [expr { 1.0/4 }]
  set cutpoint       [expr { 7.0/8 }]

  switch -- $state {
    verifying {
      set imagename  "flash_drive_yellow"
      set startpoint $initial_offset
      set endpoint   1.0
      set msg        [ui_msg messages verifying]
    }
    verifying_after_write {
      set imagename  "flash_drive_yellow"
      set startpoint $cutpoint
      set endpoint   1.0
      set msg        [ui_msg messages verifying]
    }
    writing {
      set imagename  "flash_drive_blue"
      set startpoint $initial_offset
      set endpoint   $cutpoint
      set msg        [ui_msg messages writing]
    }
  }

  set new_width [expr {
    $startpoint + ($percentage/100.0) * ($endpoint - $startpoint)
  }]

  set_rotating_label $port_ui messages [list $msg $eta]
  set_usbport_image $port_ui $imagename $new_width
}

proc usbdevice_is_a_hub {usbpath} {
  try {
    if {[catch { set usbdevicepath_list [glob "${usbpath}/*:1.0"] } err]} {
      return false
    }
    if {[llength $usbdevicepath_list] != 1} {
      error "multiple device paths"
    }

    set usbdevicepath [lindex $usbdevicepath_list 0]

    set driver_path "${usbdevicepath}/driver"
    if {![file exists $driver_path]} {
      return false
    }

    if {[file tail [file readlink $driver_path]] eq "hub"} {
      return true
    }
  } on error {errmsg} {
    puts stderr "error determining if $usbpath is a hub: $errmsg"
    return false
  }

  return false
}

proc update_new_usbhubs {} {
  global new_usbhubs

  try {
    set _new_usbhubs  [dict create]
    set by_prodvendor [dict create]

    foreach pci_device_path [glob /sys/devices/pci*/0000:*] {
      set pci_id [file tail $pci_device_path]

      set paths [exec find $pci_device_path -type d \
                           -regex {.*[.-][0-9]+-port[0-9]+$}]

      foreach path $paths {
        if {![regexp {([0-9]+)$} $path _ portname]} {
          continue
        }

        set _portbase [file tail [file dirname $path]]
        if {![regexp {^[0-9]+-(.*)$} $_portbase _ portbase]} {
          continue
        }

        set usbport [string map [list {:} .$portname:] \
                                $portbase]

        set device_link "${path}/device"

        if {[file exists $device_link]} {
          if {[usbdevice_is_a_hub $device_link]} {
            continue
          }
        }

        try {
          set hub_manufacturer [read_file "${path}/../../manufacturer"]
          set hub_product      [read_file "${path}/../../product"]
        } on error {} {
          continue
        }

        if {![regexp {^([0-9]+)\.(.*):} $usbport _ port_firstnum port_id]} {
          puts stderr "cannot determine the first number of usb port"
          continue
        }

        set devpath "pci-${pci_id}-usb-0:${usbport}-scsi-0:0:0:0"

        set hub_id "${pci_id}/${port_firstnum}"
        dict set by_prodvendor $hub_manufacturer $hub_product $hub_id \
                 $port_id $devpath
      }
    }

    dict for {manufacturer productinfo} $by_prodvendor {
      dict for {product hubinfo} $productinfo {
        dict for {hub_id devpaths_by_port_id} $hubinfo {
          dict for {port_id devpath} $devpaths_by_port_id {
            dict set _new_usbhubs $hub_id "$manufacturer / $product" \
                                  ports $port_id $devpath
          }
        }
      }
    }
  } on error {errmsg} {
    puts stderr "error updating usbhubs: $errmsg"
    return
  }

  set new_usbhubs $_new_usbhubs
}

proc update_diskdevices_loop {} {
  update_diskdevices
  after 3000 update_diskdevices_loop
}

proc get_label {labelvar default_value} {
  global usb_labels
  set label [
    expr {
      [info exists usb_labels($labelvar)]
        ? $usb_labels($labelvar)
        : $default_value
    }
  ]
  expr { $label ne "" ? $label : $default_value }
}


proc dictionary_sort_by_label {label_prefix lst} {
  set labels [lmap p $lst { list $p [get_label "${label_prefix}/${p}" $p] } ]
  lmap x [lsort -index 1 -dictionary $labels] \
         { lindex $x 0 }
}

proc update_diskdevices {{force_ui_update false}} {
  global diskdevices pci_path_dir new_usbhubs usbhubs usb_labels writable_labels

  update_new_usbhubs

  set regrid false

  set diskdevices_in_hubs [dict create]
  # list all diskdevices in new hubs
  dict for {hub_id hubproducts} $new_usbhubs {
    dict for {product productinfo} $hubproducts {
      set portinfo [dict get $productinfo ports]
      dict for {port_id devpath} $portinfo {
        dict set diskdevices_in_hubs $devpath 1
      }
    }
  }

  # check all our current diskdevices and remove those
  # that are not in current hubs
  foreach devpath [dict keys $diskdevices] {
    if {[dict exists $diskdevices_in_hubs $devpath]} {
      continue
    }

    # $devpath is gone from usbhubs, remove it and its UI

    destroy [dict get $diskdevices $devpath ui]
    close_if_open $devpath
    dict unset diskdevices $devpath
    set regrid true

    dict for {hub_id hubproducts} $usbhubs {
      dict for {product productinfo} $hubproducts {
        set portinfo [dict get $productinfo ports]
        dict for {port_id usbhub_devpath} $portinfo {
          if {$devpath eq $usbhub_devpath} {
            dict unset usbhubs $hub_id $product ports $port_id
          }
        }
      }
    }
  }

  # destroy UI of hubs that have no devices
  dict for {hub_id hubproducts} $usbhubs {
    dict for {product productinfo} $hubproducts {
      set portinfo [dict get $productinfo ports]
      if {[llength [dict keys $portinfo]] == 0} {
        dict unset usbhubs $hub_id $product
      }
    }
  }
  dict for {hub_id hubproducts} $usbhubs {
    if {[llength [dict keys $hubproducts]] == 0} {
      dict unset usbhubs $hub_id
    }
  }

  set ui_elements [list]

  dict for {hub_id hubproducts} $new_usbhubs {
    set sorted_products [dictionary_sort_by_label "hub/${hub_id}" \
                                                  [dict keys $hubproducts]]
    # add new ports to UI
    dict for {product productinfo} $hubproducts {
      set sorted_ports [
        dictionary_sort_by_label port \
                                 [dict keys [dict get $productinfo ports]]
      ]

      foreach port_id $sorted_ports {
        set devpath [dict get $productinfo ports $port_id]
        set port_ui ".f.disks.port_[string map {. _} $port_id]"
        # Add UI for port and add it to diskdevices to manage.
        # Test for diskdevice existence, because the same $devpath
        # may be in two different products (USB2.0 vs. USB3.0).
        if {[dict exists $diskdevices $devpath]} {
          if {$force_ui_update} {
            make_usbport_label $devpath $port_id $port_ui true
            set regrid true
          }
        } else {
          make_usbport_label $devpath $port_id $port_ui
          dict set diskdevices $devpath [
            dict create fh            ""       \
                        image_size    ""       \
                        progress_list [list]   \
                        state         nomedia  \
                        ui            $port_ui \
                        version       ""       ]
          set regrid true
        }

        if {$port_ui ni $ui_elements} {
          lappend ui_elements $port_ui
        }
        dict set usbhubs $hub_id $product ports $port_id $devpath
      }
    }
  }

  if {[llength [dict keys $usbhubs]] == 0} {
    grid .f.disks.nohubs_message
  } else {
    grid forget .f.disks.nohubs_message
    if {$regrid} {
      set max_row_elements 15
      set total_element_count [llength $ui_elements]
      set element_count $total_element_count
      set need_for_columns 1
      while {$element_count > $max_row_elements} {
        set element_count [expr { $element_count - $max_row_elements }]
        incr need_for_columns
      }
      set divisor [expr {
        int(ceil((0.0 + $total_element_count) / $need_for_columns)) }
      ]

      set row_pos 1
      set column_pos 1
      foreach ui $ui_elements {
        grid forget $ui
        grid $ui -row $row_pos -column $column_pos -sticky w -ipadx 5
        if {$row_pos % $divisor == 0} { incr column_pos; set row_pos 0 }
        incr row_pos
      }
    }
  }
}

proc read_usb_labels_from_disk {} {
  global paths usb_labels
  set usblabels_json_path "$paths(puavo_usb_factory_workdir)/usb_labels.json"

  if {![file exists $usblabels_json_path]} {
    return
  }

  try {
    set labels [::json::json2dict [read_file $usblabels_json_path]]
  } on error {errmsg} {
    puts stderr "error reading usb labels from disk: $errmsg"
    return
  }

  dict for {key value} $labels {
    set usb_labels($key) $value
  }
}

proc update_usb_labels_on_disk {} {
  global paths usb_labels
  set usblabels_json_path "$paths(puavo_usb_factory_workdir)/usb_labels.json"
  set tmpfile "${usblabels_json_path}.tmp"

  set js_object [dict create]
  foreach {k v} [array get usb_labels] {
    dict set js_object $k [::json::write string $v]
  }

  set json [::json::write object {*}$js_object]

  set fh [open $tmpfile w]
  puts $fh $json
  close $fh

  file rename -force $tmpfile $usblabels_json_path
}

proc scroll_topbanner {} {
  global top_banner_pos topbanner_text_id
  incr top_banner_pos -1
  if {$top_banner_pos < 2250} {
    set top_banner_pos 3000
  }

  .f.top_banner coords $topbanner_text_id $top_banner_pos 20
  after 50 scroll_topbanner
}

#
# setup UI
#

font create smallInfoFont  -family {Ubuntu Condensed} -size 14 -weight bold
font create infoFont       -family {Ubuntu Condensed} -size 20 -weight bold
font create biggerInfoFont -family {Ubuntu Condensed} -size 24 -weight bold

# style options

set default_background_color #6392ac
ttk::style configure TFrame -background $default_background_color
ttk::style configure TLabel -background $default_background_color -font infoFont

# ui messages and background image

try {
  set content_dir [get_content_dir]
} on error {} {
  puts stderr "could not get content dir"
  exit 1
}
try {
  set bg_image_path "${content_dir}/UI.png"
} on error {} {
  puts stderr "could not read background image from ${content_dir}/UI.png"
  exit 1
}
try {
  set ui_messages [::json::json2dict [read_file "${content_dir}/UI.json"]]
} on error {} {
  puts stderr "could not read ui messages from ${content_dir}/UI.json"
  exit 1
}

# ui elements

canvas .f
image create photo bg_photo
set canvas_image_index [.f create image 0 0 -image bg_photo]

image create photo flash_drive_white -file $paths(flash_drive_white)
set flash_drive_image_width [image width flash_drive_white]

set top_banner_pos 3000
set top_banner_description ""
foreach i {1 2 3 4 5 6 7 8 9} {
  set top_banner_description "$top_banner_description   [ui_msg description]"
}
canvas .f.top_banner -background #95b6bf -height 40 \
                     -highlightthickness 0
set topbanner_text_id [
  .f.top_banner create text $top_banner_pos 30                     \
                -justify center -font biggerInfoFont -fill #ffdddd \
                -text $top_banner_description -width 10000
]

ttk::label .f.instructions -text [ui_msg instructions] \
                           -wraplength 600             \
                           -padding 20                 \
                           -font infoFont

ttk::frame .f.version_status
ttk::frame .f.version_status.version
ttk::frame .f.version_status.download
ttk::frame .f.version_status.hostname

ttk::label .f.version_status.version.label \
           -text [ui_msg "version label"] -font infoFont
ttk::label .f.version_status.version.number -font infoFont
ttk::label .f.version_status.download.label \
           -text [ui_msg "download status label"] -font infoFont
ttk::label .f.version_status.download.status -font infoFont
ttk::label .f.version_status.hostname.label \
           -text [ui_msg "hostname label"] -font infoFont
ttk::label .f.version_status.hostname.value -text [exec hostname] \
                                            -font infoFont

ttk::frame .f.disks
ttk::label .f.disks.nohubs_message -font infoFont \
                                   -text [ui_msg "waiting usb hubs"] \
                                   -padding 40

pack .f.top_banner -side top -fill x

pack .f.version_status -side bottom -ipady 14 -fill x
pack .f.version_status.hostname \
     .f.version_status.version  \
     .f.version_status.download -side left -padx 30
pack .f.version_status.hostname.label .f.version_status.hostname.value \
     -side left -padx 5
pack .f.version_status.version.label .f.version_status.version.number \
     -side left -padx 5
pack .f.version_status.download.label .f.version_status.download.status \
     -side left -padx 5

pack .f.instructions -side left -anchor n -padx 40 -pady 40

pack .f.disks -side right
grid .f.disks.nohubs_message

pack .f -fill both -expand 1

bind . <Configure> {
  if {"%W" eq [winfo toplevel %W]} {
    queue_background_resizing %w %h
  }
}

bind . <Control-x> {
  set writable_labels [expr { $writable_labels ? "false" : "true" }]
  if {!$writable_labels} {
    update_usb_labels_on_disk
  }
  update_diskdevices true
}

scroll_topbanner
read_usb_labels_from_disk
update_image_info
update_diskdevices_loop
check_files
roll_rotating_usb_labels 0
