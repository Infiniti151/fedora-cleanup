#!/usr/bin/bash

path=(/home/* /var)

clear_log(){
	if [ $(du -s ${path[0]}/clean.log | awk '{print $1}') -gt 12 ];then
	    > ${path[0]}/clean.log
	fi
}

convert_to_GB(){
    echo $1 | awk '{$1=$1/(1024^2); printf "%.2f %s\n", $1,"GB";}'
}

add_to_log(){
    echo -e "$1: $2" >> ${path[0]}/clean.log
}

calculate_GB(){
    fin=$(convert_to_GB $1)
}

calculate_total(){
    total=$((total + cache))
}

clear_cache(){
	case $1 in
		"Edge cache")
			cache=$(($(du -s $2 | awk '{print $1}') + $(du -s "$3" | awk '{print $1}') + $(du -s "$4" | awk '{print $1}') + $(du -s "$5" | awk '{print $1}') + $(du -c $6/*.blob | awk '/total/ {print $1}') + $(du -s "$7" | awk '{print $1}') + $(du -s $8 | awk '{print $1}')))
		;;
		"Code cache")
			cache=$(($(du -s $2 | awk '{print $1}') + $(du -s $3 | awk '{print $1}') + $(du -s $4 | awk '{print $1}') + $(du -s $5 | awk '{print $1}') + $(du -s $6 | awk '{print $1}')))
		;;
		*)
			cache=$(du -s $2 | awk '{print $1}')
		;;
	esac
	calculate_GB $cache
	if [ "$fin" != "0.00 GB" ];then
	        calculate_total
	        case $1 in
				"DNF cache")
					dnf clean all > /dev/null
				;;
				"Edge cache")
					rm -r $2/* "$3"/* "$4"/* "$5"/* "$7" 2>&1
					rm -rf $6/*.blob 2>&1
					sudo find $8/* -maxdepth 0 -type f -not -iname "en-US.pak" -exec rm -r {} \; 2>&1
				;;
				"Code cache")
					rm -rf $2/* $3/* $4/* $5/* $6/* 2>&1
				;;
				*)
					rm -rf $2/* 2>&1
				;;
			esac
		echo -e "Deleted \033[0;35m$1: \033[0;31m$fin\033[0m"
                add_to_log "$1" "$fin"
    fi
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
			   nvidia_cache=$(du -s $3/$i/$j | awk '{print $1}')
			   cache=$(($cache + $nvidia_cache))
			   sudo rm -rf "$3/$i/$j"
			   echo -e "Deleted \033[0;31m$j: \033[0;33m$(convert_to_GB $nvidia_cache $i)\033[0m"
			done
			add_to_log "$1-$i" $(convert_to_GB $cache)
			calculate_total
		fi
	done

	x=$(ls "$4" | grep "$2-" | wc -l)
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
				cuda_cache=$(du -s $4/$i | awk '{print $1}')
				cache=$(($cache + $cuda_cache))
				sudo rm -rf "$4/$i"
				echo -e "Deleted \033[0;31m$i: \033[0;33m$(convert_to_GB $cuda_cache)\033[0m"
			done
			add_to_log "$1-$2" $(convert_to_GB $cache)
			calculate_total
		fi
	fi
}

clear_log

echo "------$(date +'%d/%m/%y %r')------" >> ${path[0]}/clean.log

clear_cache "Thumbnails cache" "${path[0]}/.cache/thumbnails/x-large"
clear_cache "Pip cache" "${path[0]}/.cache/pip"
clear_cache "Edge cache" "${path[0]}/.cache/microsoft-edge/Default/Cache/Cache_Data" "${path[0]}/.cache/microsoft-edge/Default/Code Cache/js" "${path[0]}/.config/microsoft-edge/Default/Service Worker/CacheStorage" "${path[0]}/.config/microsoft-edge/Default/Service Worker/ScriptCache" "${path[0]}/.config/microsoft-edge/Default/IndexedDB" "${path[0]}/.config/microsoft-edge/Default/load_statistics.db" "/opt/microsoft/msedge/locales"
clear_cache "Code cache" "${path[0]}/.config/Code/CachedExtensionVSIXs" "${path[0]}/.config/Code/Cache/Cache_Data" "${path[0]}/.config/Code/User/workspaceStorage" "${path[0]}/.config/Code/CachedData" "${path[0]}/.config/Code/GPUCache"
clear_cache "Firefox cache" "${path[0]}/.cache/mozilla/firefox/$(ls ${path[0]}/.cache/mozilla/firefox)/cache2/entries"
clear_cache "DNF cache" "${path[1]}/cache/libdnf5"
clear_cache "Coredumps" "${path[1]}/lib/systemd/coredump"
clear_cache "Journal logs" "${path[1]}/log/journal"
clear_nvidia "Nvidia" "cuda" "/opt/nvidia" "/usr/local"

total=$(convert_to_GB $total)
add_to_log "--------------------------------\nTotal storage recovered" "$total"
echo -e "\nTotal storage recovered: \033[0;32m$total\033[0m"