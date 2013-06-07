.PHONY: precise quantal

all: precise quantal

precise: IMAGELIST.precise
	@./build_image_rdiffs $^

quantal: IMAGELIST.quantal
	@./build_image_rdiffs $^

clean:
	rm -f CKSUMS *.cksum *.rdiff *.rdiff_signature
