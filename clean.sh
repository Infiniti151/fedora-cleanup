#!/usr/bin/env bash

path=(/home/* /var)
already_cleaned=false
akmod_files_to_keep=$(( $(rpm -qa kernel | wc -l)*2 + 1 )) # Based on the number of kernels installed

# Define color codes 
RED='\033[1;31m' 
GREEN='\033[1;32m' 
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color (reset)
DASHES="-----------------------------"

add_to_log(){
	[ $1 == "Total" ] && echo $DASHES >> "${path[0]}"/clean.log
    printf "%-10s : %s %s\n" "$1" "$2" "$3" >> "${path[0]}"/clean.log
}

log_message(){
	printf "${MAGENTA}%-10s ${CYAN}| ${RED}%s${NC}\n" "$1" "$2"
    add_to_log "$1" "$2"
}

clear_log(){
	if [ "$(stat -c%s "${path[0]}/clean.log")" -gt 1000000 ];then
	    :> "${path[0]}/clean.log"
	fi
}

log_cache(){
	if [ $2 -ne 0 ]; then
        calculate_cache "$2"
        calculate_total
        log_message "${1%% *}" "$fin"
    fi
}

convert_to_SI(){
	echo "$1" | numfmt --from-unit=1024 --to=si | sed 's/\([0-9]\)\([A-Z]\)/\1 \2/I'
}

calculate_cache(){
    fin=$(convert_to_SI "$1")
}

calculate_total(){
    total=$((total + cache))
}

check_executable(){
	[[ $(command -v "$1" >/dev/null 2>&1 && echo $?) == "0" ]]
}

delete_files(){
	local received_array=("$@") 
	for item in "${received_array[@]}"; do 
		if [ -d "$item" ]; then
			rm -rf "$item" 2>&1
		elif [ -f "$item" ];then
			rm -f "$item" 2>&1
		fi
	done
}

keep_nth_latest() {
    cache=0
	already_cleaned=true

    # Ensure directory exists and keep count is numeric
    [ -d "$2" ] || return 1
    [[ "$3" =~ ^[0-9]+$ ]] || return 1

    # Build list of dirs: either subdirs or the directory itself
    mapfile -t dirs < <(find "$2" -mindepth 1 -maxdepth 1 -type d)
    if [ ${#dirs[@]} -eq 0 ]; then
        dirs=("$2")
    fi

    for dir in "${dirs[@]}"; do
        count=$(ls -At "$dir" 2>/dev/null | wc -l)
        if [ "$count" -le "$3" ]; then
            continue
        fi
        # Files to keep = newest N
        keep_files=( $(ls -At "$dir" | head -n "$3") )
        for file in "$dir"/*; do
            [ -e "$file" ] || continue
            fname=$(basename "$file")
            if ! printf '%s\n' "${keep_files[@]}" | grep -qx "$fname"; then
                cache=$(($(du -c "$file" | awk 'END {print $1}') + cache))
                sudo rm "$file"
            fi
        done
    done

    log_cache "$1" "$cache"
}

clean_dnf(){
	already_cleaned=true
	cache=$(sudo dnf clean all | awk -F'of ' '{print $2}' | awk '{print $1 * 1024}')
	log_cache "$1" "$cache"
}

clear_cache(){
	case $1 in
	    "DNF cache")
			clean_dnf "$1"
		;;
		"Edge cache")
			cache=$(du -c "$2" "$3" "$4" "$5" "$6"/*.blob "$7" "$8" 2>/dev/null | awk 'END {print $1}')
		;;
		"Code cache")
			cache=$(du -c "$2" "$3" "$4" "$5" "$6" 2>/dev/null | awk 'END {print $1}')
		;;
		"Akmods cache")
			keep_nth_latest "$1" "$2" $akmod_files_to_keep
		;;
		"Wine cache")
			keep_nth_latest "$1" "$2" 1
		;;
		*)
			cache=$(du -c $2/* 2>/dev/null | awk 'END {print $1}')
		;;
	esac
	calculate_cache $cache
	if [[ "$fin" =~ [1-9] && $already_cleaned = false ]]; then
	        calculate_total
	        case $1 in
				"Edge cache")
					edge_arr=("$2" "$3" "$4" "$5" "$7")
					delete_files "${edge_arr[@]}" 
					rm -rf $6/*.blob 2>&1
					sudo find $8/* -maxdepth 0 -type f -not -iname "en-US.pak" -exec rm -r {} \; 2>&1
				;;
				"Code cache")
					code_arr=("$2" "$3" "$4" "$5" "$6")
					delete_files "${code_arr[@]}" 
				;;
				*)
					rm -rf $2/* 2>&1
				;;
			esac
			log_message "${1%% *}" "$fin"
    fi
	already_cleaned=false
}

clear_nvidia(){
	nvidia=(nsight-compute nsight-systems)
	IFS=$'\n'           ## only word-split on '\n'
	for i in "${nvidia[@]}"
	do
		x=$(ls -l "$3/$i" | grep -c ^d)
		if [ $x -gt 1 ];then
			readarray a < <(ls "$3/$i")
			echo -e "Total folders in \033[0;35m$i\033[0m: \033[0;36m${#a[@]}\033[0m"
			a=( $(printf "%s\n" ${a[@]} | sort -r ) )  ## reverse sort
			echo -e "Keeping \033[0;32m$a\033[0m"
			unset a[0]
			cache=0
			j="0"
			for j in "${a[@]}"
			do
			   nvidia_cache=$(du -c $3/$i/$j | awk 'END {print $1}')
			   cache=$((cache + nvidia_cache))
			   sudo rm -rf "$3/$i/$j"
			   echo -e "Deleted \033[0;31m$j: \033[0;33m$(convert_to_SI $nvidia_cache $i)\033[0m"
			done
			add_to_log "$1-$i" $(convert_to_SI $cache)
			calculate_total
		fi
	done

	x=$(ls "$4" | grep -c "$2-")
	if [ $x -gt 2 ];then
		readarray a < <(ls $4 | grep "$2-[1-9][1-9]$" | sort -r)
		readarray b < <(ls $4 | grep "$2-[1-9][1-9].[1-9]$" | sort -r)
		echo -e "Total folders of major versions \033[0;35m$2-xx\033[0m: \033[0;36m${#a[@]}\033[0m"
		echo -e "Total folders of minor versions \033[0;35m$2-xx.x\033[0m: \033[0;36m${#b[@]}\033[0m"
		a=( $(printf "%s\n" ${a[@]}) )
		b=( $(printf "%s\n" ${b[@]}) )
		if [ ${#a[@]} -gt 1 ];then
			echo -e "Keeping \033[0;32m$a\033[0m"
			unset a[0]
			for i in "${a[@]}"
			do
				sudo unlink "$4/$i"
				echo -e "Deleted \033[0;31m$i\033[0m"
			done
		fi
		if [ ${#b[@]} -gt 1 ];then
			echo -e "Keeping \033[0;32m$b\033[0m"
			unset b[0]
			cache=0
			for i in "${b[@]}"
			do
				cuda_cache=$(du -c $4/$i | awk 'END {print $1}')
				cache=$((cache + cuda_cache))
				sudo rm -rf "$4/$i"
				echo -e "Deleted \033[0;31m$i: \033[0;33m$(convert_to_SI $cuda_cache)\033[0m"
			done
			add_to_log "$1-$2" $(convert_to_SI $cache)
			calculate_total
		fi
	fi
}

clear_log

echo -e "\n[$(date +'%d/%m/%y %r')]" >> ${path[0]}/clean.log
printf "${CYAN}%s\n%-10s | %s\n%s${NC}\n" "$DASHES" "Component" "Freed Space" "$DASHES"

check_executable "pip" && clear_cache "Pip cache" "${path[0]}/.cache/pip"
check_executable "microsoft-edge" && clear_cache "Edge cache" "${path[0]}/.cache/microsoft-edge/Default/Cache/Cache_Data" "${path[0]}/.cache/microsoft-edge/Default/Code Cache/js" "${path[0]}/.config/microsoft-edge/Default/Service Worker/CacheStorage" "${path[0]}/.config/microsoft-edge/Default/Service Worker/ScriptCache" "${path[0]}/.config/microsoft-edge/Default/IndexedDB" "${path[0]}/.config/microsoft-edge/Default/load_statistics.db" "/opt/microsoft/msedge/locales"
check_executable "code" && clear_cache "Code cache" "${path[0]}/.config/Code/CachedExtensionVSIXs" "${path[0]}/.config/Code/Cache/Cache_Data" "${path[0]}/.config/Code/User/workspaceStorage" "${path[0]}/.config/Code/CachedData" "${path[0]}/.config/Code/GPUCache"
check_executable "firefox" && clear_cache "Firefox cache" "${path[0]}/.cache/mozilla/firefox/$(ls ${path[0]}/.cache/mozilla/firefox)/cache2/entries"
check_executable "librewolf" && clear_cache "Librewolf cache" "${path[0]}/.cache/librewolf/*/cache2/entries"
check_executable "akmods" && clear_cache "Akmods cache" "${path[1]}/cache/akmods"
check_executable "wine" && clear_cache "Wine cache" "${path[0]}/.cache/wine"
check_executable "nvidia-smi" && clear_cache "GLCache cache" "${path[0]}/.cache/nvidia/GLCache"
check_executable "cuda-toolkit" && clear_nvidia "Nvidia" "cuda" "/opt/nvidia" "/usr/local"
clear_cache "Thumbnails cache" "${path[0]}/.cache/thumbnails"
clear_cache "Coredumps cache" "${path[1]}/lib/systemd/coredump"
clear_cache "Journal logs" "${path[1]}/log/journal"
clear_cache "DNF cache"

total=$(convert_to_SI $total)
add_to_log "Total" "$total" "✅"
printf "${CYAN}%s\n%-10s | ${GREEN}%s\n${CYAN}%s${NC}\n" "$DASHES" "Total" "$total" "$DASHES"