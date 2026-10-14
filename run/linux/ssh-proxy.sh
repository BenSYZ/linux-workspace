#!/bin/bash -e
main(){
    this_dir="$(dirname "$(realpath "$0")")"
    ssh_sock="$this_dir"/../.ssh.sock
    exec nc -U "$ssh_sock"
    return 0
}
main "$@"

