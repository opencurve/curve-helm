#!/usr/bin/env bash

# usage: replace_config.sh /path/to/source /path/to/destination

############################  GLOBAL VARIABLES
g_color_yellow=`printf '\033[33m'`
g_color_red=`printf '\033[31m'`
g_color_normal=`printf '\033[0m'`
g_role="${CURVEFS_COMPONENT_ROLE}"
g_prefix="${CURVEFS_COMPONENT_PREFIX}"
g_config_src=""
g_config_dst=""
declare -A g_variables
declare -A g_config
{{- range $_, $role := tuple "etcd" "mds" "metaserver" }}
declare -A g_{{ $role }}_config
{{- $config := $.Values.metaserver.config }}
{{- if eq $role "etcd" }}
{{- $config = $.Values.etcd.config }}
{{- else if eq $role "mds" }}
{{- $config = $.Values.mds.config }}
{{- end }}
{{- range $k, $v := $config }}
g_{{ $role }}_config[{{ $k | quote }}]={{ $v | quote }}
{{- end }}
{{- end }}

############################  BASIC FUNCTIONS
function msg() {
    printf '%b' "$1" >&2
}

function success() {
    msg "$g_color_yellow[✔]$g_color_normal ${1}${2}"
}

function die() {
    msg "$g_color_red[✘]$g_color_normal ${1}${2}"
    exit 1
}

############################  FUNCTIONS
function get_options() {
    g_config_src=$1
    g_config_dst=$2
}

# delimiter=get_delimiter(role)
function get_delimiter() {
    local role=$1
    local delimiter="="
    if [[ $role == "etcd" ]]; then
        delimiter=": "
    fi
    printf "%s" "$delimiter"
}

function init_common_variables() {
    g_variables["prefix"]=$g_prefix
    g_variables["cluster_etcd_addr"]={{  include "helm-toolkit.curvefs.clusterEtcdAddr" . | quote }}
    g_variables["cluster_etcd_http_addr"]={{ include "helm-toolkit.curvefs.clusterEtcdHttpAddr" . | quote }}
    g_variables["cluster_mds_addr"]={{  include "helm-toolkit.curvefs.clusterMdsAddr" . | quote }}
}

function init_etcd_variables() {
    g_variables["service_sequence"]="${HOSTNAME##*-}"
    g_variables["service_addr"]="${POD_IP}"
    g_variables["service_port"]={{ .Values.etcd.port | quote }}
    g_variables["service_client_port"]={{ .Values.etcd.clientPort | quote }}
}

function init_mds_variables() {
    g_variables["service_addr"]="${POD_IP}"
    g_variables["service_port"]={{ .Values.mds.port | quote }}
    g_variables["service_dummy_port"]={{ .Values.mds.dummyPort | quote }}
}

function init_metaserver_variables() {
    g_variables["service_addr"]="${POD_IP}"
    g_variables["service_port"]={{ .Values.metaserver.port | quote }}
    g_variables["service_external_addr"]="${POD_IP}"
}

# init_variables(role)
function init_variables() {
    local role=$1
    init_common_variables
    case $role in
        etcd) init_etcd_variables ;;
        mds) init_mds_variables ;;
        metaserver) init_metaserver_variables ;;
        *) ;;
    esac
}

# init_config(role)
function init_config() {
    local role=$1
    if [ $role == "etcd" ]; then
        for key in $(echo ${!g_etcd_config[*]}); do
            g_config[$key]=${g_etcd_config[$key]}
        done
    elif [ $role == "mds" ]; then
        for key in $(echo ${!g_mds_config[*]}); do
            g_config[$key]=${g_mds_config[$key]}
        done
    elif [ $role == "metaserver" ]; then
        for key in $(echo ${!g_metaserver_config[*]}); do
            g_config[$key]=${g_metaserver_config[$key]}
        done
    fi
}

# replace_config_item(delimiter, /path/to/source, /path/to/destination)
function replace_config_item() {
    local delimiter="$1"
    local src="$2"
    local dst="$3"

    local pattern="^([^${delimiter}]+)${delimiter}[[:space:]]*(.*)$"
    while IFS= read -r line; do
        if [[ ! $line =~ $pattern ]]; then
            echo $line
            continue
        fi

        local key=${BASH_REMATCH[1]}
        local value=${g_config[$key]}
        if [[ ! $value ]]; then
            echo $line
        else
            echo ${key}${delimiter}${value}
        fi
    done < $src > $dst
}

# line=replace_line(line)
function replace_line_variable() {
    local line=$1
    local pattern='\$\{([^{}$]+)\}'

    # comment
    if [[ $line == \#* ]]; then
        echo $line
        return
    fi

    while [[ $line =~ $pattern ]];
    do
        local key=${BASH_REMATCH[1]}
        local value=${g_variables[$key]}
        if [[ ! $value ]]; then
            die "varaible '$key' not found\n"
        fi

        line="${line/${BASH_REMATCH[0]}/$value}"
    done
    echo $line
}

# replace_config_variable(/path/to/source, /path/to/destination)
function replace_config_variable() {
    local src=$1
    local dst=$2
    while IFS= read -r line; do
        line=`replace_line_variable "$line"`
        if [ $? -ne 0 ]; then
            exit 1
        fi
        echo $line
    done < $src > $dst
}

function main() {
    get_options "$@"

    init_config $g_role
    init_variables $g_role
    local delimiter=`get_delimiter $g_role`
    local tempfile=${g_config_dst}.tmp
    replace_config_item "$delimiter" $g_config_src ${tempfile}
    replace_config_variable ${tempfile} $g_config_dst
    ret=$?
    rm -f $tempfile
    exit $ret
}

############################  MAIN()
main "$@"