#!/usr/bin/env bash
#
# @PACKAGE_NAME@
# Version: @PACKAGE@-@PACKAGE_VERSION@
# Project: @PACKAGE_URL@
# Send bug reports to: @PACKAGE_BUGREPORT@
#

tdd_util_debug=''

verbose_echo() {
	local msg="${*}"

	if [[ "${verbose:-}" &&  "${verbose:-}" == 'y' || "${verbose:-}" == '1' ]]; then
		echo "${msg}"
		return
	fi

	if [[ "${quiet:-}" &&  "${quiet:-}" != 'y' && "${quiet:-}" != '1' ]]; then
		echo "${msg}"
	fi
}

test_verbose_echo() {
	echo '-----------------'

	unset verbose
	verbose_echo "${FUNCNAME[0]}: verbose AAA"
	verbose=''
	verbose_echo "${FUNCNAME[0]}: verbose BBB"
	verbose=n
	verbose_echo "${FUNCNAME[0]}: verbose CCC"
	verbose=y
	verbose_echo "${FUNCNAME[0]}: verbose DDD"
	verbose=0
	verbose_echo "${FUNCNAME[0]}: verbose EEE"
	verbose=1
	verbose_echo "${FUNCNAME[0]}: verbose FFF"
	unset verbose
	echo "${FUNCNAME[0]}: Want verbose DDD, FFF"

	echo '-----------------'

	unset quiet
	verbose_echo "${FUNCNAME[0]}: quiet GGG"
	quiet=''
	verbose_echo "${FUNCNAME[0]}: quiet HHH"
	quiet=n
	verbose_echo "${FUNCNAME[0]}: quiet III"
	quiet=y
	verbose_echo "${FUNCNAME[0]}: quiet JJJ"
	quiet=0
	verbose_echo "${FUNCNAME[0]}: quiet KKK"
	quiet=1
	verbose_echo "${FUNCNAME[0]}: quiet LLL"
	unset quiet
	echo "${FUNCNAME[0]}: Want quiet III, KKK"

	echo '-----------------'
}

