all: debian-cloud-init.iso

debian-cloud-init.iso: user-data meta-data network-config
	genisoimage -output $@ -volid cidata -input-charset utf-8 -joliet \
	  -rock $^

.PHONY: install
install:
	install -o root -g geekotest -m 644 debian-cloud-init.iso \
	    /var/lib/openqa/share/factory/iso/debian-cloud-init.iso
