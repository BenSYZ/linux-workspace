#!/bin/bash
init(){
    local latest_version
    latest_version="$(
        curl -s -H "Accept: application/json" https://www.kernel.org/releases.json \
            |jq '.releases[] | select(.moniker == "mainline").version' -r
        )"
    git clone --depth 1 --branch "$latest_version" https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
}

get_new_versions(){
    local local_version
    # -: reverse sort
    local_version="$(git tag --list --sort=-v:refname |head -n 1)"
    git ls-remote --tags --sort=-v:refname origin | \
        awk -F'/' -v local_version="$local_version" \
            '{
                if ($3 ~ /[^}]$/) {
                    if ($3 == local_version){
                        exit
                    }
                    print $3
                }
            }' | tac
}

update(){
    cd ./linux || exit
    for v in $(get_new_versions | tail -n 1);do
        echo "$v"
        git fetch --depth=1 origin "$v"
        git fetch --depth 1 origin "refs/tags/$v":"refs/tags/$v"
    done
    if ! [ -z "$v" ];then
        git stash
        git reset --hard "$v"
    fi
}

main(){
    if ! [ -e linux ];then
        init
    fi
    update
    return 0
}
main "$@"

