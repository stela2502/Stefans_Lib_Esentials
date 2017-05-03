all:
	(cd Stefans_Libs_Essentials && perl Makefile.PL --defaultdeps)
	make -C Stefans_Libs_Essentials
install:
	make -C Stefans_Libs_Essentials install
