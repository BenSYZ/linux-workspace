#!/bin/bash -e
get_remote_version(){
    cat test.json |jq '.releases[] | select(.moniker == "mainline").version' -r
    return
    curl -s -H "Accept: application/json" https://www.kernel.org/releases.json \
        |jq '.releases[] | select(.moniker == "mainline").version' -r
}

linux_git(){
    cd ./linux &> /dev/null
    git "$@"
    ret="$?"
    cd - &> /dev/null
    return "$ret"
}
get_local_version(){
    linux_git tag --contains master
}

get_patch_set(){
    local from="$1"
    local to="$2"
    local patch_file="$from""~""$to".patch
    echo "$patch_file"

    if [ -e "$patch_file" ];then
        return
    fi
    curl -s "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/rawdiff/?id=v$to&id2=v$from" \
        -o "$patch_file"
}
update_code(){
    local new_version="$1"
    local patch_file="$2"
    if linux_git tag --contains "$new_version";then
        return
    fi
    linux_git apply "$patch_file"
    linux_git add .
    linux_git commit -m "Linux $new_version"
    linux_git tag "$new_version"
}
check(){

    # index 0000000000000..b35d33fe40448
    # index 5ad082b4dd036..d19b725fd803b 100644
    # -c diff.dts.xfuncname=""
    sed 's/^\(index\) [^ ]* \?\(.*\)\?/\1 a..b \2/'

}

main(){
    remote_version="$(get_remote_version)"
    local_version="$(get_local_version)"
    if [[ "$remote_version" == "$local_version" ]];then
        return
    fi
    #echo "$remote_version" "$local_version"
    patch_file="$(get_patch_set "$local_version" "$remote_version")"
    update_code "$remote_version" "$(realpath "$patch_file")"
    return 0
}
main "$@"

