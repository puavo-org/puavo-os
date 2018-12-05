#!/usr/bin/wish

package require json
package require json::write

wm attributes . -fullscreen 1
# wm minsize  . 800 600
# wm maxsize  . 1440 900
wm protocol . WM_DELETE_WINDOW { }      ;# do not allow window close

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

set ui_messages {}
array set usb_labels ""
set writable_labels false

set puavo_usb_factory_workpath "$::env(HOME)/.puavo/usb-factory"

set pci_path_dir /dev/disk/by-path

set diskdevices [dict create]
set usbhubs     [dict create]
set new_usbhubs [dict create]

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
  global bg_image bg_image_path

  set size_diff [ expr {
    max(abs([dict get $bg_image width]  - [dict get $bg_image new_width]),
        abs([dict get $bg_image height] - [dict get $bg_image new_height]))
  }]

  if {$size_diff >= 4} {
    # XXX it would be better to use standard output
    set new_width  [dict get $bg_image new_width]
    set new_height [dict get $bg_image new_height]

    update_image bg_photo $bg_image_path $new_width $new_height

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
  global puavo_usb_factory_workpath

  if {[catch { glob ${puavo_usb_factory_workpath}/* } res]} {
    error "${puavo_usb_factory_workpath}/* did not match any files: $res"
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

  set ui [dict get $diskdevices $devpath ui]

  if {$countdown == 0} {
    set_devstate $devpath writing
    return
  }

  $ui.info.status configure \
    -text "[ui_msg messages start_writing] $countdown"

  incr countdown -1
  after 1000 [list start_preparation $devpath $countdown]
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
  set cmd "pv -b -n $srcfile | cmp -n $image_size ${pci_path_dir}/${devpath} - 2>@1"
  start_operating $devpath $cmd
}

proc start_writing {devpath} {
  global image_info pci_path_dir
  set srcfile [dict get $image_info latest_image_path]
  set cmd "pv -b -n $srcfile | dd of=${pci_path_dir}/${devpath} conv=fsync,nocreat status=none 2>@1"
  start_operating $devpath $cmd
}

proc set_device_eta {devpath bytes_written} {
  global diskdevices image_info

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
      if {[dict get $diskdevices $devpath state] eq "verifying"} {
        set_devstate $devpath start_writing
      } else {
        set_devstate $devpath error
      }
    } else {
      switch -- [dict get $diskdevices $devpath state] {
        writing   { set_devstate $devpath verifying }
        verifying { set_devstate $devpath finished  }
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

proc update_disklabel {devpath {label "LOOKUP"}} {
  global diskdevices

  if {![dict exists $diskdevices $devpath]} {
    return
  }

  set ui [dict get $diskdevices $devpath ui]

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

  $ui.info.disklabel configure -text $device_label
}

proc set_ui_status_to_nomedia {devpath} {
  global diskdevices

  if {![dict exists $diskdevices $devpath]} {
    return
  }

  set ui [dict get $diskdevices $devpath ui]
  if {[dict get $diskdevices $devpath state] eq "nomedia"} {
    $ui.info.status  configure -text  ""
    $ui.pb_frame.bar configure -value 0
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

  set ui [dict get $diskdevices $devpath ui]

  switch -- $state {
    error {
      close_if_open $devpath
      dict set diskdevices $devpath state error

      $ui.info.status  configure -text [ui_msg messages error]
      $ui.pb_frame.bar configure -value 0
    }

    finished {
      close_if_open $devpath
      dict set diskdevices $devpath state finished

      set version [dict get $diskdevices $devpath version]
      $ui.info.status configure -text "[ui_msg messages finished] $version"
      $ui.pb_frame.bar configure -value 100
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
      $ui.info.status configure -text [ui_msg messages nospaceondevice]
      $ui.pb_frame.bar configure -value 0
    }

    progress {
      lassign $args eta percentage
      switch -- [dict get $diskdevices $devpath state] {
        verifying {
          $ui.info.status  configure -text  "[ui_msg messages verifying] $eta"
          $ui.pb_frame.bar configure -value $percentage
        }
        writing {
          $ui.info.status  configure -text  "[ui_msg messages writing] $eta"
          $ui.pb_frame.bar configure -value $percentage
        }
      }
    }

    start_writing {
      dict set diskdevices $devpath state start_writing
      update_disklabel $devpath
      start_preparation $devpath 10
    }

    verifying {
      if {[quick_verify_check $devpath]} {
        update_disklabel $devpath
        set fh [start_verifying $devpath]
        dict set diskdevices $devpath fh $fh
        if {$fh ne ""} {
          dict set diskdevices $devpath state verifying

          $ui.info.status  configure -text  -
          $ui.pb_frame.bar configure -value 0
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

        $ui.info.status  configure -text  -
        $ui.pb_frame.bar configure -value 0
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

proc make_usbport_label {port_id port_ui {update false}} {
  global usb_labels writable_labels

  set label_ui $port_ui.info.port_label
  set labelvar "port/${port_id}"
  set usb_labels($labelvar) [get_label $labelvar $port_id]

  if {$update} { destroy $label_ui }

  if {$writable_labels} {
    ttk::entry $label_ui -textvariable usb_labels($labelvar) \
                                       -font infoFont -width 10
  } else {
    ttk::label $label_ui -textvariable usb_labels($labelvar) \
                                       -font infoFont -width 10
  }

  if {$update} {
    pack_usbport_ui_elements $port_ui
  }
}

proc make_usbport_ui_elements {devpath port_id port_ui} {
  ttk::frame ${port_ui} -borderwidth 1
  ttk::frame ${port_ui}.info
  ttk::frame ${port_ui}.pb_frame -height 8

  make_usbport_label $port_id $port_ui

  ttk::label ${port_ui}.info.disklabel -text "" -font infoFont
  ttk::label ${port_ui}.info.status -width 20 -font infoFont
  ttk::progressbar ${port_ui}.pb_frame.bar -orient horizontal \
                   -maximum 100 -value 0

  pack_usbport_ui_elements $port_ui
}

proc pack_usbport_ui_elements {port_ui} {
  pack forget ${port_ui}.info.port_label \
              ${port_ui}.info.status     \
              ${port_ui}.info.disklabel  \
              ${port_ui}.info            \
              ${port_ui}.pb_frame

  pack ${port_ui}.info.port_label \
       ${port_ui}.info.status     \
       ${port_ui}.info.disklabel  \
       -side left -padx 16
  pack ${port_ui}.info ${port_ui}.pb_frame -expand 1 -fill x
  place ${port_ui}.pb_frame.bar -in ${port_ui}.pb_frame \
        -relwidth 1.0 -relheight 1.0
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
        destroy [dict get $usbhubs $hub_id $product ui]
        dict unset usbhubs $hub_id $product
        set regrid true
      }
    }
  }
  dict for {hub_id hubproducts} $usbhubs {
    if {[llength [dict keys $hubproducts]] == 0} {
      dict unset usbhubs $hub_id
    }
  }

  set ui_elements [list]

  # add hubs that are missing
  dict for {hub_id hubproducts} $new_usbhubs {
    set sorted_products [dictionary_sort_by_label "hub/${hub_id}" \
                                                  [dict keys $hubproducts]]

    foreach product $sorted_products {
      if {[dict exists $usbhubs $hub_id $product]} {
        set hub_ui [dict get $usbhubs $hub_id $product ui]
        if {!$force_ui_update} {
          lappend ui_elements [dict get $usbhubs $hub_id $product ui]
          dict set usbhubs $hub_id $product ui $hub_ui
          continue
        }
        destroy $hub_ui
      }

      # add UI for hub
      set uisym_hub_id  [string map {. _      } $hub_id]
      set uisym_product [string map {. _ " " _} $product]
      set hub_ui ".f.disks.hub_${uisym_hub_id}_${uisym_product}"

      set labelvar "hub/${hub_id}/${product}"
      set usb_labels($labelvar) [get_label $labelvar $product]
      if {$writable_labels} {
        ttk::entry $hub_ui -textvariable usb_labels($labelvar) -width 50
      } else {
        ttk::label $hub_ui -textvariable usb_labels($labelvar)
      }

      lappend ui_elements $hub_ui
      set regrid true

      dict set usbhubs $hub_id $product ui $hub_ui
    }

    # add new hub ports to UI
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
            make_usbport_label $port_id $port_ui true
          }
        } else {
          make_usbport_ui_elements $devpath $port_id $port_ui
          dict set diskdevices $devpath [
            dict create fh            ""       \
                        image_size    ""       \
                        progress_list [list]   \
                        state         nomedia  \
                        ui            $port_ui \
                        version       ""       ]
          set regrid true
        }

        lappend ui_elements $port_ui
        dict set usbhubs $hub_id $product ports $port_id $devpath
      }
    }
  }

  if {[llength [dict keys $usbhubs]] == 0} {
    grid .f.disks.nohubs_message
  } else {
    grid forget .f.disks.nohubs_message
    if {$regrid} {
      foreach ui $ui_elements {
        grid forget $ui
        grid $ui -sticky w
      }
    }
  }
}

proc read_usb_labels_from_disk {} {
  global puavo_usb_factory_workpath usb_labels
  set usblabels_json_path "${puavo_usb_factory_workpath}/usb_labels.json"

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
  global puavo_usb_factory_workpath usb_labels
  set usblabels_json_path "${puavo_usb_factory_workpath}/usb_labels.json"
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

ttk::frame .f.instructions

# XXX hardcoded sizes!
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
                                   -text [ui_msg "waiting usb hubs"]

pack .f.version_status -side bottom -pady 12
pack .f.version_status.version      \
     .f.version_status.download     \
     .f.version_status.hostname -side left -padx 50
pack .f.version_status.version.label .f.version_status.version.number \
     -side left -padx 5
pack .f.version_status.download.label .f.version_status.download.status \
     -side left -padx 5
pack .f.version_status.hostname.label .f.version_status.hostname.value \
     -side left -padx 5

pack .f.instructions -side left -anchor n
pack .f.instructions.title       \
     .f.instructions.description \
     .f.instructions.steps

pack .f.disks -side right
grid .f.disks.nohubs_message

pack .f .f.bg -fill both -expand 1

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

read_usb_labels_from_disk
update_image_info
update_diskdevices_loop
check_files
