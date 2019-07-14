#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# "unofficial" bash strict mode
# See: http://redsymbol.net/articles/unofficial-bash-strict-mode
set -o errexit  # Exit when simple command fails               'set -e'
set -o errtrace # Exit on error inside any functions or subshells.
set -o nounset  # Trigger error when expanding unset variables 'set -u'
set -o pipefail # Do not hide errors within pipes              'set -o pipefail'
IFS=$'\n\t'

script_name="${0##*/}"
#
# Fetch the AWS access_key and/or secret from an AWS profile
# stored in the ~/.aws/credentials file ini format
#
# Aaron Roydhouse <aaron@roydhouse.com>, 2017
# https://github.com/whereisaaron/get-aws-profile-bash/

#
# cfg_parser - Parse and ini files into variables
# By Andres J. Diaz
# http://theoldschooldevops.com/2008/02/09/bash-ini-parser/
# Use pastebin link only and WordPress corrupts it
# http://pastebin.com/f61ef4979 (original)
# http://pastebin.com/m4fe6bdaf (supports spaces in values)
#
# shellcheck disable=SC2206,SC2116
cfg_parser ()
{
  mapfile ini < "${1:?Missing INI filename}" # convert to line-array
  ini=(${ini[*]//;*/})        # remove comments ;
  ini=(${ini[*]//\#*/})       # remove comments #
  ini=(${ini[*]/\	=/=})    # remove tabs before =
  ini=(${ini[*]/=\	/=})     # remove tabs be =
  ini=(${ini[*]/\ *=\ /=})     # remove anything with a space around  =
  ini=(${ini[*]/#[/\}$'\n'cfg.section.})   # set section prefix
  ini=(${ini[*]/%]/ \(})      # convert text2function (1)
  ini=(${ini[*]/=/=\( })      # convert item to array
  ini=(${ini[*]/%/ \)})       # close array parenthesis
  ini=(${ini[*]/%\\ \)/ \\})   # the multiline trick
  ini=(${ini[*]/%\( \)/\(\) \{})   # convert text2function (2)
  ini=(${ini[*]/%\} \)/\}})   # remove extra parenthesis
  ini[0]="" # remove first element
  ini[${#ini[*]} + 1]='}'    # add the last brace
  eval "$(echo "${ini[*]}")" # eval the result
}

# echo a message to standard error (used for messages not intended
# to be parsed by scripts, such as usage messages, warnings or errors)
echo_stderr ()
{
  printf '%s\n' "$@" >&2
}

#
# Set defaults
# See https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html
#
declare AWS_PROFILE CREDENTIALS
declare aws_access_key_id aws_secret_access_key aws_session_token
declare -i show_key show_secret show_session_token

CREDENTIALS="${AWS_SHARED_CREDENTIALS_FILE:-"$HOME/.aws/credentials"}"
AWS_PROFILE=${AWS_PROFILE:-${AWS_DEFAULT_PROFILE:-default}}
show_key=0
show_secret=0
show_session_token=0

#
# Parse options
#

display_usage ()
{
  echo_stderr "Usage: $script_name [--credentials=<path>] [--profile=<name>] [--key|--secret|--session-token]


Options:
  -p, --profile             use profile
  -f, --credentials         read credentials from specified file
  -k, --key                 get value of aws_access_key_id
  -s, --secret              get value of aws_secret_access_key
  -t, --session-token       get value of aws_session_token
  -h, --help                display this help text

Default --credentials is '\$AWS_SHARED_CREDENTIALS_FILE' or '~/.aws/credentials'
Default --profile is '\$AWS_DEFAULT_PROFILE' or 'default'

To generate environment variables for profile myprofile:

  \$ source \$($script_name --profile=myprofile)

You can specify one of --key, --secret or --session-token to
get just that value, with no line break:

  \$ FOO_KEY=\$($script_name --profile myprofile --key)
  \$ FOO_SECRET=\$($script_name -p myprofile -s)
  \$ FOO_SESSION_TOKEN=\$($script_name -t --profile=myprofile)"
}

for i in "$@"
do
case $i in
  --credentials=*)
    CREDENTIALS="${i#*=}"
    shift # past argument=value
    ;;
  -f | --credentials)
    CREDENTIALS="${2}"
    shift 2 # past argument value
    ;;
  --profile=*)
    AWS_PROFILE="${i#*=}"
    shift # past argument=value
    ;;
  -p | --profile)
    AWS_PROFILE="${2}"
    shift 2 # past argument value
    ;;
  -k | --key)
    show_key=1
    shift # past argument with no value
    ;;
  -s | --secret)
    show_secret=1
    shift # past argument with no value
    ;;
  -t | --session-token)
    show_session_token=1
    shift # past argument with no value
    ;;
  -h | --help)
    display_usage
    exit 64
    ;;
  *)
    # unknown option
    echo_stderr "Unknown option $i"
    display_usage
    exit 64
    ;;
esac
done

#
# Check options
#

if [[ $((show_key + show_secret + show_session_token)) -gt 1 ]]; then
  echo_stderr "Can only specify one of --key,--secret or --session-token"
  display_usage
  exit 64
fi

#
# Parse and display
#

if [[ ! -r "${CREDENTIALS}" ]]; then
  echo_stderr "File not found: '${CREDENTIALS}'"
  exit 3
fi

if ! cfg_parser "${CREDENTIALS}"; then
  echo_stderr "Parsing credentials file '${CREDENTIALS}' failed"
  exit 4
fi

if ! cfg.section."${AWS_PROFILE}" 2> /dev/null; then
  echo_stderr "Profile '${AWS_PROFILE}' not found"
  exit 5
fi

# shellcheck disable=SC2154
if ! ((show_key + show_secret + show_session_token)); then
  echo_stderr "# Profile '${AWS_PROFILE}'"
  printf 'export AWS_ACCESS_KEY_ID=%s\n' "${aws_access_key_id}"
  printf 'export AWS_SECRET_ACCESS_KEY=%s\n' "${aws_secret_access_key}"
  printf 'export AWS_SESSION_TOKEN=%s\n' "${aws_session_token}"
elif ((show_key)); then
  printf '%s' "${aws_access_key_id}"
elif ((show_secret)); then
  printf '%s' "${aws_secret_access_key}"
elif ((show_session_token)); then
  printf '%s' "${aws_session_token}"
else
  echo_stderr "Unknown error"
  exit 9
fi

unset -v CREDENTIALS
unset -v show_key show_secret show_session_token
unset -v aws_access_key_id aws_secret_access_key aws_session_token

exit 0

# vim: tabstop=2 shiftwidth=2 expandtab filetype=sh syntax=sh
