.DELETE_ON_ERROR: ImageBuildMakefile
ImageBuildMakefile: images.json
	puavo-build-image --images-config $< --output-makefile > $@

include ImageBuildMakefile
