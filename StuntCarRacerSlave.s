; Stunt Car Racer WHDLoad slave by Vesa Halttunen
	incdir	"INCLUDE:"
	include	"whdload.i"
	include	"whdmacros.i"
	include	"libraries/dos_lib.i"

	IFD BARFLY
	OUTPUT	"StuntCarRacer.slave"
	BOPT	O+
	BOPT	OG+
	BOPT	ODd-
	BOPT	ODe-
	BOPT	w4-
	BOPT	wo-
	SUPER
	ENDC

gameDataSize	equ	408540
expMemSize	equ	$88000			; $87054

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_EmulTrap|WHDLF_NoError	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	expMemSize		;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	.config-_base		;ws_config

.config		dc.b	"C1:B:Infinite Boost;"
		dc.b	0

;============================================================================

_name		dc.b	"Stunt Car Racer",0
_copy		dc.b	"1989 Geoff Crammond/Microstyle",0
_info		dc.b	"Adapted by Vesuri",10
		dc.b	"Work in progress "
		IFD	BARFLY
		IFND	.passchk
		DOSCMD	"WDate >T:date"
.passchk
		ENDC
		INCBIN	"T:date"
		ELSE
		dc.b	"(04.05.2026)"
		ENDC
		dc.b	-1,"This slave is partially based on the work by"
		dc.b	10,"Codetapper/Action! & StingRay."
		dc.b	-1,"Thanks to Harry, Carlo Pirri, AmiGer/CARE,"
		dc.b	10,"Galahad and Frank for the great icons!"
		dc.b	-1,"F6: Toggle infinite boost"
		dc.b	10,"Help: Win race"
		dc.b	0
_TimesName	dc.b	"StuntCarRacer.times",0
_SaveName	dc.b	"StuntCarRacer.save",0
		dc.b	"$VER: StuntCarRacer.slave 0.x (04.05.2026)",0
		EVEN

;======================================================================
_Start						;A0 = resident loader
;======================================================================
	lea	_resload(pc),a1
	move.l	a0,(a1)			;Save for later use

	move.l	a0,a2			;Check parameters
	lea	_Tags(pc),a0
	jsr	resload_Control(a2)

	lea	executable,a0
	move.l	_expmem(pc),a1
	move.l	a1,a5
	move.l	#executableSize/4-1,d1
.copy:	move.l	(a0)+,(a1)+
	dbra	d1,.copy

	move.l	a5,d0
	add.l	#expMemSize,d0
	move.l	d0,sp

	move.l	_resload(pc),a2
	move.l	a5,a0
	clr.l	-(sp)
	move.l	_ChipPtr(pc),-(sp)
	pea     WHDLTAG_CHIPPTR
	pea     -1
	pea     WHDLTAG_LOADSEG
	move.l  sp,a1
	jsr	resload_Relocate(a2)
	lea	5*4(sp),sp

	; Get code base address (first hunk address + 8)
	lea	8(a5),a4

	; Get gameData base address from a lea gameData,a0 instruction
	move.l	2(a4),a5

	; Store hook addresses and parameters
	move.l	a5,a3
	add.l	#gameDataSize,a3
	lea	_SaveTimes(pc),a0
	move.l	a0,(a3)+
	lea	_Loader(pc),a0
	move.l	a0,(a3)+
	lea	_Custom1(pc),a0
	move.l	(a0),(a3)+

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

	; Store save filesize
	lea     _SaveName(pc),a0
	jsr     resload_GetFileSize(a2)
	lea     _SaveFileSize(pc),a0
	move.l  d0,(a0)

	; Disable filter
	bset	#1,$bfe001

	; Start the game
	jsr	(a4)

	; Quit
	move.l	_resload,a2
	pea	TDREASON_OK
	jmp	resload_Abort(a2)

_resload	dc.l	0			;Resident loader
_Tags		dc.l	WHDLTAG_CUSTOM1_GET
_Custom1	dc.l	0
		dc.l	TAG_DONE
_SaveFileSize	dc.l	0
_ChipPtr	dc.l	$800

;======================================================================

_SaveTimes	movem.l	d0-d1/a0,-(sp)		;a1 = Address

		lea	_TimesName(pc),a0	;a0 = Name
		move.l	#$200,d0		;d0 = Size
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)

		movem.l	(sp)+,d0-d1/a0
		rts

;======================================================================

_Loader		movem.l	d1-d4/a0-a3,-(sp)

                move.l  _resload(pc),a2		;a0 = Address
		mulu	#$200,d1		;d1 = Offset
		mulu	#$200,d2		;d2 = Length
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

_DiskOpDone	movem.l	(sp)+,d1-d4/a0-a3
		moveq	#0,d0
		rts

_TimesLoad	add.l	a0,a1			;a1 = Source
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

executable:	incbin	"StuntCarRacer"
executableSize	equ	*-executable
