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
	bne.s	.checkVersion

.readFailure:
	jsr	_LVOIoErr(a6)
	move.l	a3,-(sp)
	move.l	d0,-(sp)
	pea	TDREASON_DOSREAD
	move.l	_resload(pc),-(sp)
	add.l	#resload_Abort,(sp)
	rts

.checkVersion:
	add.l	d0,d0
	add.l	d0,d0
	addq	#4,d0
	move.l	d0,a4

	lea	args(pc),a0
	move.l	4(sp),d0
	sub.l	#5*4,d0
	moveq	#argsEnd-args,d0
	jsr	(a4)

	move.l	_resload,a2
	pea	TDREASON_OK
	jmp	resload_Abort(a2)

patchList:
	PL_START
	PL_END

	END
