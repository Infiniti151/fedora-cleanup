# 🧹 fedora-cleanup

A cleanup script to clear caches and logs in Fedora (Tested in Fedora 43 Workstation). Prints the components cleared in the terminal along with the total storage recovered. Also logs every cleanup with a timestamp.

---

## 📝 List of caches
This script cleans the following:
1. Thumbnails cache ($HOME/.cache/thumbnails)
2. Pip cache ($HOME/.cache/pip)
3. Microsoft Edge cache ($HOME/.cache/microsoft-edge/Default/Cache/Cache_Data, $HOME/.cache/microsoft-edge/Default/Code Cache/js, $HOME/.config/microsoft-edge/Default/Service Worker/CacheStorage, $HOME/.config/microsoft-edge/Default/Service Worker/ScriptCache, $HOME/.config/microsoft-edge/Default/IndexedDB, $HOME/.config/microsoft-edge/Default/load_statistics.db, /opt/microsoft/msedge/locales)
4. VS Code cache ($HOME/.config/Code/CachedExtensionVSIXs, $HOME/.config/Code/Cache/Cache_Data, $HOME/.config/Code/User/workspaceStorage, $HOME/.config/Code/CachedData, $HOME/.config/Code/GPUCache)
5. Firefox cache ($HOME/.cache/mozilla/firefox/*/cache2/entries)
6. Librewolf cache ($HOME/.cache/librewolf/*/cache2/entries)
7. Wine cache ($HOME/.cache/wine)
8. GLCache ($HOME/.cache/nvidia/GLCache)
9. Akmods cache (/var/cache/akmods)
10. DNF5 cache (/var/cache/libdnf5)
11. Coredumps (/var/lib/systemd/coredump)
12. Journal logs (/var/log/journal)
13. Nvidia nsight-compute (/opt/Nvidia/nsight-compute/xxxx.x.x)
14. Nvidia nsight-systems (/opt/Nvidia/nsight-systems/xxxx.x.x)
15. Nvidia CUDA (/usr/local/cuda-xx.x)
---

## 📒 Notes
1. Needs to be run as sudo to delete files in /var, /opt, and /usr
2. Logs are stored in $HOME/clean.log
3. For CUDA, nsight-systems, and nsight-compute, the script deletes older version folders and only keeps the latest version

---

## 🖥️ Screenshots

![alt text](/images/terminal.png)
Terminal


![alt text](/images/log.png)
Log

