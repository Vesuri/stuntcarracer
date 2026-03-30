; Stunt Car Racer WHDLoad slave by Vesa Halttunen

	incdir	"INCLUDE:"
	include	"whdload.i"
	include	"whdmacros.i"
	include	"libraries/dos_lib.i"

	OUTPUT	"StuntCarRacer.slave"
	BOPT	O+
	BOPT	OG+
	BOPT	ODd-
	BOPT	ODe-
	BOPT	w4-
	BOPT	wo-
	SUPER

CHIPMEMSIZE	= $25000
FASTMEMSIZE	= $a0000
NUMDRIVES	= 1
WPDRIVES	= %0000
HDINIT
BOOTDOS
CACHE

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	; F10

gameDataSize	equ	408416

		include	"kick31.s"

		dc.b	"$VER: StuntCarRacer.slave 0.x (30.03.2026)",0

slv_CurrentDir:	dc.b	0
slv_name:	dc.b	"Stunt Car Racer",0
slv_copy:	dc.b	"1989 Geoff Crammond/Microstyle",0
slv_info:	dc.b	"Adapted by Vesuri",10
		dc.b	"Work in progress (30.03.2026)",0
		even

_bootdos:
	move.l	_resload,a2

	lea	executable,a0
	jsr	_LoadSegFromBuffer
	tst.l	d0
	bne.s	.loadData

	pea	TDREASON_WRONGVER
	jmp	resload_Abort(a2)

.loadData:
	; _LoadSegFromBuffer returns a BPTR
	add.l	d0,d0
	add.l	d0,d0
	; Skip NextSeg
	addq	#4,d0

	; Set beginning of code to A4
	move.l	d0,a4

	; Get gameData BSS address from a lea gameData,a0 instruction
	move.l	8(a4),a5
	; Rob Northen requires one longword before the actual payload
	lea	-4(a5),a5

	; Load the encrypted game data 8192 bytes at a time
	move.l	a5,a3
	move.l	#$e898,d6
	move.l	#gameDataSize+4,d7
.readLoop:
	move.l	d6,d0
	move.l	d7,d1
	cmp.l	#$2000,d1
	bls.s	.sizeOk
	move.l	#$2000,d1
.sizeOk:
	moveq	#1,d2
	move.l	a3,a0
	lea	(a3,d1.w),a3
	add.l	d1,d6
	sub.l	d1,d7
	jsr	resload_DiskLoad(a2)
	tst.l	d7
	bne.s	.readLoop

	; Decrypt the game data
	move.l	#(gameDataSize+4)>>2,d0
	move.l	#$c905b365,d5
	move.l	#$a0cff27b,d6
	move.l	#$59f3a592,d7
	lea	-4(a5),a0
	bsr	_Decrypt

	jsr	resload_FlushCache(a2)

	; Start the game
	jsr	(a4)

	; Quit
	move.l	_resload,a2
	pea	TDREASON_OK
	jmp	resload_Abort(a2)

patchList:
	PL_START
	PL_END

_Decrypt:
	movem.l	d0/d5-d7/a0,-(sp)
.loop:	lsl.l	#1,d7
	btst	d5,d7
	beq.s	.skip1
	btst	d6,d7
	beq.s	.skip3
	bra.s	.skip2
.skip1:	btst	d6,d7
	beq.s	.skip2
.skip3:	addq.l	#1,d7
.skip2:	add.l	d7,(a0)
	add.l	(a0)+,d7
	subq.l	#1,d0
	bne.s	.loop
	movem.l	(sp)+,d0/d5-d7/a0
	rts

		include	"LoadSegFromBuffer.s"

executable:	incbin	"StuntCarRacer"
executableEnd:
executableSize	equ	(executableEnd-executable)
