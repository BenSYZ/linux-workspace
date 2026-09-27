#!/bin/bash
main(){
    for line in {0..8};do
        printf "Line %s: " "$line"
        for c in {a..z} " " {A..Z} " " {0..9};do
            printf "%c" "$c"
        done
        printf "\n"
    done
    return 0
}
main "$@"

