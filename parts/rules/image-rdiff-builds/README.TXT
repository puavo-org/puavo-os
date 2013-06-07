Here is some helper code to build binary patches of ltsp images.  Patches
are built with rdiff, which can also be used to patch images.  Thus, you
need rdiff to use this, plus some basic tools of course.

How to use this?  If you have your images at /opt/ltsp/images,
create a subdirectory /opt/ltsp/images/rdiffs or some such under it.
Copy (or link, or symlink) Makefile and build_image_rdiffs there.
You must also create a list of ltsp images that you want the diffs
to be generated from.

The rdiff files will be built for every image pair going forward
direction only.  Thus you can use patches to ugprade, but not downgrade.
This is not difficult to change, but that would take double effort to build
and then diffs take twice as much disk space.

Create a file containing a list of images to build.  Makefile expects
to find IMAGELIST.precise and IMAGELIST.quantal in this directory.
Just list files there like this:

  ltsp-quantal-master-2013-05-15-130954-i386.img
  ltsp-quantal-master-2013-06-03-164748-i386.img
  ltsp-quantal-master-2013-06-07-145245-i386.img

Then run "make".
