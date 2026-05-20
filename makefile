BASENAME = StuntCarRacer
BASENAME_NTSC = StuntTrackRacer
GAME = $(BASENAME)
GAME_NTSC = $(BASENAME_NTSC)
GAME_WITHOUT_DATA = $(BASENAME)WithoutData
SLAVE = $(BASENAME).slave
GAME_NTSC_WITHOUT_DATA = $(BASENAME_NTSC)WithoutData
SLAVE_NTSC = $(BASENAME_NTSC).slave
GAME_SOURCE = $(BASENAME).s
SLAVE_SOURCE = $(BASENAME)Slave.s

#   O+      enable optimizer
#   OG+     enable global forward-reference optimizing
#   ODd-    disable mulu optimizing
#   ODe-    disable muls optimizing
#   w4-     disable 64k-access warnings
#   wo-     disable optimizing warnings
#   ws-     disable supervisor warnings (was SUPER)
COMMON_OPTS = -ws-
GAME_OPTS = -m1 $(COMMON_OPTS)
GAME_NTSC_OPTS = -m1 -dNTSC=1 $(COMMON_OPTS)
GAME_WITHOUT_DATA_OPTS = -dWHDLOAD=1 $(COMMON_OPTS)
GAME_NTSC_WITHOUT_DATA_OPTS = -dWHDLOAD=1 -dNTSC=1 $(COMMON_OPTS)
SLAVE_OPTS = -O+ -OG+ -ODd- -ODe- -w4- -wo- $(COMMON_OPTS)
SLAVE_NTSC_OPTS = -O+ -OG+ -ODd- -ODe- -w4- -wo- -dNTSC=1 $(COMMON_OPTS)

all : $(GAME_WITHOUT_DATA) $(SLAVE) $(GAME_NTSC_WITHOUT_DATA) $(SLAVE_NTSC)

$(GAME) : $(GAME_SOURCE)
	basm $(GAME_OPTS) -o$(GAME) $(GAME_SOURCE)

$(GAME_NTSC) : $(GAME_SOURCE)
	basm $(GAME_NTSC_OPTS) -o$(GAME_NTSC) $(GAME_SOURCE)

$(GAME_WITHOUT_DATA) : $(GAME_SOURCE)
	basm $(GAME_WITHOUT_DATA_OPTS) -o$(GAME_WITHOUT_DATA) $(GAME_SOURCE)

$(GAME_NTSC_WITHOUT_DATA) : $(GAME_SOURCE)
	basm $(GAME_NTSC_WITHOUT_DATA_OPTS) -o$(GAME_NTSC_WITHOUT_DATA) $(GAME_SOURCE)

$(SLAVE) : $(SLAVE_SOURCE) $(GAME_WITHOUT_DATA)
	WDate >T:date
	basm $(SLAVE_OPTS) -o$(SLAVE) $(SLAVE_SOURCE)

$(SLAVE_NTSC) : $(SLAVE_SOURCE) $(GAME_NTSC_WITHOUT_DATA)
	WDate >T:date
	basm $(SLAVE_NTSC_OPTS) -o$(SLAVE_NTSC) $(SLAVE_SOURCE)

clean:
	delete $(GAME) $(GAME_NTSC) $(GAME_WITHOUT_DATA) $(GAME_NTSC_WITHOUT_DATA) $(SLAVE) $(SLAVE_NTSC)
