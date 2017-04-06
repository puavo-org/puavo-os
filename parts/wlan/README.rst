============
 Puavo WLAN
============

Puavo WLAN is a software project aimed at providing remotely managed and
monitored 802.11 network system, as a part of Puavo technology stack. Puavo WLAN
consist of several components:

- accesspoint
- gateway
- controller
- mapper

Accesspoint and gateway are the only mandatory components and they form the
basic Puavo WLAN system. Gateways operate at the edge of the network, they act
as bridges and connect multiple accesspoints together. Accesspoints are
connected to gateways via VTun tunnels. All 802.11 traffic is encapsulated in
unencrypted UDP datagrams.

Controller and mapper are optional components; they can be deployed to enhance
the system. Controller is a bit confusing name at the moment; controller is
currently just a data collector, which receives periodic and event triggered
status reports from accesspoints. It does *not* control accesspoints in any way,
it just gathers status reports and stores them temporarily in Redis.

Mapper is poor man's site survey tool. Currently, it does not have any Puavo
integration; it is totally independent tool used for scanning nearby
accesspoints and for graphing coverage heat maps based on signal strengths.

=============
 Accesspoint
=============

Acesspoint is the basic building block of Puavo WLAN networks. It uses

- hostapd for providing the actual IEEE 802.11 accesspoint
- vtund for connecting accesspoint to the gateway
- horst for monitoring RSSIs of connected stations

To run accesspoint, simply run::

  sudo puavo-wlanap

Note that puavo-wlanap expects that system-udevd does not change interface
names.  /etc/systemd/network/99-default.link should be a symbolic link
to /dev/null or some equivalent configuration should be used.  Update
initrd as well ("update-initramfs -u -k all").
