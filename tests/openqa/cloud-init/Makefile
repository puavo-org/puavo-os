all: debian-cloud-init.iso

debian-cloud-init.iso: user-data meta-data network-config
	genisoimage -output $@ -volid cidata -input-charset utf-8 -joliet \
	  -rock $^

user-data: debian-cloud-init-ssh-key

debian-cloud-init-ssh-key:
	ssh-keygen -t ed25519 -N '' -f debian-cloud-init-ssh-key

.PHONY: install
install:
	install -o root -g geekotest -m 644 debian-cloud-init.iso \
	    /var/lib/openqa/share/factory/iso/debian-cloud-init.iso
