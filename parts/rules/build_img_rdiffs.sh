#!/bin/sh

set -eu

images="$(cat IMAGELIST)"

# a bit ugly, but I want to use _make_, and with "-j"
make_makefile() {
  # rdiff_specs returns:
  # $1 == rdiff, $2 == original image, $3 == target image
  all_rdiffs=$(rdiff_specs | awk '{ print $1 }'                     | xargs)
  all_images=$(rdiff_specs | awk '{ print $2; print $3 }' | sort -u | xargs)
  all_files=$( rdiff_specs | xargs -n1                    | sort -u | xargs)

  all_cksums=$(echo "$all_files" \
                 | xargs -n1 | awk '{ print $1 ".cksum" }' | xargs)

  cat <<EOF
vpath %.img ../

all: CKSUMS $all_rdiffs $all_cksums

CKSUMS::
	cat *.cksum > CKSUMS.\$\$\$\$ && mv CKSUMS.\$\$\$\$ CKSUMS

EOF

  # make .rdiff_signature rules (create signatures from source images)
  echo "$all_images" | xargs -n1 | awk '{
    printf "%s.rdiff_signature: %s\n", $1, $1
    print  "\trdiff signature $< $@"
    print  ""
  }'

  # make .rdiff rules (create rdiffs from source and target images)
  rdiff_specs | awk '{
    printf "%s: %s %s.rdiff_signature\n", $1, $3, $2
    printf "\trdiff delta %s.rdiff_signature $< $@\n", $2, $3
    print  ""
  }'

  echo "$all_files" | xargs -n1 | awk '{
    printf "%s.cksum: %s\n", $1, $1
    print  "\tcksum $^ > $@"
    print  "\t@echo refreshing CKSUMS"
    print  "\t@${MAKE} -s CKSUMS"
    print  ""
  }'
}

number_pairs() {
  image_count=$(echo "$images" | wc -l)

  for i in $(seq $image_count); do
    for j in $(seq $(expr $i + 1) $image_count); do
      echo $i $j
    done
  done
}

rdiff_specs() {
  number_pairs \
    | while read i j; do
        echo "$images" | to_rdiff_orig_target $i $j
      done
}

to_rdiff_orig_target() {
  # Returns the rdiff filename, the original image filename and the target
  # image filename, all these in each line.
  i=$1
  j=$2

  awk -v i=$i -v j=$j '
    NR == i { orig   = $0 }
    NR == j { target = $0 }
    END {
      regex = "^(.*?)-([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6})-(.*?).img$"

      if (match(orig, regex, orig_match) \
        && match(target, regex, target_match)) {
          rdiff_name = sprintf("%s-%s--%s-%s.rdiff",
                               orig_match[1],
                               orig_match[2],
                               target_match[2],
                               orig_match[3])
          print rdiff_name, orig, target
      }
    }
  '
}

make_makefile | tee Makefile | nice -n 20 make -f - -j "$(nproc)"
