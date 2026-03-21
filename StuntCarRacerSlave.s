; Stunt Car Racer WHDLoad slave by Vesa Halttunen
; Based on example slave code by wepl

	INCDIR	"INCLUDE:"
	INCLUDE	"whdload.i"
	INCLUDE	"whdmacros.i"
	INCLUDE	"libraries/dos_lib.i"

	OUTPUT	"StuntCarRacer.slave"
	BOPT	O+
	BOPT	OG+
	BOPT	ODd-
	BOPT	ODe-
	BOPT	w4-
	BOPT	wo-
	SUPER

CHIPMEMSIZE	= $25000
FASTMEMSIZE	= $9e000
NUMDRIVES	= 1
WPDRIVES	= %0000
HDINIT
BOOTDOS

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	; F10

gameDataSize	equ	408544

	INCLUDE	"kick31.s"

	dc.b	"$VER: StuntCarRacer.slave 0.x (18.03.2026)",0

slv_CurrentDir:	dc.b	"Data",0
slv_name:		dc.b	"Stunt Car Racer",0
slv_copy:		dc.b	"1989 Geoff Crammond/Microstyle",0
slv_info:		dc.b	"Adapted by Vesa Halttunen",10
				dc.b	"Version 0.x (18.03.2026)",0
programName:	dc.b	"StuntCarRacer",0
args:			dc.b	10
argsEnd:		dc.b	0
				EVEN

_bootdos:
	move.l	_resload,a2
	lea	programName(pc),a3

	lea	_dosname(pc),a1
	move.l	4.w,a6
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,a6

	move.l	a3,d1
	jsr	_LVOLoadSeg(a6)
	tst.l	d0
	bne.s	.loadData

.readFailure:
	jsr	_LVOIoErr(a6)
	move.l	a3,-(sp)
	move.l	d0,-(sp)
	pea	TDREASON_DOSREAD
	move.l	_resload(pc),-(sp)
	add.l	#resload_Abort,(sp)
	rts

.loadData:
	add.l	d0,d0
	add.l	d0,d0
	addq	#4,d0
	move.l	d0,a4

	move.l	8(a4),a5
	lea	-4(a5),a0
	move.l	#$e898,d0
	move.l	#gameDataSize+4,d1
	moveq	#1,d2
	move.l	_resload(pc),a2
	jsr	resload_DiskLoad(a2)

	move.l	#(gameDataSize+4)>>2,d0
	move.l	#$c905b365,d5
	move.l	#$a0cff27b,d6
	move.l	#$59f3a592,d7
	lea	-4(a5),a0
	bsr	_Decrypt

	lea	args(pc),a0
	moveq	#argsEnd-args,d0
	jsr	(a4)

	move.l	_resload,a2
	pea	TDREASON_OK
	jmp	resload_Abort(a2)

patchList:
	PL_START
	PL_END

_Decrypt	movem.l	d0/d5-d7/a0,-(sp)	;Rob Northen Decryption (3 Key)
.DecryptLoop	lsl.l	#1,d7
		btst	d5,d7
		beq.s	.Skip1
		btst	d6,d7
		beq.s	.Skip3
		bra.s	.Skip2
.Skip1		btst	d6,d7
		beq.s	.Skip2
.Skip3		addq.l	#1,d7			;Modify key for correct btst otherwise fuckup!
.Skip2		add.l	d7,(a0)			;Modify key to encrypted data = correct data
		add.l	(a0)+,d7		;Modify key with next encrypted longword
		subq.l	#1,d0			;Subtract from counter until null
		bne.s	.DecryptLoop
		movem.l	(sp)+,d0/d5-d7/a0
		rts
	END
