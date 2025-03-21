# 🧹 fedora-cleanup

A cleanup script to clear caches and logs in Fedora (Tested in Fedora 41)

---

## 📝 List of caches
This script cleans the following:
1. Thumbnails cache ($HOME/.cache/thumbnails/x-large)
2. Pip cache ($HOME/.cache/pip)
3. Microsoft Edge cache ($HOME/.cache/microsoft-edge/Default/Cache/Cache_Data, $HOME/.cache/microsoft-edge/Default/Code Cache/js, $HOME/.config/microsoft-edge/Default/Service Worker/CacheStorage, $HOME/.config/microsoft-edge/Default/Service Worker/ScriptCache, $HOME/.config/microsoft-edge/Default/IndexedDB, $HOME/.config/microsoft-edge/Default/load_statistics.db, /opt/microsoft/msedge/locales)
4. VS Code cache ($HOME/.config/Code/CachedExtensionVSIXs, $HOME/.config/Code/Cache/Cache_Data, $HOME/.config/Code/User/workspaceStorage, $HOME/.config/Code/CachedData, $HOME/.config/Code/GPUCache)
5. Firefox cache ($HOME/.cache/mozilla/firefox/*/cache2/entries)
6. DNF5 cache (/var/cache/libdnf5)
7. Coredumps (/var/lib/systemd/coredump)
8. Journal logs (/var/log/journal)
9. Old Nvidia nsight-compute folders (/opt/Nvidia/nsight-compute/xxxx.x.x)
10. Old Nvidia nsight-systems folders (/opt/Nvidia/nsight-systems/xxxx.x.x)
11. Old Nvidia CUDA folders (/usr/local/cuda-xx.x)

---

## 📒 Notes
1. Needs to be run as sudo to delete files in /var, /opt, and /usr
2. Logs are stored in $HOME/clean.log

---

## 🖥️ Screenshots
Terminal screenshot:
![alt text](/images/terminal.png)

Log screenshot:
![alt text](/images/log.png)

