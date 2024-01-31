SOURCE_DIR=$1
VERSION=$2
for LEGAL_DIR in `find $SOURCE_DIR/src -name legal`; do
  for COMMON_LICENSE in "### Apache 2.0 License" "### GPL v2" ; do
    for FILE in `grep -Rl "${COMMON_LICENSE}" $LEGAL_DIR`; do
      sed -i "/^${COMMON_LICENSE}/,/^###/{/^###/!{d}}" $FILE
      sed -i "s/${COMMON_LICENSE}/${COMMON_LICENSE}: Refer to the copy under \/usr\/share\/common-licenses\n/g" $FILE
    done
  done
  # special cases
  # JDK-21
  if [ $VERSION = "21" ] || [ $VERSION = "17" ] || [ $VERSION = "11" ]; then
    FILE=$SOURCE_DIR/src/jdk.internal.le/share/legal/jline.md
    sed -i "/^Apache License/,/^=====/{/^Apache License/!{/^=====/!{d}}}" $FILE
    sed -i "s/^Apache License/Apache 2.0 License: Refer to the copy under \/usr\/share\/common-licenses\n\n/g" $FILE
  fi
done


