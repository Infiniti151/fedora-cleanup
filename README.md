# fedora-cleanup

A cleanup script to clear caches and logs in Fedora (Tested in Fedora 41)

This script cleans the following:
1. Thumbnails cache ($HOME/.cache/thumbnails/x-large)
2. Microsoft Edge cache ($HOME/.cache/microsoft-edge/Default/Cache/Cache_Data and $HOME/.cache/microsoft-edge/Default/Code Cache/js)
3. Firefox cache ($HOME/.cache/mozilla/firefox/*/cache2/entries)
4. DNF5 cache (/var/cache/libdnf5)
5. Coredumps (/var/lib/systemd/coredump)
6. Journal logs (/var/log/journal)
7. Old Nvidia nsight-compute folders (/opt/Nvidia/nsight-compute/xxxx.x.x)
8. Old Nvidia nsight-systems folders (/opt/Nvidia/nsight-systems/xxxx.x.x)
9. Old Nvidia CUDA folders (/usr/local/cuda-xx.x)

Notes:
1. Needs to be run as sudo to delete files in /var, /opt, and /usr
2. Logs are stored in ~/clean.log

Terminal screenshot:
![alt text](/images/terminal.png)

Log screenshot:
![alt text](/images/log.png)


