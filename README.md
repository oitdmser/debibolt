# Debibolt



A cousin for Staticus' raspibolt script for showing bitcoind &amp; lnd status as well as memory and hdd usage. His script is detailed in his guide here: https://stadicus.github.io/RaspiBolt/raspibolt_61_system-overview.html. Used and tested on Debian Stretch (9.5)

Some key changes made to make the script more useful on a generic Debian install versus the custom Debian Stretch version (Raspbian) on Raspberry Pis:
- The lncli and bitcoin-cli calls now use rpc username/password combo generated using rpcauth.py. This is to allow for use of the script in environements where bitcoind, lnd and the user running the script are different users on the same system or on different physical systems.  (https://github.com/bitcoin/bitcoin/tree/master/share/rpcauth)
- Changed to Debian ASCII logo
- Changed CPU temp to farenheit from celcius for us 'Mericans. On my to-do  list is to make this user-configurable.
- Changed the SSD and HDD sections on raspibolt to / and /var. This change was made assuming bitcoind data is stored in /var and that /var is a separate disk.
- In Bitcoin info column added "Last Block" and "Peers"
Future iterations will include an installation guide similar to Staticus' 
