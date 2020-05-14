#! /bin/bash

set -euo pipefail

main() {
    declare package="${1-}" jobid="${2-}" url="${3-}" rversion="${4-}" \
	    checkArgs="${5-}" envVars="${6-}" build="${7-}" pkgname="${8-}" \
	    platformParams="${9-}"

    username=""
    trap cleanup 0

    # TODO: proper parser for parameters
    if [[ "$platformParams" =~ "ods=true" ]]; then
	local ods=true
    else
	local ods=""
    fi

    local password=$(random_password)
    username=$(random_username)
    homedir="/export/home/${username}"

    echo ">>>>>============== Creating user ${username}"
    create_user "${username}" "${password}" "${homedir}"

    echo ">>>>>============== Downloading package"
    download_package

    echo ">>>>>============== Setting up home directory"
    setup_home "${username}" "${homedir}" "${package}"
    echo "checkArgs=${checkArgs}" > "${homedir}/rhub-env.sh"
    echo "${envVars}" >> "${homedir}/rhub-env.sh"

    echo "Querying R version"
    local realrversion=$(get_r_version "${rversion}")

    echo ">>>>>============== Running check"
    local pkgname=$(echo ${package} | cut -d"_" -f1)
    run_check "${username}" "${package}" "${pkgname}" "${realrversion}" "${ods}"

    echo "Saving artifacts"
    save_artifacts "${jobid}" "${homedir}" "${pkgname}"

    # Cleanup is automatic
}

random_string() {
    declare n="${1-}"
    if [[ -z "$n" ]]; then echo no random string length; return 1; fi
    cat /dev/urandom | env LC_CTYPE=C tr -dc '[:alnum:]' | fold -w ${n} |
	head -n 1
}

random_username() {
    local random=$(random_string 6)
    echo "X${random}"
}

random_password() {
    echo $(random_string 16)
}

# This generates a UID that is larger than the current largest uid,
# and it has some randomness, to avoid race conditions. (Not perfect,
# but this is hard to solve without locking.)
generate_uid() {
    local maxid=$(getent passwd | cut -d: -f3 |
			 grep -v '[1-9][0-9][0-9][0-9][0-9]' |
			 sort -n | tail -1)
    echo $((maxid + 1 + $RANDOM / 2000))
}

create_user() {
    declare username="${1-}" password="{2-}" homedir="${3-}"
    local uid=$(generate_uid)

    useradd -d "${homedir}" -m -u "${uid}" -c "Rhub-user" \
	 -s /bin/bash "${username}"
    setup_user "${username}"
}

setup_user() {
    declare username="${1-}"
    # Nothing to do here for now
}

download_package() {
    /opt/csw/bin/curl -L -o "${package}" "${url}"
}

setup_home() {
    declare username="${1-}" homedir="${2-}" package="${3-}"
    mkdir -p "${homedir}"
    cp "${package}" "${homedir}"
    cp slave.sh "${homedir}"
    chown "${username}" "${homedir}"
    chmod 700 "${homedir}"
}

json_version() {
    declare url="${1-}"
    local version=$(/opt/csw/bin/curl -s "${url}" | ./JSON.sh -b |
			   grep '^\[0,"version"\]' | awk '{ print $2; }' |
			   tr -d '"')
    echo "${version}"
}

get_r_version() {
  declare rversion="${1-}"
  if [[ "${rversion}" == "r-devel" ]]; then
    realrversion="devel"
  elif [[ "${rversion}" == "r-release" ]]; then
    realrversion=$(json_version "https://rversions.r-pkg.org/r-release")
  elif [[ "${rversion}" == "r-patched" ]]; then
    realrversion=$(json_version "https://rversions.r-pkg.org/r-release")
    realrversion="${realrversion}patched"
  elif [[ "${rversion}" == "r-oldrel" ]]; then
    realrversion=$(json_version "https://rversions.r-pkg.org/r-oldrel")
  else
    realrversion="${rversion}"
  fi
  echo "${realrversion}"
}

run_check() {
  declare username="${1-}" filename="${2-}" pkgname="${3-}" rversion="${4-}" ods="${5-}"
  su - "${username}" \
    -c "~/slave.sh \"${filename}\" \"${pkgname}\" \"${rversion}\" \"${ods}\"" || true
}

save_artifacts() {
    declare jobid="${1-}" homedir="${2-}" pkgname="${3-}"
    mkdir -p "${jobid}"
    cp -r "${homedir}/${pkgname}.Rcheck" "${jobid}" || true
    cp -r "${homedir}/"*.tar.gz "${jobid}" || true
}

# Cleanup user, including home directory, arguments are global,
# because we are calling this from trap
cleanup() {
    echo "Cleaning up user and home directory"
    if [[ -z "$username" || -z "$homedir" ]]; then
	echo "Cannot clean up, no username or homedir set"
	return 1
    fi
    userdel -r ${username} || true
    rm -rf "${homedir}" || true
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
