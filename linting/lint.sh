#!/bin/zsh
set -e

fix_files=false
lint_paths=()

die() {
    echo "Error: $1" >&2
    exit 1
}

info() {
    # Prints text in bold
    printf '\e[1m*** %s\e[0m\n' "$*"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --*=*)
            # converts "--opt=val" to "--opt" "val"
            arg=$1
            shift
            set -- "${arg%%=*}" "${arg#*=}" "$@"
            ;;
        -f|--fix)
            fix_files=true
            shift
            ;;
        -*)
            die "unknown option: $1"
            ;;
        *)
            lint_paths+=("$1")
            shift
            ;;
    esac
done

# convert lint_paths from array to string
if [ "${#lint_paths[@]}" -eq 0 ]; then
    lint_paths+=("scraper/")
    echo "$lint_paths"
fi

# Auto-format python files
info "Running isort..."
if [ "$fix_files" = true ]; then
    isort --settings-path=.toml "${lint_paths[@]}"
else
    isort --settings-path=.toml -c "${lint_paths[@]}"
fi
isort_status="$?"
info "Running black..."
if [ "$fix_files" = true ]; then
    black --config=.toml "${lint_paths[@]}" --preview
else
    black --check --config=.toml "${lint_paths[@]}" --preview
fi
black_status="$?"
info "Running flake8..."
flake8 --config=.flake8 "${lint_paths[@]}"
flake8_status="$?"

if [ "$isort_status" -eq 0 ] && [ "$black_status" -eq 0 ] && [ "$flake8_status" -eq 0 ]; then
    echo -e "\e[36m"

    echo -e "\t###############################"
    echo -e "\t#                             #"
    echo -e "\t#   \e[94mAll Python Code Passed!\e[36m   #"
    echo -e "\t#                             #"
    echo -e "\t###############################"

    echo -e "\e[0m"

fi
