#!/usr/bin/env bash
# Notes #######################################################################

# Extensive descriptions are included for easy reference.
#
# Explicitness and clarity are generally preferable, especially since bash can
# be difficult to read. This leads to noisier, longer code, but should be
# easier to maintain. As a result, some general design preferences:
#
# - Use leading underscores on internal variable and function names in order
#   to avoid name collisions. For unintentionally global variables defined
#   without `local`, such as those defined outside of a function or
#   automatically through a `for` loop, prefix with double underscores.
# - Always use braces when referencing variables, preferring `${NAME}` instead
#   of `$NAME`. Braces are only required for variable references in some cases,
#   but the cognitive overhead involved in keeping track of which cases require
#   braces can be reduced by simply always using them.
# - Prefer `printf` over `echo`. For more information, see:
#   http://unix.stackexchange.com/a/65819
# - Prefer `$_explicit_variable_name` over names like `$var`.
# - Use the `#!/usr/bin/env bash` shebang in order to run the preferred
#   Bash version rather than hard-coding a `bash` executable path.
# - Prefer splitting statements across multiple lines rather than writing
#   one-liners.
# - Group related code into sections with large, easily scannable headers.
# - Describe behavior in comments as much as possible, assuming the reader is
#   a programmer familiar with the shell, but not necessarily experienced
#   writing shell scripts.

###############################################################################
# Strict Mode
###############################################################################

# Treat unset variables and parameters other than the special parameters ‘@’ or
# ‘*’ as an error when performing parameter expansion. An 'unbound variable'
# error message will be written to the standard error, and a non-interactive
# shell will exit.
#
# This requires using parameter expansion to test for unset variables.
#
# http://www.gnu.org/software/bash/manual/bashref.html#Shell-Parameter-Expansion
#
# The two approaches that are probably the most appropriate are:
#
# ${parameter:-word}
#   If parameter is unset or null, the expansion of word is substituted.
#   Otherwise, the value of parameter is substituted. In other words, "word"
#   acts as a default value when the value of "$parameter" is blank. If "word"
#   is not present, then the default is blank (essentially an empty string).
#
# ${parameter:?word}
#   If parameter is null or unset, the expansion of word (or a message to that
#   effect if word is not present) is written to the standard error and the
#   shell, if it is not interactive, exits. Otherwise, the value of parameter
#   is substituted.
#
# Examples
# ========
#
# Arrays:
#
#   ${some_array[@]:-}              # blank default value
#   ${some_array[*]:-}              # blank default value
#   ${some_array[0]:-}              # blank default value
#   ${some_array[0]:-default_value} # default value: the string 'default_value'
#
# Positional variables:
#
#   ${1:-alternative} # default value: the string 'alternative'
#   ${2:-}            # blank default value
#
# With an error message:
#
#   ${1:?'error message'}  # exit with 'error message' if variable is unbound
#
# Short form: set -u
set -o nounset

# Exit immediately if a pipeline returns non-zero.
#
# NOTE: This can cause unexpected behavior. When using `read -rd ''` with a
# heredoc, the exit status is non-zero, even though there isn't an error, and
# this setting then causes the script to exit. `read -rd ''` is synonymous with
# `read -d $'\0'`, which means `read` until it finds a `NUL` byte, but it
# reaches the end of the heredoc without finding one and exits with status `1`.
#
# Two ways to `read` with heredocs and `set -e`:
#
# 1. set +e / set -e again:
#
#     set +e
#     read -rd '' variable <<HEREDOC
#     HEREDOC
#     set -e
#
# 2. Use `<<HEREDOC || true:`
#
#     read -rd '' variable <<HEREDOC || true
#     HEREDOC
#
# More information:
#
# https://www.mail-archive.com/bug-bash@gnu.org/msg12170.html
#
# Short form: set -e
set -o errexit

# Allow the above trap be inherited by all functions in the script.
#
# Short form: set -E
set -o errtrace

# Return value of a pipeline is the value of the last (rightmost) command to
# exit with a non-zero status, or zero if all commands in the pipeline exit
# successfully.
set -o pipefail

