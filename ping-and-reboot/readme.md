# ICMP Ping and Reboot 

Some of our Unifi devices have an uptime of more than 2 years or more than 100 days between updates. This script first pings the devices and then restarts them via ssh when they are online.
Since we have the devices at different sites, we use a jump host that can reach the individual sites via site-2-site VPN. The settings for the management networks must be made in the networks.txt.

There is a pause between reboots so that the switches can be fully booted up again. The gateway with the .1 at the end is not automatically restarted.