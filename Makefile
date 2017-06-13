all:
	(cd Stefans_Libs_Essentials && perl Makefile.PL --defaultdeps)
	make -C Stefans_Libs_Essentials
install:
	make -C Stefans_Libs_Essentials install
	perl -I Stefans_Libs_Essentials/lib Stefans_Libs_Essentials/bin/record_version.pl  -package 'Stefans_Libs_Essentials' -path ./