str_trim_space() {
	local str_in=${1}
	local str_out="${str_in}"

	str_out="${str_out//$'\t'/ }"
	str_out="${str_out//$'\n'/}"
	str_out="${str_out//    / }"
	str_out="${str_out//   / }"
	str_out="${str_out//  / }"

	# trim leading space.
	str_out="${str_out#"${str_out%%[![:space:]]*}"}"

	# trim trailing space.
	str_out="${str_out%"${str_out##*[![:space:]]}"}"

	if [[ ${tdd_util_debug} && "${str_in}" != "${str_out}" ]]; then
		echo "${FUNCNAME[0]}: '${str_in}' => '${str_out}'" >&2
	fi

	echo "${str_out}"
}

clean_ws() {
	str_trim_space "${*}"
}

make_one_line_list() {
	echo -n "$(str_trim_space "${*}")"
}

make_multi_line_list() {
	local in="${*}"

	in="${in//$'\t'/  }"
	in="${in# }"
	in="${in% }"

	echo -n "$in"
}

substring_has() {
	local string=${1}
	local substring=${2}

	[ -z "${string##*"${substring}"*}" ];
}

substring_begins() {
	local string=${1}
	local substring=${2}

	[ -z "${string##"${substring}"*}" ];
}

substring_ends() {
	local string=${1}
	local substring=${2}

	[ -z "${string##*"${substring}"}" ];
}

sec_to_hour() {
	local sec=${1}

	local hour
	local frac_10
	local frac_100

	hour=$(( sec / 3600 ))
	frac_10=$(( (sec - hour * 3600) * 10 / 3600 ))
	frac_100=$(( (sec - hour * 3600) * 100 / 3600 ))

	if (( frac_10 != 0 )); then
		frac_10=''
	fi

	echo "${hour}.${frac_10}${frac_100}"
}

test_sec_to_hour() {
	local start=${1:-3590}
	local end=${2:-36037}
	local enc=${3:-1}

	local failed=''

	echo '-------------------------'

	for (( sec = start; sec <= end; sec += enc )); do
		local s2h
		local bc

		s2h="$(sec_to_hour "${sec}")"
		bc="$(printf "%0.2f\n" "$(bc -l <<< "scale=2; ${sec}/3600")")"

		if [[ "${s2h}" != "${bc}" ]]; then
			failed=1
			echo "ERROR: ${sec} sec = ${s2h} (${bc}) hour" >&1
		else
			echo "${sec} sec = ${s2h} (${bc}) hour" >&1
		fi
	done

	if [[ ! ${failed} ]]; then
		echo "${FUNCNAME[0]}: Success."
	else
		echo "${FUNCNAME[0]}: Failed."
	fi
	echo '-------------------------'
}

sec_to_min() {
	local sec=${1}

	local min
	local frac_10
	local frac_100

	min=$(( sec / 60 ))
	frac_10=$(( (sec - min * 60) * 10 / 60 ))
	frac_100=$(( (sec - min * 60) * 100 / 60 ))

	if (( frac_10 != 0 )); then
		frac_10=''
	fi

	echo "${min}.${frac_10}${frac_100}"
}

test_sec_to_min() {
	local start=${1:-0}
	local end=${2:-500}
	local enc=${3:-1}

	local failed=''

	echo '-------------------------'

	for (( sec = start; sec <= end; sec += enc )); do
		local s2m
		local bc

		s2m="$(sec_to_min "${sec}")"
		bc="$(printf "%0.2f\n" "$(bc -l <<< "scale=2; ${sec}/60")")"

		if [[ "${s2m}" != "${bc}" ]]; then
			failed=1
			echo "ERROR: ${sec} sec = ${s2m} (${bc}) min" >&1
		else
			echo "${sec} sec = ${s2m} (${bc}) min" >&1
		fi
	done

	if [[ ! ${failed} ]]; then
		echo "${FUNCNAME[0]}: Success."
	else
		echo "${FUNCNAME[0]}: Failed."
	fi
	echo '-------------------------'
}

parse_date() {
	local str=${1}
	local -n _parse_date__date=${2}
	local -n _parse_date__day=${3}
	local -n _parse_date__time=${4}

	local regex_date="(([[:digit:]]{4}\.[[:digit:]]{2}\.[[:digit:]]{2})-(([[:digit:]]{2}\.){2}[[:digit:]]{2}))"

	if [[ ! "${str}" =~ ${regex_date} ]]; then
		echo "${FUNCNAME[0]}: No match" >&2
		return 1
	fi

	_parse_date__date="${BASH_REMATCH[1]}"
	_parse_date__day="${BASH_REMATCH[2]}"
	_parse_date__time="${BASH_REMATCH[3]}"

	if [[ ${debug} ]]; then
		echo "${FUNCNAME[0]}: str:  '${str}'" >&2
		echo "${FUNCNAME[0]}: date: '${_parse_date__date}'" >&2
		echo "${FUNCNAME[0]}: day:  '${_parse_date__day}'" >&2
		echo "${FUNCNAME[0]}: time: '${_parse_date__time}'" >&2
	fi

	return 0
}

test_parse_date() {
	local date
	local day
	local time

	local -a str_array=(
		"${script_name}-$(date +%Y.%m.%d-%H.%M.%S)"
		"${script_name}-$(date +%Y.%m.%d-%H.%M.%S)-extra"
	)

	echo '-------------------------'

	local i
	for (( i = 0; i < ${#str_array[@]}; i++ )); do
		local str="${str_array[i]}"

		{
			if [[ ${i} != '0' ]]; then
				echo
			fi

			echo "${FUNCNAME[0]}: str-$(( i + 1 )): '${str}'"

			parse_date "${str}" date day time

			echo "${FUNCNAME[0]}: day:   '${day}'"
			echo "${FUNCNAME[0]}: date:  '${date}'"
			echo "${FUNCNAME[0]}: time:  '${time}'"
		} >&2
	done
	echo '-------------------------'

}

parse_date_git() {
	local str=${1}
	local -n _parse_date_git__day=${2}
	local -n _parse_date_git__month=${3}
	local -n _parse_date_git__date=${4}
	local -n _parse_date_git__year=${5}
	local -n _parse_date_git__time=${6}

	local regex_day="[[:alpha:]]{3}"
	local regex_month="[[:alpha:]]{3}"
	local regex_date="[[:digit:]][[:digit:]]?"
	local regex_time="([[:digit:]]{2}:){2}[[:digit:]]{2}"
	local regex_year="[[:digit:]]{4}"

	local regex_full="^(${regex_day}) (${regex_month})  ?(${regex_date}) (${regex_time}) (${regex_year})"

	if [[ ! "${str}" =~ ${regex_full} ]]; then
		echo "ERROR: No match '${str}'" >&2
		return 1
	fi

	_parse_date_git__day="${BASH_REMATCH[1]}"
	_parse_date_git__month="${BASH_REMATCH[2]}"
	_parse_date_git__date="${BASH_REMATCH[3]}"
	_parse_date_git__time="${BASH_REMATCH[4]}"
	_parse_date_git__year="${BASH_REMATCH[6]}"

	if [[ ${debug} ]]; then
		echo "${FUNCNAME[0]}: str:   '${str}'" >&2
		echo "${FUNCNAME[0]}: day:   '${_parse_date_git__day}'" >&2
		echo "${FUNCNAME[0]}: month: '${_parse_date_git__month}'" >&2
		echo "${FUNCNAME[0]}: date:  '${_parse_date_git__date}'" >&2
		echo "${FUNCNAME[0]}: year:  '${_parse_date_git__year}'" >&2
		echo "${FUNCNAME[0]}: time:  '${_parse_date_git__time}'" >&2
	fi
	return 0
}

test_parse_date_git() {
	local day
	local month
	local date
	local year
	local time

	local -a str_array=(
		'Wed Jan 8 13:44:58 2020 -0800'
		'Sun Feb 28 11:26:06 2021 -0800'
		"$(date '+%a %b %e %H:%M:%S %Y %z')"	# Fri Oct 21 20:47:27 2022 -0700
#		"$(date '+%c %z')"			# Fri 21 Oct 2022 08:47:27 PM PDT -0700
	)

	echo '-------------------------'

	local i
	for (( i = 0; i < ${#str_array[@]}; i++ )); do
		local str="${str_array[i]}"

		{
			if [[ ${i} != '0' ]]; then
				echo
			fi

			echo "${FUNCNAME[0]}: str-$(( i + 1 )): '${str}'"

			parse_date_git "${str}" day month date year time

			echo "${FUNCNAME[0]}: day:   '${day}'"
			echo "${FUNCNAME[0]}: month: '${month}'"
			echo "${FUNCNAME[0]}: date:  '${date}'"
			echo "${FUNCNAME[0]}: year:  '${year}'"
			echo "${FUNCNAME[0]}: time:  '${time}'"
		} >&2
	done
	echo '-------------------------'
}

parse_date_iso_8601() {
	local str=${1}
	local -n _parse_date_iso_8601__year=${2}
	local -n _parse_date_iso_8601__month=${3}
	local -n _parse_date_iso_8601__day=${4}
	local -n _parse_date_iso_8601__time=${5}

	local regex_year="[[:digit:]]{4}"
	local regex_month="[[:digit:]]{2}"
	local regex_day="[[:digit:]]{2}"
	local regex_time="[[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}"

	local regex_full="^(${regex_year})-(${regex_month})-(${regex_day}) (${regex_time}) "

	if [[ ! "${str}" =~ ${regex_full} ]]; then
		echo "ERROR: No match '${str}'" >&2
		return 1
	fi

	_parse_date_iso_8601__year="${BASH_REMATCH[1]}"
	_parse_date_iso_8601__month="${BASH_REMATCH[2]}"
	_parse_date_iso_8601__day="${BASH_REMATCH[3]}"
	_parse_date_iso_8601__time="${BASH_REMATCH[4]}"

	if [[ ${debug} ]]; then
		echo "${FUNCNAME[0]}: str:   '${str}'" >&2
		echo "${FUNCNAME[0]}: year:  '${_parse_date_iso_8601__year}'" >&2
		echo "${FUNCNAME[0]}: month: '${_parse_date_iso_8601__month}'" >&2
		echo "${FUNCNAME[0]}: day:   '${_parse_date_iso_8601__day}'" >&2
		echo "${FUNCNAME[0]}: time:  '${_parse_date_iso_8601__time}'" >&2
	fi
	return 0
}

test_parse_date_iso_8601() {
	local year
	local month
	local day
	local time

	local -a str_array=(
		'2020-12-27 13:30:10 -0800'
		'2021-01-02 18:16:00 -0700'
	)

	echo '-------------------------'

	local i
	for (( i = 0; i < ${#str_array[@]}; i++ )); do
		local str="${str_array[i]}"

		{
			if [[ ${i} != '0' ]]; then
				echo
			fi

			echo "${FUNCNAME[0]}: str-$(( i + 1 )): '${str}'"

			parse_date_iso_8601 "${str}" year month day time

			echo "${FUNCNAME[0]}: year:  '${year}'"
			echo "${FUNCNAME[0]}: month: '${month}'"
			echo "${FUNCNAME[0]}: day:   '${day}'"
			echo "${FUNCNAME[0]}: time:  '${time}'"
		} >&2
	done
	echo '-------------------------'
}

file_size_bytes() {
	local dir=${1}

	if [[ ! ${dir} ]]; then
		echo '0'
		return
	fi

	local size
	size="$(du -sb "${dir}")"
	echo "${size%%[[:space:]]*}"
}

file_size_human() {
	local dir=${1}

	local size
	size="$(du -sh "${dir}")"
	echo "${size%%[[:space:]]*}"
}

check_exists() {
	local src="${1}"
	local msg="${2}"
	local usage="${3-}"

	if [[ ! -e "${src}" ]]; then
		echo "${script_name}: ERROR (${FUNCNAME[0]}): ${msg} does not exist: '${src}'" >&2
		if [[ ${usage} ]]; then
			usage
		fi
		exit 1
	fi
}

check_directory() {
	local src="${1}"
	local msg="${2}"
	local usage="${3}"

	if [[ ! -d "${src}" ]]; then
		echo "${script_name}: ERROR (${FUNCNAME[0]}): Directory not found${msg}: '${src}'" >&2
		if [[ ${usage} ]]; then
			usage
		fi
		exit 1
	fi
}

check_file() {
	local src="${1}"
	local msg="${2}"
	local usage="${3}"

	if [[ ! -f "${src}" ]]; then
		echo -e "${script_name}: ERROR: File not found${msg}: '${src}'" >&2
		if [[ ${usage} ]]; then
			usage
		fi
		exit 1
	fi
}

check_opt() {
	option=${1}
	shift
	value="${*}"

	if [[ ! ${value} ]]; then
		echo "${script_name}: ERROR (${FUNCNAME[0]}): Must provide --${option} option." >&2
		usage
		exit 1
	fi
}

check_not_opt() {
	option1=${1}
	option2=${2}
	shift 2
	value2="${*}"

	if [[ ${value2} ]]; then
		echo "${script_name}: ERROR (${FUNCNAME[0]}): Can't use --${option2} with --${option1}." >&2
		usage
		exit 1
	fi
}

check_if_positive() {
	local name=${1}
	local val=${2}

	if [[ ! ${val##*[![:digit:]]*} || "${val}" -lt 1 ]]; then
		echo "${script_name}: ERROR: ${name} must be a positive integer.  Got '${val}'." >&2
		usage
		exit 1
	fi
}

check_prog() {
	local prog="${1}"
	local result;

	result=0
	if ! test -x "$(command -v "${prog}")"; then
		echo "${script_name}: ERROR: Please install '${prog}'." >&2
		result=1
	fi

	return ${result}
}

check_progs() {
	local progs="${*}"
	local p;
	local result;

	result=0
	for p in ${progs}; do
		if ! check_prog "${p}"; then
			result=1
		fi
	done

	return ${result}
}

check_pairs () {
	local -n _check_pairs__pairs=${1}
	local key
	local val
	local result

	result=0
	for key in "${!_check_pairs__pairs[@]}"; do
		val="${_check_pairs__pairs[${key}]}"

		if [[ ${verbose} ]]; then
			echo "${script_name}: check: '${val}' => '${key}'." >&2
		fi

		if [[ ! -e "${val}" ]]; then
			echo "${script_name}: ERROR: '${val}' not found, please install '${key}'." >&2
			((result += 1))
		fi
	done
	return "${result}"
}

check_progs_and_pairs () {
	local progs="${1}"
	local -n _check_progs_and_pairs__pairs=${2}
	local result

	result=0
	if ! check_progs "${progs}"; then
		((result += 1))
	fi

	if ! check_pairs _check_progs_and_pairs__pairs; then
		((result += 1))
	fi
	return "${result}"
}

find_common_parent() {
	local dir1
	dir1="$(realpath -m "${1}")"
	local dir2
	dir2="$(realpath -m "${2}")"
	local A1
	local A2
	local sub

	IFS="/" read -ra A1 <<< "${dir1}"
	IFS="/" read -ra A2 <<< "${dir2}"

	#echo "array len = ${#A1[@]}" >&2

	for ((i = 0; i < ${#A1[@]}; i++)); do
		echo "${i}: @${A1[i]}@ @${A2[i]}@" >&2
		if [[ "${A1[i]}" != "${A2[i]}" ]]; then
			break;
		fi
		sub+="${A1[i]}/"
	done

	#echo "sub = @${sub}@" >&2
	echo "${sub}"
}

relative_path_2() {
	local base="${1}"
	local target="${2}"
	local root="${3}"

	base="${base##"${root}"}"
	base="${base%%/}"
	base=${base%/*}
	target="${target%%/}"

	local back=""
	while :; do
		set +x
		echo "target: ${target}" >&2
		echo "base:   ${base}" >&2
		echo "back:   ${back}" >&2
		set -x
		if [[ "${base}" == "/" || ! ${base} ]]; then
			break
		fi
		back+="../"
		if [[ "${target}" == ${base}/* ]]; then
			break
		fi
		base=${base%/*}
	done

	echo "${back}${target##"${base}"/}"
}

relative_path() {
	local base="${1}"
	local target="${2}"
	local root="${3}"

	base="${base##"${root}"}"
	base="${base%%/}"
	base=${base%/*}
	target="${target%%/}"

	local back=""
	while :; do
		#echo "target: ${target}" >&2
		#echo "base:   ${base}" >&2
		#echo "back:   ${back}" >&2
		if [[ "${base}" == "/" || "${target}" == ${base}/* ]]; then
			break
		fi
		back+="../"
		base=${base%/*}
	done

	echo "${back}${target##"${base}"/}"
}

copy_file() {
	local src="${1}"
	local dest="${2}"

	check_file "${src}" '' ''
	cp -f "${src}" "${dest}"
}

cpu_count() {
	local result

	if result="$(getconf _NPROCESSORS_ONLN)"; then
		echo "${result}"
	else
		echo "1"
	fi
}

get_user_home() {
	local user=${1}
	local result;

	if ! result="$(getent passwd "${user}")"; then
		echo "${script_name}: ERROR (${FUNCNAME[0]}): No home for user '${user}'" >&2
		exit 1
	fi
	echo "${result}" | cut -d ':' -f 6
}

export known_arches="arm32 arm64 amd64 ppc32 ppc64 ppc64le"

get_arch() {
	local a=${1}

	case "${a}" in
	arm32|arm)			echo "arm32" ;;
	arm64|aarch64)			echo "arm64" ;;
	amd64|x86_64)			echo "amd64" ;;
	ppc|powerpc|ppc32|powerpc32)	echo "ppc32" ;;
	ppc64|powerpc64)		echo "ppc64" ;;
	ppc64le|powerpc64le)		echo "ppc64le" ;;
	*)
		echo "${script_name}: ERROR (${FUNCNAME[0]}): Bad arch '${a}'" >&2
		exit 1
		;;
	esac
}

get_host_arch() {
	get_arch "$(uname -m)"
}

get_triple() {
	local a=${1}

	case "${a}" in
	amd64)		echo "x86_64-linux-gnu" ;;
	arm32)		echo "arm-linux-gnueabi" ;;
	arm64)		echo "aarch64-linux-gnu" ;;
	ppc32)		echo "powerpc-linux-gnu" ;;
	ppc64)		echo "powerpc64-linux-gnu" ;;
	ppc64le)	echo "powerpc64le-linux-gnu" ;;
	*)
		echo "${script_name}: ERROR (${FUNCNAME[0]}): Bad arch '${a}'" >&2
		exit 1
		;;
	esac
}

kernel_arch() {
	local a=${1}

	case "${a}" in
	amd64)		echo "x86_64" ;;
	arm32*)		echo "arm" ;;
	arm64*)		echo "arm64" ;;
	ppc*)		echo "powerpc" ;;
	*)
		echo "${script_name}: ERROR (${FUNCNAME[0]}): Bad arch '${a}'" >&2
		exit 1
		;;
	esac
}

sudo_write() {
	sudo tee "${1}" >/dev/null
}

sudo_append() {
	sudo tee -a "${1}" >/dev/null
}

is_ip_addr() {
	local host=${1}
	local regex_ip="([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}"

	if [[ "${host}" =~ ${regex_ip} ]]; then
		echo "found name: '${host}'"
		return 1
	fi
	echo "found ip: '${host}'"
	return 0
}

# ip a | grep 'inet .* tun0' | grep -E --only-matching '([[:digit:]]{1,3}.){3}[[:digit:]]{1,3}'

find_addr() {
	local -n _find_addr__addr=${1}
	local hosts_file=${2}
	local host=${3}

	_find_addr__addr=""

	if is_ip_addr "${host}"; then
		_find_addr__addr="${host}"
		return
	fi

	if [[ ! -x "$(command -v dig)" ]]; then
		echo "${script_name}: WARNING: Please install dig (dnsutils)." >&2
	else
		_find_addr__addr="$(dig "${host}" +short)"
	fi

	if [[ ! ${_find_addr__addr} ]]; then
		_find_addr__addr="$(grep -E -m 1 "${host}[[:space:]]*$" "${hosts_file}" \
			| grep -E -o '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' || :)"

		if [[ ! ${_find_addr__addr} ]]; then
			echo "${script_name}: ERROR (${FUNCNAME[0]}): '${host}' DNS entry not found." >&2
			exit 1
		fi
	fi
}

my_addr() {
	ip route get 8.8.8.8 | grep -E -o 'src [0-9.]*' | cut -f 2 -d ' '
}

wait_pid() {
	local pid="${1}"
	local timeout_sec=${2}
	timeout_sec=${timeout_sec:-300}

	echo "${script_name}: INFO: Waiting ${timeout_sec}s for pid ${pid}." >&2

	local count=1
	while kill -0 "${pid}" &> /dev/null; do
		((count = count + 5))
		if [[ count -gt ${timeout_sec} ]]; then
			echo "${script_name}: ERROR (${FUNCNAME[0]}): wait_pid failed for pid ${pid}." >&2
			exit 2
		fi
		sleep 5s
	done
}

git_get_repo_name() {
	local repo=${1}

	if [[ "${repo: -1}" == "/" ]]; then
		repo=${repo:0:-1}
	fi

	local repo_name="${repo##*/}"

	if [[ "${repo_name:0:1}" == "." ]]; then
		repo_name="${repo%/.*}"
		repo_name="${repo_name##*/}"
		echo "${repo_name}"
		return
	fi

	repo_name="${repo_name%.*}"

	if [[ -z "${repo_name}" ]]; then
		echo "${script_name}: ERROR (${FUNCNAME[0]}): Bad repo: '${repo}'" >&2
		exit 1
	fi

	echo "${repo_name}"
}

git_set_remote() {
	local dir=${1}
	local repo=${2}
	local remote

	remote="$(git -C "${dir}" remote -v | grep -E --max-count=1 'origin' | cut -f2 | cut -d ' ' -f1)"

	if ! remote="$(git -C "${dir}" remote -v | grep -E --max-count=1 'origin' | cut -f2 | cut -d ' ' -f1)"; then
		echo "${script_name}: ERROR (${FUNCNAME[0]}): Bad git repo ${dir}." >&2
		exit 1
	fi

	if [[ "${remote}" != "${repo}" ]]; then
		echo "${script_name}: INFO: Switching git remote '${remote}' => '${repo}'." >&2
		git -C "${dir}" remote set-url origin "${repo}"
		git -C "${dir}" remote -v
	fi
}

git_checkout_force() {
	local dir=${1}
	local repo=${2}
	local branch=${3:-'master'}

	if [[ ! -d "${dir}" ]]; then
		mkdir -p "${dir}/.."
		git clone "${repo}" "${dir}"
	fi

	git_set_remote "${dir}" "${repo}"

	git -C "${dir}" checkout -- .
	git -C "${dir}" remote update -p
	git -C "${dir}" reset --hard origin/"${branch}"
	git -C "${dir}" checkout --force "${branch}"
	git -C "${dir}" pull "${repo}" "${branch}"
	git -C "${dir}" status
}

git_checkout_safe() {
	local dir=${1}
	local repo=${2}
	local branch=${3:-'master'}

	if [[ -e "${dir}" ]]; then
		if [[ ! -e "${dir}/.git/config" ]]; then
			mv "${dir}" "${dir}.backup-$(date +%Y.%m.%d-%H.%M.%S)"
		elif ! git -C "${dir}" status --porcelain; then
			echo "${script_name}: INFO: Local changes: ${dir}." >&2
			cp -a --link "${dir}" "${dir}.backup-$(date +%Y.%m.%d-%H.%M.%S)"
		fi
	fi

	git_checkout_force "${dir}" "${repo}" "${branch}"
}

run_shellcheck() {
	local file=${1}

	shellcheck=${shellcheck:-"shellcheck"}

	if ! test -x "$(command -v "${shellcheck}")"; then
		echo "${script_name}: ERROR: Please install '${shellcheck}'." >&2
		exit 1
	fi

	${shellcheck} "${file}"
}

get_container_id() {
	local cpuset
	cpuset="$(cat /proc/1/cpuset)"
	local regex="^/docker/([[:xdigit:]]*)$"
	local container_id

	if [[ "${cpuset}" =~ ${regex} ]]; then
		container_id="${BASH_REMATCH[1]}"
		echo "${script_name}: INFO: Container ID '${container_id}'." >&2
	else
		echo "${script_name}: WARNING: Container ID not found." >&2
	fi

	echo "${container_id}"
}

export ansi_reset='\e[0m'
export ansi_red='\e[1;31m'
export ansi_green='\e[0;32m'
export ansi_yellow='\e[1;33m'
export ansi_blue='\e[0;34m'
export ansi_teal='\e[0;36m'

if [[ ${PS4} == '+ ' ]]; then
	if [[ ${JENKINS_URL} ]]; then
		export PS4='+ [${STAGE_NAME}] \${BASH_SOURCE##*/}:\${LINENO}: '
	else
		export PS4='\[\e[0;33m\]+ ${BASH_SOURCE##*/}:${LINENO}:(${FUNCNAME[0]:-main}):\[\e[0m\] '
	fi
fi

script_name="${script_name:-${0##*/}}"
