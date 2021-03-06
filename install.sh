#!/bin/bash
if [ -z "${BASH_SOURCE}" ];then
    this=${PWD}
else
    rpath="$(readlink ${BASH_SOURCE})"
    if [ -z "$rpath" ];then
        rpath=${BASH_SOURCE}
    fi
    this="$(cd $(dirname $rpath) && pwd)"
fi

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

user="${SUDO_USER:-$(whoami)}"
home="$(eval echo ~$user)"

# export TERM=xterm-256color

# Use colors, but only if connected to a terminal, and that terminal
# supports them.
if which tput >/dev/null 2>&1; then
  ncolors=$(tput colors 2>/dev/null)
fi
if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
            CYAN="$(tput setaf 5)"
    BOLD="$(tput bold)"
    NORMAL="$(tput sgr0)"
else
    RED=""
    GREEN=""
    YELLOW=""
            CYAN=""
    BLUE=""
    BOLD=""
    NORMAL=""
fi

_err(){
    echo "$*" >&2
}

_runAsRoot(){
    cmd="${*}"
    local rootID=0
    if [ "${EUID}" -ne "${rootID}" ];then
        echo -n "Not root, try to run '${cmd}' as root.."
        # or sudo sh -c ${cmd} ?
        if eval "sudo ${cmd}";then
            echo "ok"
            return 0
        else
            echo "failed"
            return 1
        fi
    else
        # or sh -c ${cmd} ?
        eval "${cmd}"
    fi
}

rootID=0
function _root(){
    if [ ${EUID} -ne ${rootID} ];then
        echo "Need run as root!"
        echo "Requires root privileges."
        exit 1
    fi
}

ed=vi
if command -v vim >/dev/null 2>&1;then
    ed=vim
fi
if command -v nvim >/dev/null 2>&1;then
    ed=nvim
fi
if [ -n "${editor}" ];then
    ed=${editor}
fi
###############################################################################
# write your code below (just define function[s])
# function is hidden when begin with '_'
###############################################################################
install(){
    local dest=${1:?'missing instal location'}
    # 下面使用tar解压是指定了-C(此时的PWD是/tmp)，因此在这里就需要
    # 把dest转换成绝对路径
    dest="$(realpath $dest)"
    echo "Install location: ${dest}"
    if [ ! -d $dest ];then
        mkdir -p ${dest}
    fi
    version=${2:-1.2}
    linuxAMDLink="https://source711.oss-cn-shanghai.aliyuncs.com/fastest-port/${version}/fastest-port-linux-amd64.tar.bz2"
    linuxARMLink="https://source711.oss-cn-shanghai.aliyuncs.com/fastest-port/${version}/fastest-port-linux-arm64.tar.bz2"

    case $(uname) in
        Linux)
            case $(uname -m) in
                #树莓派4
                aarch64)
                    link="$linuxARMLink"
                ;;
                x86_64)
                    link="$linuxAMDLink"
                ;;
            esac
        ;;
        *)
            echo "Only support Linux currently"
            exit 1
        ;;
    esac
    tarFile="${link##*/}"
    cd /tmp
    if [ ! -e "${tarFile}" ];then
        curl -LO "${link}"
    else
        echo "Use /tmp/${tarFile} cache file"
    fi
    tar -C $dest -jxvf ${tarFile}

    (cd ${dest} && mv ${tarFile%.tar.bz2} fastest-port)

}

em(){
    $ed $0
}

###############################################################################
# write your code above
###############################################################################
function _help(){
    cd "${this}"
    cat<<EOF2
Usage: $(basename $0) ${bold}CMD${reset}

${bold}CMD${reset}:
EOF2
    # perl -lne 'print "\t$1" if /^\s*(\w+)\(\)\{$/' $(basename ${BASH_SOURCE})
    # perl -lne 'print "\t$2" if /^\s*(function)?\s*(\w+)\(\)\{$/' $(basename ${BASH_SOURCE}) | grep -v '^\t_'
    perl -lne 'print "\t$2" if /^\s*(function)?\s*(\w+)\(\)\{$/' $(basename ${BASH_SOURCE}) | perl -lne "print if /^\t[^_]/"
}

case "$1" in
     ""|-h|--help|help)
        _help
        ;;
    *)
        "$@"
esac
