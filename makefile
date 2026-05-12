BASENAME = StuntCarRacer
GAME = $(BASENAME)
GAME_WITHOUT_DATA = $(BASENAME)WithoutData
SLAVE = $(BASENAME).slave
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
GAME_WITHOUT_DATA_OPTS = -dWHDLOAD=1 $(COMMON_OPTS)
SLAVE_OPTS = -O+ -OG+ -ODd- -ODe- -w4- -wo- $(COMMON_OPTS)

all : $(GAME_WITHOUT_DATA) $(SLAVE)

$(GAME) : $(GAME_SOURCE)
	basm $(GAME_OPTS) -o$(GAME) $(GAME_SOURCE)

$(GAME_WITHOUT_DATA) : $(GAME_SOURCE)
	basm $(GAME_WITHOUT_DATA_OPTS) -o$(GAME_WITHOUT_DATA) $(GAME_SOURCE)

$(SLAVE) : $(SLAVE_SOURCE) $(GAME_WITHOUT_DATA)
	WDate >T:date
	basm $(SLAVE_OPTS) -o$(SLAVE) $(SLAVE_SOURCE)

clean:
	delete $(GAME) $(GAME_WITHOUT_DATA) $(SLAVE)
