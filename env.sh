case $# in
  0)
    echo "PUAVO_ROOTFS was not defined"
    echo "PUAVO_IMAGES was not defined"
    ;;
  1)
    export PUAVO_ROOTFS=$(realpath "$1")
    echo "PUAVO_ROOTFS="$PUAVO_ROOTFS""
    echo "PUAVO_IMAGES was not defined"
    ;;
  2)
    export PUAVO_ROOTFS=$(realpath "$1")
    export PUAVO_IMAGES=$(realpath "$2")
    echo "PUAVO_ROOTFS="$PUAVO_ROOTFS""
    echo "PUAVO_IMAGES="$PUAVO_IMAGES""
    ;;
  *)
    echo "Usage: source $0 [<staging area>]" >&2
    ;;
esac
