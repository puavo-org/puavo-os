parse_multiline()
{
    local file field

    file=$1
    field=$2

    ## Print all lines of the multiline field.
    sed -r -n -e "
/^${field}:/{    ## This line has only the field name...
    :next_line
    n            ## ... append the next line to the pattern space.
    /^[ \t]*$/ q ## Stop if the line is empty.
    /^[^ \t]/ q  ## Stop if the line does not start with whitespace.
    s|^[ \t]+||p ## Remove preceding whitespace and print the line.
    b next_line  ## Continue to the next line.
}" "${file}"
}

parse_simple()
{
    local file field

    file=$1
    field=$2

    sed -r -n -e "
/^${field}:/{
    s/^${field}:[ \t]*(.+)[ \t]*$/\1/p  ## Strip leading and trailing whitespace.
    q                                   ## Stop after the first occurrence.
}" "${file}"
}
