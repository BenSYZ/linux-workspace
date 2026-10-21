#!/bin/bash
main(){
    local line_num="${1:-200}"
    local digits
    digits="${#line_num}"
    for line in $(seq 0 "$line_num");do
        printf "Line %0*d: " "$digits" "$line"
        for c in {a..z} " " {A..Z} " " {0..9};do
            printf "%c" "$c"
        done
        printf "\n"
    done
    printf "EOF\n"
    return 0
}
main "$@"

