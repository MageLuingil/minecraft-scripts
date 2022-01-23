#!/bin/bash
# This script downloads all Minecraft client jars, extracts death messages from
# the language files, and compares them, compiling a list of all death message
# changes from one version of the game to the next.
# 
# Currently only supports en_US - additional languages will require more research,
# as the location they're stored got more complex in recent versions.
# 
# Author: Daniel Matthies
# 
# USAGE
# 
# ./extract_death_messages.sh [lang]
set -eo pipefail

declare -r LANG="${1:-en_US}"

check_for_commands() {
	local cmd ret=0
	for cmd in "$@"; do
		if ! command -v "$cmd" >/dev/null 2>&1; then
			echo >&2 "Error: $cmd is required"
			ret=1
		fi
	done
	return $ret
}

# Download all client jar files into ./jars/
fetch_clients() {
	local version url
	[[ -d jars ]] || mkdir jars
	echo "Downloading version manifest..."
	curl -Ss "https://launchermeta.mojang.com/mc/game/version_manifest.json" | \
		jq -r '.versions | map(select(.type | contains("release"))) | .[] | "\(.id) \(.url)"' | \
		while read version url; do
			# Only download client if we're missing death messages for this
			# version, and the client hasn't already been downloaded
			if [[ ! -f "msgs/$LANG/${version}.txt" && ! -f "jars/client-${version}.jar" ]]; then
				echo "Downloading client for $version"
				curl -Ss "$url" | jq -r '.downloads.client.url' | xargs -I{} curl -Sso "jars/client-${version}.jar" "{}"
			fi
		done
}

# Checks if the first version param is >= the second
version_gte() {
	dpkg --compare-versions "$1" "ge" "$2"
}

# Args: filename lang
extract_lang_1_0() {
	unzip -p "$1" "lang/${2}.lang" | \
		sed -n '/death\./ s/death\.[.a-zA-Z]*=%1$s/PlayerName/p'
}

# Args: filename lang
extract_lang_1_6() {
	unzip -p "$1" "assets/minecraft/lang/${2}.lang" | \
		sed -n '/death\./ s/death\.[.a-zA-Z]*=%1$s/PlayerName/p'
}

# Args: filename lang
extract_lang_1_6() {
	unzip -p "$1" "assets/minecraft/lang/${2,,}.lang" | \
		sed -n '/death\./ s/death\.[.a-zA-Z]*=%1$s/PlayerName/p'
}

# Args: filename lang
extract_lang_1_13() {
	unzip -p "$1" "assets/minecraft/lang/${2,,}.json" | \
		jq -r 'to_entries[] | select(.key|startswith("death.")) | .value' | \
		sed 's/%1$s/PlayerName/'
}

main() {
	local previous
	
	fetch_clients
	
	printf '%s\n' jars/client-*.jar | sort -V | \
	while read file; do
		local basename="$(basename $file .jar)"
		local version="${basename#client-}"
		local msgfile="msgs/$LANG/${version}.txt"
		
		mkdir -p "$(dirname $msgfile)"
		
		# Check if we need to extract death messages for this version
		if [[ -f "$msgfile" ]]; then
			:
		elif version_gte "$version" "1.13"; then
			echo "Extracting death messages for $version"
			extract_lang_1_13 "$file" "$LANG" > "$msgfile"
		elif version_gte "$version" "1.6"; then
			echo "Extracting death messages for $version"
			extract_lang_1_6 "$file" "$LANG" > "$msgfile"
		else
			echo "Extracting death messages for $version"
			extract_lang_1_0 "$file" "$LANG" > "$msgfile"
		fi
		
		# Compare to previous version
		if [[ -z "$previous" ]]; then
			echo -e "From ${version}\n" > death_messages.txt
			cat "$msgfile" >> death_messages.txt
		else
			diff --ignore-trailing-space  --old-line-format="- %L" --new-line-format="+ %L" --unchanged-line-format="" \
				<(sort "$previous") \
				<(sort "$msgfile") >changes.tmp || \
			{
				echo "Found changes for $version"
				echo -e "\nFrom ${version}\n" >> death_messages.txt
				cat changes.tmp >> death_messages.txt
			}
		fi
		
		previous="$msgfile"
	done
	
	# Cleanup
	rm changes.tmp
}

check_for_commands dpkg jq curl sed diff

main "$@"
