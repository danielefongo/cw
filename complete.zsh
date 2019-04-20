cw=`declare -f | grep -e '^__cw_' | cut -f1 -d' ' | rev | cut -f1 -d'_' | rev`

function _dothis_completions {
    local line

    _arguments -C \
        "1: :($cw)" \
        "*::arg:->args"

    case $line[1] in
        attach)
            _dothis_completions_list
        ;;
        delete)
            _dothis_completions_list
        ;;
    esac
}

function _dothis_completions_list {
  elements=`__cw_list`
  _arguments \
    "1: :($elements)"
}

compdef _dothis_completions cw