# Set $IFS to only newline and tab.
#
# http://www.dwheeler.com/essays/filenames-in-shell.html
IFS=$'\n\t'

###############################################################################
# Environment
###############################################################################

# $_ME
#
# This program's basename.
_ME="$(basename "${0}")"

###############################################################################
# Debug
###############################################################################

# _debug()
#
# Usage:
#   _debug <command> <options>...
#
# Description:
#   Execute a command and print to standard error. The command is expected to
#   print a message and should typically be either `echo`, `printf`, or `cat`.
#
# Example:
#   _debug printf "Debug info. Variable: %s\\n" "$0"
__DEBUG_COUNTER=0
_debug() {
  if ((${_USE_DEBUG:-0}))
  then
    __DEBUG_COUNTER=$((__DEBUG_COUNTER+1))
    {
      # Prefix debug message with "bug (U+1F41B)"
      printf "🐛  %s " "${__DEBUG_COUNTER}"
      "${@}"
      printf "―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――\\n"
    } 1>&2
  fi
}

###############################################################################
# Error Messages
###############################################################################

# _exit_1()
#
# Usage:
#   _exit_1 <command>
#
# Description:
#   Exit with status 1 after executing the specified command with output
#   redirected to standard error. The command is expected to print a message
#   and should typically be either `echo`, `printf`, or `cat`.
_exit_1() {
  {
    printf "%s " "$(tput setaf 1)!$(tput sgr0)"
    "${@}"
  } 1>&2
  exit 1
}

# _warn()
#
# Usage:
#   _warn <command>
#
# Description:
#   Print the specified command with output redirected to standard error.
#   The command is expected to print a message and should typically be either
#   `echo`, `printf`, or `cat`.
_warn() {
  {
    printf "%s " "$(tput setaf 1)!$(tput sgr0)"
    "${@}"
  } 1>&2
}

###############################################################################
# Help
###############################################################################

# _print_help()
#
# Usage:
#   _print_help
#
# Description:
#   Print the program help information.
_print_help() {
  cat <<HEREDOC
     _                 _
 ___(_)_ __ ___  _ __ | | ___   _
/ __| | '_ \` _ \\| '_ \\| |/ _ \\_| |_
\\__ \\ | | | | | | |_) | |  __/_   _|
|___/_|_| |_| |_| .__/|_|\\___| |_|
                |_|
Boilerplate for creating a simple bash script with some basic strictness
checks and help features, and easy debug printing, and basic option handling.
Usage:
  ${_ME} [--options] [<arguments>]
  ${_ME} -h | --help
Options:
  -h --help  Display this help information.
HEREDOC
}

###############################################################################
# Options
#
# NOTE: The `getops` builtin command only parses short options and BSD `getopt`
# does not support long arguments (GNU `getopt` does), so the most portable
# and clear way to parse options is often to just use a `while` loop.
#
# For a pure bash `getopt` function, try pure-getopt:
#   https://github.com/agriffis/pure-getopt
#
# More info:
#   http://wiki.bash-hackers.org/scripting/posparams
#   http://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html
#   http://stackoverflow.com/a/14203146
#   http://stackoverflow.com/a/7948533
#   https://stackoverflow.com/a/12026302
#   https://stackoverflow.com/a/402410
###############################################################################

# Parse Options ###############################################################

# Initialize program option variables.
_PRINT_HELP=0
_USE_DEBUG=0

# Initialize additional expected option variables.
_OPTION_X=0
_SHORT_OPTION=
_LONG_OPTION=

# __get_option_value()
#
# Usage:
#   __get_option_value <option> <value>
#
# Description:
#  Given a flag (e.g., -e | --example) return the value or exit 1 if value
#  is blank or appears to be another option.
__get_option_value() {
  local __arg="${1:-}"
  local __val="${2:-}"

  if [[ -n "${__val:-}" ]] && [[ ! "${__val:-}" =~ ^- ]]
  then
    printf "%s\\n" "${__val}"
  else
    _exit_1 printf "%s requires a valid argument.\\n" "${__arg}"
  fi
}

