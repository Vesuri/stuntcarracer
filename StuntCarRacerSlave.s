; Stunt Car Racer WHDLoad slave by Vesa Halttunen
; TODO
; - Load and save driver information to a separate file "StuntCarRacer.save"
; - Trainer (F6 to toggle infinite boost, F7 to win the race)
;   - Tooltype CUSTOM1=1 to automatically start with infinite boost
; - Load and save fastest lap and track times
; - Audio filter disable for clearer sound
; - Fire button to bypass name entry sequence

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

gameDataSize	equ	408540

		include	"kick31.s"

		dc.b	"$VER: StuntCarRacer.slave 0.x (12.04.2026)",0

slv_CurrentDir:	dc.b	0
slv_name:	dc.b	"Stunt Car Racer",0
slv_copy:	dc.b	"1989 Geoff Crammond/Microstyle",0
slv_info:	dc.b	"Adapted by Vesuri",10
		dc.b	"Work in progress (12.04.2026)",0
_PlayerName	dc.b	"Player      ",0
_TimesName	dc.b	"StuntCarRacer.times",0
_SaveName	dc.b	"StuntCarRacer.save",0
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
	move.l	2(a4),a5
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
	move.l	a5,a0
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
;	PL_PS	$f036,_Keybd		;Detect quit key: ror.b #1,d0 and eori.b #$ff,d0
;	PL_R	$59846			;Don't ask for floppy!
;	PL_PS	$5b6bc,_SkipPlayerName	;Allow fire to skip name entry
;	PL_L	$5b6c2,$4e714e71	;nop nop
;	PL_P	$5f2f8,_SaveTimes	;move.b ($1c947).l,(2,a1,d1.w)
;	PL_P	$62e86,_Loader		;Rob Northen loader
	PL_END

_SaveFileSize	dc.l	0

;======================================================================

_WinRace	move.b	#4,($1bb20).l		;Cheating bastard! :)
		rts

;======================================================================

_RefreshBoost	cmp.b	#0,$1ca20
		bne.b	_ToggleBoost
		move.b	#$80,($1ca20).l		;Lame trainer
_ToggleBoost	;eor.l	#$65000008~$4e714e71,$60836
		rts

;======================================================================

_SkipPlayerName	cmpi.b	#' ',(1,a0,d0.w)
		bne.b	.NotBlankName
		movem.l	d0/d1/a0/a1,-(sp)
		movea.l	a0,a1
		lea	_PlayerName(pc),a0
		moveq	#11,d1
.CopyPlayerName	move.b	(a0)+,(1,a1,d0.w)
		addq.l	#1,d0
		dbra	d1,.CopyPlayerName
		movem.l	(sp)+,d0/d1/a0/a1
.NotBlankName	rts

;======================================================================

_Keybd		ror.b	#1,d0			;Stolen 6 bytes
		eor.b	#$ff,d0
;		cmp.b	_keyexit(pc),d0
;		beq.w	_exit
		cmp.b	#$55,d0			;F6 = Refresh boost
		beq.w	_RefreshBoost
;		cmp.b	#$56,d0			;F7 = Switch turbo on/off
;		beq.w	_ToggleTurbo
		cmp.b	#$5f,d0			;Help = Win the race!
		beq.w	_WinRace
		rts

;======================================================================

_SaveTimes	move.b	($1c947).l,(2,a1,d1.w)	;Stolen code

		movem.l	d0-d1/a0-a2,-(sp)

		lea	_TimesName(pc),a0	;a0 = Name
		lea	$7a61a,a1		;a1 = Address
		move.l	#$200,d0		;d0 = Size
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)

		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Loader		movem.l	d1-d4/a0-a3,-(sp)

                move.l  _resload(pc),a2		;a0 = Address
		mulu	#$200,d1		;d1 = Offset
		mulu	#$200,d2		;d2 = Length
		cmp.l	#$dc00,d1		;Initial game load
		beq.b	_DiskLoad
		cmp.l	#$a00,d1		;When game starts, it loads this
		beq.b	_TimesLoad

		move.l	d2,d0			;d0 = Length
		move.l	a0,a1			;a1 = Source
		lea	_SaveName(pc),a0	;a0 = Name
		lea	_SaveFileSize(pc),a3	;a3 = Save game file size
		move.l	d1,d4
		add.l	d0,d4			;d4 = Minimum file size required
		cmp.w	#1,d3			;0 = read, 1 = write
		beq.b	_Save

		move.l	(a3),d3			;Check that the load operation
		cmp.l	d4,d3			;will work
		blt.b	_DiskOpDone

		jsr	resload_LoadFileOffset(a2)
		bra.b	_DiskOpDone

_Save		jsr	resload_SaveFileOffset(a2)

		cmp.l	(a3),d4
		blt.b	_DiskOpDone
		move.l	d4,(a3)			;Save new file length
		bra.b	_DiskOpDone

_DiskLoad	move.l	d1,d0			;d0 = offset (bytes)
		move.l	d2,d1			;d1 = length (bytes)
		moveq	#1,d2			;d2 = disk
		jsr	resload_DiskLoad(a2)	;a0 = destination

_DiskOpDone	movem.l	(sp)+,d1-d4/a0-a3
		moveq	#0,d0
		rts

_TimesLoad	move.l	a0,a1			;a1 = Source
		lea	_TimesName(pc),a0

		movem.l	d0-d1/a0-a1,-(sp)
		jsr	resload_GetFileSize(a2)
		move.l	d0,d3
		movem.l	(sp)+,d0-d1/a0-a1
		
		cmp.l	#$200,d3
		bne.b	_DiskOpDone

		jsr	resload_LoadFile(a2)
		bra.b	_DiskOpDone

;======================================================================

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

		include	"LoadSegFromBuffer.s"
executable:	incbin	"StuntCarRacer"
