# kimsufi-availability
This repository contains a script parsing the OVH avilability api and executing an action when the specified offer is available.

# Usage
./kimsufi-availability.rb [options]
 -    -v, --[no-]verbose               Run verbosely.
 -    -l, --loop N                     When this option is set, the script will check the OVH API every N seconds.
 -    -o, --offers x,y,z               List offers to watch in the list ["KS-1", "KS-2", "KS-2 SSD", "KS-3", "KS-4", "KS-5", "KS-6"].
 -    -c, --commands x,y,z             List of commands to execute on offer availability (firefox https://www.kimsufi.com/fr/commande/kimsufi.xml?reference=150sk10).
 -    -p, --proxy [addr:port]          Addresse of the proxy server to use to request ovh api.
 -    -u, --user [user]                User to use for proxy authentification. Password will be asked dynamically.