while ((${#}))
do
  __arg="${1:-}"
  __val="${2:-}"

  case "${__arg}" in
    -h|--help)
      _PRINT_HELP=1
      ;;
    --debug)
      _USE_DEBUG=1
      ;;
    --endopts)
      # Terminate option parsing.
      break
      ;;
    -*)
      _exit_1 printf "Unexpected option: %s\\n" "${__arg}"
      ;;
  esac

  shift
done

###############################################################################
# Program Functions
###############################################################################

_simple() {
  _debug printf ">> Performing operation...\\n"

  if [ -f $HOME/.domainrc ]; then
    . $HOME/.domainrc
    _debug printf ">> Variables ◆◆◆◆\\n"
    _debug printf ">> INSTANCE_TOP_DOMAIN: $INSTANCE_TOP_DOMAIN\\n"
    _debug printf ">> INSTANCE_FULL_DOMAIN: $INSTANCE_FULL_DOMAIN\\n"
    _debug printf ">> CONOHA_USERNAME: $CONOHA_USERNAME\\n"
    _debug printf ">> CONOHA_PASSWORD: $CONOHA_PASSWORD\\n"
    _debug printf ">> CONOHA_TENANTID: $CONOHA_TENANTID\\n"
    _debug printf ">> STATIC_IP: $STATIC_IP\\n"
    _debug printf ">> ◆◆◆◆◆◆◆◆◆◆◆◆◆◆\\n"
  fi

  _debug printf ">> Fetch token.\\n"

  local _token=$(curl -s -X POST \
  -H "Accept: application/json" \
  -d "{\"auth\":{\"passwordCredentials\":{\"username\":\"$CONOHA_USERNAME\",\"password\":\"$CONOHA_PASSWORD\"},\"tenantId\":\"$CONOHA_TENANTID\"}}" \
  https://identity.tyo1.conoha.io/v2.0/tokens | \
  jq -r '.access.token.id')

  _debug printf ">> Token is \"$_token\" \\n"

  _debug printf ">> Fetch domain id.\\n"

  local _domain_id=$(curl -s https://dns-service.tyo1.conoha.io/v1/domains \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $_token" | \
  jq -r ".domains[] | select( .name == \"$INSTANCE_TOP_DOMAIN.\" ) | .id")

  _debug printf ">> Domain id is \"$_domain_id\" \\n"

  _debug printf ">> Fetch record id.\\n"

  local _record_id=$(curl -s https://dns-service.tyo1.conoha.io/v1/domains/$_domain_id/records \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $_token" | \
  jq -r ".records[] | select( .name == \"$INSTANCE_FULL_DOMAIN.\" ) | .id")

  _debug printf ">> Record_id id is \"$_record_id\".\\n"

  # Already be persited
  if [ -n "$_record_id" ]; then
    _debug printf ">> Delete record.\\n"

    curl -s https://dns-service.tyo1.conoha.io/v1/domains/$_domain_id/records/$_record_id \
    -X DELETE \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $_token" > /dev/null

    _debug printf ">> Deleted record.\\n"
  fi

  # 160.251.72.141 172.17.0.1 172.19.0.1 2400:8500:1302:1176:160:251:72:141
  local _addr=$(if [ -n "$STATIC_IP" ]; then echo $STATIC_IP; else hostname -I | cut -d' ' -f1; fi)
  _debug printf ">> Host address is \"$_addr\".\\n"

  if [ -z "$_addr" ]; then
    _exit_1 printf "Missed the IP address out!\\n"
  fi

  _debug printf ">> Persiste record.\\n"

  curl -s https://dns-service.tyo1.conoha.io/v1/domains/$_domain_id/records \
  -X POST \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $_token" \
  -d "{\"name\":\"$INSTANCE_FULL_DOMAIN.\",\"type\":\"A\",\"data\":\"$_addr\"}" > /dev/null

  _debug printf ">> Done performing operation.\\n"
}

###############################################################################
# Main
###############################################################################

# _main()
#
# Usage:
#   _main [<options>] [<arguments>]
#
# Description:
#   Entry point for the program, handling basic option parsing and dispatching.
_main() {
  if ((_PRINT_HELP))
  then
    _print_help
  else
    _simple "$@"
  fi
}

# Call `_main` after everything has been defined.
_main "$@"