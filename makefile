# Native host build; the original basm build is make -f makefile.amiga.
VASM ?= $(HOME)/.local/vasmm68k_mot
WHDLOAD ?= $(HOME)/.local/share/amiga/WHDLoad
NDK ?= $(HOME)/.local/opt/m68k-amiga-elf/sys-include
PYTHON ?= python3
# WHDLoad resload_Relocate rejects vasm's compact HUNK_DREL32 records.
GAMEFLAGS = -m68000 -devpac -Fhunkexe -kick1hunks -nosym -DWHDLOAD=1
SLAVEFLAGS = -m68000 -pic -x -devpac -Fhunkexe -nosym -DHOSTBUILD=1
INCLUDES = -I"$(WHDLOAD)/Include" -I"$(NDK)"
GFX = $(wildcard gfx/*)

.PHONY: all clean dist distclean FORCE
.DELETE_ON_ERROR:
all: build/StuntCarRacer.slave build/StuntTrackRacer.slave

# Always rebuild: SDK/tool/option changes must not leave stale release binaries.
build/date: FORCE
	@mkdir -p build
	$(PYTHON) tools/build_date.py $@

build/StuntCarRacerWithoutData: StuntCarRacer.s FORCE | build/date
	"$(VASM)" $(GAMEFLAGS) -o $@ $<

build/StuntTrackRacerWithoutData: StuntCarRacer.s FORCE | build/date
	"$(VASM)" $(GAMEFLAGS) -DNTSC=1 -o $@ $<

build/StuntCarRacer.slave: StuntCarRacerSlave.s build/StuntCarRacerWithoutData build/date $(GFX)
	"$(VASM)" $(SLAVEFLAGS) $(INCLUDES) -o $@ $<

build/StuntTrackRacer.slave: StuntCarRacerSlave.s build/StuntTrackRacerWithoutData build/date $(GFX)
	"$(VASM)" $(SLAVEFLAGS) -DNTSC=1 $(INCLUDES) -o $@ $<

dist:
	./create_release.sh

clean:
	rm -rf build

distclean: clean
	rm -rf dist
