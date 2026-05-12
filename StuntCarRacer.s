	ifnd	WHDLOAD
WHDLOAD				equ	0
	endc

FRAMERATE_MULTIPLIER		equ	6				; 8FPS -> 48FPS
TIMESTEP_FACTOR			equ	$EE/FRAMERATE_MULTIPLIER	; originally $EE
MAJOR_IMPACT_COOLDOWN_TIME	equ	$FF				; originally $45

	section	Code,code

	ifeq	WHDLOAD
startup:
	move.l	sp,sp_quit

	; Open libraries
	move.l	4.w,a6
	moveq	#0,d0
	lea	name_graphics,a1
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,base_graphics
	beq	startupFailure

	jsr	_LVOForbid(a6)

	; Get Vector Base Register
	move.w	AttnFlags(a6),d0
	beq	.no680x0
	lea	GetVBR(pc),a5
	jsr	_LVOSuperVisor(a6)
.no680x0:

	; Store old values
	move.l	base_vector,a5
	move.l	base_graphics,a6
	move.l	gb_ActiView(a6),gb_ActiView_old
	move.l 	gb_copinit(a6),gb_copinit_old
	move.l	tv_Lev1IntVect(a5),tv_Lev1IntVect_old
	move.l	tv_Lev2IntVect(a5),tv_Lev2IntVect_old
	move.l	tv_Lev3IntVect(a5),tv_Lev3IntVect_old
	move.l	tv_Lev4IntVect(a5),tv_Lev4IntVect_old
	move.l	tv_Lev5IntVect(a5),tv_Lev5IntVect_old
	move.l	tv_Lev6IntVect(a5),tv_Lev6IntVect_old
	move.l	tv_Lev7IntVect(a5),tv_Lev7IntVect_old
	sub.l	a1,a1
	jsr	_LVOLoadView(a6)
	jsr	_LVOWaitTOF(a6)
	jsr	_LVOWaitTOF(a6)

	lea	_custom,a6
	move.w	dmaconr(a6),dmaconr_old
	move.w	intenar(a6),intenar_old
	move.b	_ciaa+ciacra,ciaacra_old
	move.b	_ciaa+ciacrb,ciaacrb_old
	move.b	_ciab+ciacra,ciabcra_old
	move.b	_ciab+ciacrb,ciabcrb_old
	move.w	#DMAF_BLITHOG|DMAF_ALL,dmacon(a6)
	move.w	#$ffff-INTF_SETCLR,intena(a6)
	bra	begin

startupFailure:
	moveq	#1,d0
	rts

shutdown:
	bsr	disableAudio

	; Disable interrupts and DMA
	lea	_custom,a6
	move.w	#INTF_BLIT|INTF_VERTB,intreq(a6)
	move.w	#INTF_BLIT|INTF_VERTB,intreq(a6)
	move.w	#$ffff-INTF_SETCLR,intena(a6)
	move.w	#DMAF_COPPER,dmacon(a6)

	; Restore old values
	move.l	gb_copinit_old,cop1lch(a6)
	clr.w	copjmp1(a6)
	move.l	base_vector,a5
	move.b	ciaacra_old,_ciaa+ciacra
	move.b	ciaacrb_old,_ciaa+ciacrb
	move.b	ciabcra_old,_ciab+ciacra
	move.b	ciabcrb_old,_ciab+ciacrb
	move.w	#DMAF_SETCLR|DMAF_COPPER,dmacon(a6)
	move.l	tv_Lev1IntVect_old,tv_Lev1IntVect(a5)
	move.l	tv_Lev2IntVect_old,tv_Lev2IntVect(a5)
	move.l	tv_Lev3IntVect_old,tv_Lev3IntVect(a5)
	move.l	tv_Lev4IntVect_old,tv_Lev4IntVect(a5)
	move.l	tv_Lev5IntVect_old,tv_Lev5IntVect(a5)
	move.l	tv_Lev6IntVect_old,tv_Lev6IntVect(a5)
	move.l	tv_Lev7IntVect_old,tv_Lev7IntVect(a5)
	move.w	dmaconr_old,d0
	or.w	#DMAF_SETCLR,d0
	move.w	d0,dmacon(a6)
	move.w	intenar_old,d0
	or.w	#INTF_SETCLR|INTF_INTEN,d0
	move.w	d0,intena(a6)
	move.l	base_graphics,a6
	move.l	gb_ActiView_old,a1
	jsr	_LVOLoadView(a6)
	jsr	_LVOWaitTOF(a6)
	jsr	_LVOWaitTOF(a6)

	move.l	4.w,a6
	jsr	_LVOPermit(a6)
	tst.l	base_graphics
	beq.b	.nobase_graphics
	move.l	base_graphics,a1
	jsr	_LVOCloseLibrary(a6)
.nobase_graphics:
	moveq	#0,d0
	rts

GetVBR:	ORI	#$0700,SR
	movec	vbr,d0
	move.l	d0,base_vector
	RTE

setQuitOnRMB:
	btst	#10,$dff016
	bne.s	.noQuit
	move.b	#1,quit
.noQuit:
	rts

testQuit:
	tst.b	quit
	bne.s	doQuit
	rts
doQuit:	move.l	sp_quit,sp
	jmp	shutdown
	endc

begin:	lea	gameData,a0
        sub.l   #ORIGINAL_LOAD_ADDRESS,a0
	add.l	sampleParameterTable,a0
	lea	sampleData,a1
	move.w	#downsampledEngineData-sampleData-1,d7
.copySampleData:
	move.b	(a0)+,(a1)+
	dbra	d7,.copySampleData

	move.l	sampleParameterTable,d0
	neg.l	d0
	add.l	#sampleData,d0
	lea	sampleParameterTable,a0
	add.l	d0,0*16(a0)
	add.l	d0,1*16(a0)
	add.l	d0,2*16(a0)
	add.l	d0,3*16(a0)
	add.l	d0,4*16(a0)
	add.l	d0,5*16(a0)
	add.l	d0,6*16(a0)

	JSR	initialize
	JMP	initializeGameMemoryAndState

initialize:
;	MOVE.W	#$2700,SR
	MOVE.W	#(INTF_TBE|INTF_DSKBLK|INTF_SOFTINT|INTF_PORTS|INTF_COPER|INTF_VERTB|INTF_BLIT|INTF_AUD0|INTF_AUD1|INTF_AUD2|INTF_AUD3|INTF_RBF|INTF_DSKSYNC|INTF_EXTER|INTF_INTEN),_custom+intena
	MOVE.W	#(INTF_TBE|INTF_DSKBLK|INTF_SOFTINT|INTF_PORTS|INTF_COPER|INTF_VERTB|INTF_BLIT|INTF_AUD0|INTF_AUD1|INTF_AUD2|INTF_AUD3|INTF_RBF|INTF_DSKSYNC|INTF_EXTER|INTF_INTEN),_custom+intreq
	MOVE.W	#(INTF_TBE|INTF_PORTS|INTF_COPER|INTF_VERTB|INTF_RBF|INTF_EXTER|INTF_INTEN|INTF_SETCLR),_custom+intena
	MOVE.W	#(DMAF_AUD0|DMAF_AUD1|DMAF_AUD2|DMAF_AUD3|DMAF_AUDIO|DMAF_DISK|DMAF_BLITTER|DMAF_COPPER|DMAF_BLITHOG|DMAF_BLTNZERO|DMAF_BLTDONE|$00001800),_custom+dmacon
	move.l	base_vector,a5
	MOVE.L	#level1Interrupt,tv_Lev1IntVect(a5)
	MOVE.L	#level2Interrupt,tv_Lev2IntVect(a5)
	MOVE.L	#level3Interrupt,tv_Lev3IntVect(a5)
	MOVE.L	#level4Interrupt,tv_Lev4IntVect(a5)
	MOVE.L	#level5Interrupt,tv_Lev5IntVect(a5)
	MOVE.L	#level6Interrupt,tv_Lev6IntVect(a5)
	MOVE.L	#level7Interrupt,tv_Lev7IntVect(a5)
;	MOVE.W	#$2000,SR
	MOVE.L	#frameBuffer1,D0			; originally lbL05BE94
	MOVE.L	D0,frameBuffers
	MOVE.L	D0,renderFrameBuffer
	ADD.L	#$00007D00,D0
	MOVE.L	D0,displayFrameBuffer
	JSR	setupFrameBufferAddresses
	JSR	initializeSpritePointers
	JSR	loadPaletteColors
	MOVE.W	#$4200,_custom+bplcon0
	MOVE.W	#$3C81,_custom+diwstrt
	MOVE.W	#$04C1,_custom+diwstop
	MOVE.W	#$003C,spriteYOffset
	MOVE.W	#$0038,_custom+ddfstrt
	MOVE.W	#$00D0,_custom+ddfstop
	MOVE.W	#$0000,_custom+bpl1mod
	MOVE.W	#$0000,_custom+bpl2mod
	MOVE.W	#$0000,_custom+bplcon1
	MOVE.W	#$0024,_custom+bplcon2
	move.w	#$0020,_custom+beamcon0
	MOVE.L	#copperlistStart,A0
	MOVE.L	A0,_custom+cop1lc
	MOVE.W	_custom+copjmp1,D0
	MOVE.W	#(DMAF_COPPER|DMAF_RASTER|DMAF_MASTER|DMAF_SETCLR),_custom+dmacon
	JSR	initializeCIA
	MOVE.L	#sampleData,A0
	MOVE.L	#downsampledEngineData,A2
eorSamplesLoop:
	EOR.B	#$80,(A0)+
	CMP.L	A2,A0
	BLT	eorSamplesLoop
	MOVE.W	#$00FF,_custom+adkcon
	JSR	generateEngineSamples
	RTS

initializeCIA:
	LEA	_ciaa,A0
	MOVE.B	#CIACRAF_RUNMODE,ciacra(A0)
	MOVE.B	#CIACRBF_RUNMODE,ciacrb(A0)
	MOVE.B	#(CIAICRF_TA|CIAICRF_ALRM|CIAICRF_FLG|$00000060),ciaicr(A0)
	MOVE.B	#(CIAICRF_TB|CIAICRF_SP|CIAICRF_SETCLR),ciaicr(A0)
	LEA	_ciab,A0
	MOVE.B	#CIACRAF_RUNMODE,ciacra(A0)
	MOVE.B	#CIACRBF_RUNMODE,ciacrb(A0)
	MOVE.B	#(CIAICRF_TA|CIAICRF_ALRM|CIAICRF_SP|CIAICRF_FLG|$00000060),ciaicr(A0)
	MOVE.B	#(CIAICRF_TB|CIAICRF_SETCLR),ciaicr(A0)
	RTS

level1Interrupt:
	BTST	#INTB_TBE,_custom+intreqr+1
	BEQ	noSerialInterrupt
	JSR	serialTransmitEmptyInterrupt
	MOVE.W	#INTF_TBE,_custom+intreq
	RTE

noSerialInterrupt:
	BTST	#INTB_DSKBLK,_custom+intreqr+1
	BEQ	noDiskBlockInterrupt
	JSR	diskBlockInterrupt
	MOVE.W	#INTF_DSKBLK,_custom+intreq
	RTE

noDiskBlockInterrupt:
	MOVE.W	#INTF_SOFTINT,_custom+intreq
	RTE

level2Interrupt:
	JSR	ciaAInterrupt
	MOVE.W	#INTF_PORTS,_custom+intreq
	RTE

level3Interrupt:
	ifeq	WHDLOAD
	bsr	setQuitOnRMB
	endc
	BTST	#INTB_COPER,_custom+intreqr+1
	BEQ	noCopperInterrupt
	JSR	copperInterrupt
	MOVE.W	#INTF_COPER,_custom+intreq
noCopperInterrupt:
	BTST	#INTB_VERTB,_custom+intreqr+1
	BEQ	noVerticalBlankInterrupt
	JSR	verticalBlankInterrupt
	MOVE.W	#INTF_VERTB,_custom+intreq
	RTE

noVerticalBlankInterrupt:
	MOVE.W	#INTF_BLIT,_custom+intreq
	RTE

level4Interrupt:
	BTST	#INTB_AUD0,_custom+intreqr+1
	BEQ	noAudioChannel0Interrupt
	JSR	audioChannel0Interrupt
	MOVE.W	#INTF_AUD0,_custom+intreq
noAudioChannel0Interrupt:
	BTST	#$00,_custom+intreqr
	BEQ	noAudioChannel1Interrupt
	JSR	audioChannel1Interrupt
	MOVE.W	#INTF_AUD1,_custom+intreq
noAudioChannel1Interrupt:
	BTST	#$01,_custom+intreqr
	BEQ	noAudioChannel2Interrupt
	JSR	audioChannel2Interrupt
	MOVE.W	#INTF_AUD2,_custom+intreq
noAudioChannel2Interrupt:
	BTST	#$02,_custom+intreqr
	BEQ	noAudioChannel3Interrupt
	JSR	audioChannel3Interrupt
	MOVE.W	#INTF_AUD3,_custom+intreq
noAudioChannel3Interrupt:
	RTE

level5Interrupt:
	BTST	#$03,_custom+intreqr
	BEQ	noSerialReceiveFullInterrupt
	JSR	serialReceiveFullInterrupt
	MOVE.W	#INTF_RBF,_custom+intreq
	RTE

noSerialReceiveFullInterrupt:
	JSR	diskSyncInterrupt
	MOVE.W	#INTF_DSKSYNC,_custom+intreq
	RTE

level6Interrupt:
	JSR	ciaBInterrupt
	MOVE.W	#INTF_EXTER,_custom+intreq
	RTE

level7Interrupt:
	RTE

ciaAInterrupt:
	MOVEM.L	D0/A0/A3,-(SP)
	LEA	_ciaa,A3
	MOVE.B	ciaicr(A3),D0
	BPL	ciaAInterruptDone
	BTST	#$01,D0
	BEQ	ciaATimerBDone
	CLR.B	ciaTimerFlag
ciaATimerBDone:
	BTST	#$03,D0
	BEQ	ciaAInterruptDone
	MOVE.L	#keyboardState,A0
	CLR.W	D0
	MOVE.B	ciasdr(A3),D0
	ROR.B	#$01,D0
	EOR.B	#$FF,D0
	cmp.b	#$55,d0			; added F6 = Refresh boost
	beq.s	refreshBoost
	cmp.b	#$5f,d0			; Help = Win the race!
	beq.s	winRace
	CMP.B	#$F0,D0
	BCC	lbC00095E
	TST.B	D0
	BPL	lbC000958
	AND.B	#$7F,D0
	MOVE.B	#$00,$00(A0,D0.W)
	BRA	lbC00095E

refreshBoost:
	tst.b	boostFuelLevel
	bne.s	.toggleBoost
	move.b	maxBoostFuel,boostFuelLevel	;Lame trainer
.toggleBoost:
	eor.l	#1,infiniteBoost
	bra	lbC00095E

winRace:
	move.b	#4,player1LapCounter		;Cheating bastard! :)
	bra	lbC00095E

lbC000958:
	MOVE.B	#$B3,$00(A0,D0.W)
lbC00095E:
	JSR	setCIABTimerB
ciaAInterruptDone:
	MOVEM.L	(SP)+,D0/A0/A3
	RTS

setCIABTimerB:
	TST.B	ciaBTimerBSet
	BNE	ciaBTimerBDone
	MOVE.B	#$80,ciaBTimerBSet
	LEA	_ciaa,A0
	BSET	#$06,ciacra(A0)
	LEA	_ciab,A0
	MOVE.B	#$08,ciacrb(A0)
	MOVE.B	#$82,ciaicr(A0)
	MOVE.B	#$B0,ciatblo(A0)
	MOVE.B	#$00,ciatbhi(A0)
ciaBTimerBDone:
	RTS

ciaBInterrupt:
	MOVEM.L	D0/A0,-(SP)
	LEA	_ciab,A0
	MOVE.B	ciaicr(A0),D0
	BPL	ciaBInterruptDone
	BTST	#CIAICRB_TB,D0
	BEQ	ciaBInterruptDone
	LEA	_ciaa,A0
	BCLR	#$06,ciacra(A0)
	CLR.B	ciaBTimerBSet
ciaBInterruptDone:
	MOVEM.L	(SP)+,D0/A0
	RTS

verticalBlankInterrupt:
	bsr	copperInterrupt
	MOVEM.L	D0-D7/A0-A6,-(SP)
	CLR.W	D1
	CLR.W	D2
	JSR	verticalBlank
	BTST	#$05,_custom+serdatr
	BEQ	.done
	MOVE.B	serialWriteIndex,D0
	CMP.B	serialReadIndex,D0
	BEQ	.done
	JSR	serialTransmitEmptyInterrupt
.done:	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

copperInterrupt:
	TST.B	copperlistUpdatePendingFlag
	BEQ	lbC000A46
	MOVEM.L	D0-D7/A0-A6,-(SP)
	JSR	updateCopperlistPointers
	CLR.B	copperlistUpdatePendingFlag
	move.b	framesSinceCopperlistUpdateAccumulator,framesSinceCopperlistUpdate
	clr.b	framesSinceCopperlistUpdateAccumulator
	TST.B	spriteUpdatePendingFlag
	BEQ	lbC000A42
	JSR	updateSpritePositions
	CLR.B	spriteUpdatePendingFlag
lbC000A42:
	MOVEM.L	(SP)+,D0-D7/A0-A6
lbC000A46:
	RTS

serialTransmitEmptyInterrupt:
	TST.B	lbB000B58
	BPL	lbC000A5A
	ADDQ.W	#$01,lbW000B5A
	RTS

lbC000A5A:
	MOVE.B	#$80,lbB000B58
lbC000A62:
	BTST	#$05,_custom+serdatr
	BEQ	lbC000AC4
	MOVEM.L	D0/D3/A0,-(SP)
	MOVE.W	#$000F,D3
lbC000A76:
	DBRA	D3,lbC000A76
	CLR.W	D3
	MOVE.B	serialReadIndex,D3
	CMP.B	serialWriteIndex,D3
	BEQ	lbC000AC0
	MOVE.L	#serialTransmitBuffer,A0
	MOVE.B	$00(A0,D3.W),D0
	ADDQ.B	#$01,serialReadIndex
	AND.W	#$00FF,D0
	MOVE.W	#$0007,D3
	BSET	#$08,D0
lbC000AA8:
	ROR.B	#$01,D0
	BCC	lbC000AB2
	BCHG	#$08,D0
lbC000AB2:
	DBRA	D3,lbC000AA8
	BSET	#$09,D0
	MOVE.W	D0,_custom+serdat
lbC000AC0:
	MOVEM.L	(SP)+,D0/D3/A0
lbC000AC4:
	CLR.B	lbB000B58
	TST.W	lbW000B5A
	BEQ	lbC000ADE
	SUBQ.W	#$01,lbW000B5A
	BRA	lbC000A62

lbC000ADE:
	RTS

serialReceiveFullInterrupt:
	MOVEM.L	D0/D3/A0,-(SP)
	MOVE.W	_custom+serdatr,D0
	MOVE.W	#$0007,D3
lbC000AEE:
	ROR.B	#$01,D0
	BCC	lbC000AF8
	BCHG	#$08,D0
lbC000AF8:
	DBRA	D3,lbC000AEE
	BTST	#$08,D0
	BEQ	lbC000B2C
	CLR.W	D3
	MOVE.B	serialBufferIndex,D3
	ADDQ.B	#$01,D3
	CMP.B	lbB000B55,D3
	BEQ	lbC000B2C
	SUBQ.B	#$01,D3
	MOVE.L	#serialReceiveBuffer,A0
	MOVE.B	D0,$00(A0,D3.W)
	ADD.B	#$01,serialBufferIndex
lbC000B2C:
	MOVEM.L	(SP)+,D0/D3/A0
	RTS

initializeSerialPort:
	CLR.L	serialBufferIndex
	MOVE.W	#$8174,_custom+serper
	LEA	_ciab,A0
	OR.B	#$40,ciaddra(A0)
	AND.B	#(CIAF_PRTRBUSY|CIAF_PRTRPOUT|CIAF_PRTRSEL|CIAF_COMDSR|CIAF_COMCTS|CIAF_COMCD|CIAF_COMDTR),ciapra(A0)
	RTS

lbC000B5C:
	MOVE.B	serialBufferIndex,D0
	CMP.B	lbB000B55,D0
	RTS

readSerialByte:
	MOVE.L	#serialReceiveBuffer,A0
	CLR.W	D1
lbC000B72:
	MOVE.B	lbB000B55,D1
	CMP.B	serialBufferIndex,D1
	BEQ	lbC000B72
	MOVE.B	$00(A0,D1.W),D0
	ADDQ.B	#$01,lbB000B55
	RTS

queueSerialByte:
	MOVE.L	#serialTransmitBuffer,A0
	CLR.W	D1
	MOVE.B	serialWriteIndex,D1
	ADDQ.B	#$01,D1
	CMP.B	serialReadIndex,D1
	BEQ	queueSerialByte
	SUBQ.B	#$01,D1
	MOVE.B	D0,$00(A0,D1.W)
	ADDQ.B	#$01,serialWriteIndex
	BTST	#$05,_custom+serdatr
	BEQ	lbC000BC6
	JSR	serialTransmitEmptyInterrupt
lbC000BC6:
	RTS

diskSyncInterrupt:
	RTS

diskBlockInterrupt:
	RTS

audioChannel0Interrupt:
	MOVE.W	audioChannel0Period,_custom+aud0+ac_per
	RTS

audioChannel1Interrupt:
	MOVEM.L	D0/A0,-(SP)
	MOVE.W	#$0004,D0
	BRA	audioInterrupt

audioChannel2Interrupt:
	MOVEM.L	D0/A0,-(SP)
	MOVE.W	#$0008,D0
	BRA	audioInterrupt

audioChannel3Interrupt:
	MOVEM.L	D0/A0,-(SP)
	MOVE.W	#$000C,D0
audioInterrupt:
	LEA	audioChannelMasks,A0
	LEA	$00(A0,D0.W),A0
	MOVE.W	_custom+dmaconr,D0
	AND.W	$0002(A0),D0
	BNE	audioChannelEnabled
	MOVE.W	$0002(A0),D0
	AND.W	audioDMAEnableGuard,D0
	BNE	audioInterruptDone
	MOVE.W	$0002(A0),D0
	ASL.W	#$07,D0
	MOVE.W	D0,_custom+intena
	BRA	audioInterruptDone

audioChannelEnabled:
	ADDQ.W	#$01,(A0)
	CMP.W	#$0002,(A0)
	BLT	audioInterruptDone
	MOVE.W	$0002(A0),D0
	MOVE.W	D0,_custom+dmacon
	ASL.W	#$07,D0
	MOVE.W	D0,_custom+intena
audioInterruptDone:
	MOVEM.L	(SP)+,D0/A0
	RTS

playSample:
	MOVEM.L	D0/D3/D4/A0/A1,-(SP)
	AND.W	#$0007,D0
	ASL.W	#$04,D0
	LEA	sampleParameterTable,A0
	LEA	$00(A0,D0.W),A0
	MOVE.W	$000C(A0),D0
	ASL.W	#$02,D0
	LEA	audioChannelMasks,A1
	MOVE.W	$02(A1,D0.W),D3
	MOVE.W	D3,D4
	ASL.W	#$07,D4
	MOVE.W	D4,_custom+intena
	MOVE.W	D3,_custom+dmacon
	MOVE.W	#$0000,$00(A1,D0.W)
	ASL.W	#$02,D0
	LEA	_custom,A1
	LEA	$00(A1,D0.W),A1
	MOVE.L	(A0),$00A0(A1)
	MOVE.L	$0004(A0),D0
	LSR.L	#$01,D0
	MOVE.W	D0,$00A4(A1)
	MOVE.W	$000A(A0),$00A8(A1)
	MOVE.W	$0008(A0),$00A6(A1)
	MOVE.W	D3,audioDMAEnableGuard
	BSET	#INTB_SETCLR,D3
	MOVE.W	D4,_custom+intreq
	BSET	#INTB_SETCLR,D4
	MOVE.W	D4,_custom+intena
	MOVE.W	D3,_custom+dmacon
	CLR.W	audioDMAEnableGuard
	MOVEM.L	(SP)+,D0/D3/D4/A0/A1
	RTS

disableAudio:
	MOVE.W	#(DMAF_AUD0|DMAF_AUD1|DMAF_AUD2|DMAF_AUD3|DMAF_AUDIO),_custom+dmacon
	MOVE.W	#(INTF_AUD0|INTF_AUD1|INTF_AUD2|INTF_AUD3),_custom+intena
	RTS

generateEngineSamples:
	MOVE.L	#$00000C64,D6
	MOVE.L	#downsampledEngineData,A1
	MOVE.L	#sampleEngineData,A2
	MOVE.L	#$00000006,D5
	MOVE.L	#sampleEngineParameters,A5
	MOVE.L	#sampleEngineData,(A5)+
	LSR.L	#$01,D6
	MOVE.L	D6,(A5)+
	ASL.L	#$01,D6
.sampleLoop:
	MOVE.L	A2,A0
	MOVE.L	A1,A2
	MOVE.L	A1,(A5)+
	LSR.W	#$01,D6
	MOVE.W	D6,D0
	SUBQ.W	#$01,D0
.copyLoop:
	MOVE.B	(A0)+,(A1)+
	ADD.L	#$00000001,A0
	DBRA	D0,.copyLoop
	MOVE.L	A1,D0
	BCLR	#$00,D0
	MOVE.L	D0,A1
	SUB.L	-$0004(A5),D0
	LSR.L	#$01,D0
	MOVE.L	D0,(A5)+
	DBRA	D5,.sampleLoop
	MOVE.L	sampleEngineParameters,sampleEnginePointer
	MOVE.L	downsampledSampleEngineTable,D0
	ASL.L	#$01,D0
	MOVE.L	D0,sampleEngineSize
	RTS

readJoystickState:
	ifeq	WHDLOAD
	jsr	testQuit
	endc
	MOVEM.L	D3/D4/A0,-(SP)
	CLR.B	D4
	MOVE.W	_custom+joy1dat,D0
	MOVE.W	D0,D3
	LSR.W	#$01,D3
	EOR.W	D0,D3
	BTST	#$08,D3
	BEQ	lbC00D068
	BSET	#$00,D4
lbC00D068:
	BTST	#$00,D3
	BEQ	lbC00D074
	BSET	#$01,D4
lbC00D074:
	BTST	#$09,D0
	BEQ	lbC00D080
	BSET	#$02,D4
lbC00D080:
	BTST	#$01,D0
	BEQ	lbC00D08C
	BSET	#$03,D4
lbC00D08C:
	LEA	_ciaa,A0
	AND.B	#$7F,ciaddra(A0)
	BTST	#$07,$0000(A0)
	BNE	lbC00D0A6
	BSET	#$04,D4
lbC00D0A6:
	EOR.B	#$FF,D4
	MOVE.B	D4,joystickState
	MOVEM.L	(SP)+,D3/D4/A0
	RTS

setupFrameBufferAddresses:
	MOVE.L	#fastRenderBuffer,D3		; originally renderFrameBuffer
	ADD.L	#$00000284,D3
	MOVE.L	D3,viewportTopAddress
	MOVE.L	displayFrameBuffer,bitplane1Pointer
	MOVE.B	#$80,copperlistUpdatePendingFlag
.wait:	tst.b   copperlistUpdatePendingFlag	; added
	bmi	.wait
	RTS

updateCopperlistPointers:
	MOVEM.L	D3/D4,-(SP)
	MOVE.L	bitplane1Pointer,D0
	MOVE.L	#copperlist,A0
	MOVE.W	#$0003,D4
lbC00D0F0:
	MOVE.L	D0,D3
	SWAP	D3
	MOVE.W	D3,$0002(A0)
	MOVE.W	D0,$0006(A0)
	ADD.L	#$00000008,A0
	ADD.L	#$00001F40,D0
	DBRA	D4,lbC00D0F0
	MOVEM.L	(SP)+,D3/D4
	RTS

busyWaitDelay:
	MOVE.L	#$00001800,D0
lbC00D11E:
	SUB.L	#$00000001,D0
	BNE	lbC00D11E
	RTS

displayMessageWithColors:
	MOVE.B	textTransparencyMode,D0
	MOVE.W	D0,-(SP)
	MOVE.W	textCursorColumn,-(SP)
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	displayFrameBuffer,renderFrameBuffer
	MOVE.W	D1,-(SP)
	MOVE.B	#$00,textTransparencyMode
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.B	#$03,D0
	JSR	setForegroundColor
	MOVE.W	#$00D0,D1
	JSR	displayMessage
	MOVE.W	(SP)+,D1
	JSR	displayMessage
	MOVE.L	(SP)+,renderFrameBuffer
	MOVE.W	(SP)+,textCursorColumn
	MOVE.W	(SP)+,D0
	MOVE.B	D0,textTransparencyMode
	RTS

initializeGameMemoryAndState:
	CLR.L	D1
	CLR.L	D2
	MOVE.L	#keyboardState,A0
	MOVE.W	#$007F,D1
.clearKeyboardStateLoop:
	MOVE.B	#$00,$00(A0,D1.W)
	SUBQ.B	#$01,D1
	BPL	.clearKeyboardStateLoop
	MOVE.L	#leagueSeasonData,A0
.clearBuffersLoop:
	MOVE.B	#$00,(A0)+
	CMP.L	#endOfBuffers,A0
	BLT	.clearBuffersLoop
	JSR	initializeGraphicsData
	JMP	startupInitAndEnterMenu

copyPalette:
	MOVE.L	#sourcePalette,A0
	MOVE.W	#$000F,D0
.copyLoop:
	MOVE.W	(A1)+,(A0)+
	DBRA	D0,.copyLoop
	RTS

copyPaletteToCopperlist:
	MOVE.L	#palette,A1
	MOVE.L	#copperlistColor0,A0
	MOVE.W	#$000F,D4
.copyLoop:
	MOVE.W	(A1)+,D3
	ASL.W	#$01,D3
	MOVE.B	D3,D0
	AND.B	#$0F,D0
	BEQ	.bOk
	OR.B	#$01,D3
.bOk:	MOVE.B	D3,D0
	AND.B	#$F0,D0
	BEQ	.gOk
	OR.B	#$10,D3
.gOk:	MOVE.W	D3,D0
	AND.W	#$0F00,D0
	BEQ	.rOk
	OR.W	#$0100,D3
.rOk:	MOVE.W	D3,(A0)+
	ADD.L	#$00000002,A0
	DBRA	D4,.copyLoop
	RTS

copyMainGameBackground:
	MOVE.L	frameBuffers,A1
	MOVE.L	#imageMainGameBackground,A0
	JSR	decompressRLEImage
	MOVE.L	frameBuffers,A0
	MOVE.L	A0,A1
	ADD.W	#$7D00,A1
	lea	fastRenderBuffer,a2		; added
	MOVE.W	#$7D00/4-1,D3			; originally #$7CFF
.copyLoop:
	MOVE.L	(A0)+,D0			; originally MOVE.B	(A0)+,(A1)+
	move.l	d0,(A1)+
	move.l	d0,(A2)+
	DBRA	D3,.copyLoop
	RTS

sendSerialByteWithChecksum:
	AND.W	#$00FF,D0
	ADD.W	D0,checksumAccumulator
	ADDQ.W	#$01,checksumAccumulator
	JSR	queueSerialByte
	CLR.W	D1
	CLR.W	D2
	RTS

sendSerialWordWithChecksum:
	MOVE.W	D0,-(SP)
	LSR.W	#$08,D0
	JSR	sendSerialByteWithChecksum
	MOVE.W	(SP)+,D0
	JMP	sendSerialByteWithChecksum

checkNetworkStatus:
	JMP	lbC000B5C

waitForNetworkByte:
	JSR	checkNetworkStatus
	BNE	processNetworkData
	JSR	checkSpaceKeyPressed
	BNE	waitForNetworkByte
	MOVE.B	#$00,D0
	RTS

processNetworkData:
	JSR	readSerialByte
	AND.W	#$00FF,D0
	ADD.W	D0,networkDataCounter1
	ADDQ.W	#$01,networkDataCounter1
	ADDQ.W	#$01,networkDataCounter2
	CLR.W	D1
	CLR.W	D2
	RTS

waitForNetworkWord:
	JSR	waitForNetworkByte
	MOVE.W	D0,-(SP)
	JSR	waitForNetworkByte
	MOVE.B	D0,D3
	MOVE.W	(SP)+,D0
	ASL.W	#$08,D0
	MOVE.B	D3,D0
	RTS

	MOVE.W	#$03E8,lbW049574
	BRA	lbC0489A8

waitForNetworkByteTimeout:
	MOVE.W	#$0003,lbW049574
lbC0489A8:
	JSR	checkNetworkStatus
	BNE	lbC0489CC
	JSR	preciseTiming
	SUBQ.W	#$01,lbW049574
	BNE	lbC0489A8
	MOVE.B	#$00,D0
	ORI.B	#$01,CCR
	RTS

lbC0489CC:
	JSR	processNetworkData
	ANDI.B	#$1E,CCR
	RTS

networkHandshakeLoop:
	JSR	checkNetworkStatus
	BEQ	lbC0489EC
	JSR	processNetworkData
	BRA	networkHandshakeLoop

lbC0489EC:
	RTS

initializeNetworking:
	JSR	initializeSerialPort
	CLR.W	D1
	CLR.W	D2
	JSR	networkHandshakeLoop
	RTS

checkKeyPressedOrNetworkState:
	TST.B	networkGameMode
	BNE	lbC048A10
	JMP	checkKeyPressed

lbC048A10:
	TST.B	D0
	BEQ	lbC048A1C
	MOVE.B	#$00,D0
	RTS

lbC048A1C:
	MOVE.B	#$FF,D0
	RTS

networkTimingSync0:
	JSR	networkTimingSync1
networkTimingSync1:
	JSR	networkDelay
	JSR	longNetworkDelay
networkTimingSync2:
	JSR	networkDelayWrapper
	JSR	networkDelay
longNetworkDelay:
	JSR	networkDelay
networkDelayWrapper:
	JSR	networkDelay
networkDelay:
	MOVE.W	D0,-(SP)
	MOVE.W	#$1B9E,D0
	BRA	ciaTimerDelay

networkTimingSyncShort:
	JSR	preciseTiming
	JSR	mediumDelay
mediumDelay:
	MOVE.W	D0,-(SP)
	MOVE.W	#$0586,D0
	BRA	ciaTimerDelay

preciseTiming:
	MOVE.W	D0,-(SP)
	MOVE.W	#$02C3,D0
ciaTimerDelay:
	MOVE.L	A0,-(SP)
	LEA	$00BFE001,A0
	MOVE.B	#$80,ciaTimerFlag
	MOVE.B	#$08,$0F00(A0)
	MOVE.B	#$82,$0D00(A0)
	MOVE.B	D0,$0600(A0)
	LSR.W	#$08,D0
	MOVE.B	D0,$0700(A0)
lbC048A98:
	TST.B	ciaTimerFlag
	BNE	lbC048A98
	MOVE.L	(SP)+,A0
	MOVE.W	(SP)+,D0
	RTS

validateNetworkStateFlag:
	CMP.B	#$40,D0
	BEQ	lbC048ABA
	CMP.B	#$80,D0
	BNE	lbC048ACC
lbC048ABA:
	TST.B	D3
	BEQ	lbC048ACA
	CMP.B	D0,D3
	BEQ	lbC048ACC
	MOVE.B	#$80,D0
lbC048ACA:
	MOVE.B	D0,D3
lbC048ACC:
	RTS

synchronizeNetworkState:
	MOVE.B	#$00,networkPacketReadyFlag
	CLR.W	checksumAccumulator
	MOVE.B	playerSegmentIndex,D0
	JSR	sendSerialByteWithChecksum
	MOVE.W	trackProgressionByte,D0
	JSR	sendSerialWordWithChecksum
	MOVE.W	worldYSpeed,D0
	ASR.W	#$01,D0
	ADD.W	averageWheelVelocity,D0
	ASR.W	#$03,D0
	BPL	lbC048B0A
	CLR.W	D0
lbC048B0A:
	MOVE.W	D0,lbW049570
	MOVE.L	trackSurfaceFrontLeft,D0
	ASR.L	#$03,D0
	ADD.W	lbW049570,D0
	BPL	lbC048B24
	CLR.W	D0
lbC048B24:
	MOVE.L	trackSurfaceFrontRight,D3
	ASR.L	#$03,D3
	ADD.W	lbW049570,D3
	BPL	lbC048B38
	CLR.W	D3
lbC048B38:
	MOVE.L	trackSurfaceRear,D4
	ASR.L	#$03,D4
	ADD.W	lbW049570,D4
	BPL	lbC048B4C
	CLR.W	D4
lbC048B4C:
	MOVE.W	D0,D7
	ADD.W	D3,D7
	LSR.W	#$01,D7
	SUB.W	D0,D3
	ASR.W	#$01,D3
	MOVE.W	D4,D5
	SUB.W	D3,D5
	MOVE.W	D4,D6
	ADD.W	D3,D6
	MOVE.W	#$8765,D0
	JSR	sendSerialWordWithChecksum
	MOVE.W	D5,D0
	JSR	sendSerialWordWithChecksum
	MOVE.W	D6,D0
	JSR	sendSerialWordWithChecksum
	MOVE.W	D7,D0
	JSR	sendSerialWordWithChecksum
	MOVE.W	carLocalVelocityZ,D0
	JSR	sendSerialWordWithChecksum
	MOVE.W	lateralRoadPosition,D0
	TST.B	reverseDirectionFlag
	BPL	lbC048BA2
	NEG.W	D0
	ADD.W	#$0180,D0
lbC048BA2:
	MOVE.W	D0,D0
	JSR	sendSerialWordWithChecksum
	CMP.B	#$40,pauseKeyPressed
	BEQ	sendNetworkSyncPacket
	CMP.B	#$80,pauseKeyPressed
	BEQ	sendNetworkSyncPacket
	MOVE.B	#$00,D4
	MOVE.B	#$19,D1
	JSR	checkKeyPressed
	BNE	lbC048BDA
	MOVE.B	networkGameMode,D4
lbC048BDA:
	MOVE.B	D4,pauseKeyPressed
sendNetworkSyncPacket:
	MOVE.B	pauseKeyPressed,D0
	JSR	sendSerialByteWithChecksum
	CMP.B	#$40,playerInputState
	BEQ	lbC048C22
	CMP.B	#$80,playerInputState
	BEQ	lbC048C22
	MOVE.B	#$00,D4
	MOVE.B	#$45,D1
	JSR	checkKeyPressed
	BNE	lbC048C1C
	MOVE.B	networkGameMode,D4
lbC048C1C:
	MOVE.B	D4,playerInputState
lbC048C22:
	MOVE.B	playerInputState,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	blinkCountdownTimer,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	gameModeStateFlags,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	raceStartTimer,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	holeRenderingPosition,D0
	TST.B	raceStartTimer
	BEQ	lbC048C66
	BSET	#$07,D0
lbC048C66:
	TST.B	trackSideIndicator
	BPL	lbC048C74
	BSET	#$06,D0
lbC048C74:
	MOVE.B	D0,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	lbB04956B,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	lbB04956C,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	lbB04956D,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	lapTimeDisplayDuration,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	globalFrameCounter,D0
	JSR	sendSerialByteWithChecksum
	MOVE.W	checksumAccumulator,D0
	JSR	sendSerialWordWithChecksum
	TST.B	lbB04956E
	BNE	lbC048D30
	MOVE.B	opponentSegmentIndex,lbB04956A
	MOVE.W	opponentSubSegmentProgress,lbW049576
	TST.B	lbB04956E
	BNE	lbC048D30
	CLR.W	networkDataCounter1
	JSR	waitForNetworkByte
	MOVE.B	D0,opponentSegmentIndex
	JSR	waitForNetworkWord
	MOVE.W	D0,opponentSubSegmentProgress
	TST.B	selectedTrackInDivision
	BPL	lbC048D2E
	MOVE.B	opponentSegmentIndex,D0
	CMP.B	numTrackSegments,D0
	BCC	lbC048D30
	MOVE.W	#$00FF,D0
	JSR	calculateTrackCoordinateBehindOpponent
lbC048D2E:
	RTS

lbC048D30:
	MOVE.B	#$80,networkPacketReadyFlag
	CLR.B	lbB04956E
	RTS

handleNetworkProtocol:
	TST.B	networkPacketReadyFlag
	BNE	lbC048FEE
	MOVE.B	pauseKeyPressed,lbB049550
	MOVE.B	playerInputState,lbB049551
	MOVE.B	gameModeStateFlags,lbB049552
	MOVE.B	blinkCountdownTimer,lbB049553
	MOVE.B	raceStartTimer,lbB049554
	JSR	waitForNetworkWord
	MOVE.W	D0,D0
	CMP.W	#$8765,D0
	BNE	lbC048FEE
	TST.B	networkPacketReadyFlag
	BNE	lbC048FEE
	JSR	waitForNetworkWord
	MOVE.W	D0,lbW049546
	JSR	waitForNetworkWord
	MOVE.W	D0,lbW049548
	JSR	waitForNetworkWord
	MOVE.W	D0,lbW04954A
	MOVE.W	#$0000,minBoundaryDistance
	JSR	waitForNetworkWord
	MOVE.W	D0,lbW04954C
	JSR	waitForNetworkWord
	MOVE.W	D0,D0
	MOVE.W	#$5555,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	MOVE.W	D0,lbW04954E
	JSR	waitForNetworkByte
	MOVE.B	D0,D0
	MOVE.B	lbB049550,D3
	JSR	validateNetworkStateFlag
	MOVE.B	D3,lbB049550
	JSR	waitForNetworkByte
	MOVE.B	D0,D0
	MOVE.B	lbB049551,D3
	JSR	validateNetworkStateFlag
	MOVE.B	D3,lbB049551
	JSR	waitForNetworkByte
	MOVE.B	D0,D0
	TST.B	D0
	BEQ	lbC048E46
	BMI	lbC048E40
	TST.B	lbB049553
	BEQ	lbC048E40
	CMP.B	lbB049553,D0
	BCC	lbC048E46
lbC048E40:
	MOVE.B	D0,lbB049553
lbC048E46:
	JSR	waitForNetworkByte
	MOVE.B	D0,D0
	MOVE.B	lbB049552,D3
	JSR	validateNetworkStateFlag
	MOVE.B	D3,lbB049552
	JSR	waitForNetworkByte
	MOVE.B	D0,D0
	TST.B	raceStartComplete
	BMI	lbC048E96
	TST.B	networkGameMode
	BMI	lbC048E96
	CMP.B	#$E4,lbB049554
	BCC	lbC048E96
	CMP.B	#$E4,D0
	BCC	lbC048E96
	MOVE.B	D0,lbB049554
lbC048E96:
	JSR	waitForNetworkByte
	MOVE.B	D0,lbB049555
	JSR	waitForNetworkByte
	MOVE.B	D0,lbB049556
	JSR	waitForNetworkByte
	MOVE.B	D0,lbB049557
	JSR	waitForNetworkByte
	MOVE.B	D0,lbB049558
	JSR	waitForNetworkByte
	MOVE.B	D0,lbB049559
	JSR	waitForNetworkByte
	MOVE.B	D0,lbB04955A
	MOVE.W	networkDataCounter1,savedNetworkCounter
	JSR	waitForNetworkWord
	MOVE.W	D0,D0
	CMP.W	savedNetworkCounter,D0
	BNE	lbC048FEE
	JSR	networkHandshakeLoop
	MOVE.L	lbW049546,opponentWheelPositions
	MOVE.W	lbW04954A,opponentRearRightWheelPosition
	MOVE.W	lbW04954C,aiCurrentSpeed
	MOVE.W	lbW04954E,opponentDistanceOffset
	MOVE.B	lbB049550,pauseKeyPressed
	MOVE.B	lbB049551,playerInputState
	MOVE.B	lbB049552,gameModeStateFlags
	MOVE.B	lbB049553,blinkCountdownTimer
	MOVE.B	lbB049554,raceStartTimer
	MOVE.B	lbB049555,D0
	MOVE.B	D0,multiplayerSyncFlag
	AND.B	#$0F,D0
	MOVE.B	D0,lbB049561
	MOVE.B	lbB049556,lbB00E209
	MOVE.B	lbB049557,lbB00E221
	MOVE.B	lbB049558,lbB00E239
	MOVE.B	lbB049559,networkConnectionState
	MOVE.B	lbB04955A,D0
	SUB.B	globalFrameCounter,D0
	BPL	lbC048FBE
	JSR	networkTimingSync1
	JSR	synchronizeNetworkState
	JSR	longNetworkDelay
	BRA	handleNetworkProtocol

lbC048FBE:
	BEQ	lbC048FCA
	MOVE.B	#$80,lbB04956E
lbC048FCA:
	TST.B	selectedTrackInDivision
	BPL	lbC048FEC
	JSR	convertOpponentWheelsToCarFootprint
	JSR	calculatePlayerDistance
	JSR	handleOpponentPositioning
	JSR	setupTrackGeometryForFrame
lbC048FEC:
	RTS

lbC048FEE:
	JSR	checkNetworkStatus
	BEQ	lbC049004
	JSR	processNetworkGameState
	JSR	networkHandshakeLoop
lbC049004:
	MOVE.B	lbB04956A,opponentSegmentIndex
	MOVE.W	lbW049576,opponentSubSegmentProgress
	TST.B	networkConnectionState
	BEQ	lbC049028
	SUBQ.B	#$01,networkConnectionState
lbC049028:
	MOVE.B	#$80,networkPacketReadyFlag
	MOVE.W	#$FFFF,opponentSegmentQueueOffset
	RTS

processNetworkGameState:
	JSR	receiveNetworkGamePacket
	BCS	lbC0490F8
	MOVE.B	receivedGameInitFlag,D4
	TST.B	receivedGameStateID
	BNE	lbC04906E
	BTST	#$00,D4
	BEQ	lbC04906C
	MOVE.B	networkGameMode,D0
	EOR.B	#$C0,D0
	MOVE.B	D0,pauseKeyPressed
lbC04906C:
	RTS

lbC04906E:
	BTST	#$04,receivedGameStateID
	BNE	lbC0490F8
	BTST	#$05,D4
	BEQ	lbC0490BC
	MOVE.B	D4,D0
	AND.B	#$C0,D0
	EOR.B	#$C0,D0
	MOVE.B	D0,raceOutcomeFlags
	MOVE.B	#$80,frameBufferSyncMask
	MOVE.B	#$05,raceCompletionState
	MOVE.B	#$00,gameModeStateFlags
	MOVE.B	#$00,playerInputState
	MOVE.B	#$00,pauseKeyPressed
	RTS

lbC0490BC:
	BTST	#$04,D4
	BEQ	lbC0490D6
	MOVE.B	networkGameMode,D0
	EOR.B	#$C0,D0
	MOVE.B	D0,playerInputState
	RTS

lbC0490D6:
	BTST	#$03,D4
	BEQ	lbC0490F8
	MOVE.B	networkGameMode,D0
	EOR.B	#$C0,D0
	MOVE.B	D0,gameModeStateFlags
	MOVE.B	#$80,frameBufferSyncMask
	RTS

lbC0490F8:
	RTS

sendNetworkGamePacket:
	CLR.W	checksumAccumulator
	MOVE.W	#$1256,D0
	JSR	sendSerialWordWithChecksum
	MOVE.B	#$34,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	networkInitPhase,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	gameStateID,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	localInputStateCache,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	networkProtocolState,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	localPlayerStateCache,D0
	JSR	sendSerialByteWithChecksum
	MOVE.W	checksumAccumulator,D0
	MOVE.B	D0,D0
	JSR	sendSerialByteWithChecksum
	JSR	networkDelay
	JSR	networkTimingSyncShort
	RTS

receiveNetworkGamePacket:
	MOVE.W	D7,-(SP)
	MOVE.W	#$0008,D7
lbC049172:
	CLR.W	networkDataCounter1
	JSR	waitForNetworkByteTimeout
	BCS	lbC049240
	MOVE.B	D0,D0
	CMP.B	#$12,D0
	BNE	lbC049240
	SUBQ.W	#$01,D7
	JSR	waitForNetworkByteTimeout
	BCS	lbC049240
	MOVE.B	D0,D0
	CMP.B	#$56,D0
	BNE	lbC049240
	SUBQ.W	#$01,D7
	JSR	waitForNetworkByteTimeout
	BCS	lbC049240
	MOVE.B	D0,D0
	CMP.B	#$34,D0
	BNE	lbC049240
	SUBQ.W	#$01,D7
	JSR	waitForNetworkByteTimeout
	BCS	lbC049240
	MOVE.B	D0,receivedGameInitFlag
	JSR	waitForNetworkByteTimeout
	BCS	lbC049240
	MOVE.B	D0,receivedGameStateID
	JSR	waitForNetworkByteTimeout
	BCS	lbC049240
	MOVE.B	D0,receivedInputState
	JSR	waitForNetworkByteTimeout
	BCS	lbC049240
	MOVE.B	D0,receivedPlayerCommand
	JSR	waitForNetworkByteTimeout
	BCS	lbC049240
	MOVE.B	D0,receivedPlayerState
	MOVE.W	networkDataCounter1,savedNetworkCounter
	JSR	waitForNetworkByte
	MOVE.B	D0,D0
	MOVE.W	savedNetworkCounter,D3
	CMP.B	D3,D0
	BNE	lbC049240
	MOVE.W	(SP)+,D7
	JSR	mediumDelay
	JSR	checkNetworkStatus
	BNE	receiveNetworkGamePacket
	ANDI.B	#$1E,CCR
	RTS

lbC049240:
	SUBQ.W	#$01,D7
	BPL	lbC049172
	MOVE.W	(SP)+,D7
	JSR	preciseTiming
	JSR	preciseTiming
	JSR	checkNetworkStatus
	BNE	receiveNetworkGamePacket
	ORI.B	#$01,CCR
	RTS

updateNetworkGameFlags:
	TST.B	networkGameMode
	BEQ	lbC0492AE
	MOVE.B	#$00,D0
	TST.B	raceCompletionState
	BEQ	lbC049286
	MOVE.B	raceOutcomeFlags,D0
	OR.B	#$20,D0
lbC049286:
	TST.B	playerInputState
	BEQ	lbC049294
	OR.B	#$10,D0
lbC049294:
	MOVE.B	gameModeStateFlags,D3
	CMP.B	networkGameMode,D3
	BNE	lbC0492A8
	OR.B	#$08,D0
lbC0492A8:
	MOVE.B	D0,networkInitPhase
lbC0492AE:
	RTS

waitForNetworkHandshake:
	TST.B	networkGameMode
	BEQ	lbC0493B4
	JSR	networkHandshakeLoop
	TST.B	networkGameMode
	BMI	lbC04934E
lbC0492CA:
	JSR	checkSpaceKeyPressed
	BEQ	lbC0493BA
	JSR	sendNetworkGamePacket
	JSR	receiveNetworkGamePacket
	BCS	lbC0492CA
	MOVE.B	networkProtocolState,D0
	CMP.B	receivedPlayerCommand,D0
	BEQ	lbC049310
	CMP.B	#$88,receivedPlayerCommand
	BNE	lbC0492CA
	CMP.B	#$C1,networkProtocolState
	BNE	lbC0492CA
	BRA	lbC0493BA

lbC049310:
	MOVE.B	#$AA,networkProtocolState
lbC049318:
	JSR	checkSpaceKeyPressed
	BEQ	lbC0493BA
	JSR	sendNetworkGamePacket
	JSR	receiveNetworkGamePacket
	BCC	lbC049318
	MOVE.W	#$001D,D7
lbC049336:
	JSR	checkNetworkStatus
	BNE	lbC049318
	JSR	preciseTiming
	DBRA	D7,lbC049336
	BRA	lbC0493B4

lbC04934E:
	JSR	checkSpaceKeyPressed
	BEQ	lbC0493BA
	JSR	sendNetworkGamePacket
	JSR	receiveNetworkGamePacket
	BCS	lbC04934E
	MOVE.B	receivedPlayerCommand,D0
	CMP.B	#$AA,D0
	BEQ	lbC0493AE
	CMP.B	networkProtocolState,D0
	BEQ	lbC04934E
	TST.B	D0
	BPL	lbC04934E
	CMP.B	#$E3,networkProtocolState
	BEQ	lbC0493AE
	CMP.B	#$88,receivedPlayerCommand
	BNE	lbC04934E
	CMP.B	#$C1,networkProtocolState
	BNE	lbC04934E
	BRA	lbC0493BA

lbC0493AE:
	JSR	networkTimingSync1
lbC0493B4:
	ANDI.B	#$1E,CCR
	RTS

lbC0493BA:
	ORI.B	#$01,CCR
	RTS

readInputWithNetworkSync:
	MOVE.B	D0,inputStateFlags
	MOVE.B	#$80,receivedKey
	TST.B	networkInputSyncEnabled
	BPL	lbC04944C
	TST.B	networkGameMode
	BPL	lbC049410
	MOVE.W	#$0003,D2
lbC0493E6:
	MOVE.L	#keycodeTable,A0
	MOVE.B	$00(A0,D2.W),D1
	JSR	checkKeyPressed
	BNE	lbC049400
	MOVE.B	D2,receivedKey
lbC049400:
	SUBQ.B	#$01,D2
	BPL	lbC0493E6
	MOVE.B	receivedKey,localPlayerStateCache
lbC049410:
	MOVE.B	inputStateFlags,localInputStateCache
	MOVE.B	#$E3,networkProtocolState
	JSR	waitForNetworkHandshake
	BCS	lbC04944C
	CMP.B	#$40,networkGameMode
	BNE	lbC04944C
	MOVE.B	receivedInputState,inputStateFlags
	MOVE.B	receivedPlayerState,receivedKey
lbC04944C:
	MOVE.B	#$00,networkProtocolState
	MOVE.B	inputStateFlags,D0
	RTS

validateNetworkMenuSelection:
	MOVE.B	receivedKey,D0
	BMI	lbC049480
	MOVE.B	maxMenuIndex,D3
	ADDQ.B	#$01,D3
	CMP.B	D3,D0
	BGT	lbC049480
	MOVE.B	receivedKey,selectedMenuItem
	RTS

lbC049480:
	MOVE.B	#$80,D0
	RTS

waitForUnpause:
	TST.B	networkGameMode
	BEQ	lbC0494F6
	MOVE.B	#$01,networkInitPhase
	MOVE.B	#$F1,networkProtocolState
	JSR	waitForNetworkHandshake
	BCS	lbC04950A
lbC0494AA:
	JSR	displayControlConfigurationScreen
	MOVE.B	#$18,D1
	JSR	checkKeyPressed
	BEQ	lbC0494E4
	JSR	checkSpaceKeyPressed
	BEQ	lbC04950A
	JSR	sendNetworkGamePacket
	JSR	receiveNetworkGamePacket
	BCS	lbC0494AA
	CMP.B	#$F2,receivedPlayerCommand
	BNE	lbC0494AA
lbC0494E4:
	MOVE.B	#$F2,networkProtocolState
	JSR	waitForNetworkHandshake
	BRA	lbC04950A

lbC0494F6:
	JSR	displayControlConfigurationScreen
	MOVE.B	#$18,D1
	JSR	checkKeyPressed
	BNE	lbC0494F6
lbC04950A:
	MOVE.B	#$00,networkInitPhase
	MOVE.B	#$00,pauseKeyPressed
	RTS

checkSpaceKeyPressed:
	MOVE.W	D1,lbW049538
	MOVE.W	#$0054,D1
	JSR	checkKeyPressed
	MOVE.W	SR,-(SP)
	MOVE.W	lbW049538,D1
	MOVE.W	(SP)+,SR
	RTS

establishComputerLink:
	JSR	initializeNetworking
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	displayFrameBuffer,renderFrameBuffer
	JSR	drawScreenFrame
	MOVE.B	#$01,currentMenuItem
	JSR	renderMenuCursorAndAdvance
	JSR	networkHandshakeLoop
	JSR	longNetworkDelay
	JSR	checkNetworkStatus
	BEQ	lbC0495EA
	JSR	processNetworkData
	CMP.B	#$80,D0
	BNE	lbC04968A
	MOVE.B	#$40,networkGameMode
	MOVE.W	#$0005,D7
lbC0495D2:
	MOVE.B	#$40,D0
	JSR	sendSerialByteWithChecksum
	JSR	networkDelay
	DBRA	D7,lbC0495D2
	BRA	lbC04963C

lbC0495EA:
	MOVE.B	#$80,networkGameMode
	MOVE.W	#$0023,D3
	JSR	displayLeagueMessage
	MOVE.W	#$0005,D7
lbC049600:
	MOVE.B	#$45,D1
	JSR	checkKeyPressed
	BEQ	lbC04968A
	MOVE.B	#$80,D0
	JSR	sendSerialByteWithChecksum
	JSR	networkDelay
	JSR	checkNetworkStatus
	BEQ	lbC049600
	SUBQ.W	#$01,D7
	BMI	lbC04968A
	JSR	processNetworkData
	CMP.B	#$40,D0
	BNE	lbC049600
lbC04963C:
	MOVE.B	#$01,currentMenuItem
	JSR	renderMenuCursorAndAdvance
	MOVE.W	#$0012,D3
	JSR	displayLeagueMessage
	MOVE.B	#$80,networkInputSyncEnabled
	JSR	waitForFireButtonPress
	MOVE.L	(SP)+,renderFrameBuffer
	JSR	resetTextYOffset
	TST.B	networkGameMode
	BMI	lbC04967E
	JSR	displayWaitMessage
lbC04967E:
	JSR	synchronizeLeagueSetup
	ANDI.B	#$1E,CCR
	RTS

lbC04968A:
	MOVE.B	#$00,networkGameMode
	MOVE.B	#$01,currentMenuItem
	JSR	renderMenuCursorAndAdvance
	MOVE.W	#$0000,D3
	JSR	displayLeagueMessage
	JSR	waitForFireButtonPress
	MOVE.L	(SP)+,renderFrameBuffer
	JSR	resetTextYOffset
	ORI.B	#$01,CCR
	RTS

displayLeagueMessage:
	MOVE.L	#lbL049700,A0
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	displayFrameBuffer,renderFrameBuffer
	JSR	renderNullTerminatedString
	MOVE.L	(SP)+,renderFrameBuffer
	RTS

renderNullTerminatedString:
	MOVE.B	$00(A0,D3.W),D0
	CMP.B	#$FF,D0
	BEQ	lbC0496FE
	JSR	renderCharacter
	ADDQ.W	#$01,D3
	BRA	renderNullTerminatedString

lbC0496FE:
	RTS

synchronizeLeagueSetup:
	MOVE.B	#$00,writeMode
	MOVE.B	#$40,leagueSessionMode
	TST.B	networkGameMode
	BMI	lbC0497D4
lbC049758:
	JSR	checkSpaceKeyPressed
	BEQ	lbC049844
	MOVE.W	#$00C0,D7
	MOVE.L	#transferBuffer,A6
	JSR	receiveLeagueDataPacket
	BMI	lbC049758
	MOVE.L	#transferBuffer,A6
	MOVE.B	(A6)+,D0
	CMP.B	#$08,D0
	BLT	lbC04978A
	MOVE.B	#$01,D0
lbC04978A:
	MOVE.B	D0,additionalPlayerCount
	MOVE.L	#playerNamesWithSpaces,A0
	MOVE.W	#$00BF,D7
lbC04979A:
	MOVE.B	(A6)+,(A0)+
	DBRA	D7,lbC04979A
	JSR	receiveAdditionalSyncData
	JSR	networkTimingSync0
	JSR	synchronizeNetworkSetup
	BRA	lbC049844

lbC0497B6:
	CLR.B	D0
	MOVE.B	#$01,D2
	MOVE.B	#$14,D1
	JSR	displayMenu
	CMP.B	#$00,D0
	BNE	lbC0497E8
	ADDQ.B	#$01,additionalPlayerCount
lbC0497D4:
	JSR	runPlayerNameEntry
	MOVE.B	additionalPlayerCount,D0
	CMP.B	#$07,D0
	BCS	lbC0497B6
lbC0497E8:
	TST.B	additionalPlayerCount
	BEQ	lbC0497B6
	JSR	displayWaitMessage
	MOVE.L	#transferBuffer,A6
	MOVE.B	additionalPlayerCount,(A6)+
	MOVE.W	#$00BF,D7
	MOVE.L	#playerNamesWithSpaces,A0
lbC04980E:
	MOVE.B	(A0)+,(A6)+
	DBRA	D7,lbC04980E
lbC049814:
	JSR	checkSpaceKeyPressed
	BEQ	lbC049844
	MOVE.W	#$00C0,D7
	MOVE.L	#transferBuffer,A6
	JSR	sendLeagueDataPacket
	BMI	lbC049814
	JSR	synchronizeNetworkSetup
	JSR	networkTimingSync0
	JSR	receiveAdditionalSyncData
lbC049844:
	JSR	networkTimingSync2
	RTS

sendLeagueDataPacket:
	MOVE.W	#$16D9,D0
	JSR	sendSerialWordWithChecksum
	MOVE.B	#$A8,D0
	JSR	sendSerialByteWithChecksum
	CLR.W	checksumAccumulator
lbC049866:
	MOVE.B	(A6)+,D0
	JSR	sendSerialByteWithChecksum
	DBRA	D7,lbC049866
	MOVE.W	checksumAccumulator,D0
	JSR	sendSerialWordWithChecksum
	MOVE.B	#$C1,networkProtocolState
	JSR	waitForNetworkHandshake
	BCS	lbC049898
	MOVE.B	receivedPlayerState,D0
	RTS

lbC049898:
	MOVE.B	#$80,D0
	RTS

receiveLeagueDataPacket:
	MOVE.W	#$0000,networkDataCounter2
lbC0498A6:
	CMP.W	#$000A,networkDataCounter2
	BLT	lbC0498D6
	JSR	checkSpaceKeyPressed
	BEQ	lbC049948
	MOVE.B	#$88,networkProtocolState
	JSR	sendNetworkGamePacket
	CLR.B	networkProtocolState
	CLR.W	networkDataCounter2
lbC0498D6:
	JSR	waitForNetworkByte
	MOVE.B	D0,D0
	CMP.B	#$16,D0
	BNE	lbC0498A6
	JSR	waitForNetworkByte
	MOVE.B	D0,D0
	CMP.B	#$D9,D0
	BNE	lbC0498A6
	JSR	waitForNetworkByte
	MOVE.B	D0,D0
	CMP.B	#$A8,D0
	BNE	lbC0498A6
	CLR.W	networkDataCounter1
lbC04990C:
	JSR	waitForNetworkByte
	MOVE.B	D0,D0
	MOVE.B	D0,(A6)+
	DBRA	D7,lbC04990C
	MOVE.W	networkDataCounter1,savedNetworkCounter
	JSR	waitForNetworkByte
	MOVE.B	D0,D5
	ASL.W	#$08,D5
	JSR	waitForNetworkByte
	MOVE.B	D0,D5
	CMP.W	savedNetworkCounter,D5
	BNE	lbC049948
	MOVE.B	#$33,D0
	BRA	lbC04994C

lbC049948:
	MOVE.B	#$99,D0
lbC04994C:
	MOVE.B	D0,localPlayerStateCache
	MOVE.W	D0,-(SP)
	MOVE.B	#$C1,networkProtocolState
	JSR	waitForNetworkHandshake
	BCS	lbC04996C
	MOVE.W	(SP)+,D0
	TST.B	D0
	RTS

lbC04996C:
	MOVE.W	(SP)+,D0
	MOVE.B	#$80,D0
	RTS

togglePlayerContext:
	TST.B	networkGameMode
	BEQ	lbC0499D4
	CMP.B	#$01,D1
	BNE	lbC0499D4
	CMP.B	#$01,player2LapCounter
	BEQ	lbC0499D4
	MOVE.B	player1LapCounter,lbB0499D6
	MOVE.B	currentPlayerID,lbB0499D7
	MOVE.B	player2LapCounter,player1LapCounter
	MOVE.B	opponentID,currentPlayerID
	JSR	updateRaceRecords
	MOVE.B	lbB0499D6,player1LapCounter
	MOVE.B	lbB0499D7,currentPlayerID
lbC0499D4:
	RTS

lbC0499D8:
	MOVE.L	#lbW049A46,A2
	MOVE.L	#lbW049A4E,A1
	MOVE.L	#lbW049A56,A0
	MOVE.W	totalRaceCounter,D3
	CLR.W	D0
	MOVE.B	additionalPlayerCount,D0
	CLR.W	D5
	MOVE.B	$00(A1,D0.W),D5
	CLR.W	D2
	MOVE.B	$00(A2,D0.W),D2
	LEA	$00(A0,D2.W),A0
lbC049A08:
	CMP.W	D5,D3
	BLT	lbC049A14
	SUB.W	D5,D3
	BRA	lbC049A08

lbC049A14:
	ASL.W	#$01,D3
	MOVE.B	#$0B,D0
	SUB.B	$00(A0,D3.W),D0
	MOVE.B	#$0B,D1
	SUB.B	$01(A0,D3.W),D1
	TST.B	networkGameMode
	BMI	lbC049A32
	EXG	D0,D1
lbC049A32:
	MOVE.B	D0,player1ID
	MOVE.B	D0,currentPlayerID
	MOVE.B	D1,player2ID
	RTS

displayWaitMessage:
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	displayFrameBuffer,renderFrameBuffer
	JSR	drawScreenFrame
	MOVE.B	#$01,currentMenuItem
	JSR	renderMenuCursorAndAdvance
	MOVE.W	#$002E,D3
	JSR	displayLeagueMessage
	JSR	resetTextYOffset
	MOVE.L	(SP)+,renderFrameBuffer
	RTS

synchronizeNetworkGame:
	CMP.B	#$80,networkGameMode
	BNE	synchronizeNetworkSetup
	MOVE.B	writeMode,D0
	OR.B	#$10,D0
	TST.B	directionalInputBits
	BPL	lbC049B60
	BSET	#$03,D0
lbC049B60:
	MOVE.B	D0,localInputStateCache
	MOVE.B	leagueSessionMode,localPlayerStateCache
	MOVE.B	#$B2,networkProtocolState
	JSR	waitForNetworkHandshake
	TST.B	writeMode
	BNE	lbC049BF2
	TST.B	directionalInputBits
	BNE	lbC049BF2
synchronizeNetworkSetup:
	JSR	checkSpaceKeyPressed
	BEQ	lbC049BF2
	TST.B	leagueSessionMode
	BNE	lbC049BB4
	MOVE.L	#currentDivision,A6
	MOVE.W	#$0002,D7
	BRA	lbC049BE8

lbC049BB4:
	MOVE.B	#$01,writeMode
	MOVE.B	#$01,D0
	JSR	syncMultiplayerRecords
	MOVE.B	#$00,writeMode
	MOVE.L	#transferBuffer,A6
	MOVE.W	#$00FF,D7
	CMP.B	#$40,leagueSessionMode
	BNE	lbC049BE8
	MOVE.W	#$01FF,D7
lbC049BE8:
	JSR	sendLeagueDataPacket
	BMI	synchronizeNetworkSetup
lbC049BF2:
	RTS

lbC049BF4:
	MOVE.B	#$00,lbB00D494
	JSR	displayWaitMessage
	MOVE.B	#$B2,networkProtocolState
	JSR	waitForNetworkHandshake
	JSR	checkSpaceKeyPressed
	BEQ	lbC049C42
	MOVE.B	receivedPlayerState,leagueSessionMode
	MOVE.B	receivedInputState,D0
	BPL	lbC049C4A
	JSR	initializeGameTables
	MOVE.B	receivedInputState,D0
	CMP.B	#$C0,D0
	BNE	lbC049C46
lbC049C42:
	BRA	lbC04D48C

lbC049C46:
	BRA	lbC04D4B2

lbC049C4A:
	CMP.B	#$20,D0
	BEQ	lbC04D3E4
	BTST	#$04,D0
	BEQ	lbC049C78
	BTST	#$03,D0
	BNE	lbC049C78
	BTST	#$00,D0
	BNE	lbC049C78
	MOVE.B	#$00,writeMode
	JSR	receiveAdditionalSyncData
lbC049C78:
	JMP	lbC04D590

receiveAdditionalSyncData:
	JSR	checkSpaceKeyPressed
	BEQ	lbC049CE6
	MOVE.W	#$0002,D7
	MOVE.L	#transferBuffer,A6
	TST.B	leagueSessionMode
	BEQ	lbC049CB0
	MOVE.W	#$00FF,D7
	CMP.B	#$40,leagueSessionMode
	BNE	lbC049CB0
	MOVE.W	#$01FF,D7
lbC049CB0:
	JSR	receiveLeagueDataPacket
	BMI	receiveAdditionalSyncData
	TST.B	leagueSessionMode
	BNE	lbC049CDC
	MOVE.L	#currentDivision,A0
	MOVE.L	#transferBuffer,A6
	MOVE.W	#$0002,D7
lbC049CD4:
	MOVE.B	(A6)+,(A0)+
	DBRA	D7,lbC049CD4
	RTS

lbC049CDC:
	MOVE.B	#$00,D0
	JSR	syncMultiplayerRecords
lbC049CE6:
	RTS

lbC049CE8:
	TST.B	networkGameMode
	BEQ	lbC049D70
	JSR	encodeControlKeysToIndices
	TST.B	networkGameMode
	BMI	lbC049D48
lbC049D02:
	JSR	checkSpaceKeyPressed
	BEQ	lbC049D70
	MOVE.L	#transferBuffer,A6
	MOVE.W	#$0004,D7
	JSR	receiveLeagueDataPacket
	BMI	lbC049D02
	JSR	decodeControlIndicesToKeys
	MOVE.B	opponentID,D0
	JSR	calculatePlayerDataOffset
	MOVE.L	#transferBuffer,A1
	JSR	copyBytesReverse
	TST.B	networkGameMode
	BMI	lbC049D70
lbC049D48:
	JSR	checkSpaceKeyPressed
	BEQ	lbC049D70
	MOVE.L	#encodedControlIndices,A6
	MOVE.W	#$0004,D7
	JSR	sendLeagueDataPacket
	BMI	lbC049D48
	TST.B	networkGameMode
	BMI	lbC049D02
lbC049D70:
	RTS

calculatePlayerDataOffset:
	SUBQ.B	#$04,D0
	MOVE.B	D0,D3
	ASL.B	#$02,D0
	ADD.B	D3,D0
	ADDQ.B	#$04,D0
	MOVE.B	D0,D2
	MOVE.B	#$04,D1
	MOVE.L	#playersControlKeys,A2
	RTS

copyBytesReverse:
	MOVE.B	$00(A1,D1.W),$00(A2,D2.W)
	SUBQ.B	#$01,D2
	SUBQ.B	#$01,D1
	BPL	copyBytesReverse
	RTS

encodeControlKeysToIndices:
	MOVE.L	#keyboardMatrixTable,A0
	MOVE.L	#controlKeys,A1
	MOVE.L	#encodedControlIndices,A2
	MOVE.W	#$0004,D3
lbC049DB6:
	MOVE.B	$00(A1,D3.W),D0
	MOVE.W	#$0000,D2
lbC049DBE:
	CMP.B	$00(A0,D2.W),D0
	BEQ	lbC049DD4
	ADDQ.B	#$01,D2
	CMP.B	#$80,D2
	BNE	lbC049DBE
	MOVE.B	#$00,D2
lbC049DD4:
	MOVE.B	D2,$00(A2,D3.W)
	DBRA	D3,lbC049DB6
	RTS

decodeControlIndicesToKeys:
	MOVE.L	#transferBuffer,A0
	MOVE.L	#keyboardMatrixTable,A2
	CLR.W	D0
	MOVE.W	#$0004,D3
lbC049DF0:
	MOVE.B	$00(A0,D3.W),D0
	MOVE.B	$00(A2,D0.W),$00(A0,D3.W)
	DBRA	D3,lbC049DF0
	RTS

checkRaceStartReady:
	MOVE.B	#$50,D1
	JSR	checkKeyPressed
	BEQ	lbC049E9A
	MOVE.B	#$80,localPlayerReadyFlag
	BRA	lbC049EA2

lbC049E9A:
	MOVE.B	#$00,localPlayerReadyFlag
lbC049EA2:
	TST.B	networkGameMode
	BEQ	lbC049EF8
	CMP.B	#$02,additionalPlayerCount
	BGE	lbC049EC2
	MOVE.B	#$80,localPlayerReadyFlag
	RTS

lbC049EC2:
	TST.B	networkGameMode
	BPL	lbC049ED6
	MOVE.B	localPlayerReadyFlag,localInputStateCache
lbC049ED6:
	MOVE.B	#$F4,networkProtocolState
	JSR	waitForNetworkHandshake
	TST.B	networkGameMode
	BMI	lbC049EF8
	MOVE.B	receivedInputState,localPlayerReadyFlag
lbC049EF8:
	TST.B	localPlayerReadyFlag
	RTS

updateOpponentVisibility:
	MOVE.B	#$00,opponentRelativePosition
	TST.B	networkGameMode
	BEQ	lbC049F40
	MOVE.W	opponentDistanceOffset,D0
	BPL	lbC049F42
	NEG.W	D0
	CMP.W	#$003C,D0
	BLT	lbC049F40
	MOVE.B	#$80,opponentRelativePosition
lbC049F2E:
	MOVE.W	opponentSegmentQueueOffset,D0
	BMI	lbC049F40
	ADD.W	#$0020,opponentSegmentQueueOffset
lbC049F40:
	RTS

lbC049F42:
	SUB.W	#$0100,D0
	CMP.W	#$003C,D0
	BLT	lbC049F40
	MOVE.B	#$01,opponentRelativePosition
	BRA	lbC049F2E

saveLapTimeToBuffer:
	MOVE.B	playerStatsArray,lbB04956B
	MOVE.B	lapTimeSeconds,lbB04956C
	MOVE.B	lapTimeSubseconds,lbB04956D
	RTS

synchronizeRaceData:
	TST.B	networkGameMode
	BEQ	lbC04A056
	BMI	lbC049FF4
lbC049F88:
	JSR	checkSpaceKeyPressed
	BEQ	lbC04A056
	MOVE.L	#transferBuffer,A6
	MOVE.W	#$0063,D7
	JSR	receiveLeagueDataPacket
	BMI	lbC049F88
	MOVE.L	#playerStatsArray,A0
	MOVE.L	#transferBuffer,A6
	MOVE.W	#$0047,D7
lbC049FB6:
	MOVE.B	(A6)+,(A0)+
	DBRA	D7,lbC049FB6
	MOVE.B	(A6)+,raceOutcomeFlags
	EOR.B	#$C0,raceOutcomeFlags
	MOVE.B	(A6)+,displayFlags
	MOVE.B	(A6)+,bestLapRecordHolder
	MOVE.B	(A6)+,bestRaceRecordHolder
	MOVE.L	#lbL050548,A0
	MOVE.W	#$000B,D7
lbC049FE6:
	MOVE.B	$000C(A6),$000D(A0)
	MOVE.B	(A6)+,(A0)+
	DBRA	D7,lbC049FE6
	RTS

lbC049FF4:
	MOVE.L	#transferBuffer,A6
	MOVE.L	#playerStatsArray,A0
	MOVE.W	#$0047,D7
copyRaceDataToNetworkBuffer:
	MOVE.B	(A0)+,(A6)+
	DBRA	D7,copyRaceDataToNetworkBuffer
	MOVE.B	raceOutcomeFlags,(A6)+
	MOVE.B	displayFlags,(A6)+
	MOVE.B	bestLapRecordHolder,(A6)+
	MOVE.B	bestRaceRecordHolder,(A6)+
	MOVE.L	#lbL050548,A0
	MOVE.W	#$000B,D7
lbC04A02C:
	MOVE.B	$000D(A0),$000C(A6)
	MOVE.B	(A0)+,(A6)+
	DBRA	D7,lbC04A02C
lbC04A038:
	JSR	checkSpaceKeyPressed
	BEQ	lbC04A056
	MOVE.L	#transferBuffer,A6
	MOVE.W	#$0063,D7
	JSR	sendLeagueDataPacket
	BMI	lbC04A038
lbC04A056:
	RTS

checkMultiplayerTrackSwap:
	TST.B	networkGameMode
	BEQ	lbC04A09C
	TST.B	raceStartComplete
	BPL	lbC04A09C
	MOVE.B	multiplayerSyncFlag,D0
	BPL	lbC04A09C
	ASL.B	#$01,D0
	MOVE.B	playerSegmentIndex,D3
	CMP.B	opponentSegmentIndex,D3
	BNE	lbC04A09C
	MOVE.B	trackSideIndicator,D3
	EOR.B	D3,D0
	BMI	lbC04A09C
	EOR.B	#$80,trackSideIndicator
lbC04A09C:
	RTS

displayRacePositions:
	TST.B	networkGameMode
	BEQ	lbC04A0EE
	MOVE.L	#playerStatsArray,A0
	MOVE.L	#lapTimeSeconds,A1
	MOVE.L	#lapTimeSubseconds,A2
	MOVE.L	#lbL04A180,A3
	TST.B	D0
	BMI	lbC04A0F0
	MOVE.B	currentPlayerID,D1
	ADD.B	#$0C,D1
	MOVE.B	#$00,D2
	JSR	copyStatsFromBuffers
	MOVE.B	opponentID,D1
	ADD.B	#$0C,D1
	MOVE.B	#$01,D2
	JSR	copyStatsFromBuffers
lbC04A0EE:
	RTS

lbC04A0F0:
	MOVE.B	currentPlayerID,D2
	ADD.B	#$0C,D2
	MOVE.B	#$00,D1
	JSR	compareAndUpdatePlayerStats
	MOVE.B	opponentID,D2
	ADD.B	#$0C,D2
	MOVE.B	#$01,D1
compareAndUpdatePlayerStats:
	TST.B	$00(A3,D1.W)
	BEQ	lbC04A156
	TST.B	$00(A0,D2.W)
	BNE	lbC04A126
	BRA	copyStatsToBuffers

lbC04A126:
	MOVE.W	D2,-(SP)
	MOVE.B	#$03,D2
	JSR	copyStatsToBuffers
	MOVE.W	#$0003,D1
	MOVE.W	(SP)+,D2
	JSR	compareAndCopyPlayerStats
	MOVE.L	#playerStatsArray,A0
	MOVE.L	#lapTimeSeconds,A1
	MOVE.L	#lapTimeSubseconds,A2
	MOVE.L	#lbL04A180,A3
lbC04A156:
	RTS

copyStatsToBuffers:
	MOVE.B	$00(A3,D1.W),$00(A0,D2.W)
	MOVE.B	$02(A3,D1.W),$00(A1,D2.W)
	MOVE.B	$04(A3,D1.W),$00(A2,D2.W)
	RTS

copyStatsFromBuffers:
	MOVE.B	$00(A0,D1.W),$00(A3,D2.W)
	MOVE.B	$00(A1,D1.W),$02(A3,D2.W)
	MOVE.B	$00(A2,D1.W),$04(A3,D2.W)
	RTS

displaySinglePlayerResults:
	MOVE.W	imagePlayersPalette,D0
	JSR	fadeToColor
	MOVE.L	#imagePlayersPalette,A1
	JSR	copyPalette
	MOVE.L	#imagePlayers,A1
	MOVE.L	displayFrameBuffer,A0
	MOVE.L	A0,A3
	ADD.L	#$00001F40,A3
lbC04A1B4:
	MOVE.W	(A1)+,(A0)+
	MOVE.W	(A1)+,$1F3E(A0)
	MOVE.W	(A1)+,$3E7E(A0)
	MOVE.W	(A1)+,$5DBE(A0)
	CMP.L	A3,A0
	BNE	lbC04A1B4
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	displayFrameBuffer,renderFrameBuffer
	MOVE.L	#leagueStandingsTable,A6
	MOVE.W	#$0000,D6
lbC04A1E2:
	MOVE.B	$00(A6,D6.W),D0
	MOVE.B	D6,D3
	ADD.B	#$13,D3
	JSR	renderPlayerDisplay
	ADDQ.B	#$01,D6
	CMP.B	#$0C,D6
	BLT	lbC04A1E2
	MOVE.L	(SP)+,renderFrameBuffer
	JSR	animatePaletteToTarget
	JSR	waitForFireButtonPress
	JMP	displayMenuScreen

renderRaceMatchupPortraits:
	JSR	configurePlayersAndCars
	MOVE.B	player1ID,D0
	MOVE.B	#$0C,D3
	JSR	renderPlayerDisplay
	MOVE.B	player2ID,D0
	MOVE.B	#$0D,D3
	JSR	renderPlayerDisplay
	RTS

renderPlayerDisplay:
	MOVE.B	D0,lbB04A4BB
	MOVE.W	D6,-(SP)
	MOVE.L	A6,-(SP)
	TST.B	additionalPlayerCount
	BEQ	lbC04A27A
	TST.B	networkGameMode
	BEQ	setupPlayerGraphics
lbC04A25A:
	MOVE.B	#$0B,D0
	BRA	lbC04A27A

setupPlayerGraphics:
	CMP.B	currentPlayerID,D0
	BEQ	lbC04A25A
	AND.W	#$0001,D0
	MOVE.L	#lbW04AA40,A0
	MOVE.B	$00(A0,D0.W),D0
lbC04A27A:
	CMP.B	#$0C,D0
	BGE	lbC04A39C
	CMP.B	#$1F,D3
	BGE	lbC04A39C
	MOVE.B	D0,lbB04A3A2
	MOVE.L	#lbW04A420,A0
	AND.W	#$000F,D0
	MOVE.B	$00(A0,D0.W),D0
	MOVE.L	#imagePlayers,A0
	MOVE.L	renderFrameBuffer,A3
	MOVE.L	#lbW04A3A4,A1
	AND.W	#$00FF,D0
	AND.W	#$00FF,D3
	ASL.W	#$02,D0
	ASL.W	#$02,D3
	ADD.L	$00(A1,D0.W),A0
	ADD.L	$00(A1,D3.W),A3
	MOVE.L	A3,playerNameRenderingPosition
	TST.B	lbB04A4BA
	BEQ	renderPlayerGraphicsToScreen
	JSR	applyPlayerGraphicsMasks
	BRA	lbC04A38A

renderPlayerGraphicsToScreen:
	MOVE.B	#$00,lbB04A4C8
	TST.B	additionalPlayerCount
	BEQ	lbC04A330
	CMP.B	#$0B,lbB04A3A2
	BNE	lbC04A330
	MOVE.B	#$80,lbB04A4C8
	MOVE.B	lbB04A4BB,D1
	MOVE.L	#lbL04A4BC,A2
	MOVE.B	$00(A2,D1.W),D0
	JSR	setupBitplaneMasks
	MOVE.L	D6,bitplaneMask1
	MOVE.L	D7,bitplaneMask2
	MOVE.L	#playerGraphicsMask,bitplaneMaskPointer
lbC04A330:
	MOVE.W	#$0036,D5
lbC04A334:
	MOVE.W	#$0004,D3
lbC04A338:
	TST.B	lbB04A4C8
	BEQ	lbC04A368
	MOVE.L	(A0)+,D0
	JSR	applyBitplaneMask1
	MOVE.W	D0,$1F40(A3)
	SWAP	D0
	MOVE.W	D0,(A3)+
	MOVE.L	(A0)+,D0
	JSR	applyBitplaneMask2
	MOVE.W	D0,$5DBE(A3)
	SWAP	D0
	MOVE.W	D0,$3E7E(A3)
	BRA	lbC04A376

lbC04A368:
	MOVE.W	(A0)+,(A3)+
	MOVE.W	(A0)+,$1F3E(A3)
	MOVE.W	(A0)+,$3E7E(A3)
	MOVE.W	(A0)+,$5DBE(A3)
lbC04A376:
	DBRA	D3,lbC04A338
	ADD.L	#$00000078,A0
	ADD.L	#$0000001E,A3
	DBRA	D5,lbC04A334
lbC04A38A:
	CMP.B	#$0B,lbB04A3A2
	BNE	lbC04A39C
	JSR	displayPlayerName
lbC04A39C:
	MOVE.L	(SP)+,A6
	MOVE.W	(SP)+,D6
	RTS

applyPlayerGraphicsMasks:
	MOVE.B	lbB04A4BA,D3
	AND.L	#$0000000F,D3
	MOVE.B	#$36,tempByte4
	MOVE.L	A0,A5
	MOVE.L	A3,A0
lbC04A444:
	MOVE.W	#$0000,D1
	MOVE.L	#lbW04A49A,A2
lbC04A44E:
	MOVE.W	#$0008,renderGraphicsCurrentX
	MOVE.L	#lbL04A4AE,A1
	MOVE.L	(A2)+,D0
	MOVE.W	D0,(A1)
	MOVE.L	(A5)+,$0002(A1)
	MOVE.L	(A5)+,$0006(A1)
	NOT.L	D0
	AND.L	D0,$0002(A1)
	AND.L	D0,$0006(A1)
	JSR	renderObjectColumn
	ADDQ.B	#$01,D1
	CMP.B	#$05,D1
	BLT	lbC04A44E
	ADD.L	#$00000078,A5
	ADD.L	#$0000001E,A0
	SUBQ.B	#$01,tempByte4
	BPL	lbC04A444
	RTS

applyBitplaneMask1:
	MOVE.L	bitplaneMaskPointer,A4
	MOVE.W	(A4),D4
	SWAP	D4
	MOVE.W	(A4)+,D4
	MOVE.L	A4,bitplaneMaskPointer
	AND.L	D4,D0
	MOVE.L	bitplaneMask1,D6
	NOT.L	D4
	AND.L	D4,D6
	OR.L	D6,D0
	NOT.L	D4
	RTS

applyBitplaneMask2:
	AND.L	D4,D0
	MOVE.L	bitplaneMask2,D6
	NOT.L	D4
	AND.L	D4,D6
	OR.L	D6,D0
	RTS

displaySeriesProgressIndicator:
	MOVE.B	D0,lbB055C63
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.B	#$0D,D1
	JSR	renderLeagueText
	MOVE.B	raceSeriesProgress,D0
	ADDQ.B	#$01,D0
	JSR	renderDecimalCompact
	MOVE.B	#$F4,D1
	JSR	renderLeagueText
	MOVE.B	raceCount,D0
	TST.B	additionalPlayerCount
	BEQ	lbC04A774
	ASL.B	#$01,D0
lbC04A774:
	JMP	renderDecimalCompact

renderPreRaceMatchupScreen:
	TST.B	raceMatchupScreenTypeFlag
	BMI	renderAlternateMatchupLayout
	JSR	resetTextYOffset
	MOVE.B	#$0B,D0
	JSR	displaySeriesProgressIndicator
	MOVE.W	#$0000,D3
	JSR	renderTextFromTable
	JSR	renderRaceMatchupPortraits
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	JSR	resetTextYOffset
	MOVE.B	#$14,D2
	JSR	renderTrackInfoDisplay
	MOVE.B	#$80,D0
	JSR	transferLapRecords
	JSR	displayRecordAchievements
	JMP	presentFrameBufferAndWaitForFire

renderAlternateMatchupLayout:
	JSR	setTextYOffset4
	MOVE.B	#$0A,D0
	JSR	displaySeriesProgressIndicator
	JSR	configurePlayersAndCars
	MOVE.B	#$11,D0
	JSR	displayPlayerMatchupScreen
	JSR	resetTextYOffset
	MOVE.B	#$60,D1
	JSR	renderLeagueText
	JSR	setTextYOffset4
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.W	#$0005,D3
	JSR	renderTextFromTable
	MOVE.B	lbB00E325,D0
	MOVE.B	#$0E,D3
	JSR	renderPlayerDisplay
	MOVE.B	lbB00E326,D0
	MOVE.B	#$0F,D3
	JSR	renderPlayerDisplay
	JMP	presentFrameBufferAndWaitForFire

displayLeagueStandingsTable:
	MOVE.L	#sortedRaceStandings,A6
	CLR.W	D6
	MOVE.B	renderingIndex,D6
	MOVE.B	#$0E,lbB04A4BA
	MOVE.B	$00(A6,D6.W),D0
	MOVE.B	#$10,D3
	JSR	renderPlayerDisplay
	MOVE.B	#$09,lbB04A4BA
	MOVE.B	$01(A6,D6.W),D0
	MOVE.B	#$11,D3
	JSR	renderPlayerDisplay
	MOVE.B	#$04,lbB04A4BA
	MOVE.B	$02(A6,D6.W),D0
	MOVE.B	#$12,D3
	JSR	renderPlayerDisplay
	MOVE.B	#$00,lbB04A4BA
	JSR	setTextYOffset4
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.W	#$0049,D3
	MOVE.B	#$04,textHorizontalOffset
	JSR	renderTextFromTable
	CLR.B	textHorizontalOffset
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	MOVE.B	#$04,lbB04AA3E
.renderRowLoop:
	MOVE.B	renderingIndex,D2
	MOVE.L	#sortedRaceStandings,A2
	MOVE.B	$00(A2,D2.W),tempByte5
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	MOVE.B	lbB04AA3E,D1
	MOVE.B	#$13,D2
	JSR	setTextPosition
	JSR	setTextYOffset4
	MOVE.W	#$0025,D3
	JSR	renderTextFromTable
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.L	#raceParticipationCounters,A1
	CLR.W	D0
	MOVE.B	tempByte5,D0
	MOVE.B	$00(A1,D0.W),D0
	JSR	renderDecimal
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	MOVE.B	lbB04AA3E,D1
	MOVE.B	#$15,D2
	JSR	setTextPosition
	JSR	resetTextYOffset
	MOVE.W	#$002E,D3
	JSR	renderTextFromTable
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.L	#playerRaceWins,A1
	CLR.W	D0
	MOVE.B	tempByte5,D0
	MOVE.B	$00(A1,D0.W),D0
	JSR	renderDecimal
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	MOVE.B	lbB04AA3E,D1
	MOVE.B	#$16,D2
	JSR	setTextPosition
	JSR	setTextYOffset4
	MOVE.W	#$0037,D3
	JSR	renderTextFromTable
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.L	#playerSecondPlaceFinishes,A1
	CLR.W	D0
	MOVE.B	tempByte5,D0
	MOVE.B	$00(A1,D0.W),D0
	JSR	renderDecimal
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	MOVE.B	lbB04AA3E,D1
	MOVE.B	#$18,D2
	JSR	setTextPosition
	JSR	resetTextYOffset
	MOVE.W	#$0040,D3
	JSR	renderTextFromTable
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.L	#playerRankingScores,A1
	CLR.W	D0
	MOVE.B	tempByte5,D0
	MOVE.B	$00(A1,D0.W),D0
	JSR	renderDecimal
	ADD.B	#$0B,lbB04AA3E
	ADDQ.B	#$01,renderingIndex
	MOVE.B	renderingIndex,D0
	CMP.B	maxRenderingIndex,D0
	BNE	.renderRowLoop
	JMP	presentFrameBufferAndWaitForFire

renderTableTextCharacter:
	JSR	renderCharacter
	ADDQ.W	#$01,D3
renderTextFromTable:
	MOVE.L	#leagueStatisticsTextTable,A0
	MOVE.B	$00(A0,D3.W),D0
	CMP.B	#$FF,D0
	BNE	renderTableTextCharacter
	RTS

calculateAlternateFontOffset:
	AND.W	#$007F,D0
	MOVE.L	#alternateFontBitmapData,A0
lbC04AAD0:
	CMP.B	#$20,D0
	BLT	lbC04AAE6
	SUB.B	#$20,D0
	ADD.L	#$00000F00,A0
	BRA	lbC04AAD0

lbC04AAE6:
	MOVE.W	#$0006,D3
	MULU	D3,D0
	MOVE.W	D0,D3
	LSR.W	#$04,D3
	AND.W	#$000F,D0
	BRA	lbC04AAFE

lbC04AAF8:
	ADD.L	#$00000008,A0
lbC04AAFE:
	DBRA	D3,lbC04AAF8
	MOVE.B	D0,lbB04AB4B
	RTS

extractAlternateFontScanline:
	MOVE.W	#$0005,D5
	MOVE.B	lbB04AB4B,D0
	EOR.B	#$0F,D0
	AND.L	#$0000000F,D0
	MOVE.W	(A0),D4
	CLR.L	D7
lbC04AB22:
	BTST	D0,D4
	BEQ	lbC04AB2C
	BSET	#$00,D7
lbC04AB2C:
	ASL.B	#$01,D7
	SUBQ.B	#$01,D0
	BPL	lbC04AB3C
	MOVE.W	$0008(A0),D4
	MOVE.B	#$0F,D0
lbC04AB3C:
	DBRA	D5,lbC04AB22
	ASL.B	#$01,D7
	ADD.L	#$000000A0,A0
	RTS

displayPlayerName:
	MOVE.B	textTransparencyMode,D0
	MOVE.W	D0,-(SP)
	MOVE.B	#$80,textTransparencyMode
	MOVE.L	playerNameRenderingPosition,D0
	ADD.L	#$000006E0,D0
	MOVE.L	D0,playerNameRenderingPosition
	MOVE.B	lbB04A4BA,textHorizontalOffset
	ADDQ.B	#$03,textHorizontalOffset
	MOVE.B	#$80,useAlternateFontFlag
	MOVE.B	lbB04A4BB,D1
	ASL.B	#$04,D1
	MOVE.L	#playerNamesWithSpaces,A0
	LEA	$01(A0,D1.W),A0
	MOVE.B	#$00,D0
	MOVE.W	#$000B,D3
lbC04ABA4:
	CMP.B	#$20,$00(A0,D3.W)
	BNE	lbC04ABB4
	ADDQ.B	#$01,D0
	DBRA	D3,lbC04ABA4
lbC04ABB4:
	LSR.B	#$01,D0
	MOVE.B	D0,D1
	MOVE.B	#$00,D2
	JSR	setTextPosition
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	JSR	resetTextYOffset
	MOVE.B	lbB04A4BB,D1
	ASL.B	#$04,D1
	MOVE.W	#$000C,D2
lbC04ABDE:
	MOVE.L	#playerNamesWithSpaces,A0
	MOVE.B	$01(A0,D1.W),D0
	JSR	renderCharacter
	ADDQ.B	#$01,D1
	SUBQ.B	#$01,D2
	BNE	lbC04ABDE
	CLR.B	textHorizontalOffset
	CLR.B	useAlternateFontFlag
	MOVE.W	(SP)+,D0
	MOVE.B	D0,textTransparencyMode
	RTS

displayRaceEndScreen:
	MOVE.L	#$00000001,D0
	TST.B	raceOutcomeFlags
	BPL	lbC04AC32
	MOVE.L	#$00000002,D0
	TST.B	postWreckStateFlag
	BEQ	lbC04AC32
	CLR.L	D0
	MOVE.B	#$03,D0
lbC04AC32:
	JSR	displayResultScreen
	RTS

displayAlternateEndScreen:
	TST.B	alternateEndScreenEnabledFlag
	BMI	lbC04AC50
	MOVE.L	#$00000004,D0
	JMP	displayResultScreen

lbC04AC50:
	RTS

displayResultScreen:
	ASL.W	#$02,D0
	MOVE.W	D0,-(SP)
	MOVE.W	#$0000,D0
	JSR	fadeToColor
	MOVE.W	(SP)+,D0
	MOVE.L	#resultScreenPointerTable,A0
	MOVE.L	$00(A0,D0.W),A6
	LEA	$0002(A6),A1
	JSR	copyPalette
	LEA	$0022(A6),A0
	MOVE.L	displayFrameBuffer,A1
	TST.B	(A6)
	BPL	.copyRawImage
	JSR	decompressRLEImage
	BRA	.imageOk

.copyRawImage:
	MOVE.L	A1,A3
	ADD.L	#$00001F40,A3
.copyLoop:
	MOVE.W	(A0)+,(A1)+
	MOVE.W	(A0)+,$1F3E(A1)
	MOVE.W	(A0)+,$3E7E(A1)
	MOVE.W	(A0)+,$5DBE(A1)
	CMP.L	A3,A1
	BNE	.copyLoop
.imageOk:
	JSR	animatePaletteToTarget
	JSR	waitForFireButtonPress
	RTS

copyTrackPreviewRegion:
	MOVE.L	frameBuffers,A0
	MOVE.L	displayFrameBuffer,A3
	ADD.L	#$00000140,A0
	ADD.L	#$00000140,A3
	MOVE.L	A0,A2
	ADD.L	#$00001540,A2
.copyLoop:
	MOVE.W	(A0)+,(A3)+
	MOVE.W	$1F3E(A0),$1F3E(A3)
	MOVE.W	$3E7E(A0),$3E7E(A3)
	MOVE.W	$5DBE(A0),$5DBE(A3)
	CMP.L	A2,A0
	BLT	.copyLoop
	RTS

decompressRLEImage:
	MOVE.L	A1,A2
	MOVE.W	#$00C7,D6
lbC04ACFE:
	MOVE.W	#$0003,D5
lbC04AD02:
	MOVE.L	A2,A1
	ADD.L	#$00001F40,A2
	MOVE.W	#$0000,D3
lbC04AD0E:
	MOVE.B	(A0)+,D0
	BPL	lbC04AD2C
	NEG.B	D0
	BMI	lbC04AD0E
	AND.W	#$00FF,D0
	MOVE.B	(A0)+,D4
lbC04AD20:
	MOVE.B	D4,(A1)+
	ADDQ.B	#$01,D3
	DBRA	D0,lbC04AD20
	BRA	lbC04AD38

lbC04AD2C:
	AND.W	#$00FF,D0
lbC04AD30:
	MOVE.B	(A0)+,(A1)+
	ADDQ.B	#$01,D3
	DBRA	D0,lbC04AD30
lbC04AD38:
	CMP.B	#$28,D3
	BNE	lbC04AD0E
	DBRA	D5,lbC04AD02
	ADD.L	#$FFFF8328,A2
	DBRA	D6,lbC04ACFE
	RTS

decompressRLEObjectToMask:
	MOVE.L	A1,A2
	MOVE.W	#$00C7,D6
lbC04AD56:
	MOVE.W	#$0003,D5
lbC04AD5A:
	MOVE.L	A2,A1
	ADD.L	#$00000002,A2
	MOVE.W	#$0000,D3
lbC04AD66:
	MOVE.B	(A0)+,D0
	BPL	lbC04AD92
	NEG.B	D0
	BMI	lbC04AD66
	AND.W	#$00FF,D0
	MOVE.B	(A0)+,D4
lbC04AD78:
	MOVE.B	D4,(A1)+
	ADDQ.B	#$01,D3
	BTST	#$00,D3
	BNE	lbC04AD8A
	ADD.L	#$00000006,A1
lbC04AD8A:
	DBRA	D0,lbC04AD78
	BRA	lbC04ADAE

lbC04AD92:
	AND.W	#$00FF,D0
lbC04AD96:
	MOVE.B	(A0)+,D4
	MOVE.B	D4,(A1)+
	ADDQ.B	#$01,D3
	BTST	#$00,D3
	BNE	lbC04ADAA
	ADD.L	#$00000006,A1
lbC04ADAA:
	DBRA	D0,lbC04AD96
lbC04ADAE:
	CMP.B	#$28,D3
	BNE	lbC04AD66
	DBRA	D5,lbC04AD5A
	ADD.L	#$00000098,A2
	DBRA	D6,lbC04AD56
	RTS

renderCharacter:
	MOVEM.L	D0-D5/A0/A1,-(SP)
	JSR	processCharacterBuffer
	MOVEM.L	(SP)+,D0-D5/A0/A1
	RTS

processCharacterBuffer:
	TST.B	textControlCodeState
	BEQ	lbC04AE0C
	ADDQ.B	#$01,controlCodeByteCounter
	MOVE.B	controlCodeByteCounter,D3
	CMP.B	#$02,D3
	BEQ	lbC04ADFC
	MOVE.B	D0,textCursorColumn
	RTS

lbC04ADFC:
	MOVE.B	D0,textCursorRow
	MOVE.B	#$00,textControlCodeState
	RTS

lbC04AE0C:
	CMP.B	#$1F,D0
	BNE	lbC04AE24
	MOVE.B	D0,textControlCodeState
	MOVE.B	#$00,controlCodeByteCounter
	RTS

lbC04AE24:
	CMP.B	#$7F,D0
	BCS	lbC04AE64
	BNE	lbC04AE62
	SUBQ.B	#$01,textCursorColumn
	MOVE.B	textTransparencyMode,savedTransparencyFlag
	MOVE.B	#$00,textTransparencyMode
	MOVE.B	#$20,D0
	JSR	processCharacterBuffer
	MOVE.B	savedTransparencyFlag,textTransparencyMode
	SUBQ.B	#$01,textCursorColumn
lbC04AE62:
	RTS

lbC04AE64:
	SUB.B	#$20,D0
	MOVE.B	textCursorColumn,D3
	AND.W	#$00FF,D3
	MOVE.W	D3,D4
	ASL.W	#$03,D3
	SUB.W	D4,D3
	TST.B	useAlternateFontFlag
	BEQ	lbC04AE84
	SUB.W	D4,D3
lbC04AE84:
	MOVE.B	textHorizontalOffset,D4
	AND.W	#$00FF,D4
	ADD.W	D4,D3
	MOVE.W	D3,D4
	LSR.W	#$04,D4
	MOVE.B	D4,characterByteOffset
	MOVE.B	D3,D4
	AND.B	#$0F,D4
	MOVE.B	D4,characterPixelOffset
	AND.L	#$000000FF,D0
	TST.B	useAlternateFontFlag
	BEQ	calculateFontTableOffset
	JSR	calculateAlternateFontOffset
	BRA	calculateCharacterScreenAddress

calculateFontTableOffset:
	ASL.L	#$03,D0
	MOVE.L	#primaryFontBitmapData,A0
	ADD.L	D0,A0
calculateCharacterScreenAddress:
	MOVE.B	textCursorRow,D0
	ASL.B	#$03,D0
	ADD.B	textYOffset,D0
	AND.L	#$000000FF,D0
	MOVE.L	D0,D4
	ASL.L	#$02,D4
	ADD.L	D4,D0
	ASL.L	#$03,D0
	MOVE.L	frameBuffers,A1
	ADD.L	#$00007D00,A1
	TST.B	singleBufferRenderMode
	BPL	lbC04AF02
	tst.b	frameProcessingFlag		; added
	bmi.s	.fast
	MOVE.L	renderFrameBuffer,A1
	bra.s	lbC04AF02
.fast:	lea	fastRenderBuffer,a1
lbC04AF02:
	TST.B	useAlternateFontFlag
	BEQ	lbC04AF12
	MOVE.L	playerNameRenderingPosition,A1
lbC04AF12:
	ADD.L	D0,A1
	MOVE.B	characterByteOffset,D3
	AND.L	#$000000FF,D3
	ASL.L	#$01,D3
	ADD.L	D3,A1
	CMP.B	#$41,displayUpdateFlag
	BNE	lbC04AF40
	TST.B	useAlternateFontFlag
	BNE	lbC04AF40
	ADD.L	#$FFFFFEC0,A1
lbC04AF40:
	MOVE.B	#$08,D2
lbC04AF44:
	TST.B	useAlternateFontFlag
	BEQ	lbC04AF5E
	JSR	extractAlternateFontScanline
	MOVE.L	#$1F800,D5
	BRA	lbC04AF6C

lbC04AF5E:
	MOVE.B	(A0)+,D7
	AND.L	#$000000FF,D7
	MOVE.L	#$1FC00,D5
lbC04AF6C:
	ASL.L	#$08,D7
	ASL.L	#$01,D7
	MOVE.B	characterPixelOffset,D3
	EOR.B	#$0F,D3
	AND.L	#$0000000F,D3
	ASL.L	D3,D7
	ASL.L	D3,D5
	MOVE.L	D7,D6
	SWAP	D7
	MOVE.W	D7,D6
	MOVE.L	D5,D4
	SWAP	D5
	MOVE.W	D5,D4
	MOVE.L	foregroundColorMask1,D3
	AND.L	D4,D3
	NOT.L	D4
	MOVE.W	(A1),D0
	SWAP	D0
	MOVE.W	$1F40(A1),D0
	TST.B	textTransparencyMode
	BMI	lbC04AFB0
	AND.L	D4,D0
	OR.L	D3,D0
lbC04AFB0:
	MOVE.L	backgroundColorMask1,D3
	AND.L	D6,D3
	NOT.L	D6
	AND.L	D6,D0
	OR.L	D3,D0
	MOVE.W	D0,$1F40(A1)
	SWAP	D0
	MOVE.W	D0,(A1)
	TST.B	singleBufferRenderMode
	BMI	lbC04AFDA
	MOVE.W	D0,-$7D00(A1)
	SWAP	D0
	MOVE.W	D0,-$5DC0(A1)
lbC04AFDA:
	ADD.L	#$00003E80,A1
	NOT.L	D4
	NOT.L	D6
	MOVE.L	foregroundColorMask2,D3
	AND.L	D4,D3
	NOT.L	D4
	MOVE.W	(A1),D0
	SWAP	D0
	MOVE.W	$1F40(A1),D0
	TST.B	textTransparencyMode
	BMI	lbC04B004
	AND.L	D4,D0
	OR.L	D3,D0
lbC04B004:
	MOVE.L	backgroundColorMask2,D3
	AND.L	D6,D3
	NOT.L	D6
	AND.L	D6,D0
	OR.L	D3,D0
	MOVE.W	D0,$1F40(A1)
	SWAP	D0
	MOVE.W	D0,(A1)
	TST.B	singleBufferRenderMode
	BMI	lbC04B02E
	MOVE.W	D0,-$7D00(A1)
	SWAP	D0
	MOVE.W	D0,-$5DC0(A1)
lbC04B02E:
	ADD.L	#$FFFFC182,A1
	MOVE.L	D7,D6
	SWAP	D7
	MOVE.W	D7,D6
	MOVE.L	D5,D4
	SWAP	D5
	MOVE.W	D5,D4
	MOVE.L	foregroundColorMask1,D3
	AND.L	D4,D3
	NOT.L	D4
	MOVE.W	(A1),D0
	SWAP	D0
	MOVE.W	$1F40(A1),D0
	TST.B	textTransparencyMode
	BMI	lbC04B060
	AND.L	D4,D0
	OR.L	D3,D0
lbC04B060:
	MOVE.L	backgroundColorMask1,D3
	AND.L	D6,D3
	NOT.L	D6
	AND.L	D6,D0
	OR.L	D3,D0
	MOVE.W	D0,$1F40(A1)
	SWAP	D0
	MOVE.W	D0,(A1)
	TST.B	singleBufferRenderMode
	BMI	lbC04B08A
	MOVE.W	D0,-$7D00(A1)
	SWAP	D0
	MOVE.W	D0,-$5DC0(A1)
lbC04B08A:
	ADD.L	#$00003E80,A1
	NOT.L	D4
	NOT.L	D6
	MOVE.L	foregroundColorMask2,D3
	AND.L	D4,D3
	NOT.L	D4
	MOVE.W	(A1),D0
	SWAP	D0
	MOVE.W	$1F40(A1),D0
	TST.B	textTransparencyMode
	BMI	lbC04B0B4
	AND.L	D4,D0
	OR.L	D3,D0
lbC04B0B4:
	MOVE.L	backgroundColorMask2,D3
	AND.L	D6,D3
	NOT.L	D6
	AND.L	D6,D0
	OR.L	D3,D0
	MOVE.W	D0,$1F40(A1)
	SWAP	D0
	MOVE.W	D0,(A1)
	TST.B	singleBufferRenderMode
	BMI	lbC04B0DE
	MOVE.W	D0,-$7D00(A1)
	SWAP	D0
	MOVE.W	D0,-$5DC0(A1)
lbC04B0DE:
	ADD.L	#$FFFFC1A6,A1
	SUBQ.B	#$01,D2
	BNE	lbC04AF44
	MOVE.B	textCursorColumn,D0
	ADDQ.B	#$01,D0
	CMP.B	#$2D,D0
	BCS	lbC04B0FE
	MOVE.B	#$00,D0
lbC04B0FE:
	MOVE.B	D0,textCursorColumn
	RTS

setBackgroundColor:
	JSR	setupBitplaneMasks
	MOVE.L	D6,backgroundColorMask1
	MOVE.L	D7,backgroundColorMask2
	RTS

setForegroundColor:
	JSR	setupBitplaneMasks
	MOVE.L	D6,foregroundColorMask1
	MOVE.L	D7,foregroundColorMask2
	RTS

waitForInputPress:
	JSR	scanForInput
	BCC	waitForInputPress
waitForInputPressAgain:
	JSR	scanForInput
	BCS	waitForInputPressAgain
	RTS

scanForInput:
	JSR	readJoystickState
	MOVE.W	#$007F,D0
	MOVE.L	#keyboardState,A0
lbC04B16C:
	CMP.B	#$B3,$00(A0,D0.W)
	BNE	lbC04B186
	CMP.B	#$60,D0
	BEQ	lbC04B186
	CMP.B	#$61,D0
	BNE	lbC04B1F4
lbC04B186:
	DBRA	D0,lbC04B16C
	BTST	#$00,joystickState
	BNE	lbC04B19E
	MOVE.W	#$4C00,D0
	BRA	lbC04B222

lbC04B19E:
	BTST	#$01,joystickState
	BNE	lbC04B1B2
	MOVE.W	#$4D00,D0
	BRA	lbC04B222

lbC04B1B2:
	BTST	#$02,joystickState
	BNE	lbC04B1C6
	MOVE.W	#$4F00,D0
	BRA	lbC04B222

lbC04B1C6:
	BTST	#$03,joystickState
	BNE	lbC04B1DA
	MOVE.W	#$4E00,D0
	BRA	lbC04B222

lbC04B1DA:
	BTST	#$04,joystickState
	BNE	lbC04B1EE
	MOVE.W	#$440D,D0
	BRA	lbC04B222

lbC04B1EE:
	ORI.B	#$01,CCR
	RTS

lbC04B1F4:
	MOVE.B	#$00,$00(A0,D0.W)
	TST.B	$0060(A0)
	BNE	lbC04B20A
	TST.B	$0061(A0)
	BEQ	lbC04B214
lbC04B20A:
;	MOVE.L	lbB00D194,A0			; removed
	lea	uppercaseTable,a0		; added
	BRA	lbC04B21A

lbC04B214:
;	MOVE.L	lbW00D190,A0			; removed
	lea	lowercaseTable,a0		; added
lbC04B21A:
	LEA	$00(A0,D0.W),A0
	ASL.W	#$08,D0
	MOVE.B	(A0),D0
lbC04B222:
	ANDI.B	#$1E,CCR
	RTS

processDirectionalInput:
	MOVE.B	#$00,directionalInputBits
	CMP.B	#$00,D0
	BNE	lbC04B292
	LSR.W	#$08,D0
	CMP.B	#$45,D0
	BNE	lbC04B24C
	MOVE.B	#$80,directionalInputBits
	RTS

lbC04B24C:
	CMP.B	#$4C,D0
	BNE	lbC04B25E
	MOVE.B	#$20,directionalInputBits
	RTS

lbC04B25E:
	CMP.B	#$4D,D0
	BNE	lbC04B270
	MOVE.B	#$40,directionalInputBits
	RTS

lbC04B270:
	CMP.B	#$4F,D0
	BNE	lbC04B282
	MOVE.B	#$10,directionalInputBits
	RTS

lbC04B282:
	CMP.B	#$4E,D0
	BNE	lbC04B292
	MOVE.B	#$08,directionalInputBits
lbC04B292:
	RTS

updateCoordinateTransforms:
	MOVE.L	#trackCoordinatesX,A0
	MOVE.W	$00(A0,D2.W),tempWord1
	MOVE.W	$20(A0,D2.W),tempWord2
	JSR	projectTrackXToScreen
	JSR	transformCoordinate
	MOVE.L	#coordinateLookupTable,A0
	MOVE.W	$00(A0,D1.W),D0
	ADD.W	#$0024,D1
	MOVE.W	D0,$00(A0,D1.W)
	JSR	transformCoordinate
	JSR	apply3DTransformation
	SUB.W	#$0024,D1
	AND.W	#$00FF,D1
	JMP	apply3DTransformation

clampAndSetupCoordinates:
	MOVE.W	inputCoordX1,D0
	MOVE.W	boundsMinX,D3
	ADD.W	#$0050,D3
	CMP.W	D3,D0
	BGE	lbC04B2FA
	MOVE.W	D0,D3
lbC04B2FA:
	MOVE.W	D3,clampedCoordX1
	MOVE.W	inputCoordX2,D0
	MOVE.W	boundsMaxX,D3
	ADD.W	#$0050,D3
	CMP.W	D3,D0
	BGE	lbC04B318
	MOVE.W	D0,D3
lbC04B318:
	MOVE.W	D3,clampedCoordX2
	MOVE.W	boundsMaxX,D4
	SUB.W	boundsMinX,D4
	ASR.W	#$01,D4
	MOVE.W	boundsMinY,D5
	SUB.W	D4,D5
	MOVE.W	inputCoordY1,D0
	MOVE.W	D5,D3
	ADD.W	#$0050,D3
	CMP.W	D3,D0
	BGE	lbC04B348
	MOVE.W	D0,D3
lbC04B348:
	MOVE.W	D3,clampedCoordY1
	MOVE.W	boundsMinY,D5
	ADD.W	D4,D5
	MOVE.W	inputCoordY2,D0
	MOVE.W	D5,D3
	ADD.W	#$0050,D3
	CMP.W	D3,D0
	BGE	lbC04B36A
	MOVE.W	D0,D3
lbC04B36A:
	MOVE.W	D3,clampedCoordY2
	MOVE.B	#$0A,D2
	MOVE.B	#$F4,D1
	JSR	updateCoordinateTransforms
	MOVE.B	#$0E,D2
	MOVE.B	#$F8,D1
	JSR	updateCoordinateTransforms
	MOVE.B	#$10,D2
	MOVE.B	#$F6,D1
	JSR	updateCoordinateTransforms
	MOVE.B	#$14,D2
	MOVE.B	#$FA,D1
	JSR	updateCoordinateTransforms
	MOVE.B	#$F4,D1
	JSR	calculateCoordinateDeltas
	JSR	setupRenderingCoordinates
	MOVE.W	viewStepX,D0
	MOVE.W	viewStepY,D3
	SUBQ.W	#$01,D3
	SUB.W	D0,lbW00D9C8
	SUB.W	D0,lbW00D9CC
	SUB.W	D3,lbW00DB08
	SUB.W	D3,lbW00DB0C
	MOVE.B	#$F6,D1
	JSR	calculateCoordinateDeltas
	JSR	setupQuadrilateralVertices
	MOVE.W	viewStepX,D0
	MOVE.W	viewStepY,D3
	SUB.W	D0,lbW00D9CA
	SUB.W	D0,lbW00D9CE
	SUB.W	D3,lbW00DB0A
	SUB.W	D3,lbW00DB0E
	JSR	renderTrackQuadrilateral
	RTS

renderTrackQuadrilateral:
	MOVE.W	#$05E0,D0
	ADD.W	#$0080,D0
	MOVE.W	D0,renderCommandQueueOffset
	MOVE.W	#$0118,D1
	MOVE.W	#$011C,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$0118,D1
	MOVE.W	#$011A,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$011A,D1
	MOVE.W	#$011E,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$011C,D1
	MOVE.W	#$011E,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	RTS

calculateStepSizes:
	MOVE.W	viewOffsetX,D0
	BPL	lbC04B486
	NEG.W	D0
lbC04B486:
	LSR.W	#$01,D0
	MOVE.W	D0,quadRectHalfWidth
	LSR.W	#$01,D0
	MOVE.W	D0,stepSizeXHalf
	LSR.W	#$01,D0
	MOVE.W	D0,stepSizeXQuarter
	TST.W	viewOffsetX
	BPL	lbC04B4BA
	NEG.W	quadRectHalfWidth
	NEG.W	stepSizeXHalf
	NEG.W	stepSizeXQuarter
lbC04B4BA:
	MOVE.W	viewStepX,D0
	BPL	lbC04B4C6
	NEG.W	D0
lbC04B4C6:
	LSR.W	#$01,D0
	MOVE.W	D0,quadRectWidth
	LSR.W	#$01,D0
	MOVE.W	D0,stepSizeYHalf
	LSR.W	#$01,D0
	MOVE.W	D0,stepSizeYQuarter
	TST.W	viewStepX
	BPL	lbC04B4FA
	NEG.W	quadRectWidth
	NEG.W	stepSizeYHalf
	NEG.W	stepSizeYQuarter
lbC04B4FA:
	MOVE.W	viewOffsetY,D0
	BPL	lbC04B506
	NEG.W	D0
lbC04B506:
	LSR.W	#$01,D0
	MOVE.W	D0,quadRectHalfHeight
	LSR.W	#$01,D0
	MOVE.W	D0,lbW00D578
	LSR.W	#$01,D0
	MOVE.W	D0,lbW00D580
	TST.W	viewOffsetY
	BPL	lbC04B53A
	NEG.W	quadRectHalfHeight
	NEG.W	lbW00D578
	NEG.W	lbW00D580
lbC04B53A:
	MOVE.W	viewStepY,D0
	BPL	lbC04B546
	NEG.W	D0
lbC04B546:
	LSR.W	#$01,D0
	MOVE.W	D0,quadRectHeight
	LSR.W	#$01,D0
	MOVE.W	D0,lbW00D57A
	LSR.W	#$01,D0
	MOVE.W	D0,lbW00D582
	TST.W	viewStepY
	BPL	lbC04B57A
	NEG.W	quadRectHeight
	NEG.W	lbW00D57A
	NEG.W	lbW00D582
lbC04B57A:
	RTS

setupRenderingCoordinates:
	MOVE.W	#$05E0,D0
	ADD.W	#$0040,D0
	MOVE.W	D0,renderCommandQueueOffset
	JSR	negateViewOffset
	JSR	calculateRelativeViewOffset
	MOVE.W	#$05E0,D0
	ADD.W	#$0010,D0
	MOVE.W	D0,renderCommandQueueOffset
	MOVE.W	quadRectHalfWidth,D0
	SUB.W	quadRectWidth,D0
	MOVE.W	D0,lbW00D9BE
	MOVE.W	quadRectHalfHeight,D0
	SUB.W	quadRectHeight,D0
	MOVE.W	D0,lbW00DAFE
	MOVE.W	quadRectHalfWidth,D0
	NEG.W	D0
	SUB.W	quadRectWidth,D0
	MOVE.W	D0,lbW00D9B8
	MOVE.W	quadRectHalfHeight,D0
	NEG.W	D0
	SUB.W	quadRectHeight,D0
	MOVE.W	D0,lbW00DAF8
	MOVE.W	viewStepX,D0
	ADD.W	stepSizeXHalf,D0
	ADD.W	stepSizeXQuarter,D0
	MOVE.W	D0,lbW00D9BC
	MOVE.W	viewStepY,D0
	ADD.W	lbW00D578,D0
	ADD.W	lbW00D580,D0
	MOVE.W	D0,lbW00DAFC
	MOVE.W	viewStepX,D0
	SUB.W	stepSizeXHalf,D0
	SUB.W	stepSizeXQuarter,D0
	MOVE.W	D0,lbW00D9BA
	MOVE.W	viewStepY,D0
	SUB.W	lbW00D578,D0
	SUB.W	lbW00D580,D0
	MOVE.W	D0,lbW00DAFA
	MOVE.W	quadTranslateX,D0
	MOVE.W	quadTranslateY,D3
	ADD.W	D0,lbW00D9B8
	ADD.W	D3,lbW00DAF8
	ADD.W	D0,lbW00D9BA
	ADD.W	D3,lbW00DAFA
	ADD.W	D0,lbW00D9BC
	ADD.W	D3,lbW00DAFC
	ADD.W	D0,lbW00D9BE
	ADD.W	D3,lbW00DAFE
	ADDQ.W	#$01,lbW00D9BC
	ADDQ.W	#$01,lbW00D9BE
	ADDQ.W	#$01,lbW00DAF8
	ADDQ.W	#$01,lbW00DAFE
	MOVE.W	#$0108,D1
	MOVE.W	#$010A,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$010A,D1
	MOVE.W	#$010C,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$010C,D1
	MOVE.W	#$010E,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$010E,D1
	MOVE.W	#$0108,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	RTS

setupQuadrilateralVertices:
	MOVE.W	quadRectHalfWidth,D0
	MOVE.W	D0,quadVertexX2
	SUB.W	quadRectWidth,D0
	MOVE.W	D0,quadVertexX3
	MOVE.W	quadRectHalfHeight,D0
	MOVE.W	D0,quadVertexY2
	SUB.W	quadRectHeight,D0
	MOVE.W	D0,quadVertexY3
	MOVE.W	quadRectHalfWidth,D0
	NEG.W	D0
	MOVE.W	D0,quadVertexX1
	SUB.W	quadRectWidth,D0
	MOVE.W	D0,quadVertexX0
	MOVE.W	quadRectHalfHeight,D0
	NEG.W	D0
	MOVE.W	D0,quadVertexY1
	SUB.W	quadRectHeight,D0
	MOVE.W	D0,quadVertexY0
	MOVE.W	quadTranslateX,D0
	MOVE.W	quadTranslateY,D3
	ADD.W	D0,quadVertexX0
	ADD.W	D3,quadVertexY0
	ADD.W	D0,quadVertexX1
	ADD.W	D3,quadVertexY1
	ADD.W	D0,quadVertexX2
	ADD.W	D3,quadVertexY2
	ADD.W	D0,quadVertexX3
	ADD.W	D3,quadVertexY3
	ADDQ.W	#$01,quadVertexX2
	ADDQ.W	#$01,quadVertexX3
	ADDQ.W	#$01,quadVertexY0
	ADDQ.W	#$01,quadVertexY3
	MOVE.W	#$05E0,D0
	ADD.W	#$0020,D0
	MOVE.W	D0,renderCommandQueueOffset
	MOVE.W	#$0110,D1
	MOVE.W	#$0112,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$0112,D1
	MOVE.W	#$0114,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$0114,D1
	MOVE.W	#$0116,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$0116,D1
	MOVE.W	#$0110,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$0108,D1
	MOVE.W	#$0110,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$010E,D1
	MOVE.W	#$0116,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$010A,D1
	MOVE.W	#$0112,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$010C,D1
	MOVE.W	#$0114,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$05E0,D0
	ADD.W	#$0060,D0
	MOVE.W	D0,renderCommandQueueOffset
	JSR	negateViewOffset
	JSR	calculateRelativeViewOffset
	RTS

negateViewOffset:
	MOVE.W	viewOffsetX,D0
	NEG.W	D0
	MOVE.W	D0,adjustedViewX
	MOVE.W	viewOffsetY,D0
	NEG.W	D0
	MOVE.W	D0,adjustedViewY
	BRA	setupQuadVerticesWithOffset

calculateRelativeViewOffset:
	MOVE.W	viewOffsetX,D0
	SUB.W	quadRectHalfWidth,D0
	MOVE.W	D0,adjustedViewX
	MOVE.W	viewOffsetY,D0
	SUB.W	quadRectHalfHeight,D0
	MOVE.W	D0,adjustedViewY
setupQuadVerticesWithOffset:
	MOVE.W	adjustedViewX,D0
	MOVE.W	D0,quadVertexX5
	ADD.W	quadRectHalfWidth,D0
	MOVE.W	D0,quadVertexX6
	MOVE.W	adjustedViewY,D0
	MOVE.W	D0,quadVertexY5
	ADD.W	quadRectHalfHeight,D0
	MOVE.W	D0,quadVertexY6
	MOVE.W	adjustedViewX,D0
	SUB.W	viewStepX,D0
	MOVE.W	D0,quadVertexX4
	ADD.W	quadRectHalfWidth,D0
	MOVE.W	D0,quadVertexX7
	MOVE.W	adjustedViewY,D0
	SUB.W	viewStepY,D0
	MOVE.W	D0,quadVertexY4
	ADD.W	quadRectHalfHeight,D0
	MOVE.W	D0,quadVertexY7
	MOVE.W	quadTranslateX,D0
	MOVE.W	quadTranslateY,D3
	ADD.W	D0,quadVertexX4
	ADD.W	D3,quadVertexY4
	ADD.W	D0,quadVertexX5
	ADD.W	D3,quadVertexY5
	ADD.W	D0,quadVertexX6
	ADD.W	D3,quadVertexY6
	ADD.W	D0,quadVertexX7
	ADD.W	D3,quadVertexY7
	ADDQ.W	#$01,quadVertexX6
	ADDQ.W	#$01,quadVertexX7
	ADDQ.W	#$01,quadVertexY4
	ADDQ.W	#$01,quadVertexY7
	MOVE.W	#$0100,D1
	MOVE.W	#$0102,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$0102,D1
	MOVE.W	#$0104,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$0104,D1
	MOVE.W	#$0106,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.W	#$0106,D1
	MOVE.W	#$0100,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderCommandQueueOffset
	RTS

calculateCoordinateDeltas:
	MOVE.L	#coordinateLookupTable,A4
	MOVE.L	#transformedVertexBounds,A5
	MOVE.W	$04(A4,D1.W),D4
	SUB.W	$00(A4,D1.W),D4
	ASR.W	#$01,D4
	MOVE.W	$04(A5,D1.W),D5
	SUB.W	$00(A5,D1.W),D5
	ASR.W	#$01,D5
	MOVE.W	D4,D0
	BPL	lbC04B9F6
	NEG.W	D0
lbC04B9F6:
	CMP.W	#$00FF,D0
	BCS	lbC04BA02
	MOVE.W	#$00FF,D0
lbC04BA02:
	MOVE.W	D0,viewStepY
	MOVE.W	D5,D0
	BPL	lbC04BA10
	NEG.W	D0
lbC04BA10:
	CMP.W	#$00FF,D0
	BCS	lbC04BA1C
	MOVE.W	#$00FF,D0
lbC04BA1C:
	MOVE.W	D0,viewOffsetY
	MOVE.W	viewStepY,viewOffsetX
	TST.W	D4
	BPL	lbC04BA3C
	NEG.W	viewOffsetX
	BRA	lbC04BA42

lbC04BA3C:
	NEG.W	viewStepY
lbC04BA42:
	MOVE.W	viewOffsetY,viewStepX
	TST.W	D5
	BPL	lbC04BA5E
	NEG.W	viewStepX
	NEG.W	viewOffsetY
lbC04BA5E:
	ASR.W	viewStepX
	ASR.W	viewStepY
	MOVE.W	$00(A4,D1.W),D0
	ADD.W	D4,D0
	MOVE.W	D0,quadTranslateX
	MOVE.W	$00(A5,D1.W),D0
	ADD.W	D5,D0
	MOVE.W	D0,quadTranslateY
	BRA	calculateStepSizes

setupTrackGeometryForFrame:
	MOVE.W	#$0040,D0
	JSR	calculateTrackCoordinateBehindOpponent
	MOVE.W	D0,trackDistance
	MOVE.B	D1,trackDirection
	JSR	loadTrackSegmentConfiguration
	MOVE.W	D1,D0
	JSR	transformSegmentToViewSpace
	MOVE.W	cameraRotationFlags,D0
	SUB.W	segmentSlopeFlags,D0
	MOVE.W	D0,trackHeightDifference
	MOVE.W	primaryGeometryOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A4
	MOVE.W	alternateGeometryOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A5
	MOVE.B	trackDistance,D1
	ASL.W	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,splineControlPoint1
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,splineControlPoint2
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,splineControlPoint3
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,splineControlPoint4
	ADDQ.B	#$01,D1
	CMP.B	trackSegmentLimit,D1
	BCS	processWithinSegmentBounds
	JSR	advanceToNextSegment
	JSR	loadTrackSegmentConfiguration
	MOVE.W	primaryGeometryOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A4
	MOVE.W	alternateGeometryOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A5
	MOVE.W	#$0002,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,additionalInterpolationPoints1
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,additionalInterpolationPoints2
	ADDQ.B	#$01,D1
	JSR	retreatToPreviousSegment
	JSR	loadTrackSegmentConfiguration
	MOVE.W	primaryGeometryOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A4
	MOVE.W	alternateGeometryOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A5
	BRA	doProcessTrackCharacteristics

processWithinSegmentBounds:
	JSR	getTrackDataPoint
	MOVE.W	D0,additionalInterpolationPoints1
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,additionalInterpolationPoints2
	ADDQ.B	#$01,D1
doProcessTrackCharacteristics:
	MOVE.B	trackDistance,D0
	JSR	processTrackCharacteristics
	MOVE.W	#$0008,D2
	MOVE.W	#$0000,D1
	JSR	interpolateOpponentTrackPosition
	MOVE.W	#$000C,D2
	MOVE.W	#$0002,D1
	JSR	interpolateOpponentTrackPosition
	BCLR	#$07,segmentHalfFlags
	MOVE.L	#opponentWheelPositions,A0
	MOVE.L	#distanceLookupTable,A3
	MOVE.W	(A0),D0
	SUB.W	$0002(A0),D0
	BPL	lbC04BC42
	NEG.W	D0
lbC04BC42:
	ASR.W	#$04,D0
	MOVE.B	$00(A3,D0.W),distanceCharacteristic
	MOVE.B	trackDistanceHigh,segmentBlendParam
	MOVE.W	opponentDistanceOffset,D0
	CLR.W	D3
	MOVE.B	distanceCharacteristic,D3
	SUB.W	D3,D0
	MOVE.W	D0,adjustedDistanceValue
	MOVE.W	#$0000,D1
	JSR	calculateAndStoreBounds
	MOVE.W	#$000A,D2
	MOVE.W	#$0008,D1
	MOVE.W	adjustedDistanceValue,D0
	JSR	interpolateCoordinatePair
	MOVE.W	opponentDistanceOffset,D0
	CLR.W	D3
	MOVE.B	distanceCharacteristic,D3
	ADD.W	D3,D0
	MOVE.W	D0,adjustedDistanceValue
	MOVE.W	#$0002,D1
	JSR	calculateAndStoreBounds
	MOVE.W	#$000E,D2
	MOVE.W	#$0008,D1
	MOVE.W	adjustedDistanceValue,D0
	JSR	interpolateCoordinatePair
	MOVE.W	splineControlPoint1,D0
	SUB.W	splineControlPoint3,D0
	BPL	lbC04BCD0
	NEG.W	D0
lbC04BCD0:
	CMP.W	#$0014,D0
	BLT	lbC04BCE0
	MOVE.B	#$80,curveSmoothingFlag
lbC04BCE0:
	JSR	calculateRoadEdgeControlPoints
	MOVE.W	splineControlPoint1,D0
	SUB.W	splineControlPoint3,D0
	BPL	lbC04BCF8
	NEG.W	D0
lbC04BCF8:
	CMP.W	#$0014,D0
	BLT	lbC04BD08
	MOVE.B	#$80,curveSmoothingFlag
lbC04BD08:
	MOVE.W	#$00FF,D0
calculateTrackCoordinateBehindOpponent:
	MOVE.B	opponentSegmentIndex,D1
	MOVE.B	D1,currentSegmentIndex
	MOVE.W	opponentSubSegmentProgress,D3
	SUB.W	D3,D0
	NEG.W	D0
	BPL	lbC04BD40
	MOVE.W	D0,-(SP)
	JSR	retreatToPreviousSegment
	JSR	loadTrackSegmentConfiguration
	MOVE.W	(SP)+,D3
	MOVE.B	trackModeParameter,D0
	ASL.W	#$08,D0
	ADD.W	D3,D0
lbC04BD40:
	MOVE.W	D0,lbB00D524
	MOVE.B	D1,lbB00D4A6
	RTS

calculateAndStoreBounds:
	JSR	calculateBilinearTrackInterpolation
	MOVE.L	tempByte1,D0
	ASR.L	#$03,D0
	MOVE.L	#boundsMinX,A0
	MOVE.W	D0,$00(A0,D1.W)
	RTS

calculateRoadEdgeControlPoints:
	MOVE.L	#trackCoordinatesX,A0
	MOVE.W	$000E(A0),D0
	SUB.W	$000A(A0),D0
	MOVE.W	D0,tempAttenuatedValue
	ASR.W	#$01,D0
	ADD.W	D0,tempAttenuatedValue
	MOVE.W	$002E(A0),D0
	SUB.W	$002A(A0),D0
	MOVE.W	D0,perpendicularOffsetY
	ASR.W	#$01,D0
	ADD.W	D0,perpendicularOffsetY
	MOVE.W	$000A(A0),D0
	SUB.W	perpendicularOffsetY,D0
	MOVE.W	D0,$0010(A0)
	MOVE.W	$002A(A0),D0
	ADD.W	tempAttenuatedValue,D0
	MOVE.W	D0,$0030(A0)
	MOVE.W	$000E(A0),D0
	SUB.W	perpendicularOffsetY,D0
	MOVE.W	D0,$0014(A0)
	MOVE.W	$002E(A0),D0
	ADD.W	tempAttenuatedValue,D0
	MOVE.W	D0,$0034(A0)
	MOVE.B	trackDistanceHigh,D0
	ADD.B	#$80,D0
	BCC	lbC04BE08
	MOVE.W	splineControlPoint3,splineControlPoint1
	MOVE.W	splineControlPoint4,splineControlPoint2
	MOVE.W	additionalInterpolationPoints1,splineControlPoint3
	MOVE.W	additionalInterpolationPoints2,splineControlPoint4
lbC04BE08:
	MOVE.B	D0,segmentBlendParam
	MOVE.B	opponentLateralPosition,lateralTrackPosition
	MOVE.W	#$0004,D1
	BRA	calculateAndStoreBounds

linearInterpolateCoordinates:
	MOVE.L	#trackCoordinatesX,A0
	MOVE.W	$04(A0,D1.W),D0
	SUB.W	$00(A0,D1.W),D0
	MOVE.W	interpolationBlendFactor,D3
	MULS	D3,D0
	ASR.L	#$08,D0
	TST.B	segmentHalfFlags
	BPL	addBaseCoordinateAndStore
	ADDQ.B	#$04,D1
	JSR	addBaseCoordinateAndStore
	SUBQ.B	#$04,D1
	RTS

addBaseCoordinateAndStore:
	ADD.W	$00(A0,D1.W),D0
	MOVE.W	D0,$00(A0,D2.W)
	RTS

interpolateOpponentTrackPosition:
	MOVE.B	trackDistanceHigh,D0
	MOVE.L	#opponentSegmentOffset1,A0
	ADD.B	$00(A0,D1.W),D0
	ROXR.B	#$01,D3
	MOVE.B	D3,segmentHalfFlags
	AND.W	#$00FF,D0
interpolateCoordinatePair:
	MOVE.W	D0,interpolationBlendFactor
	JSR	linearInterpolateCoordinates
	ADD.B	#$20,D2
	ADD.B	#$20,D1
	BRA	linearInterpolateCoordinates

loadAndTransformTrackVertex:
	MOVE.L	#trackCoordinatesX,A0
	MOVE.W	$00(A0,D2.W),tempWord1
	MOVE.W	$20(A0,D2.W),tempWord2
	JSR	projectTrackXToScreen
	JSR	transformCoordinate
	JMP	apply3DTransformation

processTrackCharacteristics:
	MOVE.B	D0,D2
	MOVE.W	geometryDatabaseOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A3
	MOVE.B	(A3),D0
	ADDQ.B	#$07,D0
	MOVE.B	D0,trackOffsetBase
	TST.B	reverseDirectionFlag
	BNE	processAlternateTrackData
	ASL.B	#$03,D2
	ADD.B	trackOffsetBase,D2
	MOVE.B	#$00,D1
lbC04BEF2:
	JSR	storeTrackCoordinates
	ADDQ.B	#$02,D1
	CMP.B	#$08,D1
	BNE	lbC04BEF2
	RTS

processAlternateTrackData:
	MOVE.B	trackModeParameter,D0
	SUB.B	D2,D0
	SUBQ.B	#$01,D0
	ASL.B	#$03,D0
	ADD.B	trackOffsetBase,D0
	MOVE.B	D0,D2
	MOVE.B	#$06,D1
lbC04BF1C:
	JSR	storeTrackCoordinates
	SUBQ.B	#$02,D1
	BPL	lbC04BF1C
	RTS

storeTrackCoordinates:
	JSR	interpolateOpponentTrackPositionFromData
	MOVE.L	#trackCoordinatesX,A1
	MOVE.W	tempWord1,$00(A1,D1.W)
	MOVE.L	#trackCoordinatesY,A1
	MOVE.W	tempWord2,$00(A1,D1.W)
	RTS

lbC04BF4E:
	JSR	renderCharacter
	ADDQ.B	#$01,D1
renderTextString:
	TST.B	textRenderingFlag
	BMI	renderMenuString
	MOVE.L	#textStringTable,A1
	MOVE.B	$00(A1,D1.W),D0
	CMP.B	#$FF,D0
	BNE	lbC04BF4E
	RTS

lbC04BF74:
	JSR	renderCharacter
	ADDQ.B	#$01,D1
renderMenuString:
	MOVE.L	#menuTextStrings,A1
	MOVE.B	$00(A1,D1.W),D0
	CMP.B	#$FF,D0
	BNE	lbC04BF74
	RTS

animateDrawBridge:
	MOVE.B	currentTrackID,D0
	CMP.B	#$05,D0
	BEQ	.trackIsDrawBridge
	RTS

.trackIsDrawBridge:
	CMP.B	#$38,playerSegmentIndex
	BCC	.checkOpponentSegmentIndex
	CMP.B	#$33,playerSegmentIndex
	BCC	.carWithinActiveSegments
.checkOpponentSegmentIndex:
	CMP.B	#$38,opponentSegmentIndex
	BCC	.drawBridgeInactive
	CMP.B	#$33,opponentSegmentIndex
	BCC	.carWithinActiveSegments
	TST.B	drawBridgeActive
	BEQ	.drawBridgeInactive
	CMP.B	#$30,opponentSegmentIndex
	BCS	.drawBridgeInactive
.carWithinActiveSegments:
	MOVE.B	#$0C,D0
	MOVE.B	D0,drawBridgeActive
;	ADD.B	drawBridgeAnimationPhase,D0			; dead code
;	BRA	lbC04C266
	rts							; added

.drawBridgeInactive:
;	TST.B	frameThrottleFlag
;	BMI	.animationPhaseOk
	move.b	framesSinceCopperlistUpdate,d0			; added
	ADD.B	d0,drawBridgeAnimationPhase			; originally ADDQ.B #$01
	cmp.b	#$c0,drawBridgeAnimationPhase			; added
	bcs.s	.animationPhaseOk
	clr.b	drawBridgeAnimationPhase
.animationPhaseOk:
	MOVE.W	#$0000,segmentProgressDistance
	MOVE.B	#$00,drawBridgeActive
	MOVE.B	drawBridgeAnimationPhase,D0
	AND.W	#$00FF,D0					; originally $1F
	SUB.W	#$0010*FRAMERATE_MULTIPLIER,D0			; originally $10
	BPL	.animationPhasePositive
	NOT.W	D0
.animationPhasePositive:
	MOVE.B	D0,D2
;	ADDQ.W	#$04,D0
;	MOVE.L	#drawBridgeAngleTable,A0			; dead code
;	MOVE.B	$00(A0,D2.W),lbB00E285
;	MOVE.B	$00(A0,D2.W),lbB00E286
;	ASL.W	#$05,D0
	MOVE.W	D0,tempWord1
	add.w	d0,d0						; added
	add.w	d0,d0
	add.w	#128,d0
	add.w	d0,tempWord1
	MOVE.B	#$02,D2
	MOVE.B	#$BE,D1
	MOVE.L	#segmentGeometryOffsetTable,A1
	MOVE.W	$00(A1,D1.W),rawTrackDataOffset
	MOVE.W	rawTrackDataOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A0
	MOVE.B	#$0F,D1
lbC04C188:
	MOVE.W	segmentProgressDistance,D0
	ADD.W	tempWord1,D0
	MOVE.W	D0,segmentProgressDistance
lbC04C19A:
	MOVE.B	segmentProgressDistance,D0
	CMP.B	#$20,D2
	BNE	lbC04C1AC
	OR.B	#$80,D0
lbC04C1AC:
	MOVE.B	D0,-(SP)
	MOVE.B	D0,$00(A0,D2.W)
	ADDQ.B	#$01,D2
	MOVE.B	segmentProgressDistanceLow,$00(A0,D2.W)
	ADDQ.B	#$01,D2
	MOVE.B	D2,tempByte4
	MOVE.B	#$48,D2
	SUB.B	tempByte4,D2
	MOVE.B	(SP)+,$00(A0,D2.W)
	ADDQ.B	#$01,D2
	MOVE.B	segmentProgressDistanceLow,$00(A0,D2.W)
	MOVE.B	tempByte4,D2
	CMP.B	#$12,D2
	BEQ	lbC04C19A
	SUBQ.B	#$01,D1
	BNE	lbC04C188
	TST.B	drawBridgeUpdateFlag
	BEQ	lbC04C24A
	MOVE.L	#drawBridgeSegmentPointer,A1
	MOVE.L	(A1),A1
	MOVE.B	$0010(A0),D0
	ASL.W	#$08,D0
	MOVE.B	$0013(A0),D0
	BCLR	#$0F,D0
	ADD.W	drawBridgeSegmentBase1,D0
	MOVE.W	D0,$0006(A1)
	MOVE.W	D0,$000C(A1)
	MOVE.W	D0,$004C(A1)
	MOVE.W	D0,$0052(A1)
	MOVE.B	$0020(A0),D0
	ASL.W	#$08,D0
	MOVE.B	$0021(A0),D0
	BCLR	#$0F,D0
	ADD.W	drawBridgeSegmentBase2,D0
	MOVE.W	D0,$0014(A1)
	MOVE.W	D0,$001A(A1)
	MOVE.W	D0,$003E(A1)
	MOVE.W	D0,$0044(A1)
lbC04C24A:
	MOVE.B	#$80,drawBridgeUpdateFlag
;	MOVE.B	opponentSegmentIndex,D0			; dead code
;	CMP.B	#$2F,D0
;	BNE	lbC04C294
;	MOVE.B	drawBridgeAnimationPhase,D0
;lbC04C266:
;	MOVE.L	#drawBridgeHeightOffsets,A1
;	MOVE.L	#drawBridgeHeightValues,A2
;	AND.B	#$1F,D0
;	LSR.B	#$01,D0
;	MOVE.B	D0,D2
;	MOVE.B	#$00,D1
;	MOVE.B	#$C6,D0
;lbC04C282:
;	ADD.B	$00(A1,D2.W),D0
;	MOVE.B	D0,$00(A2,D1.W)
;	ADDQ.B	#$01,D1
;	CMP.B	#$03,D1
;	BNE	lbC04C282
;lbC04C294:
	RTS

initializeGameData:
	MOVE.L	#gameDataRegionStart,A0
.clearLoop:
	MOVE.B	#$00,(A0)+
	CMP.L	#playerHolePositions,A0
	BNE	.clearLoop
	JSR	loadPlayerConfiguration
	MOVE.B	#$00,displayUpdateFlag
	MOVE.B	#$0B,D1
.resetStandingsLoop:
	MOVE.B	D1,D0
	MOVE.L	#leagueStandingsTable,A1
	MOVE.B	D0,$00(A1,D1.W)
	JSR	generateRandomNumber
	SUBQ.B	#$01,D1
	BPL	.resetStandingsLoop
	JSR	initializeGameTables
	MOVE.B	#$0A,holeRenderingPosition
	MOVE.B	#$00,lbB0117F7
	MOVE.B	#$10,lbB0117F8
	MOVE.B	#$7E,lbB0117ED
	MOVE.L	#$00000000,lbL01197A
	MOVE.L	#$00000000,lbW01197E
	MOVE.B	#$7E,lbB011980
	RTS

initializeGameTables:
	MOVE.W	#$0000,D0
	MOVE.B	D0,currentRaceNumber
	MOVE.B	D0,raceSeriesCounter
	MOVE.W	D0,totalRaceCounter
	MOVE.B	#$3B,D1
lbC04C352:
	MOVE.L	#playerRaceWins,A1
	MOVE.B	#$00,$00(A1,D1.W)
	CMP.B	#$0C,D1
	BCC	lbC04C37C
	MOVE.L	#sortedRaceStandings,A0
	MOVE.B	D1,$00(A0,D1.W)
	MOVE.L	#playerHolePositions,A0
	MOVE.B	#$0A,$00(A0,D1.W)
lbC04C37C:
	SUBQ.B	#$01,D1
	BPL	lbC04C352
	RTS

setupRandomRaceParameters:
	MOVE.L	#aiBaseSkillTable,A0
	MOVE.L	#aiSkillLevelTable,A1
	MOVE.W	#$000B,D1
lbC04C394:
	JSR	generateRandomNumber
	AND.B	#$3F,D0
	ADD.B	$00(A0,D1.W),D0
	MOVE.B	D0,$00(A1,D1.W)
	SUBQ.B	#$01,D1
	BPL	lbC04C394
	MOVE.B	currentRaceNumber,D1
	MOVE.B	#$00,D0
lbC04C3B6:
	MOVE.B	D0,displayTrackID
	TST.B	additionalPlayerCount
	BEQ	lbC04C3D0
	CMP.B	currentDivision,D0
	BNE	lbC04C3E2
lbC04C3D0:
	JSR	configurePlayersAndCars
	JSR	setupRaceHandicapping
	JSR	sortRaceResults
lbC04C3E2:
	MOVE.B	displayTrackID,D0
	ADDQ.B	#$01,D0
	CMP.B	#$04,D0
	BLT	lbC04C3B6
	RTS

setupGameConfiguration:
	MOVE.B	additionalPlayerCount,D0
	BEQ	lbC04C422
	EOR.B	#$FF,D0
	ADD.B	#$0C,D0
	MOVE.B	D0,trackBaseOffset
	MOVE.B	#$0C,maxRenderingIndex
	RTS

lbC04C422:
	MOVE.B	displayTrackID,D1
	MOVE.L	#divisionBaseOffsets,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.B	D0,trackBaseOffset
	ADDQ.B	#$03,D0
	MOVE.B	D0,maxRenderingIndex
	RTS

configurePlayersAndCars:
	JSR	setupGameConfiguration
	TST.B	additionalPlayerCount
	BEQ	lbC04C47C
	TST.B	networkGameMode
	BNE	lbC0499D8
	MOVE.B	#$0B,D0
	SUB.B	currentRaceNumber,D0
	MOVE.B	D0,player1ID
	MOVE.B	D0,D2
	MOVE.B	remainingRaces,D0
	BRA	lbC04C4BA

lbC04C47C:
	MOVE.L	#player1OpponentIndices,A0
	MOVE.L	#player2OpponentIndices,A1
	MOVE.B	currentRaceNumber,D1
	MOVE.B	$00(A0,D1.W),D2
	ADD.B	trackBaseOffset,D2
	MOVE.L	#leagueStandingsTable,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.B	D0,player1ID
	MOVE.B	$00(A1,D1.W),D2
	ADD.B	trackBaseOffset,D2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.B	#$0B,D2
lbC04C4BA:
	MOVE.B	D0,player2ID
	MOVE.B	D2,currentPlayerID
	RTS

setupRaceHandicapping:
	MOVE.W	#$0000,D1
	JSR	generateRandomNumber
	CMP.B	#$A0,D0
	BCS	lbC04C4EA
	MOVE.B	#$40,D1
lbC04C4EA:
	MOVE.B	D1,raceSetupFlags
	MOVE.B	player1ID,D2
	MOVE.B	player2ID,D1
	MOVE.L	#raceParticipationCounters,A1
	ADDQ.B	#$01,$00(A1,D1.W)
	ADDQ.B	#$01,$00(A1,D2.W)
	MOVE.B	raceOutcomeFlags,D0
	CMP.B	currentPlayerID,D1
	BEQ	lbC04C528
	CMP.B	currentPlayerID,D2
	BNE	lbC04C534
	EOR.B	#$C0,D0
lbC04C528:
	MOVE.B	D0,raceSetupFlags
	JMP	lbC04C566

lbC04C534:
	MOVE.L	#aiSkillLevelTable,A2
	MOVE.B	$00(A2,D2.W),D0
	CMP.B	$00(A2,D1.W),D0
	BCS	lbC04C566
	BNE	lbC04C556
	JSR	generateRandomNumber
	LSR.B	#$01,D0
	BCS	lbC04C566
lbC04C556:
	MOVE.B	raceSetupFlags,D0
	EOR.B	#$C0,D0
	MOVE.B	D0,raceSetupFlags
lbC04C566:
	TST.B	raceSetupFlags
	BMI	lbC04C58E
	MOVE.B	D1,tempByte2
	BTST	#$06,raceSetupFlags
	BNE	lbC04C5A0
lbC04C582:
	MOVE.B	D1,tempByte1
	JMP	lbC04C5A6

lbC04C58E:
	MOVE.B	D2,tempByte2
	BTST	#$06,raceSetupFlags
	BEQ	lbC04C582
lbC04C5A0:
	MOVE.B	D2,tempByte1
lbC04C5A6:
	TST.B	networkGameMode
	BEQ	lbC04C5BA
	TST.B	raceMode
	BMI	lbC04C5FC
lbC04C5BA:
	MOVE.B	tempByte2,D1
	MOVE.L	#playerRaceWins,A1
	ADDQ.B	#$01,$00(A1,D1.W)
	MOVE.B	tempByte1,D1
	MOVE.L	#playerSecondPlaceFinishes,A1
	ADDQ.B	#$01,$00(A1,D1.W)
	MOVE.B	displayTrackID,D0
	CMP.B	currentDivision,D0
	BNE	lbC04C5FC
	MOVE.B	D1,lbB00E326
	MOVE.B	tempByte2,D0
	MOVE.B	D0,lbB00E325
lbC04C5FC:
	RTS

sortRaceResults:
	JSR	setupGameConfiguration
	MOVE.L	#sortedRaceStandings,A3
	MOVE.B	trackBaseOffset,D2
lbC04C610:
	MOVE.L	#leagueStandingsTable,A2
	MOVE.B	$00(A2,D2.W),D1
	MOVE.B	D1,D0
	MOVE.B	D0,$00(A3,D2.W)
	MOVE.L	#playerRaceWins,A0
	MOVE.B	$00(A0,D1.W),D0
	ASL.B	#$01,D0
	MOVE.L	#playerSecondPlaceFinishes,A0
	ADD.B	$00(A0,D1.W),D0
	MOVE.L	#playerRankingScores,A1
	MOVE.B	D0,$00(A1,D1.W)
	ADDQ.B	#$01,D2
	CMP.B	maxRenderingIndex,D2
	BLT	lbC04C610
lbC04C64C:
	MOVE.B	#$00,D0
	MOVE.B	D0,tempByte2
	MOVE.B	trackBaseOffset,D2
lbC04C65C:
	MOVE.B	D2,tempByte1
	MOVE.B	$00(A3,D2.W),D1
	MOVE.B	$01(A3,D2.W),D0
	MOVE.B	D0,D2
	MOVE.L	#playerRankingScores,A1
	MOVE.B	$00(A1,D1.W),D0
	CMP.B	$00(A1,D2.W),D0
	BLT	lbC04C6B8
	BNE	lbC04C6DA
	MOVE.L	#playerRaceWins,A1
	MOVE.B	$00(A1,D1.W),D0
	CMP.B	$00(A1,D2.W),D0
	BLT	lbC04C6B8
	BNE	lbC04C6DA
	TST.B	additionalPlayerCount
	BEQ	lbC04C6AC
	CMP.B	D2,D1
	BCS	lbC04C6B8
	BRA	lbC04C6DA

lbC04C6AC:
	JSR	generateRandomNumber
	LSR.B	#$01,D0
	BCC	lbC04C6DA
lbC04C6B8:
	MOVE.B	D2,tempByte3
	MOVE.B	tempByte1,D2
	MOVE.B	D1,D0
	MOVE.B	D0,$01(A3,D2.W)
	MOVE.B	tempByte3,D0
	MOVE.B	D0,$00(A3,D2.W)
	ADDQ.B	#$01,tempByte2
lbC04C6DA:
	MOVE.B	tempByte1,D2
	ADDQ.B	#$01,D2
	ADDQ.B	#$01,D2
	CMP.B	maxRenderingIndex,D2
	BGE	lbC04C6F4
	SUBQ.B	#$01,D2
	BRA	lbC04C65C

lbC04C6F4:
	MOVE.B	tempByte2,D0
	BNE	lbC04C64C
	RTS

readTrackDataByte:
	MOVE.B	$00(A5,D5.W),D0
	ADDQ.W	#$01,D5
	AND.B	#$FF,D0
	RTS

applyDirectionalOffset:
	TST.B	tempByte3
	BMI	lbC04C72E
	BTST	#$06,tempByte3
	BNE	lbC04C728
	ADD.B	#$10,D0
	RTS

lbC04C728:
	ADD.B	#$01,D0
	RTS

lbC04C72E:
	BTST	#$06,tempByte3
	BNE	lbC04C740
	SUB.B	#$10,D0
	RTS

lbC04C740:
	SUB.B	#$01,D0
	RTS

processTrackDataBuffer:
	MOVE.B	D1,D0
	ASL.B	#$01,D0
	MOVE.B	D0,D2
	MOVE.L	#trackDataOffsetTable,A2
	MOVE.W	$00(A2,D2.W),rawTrackDataOffset
	MOVE.W	rawTrackDataOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A5
	MOVE.W	#$0000,D5
lbC04C778:
	JSR	readTrackDataByte
	MOVE.L	#trackDataBuffer,A2
	MOVE.B	D0,$00(A2,D5.W)
	CMP.B	#$04,D5
	BNE	lbC04C778
	JSR	readTrackDataByte
	MOVE.B	D0,playerOpponentLateralDistance
	MOVE.B	D0,wheelDataOffset
	JSR	readTrackDataByte
	MOVE.B	D0,tempWord1
	MOVE.B	D0,tempWord2
	MOVE.B	#$00,D1
	MOVE.B	D1,segmentAlternateFlag
	MOVE.B	D1,segmentProgressDistanceLow
	MOVE.B	D1,segmentProgressDistance
	MOVE.B	D1,segmentRepeatCounter
lbC04C7D0:
	MOVE.B	segmentRepeatCounter,D0
	BEQ	lbC04C820
	SUBQ.B	#$01,segmentRepeatCounter
	MOVE.B	previousSegmentProperties,D0
	MOVE.B	D0,tempByte3
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	D0,$00(A1,D1.W)
	AND.B	#$10,D0
	BEQ	lbC04C80E
	MOVE.B	tempByte3,D0
	EOR.B	#$C0,D0
	MOVE.B	D0,tempByte3
lbC04C80E:
	MOVE.B	currentTrackCoordinate,D0
	JSR	applyDirectionalOffset
	JMP	lbC04C86C

lbC04C820:
	JSR	readTrackDataByte
	MOVE.B	D0,tempByte3
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	D0,$00(A1,D1.W)
	AND.B	#$0F,D0
	CMP.B	#$0F,D0
	BNE	lbC04C856
	MOVE.B	tempByte3,D0
	LSR.B	#$04,D0
	MOVE.B	D0,segmentRepeatCounter
	JMP	lbC04C7D0

lbC04C856:
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.B	D0,previousSegmentProperties
	JSR	readTrackDataByte
lbC04C86C:
	MOVE.L	#trackSegmentCoordinates,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.B	D0,currentTrackCoordinate
	MOVE.B	segmentAlternateFlag,D0
	LSR.B	#$02,D0
	ROXR.B	#$01,D0
	MOVE.B	D0,tempByte4
	MOVE.B	tempByte3,D0
	AND.B	#$0F,D0
	CMP.B	#$0C,D0
	BLT	lbC04C8DC
	MOVE.B	D0,D2
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$F0,D0
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.L	#specialSegmentLookupTable-12,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.L	#segmentGeometryIndices,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.L	#specialSegmentLookupTable-10,A2
	MOVE.B	$00(A2,D2.W),D0
	JMP	lbC04C910

lbC04C8DC:
	JSR	readTrackDataByte
	MOVE.L	#segmentGeometryIndices,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.B	tempByte3,D0
	AND.B	#$20,D0
	BEQ	lbC04C90A
	MOVE.L	#segmentGeometryIndices,A1
	MOVE.B	$00(A1,D1.W),D0
	JMP	lbC04C910

lbC04C90A:
	JSR	readTrackDataByte
lbC04C910:
	AND.B	#$7F,D0
	OR.B	tempByte4,D0
	MOVE.L	#segmentAlternateGeometryIndices,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.B	D2,D0
	MOVE.B	D0,-(SP)
	ASL.B	#$01,D1
	MOVE.L	#segmentWorldPositions,A1
	MOVE.W	segmentProgressDistance,D0
	ASL.W	#$05,D0
	MOVE.W	D0,$00(A1,D1.W)
	LSR.B	#$01,D1
	JSR	loadTrackSegmentConfiguration
	ASL.B	#$01,D1
	MOVE.B	segmentAlternateFlag,D0
	ADD.B	maxSegmentIndex,D0
	AND.B	#$02,D0
	MOVE.B	D0,segmentAlternateFlag
	MOVE.B	trackModeParameter,D0
	AND.W	#$00FF,D0
	ADD.W	D0,segmentProgressDistance
	MOVE.B	#$00,D2
	JSR	readSegmentInterpolationValue
	MOVE.B	D0,tempByte3
	MOVE.L	#segmentInterpolationPoint1,A3
	MOVE.L	#segmentInterpolationPoint2,A4
	MOVE.W	tempWord1,D4
	SUB.W	tempByte3,D4
	MOVE.W	D4,$00(A3,D1.W)
	MOVE.B	trackModeParameter,D2
	JSR	readSegmentInterpolationValue
	MOVE.B	D0,tempByte3
	ADD.W	tempByte3,D4
	MOVE.W	D4,tempWord1
	MOVE.B	#$00,D2
	JSR	switchToAlternateGeometryAndReadSegmentInterpolationValue
	MOVE.B	D0,tempByte3
	MOVE.W	tempWord2,D4
	SUB.W	tempByte3,D4
	MOVE.W	D4,$00(A4,D1.W)
	MOVE.B	trackModeParameter,D2
	JSR	switchToAlternateGeometryAndReadSegmentInterpolationValue
	MOVE.B	D0,tempByte3
	ADD.W	tempByte3,D4
	MOVE.W	D4,tempWord2
	LSR.B	#$01,D1
	MOVE.B	(SP)+,D0
	MOVE.B	D0,D2
	ADDQ.B	#$01,D1
	CMP.B	numTrackSegments,D1
	BEQ	lbC04CA0C
	JMP	lbC04C7D0

lbC04CA0C:
	MOVE.B	lapApproachSegment,D1
	ADDQ.B	#$01,D1
	CMP.B	numTrackSegments,D1
	BLT	lbC04CA22
	MOVE.B	#$00,D1
lbC04CA22:
	MOVE.B	D1,lapLineSegment
	MOVE.W	segmentProgressDistance,D0
	ASL.W	#$05,D0
	MOVE.W	D0,startWorldPosition
	MOVE.B	#$00,D1
lbC04CA3A:
	JSR	readTrackDataByte
	MOVE.L	#trackMetadataBuffer,A1
	MOVE.B	D0,$00(A1,D1.W)
	ADDQ.B	#$01,D1
	CMP.B	#$06,D1
	BNE	lbC04CA3A
	MOVE.B	obstacleCount,D0
	BEQ	lbC04CA8E
	MOVE.B	#$00,D1
lbC04CA62:
	JSR	readTrackDataByte
	MOVE.L	#obstacleSegmentIndices,A1
	MOVE.B	D0,$00(A1,D1.W)
	JSR	readTrackDataByte
	MOVE.L	#obstacleTypes,A1
	MOVE.B	D0,$00(A1,D1.W)
	ADDQ.B	#$01,D1
	CMP.B	obstacleCount,D1
	BNE	lbC04CA62
lbC04CA8E:
	MOVE.B	trackFeatureCount,D0
	BEQ	lbC04CAB8
	MOVE.B	#$00,D1
lbC04CA9C:
	JSR	readTrackDataByte
	MOVE.L	#trackFeatureData,A1
	MOVE.B	D0,$00(A1,D1.W)
	ADDQ.B	#$01,D1
	CMP.B	trackFeatureCount,D1
	BNE	lbC04CA9C
lbC04CAB8:
	JSR	initializeTrackDifficultyParameters
	MOVE.B	#$00,D0
	MOVE.B	D0,segmentRepeatCounter
	MOVE.B	#$7C,D0
	MOVE.B	D0,tempByte4
	MOVE.B	#$02,D0
	MOVE.B	D0,renderModeFlag
	BNE	lbC04CBB0
lbC04CAE0:
	MOVE.B	obstacleCount,D2
	JMP	lbC04CAFC

lbC04CAEC:
	MOVE.B	D1,D0
	MOVE.L	#obstacleSegmentIndices,A2
	CMP.B	$00(A2,D2.W),D0
	BEQ	lbC04CB08
lbC04CAFC:
	SUBQ.B	#$01,D2
	BPL	lbC04CAEC
	JMP	lbC04CB38

lbC04CB08:
	MOVE.L	#obstacleTypes,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.L	#segmentVisibilityData,A1
	MOVE.B	D0,$00(A1,D1.W)
	BPL	lbC04CB2A
	MOVE.B	#$03,D2
	MOVE.B	D2,segmentRepeatCounter
lbC04CB2A:
	AND.B	#$7F,D0
	MOVE.B	D0,tempByte4
	BPL	lbC04CBAA
lbC04CB38:
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$0F,D0
	MOVE.B	D0,D2
	MOVE.L	#geometryParameterTable,A2
	MOVE.B	$00(A2,D2.W),D0
	BPL	lbC04CB72
	MOVE.B	aiCorneringSkill,D0
	SUB.B	#$0A,D0
	MOVE.B	D0,tempByte4
	MOVE.B	aiCorneringSkill,D0
	JMP	lbC04CB8C

lbC04CB72:
	MOVE.B	tempByte4,D0
	ADD.B	#$0A,D0
	BMI	lbC04CB86
	MOVE.B	D0,tempByte4
lbC04CB86:
	MOVE.B	tempByte4,D0
lbC04CB8C:
	MOVE.B	segmentRepeatCounter,D2
	BEQ	lbC04CBA0
	SUBQ.B	#$01,segmentRepeatCounter
	OR.B	#$80,D0
lbC04CBA0:
	MOVE.L	#segmentVisibilityData,A1
	MOVE.B	D0,$00(A1,D1.W)
lbC04CBAA:
	SUBQ.B	#$01,D1
	BPL	lbC04CAE0
lbC04CBB0:
	MOVE.B	numTrackSegments,D1
	SUBQ.B	#$01,D1
	SUBQ.B	#$01,renderModeFlag
	BNE	lbC04CAE0
	RTS

switchToAlternateGeometryAndReadSegmentInterpolationValue:
	MOVE.W	alternateGeometryOffset,primaryGeometryOffset
readSegmentInterpolationValue:
	MOVE.W	primaryGeometryOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A0
	MOVE.B	geometryFormatFlag,D0
	BPL	lbC04CC14
	MOVE.B	D2,D0
	ASL.B	#$01,D0
	MOVE.B	D0,D2
	ADDQ.B	#$01,D2
	MOVE.B	$00(A0,D2.W),D0
	MOVE.B	D0,tempByte4
	SUBQ.B	#$01,D2
	MOVE.B	$00(A0,D2.W),D0
	AND.B	#$7F,D0
	RTS

lbC04CC14:
	MOVE.B	$00(A0,D2.W),D0
	ASL.B	#$01,D0
	AND.B	#$E0,D0
	MOVE.B	D0,tempByte4
	MOVE.B	$00(A0,D2.W),D0
	AND.B	#$0F,D0
	RTS

handleRaceStartCountdown:
	MOVE.B	raceStartTimer,D1
	BEQ	.done
	CMP.B	#$E6,D1
	BCS	.checkInitialRaise
	JSR	checkMultiplayerTrackSwap
	MOVE.B	#$28,D0					; originally $2C
	TST.B	trackSideIndicator
	BPL	.setStartRotation
	MOVE.B	#$D8,D0					; originally $D4
.setStartRotation:
	MOVE.B	D0,raceStartRoll
	MOVE.B	#$00,raceStartRollLow
.decrementTimer:
	tst.b	frameThrottleFlag			; added
	bmi.s	.timerOk
	SUBQ.B	#$01,raceStartTimer
.timerOk:
	RTS

.checkInitialRaise:
	CMP.B	#$E5,D1
	BNE	.checkFullRaise
	MOVE.B	#$00,D0
	JSR	updateRaceStartRoll
	MOVE.B	#$03,D0
	JSR	adjustCarHeightToTrack
	BPL	.decrementTimer
.done:	RTS

.checkFullRaise:
	CMP.B	#$E4,D1
	BNE	.holdAndCountdown
	MOVE.B	#$04,D0
	JSR	adjustCarHeightToTrack
	MOVE.B	#$FF,D0
	JSR	updateRaceStartRoll
	BNE	.done
	JSR	generateRandomNumber
	AND.B	#$1F,D0
	ADD.B	#$A0,D0
	MOVE.B	#$2C,D2				; DROP START
	TST.B	raceStartComplete
	BPL	.messageIndexOk
	MOVE.B	#$3C,D2				; PRESS FIRE
.messageIndexOk:
	TST.B	selectedTrackInDivision
	BMI	.raceStartTimerOk
	MOVE.B	#$8C,D0
.raceStartTimerOk:
	MOVE.B	D0,raceStartTimer
	TST.B	crashRecoveryTimer
	BEQ	.crashRecoveryTimerOk
	MOVE.B	#$32,crashRecoveryTimer
.crashRecoveryTimerOk:
	MOVE.B	#$04,D0
	JMP	setMessageParameters

;.done:	RTS					; removed

.holdAndCountdown:
	MOVE.B	#$00,D0
	JSR	updateRaceStartRoll
	MOVE.B	#$02,D0
	JSR	adjustCarHeightToTrack
	TST.B	frameThrottleFlag
	BMI	.checkTransition
	SUBQ.B	#$01,raceStartTimer
	BNE	.checkTransition
	ADDQ.B	#$01,raceStartTimer
.checkTransition:
	MOVE.B	raceStartComplete,D0
	BNE	.checkRaceActive
	TST.B	raceStartTimer
	BPL	.startRace
	RTS

.checkRaceActive:
	MOVE.B	raceActiveFlag,D0
	BNE	.raceIsActive
.startRace:
	MOVE.B	#$00,D0
	MOVE.B	D0,raceStartTimer
	MOVE.B	D0,offTrackStateFlags
	MOVE.B	D0,gameMessageActiveFlag
	MOVE.B	#$80,D0
	MOVE.B	D0,raceStartComplete
.raceIsActive:
	RTS

adjustCarHeightToTrack:
	ASL.W	#$08,D0
	MOVE.W	carHeightPosition,D3
	SUB.W	trackSurfaceHeight,D3
	SUB.W	D0,D3
	MOVE.W	D3,D0
	ASR.W	#$03,D0
	SUB.W	#$0100,D0
	BPL	lbC04CD9A
	CMP.W	#$FE00,D0
	BCC	lbC04CD9A
	MOVE.W	#$FE00,D0
lbC04CD9A:
	SUB.W	D0,pitchSpringAngle
	LSR.W	#$08,D3
	MOVE.B	D3,D0
	ADDQ.B	#$02,D0
	RTS

updateRaceStartRoll:
	MOVE.B	#$0C,D4						; originally $10
	TST.B	trackSideIndicator
	BPL	lbC04CDBC
	NEG.B	D0
	MOVE.B	#$F4,D4						; originally $F0
lbC04CDBC:
	ASL.W	#$08,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
;	BEQ	lbC04CDCA					; originally BEQ
	MULS	D2,D0
	ASR.L	#$08,D0
lbC04CDCA:
	MOVE.W	offsetFromRoadCenter,D3
	ASL.W	#$05,D3
	MOVE.B	raceStartRoll,D7
	CMP.B	D4,D7
	BEQ	lbC04CDE4
	ADD.W	D0,raceStartRoll
lbC04CDE4:
	MOVE.W	raceStartRoll,D0
	SUB.W	D3,D0
	MOVE.W	D0,cameraAngleZ
	MOVE.W	#$0000,D0
	MOVE.W	D0,targetPitchRate
	MOVE.B	raceStartRoll,D0
	CMP.B	D4,D0
	RTS

applyCameraLateralOffset:
	MOVE.W	#$0008,D1
	MOVE.W	#$0004,D2
	MOVE.L	#cameraWorldX,A3
lbC04CE14:
	MOVE.L	#lbL00DB30,A2
	MOVE.W	$00(A2,D2.W),D0
	CMP.B	#$08,D1
	BNE	lbC04CE28
	NEG.W	D0
lbC04CE28:
	MOVE.B	trackSideIndicator,trackSideIndicatorCopy
	MOVE.B	#$A0,tempByte3
	MOVE.B	tempByte3,D3
	AND.W	#$00FF,D3
	TST.B	trackSideIndicatorCopy
	BPL	lbC04CE50
	NEG.W	D3
lbC04CE50:
	ASL.W	#$07,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	EXT.L	D0
	ASL.L	#$06,D0
	ADD.L	D0,$00(A3,D1.W)
	MOVE.B	#$06,D2
	SUBQ.B	#$08,D1
	BPL	lbC04CE14
	RTS

updateEngineAudioPitch:
	MOVE.B	wheelMovementActive,D0
	BNE	lbC04CE90
	MOVE.W	#$0000,D0
	MOVE.B	inputStateFlags,D0
	AND.B	#$03,D0
	BEQ	lbC04CEA0
	MOVE.W	#$9000,D0
	BNE	lbC04CEA0
lbC04CE90:
	MOVE.W	carLocalVelocityZ,D0
	AND.W	#$FFF0,D0
	BPL	lbC04CEA0
	NEG.W	D0
lbC04CEA0:
	ADD.W	#$0580,D0
	LSR.W	#$03,D0
	MOVE.W	enginePitchAccumulator,D3
	CMP.W	#$00C0,D3
	BGE	lbC04CEBC
	MOVE.W	#$0002,D0
	BRA	lbC04CEC0

lbC04CEBC:
	SUB.W	D3,D0
	ASR.W	#$03,D0
lbC04CEC0:
	MOVE.W	D0,enginePitchDelta
	MOVE.B	enginePitchDelta,D0
	BMI	lbC04CEE6
	BEQ	lbC04CF32
	MOVE.B	#$00,enginePitchDeltaLow
	MOVE.B	#$01,D0
	JMP	lbC04CF2C

lbC04CEE6:
	MOVE.B	wheelMovementActive,D2
	BEQ	lbC04CF0A
	CMP.B	#$FF,D0
	BEQ	lbC04CF32
	MOVE.B	#$00,enginePitchDeltaLow
	MOVE.B	#$FF,D0
	JMP	lbC04CF2C

lbC04CF0A:
	CMP.B	#$FF,D0
	BNE	lbC04CF20
	MOVE.B	enginePitchDeltaLow,D0
	CMP.B	#$E0,D0
	BCC	lbC04CF32
lbC04CF20:
	MOVE.B	#$E0,enginePitchDeltaLow
	MOVE.B	#$FF,D0
lbC04CF2C:
	MOVE.B	D0,enginePitchDelta
lbC04CF32:
	JSR	generateRandomNumber
	AND.B	#$0F,D0
	MOVE.B	#$00,engineAudioNoiseFlag
	RTS

runPlayerNameEntry:
	JSR	drawScreenFrame
	MOVE.B	#$E0,D1
	JSR	renderLeagueText
	MOVE.B	#$01,D0
	MOVE.B	D0,currentMenuItem
;
;lbC04CF62:
	JSR	renderMenuCursorAndAdvance
	MOVE.B	#$0A,D0
	MOVE.W	#$006A,D4
	MOVE.W	#$00BE,D6
	MOVE.W	#$0085,D5
	JSR	drawHorizontalLine
	JSR	copyFirstFrameBufferToSecond
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	displayFrameBuffer,renderFrameBuffer
lbC04CF94:
	MOVE.B	#$02,D0
	JSR	setForegroundColor
	JSR	inputPlayerName
	JSR	setTextYOffset4
	MOVE.W	#$000B,D0
	SUB.B	additionalPlayerCount,D0
	ASL.W	#$04,D0
	MOVE.L	#playerNamesWithSpaces,A0
	CMP.B	#$20,$01(A0,D0.W)
;	BEQ	lbC04CF94
	bne.b	.nameOk
	move.b	#'P',$01(A0,D0.W)
	move.b	#'l',$02(A0,D0.W)
	move.b	#'a',$03(A0,D0.W)
	move.b	#'y',$04(A0,D0.W)
	move.b	#'e',$05(A0,D0.W)
	move.b	#'r',$06(A0,D0.W)
.nameOk:
	JSR	resetTextYOffset
	MOVE.B	#$03,D0
	JSR	setForegroundColor
	MOVE.L	(SP)+,renderFrameBuffer
	RTS

inputPlayerName:
	MOVE.B	#$0E,D1
	MOVE.B	#$10,D2
	JSR	setTextPosition
	MOVE.B	#$3E,D0
	JSR	renderCharacter
.loop:	JSR	scanForInput
	BCC	.loop
	MOVE.B	#$00,D0
	MOVE.B	#$0C,D3
	MOVE.B	#$00,currentInputPosition
	MOVE.B	#$0B,D0
	SUB.B	additionalPlayerCount,D0
	ASL.B	#$04,D0
inputTextString:
	MOVE.B	D0,currentPlayerNameOffset
	MOVE.B	D3,maxInputLength
	MOVE.B	#$00,directionalInputBits
	MOVE.B	currentInputPosition,D1
	ADD.B	D1,textCursorColumn
	BRA	inputPlayerNameLoop

resetInputPosition:
	MOVE.B	#$00,D1
inputPlayerNameLoop:
	MOVE.B	D1,D2
	ADD.B	currentPlayerNameOffset,D2
	JSR	waitForInputPress
	TST.B	disableDirectionalInputFlag
	BPL	lbC04D06C
	JSR	processDirectionalInput
	TST.B	directionalInputBits
	BNE	padNameWithSpaces
lbC04D06C:
	CMP.B	#$0D,D0
	BEQ	padNameWithSpaces
	CMP.B	#$08,D0
	BEQ	backspace
	CMP.B	#$20,D0
	BNE	lbC04D090
	CMP.B	#$00,D1
	BEQ	inputPlayerNameLoop
	BRA	lbC04D0DA

lbC04D090:
	CMP.B	#$2E,D0
	BCS	inputPlayerNameLoop
	CMP.B	#$3B,D0
	BCS	lbC04D0DA
	CMP.B	#$41,D0
	BCS	inputPlayerNameLoop
	CMP.B	#$5B,D0
	BCS	lbC04D0DA
	CMP.B	#$61,D0
	BCS	inputPlayerNameLoop
	CMP.B	#$7B,D0
	BCS	lbC04D0DA
	BRA	inputPlayerNameLoop

backspace:
	SUBQ.B	#$01,D1
	BMI	resetInputPosition
	MOVE.B	#$7F,D0
	JSR	renderCharacter
	JMP	inputPlayerNameLoop

lbC04D0DA:
	CMP.B	#$60,D0
	BCS	lbC04D0F2
	CMP.B	#$C0,currentPlayerNameOffset
	BNE	lbC04D0F2
	SUB.B	#$20,D0
lbC04D0F2:
	CMP.B	maxInputLength,D1
	BGE	inputPlayerNameLoop
	JSR	renderCharacter
	MOVE.L	#playerNames,A2
	MOVE.B	D0,$00(A2,D2.W)
	ADDQ.B	#$01,D1
	JMP	inputPlayerNameLoop

padNameLoop:
	MOVE.B	D1,D2
	ADD.B	currentPlayerNameOffset,D2
	MOVE.B	#$20,D0
	MOVE.L	#playerNames,A2
	MOVE.B	D0,$00(A2,D2.W)
	ADDQ.B	#$01,D1
padNameWithSpaces:
	CMP.B	maxInputLength,D1
	BLT	padNameLoop
	JMP	resetTextYOffset

displayMenu:
	SUBQ.B	#$01,D2
	MOVE.B	D2,maxMenuIndex
	MOVE.B	D1,currentTrackCoordinate
	MOVE.B	D0,selectedMenuItem
	JSR	renderDivisionBackgroundAndHeader
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.B	#$00,D1
	MOVE.B	D1,menuHighlightMode
	JSR	renderTextString
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
renderAllMenuOptions:
	MOVE.B	#$00,D0
	MOVE.B	D0,currentMenuItem
lbC04D188:
	MOVE.B	currentMenuItem,D2
	MOVE.B	D2,tempByte1
	CMP.B	selectedMenuItem,D2
	BNE	lbC04D1B6
	MOVE.B	#$00,D0
	MOVE.B	menuHighlightMode,D2
	BNE	lbC04D1B0
	MOVE.B	#$01,D0
lbC04D1B0:
	MOVE.B	D0,menuCursorObjectType
lbC04D1B6:
	JSR	renderMenuCursorAndAdvance
	MOVE.B	tempByte1,D0
	ADDQ.B	#$01,D0
	JSR	renderDigit
	MOVE.B	#$2E,D0
	JSR	renderCharacter
	MOVE.B	#$20,D0
	JSR	renderCharacter
	MOVE.B	tempByte1,D2
	ADD.B	currentTrackCoordinate,D2
	MOVE.L	#menuStringOffsetTable,A2
	MOVE.B	$00(A2,D2.W),D1
	JSR	renderTextString
	CMP.B	#$18,currentTrackCoordinate
	BNE	lbC04D214
	MOVE.B	tempByte1,D0
	ADDQ.B	#$01,D0
	JSR	renderDigit
lbC04D214:
	MOVE.B	maxMenuIndex,D0
	CMP.B	tempByte1,D0
	BCS	lbC04D262
	MOVE.B	currentTrackCoordinate,D0
	CMP.B	#$1C,D0
	BNE	lbC04D188
	MOVE.B	#$23,D1
	JSR	renderLeagueText
	MOVE.B	selectedDivision,D0
	ASL.B	#$01,D0
	ADD.B	tempByte1,D0
	MOVE.B	D0,D2
	MOVE.L	#trackIDLookupTable,A2
	MOVE.B	$00(A2,D2.W),D1
	JSR	renderTrackName
	JMP	lbC04D188

lbC04D262:
	JSR	copyFirstFrameBufferToSecond
	MOVE.B	#$0F,D2
	JSR	delayWithParam
	MOVE.B	menuHighlightMode,D0
	BEQ	lbC04D28A
	JSR	resetTextYOffset
	MOVE.B	selectedMenuItem,D0
	RTS

lbC04D28A:
	JSR	readControllerInput
	BNE	lbC04D28A
	MOVE.B	#$02,D2
	JSR	delayWithParam
readInputLoop:
	JSR	readControllerInput
	AND.B	#$10,D0
	MOVE.B	D0,menuHighlightMode
	BNE	renderAllMenuOptions
	TST.B	networkGameMode
	BEQ	processLocalMenuInput
	JSR	validateNetworkMenuSelection
	BMI	lbC04D2F8
	BRA	renderAllMenuOptions

processLocalMenuInput:
	MOVE.B	maxMenuIndex,D2
	ADDQ.B	#$01,D2
lbC04D2D2:
	MOVE.L	#keycodeTable,A2
	MOVE.B	$00(A2,D2.W),D1
	JSR	checkKeyPressed
	BNE	lbC04D2F2
	MOVE.B	D2,selectedMenuItem
	JMP	renderAllMenuOptions

lbC04D2F2:
	SUBQ.B	#$01,D2
	BPL	lbC04D2D2
lbC04D2F8:
	MOVE.B	selectedMenuItem,D1
	MOVE.B	inputStateFlags,D0
	AND.B	#$03,D0
	BEQ	readInputLoop
	AND.B	#$01,D0
	BEQ	lbC04D322
	SUBQ.B	#$01,D1
	BPL	lbC04D332
	MOVE.B	#$00,D1
	BEQ	lbC04D332
lbC04D322:
	CMP.B	maxMenuIndex,D1
	BEQ	lbC04D330
	BCC	lbC04D332
lbC04D330:
	ADDQ.B	#$01,D1
lbC04D332:
	MOVE.B	D1,selectedMenuItem
	JMP	renderAllMenuOptions

delayRoutine:
	MOVE.B	#$14,D2
delayWithParam:
	MOVE.B	#$14,D0
	MOVE.B	D0,tempByte3
lbC04D34C:
	SUBQ.B	#$01,tempByte4
	BNE	lbC04D34C
	SUBQ.B	#$01,tempByte3
	BNE	lbC04D34C
	SUBQ.B	#$01,D2
	BNE	delayWithParam
	RTS

handleMenuRaceOptions:
	TST.B	D0
	BNE	handleTrackSelection
	JSR	displayTrackRecordsScreen
	BRA	handleMainMenu

handleTrackSelection:
	JSR	selectDivisionAndTrack
	CMP.B	#$02,D0
	BCC	handleMainMenu
	MOVE.B	D0,selectedTrackInDivision
	MOVE.B	#$01,divisionSelectedFlag
	MOVE.B	selectedDivision,D0
	ASL.B	#$01,D0
	ADD.B	selectedTrackInDivision,D0
	JSR	setCurrentTrackID
	JMP	delayRoutine

lbC04D3AE:
	MOVE.B	#$00,D0
	JSR	encodeOrDecodeLeagueData
	MOVE.B	#$80,D0
	MOVE.B	D0,selectedTrackInDivision
	RTS

lbC04D3C4:
	TST.B	networkGameMode
	BPL	lbC04D3E4
	MOVE.B	#$20,localInputStateCache
	MOVE.B	#$B2,networkProtocolState
	JSR	waitForNetworkHandshake
lbC04D3E4:
	JSR	delayRoutine
handleMainMenu:
	MOVE.B	#$00,directionalInputBits
	TST.B	divisionSelectedFlag
	BNE	handleTrackSelection
	MOVE.B	#$01,D0
	TST.B	selectedTrackInDivision
	BPL	lbC04D40E
	MOVE.B	#$02,D0
lbC04D40E:
	MOVE.B	#$03,D2
	MOVE.B	#$00,D1
	JSR	displayMenu
	CMP.B	#$02,D0
	BEQ	lbC04D3AE
	BLT	handleMenuRaceOptions
	JSR	delayRoutine
	CMP.B	#$40,networkGameMode
	BEQ	lbC049BF4
	MOVE.B	#$03,D2
	MOVE.B	#$03,D0
	MOVE.B	#$04,D1
	JSR	displayMenu
	CMP.B	#$02,D0
	BLT	enterLeagueCareer
	BNE	lbC04D3C4
	JSR	initializeGameTables
	MOVE.B	#$50,D1
	JSR	checkKeyPressed
	BNE	startNewSeason
	TST.B	networkGameMode
	BPL	lbC04D48C
	MOVE.B	#$C0,localInputStateCache
	MOVE.B	#$B2,networkProtocolState
	JSR	waitForNetworkHandshake
lbC04D48C:
	JMP	prepareAndEnterMenuLoop

startNewSeason:
	TST.B	networkGameMode
	BPL	lbC04D4B2
	MOVE.B	#$80,localInputStateCache
	MOVE.B	#$B2,networkProtocolState
	JSR	waitForNetworkHandshake
lbC04D4B2:
	TST.B	additionalPlayerCount
	BNE	lbC04D4CA
	MOVE.B	#$80,D0
	JSR	encodeOrDecodeLeagueData
	BCC	lbC04D59C
lbC04D4CA:
	JSR	initializeGameData
	JSR	displayMenuScreen
	BRA	lbC04D59C

enterLeagueCareer:
	MOVE.B	D0,writeMode
	ASL.B	#$02,D0
	ADD.B	#$08,D0
	MOVE.B	D0,D1
	MOVE.B	#$00,D2
lbC04D4EC:
	MOVE.L	#leagueSeasonData,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.L	#trackSegmentGrid,A2
	MOVE.B	D0,$00(A2,D2.W)
	SUBQ.B	#$01,D2
	BNE	lbC04D4EC
	MOVE.B	bufferEncodedFlag,D0
	MOVE.B	D0,lbB00D4D0
	JSR	delayRoutine
	MOVE.B	#$00,D0
	JSR	encodeOrDecodeLeagueData
	JSR	showLoadGameMenu
	TST.B	leagueSessionMode
	BNE	lbC04D562
	TST.B	diskOperationAborted
	BMI	lbC04D55C
	MOVE.B	writeMode,D0
	BNE	lbC04D55C
	MOVE.B	#$80,D0
	JSR	encodeOrDecodeLeagueData
	BCC	lbC04D562
	MOVE.B	#$81,lbB00D494
lbC04D55C:
	JSR	restoreGameData
lbC04D562:
	CMP.B	#$81,lbB00D494
	BNE	lbC04D57E
	MOVE.W	#$0068,D1
	JSR	displayMessageWithColors
	JSR	waitForInputPress
lbC04D57E:
	CMP.B	#$80,networkGameMode
	BNE	lbC04D590
	JSR	synchronizeNetworkGame
lbC04D590:
	CMP.B	#$40,leagueSessionMode
	BEQ	lbC04D5A2
lbC04D59C:
	JSR	initializeRaceMode
lbC04D5A2:
	JMP	handleMainMenu

restoreGameData:
	MOVE.B	#$00,D2
	MOVE.B	lbB00D4D0,bufferEncodedFlag
	MOVE.L	#trackSegmentGrid,A2
	MOVE.L	#leagueSeasonData,A0
lbC04D5C2:
	MOVE.B	$00(A2,D2.W),$00(A0,D2.W)
	SUBQ.B	#$01,D2
	BNE	lbC04D5C2
	RTS

setCurrentTrackID:
	MOVE.B	D0,D1
	MOVE.L	#trackIDLookupTable,A0
	MOVE.B	$00(A0,D1.W),currentTrackID
;	TST.B	currentPlayerContext		; removed: dead code
;	BEQ	.evenOddOk
;	BCHG	#$00,D1
;.evenOddOk:
;	MOVE.L	#trackConfigTable,A0
;	MOVE.B	$00(A0,D1.W),trackConfigValue
	RTS

processOpponentAI:
	MOVE.B	aiEnabled,D0
	BEQ	.done
	TST.B	networkGameMode
	BNE	.done
	MOVE.B	#$00,D1
	MOVE.B	D1,opponentSegmentOffset1
	MOVE.B	D1,opponentSegmentOffset2
	MOVE.B	D1,aiMovementOverride
	MOVE.B	aiActionTimer,D0
	BEQ	.determinePatternOffset
	TST.B	frameThrottleFlag
	BMI	.actionTimerOk
	SUBQ.B	#$01,aiActionTimer
.actionTimerOk:
	ADD.B	aiPatternOffset,D0
	AND.B	#$0F,D0
	MOVE.B	D0,D2
	MOVE.L	#aiMovementPatterns,A2
	MOVE.B	$00(A2,D2.W),D0
	BPL	.segmentOffsetOk
	NEG.B	D0
	ADDQ.B	#$01,D1
.segmentOffsetOk:
	MOVE.L	#opponentSegmentOffset1,A1
	MOVE.B	D0,$00(A1,D1.W)
	ADDQ.B	#$05,D2
	AND.B	#$0F,D2
	MOVE.L	#aiMovementPatterns,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.B	D0,aiMovementOverride
	JMP	.actionHandled

.determinePatternOffset:
	MOVE.B	opponentSegmentIndex,D2
	MOVE.L	#segmentVisibilityData,A0
	TST.B	$00(A0,D2.W)
	BMI	.actionHandled
	TST.B	opponentAheadFlag
	BMI	.actionHandled
	TST.B	segmentSteeringFlags
	BMI	.actionHandled
	MOVE.B	#$08,D2
	TST.B	aiPatternControlFlags
	BPL	.actionHandled
	BTST	#$06,aiPatternControlFlags
	BEQ	.patternOffsetOk
	MOVE.B	#$10,D2
.patternOffsetOk:
	MOVE.B	D2,aiPatternOffset
	JSR	generateRandomNumber
	AND.B	#$1F,D0
	MOVE.B	D0,tempByte4
	MOVE.B	opponentID,D0
	CMP.B	tempByte4,D0
	BLT	.actionHandled
	MOVE.B	#$10,D0
	MOVE.B	D0,aiActionTimer
.actionHandled:
	MOVE.B	reverseDirectionFlag,D0
	LSR.B	#$01,D0
	MOVE.B	segmentSteeringFlags,D3
	EOR.B	D3,D0
	MOVE.B	D0,aiPatternControlFlags
.done:
	RTS

applyTrackSegmentGeometry:
	MOVE.B	currentSegmentIndex,D1
	JSR	loadTrackSegmentConfiguration
	MOVE.W	geometryDatabaseOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A5
	MOVE.W	D1,D0
	JSR	transformSegmentToViewSpace
	MOVE.W	cameraRotationFlags,D0
	SUB.W	segmentSlopeFlags,D0
	MOVE.W	D0,trackHeightDifference
	TST.B	segmentSteeringFlags
	BMI	lbC04D850
	BTST	#$06,segmentSteeringFlags
	BNE	lbC04D7CE
	JSR	applyTrackDirectionTransform
	MOVE.B	$0003(A5),D3
	ASL.W	#$08,D3
	MOVE.B	$0002(A5),D3
	MOVE.W	tempWord1,D0
lbC04D7B0:
	SUB.W	D3,D0
	MOVE.W	D0,lateralRoadPosition
	MOVE.W	tempWord2,lbW00D410
	MOVE.W	segmentSlopeFlags,segmentTargetAngle
	RTS

lbC04D7CE:
	JSR	applyTrackDirectionTransform
	MOVE.B	#$B5,tempByte3
	MOVE.W	tempWord1,D0
	SUB.W	tempWord2,D0
	MOVE.B	tempByte3,D3
	ASL.W	#$07,D3
	BCLR	#$0F,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	MOVE.B	$0003(A5),D3
	ASL.W	#$08,D3
	MOVE.B	$0002(A5),D3
	SUB.W	D3,D0
	MOVE.W	D0,lateralRoadPosition
	MOVE.B	$0007(A5),tempByte3
	MOVE.W	tempWord1,D0
	ADD.W	tempWord2,D0
	MOVE.B	tempByte3,D3
	ASL.W	#$07,D3
	BCLR	#$0F,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	MOVE.W	D0,lbW00D410
	MOVE.B	$0005(A5),D3
	ASL.W	#$08,D3
	MOVE.B	$0004(A5),D3
	ADD.W	segmentSlopeFlags,D3
	MOVE.W	D3,segmentTargetAngle
	RTS

lbC04D850:
	MOVE.B	#$02,D2
	JSR	interpolateOpponentTrackPositionFromData
	MOVE.W	tempWord1,D0
	MOVE.W	tempWord2,D3
	JSR	calculateDivision
	MOVE.W	D0,-(SP)
	JSR	calculateVectorMagnitude
	MOVE.W	D0,perspectiveDepthDivisor
	MOVE.W	(SP)+,D0
	ADD.W	cameraRotationFlags,D0
	BPL	lbC04D88E
	ADD.W	#$8000,D0
	BRA	lbC04D892

lbC04D88E:
	SUB.W	#$8000,D0
lbC04D892:
	MOVE.W	D0,lbW00D51C
	ADD.W	#$4000,D0
	SUB.W	trackDirectionInversionFlag,D0
	MOVE.W	D0,segmentTargetAngle
	MOVE.B	segmentSteeringFlags,D4
	AND.B	#$03,D4
	NEG.B	D4
	ADDQ.B	#$01,D4
	MOVE.B	$0007(A5),D3
	ASL.W	#$08,D3
	MOVE.B	$0006(A5),D3
	ASL.W	#$06,D3
	MOVE.W	lbW00D51C,D0
	SUB.W	D3,D0
	SUB.W	segmentSlopeFlags,D0
	BPL	lbC04D8D6
	NEG.W	D0
lbC04D8D6:
	MOVE.B	$0008(A5),tempByte3
	MOVE.B	tempByte3,D3
	ASL.W	#$07,D3
	BCLR	#$0F,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	TST.B	D4
	BPL	lbC04D904
	NEG.B	D4
	AND.L	#$00000007,D4
	ASL.W	D4,D0
	BRA	lbC04D90C

lbC04D904:
	AND.L	#$00000007,D4
	LSR.W	D4,D0
lbC04D90C:
	MOVE.W	D0,lbW00D410
	LSR.W	#$07,D0
	ADDQ.B	#$02,D0
	CMP.B	trackSegmentLimit,D0
	BLT	lbC04D980
	MOVE.B	trackGeometryTypeIndex,D0
	CMP.B	#$01,D0
	BEQ	lbC04D936
	CMP.B	#$03,D0
	BNE	lbC04D980
lbC04D936:
	MOVE.B	currentSegmentIndex,tempByte2
	TST.B	reverseDirectionFlag
	BEQ	lbC04D956
	JSR	retreatToPreviousSegment
	JMP	lbC04D95C

lbC04D956:
	JSR	advanceToNextSegment
lbC04D95C:
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$0F,D0
	CMP.B	#$04,D0
	BNE	lbC04D976
	BRA	applyTrackSegmentGeometry

lbC04D976:
	MOVE.B	tempByte2,currentSegmentIndex
lbC04D980:
	JSR	calculatePerspectiveAdjustment
	MOVE.B	$000A(A5),D3
	ASL.W	#$08,D3
	MOVE.B	$0009(A5),D3
	SUB.W	perspectiveDepthDivisor,D3
	TST.B	trackDirectionInversionFlag
	BPL	lbC04D9A2
	NEG.W	D3
lbC04D9A2:
	MOVE.W	D3,lateralRoadPosition
	RTS

getTrackDataPoint:
	MOVE.B	D1,D2
	TST.B	geometryFormatFlag
	BPL	lbC04D9F6
	BCLR	#$00,D2
	BTST	#$00,D1
	BNE	lbC04D9DC
	MOVE.B	$01(A4,D2.W),D3
	MOVE.B	$00(A4,D2.W),D0
	AND.B	#$7F,D0
	ASL.W	#$08,D0
	OR.B	D3,D0
	ADD.W	segmentBezierOffset1,D0
	BRA	lbC04DA34

lbC04D9DC:
	MOVE.B	$01(A5,D2.W),D3
	MOVE.B	$00(A5,D2.W),D0
	AND.B	#$7F,D0
	ASL.W	#$08,D0
	OR.B	D3,D0
	ADD.W	segmentBezierOffset2,D0
	BRA	lbC04DA34

lbC04D9F6:
	LSR.B	#$01,D2
	BCS	lbC04DA1A
	MOVE.B	$00(A4,D2.W),D0
	MOVE.B	D0,D3
	ASL.B	#$01,D0
	AND.W	#$00E0,D0
	AND.B	#$0F,D3
	ASL.W	#$08,D3
	OR.W	D3,D0
	ADD.W	segmentBezierOffset1,D0
	BRA	lbC04DA34

lbC04DA1A:
	MOVE.B	$00(A5,D2.W),D0
	MOVE.B	D0,D3
	ASL.B	#$01,D0
	AND.W	#$00E0,D0
	AND.B	#$0F,D3
	ASL.W	#$08,D3
	OR.W	D3,D0
	ADD.W	segmentBezierOffset2,D0
lbC04DA34:
	ASR.W	#$05,D0
	RTS

calculateTrackPosition:
	MOVE.W	lbW00D410,D0
	MOVE.B	trackModeParameter,D4
	ASL.W	#$08,D4
	TST.B	reverseDirectionFlag
	BPL	lbC04DA54
	SUB.W	D4,D0
	NEG.W	D0
lbC04DA54:
	MOVE.W	D0,trackProgressionByte
	ADD.W	#$0040,D0
	MOVE.W	D0,trackProgressionOffset
	CMP.W	D4,D0
	BLT	lbC04DA76
	MOVE.B	#$80,trackProgressionOffset
	MOVE.W	#$0000,D0
lbC04DA76:
	LSR.W	#$08,D0
	ADDQ.B	#$01,D0
;	ASL.B	#$01,D0
;	MOVE.B	D0,lbB00D4E5				; removed: dead code
;	ASL.B	#$01,D0
	add.b	d0,d0					; added
	add.b	d0,d0
	MOVE.B	D0,renderingLoopIndex
	MOVE.B	reverseDirectionFlag,D0
	BPL	lbC04DAA2
	MOVE.W	D4,D0
	SUB.W	lbW00D410,D0
	LSR.W	#$08,D0
	BRA	lbC04DAA8

lbC04DAA2:
	MOVE.B	lbW00D410,D0
lbC04DAA8:
	MOVE.B	#$20,D3
	SUB.B	D0,D3
	TST.B	trackProgressionOffset
	BPL	lbC04DABE
	ADD.B	trackModeParameter,D3
lbC04DABE:
	MOVE.B	D3,segmentDepthCounter
	AND.W	#$00FF,D3
	MOVE.W	D3,visibilityAccumulator
	RTS

updateWheelHeightsFromTrack:
	MOVE.B	playerSegmentIndex,D1
	MOVE.B	D1,currentSegmentIndex
	JSR	loadTrackSegmentConfiguration
	MOVE.B	#$00,renderingOrderMode
	MOVE.B	#$04,D1
.processNextWheel:
	MOVE.B	D1,wheelDataOffset
	MOVE.B	playerSegmentIndex,D0
	CMP.B	currentSegmentIndex,D0
	BEQ	.segmentAlreadyLoaded
	MOVE.B	D0,D1
	MOVE.B	D1,currentSegmentIndex
	JSR	loadTrackSegmentConfiguration
	MOVE.B	wheelDataOffset,D1
.segmentAlreadyLoaded:
	MOVE.B	segmentOrientationPrimary,tempByte3
	MOVE.L	#wheelCornerXFrontLeft,A1
	MOVE.W	$00(A1,D1.W),D0
	ASR.W	#$04,D0
	ADD.W	lateralRoadPosition,D0
	CMP.W	#$0180,D0
	BCS	.lateralPositionValid
	BSET	#$07,wheelOutOfLateralBoundsFlag
	MOVE.W	D0,lateralPositionOutOfBounds
	BMI	.setLateralToMin
	MOVE.B	#$FF,D0
	BRA	.lateralCalculationDone

.setLateralToMin:
	MOVE.B	#$00,D0
	BRA	.lateralCalculationDone

.lateralPositionValid:
	TST.W	D0
	BPL	.lateralPositionPositive
	NEG.W	D0
.lateralPositionPositive:
	MOVE.B	tempByte3,D3
	ASL.W	#$07,D3
	BCLR	#$0F,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	CMP.W	#$0100,D0
	BLT	.lateralCalculationDone
	MOVE.B	#$FF,D0					; originally $000000FF
.lateralCalculationDone:
	MOVE.B	D0,lateralTrackPosition
	TST.B	reverseDirectionFlag
	BPL	.forwardDirection
	EOR.B	#$FF,D0
.forwardDirection:
	CMP.B	#$04,D1
	BNE	.notRearWheel
	MOVE.B	D0,playerLateralPosition
.notRearWheel:
	MOVE.B	segmentOrientationAlternate,tempByte3
	MOVE.L	#wheelCornerYFrontLeft,A1
	MOVE.W	$00(A1,D1.W),D0
	ASR.W	#$03,D0
	MOVE.B	tempByte3,D3
	ASL.W	#$07,D3
	BCLR	#$0F,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	ADD.W	lbW00D410,D0
	MOVE.W	D0,forwardPositionIntermediate
	MOVE.B	forwardPositionIntermediate,D0
	ASL.B	#$01,D0
	MOVE.B	D0,segmentDataIndexScaled
	BMI	.segmentIndexOutOfBounds
	CMP.B	maxSegmentIndex,D0
	BLT	.segmentIndexValid
.segmentIndexOutOfBounds:
	JSR	handleSegmentTransition
.segmentIndexValid:
	MOVE.W	primaryGeometryOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A4
	MOVE.W	alternateGeometryOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A5
	TST.B	reverseDirectionFlag
	BMI	.reverseDirection
	MOVE.B	segmentDataIndexScaled,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,splineControlPoint1
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,splineControlPoint2
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,splineControlPoint3
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,splineControlPoint4
	ADDQ.B	#$01,D1
	BRA	.controlPointsLoaded

.reverseDirection:
	MOVE.B	trackSegmentLimit,D1
	SUB.B	segmentDataIndexScaled,D1
	SUB.B	#$04,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,splineControlPoint4
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,splineControlPoint3
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,splineControlPoint2
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,splineControlPoint1
	ADDQ.B	#$01,D1
.controlPointsLoaded:
	MOVE.B	wheelDataOffset,D1
	JSR	updateCarWorldPositionCoordinate
	SUBQ.B	#$02,D1
	BPL	.processNextWheel
	RTS

applyTrackDirectionTransform:
	TST.B	trackHeightDifference
	BMI	.checkNegative
	BTST	#$06,trackHeightDifference
	BNE	.rotation90CCW
	MOVE.W	#$0000,D0
	SUB.W	baseCoordinateX,D0
	MOVE.W	D0,tempWord1
	MOVE.W	#$0000,D0
	SUB.W	baseCoordinateY,D0
	MOVE.W	D0,tempWord2
	RTS

.rotation90CCW:
	MOVE.W	#$0000,D0
	SUB.W	baseCoordinateY,D0
	MOVE.W	D0,tempWord1
	MOVE.W	#$0800,D0
	ADD.W	baseCoordinateX,D0
	MOVE.W	D0,tempWord2
	RTS

.checkNegative:
	BTST	#$06,trackHeightDifference
	BNE	.rotation90CW
	MOVE.W	#$0800,D0
	ADD.W	baseCoordinateX,D0
	MOVE.W	D0,tempWord1
	MOVE.W	#$0800,D0
	ADD.W	baseCoordinateY,D0
	MOVE.W	D0,tempWord2
	RTS

.rotation90CW:
	MOVE.W	#$0800,D0
	ADD.W	baseCoordinateY,D0
	MOVE.W	D0,tempWord1
	MOVE.W	#$0000,D0
	SUB.W	baseCoordinateX,D0
	MOVE.W	D0,tempWord2
	RTS

handleSegmentTransition:
	MOVE.B	forwardPositionIntermediate,D0
	MOVE.B	reverseDirectionFlag,D3
	EOR.B	D3,D0
	BPL	lbC04DDB0
	JSR	retreatToPreviousSegment
	JSR	loadTrackSegmentConfiguration
	MOVE.B	reverseDirectionFlag,D0
	BPL	lbC04DDDC
	BMI	lbC04DDC6
lbC04DDB0:
	JSR	advanceToNextSegment
	JSR	loadTrackSegmentConfiguration
	TST.B	reverseDirectionFlag
	BMI	lbC04DDDC
lbC04DDC6:
	MOVE.B	#$00,segmentDataIndexScaled
	TST.B	forwardPositionIntermediate
	BPL	lbC04DE18
	BMI	lbC04DDF4
lbC04DDDC:
	MOVE.B	trackSegmentLimit,D0
	SUBQ.B	#$04,D0
	MOVE.B	D0,segmentDataIndexScaled
	TST.B	forwardPositionIntermediate
	BMI	lbC04DE18
lbC04DDF4:
	NEG.B	segmentBlendParam
	BNE	lbC04DE06
	MOVE.B	#$FF,segmentBlendParam
lbC04DE06:
	NEG.B	lateralTrackPosition
	BNE	lbC04DE18
	MOVE.B	#$FF,lateralTrackPosition
lbC04DE18:
	RTS

advanceToNextSegment:
	MOVE.B	currentSegmentIndex,D1
	ADDQ.B	#$01,D1
	CMP.B	numTrackSegments,D1
	BLT	lbC04DE30
	MOVE.B	#$00,D1
lbC04DE30:
	MOVE.B	D1,currentSegmentIndex
	RTS

retreatToPreviousSegment:
	MOVE.B	currentSegmentIndex,D1
	SUBQ.B	#$01,D1
	BPL	lbC04DE4C
	MOVE.B	numTrackSegments,D1
	SUBQ.B	#$01,D1
lbC04DE4C:
	MOVE.B	D1,currentSegmentIndex
	RTS

calculateBilinearTrackInterpolation:
	MOVE.B	lateralTrackPosition,D3
	AND.W	#$00FF,D3
	MOVE.W	splineControlPoint2,D0
	SUB.W	splineControlPoint1,D0
	MULS	D3,D0
	MOVE.W	splineControlPoint1,D4
	EXT.L	D4
	ASL.L	#$08,D4
	ADD.L	D4,D0
	MOVE.L	D0,D5
	MOVE.W	splineControlPoint4,D0
	SUB.W	splineControlPoint3,D0
	MULS	D3,D0
	MOVE.W	splineControlPoint3,D4
	EXT.L	D4
	ASL.L	#$08,D4
	ADD.L	D4,D0
	MOVE.B	segmentBlendParam,D3
	AND.W	#$00FF,D3
	SUB.L	D5,D0
	MOVE.L	D0,D4
	BPL	lbC04DEA8
	NEG.L	D4
lbC04DEA8:
	CMP.L	#$00008000,D4
	BLT	lbC04DED0
	ASR.L	#$03,D0
	TST.W	D0
	BPL	lbC04DEC8
	NEG.W	D0
	MULU	D3,D0
	MOVE.B	#$00,D0
	NEG.L	D0
	BRA	lbC04DECA

lbC04DEC8:
	MULU	D3,D0
lbC04DECA:
	ASL.L	#$03,D0
	BRA	lbC04DEE6

lbC04DED0:
	TST.W	D0
	BPL	lbC04DEE4
	NEG.W	D0
	MULU	D3,D0
	MOVE.B	#$00,D0
	NEG.L	D0
	BRA	lbC04DEE6

lbC04DEE4:
	MULU	D3,D0
lbC04DEE6:
	ASR.L	#$08,D0
	ADD.L	D5,D0
	MOVE.L	D0,tempByte1
	RTS

updateCarWorldPositionCoordinate:
	JSR	calculateBilinearTrackInterpolation
	ASL.B	#$01,D1
	MOVE.L	#wheelHeightFrontLeft,A3
	BCLR	#$07,wheelOutOfLateralBoundsFlag
	BEQ	lbC04DF12
	JSR	checkLateralBoundsAndBounce
lbC04DF12:
	MOVE.B	carSpeedMagnitude,D0
	CMP.B	#$0A,D0
	BLT	lbC04DF32
lbC04DF20:
	MOVE.L	#wheelHeightFrontLeft,A0
	MOVE.L	tempByte1,$00(A3,D1.W)
	LSR.B	#$01,D1
	RTS

lbC04DF32:
	MOVE.B	cameraAngleX,D0
	BPL	lbC04DF3E
	NEG.B	D0
lbC04DF3E:
	CMP.B	#$05,D0
	BGT	lbC04DF20
	MOVE.L	$00(A3,D1.W),D0
	ADD.L	tempByte1,D0
	ROXR.L	#$01,D0
	MOVE.L	D0,$00(A3,D1.W)
	LSR.B	#$01,D1
	RTS

calculatePerspectiveAdjustment:
	MOVE.W	tempWord1,D0
	JSR	squareAndAbsolute
	MOVE.L	D0,D4
	MOVE.W	tempWord2,D0
	JSR	squareAndAbsolute
	ADD.L	D0,D4
	MOVE.W	perspectiveDepthDivisor,D0
	JSR	squareAndAbsolute
	MOVE.B	trackGeometryTypeIndex,D2
	MOVE.L	#lbL04DFB8,A0
	MOVE.B	$00(A0,D2.W),tempByte3
	SUB.L	D0,D4
	LSR.L	#$08,D4
	MOVE.W	D4,D0
	MOVE.B	tempByte3,D3
	ASL.W	#$07,D3
	BCLR	#$0F,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	ASR.W	#$04,D0
	ADD.W	D0,perspectiveDepthDivisor
	RTS

interpolateOpponentTrackPositionFromData:
	MOVE.W	geometryDatabaseOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A5
	TST.B	trackHeightDifference
	BMI	lbC04E070
	BTST	#$06,trackHeightDifference
	BNE	lbC04E02E
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateX,tempWord1
	ADD.W	D3,tempWord1
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateY,tempWord2
	ADD.W	D3,tempWord2
	RTS

lbC04E02E:
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateY,tempWord2
	ADD.W	D3,tempWord2
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateX,tempWord1
	SUB.W	D3,tempWord1
	ADD.W	#$0800,tempWord1
	RTS

lbC04E070:
	BTST	#$06,trackHeightDifference
	BNE	lbC04E0C6
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateX,tempWord1
	SUB.W	D3,tempWord1
	ADD.W	#$0800,tempWord1
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateY,tempWord2
	SUB.W	D3,tempWord2
	ADD.W	#$0800,tempWord2
	RTS

lbC04E0C6:
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateY,tempWord2
	SUB.W	D3,tempWord2
	ADD.W	#$0800,tempWord2
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateX,tempWord1
	ADD.W	D3,tempWord1
	RTS

checkLateralBoundsAndBounce:
	MOVE.W	lateralPositionOutOfBounds,D0
	BMI	lbC04E120
	MOVE.W	#$0180,D0
	SUB.W	lateralPositionOutOfBounds,D0
	BPL	lbC04E122
lbC04E120:
	NEG.W	D0
lbC04E122:
	CMP.W	#$0030,D0
	BGT	lbC04E172
	AND.L	#$000000FF,D0
	ASL.L	#$04,D0
	MOVE.L	tempByte1,D3
	SUB.L	D0,D3
	SUB.L	#$00000100,D3
	CMP.L	#$00001000,D3
	BLT	lbC04E172
	MOVE.L	D3,tempByte1
	MOVE.B	lateralPositionOutOfBounds,D3
	MOVE.B	reverseDirectionFlag,D0
	EOR.B	D3,D0
	AND.B	#$80,D0
	BMI	lbC04E16A
	MOVE.B	#$40,D0
lbC04E16A:
	MOVE.B	D0,wheelBouncePhaseAccumulator
	RTS

lbC04E172:
	MOVE.L	#$00001000,tempByte1
	MOVE.B	renderingOrderMode,D0
	LSR.B	#$01,D0
	BSET	#$07,D0
	MOVE.B	D0,renderingOrderMode
	RTS

startupInitAndEnterMenu:
	MOVE.W	#$0000,imageMenuScreenPalette
	MOVE.W	#$00FF,D0
	MOVE.L	#playerNamesWithSpaces,A0
	MOVE.L	#playerNamesBuffer,A1
.copyPlayerNamesLoop:
	MOVE.B	(A0)+,(A1)+
	DBRA	D0,.copyPlayerNamesLoop
	MOVE.L	#defaultRecordTemplate,A0
	MOVE.L	#lapRecordTable,A1
	MOVE.L	#raceRecordTable,A2
	CLR.W	D1
	CLR.W	D2
.initRecordTablesLoop:
	MOVE.B	$00(A0,D2.W),$00(A1,D1.W)
	MOVE.B	$00(A0,D2.W),$00(A2,D1.W)
	SUBQ.B	#$01,D2
	BPL	.recordTemplateIndexOk
	MOVE.B	#$0F,D2
.recordTemplateIndexOk:
	SUBQ.B	#$01,D1
	BNE	.initRecordTablesLoop
	TST.B	lapRecordsLoadedFlag
	BNE	lbC04E826
	JSR	loadLapRecords
;	BRA	installLineEmulatorTrap
;
;installLineEmulatorTrap:
;	MOVE.L	#$9CEDCD02,D0
;	MOVE.L	D0,$24
;	BRA	cleanupInitializationAndStartGame
;
;cleanupInitializationAndStartGame:
	JSR	finalizeFloppyAccessAndInitCIA
	BRA	validateSaveDataChecksum

finalizeFloppyAccessAndInitCIA:
;	BTST	#DMAB_BLITTER,_custom+dmaconr			; removed
;	BNE	finalizeFloppyAccessAndInitCIA
;	OR.B	#CIAF_DSKSEL0,_ciab+ciaprb
;	MOVE.W	#(DMAF_DISK|DMAF_BLITTER|DMAF_BLITHOG),_custom+dmacon
	CLR.W	D1
	CLR.W	D2
	MOVE.B	#$00,lbB00D494
;	JMP	initializeCIA					; removed
	rts

validateSaveDataChecksum:
	MOVE.L	D0,lbL0563EC
	MOVE.L	saveSlotNameBuffer,D0
	ADD.L	saveDataChecksumValue,D0
	MOVE.L	lbL04E82C,D3
	EOR.L	D3,D0
	MOVE.L	D0,lbL04E82C
	MOVE.B	#$80,lapRecordsLoadedFlag
	CLR.W	D1
	CLR.W	D2
lbC04E826:
;	JMP	prepareAndEnterMenuLoop

prepareAndEnterMenuLoop:
	MOVE.W	#$00FF,D0
	MOVE.L	#playerNamesWithSpaces,A0
	MOVE.L	#playerNamesBuffer,A1
copyPlayerNamesWithSpacesLoop:
	MOVE.B	(A1)+,(A0)+
	DBRA	D0,copyPlayerNamesWithSpacesLoop
	MOVE.B	#$00,networkGameMode
	MOVE.B	#$40,gameStateID
	TST.B	menuInitializedFlag
	BNE	lbC04E87E
	MOVE.B	#$80,menuInitializedFlag
lbC04E87E:
	JSR	initializeGameData
	MOVE.B	#$80,suppressMenuTextFlag
	JSR	displayMenuScreen
	CLR.B	suppressMenuTextFlag
	JSR	selectGameMode
	JSR	initializeRaceMode
	JSR	saveRandomState
	MOVE.B	#$F3,networkProtocolState
	JSR	waitForNetworkHandshake
menuSystemLoop:
	BCLR	#$07,raceMode
	MOVE.B	#$10,gameStateID
	JSR	handleMainMenu
	TST.B	selectedTrackInDivision
	BMI	gameStateTransition
	MOVE.B	#$12,gameStateID
	JSR	runTrackPreviewScreen
	MOVE.B	#$00,gameStateID
	JSR	runMainGame
	JSR	displayMenuScreen
	JMP	menuSystemLoop

lbC04E900:
	MOVE.B	#$C0,D0
	MOVE.B	D0,raceMode
	MOVE.B	D0,raceOutcomeFlags
	BRA	lbC04E968

gameStateTransition:
	JSR	randomizeCarAssignments
	CMP.B	#$02,raceCount
	BNE	lbC04E938
	TST.B	networkGameMode
	BEQ	lbC04E938
	MOVE.B	#$01,raceCount
lbC04E938:
	MOVE.B	#$17,D1
lbC04E93C:
	JSR	clearGameDataSlot
	CMP.B	#$10,D1
	BGE	lbC04E956
	MOVE.L	#playerStatsArray,A0
	MOVE.B	#$09,$00(A0,D1.W)
lbC04E956:
	SUBQ.B	#$01,D1
	BPL	lbC04E93C
	CLR.B	bestLapRecordHolder
	CLR.B	bestRaceRecordHolder
lbC04E968:
	MOVE.B	currentDivision,displayTrackID
	JSR	configurePlayersAndCars
	TST.B	raceMode
	BMI	startPracticeMode
	MOVE.B	player2ID,D2
	MOVE.B	player1ID,D0
	CMP.B	currentPlayerID,D0
	BEQ	startCompetitiveRace
	CMP.B	currentPlayerID,D2
	BNE	startPracticeMode
	MOVE.B	D0,D2
	JMP	startCompetitiveRace

startPracticeMode:
	JSR	setupRandomRaceParameters
	JMP	lbC04EA8C

startCompetitiveRace:
	MOVE.B	D2,opponentID
	MOVE.B	#$C0,displayFlags
	MOVE.B	#$11,gameStateID
	JSR	displayRaceMatchupScreen
	JSR	checkRaceStartReady
	BEQ	lbC04E900
	MOVE.B	#$00,D0
	JSR	displayRacePositions
	MOVE.B	#$12,gameStateID
	JSR	runTrackPreviewScreen
	MOVE.B	#$80,D0
	JSR	propagateControlKeys
	MOVE.B	#$00,gameStateID
	JSR	runMainGame
	MOVE.B	#$80,D0
	JSR	displayRacePositions
	JSR	synchronizeRaceData
	MOVE.B	#$00,D0
	JSR	propagateControlKeys
	MOVE.B	#$00,D0
	JSR	transferLapRecords
	JSR	setupRandomRaceParameters
	JSR	displayRaceEndScreen
	JSR	displayMenuScreen
	TST.B	displayFlags
	BEQ	lbC04EA60
	MOVE.B	#$01,gameStateID
	JSR	displayRaceMatchupScreen
	CLR.B	displayFlags
lbC04EA60:
	MOVE.B	#$02,gameStateID
	JSR	displayRaceMatchupScreenAlt
	MOVE.B	#$03,gameStateID
	JSR	configureRaceSetup
	TST.B	additionalPlayerCount
	BEQ	lbC04EA8C
	JSR	configureMultiplayerRace
lbC04EA8C:
	ADDQ.B	#$01,raceSeriesProgress
	ADDQ.B	#$01,currentRaceNumber
	ADDQ.W	#$01,totalRaceCounter
	MOVE.B	currentRaceNumber,D0
	CMP.B	raceCount,D0
	BCS	lbC04E968
	CLR.B	currentRaceNumber
	TST.B	additionalPlayerCount
	BNE	lbC04EADC
	JSR	displayPostRaceStandings
	JSR	displayAlternateEndScreen
	JSR	initializeRaceMode
lbC04EAD0:
	JSR	initializeGameTables
	JMP	menuSystemLoop

lbC04EADC:
	JSR	cleanupNetworkRace
	CLR.B	raceMode
	SUBQ.B	#$01,remainingRaces
	BMI	lbC04EAF6
	BRA	lbC04E938

lbC04EAF6:
	ADDQ.B	#$01,raceSeriesCounter
	CMP.B	#$04,raceSeriesCounter
	BCC	lbC04EAD0
	BRA	menuSystemLoop

runTrackPreviewScreen:
	JSR	loadPlayerConfiguration
	MOVE.W	imageTrackPreviewBackgroundPalette,D0
	JSR	fadeToColor
	MOVE.B	#$40,D0
	MOVE.B	D0,displayUpdateFlag
	MOVE.L	#imageTrackPreviewBackgroundPalette,A1
	JSR	copyPalette
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	MOVE.B	#$80,textTransparencyMode
	MOVE.L	#imageTrackPreviewBackground,A0
	MOVE.L	frameBuffers,A1
	JSR	decompressRLEImage
	MOVE.L	frameBuffers,A1
	MOVE.L	displayFrameBuffer,A0
	MOVE.L	A0,renderFrameBuffer
	MOVE.L	renderFrameBuffer,D3
	ADD.L	#$00000284,D3
	MOVE.L	D3,viewportTopAddress
	MOVE.L	A0,A3
	ADD.L	#$00007D00,A3
lbC04EB84:
	MOVE.L	(A1)+,(A0)+
	CMP.L	A3,A0
	BNE	lbC04EB84
	MOVE.B	#$09,D3
	MOVE.B	#$0A,D0
	TST.B	currentPlayerContext
	BEQ	lbC04EBA6
	MOVE.B	#$08,D3
	MOVE.B	#$04,D0
lbC04EBA6:
	MOVE.B	D3,trackColorIndex1
	MOVE.B	D0,trackColorIndex2
	JSR	displayTrackHeader
	MOVE.B	#$03,D0
	JSR	setBackgroundColor
	JSR	initializeSegmentFlags
	MOVE.B	currentTrackID,D1
	JSR	processTrackDataBuffer
	JSR	initializeLookupTables
	JSR	animateDrawBridge
	JSR	loadMountainData
	JSR	generateTrackSegmentData
	JSR	renderTrackPreview
	MOVE.B	#$2C,D1
	JSR	renderLeagueText
	tst.b	ciaBTimerBSet				; added
	beq.s	lbC04EBFC
	bclr	#6,_ciaa+ciacra
	clr.b	ciaBTimerBSet
lbC04EBFC:
	JSR	waitForTrackPreviewInput
	BCC	lbC04EC12
	JSR	renderTrackPreview
	JMP	lbC04EBFC

lbC04EC12:
	MOVE.W	#$0000,D0
	JSR	fadeToColor
	MOVE.B	#$00,displayUpdateFlag
	RTS

runMainGame:
	TST.B	networkGameMode
	BEQ	lbC04EC48
	JSR	networkTimingSync1
	JSR	networkTimingSync1
	JSR	networkHandshakeLoop
	JSR	networkTimingSync2
lbC04EC48:
	MOVE.B	#$00,networkInputSyncEnabled
	MOVE.B	#$00,networkInitPhase
	JSR	loadPlayerConfiguration
	JSR	copyMainGameBackground
	MOVE.L	#imageMainGameBackgroundPalette,A1
	JSR	copyPalette
	MOVE.B	#$0E,D0
	JSR	setForegroundColor
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
	JSR	setupDamageBar
	MOVE.B	#$09,D3
	MOVE.B	#$0A,D0
	TST.B	currentPlayerContext
	BEQ	lbC04ECA4
	MOVE.B	#$00,D3
	MOVE.B	#$08,D0
lbC04ECA4:
	MOVE.B	D3,trackColorIndex1
	MOVE.B	D0,trackColorIndex2
	JSR	displayHUDText
	MOVE.B	#$0B,D2
	JSR	renderPlayer1CarGraphic
	JSR	renderPlayer2CarGraphic
	MOVE.B	playerSpawnSegment,D1
	MOVE.B	D1,opponentSegmentIndex
	MOVE.B	#$04,opponentSubSegmentProgress
	MOVE.B	#$4C,opponentLateralPosition
	JSR	initializeTrackCoordinates
	MOVE.B	playerSpawnSegment,D1
	CMP.B	#$40,networkGameMode
	BNE	initializeGameSystemsAndMainLoop
	MOVE.B	#$80,trackSideIndicator
initializeGameSystemsAndMainLoop:
	JSR	initializePlayerAtSegment
	JSR	updateWheelSuspensionPosition
	JSR	initializeDebrisParticlePositions
	JSR	processGameFrame
	JSR	updateFrameThrottlingAndTimers
	SUBQ.B	#$01,frameCounter
	JSR	swapDisplayBuffers
	JSR	updateGamePhysics
	JSR	processGameFrame
	JSR	updateFrameThrottlingAndTimers
	SUBQ.B	#$01,frameCounter
	JSR	updateSpeedometerBar
	JSR	swapDisplayBuffers
	MOVE.B	#$80,D0
	MOVE.B	D0,frameProcessingFlag
	MOVE.B	D0,displayUpdateFlag
	MOVE.B	#$03,D2
	JSR	delayWithParam
	JSR	animatePaletteToTarget
	MOVE.W	#$8020,dmaconValueToSet
	JSR	initializeGameLoop
mainGameLoop:
	SUBQ.B	#$01,frameCounter
	move.b	framesSinceCopperlistUpdate,framesToProcess		; added
	sub.b	#1,framesToProcess
.loop:	JSR	processPlayerInput
	JSR	updateGamePhysics
	JSR	updateEngineAudioPitch
	JSR	processGameFrame
	sub.b	#1,framesToProcess
	bpl	.loop
	JSR	animateDrawBridge
	JSR	updateSpeedometerBar
	JSR	updateDamageAndTimers
	JSR	updateFrameThrottlingAndTimers
	JSR	renderDistanceDisplay
	MOVE.B	frameBufferSyncMask,D0
	AND.B	frameBufferToggle,D0
	BPL	continueGameLoop
	TST.B	lapTimeDisplayDuration
	BNE	continueGameLoop
	TST.B	networkGameMode
	BEQ	checkGameEndConditions
	TST.B	networkConnectionState
	BNE	continueGameLoop
checkGameEndConditions:
	TST.B	raceStartTimer
	BNE	lbC04EDFC
	MOVE.B	wheelMovementActive,D0
	BEQ	continueGameLoop
lbC04EDFC:
	clr.b	frameProcessingFlag		; added
	TST.B	raceCompletionState
	BNE	lbC04EE34
	MOVE.B	networkGameMode,D0
	BEQ	lbC04EE22
	MOVE.B	#$00,raceOutcomeFlags
	CMP.B	gameModeStateFlags,D0
	BNE	lbC04EE34
lbC04EE22:
	MOVE.B	#$0B,D2
	JSR	renderPlayer2CarGraphic
	MOVE.B	#$C0,raceOutcomeFlags
lbC04EE34:
	JSR	renderMessagePanel
	MOVE.B	#$3C,D2
	MOVE.B	#$04,D0
	JSR	displayGameMessage
	MOVE.W	#$FFF8,enginePitchDelta
	MOVE.B	#$00,wheelSpeed
	CMP.B	#MAJOR_IMPACT_COOLDOWN_TIME,majorImpactCooldownTimer
	BNE	lbC04EE74
	MOVE.B	holeRenderingPosition,D2
	BEQ	lbC04EE74
	JSR	renderExistingHole
lbC04EE74:
	JSR	swapDisplayBuffers
	MOVE.B	#$80,gameExitFlag
	MOVE.B	#$80,networkInputSyncEnabled
	JSR	updateNetworkGameFlags
	JSR	disableAudio
	JSR	waitForFireButtonPress
	BRA	lbC04EF74

showFramerate:
	MOVE.B	#$1F,D0
	JSR	renderCharacter
	MOVE.B	#$06,D0
	JSR	renderCharacter
	MOVE.B	#$16,D0
	JSR	renderCharacter
	MOVE.B	#$02,textHorizontalOffset
	MOVE.B	#$02,textYOffset
	move.b	framesSinceCopperlistUpdate,d0
	JSR	renderDigitAndAdvance
	rts

continueGameLoop:
;	jsr	showFramerate
	JSR	swapDisplayBuffers
	JSR	handlePause
	MOVE.B	raceStartTimer,D0
	BNE	lbC04EF0E
	MOVE.B	offTrackStateFlags,D2
	BPL	lbC04EF0E
	MOVE.B	wheelMovementActive,D0
	BEQ	lbC04EF0E
	MOVE.B	carHeightPosition,D0
	BMI	lbC04EEDC
	CMP.B	#$02,D0
	BGE	lbC04EEE2
lbC04EEDC:
	MOVE.B	D2,raceCompletionCheckFlag
lbC04EEE2:
	move.b	framesSinceCopperlistUpdate,d0
	SUB.B	d0,restartTimerCountdown		; originally #$01
	BPL	lbC04EF0E
	ADD.B	d0,restartTimerCountdown		; originally #$01
	MOVE.B	blinkCountdownTimer,D0
	BNE	lbC04EF0E
	JSR	disableAudio
	MOVE.B	lastValidSegmentIndex,D1
	JMP	initializeGameSystemsAndMainLoop

lbC04EF0E:
	TST.B	raceStartTimer
	BNE	lbC04EF2C
	TST.B	offTrackStateFlags
	BMI	mainGameLoop
	TST.B	wheelMovementActive
	BEQ	mainGameLoop
lbC04EF2C:
	MOVE.B	#$45,D1
	MOVE.B	playerInputState,D0
	JSR	checkKeyPressedOrNetworkState
	BNE	mainGameLoop
	TST.B	raceCompletionState
	BNE	lbC04EF6E
	MOVE.B	networkGameMode,D0
	BEQ	lbC04EF66
	MOVE.B	#$00,raceOutcomeFlags
	CMP.B	playerInputState,D0
	BNE	lbC04EF6E
lbC04EF66:
	MOVE.B	#$C0,raceOutcomeFlags
lbC04EF6E:
	JSR	updateNetworkGameFlags
lbC04EF74:
	MOVE.W	#$0020,dmaconValueToSet
	MOVE.W	imageMenuScreenPalette,D0
	JSR	fadeToColor
	MOVE.B	#$00,D0
	MOVE.B	D0,displayUpdateFlag
	JSR	disableAudio
	TST.B	selectedTrackInDivision
	BPL	lbC04F00A
	TST.B	additionalPlayerCount
	BEQ	lbC04F014
	MOVE.B	currentPlayerID,D1
	MOVE.L	#playerHolePositions,A0
	MOVE.B	holeRenderingPosition,$00(A0,D1.W)
	TST.B	networkGameMode
	BEQ	lbC04EFEE
	MOVE.B	opponentID,D1
	MOVE.B	lbB049561,$00(A0,D1.W)
	CMP.B	#$04,player2LapCounter
	BEQ	lbC04EFEE
	ADD.B	#$0C,D1
	JSR	clearGameDataSlot
lbC04EFEE:
	CMP.B	#$04,player1LapCounter
	BEQ	lbC04F00A
	MOVE.B	currentPlayerID,D1
	ADD.B	#$0C,D1
	JSR	clearGameDataSlot
lbC04F00A:
	MOVE.B	savedHoleRenderingPosition,holeRenderingPosition
lbC04F014:
	JSR	saveRandomState
	MOVE.B	#$80,networkInputSyncEnabled
	RTS

loadPlayerConfiguration:
	MOVE.L	#gameDataRegionStart,A0
.clearLoop:
	MOVE.B	#$00,(A0)+
	CMP.L	#segmentProcessedFlags,A0
	BNE	.clearLoop
	MOVE.L	#playerContextConfiguration,A0
	MOVE.L	#playerContextValues,A1
	MOVE.B	currentPlayerContext,D1
	MOVE.B	#$00,D2
.copyLoop:
	MOVE.B	$00(A0,D1.W),$00(A1,D2.W)
	ADDQ.B	#$01,D1
	ADDQ.B	#$01,D2
	CMP.B	#$0B,D2
	BNE	.copyLoop
	MOVE.W	#$007F,previousSpeedBarLength
	MOVE.B	#$BA,wheelBaseHeight
	MOVE.B	#$02,D1
.resetLoop:
	MOVE.B	#$09,D0
	MOVE.L	#playerStatsArray,A1
	MOVE.B	D0,$00(A1,D1.W)
	SUBQ.B	#$01,D1
	BPL	.resetLoop
	MOVE.B	currentPlayerID,D1
	ADD.B	#$0C,D1
	JSR	clearGameDataSlot
	TST.B	networkGameMode
	BEQ	lbC04F0B4
	MOVE.B	opponentID,D1
	ADD.B	#$0C,D1
	JSR	clearGameDataSlot
lbC04F0B4:
	JSR	calculateTransformMatrices
	MOVE.W	#$0400,viewportCenterY
;	MOVE.W	#$FF00,visualEffectFlags		; removed: dead code
	JSR	disableAudio
	MOVE.B	#$04,maxLapsForRace
	JSR	initializeRandomSeeds
	MOVE.B	#$3B,randomSeed2Low
	MOVE.B	trackBoostFuelPlayer1,D1
	TST.B	currentPlayerContext
	BEQ	lbC04F0FC
	MOVE.B	trackBoostFuelPlayer2,D1
lbC04F0FC:
	MOVE.B	#$00,D0
	MOVE.B	#$01,D3
	ANDI.B	#$0F,CCR
lbC04F108:
	ABCD	D3,D0
	SUBQ.B	#$01,D1
	BNE	lbC04F108
	MOVE.B	D0,boostFuelLevel
	MOVE.B	D0,maxBoostFuel
	MOVE.B	holeRenderingPosition,savedHoleRenderingPosition
	MOVE.L	#keyboardState,A0
	MOVE.W	#$007F,D0
lbC04F130:
	MOVE.B	#$00,$00(A0,D0.W)
	DBRA	D0,lbC04F130
	MOVE.L	#lineDrawingBuffer,A0
	MOVE.W	#$270F,D3
	MOVE.B	#$00,D0
lbC04F148:
	MOVE.B	D0,(A0)+
	DBRA	D3,lbC04F148
	JSR	loadPaletteColors
	JSR	initializeCIA
initializeSegmentFlags:
	MOVE.B	#$3E,D1
	MOVE.L	#trackSegmentData,A1
	MOVE.L	#segmentProcessedFlags,A2
lbC04F16A:
	MOVE.W	#$8000,$78(A1,D1.W)
	MOVE.B	#$80,$00(A2,D1.W)
	SUBQ.B	#$02,D1
	BPL	lbC04F16A
	RTS

setupDamageBar:
	TST.B	additionalPlayerCount
	BEQ	.playerOk
	MOVE.B	currentPlayerID,D1
	MOVE.L	#playerHolePositions,A0
	MOVE.B	$00(A0,D1.W),holeRenderingPosition
.playerOk:
	JMP	renderAllDamage

processPlayerInput:
	JSR	readControllerInput
	MOVE.B	wheelMovementActive,D0
	BEQ	.steeringHandled
	MOVE.B	raceStartTimer,D0
	BNE	.steeringHandled
	MOVE.B	inputStateFlags,D0
	AND.B	#$0C,D0
	BEQ	.steeringHandled
	CMP.B	#$04,D0
	BEQ	.left
	MOVE.B	#$0F,D0
	BNE	.steeringHandled
.left:	MOVE.B	#$F1,D0
.steeringHandled:
	MOVE.B	D0,steeringInputDirection
	MOVE.B	inputStateFlags,D0
	AND.B	#$10,D0
	EOR.B	#$10,D0
	MOVE.B	D0,raceActiveFlag
	MOVE.B	#$00,D2
	MOVE.B	#$00,D1
	MOVE.B	carLocalVelocityZ,D0
	BMI	lbC04F212
	CMP.B	#$78,D0
	BCC	lbC04F26C
lbC04F212:
	MOVE.B	raceStartTimer,D0
	BNE	lbC04F26C
	MOVE.B	postWreckStateFlag,D0
	BNE	lbC04F26C
	MOVE.B	inputStateFlags,D0
	AND.B	#$03,D0
	CMP.B	#$01,D0
	BEQ	lbC04F246
	BGT	lbC04F25A
	MOVE.B	accelerationStateFlag,D0
	BPL	lbC04F26C
lbC04F246:
	MOVE.B	gasInputIntensityValue,D1
	MOVE.B	gasInputAccumulatorValue,D2
	MOVE.B	#$80,D0
	BNE	lbC04F266
lbC04F25A:
	MOVE.B	#$10,D1
	MOVE.B	#$FF,D2
	MOVE.B	#$00,D0
lbC04F266:
	MOVE.B	D0,accelerationStateFlag
lbC04F26C:
	MOVE.B	D1,gasOutputIntensityValue
	MOVE.B	D2,gasOutputAccumulatorValue
	JSR	updateTurboBoostSystem
	RTS

waitForTrackPreviewInput:
	MOVE.B	#$1F,buttonReleaseMask
lbC04F288:
	JSR	readControllerInput
	AND.B	D0,buttonReleaseMask
	BNE	lbC04F288
	MOVE.B	inputStateFlags,D1
	MOVE.B	D1,D0
	AND.B	#$04,D0
	BNE	lbC04F2CE
	MOVE.B	D1,D0
	AND.B	#$08,D0
	BNE	lbC04F2C2
	MOVE.B	D1,D0
	AND.B	#$10,D0
	BEQ	lbC04F288
	ANDI.B	#$1E,CCR
	RTS

lbC04F2C2:
	SUBQ.B	#$01,cameraAngleIndex
	ORI.B	#$01,CCR
	RTS

lbC04F2CE:
	ADDQ.B	#$01,cameraAngleIndex
	ORI.B	#$01,CCR
	RTS

handlePause:
	TST.B	pauseState
	BMI	.pauseIfNotAlreadyPaused
	MOVE.B	#$19,D1
	MOVE.B	pauseKeyPressed,D0
	JSR	checkKeyPressedOrNetworkState
	BEQ	.pauseIfNotAlreadyPaused
	RTS

.pauseIfNotAlreadyPaused:
	TST.B	pauseState
	BMI	.pause
	MOVE.B	#$80,pauseState
	RTS

.pause:
	MOVE.B	#$00,pauseState
	MOVE.B	#$80,networkInputSyncEnabled
	MOVE.B	#$80,disableWheelUpdateFlag
	JSR	disableAudio
	MOVE.W	#$0000,enginePitchDelta
	MOVE.B	gameMessageActiveFlag,D0
	MOVE.W	D0,-(SP)
	MOVE.B	gameMessageIndex,D0
	MOVE.W	D0,-(SP)
	MOVE.B	gameMessageMode,D0
	MOVE.W	D0,-(SP)
	MOVE.L	renderFrameBuffer,-(SP)
	clr.b	frameProcessingFlag		; added
	MOVE.L	displayFrameBuffer,renderFrameBuffer
	JSR	renderMessagePanel
	MOVE.B	#$4C,D2
	MOVE.B	#$02,D0
	JSR	setMessageParameters
	JSR	updateGameMessageDisplay
	move.b	#$80,frameProcessingFlag	; added
	MOVE.L	(SP)+,renderFrameBuffer
	JSR	waitForUnpause
	MOVE.W	(SP)+,D0
	MOVE.B	D0,gameMessageMode
	MOVE.W	(SP)+,D0
	MOVE.B	D0,gameMessageIndex
	MOVE.W	(SP)+,D0
	MOVE.B	D0,gameMessageActiveFlag
	MOVE.B	#$00,networkInputSyncEnabled
	MOVE.B	#$00,disableWheelUpdateFlag
initializeGameLoop:
	MOVE.B	#$07,D0			; engine
	JSR	playSample
	JSR	updateEngineAudioPitch
	RTS

swapDisplayBuffers:
	TST.B	framesToWait
	BNE	swapDisplayBuffers
	EOR.B	#$01,bufferSelector
	MOVE.B	bufferSelector,D0
	ADD.B	#$05,D0
	MOVE.B	#$00,framesToWait	; originally $06
	MOVE.L	frameBuffers,D0
	MOVE.L	D0,D3
	MOVE.B	frameBufferToggle,D4
	EOR.B	#$80,D4
	MOVE.B	D4,frameBufferToggle
	BPL	lbC04F414
	MOVE.B	#$80,lbB00D5C8
	ADD.L	#$00007D00,D0
	JMP	lbC04F422

lbC04F414:
	MOVE.B	#$00,lbB00D5C8
	ADD.L	#$00007D00,D3
lbC04F422:
	MOVE.L	D0,displayFrameBuffer
	MOVE.L	D3,renderFrameBuffer
	JSR	setupFrameBufferAddresses
	RTS

updateFrameThrottlingAndTimers:
	ADDQ.B	#$01,globalFrameCounter
	MOVE.B	#$00,D2
	MOVE.B	#TIMESTEP_FACTOR,D0
;	BEQ	lbC04F452				; removed
	ADD.B	D0,frameThrottleAccumulator
	BCS	lbC04F452
	SUBQ.B	#$01,D2
lbC04F452:
	MOVE.B	D2,frameThrottleFlag
	MOVE.B	lapTimeDisplayDuration,D0
	BEQ	.lapCompletionHandled
;	SUBQ.B	#$01,lapTimeDisplayDuration
;	BNE	.lapCompletionHandled
	move.b	framesSinceCopperlistUpdate,d1			; added
	cmp.b	d1,d0
	bls.s	.handleLapCompletion
	sub.b	d1,lapTimeDisplayDuration
	bra.s	.lapCompletionHandled
.handleLapCompletion:
	clr.b	lapTimeDisplayDuration
	JSR	handleLapCompletionTiming
.lapCompletionHandled:
	TST.B	selectedTrackInDivision
	BPL	lbC04F4AA
	MOVE.B	#$01,D1
	TST.B	networkGameMode
	BEQ	lbC04F49E
	TST.B	networkPacketReadyFlag
	BNE	lbC04F4AA
	TST.B	networkConnectionState
	BNE	lbC04F4A4
lbC04F49E:
	JSR	updateLapTimer
lbC04F4A4:
	JSR	checkLapCompletion
lbC04F4AA:
	MOVE.B	#$00,D1
	JSR	updateLapTimer
	JSR	saveLapTimeToBuffer
	JSR	checkLapCompletion
	JSR	checkRaceCompletion
	TST.B	raceCompletionCheckFlag
	BPL	updateBlinkCountdownTimer
	JSR	updateBlinkCountdownTimer
updateBlinkCountdownTimer:
	MOVE.B	blinkCountdownTimer,D0
	BEQ	lbC04F536
	BMI	lbC04F526
	LSR.B	#$02,D0
	AND.B	#$01,D0
	MOVE.B	D0,blinkFlag
	TST.B	raceStartTimer
	BNE	lbC04F512
	MOVE.B	wheelMovementActive,D0
	BNE	lbC04F512
	MOVE.B	blinkCountdownTimer,D0
	CMP.B	#$06,D0
	BCS	lbC04F536
lbC04F512:
	TST.B	frameThrottleFlag
	BMI	lbC04F536
	SUBQ.B	#$01,blinkCountdownTimer
	BNE	lbC04F536
lbC04F526:
	MOVE.B	#$80,D0
	MOVE.B	D0,frameBufferSyncMask
	MOVE.B	D0,blinkCountdownTimer
lbC04F536:
	RTS

compareAndCopyPlayerStats:
	MOVE.L	#lapTimeSubseconds,A0
	MOVE.L	#lapTimeSeconds,A1
	MOVE.L	#playerStatsArray,A2
	MOVE.B	$00(A2,D1.W),D0
	CMP.B	$00(A2,D2.W),D0
	BCS	lbC04F57C
	BNE	lbC04F576
	MOVE.B	$00(A1,D1.W),D0
	CMP.B	$00(A1,D2.W),D0
	BCS	lbC04F57C
	BNE	lbC04F576
	MOVE.B	$00(A0,D1.W),D0
	CMP.B	$00(A0,D2.W),D0
	BCS	lbC04F57C
lbC04F576:
	ORI.B	#$01,CCR
	RTS

lbC04F57C:
	MOVE.L	#lapTimeSubseconds,A1
	MOVE.B	$00(A1,D1.W),$00(A1,D2.W)
	MOVE.L	#lapTimeSeconds,A1
	MOVE.B	$00(A1,D1.W),$00(A1,D2.W)
	MOVE.L	#playerStatsArray,A1
	MOVE.B	$00(A1,D1.W),$00(A1,D2.W)
	ANDI.B	#$1E,CCR
	RTS

handleLapCompletionTiming:
	MOVE.B	D1,D0
	MOVE.B	D0,-(SP)
	JSR	renderResultsCarIcon
	MOVE.B	#$02,D2
	MOVE.B	#$03,D1
	MOVE.B	#$80,D0
	JSR	renderLapTimeDisplay
	MOVE.B	(SP)+,D0
	MOVE.B	D0,D1
	RTS

checkLapCompletion:
	TST.B	D1
	BNE	.offTrackStateChecked
	BTST	#$06,offTrackStateFlags
	BNE	.lapCompletionChecked
.offTrackStateChecked:
	MOVE.L	#playerSegmentIndex,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#lapCrossingDetectionFlag,A1
	MOVE.B	$00(A1,D1.W),D2
	BPL	.checkLapLineCrossing
	CMP.B	finishLineSegmentIndex,D0
	BNE	.lapCompletionChecked
	MOVE.B	#$00,$00(A1,D1.W)
.lapCompletionChecked:
	RTS

.checkLapLineCrossing:
	CMP.B	lapLineSegment,D0
	BNE	.lapCompletionChecked
	MOVE.B	#$80,$00(A1,D1.W)
	MOVE.L	#player1LapCounter,A1
	ADDQ.B	#$01,$00(A1,D1.W)
	CMP.B	#$01,$00(A1,D1.W)
	BEQ	lbC04F64A
	TST.B	networkGameMode
	BEQ	lbC04F644
	CMP.B	#$01,D1
	BNE	lbC04F644
	TST.B	networkConnectionState
	BNE	lbC04F64A
lbC04F644:
	JSR	updateOpponentLapTime
lbC04F64A:
	JSR	togglePlayerContext
	TST.B	D1
	BNE	lbC04F6D6
	MOVE.B	player1LapCounter,D0
	CMP.B	#$01,D0
	BEQ	lbC04F680
	JSR	updateRaceRecords
	MOVE.B	#$1B*FRAMERATE_MULTIPLIER,D0				; originally $1B
	MOVE.B	D0,lapTimeDisplayDuration
	JSR	refreshLapTimerHUD
	JSR	saveLapTimeToBuffer
lbC04F680:
	MOVE.B	D1,tempByte5
	MOVE.B	#$1F,D0
	JSR	renderCharacter
	MOVE.B	#$06,D0
	JSR	renderCharacter
	MOVE.B	#$16,D0
	JSR	renderCharacter
	MOVE.B	#$02,textHorizontalOffset
	MOVE.B	#$02,textYOffset
	MOVE.B	player1LapCounter,D0
	JSR	renderDigitAndAdvance
	MOVE.B	#$00,textHorizontalOffset
	MOVE.B	#$00,textYOffset
	MOVE.B	tempByte5,D1
lbC04F6D6:
	MOVE.L	#player1LapCounter,A1
	MOVE.B	$00(A1,D1.W),D0
	CMP.B	#$01,D0
	BEQ	lbC04F714
	MOVE.B	#$02,D2
	JSR	compareAndCopyPlayerStats
	BCS	lbC04F714
	MOVE.B	D1,D0
	LSR.B	#$01,D0
	ROXR.B	#$02,D0
	MOVE.B	D0,raceWinnerBits
	BEQ	lbC04F714
	MOVE.B	#$00,lapTimeDisplayDuration
	JSR	handleLapCompletionTiming
lbC04F714:
	JSR	clearGameDataSlot
	RTS

checkRaceCompletion:
	MOVE.W	#$0001,D1
lbC04F720:
	TST.B	raceCompletionState
	BNE	lbC04F798
	MOVE.L	#player1LapCounter,A1
	MOVE.B	$00(A1,D1.W),D0
	CMP.B	maxLapsForRace,D0
	BNE	lbC04F798
	MOVE.B	D0,raceCompletionState
	MOVE.B	blinkCountdownTimer,D0
	BNE	lbC04F758
	MOVE.B	#$2C,D0
	MOVE.B	D0,blinkCountdownTimer
lbC04F758:
	MOVE.W	D1,-(SP)
	JSR	renderLeaderCarIcon
	MOVE.W	(SP)+,D1
	CMP.W	#$000B,D2
	BEQ	lbC04F780
	MOVE.B	#$54,D2
	TST.B	selectedTrackInDivision
	BPL	lbC04F78E
	MOVE.B	#$08,D2
	BNE	lbC04F78E
lbC04F780:
	MOVE.B	#$80,D0
	MOVE.B	D0,raceOutcomeFlags
	MOVE.B	#$1C,D2
lbC04F78E:
	MOVE.B	#$04,D0
	JSR	setMessageParameters
lbC04F798:
	MOVE.B	raceOutcomeFlags,D0
	AND.B	#$BF,D0
	OR.B	raceWinnerBits,D0
	MOVE.B	D0,raceOutcomeFlags
	SUBQ.B	#$01,D1
	BPL	lbC04F720
	RTS

setTextPosition:
	MOVE.B	#$1F,D0
	JSR	renderCharacter
	MOVE.B	D1,D0
	JSR	renderCharacter
	MOVE.B	D2,D0
	JMP	renderCharacter

refreshLapTimerHUD:
	MOVE.B	D1,D0
	MOVE.B	D0,-(SP)
	MOVE.B	#$02,D1
	MOVE.B	#$00,D2
	MOVE.B	lapTimeDisplayDuration,D0
	BEQ	lbC04F7EA
	MOVE.B	#$80,D0
lbC04F7EA:
	JSR	renderLapTimeDisplay
	MOVE.B	(SP)+,D0
	MOVE.B	D0,D1
	RTS

renderDigitAndAdvance:
	ADDQ.B	#$01,textHorizontalOffset
	BRA	renderDigit

renderDigit:
	ADD.B	#$30,D0
	JMP	renderCharacter

clearGameDataSlot:
	MOVE.B	#$00,D0
	MOVE.L	#lapTimeSeconds,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.L	#lapTimeSubseconds,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.L	#playerStatsArray,A1
	MOVE.B	D0,$00(A1,D1.W)
	RTS

updateLapTimer:
	tst.b	frameThrottleFlag	; added
	bne.s	lbC04F8AC
	MOVE.B	#$14,D0			; originally $13
incrementLapTimeBCD:
	MOVE.L	#lapTimeSubseconds,A0
	MOVE.L	#lapTimeSeconds,A1
	MOVE.L	#playerStatsArray,A2
	ANDI.B	#$0F,CCR
	MOVE.B	$00(A0,D1.W),D3
	ABCD	D3,D0
	BCC	lbC04F8AE
	MOVE.B	D0,$00(A0,D1.W)
	MOVE.B	$00(A1,D1.W),D0
	MOVE.B	#$00,D3
	ABCD	D3,D0
	MOVE.B	D0,$00(A1,D1.W)
	CMP.B	#$60,D0
	BCS	lbC04F88C
	MOVE.B	#$00,$00(A1,D1.W)
	ANDI.B	#$0F,CCR
	MOVE.B	$00(A2,D1.W),D0
	MOVE.B	#$01,D3
	ABCD	D3,D0
	CMP.B	#$0A,D0
	BGE	lbC04F88C
	MOVE.B	D0,$00(A2,D1.W)
lbC04F88C:
	TST.B	D1
	BNE	lbC04F8AC
	TST.B	lapTimeDisplayDuration
	BNE	lbC04F8AC
	TST.B	player1LapCounter
	BEQ	lbC04F8AC
	JSR	refreshLapTimerHUD
lbC04F8AC:
	RTS

lbC04F8AE:
	MOVE.B	D0,$00(A0,D1.W)
	RTS

updateDamageAndTimers:
	MOVE.B	damageAccumulationActive,D0
	BEQ	.damageBarUpdated
	MOVE.B	accumulatedForceFrontLeft,D0
	ADD.B	accumulatedForceFrontRight,D0
	ROXR.B	#$01,D0
	ADD.B	accumulatedForceRear,D0
	ROXR.B	#$01,D0
	MOVE.B	D0,targetDamageLevel
	JSR	updateDamageBarHUD
.damageBarUpdated:
	MOVE.B	majorImpactCooldownTimer,D0
	BEQ	.checkDamageAccumulation
;	SUBQ.B	#$01,majorImpactCooldownTimer	; originally
	move.b	framesSinceCopperlistUpdate,d2	; added
	cmp.b	d2,d0
	bcc.s	.deltaOk
	move.b	d0,d2
.deltaOk:
	sub.b	d2,majorImpactCooldownTimer
	CMP.B	#MAJOR_IMPACT_COOLDOWN_TIME,D0
	BEQ	.majorImpact
	MOVE.B	damageAccumulationActive,D0
	BNE	.minorImpact
	RTS

.majorImpact:
	MOVE.B	holeRenderingPosition,D2
	JSR	renderExistingHole
	BRA	.minorImpact			; originally JMP

.checkDamageAccumulation:
	MOVE.B	damageAccumulationActive,D0
	BEQ	.done
	MOVE.W	maxCompressionVelocity,D0
	CMP.W	#$1400,D0
	BCS	.minorImpact
	MOVE.B	holeRenderingPosition,D2
	BEQ	.minorImpact
	SUBQ.B	#$01,D2
	MOVE.B	D2,holeRenderingPosition
	JSR	renderNewHole
	MOVE.B	#MAJOR_IMPACT_COOLDOWN_TIME,D0
	MOVE.B	D0,majorImpactCooldownTimer
;	MOVE.B	#$0A,D0					; removed: unnecessary code
	MOVE.B	#$05,D0					; major impact
	BRA	.playSample				; originally BNE
.minorImpact:
	tst.b	creakingSoundCooldownTimer		; added
	bne.s	.sampleOk
	MOVE.B	maxCompressionVelocity,D0
	CMP.B	#$07,D0
	BCC	.velocityOk
	MOVE.B	#$07,D0
.velocityOk:
	ASL.B	#$02,D0
	CMP.B	#$40,D0
	BCS	.volumeOk
	MOVE.B	#$40,D0
.volumeOk:
	MOVE.B	D0,audioSample4Volume
	MOVE.B	#$04,D0					; creaking
	move.b	#17,creakingSoundCooldownTimer		; added
.playSample:
	JSR	playSample
.sampleOk:
	MOVE.B	#$00,D0
	MOVE.B	D0,damageAccumulationActive
.done:	RTS

renderResultsCarIcon:
	MOVE.B	#$0B,D2
	MOVE.B	raceWinnerBits,D0
	BNE	renderPlayer2CarGraphic
	MOVE.B	#$07,D2
renderPlayer2CarGraphic:
	MOVE.B	D2,unusedDisplayFlag2
	MOVE.B	#$11,D0
	CMP.B	#$07,D2
	BEQ	lbC04F9C0
	MOVE.B	#$12,D0
lbC04F9C0:
	BRA	renderCarIcon

renderLeaderCarIcon:
	MOVE.B	#$0B,D2
	JSR	checkForTieCondition
	BPL	renderPlayer1CarGraphic
	MOVE.B	#$07,D2
renderPlayer1CarGraphic:
	MOVE.B	D2,unusedDisplayFlag1
	MOVE.B	#$0F,D0
	CMP.B	#$07,D2
	BEQ	renderCarIcon
	MOVE.B	#$10,D0
renderCarIcon:
	MOVE.W	D2,-(SP)
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	frameBuffers,renderFrameBuffer
	MOVE.W	D0,-(SP)
	JSR	renderMaskedGraphicsObject
	MOVE.W	(SP)+,D0
	MOVE.L	renderFrameBuffer,D3
	ADD.L	#$00007D00,D3
	MOVE.L	D3,renderFrameBuffer
	JSR	renderMaskedGraphicsObject
	MOVE.L	(SP)+,renderFrameBuffer
	MOVE.W	(SP)+,D2
	RTS

renderDistanceDisplay:
	MOVE.B	frameCounter,D0
	AND.B	#$03,D0
	BEQ	.render
	RTS

.render:
	MOVE.B	#$00,D1
	MOVE.B	D1,D5
	MOVE.B	#$00,D2
	MOVE.W	opponentDistance,D0
	MOVE.W	D0,D3
	LSR.W	#$02,D3
	ADD.W	D3,D0
	LSR.W	#$02,D0
	JMP	.extractThousands

.thousandsLoop:
	SUB.W	#$03E8,D0
	ADDQ.B	#$01,D5
.extractThousands:
	CMP.W	#$03E8,D0
	BGE	.thousandsLoop
	JMP	.extractHundreds

.hundredsLoop:
	SUB.W	#$0064,D0
	ADDQ.B	#$01,D2
.extractHundreds:
	CMP.W	#$0064,D0
	BGE	.hundredsLoop
	JMP	.extractTens

.tensLoop:
	SUB.B	#$0A,D0
	ADDQ.B	#$01,D1
.extractTens:
	CMP.B	#$0A,D0
	BGE	.tensLoop
	MOVE.B	D0,tempByte1
	MOVE.B	D1,tempByte3
	MOVE.B	D2,tempByte2
	MOVE.B	D5,tempByte0
	MOVE.B	#$01,textHorizontalOffset
	MOVE.B	#$04,textYOffset
	MOVE.B	#$1F,D0
	JSR	renderCharacter
	MOVE.B	#$06,D0
	JSR	renderCharacter
	MOVE.B	#$17,D0
	JSR	renderCharacter
	MOVE.B	#$F0,D0
	TST.B	opponentAheadFlag
	BPL	.signOk
	MOVE.B	#$FD,D0
.signOk:
	JSR	renderDigitAndAdvance
	MOVE.B	tempByte0,D0
	JSR	renderDigitAndAdvance
	MOVE.B	tempByte2,D0
	JSR	renderDigitAndAdvance
	MOVE.B	tempByte3,D0
	JSR	renderDigitAndAdvance
	MOVE.B	tempByte1,D0
	JSR	renderDigitAndAdvance
	MOVE.B	#$00,textHorizontalOffset
	MOVE.B	#$00,textYOffset
	TST.B	raceCompletionState
	BNE	.done
	JSR	renderLeaderCarIcon
.done:	RTS

updateSpeedometerBar:
	MOVE.W	carLocalVelocityZ,D0
	SUB.W	#$1100,D0
	BPL	lbC04FB50
	MOVE.W	#$0000,D0
lbC04FB50:
	MOVE.W	#$B700,D3
	MULU	D3,D0
	SWAP	D0
	LSR.W	#$07,D0
	CMP.W	#$0080,D0
	BLT	lbC04FB66
	SUB.W	#$0080,D0
lbC04FB66:
	MOVE.W	D0,speedBarLength
	SUB.W	previousSpeedBarLength,D0
	BNE	lbC04FB7C
	JMP	lbC04FC1A

lbC04FB7C:
	MOVE.L	frameBuffers,A6
	ADD.L	#$00001B3C,A6
	MOVE.W	previousSpeedBarLength,D4
	MOVE.W	speedBarLength,D5
	ADDQ.W	#$01,D4
	ADDQ.W	#$01,D5
	TST.W	D0
	BMI	lbC04FBA6
	MOVE.B	#$03,D0
	BRA	lbC04FBAC

lbC04FBA6:
	MOVE.B	#$00,D0
	EXG	D4,D5
lbC04FBAC:
	JSR	setupBitplaneMasks
	MOVE.L	#lbW0580E0,A5
	JSR	fillHorizontalSpan
	MOVE.L	A6,A0
	ADD.L	#$00007D00,A0
	MOVE.W	#$0007,D3
lbC04FBCA:
	MOVE.W	(A6),$0028(A6)
	MOVE.W	$1F40(A6),$1F68(A6)
	MOVE.W	$3E80(A6),$3EA8(A6)
	MOVE.W	$5DC0(A6),$5DE8(A6)
	MOVE.W	(A6),(A0)
	MOVE.W	$1F40(A6),$1F40(A0)
	MOVE.W	$3E80(A6),$3E80(A0)
	MOVE.W	$5DC0(A6),$5DC0(A0)
	MOVE.W	(A6),$0028(A0)
	MOVE.W	$1F40(A6),$1F68(A0)
	MOVE.W	$3E80(A6),$3EA8(A0)
	MOVE.W	$5DC0(A6),$5DE8(A0)
	ADD.L	#$00000002,A6
	ADD.L	#$00000002,A0
	DBRA	D3,lbC04FBCA
lbC04FC1A:
	MOVE.W	speedBarLength,previousSpeedBarLength
	RTS

renderLapTimeDisplay:
	MOVE.B	D2,renderingIndex
	MOVE.B	D0,lapTimeSubsecondVisibility
	MOVE.L	#lbL04FD6C,A1
	MOVE.B	$04(A1,D1.W),textYOffset
	MOVE.B	#$80,textTransparencyMode
	MOVE.B	#$1F,D0
	JSR	renderCharacter
	MOVE.B	#$22,D0
	JSR	renderCharacter
	MOVE.B	$00(A1,D1.W),D0
	JSR	renderCharacter
	MOVE.B	#$05,textHorizontalOffset
	MOVE.B	#$3A,D0
	JSR	renderCharacter
	ADDQ.B	#$02,textCursorColumn
	SUBQ.B	#$02,textYOffset
	MOVE.B	#$02,textHorizontalOffset
	MOVE.B	#$2E,D0
	JSR	renderCharacter
	MOVE.B	#$00,textTransparencyMode
	ADDQ.B	#$02,textYOffset
	SUBQ.B	#$05,textCursorColumn
	MOVE.B	#$06,textHorizontalOffset
	MOVE.L	#playerStatsArray,A2
	MOVE.B	$00(A2,D2.W),D0
	AND.B	#$0F,D0
	JSR	renderDigit
	ADDQ.B	#$01,textCursorColumn
	MOVE.B	#$03,textHorizontalOffset
	MOVE.B	renderingIndex,D2
	MOVE.L	#lapTimeSeconds,A2
	MOVE.B	$00(A2,D2.W),D0
	LSR.B	#$04,D0
	JSR	renderDigit
	MOVE.B	renderingIndex,D2
	MOVE.L	#lapTimeSeconds,A2
	MOVE.B	$00(A2,D2.W),D0
	AND.B	#$0F,D0
	JSR	renderDigit
	ADDQ.B	#$04,textHorizontalOffset
	MOVE.B	renderingIndex,D2
	MOVE.L	#lapTimeSubseconds,A2
	MOVE.B	$00(A2,D2.W),D0
	LSR.B	#$04,D0
	TST.B	lapTimeSubsecondVisibility
	BMI	lbC04FD2C
	MOVE.B	#$F0,D0
lbC04FD2C:
	JSR	renderDigit
	MOVE.B	renderingIndex,D2
	MOVE.L	#lapTimeSubseconds,A2
	MOVE.B	$00(A2,D2.W),D0
	AND.B	#$0F,D0
	TST.B	lapTimeSubsecondVisibility
	BMI	lbC04FD54
	MOVE.B	#$F0,D0
lbC04FD54:
	JSR	renderDigit
	MOVE.B	#$00,textHorizontalOffset
	MOVE.B	#$00,textYOffset
	RTS

displayHUDText:
	MOVE.B	#$02,textYOffset
	MOVE.B	#$02,textHorizontalOffset
	MOVE.B	#$1F,D0
	JSR	renderCharacter
	MOVE.B	#$05,D0
	JSR	renderCharacter
	MOVE.B	#$16,D0
	JSR	renderCharacter
	MOVE.B	#$4C,D0
	JSR	renderCharacter
	ADDQ.B	#$02,textHorizontalOffset
	MOVE.B	#$1F,D0
	JSR	renderCharacter
	MOVE.B	#$08,D0
	JSR	renderCharacter
	MOVE.B	#$16,D0
	JSR	renderCharacter
	MOVE.B	#$42,D0
	JSR	renderCharacter
	MOVE.B	#$00,textHorizontalOffset
	MOVE.B	#$00,textYOffset
	RTS

setMessageParameters:
	MOVE.B	#$80,gameMessageActiveFlag
	MOVE.B	D2,gameMessageIndex
	MOVE.B	D0,gameMessageMode
	RTS

displayGameMessage:
	JSR	setMessageParameters
updateGameMessageDisplay:
	TST.B	gameMessageActiveFlag
	BMI	.displayMessage
.done:	RTS

.displayMessage:
	MOVE.B	blinkCountdownTimer,D0
	BEQ	.setupMessage
	BMI	.checkIfPressFire
	CMP.B	#$03,D0
	BGE	.setupMessage
.checkIfPressFire:
	CMP.B	#$3C,gameMessageIndex
	BNE	.done
.setupMessage:
	TST.B	pauseState
	BMI	.done
	MOVE.B	#$80,textTransparencyMode
	MOVE.B	#$80,singleBufferRenderMode
	MOVE.B	#$00,D0
	TST.B	blinkFlag
	BEQ	.colorOk
	MOVE.B	#$0F,D0
.colorOk:
	JSR	setBackgroundColor
	MOVE.B	gameMessageMode,renderModeFlag
	MOVE.B	gameMessageIndex,D2
	MOVE.B	D1,-(SP)
	MOVE.B	#$04,textCursorRow
	MOVE.B	#$13,textCursorColumn
	MOVE.B	#$03,textHorizontalOffset
	MOVE.B	#$00,textYOffset
	CMP.B	#$02,gameMessageMode
	BNE	lbC04FEAE
	MOVE.B	#$05,textYOffset
lbC04FEAE:
	MOVE.L	#gameMessageTable,A2
	MOVE.B	$00(A2,D2.W),D1
	CMP.B	#$21,D1
	BNE	lbC04FEE0
	MOVE.B	#$13,textCursorColumn
	MOVE.B	#$05,textCursorRow
	MOVE.B	#$03,textHorizontalOffset
	MOVE.B	#$02,textYOffset
lbC04FEE0:
	ADDQ.B	#$01,D2
	MOVE.B	#$03,D0
	MOVE.B	D0,segmentRepeatCounter
lbC04FEEC:
	MOVE.L	#gameMessageTable,A2
	MOVE.B	$00(A2,D2.W),D0
	CMP.B	#$3C,D0
	BNE	lbC04FF08
	ADDQ.B	#$04,textHorizontalOffset
	BRA	lbC04FF14

lbC04FF08:
	JSR	renderCharacter
	ADDQ.B	#$01,textHorizontalOffset
lbC04FF14:
	ADDQ.B	#$01,D2
	ADDQ.B	#$01,D1
	SUBQ.B	#$01,segmentRepeatCounter
	BNE	lbC04FEEC
	SUBQ.B	#$01,renderModeFlag
	BNE	lbC04FEAE
	MOVE.B	(SP)+,D1
	MOVE.B	#$00,textTransparencyMode
	MOVE.B	#$00,singleBufferRenderMode
	MOVE.B	#$00,textHorizontalOffset
	MOVE.B	#$00,textYOffset
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
	RTS

advanceWheelRotationFrame:
	MOVE.B	wheelRotationFrame,D0
	TST.W	carLocalVelocityZ
	BPL	lbC050062
	SUBQ.B	#$01,D0
	BPL	lbC050070
	MOVE.B	#$02,D0
	BRA	lbC050070

lbC050062:
	ADDQ.B	#$01,D0
	CMP.B	#$03,D0
	BCS	lbC050070
	MOVE.B	#$00,D0
lbC050070:
	MOVE.B	D0,wheelRotationFrame
	RTS

updateWheelSuspensionPosition:
	MOVE.B	#$00,D1
	MOVE.W	#$0030,D3
	MOVE.L	#graphicsRenderingParameters,A2
lbC050086:
	MOVE.L	#clampedSuspensionFrontLeft,A0
	MOVE.W	$00(A0,D1.W),D0
	ADD.W	#$0100,D0
	BPL	lbC05009C
	MOVE.W	#$0000,D0
lbC05009C:
	CMP.W	#$0800,D0
	BCS	lbC0500A8
	MOVE.W	#$07FF,D0
lbC0500A8:
	LSR.W	#$03,D0
	NOT.B	D0
	ASL.W	#$01,D0
	MOVE.L	#sineTable,A1
	MOVE.W	$00(A1,D0.W),D0
	ROL.W	#$05,D0
	AND.B	#$1F,D0
	NOT.B	D0
	ADD.B	wheelBaseHeight,D0
	MOVE.B	wheelBouncePhaseAccumulator,D4
	ASL.W	#$01,D4
	MOVE.B	D4,wheelBouncePhaseAccumulator
	BTST	#$08,D4
	BNE	lbC0500E4
	CMP.B	#$BA,D0
	BCS	lbC0500E8
lbC0500E4:
	MOVE.B	#$B9,D0
lbC0500E8:
	CMP.B	#$97,D0
	BCC	lbC0500F4
	MOVE.B	#$97,D0
lbC0500F4:
	SUB.B	#$32,D0
	AND.W	#$00FF,D0
	MOVE.L	A2,A4
	ADD.L	#$00000250,A4
	CMP.W	#$007E,D0
	BGE	lbC050112
	ADD.L	#$00000060,A4
lbC050112:
	MOVE.W	#$009E,D5
	SUB.W	D0,D5
	MOVE.W	#$0002,D4
lbC05011C:
	MOVE.W	D0,$0A(A2,D3.W)
	MOVE.W	D0,$0A(A4,D3.W)
	MOVE.W	D5,$06(A2,D3.W)
	ADD.W	#$0010,D3
	DBRA	D4,lbC05011C
	MOVE.W	#$0000,D3
	ADDQ.B	#$02,D1
	CMP.B	#$04,D1
	BLT	lbC050086
	MOVE.B	#$80,spriteUpdatePendingFlag
	RTS

initiateCarWreck:
	MOVE.B	blinkCountdownTimer,D0
	BNE	.done
	CMP.B	#$40,gameModeStateFlags
	BEQ	.gameModeStateFlagsSet
	CMP.B	#$80,gameModeStateFlags
	BEQ	.gameModeStateFlagsSet
	MOVE.B	networkGameMode,gameModeStateFlags
.gameModeStateFlagsSet:
	MOVE.B	#$02,D0
	MOVE.B	D0,postWreckStateFlag
	MOVE.B	#$92,D0
	MOVE.B	D0,wheelBaseHeight
	MOVE.B	#$82,D0
;	MOVE.B	D0,visualEffectFlags			; removed: dead code
	MOVE.B	#$3C,D0
	MOVE.B	D0,blinkCountdownTimer
	MOVE.B	#$02,D0
	MOVE.B	#$00,D2
	JSR	setMessageParameters
.done:	RTS

selectGameMode:
	MOVE.B	#$80,D0
	MOVE.B	D0,textRenderingFlag
	MOVE.B	#$00,D0
	MOVE.B	D0,additionalPlayerCount
	MOVE.B	#$02,D2
	MOVE.B	#$10,D1
	JSR	displayMenu
	CMP.B	#$01,D0
	BEQ	gameModeMultiplayer
	BGT	gameModeComputerLink
	JSR	runPlayerNameEntry
	JMP	gameModeSelected

addMultiplayerPlayers:
	MOVE.B	#$00,D0
	MOVE.B	#$01,D2
	MOVE.B	#$14,D1
	JSR	displayMenu
	CMP.B	#$00,D0
	BNE	lbC05021A
	ADDQ.B	#$01,additionalPlayerCount
gameModeMultiplayer:
	JSR	runPlayerNameEntry
	MOVE.B	additionalPlayerCount,D0
	CMP.B	#$07,D0
	BCS	addMultiplayerPlayers
lbC05021A:
	MOVE.B	additionalPlayerCount,D0
	BEQ	addMultiplayerPlayers
gameModeSelected:
	MOVE.B	#$00,D0
	MOVE.B	D0,textRenderingFlag
	RTS

gameModeComputerLink:
	JSR	establishComputerLink
	BCS	selectGameMode
	BRA	gameModeSelected

displayLeagueRaceResults:
	JSR	sortRaceResults
	MOVE.B	#$10,D0
	MOVE.B	D0,displayColumnOffset
	MOVE.B	#$0E,D0
	MOVE.B	D0,resultsTableHeader
	MOVE.B	multiplayerRaceDisplayFlag,D0
	AND.B	standingsDisplayModeFlag,D0
	BPL	lbC050324
	JSR	drawScreenFrame
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.B	#$0B,D1
	MOVE.B	#$09,D2
	JSR	setTextPosition
	MOVE.B	#$00,D1
	JSR	renderStatsText
	MOVE.B	additionalPlayerCount,D0
	CMP.B	#$05,D0
	BCS	lbC0502A4
	JSR	setTextYOffset4
lbC0502A4:
	MOVE.B	additionalPlayerCount,D1
	MOVE.L	#divisionRowPositions,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.B	D0,D2
	ADDQ.B	#$02,D0
	MOVE.B	D0,displayColumnOffset
	JSR	renderTrackInfoDisplay
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
	JSR	displayRecordHolders
	MOVE.B	additionalPlayerCount,D0
	CMP.B	#$06,D0
	BEQ	lbC0502F0
	CMP.B	#$05,D0
	BEQ	lbC0502F0
	JSR	resetTextYOffset
lbC0502F0:
	MOVE.B	additionalPlayerCount,D1
	MOVE.L	#trackColumnOffsets,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.B	D0,resultsTableHeader
	ADDQ.B	#$02,D0
	MOVE.B	additionalPlayerCount,D2
	CMP.B	#$07,D2
	BNE	lbC050318
	SUBQ.B	#$01,D0
lbC050318:
	MOVE.B	D0,displayColumnOffset
	JMP	lbC050384

lbC050324:
	JSR	renderDivisionBackgroundAndHeader
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	TST.B	multiplayerRaceDisplayFlag
	BMI	lbC05037A
	MOVE.B	#$86,D1
	JSR	renderLeagueText
	CMP.B	#$03,raceSeriesCounter
	BCS	lbC050398
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	JSR	setTextYOffset4
	MOVE.B	#$13,D1
	JSR	renderStatsText
	JSR	resetTextYOffset
	JMP	lbC050398

lbC05037A:
	MOVE.B	#$0B,D2
	JSR	renderTrackInfoDisplay
lbC050384:
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.B	#$8C,D1
	JSR	renderStatsText
lbC050398:
	MOVE.B	#$0E,D0
	MOVE.B	D0,currentMenuItem
	MOVE.B	additionalPlayerCount,D0
	ADDQ.B	#$02,D0
	JSR	renderMenuCursorAndAdvanceMultiSegment
lbC0503B0:
	JSR	incrementMenuPosition
	ADDQ.B	#$01,displayRowOffset
	JSR	renderStandingsEntry
	BNE	lbC0503B0
	RTS

incrementMenuPosition:
	MOVE.B	#$05,D1
	MOVE.B	displayRowOffset,D2
	JSR	setTextPosition
	ADDQ.B	#$01,currentMenuItem
	RTS

renderTrackInfoDisplay:
	MOVE.B	D2,lbB050474
	MOVE.B	currentTrackID,D1
	MOVE.L	#trackDisplayYOffsets,A0
	MOVE.B	$00(A0,D1.W),D1
	SUBQ.B	#$06,D1
	TST.B	additionalPlayerCount
	BEQ	lbC05040E
	TST.B	currentPlayerContext
	BEQ	lbC05040E
	SUBQ.B	#$02,D1
lbC05040E:
	JSR	setTextPosition
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	MOVE.B	#$93,D1
	JSR	renderMenuString
	MOVE.B	currentTrackID,D1
	JSR	renderTrackName
	MOVE.B	additionalPlayerCount,D0
	BEQ	lbC050462
	MOVE.B	currentPlayerContext,D0
	BEQ	lbC050462
	MOVE.B	#$21,D1
	MOVE.B	lbB050474,D2
	JSR	setTextPosition
	MOVE.B	#$63,D1
	JSR	renderMenuString
lbC050462:
	RTS

lbC050576:
	JSR	renderCharacter
	ADDQ.B	#$01,D1
renderStatsText:
	MOVE.L	#raceResultsText,A1
	MOVE.B	$00(A1,D1.W),D0
	CMP.B	#$FF,D0
	BNE	lbC050576
	RTS

renderLapTime:
	MOVE.L	#playerStatsArray,A1
	MOVE.B	$00(A1,D1.W),D0
	CMP.B	#$09,D0
	BCC	lbC0506A4
	MOVE.L	#lapTimeSeconds,A1
	OR.B	$00(A1,D1.W),D0
	BEQ	lbC0506A4
	MOVE.L	#playerStatsArray,A1
	MOVE.B	$00(A1,D1.W),D0
	JSR	renderDigit
	MOVE.B	#$3A,D0
	JSR	renderCharacter
	MOVE.L	#lapTimeSeconds,A1
	MOVE.B	$00(A1,D1.W),D0
	JSR	renderBCDDigitPair
	MOVE.B	#$2E,D0
	JSR	renderCharacter
	MOVE.L	#lapTimeSubseconds,A1
	MOVE.B	$00(A1,D1.W),D0
	JMP	renderBCDDigitPair

lbC0506A4:
	MOVE.B	#$2D,D0
	MOVE.B	#$07,D2
lbC0506AC:
	JSR	renderCharacter
	SUBQ.B	#$01,D2
	BNE	lbC0506AC
	RTS

renderPaddedDecimal:
	MOVE.B	D0,-(SP)
	JSR	renderTwoSpaces
	MOVE.B	(SP)+,D0
	JMP	renderDecimal

renderDecimalCompact:
	CMP.B	#$0A,D0
	BCS	lbC0506FE
renderDecimal:
	CMP.B	#$0A,D0
	BCC	lbC0506E8
	MOVE.B	D0,-(SP)
	JSR	renderSpace
	JMP	lbC0506F8

lbC0506E8:
	JSR	convertBinaryToBCD
renderBCDDigitPair:
	MOVE.B	D0,-(SP)
	LSR.B	#$04,D0
	JSR	renderDigit
lbC0506F8:
	MOVE.B	(SP)+,D0
	AND.B	#$0F,D0
lbC0506FE:
	JMP	renderDigit

addLapTimesBCD:
	MOVE.L	#lapTimeSubseconds,A0
	MOVE.L	#lapTimeSeconds,A1
	MOVE.L	#playerStatsArray,A2
	ANDI.B	#$0F,CCR
	MOVE.B	$00(A0,D1.W),D3
	MOVE.B	$00(A0,D2.W),D0
	ABCD	D3,D0
	MOVE.B	D0,$00(A0,D2.W)
	MOVE.B	$00(A1,D1.W),D3
	MOVE.B	$00(A1,D2.W),D0
	ABCD	D3,D0
	BCS	lbC05073E
	CMP.B	#$60,D0
	BCS	lbC050750
lbC05073E:
	MOVE.B	#$60,D3
	ANDI.B	#$0F,CCR
	SBCD	D3,D0
	ORI.B	#$10,CCR
	BRA	lbC050754

lbC050750:
	ANDI.B	#$0F,CCR
lbC050754:
	MOVE.B	D0,$00(A1,D2.W)
	MOVE.B	$00(A2,D1.W),D3
	MOVE.B	$00(A2,D2.W),D0
	ABCD	D3,D0
	MOVE.B	D0,$00(A2,D2.W)
	RTS

randomizeCarAssignments:
	MOVE.B	#$06,D1
	TST.B	additionalPlayerCount
	BEQ	lbC050814
	MOVE.B	#$01,D1
	MOVE.B	#$01,remainingRaces
lbC050782:
	MOVE.B	D1,tempByte3
	MOVE.B	D1,D0
	MOVE.B	currentDivision,D2
	BEQ	lbC0507B6
	JSR	generateRandomNumber
	AND.B	#$01,D0
	ADDQ.B	#$01,D0
	ADD.B	lbB05047E,D0
	CMP.B	#$03,D0
	BCS	lbC0507B0
	SUBQ.B	#$03,D0
lbC0507B0:
	MOVE.B	D0,lbB05047E
lbC0507B6:
	MOVE.L	#divisionBaseOffsets,A0
	MOVE.L	#opponentTraitsBuffer,A1
	MOVE.L	#opponentBehaviorTraits,A2
	MOVE.L	#playerNamesBuffer,A3
	MOVE.L	#playerNamesWithSpaces,A4
	MOVE.L	#lbW04AA40,A5
	ADD.B	$00(A0,D2.W),D0
	MOVE.B	D0,D2
	MOVE.B	D0,$00(A5,D1.W)
	MOVE.B	$00(A1,D2.W),$00(A2,D1.W)
	ASL.B	#$04,D1
	ASL.B	#$04,D2
	MOVE.W	#$000F,D3
lbC0507F2:
	MOVE.B	$00(A3,D2.W),$00(A4,D1.W)
	ADDQ.B	#$01,D1
	ADDQ.B	#$01,D2
	DBRA	D3,lbC0507F2
	MOVE.B	tempByte3,D1
	SUBQ.B	#$01,D1
	BPL	lbC050782
	MOVE.B	additionalPlayerCount,D1
	ADDQ.B	#$01,D1
lbC050814:
	MOVE.B	D1,raceCount
	MOVE.B	#$00,raceSeriesProgress
	RTS

renderThreeSpaces:
	MOVE.B	#$20,D0
	JSR	renderCharacter
renderTwoSpaces:
	MOVE.B	#$20,D0
	JSR	renderCharacter
renderSpace:
	MOVE.B	#$20,D0
	JMP	renderCharacter

cleanupNetworkRace:
	TST.B	networkGameMode
	BEQ	lbC050858
	CMP.B	#$02,additionalPlayerCount
	BLT	lbC050874
lbC050858:
	MOVE.B	#$80,D0
	MOVE.B	D0,standingsDisplayModeFlag
	JSR	configureMultiplayerRace
	JSR	configureRaceSetup
	CLR.B	standingsDisplayModeFlag
lbC050874:
	RTS

configureMultiplayerRace:
	MOVE.B	#$80,D0
	MOVE.B	D0,multiplayerRaceDisplayFlag
	JSR	configureRaceSetup
	CLR.B	multiplayerRaceDisplayFlag
	RTS

displayRecordHolders:
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
	MOVE.B	#$0E,D0
	MOVE.B	D0,currentMenuItem
	MOVE.B	#$00,menuCursorObjectType
	MOVE.B	#$03,D0
	JSR	renderMenuCursorAndAdvanceMultiSegment
	MOVE.B	#$23,D1
	JSR	renderStatsText
	MOVE.B	bestRaceRecordHolder,D1
	BEQ	lbC0508E2
	MOVE.L	#playerRaceWins,A1
	ADDQ.B	#$01,$00(A1,D1.W)
	JSR	renderPlayerName
	MOVE.B	#$E9,D1
	JSR	renderLeagueText
lbC0508E2:
	MOVE.B	#$05,D1
	MOVE.B	displayRowOffset,D2
	ADDQ.B	#$01,D2
	JSR	setTextPosition
	MOVE.B	#$2F,D1
	JSR	renderStatsText
	MOVE.B	bestLapRecordHolder,D1
	BEQ	lbC050922
	MOVE.L	#playerSecondPlaceFinishes,A1
	ADDQ.B	#$01,$00(A1,D1.W)
	JSR	renderPlayerName
	MOVE.B	#$EF,D1
	JSR	renderLeagueText
lbC050922:
	JMP	sortRaceResults

convertBinaryToBCD:
	ANDI.B	#$0F,CCR
	MOVE.W	D1,-(SP)
	CLR.W	D1
	MOVE.B	D0,D1
	BEQ	lbC050946
	MOVE.B	#$01,D3
	CLR.B	D0
	BRA	lbC050942

lbC050940:
	ABCD	D3,D0
lbC050942:
	DBRA	D1,lbC050940
lbC050946:
	MOVE.W	(SP)+,D1
	RTS

lbC05094A:
	MOVE.L	#transferBuffer,A0
	MOVE.L	#leagueSeasonData,A1
	MOVE.W	#$00BF,D0
	TST.B	writeMode
	BNE	lbC05096C
lbC050964:
	MOVE.B	(A0)+,(A1)+
	DBRA	D0,lbC050964
	RTS

lbC05096C:
	MOVE.B	(A1)+,(A0)+
	DBRA	D0,lbC05096C
	RTS

displayRecordAchievements:
	MOVE.B	displayFlags,D0
	BEQ	lbC050A6A
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.B	#$B8,D1
	MOVE.B	#$04,menuCursorObjectType
	MOVE.B	#$03,D0
	MOVE.B	D0,currentMenuItem
	MOVE.B	displayFlags,D0
	AND.B	#$01,D0
	BEQ	lbC0509E6
	MOVE.B	#$E3,D1
	MOVE.B	#$01,D2
	MOVE.B	#$10,D0
	MOVE.B	D0,currentMenuItem
	MOVE.B	D2,menuCursorObjectType
	JSR	renderMenuString
	MOVE.B	displayFlags,D0
	AND.B	#$C0,D0
	CMP.B	#$C0,D0
	BNE	lbC0509E6
	MOVE.B	#$6F,D1
	JSR	renderMenuString
lbC0509E6:
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
	MOVE.B	#$03,D0
	JSR	renderMenuCursorAndAdvanceMultiSegment
	TST.B	displayFlags
	BPL	lbC050A28
	MOVE.B	#$23,D1
	JSR	renderStatsText
	MOVE.B	#$D6,D1
	JSR	renderMenuString
	JSR	renderSpace
	MOVE.B	#$0F,D1
	JSR	renderLapTime
lbC050A28:
	BTST	#$06,displayFlags
	BEQ	lbC050A6A
	MOVE.B	#$05,D1
	MOVE.B	displayRowOffset,D2
	ADDQ.B	#$01,D2
	JSR	setTextPosition
	MOVE.B	#$2F,D1
	JSR	renderStatsText
	MOVE.B	#$C9,D1
	JSR	renderMenuString
	JSR	renderSpace
	MOVE.B	#$0E,D1
	JMP	renderLapTime

lbC050A6A:
	RTS

updateRaceRecords:
	MOVE.W	D1,-(SP)
	MOVE.B	#$0C,D2
	JSR	compareAndCopyPlayerStats
	BCS	lbC050A88
	MOVE.B	currentPlayerID,D0
	MOVE.B	D0,bestLapRecordHolder
lbC050A88:
	MOVE.B	#$0E,D2
	JSR	compareAndCopyPlayerStats
	BCS	lbC050AB0
	MOVE.B	#$C9,D2
	JSR	copyPlayerNameToMenu
	MOVE.B	displayFlags,D0
	OR.B	#$41,D0
	MOVE.B	D0,displayFlags
lbC050AB0:
	MOVE.B	currentPlayerID,D2
	JSR	compareAndCopyPlayerStats
	ADD.B	#$0C,D2
	JSR	addLapTimesBCD
	MOVE.B	player1LapCounter,D0
	CMP.B	#$04,D0
	BNE	lbC050B1A
	MOVE.B	D2,D0
	MOVE.B	D0,D1
	MOVE.B	#$0D,D2
	JSR	compareAndCopyPlayerStats
	BCS	lbC050AF2
	MOVE.B	currentPlayerID,D0
	MOVE.B	D0,bestRaceRecordHolder
lbC050AF2:
	MOVE.B	#$0F,D2
	JSR	compareAndCopyPlayerStats
	BCS	lbC050B1A
	MOVE.B	#$D6,D2
	JSR	copyPlayerNameToMenu
	MOVE.B	displayFlags,D0
	OR.B	#$81,D0
	MOVE.B	D0,displayFlags
lbC050B1A:
	MOVE.W	(SP)+,D1
	RTS

copyPlayerNameToMenu:
	MOVE.W	D1,-(SP)
	MOVE.B	currentPlayerID,D0
	ASL.B	#$04,D0
	MOVE.B	D0,D1
	MOVE.B	#$0C,D0
	MOVE.B	D0,tempByte4
lbC050B34:
	MOVE.L	#playerNames,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#menuTextStrings,A2
	MOVE.B	D0,$00(A2,D2.W)
	ADDQ.B	#$01,D1
	ADDQ.B	#$01,D2
	SUBQ.B	#$01,tempByte4
	BNE	lbC050B34
	MOVE.W	(SP)+,D1
	RTS

transferLapRecords:
	MOVE.B	D0,tempByte4
	MOVE.B	currentTrackID,D1
	MOVE.L	#trackIDLookupTable,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.B	currentPlayerContext,D2
	BEQ	lbC050B7E
	ADD.B	#$08,D0
lbC050B7E:
	ASL.B	#$04,D0
	MOVE.B	D0,D1
	MOVE.B	#$00,D2
	TST.B	tempByte4
	BMI	lbC050C02
lbC050B90:
	MOVE.L	#lbL050548,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.L	#lapRecordTable,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.L	#trackRecordMessage,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.L	#raceRecordTable,A1
	MOVE.B	D0,$00(A1,D1.W)
	ADDQ.B	#$01,D1
	ADDQ.B	#$01,D2
	CMP.B	#$0C,D2
	BNE	lbC050B90
	MOVE.L	#lapRecordTable,A1
	MOVE.B	lbB00E216,$00(A1,D1.W)
	MOVE.B	lbB00E22E,$01(A1,D1.W)
	MOVE.B	lbB00E246,$02(A1,D1.W)
	MOVE.L	#raceRecordTable,A1
	MOVE.B	lbB00E217,$00(A1,D1.W)
	MOVE.B	lbB00E22F,$01(A1,D1.W)
	MOVE.B	lbB00E247,$02(A1,D1.W)
	tst.l	saveLapRecords						; added
	beq.s	.done
	lea	lapRecordTable,a1
	move.l	saveLapRecords,a2
	jsr	(a2)
.done:	RTS

lbC050C02:
	MOVE.L	#lapRecordTable,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#lbL050548,A2
	MOVE.B	D0,$00(A2,D2.W)
	MOVE.L	#raceRecordTable,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#trackRecordMessage,A2
	MOVE.B	D0,$00(A2,D2.W)
	ADDQ.B	#$01,D1
	ADDQ.B	#$01,D2
	CMP.B	#$0C,D2
	BNE	lbC050C02
	MOVE.L	#lapRecordTable,A1
	MOVE.B	$00(A1,D1.W),lbB00E216
	MOVE.B	$01(A1,D1.W),lbB00E22E
	MOVE.B	$02(A1,D1.W),lbB00E246
	MOVE.L	#raceRecordTable,A1
	MOVE.B	$00(A1,D1.W),lbB00E217
	MOVE.B	$01(A1,D1.W),lbB00E22F
	MOVE.B	$02(A1,D1.W),lbB00E247
	RTS

syncMultiplayerRecords:
	MOVE.B	writeMode,D3
	EOR.B	D3,D0
	BNE	lbC050CE8
	MOVE.B	lbB00D494,D0
	BMI	lbC050CE8
	MOVE.B	leagueSessionMode,D0
	BMI	lbC050CE8
	BEQ	lbC05094A
	CMP.B	#$40,D0
	BEQ	lbC050CA6
	JMP	lbC0511A8

lbC050CA6:
	MOVE.B	writeMode,D0
	BEQ	lbC050CEA
	MOVE.B	#$00,D1
lbC050CB4:
	MOVE.L	#lapRecordTable,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#transferBuffer,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.L	#raceRecordTable,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#remoteRaceRecordBuffer,A1
	MOVE.B	D0,$00(A1,D1.W)
	SUBQ.B	#$01,D1
	BNE	lbC050CB4
	JSR	encodeLeagueData
lbC050CE8:
	RTS

lbC050CEA:
	JSR	decodeLeagueData
	BCS	lbC050CE8
	MOVE.L	#transferBuffer,A0
	MOVE.L	#lapRecordTable,A1
	MOVE.B	#$00,D1
lbC050D04:
	MOVE.B	$0C(A0,D1.W),D0
	CMP.B	$0C(A1,D1.W),D0
	BCS	lbC050D30
	BNE	lbC050D48
	MOVE.B	$0D(A0,D1.W),D0
	CMP.B	$0D(A1,D1.W),D0
	BCS	lbC050D30
	BNE	lbC050D48
	MOVE.B	$0E(A0,D1.W),D0
	CMP.B	$0E(A1,D1.W),D0
	BCC	lbC050D48
lbC050D30:
	MOVE.B	#$10,D2
lbC050D34:
	MOVE.B	$00(A0,D1.W),$00(A1,D1.W)
	ADDQ.B	#$01,D1
	SUBQ.B	#$01,D2
	BNE	lbC050D34
	JMP	lbC050D4C

lbC050D48:
	ADD.B	#$10,D1
lbC050D4C:
	CMP.B	#$00,D1
	BNE	lbC050D04
	MOVE.L	#remoteRaceRecordBuffer,A0
	MOVE.L	#raceRecordTable,A1
lbC050D60:
	MOVE.B	$0C(A0,D1.W),D0
	CMP.B	$0C(A1,D1.W),D0
	BCS	lbC050D8C
	BNE	lbC050DA4
	MOVE.B	$0D(A0,D1.W),D0
	CMP.B	$0D(A1,D1.W),D0
	BCS	lbC050D8C
	BNE	lbC050DA4
	MOVE.B	$0E(A0,D1.W),D0
	CMP.B	$0E(A1,D1.W),D0
	BCC	lbC050DA4
lbC050D8C:
	MOVE.B	#$10,D2
lbC050D90:
	MOVE.B	$00(A0,D1.W),$00(A1,D1.W)
	ADDQ.B	#$01,D1
	SUBQ.B	#$01,D2
	BNE	lbC050D90
	JMP	lbC050DA8

lbC050DA4:
	ADD.B	#$10,D1
lbC050DA8:
	CMP.B	#$00,D1
	BNE	lbC050D60
	JMP	lbC050CE8

checkSpecialCommands:
	MOVE.B	#$00,D2
	MOVE.B	#$03,D1
.checkHALLLoop:
	MOVE.L	#nameInputBuffer,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#commandSkipStandingsScreen,A1
	CMP.B	$00(A1,D1.W),D0
	BNE	.checkHALLDone
	SUBQ.B	#$01,D1
	BPL	.checkHALLLoop
	MOVE.B	#$40,D2
	BNE	.checkMPDone
.checkHALLDone:
	MOVE.B	#$01,D1
.checkMPLoop:
	MOVE.L	#nameInputBuffer,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#commandRestoreDriverNames,A1
	CMP.B	$00(A1,D1.W),D0
	BNE	.checkMPDone
	SUBQ.B	#$01,D1
	BPL	.checkMPLoop
	MOVE.B	#$01,D2
.checkMPDone:
	MOVE.B	D2,leagueSessionMode
	MOVE.B	writeMode,D0
	BEQ	lbC050E32
	MOVE.B	D2,D0
	BEQ	lbC050E38
	CMP.B	#$01,D2
	BNE	lbC050E32
	MOVE.B	additionalPlayerCount,D0
	BEQ	lbC050E42
lbC050E32:
	ANDI.B	#$1E,CCR
	RTS

lbC050E38:
	MOVE.B	additionalPlayerCount,D0
	BEQ	lbC050E32
lbC050E42:
	JSR	setTextYOffset4
	MOVE.B	#$06,D1
	MOVE.B	#$16,D2
	JSR	setTextPosition
	MOVE.B	#$57,D1
	JSR	displayDiskMessage
	JSR	waitForInputPress
	MOVE.B	#$19,D1
lbC050E6A:
	MOVE.B	#$7F,D0
	JSR	renderCharacter
	SUBQ.B	#$01,D1
	BNE	lbC050E6A
	JSR	resetTextYOffset
	ORI.B	#$01,CCR
	RTS

;lbC050E90:						; removed: dead code
;	MOVE.L	D0,D2
;	MOVE.B	lbB00D494,D0
;	BMI.L	lbC050EA6
;	MOVE.B	lbB00D46B,D0
;	BMI.L	lbC050F2E
;lbC050EA6:
;	JSR	displayMenuScreen
;	MOVE.B	#$01,D0
;	MOVE.B	D0,lbB00D416
;	JSR	renderMenuCursorAndAdvance
;	MOVE.B	#$0C,D1
;	JSR	renderPlayerName
;	MOVE.B	lbB00D494,D0
;	BPL.L	lbC050EDA
;	MOVE.B	#$00,D1
;	JSR	displayDiskMessage
;lbC050EDA:
;	MOVE.B	lbB00E331,D2
;	MOVEA.L	#lbB050F36,A2
;	MOVE.B	$00(A2,D2.W),D1
;	JSR	displayDiskMessage
;	MOVE.B	lbB00D494,D0
;	BPL.L	lbC050F1C
;	JSR	renderMenuCursorAndAdvance
;	MOVE.B	lbB00D494,D2
;	ADDQ.B	#$02,D2
;	ANDI.B	#$07,D2
;	MOVEA.L	#lbB050F36,A2
;	MOVE.B	$00(A2,D2.W),D1
;	JSR	displayDiskMessage
;lbC050F1C:
;	JSR	animatePaletteToTarget
;	JSR	waitForFireButtonPress
;	JSR	resetTextYOffset
;lbC050F2E:
;	MOVE.B	lbB00D494,D0
;	RTS

lbC050FEA:
	JSR	renderCharacter
	ADDQ.B	#$01,D1
displayDiskMessage:
	MOVE.L	#diskIOMessages,A1
	MOVE.B	$00(A1,D1.W),D0
	CMP.B	#$FF,D0
	BNE	lbC050FEA
	RTS

linearCongruentialRandom:
	MOVE.W	obfuscationLcgState,D0
	ASL.W	#$02,D0
	ADD.W	obfuscationLcgState,D0
	MOVE.W	D0,obfuscationLcgState
	LSR.W	#$02,D0
	RTS

initializeObfuscationEncode:
	MOVE.B	#$00,D0
	JMP	setEncodeDecodeFlag

initializeObfuscationDecode:
	MOVE.B	#$80,D0
setEncodeDecodeFlag:
	MOVE.B	D0,encodeDecodeFlag
	MOVE.L	#transferBuffer,obfuscationBufferPointer
	MOVE.W	#$683B,obfuscationLcgState
	MOVE.B	#$00,D1
lbC05104C:
	JSR	linearCongruentialRandom
	MOVE.L	#multiplayerObfuscationTable,A1
	MOVE.B	D0,$00(A1,D1.W)
	ADDQ.B	#$01,D1
	BNE	lbC05104C
	MOVE.B	#$0F,D2
	TST.B	encodeDecodeFlag
	BMI	lbC051086
	MOVE.B	obfuscationCipherIndex,D0
	MOVE.L	obfuscationBufferPointer,A0
	MOVE.B	D0,$00(A0,D2.W)
	JMP	lbC051096

lbC051086:
	MOVE.L	obfuscationBufferPointer,A0
	MOVE.B	$00(A0,D2.W),D0
	MOVE.B	D0,obfuscationCipherIndex
lbC051096:
	MOVE.B	#$00,D2
	MOVE.L	obfuscationBufferPointer,A0
	MOVE.L	#multiplayerObfuscationTable,A1
	TST.B	encodeDecodeFlag
	BMI	lbC0510CC
	MOVE.B	D2,D0
	MOVE.B	#$EF,D2
	MOVE.B	D0,$00(A0,D2.W)
	MOVE.B	#$1F,D2
	MOVE.B	D0,$00(A0,D2.W)
	MOVE.B	#$FF,D2
	MOVE.B	D0,$00(A0,D2.W)
	MOVE.B	D0,D2
lbC0510CC:
	MOVE.B	#$00,D1
lbC0510D0:
	MOVE.B	$00(A0,D2.W),D0
	MOVE.B	D0,tempByte1
	MOVE.B	D1,tempByte0
	MOVE.B	obfuscationCipherIndex,D1
	MOVE.B	$00(A1,D1.W),D0
	ADDQ.B	#$01,obfuscationCipherIndex
	MOVE.B	tempByte0,D1
	ADDQ.B	#$01,D1
	TST.B	encodeDecodeFlag
	BPL	lbC051110
	CMP.B	tempByte1,D1
	BEQ	lbC05111C
	BNE	lbC0510D0
lbC051110:
	CMP.B	tempByte1,D0
	BNE	lbC0510D0
	MOVE.B	D1,D0
lbC05111C:
	MOVE.L	obfuscationBufferPointer,A0
	MOVE.B	D0,$00(A0,D2.W)
	MOVE.B	obfuscationCipherIndex,D0
	ADD.B	$00(A1,D1.W),D0
	MOVE.B	D0,obfuscationCipherIndex
	CMP.B	#$0E,D2
	BNE	lbC051140
	ADDQ.B	#$01,D2
lbC051140:
	ADDQ.B	#$01,D2
	BNE	lbC0510CC
	TST.B	encodeDecodeFlag
	BPL	lbC05117A
	MOVE.B	#$EF,D2
	MOVE.B	$00(A0,D2.W),D0
	MOVE.B	#$FF,D2
	OR.B	$00(A0,D2.W),D0
	MOVE.B	#$1F,D2
	OR.B	$00(A0,D2.W),D0
	BEQ	lbC05117A
	MOVE.B	#$81,D0
	MOVE.B	D0,lbB00D494
	ORI.B	#$01,CCR
lbC05117A:
	RTS

encodeLeagueData:
	JSR	initializeObfuscationEncode
	ADD.L	#$00000100,obfuscationBufferPointer
	JMP	lbC051096

decodeLeagueData:
	JSR	initializeObfuscationDecode
	ADD.L	#$00000100,obfuscationBufferPointer
	JMP	lbC051096

lbC0511A8:
	MOVE.B	writeMode,D0
	BEQ	lbC05121C
	MOVE.B	#$7F,D1
lbC0511B6:
	MOVE.L	#opponentDriverNames,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#tempMessageBuffer1,A1
	MOVE.B	D0,$00(A1,D1.W)
	CMP.B	#$3C,D1
	BCC	lbC0511E6
	MOVE.L	#playerRaceWins,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#tempMessageBuffer2,A1
	MOVE.B	D0,$00(A1,D1.W)
lbC0511E6:
	CMP.B	#$0C,D1
	BCC	lbC051202
	MOVE.L	#playerHolePositions,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#tempMessageBuffer3,A1
	MOVE.B	D0,$00(A1,D1.W)
lbC051202:
	SUBQ.B	#$01,D1
	BPL	lbC0511B6
	MOVE.B	additionalPlayerCount,D0
	MOVE.B	D0,tempPlayerCountBackup
	JSR	initializeObfuscationEncode
	RTS

lbC05121C:
	JSR	initializeObfuscationDecode
	BCS	lbC051288
	MOVE.B	#$7F,D1
lbC05122A:
	MOVE.L	#tempMessageBuffer1,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#opponentDriverNames,A1
	MOVE.B	D0,$00(A1,D1.W)
	CMP.B	#$3C,D1
	BCC	lbC05125A
	MOVE.L	#tempMessageBuffer2,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#playerRaceWins,A1
	MOVE.B	D0,$00(A1,D1.W)
lbC05125A:
	CMP.B	#$0C,D1
	BCC	lbC051276
	MOVE.L	#tempMessageBuffer3,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#playerHolePositions,A1
	MOVE.B	D0,$00(A1,D1.W)
lbC051276:
	SUBQ.B	#$01,D1
	BPL	lbC05122A
	MOVE.B	tempPlayerCountBackup,D0
	MOVE.B	D0,additionalPlayerCount
lbC051288:
	RTS

displayControlConfigurationScreen:
	MOVE.B	#$50,D1
	JSR	checkKeyPressed
	BNE	lbC0513DA
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	displayFrameBuffer,renderFrameBuffer
lbC0512A8:
	JSR	renderMessagePanel
	MOVE.B	#$64,D2
	MOVE.B	#$04,D0
	JSR	displayGameMessage
	MOVE.B	#$01,lbB0513DD
lbC0512C4:
	MOVE.B	#$28,D2
	JSR	delayWithParam
	MOVE.B	#$04,D1
lbC0512D2:
	JSR	renderMessagePanel
	MOVE.B	D1,lbB0513DC
	MOVE.L	#messageTypeTable,A1
	MOVE.B	$00(A1,D1.W),D2
	MOVE.B	#$04,D0
	JSR	displayGameMessage
lbC0512F2:
	MOVE.B	#$67,D1
lbC0512F6:
	MOVE.B	D1,tempByte1
	JSR	checkKeyPressed
	BNE	lbC051386
	MOVE.B	tempByte1,D0
	MOVE.B	lbB0513DC,D1
	MOVE.L	#lbB0513DE,A1
	MOVE.B	$00(A1,D1.W),D2
	MOVE.L	#controlKeys,A2
	TST.B	lbB0513DD
	BNE	lbC051358
	CMP.B	$00(A2,D2.W),D0
	BEQ	lbC05135C
	JSR	renderMessagePanel
	MOVE.B	#$D4,D2
	MOVE.B	#$04,D0
	JSR	displayGameMessage
	MOVE.B	#$28,D2
	JSR	delayWithParam
	JMP	lbC0512A8

lbC051358:
	MOVE.B	D0,$00(A2,D2.W)
lbC05135C:
	MOVE.B	#$00,D0				; chime
	JSR	playSample
lbC051366:
	MOVE.B	tempByte1,D1
	JSR	checkKeyPressed
	BEQ	lbC051366
	MOVE.B	#$03,D2
	JSR	delayWithParam
	JMP	lbC051396

lbC051386:
	MOVE.B	tempByte1,D1
	SUBQ.B	#$01,D1
	BNE	lbC0512F6
	BRA	lbC0512F2

lbC051396:
	MOVE.B	lbB0513DC,D1
	SUBQ.B	#$01,D1
	BPL	lbC0512D2
	JSR	renderMessagePanel
	SUBQ.B	#$01,lbB0513DD
	BMI	lbC0513C6
	MOVE.B	#$C4,D2
	MOVE.B	#$04,D0
	JSR	displayGameMessage
	JMP	lbC0512C4

lbC0513C6:
	MOVE.B	#$4C,D2
	MOVE.B	#$02,D0
	JSR	displayGameMessage
	MOVE.L	(SP)+,renderFrameBuffer
lbC0513DA:
	RTS

renderMessagePanel:
	MOVE.B	#$33,D0
	JMP	renderMaskedGraphicsObject

propagateControlKeys:
	MOVE.B	D0,tempByte4
	MOVE.B	additionalPlayerCount,D0
	BEQ	lbC05142C
	MOVE.B	currentPlayerID,D0
	JSR	calculatePlayerDataOffset
	MOVE.L	#controlKeys,A1
	TST.B	tempByte4
	BPL	lbC05142E
lbC05141E:
	MOVE.B	$00(A2,D2.W),$00(A1,D1.W)
	SUBQ.B	#$01,D2
	SUBQ.B	#$01,D1
	BPL	lbC05141E
lbC05142C:
	RTS

lbC05142E:
	JSR	copyBytesReverse
	JMP	lbC049CE8

selectDivisionAndTrack:
	MOVE.B	#$80,D0
	MOVE.B	D0,textRenderingFlag
	BCLR	#$00,divisionSelectedFlag
	BNE	lbC05149A
	MOVE.B	#$03,D2
	MOVE.B	currentDivision,D0
	EOR.B	#$03,D0
	MOVE.B	#$18,D1
	JSR	displayMenu
	EOR.B	#$03,D0
	MOVE.B	D0,selectedDivision
lbC05149A:
	MOVE.B	#$40,textRenderingFlag
	MOVE.B	#$02,D2
	MOVE.B	selectedTrackInDivision,D0
	AND.B	#$01,D0
	MOVE.B	#$1C,D1
	JSR	displayMenu
	MOVE.B	#$00,D2
	MOVE.B	D2,textRenderingFlag
	RTS

displayTrackRecordsScreen:
	MOVE.B	#$42,displayUpdateFlag
	MOVE.W	imageStandingsBackgroundPalette,D0
	JSR	fadeToColor
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	displayFrameBuffer,renderFrameBuffer
	MOVE.B	#$7F,D1
	MOVE.B	#$7F,D2
	MOVE.B	currentPlayerContext,D0
	BEQ	lbC051500
	MOVE.B	#$FF,D2
lbC051500:
	MOVE.L	#lapRecordTable,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.L	#raceRecordTable,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.L	#raceRecordDisplayBuffer,A1
	MOVE.B	D0,$00(A1,D1.W)
	SUBQ.B	#$01,D2
	SUBQ.B	#$01,D1
	BPL	lbC051500
	MOVE.L	#imageStandingsBackgroundPalette,A1
	JSR	copyPalette
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	MOVE.B	#$80,textTransparencyMode
	MOVE.L	#imageStandingsBackground,A0
	MOVE.L	displayFrameBuffer,A1
	JSR	decompressRLEImage
	MOVE.B	#$02,textHorizontalOffset
	MOVE.B	#$3B,D1
	MOVE.B	currentPlayerContext,D0
	BEQ	lbC05158A
	MOVE.B	#$07,D0
	JSR	setBackgroundColor
	MOVE.B	#$4B,D1
	JSR	renderStatsText
lbC05158A:
	MOVE.B	#$08,D0
	JSR	setBackgroundColor
	MOVE.B	#$5B,D1
	JSR	renderStatsText
	MOVE.B	#$07,currentMenuItem
lbC0515A6:
	MOVE.B	#$07,D0
	SUB.B	currentMenuItem,D0
	ASL.B	#$01,D0
	ADD.B	#$09,D0
	MOVE.B	D0,D2
	MOVE.B	#$00,D1
	JSR	setTextPosition
	MOVE.B	currentMenuItem,D0
	ASL.B	#$01,D0
	MOVE.B	D0,D1
	MOVE.B	#$01,D0
	MOVE.B	D0,textHorizontalOffset
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	MOVE.L	#trackAbbreviationCodes1,A1
	MOVE.B	$00(A1,D1.W),D0
	JSR	renderCharacter
	MOVE.L	#trackAbbreviationCodes2,A1
	MOVE.B	$00(A1,D1.W),D0
	JSR	renderCharacter
	JSR	renderSpace
	MOVE.B	#$04,textHorizontalOffset
	MOVE.B	#$00,segmentRepeatCounter
lbC051616:
	MOVE.B	currentMenuItem,D0
	ASL.B	#$04,D0
	OR.B	segmentRepeatCounter,D0
	MOVE.B	D0,D1
	MOVE.B	#$07,D0
	JSR	setBackgroundColor
	MOVE.B	#$0C,D2
lbC051634:
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	$00(A1,D1.W),D0
	JSR	renderCharacter
	ADDQ.B	#$01,D1
	SUBQ.B	#$01,D2
	BNE	lbC051634
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	JSR	renderSpace
	SUBQ.B	#$01,textHorizontalOffset
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	$00(A1,D1.W),playerStatsArray
	MOVE.B	$01(A1,D1.W),lapTimeSeconds
	MOVE.B	$02(A1,D1.W),lapTimeSubseconds
	MOVE.B	#$00,D1
	JSR	renderLapTime
	MOVE.B	segmentRepeatCounter,D0
	EOR.B	#$80,D0
	MOVE.B	D0,segmentRepeatCounter
	BPL	lbC0516B4
	JSR	renderTwoSpaces
	MOVE.B	#$02,D0
	MOVE.B	D0,textHorizontalOffset
	JMP	lbC051616

lbC0516B4:
	SUBQ.B	#$01,currentMenuItem
	BPL	lbC0515A6
	MOVE.B	#$00,D0
	MOVE.B	D0,textHorizontalOffset
	JSR	animatePaletteToTarget
	JSR	waitForFireButtonPress
	MOVE.L	(SP)+,renderFrameBuffer
	JMP	displayMenuScreen

getSegmentAtGridCoordinate:
	MOVE.B	trackViewOffsetY,D0
	ADD.B	gridLookupY,D0
	CMP.B	#$10,D0
	BCC	lbC051750
	ASL.B	#$04,D0
	MOVE.B	D0,tempByte4
	MOVE.B	trackViewOffsetX,D0
	ADD.B	gridLookupX,D0
	CMP.B	#$10,D0
	BCC	lbC051750
	AND.B	#$0F,D0
	OR.B	tempByte4,D0
	MOVE.B	D0,D1
	MOVE.L	#trackSegmentGrid,A1
	MOVE.B	$00(A1,D1.W),D0
	ANDI.B	#$1E,CCR
	RTS

lbC051750:
	ORI.B	#$01,CCR
	RTS

loadTrackSegmentConfiguration:
	MOVE.L	#segmentGeometryIndices,A1
	MOVE.B	$00(A1,D1.W),D2
	MOVE.B	D2,geometryFormatFlag
	ASL.B	#$01,D2
	MOVE.L	#segmentGeometryOffsetTable,A2
	MOVE.W	$00(A2,D2.W),primaryGeometryOffset
	MOVE.L	#segmentAlternateGeometryIndices,A1
	MOVE.B	$00(A1,D1.W),D2
	ASL.B	#$01,D2
	MOVE.B	#$00,D0
	ROXL.B	#$01,D0
	ASL.B	#$01,D0
	MOVE.B	D0,segmentAlternateFlag
	MOVE.L	#segmentGeometryOffsetTable,A2
	MOVE.W	$00(A2,D2.W),D0
	MOVE.W	D0,alternateGeometryOffset
	ASL.B	#$01,D1
	MOVE.L	#segmentInterpolationPoint1,A1
	MOVE.W	$00(A1,D1.W),segmentBezierOffset1
	MOVE.L	#segmentInterpolationPoint2,A1
	MOVE.W	$00(A1,D1.W),segmentBezierOffset2
	LSR.B	#$01,D1
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$C0,D0
	MOVE.B	D0,segmentSlopeFlags
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$10,D0
	ASL.B	#$03,D0
	MOVE.B	D0,reverseDirectionFlag
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$0F,D0
	MOVE.B	D0,trackGeometryTypeIndex
	ASL.B	#$01,D0
	MOVE.B	D0,D2
	MOVE.L	#trackGeometryDatabase,A2
	MOVE.W	$00(A2,D2.W),geometryDatabaseOffset
	MOVE.W	geometryDatabaseOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A0
	MOVE.B	$0001(A0),segmentSteeringFlags
	MOVE.B	$0000(A0),D2
	MOVE.B	$00(A0,D2.W),D0
	ADDQ.B	#$01,D2
	MOVE.B	D0,D3
	MOVE.B	D0,trackSegmentLimit
	ASL.B	#$01,D3
	MOVE.B	D3,trackSegmentLimitDoubled
	SUBQ.B	#$02,D0
	MOVE.B	D0,maxSegmentIndex
	ASL.B	#$01,D0
	MOVE.B	D0,maxSegmentIndexDoubled
	MOVE.B	trackSegmentLimit,D0
	LSR.B	#$01,D0
	SUBQ.B	#$01,D0
	MOVE.B	D0,trackModeParameter
	MOVE.B	$00(A0,D2.W),D0
	ADDQ.B	#$01,D2
	LSR.B	#$01,D0
	ROXR.B	#$01,D0
	AND.B	#$80,D0
	MOVE.B	D0,trackDirectionInversionFlag
	MOVE.B	$00(A0,D2.W),segmentOrientationPrimary
	ADDQ.B	#$01,D2
	MOVE.B	$00(A0,D2.W),segmentOrientationAlternate
	ADDQ.B	#$03,D2
	MOVE.B	$00(A0,D2.W),segmentBaseSteeringOffset
	ADDQ.B	#$01,D2
	RTS

transformSegmentToViewSpace:
	MOVE.L	#trackSegmentCoordinates,A1
	AND.W	#$00FF,D0
	MOVE.B	$00(A1,D0.W),D3
	LSR.B	#$04,D3
	MOVE.B	$00(A1,D0.W),D0
	AND.B	#$0F,D0
	SUB.B	trackViewOffsetX,D0
	SUB.B	trackViewOffsetY,D3
	TST.B	cameraRotationFlags
	BMI	lbC0518D8
	BTST	#$06,cameraRotationFlags
	BEQ	lbC0518F2
	EXG	D0,D3
	NEG.B	D0
	JMP	lbC0518F2

lbC0518D8:
	BTST	#$06,cameraRotationFlags
	BNE	lbC0518EE
	NEG.B	D0
	NEG.B	D3
	JMP	lbC0518F2

lbC0518EE:
	EXG	D0,D3
	NEG.B	D3
lbC0518F2:
	MOVE.B	D0,transformedGridX
	MOVE.B	D3,transformedGridY
	ASL.B	#$03,D0
	ADD.B	cameraGridOffsetXHigh,D0
	MOVE.B	D0,baseCoordinateX
	ASL.B	#$03,D3
	ADD.B	cameraGridOffsetZHigh,D3
	MOVE.B	D3,baseCoordinateY
	RTS

findSegmentBySubGridAdjustment:
	MOVE.B	D0,tempByte4
	MOVE.B	D2,tempByte3
	CMP.B	tempByte4,D2
	BCC	lbC051966
	ADD.B	tempByte3,D0
	BCC	lbC051952
	MOVE.B	D1,D0
	AND.B	#$0F,D0
	CMP.B	#$0F,D0
	BEQ	lbC0519A0
	ADDQ.B	#$01,D1
	JMP	lbC051994

lbC051952:
	MOVE.B	D1,D0
	AND.B	#$F0,D0
	BEQ	lbC0519A0
	SUB.B	#$10,D1
	JMP	lbC051994

lbC051966:
	ADD.B	tempByte3,D0
	BCC	lbC051988
	MOVE.B	D1,D0
	AND.B	#$F0,D0
	CMP.B	#$F0,D0
	BEQ	lbC0519A0
	ADD.B	#$10,D1
	JMP	lbC051994

lbC051988:
	MOVE.B	D1,D0
	AND.B	#$0F,D0
	BEQ	lbC0519A0
	SUBQ.B	#$01,D1
lbC051994:
	MOVE.L	#trackSegmentGrid,A1
	MOVE.B	$00(A1,D1.W),D0
	RTS

lbC0519A0:
	MOVE.B	#$FF,D0
	RTS

convertCameraToGridSpace:
	LSR.W	#$08,D0
	MOVE.B	D0,tempByte2
	MOVE.L	#cameraWorldX,A0
	MOVE.L	#subGridOffsetX,A1
	MOVE.L	#trackViewOffsetX,A2
	TST.W	$0002(A0)
	BNE	lbC0519CC
	ADDQ.W	#$01,$0002(A0)
lbC0519CC:
	MOVE.L	(A0),D0
	ASL.L	#$01,D0
	SWAP	D0
	MOVE.B	D0,(A1)
	LSR.W	#$08,D0
	MOVE.B	D0,(A2)
	TST.W	$000A(A0)
	BNE	lbC0519E4
	ADDQ.W	#$01,$000A(A0)
lbC0519E4:
	MOVE.L	$0008(A0),D0
	ASL.L	#$01,D0
	SWAP	D0
	MOVE.B	D0,$0002(A1)
	LSR.W	#$08,D0
	MOVE.B	D0,$0002(A2)
	TST.B	tempByte2
	BMI	lbC051A40
	BTST	#$06,tempByte2
	BNE	lbC051A22
	MOVE.L	cameraWorldX,rotatedCameraX
	MOVE.L	cameraWorldZ,rotatedCameraZ
	RTS

lbC051A22:
	MOVE.L	cameraWorldX,rotatedCameraZ
	MOVE.L	#$08000000,D0
	SUB.L	cameraWorldZ,D0
	MOVE.L	D0,rotatedCameraX
	RTS

lbC051A40:
	BTST	#$06,tempByte2
	BNE	lbC051A72
	MOVE.L	#$08000000,D0
	SUB.L	cameraWorldX,D0
	MOVE.L	D0,rotatedCameraX
	MOVE.L	#$08000000,D0
	SUB.L	cameraWorldZ,D0
	MOVE.L	D0,rotatedCameraZ
	RTS

lbC051A72:
	MOVE.L	#$08000000,D0
	SUB.L	cameraWorldX,D0
	MOVE.L	D0,rotatedCameraZ
	MOVE.L	cameraWorldZ,rotatedCameraX
	RTS

calculateCameraTransform:
	MOVE.W	cameraAngleY,D0
	ADD.W	#$2000,D0
	AND.W	#$C000,D0
	MOVE.W	D0,cameraRotationFlags
	JSR	convertCameraToGridSpace
	MOVE.L	cameraWorldY,D0
	LSR.L	#$08,D0
	LSR.L	#$03,D0
	MOVE.W	D0,carHeightPosition
	MOVE.W	#$0780,D3
	MOVE.W	averageWheelVelocity,D0
	CMP.W	#$0500,D0
	BCS	lbC051AD2
	ASL.W	#$01,D0
	MOVE.W	#$0280,D3
lbC051AD2:
	ADD.W	D3,D0
	MOVE.W	cameraAngleX,D3
	BPL	lbC051AE2
	ASR.W	#$01,D3
	SUB.W	D3,D0
lbC051AE2:
	ASR.W	#$04,D0
	ADD.W	carHeightPosition,D0
	MOVE.W	D0,cameraHeightBaseline
	MOVE.L	rotatedCameraX,D0
	LSR.L	#$08,D0
	LSR.L	#$04,D0
	AND.W	#$07FF,D0
	NEG.W	D0
	MOVE.B	D0,cameraGridOffsetXLow
	LSR.W	#$08,D0
	MOVE.B	D0,cameraGridOffsetXHigh
	MOVE.L	rotatedCameraZ,D0
	LSR.L	#$08,D0
	LSR.L	#$04,D0
	AND.W	#$07FF,D0
	NEG.W	D0
	MOVE.B	D0,cameraGridOffsetZLow
	LSR.W	#$08,D0
	MOVE.B	D0,cameraGridOffsetZHigh
	MOVE.W	cameraAngleY,D0
	ADD.W	#$2000,D0
	AND.W	#$3FFE,D0
	SUB.W	#$2000,D0
	MOVE.W	D0,cameraYawPerspectiveOffset
	RTS

checkRoadBoundaries:
	MOVE.B	#$00,offRoadSideFlags
	MOVE.W	lateralRoadPosition,D0
	SUB.W	#$00C0,D0
	TST.B	reverseDirectionFlag
	BPL	lbC051B64
	NEG.W	D0
lbC051B64:
	MOVE.W	D0,offsetFromRoadCenter
	BPL	lbC051B70
	NEG.W	D0
lbC051B70:
	CMP.W	#$00C0,D0
	BLT	lbC051B92
	MOVE.B	#$80,offRoadSideFlags
	TST.W	offsetFromRoadCenter
	BMI	lbC051B92
	MOVE.B	#$02,offRoadSideFlags
lbC051B92:
	CMP.W	#$0100,D0
	BLT	.edgeGrind
	TST.B	offTrackStateFlags
	BMI	.offTrackStateOk
	MOVE.B	#$80,offTrackStateFlags
	MOVE.B	offsetFromRoadCenter,trackSideIndicator
	MOVE.B	#$10*FRAMERATE_MULTIPLIER,restartTimerCountdown			; originally $10
	JSR	initializeDebrisParticlePositions
.offTrackStateOk:
	RTS

.edgeGrind:
	BTST	#$06,offTrackStateFlags
	BNE	.offTrackStateOk
	MOVE.B	#$00,offTrackStateFlags
	MOVE.B	#$00,raceCompletionCheckFlag
	RTS

renderTrackPreviewGrid:
	MOVE.B	#$10,D2
lbC051BE8:
	MOVE.B	#$08,D1
	MOVE.B	#$00,gridSweepDirection
lbC051BF4:
	JSR	renderTrackPreviewSegment
	SUBQ.B	#$01,D1
	BNE	lbC051BF4
	MOVE.B	#$F8,D1
	MOVE.B	#$80,gridSweepDirection
lbC051C0C:
	JSR	renderTrackPreviewSegment
	ADDQ.B	#$01,D1
	BMI	lbC051C0C
	BEQ	lbC051C0C
	SUBQ.B	#$01,D2
	BPL	lbC051BE8
	RTS

renderTrackPreviewSegment:
	MOVE.B	D1,currentTrackCoordinate
	MOVE.B	D2,maxMenuIndex
	TST.B	cameraRotationFlags
	BMI	lbC051C5A
	BTST	#$06,cameraRotationFlags
	BEQ	lbC051C8A
	MOVE.B	maxMenuIndex,D1
	MOVE.B	currentTrackCoordinate,D2
	NEG.B	D2
	JMP	lbC051C8A

lbC051C5A:
	BTST	#$06,cameraRotationFlags
	BNE	lbC051C7C
	MOVE.B	currentTrackCoordinate,D1
	NEG.B	D1
	MOVE.B	maxMenuIndex,D2
	NEG.B	D2
	JMP	lbC051C8A

lbC051C7C:
	MOVE.B	maxMenuIndex,D1
	NEG.B	D1
	MOVE.B	currentTrackCoordinate,D2
lbC051C8A:
	MOVE.B	D1,gridLookupX
	MOVE.B	D2,gridLookupY
	MOVE.W	#$0000,D0
	MOVE.W	D0,visibilityAccumulator
	MOVE.B	D0,segmentDepthCounter
	JSR	getSegmentAtGridCoordinate
	BCS	lbC051DA6
	CMP.B	#$FF,D0
	BEQ	lbC051DA6
	MOVE.B	D0,currentSegmentIndex
	MOVE.B	#$00,segmentDataStartIndex
	MOVE.B	#$80,D0
	MOVE.B	D0,processedSegmentIndices1
	MOVE.B	D0,processedSegmentIndices2
	JSR	transformTrackSegmentCoordinates
	MOVE.B	#$E0,renderingOrderMode
	MOVE.B	#$80,offsetFromRoadCenter
	MOVE.L	#transformedVertexBounds,A0
	MOVE.W	(A0),D0
	CMP.W	$0002(A0),D0
	BGT	lbC051D1A
	MOVE.W	$0010(A0),D0
	CMP.W	$0012(A0),D0
	BGT	lbC051D1A
	MOVE.B	maxSegmentIndexDoubled,D1
	MOVE.W	$00(A0,D1.W),D0
	CMP.W	$02(A0,D1.W),D0
	BLE	lbC051D22
lbC051D1A:
	MOVE.B	#$00,offsetFromRoadCenter
lbC051D22:
	MOVE.B	#$00,segmentRenderingFlag
	MOVE.B	segmentSteeringFlags,D0
	AND.B	#$C0,D0
	BNE	lbC051D4C
	BTST	#$06,trackHeightDifference
	BNE	lbC051D4C
	MOVE.B	#$80,segmentRenderingFlag
lbC051D4C:
	MOVE.B	maxSegmentIndexDoubled,D1
	MOVE.L	#segmentProcessedFlags,A0
	MOVE.B	#$00,(A0)
	MOVE.B	#$00,$00(A0,D1.W)
	MOVE.W	minimumRenderQueueOffset,renderCommandQueueOffset
	MOVE.W	#$0000,D1
	MOVE.B	#$00,segmentProcessedFlag
	MOVE.B	#$00,processedSegmentIndices1
	MOVE.B	#$00,tempByte5
	ADD.W	#$0010,renderCommandQueueOffset
	MOVE.L	#lineDrawingBuffer,lineDrawingBufferPointer
	JSR	drawTrackSegmentWireframe
	JSR	renderTrackNear
lbC051DA6:
	MOVE.B	currentTrackCoordinate,D1
	MOVE.B	maxMenuIndex,D2
	RTS

renderTrackPreview:
	MOVE.W	#$0060,minimumRenderQueueOffset
	MOVE.B	#$80,lbB00D468
	MOVE.B	cameraAngleIndex,D1
	AND.B	#$03,D1
	MOVE.L	#lbL051E52,A1
	MOVE.B	$00(A1,D1.W),cameraWorldX
	MOVE.L	#lbB051E56,A1
	MOVE.B	$00(A1,D1.W),cameraWorldZ
	MOVE.L	#lbL051E5A,A1
	MOVE.B	$00(A1,D1.W),cameraAngleY
	MOVE.B	#$03,cameraWorldY
	MOVE.B	#$F0,lbB00D5DD
	MOVE.B	#$00,lbB00D5C8
	MOVE.W	#$0700,viewportCenterY
	JSR	prepareFrameRendering
	JSR	copyTrackPreviewRegion
	JSR	animatePaletteToTarget
	MOVE.B	#$80,segmentConfigLoadedFlag
	JSR	renderTrackPreviewGrid
	MOVE.B	#$00,segmentConfigLoadedFlag
	MOVE.W	#$0000,minimumRenderQueueOffset
	MOVE.B	#$00,lbB00D468
	RTS

reverseTrackSegmentData:
	MOVE.L	#trackSegmentData,A6
	MOVE.L	#segmentProcessedFlags,A0
	MOVE.B	trackSegmentLimit,D4
	LSR.B	#$01,D4
	MOVE.W	#$0000,D1
	MOVE.B	trackSegmentLimit,D2
	SUBQ.B	#$01,D2
	ASL.B	#$01,D2
lbC051E80:
	MOVE.W	$00(A6,D1.W),D0
	MOVE.W	$00(A6,D2.W),$00(A6,D1.W)
	MOVE.W	D0,$00(A6,D2.W)
	SUBQ.B	#$02,D2
	BTST	#$01,D1
	BNE	lbC051EA6
	MOVE.B	$00(A0,D1.W),D0
	MOVE.B	$00(A0,D2.W),$00(A0,D1.W)
	MOVE.B	D0,$00(A0,D2.W)
lbC051EA6:
	ADDQ.B	#$02,D1
	SUBQ.B	#$01,D4
	BNE	lbC051E80
	RTS

lbC051EB0:
	JSR	retreatToPreviousSegment
initializePlayerAtSegment:
	MOVE.B	D1,currentSegmentIndex
	MOVE.B	D1,playerSegmentIndex
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$0F,D0
	MOVE.B	D0,D2
	MOVE.L	#geometryParameterTable,A2
	MOVE.B	$00(A2,D2.W),D0
	BMI	lbC051EB0
	MOVE.B	trackFeatureCount,D2
	BEQ	lbC051F02
	SUBQ.B	#$01,D2
lbC051EEC:
	MOVE.B	D1,D0
	MOVE.L	#trackFeatureData,A2
	CMP.B	$00(A2,D2.W),D0
	BEQ	lbC051EB0
	SUBQ.B	#$01,D2
	BPL	lbC051EEC
lbC051F02:
	MOVE.L	#rotatedCameraX,A0
lbC051F08:
	MOVE.B	#$00,(A0)+
	CMP.L	#opponentFrontWheelAccel,A0
	BNE	lbC051F08
	MOVE.B	#$F0,raceStartTimer
	JSR	loadTrackSegmentConfiguration
	MOVE.L	#trackSegmentCoordinates,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$0F,D0
	MOVE.B	D0,gridLookupX
	MOVE.B	$00(A1,D1.W),D0
	LSR.B	#$04,D0
	MOVE.B	D0,gridLookupY
	MOVE.W	#$0000,D0
	MOVE.W	D0,lbW00D5DA
	MOVE.W	D0,lbW00D5E2
	MOVE.B	gridLookupX,D0
	AND.W	#$00FF,D0
	ASL.W	#$07,D0
	ADD.W	#$0040,D0
	MOVE.W	D0,cameraWorldX
	MOVE.B	gridLookupY,D0
	AND.W	#$00FF,D0
	ASL.W	#$07,D0
	ADD.W	#$0040,D0
	MOVE.W	D0,cameraWorldZ
	MOVE.B	#$04,cameraWorldY
	MOVE.B	#$00,D1
	MOVE.B	trackGeometryTypeIndex,D0
	CMP.B	#$04,D0
	BEQ	lbC051FA2
	CMP.B	#$0A,D0
	BNE	lbC051FA6
lbC051FA2:
	MOVE.B	#$20,D1
lbC051FA6:
	MOVE.B	segmentSlopeFlags,D0
	MOVE.B	reverseDirectionFlag,D3
	EOR.B	D3,D0
	ADD.B	D1,D0
	MOVE.B	D0,cameraAngleY
	JSR	calculateCameraTransform
	JSR	applyTrackSegmentGeometry
	JSR	checkRoadBoundaries
	JSR	updateGamePhysics
	MOVE.W	#$0000,lbW00D5DE
	MOVE.W	#$0010,cameraWorldY
	MOVE.L	wheelHeightRear,D0
	MOVE.L	D0,D3
	MOVE.B	raceStartComplete,D2
	BEQ	lbC05200E
	ASL.L	#$08,D0
	ASL.L	#$01,D0
	ADD.L	#$00180000,D0
	MOVE.L	D0,cameraWorldY
	MOVE.B	#$E6,raceStartTimer
lbC05200E:
	LSR.L	#$02,D3
	MOVE.W	D3,trackSurfaceHeight
	JSR	applyCameraLateralOffset
	MOVE.B	#$08,D1
	MOVE.L	#wheelHeightFrontLeft,A1
	MOVE.L	#trackSurfaceFrontLeft,A2
lbC05202C:
	MOVE.L	#$00001000,$00(A1,D1.W)
	MOVE.L	#$00001000,$00(A2,D1.W)
	SUBQ.B	#$04,D1
	BPL	lbC05202C
	MOVE.L	#$00000000,previousSuspensionFrontLeft
	MOVE.W	#$0000,previousSuspensionRear
	JSR	calculateCameraTransform
	MOVE.B	#$B0,chainVerticalPosition
	MOVE.B	#$08/FRAMERATE_MULTIPLIER,chainLiftVelocity		; originally $08
	RTS

calculatePlayerDistance:
	MOVE.W	opponentSubSegmentProgress,D0
	SUB.W	trackProgressionByte,D0
	ASR.W	#$03,D0
	MOVE.B	opponentSegmentIndex,D1
	MOVE.B	playerSegmentIndex,D2
	MOVE.L	#segmentWorldPositions,A0
	ASL.B	#$01,D1
	ASL.B	#$01,D2
	MOVE.W	$00(A0,D1.W),D3
	SUB.W	$00(A0,D2.W),D3
	ADD.W	D3,D0
	MOVE.W	D0,D5
	MOVE.W	D0,playerDistanceDifference
	BPL	lbC0520A8
	NEG.W	D0
lbC0520A8:
	MOVE.W	startWorldPosition,D4
	SUB.W	D0,D4
	CMP.W	D0,D4
	BCS	lbC0520BC
	MOVE.W	D0,D4
	EOR.W	#$8000,D5
lbC0520BC:
	MOVE.W	D4,opponentDistance
	EOR.W	#$8000,D5
	LSR.W	#$08,D5
	MOVE.B	D5,opponentAheadFlag
	RTS

checkForTieCondition:
	MOVE.B	player2LapCounter,D0
	SUB.B	player1LapCounter,D0
	BNE	lbC052122
	MOVE.B	playerSegmentIndex,D0
	SUB.B	lapLineSegment,D0
	BCC	lbC0520F6
	ADD.B	numTrackSegments,D0
lbC0520F6:
	MOVE.B	opponentSegmentIndex,D3
	SUB.B	lapLineSegment,D3
	BCC	lbC05210C
	ADD.B	numTrackSegments,D3
lbC05210C:
	SUB.B	D0,D3
	BNE	lbC052122
	MOVE.W	playerDistanceDifference,D0
	BNE	lbC052122
	MOVE.B	networkGameMode,D0
lbC052122:
	RTS

updateBoostFuelDisplay:
	tst.l	infiniteBoost			; added
	bne.s	.boostOk
	MOVE.B	boostFuelLevel,D3
	ANDI.B	#$0F,CCR
	ABCD	D3,D0
	CMP.B	maxBoostFuel,D0
	BCS	.maxOk
	MOVE.B	maxBoostFuel,D0
.maxOk:	MOVE.B	D0,boostFuelLevel
.boostOk:
	MOVE.B	#$1F,D0
	JSR	renderCharacter
	MOVE.B	#$09,D0
	JSR	renderCharacter
	MOVE.B	#$16,D0
	JSR	renderCharacter
	MOVE.B	#$04,textHorizontalOffset
	MOVE.B	#$02,textYOffset
	MOVE.B	boostFuelLevel,D0
	LSR.B	#$04,D0
	JSR	renderDigitAndAdvance
	MOVE.B	boostFuelLevel,D0
	AND.B	#$0F,D0
	JSR	renderDigitAndAdvance
	MOVE.B	#$00,textHorizontalOffset
	MOVE.B	#$00,textYOffset
	RTS

updateTurboBoostSystem:
	MOVE.B	raceActiveFlag,D0
	OR.B	postWreckStateFlag,D0
	BNE	lbC052210
	MOVE.B	accelerationStateFlag,D0
	BMI	lbC0521CC
	MOVE.B	inputStateFlags,D0
	AND.B	#$03,D0
	BEQ	lbC052210
lbC0521CC:
	MOVE.B	boostFuelLevel,D0
	BEQ	lbC052210
	TST.B	frameThrottleFlag
	BMI	lbC052200
	SUBQ.B	#$01,fuelConsumptionTimer
	BPL	lbC052200
	MOVE.B	fuelConsumptionRate,D2
	MOVE.B	D2,fuelConsumptionTimer
	MOVE.B	#$99,D0
	JSR	updateBoostFuelDisplay
lbC052200:
	MOVE.B	#$80,boostActiveFlag
	ASL.W	gasOutputAccumulatorValue
	RTS

lbC052210:
	MOVE.B	#$00,boostActiveFlag
	RTS

renderExistingHole:
	MOVE.B	#$17,D1
	BRA	renderDamageBarSegment

renderNewHole:
	MOVE.B	#$19,D1
	BRA	renderDamageBarSegment

renderUndamagedSegment:
	MOVE.B	#$1B,D1
renderDamageBarSegment:
	MOVE.W	D1,-(SP)
	MOVE.L	#graphicsRenderingParameters+8,A0
	MOVE.B	D2,D0
	ASL.B	#$01,D0
	ADD.B	D2,D0
	ADDQ.B	#$06,D0
	LSR.B	#$01,D0
	BCC	lbC052246
	ADDQ.B	#$01,D1
lbC052246:
	AND.W	#$00FF,D0
	MOVE.W	D1,D3
	ASL.W	#$04,D3
	MOVE.W	D0,$00(A0,D3.W)
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	frameBuffers,renderFrameBuffer
	MOVE.B	D1,D0
	JSR	renderMaskedGraphicsObject
	MOVE.L	#$00007D00,D0
	ADD.L	D0,renderFrameBuffer
	MOVE.B	D1,D0
	JSR	renderMaskedGraphicsObject
	MOVE.L	(SP)+,renderFrameBuffer
	MOVE.W	(SP)+,D1
	RTS

renderAllDamage:
	MOVE.B	#$09,D2
.damageLoop:
	CMP.B	holeRenderingPosition,D2
	BGE	.renderDamage
	JSR	renderUndamagedSegment
	BRA	.next

.renderDamage:
	JSR	renderExistingHole
.next:	SUBQ.B	#$01,D2
	BPL	.damageLoop
	RTS

encodeOrDecodeLeagueData:
	MOVE.B	D0,encodeDecodeFlag
	MOVE.L	#randomSeed1,A0
	MOVE.L	#randomSeedBuffer1,A1
	MOVE.B	#$04,D1
lbC0522C4:
	TST.B	encodeDecodeFlag
	BMI	lbC0522DE
	MOVE.B	(A0)+,$00(A1,D1.W)
	JMP	lbC0522EC

lbC0522D8:
	ANDI.B	#$1E,CCR
	RTS

lbC0522DE:
	MOVE.B	bufferEncodedFlag,D0
	BPL	lbC0522D8
	MOVE.B	$00(A1,D1.W),(A0)+
lbC0522EC:
	SUBQ.B	#$01,D1
	BPL	lbC0522C4
	TST.B	encodeDecodeFlag
	BMI	lbC05231E
	MOVE.B	#$0B,D1
lbC052300:
	MOVE.L	#obfuscationWhitespace,A1
	MOVE.B	$00(A1,D1.W),D0
	EOR.B	#$3B,D0
	MOVE.L	#lbL00E2B6,A1
	MOVE.B	D0,$00(A1,D1.W)
	SUBQ.B	#$01,D1
	BPL	lbC052300
lbC05231E:
	MOVE.B	#$1A,D1
lbC052322:
	TST.B	encodeDecodeFlag
	BPL	lbC05234C
	MOVE.L	#leagueSeasonData,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.B	D0,tempByte1
	MOVE.L	#obfuscatedLeagueBuffer,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.B	D0,tempByte2
lbC05234C:
	MOVE.B	#$00,D2
	MOVE.B	D2,tempByte3
lbC052356:
	ADDQ.B	#$01,tempByte3
	BNE	lbC052366
	ADDQ.B	#$01,D2
	BMI	lbC052482
lbC052366:
	JSR	generateRandomNumber
	MOVE.B	D0,tempByte0
	TST.B	encodeDecodeFlag
	BMI	lbC0523AC
	MOVE.L	#lbL00E2B6,A1
	CMP.B	$00(A1,D1.W),D0
	BNE	lbC052356
	MOVE.B	D2,D0
	MOVE.L	#leagueSeasonData,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.B	tempByte3,D0
	MOVE.L	#obfuscatedLeagueBuffer,A1
	MOVE.B	D0,$00(A1,D1.W)
	JMP	lbC0523D6

lbC0523AC:
	CMP.B	tempByte1,D2
	BNE	lbC052356
	MOVE.B	tempByte3,D0
	CMP.B	tempByte2,D0
	BNE	lbC052356
	MOVE.B	tempByte0,D0
	MOVE.L	#transferBuffer,A1
	MOVE.B	D0,$00(A1,D1.W)
lbC0523D6:
	SUBQ.B	#$01,D1
	BPL	lbC052322
	MOVE.L	#randomSeed1,A0
	MOVE.B	#$04,D1
	MOVE.B	#$09,D2
lbC0523EA:
	MOVE.B	(A0)+,D0
	TST.B	encodeDecodeFlag
	BMI	lbC052404
	MOVE.L	#randomSeedBuffer2,A1
	MOVE.B	D0,$00(A1,D1.W)
	BPL	lbC052412
lbC052404:
	MOVE.L	#randomSeedBuffer2,A1
	CMP.B	$00(A1,D1.W),D0
	BNE	lbC052482
lbC052412:
	SUBQ.B	#$01,D1
	BPL	lbC0523EA
	TST.B	encodeDecodeFlag
	BPL	lbC052472
	MOVE.L	#lbL00E2B6,A3
	MOVE.L	#transferBuffer,A0
	MOVE.B	#$1A,D1
lbC052432:
	TST.B	additionalPlayerCount
	BEQ	lbC052444
	CMP.B	#$18,D1
	BCS	lbC05244A
lbC052444:
	MOVE.B	$00(A0,D1.W),$00(A3,D1.W)
lbC05244A:
	SUBQ.B	#$01,D1
	BPL	lbC052432
	MOVE.B	#$0B,D1
lbC052454:
	MOVE.L	#lbL00E2B6,A1
	MOVE.B	$00(A1,D1.W),D0
	EOR.B	#$3B,D0
	MOVE.L	#obfuscationWhitespace,A1
	MOVE.B	D0,$00(A1,D1.W)
	SUBQ.B	#$01,D1
	BPL	lbC052454
lbC052472:
	MOVE.B	#$80,D0
	MOVE.B	D0,bufferEncodedFlag
	ANDI.B	#$1E,CCR
	RTS

lbC052482:
	MOVE.B	#$3B,randomSeed2Low
	MOVE.B	encodeDecodeFlag,D0
	BPL	encodeOrDecodeLeagueData
	ORI.B	#$01,CCR
	RTS

	MOVE.B	#$03,framesToWaitWhenFading
lbC0524A2:
	TST.B	framesToWaitWhenFading
	BNE	lbC0524A2
	RTS

readControllerInput:
	JSR	generateRandomNumber
	MOVE.B	#$10,D7
	MOVE.B	#$00,D6
	MOVE.L	#controlKeys,A4
	MOVE.B	#$04,D2
lbC0524C6:
	MOVE.B	$00(A4,D2.W),D1
	JSR	checkKeyPressed
	BNE	lbC0524D6
	OR.B	D7,D6
lbC0524D6:
	LSR.B	#$01,D7
	SUBQ.B	#$01,D2
	BPL	lbC0524C6
	MOVE.B	D6,D0
	BTST	#$04,D6
	BEQ	lbC0524EC
	BSET	#$00,D0
lbC0524EC:
	BTST	#$01,D6
	BEQ	lbC0524F8
	BSET	#$04,D0
lbC0524F8:
	BTST	#$00,D6
	BEQ	lbC052508
	BSET	#$01,D0
	BCLR	#$00,D0
lbC052508:
	TST.B	D0
	BNE	lbC05254C
	ADDQ.B	#$01,obfuscationCipherIndex
	JSR	readJoystickState
	MOVE.B	joystickState,D0
	EOR.B	#$FF,D0
	BNE	lbC05254C
	TST.B	displayUpdateFlag
	BMI	lbC05254C
	MOVE.B	#$44,D1
	JSR	checkKeyPressed
	BNE	lbC052548
	MOVE.B	#$10,D0
	BRA	lbC05254C

lbC052548:
	MOVE.B	#$00,D0
lbC05254C:
	AND.B	#$1F,D0
	TST.B	networkGameMode
	BEQ	lbC05257E
	MOVE.B	D0,inputStateFlags
	MOVE.B	#$45,D1
	JSR	checkKeyPressed
	MOVE.W	SR,-(SP)
	MOVE.B	inputStateFlags,D0
	MOVE.W	(SP)+,SR
	BEQ	lbC05257E
	JSR	readInputWithNetworkSync
lbC05257E:
	MOVE.B	D0,inputStateFlags
	RTS

handleGroundCollision:
	MOVE.B	#$06,grindSampleID	; ground grind
	MOVE.B	carSpeedMagnitude,D0
	CMP.B	#$10,D0
	BLT	lbC0525AC
	MOVE.B	#$10,D0
lbC0525AC:
	MOVE.B	D0,collisionImpactLevel
	MOVE.B	#$0F,D1
	TST.B	networkGameMode
	BEQ	lbC0525C4
	MOVE.B	#$03,D1
lbC0525C4:
	JSR	generateRandomNumber
	AND.W	#$001C,D0
	ADD.W	#$01C2,D0
	MOVE.W	D0,sampleGroundCollisionPeriod
	BRA	setParticleCountAndPlayGrindSound

noEdgeCollision:
	tst.b	offTrackStateFlags	; added
	bmi.s	.cooldownOk
	clr.b	grindSoundCooldownTimer
.cooldownOk:
	RTS

initializeDebrisParticlePositions:
	MOVE.W	#$003E,D1
	MOVE.W	#$00D4,D0
	MOVE.L	#debrisParticleYPositions,A1
.loop:	MOVE.W	D0,$00(A1,D1.W)			; fixed shorter loop
	SUBQ.B	#$02,D1
	BPL	.loop
	RTS

handleEdgeCollision:
	MOVE.B	#$01,grindSampleID		; egde grind
	MOVE.B	wheelBouncePhaseAccumulator,D0
	BNE	lbC052614
	MOVE.B	postWreckStateFlag,D0
	BEQ	noEdgeCollision
lbC052614:
	TST.B	offTrackStateFlags
	BMI	noEdgeCollision
	MOVE.B	carSpeedMagnitude,D0
	CMP.B	#$01,D0
	BLT	noEdgeCollision
	CMP.B	#$32,D0
	BLT	lbC052638
	MOVE.B	#$32,D0
lbC052638:
	MOVE.B	D0,collisionImpactLevel
	MOVE.B	#$1F,D1
	JSR	generateRandomNumber
	AND.B	#$07,D0
	MOVE.B	D0,D2
	MOVE.B	collisionImpactLevel,D0
	LSR.B	#$01,D0
;	BRA	lbC052682

;	CMP.B	#$08,D0			; removed: dead code
;	BGE	lbC05266A
;	MOVE.B	#$08,D0
;	BNE	lbC052682
;lbC05266A:
;	CMP.B	#$06,D2
;	BLT	lbC052682
;	MOVE.B	#$0D,D0
;	CMP.B	#$07,D2
;	BNE	lbC052682
;	MOVE.B	#$03,D0
;lbC052682:
	CMP.B	#$1F,D0
	BCS	lbC05268E
	MOVE.B	#$1F,D0
lbC05268E:
	EOR.B	#$1F,D0
	AND.W	#$00FF,D0
	ASL.W	#$02,D0
	ADD.W	#$00AA,D0
	MOVE.W	D0,sampleGrindPeriod
setParticleCountAndPlayGrindSound:
	ASL.B	#$01,D1
	MOVE.B	D1,opponentTargetLateralPosition
	MOVE.B	wheelMovementActive,D0
	BEQ	initializeDebrisParticlePositions
	tst.b	grindSoundCooldownTimer		; added
	bne.s	.soundDone
	MOVE.B	grindSampleID,D0
	JSR	playSample
.soundDone:
	add.b	#1,grindSoundCooldownTimer
	cmp.b	#FRAMERATE_MULTIPLIER,grindSoundCooldownTimer
	ble.s	.cooldownDone
	clr.b	grindSoundCooldownTimer
.cooldownDone:
	MOVE.L	#debrisParticleXPositions,A4
	MOVE.L	#debrisParticleXVelocities,A5
	MOVE.B	opponentTargetLateralPosition,D1
.updateParticlesLoop:
	JSR	validateAndRenderParticle
	BNE	.particleUpdated
	ADDQ.W	#$01,$40(A5,D1.W)	; originally #$02
	MOVE.W	$40(A5,D1.W),D0
	ADD.W	D0,$40(A4,D1.W)
	MOVE.W	$00(A5,D1.W),D0
	ADD.W	D0,$00(A4,D1.W)
.particleUpdated:
	SUBQ.B	#$02,D1
	BPL	.updateParticlesLoop
	MOVE.B	opponentTargetLateralPosition,D1
.respawnOffscreenParticlesLoop:
	MOVE.W	$40(A4,D1.W),D0
	CMP.W	#$0080,D0
	BCS	.particleOk
	JSR	generateRandomNumber
	AND.W	#$0007,D0
	MOVE.W	D0,D3
	CLR.W	D0
	MOVE.B	collisionImpactLevel,D0
	LSR.W	#$02,D0			; originally #$01
	TST.B	offTrackStateFlags
	BMI	.yVelocityOk
	LSR.W	#$01,D0
.yVelocityOk:
	ADD.W	D3,D0
	NOT.W	D0
	MOVE.W	D0,$40(A5,D1.W)
	TST.B	offTrackStateFlags
	BPL	.edgeCollision
	JSR	initializeDustCloudParticle
	JMP	.coordinatesOk

.edgeCollision:
	JSR	generateRandomNumber
	AND.W	#$007F,D0
	ADD.W	#$0040,D0
	MOVE.W	D0,$00(A4,D1.W)
	MOVE.W	D0,D5
	JSR	generateRandomNumber
	OR.W	#$FFF8,D0
	ADD.W	#$007F,D0
	MOVE.W	D0,$40(A4,D1.W)
.coordinatesOk:
	MOVE.W	D5,D0
	SUB.W	#$0080,D0
	ASR.W	#$04,D0			; originally #$03
	MOVE.W	D0,$00(A5,D1.W)
	JSR	validateAndRenderParticle
.particleOk:
	SUBQ.B	#$02,D1
	BPL	.respawnOffscreenParticlesLoop
	RTS

validateAndRenderParticle:
	MOVE.B	D1,tempByte5
	MOVE.W	$40(A4,D1.W),D5
	CMP.W	#$0080,D5
	BCC	.resetY
	MOVE.W	$00(A4,D1.W),D0
	CMP.W	#$0100,D0
	BCC	.resetY
	CMP.W	#$0001,D5
	BCC	.coordinateOk
.resetY:
	MOVE.W	#$00D2,$40(A4,D1.W)
	RTS

.coordinateOk:
	TST.B	offTrackStateFlags
	BPL	.render
	JSR	renderDustCloud
	JMP	.done

.render:
	MOVE.W	D0,D4
	CMP.W	#$00FE,D0
	BCC	.resetY
	MOVE.L	viewportTopAddress,A0
	EXT.L	D0
	EXT.L	D5
	LSR.L	#$03,D0
	AND.B	#$FE,D0
	ADD.L	D0,A0
	MOVE.L	D5,D0
	ASL.L	#$02,D0
	ADD.L	D5,D0
	ASL.L	#$03,D0
	ADD.L	D0,A0
	MOVE.B	#$03,D0
	JSR	setPixelColor
	JSR	plotPixel
	ADDQ.W	#$01,D4
	JSR	plotPixel
	SUB.L	#$00000028,A0
	SUBQ.W	#$01,D4
	JSR	plotPixel
	ADDQ.W	#$01,D4
	MOVE.B	#$0F,D0
	JSR	setPixelColor
	JSR	plotPixel
.done:
	MOVE.B	tempByte5,D1
	MOVE.B	#$00,D0
	RTS

initializeDustCloudParticle:
	JSR	generateRandomNumber
	AND.W	#$00FF,D0
	MOVE.W	D0,$00(A4,D1.W)
	MOVE.W	D0,D5
	JSR	generateRandomNumber
	AND.W	#$0007,D0
	ADD.W	#$0076,D0
	MOVE.W	D0,$40(A4,D1.W)
	RTS

renderDustCloud:
	MOVE.B	D1,D2
	LSR.B	#$01,D2
	ADD.B	frameCounter,D2
	AND.W	#$000F,D2
	MOVE.L	#dustCloudAnimSequence,A0
	MOVE.B	$00(A0,D2.W),D2
	ASL.B	#$01,D2
	MOVE.W	$00(A4,D1.W),D4
	MOVE.L	#dustCloudOffsetTable,A0
	SUB.W	$00(A0,D2.W),D4
	ADD.W	#$0020,D4
	MOVE.W	$40(A4,D1.W),D5
	ADD.W	#$0010,D5
	MOVE.B	D2,D0
	LSR.B	#$01,D0
	ADD.B	#$1D,D0
	JMP	renderGraphicsObjectAtPosition

updateWheelSpeed:
	MOVE.W	carLocalVelocityZ,D0
	BPL	.velocityPositive
	NEG.W	D0
.velocityPositive:
	MOVE.W	D0,carSpeedMagnitude
	MOVE.B	wheelMovementActive,D1
	BNE	.wheelsMoving
	MOVE.W	wheelSpeed,D0
	LSR.W	#$05,D0			; originally $02
	SUB.W	D0,wheelSpeed
	RTS

.wheelsMoving:
	CMP.W	#$0800,D0
	BGE	.highSpeed
	ASL.W	#$03,D0
	MOVE.W	D0,wheelSpeed
	RTS

.highSpeed:
	ASL.W	#$01,D0
	ADD.W	#$3000,D0
	BCC	.wheelSpeedOk
	MOVE.W	#$FF00,D0
.wheelSpeedOk:
	MOVE.W	D0,wheelSpeed
	RTS

calculateSteeringResponse:
	MOVE.B	playerSegmentIndex,D1
	MOVE.B	D1,currentSegmentIndex
	JSR	loadTrackSegmentConfiguration
	MOVE.W	segmentTargetAngle,D4
	SUB.W	cameraAngleY,D4
	MOVE.W	reverseDirectionFlag,D3
	EOR.W	D3,D4
	MOVE.B	#$00,D2
	TST.B	segmentSteeringFlags
	BPL	lbC052956
	ADDQ.B	#$02,D2
	MOVE.W	trackDirectionInversionFlag,D0
	EOR.W	D3,D0
	BPL	lbC052956
	ADDQ.B	#$02,D2
lbC052956:
	MOVE.L	#steeringOffsetTable,A0
	ADD.W	$00(A0,D2.W),D4
	MOVE.W	D4,D0
	BPL	lbC052968
	NEG.W	D0
lbC052968:
	MOVE.W	D0,segmentProgressDistance
	MOVE.W	D4,tempWord1
	CMP.W	#$0800,D0
	BCS	lbC052984
	MOVE.W	#$7FFF,D0
	BNE	lbC052986
lbC052984:
	ASL.W	#$04,D0
lbC052986:
	MOVE.W	D0,steeringScaleFactor
	MOVE.B	trackModeParameter,D0
	SUB.B	trackProgressionByte,D0
	CMP.B	#$02,D0
	BCC	lbC0529AC
	JSR	advanceToNextSegment
	JSR	loadTrackSegmentConfiguration
lbC0529AC:
	MOVE.B	trackDirectionInversionFlag,D0
	MOVE.B	reverseDirectionFlag,D3
	EOR.B	D3,D0
	MOVE.B	D0,trackDirectionMultiplier
	MOVE.B	steeringInputDirection,D0
	BEQ	lbC052A3C
	MOVE.B	tempWord1,D3
	EOR.B	D3,D0
	MOVE.B	D0,tempByte4
	MOVE.B	segmentSteeringFlags,D0
	BPL	lbC052A20
	MOVE.B	steeringInputDirection,D0
	MOVE.B	trackDirectionMultiplier,D3
	EOR.B	D3,D0
	BMI	lbC052A04
	MOVE.B	segmentBaseSteeringOffset,D0
	ADD.B	#$2D,D0
	JMP	lbC052A26

lbC052A04:
	MOVE.B	trackDirectionMultiplier,D0
	MOVE.B	D0,steeringInputDirection
	MOVE.B	segmentBaseSteeringOffset,D0
	SUB.B	#$23,D0
	JMP	lbC052A36

lbC052A20:
	MOVE.B	segmentBaseSteeringOffset,D0
lbC052A26:
	TST.B	tempByte4
	BMI	lbC052A36
	ADD.B	steeringScaleFactor,D0
lbC052A36:
	JMP	lbC052B1C

lbC052A3C:
	MOVE.W	#$0000,D4
	MOVE.B	segmentSteeringFlags,D0
	BPL	lbC052A60
	MOVE.B	trackDirectionMultiplier,steeringInputDirection
	MOVE.B	segmentBaseSteeringOffset,D0
	JMP	lbC052B1C

lbC052A60:
	MOVE.B	tempWord1,steeringInputDirection
	MOVE.W	segmentProgressDistance,D0
	MOVE.B	D0,D2
	MOVE.B	segmentProgressDistance,D3
	BEQ	lbC052A88
	SUB.W	#$1E00,D0
	BPL	lbC052AC2
	MOVE.B	#$FF,D2
lbC052A88:
	MOVE.B	D2,tempByte3
	MOVE.W	carLocalVelocityZ,D0
	BPL	lbC052A9A
	NEG.W	D0
lbC052A9A:
	ADD.W	#$0A00,D0
	BPL	lbC052AA6
	MOVE.W	#$7F00,D0
lbC052AA6:
	MOVE.B	tempByte3,D3
	ASL.W	#$07,D3
	BCLR	#$0F,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	LSR.W	#$07,D0
	TST.B	D0
	BNE	lbC052AC2
	ADDQ.B	#$01,D0
lbC052AC2:
	TST.B	tempWord1
	BPL	.angleDeltaPositive
	NEG.W	D0
.angleDeltaPositive:
	muls	#TIMESTEP_FACTOR,d0	; added
	asr.l	#8,d0
	ADD.W	D0,cameraAngleY
lbC052AD4:
	MOVE.W	#$0000,D2
	MOVE.W	rotationSpeedY,D0
	AND.L	#$0000000F,D2
	LSR.W	D2,D0
	SUB.W	D0,D4
;	MOVE.L	#memory_79360,A0
;	SUB.L	#START+$6174,A0
;	MOVE.L	#$667B379F,D3
;	ADD.L	#$36729563,D3
;	CMP.L	(A0),D3			; This is the magic value at installLineEmulatorTrap
;	BNE	lbC052B10
	TST.B	wheelMovementActive
	BNE	lbC052B14
lbC052B10:
	MOVE.W	#$0000,D4
lbC052B14:
	MOVE.W	D4,angularAccelerationY
	RTS

lbC052B1C:
	MOVE.B	D0,tempByte3
	MOVE.W	carLocalVelocityZ,D0
	MOVE.B	tempByte3,D3
	ASL.W	#$07,D3
	BCLR	#$0F,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	TST.B	steeringInputDirection
	BPL	lbC052B46
	NEG.W	D0
lbC052B46:
	ASR.W	#$03,D0
	MOVE.W	D0,D4
	CMP.B	#$1E,segmentProgressDistance
	BCS	lbC052AD4
	BRA	lbC052A60

displayTrackHeader:
	JSR	setTextYOffset4
	MOVE.B	currentTrackID,D1
	MOVE.L	#trackDisplayYOffsets,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.B	D0,trackSpecificYOffset
	MOVE.B	#$58,D1
	JSR	renderLeagueText
	MOVE.B	currentTrackID,D1
	JSR	renderTrackName
	JSR	resetTextYOffset
	RTS

multiplyAndRandomize:
	AND.W	#$00FF,D0
	MOVE.B	tempByte3,D3
	AND.W	#$00FF,D3
	MULU	D0,D3
	MOVE.W	D3,D0
	MOVE.B	D0,tempByte4
	LSR.W	#$08,D0
	RTS

checkKeyPressed:
	MOVE.L	#keyboardState,A0
	MOVE.B	$00(A0,D1.W),D1
	CMP.B	#$B3,D1
	RTS

	TST.B	D0
	BMI	lbC052BE2
	TST.B	trackSideIndicatorCopy
	BMI	lbC052BEE
lbC052BDE:
	BRA	multiplyAndRandomize

lbC052BE2:
	NEG.B	D0
	TST.B	trackSideIndicatorCopy
	BMI	lbC052BDE
lbC052BEE:
	JSR	multiplyAndRandomize
	NEG.W	D3
	MOVE.W	D3,D0
	MOVE.B	D3,tempByte4
	LSR.W	#$08,D0
	RTS

	BCLR	#$07,trackSideIndicatorCopy
	ASL.W	#$08,D0
	OR.B	tempByte4,D0
	MOVE.B	tempByte3,D3
	AND.W	#$00FF,D3
	TST.B	trackSideIndicatorCopy
	BPL	lbC052C28
	NEG.W	D3
lbC052C28:
	MULS	D0,D3
	ASR.L	#$08,D3
	MOVE.W	D3,D0
	MOVE.B	D0,tempByte4
	LSR.W	#$08,D0
	RTS

getNegativeTrigValue:
	MOVE.W	#$FEC3,D0
	BRA	matrixMultiply

getPositiveTrigValue:
	MOVE.W	#$013D,D0
matrixMultiply:
	ASL.W	#$01,D1
	MOVE.L	#lbL00DB30,A0
	MOVE.W	$00(A0,D1.W),D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	LSR.W	#$01,D1
	RTS

squareAndAbsolute:
	MOVE.W	D0,D3
	MULS	D3,D0
	TST.L	D0
	BPL	lbC052C66
	NEG.L	D0
lbC052C66:
	RTS

calculateTransformMatrices:
	MOVE.L	#lbL00DB30,A5
	MOVE.W	cameraAngleY,D0
	JSR	calculateSine
	MOVE.W	D0,$0004(A5)
	MOVE.W	D0,$000C(A5)
	MOVE.W	D0,$000E(A5)
	MOVE.W	D0,$0014(A5)
	MOVE.W	D0,$0016(A5)
	MOVE.W	cameraAngleY,D0
	JSR	calculateCosine
	MOVE.W	D0,$0006(A5)
	MOVE.W	D0,$0010(A5)
	MOVE.W	D0,$0012(A5)
	MOVE.W	D0,$0018(A5)
	MOVE.W	D0,$001A(A5)
	MOVE.W	cameraAngleY,D0
	SUB.W	segmentTargetAngle,D0
	MOVE.W	D0,-(SP)
	JSR	calculateSine
	MOVE.W	D0,$0034(A5)
	MOVE.W	D0,$0042(A5)
	MOVE.W	D0,$0044(A5)
	MOVE.W	(SP)+,D0
	JSR	calculateCosine
	MOVE.W	D0,$0038(A5)
	MOVE.W	D0,$003E(A5)
	MOVE.W	D0,$0046(A5)
	MOVE.W	cameraAngleX,D0
	JSR	calculateSine
	MOVE.W	D0,$0008(A5)
	MOVE.W	cameraAngleX,D0
	JSR	calculateCosine
	MOVE.W	D0,$000A(A5)
	MOVE.W	D0,$001C(A5)
	MOVE.W	D0,$001E(A5)
	MOVE.W	cameraAngleZ,D0
	JSR	calculateCosine
	MOVE.W	D0,$0022(A5)
	MOVE.W	cameraAngleZ,D0
	JSR	calculateSine
	MOVE.W	D0,$0020(A5)
	MOVE.W	$0008(A5),D5
	MOVE.W	#$000C,D3
lbC052D32:
	MOVE.W	$00(A5,D3.W),D4
	MULS	D5,D4
	ASL.L	#$01,D4
	SWAP	D4
	MOVE.W	D4,$00(A5,D3.W)
	ADD.W	#$0002,D3
	CMP.W	#$0012,D3
	BLE	lbC052D32
	MOVE.W	$0008(A5),D5
	MOVE.W	#$0034,D3
lbC052D54:
	MOVE.W	$00(A5,D3.W),D4
	MULS	D5,D4
	ASL.L	#$01,D4
	SWAP	D4
	MOVE.W	D4,$00(A5,D3.W)
	ADD.W	#$0004,D3
	CMP.W	#$0038,D3
	BLE	lbC052D54
	MOVE.W	$000C(A5),(A5)
	MOVE.W	$0010(A5),$0002(A5)
	MOVE.W	$000A(A5),D5
	MOVE.W	#$0004,D3
lbC052D80:
	MOVE.W	$00(A5,D3.W),D4
	MULS	D5,D4
	ASL.L	#$01,D4
	SWAP	D4
	MOVE.W	D4,$00(A5,D3.W)
	ADD.W	#$0002,D3
	CMP.W	#$0006,D3
	BLE	lbC052D80
	MOVE.W	$000A(A5),D5
	MOVE.W	#$0044,D3
lbC052DA2:
	MOVE.W	$00(A5,D3.W),D4
	MULS	D5,D4
	ASL.L	#$01,D4
	SWAP	D4
	MOVE.W	D4,$00(A5,D3.W)
	ADD.W	#$0002,D3
	CMP.W	#$0046,D3
	BLE	lbC052DA2
	MOVE.W	$0020(A5),D5
	MOVE.W	#$000C,D3
lbC052DC4:
	MOVE.W	$00(A5,D3.W),D4
	MULS	D5,D4
	ASL.L	#$01,D4
	SWAP	D4
	MOVE.W	D4,$00(A5,D3.W)
	ADD.W	#$0004,D3
	CMP.W	#$001C,D3
	BLE	lbC052DC4
	MOVE.W	$0020(A5),D5
	MOVE.W	#$0034,D3
lbC052DE6:
	MOVE.W	$00(A5,D3.W),D4
	MULS	D5,D4
	ASL.L	#$01,D4
	SWAP	D4
	MOVE.W	D4,$00(A5,D3.W)
	ADD.W	#$0004,D3
	CMP.W	#$0038,D3
	BLE	lbC052DE6
	MOVE.W	$0022(A5),D5
	MOVE.W	#$000E,D3
lbC052E08:
	MOVE.W	$00(A5,D3.W),D4
	MULS	D5,D4
	ASL.L	#$01,D4
	SWAP	D4
	MOVE.W	D4,$00(A5,D3.W)
	ADD.W	#$0004,D3
	CMP.W	#$001E,D3
	BLE	lbC052E08
	MOVE.W	$0022(A5),D5
	MOVE.W	#$003E,D3
lbC052E2A:
	MOVE.W	$00(A5,D3.W),D4
	MULS	D5,D4
	ASL.L	#$01,D4
	SWAP	D4
	MOVE.W	D4,$00(A5,D3.W)
	ADD.W	#$0004,D3
	CMP.W	#$0042,D3
	BLE	lbC052E2A
	MOVE.W	$0018(A5),D0
	SUB.W	$000E(A5),D0
	MOVE.W	D0,$0028(A5)
	MOVE.W	$0012(A5),D0
	NEG.W	D0
	SUB.W	$0014(A5),D0
	MOVE.W	D0,$002A(A5)
	MOVE.W	$001A(A5),D0
	ADD.W	$000C(A5),D0
	MOVE.W	D0,$002C(A5)
	MOVE.W	$0010(A5),D0
	SUB.W	$0016(A5),D0
	MOVE.W	D0,$002E(A5)
	MOVE.W	$001C(A5),$0030(A5)
	NEG.W	$0030(A5)
	MOVE.W	$0020(A5),D0
	NEG.W	D0
	MOVE.W	D0,$0024(A5)
	RTS

transformWorldCoordinates:
	MOVE.W	#$0002,D2
	MOVE.L	#transformationMatrix,A5
	MOVE.L	#carLocalVelocityX,A4
lbC052E9C:
	MOVE.W	#$0000,D5
	MOVE.W	worldXSpeed,D0
	MOVE.B	$00(A5,D2.W),D1
	JSR	matrixMultiply
	ADD.W	D0,D5
	MOVE.W	worldYSpeed,D0
	MOVE.B	$03(A5,D2.W),D1
	JSR	matrixMultiply
	ADD.W	D0,D5
	MOVE.W	worldZSpeed,D0
	MOVE.B	$06(A5,D2.W),D1
	JSR	matrixMultiply
	ADD.W	D0,D5
	ASL.W	#$01,D2
	MOVE.W	D5,$00(A4,D2.W)
	LSR.W	#$01,D2
	SUBQ.B	#$02,D2
	BPL	lbC052E9C
	RTS

calculateViewAngles:
	MOVE.W	#$000F,D1
	JSR	getNegativeTrigValue
	MOVE.W	D0,baseRollAngle
	MOVE.W	#$0004,D1
	JSR	getNegativeTrigValue
	MOVE.W	D0,additionalYawOffset
	MOVE.W	#$000E,D1
	JSR	getPositiveTrigValue
	MOVE.W	D0,baseTargetRoll
	RTS

calculateSecondaryCoordinates:
	MOVE.W	#$0002,D2
	MOVE.L	#transformationMatrix,A5
	MOVE.L	#worldAccelerationX,A4
lbC052F28:
	MOVE.W	#$0000,D5
	MOVE.W	adjustedRollAngle,D0
	MOVE.B	$09(A5,D2.W),D1
	JSR	matrixMultiply
	ADD.W	D0,D5
	MOVE.W	adjustedPitchAngle,D0
	MOVE.B	$0C(A5,D2.W),D1
	JSR	matrixMultiply
	ADD.W	D0,D5
	MOVE.W	adjustedYawAngle,D0
	MOVE.B	$0F(A5,D2.W),D1
	JSR	matrixMultiply
	ADD.W	D0,D5
	ASL.W	#$01,D2
	MOVE.W	D5,$00(A4,D2.W)
	LSR.W	#$01,D2
	SUBQ.B	#$01,D2
	BPL	lbC052F28
	RTS

calculateTertiaryCoordinates:
	MOVE.W	#$0001,D2
	MOVE.L	#transformationMatrix,A5
	MOVE.L	#transformedAngularVelocityX,A4
lbC052F82:
	MOVE.W	#$0000,D5
	MOVE.W	rotationSpeedX,D0
	MOVE.B	$12(A5,D2.W),D1
	JSR	matrixMultiply
	ADD.W	D0,D5
	MOVE.W	rotationSpeedY,D0
	MOVE.B	$14(A5,D2.W),D1
	JSR	matrixMultiply
	ADD.W	D0,D5
	ASL.W	#$01,D2
	MOVE.W	D5,$00(A4,D2.W)
	LSR.W	#$01,D2
	SUBQ.B	#$01,D2
	BPL	lbC052F82
	MOVE.W	transformedAngularVelocityY,D0
	MOVE.W	#$0004,D1
	JSR	matrixMultiply
	ADD.W	rotationSpeedZ,D0
	MOVE.W	D0,transformedAngularVelocityZ
	RTS

verticalBlank:
	tst.b	creakingSoundCooldownTimer			; added
	beq.s	.creakingSoundCooldownTimerOk
	sub.b	#1,creakingSoundCooldownTimer
.creakingSoundCooldownTimerOk:
	add.b	#1,framesSinceCopperlistUpdateAccumulator
	CLR.W	D1
	CLR.W	D2
	TST.B	framesToWait
	BEQ	.waitOk
	SUBQ.B	#$01,framesToWait
.waitOk:
	TST.B	framesToWaitWhenFading
	BEQ	.fadeOk
	SUBQ.B	#$01,framesToWaitWhenFading
.fadeOk:
	TST.B	displayUpdateFlag
	BPL	.wheelGraphicsOk
	TST.B	disableWheelUpdateFlag
	BNE	.wheelGraphicsOk
	JSR	updateWheelGraphics
.wheelGraphicsOk:
	MOVE.W	dmaconValueToSet,_custom+dmacon
	MOVE.W	enginePitchAccumulator,D0
	ADD.W	enginePitchDelta,D0
	BPL	.enginePitchOk
	TST.B	gameExitFlag
	BEQ	.clearAccumulator
	MOVE.W	#DMAF_AUD0,_custom+dmacon
	MOVE.W	#INTF_AUD0,_custom+intena
	BRA	verticalBlankDone

.clearAccumulator:
	MOVE.W	#$0000,D0
.enginePitchOk:
	MOVE.W	D0,enginePitchAccumulator
	ADD.W	#$017A,D0
	MOVE.L	#$00493E00,D3
	DIVU	D0,D3
	CMP.W	#$3FFF,D3
	BCS	lbC053074
	MOVE.W	#$3FFE,D3
lbC053074:
	OR.B	engineAudioNoiseFlag,D3
	CMP.W	#$007C,D3
	BGE	lbC053086
	MOVE.W	#$007C,D3
lbC053086:
	MOVE.W	#$0006,D4
lbC05308A:
	CMP.W	#$0100,D3
	BLT	setAudioChannel0
	LSR.W	#$01,D3
	SUBQ.W	#$01,D4
	BPL	lbC05308A
	MOVE.W	#$0000,D4
	BRA	lbC05308A

setAudioChannel0:
	MOVE.L	#sampleEngineParameters,A0
	LEA	_custom,A1
	ASL.W	#$03,D4
	MOVE.L	$00(A0,D4.W),aud0(A1)
	MOVE.W	$06(A0,D4.W),aud0+ac_len(A1)
	MOVE.W	D3,audioChannel0Period
verticalBlankDone:
	RTS

;	MOVEM.L	(SP)+,D0-D7/A0-A6				; removed: dead code
;	RTS

adjustCoordinateBoundsFromCenter:
	MOVE.B	tempByte5,D1
	MOVE.B	#$02,D3
lbC0530DA:
	EOR.B	#$02,D1
	MOVE.L	#coordinateLookupTable,A4
	MOVE.L	#transformedVertexBounds,A5
	MOVE.W	$00(A4,D1.W),D0
	SUB.W	#$0080,D0
	BPL	lbC0530F8
	NEG.W	D0
lbC0530F8:
	SUB.W	#$00A0,D0
	BMI	lbC053106
	LSR.W	#$03,D0
	ADD.W	D0,$00(A5,D1.W)
lbC053106:
	SUBQ.B	#$01,D3
	BNE	lbC0530DA
	RTS

applyMomentumAmplification:
	MOVE.W	#$0114*FRAMERATE_MULTIPLIER,D3	; originally $0114
;	BEQ	lbC05311A			; originally BEQ
	MULS	D3,D0
	ASR.L	#$08,D0
;lbC05311A:
	ADD.W	D6,D0
	RTS

updateOpponentLapTime:
	MOVE.W	D1,D3
	MOVE.L	#trackProgressionByte,A0
	ASL.B	#$01,D3
	TST.B	$00(A0,D3.W)
	BNE	lbC05315A
	MOVE.B	$01(A0,D3.W),D0
	EOR.B	#$FF,D0
	MOVE.B	D0,tempByte3
	MOVE.B	#$0D,D0
	JSR	multiplyAndRandomize
	CMP.B	#$0A,D0
	BCS	lbC053154
	ADD.B	#$06,D0
lbC053154:
	JSR	incrementLapTimeBCD
lbC05315A:
	RTS

updateGamePhysics:
	JSR	calculateTransformMatrices
	JSR	calculateWheelCornerPositions
	JSR	updateWheelHeightsFromTrack
	JSR	calculateExpectedTrackSurfaceHeights
	JSR	transformWorldCoordinates
	JSR	updateWheelSpeed
	JSR	calculateViewAngles
	JSR	updateWheelSuspensionPhysics
	MOVE.B	frameProcessingFlag,D0
	BEQ	.processed
	JSR	updateCarOrientation
	JSR	calculateSteeringResponse
	JSR	calculateSecondaryCoordinates
	JSR	updateCollisionState
	JSR	updateVelocityDamping
	JSR	integrateVelocityComponents
	JSR	calculateTertiaryCoordinates
.processed:
	JSR	applyVelocityIntegration
	JSR	updateWorldPosition
	RTS

calculateWheelCornerPositions:
	MOVE.W	transformMatrix3E,D4
	MOVE.W	transformMatrix34,D0
	ASR.W	#$01,D4
	ASR.W	#$01,D0
	SUB.W	D0,D4
	MOVE.W	transformMatrix38,D5
	MOVE.W	transformMatrix44,D0
	ASR.W	#$01,D5
	ASR.W	#$01,D0
	SUB.W	D0,D5
	MOVE.W	transformMatrix46,D0
	MOVE.W	transformMatrix48,D3
	ASR.W	#$05,D4
	ASR.W	#$05,D5
	ASR.W	#$05,D0
	ASR.W	#$05,D3
	MOVE.W	D0,wheelCornerXRearCenter
	NEG.W	wheelCornerXRearCenter
	MOVE.W	D3,wheelCornerYRearCenter
	NEG.W	wheelCornerYRearCenter
	MOVE.W	D0,wheelCornerXFrontLeft
	MOVE.W	D0,wheelCornerXFrontRight
	MOVE.W	D3,wheelCornerYFrontLeft
	MOVE.W	D3,wheelCornerYFrontRight
	SUB.W	D4,wheelCornerXFrontLeft
	SUB.W	D5,wheelCornerYFrontLeft
	ADD.W	D4,wheelCornerXFrontRight
	ADD.W	D5,wheelCornerYFrontRight
	RTS

updateWorldPosition:
	MOVE.W	worldXSpeed,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC053262
	MULS	D2,D0
	ASR.L	#$08,D0
lbC053262:
	EXT.L	D0
	ASL.L	#$06,D0
	ADD.L	D0,cameraWorldX
	MOVE.W	worldYSpeed,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC05327E
	MULS	D2,D0
	ASR.L	#$08,D0
lbC05327E:
	EXT.L	D0
	ASL.L	#$07,D0
	ADD.L	D0,cameraWorldY
	MOVE.W	worldZSpeed,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC05329A
	MULS	D2,D0
	ASR.L	#$08,D0
lbC05329A:
	EXT.L	D0
	ASL.L	#$06,D0
	ADD.L	D0,cameraWorldZ
	MOVE.W	cameraWorldY,D0
	CMP.W	#$03E8,D0
	BLT	lbC0532BA
	MOVE.W	#$03E8,cameraWorldY
lbC0532BA:
	MOVE.W	transformedAngularVelocityX,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC0532CC
	MULS	D2,D0
	ASR.L	#$08,D0
lbC0532CC:
	ADD.W	D0,cameraAngleX
	MOVE.W	transformedAngularVelocityY,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC0532E4
	MULS	D2,D0
	ASR.L	#$08,D0
lbC0532E4:
	ADD.W	D0,cameraAngleY
	MOVE.W	transformedAngularVelocityZ,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC0532FC
	MULS	D2,D0
	ASR.L	#$08,D0
lbC0532FC:
	ADD.W	D0,cameraAngleZ
	MOVE.W	#$0000,D2
	TST.B	raceCompletionCheckFlag
	BPL	lbC053320
	MOVE.B	renderingOrderMode,D0
	CMP.B	#$E0,D0
	BNE	lbC053320
	ADDQ.B	#$02,D2
lbC053320:
	MOVE.L	#cameraAngleThresholds,A0
	MOVE.W	cameraAngleX,D3
	BMI	lbC05333E
	MOVE.W	$00(A0,D2.W),D0
	CMP.W	D3,D0
	BCC	lbC053362
	BRA	lbC053348

lbC05333E:
	MOVE.W	$04(A0,D2.W),D0
	CMP.W	D3,D0
	BCS	lbC053362
lbC053348:
	MOVE.W	D0,cameraAngleX
	MOVE.W	rotationSpeedX,D3
	EOR.W	D3,D0
	BMI	lbC053362
	MOVE.W	#$0000,rotationSpeedX
lbC053362:
	MOVE.W	cameraAngleZ,D3
	BMI	lbC05337A
	MOVE.W	$00(A0,D2.W),D0
	CMP.W	D3,D0
	BCC	lbC05339E
	BRA	lbC053384

lbC05337A:
	MOVE.W	$04(A0,D2.W),D0
	CMP.W	D3,D0
	BCS	lbC05339E
lbC053384:
	MOVE.W	D0,cameraAngleZ
	MOVE.W	rotationSpeedZ,D3
	EOR.W	D3,D0
	BMI	lbC05339E
	MOVE.W	#$0000,rotationSpeedZ
lbC05339E:
	BCLR	#$07,lbB00D4AB
	MOVE.B	cameraAngleX,D0
	BPL	lbC0533B2
	NEG.B	D0
lbC0533B2:
	CMP.B	#$0F,D0
	BLT	lbC0533C2
	BSET	#$07,lbB00D4AB
lbC0533C2:
	MOVE.W	#$0000,D0
	SUB.W	cameraAngleX,D0
	MOVE.W	D0,viewportCenterY
	RTS

applyVelocityIntegration:
	MOVE.W	worldAccelerationX,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC0533EE
	MULS	D2,D0
	ASR.L	#$08,D0
lbC0533EE:
	ADD.W	D0,worldXSpeed
	MOVE.W	worldAccelerationY,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC053406
	MULS	D2,D0
	ASR.L	#$08,D0
lbC053406:
	ADD.W	D0,worldYSpeed
	MOVE.W	worldAccelerationZ,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC05341E
	MULS	D2,D0
	ASR.L	#$08,D0
lbC05341E:
	ADD.W	D0,worldZSpeed
	RTS

integrateVelocityComponents:
	MOVE.W	angularAccelerationX,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
;	BEQ	lbC053438			; removed: unnecessary
	MULS	D2,D0
	ASR.L	#$08,D0
;lbC053438:
	ADD.W	D0,rotationSpeedX
	MOVE.W	angularAccelerationY,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
;	BEQ	lbC053450			; removed: unnecessary
	MULS	D2,D0
	ASR.L	#$08,D0
;lbC053450:
	ADD.W	D0,rotationSpeedY
	MOVE.W	angularAccelerationZ,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
;	BEQ	lbC053468			; removed: unnecessary
	MULS	D2,D0
	ASR.L	#$08,D0
;lbC053468:
	ADD.W	D0,rotationSpeedZ
	RTS

calculateExpectedTrackSurfaceHeights:
	MOVE.W	cameraAngleX,D0
	JSR	calculateSine
	MOVE.W	D0,tempWord1
	MOVE.W	cameraAngleZ,D0
	JSR	calculateSine
	EXT.L	D0
	ASL.L	#$03,D0
	MOVE.W	tempWord1,D3
	EXT.L	D3
	ASL.L	#$04,D3
	MOVE.L	cameraWorldY,D4
	SUB.L	D3,D4
	ASR.L	#$08,D4
	MOVE.L	D4,trackSurfaceRear
	MOVE.L	cameraWorldY,D4
	ADD.L	D3,D4
	MOVE.L	D4,D5
	SUB.L	D0,D5
	ASR.L	#$08,D5
	MOVE.L	D5,trackSurfaceFrontRight
	ADD.L	D0,D4
	ASR.L	#$08,D4
	MOVE.L	D4,trackSurfaceFrontLeft
	RTS

updateWheelSuspensionPhysics:
	MOVE.B	#$00,hardImpactCount
	MOVE.B	#$00,maxCompressionVelocity
	MOVE.L	wheelHeightFrontLeft,D0
	SUB.L	trackSurfaceFrontLeft,D0
	SUB.L	trackOffsetAdjustment,D0
	MOVE.L	D0,suspensionTravelFrontLeft
	BMI	.negativeSuspensionFrontLeftClamp
	CMP.L	#$00001400,D0
	BCS	.suspensionFrontLeftOk
	BRA	.positiveSuspensionFrontLeftClamp

.negativeSuspensionFrontLeftClamp:
	CMP.L	#$FFFFFD00,D0
	BCC	.suspensionFrontLeftOk
	MOVE.L	#$FFFFFD00,D0
	BRA	.suspensionFrontLeftOk

.positiveSuspensionFrontLeftClamp:
	MOVE.L	#$00001400,D0
.suspensionFrontLeftOk:
	MOVE.W	D0,clampedSuspensionFrontLeft
	MOVE.W	D0,D6
	MOVE.W	previousSuspensionFrontLeft,D3
	SUB.W	D3,D0
	JSR	applyMomentumAmplification
	BMI	.resetVelocityFrontLeft
	MOVE.W	suspensionVelocityFrontLeft,D4
	MOVE.W	D0,suspensionVelocityFrontLeft
	CMP.W	#$0400,D0
	BLT	.hardImpactFrontLeftChecked
	CMP.W	#$0200,D4
	BGE	.hardImpactFrontLeftChecked
	ADDQ.B	#$01,hardImpactCount
.hardImpactFrontLeftChecked:
	MOVE.W	suspensionVelocityFrontLeft,D0
	MOVE.B	trackWidthMultiplier,D3
	ASL.W	#$08,D3
	SUB.W	D3,D0
	BMI	.resetHighCompressionFrameCount
	CMP.W	#$0700,D0
	BLT	.resetHighCompressionFrameCount
	CMP.W	maxCompressionVelocity,D0
	BCS	.maxDistanceOk1
	MOVE.W	D0,maxCompressionVelocity
.maxDistanceOk1:
	SUB.W	#$0600,D0
	TST.B	frameThrottleFlag
	BMI	.damageAccumulationDone1
	ADDQ.B	#$01,highCompressionFrameCount
	MOVE.B	highCompressionFrameCount,D3
	CMP.B	damageFrameLimit,D3
	BGE	.damageAccumulationDone1
	LSR.W	#$08,D0
	MOVE.B	D0,D3
	LSR.B	#$01,D3
	ADD.B	D3,D0
	ADD.B	accumulatedForceFrontLeft,D0
	BCC	.forceXOk
	MOVE.B	#$FF,D0
.forceXOk:
	MOVE.B	D0,accumulatedForceFrontLeft
	MOVE.B	#$80,damageAccumulationActive
.damageAccumulationDone1:
	MOVE.W	suspensionVelocityFrontLeft,D0
	CMP.W	#$1200,D0
	BCS	.velocityFrontLeftOk
	MOVE.W	#$1200-1,suspensionVelocityFrontLeft
.velocityFrontLeftOk:
	BRA	.clampDistanceY

.resetVelocityFrontLeft:
	MOVE.W	#$0000,suspensionVelocityFrontLeft
.resetHighCompressionFrameCount:
	MOVE.B	#$00,highCompressionFrameCount
.clampDistanceY:
	MOVE.W	clampedSuspensionFrontLeft,previousSuspensionFrontLeft
	MOVE.L	wheelHeightFrontRight,D0
	SUB.L	trackSurfaceFrontRight,D0
	SUB.L	trackOffsetAdjustment,D0
	MOVE.L	D0,suspensionTravelFrontRight
	BMI	.negativeSuspensionFrontRightClamp
	CMP.L	#$00001400,D0
	BCS	.suspensionFrontRightOk
	BRA	.positiveSuspensionFrontRightClamp

.negativeSuspensionFrontRightClamp:
	CMP.L	#$FFFFFD00,D0
	BCC	.suspensionFrontRightOk
	MOVE.L	#$FFFFFD00,D0
	BRA	.suspensionFrontRightOk

.positiveSuspensionFrontRightClamp:
	MOVE.L	#$00001400,D0
.suspensionFrontRightOk:
	MOVE.W	D0,clampedSuspensionFrontRight
	MOVE.W	D0,D6
	MOVE.W	previousSuspensionFrontRight,D3
	SUB.W	D3,D0
	JSR	applyMomentumAmplification
	BMI	.resetVelocityFrontRight
	MOVE.W	suspensionVelocityFrontRight,D4
	MOVE.W	D0,suspensionVelocityFrontRight
	CMP.W	#$0400,D0
	BLT	.hardImpactFrontRightChecked
	CMP.W	#$0200,D4
	BGE	.hardImpactFrontRightChecked
	ADDQ.B	#$01,hardImpactCount
.hardImpactFrontRightChecked:
	MOVE.W	suspensionVelocityFrontRight,D0
	MOVE.B	trackWidthMultiplier,D3
	ASL.W	#$08,D3
	SUB.W	D3,D0
	BMI	.resetOffTrackFrameCounter2
	CMP.W	#$0700,D0
	BLT	.resetOffTrackFrameCounter2
	CMP.W	maxCompressionVelocity,D0
	BCS	.maxDistanceOk2
	MOVE.W	D0,maxCompressionVelocity
.maxDistanceOk2:
	SUB.W	#$0600,D0
	TST.B	frameThrottleFlag
	BMI	.damageAccumulationDone2
	ADDQ.B	#$01,highCompressionFrameCount
	MOVE.B	highCompressionFrameCount,D3
	CMP.B	damageFrameLimit,D3
	BGE	.damageAccumulationDone2
	LSR.W	#$08,D0
	MOVE.B	D0,D3
	LSR.B	#$01,D3
	ADD.B	D3,D0
	ADD.B	accumulatedForceFrontRight,D0
	BCC	.forceYOk
	MOVE.B	#$FF,D0
.forceYOk:
	MOVE.B	D0,accumulatedForceFrontRight
	MOVE.B	#$80,damageAccumulationActive
.damageAccumulationDone2:
	MOVE.W	suspensionVelocityFrontRight,D0
	CMP.W	#$1200,D0
	BCS	.velocityFrontRightOk
	MOVE.W	#$1200-1,suspensionVelocityFrontRight
.velocityFrontRightOk:
	BRA	.clampDistanceZ

.resetVelocityFrontRight:
	MOVE.W	#$0000,suspensionVelocityFrontRight
.resetOffTrackFrameCounter2:
	MOVE.B	#$00,highCompressionFrameCount
.clampDistanceZ:
	MOVE.W	clampedSuspensionFrontRight,previousSuspensionFrontRight
	MOVE.L	wheelHeightRear,D0
	SUB.L	trackSurfaceRear,D0
	SUB.L	trackOffsetAdjustment,D0
	MOVE.L	D0,suspensionTravelRear
	BMI	.negativeSuspensionRearClamp
	CMP.L	#$00001400,D0
	BCS	.suspensionRearOk
	BRA	.positiveSuspensionRearClamp

.negativeSuspensionRearClamp:
	CMP.L	#$FFFFFD00,D0
	BCC	.suspensionRearOk
	MOVE.L	#$FFFFFD00,D0
	BRA	.suspensionRearOk

.positiveSuspensionRearClamp:
	MOVE.L	#$00001400,D0
.suspensionRearOk:
	MOVE.W	D0,clampedSuspensionRear
	MOVE.W	D0,D6
	MOVE.W	previousSuspensionRear,D3
	SUB.W	D3,D0
	JSR	applyMomentumAmplification
	BMI	.resetVelocityRear
	MOVE.W	suspensionVelocityRear,D4
	MOVE.W	D0,suspensionVelocityRear
	CMP.W	#$0400,D0
	BLT	.hardImpactRearChecked
	CMP.W	#$0200,D4
	BGE	.hardImpactRearChecked
	ADDQ.B	#$01,hardImpactCount
.hardImpactRearChecked:
	MOVE.W	suspensionVelocityRear,D0
	MOVE.B	trackWidthMultiplier,D3
	ASL.W	#$08,D3
	SUB.W	D3,D0
	BMI	.resetOffTrackFrameCounter3
	CMP.W	#$0700,D0
	BLT	.resetOffTrackFrameCounter3
	CMP.W	maxCompressionVelocity,D0
	BCS	.maxDistanceOk3
	MOVE.W	D0,maxCompressionVelocity
.maxDistanceOk3:
	SUB.W	#$0600,D0
	TST.B	frameThrottleFlag
	BMI	.damageAccumulationDone3
	ADDQ.B	#$01,highCompressionFrameCount
	MOVE.B	highCompressionFrameCount,D3
	CMP.B	damageFrameLimit,D3
	BGE	.damageAccumulationDone3
	LSR.W	#$08,D0
	MOVE.B	D0,D3
	LSR.B	#$01,D3
	ADD.B	D3,D0
	ADD.B	accumulatedForceRear,D0
	BCC	.forceZOk
	MOVE.B	#$FF,D0
.forceZOk:
	MOVE.B	D0,accumulatedForceRear
	MOVE.B	#$80,damageAccumulationActive
.damageAccumulationDone3:
	MOVE.W	suspensionVelocityRear,D0
	CMP.W	#$1200,D0
	BCS	.velocityRearOk
	MOVE.W	#$1200-1,suspensionVelocityRear
.velocityRearOk:
	BRA	.clampingDone

.resetVelocityRear:
	MOVE.W	#$0000,suspensionVelocityRear
.resetOffTrackFrameCounter3:
	MOVE.B	#$00,highCompressionFrameCount
.clampingDone:
	MOVE.W	clampedSuspensionRear,previousSuspensionRear
	MOVE.W	suspensionVelocityFrontLeft,D0
	ADD.W	suspensionVelocityFrontRight,D0
	ASR.W	#$01,D0
	MOVE.W	D0,tempWord1
	ADD.W	suspensionVelocityRear,D0
	ASR.W	#$01,D0
	MOVE.W	D0,averageWheelVelocity
	JSR	calculateSuspensionSpringForces
	MOVE.W	suspensionVelocityFrontLeft,D0
	SUB.W	suspensionVelocityFrontRight,D0
	MOVE.W	D0,D3
	ASL.W	#$01,D0
	ADD.W	D3,D0
	BPL	.positive1
	NEG.W	D0
.positive1:
	CMP.W	#$1000,D0
	BLT	.averageOk
	MOVE.W	#$1000,D0
.averageOk:
	TST.W	D3
	BPL	.positive2
	NEG.W	D0
.positive2:
	MOVE.W	D0,targetRollRate
	MOVE.W	tempWord1,D0
	SUB.W	suspensionVelocityRear,D0
	MOVE.W	D0,targetPitchRate
	MOVE.B	averageWheelVelocity,D0
	OR.B	averageWheelVelocityLow,D0
	MOVE.B	D0,wheelMovementActive
	BNE	.targetPitchRateDone
	TST.B	raceStartTimer
	BNE	.targetPitchRateDone
	MOVE.W	#$FF80,D3
	MOVE.W	cameraAngleX,D0
	BPL	.cameraAnglePositive
	MOVE.B	currentTrackID,D0
	CMP.B	#$07,D0
	BNE	.notTrack7
	MOVE.B	#$F8,D1
	BRA	.checkTargetPitchRate

.notTrack7:
	CMP.B	#$04,D0
	BNE	.targetPitchRateDone
	MOVE.W	#$FFF8,D3
	BRA	.checkTargetPitchRate

.cameraAnglePositive:
	CMP.W	#$1000,D0
	BLT	.checkTargetPitchRate
	MOVE.W	#$FF00,D3
.checkTargetPitchRate:
	SUB.W	targetPitchRate,D3
	BPL	.targetPitchRateDone
	MOVE.B	rotationSpeedX,D0
	BPL	.setTargetPitchRate
	CMP.B	#$FF,D0
	BNE	.targetPitchRateDone
.setTargetPitchRate:
	MOVE.W	D3,targetPitchRate
.targetPitchRateDone:
	JSR	handleRaceStartCountdown
	MOVE.W	yawSpringAngle,lbW00D646
	JSR	applyOpponentCollisionForces
	TST.B	impactSoundCooldownTimer
	BEQ	.cooldownTimerOk
	SUBQ.B	#$01,impactSoundCooldownTimer
.cooldownTimerOk:
	TST.B	hardImpactCount
	BEQ	.impactSoundDone
	MOVE.B	maxCompressionVelocity,D0
	CMP.B	#$07,D0
	BCC	.minimumVolumeOk
	MOVE.B	#$07,D0
.minimumVolumeOk:
	ASL.B	#$02,D0
	CMP.B	#$40,D0
	BCS	.maximumVolumeOk
	MOVE.B	#$40,D0
.maximumVolumeOk:
	MOVE.B	D0,sampleImpactVolume
	TST.B	impactSoundCooldownTimer
	BNE	.impactSoundDone
	MOVE.B	#$03,D0					; impact
	JSR	playSample
	MOVE.B	#$05*FRAMERATE_MULTIPLIER,impactSoundCooldownTimer		; originally $05
.impactSoundDone:
	RTS

updateCarOrientation:
	MOVE.W	baseRollAngle,D0
	ADD.W	pitchSpringAngle,D0
	MOVE.W	D0,adjustedPitchAngle
	MOVE.B	gasOutputAccumulatorValue,D0
	OR.B	carLocalVelocityZ,D0
	BMI	lbC0539EE
	TST.B	gasOutputIntensityValue
	BEQ	lbC0539EE
	AND.W	#$00FF,D0
	SUB.W	D0,gasOutputAccumulatorValue
lbC0539EE:
	MOVE.W	gasOutputAccumulatorValue,D3
	BPL	lbC0539FA
	NEG.W	D3
lbC0539FA:
	JSR	getSteeringMultiplier
	SUB.W	D0,D3
	BCS	lbC053A18
	TST.B	gasOutputAccumulatorValue
	BPL	lbC053A12
	NEG.W	D0
lbC053A12:
	MOVE.W	D0,gasOutputAccumulatorValue
lbC053A18:
	MOVE.W	gasOutputAccumulatorValue,D0
	ADD.W	yawSpringAngle,D0
	ADD.W	additionalYawOffset,D0
	MOVE.W	D0,adjustedYawAngle
	JSR	calculateRollAngleTransition
	RTS

updateVelocityDamping:
	MOVE.W	rotationSpeedX,D3
	tst.b	wheelMovementActive	; added
	bne.s	.groundDampingX
	ASR.W	#$04,D3
	MOVE.W	targetPitchRate,D0
	SUB.W	D3,D0
;	TST.B	wheelMovementActive
	BRA.S	lbC053A5C		; originally BEQ
.groundDampingX:
	asr.w	#1,d3			; added
	MOVE.W	targetPitchRate,D0
	SUB.W	D3,D0
	MOVE.W	adjustedYawAngle,D3
	ASR.W	#$02,D3
	ADD.W	D3,D0
lbC053A5C:
	MOVE.W	D0,angularAccelerationX
	MOVE.W	rotationSpeedZ,D3
	tst.b	wheelMovementActive	; added
	bne.s	.groundDampingZ
	ASR.W	#$04,D3
	bra.s	.speedZOk
.groundDampingZ:
	asr.w	#1,d3			; added
.speedZOk:
	MOVE.W	targetRollRate,D0
	SUB.W	D3,D0
	MOVE.W	D0,angularAccelerationZ
	RTS

calculateRollAngleTransition:
	MOVE.W	baseTargetRoll,D4
	ADD.W	rollSpringAngle,D4
	MOVE.W	D4,D3
	SUB.W	carLocalVelocityX,D3
	BPL	lbC053A94
	NEG.W	D3
lbC053A94:
	JSR	getSteeringMultiplier
	CMP.W	D0,D3
	BCS	lbC053ABE
	TST.B	carLocalVelocityX
	BPL	lbC053AAC
	NEG.W	D0
lbC053AAC:
	SUB.W	D0,D4
	MOVE.W	D4,adjustedRollAngle
	MOVE.B	#$80,rollTransitionFlag
	RTS

lbC053ABE:
	MOVE.W	rollSpringAngle,D0
	SUB.W	carLocalVelocityX,D0
	MOVE.W	D0,adjustedRollAngle
	MOVE.B	#$00,rollTransitionFlag
	RTS

getSteeringMultiplier:
	TST.B	wheelMovementActive
	BEQ	lbC053AEE
	MOVE.W	pitchSpringAngle,D0
	ASL.W	#$01,D0
	RTS

lbC053AEE:
	MOVE.W	#$0000,D0
	RTS

updateCollisionState:
	MOVE.L	#$00000001,D7
	TST.B	wheelMovementActive
	BEQ	lbC053B2E
	MOVE.B	lbW00D646,D0
	BPL	lbC053B12
	EOR.B	#$FF,D0
lbC053B12:
	CMP.B	#$03,D0
	BGE	lbC053B3E
	TST.B	offTrackStateFlags
	BMI	lbC053B3E
	TST.B	postWreckStateFlag
	BNE	lbC053B38
lbC053B2E:
	TST.B	raceStartTimer
	BEQ	lbC053B46
lbC053B38:
	MOVE.L	#$00000003,D7
lbC053B3E:
	MOVE.W	#$6000,D0
	BRA	lbC053BA4

lbC053B46:
	MOVE.W	carLocalVelocityX,D0
	BPL	lbC053B52
	NEG.W	D0
lbC053B52:
	MOVE.W	carLocalVelocityY,D3
	BPL	lbC053B5E
	NEG.W	D3
lbC053B5E:
	CMP.W	D3,D0
	BGE	lbC053B66
	MOVE.W	D3,D0
lbC053B66:
	MOVE.W	carLocalVelocityZ,D3
	BPL	lbC053B72
	NEG.W	D3
lbC053B72:
	CMP.W	D3,D0
	BGE	lbC053B7A
	MOVE.W	D3,D0
lbC053B7A:
	MOVE.L	#$00000005,D7
	TST.B	draftingTimer
	BPL	lbC053BA4
	TST.B	opponentAheadFlag
	BMI	lbC053BA4
	MOVE.W	#$0014,D3
	ASL.W	#$07,D3
	SUB.W	D3,D0
	BCC	lbC053BA4
	MOVE.W	#$0000,D0
lbC053BA4:
	MOVE.W	worldXSpeed,D3
	MULS	D0,D3
	SWAP	D3
	ASR.W	D7,D3
	SUB.W	D3,worldAccelerationX
	MOVE.W	worldYSpeed,D3
	MULS	D0,D3
	SWAP	D3
	ASR.W	D7,D3
	SUB.W	D3,worldAccelerationY
	MOVE.W	worldZSpeed,D3
	MULS	D0,D3
	SWAP	D3
	ASR.W	D7,D3
	SUB.W	D3,worldAccelerationZ
	RTS

calculateSuspensionSpringForces:
	MOVE.W	#$0000,pitchReferenceZero
	MOVE.L	suspensionTravelFrontLeft,D0
	ADD.L	suspensionTravelFrontRight,D0
	ASR.L	#$01,D0
	SUB.L	suspensionTravelRear,D0
	ASR.L	#$04,D0
	MOVE.W	D0,D3
	EOR.W	#$8000,D3
	MOVE.W	D3,pitchDisplacement
	JSR	attenuateDisplacementValue
	MOVE.B	attenuatedDisplacementValue,tempAttenuatedValue
	MOVE.B	rawDisplacementValue,yawSpringComponent
	MOVE.L	suspensionTravelFrontLeft,D0
	SUB.L	suspensionTravelFrontRight,D0
	ASR.L	#$03,D0
	MOVE.W	D0,rollDisplacement
	JSR	attenuateDisplacementValue
	MOVE.B	tempAttenuatedValue,tempByte3
	MOVE.B	attenuatedDisplacementValue,D0
	JSR	multiplyAndRandomize
	MOVE.B	D0,pitchSpringComponent
	MOVE.B	rawDisplacementValue,D0
	JSR	multiplyAndRandomize
	MOVE.B	D0,rollSpringComponent
	MOVE.B	rollSpringComponent,tempByte3
	MOVE.B	rollDisplacement,trackSideIndicatorCopy
	MOVE.W	averageWheelVelocity,D0
	MOVE.B	tempByte3,D3
	AND.W	#$00FF,D3
	TST.B	trackSideIndicatorCopy
	BPL	.rollComponentPositive
	NEG.W	D3
.rollComponentPositive:
	ASL.W	#$07,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	MOVE.W	D0,rollSpringAngle
	MOVE.B	pitchSpringComponent,tempByte3
	MOVE.B	pitchReferenceZero,trackSideIndicatorCopy
	MOVE.W	averageWheelVelocity,D0
	MOVE.B	tempByte3,D3
	AND.W	#$00FF,D3
	TST.B	trackSideIndicatorCopy
	BPL	.pitchComponentPositive
	NEG.W	D3
.pitchComponentPositive:
	ASL.W	#$07,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	MOVE.W	D0,pitchSpringAngle
	MOVE.B	yawSpringComponent,tempByte3
	MOVE.B	pitchDisplacement,trackSideIndicatorCopy
	MOVE.W	averageWheelVelocity,D0
	MOVE.B	tempByte3,D3
	AND.W	#$00FF,D3
	TST.B	trackSideIndicatorCopy
	BPL	.yawComponentPositive
	NEG.W	D3
.yawComponentPositive:
	ASL.W	#$07,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	MOVE.W	D0,yawSpringAngle
	RTS

attenuateDisplacementValue:
	TST.W	D0
	BPL	.distancePositive
	NEG.W	D0
.distancePositive:
	MOVE.B	#$FF,D1
	CMP.W	#$0100,D0
	BGE	.distanceOk
	MOVE.B	D0,D1
.distanceOk:
	MOVE.B	D1,rawDisplacementValue
	LSR.B	#$01,D1
	MOVE.L	#attenuationTable,A0
	MOVE.B	$00(A0,D1.W),D0
	MOVE.B	D0,attenuatedDisplacementValue
	RTS

projectTrackXToScreen:
	MOVE.W	tempWord1,D0
	MOVE.W	tempWord2,D3
	TST.B	segmentConfigLoadedFlag
	BPL	transformXCoordinateToPerspective
	ASR.W	#$01,D0
	ASR.W	#$01,D3
	MOVE.W	D3,perspectiveDepthDivisor
	ADD.B	#$31,perspectiveDepthDivisor
	ASR.W	#$01,D3
	ADD.W	#$4900,D3
	JSR	calculateDivision
	SUB.W	cameraYawPerspectiveOffset,D0
	ASR.W	#$03,D0
	MOVE.L	#coordinateLookupTable,A0
	MOVE.W	D0,$00(A0,D1.W)
	RTS

transformXCoordinateToPerspective:
	JSR	calculateDivision
	SUB.W	cameraYawPerspectiveOffset,D0
	ASR.W	#$03,D0
	MOVE.L	#coordinateLookupTable,A0
	MOVE.W	D0,$00(A0,D1.W)
	JSR	calculateVectorMagnitude
	MOVE.W	D0,perspectiveDepthDivisor
	RTS

transformCoordinate:
	MOVE.L	#trackSegmentData,A0
	MOVE.W	$00(A0,D1.W),D0
	SUB.W	cameraHeightBaseline,D0
	NEG.W	D0
	ASR.W	#$02,D0
	MOVE.W	perspectiveDepthDivisor,D3
	TST.B	segmentConfigLoadedFlag
	BPL	transformYCoordinateToPerspective
	MOVE.W	#$4C1B,D4
	MULS	D4,D0
	ASL.L	#$01,D0
	SWAP	D0
transformYCoordinateToPerspective:
	JSR	calculateDivision
	SUB.W	viewportCenterY,D0
	ASR.W	#$03,D0
	MOVE.L	#transformedVertexBounds,A0
	MOVE.W	D0,$00(A0,D1.W)
	RTS

apply3DTransformation:
	MOVE.L	#trackSegmentData,A0
	TST.W	$00(A0,D1.W)
	BMI	lbC053E72
applyScreenSpaceRotation:
	MOVE.L	#lbL00DB30,A3
	MOVE.L	#coordinateLookupTable,A5
	MOVE.L	#transformedVertexBounds,A4
projectVertexToScreen:
	MOVE.W	$00(A5,D1.W),D5
	MOVE.W	$00(A4,D1.W),D4
	MOVE.W	$0022(A3),D0
	MULS	D5,D0
	ASL.L	#$01,D0
	SWAP	D0
	MOVE.W	$0020(A3),D3
	MULS	D4,D3
	ASL.L	#$01,D3
	SWAP	D3
	ADD.W	D3,D0
	ASR.W	#$02,D0
	ADD.W	#$0080,D0
	MOVE.W	D0,$00(A5,D1.W)
	MOVE.W	$0022(A3),D0
	MULS	D4,D0
	ASL.L	#$01,D0
	SWAP	D0
	MOVE.W	$0020(A3),D3
	MULS	D5,D3
	ASL.L	#$01,D3
	SWAP	D3
	SUB.W	D3,D0
	ASR.W	#$02,D0
	ADD.W	#$0040,D0
	MOVE.W	D0,$00(A4,D1.W)
lbC053E72:
	RTS

generateRandomNumber:
	MOVE.W	randomSeed2,D0
	LSR.W	#$04,D0
	MOVE.W	randomSeed1,D3
	LSR.W	#$01,D3
	EOR.B	D3,D0
	MOVE.L	randomSeed1,D3
	ASL.L	#$08,D3
	MOVE.B	randomSeed3,D3
	MOVE.L	D3,randomSeed1
	MOVE.B	D0,randomSeed3
	RTS

displayMessage:
	CLR.W	D3
	MOVE.W	D1,D3
	CLR.W	D1
	BRA	.getCharacter

.loop:	JSR	renderCharacter
	ADDQ.W	#$01,D3
.getCharacter:
	MOVEA.L	#saveLoadMenuText,A1
	MOVE.B	$00(A1,D3.W),D0
	CMP.B	#$FF,D0
	BNE	.loop
	RTS

showLoadGameMenu:
	JSR	drawScreenFrame
	JSR	copyFirstFrameBufferToSecond
	MOVE.W	#$012A,D1
;	JSR	displayMessageWithColors			; removed
;	JSR	waitForInputPress
	JSR	drawScreenFrame
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	MOVE.W	#$0000,D1
	TST.B	writeMode
	BEQ	lbC054086
	MOVE.W	#$0016,D1
lbC054086:
	JSR	displayMessage
	JSR	copyFirstFrameBufferToSecond
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	displayFrameBuffer,renderFrameBuffer
	MOVE.B	#$80,disableDirectionalInputFlag
	JSR	handleSaveSlotSelection
	MOVE.B	#$00,disableDirectionalInputFlag
	MOVE.B	#$03,D0
	JSR	setForegroundColor
	MOVE.L	(SP)+,renderFrameBuffer
	RTS

handleSaveSlotSelection:
	JSR	loadSaveGameFromDisk
	TST.B	diskOperationAborted
	BPL	lbC0540DC
	RTS

lbC0540DC:
	JSR	displayAllSaveSlots
	MOVE.B	#$00,textTransparencyMode
lbC0540EA:
	MOVE.B	#$0F,lbB0544B8
	MOVE.B	#$0B,lbB0544B9
	MOVE.B	selectedSaveSlotIndex,D0
	TST.B	writeMode
	BEQ	lbC054110
	MOVE.B	backupSaveSlotIndex,D0
lbC054110:
	MOVE.B	D0,currentSaveSlotIndex
	MOVE.B	#$00,lbB0544B8
	MOVE.B	#$00,lbB0544B9
	MOVE.B	#$02,D0
	JSR	setForegroundColor
	JSR	displaySaveSlot
	SUB.B	#$09,textCursorColumn
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
	MOVE.B	#$3E,D0
	JSR	renderCharacter
	JSR	waitForDirectionRelease
	MOVE.B	textCursorColumn,lbB0544BA
	TST.B	writeMode
	BNE	lbC05419A
lbC05416C:
	JSR	waitForInputPress
	JSR	processDirectionalInput
	TST.B	directionalInputBits
	BNE	handleSlotNavigation
	CMP.B	#$0D,D0
	BNE	lbC05416C
	CMP.B	#$20,nameInputBuffer
	BEQ	lbC05416C
	BRA	lbC05424A

lbC05419A:
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
	MOVE.B	#$02,D0
	JSR	setForegroundColor
	MOVE.B	#$C0,D0
	MOVE.B	#$08,D3
	JSR	inputTextString
	MOVE.W	#$0091,D1
	JSR	displayMessageWithColors
	TST.B	directionalInputBits
	BNE	handleSlotNavigation
	CMP.B	#$20,nameInputBuffer
	BNE	lbC05424A
	MOVE.B	#$7F,D1
	MOVE.W	D1,D1
	JSR	displayMessageWithColors
	MOVE.B	#$00,currentInputPosition
	BRA	lbC05419A

handleSlotNavigation:
	BMI	setDiskOperationAborted
	JSR	refreshSaveSlotDisplay
	BTST	#$06,directionalInputBits
	BNE	lbC054240
	BTST	#$05,directionalInputBits
	BNE	lbC054236
	BTST	#$03,directionalInputBits
	BNE	lbC05422C
	JSR	checkMinimumSlotThreshold
	BRA	lbC054246

lbC05422C:
	JSR	checkMaximumSlotThreshold
	BRA	lbC054246

lbC054236:
	JSR	moveToPreviousSlot
	BRA	lbC054246

lbC054240:
	JSR	moveToNextSlot
lbC054246:
	BRA	lbC0540EA

lbC05424A:
	JSR	checkSpecialCommands
	BCS	lbC0540EA
	MOVE.B	#$02,D0
	JSR	setForegroundColor
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	JSR	initializeSlotDisplay
	MOVE.B	#$01,D0
	JSR	syncMultiplayerRecords
	CLR.W	D0
	MOVE.B	currentSaveSlotIndex,D0
	ADD.W	#$0017,D0
	MOVE.W	D0,lbW054632
lbC05428A:
	MOVE.W	lbW054632,D0
	MOVE.L	#transferBuffer,A0
	TST.B	writeMode
	BEQ	lbC0542D2
	JSR	writeSaveSlotToDisk
	BEQ	writeBackupSaveSlot
	BPL	lbC05428A
	RTS

writeBackupSaveSlot:
	MOVE.B	currentSaveSlotIndex,D3
	ADDQ.B	#$01,D3
	CMP.B	#$1E,D3
	BLT	.indexOk
	MOVE.B	#$00,D3
.indexOk:
	MOVE.B	D3,backupSaveSlotIndex
	JSR	commitSaveSlotToDisk
	RTS

lbC0542D2:
	JSR	readSaveSlotFromDisk
	BEQ	lbC0542E2
	BPL	lbC05428A
	RTS

lbC0542E2:
	MOVE.B	currentSaveSlotIndex,selectedSaveSlotIndex
	JSR	commitSaveSlotToDisk
	MOVE.B	#$00,D0
	JSR	syncMultiplayerRecords
	RTS

promptDiskRetryOrAbort:
	MOVE.B	#$00,diskOperationAborted
	TST.B	D0
	BNE	showDiskErrorAndPrompt
	RTS

showDiskErrorAndPrompt:
	MOVE.B	#$2C,D1
	CMP.B	#$22,D0
	BEQ	lbC05432A
	MOVE.B	#$3C,D1
	CMP.B	#$1C,D0
	BEQ	lbC05432A
	MOVE.B	#$D4,D1
lbC05432A:
	MOVE.W	D1,D1
	JSR	displayMessageWithColors
	JSR	waitForInputPress
	LSR.W	#$08,D0
	CMP.B	#$45,D0
	BEQ	setDiskOperationAborted
	MOVE.B	#$03,D0
	JSR	setForegroundColor
	MOVE.W	#$0091,D1
	JSR	displayMessageWithColors
	MOVE.B	#$32,D2
	JSR	delayWithParam
	MOVE.B	#$01,D0
	RTS

setDiskOperationAborted:
	MOVE.B	#$80,diskOperationAborted
	RTS

refreshSaveSlotDisplay:
	MOVE.B	#$03,D0
	JSR	setForegroundColor
	MOVE.B	lbB0544BA,textCursorColumn
	SUB.B	#$01,textCursorColumn
	MOVE.B	#$20,D0
	JSR	renderCharacter
	MOVE.B	#$0F,lbB0544B8
	MOVE.B	#$0B,lbB0544B9
	JSR	displaySaveSlot
	SUB.B	#$09,textCursorColumn
	RTS

moveToPreviousSlot:
	MOVE.B	currentSaveSlotIndex,D0
	SUBQ.B	#$01,D0
	BPL	lbC0543C6
	MOVE.B	#$1D,D0
lbC0543C6:
	BRA	updateCurrentSlot

moveToNextSlot:
	MOVE.B	currentSaveSlotIndex,D0
	ADDQ.B	#$01,D0
	CMP.B	#$1E,D0
	BLT	updateCurrentSlot
	MOVE.B	#$00,D0
updateCurrentSlot:
	MOVE.B	D0,currentSaveSlotIndex
	TST.B	writeMode
	BEQ	lbC0543F6
	MOVE.B	D0,backupSaveSlotIndex
	RTS

lbC0543F6:
	MOVE.B	D0,selectedSaveSlotIndex
	RTS

checkMaximumSlotThreshold:
	MOVE.B	currentSaveSlotIndex,D0
	ADD.B	#$0A,D0
	CMP.B	#$1E,D0
	BLT	updateCurrentSlot
	RTS

checkMinimumSlotThreshold:
	MOVE.B	currentSaveSlotIndex,D0
	SUB.B	#$0A,D0
	BPL	updateCurrentSlot
	RTS

waitForDirectionRelease:
	JSR	readJoystickState
	MOVE.B	joystickState,D0
	AND.B	#$0F,D0
	EOR.B	#$0F,D0
	BNE	waitForDirectionRelease
	MOVE.B	#$4C,D1
	JSR	checkKeyPressed
	BEQ	waitForDirectionRelease
	MOVE.B	#$4D,D1
	JSR	checkKeyPressed
	BEQ	waitForDirectionRelease
	MOVE.B	#$4F,D1
	JSR	checkKeyPressed
	BEQ	waitForDirectionRelease
	MOVE.B	#$4E,D1
	JSR	checkKeyPressed
	BEQ	waitForDirectionRelease
	RTS

readSaveSlotFromDisk:
	MOVE.W	#$0000,D3
	BRA	transferSaveSlot

writeSaveSlotToDisk:
	MOVE.W	#$0001,D3
transferSaveSlot:
	CMP.W	#$0320,D3
	BCC	displaySaveSlotFailedDialog
	MOVE.W	D0,D1
	MOVE.W	#$0000,D0
	MOVE.W	#$0001,D2
	MOVE.L	#$00000400,A1
	JSR	loadOrSaveData
	CLR.W	D1
	CLR.W	D2
lbC0544A2:
	JSR	promptDiskRetryOrAbort
	RTS

displaySaveSlotFailedDialog:
	MOVE.B	#$80,D0
	BRA	lbC0544A2

commitSaveSlotToDisk:
	CLR.L	D0
	MOVE.W	lbW054632,D0
	SUB.L	#$00000017,D0
	ASL.L	#$04,D0
	MOVE.W	#$0007,D3
	MOVE.L	#nameInputBuffer,A0
	MOVE.L	#saveSlotNameBuffer,A1
	ADD.L	D0,A1
lbC0544E0:
	MOVE.B	$00(A0,D3.W),$00(A1,D3.W)
	DBRA	D3,lbC0544E0
	MOVE.B	#$00,$000F(A1)
lbC0544F0:
	MOVE.L	#saveSlotNameBuffer,A0
	MOVE.W	#$0016,D0
	MOVE.L	#$47826653,saveDataValidationBuffer
	MOVE.B	selectedSaveSlotIndex,savedSlotIndex
	MOVE.B	backupSaveSlotIndex,saveSlotFlags
	JSR	writeSaveSlotToDisk
	BEQ	lbC054526
	BPL	lbC0544F0
lbC054526:
	RTS

loadSaveGameFromDisk:
	MOVE.B	#$01,lbB054608
lbC054530:
	MOVE.B	#$00,saveSlotHighlightFlag
	MOVE.B	#$00,diskOperationAborted
	MOVE.L	#saveSlotNameBuffer,A0
	MOVE.W	#$0016,D0
	JSR	readSaveSlotFromDisk
	BEQ	lbC05455C
	BMI	lbC054606
	BRA	loadSaveGameFromDisk

lbC05455C:
	MOVE.B	savedSlotIndex,D0
	MOVE.B	saveSlotFlags,D3
	CMP.L	#$47826653,saveDataValidationBuffer
	BEQ	lbC0545FA
	MOVE.B	#$80,saveSlotHighlightFlag
	TST.B	writeMode
	BEQ	lbC0545F2
	MOVE.W	#$00F0,D1
	JSR	displayMessageWithColors
	SUBQ.B	#$01,lbB054608
	BMI	lbC0545F2
	JSR	waitForInputPress
	CMP.B	#$00,D0
	BNE	lbC0545C0
	LSR.W	#$08,D0
	CMP.B	#$45,D0
	BNE	lbC0545C0
	MOVE.B	#$80,diskOperationAborted
	BRA	lbC0545F2

lbC0545C0:
	JSR	drawScreenFrame
	MOVE.B	#$01,textYOffset
	MOVE.W	#$0000,D1
	TST.B	writeMode
	BEQ	lbC0545E0
	MOVE.W	#$0016,D1
lbC0545E0:
	JSR	displayMessage
	MOVE.B	#$00,textYOffset
	BRA	lbC054530

lbC0545F2:
	MOVE.B	#$00,D0
	MOVE.B	#$00,D3
lbC0545FA:
	MOVE.B	D0,selectedSaveSlotIndex
	MOVE.B	D3,backupSaveSlotIndex
lbC054606:
	RTS

loadLapRecords:
	MOVE.W	#$0000,D0
	MOVE.W	#$0005,D1
	MOVE.W	#$0001,D2
	MOVE.W	#$0000,D3
	MOVE.L	#saveSlotNameBuffer,A0
	MOVE.L	#$00000400,A1
	JSR	loadOrSaveData
	CLR.W	D1
	CLR.W	D0
	RTS

displayAllSaveSlots:
	MOVE.B	#$00,textTransparencyMode
	MOVE.B	#$03,D0
	JSR	setForegroundColor
	MOVE.B	#$0F,lbB0544B8
	MOVE.B	#$0B,lbB0544B9
	MOVE.B	#$00,currentSaveSlotIndex
lbC05465E:
	JSR	displaySaveSlot
	ADDQ.B	#$01,currentSaveSlotIndex
	CMP.B	#$1E,currentSaveSlotIndex
	BNE	lbC05465E
	MOVE.B	#$80,textTransparencyMode
	RTS

initializeSlotDisplay:
	MOVE.B	#$80,lbB0544BC
	BRA	lbC054692

displaySaveSlot:
	CLR.B	lbB0544BC
lbC054692:
	MOVE.L	#nameInputBuffer,A1
	MOVE.B	#$00,currentInputPosition
	MOVE.B	#$06,D4
	MOVE.B	currentSaveSlotIndex,D5
	CMP.B	#$1E,D5
	BCS	lbC0546B6
	MOVE.B	#$00,D5
lbC0546B6:
	CMP.B	#$0A,D5
	BLT	lbC0546CA
	SUB.B	#$0A,D5
	ADD.B	#$0A,D4
	BRA	lbC0546B6

lbC0546CA:
	ADD.B	#$0B,D5
	MOVE.B	#$1F,D0
	JSR	renderCharacter
	MOVE.B	D4,D0
	JSR	renderCharacter
	MOVE.B	D5,D0
	JSR	renderCharacter
	CLR.W	D0
	MOVE.B	currentSaveSlotIndex,D0
	ASL.W	#$04,D0
	MOVE.L	#saveSlotNameBuffer,A0
	LEA	$00(A0,D0.W),A0
	MOVE.W	#$0000,D3
lbC054700:
	TST.B	lbB0544BC
	BPL	lbC054718
	MOVE.L	#nameInputBuffer,A0
	MOVE.B	$00(A0,D3.W),D0
	BRA	lbC054766

lbC054718:
	TST.B	$000F(A0)
	BNE	lbC054750
	TST.B	saveSlotHighlightFlag
	BNE	lbC054750
	MOVE.B	lbB0544B8,D0
	JSR	setBackgroundColor
	MOVE.B	$00(A0,D3.W),D0
	MOVE.B	D0,$00(A1,D3.W)
	CMP.B	#$20,D0
	BLE	lbC054750
	ADDQ.B	#$01,currentInputPosition
	BRA	lbC054766

lbC054750:
	MOVE.B	#$20,$00(A1,D3.W)
	MOVE.B	lbB0544B9,D0
	JSR	setBackgroundColor
	MOVE.B	#$5F,D0
lbC054766:
	JSR	renderCharacter
	ADDQ.W	#$01,D3
	CMP.W	#$0008,D3
	BNE	lbC054700
	RTS

loadOrSaveData:
	tst.l	readWriteSaveSlotData				; added
	beq.s	.done
	move.l	readWriteSaveSlotData,a2
	JSR	(a2)						; originally readWriteSaveSlotData
.done:	JMP	finalizeFloppyAccessAndInitCIA

saveRandomState:
	MOVE.L	randomSeed1,savedRandomSeed1
	MOVE.B	randomSeed3,savedRandomSeed3
	RTS

initializeRandomSeeds:
	MOVE.L	savedRandomSeed1,randomSeed1
	MOVE.B	savedRandomSeed3,randomSeed3
	RTS

handleOpponentPositioning:
	MOVE.B	opponentID,D1
	MOVE.B	#$00,D2
	MOVE.B	D2,draftingTimer
	MOVE.B	opponentLateralPosition,D0
	MOVE.B	D0,opponentTargetLateralPosition
	SUB.B	playerLateralPosition,D0
	BCC	.positionDeltaOk
	NEG.B	D0
	SUBQ.B	#$01,D2
.positionDeltaOk:
	MOVE.B	D0,playerOpponentLateralDistance
	MOVE.B	D2,tempWord1
	MOVE.B	opponentDistance,D0
	BEQ	.opponentNear
	JMP	.opponentFar

.opponentNear:
	MOVE.B	opponentDistanceLow,D0
	CMP.B	#$40,D0
	BCC	.draftingOk
	TST.B	opponentAheadFlag
	BMI	.handleDrafting
	CMP.B	#$32,playerOpponentLateralDistance
	BCC	.draftingOk
.handleDrafting:
	SUBQ.B	#$01,draftingTimer
.draftingOk:
	CMP.B	#$10,D0
	BCC	.noCollision
	TST.B	networkGameMode
	BEQ	.networkOk
	TST.B	opponentDistanceOffset
	BNE	.noCollision
.networkOk:
	MOVE.B	playerOpponentLateralDistance,D0
	CMP.B	#$32,D0
	BCC	.noCollision
	MOVE.B	lateralRoadPosition,D0
	CMP.B	#$01,D0
	BCS	.collision
	BNE	.noCollision
	MOVE.B	speedMinor,D0
	CMP.B	#$80,D0
	BCC	.noCollision
.collision:
	JSR	calculateOpponentCollisionForces
	JMP	.opponentVeryClose

.noCollision:
	MOVE.B	#$00,D0
	MOVE.B	D0,opponentCollisionTimer
	MOVE.B	#$00,opponentCollisionActive
	MOVE.B	opponentDistanceLow,D0
	CMP.B	#$18,D0
	BCC	.opponentNotVeryClose
.opponentVeryClose:
	MOVE.L	#opponentBehaviorTraits,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$08,D0					; aggressive
	BEQ	.aggressive
	TST.B	opponentAheadFlag
	BMI	.aggressive
	MOVE.B	opponentDistanceLow,D0
	CMP.B	#$0E,D0
	BCC	.opponentFar
.aggressive:
	JSR	adjustOpponentPositionAggressive
	JMP	.applyLateralMovement

.opponentNotVeryClose:
	TST.B	opponentAheadFlag
	BMI	.standardWithoutLookahead
	CMP.B	#$32,D0
	BCC	.opponentFurtherAhead
	MOVE.L	#opponentBehaviorTraits,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$02,D0					; follow
	BEQ	.standardWithLookahead
	JSR	copyPlayerToOpponentPosition
	JMP	.scanUpcomingSegments

.opponentFurtherAhead:
	CMP.B	#$C8,D0
	BCC	.opponentFar
	MOVE.L	#opponentBehaviorTraits,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$20,D0					; overtake
	BEQ	.opponentFar
.standardWithLookahead:
	JSR	adjustOpponentPositionStandard
	JMP	.scanUpcomingSegments

.standardWithoutLookahead:
	JSR	adjustOpponentPositionStandard
	JMP	.applyLateralMovement

.opponentFar:
	MOVE.B	#$40,D2
	MOVE.L	#opponentBehaviorTraits,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$08,D0					; aggressive
	BEQ	.targetLateralPosOk1
	MOVE.B	#$6E,D2
.targetLateralPosOk1:
	MOVE.B	D1,D0
	AND.B	#$01,D0
	BEQ	.targetLateralPosOk2
	NOT.B	D2
.targetLateralPosOk2:
	MOVE.B	D2,opponentTargetLateralPosition
.scanUpcomingSegments:
	MOVE.B	#$02,D0
	MOVE.B	D0,tempByte2
	MOVE.B	opponentSegmentIndex,D1
	MOVE.B	D1,currentSegmentIndex
.scanUpcomingSegmentsLoop:
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$0F,D0
	MOVE.B	D0,D2
	MOVE.L	#geometryParameterTable,A2
	MOVE.B	$00(A2,D2.W),D0
	BPL	.targetLateralPosOk3
	MOVE.B	#$80,opponentTargetLateralPosition
.targetLateralPosOk3:
	JSR	advanceToNextSegment
	SUBQ.B	#$01,tempByte2
	BNE	.scanUpcomingSegmentsLoop
.applyLateralMovement:
	MOVE.B	aiMovementOverride,D0
	BMI	.moveLeft
	BNE	.moveRight
	MOVE.B	opponentTargetLateralPosition,D0
	SUB.B	opponentLateralPosition,D0
	BEQ	.done
	BCC	.moveRight
.moveLeft:
	CMP.B	#$F0,D0
	BCC	.done
	MOVE.B	#$FF,D0				; originally $F7
	BRA	.deltaOk			; originally BNE
.moveRight:
	CMP.B	#$10,D0
	BCS	.done
	MOVE.B	#$01,D0				; originally $09
.deltaOk:
	ADD.B	opponentLateralPosition,D0
	MOVE.B	aiEnabled,D2
	BEQ	.done
	CMP.B	#$E1,D0
	BCC	.done
	CMP.B	#$20,D0
	BCS	.done
	TST.B	networkGameMode
	BNE	.done
	MOVE.B	D0,opponentLateralPosition
.done:	RTS

adjustOpponentPositionAggressive:
	MOVE.B	playerOpponentLateralDistance,D0
	CMP.B	#$38,D0
	BCC	opponentTargetLateralPositionOk
	TST.B	tempWord1
	BMI	adjustOpponentRight
	BPL	adjustOpponentLeft
adjustOpponentPositionStandard:
	MOVE.B	playerOpponentLateralDistance,D0
	CMP.B	#$38,D0
	BCC	opponentTargetLateralPositionOk
	MOVE.B	playerLateralPosition,D0
	TST.B	tempWord1
	BMI	adjustOpponentRightUnlessFar
	CMP.B	#$A0,D0
	BCC	adjustOpponentRight
adjustOpponentLeft:
	MOVE.B	#$E0,D0
	MOVE.B	D0,opponentTargetLateralPosition
	RTS

adjustOpponentRightUnlessFar:
	CMP.B	#$60,D0
	BCS	adjustOpponentLeft
adjustOpponentRight:
	MOVE.B	#$20,D0
	MOVE.B	D0,opponentTargetLateralPosition
opponentTargetLateralPositionOk:
	RTS

copyPlayerToOpponentPosition:
	MOVE.B	playerLateralPosition,D0
	MOVE.B	D0,opponentTargetLateralPosition
	RTS

processOpponentLogic:
	MOVE.B	raceStartComplete,D0
	BEQ	lbC055356
	MOVE.B	crashRecoveryTimer,D0
	BNE	lbC055356
	MOVE.B	opponentSegmentIndex,D1
	JSR	loadTrackSegmentConfiguration
	JSR	calculateOpponentWheelForces
	JSR	processOpponentAI
	JSR	setAITargetSpeed
	JSR	applyOpponentCollisionAvoidance
	JSR	updateOpponentAcceleration
	MOVE.B	segmentOrientationAlternate,D0
	MOVE.B	D0,tempByte3
	MOVE.W	aiCurrentSpeed,D0
	MOVE.B	tempByte3,D3
	ASL.W	#$07,D3
	BCLR	#$0F,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC055304
	MULS	D2,D0
	ASR.L	#$08,D0
lbC055304:
	EXT.L	D0
	ASL.L	#$03,D0
	MOVE.B	D0,D3
	ASR.L	#$08,D0
	ADD.B	D3,opponentSpeedFractional
	BCC	lbC055318
	ADDQ.W	#$01,D0
lbC055318:
	ADD.W	D0,opponentSubSegmentProgress
	MOVE.B	opponentSubSegmentProgress,D0
	CMP.B	trackModeParameter,D0
	BCS	lbC055356
	SUB.B	trackModeParameter,D0
	MOVE.B	D0,opponentSubSegmentProgress
	MOVE.B	opponentSegmentIndex,D1
	ADDQ.B	#$01,D1
	CMP.B	numTrackSegments,D1
	BCS	lbC055350
	MOVE.B	#$00,D1
lbC055350:
	MOVE.B	D1,opponentSegmentIndex
lbC055356:
	RTS

initializeTrackCoordinates:
	JSR	setupTrackGeometryForFrame
	JSR	generateRandomNumber
	AND.W	#$007F,D0
	ADD.B	#$68,D0
	MOVE.L	#boundsMinX,A0
	MOVE.L	#opponentWheelPositions,A1
	MOVE.B	#$06,D1
lbC05537C:
	MOVE.W	$00(A0,D1.W),D3
	ADD.W	D0,D3
	MOVE.W	D3,$00(A1,D1.W)
	SUBQ.B	#$02,D1
	BPL	lbC05537C
	RTS

initializeTrackDifficultyParameters:
	TST.B	additionalPlayerCount
	BEQ	lbC0553A2
	TST.B	currentRaceNumber
	BNE	lbC055406
lbC0553A2:
	MOVE.W	#$00FF,D4
lbC0553A6:
	JSR	generateRandomNumber
	DBRA	D4,lbC0553A6
	CLR.W	D1
	MOVE.B	currentTrackID,D1
	MOVE.B	trackMetadataBuffer,D2
	TST.B	currentPlayerContext
	BEQ	lbC0553D2
	ADD.B	#$20,D1
	MOVE.B	trackDamageFrameBase,D2
lbC0553D2:
	MOVE.B	D2,damageFrameLimit
	JSR	generateRandomNumber
	MOVE.L	#lbW01172C,A0
	AND.B	$00(A0,D1.W),D0
	ADD.B	$08(A0,D1.W),D0
	MOVE.B	D0,aiLookAheadDistance
	JSR	generateRandomNumber
	AND.B	$10(A0,D1.W),D0
	ADD.B	$18(A0,D1.W),D0
	MOVE.B	D0,aiCorneringSkill
lbC055406:
	RTS

updateOpponentAcceleration:
	MOVE.W	#$0000,tempByte1
	MOVE.B	lbB00D4EF,D0
	ASL.B	#$01,D0
	MOVE.B	aiCurrentSpeed,D0
	BMI	lbC055494
	ROXL.B	#$01,D0
	TST.B	draftingTimer
	BPL	lbC055444
	TST.B	opponentAheadFlag
	BPL	lbC055444
	SUB.B	#$14,D0
	BCC	lbC055444
	MOVE.B	#$00,D0
lbC055444:
	MOVE.B	D0,tempByte3
	MOVE.B	aiCurrentSpeed,D0
	JSR	multiplyAndRandomize
	ASR.W	#$06,D3
	MOVE.W	D3,tempByte1
	MOVE.B	aiEnabled,D0
	BEQ	lbC055494
	MOVE.W	aiTargetSpeed,D0
	BMI	lbC055494
	MOVE.W	#$0000,D3
	MOVE.B	aiCurrentSpeed,D3
	SUB.W	D3,D0
	TST.B	segmentSteeringFlags
	BPL	lbC05548E
	SUB.W	D3,D0
	SUB.W	#$0023,D0
lbC05548E:
	MOVE.W	D0,aiTargetSpeed
lbC055494:
	MOVE.W	aiTargetSpeed,D0
	SUB.W	tempByte1,D0
	TST.B	aiEnabled
	BEQ	lbC0554E4
	MOVE.W	boundsMinX,D3
	ADD.W	boundsMaxX,D3
	LSR.W	#$01,D3
	SUB.W	boundsMinY,D3
	MOVE.W	D3,D4
	BPL	lbC0554C6
	NEG.W	D4
lbC0554C6:
	CMPI.W	#$0200,D4
	BCS	lbC0554D2
	MOVE.W	#$01FE,D4
lbC0554D2:
	LSR.W	#$01,D4
	MOVE.W	D4,D5
	ASR.W	#$02,D5
	ADD.W	D4,D5
	TST.W	D3
	BPL	lbC0554E2
	NEG.W	D5
lbC0554E2:
	ADD.W	D5,D0
lbC0554E4:
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC0554F0
	MULS	D2,D0
	ASR.L	#$08,D0
lbC0554F0:
	ADD.W	D0,aiCurrentSpeed
	BPL	lbC055502
	MOVE.W	#$0000,aiCurrentSpeed
lbC055502:
	RTS

setAITargetSpeed:
	MOVE.B	aiBaseSpeedHigh,D0
	MOVE.B	aiBaseSpeedLow,D2
	MOVE.B	aiActionTimer,D1
	BEQ	lbC05551E
	SUB.B	#$19,D0
lbC05551E:
	MOVE.B	aiEnabled,D1
	BNE	lbC05552E
	MOVE.B	#$00,D0
	MOVE.B	D0,D2
lbC05552E:
	MOVE.B	D0,aiTargetSpeedHigh
	MOVE.B	D2,aiTargetSpeed
	RTS

applyOpponentCollisionAvoidance:
	TST.B	aiEnabled
	BNE	.avoidCollisions
	RTS

.avoidCollisions:
	MOVE.B	opponentSegmentIndex,D1
	MOVE.L	#segmentVisibilityData,A0
	MOVE.B	$00(A0,D1.W),D0
	BMI	lbC05556C
	CMP.B	aiLookAheadDistance,D0
	BCS	lbC05556C
	MOVE.B	aiLookAheadDistance,D0
lbC05556C:
	AND.B	#$7F,D0
	MOVE.B	D0,collisionDistanceTemp
	MOVE.B	aiCurrentSpeed,D0
	SUB.B	collisionDistanceTemp,D0
	BCS	lbC0555A0
	BEQ	lbC0555D6
	MOVE.B	#$80,boundaryCollisionDirectionFlag
	NEG.W	aiTargetSpeed
	CMP.B	#$0E,D0
	BCS	lbC0555D4
lbC0555A0:
	MOVE.L	#segmentVisibilityData,A1
	TST.B	$00(A1,D1.W)
	BMI	lbC0555CE
	TST.B	D0
	BPL	lbC0555CE
	MOVE.B	boundaryCollisionDirectionFlag,D2
	BEQ	lbC0555CE
	CMP.B	#$FE,D0
	BCC	lbC0555D4
	BCLR	#$07,boundaryCollisionDirectionFlag
lbC0555CE:
	ASL.W	aiTargetSpeed
lbC0555D4:
	RTS

lbC0555D6:
	MOVE.B	#$80,boundaryCollisionDirectionFlag
	RTS

calculateOpponentCollisionForces:
	MOVE.B	raceStartComplete,D0
	BNE	lbC0555FA
	RTS

lbC0555F0:
	MOVE.B	#$03*FRAMERATE_MULTIPLIER,opponentCollisionTimer	; originally $03
	RTS

lbC0555FA:
	MOVE.B	aiEnabled,D0
	BEQ	lbC05560E
	MOVE.B	wheelMovementActive,D0
	BNE	lbC055654
lbC05560E:
	MOVE.W	carHeightPosition,D0
	SUB.W	opponentWheelPositions,D0
	MOVE.W	D0,D4
	ADD.W	#$0028,D0
	BPL	lbC055626
	NEG.W	D0
lbC055626:
	CMP.W	#$00C0,D0
	BGE	lbC0555F0
	TST.B	opponentCollisionTimer
	BEQ	lbC055654
	SUBQ.B	#$01,opponentCollisionTimer
	MOVE.W	#$0100,D3
	SUB.W	D0,D3
	TST.W	D4
	BPL	lbC05564C
	NEG.W	D3
lbC05564C:
	ASL.W	#$04,D3
	MOVE.W	D3,verticalOpponentCollisionForce
lbC055654:
	MOVE.B	playerOpponentLateralDistance,D0
	CMP.B	#$2D,D0
	BCC	lbC055688
	MOVE.B	opponentDistanceLow,D0
	CMP.B	#$08,D0
	BCC	lbC055688
	MOVE.B	#$08,D0
	TST.B	tempWord1
	BMI	lbC055682
	MOVE.B	#$F8,D0
lbC055682:
	MOVE.B	D0,lateralOpponentCollisionForce
lbC055688:
	TST.B	opponentCollisionActive
	BMI	lbC0556C2
	MOVE.W	#$0003,D3
	MOVE.W	#$0000,D0
	TST.B	crashRecoveryTimer
	BNE	lbC0556AA
	MOVE.W	aiCurrentSpeed,D0
lbC0556AA:
	SUB.W	carLocalVelocityZ,D0
	BPL	lbC0556B8
	MOVE.W	#$FFFD,D3
lbC0556B8:
	ASR.W	#$01,D0
	ADD.W	D3,D0
	MOVE.W	D0,forwardOpponentCollisionForce
lbC0556C2:
	MOVE.B	#$80,collisionActiveFlag
	MOVE.B	#$80,opponentCollisionActive
	tst.b	frameThrottleFlag				 ; added
	bmi	.skipCollisionDamage
	MOVE.W	#$0200,D3
	MOVE.W	lateralOpponentCollisionForce,D0
	BPL	.lateralForcePositive
	NEG.W	D0
.lateralForcePositive:
	ADD.W	D0,D3
	MOVE.W	verticalOpponentCollisionForce,D0
	BPL	.verticalForcePositive
	NEG.W	D0
.verticalForcePositive:
	ADD.W	D0,D3
	MOVE.W	forwardOpponentCollisionForce,D0
	BPL	.forwardForcePositive
	NEG.W	D0
.forwardForcePositive:
	ADD.W	D0,D3
	LSR.W	#$08,D3
	MOVE.L	#accumulatedForceFrontLeft,A0
	MOVE.W	#$0002,D2
.loop:	MOVE.B	$00(A0,D2.W),D0
	ADD.B	D3,D0
	BCC	.forceOk
	MOVE.B	#$FF,D0
.forceOk:
	MOVE.B	D0,$00(A0,D2.W)
	SUBQ.B	#$01,D2
	BPL	.loop
	MOVE.B	#$80,damageAccumulationActive
.skipCollisionDamage:					; added
	RTS

applyOpponentCollisionForces:
	TST.B	collisionSoundCooldown
	BEQ	lbC05573E
	SUBQ.B	#$01,collisionSoundCooldown
lbC05573E:
	TST.B	collisionActiveFlag
	BEQ	lbC0557DC
	MOVE.B	#$00,collisionActiveFlag
	MOVE.W	aiCurrentSpeed,D0
	SUB.W	forwardOpponentCollisionForce,D0
	BPL	lbC055764
	MOVE.W	#$0000,D0
lbC055764:
	MOVE.W	D0,aiCurrentSpeed
	MOVE.W	verticalOpponentCollisionForce,D0
	ASR.W	#$04,D0
	SUB.W	D0,opponentWheelVelocities
	SUB.W	D0,opponentRearLeftWheelVelocity
	SUB.W	D0,opponentRearRightWheelVelocity
	MOVE.W	lateralOpponentCollisionForce,D0
	ADD.W	D0,rollSpringAngle
	MOVE.W	verticalOpponentCollisionForce,D0
	ADD.W	D0,pitchSpringAngle
	MOVE.W	forwardOpponentCollisionForce,D0
	ADD.W	D0,yawSpringAngle
	MOVE.W	#$0000,lateralOpponentCollisionForce
	MOVE.W	#$0000,verticalOpponentCollisionForce
	MOVE.W	#$0000,forwardOpponentCollisionForce
	TST.B	collisionSoundCooldown
	BNE	lbC0557DC
	MOVE.B	#$02,D0				; car collision
	JSR	playSample
	MOVE.B	#$05*FRAMERATE_MULTIPLIER,collisionSoundCooldown	; originally $05
lbC0557DC:
	RTS

calculateOpponentWheelForces:
	MOVE.W	#$8000,minBoundaryDistance
	MOVE.W	#$0028,D0
	TST.B	segmentSteeringFlags
	BPL	lbC0557FC
	MOVE.W	#$007C,D0
lbC0557FC:
	MOVE.W	D0,tempWord2
	MOVE.W	#$0000,D7
	MOVE.W	boundsMinX,D0
	SUB.W	opponentWheelPositions,D0
	CMP.W	minBoundaryDistance,D0
	BLT	lbC055822
	MOVE.W	D0,minBoundaryDistance
lbC055822:
	ADD.W	tempWord2,D0
	BPL	lbC055838
	CMP.W	#$FFA0,D0
	BCC	lbC055838
	MOVE.W	#$FFA0,D0
lbC055838:
	MOVE.W	D0,D6
	SUB.W	opponentFrontWheelHeightPrev,D0
	JSR	applyMomentumAmplification
	BPL	lbC05584E
	MOVE.W	#$0000,D0
lbC05584E:
	CMP.W	#$0400,D0
	BLT	lbC05585A
	MOVE.W	#$03FF,D0
lbC05585A:
	OR.W	D0,D7
	SUB.W	tempWord2,D0
	MOVE.W	D0,opponentFrontWheelAccel
	MOVE.W	D6,opponentFrontWheelHeightPrev
	MOVE.W	boundsMaxX,D0
	SUB.W	opponentRearLeftWheelPosition,D0
	CMP.W	minBoundaryDistance,D0
	BLT	lbC05588A
	MOVE.W	D0,minBoundaryDistance
lbC05588A:
	ADD.W	tempWord2,D0
	BPL	lbC0558A0
	CMP.W	#$FFA0,D0
	BCC	lbC0558A0
	MOVE.W	#$FFA0,D0
lbC0558A0:
	MOVE.W	D0,D6
	SUB.W	opponentWheelHeightRL,D0
	JSR	applyMomentumAmplification
	BPL	lbC0558B6
	MOVE.W	#$0000,D0
lbC0558B6:
	CMP.W	#$0400,D0
	BLT	lbC0558C2
	MOVE.W	#$03FF,D0
lbC0558C2:
	OR.W	D0,D7
	SUB.W	tempWord2,D0
	MOVE.W	D0,opponentWheelAccelerationRL
	MOVE.W	D6,opponentWheelHeightRL
	MOVE.W	boundsMinY,D0
	SUB.W	opponentRearRightWheelPosition,D0
	CMP.W	minBoundaryDistance,D0
	BLT	lbC0558F2
	MOVE.W	D0,minBoundaryDistance
lbC0558F2:
	ADD.W	tempWord2,D0
	BPL	lbC055908
	CMP.W	#$FFA0,D0
	BCC	lbC055908
	MOVE.W	#$FFA0,D0
lbC055908:
	MOVE.W	D0,D6
	SUB.W	opponentWheelHeightRR,D0
	JSR	applyMomentumAmplification
	BPL	lbC05591E
	MOVE.W	#$0000,D0
lbC05591E:
	CMP.W	#$0400,D0
	BLT	lbC05592A
	MOVE.W	#$03FF,D0
lbC05592A:
	OR.W	D0,D7
	SUB.W	tempWord2,D0
	MOVE.W	D0,opponentWheelAccelerationRR
	MOVE.W	D6,opponentWheelHeightRR
	MOVE.W	D7,D0
	ASR.W	#$08,D0
	OR.B	D7,D0
	MOVE.B	D0,aiEnabled
	MOVE.W	opponentFrontWheelAccel,D4
	ADD.W	opponentWheelAccelerationRL,D4
	ADD.W	opponentWheelAccelerationRR,D4
	MOVE.W	opponentFrontWheelAccel,D7
	ASL.W	#$02,D7
	MOVE.W	D4,D0
	ADD.W	opponentFrontWheelAccel,D0
	ADD.W	D7,D0
	ASR.W	#$03,D0
	MOVE.W	D0,opponentWheelForceTotal
	MOVE.W	opponentWheelAccelerationRL,D7
	ASL.W	#$02,D7
	MOVE.W	D4,D0
	ADD.W	opponentWheelAccelerationRL,D0
	ADD.W	D7,D0
	ASR.W	#$03,D0
	MOVE.W	D0,opponentWheelForceRL
	MOVE.W	opponentWheelAccelerationRR,D7
	ASL.W	#$02,D7
	MOVE.W	D4,D0
	ADD.W	opponentWheelAccelerationRR,D0
	ADD.W	D7,D0
	ASR.W	#$03,D0
	MOVE.W	D0,opponentWheelForceRR
	MOVE.B	opponentID,D1
	MOVE.L	#opponentBehaviorTraits,A0
	MOVE.B	$00(A0,D1.W),D0
	AND.B	#$04,D0
	BEQ	lbC0559EC
	MOVE.W	opponentRearRightWheelVelocity,D0
	OR.W	opponentWheelForceRR,D0
	AND.W	#$FFFC,D0
	BNE	lbC0559EC
	JSR	generateRandomNumber
	AND.B	#$0F,D0
	BNE	lbC0559EC
	MOVE.W	#$00A0,opponentRearRightWheelVelocity
lbC0559EC:
	MOVE.W	opponentWheelForceTotal,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC0559FE
	MULS	D2,D0
	ASR.L	#$08,D0
lbC0559FE:
	ADD.W	opponentWheelVelocities,D0
	MOVE.W	D0,opponentWheelVelocities
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC055A16
	MULS	D2,D0
	ASR.L	#$08,D0
lbC055A16:
	ASR.W	#$01,D0
	ADD.W	D0,opponentWheelPositions
	MOVE.W	opponentWheelForceRL,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC055A30
	MULS	D2,D0
	ASR.L	#$08,D0
lbC055A30:
	ADD.W	opponentRearLeftWheelVelocity,D0
	MOVE.W	D0,opponentRearLeftWheelVelocity
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC055A48
	MULS	D2,D0
	ASR.L	#$08,D0
lbC055A48:
	ASR.W	#$01,D0
	ADD.W	D0,opponentRearLeftWheelPosition
	MOVE.W	opponentWheelForceRR,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC055A62
	MULS	D2,D0
	ASR.L	#$08,D0
lbC055A62:
	ADD.W	opponentRearRightWheelVelocity,D0
	MOVE.W	D0,opponentRearRightWheelVelocity
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC055A7A
	MULS	D2,D0
	ASR.L	#$08,D0
lbC055A7A:
	ASR.W	#$01,D0
	ADD.W	D0,opponentRearRightWheelPosition
	MOVE.W	#$0128,tempWord1
	MOVE.B	#$00,D1
	MOVE.B	#$02,D2
	JSR	updateOpponentWheelSuspension
	MOVE.W	#$0170,tempWord1
	MOVE.B	#$00,D1
	TST.W	D4
	BPL	lbC055AAC
	ADDQ.B	#$02,D1
lbC055AAC:
	MOVE.B	#$04,D2
	JSR	updateOpponentWheelSuspension
convertOpponentWheelsToCarFootprint:
	MOVE.W	opponentWheelPositions,inputCoordX1
	ADD.W	#$0050,inputCoordX1
	MOVE.W	opponentRearLeftWheelPosition,inputCoordX2
	ADD.W	#$0050,inputCoordX2
	MOVE.W	opponentRearRightWheelPosition,inputCoordY1
	ADD.W	#$0050,inputCoordY1
	MOVE.W	inputCoordX2,D0
	SUB.W	inputCoordX1,D0
	ASR.W	#$01,D0
	MOVE.W	inputCoordY1,D3
	ADD.W	D0,D3
	MOVE.W	D3,inputCoordY2
	MOVE.W	inputCoordY1,D3
	SUB.W	D0,D3
	MOVE.W	D3,inputCoordY1
	RTS

calculateWheelDistance:
	MOVE.L	#opponentWheelPositions,A0
	MOVE.W	$00(A0,D1.W),D0
	SUB.W	$00(A0,D2.W),D0
	MOVE.W	D0,D4
	TST.W	D0
	BPL	.distancePositive
	NEG.W	D0
.distancePositive:
	RTS

updateOpponentWheelSuspension:
	MOVE.L	#opponentWheelVelocities,A4
	MOVE.B	D1,wheelDataOffset
	JSR	calculateWheelDistance
	MOVE.W	tempWord1,D3
	SUB.W	D0,D3
	BPL	.wheelDistanceOk
	TST.W	D4
	BPL	.wheelToAdjustSelected
	MOVE.B	D2,D1
.wheelToAdjustSelected:
	MOVE.L	#opponentWheelPositions,A0
	ADD.W	D3,$00(A0,D1.W)			 
	CMP.B	#$04,D2
	BEQ	.fullAveraging
	MOVE.B	#$00,D1				 
	JMP	averageWheelVelocities

.fullAveraging:
	MOVE.B	#$00,D1
	MOVE.B	#$02,D2
	JSR	averageWheelVelocities
	MOVE.B	#$04,D1
	JSR	averageWheelVelocities
	MOVE.B	#$00,D1
	JSR	averageWheelVelocities
	MOVE.B	#$04,D2
	MOVE.B	wheelDataOffset,D1
.wheelDistanceOk:
	CMP.B	#$04,D2
	BNE	.dampingDone
	MOVE.B	aiEnabled,D0
	BNE	.dampingDone
;	TST.B	tempByte1			; removed: nop code
;	BMI	lbC055BBC
;lbC055BBC:
	MOVE.W	$00(A4,D1.W),D0
	SUB.W	$0004(A4),D0
	BMI	.applyDamping
	CMP.W	#$0010,D0
	BGE	.dampingDone
.applyDamping:
	MOVE.B	#$04,D1
	MOVE.L	#opponentSuspensionDampingTable,A0
.wheelLoop:
	MOVE.W	$00(A0,D1.W),D0
	ADD.W	D0,$00(A4,D1.W)
	SUBQ.B	#$02,D1
	BPL	.wheelLoop
.dampingDone:
	RTS

averageWheelVelocities:
	MOVE.W	$00(A4,D1.W),D0
	ADD.W	$00(A4,D2.W),D0
	ASR.W	#$01,D0
	MOVE.W	D0,$00(A4,D1.W)
	MOVE.W	D0,$00(A4,D2.W)
	RTS

initializeLookupTables:
	MOVE.B	#$FF,D0
	MOVE.L	#trackSegmentGrid,A0
	MOVE.W	#$0000,D1
lbC055C12:
	MOVE.B	D0,$00(A0,D1.W)
	SUBQ.B	#$01,D1
	BNE	lbC055C12
	MOVE.L	#trackSegmentCoordinates,A1
lbC055C22:
	MOVE.B	$00(A1,D1.W),D2
	MOVE.B	D1,$00(A0,D2.W)
	ADDQ.B	#$01,D1
	CMP.B	numTrackSegments,D1
	BNE	lbC055C22
	RTS

lbC055C38:
	JSR	renderCharacter
	ADDQ.B	#$01,D1
renderLeagueText:
	MOVE.L	#leagueTextTable,A1
	MOVE.B	$00(A1,D1.W),D0
	CMP.B	#$FF,D0
	BNE	lbC055C38
	RTS

fadeToColor:
	MOVE.W	D0,palette
	MOVE.B	#$1E,framesToWaitWhenFading
	MOVE.L	#palette,A0
	MOVE.W	#$001E,D4
lbC055D66:
	MOVE.W	(A0),$20(A0,D4.W)
	SUBQ.W	#$02,D4
	BPL	lbC055D66
animatePaletteToTarget:
	MOVE.L	#palette,A0
	MOVE.W	#$001E,D4
	MOVE.B	#$00,D7
lbC055D7E:
	MOVE.B	$20(A0,D4.W),D0
	AND.B	#$0F,D0
	MOVE.B	$00(A0,D4.W),D3
	AND.B	#$0F,D3
	CMP.B	D3,D0
	BEQ	lbC055D9E
	BGT	lbC055D9A
	SUBQ.B	#$02,D3
lbC055D9A:
	ADDQ.B	#$01,D3
	ADDQ.B	#$01,D7
lbC055D9E:
	MOVE.B	D3,$00(A0,D4.W)
	MOVE.B	$21(A0,D4.W),D0
	LSR.B	#$04,D0
	MOVE.B	$01(A0,D4.W),D3
	LSR.B	#$04,D3
	CMP.B	D3,D0
	BEQ	lbC055DBE
	BGT	lbC055DBA
	SUBQ.B	#$02,D3
lbC055DBA:
	ADDQ.B	#$01,D3
	ADDQ.B	#$01,D7
lbC055DBE:
	MOVE.B	$01(A0,D4.W),D0
	AND.B	#$0F,D0
	ASL.B	#$04,D3
	OR.B	D3,D0
	MOVE.B	D0,$01(A0,D4.W)
	MOVE.B	$21(A0,D4.W),D0
	AND.B	#$0F,D0
	MOVE.B	$01(A0,D4.W),D3
	AND.B	#$0F,D3
	CMP.B	D3,D0
	BEQ	lbC055DEE
	BGT	lbC055DEA
	SUBQ.B	#$02,D3
lbC055DEA:
	ADDQ.B	#$01,D3
	ADDQ.B	#$01,D7
lbC055DEE:
	MOVE.B	$01(A0,D4.W),D0
	AND.B	#$F0,D0
	OR.B	D3,D0
	MOVE.B	D0,$01(A0,D4.W)
	SUBQ.W	#$02,D4
	BPL	lbC055D7E
	TST.B	D7
	BEQ	lbC055E24
	JSR	copyPaletteToCopperlist
	MOVE.B	#$02,framesToWait
lbC055E16:
	TST.B	framesToWait
	BNE	lbC055E16
	BRA	animatePaletteToTarget

lbC055E24:
	TST.B	framesToWaitWhenFading
	BNE	lbC055E24
	RTS

displayMenuScreen:
	clr.b	frameProcessingFlag		; added
	MOVE.W	imageMenuScreenPalette,D0
	JSR	fadeToColor
	MOVE.B	#$80,singleBufferRenderMode
	MOVE.L	frameBuffers,D0
	MOVE.L	D0,renderFrameBuffer
	ADD.L	#$00007D00,D0
	MOVE.L	D0,displayFrameBuffer
	JSR	setupFrameBufferAddresses
	MOVE.L	#imageMenuScreenPalette,A1
	JSR	copyPalette
	MOVE.L	#imageMenuScreen,A1
	MOVE.L	frameBuffers,A0
	MOVE.L	A0,A3
	ADD.L	#$00001F40,A3
	MOVE.L	displayFrameBuffer,A4
.copyImageLoop:
	MOVE.W	(A1),(A4)+
	MOVE.W	(A1)+,(A0)+
	MOVE.W	(A1),$1F3E(A4)
	MOVE.W	(A1)+,$1F3E(A0)
	MOVE.W	(A1),$3E7E(A4)
	MOVE.W	(A1)+,$3E7E(A0)
	MOVE.W	(A1),$5DBE(A4)
	MOVE.W	(A1)+,$5DBE(A0)
	CMP.L	A3,A0
	BNE	.copyImageLoop
	MOVE.B	#$41,displayUpdateFlag
	JSR	renderDivisionBackgroundAndHeader
	JSR	copyFirstFrameBufferToSecond
	JMP	animatePaletteToTarget

renderDivisionBackgroundAndHeader:
	MOVE.B	currentDivision,D0
	MOVE.B	D0,displayTrackID
	JSR	drawScreenFrame
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	TST.B	suppressMenuTextFlag
	BNE	.skipTextRendering
	TST.B	textRenderingFlag
	BEQ	.beginHeaderRendering
.skipTextRendering:
	RTS

.beginHeaderRendering:
	TST.B	additionalPlayerCount
	BNE	.renderMultiplayerHeader
	MOVE.B	#$09,D2
	MOVE.B	currentPlayerContext,D0
	BEQ	.renderPlayer1Division
	MOVE.B	D2,lbB04C057
	MOVE.B	#$BB,D1
	JSR	renderTextString
	JMP	.renderDivisionNumber

.renderPlayer1Division:
	MOVE.B	D2,lbB055C56
	MOVE.B	#$00,D1
	JSR	renderLeagueText
.renderDivisionNumber:
	MOVE.B	#$04,D0
	SUB.B	displayTrackID,D0
	JSR	renderDigit
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	RTS

.renderMultiplayerHeader:
	MOVE.B	#$A0,D1
	JMP	renderMenuString

displayRaceMatchupScreenAlt:
	MOVE.B	#$80,D0
	BRA	renderMatchupScreenCommon

displayRaceMatchupScreen:
	MOVE.B	#$00,D0
renderMatchupScreenCommon:
	MOVE.B	D0,raceMatchupScreenTypeFlag
	JSR	renderDivisionBackgroundAndHeader
	MOVE.B	displayTrackID,D0
	ASL.B	#$01,D0
	MOVE.B	D0,tempByte4
	MOVE.B	currentRaceNumber,D0
	TST.B	additionalPlayerCount
	BEQ	.calculateRaceConfigIndex
	MOVE.B	remainingRaces,D0
	EOR.B	#$01,D0
.calculateRaceConfigIndex:
	AND.B	#$01,D0
	ADD.B	tempByte4,D0
	MOVE.B	D0,D1
	JSR	setCurrentTrackID
	BTST	#$00,displayFlags
	BNE	.renderSimplifiedTrackInfo
	JMP	renderPreRaceMatchupScreen

.renderSimplifiedTrackInfo:
	MOVE.B	#$0B,D2
	JSR	renderTrackInfoDisplay
	JSR	displayRecordAchievements
	JMP	presentFrameBufferAndWaitForFire

displayPostRaceStandings:
	JSR	renderDivisionBackgroundAndHeader
	JSR	updateLeagueStandingsAfterRace
	JMP	presentFrameBufferAndWaitForFire

configureRaceSetup:
	JSR	setupGameConfiguration
	MOVE.B	trackBaseOffset,renderingIndex
	TST.B	additionalPlayerCount
	BEQ	.singlePlayer
	JSR	displayLeagueRaceResults
	BRA	presentFrameBufferAndWaitForFire

.singlePlayer:
	JSR	renderDivisionBackgroundAndHeader
	JMP	displayLeagueStandingsTable

renderStandingsEntry:
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
	MOVE.B	renderingIndex,D2
	MOVE.L	#sortedRaceStandings,A2
	MOVE.B	$00(A2,D2.W),D1
	MOVE.B	D1,tempByte5
	JSR	renderPlayerName
	JSR	renderSpace
	MOVE.B	tempByte5,D1
	TST.B	multiplayerRaceDisplayFlag
	BPL	lbC05606E
	JSR	renderLapTime
	JSR	renderTwoSpaces
	ADD.B	#$0C,D1
	JSR	renderLapTime
	BRA	lbC0560B4

lbC05606E:
	MOVE.L	#raceParticipationCounters,A1
	MOVE.B	$00(A1,D1.W),D0
	JSR	renderDecimal
	MOVE.L	#playerRaceWins,A1
	MOVE.B	$00(A1,D1.W),D0
	JSR	renderPaddedDecimal
	MOVE.L	#playerSecondPlaceFinishes,A1
	MOVE.B	$00(A1,D1.W),D0
	JSR	renderPaddedDecimal
	JSR	renderThreeSpaces
	MOVE.L	#playerRankingScores,A1
	MOVE.B	$00(A1,D1.W),D0
	JSR	renderDecimal
lbC0560B4:
	ADDQ.B	#$01,renderingIndex
	MOVE.B	renderingIndex,D0
	CMP.B	maxRenderingIndex,D0
	RTS

;	MOVE.B	#$07,D0					; removed: dead code
;	JSR	displayPlayerMatchupScreen
;	MOVE.B	#$60,D1
;	JSR	renderLeagueText
;	JSR	renderMenuCursorAndAdvance
;	MOVE.B	#$6A,D1
;	JSR	renderLeagueText
;	MOVE.B	lbB00E325,D1
;	JSR	renderPlayerName
;	MOVE.B	#$E9,D1
;	JSR	renderLeagueText
;	JSR	renderMenuCursorAndAdvance
;	MOVE.B	#$78,D1
;	JSR	renderLeagueText
;	MOVE.B	lbB00E326,D1
;	JSR	renderPlayerName
;	MOVE.B	#$EF,D1
;	JSR	renderLeagueText
presentFrameBufferAndWaitForFire:
	JSR	copyFirstFrameBufferToSecond
	JSR	waitForFireButtonPress
resetTextYOffset:
	MOVE.B	#$00,textYOffset
	RTS

copyFirstFrameBufferToSecond:
	MOVE.L	frameBuffers,A0
	ADD.L	#$00000B6C,A0
	ADD.L	#$FFFFFEC0,A0
	MOVE.L	A0,A3
	ADD.L	#$00007D00,A3
	MOVE.W	#$007E,D4
.yLoop:	MOVE.W	#$000D,D3
.xLoop:	MOVE.W	(A0)+,(A3)+
	MOVE.W	$1F3E(A0),$1F3E(A3)
	MOVE.W	$3E7E(A0),$3E7E(A3)
	MOVE.W	$5DBE(A0),$5DBE(A3)
	DBRA	D3,.xLoop
	ADD.L	#$0000000C,A0
	ADD.L	#$0000000C,A3
	DBRA	D4,.yLoop
	RTS

waitForFireButtonPress:
	JSR	readControllerInput
	AND.B	#$10,D0
	BNE	waitForFireButtonPress
	MOVE.B	#$05,D2
	JSR	delayWithParam
lbC0561A2:
	JSR	readControllerInput
	AND.B	#$10,D0
	BEQ	lbC0561A2
	RTS

initializeRaceMode:
	TST.B	additionalPlayerCount
	BNE	configureRaceSetup
	JMP	displaySinglePlayerResults

displayPlayerMatchupScreen:
	MOVE.B	D0,currentMenuItem
	JSR	configurePlayersAndCars
	JSR	renderMenuCursorAndAdvance
	MOVE.B	player1ID,D1
	JSR	renderPlayerName
	MOVE.B	#$28,D1
	JSR	renderLeagueText
	MOVE.B	player2ID,D1
	JSR	renderPlayerName
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	JMP	resetTextYOffset

updateLeagueStandingsAfterRace:
	MOVE.B	#$80,alternateEndScreenEnabledFlag
	MOVE.B	#$0B,D1
	MOVE.L	#leagueStandingsTable,A0
	MOVE.L	#sortedRaceStandings,A1
.copyStandingsLoop:
	MOVE.B	$00(A1,D1.W),$00(A0,D1.W)
	SUBQ.B	#$01,D1
	BPL	.copyStandingsLoop
	JSR	setupGameConfiguration
	MOVE.B	#$0F,D1
	MOVE.B	#$0C,D2
	JSR	setTextPosition
	MOVE.B	#$D7,D1
	JSR	renderLeagueText
	MOVE.B	#$01,D0
	MOVE.B	D0,currentMenuItem
	MOVE.B	trackBaseOffset,D2
	BNE	.displayWinnerText
	MOVE.B	sortedRaceStandings,D0
	CMP.B	currentPlayerID,D0
	BNE	.displayRelegationText
	MOVE.B	currentPlayerContext,D0
	BEQ	.displayWinnerText
	JSR	renderMenuCursorAndAdvance
	MOVE.B	#$CE,D1
	JSR	renderTextString
	JMP	.startPromotionSequence

.displayWinnerText:
	JSR	renderMenuCursorAndAdvance
	MOVE.B	#$B7,D1
	JSR	renderLeagueText
	MOVE.B	trackBaseOffset,D2
	MOVE.L	#sortedRaceStandings,A2
	MOVE.B	$00(A2,D2.W),D1
	CMP.B	currentPlayerID,D1
	BNE	.endScreenFlagOk
	MOVE.B	D1,alternateEndScreenEnabledFlag
.endScreenFlagOk:
	JSR	renderPlayerName
	MOVE.B	trackBaseOffset,D2
	BNE	.displayRelegationText
	JSR	renderMenuCursorAndAdvance
	MOVE.B	#$A7,D1
	JSR	renderTextString
	JMP	.startPromotionSequence

.displayRelegationText:
	MOVE.B	maxRenderingIndex,D2
	SUBQ.B	#$01,D2
	CMP.B	#$0B,D2
	BEQ	.startPromotionSequence
	JSR	renderMenuCursorAndAdvance
	MOVE.B	#$C7,D1
	JSR	renderLeagueText
	MOVE.B	maxRenderingIndex,D2
	SUBQ.B	#$01,D2
	MOVE.L	#sortedRaceStandings,A2
	MOVE.B	$00(A2,D2.W),D1
	JSR	renderPlayerName
.startPromotionSequence:
	MOVE.B	#$02,D0
	MOVE.B	D0,displayTrackID
.promoteWinnerLoop:
	JSR	setupGameConfiguration
	MOVE.B	trackBaseOffset,D2
	MOVE.L	#leagueStandingsTable,A0
	MOVE.B	$00(A0,D2.W),D1
	MOVE.B	-$01(A0,D2.W),$00(A0,D2.W)
	MOVE.B	D1,-$01(A0,D2.W)
	SUBQ.B	#$01,displayTrackID
	BPL	.promoteWinnerLoop
	MOVE.B	currentPlayerID,D0
	CMP.B	sortedRaceStandings,D0
	BNE	.handleNonChampionship
	MOVE.B	currentPlayerContext,D1
	BNE	.handleChampionshipWon
	MOVE.B	D0,currentPlayerContext
	MOVE.L	#leagueStandingsTable,A0
	MOVE.B	#$0B,D1
.resetStandingsForChampionship:
	MOVE.B	D1,$00(A0,D1.W)
	SUBQ.B	#$01,D1
	BPL	.resetStandingsForChampionship
	MOVE.B	#$00,D0
	BRA	.setNextTrackSelection

.handleNonChampionship:
	JSR	findPlayerInStandings
	MOVE.L	#lbL0563C6,A1
	MOVE.B	$00(A1,D1.W),D0
.setNextTrackSelection:
	MOVE.B	D0,currentDivision
	BEQ	.handleChampionshipWon
	RTS

.handleChampionshipWon:
;	MOVE.B	#$06,D0				; fixed unnecessarily complex way to set a value to 10
;	ASL.B	#$01,D0
;	SUBQ.B	#$02,D0
;	MOVE.B	D0,holeRenderingPosition
	MOVE.B	#$0A,holeRenderingPosition
	RTS

findPlayerInStandings:
	MOVE.B	#$0B,D1
searchStandingsLoop:
	MOVE.L	#leagueStandingsTable,A1
	CMP.B	$00(A1,D1.W),D0
	BEQ	.searchComplete
	SUBQ.B	#$01,D1
	BPL	searchStandingsLoop
.searchComplete:
	RTS

renderMenuCursorAndAdvance:
	MOVE.B	#$02,D0
renderMenuCursorAndAdvanceMultiSegment:
	SUBQ.B	#$02,D0
	MOVE.B	D0,lbB00D554
	MOVE.B	#$1F,D0
	JSR	renderCharacter
	MOVE.B	#$05,D0
	JSR	renderCharacter
	MOVE.B	currentMenuItem,D1
	MOVE.L	#lbL0563F4,A0
	MOVE.B	$00(A0,D1.W),D0
	MOVE.B	D0,displayRowOffset
	JSR	renderCharacter
	CLR.W	D4
	MOVE.B	menuCursorObjectType,D4
	ASL.W	#$02,D4
	MOVE.L	#imageMenuScreen,A0
	SUB.L	#$00000500,A0
	MOVE.L	#lbL05651A,A1
	ADD.L	$00(A1,D4.W),A0
	MOVE.L	renderFrameBuffer,A3
	ADD.L	#$FFFFFEC0,A3
	MOVE.W	#$0028,D3
	AND.W	#$00FF,D0
	MULU	D3,D0
	ASL.L	#$03,D0
	SUB.L	#$00000028,D0
	ADD.L	D0,A3
	ADD.L	#$00000004,A3
	MOVE.L	A0,A2
	ADD.L	#$000000A0,A2
	MOVE.L	A3,A4
	ADD.L	#$00000028,A4
	MOVE.W	#$0010,D4
	CMP.B	#$03,menuCursorObjectType
	BNE	.renderNextSegment
	MOVE.W	#$0018,D4
.renderNextSegment:
	MOVE.W	#$000D,D3
.copyRow:
	MOVE.W	(A0)+,(A3)+
	MOVE.W	(A0)+,$1F3E(A3)
	MOVE.W	(A0)+,$3E7E(A3)
	MOVE.W	(A0)+,$5DBE(A3)
	DBRA	D3,.copyRow
	ADD.L	#$00000030,A0
	ADD.L	#$0000000C,A3
	DBRA	D4,.renderNextSegment
	SUBQ.B	#$01,lbB00D554
	BMI	.finishMenuLineSetup
	MOVE.L	A2,A0
	ADD.L	#$00000140,A4
	MOVE.L	A4,A3
	MOVE.W	#$000F,D4
	BRA	.renderNextSegment

.finishMenuLineSetup:
	MOVE.B	#$02,menuCursorObjectType
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
	ADDQ.B	#$01,currentMenuItem
setTextYOffset4:
	MOVE.B	#$04,textYOffset
	RTS

renderPlayerName:
	MOVE.L	#playerNamesWithSpaces,A0
	MOVE.B	#$0D,D2
	JMP	lbC056548

renderTrackName:
	MOVE.L	#trackNames,A0
	MOVE.B	#$0F,D2
lbC056548:
	MOVE.B	D2,tempByte4
	ASL.B	#$04,D1
	MOVE.B	#$00,D2
lbC056554:
	MOVE.B	$00(A0,D1.W),D0
	JSR	renderCharacter
	ADDQ.B	#$01,D1
	ADDQ.B	#$01,D2
	CMP.B	tempByte4,D2
	BNE	lbC056554
	RTS

drawScreenFrame:
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.B	#$03,D0
	JSR	setForegroundColor
	MOVE.B	#$80,textTransparencyMode
	MOVE.L	renderFrameBuffer,A0
	ADD.L	#$FFFFFEC0,A0
	ADD.L	#$00000B6C,A0
	MOVE.L	A0,A3
	ADD.L	#$000013D8,A3
	MOVE.B	#$03,D0
	JSR	setupBitplaneMasks
	MOVE.W	D6,D1
	SWAP	D6
	MOVE.W	D7,D2
	SWAP	D7
	MOVE.W	#$0001,D4
lbC0565BA:
	ADD.L	#$00000004,A0
	MOVE.W	#$000B,D3
lbC0565C4:
	MOVE.W	D6,(A0)+
	MOVE.W	D1,$1F3E(A0)
	MOVE.W	D7,$3E7E(A0)
	MOVE.W	D2,$5DBE(A0)
	DBRA	D3,lbC0565C4
	ADD.L	#$0000000C,A0
	DBRA	D4,lbC0565BA
lbC0565E0:
	MOVE.W	#$000D,D3
lbC0565E4:
	MOVE.W	D6,(A0)+
	MOVE.W	D1,$1F3E(A0)
	MOVE.W	D7,$3E7E(A0)
	MOVE.W	D2,$5DBE(A0)
	DBRA	D3,lbC0565E4
	ADD.L	#$0000000C,A0
	CMP.L	A3,A0
	BLT	lbC0565E0
	CLR.W	D1
	CLR.W	D2
	RTS

calculateSine:
	MOVE.W	#$0000,D5
	BRA	lbC056614

calculateCosine:
	MOVE.W	#$4000,D5
lbC056614:
	MOVE.L	#sineTable,A0
	MOVE.W	D0,D3
	AND.W	#$3FFF,D3
	MOVE.W	D0,D6
	AND.W	#$4000,D6
	EOR.W	D5,D6
	BNE	lbC056632
	EOR.W	#$3FFF,D3
	ADDQ.W	#$01,D3
lbC056632:
	ROR.W	#$05,D3
	MOVE.W	D3,D4
	AND.W	#$03FE,D4
	MOVE.W	$00(A0,D4.W),D6
	SUB.W	$02(A0,D4.W),D6
	ROR.W	#$01,D3
	AND.W	#$FC00,D3
	MULU	D3,D6
	SWAP	D6
	MOVE.W	$00(A0,D4.W),D7
	SUB.W	D6,D7
	LSR.W	#$01,D7
	MOVE.W	D0,D3
	AND.W	D5,D3
	ASL.W	#$01,D3
	EOR.W	D3,D0
	BPL	lbC056662
	NEG.W	D7
lbC056662:
	MOVE.W	D7,D0
	RTS

calculateDivision:
	MOVE.L	#reciprocalTable,A0
	MOVE.W	D0,D4
	BPL	lbC056674
	NEG.W	D0
lbC056674:
	MOVE.W	D3,D5
	BPL	lbC05667C
	NEG.W	D3
lbC05667C:
	CMP.W	D0,D3
	BNE	lbC05668E
	MOVE.W	#$FFFF,D7
	MOVE.W	#$2000,D0
	BRA	lbC0566D2

lbC05668E:
	BGT	lbC0566C0
	SWAP	D3
	CLR.W	D3
	DIVU	D0,D3
	MOVE.W	D3,D7
	LSR.W	#$04,D3
	AND.B	#$FE,D3
	MOVE.W	$00(A0,D3.W),D0
	MOVE.W	D4,D3
	EOR.W	D5,D3
	BMI	lbC0566AE
	NEG.W	D0
lbC0566AE:
	MOVE.W	#$4000,D3
	TST.W	D4
	BPL	lbC0566BC
	MOVE.W	#$C000,D3
lbC0566BC:
	ADD.W	D3,D0
	RTS

lbC0566C0:
	SWAP	D0
	CLR.W	D0
	DIVU	D3,D0
	MOVE.W	D0,D7
	LSR.W	#$04,D0
	AND.B	#$FE,D0
	MOVE.W	$00(A0,D0.W),D0
lbC0566D2:
	MOVE.W	D4,D3
	EOR.W	D5,D3
	BPL	lbC0566DC
	NEG.W	D0
lbC0566DC:
	TST.W	D5
	BPL	lbC0566E6
	ADD.W	#$8000,D0
lbC0566E6:
	RTS

calculateVectorMagnitude:
	MOVE.L	#arctanTable,A0
	TST.W	D4
	BPL	.xPositive
	NEG.W	D4
.xPositive:
	TST.W	D5
	BPL	.yPositive
	NEG.W	D5
.yPositive:
	CMP.W	D4,D5
	BGE	.yLarger
	EXG	D4,D5
.yLarger:
	LSR.W	#$04,D7
	AND.B	#$FE,D7
	MOVE.W	$00(A0,D7.W),D0
	MULU	D4,D0
	SWAP	D0
	ADD.W	D5,D0
	RTS

prepareFrameRendering:
	JSR	calculateCameraTransform
	MOVE.B	#$00,D0
	MOVE.B	D0,lbB00D4AE
	MOVE.B	D0,lbB00D45C
	MOVE.B	D0,lbB00D47F
	MOVE.W	#$FFFF,opponentSegmentQueueOffset
	MOVE.B	#$00,curveSmoothingFlag
	JSR	clearRenderBuffers
	RTS

processGameFrame:
	JSR	prepareFrameRendering
	MOVE.B	#$00,D0
	MOVE.B	D0,gridLookupX
	MOVE.B	D0,gridLookupY
	JSR	getSegmentAtGridCoordinate
	BCS	.playerOffGrid
	CMP.B	#$FF,D0
	BNE	.segmentFound
	MOVE.B	subGridOffsetX,D0
	MOVE.B	subGridOffsetZ,D2
	JSR	findSegmentBySubGridAdjustment
	CMP.B	#$FF,D0
	BNE	.segmentFound
.playerOffGrid:
	MOVE.B	#$C0,offTrackStateFlags
	TST.B	networkGameMode
	BEQ	.networkStateOk
	JSR	synchronizeNetworkState
.networkStateOk:
	TST.B	selectedTrackInDivision
	BPL	.opponentLogicProcessed
	JSR	processOpponentLogic
	JSR	setupTrackGeometryForFrame
.opponentLogicProcessed:
	MOVE.B	prevTrackProgressionOffset,trackProgressionOffset
	MOVE.W	prevVisibilityAccumulator,visibilityAccumulator
	MOVE.B	prevSegmentDepthCounter,segmentDepthCounter
	BRA	.setupRendering

;	JSR	busyWaitDelay				; removed: dead code
;	JSR	renderHorizon
;	JSR	renderMountainHorizon
;	JMP	lbC0569E2

.segmentFound:
	MOVE.B	D0,currentSegmentIndex
	JSR	applyTrackSegmentGeometry
	JSR	checkRoadBoundaries
	MOVE.B	currentSegmentIndex,D0
	MOVE.B	D0,playerSegmentIndex
	BTST	#$06,offTrackStateFlags
	BNE	.lastValidSegmentIndexOk
	MOVE.B	D0,lastValidSegmentIndex
.lastValidSegmentIndexOk:
	JSR	calculateTrackPosition
	MOVE.B	trackProgressionOffset,prevTrackProgressionOffset
	MOVE.W	visibilityAccumulator,prevVisibilityAccumulator
	MOVE.B	segmentDepthCounter,prevSegmentDepthCounter
	TST.B	networkGameMode
	BEQ	.localGameMode
	JSR	synchronizeNetworkState
	BRA	.setupRendering

.localGameMode:
	TST.B	selectedTrackInDivision
	BPL	.setupRendering
	JSR	processOpponentLogic
	JSR	calculatePlayerDistance
	JSR	handleOpponentPositioning
	JSR	setupTrackGeometryForFrame
.setupRendering:
	tst.b	framesToProcess				; added
	beq.s	.continueSetup
	rts
.continueSetup:
	MOVE.B	#$80,D0
	MOVE.B	D0,processedSegmentIndices1
	MOVE.B	D0,processedSegmentIndices2
	MOVE.B	playerSegmentIndex,currentSegmentIndex
	MOVE.B	#$00,segmentDataStartIndex
	MOVE.B	trackProgressionOffset,D0
	BPL	lbC0568BA
	JSR	advanceToNextSegment
	MOVE.B	#$00,trackProgressionOffset
lbC0568BA:
	TST.B	trackProgressionOffset
	BNE	lbC0568E2
	JSR	retreatToPreviousSegment
	CMP.B	lbB00D4A6,D1
	BNE	lbC0568DC
	MOVE.W	#$0000,opponentSegmentQueueOffset
lbC0568DC:
	JSR	advanceToNextSegment
lbC0568E2:
	JSR	transformTrackSegmentCoordinates
	JSR	processTrackVisibility
	JSR	processRenderData
	JSR	processTrackSegments
;	MOVE.B	#$00,lbB00D4E5				; removed: dead code
	MOVE.B	#$00,renderingLoopIndex
	MOVE.B	#$04,segmentDataStartIndex
	JSR	shiftCoordinateArrays
	JSR	advanceToNextSegment
	JSR	transformTrackSegmentCoordinates
	JSR	processTrackVisibility
	JSR	generateTrackEdgeLines
	JSR	shiftCoordinateArrays
	MOVE.B	#$01,lbB00D47F
	JSR	advanceToNextSegment
	JSR	transformTrackSegmentCoordinates
	JSR	processTrackVisibility
	JSR	generateTrackEdgeLines
	JSR	shiftCoordinateArrays
	JSR	advanceToNextSegment
	MOVE.W	renderCommandQueueOffset,farSegmentQueueOffset
	MOVE.W	transformedCoordinates1,lbW0579FC
	MOVE.W	transformedCoordinates2,lbW0579FE
	JSR	transformCoordinates
	JSR	drawTrackLines
	TST.B	selectedTrackInDivision
	BMI	lbC05699E
	MOVE.W	#$FFFF,opponentSegmentQueueOffset
lbC05699E:
	TST.B	networkGameMode
	BEQ	lbC0569AE
	JSR	handleNetworkProtocol
lbC0569AE:
	MOVE.W	renderCommandQueueOffset,-(SP)
	JSR	renderHorizon
	JSR	renderMountainHorizon
	MOVE.W	(SP)+,renderCommandQueueOffset
	JSR	updateOpponentVisibility
	JSR	renderTrackFar
	MOVE.W	farSegmentQueueOffset,renderCommandQueueOffset
	JSR	renderTrackNear
lbC0569E2:
	TST.B	raceStartTimer
	BNE	.groundCollisionHandled
	TST.B	offTrackStateFlags
	BPL	.groundCollisionHandled
	JSR	handleGroundCollision
.groundCollisionHandled:
	JSR	handleEdgeCollision
	JSR	updateChainAnimation
	MOVE.B	#$0D,D0				; left top
	JSR	renderMaskedGraphicsObject
	MOVE.B	#$0E,D0				; right top
	JSR	renderMaskedGraphicsObject
	JSR	updateWheelSuspensionPosition
	MOVE.B	wheelRotationFrame,D0		; right wheel
	JSR	renderMaskedGraphicsObject
	MOVE.B	#$05,D0				; left wheel
	SUB.B	wheelRotationFrame,D0
	JSR	renderMaskedGraphicsObject
	MOVE.B	#$0A,D0				; engine
	JSR	renderMaskedGraphicsObject
	MOVE.B	#$0B,D0				; left exhaust
	JSR	renderMaskedGraphicsObject
	MOVE.B	#$0C,D0				; right exhaust
	JSR	renderMaskedGraphicsObject
	TST.B	boostActiveFlag
	BEQ	.flameRenderingDone
	MOVE.B	flameAnimationFrame,D0
	ADDQ.B	#$01,D0
	CMP.B	#$03,D0
	BLT	.flameAnimationFrameOk
	MOVE.B	#$00,D0
.flameAnimationFrameOk:
	MOVE.B	D0,flameAnimationFrame
	MOVE.W	D0,-(SP)
	ADD.B	#$06,D0
	CMP.B	#$08,D0
	BNE	.leftFlameObjectIdOk
	MOVE.B	#$31,D0				; left flames
.leftFlameObjectIdOk:
	JSR	renderMaskedGraphicsObject
	MOVE.W	(SP)+,D0
	ADD.B	#$08,D0
	CMP.B	#$0A,D0
	BNE	.rightFlameObjectIdOk
	MOVE.B	#$32,D0				; right flames
.rightFlameObjectIdOk:
	JSR	renderMaskedGraphicsObject
.flameRenderingDone:
	JSR	updateGameMessageDisplay
	JSR	copyFastRenderBuffer
	RTS

copyFastRenderBuffer:
	lea	fastRenderBuffer,a0
	move.l	renderFrameBuffer,a1
	lea	16*40+4(a0),a0
	lea	16*40+4(a1),a1
	moveq	#4-1,d7
.copyBitplane:
	move.w	#128-1,d6
.copyMain:
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	lea	8(a0),a0
	lea	8(a1),a1
	dbra	d6,.copyMain	
	moveq	#16-1,d6
.copyBottom:
	move.l	(a0),(a1)
	move.l	28(a0),28(a1)
	lea	40(a0),a0
	lea	40(a1),a1
	dbra	d6,.copyBottom
	lea	(200-128-16)*40(a0),a0
	lea	(200-128-16)*40(a1),a1
	dbra	d7,.copyBitplane
	rts

updateWheelGraphics:
	MOVE.B	wheelSpeed,D0
	ADD.B	D0,wheelAnimationAccumulator
	BCC	.wheelRotationFrameOk
	JSR	advanceWheelRotationFrame
.wheelRotationFrameOk:
	MOVE.B	wheelRotationFrame,D0
	ADD.B	#$25,D0
	CMP.W	#$007E,rightWheelHeight
	BGE	.rightWheelSpriteIdOk
	ADD.B	#$06,D0
.rightWheelSpriteIdOk:
	MOVE.W	#$0000,D1
	JSR	setSpriteFromTable
	MOVE.B	#$05,D0
	SUB.B	wheelRotationFrame,D0
	ADD.B	#$25,D0
	CMP.W	#$007E,leftWheelHeight
	BGE	.leftWheelSpriteIdOk
	ADD.B	#$06,D0
.leftWheelSpriteIdOk:
	MOVE.W	#$0001,D1
	JSR	setSpriteFromTable
	RTS

transformTrackSegmentCoordinates:
	MOVE.L	#trackSegmentData,A6
	MOVE.B	currentSegmentIndex,D1
	JSR	loadTrackSegmentConfiguration
	MOVE.B	currentSegmentIndex,D0
	JSR	transformSegmentToViewSpace
	MOVE.B	cameraRotationFlags,D0
	SUB.B	segmentSlopeFlags,D0
	MOVE.B	D0,trackHeightDifference
	JSR	setupTrackGeometryForFrame2
	MOVE.B	renderingLoopIndex,D1
	BEQ	lbC056B72
	MOVE.L	#lbL00D76C,A0
	MOVE.W	$00(A0,D1.W),lbW00D434
	MOVE.W	$02(A0,D1.W),lbW00D436
lbC056B72:
	TST.B	displayUpdateFlag
	BMI	lbC056BFE
	MOVE.B	trackHeightDifference,D0
	MOVE.B	reverseDirectionFlag,D3
	EOR.B	D3,D0
	TST.B	gridSweepDirection
	BPL	lbC056BAA
	TST.B	segmentSteeringFlags
	BMI	lbC056BB4
	BTST	#$06,segmentSteeringFlags
	BEQ	lbC056BB4
lbC056BAA:
	TST.B	trackDirectionInversionFlag
	BPL	lbC056BB8
lbC056BB4:
	ADD.B	#$40,D0
lbC056BB8:
	MOVE.B	#$00,lbB00D4AD
	BPL	lbC056BFE
	MOVE.B	D0,lbB00D4AE
	MOVE.B	#$00,segmentDataStartIndex
	JSR	reverseTrackSegmentData
	MOVE.B	segmentAlternateFlag,D0
	ADD.B	maxSegmentIndex,D0
	AND.B	#$02,D0
	MOVE.B	D0,segmentAlternateFlag
	TST.B	reverseDirectionFlag
	BNE	lbC056C0E
	JMP	lbC056CBC

lbC056BFE:
	TST.B	reverseDirectionFlag
	BEQ	lbC056C0E
	JMP	lbC056CBC

lbC056C0E:
	MOVE.W	geometryDatabaseOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A0
	MOVE.B	(A0),D0
	ADDQ.B	#$07,D0
	MOVE.B	D0,trackOffsetBase
	MOVE.B	segmentDataStartIndex,D1
	MOVE.L	#trackSegmentData,A6
lbC056C3E:
	TST.W	$00(A6,D1.W)
	BMI	lbC056CAA
	MOVE.W	#$8000,$78(A6,D1.W)
	CMP.B	renderingLoopIndex,D1
	BGE	lbC056C62
	MOVE.W	#$8000,$00(A6,D1.W)
	JMP	lbC056CAA

lbC056C62:
	MOVE.W	D1,D2
	ASL.W	#$01,D2
	ADD.B	trackOffsetBase,D2
	JSR	interpolateOpponentTrackPositionFromData
	JSR	projectTrackXToScreen
	JSR	transformCoordinate
	BTST	#$06,offTrackStateFlags
	BEQ	lbC056C94
	JSR	checkFarClippingPlane
	BCS	lbC056C9A
lbC056C94:
	JSR	checkTrackEdgeVisibility
lbC056C9A:
	MOVE.B	D1,D2
	AND.B	#$02,D2
	MOVE.L	#processedSegmentIndices1,A2
	MOVE.B	D1,$00(A2,D2.W)
lbC056CAA:
	ADDQ.B	#$02,D1
	CMP.B	trackSegmentLimitDoubled,D1
	BNE	lbC056C3E
	JMP	lbC056D72

lbC056CBC:
	MOVE.W	geometryDatabaseOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A0
	MOVE.B	(A0),D0
	ADDQ.B	#$07,D0
	MOVE.B	trackSegmentLimit,D3
	SUBQ.B	#$01,D3
	ASL.B	#$02,D3
	ADD.B	D3,D0
	MOVE.B	D0,trackOffsetBase
	MOVE.B	segmentDataStartIndex,D1
	MOVE.L	#trackSegmentData,A6
lbC056CF8:
	TST.W	$00(A6,D1.W)
	BMI	lbC056D66
	MOVE.W	#$8000,$78(A6,D1.W)
	CMP.B	renderingLoopIndex,D1
	BGE	lbC056D1C
	MOVE.W	#$8000,$00(A6,D1.W)
	JMP	lbC056D66

lbC056D1C:
	MOVE.B	D1,D3
	ASL.B	#$01,D3
	MOVE.B	trackOffsetBase,D2
	SUB.B	D3,D2
	JSR	interpolateOpponentTrackPositionFromData
	JSR	projectTrackXToScreen
	JSR	transformCoordinate
	BTST	#$06,offTrackStateFlags
	BEQ	lbC056D50
	JSR	checkFarClippingPlane
	BCS	lbC056D56
lbC056D50:
	JSR	checkTrackEdgeVisibility
lbC056D56:
	MOVE.B	D1,D2
	AND.B	#$02,D2
	MOVE.L	#processedSegmentIndices1,A2
	MOVE.B	D1,$00(A2,D2.W)
lbC056D66:
	ADDQ.B	#$02,D1
	CMP.B	trackSegmentLimitDoubled,D1
	BNE	lbC056CF8
lbC056D72:
	MOVE.L	#coordinateLookupTable,A1
	MOVE.B	processedSegmentIndices1,D1
	MOVE.W	$00(A1,D1.W),transformedCoordinates1
	MOVE.B	processedSegmentIndices2,D1
	MOVE.W	$00(A1,D1.W),transformedCoordinates2
	MOVE.B	segmentDataStartIndex,D1
lbC056D9A:
	TST.W	$00(A6,D1.W)
	BMI	lbC056DA8
	JSR	applyScreenSpaceRotation
lbC056DA8:
	ADDQ.B	#$02,D1
	CMP.B	trackSegmentLimitDoubled,D1
	BNE	lbC056D9A
	MOVE.B	processedSegmentIndices1,lbB056DC0
	RTS

checkTrackEdgeVisibility:
	MOVE.L	#coordinateLookupTable,A4
	MOVE.L	#transformedVertexBounds,A5
	MOVE.B	D1,D2
	AND.B	#$02,D2
	MOVE.L	#processedSegmentIndices1,A2
	MOVE.B	$00(A2,D2.W),D2
	BPL	lbC056E04
	TST.B	lbB00D468
	BMI	lbC056E42
	MOVE.B	offRoadSideFlags,D0
	BEQ	lbC056E62
	EOR.B	D1,D0
	AND.B	#$02,D0
	BEQ	lbC056E42
	BRA	lbC056E62

lbC056E04:
	CMP.B	#$04,D2
	BGE	lbC056E1A
	TST.B	lbB00D468
	BMI	lbC056E1A
	ADD.B	#$F0,D2
lbC056E1A:
	MOVE.B	D1,D0
	AND.B	#$02,D0
	BNE	lbC056E36
	MOVE.W	$00(A4,D2.W),D0
	SUB.W	$00(A4,D1.W),D0
	BMI	lbC056E62
	JMP	lbC056E42

lbC056E36:
	MOVE.W	$00(A4,D1.W),D0
	SUB.W	$00(A4,D2.W),D0
	BMI	lbC056E62
lbC056E42:
	MOVE.W	#$0200,$78(A6,D1.W)
	MOVE.W	$00(A4,D1.W),$78(A4,D1.W)
	ADD.B	#$78,D1
	JSR	transformCoordinate
	JSR	apply3DTransformation
	SUB.B	#$78,D1
lbC056E62:
	RTS

shiftCoordinateArrays:
	MOVE.L	#coordinateLookupTable,A4
	MOVE.L	#transformedVertexBounds,A5
	MOVE.B	trackSegmentLimitDoubled,D1
	MOVE.B	lbB056DC0,D0
	BMI	lbC056E84
	ADDQ.B	#$04,D0
	MOVE.B	D0,D1
lbC056E84:
	TST.B	lbB00D4AE
	BMI	lbC056ED8
	MOVE.B	#$02,D2
lbC056E92:
	SUBQ.B	#$02,D1
	MOVE.W	$00(A4,D1.W),$00(A4,D2.W)
	MOVE.W	$00(A5,D1.W),$00(A5,D2.W)
	MOVE.W	$00(A6,D1.W),$00(A6,D2.W)
	MOVE.W	$78(A4,D1.W),$78(A4,D2.W)
	MOVE.W	$78(A5,D1.W),$78(A5,D2.W)
	MOVE.W	$78(A6,D1.W),$78(A6,D2.W)
	SUBQ.B	#$02,D2
	BPL	lbC056E92
	MOVE.B	#$00,processedSegmentIndices1
	MOVE.B	#$02,D0
	MOVE.B	D0,processedSegmentIndices2
	CMP.W	#$0100,$00(A4,D1.W)
	RTS

lbC056ED8:
	MOVE.B	#$00,segmentDataStartIndex
	SUBQ.B	#$04,D1
	CMP.W	#$0100,$00(A4,D1.W)
	RTS

processTrackVisibility:
	CLR.W	D0
	MOVE.B	currentSegmentIndex,D0
	MOVE.L	#segmentDataPointers,A0
	ASL.W	#$02,D0
	MOVE.L	$00(A0,D0.W),A0
	MOVE.W	(A0),segmentRenderFlags
	MOVE.L	#segmentProcessedFlags,A3
	MOVE.L	#trackSegmentData,A6
	MOVE.B	trackSegmentLimitDoubled,D1
	JSR	processTrackSurfaceVisibility
	MOVE.B	trackSegmentLimitDoubled,D1
	ADDQ.B	#$02,D1
processTrackSurfaceVisibility:
	SUBQ.B	#$04,D1
	TST.W	$00(A6,D1.W)
	BMI	lbC056F8E
	TST.W	$78(A6,D1.W)
	BPL	lbC056FB0
	MOVE.B	D1,D0
	BCLR	#$01,D0
	CMP.B	renderingLoopIndex,D0
	BEQ	lbC056F6E
	BTST	#$01,D1
	BNE	lbC056F5E
	BTST	#$07,segmentRenderFlags
	BNE	lbC056FD0
	BRA	lbC056F8E

lbC056F5E:
	BTST	#$06,segmentRenderFlags
	BNE	lbC056FD0
	BRA	lbC056F8E

lbC056F6E:
	TST.B	offRoadSideFlags
	BEQ	lbC056F8E
	MOVE.W	offsetFromRoadCenter,D0
	ROL.W	#$02,D0
	EOR.B	D1,D0
	AND.B	#$02,D0
	BEQ	lbC056F8E
	BRA	lbC056FD0

lbC056F8E:
	SUBQ.B	#$04,D1
	BMI	lbC05701E
lbC056F94:
	TST.W	$00(A6,D1.W)
	BMI	lbC056F8E
	TST.W	$78(A6,D1.W)
	BMI	lbC056F8E
	MOVE.W	D1,D3
	BCLR	#$01,D3
	OR.B	#$40,$00(A3,D3.W)
lbC056FB0:
	SUBQ.B	#$04,D1
	BMI	lbC05701E
	TST.W	$00(A6,D1.W)
	BMI	lbC056FB0
	TST.W	$78(A6,D1.W)
	BPL	lbC056FB0
	CMP.B	renderingLoopIndex,D1
	BLT	lbC05701E
lbC056FD0:
	JSR	processTrackVertexWithCharacteristics
	MOVE.W	D1,D3
	BCLR	#$01,D3
	OR.B	#$40,$00(A3,D3.W)
	SUBQ.B	#$04,D1
	BPL	lbC056F94
	ADDQ.B	#$04,D1
	MOVE.W	renderCommandQueueOffset,D3
	CMP.W	#$0020,D3
	BEQ	lbC05701E
	MOVE.W	D3,-(SP)
	SUB.W	#$0010,D3
	TST.W	D1
	BEQ	lbC057006
	ADDQ.W	#$04,D3
lbC057006:
	MOVE.W	D3,renderCommandQueueOffset
	MOVE.W	D1,D2
	ADD.B	#$78,D1
	JSR	drawClippedLine
	MOVE.W	(SP)+,renderCommandQueueOffset
lbC05701E:
	RTS

processTrackVertexWithCharacteristics:
	MOVEM.L	D1-D7/A3-A6,-(SP)
	MOVE.B	D1,tempByte5
	MOVE.W	#$0200,$78(A6,D1.W)
	MOVE.W	D1,D0
	LSR.W	#$02,D0
	JSR	processTrackCharacteristics
	MOVE.B	tempByte5,D1
	MOVE.W	D1,D2
	AND.W	#$0002,D2
	ADD.B	#$78,D1
	JSR	loadAndTransformTrackVertex
	MOVEM.L	(SP)+,D1-D7/A3-A6
	RTS

setupTrackGeometryForFrame2:
	MOVE.W	primaryGeometryOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A4
	MOVE.W	alternateGeometryOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A5
	MOVE.L	#segmentProcessedFlags,A3
	MOVE.W	#$002E,D7
	SUB.W	visibilityAccumulator,D7
	BPL	lbC0570A2
	MOVE.B	#$00,D7
lbC0570A2:
	CLR.W	D0
	MOVE.B	trackModeParameter,D0
	ADD.W	D0,visibilityAccumulator
	MOVE.B	#$00,D0
	MOVE.B	maxSegmentIndex,D1
	ASL.W	#$01,D1
	MOVE.B	currentSegmentIndex,D2
	CMP.B	lapApproachSegment,D2
	BNE	lbC0570D0
	MOVE.B	#$01,D0
lbC0570D0:
	MOVE.B	D0,$00(A3,D1.W)
	MOVE.B	#$00,D2
	MOVE.B	segmentDataStartIndex,D1
	BNE	lbC057112
	MOVE.B	D2,segmentProcessingIndex
	TST.B	geometryFormatFlag
	BPL	lbC057106
	MOVE.B	segmentProcessingIndex,D2
	ASL.B	#$01,D2
	MOVE.B	$00(A4,D2.W),D0
	BPL	lbC057236
	BRA	lbC057230

lbC057106:
	MOVE.B	$00(A4,D2.W),D0
	BMI	lbC057146
	BRA	lbC05714C

lbC057112:
	MOVE.B	#$01,D2
	MOVE.B	D2,segmentProcessingIndex
	TST.B	geometryFormatFlag
	BMI	lbC057202
lbC057126:
	MOVE.B	$00(A4,D2.W),D0
	BMI	lbC057146
	CMP.B	D7,D2
	BCS	lbC05714C
	MOVE.W	#$8000,$00(A6,D1.W)
	MOVE.W	#$8000,$02(A6,D1.W)
	JMP	lbC0571EC

lbC057146:
	MOVE.B	#$00,$00(A3,D1.W)
lbC05714C:
	MOVE.B	$00(A4,D2.W),D0
	MOVE.B	D0,D3
	ASL.B	#$01,D0
	AND.W	#$00E0,D0
	AND.B	#$0F,D3
	ASL.W	#$08,D3
	OR.W	D3,D0
	ADD.W	segmentBezierOffset1,D0
	MOVE.W	D0,$00(A6,D1.W)
	TST.B	$00(A3,D1.W)
	BMI	lbC0571CE
	MOVE.W	-$04(A6,D1.W),D3
	BPL	lbC0571B0
	TST.B	lbB00D47F
	BEQ	lbC0571CE
	CMP.B	#$04,D1
	BLT	lbC0571CE
	MOVE.W	D0,-(SP)
	SUBQ.B	#$01,D2
	MOVE.B	$00(A4,D2.W),D0
	MOVE.B	D0,D3
	ASL.B	#$01,D0
	AND.W	#$00E0,D0
	AND.B	#$0F,D3
	ASL.W	#$08,D3
	OR.W	D3,D0
	ADD.W	segmentBezierOffset1,D0
	ADDQ.B	#$01,D2
	MOVE.W	D0,D3
	MOVE.W	(SP)+,D0
lbC0571B0:
	SUB.W	D3,D0
	BPL	lbC0571B8
	NEG.W	D0
lbC0571B8:
	CMP.W	#$0280,D0
	BLT	lbC0571CE
	CMP.B	#$04,D1
	BLT	lbC0571CE
	OR.B	#$20,$00(A3,D1.W)
lbC0571CE:
	MOVE.B	$00(A5,D2.W),D0
	MOVE.B	D0,D3
	ASL.B	#$01,D0
	AND.W	#$00E0,D0
	AND.B	#$0F,D3
	ASL.W	#$08,D3
	OR.W	D3,D0
	ADD.W	segmentBezierOffset2,D0
	MOVE.W	D0,$02(A6,D1.W)
lbC0571EC:
	ADDQ.B	#$01,D2
	ADDQ.B	#$04,D1
	CMP.B	maxSegmentIndexDoubled,D1
	BLT	lbC057126
	BEQ	lbC05714C
	BRA	lbC0572EE

lbC057202:
	MOVE.B	segmentProcessingIndex,D2
	ASL.B	#$01,D2
	TST.B	$00(A4,D2.W)
	BMI	lbC057230
	MOVE.B	segmentProcessingIndex,D0
	CMP.B	D7,D0
	BCS	lbC057236
	MOVE.W	#$8000,$00(A6,D1.W)
	MOVE.W	#$8000,$02(A6,D1.W)
	JMP	lbC0572CA

lbC057230:
	MOVE.B	#$00,$00(A3,D1.W)
lbC057236:
	MOVE.B	$01(A4,D2.W),D3
	MOVE.B	$00(A4,D2.W),D0
	AND.B	#$7F,D0
	ASL.W	#$08,D0
	OR.B	D3,D0
	ADD.W	segmentBezierOffset1,D0
	MOVE.W	D0,$00(A6,D1.W)
	TST.B	$00(A3,D1.W)
	BMI	lbC0572B0
	MOVE.W	-$04(A6,D1.W),D3
	BPL	lbC057292
	TST.B	lbB00D47F
	BEQ	lbC0572B0
	CMP.B	#$04,D1
	BLT	lbC0572B0
	MOVE.W	D0,-(SP)
	SUBQ.B	#$02,D2
	MOVE.B	$01(A4,D2.W),D3
	MOVE.B	$00(A4,D2.W),D0
	AND.B	#$7F,D0
	ASL.W	#$08,D0
	OR.B	D3,D0
	ADD.W	segmentBezierOffset1,D0
	ADDQ.B	#$02,D2
	MOVE.W	D0,D3
	MOVE.W	(SP)+,D0
lbC057292:
	SUB.W	D3,D0
	BPL	lbC05729A
	NEG.W	D0
lbC05729A:
	CMP.W	#$0280,D0
	BLT	lbC0572B0
	CMP.B	#$04,D1
	BLT	lbC0572B0
	OR.B	#$20,$00(A3,D1.W)
lbC0572B0:
	MOVE.B	$01(A5,D2.W),D3
	MOVE.B	$00(A5,D2.W),D0
	AND.B	#$7F,D0
	ASL.W	#$08,D0
	OR.B	D3,D0
	ADD.W	segmentBezierOffset2,D0
	MOVE.W	D0,$02(A6,D1.W)
lbC0572CA:
	ADDQ.B	#$01,segmentProcessingIndex
	ADDQ.B	#$04,D1
	CMP.B	maxSegmentIndexDoubled,D1
	BLT	lbC057202
	BNE	lbC0572F0
	MOVE.B	segmentProcessingIndex,D2
	ASL.B	#$01,D2
	JMP	lbC057236

lbC0572EE:
	SUBQ.B	#$01,D2
lbC0572F0:
	MOVE.B	$00(A4,D2.W),D0
	BPL	lbC057316
	MOVE.B	#$80,-$04(A3,D1.W)
	MOVE.B	trackModeParameter,D2
	CMP.B	D7,D2
	BCS	lbC057316
	MOVE.W	#$8000,-$04(A6,D1.W)
	MOVE.W	#$8000,-$02(A6,D1.W)
lbC057316:
	RTS

processRenderData:
	MOVE.B	renderingLoopIndex,D1
	BNE	lbC057324
	RTS

lbC057324:
	MOVE.W	#$0008,D3
	JSR	renderBarrierPost
	MOVE.B	renderingLoopIndex,D1
	ADDQ.B	#$02,D1
	MOVE.W	#$0009,D3
	JSR	renderBarrierPost
	MOVE.B	renderingLoopIndex,D1
	ADD.B	#$78,D1
	MOVE.W	#$000A,D3
	JSR	renderBarrierPost
	MOVE.B	renderingLoopIndex,D1
	ADD.B	#$7A,D1
	MOVE.W	#$000B,D3
	JSR	renderBarrierPost
	MOVE.W	#$0020,renderCommandQueueOffset
	RTS

renderBarrierPost:
	ASL.W	#$02,D3
	MOVE.W	D3,renderCommandQueueOffset
	MOVE.L	#coordinateLookupTable,A4
	MOVE.L	#transformedVertexBounds,A5
	MOVE.B	D1,tempByte5
	CMP.W	#$0078,D1
	BLT	lbC05739C
	TST.W	$00(A6,D1.W)
	BMI	lbC0573CC
lbC05739C:
	MOVE.W	$00(A4,D1.W),D0
	CMP.W	#$0100,D0
	BCC	lbC0573CC
	MOVE.W	$00(A5,D1.W),D0
	CMP.W	#$0080,D0
	BCC	lbC0573CC
	JSR	processTrackEdgeVertex
	MOVE.B	tempByte5,D1
	MOVE.W	D1,D2
	SUBQ.B	#$04,D2
	JSR	drawClippedLine
	RTS

lbC0573CC:
	MOVE.L	#renderCommandQueue,A1
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	#$80000000,$00(A1,D3.W)
	RTS

processTrackEdgeVertex:
	MOVE.B	D1,tempByte5
	MOVE.B	D1,D0
	AND.B	#$02,D0
	MOVE.B	D0,renderingIndex
	MOVE.B	D0,D2
	CMP.W	#$0078,D1
	BLT	lbC057408
	MOVE.W	#$0200,-$04(A6,D1.W)
	BRA	lbC057414

lbC057408:
	MOVE.L	#lbW00D434,A2
	MOVE.W	$00(A2,D2.W),-$04(A6,D1.W)
lbC057414:
	MOVE.B	trackProgressionOffset,D0
	JSR	processTrackCharacteristics
	MOVE.B	renderingIndex,D1
	MOVE.B	#$08,D2
	MOVE.B	lbB00D40F,D0
	AND.W	#$00FF,D0
	JSR	interpolateCoordinatePair
	MOVE.B	tempByte5,D1
	CMP.W	#$0078,D1
	BGE	lbC057474
	MOVE.B	#$00,D0
	MOVE.B	lbB00D40F,tempByte3
	MOVE.W	$00(A6,D1.W),D0
	SUB.W	-$04(A6,D1.W),D0
	MOVE.B	tempByte3,D3
	ASL.W	#$07,D3
	BCLR	#$0F,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	ADD.W	D0,-$04(A6,D1.W)
lbC057474:
	SUBQ.B	#$04,D1
	MOVE.B	#$08,D2
	JSR	loadAndTransformTrackVertex
	MOVE.L	#coordinateLookupTable,A4
	MOVE.L	#transformedVertexBounds,A5
	MOVE.W	$00(A4,D1.W),D4
	MOVE.W	$00(A5,D1.W),D5
	MOVE.W	D4,D0
	CMP.W	#$0100,D0
	BCC	lbC0574E2
	MOVE.W	D5,D0
	CMP.W	#$0080,D0
	BCC	lbC0574E2
	MOVE.W	D4,D6
	SUB.W	$04(A4,D1.W),D6
	MOVE.W	D5,D7
	SUB.W	$04(A5,D1.W),D7
	BNE	lbC0574DA
	TST.W	D6
	BNE	lbC0574DA
	MOVE.W	#$0001,D7
	BRA	lbC0574DA

lbC0574C6:
	MOVE.W	D4,D0
	CMP.W	#$0100,D0
	BCC	lbC0574E2
	MOVE.W	D5,D0
	CMP.W	#$0080,D0
	BCC	lbC0574E2
lbC0574DA:
	ADD.W	D6,D4
	ADD.W	D7,D5
	BRA	lbC0574C6

lbC0574E2:
	MOVE.W	D4,$00(A4,D1.W)
	MOVE.W	D5,$00(A5,D1.W)
	RTS

generateTrackSegmentData:
	JSR	initializeTrackSegmentBuffers
	MOVE.L	#segmentGeometryData,segmentDataWritePointer
	MOVE.B	#$00,segmentDataStartIndex
	MOVE.L	#trackSegmentData,A6
	MOVE.B	#$00,D1
lbC05750E:
	MOVE.B	D1,currentSegmentIndex
	MOVE.W	D1,D0
	MOVE.L	#segmentDataPointers,A0
	ASL.W	#$02,D0
	MOVE.L	segmentDataWritePointer,$00(A0,D0.W)
	MOVE.W	#$0000,segmentRenderFlags
	JSR	advanceToNextSegment
	JSR	loadTrackSegmentConfiguration
	TST.B	segmentSteeringFlags
	BPL	lbC057566
	MOVE.B	#$40,segmentRenderFlags
	MOVE.B	trackDirectionInversionFlag,D3
	MOVE.B	reverseDirectionFlag,D0
	EOR.B	D0,D3
	BPL	lbC057566
	MOVE.B	#$80,segmentRenderFlags
lbC057566:
	JSR	retreatToPreviousSegment
	JSR	loadTrackSegmentConfiguration
	MOVE.W	#$0000,visibilityAccumulator
	MOVE.B	segmentSlopeFlags,trackHeightDifference
	NEG.B	trackHeightDifference
	JSR	setupTrackGeometryForFrame2
	MOVE.B	segmentDataStartIndex,D1
	MOVE.L	#segmentProcessedFlags,A3
	MOVE.L	segmentDataWritePointer,A4
	MOVE.W	geometryDatabaseOffset,D0
	ROL.W	#$08,D0
	SUB.W	#$B100,D0
	AND.L	#$FFFF,D0
	ADD.L	#trackGeometryDatabase,D0
	MOVE.L	D0,A0
	MOVE.B	(A0),D0
	ADDQ.B	#$07,D0
	TST.B	reverseDirectionFlag
	BPL	lbC0575D6
	MOVE.B	trackSegmentLimit,D3
	SUBQ.B	#$01,D3
	ASL.B	#$02,D3
	ADD.B	D3,D0
lbC0575D6:
	MOVE.B	D0,trackOffsetBase
lbC0575DC:
	MOVE.B	$00(A3,D1.W),D0
	BMI	lbC0576E4
	MOVE.B	#$80,$00(A3,D1.W)
	CMP.B	#$04,D1
	BLT	lbC0576E4
	CMP.B	maxSegmentIndexDoubled,D1
	BGE	lbC05765E
	CLR.W	D3
	MOVE.B	maxSegmentIndexDoubled,D3
	TST.B	$00(A3,D3.W)
	BPL	lbC057614
	SUBQ.B	#$04,D3
	CMP.B	D3,D1
	BEQ	lbC05765E
lbC057614:
	TST.B	segmentSteeringFlags
	BMI	lbC05765E
	MOVE.B	currentSegmentIndex,D3
	MOVE.L	#segmentGeometryIndices,A2
	CMP.B	#$25,$00(A2,D3.W)
	BNE	lbC05763C
	CMP.B	#$18,D1
	BEQ	lbC05765E
lbC05763C:
	MOVE.W	$00(A6,D1.W),D3
	LSR.W	#$01,D3
	MOVE.W	-$04(A6,D1.W),D4
	ADD.W	$04(A6,D1.W),D4
	LSR.W	#$02,D4
	SUB.W	D4,D3
	TST.W	D3
	BPL	lbC057656
	NEG.W	D3
lbC057656:
	CMP.W	#$0050,D3
	BLT	lbC0576E4
lbC05765E:
	AND.B	#$3F,D0
	ASL.W	#$08,D0
	TST.B	segmentSteeringFlags
	BMI	lbC057674
	OR.W	segmentRenderFlags,D0
lbC057674:
	MOVE.B	currentSegmentIndex,D0
	MOVE.W	D0,(A4)+
lbC05767C:
	TST.B	reverseDirectionFlag
	BPL	lbC057696
	MOVE.B	D1,D3
	ASL.B	#$01,D3
	MOVE.B	trackOffsetBase,D2
	SUB.B	D3,D2
	BRA	lbC0576A0

lbC057696:
	MOVE.B	D1,D2
	ASL.B	#$01,D2
	ADD.B	trackOffsetBase,D2
lbC0576A0:
	JSR	interpolateOpponentTrackPositionFromData
	MOVE.W	tempWord1,(A4)+
	MOVE.W	tempWord2,(A4)+
	MOVE.W	$00(A6,D1.W),(A4)+
	ADDQ.B	#$02,D1
	BTST	#$01,D1
	BNE	lbC05767C
lbC0576C0:
	CMP.B	trackSegmentLimitDoubled,D1
	BNE	lbC0575DC
	MOVE.L	A4,segmentDataWritePointer
	MOVE.B	currentSegmentIndex,D1
	ADDQ.B	#$01,D1
	CMP.B	numTrackSegments,D1
	BLT	lbC05750E
	RTS

lbC0576E4:
	ADDQ.B	#$04,D1
	BRA	lbC0576C0

initializeTrackSegmentBuffers:
	CLR.W	D3
	MOVE.L	#segmentRenderDepthTable,A0
	MOVE.B	numTrackSegments,D3
	BRA	lbC057702

lbC0576FC:
	MOVE.B	#$78,$00(A0,D3.W)
lbC057702:
	DBRA	D3,lbC0576FC
	MOVE.L	#trackSpecificRenderDepthOverrides,A1
	CLR.W	D3
	MOVE.B	currentTrackID,D3
	ASL.W	#$03,D3
	MOVE.W	#$0003,D4
lbC05771A:
	MOVE.B	$00(A1,D3.W),D1
	BMI	lbC05772E
	MOVE.B	$01(A1,D3.W),$00(A0,D1.W)
	ADDQ.B	#$02,D3
	DBRA	D4,lbC05771A
lbC05772E:
	RTS

transformCoordinates:
	CLR.W	D0
	MOVE.B	currentSegmentIndex,D0
	MOVE.L	#segmentDataPointers,A0
	ASL.W	#$02,D0
	MOVE.L	$00(A0,D0.W),A6
	MOVE.W	#$0004,D1
lbC0577DC:
	MOVE.W	(A6)+,D0
	MOVE.L	#segmentRenderBuffer,A0
	MOVE.W	D0,$00(A0,D1.W)
	MOVE.W	D0,segmentRenderFlags
	MOVE.B	D0,currentSegmentIndex
	JSR	transformSegmentToViewSpace
	MOVE.B	transformedGridX,D0
	EXT.W	D0
	MOVE.B	cameraGridOffsetXHigh,D4
	ASL.W	#$08,D4
	MOVE.B	cameraGridOffsetXLow,D4
	ASR.W	#$01,D4
	ASL.W	#$02,D0
	ASL.W	#$08,D0
	ADD.W	D0,D4
	MOVE.W	D4,transformedGridX
	MOVE.B	transformedGridY,D0
	EXT.W	D0
	MOVE.B	cameraGridOffsetZHigh,D4
	ASL.W	#$08,D4
	MOVE.B	cameraGridOffsetZLow,D4
	ASR.W	#$01,D4
	ASL.W	#$02,D0
	ASL.W	#$08,D0
	ADD.W	D0,D4
	MOVE.W	D4,transformedGridY
lbC057842:
	TST.B	cameraRotationFlags
	BMI	lbC05786C
	BTST	#$06,cameraRotationFlags
	BNE	lbC057860
	MOVE.W	(A6)+,D0
	MOVE.W	(A6)+,D3
	BRA	lbC057890

lbC057860:
	MOVE.W	(A6)+,D3
	MOVE.W	#$0800,D0
	SUB.W	(A6)+,D0
	BRA	lbC057890

lbC05786C:
	BTST	#$06,cameraRotationFlags
	BNE	lbC057888
	MOVE.W	#$0800,D0
	SUB.W	(A6)+,D0
	MOVE.W	#$0800,D3
	SUB.W	(A6)+,D3
	BRA	lbC057890

lbC057888:
	MOVE.W	#$0800,D3
	SUB.W	(A6)+,D3
	MOVE.W	(A6)+,D0
lbC057890:
	ASR.W	#$01,D0
	ASR.W	#$01,D3
	ADD.W	transformedGridX,D0
	ADD.W	transformedGridY,D3
	JSR	transformXCoordinateToPerspective
	MOVE.W	(A6)+,D0
	MOVE.L	A6,-(SP)
	MOVE.L	#trackSegmentData,A6
	MOVE.W	D0,$00(A6,D1.W)
	SUB.W	cameraHeightBaseline,D0
	NEG.W	D0
	ASR.W	#$03,D0
	MOVE.W	perspectiveDepthDivisor,D3
	JSR	transformYCoordinateToPerspective
	MOVE.L	#coordinateLookupTable,A4
	MOVE.W	$00(A4,D1.W),D0
	BTST	#$01,D1
	BNE	lbC05790C
	MOVE.W	lbW0579FC,D3
	MOVE.W	D0,lbW0579FC
	CMP.W	D3,D0
	BLT	lbC057938
	BNE	lbC0578FC
	TST.B	offRoadSideFlags
	BNE	lbC057938
lbC0578FC:
	BTST	#$07,segmentRenderFlags
	BNE	lbC057938
	BRA	lbC05796E

lbC05790C:
	MOVE.W	lbW0579FE,D3
	MOVE.W	D0,lbW0579FE
	CMP.W	D3,D0
	BGT	lbC057938
	BNE	lbC05792C
	TST.B	offRoadSideFlags
	BNE	lbC057938
lbC05792C:
	BTST	#$06,segmentRenderFlags
	BEQ	lbC05796E
lbC057938:
	MOVE.W	#$0200,$78(A6,D1.W)
	MOVE.W	$00(A4,D1.W),$78(A4,D1.W)
	MOVE.W	cameraHeightBaseline,D0
	SUB.W	#$0200,D0
	ASR.W	#$03,D0
	ADD.B	#$78,D1
	MOVE.W	perspectiveDepthDivisor,D3
	JSR	transformYCoordinateToPerspective
	JSR	applyScreenSpaceRotation
	SUB.B	#$78,D1
	BRA	lbC057974

lbC05796E:
	MOVE.W	#$8000,$78(A6,D1.W)
lbC057974:
	JSR	applyScreenSpaceRotation
	MOVE.L	(SP)+,A6
	CMP.L	segmentDataWritePointer,A6
	BLT	lbC05798C
	MOVE.L	#segmentGeometryData,A6
lbC05798C:
	ADDQ.B	#$02,D1
	BTST	#$01,D1
	BNE	lbC057842
	MOVE.B	currentSegmentIndex,D2
	MOVE.L	#segmentRenderDepthTable,A0
	CMP.B	$00(A0,D2.W),D1
	BGE	lbC0579F2
	MOVE.L	#coordinateLookupTable,A4
	CMP.W	#$0100,-$04(A4,D1.W)
	BCS	lbC0577DC
	CMP.W	#$0100,-$02(A4,D1.W)
	BCS	lbC0577DC
	MOVE.L	#trackSegmentData,A0
	TST.W	$74(A0,D1.W)
	BMI	lbC0579E0
	CMP.W	#$0100,$74(A4,D1.W)
	BCS	lbC0577DC
	BRA	lbC0579F2

lbC0579E0:
	TST.W	$76(A0,D1.W)
	BMI	lbC0579F2
	CMP.W	#$0100,$76(A4,D1.W)
	BCS	lbC0577DC
lbC0579F2:
	MOVE.B	D1,lbB0579FA
	RTS

updateDamageBarHUD:
	MOVE.B	targetDamageLevel,D0
	CMP.B	accumulatedCarDamage,D0
	BEQ	lbC057A1A
	BCC	lbC057A1C
lbC057A1A:
	RTS

lbC057A1C:
	ADDQ.B	#$01,accumulatedCarDamage
	MOVE.B	damageBarVerticalOffset,D2
	BTST	#$00,accumulatedCarDamage
	BNE	lbC057A70
	JSR	generateRandomNumber
	LSR.B	#$01,D0
	BCC	lbC057A70
	LSR.B	#$01,D0
	BCC	lbC057A5E
	CMP.B	#$05,D2
	BCS	lbC057A56
	LSR.B	#$01,D0
	BCC	lbC057A5E
	SUBQ.B	#$01,D2
lbC057A56:
	ADDQ.B	#$01,D2
	JMP	lbC057A70

lbC057A5E:
	CMP.B	#$03,D2
	BCC	lbC057A6E
	LSR.B	#$01,D0
	BCC	lbC057A56
	ADDQ.B	#$01,D2
lbC057A6E:
	SUBQ.B	#$01,D2
lbC057A70:
	MOVE.B	#$0B,damageBarColor
	CMP.B	damageBarVerticalOffset,D2
	BLE	lbC057A8A
	MOVE.B	#$0C,damageBarColor
lbC057A8A:
	MOVE.B	D2,damageBarVerticalOffset
	MOVE.B	accumulatedCarDamage,D0
	CMP.B	#$F0,D0
	BCS	lbC057AAA
	SUBQ.B	#$01,accumulatedCarDamage
lbC057AA4:
	JMP	initiateCarWreck

lbC057AAA:
	MOVE.L	frameBuffers,A0
	ADD.L	#$00000004,A0
	MOVE.B	accumulatedCarDamage,D4
	AND.W	#$00FF,D4
	ADD.B	#$08,D4
	MOVE.W	D4,D0
	MOVE.B	damageBarVerticalOffset,D5
	AND.W	#$0007,D5
	EXT.L	D0
	EXT.L	D5
	LSR.L	#$03,D0
	AND.B	#$FE,D0
	ADD.L	D0,A0
	MOVE.L	D5,D0
	ASL.L	#$02,D0
	ADD.L	D5,D0
	ASL.L	#$03,D0
	ADD.L	D0,A0
	JSR	testPixelAtLocation
	BEQ	lbC057B54
	MOVE.B	#$00,D0
	JSR	setPixelColor
	JSR	plotPixel
	ADD.L	#$00007D00,A0
	JSR	plotPixel
	SUB.L	#$00000028,A0
	SUB.L	#$00007D00,A0
	JSR	plotPixel
	ADD.L	#$00007D00,A0
	JSR	plotPixel
	SUB.L	#$00000028,A0
	MOVE.B	damageBarColor,D0
	JSR	setPixelColor
	JSR	plotPixel
	SUB.L	#$00007D00,A0
	JSR	plotPixel
	JMP	updateDamageBarHUD

lbC057B54:
	ADDQ.B	#$01,targetDamageLevel
	BEQ	lbC057AA4
	JSR	resetDamageAccumulators
	JMP	updateDamageBarHUD

resetDamageAccumulators:
	MOVE.B	#$02,D2
lbC057B6E:
	MOVE.B	targetDamageLevel,D0
	MOVE.L	#accumulatedForceFrontLeft,A2
	MOVE.B	D0,$00(A2,D2.W)
	SUBQ.B	#$01,D2
	BPL	lbC057B6E
	RTS

testPixelAtLocation:
	MOVE.W	D4,D3
	AND.W	#$000F,D3
	ASL.W	#$02,D3
	MOVE.L	#bitMaskTable,A3
	MOVE.W	(A0),D0
	OR.W	$3E80(A0),D0
	SWAP	D0
	MOVE.W	$1F40(A0),D0
	OR.W	$5DC0(A0),D0
	AND.L	$00(A3,D3.W),D0
	RTS

updateChainAnimation:
	MOVE.B	raceStartTimer,D0
	BNE	renderChains
	MOVE.B	chainVerticalPosition,D0
	CMP.B	#$60,D0
	BLS	chainAnimationComplete		; originally BEQ
	SUB.B	chainLiftVelocity,D0
	MOVE.B	D0,chainVerticalPosition
	ADD.B	#$08/FRAMERATE_MULTIPLIER,chainLiftVelocity		; originally $08
renderChains:
	MOVE.B	chainVerticalPosition,D2
renderChainSegment:
	MOVE.L	#chainRenderParams,A3
	MOVE.W	D2,D3
	SUB.W	#$0030,D3
	MOVE.W	D3,(A3)
	MOVE.W	D3,$0020(A3)
	ADD.W	#$0008,D3
	MOVE.W	D3,$0010(A3)
	MOVE.W	D3,$0030(A3)
	CMP.W	#$0010,$0010(A3)
	BLT	chainAnimationComplete
	MOVE.B	#$14,D0
	JSR	renderMaskedGraphicsObject
	MOVE.B	#$16,D0
	JSR	renderMaskedGraphicsObject
	CMP.W	#$0010,(A3)
	BLT	chainAnimationComplete
	MOVE.B	#$13,D0
	JSR	renderMaskedGraphicsObject
	MOVE.B	#$15,D0
	JSR	renderMaskedGraphicsObject
	SUB.B	#$10,D2
	BRA	renderChainSegment

chainAnimationComplete:
	RTS

setPixelColor:
;	LSR.B	#$01,D0
;	BCS	lbC057C62
;	BCLR	#$06,lbB057D05
;	BCLR	#$06,lbB057D1B
;	BRA	lbC057C72
;
;lbC057C62:
;	BSET	#$06,lbB057D05
;	BSET	#$06,lbB057D1B
;lbC057C72:
;	LSR.B	#$01,D0
;	BCS	lbC057C8C
;	BCLR	#$06,lbB057D09
;	BCLR	#$06,lbB057D1D
;	BRA	lbC057C9C
;
;lbC057C8C:
;	BSET	#$06,lbB057D09
;	BSET	#$06,lbB057D1D
;lbC057C9C:
;	LSR.B	#$01,D0
;	BCS	lbC057CB6
;	BCLR	#$06,lbB057D0D
;	BCLR	#$06,lbB057D21
;	BRA	lbC057CC6
;
;lbC057CB6:
;	BSET	#$06,lbB057D0D
;	BSET	#$06,lbB057D21
;lbC057CC6:
;	LSR.B	#$01,D0
;	BCS	lbC057CE0
;	BCLR	#$06,lbB057D11
;	BCLR	#$06,lbB057D25
;	BRA	lbC057CF0
;
;lbC057CE0:
;	BSET	#$06,lbB057D11
;	BSET	#$06,lbB057D25
;lbC057CF0:
	ext.w	d0
	lsl.w	#5,d0
	addq	#2,d0
	move.w	d0,plotPixelOffset
	RTS

plotPixel:
	MOVE.B	D4,D0
;	AND.W	#$000F,D0
;	EOR.W	#$000F,D0
;	CMP.W	#$0008,D0
;	BGE	.highByte
;	dc.b	$01					; BSET/BCLR $D0,$0001(A0)
;lbB057D05:
;	dc.b	$E8,$00,$01,$01				; BSET/BCLR D0,$1F41(A0)
;lbB057D09:
;	dc.b	$E8,$1F,$41,$01				; BSET/BCLR D0,$3E81(A0)
;lbB057D0D:
;	dc.b	$E8,$3E,$81,$01				; BSET/BCLR D0,$5DC1(A0)
;lbB057D11:
;	dc.b	$E8,$5D,$C1
	move.w	d1,-(sp)
	move.w	plotPixelOffset,d1
	not.b	d0
	btst	#3,d0
	bne	.highByte
	jmp	(pc,d1.w)
	bclr	d0,$0001(a0)
	bclr	d0,$1f41(a0)
	bclr	d0,$3e81(a0)
	bclr	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0001(a0)
	bclr	d0,$1f41(a0)
	bclr	d0,$3e81(a0)
	bclr	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bclr	d0,$0001(a0)
	bset	d0,$1f41(a0)
	bclr	d0,$3e81(a0)
	bclr	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0001(a0)
	bset	d0,$1f41(a0)
	bclr	d0,$3e81(a0)
	bclr	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bclr	d0,$0001(a0)
	bclr	d0,$1f41(a0)
	bset	d0,$3e81(a0)
	bclr	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0001(a0)
	bclr	d0,$1f41(a0)
	bset	d0,$3e81(a0)
	bclr	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bclr	d0,$0001(a0)
	bset	d0,$1f41(a0)
	bset	d0,$3e81(a0)
	bclr	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0001(a0)
	bset	d0,$1f41(a0)
	bset	d0,$3e81(a0)
	bclr	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bclr	d0,$0001(a0)
	bclr	d0,$1f41(a0)
	bclr	d0,$3e81(a0)
	bset	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0001(a0)
	bclr	d0,$1f41(a0)
	bclr	d0,$3e81(a0)
	bset	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bclr	d0,$0001(a0)
	bset	d0,$1f41(a0)
	bclr	d0,$3e81(a0)
	bset	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0001(a0)
	bset	d0,$1f41(a0)
	bclr	d0,$3e81(a0)
	bset	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bclr	d0,$0001(a0)
	bclr	d0,$1f41(a0)
	bset	d0,$3e81(a0)
	bset	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0001(a0)
	bclr	d0,$1f41(a0)
	bset	d0,$3e81(a0)
	bset	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bclr	d0,$0001(a0)
	bset	d0,$1f41(a0)
	bset	d0,$3e81(a0)
	bset	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0001(a0)
	bset	d0,$1f41(a0)
	bset	d0,$3e81(a0)
	bset	d0,$5dc1(a0)
	move.w	(sp)+,d1
	RTS

.highByte:
;	AND.W	#$0007,D0
;	dc.b	$01					; BSET/BCLR D0,(A0)
;lbB057D1B:
;	dc.b	$D0,$01					; BSET/BCLR D0,$1F40(A0)
;lbB057D1D:
;	dc.b	$E8,$1F,$40,$01				; BSET/BCLR D0,$3E80(A0)
;lbB057D21:
;	dc.b	$E8,$3E,$80,$01				; BSET/BCLR D0,$5DC0(A0)
;lbB057D25:
;	dc.b	$E8,$5D,$C0
	jmp	(pc,d1.w)
	bclr	d0,$0000(a0)
	bclr	d0,$1f40(a0)
	bclr	d0,$3e80(a0)
	bclr	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0000(a0)
	bclr	d0,$1f40(a0)
	bclr	d0,$3e80(a0)
	bclr	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bclr	d0,$0000(a0)
	bset	d0,$1f40(a0)
	bclr	d0,$3e80(a0)
	bclr	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0000(a0)
	bset	d0,$1f40(a0)
	bclr	d0,$3e80(a0)
	bclr	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bclr	d0,$0000(a0)
	bclr	d0,$1f40(a0)
	bset	d0,$3e80(a0)
	bclr	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0000(a0)
	bclr	d0,$1f40(a0)
	bset	d0,$3e80(a0)
	bclr	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bclr	d0,$0000(a0)
	bset	d0,$1f40(a0)
	bset	d0,$3e80(a0)
	bclr	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0000(a0)
	bset	d0,$1f40(a0)
	bset	d0,$3e80(a0)
	bclr	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bclr	d0,$0000(a0)
	bclr	d0,$1f40(a0)
	bclr	d0,$3e80(a0)
	bset	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0000(a0)
	bclr	d0,$1f40(a0)
	bclr	d0,$3e80(a0)
	bset	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bclr	d0,$0000(a0)
	bset	d0,$1f40(a0)
	bclr	d0,$3e80(a0)
	bset	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0000(a0)
	bset	d0,$1f40(a0)
	bclr	d0,$3e80(a0)
	bset	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bclr	d0,$0000(a0)
	bclr	d0,$1f40(a0)
	bset	d0,$3e80(a0)
	bset	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0000(a0)
	bclr	d0,$1f40(a0)
	bset	d0,$3e80(a0)
	bset	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bclr	d0,$0000(a0)
	bset	d0,$1f40(a0)
	bset	d0,$3e80(a0)
	bset	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS
	nop
	nop
	nop
	nop
	nop
	nop
	bset	d0,$0000(a0)
	bset	d0,$1f40(a0)
	bset	d0,$3e80(a0)
	bset	d0,$5dc0(a0)
	move.w	(sp)+,d1
	RTS

drawHorizontalLine:
	JSR	setPixelColor
	MOVE.L	renderFrameBuffer,A0
	MOVE.W	D4,D0
	EXT.L	D0
	EXT.L	D5
	LSR.L	#$03,D0
	AND.B	#$FE,D0
	ADD.L	D0,A0
	MOVE.L	D5,D0
	ASL.L	#$02,D0
	ADD.L	D5,D0
	ASL.L	#$03,D0
	ADD.L	D0,A0
.loop:	JSR	plotPixel
	ADDQ.W	#$01,D4
	MOVE.B	D4,D0
	AND.B	#$0F,D0
	BNE	.wordOk
	ADD.L	#$00000002,A0
.wordOk:
	CMP.W	D4,D6
	BNE	.loop
	RTS

applyBitplaneMask:
	MOVE.W	D4,D2
	NOT.W	D2
	moveq	#0,d0
	move.b	lbB057D75,d0
	jmp	(pc,d0.w)
;	dc.w	$6000					; original BRA.W + self modifying code
;	ds.b	1
;lbB057D75:
;	dc.b	$02

lbC057D76:
	AND.W	D2,(A4)+
	AND.W	D2,$1F3E(A4)
	AND.W	D2,$3E7E(A4)
	AND.W	D2,$5DBE(A4)
	RTS

	OR.W	D4,(A4)+
	AND.W	D2,$1F3E(A4)
	AND.W	D2,$3E7E(A4)
	AND.W	D2,$5DBE(A4)
	RTS

	AND.W	D2,(A4)+
	OR.W	D4,$1F3E(A4)
	AND.W	D2,$3E7E(A4)
	AND.W	D2,$5DBE(A4)
	RTS

	OR.W	D4,(A4)+
	OR.W	D4,$1F3E(A4)
	AND.W	D2,$3E7E(A4)
	AND.W	D2,$5DBE(A4)
	RTS

	AND.W	D2,(A4)+
	AND.W	D2,$1F3E(A4)
	OR.W	D4,$3E7E(A4)
	AND.W	D2,$5DBE(A4)
	RTS

	OR.W	D4,(A4)+
	AND.W	D2,$1F3E(A4)
	OR.W	D4,$3E7E(A4)
	AND.W	D2,$5DBE(A4)
	RTS

	AND.W	D2,(A4)+
	OR.W	D4,$1F3E(A4)
	OR.W	D4,$3E7E(A4)
	AND.W	D2,$5DBE(A4)
	RTS

	OR.W	D4,(A4)+
	OR.W	D4,$1F3E(A4)
	OR.W	D4,$3E7E(A4)
	AND.W	D2,$5DBE(A4)
	RTS

	AND.W	D2,(A4)+
	AND.W	D2,$1F3E(A4)
	AND.W	D2,$3E7E(A4)
	OR.W	D4,$5DBE(A4)
	RTS

	OR.W	D4,(A4)+
	AND.W	D2,$1F3E(A4)
	AND.W	D2,$3E7E(A4)
	OR.W	D4,$5DBE(A4)
	RTS

	AND.W	D2,(A4)+
	OR.W	D4,$1F3E(A4)
	AND.W	D2,$3E7E(A4)
	OR.W	D4,$5DBE(A4)
	RTS

	OR.W	D4,(A4)+
	OR.W	D4,$1F3E(A4)
	AND.W	D2,$3E7E(A4)
	OR.W	D4,$5DBE(A4)
	RTS

	AND.W	D2,(A4)+
	AND.W	D2,$1F3E(A4)
	OR.W	D4,$3E7E(A4)
	OR.W	D4,$5DBE(A4)
	RTS

	OR.W	D4,(A4)+
	AND.W	D2,$1F3E(A4)
	OR.W	D4,$3E7E(A4)
	OR.W	D4,$5DBE(A4)
	RTS

	AND.W	D2,(A4)+
	OR.W	D4,$1F3E(A4)
	OR.W	D4,$3E7E(A4)
	OR.W	D4,$5DBE(A4)
	RTS

	OR.W	D4,(A4)+
	OR.W	D4,$1F3E(A4)
	OR.W	D4,$3E7E(A4)
	OR.W	D4,$5DBE(A4)
	RTS

fillHorizontalSpan:
	CMP.W	D4,D5
	BGT	lbC057E8E
	BEQ	lbC057F12
	TST.B	trackRenderingEnableFlag
	BPL	lbC057F12
	BRA	lbC057F12

lbC057E8E:
	MOVE.W	D4,D1
	AND.W	#$00F0,D1
	LSR.W	#$03,D1
	LEA	$00(A6,D1.W),A4
	MOVE.W	D4,D3
	MOVE.W	D5,D1
	LSR.W	#$04,D3
	LSR.W	#$04,D1
	SUB.W	D3,D1
	BNE	lbC057EC8
	AND.W	#$000F,D4
	ASL.W	#$02,D4
	MOVE.W	$00(A5,D4.W),D4
	AND.W	#$000F,D5
	ASL.W	#$02,D5
	MOVE.W	$40(A5,D5.W),D5
	AND.W	D5,D4
	JSR	applyBitplaneMask
	BRA	lbC057F12

lbC057EC8:
	SUBQ.B	#$01,D1
	AND.W	#$000F,D4
	BEQ	lbC057EE4
	ASL.W	#$02,D4
	MOVE.W	$00(A5,D4.W),D4
	JSR	applyBitplaneMask
	SUBQ.W	#$01,D1
	BMI	lbC057EFE
lbC057EE4:
	MOVE.L	D6,D2
	MOVE.L	D7,D3
	SWAP	D2
	SWAP	D3
lbC057EEC:
	MOVE.W	D2,(A4)+
	MOVE.W	D6,$1F3E(A4)
	MOVE.W	D3,$3E7E(A4)
	MOVE.W	D7,$5DBE(A4)
	DBRA	D1,lbC057EEC
lbC057EFE:
	AND.W	#$000F,D5
	BEQ	lbC057F12
	ASL.W	#$02,D5
	MOVE.W	$40(A5,D5.W),D4
	JSR	applyBitplaneMask
lbC057F12:
	CLR.L	D1
	CLR.L	D2
	RTS

renderQuadrilateral:
	MOVE.W	(A2),D2
	MOVE.W	(A0),D0
	CMP.W	(A3),D0
	BNE	lbC057F36
	CMP.W	(A1),D2
	BNE	lbC057F5E
	CMP.W	D2,D0
	BGE	lbC057F5E
lbC057F2E:
	EXG	A2,A0
	EXG	A3,A1
	BRA	lbC057F5E

lbC057F36:
	BLT	lbC057F4E
	CMP.W	(A1),D2
	BEQ	lbC057F2E
	EXG	D0,A0
	MOVE.L	A1,A0
	MOVE.L	A2,A1
	MOVE.L	A3,A2
	MOVE.L	D0,A3
	BRA	lbC057F5E

lbC057F4E:
	CMP.W	(A1),D2
	BEQ	lbC057F2E
	EXG	D0,A3
	MOVE.L	A2,A3
	MOVE.L	A1,A2
	MOVE.L	A0,A1
	MOVE.L	D0,A0
lbC057F5E:
	MOVE.B	#$02,lbB0581A0
scanlinePolygonFill:
	MOVE.L	#lbW0580E0,A5
	MOVE.W	(A0)+,D1
	MOVE.W	(A3)+,D0
	CMP.W	D1,D0
	BNE	lbC0580DA
	ADDQ.L	#$06,A0
	ADDQ.L	#$06,A3
	MOVE.W	D1,polygonFillStartY
	SUBQ.W	#$01,D1
	BMI	lbC0580DA
	MOVE.L	viewportTopAddress,A6
	CLR.L	D0
	MOVE.W	D1,D0
	ASL.W	#$02,D0
	ADD.W	D1,D0
	ASL.W	#$03,D0
	ADD.L	D0,A6
lbC057F98:
	MOVE.W	(A0)+,D4
	BPL	lbC057FE0
	SUBQ.B	#$01,lbB0581A0
	BMI	lbC0580DA
	MOVE.L	A1,A0
	MOVE.L	A2,A1
	MOVE.W	(A0)+,D0
	CMP.W	polygonFillStartY,D0
	BNE	lbC0580DA
	ADDQ.L	#$06,A0
	MOVE.W	(A0)+,D4
	BPL	lbC057FE0
	SUBQ.B	#$01,lbB0581A0
	BMI	lbC0580DA
	MOVE.L	A1,A0
	MOVE.W	(A0)+,D0
	CMP.W	polygonFillStartY,D0
	BNE	lbC0580DA
	ADDQ.L	#$06,A0
	MOVE.W	(A0)+,D4
	BMI	lbC0580DA
lbC057FE0:
	MOVE.W	(A3)+,D5
	BPL	lbC058028
	SUBQ.B	#$01,lbB0581A0
	BMI	lbC0580DA
	MOVE.L	A2,A3
	MOVE.L	A1,A2
	MOVE.W	(A3)+,D0
	CMP.W	polygonFillStartY,D0
	BNE	lbC0580DA
	ADDQ.L	#$06,A3
	MOVE.W	(A3)+,D5
	BPL	lbC058028
	SUBQ.B	#$01,lbB0581A0
	BMI	lbC0580DA
	MOVE.L	A2,A3
	MOVE.W	(A3)+,D0
	CMP.W	polygonFillStartY,D0
	BNE	lbC0580DA
	ADDQ.L	#$06,A3
	MOVE.W	(A3)+,D5
	BMI	lbC0580DA
lbC058028:
	CMP.W	D4,D5
	BGT	lbC058040
	BEQ	lbC0580C4
	TST.B	trackRenderingEnableFlag
	BPL	lbC0580C4
	BRA	lbC0580DA

lbC058040:
	MOVE.W	D4,D1
	AND.W	#$00F0,D1
	LSR.W	#$03,D1
	LEA	$00(A6,D1.W),A4
	MOVE.W	D4,D3
	MOVE.W	D5,D1
	LSR.W	#$04,D3
	LSR.W	#$04,D1
	SUB.W	D3,D1
	BNE	lbC05807A
	AND.W	#$000F,D4
	ASL.W	#$02,D4
	MOVE.W	$00(A5,D4.W),D4
	AND.W	#$000F,D5
	ASL.W	#$02,D5
	MOVE.W	$40(A5,D5.W),D5
	AND.W	D5,D4
	JSR	applyBitplaneMask
	BRA	lbC0580C4

lbC05807A:
	SUBQ.B	#$01,D1
	AND.W	#$000F,D4
	BEQ	lbC058096
	ASL.W	#$02,D4
	MOVE.W	$00(A5,D4.W),D4
	JSR	applyBitplaneMask
	SUBQ.W	#$01,D1
	BMI	lbC0580B0
lbC058096:
	MOVE.L	D6,D2
	MOVE.L	D7,D3
	SWAP	D2
	SWAP	D3
lbC05809E:
	MOVE.W	D2,(A4)+
	MOVE.W	D6,$1F3E(A4)
	MOVE.W	D3,$3E7E(A4)
	MOVE.W	D7,$5DBE(A4)
	DBRA	D1,lbC05809E
lbC0580B0:
	AND.W	#$000F,D5
	BEQ	lbC0580C4
	ASL.W	#$02,D5
	MOVE.W	$40(A5,D5.W),D4
	JSR	applyBitplaneMask
lbC0580C4:
	SUBQ.W	#$01,polygonFillStartY
	SUB.L	#$00000028,A6
	CMP.L	viewportTopAddress,A6
	BGE	lbC057F98
lbC0580DA:
	CLR.L	D1
	CLR.L	D2
	RTS

drawClippedLine:
	MOVE.L	#renderCommandQueue,A1
	MOVE.W	#$0000,lbW0581A6
	MOVE.W	#$FFFF,lbW0581A2
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	lineDrawingBufferPointer,A0
	CMP.L	#lineDrawingBufferEnd,A0
	BLT	.drawLine
	TST.B	lineDrawingModeFlag
	BMI	.drawLine
	MOVE.L	#$80000000,$00(A1,D0.W)
	CLR.W	D1
	CLR.W	D2
	RTS

.drawLine:
	MOVE.L	A0,$00(A1,D0.W)
	MOVE.L	A0,A2
	ADD.L	#$00000008,A0
	MOVE.L	#coordinateLookupTable,A4
	MOVE.L	#transformedVertexBounds,A5
	MOVE.W	$00(A4,D1.W),D4
	MOVE.W	$00(A4,D2.W),D6
	MOVE.W	$00(A5,D1.W),D5
	MOVE.W	$00(A5,D2.W),D7
	CMP.W	D7,D5
	BGE	lbC058224
	EXG	D7,D5
	EXG	D6,D4
	OR.B	#$40,$00(A1,D0.W)
lbC058224:
	MOVE.W	#$0000,D0
	MOVE.W	D0,D3
	CMP.W	#$0100,D4
	BCS	lbC058244
	TST.W	D4
	BPL	lbC058240
	BSET	#$03,D0
	BRA	lbC058244

lbC058240:
	BSET	#$02,D0
lbC058244:
	CMP.W	#$0100,D6
	BCS	lbC05825E
	TST.W	D6
	BPL	lbC05825A
	BSET	#$03,D3
	BRA	lbC05825E

lbC05825A:
	BSET	#$02,D3
lbC05825E:
	CMP.W	#$0080,D5
	BCS	lbC058278
	TST.W	D5
	BPL	lbC058274
	BSET	#$01,D0
	BRA	lbC058278

lbC058274:
	BSET	#$00,D0
lbC058278:
	CMP.W	#$0080,D7
	BCS	lbC058292
	TST.W	D7
	BPL	lbC05828E
	BSET	#$01,D3
	BRA	lbC058292

lbC05828E:
	BSET	#$00,D3
lbC058292:
	MOVE.B	D0,D1
	MOVE.B	D3,D2
	SWAP	D0
	MOVE.B	D1,D0
	OR.B	D2,D0
	AND.B	#$0F,D0
	BEQ	lbC058736
	MOVE.B	D1,D0
	AND.B	D2,D0
	AND.B	#$0F,D0
	BEQ	lbC0582BC
	JSR	outputClippedLine
	CLR.W	D1
	CLR.W	D2
	RTS

lbC0582BC:
	SWAP	D0
	BTST	#$01,D1
	BEQ	lbC058328
	BCLR	#$07,D1
	MOVE.W	D6,D0
	SUB.W	D4,D0
	BPL	lbC0582D8
	BSET	#$07,D1
	NEG.W	D0
lbC0582D8:
	MOVE.W	D7,D3
	SUB.W	D5,D3
	BPL	lbC0582E6
	BCHG	#$07,D1
	NEG.W	D3
lbC0582E6:
	NEG.W	D5
	CMP.W	D0,D3
	BLT	lbC058300
	BEQ	lbC058316
	SWAP	D0
	CLR.W	D0
	DIVU	D3,D0
	MULU	D0,D5
	SWAP	D5
	BRA	lbC058316

lbC058300:
	CMP.W	D3,D5
	BLT	lbC05830C
	MOVE.W	D0,D5
	BRA	lbC058316

lbC05830C:
	SWAP	D5
	CLR.W	D5
	DIVU	D3,D5
	MULU	D0,D5
	SWAP	D5
lbC058316:
	TST.B	D1
	BPL	lbC05831E
	NEG.W	D5
lbC05831E:
	ADD.W	D5,D4
	MOVE.W	#$0000,D5
	BRA	lbC058390

lbC058328:
	BTST	#$00,D1
	BEQ	lbC0583D6
	BCLR	#$07,D1
	MOVE.W	D6,D0
	SUB.W	D4,D0
	BPL	lbC058342
	BSET	#$07,D1
	NEG.W	D0
lbC058342:
	MOVE.W	D7,D3
	SUB.W	D5,D3
	BPL	lbC058350
	BCHG	#$07,D1
	NEG.W	D3
lbC058350:
	SUB.W	#$0080,D5
	CMP.W	D0,D3
	BLT	lbC05836C
	BEQ	lbC058382
	SWAP	D0
	CLR.W	D0
	DIVU	D3,D0
	MULU	D0,D5
	SWAP	D5
	BRA	lbC058382

lbC05836C:
	CMP.W	D3,D5
	BLT	lbC058378
	MOVE.W	D0,D5
	BRA	lbC058382

lbC058378:
	SWAP	D5
	CLR.W	D5
	DIVU	D3,D5
	MULU	D0,D5
	SWAP	D5
lbC058382:
	TST.B	D1
	BMI	lbC05838A
	NEG.W	D5
lbC05838A:
	ADD.W	D5,D4
	MOVE.W	#$0080,D5
lbC058390:
	AND.B	#$F0,D1
	CMP.W	#$0100,D4
	BCS	lbC0583AE
	TST.W	D4
	BPL	lbC0583AA
	BSET	#$03,D1
	BRA	lbC0583AE

lbC0583AA:
	BSET	#$02,D1
lbC0583AE:
	SWAP	D0
	MOVE.B	D1,D0
	OR.B	D2,D0
	AND.B	#$0F,D0
	BEQ	lbC058736
	MOVE.B	D1,D0
	AND.B	D2,D0
	AND.B	#$0F,D0
	BEQ	lbC0583D4
	JSR	outputClippedLine
	CLR.W	D1
	CLR.W	D2
	RTS

lbC0583D4:
	SWAP	D0
lbC0583D6:
	BTST	#$01,D2
	BEQ	lbC058440
	BCLR	#$07,D1
	MOVE.W	D6,D0
	SUB.W	D4,D0
	BPL	lbC0583F0
	BSET	#$07,D1
	NEG.W	D0
lbC0583F0:
	MOVE.W	D7,D3
	SUB.W	D5,D3
	BPL	lbC0583FE
	BCHG	#$07,D1
	NEG.W	D3
lbC0583FE:
	NEG.W	D7
	CMP.W	D0,D3
	BLT	lbC058418
	BEQ	lbC05842E
	SWAP	D0
	CLR.W	D0
	DIVU	D3,D0
	MULU	D0,D7
	SWAP	D7
	BRA	lbC05842E

lbC058418:
	CMP.W	D3,D7
	BLT	lbC058424
	MOVE.W	D0,D7
	BRA	lbC05842E

lbC058424:
	SWAP	D7
	CLR.W	D7
	DIVU	D3,D7
	MULU	D0,D7
	SWAP	D7
lbC05842E:
	TST.B	D1
	BPL	lbC058436
	NEG.W	D7
lbC058436:
	ADD.W	D7,D6
	MOVE.W	#$0000,D7
	BRA	lbC0584A8

lbC058440:
	BTST	#$00,D2
	BEQ	lbC0584EE
	BCLR	#$07,D1
	MOVE.W	D6,D0
	SUB.W	D4,D0
	BPL	lbC05845A
	BSET	#$07,D1
	NEG.W	D0
lbC05845A:
	MOVE.W	D7,D3
	SUB.W	D5,D3
	BPL	lbC058468
	BCHG	#$07,D1
	NEG.W	D3
lbC058468:
	SUB.W	#$0080,D7
	CMP.W	D0,D3
	BLT	lbC058484
	BEQ	lbC05849A
	SWAP	D0
	CLR.W	D0
	DIVU	D3,D0
	MULU	D0,D7
	SWAP	D7
	BRA	lbC05849A

lbC058484:
	CMP.W	D3,D7
	BLT	lbC058490
	MOVE.W	D0,D7
	BRA	lbC05849A

lbC058490:
	SWAP	D7
	CLR.W	D7
	DIVU	D3,D7
	MULU	D0,D7
	SWAP	D7
lbC05849A:
	TST.B	D1
	BMI	lbC0584A2
	NEG.W	D7
lbC0584A2:
	ADD.W	D7,D6
	MOVE.W	#$0080,D7
lbC0584A8:
	AND.B	#$F0,D2
	CMP.W	#$0100,D6
	BCS	lbC0584C6
	TST.W	D6
	BPL	lbC0584C2
	BSET	#$03,D2
	BRA	lbC0584C6

lbC0584C2:
	BSET	#$02,D2
lbC0584C6:
	SWAP	D0
	MOVE.B	D1,D0
	OR.B	D2,D0
	AND.B	#$0F,D0
	BEQ	lbC058736
	MOVE.B	D1,D0
	AND.B	D2,D0
	AND.B	#$0F,D0
	BEQ	lbC0584EC
	JSR	outputClippedLine
	CLR.W	D1
	CLR.W	D2
	RTS

lbC0584EC:
	SWAP	D0
lbC0584EE:
	MOVE.W	D5,(A2)
	MOVE.W	D7,$0002(A2)
	SUBQ.B	#$01,lbW0581A6
	BTST	#$03,D1
	BEQ	lbC058588
	MOVE.W	D5,-(SP)
	BCLR	#$07,D1
	MOVE.W	D6,D0
	SUB.W	D4,D0
	BPL	lbC058516
	BSET	#$07,D1
	NEG.W	D0
lbC058516:
	MOVE.W	D7,D3
	SUB.W	D5,D3
	BPL	lbC058524
	BCHG	#$07,D1
	NEG.W	D3
lbC058524:
	NEG.W	D4
	CMP.W	D3,D0
	BLT	lbC05853E
	BEQ	lbC058554
	SWAP	D3
	CLR.W	D3
	DIVU	D0,D3
	MULU	D3,D4
	SWAP	D4
	BRA	lbC058554

lbC05853E:
	CMP.W	D0,D4
	BLT	lbC05854A
	MOVE.W	D3,D4
	BRA	lbC058554

lbC05854A:
	SWAP	D4
	CLR.W	D4
	DIVU	D0,D4
	MULU	D3,D4
	SWAP	D4
lbC058554:
	TST.B	D1
	BPL	lbC05855C
	NEG.W	D4
lbC05855C:
	ADD.W	D4,D5
	MOVE.W	#$0000,D4
	MOVE.W	(SP)+,D3
	TST.B	lineDrawingModeFlag
	BPL	lbC058572
	MOVE.W	D5,D3
	MOVE.W	D5,(A2)
lbC058572:
	SUB.W	D5,D3
	BMI	lbC058584
	BRA	lbC058580

lbC05857C:
	MOVE.W	#$0000,(A0)+
lbC058580:
	DBRA	D3,lbC05857C
lbC058584:
	BRA	lbC058614

lbC058588:
	BTST	#$02,D1
	BEQ	lbC058614
	MOVE.W	D5,-(SP)
	BCLR	#$07,D1
	MOVE.W	D6,D0
	SUB.W	D4,D0
	BPL	lbC0585A4
	BSET	#$07,D1
	NEG.W	D0
lbC0585A4:
	MOVE.W	D7,D3
	SUB.W	D5,D3
	BPL	lbC0585B2
	BCHG	#$07,D1
	NEG.W	D3
lbC0585B2:
	SUB.W	#$0100,D4
	CMP.W	D3,D0
	BLT	lbC0585CE
	BEQ	lbC0585E4
	SWAP	D3
	CLR.W	D3
	DIVU	D0,D3
	MULU	D3,D4
	SWAP	D4
	BRA	lbC0585E4

lbC0585CE:
	CMP.W	D0,D4
	BLT	lbC0585DA
	MOVE.W	D3,D4
	BRA	lbC0585E4

lbC0585DA:
	SWAP	D4
	CLR.W	D4
	DIVU	D0,D4
	MULU	D3,D4
	SWAP	D4
lbC0585E4:
	TST.B	D1
	BMI	lbC0585EC
	NEG.W	D4
lbC0585EC:
	ADD.W	D4,D5
	MOVE.W	#$0100,D4
	MOVE.W	(SP)+,D3
	TST.B	lineDrawingModeFlag
	BPL	lbC058602
	MOVE.W	D5,D3
	MOVE.W	D5,(A2)
lbC058602:
	SUB.W	D5,D3
	BMI	lbC058614
	BRA	lbC058610

lbC05860C:
	MOVE.W	#$0100,(A0)+
lbC058610:
	DBRA	D3,lbC05860C
lbC058614:
	BTST	#$03,D2
	BEQ	lbC0586A6
	MOVE.W	D7,-(SP)
	BCLR	#$07,D1
	MOVE.W	D6,D0
	SUB.W	D4,D0
	BPL	lbC058630
	BSET	#$07,D1
	NEG.W	D0
lbC058630:
	MOVE.W	D7,D3
	SUB.W	D5,D3
	BPL	lbC05863E
	BCHG	#$07,D1
	NEG.W	D3
lbC05863E:
	NEG.W	D6
	CMP.W	D3,D0
	BLT	lbC058658
	BEQ	lbC05866E
	SWAP	D3
	CLR.W	D3
	DIVU	D0,D3
	MULU	D3,D6
	SWAP	D6
	BRA	lbC05866E

lbC058658:
	CMP.W	D0,D6
	BLT	lbC058664
	MOVE.W	D3,D6
	BRA	lbC05866E

lbC058664:
	SWAP	D6
	CLR.W	D6
	DIVU	D0,D6
	MULU	D3,D6
	SWAP	D6
lbC05866E:
	TST.B	D1
	BPL	lbC058676
	NEG.W	D6
lbC058676:
	ADD.W	D6,D7
	MOVE.W	#$0000,D6
	MOVE.W	D7,D3
	SUB.W	(SP)+,D3
	SUBQ.W	#$01,D3
	TST.B	lineDrawingModeFlag
	BPL	lbC058694
	MOVE.W	D7,$0002(A2)
	BRA	lbC0586A2

lbC058694:
	MOVE.W	D3,lbW0581A2
	MOVE.W	#$0000,lbW0581A4
lbC0586A2:
	BRA	lbC058736

lbC0586A6:
	BTST	#$02,D2
	BEQ	lbC058736
	MOVE.W	D7,-(SP)
	BCLR	#$07,D1
	MOVE.W	D6,D0
	SUB.W	D4,D0
	BPL	lbC0586C2
	BSET	#$07,D1
	NEG.W	D0
lbC0586C2:
	MOVE.W	D7,D3
	SUB.W	D5,D3
	BPL	lbC0586D0
	BCHG	#$07,D1
	NEG.W	D3
lbC0586D0:
	SUB.W	#$0100,D6
	CMP.W	D3,D0
	BLT	lbC0586EC
	BEQ	lbC058702
	SWAP	D3
	CLR.W	D3
	DIVU	D0,D3
	MULU	D3,D6
	SWAP	D6
	BRA	lbC058702

lbC0586EC:
	CMP.W	D0,D6
	BLT	lbC0586F8
	MOVE.W	D3,D6
	BRA	lbC058702

lbC0586F8:
	SWAP	D6
	CLR.W	D6
	DIVU	D0,D6
	MULU	D3,D6
	SWAP	D6
lbC058702:
	TST.B	D1
	BMI	lbC05870A
	NEG.W	D6
lbC05870A:
	ADD.W	D6,D7
	MOVE.W	#$0100,D6
	MOVE.W	D7,D3
	SUB.W	(SP)+,D3
	SUBQ.W	#$01,D3
	TST.B	lineDrawingModeFlag
	BPL	lbC058728
	MOVE.W	D7,$0002(A2)
	BRA	lbC058736

lbC058728:
	MOVE.W	D3,lbW0581A2
	MOVE.W	#$0100,lbW0581A4
lbC058736:
	MOVE.W	D5,D2
	SUB.W	D7,D2
	MOVE.W	D4,D1
	SUB.W	D6,D1
	BPL	lbC0587FE
	NEG.W	D1
	CMP.W	D2,D1
	BLT	lbC0587A4
	TST.W	lbW0581A6
	BMI	lbC05875A
	MOVE.W	D5,(A2)
	MOVE.W	D7,$0002(A2)
lbC05875A:
	MOVE.W	D4,$0004(A2)
	MOVE.W	D6,$0006(A2)
	MOVE.W	D1,D3
	LSR.W	#$01,D3
	NOT.W	D3
	BRA	lbC05877A

lbC05876C:
	ADDQ.W	#$01,D4
	ADD.W	D2,D3
	BCC	lbC05877A
	SUB.W	D1,D3
	SUBQ.W	#$01,D5
	MOVE.W	D4,(A0)+
lbC05877A:
	CMP.W	D6,D4
	BNE	lbC05876C
	MOVE.W	lbW0581A2,D0
	BMI	lbC058794
lbC05878A:
	MOVE.W	lbW0581A4,(A0)+
	DBRA	D0,lbC05878A
lbC058794:
	MOVE.W	#$8000,(A0)+
	MOVE.L	A0,lineDrawingBufferPointer
	CLR.W	D1
	CLR.W	D2
	RTS

lbC0587A4:
	TST.W	lbW0581A6
	BMI	lbC0587B4
	MOVE.W	D5,(A2)
	MOVE.W	D7,$0002(A2)
lbC0587B4:
	MOVE.W	D4,$0004(A2)
	MOVE.W	D6,$0006(A2)
	MOVE.W	D2,D3
	LSR.W	#$01,D3
	NOT.W	D3
	BRA	lbC0587D4

lbC0587C6:
	SUBQ.W	#$01,D5
	MOVE.W	D4,(A0)+
	ADD.W	D1,D3
	BCC	lbC0587D4
	SUB.W	D2,D3
	ADDQ.W	#$01,D4
lbC0587D4:
	CMP.W	D7,D5
	BNE	lbC0587C6
	MOVE.W	lbW0581A2,D0
	BMI	lbC0587EE
lbC0587E4:
	MOVE.W	lbW0581A4,(A0)+
	DBRA	D0,lbC0587E4
lbC0587EE:
	MOVE.W	#$8000,(A0)+
	MOVE.L	A0,lineDrawingBufferPointer
	CLR.W	D1
	CLR.W	D2
	RTS

lbC0587FE:
	CMP.W	D2,D1
	BLT	lbC05885E
	TST.W	lbW0581A6
	BMI	lbC058814
	MOVE.W	D5,(A2)
	MOVE.W	D7,$0002(A2)
lbC058814:
	MOVE.W	D4,$0004(A2)
	MOVE.W	D6,$0006(A2)
	MOVE.W	D1,D3
	LSR.W	#$01,D3
	NOT.W	D3
	BRA	lbC058834

lbC058826:
	SUBQ.W	#$01,D4
	ADD.W	D2,D3
	BCC	lbC058834
	SUB.W	D1,D3
	SUBQ.W	#$01,D5
	MOVE.W	D4,(A0)+
lbC058834:
	CMP.W	D6,D4
	BNE	lbC058826
	MOVE.W	lbW0581A2,D0
	BMI	lbC05884E
lbC058844:
	MOVE.W	lbW0581A4,(A0)+
	DBRA	D0,lbC058844
lbC05884E:
	MOVE.W	#$8000,(A0)+
	MOVE.L	A0,lineDrawingBufferPointer
	CLR.W	D1
	CLR.W	D2
	RTS

lbC05885E:
	TST.W	lbW0581A6
	BMI	lbC05886E
	MOVE.W	D5,(A2)
	MOVE.W	D7,$0002(A2)
lbC05886E:
	MOVE.W	D4,$0004(A2)
	MOVE.W	D6,$0006(A2)
	MOVE.W	D2,D3
	LSR.W	#$01,D3
	NOT.W	D3
	BRA	lbC05888E

lbC058880:
	SUBQ.W	#$01,D5
	MOVE.W	D4,(A0)+
	ADD.W	D1,D3
	BCC	lbC05888E
	SUB.W	D2,D3
	SUBQ.W	#$01,D4
lbC05888E:
	CMP.W	D7,D5
	BNE	lbC058880
	MOVE.W	lbW0581A2,D0
	BMI	lbC0588A8
lbC05889E:
	MOVE.W	lbW0581A4,(A0)+
	DBRA	D0,lbC05889E
lbC0588A8:
	MOVE.W	#$8000,(A0)+
	MOVE.L	A0,lineDrawingBufferPointer
	CLR.W	D1
	CLR.W	D2
	RTS

clearRenderBuffers:
	MOVE.L	#lineDrawingBuffer,A0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	A1,A3
	MOVE.L	#$80000000,D0
	MOVE.L	D0,(A3)+
	MOVE.L	D0,(A3)+
	MOVE.L	D0,(A3)+
	MOVE.L	D0,(A3)+
	MOVE.L	D0,(A3)+
	MOVE.L	D0,(A3)+
	MOVE.L	D0,(A3)+
	MOVE.B	#$00,$001E(A1)
	MOVE.L	A0,lineDrawingBufferPointer
	MOVE.W	#$0020,renderCommandQueueOffset
	RTS

manageRenderBounds:
	MOVE.B	#$FF,previousSegmentOffset
	MOVE.W	renderCommandQueueOffset,D0
calculateRenderDepth:
	MOVE.L	#renderCommandQueue,A0
	SUB.W	#$0020,D0
	CMP.W	#$FF00,minBoundaryDistance
	BLT	lbC058922
	BTST	#$05,$1E(A1,D0.W)
	BNE	lbC058922
	SUB.W	#$0020,D0
lbC058922:
	AND.W	#$FFE0,D0
	MOVE.W	D0,opponentSegmentQueueOffset
	RTS

processTrackSegments:
	MOVE.B	#$FF,D4
	MOVE.B	lbB00D4A6,D0
	CMP.B	currentSegmentIndex,D0
	BNE	lbC05894A
	MOVE.B	lbB00D524,D4
	ASL.B	#$02,D4
lbC05894A:
	MOVE.B	D4,previousSegmentOffset
	MOVE.B	#$00,processedSegmentIndices1
	MOVE.W	#$0030,renderCommandQueueOffset
	MOVE.B	renderingLoopIndex,D1
	BEQ	lbC058A14
	MOVE.L	#segmentProcessedFlags,A3
	MOVE.W	D1,D0
	BRA	lbC05897C

lbC058976:
	MOVE.B	#$80,$00(A3,D0.W)
lbC05897C:
	SUBQ.W	#$04,D0
	BPL	lbC058976
	MOVE.B	D1,D0
	LSR.B	#$02,D0
	SUBQ.B	#$01,D0
	ADD.B	D0,segmentDepthCounter
	BRA	lbC058A14

generateTrackEdgeLines:
	MOVE.L	#segmentProcessedFlags,A3
	CMP.W	#$05E0,renderCommandQueueOffset
	BCC	lbC058D5E
	MOVE.B	#$FF,D4
	MOVE.B	lbB00D4A6,D0
	CMP.B	currentSegmentIndex,D0
	BNE	lbC0589C0
	MOVE.B	lbB00D524,D4
	ASL.B	#$02,D4
lbC0589C0:
	MOVE.B	D4,previousSegmentOffset
	TST.B	previousSegmentOffset
	BNE	lbC0589D6
	JSR	manageRenderBounds
lbC0589D6:
	MOVE.B	#$00,processedSegmentIndices1
	MOVE.W	#$0004,D1
lbC0589E2:
	TST.W	$00(A6,D1.W)
	BPL	lbC058A14
lbC0589EA:
	MOVE.B	#$80,$00(A3,D1.W)
	CMP.B	previousSegmentOffset,D1
	BCS	lbC058A00
	JSR	manageRenderBounds
lbC058A00:
	ADDQ.B	#$04,D1
	ADDQ.B	#$01,segmentDepthCounter
	CMP.B	trackSegmentLimitDoubled,D1
	BLT	lbC0589E2
	RTS

lbC058A14:
	MOVE.B	processedSegmentIndices1,D2
	MOVE.B	D1,tempByte5
	MOVE.B	segmentAlternateFlag,D0
	ASL.B	#$01,D0
	EOR.B	D1,D0
	AND.B	#$04,D0
	MOVE.B	D0,segmentAlternateRenderFlag
	MOVE.L	#segmentProcessedFlags,A3
	MOVE.B	$00(A3,D1.W),segmentProcessedFlag
	JSR	adjustCoordinateBoundsFromCenter
	CMP.W	#$0030,renderCommandQueueOffset
	BEQ	lbC058B84
	TST.W	$00(A6,D2.W)
	BMI	lbC058A84
	TST.W	$00(A6,D1.W)
	BMI	lbC058A84
	MOVE.B	D2,D2
	ADD.B	#$00,D2
	ADD.B	#$00,D1
	JSR	drawClippedLine
	MOVE.B	tempByte5,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058A98

lbC058A84:
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058A98:
	ADD.W	#$0004,renderCommandQueueOffset
	TST.W	$02(A6,D2.W)
	BMI	lbC058AD0
	TST.W	$02(A6,D1.W)
	BMI	lbC058AD0
	MOVE.B	D2,D2
	ADD.B	#$02,D2
	ADD.B	#$02,D1
	JSR	drawClippedLine
	MOVE.B	tempByte5,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058AE4

lbC058AD0:
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058AE4:
	ADD.W	#$0004,renderCommandQueueOffset
	TST.W	$78(A6,D2.W)
	BMI	lbC058B1C
	TST.W	$78(A6,D1.W)
	BMI	lbC058B1C
	MOVE.B	D2,D2
	ADD.B	#$78,D2
	ADD.B	#$78,D1
	JSR	drawClippedLine
	MOVE.B	tempByte5,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058B30

lbC058B1C:
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058B30:
	ADD.W	#$0004,renderCommandQueueOffset
	TST.W	$7A(A6,D2.W)
	BMI	lbC058B68
	TST.W	$7A(A6,D1.W)
	BMI	lbC058B68
	MOVE.B	D2,D2
	ADD.B	#$7A,D2
	ADD.B	#$7A,D1
	JSR	drawClippedLine
	MOVE.B	tempByte5,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058B7C

lbC058B68:
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058B7C:
	ADD.W	#$0004,renderCommandQueueOffset
lbC058B84:
	TST.B	segmentAlternateRenderFlag
	BEQ	drawTrackSegmentWireframe
	TST.B	segmentProcessedFlag
	BPL	drawTrackSegmentWireframe
	BTST	#$06,segmentProcessedFlag
	BNE	drawTrackSegmentWireframe
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D3.W)
	MOVE.L	#$80000000,$04(A1,D3.W)
	ADD.W	#$0008,renderCommandQueueOffset
	BRA	lbC058C64

drawTrackSegmentWireframe:
	TST.W	$78(A6,D1.W)
	BMI	lbC058BFC
	TST.W	$00(A6,D1.W)
	BMI	lbC058BFC
	MOVE.B	D1,D2
	ADD.B	#$78,D2
	ADD.B	#$00,D1
	JSR	drawClippedLine
	MOVE.B	tempByte5,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058C10

lbC058BFC:
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058C10:
	ADD.W	#$0004,renderCommandQueueOffset
	TST.W	$02(A6,D1.W)
	BMI	lbC058C48
	TST.W	$7A(A6,D1.W)
	BMI	lbC058C48
	MOVE.B	D1,D2
	ADD.B	#$02,D2
	ADD.B	#$7A,D1
	JSR	drawClippedLine
	MOVE.B	tempByte5,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058C5C

lbC058C48:
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058C5C:
	ADD.W	#$0004,renderCommandQueueOffset
lbC058C64:
	TST.B	segmentProcessedFlag
	BPL	lbC058C8C
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D3.W)
	ADDQ.W	#$04,renderCommandQueueOffset
	BRA	lbC058CD8

lbC058C8C:
	TST.W	$00(A6,D1.W)
	BMI	lbC058CBC
	TST.W	$02(A6,D1.W)
	BMI	lbC058CBC
	MOVE.B	D1,D2
	ADD.B	#$00,D2
	ADD.B	#$02,D1
	JSR	drawClippedLine
	MOVE.B	tempByte5,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058CD0

lbC058CBC:
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058CD0:
	ADD.W	#$0004,renderCommandQueueOffset
lbC058CD8:
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.B	currentSegmentIndex,$00(A1,D3.W)
	MOVE.B	segmentSteeringFlags,$03(A1,D3.W)
	MOVE.B	#$09,D0
	CMP.B	#$26,segmentDepthCounter
	BLT	lbC058D26
	MOVE.B	#$0A,D0
	CMP.B	#$2A,segmentDepthCounter
	BLT	lbC058D26
	MOVE.B	#$0B,D0
	CMP.B	#$2C,segmentDepthCounter
	BLT	lbC058D26
	OR.B	#$80,D0
	BRA	lbC058D34

lbC058D26:
	TST.B	segmentAlternateRenderFlag
	BEQ	lbC058D34
	MOVE.B	#$03,D0
lbC058D34:
	MOVE.B	D0,$01(A1,D3.W)
	MOVE.B	segmentProcessedFlag,$02(A1,D3.W)
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.L	#segmentProcessedFlags,A3
	MOVE.B	D1,processedSegmentIndices1
	CMP.W	#$05E0,renderCommandQueueOffset
	BCS	lbC0589EA
lbC058D5E:
	RTS

drawTrackLines:
	MOVE.B	#$00,lbB00D467
	MOVE.L	#trackSegmentData,A6
	MOVE.B	#$00,D2
	MOVE.B	#$04,D1
lbC058D76:
	CMP.W	#$05E0,renderCommandQueueOffset
	BCC	lbC059008
	MOVE.B	D1,tempByte5
	MOVE.B	D2,processedSegmentIndices1
	TST.W	$00(A6,D2.W)
	BMI	lbC058DBE
	TST.W	$00(A6,D1.W)
	BMI	lbC058DBE
	MOVE.B	D2,D2
	ADD.B	#$00,D2
	ADD.B	#$00,D1
	JSR	drawClippedLine
	MOVE.B	tempByte5,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058DD2

lbC058DBE:
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058DD2:
	ADD.W	#$0004,renderCommandQueueOffset
	TST.W	$02(A6,D2.W)
	BMI	lbC058E0A
	TST.W	$02(A6,D1.W)
	BMI	lbC058E0A
	MOVE.B	D2,D2
	ADD.B	#$02,D2
	ADD.B	#$02,D1
	JSR	drawClippedLine
	MOVE.B	tempByte5,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058E1E

lbC058E0A:
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058E1E:
	ADD.W	#$0004,renderCommandQueueOffset
	TST.W	$78(A6,D2.W)
	BMI	lbC058E56
	TST.W	$78(A6,D1.W)
	BMI	lbC058E56
	MOVE.B	D2,D2
	ADD.B	#$78,D2
	ADD.B	#$78,D1
	JSR	drawClippedLine
	MOVE.B	tempByte5,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058E6A

lbC058E56:
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058E6A:
	ADD.W	#$0004,renderCommandQueueOffset
	TST.W	$7A(A6,D2.W)
	BMI	lbC058EA2
	TST.W	$7A(A6,D1.W)
	BMI	lbC058EA2
	MOVE.B	D2,D2
	ADD.B	#$7A,D2
	ADD.B	#$7A,D1
	JSR	drawClippedLine
	MOVE.B	tempByte5,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058EB6

lbC058EA2:
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058EB6:
	ADD.W	#$0004,renderCommandQueueOffset
	TST.W	$78(A6,D1.W)
	BMI	lbC058EEE
	TST.W	$00(A6,D1.W)
	BMI	lbC058EEE
	MOVE.B	D1,D2
	ADD.B	#$78,D2
	ADD.B	#$00,D1
	JSR	drawClippedLine
	MOVE.B	tempByte5,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058F02

lbC058EEE:
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058F02:
	ADD.W	#$0004,renderCommandQueueOffset
	TST.W	$02(A6,D1.W)
	BMI	lbC058F3A
	TST.W	$7A(A6,D1.W)
	BMI	lbC058F3A
	MOVE.B	D1,D2
	ADD.B	#$02,D2
	ADD.B	#$7A,D1
	JSR	drawClippedLine
	MOVE.B	tempByte5,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058F4E

lbC058F3A:
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058F4E:
	ADD.W	#$0004,renderCommandQueueOffset
	TST.W	$00(A6,D1.W)
	BMI	lbC058F86
	TST.W	$02(A6,D1.W)
	BMI	lbC058F86
	MOVE.B	D1,D2
	ADD.B	#$00,D2
	ADD.B	#$02,D1
	JSR	drawClippedLine
	MOVE.B	tempByte5,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058F9A

lbC058F86:
	MOVE.W	renderCommandQueueOffset,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058F9A:
	ADD.W	#$0004,renderCommandQueueOffset
	MOVE.L	#renderCommandQueue,A0
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	#segmentRenderBuffer,A3
	MOVE.W	$00(A3,D1.W),tempByte3
	MOVE.B	tempByte4,D0
	MOVE.B	D0,$00(A0,D3.W)
	MOVE.B	tempByte3,$02(A0,D3.W)
	TST.B	lbB00D467
	BNE	lbC058FF4
	CMP.B	lbB00D4A6,D0
	BNE	lbC058FF4
	MOVE.W	D3,D0
	ADDQ.W	#$04,D0
	JSR	calculateRenderDepth
	MOVE.B	#$80,lbB00D467
lbC058FF4:
	ADDQ.W	#$04,renderCommandQueueOffset
	MOVE.B	D1,D2
	ADDQ.B	#$04,D1
	CMP.B	lbB0579FA,D1
	BLT	lbC058D76
lbC059008:
	RTS

setupBitplaneMasks:
	MOVE.B	D0,D6
	ASL.B	#$04,D6
	ADDQ.B	#$02,D6
	MOVE.B	D6,lbB057D75
	CLR.L	D6
	CLR.L	D7
	LSR.B	#$01,D0
	BCC	lbC059022
	NOT.W	D6
lbC059022:
	SWAP	D6
	LSR.B	#$01,D0
	BCC	lbC05902C
	NOT.W	D6
lbC05902C:
	LSR.B	#$01,D0
	BCC	lbC059034
	NOT.W	D7
lbC059034:
	SWAP	D7
	LSR.B	#$01,D0
	BCC	lbC05903E
	NOT.W	D7
lbC05903E:
	RTS

outputClippedLine:
	MOVE.W	renderCommandQueueOffset,D3
	OR.B	#$80,D0
	OR.B	D0,$00(A1,D3.W)
	TST.W	D4
	BPL	lbC059058
	MOVE.W	#$0000,D4
lbC059058:
	CMP.W	#$0100,D4
	BLT	lbC059064
	MOVE.W	#$0100,D4
lbC059064:
	TST.W	D6
	BPL	lbC05906E
	MOVE.W	#$0000,D6
lbC05906E:
	CMP.W	#$0100,D6
	BLT	lbC05907A
	MOVE.W	#$0100,D6
lbC05907A:
	LSR.B	#$01,D0
	BCC	lbC05909E
	MOVE.W	#$0080,(A2)
	MOVE.W	#$0080,$0002(A2)
	MOVE.W	D4,$0004(A2)
	MOVE.W	D6,$0006(A2)
	MOVE.W	#$8000,(A0)+
	MOVE.L	A0,lineDrawingBufferPointer
	RTS

lbC05909E:
	LSR.B	#$01,D0
	BCC	lbC0590BE
	MOVE.L	#$00000000,(A2)
	MOVE.W	D4,$0004(A2)
	MOVE.W	D6,$0006(A2)
	MOVE.W	#$8000,(A0)+
	MOVE.L	A0,lineDrawingBufferPointer
	RTS

lbC0590BE:
	CMP.W	D7,D5
	BGE	lbC0590C6
	EXG	D7,D5
lbC0590C6:
	LSR.B	#$01,D0
	BCC	lbC059126
	TST.W	D5
	BPL	lbC0590D6
	MOVE.W	#$0000,D5
lbC0590D6:
	CMP.W	#$0080,D5
	BCS	lbC0590E2
	MOVE.W	#$0080,D5
lbC0590E2:
	MOVE.W	D5,(A2)
	TST.W	D7
	BPL	lbC0590EE
	MOVE.W	#$0000,D7
lbC0590EE:
	CMP.W	#$0080,D7
	BCS	lbC0590FA
	MOVE.W	#$0080,D7
lbC0590FA:
	MOVE.W	D7,$0002(A2)
	MOVE.W	D4,$0004(A2)
	MOVE.W	D6,$0006(A2)
	MOVE.W	#$0100,D3
	SUB.W	D7,D5
	BPL	lbC059116
	BRA	lbC05911A

lbC059114:
	MOVE.W	D3,(A0)+
lbC059116:
	DBRA	D5,lbC059114
lbC05911A:
	MOVE.W	#$8000,(A0)+
	MOVE.L	A0,lineDrawingBufferPointer
	RTS

lbC059126:
	LSR.B	#$01,D0
	BCC	lbC059186
	TST.W	D5
	BPL	lbC059136
	MOVE.W	#$0000,D5
lbC059136:
	CMP.W	#$0080,D5
	BCS	lbC059142
	MOVE.W	#$0080,D5
lbC059142:
	MOVE.W	D5,(A2)
	TST.W	D7
	BPL	lbC05914E
	MOVE.W	#$0000,D7
lbC05914E:
	CMP.W	#$0080,D7
	BCS	lbC05915A
	MOVE.W	#$0080,D7
lbC05915A:
	MOVE.W	D7,$0002(A2)
	MOVE.W	D4,$0004(A2)
	MOVE.W	D6,$0006(A2)
	MOVE.W	#$0000,D3
	SUB.W	D7,D5
	BPL	lbC059176
	BRA	lbC05917A

lbC059174:
	MOVE.W	D3,(A0)+
lbC059176:
	DBRA	D5,lbC059174
lbC05917A:
	MOVE.W	#$8000,(A0)+
	MOVE.L	A0,lineDrawingBufferPointer
	RTS

lbC059186:
	RTS

renderHorizon:
	MOVE.W	#$0500,D0
	MOVE.W	D0,lbW00D8B6
	NEG.W	D0
	MOVE.W	D0,lbW00D8B4
	MOVE.W	viewportCenterY,D0
	ASR.W	#$03,D0
	NEG.W	D0
	TST.B	lbB00D468
	BMI	lbC0591B0
	SUBQ.W	#$08,D0
lbC0591B0:
	MOVE.W	D0,lbW00D9F4
	MOVE.W	D0,lbW00D9F6
	MOVE.W	#$0004,D1
	JSR	applyScreenSpaceRotation
	MOVE.W	#$0006,D1
	JSR	applyScreenSpaceRotation
	MOVE.W	#$0000,renderCommandQueueOffset
	MOVE.W	#$0004,D1
	MOVE.W	#$0006,D2
	MOVE.B	#$80,lineDrawingModeFlag
	JSR	drawClippedLine
	MOVE.B	#$00,lineDrawingModeFlag
	MOVE.L	lineDrawingBufferPointer,A3
	MOVE.L	A3,A4
	MOVE.L	(A1),D0
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05938A
	MOVE.L	D0,A0
	MOVE.L	A0,A2
	MOVE.W	(A2)+,D0
	MOVE.W	D0,(A4)+
	MOVE.W	D0,polygonFillStartY
	CMP.W	#$0081,D0
	BCC	lbC05938A
	MOVE.W	(A2)+,D3
	MOVE.W	D3,horizonFillStartY
	CMP.W	#$0081,D3
	BCC	lbC05938A
	MOVE.W	D3,(A4)+
	MOVE.W	#$0100,D6
	MOVE.W	lbW00D9F6,D7
	SUB.W	lbW00D9F4,D7
	BPL	lbC05924C
	MOVE.W	#$0000,D6
	EXG	A3,A0
lbC05924C:
	MOVE.W	D6,(A4)+
	MOVE.W	D6,(A4)+
	SUB.W	D3,D0
	BMI	lbC05925C
lbC059256:
	MOVE.W	D6,(A4)+
	DBRA	D0,lbC059256
lbC05925C:
	MOVE.W	#$8000,(A4)+
	MOVEM.L	A0-A2,-(SP)
	MOVE.L	viewportTopAddress,A4
	MOVE.W	horizonFillStartY,D0
	ASL.W	#$02,D0
	ADD.W	horizonFillStartY,D0
	ASL.W	#$03,D0
	LEA	$00(A4,D0.W),A4
	MOVE.W	#$007F,D4
	SUB.W	horizonFillStartY,D4
	BMI	lbC0592F2
	MOVE.B	#$0D,D0
	JSR	setupBitplaneMasks
	JSR	expandMasksToLongwords
fillLoop1:
	LEA	$1F40(A4),A0
	LEA	$3E80(A4),A1
	LEA	$5DC0(A4),A2
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	ADD.L	#$00000008,A4
	DBRA	D4,fillLoop1
lbC0592F2:
	MOVE.B	#$07,D0
	JSR	setupBitplaneMasks
	JSR	expandMasksToLongwords
	MOVE.W	horizonFillStartY,D4
	SUBQ.B	#$01,D4
	BMI	lbC05936A
	MOVE.L	viewportTopAddress,A4
fillLoop2:
	LEA	$1F40(A4),A0
	LEA	$3E80(A4),A1
	LEA	$5DC0(A4),A2
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	MOVE.L	D6,(A4)+
	MOVE.L	D1,(A0)+
	MOVE.L	D7,(A1)+
	MOVE.L	D2,(A2)+
	ADD.L	#$00000008,A4
	DBRA	D4,fillLoop2
lbC05936A:
	MOVE.B	#$00,lbB0581A0
	MOVEM.L	(SP)+,A0-A2
	CLR.W	D1
	CLR.W	D2
	MOVE.B	#$07,D0
	JSR	setupBitplaneMasks
	JMP	scanlinePolygonFill

lbC05938A:
	RTS

expandMasksToLongwords:
	MOVE.L	D6,D0
	MOVE.L	D6,D1
	SWAP	D1
	MOVE.W	D6,D1
	SWAP	D0
	MOVE.W	D0,D6
	MOVE.L	D7,D0
	MOVE.L	D7,D2
	SWAP	D2
	MOVE.W	D7,D2
	SWAP	D0
	MOVE.W	D0,D7
	RTS

renderOpponentCar:
	TST.B	opponentAheadFlag
	BMI	lbC059A42
	MOVE.W	opponentDistance,D0
	CMP.W	#$000A,D0
	BCS	lbC059A42
	CMP.W	#$0C80,D0
	BGE	lbC059A42
	MOVE.W	renderCommandQueueOffset,-(SP)
	MOVE.W	#$05E0,renderCommandQueueOffset
	JSR	clampAndSetupCoordinates
	MOVE.B	#$80,trackRenderingEnableFlag
	MOVE.W	#$05E0,renderCommandQueueOffset
	TST.B	curveSmoothingFlag
	BNE	lbC0594B8
	CMP.W	#$001C,opponentDistanceOffset
	BLT	lbC0594B8
	CMP.W	#$00E4,opponentDistanceOffset
	BGT	lbC0594B8
	ADD.W	#$0080,renderCommandQueueOffset
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	$00(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0594B0
	MOVE.L	D0,A0
	MOVE.L	$04(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0594B0
	MOVE.L	D0,A1
	MOVE.L	$08(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0594B0
	MOVE.L	D0,A2
	MOVE.L	$0C(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0594B0
	MOVE.L	D0,A3
	AND.L	#$0F000000,D4
	BNE	lbC0594B0
	MOVE.B	#$05,D0
	MOVE.B	D0,D6
	ASL.B	#$04,D6
	ADDQ.B	#$02,D6
	MOVE.B	D6,lbB057D75
	CLR.L	D6
	CLR.L	D7
	LSR.B	#$01,D0
	BCC	lbC05948E
	NOT.W	D6
lbC05948E:
	SWAP	D6
	LSR.B	#$01,D0
	BCC	lbC059498
	NOT.W	D6
lbC059498:
	LSR.B	#$01,D0
	BCC	lbC0594A0
	NOT.W	D7
lbC0594A0:
	SWAP	D7
	LSR.B	#$01,D0
	BCC	lbC0594AA
	NOT.W	D7
lbC0594AA:
	JSR	renderQuadrilateral
lbC0594B0:
	SUB.W	#$0080,renderCommandQueueOffset
lbC0594B8:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	$60(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059554
	MOVE.L	D0,A0
	MOVE.L	$64(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059554
	MOVE.L	D0,A1
	MOVE.L	$68(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059554
	MOVE.L	D0,A2
	MOVE.L	$6C(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059554
	MOVE.L	D0,A3
	AND.L	#$0F000000,D4
	BNE	lbC059554
	MOVE.B	#$00,D0
	MOVE.B	D0,D6
	ASL.B	#$04,D6
	ADDQ.B	#$02,D6
	MOVE.B	D6,lbB057D75
	CLR.L	D6
	CLR.L	D7
	LSR.B	#$01,D0
	BCC	lbC059532
	NOT.W	D6
lbC059532:
	SWAP	D6
	LSR.B	#$01,D0
	BCC	lbC05953C
	NOT.W	D6
lbC05953C:
	LSR.B	#$01,D0
	BCC	lbC059544
	NOT.W	D7
lbC059544:
	SWAP	D7
	LSR.B	#$01,D0
	BCC	lbC05954E
	NOT.W	D7
lbC05954E:
	JSR	renderQuadrilateral
lbC059554:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	$70(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0595F0
	MOVE.L	D0,A0
	MOVE.L	$74(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0595F0
	MOVE.L	D0,A1
	MOVE.L	$78(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0595F0
	MOVE.L	D0,A2
	MOVE.L	$7C(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0595F0
	MOVE.L	D0,A3
	AND.L	#$0F000000,D4
	BNE	lbC0595F0
	MOVE.B	#$00,D0
	MOVE.B	D0,D6
	ASL.B	#$04,D6
	ADDQ.B	#$02,D6
	MOVE.B	D6,lbB057D75
	CLR.L	D6
	CLR.L	D7
	LSR.B	#$01,D0
	BCC	lbC0595CE
	NOT.W	D6
lbC0595CE:
	SWAP	D6
	LSR.B	#$01,D0
	BCC	lbC0595D8
	NOT.W	D6
lbC0595D8:
	LSR.B	#$01,D0
	BCC	lbC0595E0
	NOT.W	D7
lbC0595E0:
	SWAP	D7
	LSR.B	#$01,D0
	BCC	lbC0595EA
	NOT.W	D7
lbC0595EA:
	JSR	renderQuadrilateral
lbC0595F0:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	$20(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05968C
	MOVE.L	D0,A0
	MOVE.L	$38(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05968C
	MOVE.L	D0,A1
	MOVE.L	$10(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05968C
	MOVE.L	D0,A2
	MOVE.L	$30(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05968C
	MOVE.L	D0,A3
	AND.L	#$0F000000,D4
	BNE	lbC05968C
	MOVE.B	#$0C,D0
	MOVE.B	D0,D6
	ASL.B	#$04,D6
	ADDQ.B	#$02,D6
	MOVE.B	D6,lbB057D75
	CLR.L	D6
	CLR.L	D7
	LSR.B	#$01,D0
	BCC	lbC05966A
	NOT.W	D6
lbC05966A:
	SWAP	D6
	LSR.B	#$01,D0
	BCC	lbC059674
	NOT.W	D6
lbC059674:
	LSR.B	#$01,D0
	BCC	lbC05967C
	NOT.W	D7
lbC05967C:
	SWAP	D7
	LSR.B	#$01,D0
	BCC	lbC059686
	NOT.W	D7
lbC059686:
	JSR	renderQuadrilateral
lbC05968C:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	$18(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059728
	MOVE.L	D0,A0
	MOVE.L	$3C(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059728
	MOVE.L	D0,A1
	MOVE.L	$28(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059728
	MOVE.L	D0,A2
	MOVE.L	$34(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059728
	MOVE.L	D0,A3
	AND.L	#$0F000000,D4
	BNE	lbC059728
	MOVE.B	#$0C,D0
	MOVE.B	D0,D6
	ASL.B	#$04,D6
	ADDQ.B	#$02,D6
	MOVE.B	D6,lbB057D75
	CLR.L	D6
	CLR.L	D7
	LSR.B	#$01,D0
	BCC	lbC059706
	NOT.W	D6
lbC059706:
	SWAP	D6
	LSR.B	#$01,D0
	BCC	lbC059710
	NOT.W	D6
lbC059710:
	LSR.B	#$01,D0
	BCC	lbC059718
	NOT.W	D7
lbC059718:
	SWAP	D7
	LSR.B	#$01,D0
	BCC	lbC059722
	NOT.W	D7
lbC059722:
	JSR	renderQuadrilateral
lbC059728:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	$10(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0597C4
	MOVE.L	D0,A0
	MOVE.L	$14(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0597C4
	MOVE.L	D0,A1
	MOVE.L	$18(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0597C4
	MOVE.L	D0,A2
	MOVE.L	$1C(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0597C4
	MOVE.L	D0,A3
	AND.L	#$0F000000,D4
	BNE	lbC0597C4
	MOVE.B	#$0A,D0
	MOVE.B	D0,D6
	ASL.B	#$04,D6
	ADDQ.B	#$02,D6
	MOVE.B	D6,lbB057D75
	CLR.L	D6
	CLR.L	D7
	LSR.B	#$01,D0
	BCC	lbC0597A2
	NOT.W	D6
lbC0597A2:
	SWAP	D6
	LSR.B	#$01,D0
	BCC	lbC0597AC
	NOT.W	D6
lbC0597AC:
	LSR.B	#$01,D0
	BCC	lbC0597B4
	NOT.W	D7
lbC0597B4:
	SWAP	D7
	LSR.B	#$01,D0
	BCC	lbC0597BE
	NOT.W	D7
lbC0597BE:
	JSR	renderQuadrilateral
lbC0597C4:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	$38(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059860
	MOVE.L	D0,A0
	MOVE.L	$24(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059860
	MOVE.L	D0,A1
	MOVE.L	$3C(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059860
	MOVE.L	D0,A2
	MOVE.L	$14(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059860
	MOVE.L	D0,A3
	AND.L	#$0F000000,D4
	BNE	lbC059860
	MOVE.B	#$0F,D0
	MOVE.B	D0,D6
	ASL.B	#$04,D6
	ADDQ.B	#$02,D6
	MOVE.B	D6,lbB057D75
	CLR.L	D6
	CLR.L	D7
	LSR.B	#$01,D0
	BCC	lbC05983E
	NOT.W	D6
lbC05983E:
	SWAP	D6
	LSR.B	#$01,D0
	BCC	lbC059848
	NOT.W	D6
lbC059848:
	LSR.B	#$01,D0
	BCC	lbC059850
	NOT.W	D7
lbC059850:
	SWAP	D7
	LSR.B	#$01,D0
	BCC	lbC05985A
	NOT.W	D7
lbC05985A:
	JSR	renderQuadrilateral
lbC059860:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	$30(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0598FC
	MOVE.L	D0,A0
	MOVE.L	$1C(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0598FC
	MOVE.L	D0,A1
	MOVE.L	$34(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0598FC
	MOVE.L	D0,A2
	MOVE.L	$2C(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC0598FC
	MOVE.L	D0,A3
	AND.L	#$0F000000,D4
	BNE	lbC0598FC
	MOVE.B	#$09,D0
	MOVE.B	D0,D6
	ASL.B	#$04,D6
	ADDQ.B	#$02,D6
	MOVE.B	D6,lbB057D75
	CLR.L	D6
	CLR.L	D7
	LSR.B	#$01,D0
	BCC	lbC0598DA
	NOT.W	D6
lbC0598DA:
	SWAP	D6
	LSR.B	#$01,D0
	BCC	lbC0598E4
	NOT.W	D6
lbC0598E4:
	LSR.B	#$01,D0
	BCC	lbC0598EC
	NOT.W	D7
lbC0598EC:
	SWAP	D7
	LSR.B	#$01,D0
	BCC	lbC0598F6
	NOT.W	D7
lbC0598F6:
	JSR	renderQuadrilateral
lbC0598FC:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	$40(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059998
	MOVE.L	D0,A0
	MOVE.L	$44(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059998
	MOVE.L	D0,A1
	MOVE.L	$48(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059998
	MOVE.L	D0,A2
	MOVE.L	$4C(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059998
	MOVE.L	D0,A3
	AND.L	#$0F000000,D4
	BNE	lbC059998
	MOVE.B	#$00,D0
	MOVE.B	D0,D6
	ASL.B	#$04,D6
	ADDQ.B	#$02,D6
	MOVE.B	D6,lbB057D75
	CLR.L	D6
	CLR.L	D7
	LSR.B	#$01,D0
	BCC	lbC059976
	NOT.W	D6
lbC059976:
	SWAP	D6
	LSR.B	#$01,D0
	BCC	lbC059980
	NOT.W	D6
lbC059980:
	LSR.B	#$01,D0
	BCC	lbC059988
	NOT.W	D7
lbC059988:
	SWAP	D7
	LSR.B	#$01,D0
	BCC	lbC059992
	NOT.W	D7
lbC059992:
	JSR	renderQuadrilateral
lbC059998:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	$50(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059A34
	MOVE.L	D0,A0
	MOVE.L	$54(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059A34
	MOVE.L	D0,A1
	MOVE.L	$58(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059A34
	MOVE.L	D0,A2
	MOVE.L	$5C(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC059A34
	MOVE.L	D0,A3
	AND.L	#$0F000000,D4
	BNE	lbC059A34
	MOVE.B	#$00,D0
	MOVE.B	D0,D6
	ASL.B	#$04,D6
	ADDQ.B	#$02,D6
	MOVE.B	D6,lbB057D75
	CLR.L	D6
	CLR.L	D7
	LSR.B	#$01,D0
	BCC	lbC059A12
	NOT.W	D6
lbC059A12:
	SWAP	D6
	LSR.B	#$01,D0
	BCC	lbC059A1C
	NOT.W	D6
lbC059A1C:
	LSR.B	#$01,D0
	BCC	lbC059A24
	NOT.W	D7
lbC059A24:
	SWAP	D7
	LSR.B	#$01,D0
	BCC	lbC059A2E
	NOT.W	D7
lbC059A2E:
	JSR	renderQuadrilateral
lbC059A34:
	MOVE.B	#$00,trackRenderingEnableFlag
	MOVE.W	(SP)+,renderCommandQueueOffset
lbC059A42:
	RTS

clipLineAndMakeEdge:
	CMP.W	D2,D1
	BGE	lbC059A52
	EXG	D1,D2
lbC059A52:
	MOVE.L	lineDrawingBufferPointer,A0
	CMP.L	#lineDrawingBufferEnd,A0
	BGT	lbC059AB2
	CMP.W	#$0081,D2
	BCC	lbC059AB2
	CMP.W	#$0081,D1
	BCC	lbC059AB2
	MOVE.W	D1,(A0)+
	MOVE.W	D2,(A0)+
	MOVE.W	D0,(A0)+
	MOVE.W	D0,(A0)+
	SUB.W	D2,D1
	BRA	lbC059A82

lbC059A80:
	MOVE.W	D0,(A0)+
lbC059A82:
	DBRA	D1,lbC059A80
	MOVE.W	#$8000,(A0)+
	TST.B	edgeDirectionFlag
	BMI	lbC059A9E
	MOVE.L	lineDrawingBufferPointer,(A1)+
	BRA	lbC059AA4

lbC059A9E:
	MOVE.L	lineDrawingBufferPointer,-(A2)
lbC059AA4:
	MOVE.L	A0,lineDrawingBufferPointer
	MOVE.W	#$0000,D1
	MOVE.W	D1,D2
	RTS

lbC059AB2:
	MOVE.W	#$0001,D1
	MOVE.W	D1,D2
	RTS

extractVertexCoordinates:
	BTST	#$06,D0
	BEQ	lbC059ACA
	MOVE.W	(A5),D7
	MOVE.W	$0004(A5),D6
	RTS

lbC059ACA:
	MOVE.W	$0002(A5),D7
	MOVE.W	$0006(A5),D6
	RTS

checkEdgeClippingRequired:
	MOVE.B	#$00,edgeClipFailedFlag
	MOVE.B	#$00,edgeDirectionFlag
	JSR	checkIfClippingRequired
	TST.B	clipRequiredFlag
	BPL	lbC059B9A
	TST.B	renderingFlag
	BEQ	lbC059B7A
	MOVE.B	offRoadSideFlags,D1
	BEQ	lbC059B84
	MOVE.B	renderingFlag,D3
	EOR.B	D3,D1
	BNE	lbC059B84
	MOVE.W	offsetFromRoadCenter,D3
	BPL	lbC059B22
	NEG.W	D3
lbC059B22:
	CMP.W	#$00C5,D3
	BLT	lbC059B84
	CMP.W	#$0240,D3
	BGE	lbC059B84
	TST.B	renderingFlag
	BMI	lbC059B5A
	TST.W	D7
	BEQ	lbC059B50
	TST.W	D6
	BNE	lbC059B84
	CMP.W	#$0040,D7
	BGE	lbC059B84
lbC059B50:
	CMP.W	D7,D5
	BLE	lbC059B84
	BRA	lbC059B9A

lbC059B5A:
	TST.W	D5
	BEQ	lbC059B70
	CMP.W	#$0100,D0
	BNE	lbC059B84
	CMP.W	#$0040,D5
	BGE	lbC059B84
lbC059B70:
	CMP.W	D5,D7
	BLE	lbC059B84
	BRA	lbC059B9A

lbC059B7A:
	TST.B	offRoadSideFlags
	BEQ	lbC059B9A
lbC059B84:
	TST.B	clipRequiredFlag
	BPL	lbC059B9A
	EXG	D0,D6
	EXG	D5,D7
	MOVE.B	#$80,edgeDirectionFlag
lbC059B9A:
	BRA	lbC059B9E

lbC059B9E:
	MOVE.W	D0,savedXCoordinate
	MOVE.B	#$00,clipIterationCounter
	CMP.W	#$0100,D0
	BEQ	lbC059BD6
	CMP.W	#$0000,D0
	BEQ	lbC059BEA
	CMP.W	#$0080,D5
	BEQ	lbC059BE0
	CMP.W	#$0000,D5
	BEQ	lbC059BF4
	BRA	lbC059C0A

lbC059BD0:
	ADDQ.B	#$01,clipIterationCounter
lbC059BD6:
	JSR	clipAgainstRightEdge
	BCC	lbC059C12
lbC059BE0:
	JSR	clipAgainstMiddle
	BCC	lbC059C12
lbC059BEA:
	JSR	clipAgainstLeftEdge
	BCC	lbC059C12
lbC059BF4:
	JSR	clipAgainstBottom
	BCC	lbC059C12
	CMP.B	#$02,clipIterationCounter
	BLT	lbC059BD0
lbC059C0A:
	MOVE.B	#$80,edgeClipFailedFlag
lbC059C12:
	RTS

clipAgainstRightEdge:
	CMP.W	#$0100,D6
	BEQ	lbC059C3A
lbC059C1C:
	MOVE.W	#$0100,D0
	MOVE.W	D5,D1
	MOVE.W	#$0080,D2
	JSR	clipLineAndMakeEdge
	BNE	lbC059C0A
	MOVE.W	#$0080,D5
	ORI.B	#$01,CCR
	RTS

lbC059C3A:
	CMP.W	D7,D5
	BGT	lbC059C1C
	MOVE.W	#$0100,D0
	MOVE.W	D5,D1
	MOVE.W	D7,D2
	JSR	clipLineAndMakeEdge
	BNE	lbC059C0A
	ANDI.B	#$1E,CCR
	RTS

clipAgainstLeftEdge:
	CMP.W	#$0000,D6
	BEQ	lbC059C7E
lbC059C60:
	MOVE.W	#$0000,D0
	MOVE.W	D5,D1
	MOVE.W	#$0000,D2
	JSR	clipLineAndMakeEdge
	BNE	lbC059C0A
	MOVE.W	#$0000,D5
	ORI.B	#$01,CCR
	RTS

lbC059C7E:
	CMP.W	D7,D5
	BLT	lbC059C60
	MOVE.W	#$0000,D0
	MOVE.W	D5,D1
	MOVE.W	D7,D2
	JSR	clipLineAndMakeEdge
	BNE	lbC059C0A
	ANDI.B	#$1E,CCR
	RTS

clipAgainstMiddle:
	CMP.W	#$0080,D7
	BEQ	lbC059CB2
lbC059CA4:
	MOVE.W	#$0000,savedXCoordinate
	ORI.B	#$01,CCR
	RTS

lbC059CB2:
	MOVE.W	savedXCoordinate,D0
	CMP.W	D6,D0
	BLT	lbC059CA4
	ANDI.B	#$1E,CCR
	RTS

clipAgainstBottom:
	CMP.W	#$0000,D7
	BEQ	lbC059CDA
lbC059CCC:
	MOVE.W	#$0100,savedXCoordinate
	ORI.B	#$01,CCR
	RTS

lbC059CDA:
	MOVE.W	savedXCoordinate,D0
	CMP.W	D6,D0
	BGT	lbC059CCC
	ANDI.B	#$1E,CCR
	RTS

checkIfClippingRequired:
	MOVE.W	D0,D1
	MOVE.W	D5,D2
	JSR	calculateEdgeIntersection
	MOVE.W	D3,-(SP)
	MOVE.W	D6,D1
	MOVE.W	D7,D2
	JSR	calculateEdgeIntersection
	SUB.W	(SP)+,D3
	BPL	lbC059D16
	NEG.W	D3
	CMP.W	#$0180,D3
	BLT	lbC059D1E
	BRA	lbC059D28

lbC059D16:
	CMP.W	#$0180,D3
	BLT	lbC059D28
lbC059D1E:
	MOVE.B	#$80,clipRequiredFlag
	RTS

lbC059D28:
	MOVE.B	#$00,clipRequiredFlag
	RTS

calculateEdgeIntersection:
	MOVE.W	#$0000,D3
	CMP.W	#$0000,D2
	BNE	lbC059D44
	MOVE.W	D1,D3
	BRA	lbC059D76

lbC059D44:
	ADD.W	#$0100,D3
	CMP.W	#$0100,D1
	BNE	lbC059D56
	ADD.W	D2,D3
	BRA	lbC059D76

lbC059D56:
	ADD.W	#$0080,D3
	CMP.W	#$0080,D2
	BNE	lbC059D6C
	ADD.W	#$0100,D3
	SUB.W	D1,D3
	BRA	lbC059D76

lbC059D6C:
	ADD.W	#$0100,D3
	ADD.W	#$0080,D3
	SUB.W	D2,D3
lbC059D76:
	CLR.W	D1
	CLR.W	D2
	RTS

checkFarClippingPlane:
	MOVE.L	#coordinateLookupTable,A0
	MOVE.W	$00(A0,D1.W),D0
	BPL	lbC059D8C
	NEG.W	D0
lbC059D8C:
	CMP.W	#$0C00,D0
	BGE	lbC059D9A
	ANDI.B	#$1E,CCR
	RTS

lbC059D9A:
	MOVE.W	#$8000,$00(A6,D1.W)
	ORI.B	#$01,CCR
	RTS

findActiveEdgesForScanline:
	MOVE.W	lbW05B3CC,D2
	MOVE.L	#renderDataBuffer,A4
lbC059DB6:
	MOVE.W	$00(A4,D2.W),D0
	BPL	lbC059DCC
lbC059DBE:
	SUB.W	#$000A,D2
	BPL	lbC059DB6
	MOVE.W	#$8000,D0
	RTS

lbC059DCC:
	CMP.L	A2,A1
	BGT	lbC059DE6
	CMP.L	$02(A4,D2.W),A1
	BGT	lbC059DBE
	CMP.L	$02(A4,D2.W),A2
	BLT	lbC059DBE
	BRA	lbC059DF6

lbC059DE6:
	CMP.L	$02(A4,D2.W),A1
	BLT	lbC059DF6
	CMP.L	$02(A4,D2.W),A2
	BLT	lbC059DBE
lbC059DF6:
	MOVE.W	D2,D1
lbC059DF8:
	SUB.W	#$000A,D2
	BMI	lbC059E3C
	CMP.W	$00(A4,D2.W),D0
	BGE	lbC059DF8
	CMP.L	A2,A1
	BGT	lbC059E22
	CMP.L	$02(A4,D2.W),A1
	BGT	lbC059DF8
	CMP.L	$02(A4,D2.W),A2
	BLT	lbC059DF8
	BRA	lbC059E32

lbC059E22:
	CMP.L	$02(A4,D2.W),A1
	BLT	lbC059E32
	CMP.L	$02(A4,D2.W),A2
	BLT	lbC059DF8
lbC059E32:
	MOVE.W	D2,D1
	MOVE.W	$00(A4,D1.W),D0
	BRA	lbC059DF8

lbC059E3C:
	MOVE.W	#$8000,$00(A4,D1.W)
	RTS

initializeEdgeSortBuffers:
	MOVE.B	#$00,scanlineCounter
	MOVE.L	A1,lbL05B3F4
	MOVE.L	A2,lbL05B3F0
	SUB.L	A2,A1
	MOVE.L	A1,lbL05B3F8
	BEQ	lbC05A1CC
	MOVE.W	#$0000,D7
	MOVE.B	lbB05B3EA,D6
	AND.B	#$40,D6
	EOR.B	#$40,D6
	MOVE.L	#renderDataBuffer,A4
	MOVE.L	#edgeSortBuffer,A0
	MOVE.L	(A0)+,A5
	MOVE.L	A0,A3
	BRA	lbC059F02

lbC059E8A:
	MOVE.L	A0,A3
	MOVE.L	(A0)+,A5
	MOVE.W	(A5),D0
	CMP.W	$0002(A5),D0
	BNE	lbC059EB2
	CMP.L	#edgeSortBuffer,A3
	BNE	lbC059F02
	BTST	#$06,lbB05B3EA
	BNE	lbC059EC8
	BRA	lbC059F02

lbC059EB2:
	CMP.W	D4,D0
	BEQ	lbC059EC8
	CMP.W	$0002(A5),D3
	BNE	lbC059ED6
	MOVE.B	#$40,D6
	BRA	lbC059F02

lbC059EC8:
	TST.B	D6
	BNE	lbC059ED6
	MOVE.B	#$00,D6
	BRA	lbC059F02

lbC059ED6:
	EOR.B	#$40,D6
	BNE	lbC059F02
	MOVE.L	A3,$06(A4,D7.W)
	MOVE.L	A0,D2
	SUBQ.L	#$08,D2
	CMP.L	lbL05B3F0,D2
	BGE	lbC059EF6
	ADD.L	lbL05B3F8,D2
lbC059EF6:
	MOVE.L	D2,$02(A4,D7.W)
	MOVE.W	D0,$00(A4,D7.W)
	ADD.W	#$000A,D7
lbC059F02:
	MOVE.W	(A5),D3
	MOVE.W	$0002(A5),D4
	CMP.L	lbL05B3F4,A0
	BNE	lbC059F18
	SUB.L	lbL05B3F8,A0
lbC059F18:
	CMP.L	#edgeSortBuffer,A3
	BNE	lbC059E8A
	SUB.W	#$000A,D7
	BEQ	lbC059F8C
	BMI	lbC05A1D2
	MOVE.W	D7,lbW05B3CC
	MOVE.W	lbW05B3CC,D2
	MOVE.W	$00(A4,D2.W),D0
	MOVE.W	D2,D1
	BRA	lbC059F52

lbC059F44:
	CMP.W	$00(A4,D2.W),D0
	BGE	lbC059F52
	MOVE.W	$00(A4,D2.W),D0
	MOVE.W	D2,D1
lbC059F52:
	SUB.W	#$000A,D2
	BPL	lbC059F44
	MOVE.W	#$8000,$00(A4,D1.W)
	MOVE.L	$06(A4,D1.W),A1
	MOVE.L	$02(A4,D1.W),A2
	JSR	findActiveEdgesForScanline
	MOVE.W	D0,lbW05B3CE
	BMI	lbC059F88
	MOVE.L	$06(A4,D1.W),currentEdgePointer1
	MOVE.L	$02(A4,D1.W),currentEdgePointer2
lbC059F88:
	BRA	lbC059F9C

lbC059F8C:
	MOVE.W	#$8000,lbW05B3CE
	MOVE.L	$0006(A4),A1
	MOVE.L	$0002(A4),A2
lbC059F9C:
	MOVE.L	(A1),A0
	MOVE.L	(A2),A3
	MOVE.B	lbB05B3EC,D0
	MOVE.B	D0,D6
	ASL.B	#$04,D6
	ADDQ.B	#$02,D6
	MOVE.B	D6,lbB057D75
	CLR.L	D6
	CLR.L	D7
	LSR.B	#$01,D0
	BCC	lbC059FBE
	NOT.W	D6
lbC059FBE:
	SWAP	D6
	LSR.B	#$01,D0
	BCC	lbC059FC8
	NOT.W	D6
lbC059FC8:
	LSR.B	#$01,D0
	BCC	lbC059FD0
	NOT.W	D7
lbC059FD0:
	SWAP	D7
	LSR.B	#$01,D0
	BCC	lbC059FDA
	NOT.W	D7
lbC059FDA:
	MOVE.L	#lbW0580E0,A5
	MOVE.W	(A0)+,D1
	MOVE.W	(A3)+,D0
	CMP.W	D1,D0
	BNE	lbC05A1D2
	ADDQ.L	#$06,A0
	ADDQ.L	#$06,A3
	MOVE.W	D1,polygonFillStartY
	SUBQ.W	#$01,D1
	CMP.W	#$0080,D1
	BCC	lbC05A1D2
	MOVE.L	viewportTopAddress,A6
	CLR.L	D0
	MOVE.W	D1,D0
	ASL.W	#$02,D0
	ADD.W	D1,D0
	ASL.W	#$03,D0
	ADD.L	D0,A6
lbC05A010:
	MOVE.W	polygonFillStartY,D0
	CMP.W	lbW05B3CE,D0
	BNE	lbC05A06A
	MOVE.W	polygonFillStartY,-(SP)
	MOVE.L	A6,-(SP)
	MOVE.L	A3,-(SP)
	MOVE.L	A2,-(SP)
	MOVE.L	currentEdgePointer1,-(SP)
	ADDQ.B	#$01,scanlineCounter
	MOVE.L	currentEdgePointer2,A2
	MOVE.L	(A2),A3
	ADD.L	#$00000008,A3
	JSR	findActiveEdgesForScanline
	MOVE.W	D0,lbW05B3CE
	BMI	lbC05A066
	MOVE.L	$06(A4,D1.W),currentEdgePointer1
	MOVE.L	$02(A4,D1.W),currentEdgePointer2
lbC05A066:
	BRA	lbC05A010

lbC05A06A:
	MOVE.W	(A0)+,D4
	BPL	lbC05A09E
lbC05A070:
	ADDQ.L	#$04,A1
	CMP.L	lbL05B3F4,A1
	BLT	lbC05A082
	SUB.L	lbL05B3F8,A1
lbC05A082:
	CMP.L	A2,A1
	BEQ	lbC05A182
	MOVE.L	(A1),A0
	MOVE.W	(A0)+,D4
	CMP.W	polygonFillStartY,D4
	BNE	lbC05A1D2
	ADDQ.L	#$06,A0
	MOVE.W	(A0)+,D4
	BMI	lbC05A070
lbC05A09E:
	MOVE.W	(A3)+,D5
	BPL	lbC05A0D0
lbC05A0A4:
	CMP.L	lbL05B3F0,A2
	BNE	lbC05A0B4
	ADD.L	lbL05B3F8,A2
lbC05A0B4:
	MOVE.L	-(A2),A3
	CMP.L	A1,A2
	BEQ	lbC05A182
	MOVE.W	(A3)+,D5
	CMP.W	polygonFillStartY,D5
	BNE	lbC05A1D2
	ADDQ.L	#$06,A3
	MOVE.W	(A3)+,D5
	BMI	lbC05A0A4
lbC05A0D0:
	CMP.W	D4,D5
	BGT	lbC05A0E8
	BEQ	lbC05A16C
	TST.B	trackRenderingEnableFlag
	BPL	lbC05A16C
	BRA	lbC05A16C

lbC05A0E8:
	MOVE.W	D4,D1
	AND.W	#$00F0,D1
	LSR.W	#$03,D1
	LEA	$00(A6,D1.W),A4
	MOVE.W	D4,D3
	MOVE.W	D5,D1
	LSR.W	#$04,D3
	LSR.W	#$04,D1
	SUB.W	D3,D1
	BNE	lbC05A122
	AND.W	#$000F,D4
	ASL.W	#$02,D4
	MOVE.W	$00(A5,D4.W),D4
	AND.W	#$000F,D5
	ASL.W	#$02,D5
	MOVE.W	$40(A5,D5.W),D5
	AND.W	D5,D4
	JSR	applyBitplaneMask
	BRA	lbC05A16C

lbC05A122:
	SUBQ.B	#$01,D1
	AND.W	#$000F,D4
	BEQ	lbC05A13E
	ASL.W	#$02,D4
	MOVE.W	$00(A5,D4.W),D4
	JSR	applyBitplaneMask
	SUBQ.W	#$01,D1
	BMI	lbC05A158
lbC05A13E:
	MOVE.L	D6,D2
	MOVE.L	D7,D3
	SWAP	D2
	SWAP	D3
lbC05A146:
	MOVE.W	D2,(A4)+
	MOVE.W	D6,$1F3E(A4)
	MOVE.W	D3,$3E7E(A4)
	MOVE.W	D7,$5DBE(A4)
	DBRA	D1,lbC05A146
lbC05A158:
	AND.W	#$000F,D5
	BEQ	lbC05A16C
	ASL.W	#$02,D5
	MOVE.W	$40(A5,D5.W),D4
	JSR	applyBitplaneMask
lbC05A16C:
	SUBQ.W	#$01,polygonFillStartY
	SUB.L	#$00000028,A6
	CMP.L	viewportTopAddress,A6
	BGE	lbC05A010
lbC05A182:
	TST.B	scanlineCounter
	BEQ	lbC05A1CC
	MOVE.L	(SP)+,A1
	MOVE.L	(SP)+,A2
	MOVE.L	(SP)+,A3
	MOVE.L	(SP)+,A6
	MOVE.W	(SP)+,polygonFillStartY
	SUBQ.B	#$01,scanlineCounter
	MOVE.L	(A1),A0
	ADD.L	#$00000008,A0
	JSR	findActiveEdgesForScanline
	MOVE.W	D0,lbW05B3CE
	BMI	lbC05A1C8
	MOVE.L	$06(A4,D1.W),currentEdgePointer1
	MOVE.L	$02(A4,D1.W),currentEdgePointer2
lbC05A1C8:
	BRA	lbC05A010

lbC05A1CC:
	CLR.L	D1
	CLR.L	D2
	RTS

lbC05A1D2:
	TST.B	scanlineCounter
	BEQ	lbC05A1CC
	MOVE.L	(SP)+,A1
	MOVE.L	(SP)+,A2
	MOVE.L	(SP)+,A3
	MOVE.L	(SP)+,A6
	MOVE.W	(SP)+,polygonFillStartY
	SUBQ.B	#$01,scanlineCounter
	MOVE.L	(A1),A0
	ADD.L	#$00000008,A0
	BRA	lbC05A1D2

renderTrackSurfaceEdge:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.B	#$0F,D0
	JSR	setPixelColor
	MOVE.L	$18(A4,D3.W),D0
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A228
	MOVE.L	D0,A3
	JSR	rasterizeVerticalEdge
lbC05A228:
	RTS

renderRightBarrierEdges:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	BRA	lbC05A270

lbC05A23A:
	MOVE.B	$1D(A4,D3.W),D0
	BMI	lbC05A26C
	CMP.B	#$03,D0
	BEQ	lbC05A26C
	MOVE.B	trackColorIndex1,D0
	JSR	setPixelColor
	MOVE.L	$10(A4,D3.W),D0
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A26C
	MOVE.L	D0,A3
	JSR	rasterizeVerticalEdge
lbC05A26C:
	SUB.W	#$0020,D3
lbC05A270:
	CMP.W	currentSegmentQueueOffset,D3
	BNE	lbC05A23A
	RTS

renderLeftBarrierEdges:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	BRA	lbC05A2C2

lbC05A28C:
	MOVE.B	$1D(A4,D3.W),D0
	BMI	lbC05A2BE
	CMP.B	#$03,D0
	BEQ	lbC05A2BE
	MOVE.B	trackColorIndex1,D0
	JSR	setPixelColor
	MOVE.L	$14(A4,D3.W),D0
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A2BE
	MOVE.L	D0,A3
	JSR	rasterizeVerticalEdge
lbC05A2BE:
	SUB.W	#$0020,D3
lbC05A2C2:
	CMP.W	currentSegmentQueueOffset,D3
	BNE	lbC05A28C
	RTS

renderLeftRoadEdge:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	BRA	lbC05A306

lbC05A2DE:
	MOVE.B	$1D(A4,D3.W),D0
	BMI	lbC05A302
	JSR	setPixelColor
	MOVE.L	$00(A4,D3.W),D0
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A302
	MOVE.L	D0,A3
	JSR	rasterizeVerticalEdge
lbC05A302:
	SUB.W	#$0020,D3
lbC05A306:
	CMP.W	currentSegmentQueueOffset,D3
	BNE	lbC05A2DE
	RTS

renderRightRoadEdge:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	BRA	lbC05A34A

lbC05A322:
	MOVE.B	$1D(A4,D3.W),D0
	BMI	lbC05A346
	JSR	setPixelColor
	MOVE.L	$04(A4,D3.W),D0
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A346
	MOVE.L	D0,A3
	JSR	rasterizeVerticalEdge
lbC05A346:
	SUB.W	#$0020,D3
lbC05A34A:
	CMP.W	currentSegmentQueueOffset,D3
	BNE	lbC05A322
	RTS

renderRightBarrier:
	MOVE.B	#$80,renderingFlag
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
lbC05A36A:
	MOVE.W	D3,barrierSegmentQueueOffset
	MOVE.L	$10(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BNE	lbC05A3A0
lbC05A380:
	SUB.W	#$0020,D3
	CMP.W	currentSegmentQueueOffset,D3
	BLE	lbC05A4EA
	MOVE.L	$10(A4,D3.W),D0
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A380
	BRA	lbC05A36A

lbC05A3A0:
	MOVE.L	#edgeSortBuffer,A1
	MOVE.L	A1,A2
	MOVE.B	#$0F,D5
	BTST	#$00,$1C(A4,D3.W)
	BEQ	lbC05A3BC
	MOVE.B	trackColorIndex2,D5
lbC05A3BC:
	TST.B	segmentRenderingFlag
	BEQ	lbC05A3CC
	MOVE.B	trackColorIndex1,D5
lbC05A3CC:
	MOVE.B	D5,lbB05B3EC
	MOVE.L	D0,(A1)+
	MOVE.B	$10(A4,D3.W),D0
	MOVE.B	D0,lbB05B3EA
	MOVE.B	D0,lbB05B3DE
	EOR.B	#$40,D0
	MOVE.B	D0,lbB05B3E2
	CMP.W	#$0020,barrierSegmentQueueOffset
	BEQ	lbC05A472
lbC05A3FA:
	MOVE.L	$00(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A44A
	MOVE.B	$00(A4,D3.W),lbB05B3E2
	MOVE.L	D0,(A1)+
	MOVE.L	$08(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A448
	MOVE.B	$08(A4,D3.W),lbB05B3DE
	MOVE.L	D0,-(A2)
	SUB.W	#$0020,D3
	CMP.W	currentSegmentQueueOffset,D3
	BEQ	lbC05A454
	CMP.W	#$0020,D3
	BNE	lbC05A3FA
	BRA	lbC05A472

lbC05A448:
	SUBQ.L	#$04,A1
lbC05A44A:
	CMP.W	renderCommandQueueOffset,D3
	BEQ	lbC05A4EA
lbC05A454:
	MOVE.L	$10(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A4EA
	MOVE.B	$10(A4,D3.W),lbB05B3E2
	MOVE.L	D0,(A1)+
	BRA	lbC05A4DA

lbC05A472:
	MOVE.L	$00(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A48C
	MOVE.B	$00(A4,D3.W),lbB05B3E2
	MOVE.L	D0,(A1)+
lbC05A48C:
	MOVE.L	-$0004(A1),A5
	MOVE.B	lbB05B3E2,D0
	JSR	extractVertexCoordinates
	MOVE.W	D6,-(SP)
	MOVE.W	D7,D5
	MOVE.L	$08(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A4BA
	MOVE.B	$08(A4,D3.W),lbB05B3DE
	MOVE.L	D0,-(A2)
lbC05A4BA:
	MOVE.L	(A2),A5
	MOVE.B	lbB05B3DE,D0
	JSR	extractVertexCoordinates
	MOVE.W	(SP)+,D0
	JSR	checkEdgeClippingRequired
	TST.B	edgeClipFailedFlag
	BMI	lbC05A4EA
lbC05A4DA:
	AND.L	#$0F000000,D4
	BNE	lbC05A4EA
	JSR	initializeEdgeSortBuffers
lbC05A4EA:
	RTS

renderLeftBarrier:
	MOVE.B	#$02,renderingFlag
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
lbC05A500:
	MOVE.W	D3,barrierSegmentQueueOffset
	MOVE.L	$14(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BNE	lbC05A536
lbC05A516:
	SUB.W	#$0020,D3
	CMP.W	currentSegmentQueueOffset,D3
	BLE	lbC05A680
	MOVE.L	$14(A4,D3.W),D0
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A516
	BRA	lbC05A500

lbC05A536:
	MOVE.L	#edgeSortBuffer,A1
	MOVE.L	A1,A2
	MOVE.B	#$0F,D5
	BTST	#$00,$1C(A4,D3.W)
	BEQ	lbC05A552
	MOVE.B	trackColorIndex2,D5
lbC05A552:
	TST.B	segmentRenderingFlag
	BEQ	lbC05A562
	MOVE.B	trackColorIndex1,D5
lbC05A562:
	MOVE.B	D5,lbB05B3EC
	MOVE.L	D0,(A1)+
	MOVE.B	$14(A4,D3.W),D0
	MOVE.B	D0,lbB05B3EA
	MOVE.B	D0,lbB05B3DE
	EOR.B	#$40,D0
	MOVE.B	D0,lbB05B3E2
	CMP.W	#$0020,barrierSegmentQueueOffset
	BEQ	lbC05A608
lbC05A590:
	MOVE.L	$0C(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A5E0
	MOVE.B	$0C(A4,D3.W),lbB05B3E2
	MOVE.L	D0,(A1)+
	MOVE.L	$04(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A5DE
	MOVE.B	$04(A4,D3.W),lbB05B3DE
	MOVE.L	D0,-(A2)
	SUB.W	#$0020,D3
	CMP.W	currentSegmentQueueOffset,D3
	BEQ	lbC05A5EA
	CMP.W	#$0020,D3
	BNE	lbC05A590
	BRA	lbC05A608

lbC05A5DE:
	SUBQ.L	#$04,A1
lbC05A5E0:
	CMP.W	renderCommandQueueOffset,D3
	BEQ	lbC05A680
lbC05A5EA:
	MOVE.L	$14(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A680
	MOVE.B	$14(A4,D3.W),lbB05B3E2
	MOVE.L	D0,(A1)+
	BRA	lbC05A670

lbC05A608:
	MOVE.L	$0C(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A622
	MOVE.B	$0C(A4,D3.W),lbB05B3E2
	MOVE.L	D0,(A1)+
lbC05A622:
	MOVE.L	-$0004(A1),A5
	MOVE.B	lbB05B3E2,D0
	JSR	extractVertexCoordinates
	MOVE.W	D6,-(SP)
	MOVE.W	D7,D5
	MOVE.L	$04(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A650
	MOVE.B	$04(A4,D3.W),lbB05B3DE
	MOVE.L	D0,-(A2)
lbC05A650:
	MOVE.L	(A2),A5
	MOVE.B	lbB05B3DE,D0
	JSR	extractVertexCoordinates
	MOVE.W	(SP)+,D0
	JSR	checkEdgeClippingRequired
	TST.B	edgeClipFailedFlag
	BMI	lbC05A680
lbC05A670:
	AND.L	#$0F000000,D4
	BNE	lbC05A680
	JSR	initializeEdgeSortBuffers
lbC05A680:
	RTS

renderTrackSurface:
	MOVE.B	#$00,renderingFlag
	MOVE.B	#$00,segmentPropertyFlags
	MOVE.B	#$80,lbB00D4D2
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.W	D3,barrierSegmentQueueOffset
	MOVE.L	$18(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A80C
	MOVE.L	#edgeSortBuffer,A1
	MOVE.L	A1,A2
	MOVE.B	#$01,D5
	BTST	#$00,$1C(A4,D3.W)
	BEQ	lbC05A6D6
	MOVE.B	#$02,D5
lbC05A6D6:
	MOVE.B	$1E(A4,D3.W),segmentPropertyFlags
	BTST	#$05,segmentPropertyFlags
	BEQ	lbC05A6EE
	MOVE.B	#$00,D5
lbC05A6EE:
	MOVE.B	D5,lbB05B3EC
	MOVE.L	D0,(A1)+
	MOVE.B	$18(A4,D3.W),D0
	MOVE.B	D0,lbB05B3EA
	MOVE.B	D0,lbB05B3DE
	EOR.B	#$40,D0
	MOVE.B	D0,lbB05B3E2
	CMP.W	#$0020,barrierSegmentQueueOffset
	BEQ	lbC05A794
lbC05A71C:
	MOVE.L	$04(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A76C
	MOVE.B	$04(A4,D3.W),lbB05B3E2
	MOVE.L	D0,(A1)+
	MOVE.L	$00(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A76A
	MOVE.B	$00(A4,D3.W),lbB05B3DE
	MOVE.L	D0,-(A2)
	SUB.W	#$0020,D3
	CMP.W	currentSegmentQueueOffset,D3
	BEQ	lbC05A776
	CMP.W	#$0020,D3
	BNE	lbC05A71C
	BRA	lbC05A794

lbC05A76A:
	SUBQ.L	#$04,A1
lbC05A76C:
	CMP.W	renderCommandQueueOffset,D3
	BEQ	lbC05A80C
lbC05A776:
	MOVE.L	$18(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A80C
	MOVE.B	$18(A4,D3.W),lbB05B3E2
	MOVE.L	D0,(A1)+
	BRA	lbC05A7FC

lbC05A794:
	MOVE.L	$04(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A7AE
	MOVE.B	$04(A4,D3.W),lbB05B3E2
	MOVE.L	D0,(A1)+
lbC05A7AE:
	MOVE.L	-$0004(A1),A5
	MOVE.B	lbB05B3E2,D0
	JSR	extractVertexCoordinates
	MOVE.W	D6,-(SP)
	MOVE.W	D7,D5
	MOVE.L	$00(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A7DC
	MOVE.B	$00(A4,D3.W),lbB05B3DE
	MOVE.L	D0,-(A2)
lbC05A7DC:
	MOVE.L	(A2),A5
	MOVE.B	lbB05B3DE,D0
	JSR	extractVertexCoordinates
	MOVE.W	(SP)+,D0
	JSR	checkEdgeClippingRequired
	TST.B	edgeClipFailedFlag
	BMI	lbC05A80C
lbC05A7FC:
	AND.L	#$0F000000,D4
	BNE	lbC05A80C
	JSR	initializeEdgeSortBuffers
lbC05A80C:
	MOVE.B	#$00,lbB00D4D2
	BTST	#$00,segmentPropertyFlags
	BEQ	lbC05A826
	JSR	renderTrackSurfaceEdge
lbC05A826:
	RTS

renderTrackNear:
	SUB.W	#$0020,renderCommandQueueOffset
	CMP.W	#$0040,renderCommandQueueOffset
	BLT	.done
.renderLoop:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
.nextCommand:
	SUB.W	#$0020,D3
	BEQ	.offsetOk1
	TST.B	$1E(A4,D3.W)
	BMI	.nextCommand
.offsetOk1:
	MOVE.W	D3,currentSegmentQueueOffset
	CMP.W	minimumRenderQueueOffset,D3
	BLT	.done
	TST.B	renderingOrderMode
	BNE	.useLateralPositionForDepthSorting
	JSR	renderRightBarrier
	JSR	renderRightBarrierEdges
	JSR	renderLeftBarrier
	JSR	renderLeftBarrierEdges
	JSR	renderOpponentCarIfAhead
	JSR	renderOpponentCarIfBehind
	JSR	renderTrackSurface
	JSR	renderLeftRoadEdge
	JSR	renderRightRoadEdge
	JSR	renderOpponentCarIfOccluded
	BRA	.advanceInQueue

.useLateralPositionForDepthSorting:
	TST.B	offsetFromRoadCenter
	BPL	.carOnRightSide
	JSR	renderOpponentCarIfAhead
	JSR	renderLeftBarrier
	JSR	renderLeftBarrierEdges
	JSR	renderTrackSurface
	JSR	renderRightRoadEdge
	JSR	renderOpponentCarIfOccluded
	JSR	renderRightBarrier
	JSR	renderRightBarrierEdges
	MOVE.W	renderCommandQueueOffset,D3
	CMP.W	barrierSegmentQueueOffset,D3
	BEQ	.offsetOk2
	TST.B	raceStartTimer
	BNE	.offsetOk2
	MOVE.W	renderCommandQueueOffset,-(SP)
	MOVE.W	barrierSegmentQueueOffset,renderCommandQueueOffset
	JSR	renderLeftRoadEdge
	MOVE.W	(SP)+,renderCommandQueueOffset
	BRA	.leftRoadEdgeRendered

.offsetOk2:
	JSR	renderLeftRoadEdge
.leftRoadEdgeRendered:
	JSR	renderOpponentCarIfBehind
	BRA	.advanceInQueue

.carOnRightSide:
	JSR	renderOpponentCarIfBehind
	JSR	renderRightBarrier
	JSR	renderRightBarrierEdges
	JSR	renderTrackSurface
	JSR	renderLeftRoadEdge
	JSR	renderOpponentCarIfOccluded
	JSR	renderLeftBarrier
	JSR	renderLeftBarrierEdges
	MOVE.W	renderCommandQueueOffset,D3
	CMP.W	barrierSegmentQueueOffset,D3
	BEQ	.offsetOk3
	TST.B	raceStartTimer
	BNE	.offsetOk3
	MOVE.W	renderCommandQueueOffset,-(SP)
	MOVE.W	barrierSegmentQueueOffset,renderCommandQueueOffset
	JSR	renderRightRoadEdge
	MOVE.W	(SP)+,renderCommandQueueOffset
	BRA	.rightRoadEdgeRendered

.offsetOk3:
	JSR	renderRightRoadEdge
.rightRoadEdgeRendered:
	JSR	renderOpponentCarIfAhead
.advanceInQueue:
	MOVE.W	currentSegmentQueueOffset,renderCommandQueueOffset
	BNE	.renderLoop
.done:	RTS

renderTrackFar:
	SUB.W	#$0020,renderCommandQueueOffset
	MOVE.W	renderCommandQueueOffset,D3
	CMP.W	farSegmentQueueOffset,D3
	BLT	lbC05AA6A
	SUB.W	#$0020,D3
	MOVE.W	D3,currentSegmentQueueOffset
	TST.B	renderingOrderMode
	BNE	lbC05AA10
	JSR	renderRightTrackSidePanel
	JSR	renderLeftTrackSidePanel
	JSR	renderOpponentCarIfAhead
	JSR	renderOpponentCarIfBehind
	JSR	renderTrackSurface
	JSR	renderOpponentCarIfOccluded
	BRA	lbC05AA66

lbC05AA10:
	TST.B	offsetFromRoadCenter
	BPL	lbC05AA42
	JSR	renderOpponentCarIfAhead
	JSR	renderLeftTrackSidePanel
	JSR	renderTrackSurface
	JSR	renderOpponentCarIfOccluded
	JSR	renderRightTrackSidePanel
	JSR	renderOpponentCarIfBehind
	BRA	lbC05AA66

lbC05AA42:
	JSR	renderOpponentCarIfBehind
	JSR	renderRightTrackSidePanel
	JSR	renderTrackSurface
	JSR	renderOpponentCarIfOccluded
	JSR	renderLeftTrackSidePanel
	JSR	renderOpponentCarIfAhead
lbC05AA66:
	BRA	renderTrackFar

lbC05AA6A:
	RTS

renderOpponentCarIfAhead:
	TST.B	opponentRelativePosition
	BEQ	renderOpponentDone
	BPL	lbC05AA92
	RTS

renderOpponentCarIfBehind:
	TST.B	opponentRelativePosition
	BMI	lbC05AA92
	RTS

renderOpponentCarIfOccluded:
	TST.B	opponentRelativePosition
	BNE	renderOpponentDone
lbC05AA92:
	MOVE.W	currentSegmentQueueOffset,D3
	CMP.W	opponentSegmentQueueOffset,D3
	BGT	renderOpponentDone
	JSR	renderOpponentCar
	MOVE.W	#$FFFF,opponentSegmentQueueOffset
renderOpponentDone:
	RTS

renderLeftTrackSidePanel:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.B	#$0F,D7
	BTST	#$00,$1C(A4,D3.W)
	BEQ	lbC05AAD4
	MOVE.B	trackColorIndex2,D7
lbC05AAD4:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	$0C(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05AB6E
	MOVE.L	D0,A0
	MOVE.L	-$0C(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05AB6E
	MOVE.L	D0,A1
	MOVE.L	$04(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05AB6E
	MOVE.L	D0,A2
	MOVE.L	$14(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05AB6E
	MOVE.L	D0,A3
	AND.L	#$0F000000,D4
	BNE	lbC05AB6E
	MOVE.B	D7,D0
	MOVE.B	D0,D6
	ASL.B	#$04,D6
	ADDQ.B	#$02,D6
	MOVE.B	D6,lbB057D75
	CLR.L	D6
	CLR.L	D7
	LSR.B	#$01,D0
	BCC	lbC05AB4C
	NOT.W	D6
lbC05AB4C:
	SWAP	D6
	LSR.B	#$01,D0
	BCC	lbC05AB56
	NOT.W	D6
lbC05AB56:
	LSR.B	#$01,D0
	BCC	lbC05AB5E
	NOT.W	D7
lbC05AB5E:
	SWAP	D7
	LSR.B	#$01,D0
	BCC	lbC05AB68
	NOT.W	D7
lbC05AB68:
	JSR	renderQuadrilateral
lbC05AB6E:
	RTS

renderRightTrackSidePanel:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.B	#$0F,D7
	BTST	#$00,$1C(A4,D3.W)
	BEQ	lbC05AB90
	MOVE.B	trackColorIndex2,D7
lbC05AB90:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderCommandQueueOffset,D3
	MOVE.L	$08(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05AC2A
	MOVE.L	D0,A0
	MOVE.L	$10(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05AC2A
	MOVE.L	D0,A1
	MOVE.L	$00(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05AC2A
	MOVE.L	D0,A2
	MOVE.L	-$10(A4,D3.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05AC2A
	MOVE.L	D0,A3
	AND.L	#$0F000000,D4
	BNE	lbC05AC2A
	MOVE.B	D7,D0
	MOVE.B	D0,D6
	ASL.B	#$04,D6
	ADDQ.B	#$02,D6
	MOVE.B	D6,lbB057D75
	CLR.L	D6
	CLR.L	D7
	LSR.B	#$01,D0
	BCC	lbC05AC08
	NOT.W	D6
lbC05AC08:
	SWAP	D6
	LSR.B	#$01,D0
	BCC	lbC05AC12
	NOT.W	D6
lbC05AC12:
	LSR.B	#$01,D0
	BCC	lbC05AC1A
	NOT.W	D7
lbC05AC1A:
	SWAP	D7
	LSR.B	#$01,D0
	BCC	lbC05AC24
	NOT.W	D7
lbC05AC24:
	JSR	renderQuadrilateral
lbC05AC2A:
	RTS

rasterizeVerticalEdge:
	CMP.W	#$0080,$0002(A3)
	BCC	lbC05AE0A
	MOVE.L	A3,A2
	ADD.L	#$00000008,A3
	MOVE.W	(A2),D5
	SUBQ.W	#$01,D5
	MOVE.W	$0004(A2),D4
	BEQ	lbC05AC90
	CMP.W	#$0100,D4
	BGE	lbC05AC62
	MOVE.W	(A3)+,D6
	BPL	lbC05ACA2
	MOVE.W	$0006(A2),D6
	BRA	lbC05ACA2

lbC05AC62:
	BNE	lbC05AE0A
	SUBQ.W	#$01,D4
	BRA	lbC05AC6E

lbC05AC6C:
	SUBQ.W	#$01,D5
lbC05AC6E:
	MOVE.W	(A3)+,D6
	CMP.W	#$0100,D6
	BEQ	lbC05AC6C
	TST.W	D6
	BPL	lbC05ACA2
	MOVE.W	$0006(A2),D6
	CMP.W	#$0100,D6
	BEQ	lbC05AE0A
	BRA	lbC05ACA2

lbC05AC8E:
	SUBQ.W	#$01,D5
lbC05AC90:
	MOVE.W	(A3)+,D6
	BEQ	lbC05AC8E
	BPL	lbC05ACA2
	MOVE.W	$0006(A2),D6
	BEQ	lbC05AE0A
lbC05ACA2:
	CMP.W	#$0080,D5
	BCC	lbC05AE0A
	CMP.W	#$0100,D4
	BCC	lbC05AE0A
	SUB.L	#$00000002,A3
	MOVE.W	$0004(A2),D0
	SUB.W	$0006(A2),D0
	BMI	lbC05AD66
	MOVE.L	viewportTopAddress,A0
	MOVE.W	D4,D0
	EXT.L	D0
	EXT.L	D5
	LSR.L	#$03,D0
	AND.B	#$FE,D0
	ADD.L	D0,A0
	MOVE.L	D5,D0
	ASL.L	#$02,D0
	ADD.L	D5,D0
	ASL.L	#$03,D0
	ADD.L	D0,A0
	MOVE.B	#$00,D2
	MOVE.W	(A3)+,D6
	BPL	lbC05AD00
	TST.B	D2
	BMI	lbC05AD64
	MOVE.B	#$80,D2
	SUB.L	#$00000002,A3
	MOVE.W	$0006(A2),D6
lbC05AD00:
	BNE	lbC05AD08
	MOVE.W	#$FFFF,D6
lbC05AD08:
	JSR	plotPixel
	CMP.W	D4,D6
	BNE	lbC05AD48
	MOVE.W	(A3)+,D6
	BPL	lbC05AD2E
	TST.B	D2
	BMI	lbC05AD64
	MOVE.B	#$80,D2
	SUB.L	#$00000002,A3
	MOVE.W	$0006(A2),D6
lbC05AD2E:
	BNE	lbC05AD36
	MOVE.W	#$FFFF,D6
lbC05AD36:
	SUBQ.W	#$01,D5
	BMI	lbC05AE0A
	SUB.L	#$00000028,A0
	CMP.W	D4,D6
	BEQ	lbC05AD08
lbC05AD48:
	MOVE.W	D4,D0
	SUBQ.W	#$01,D4
	AND.W	#$000F,D0
	BNE	lbC05AD60
	TST.W	D4
	BMI	lbC05AE0A
	SUB.L	#$00000002,A0
lbC05AD60:
	BRA	lbC05AD08

lbC05AD64:
	RTS

lbC05AD66:
	MOVE.L	viewportTopAddress,A0
	MOVE.W	D4,D0
	EXT.L	D0
	EXT.L	D5
	LSR.L	#$03,D0
	AND.B	#$FE,D0
	ADD.L	D0,A0
	MOVE.L	D5,D0
	ASL.L	#$02,D0
	ADD.L	D5,D0
	ASL.L	#$03,D0
	ADD.L	D0,A0
	MOVE.B	#$00,D2
	MOVE.W	(A3)+,D6
	BPL	lbC05ADA2
	TST.B	D2
	BMI	lbC05AE08
	MOVE.B	#$80,D2
	SUB.L	#$00000002,A3
	MOVE.W	$0006(A2),D6
lbC05ADA2:
	BNE	lbC05ADAA
	MOVE.W	#$FFFF,D6
lbC05ADAA:
	JSR	plotPixel
	CMP.W	D4,D6
	BNE	lbC05ADEA
	MOVE.W	(A3)+,D6
	BPL	lbC05ADD0
	TST.B	D2
	BMI	lbC05AE08
	MOVE.B	#$80,D2
	SUB.L	#$00000002,A3
	MOVE.W	$0006(A2),D6
lbC05ADD0:
	BNE	lbC05ADD8
	MOVE.W	#$FFFF,D6
lbC05ADD8:
	SUBQ.W	#$01,D5
	BMI	lbC05AE0A
	SUB.L	#$00000028,A0
	CMP.W	D4,D6
	BEQ	lbC05ADAA
lbC05ADEA:
	ADDQ.W	#$01,D4
	MOVE.W	D4,D0
	AND.W	#$000F,D0
	BNE	lbC05AE04
	CMP.W	#$0100,D4
	BGE	lbC05AE0A
	ADD.L	#$00000002,A0
lbC05AE04:
	BRA	lbC05ADAA

lbC05AE08:
	RTS

lbC05AE0A:
	RTS

sortTriangleVertices:
	MOVE.W	(A0),D0
	CMP.W	(A2),D0
	BEQ	lbC05AE2E
	CMP.W	(A1),D0
	BEQ	lbC05AE24
	MOVE.L	A1,A3
	MOVE.L	A0,A1
	EXG	A2,A0
	BRA	lbC05AE32

lbC05AE24:
	MOVE.L	A0,A3
	MOVE.L	A1,A0
	MOVE.L	A2,A1
	BRA	lbC05AE32

lbC05AE2E:
	MOVE.L	A2,A3
	MOVE.L	A1,A2
lbC05AE32:
	MOVE.B	#$01,lbB0581A0
	BRA	scanlinePolygonFill

renderMountainHorizon:
	MOVE.W	viewportCenterY,D0
	ASR.W	#$03,D0
	NEG.W	D0
	MOVE.W	D0,mountainScreenY
	MOVE.L	#mountainHorizontalAngles,A0
	MOVE.B	cameraAngleY,D6
	SUB.B	#$1C,D6
	MOVE.B	#$2C,D7
	MOVE.B	mountainSegmentCount,D1
	SUBQ.B	#$01,D1
lbC05AE6A:
	MOVE.B	$00(A0,D1.W),D0
	SUB.B	D6,D0
	CMP.B	D7,D0
	BCC	lbC05AFF4
	MOVEM.L	D1/D6/D7/A0,-(SP)
	SUB.B	#$1C,D0
	ASL.W	#$08,D0
	CLR.W	D3
	MOVE.B	cameraAngleYLow,D3
	AND.B	#$FE,D3
	SUB.W	D3,D0
	ASR.W	#$03,D0
	MOVE.W	D0,mountainScreenX
	CLR.W	D0
	MOVE.L	#mountainShapeIndices,A0
	MOVE.B	$00(A0,D1.W),D0
	ASL.W	#$03,D0
	MOVE.L	#mountainSilhouetteTable,A0
	MOVE.L	$00(A0,D0.W),A6
	MOVE.L	$04(A0,D0.W),A2
	MOVE.W	(A6)+,D6
	SUBQ.W	#$01,D6
	MOVE.B	D6,D1
	ASL.B	#$01,D1
	MOVE.L	#coordinateLookupTable,A4
	MOVE.L	#transformedVertexBounds,A5
	MOVE.W	mountainScreenX,D4
	MOVE.W	mountainScreenY,D5
lbC05AED2:
	MOVE.W	(A6)+,D0
	BPL	lbC05AEDA
	MOVE.W	(A2)+,D0
lbC05AEDA:
	ADD.W	D4,D0
	MOVE.W	D0,(A4)+
	MOVE.W	(A6)+,D0
	BPL	lbC05AEE6
	MOVE.W	(A2)+,D0
lbC05AEE6:
	SUB.W	D5,D0
	NEG.W	D0
	MOVE.W	D0,(A5)+
	DBRA	D6,lbC05AED2
	MOVE.L	A6,-(SP)
	MOVE.L	#lbL00DB30,A3
	MOVE.L	#coordinateLookupTable,A5
	MOVE.L	#transformedVertexBounds,A4
lbC05AF04:
	JSR	projectVertexToScreen
	SUBQ.B	#$02,D1
	BPL	lbC05AF04
	MOVE.L	(SP)+,A6
	MOVE.W	#$0000,renderCommandQueueOffset
	MOVE.B	(A6)+,lbB05B097
lbC05AF20:
	MOVE.B	(A6)+,D1
	MOVE.B	(A6)+,D2
	MOVE.L	A6,-(SP)
	JSR	drawClippedLine
	MOVE.L	(SP)+,A6
	ADDQ.W	#$04,renderCommandQueueOffset
	SUBQ.B	#$01,lbB05B097
	BNE	lbC05AF20
	MOVE.B	(A6)+,lbB05B098
lbC05AF44:
	MOVE.L	#renderCommandQueue,A5
	MOVE.B	(A6)+,D0
	JSR	setupBitplaneMasks
	MOVE.B	(A6)+,lbB05B096
	MOVE.L	#$FFFFFFFF,D4
	MOVE.B	(A6)+,D2
	MOVE.L	$00(A5,D2.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05AFE6
	MOVE.L	D0,A0
	MOVE.B	(A6)+,D2
	MOVE.L	$00(A5,D2.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05AFE6
	MOVE.L	D0,A1
	MOVE.B	(A6)+,D2
	MOVE.L	$00(A5,D2.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05AFE6
	MOVE.L	D0,A2
	CMP.B	#$03,lbB05B096
	BNE	lbC05AFBE
	AND.L	#$0F000000,D4
	BNE	lbC05AFE6
	MOVE.L	A6,-(SP)
	JSR	sortTriangleVertices
	MOVE.L	(SP)+,A6
	BRA	lbC05AFE6

lbC05AFBE:
	MOVE.B	(A6)+,D2
	MOVE.L	$00(A5,D2.W),D0
	AND.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05AFE6
	MOVE.L	D0,A3
	AND.L	#$0F000000,D4
	BNE	lbC05AFE6
	MOVE.L	A6,-(SP)
	JSR	renderQuadrilateral
	MOVE.L	(SP)+,A6
lbC05AFE6:
	SUBQ.B	#$01,lbB05B098
	BNE	lbC05AF44
	MOVEM.L	(SP)+,D1/D6/D7/A0
lbC05AFF4:
	SUBQ.B	#$01,D1
	BPL	lbC05AE6A
	RTS

loadMountainData:
	;MOVE.B	currentTrackID,D1
	MOVE.B	#$00,D1
	MOVE.L	#trackMountainDataTable,A1
	ASL.B	#$02,D1
	MOVE.L	$00(A1,D1.W),A2
	MOVE.B	(A2)+,D3
	MOVE.B	D3,mountainSegmentCount
	MOVE.L	#mountainHorizontalAngles,A0
	MOVE.L	#mountainShapeIndices,A1
	MOVE.W	#$0000,D1
lbC05B02A:
	MOVE.B	(A2)+,(A0)+
	MOVE.B	(A2)+,(A1)+
	SUBQ.B	#$01,D3
	BNE	lbC05B02A
loadMountainDataDone:
	RTS

initializeGraphicsData:
	MOVE.L	#bitmapGraphicsBuffer,A1
	MOVE.W	#$0000,D4
.loadGraphicsElementLoop:
	JSR	loadGraphicsElement
	ADDQ.W	#$01,D4
	CMP.W	#$000A,D4
	BNE	.graphicsElementIndexOk
	MOVE.W	#$000F,D4
.graphicsElementIndexOk:
	cmp.w	#$0025,d4				; added
	bne.s	.notFirstSprite
	move.l	a1,-(sp)
	lea	spriteBuffer,a1
	bra.s	.destinationOk
.notFirstSprite:
	cmp.w	#$0031,d4
	bne.s	.destinationOk
	move.l	(sp)+,a1
.destinationOk:
	CMP.W	#$0034,D4
	BNE	.loadGraphicsElementLoop
	MOVE.L	A1,-(SP)
	MOVE.L	#imageMainGameBackground,A0
	MOVE.L	#bitplaneMaskTable,A1
	JSR	decompressRLEObjectToMask
	MOVE.L	(SP)+,A1
	MOVE.W	#$000A,D4
.loadGraphicsElementWithMaskLoop:
	JSR	loadGraphicsElement
	ADDQ.W	#$01,D4
	CMP.W	#$000F,D4
	BNE	.loadGraphicsElementWithMaskLoop
	RTS

loadGraphicsElement:
	CLR.B	loadingHardwareSprite
	CMP.W	#$0025,D4				; indices 37-48 are hardware sprite graphics and need special handling
	BLT	.loadingHardwareSpriteOk
	CMP.W	#$0030,D4
	BGT	.loadingHardwareSpriteOk
	MOVE.B	#$80,loadingHardwareSprite
.loadingHardwareSpriteOk:
	MOVE.W	D4,D0
	ASL.W	#$02,D0
	MOVE.L	#graphicsPointerTable,A5
	MOVE.L	A1,$00(A5,D0.W)
	ASL.W	#$02,D0
	MOVE.L	#graphicsRenderingParameters,A3
	LEA	$00(A3,D0.W),A3
	MOVE.W	(A3)+,D1
	MOVE.W	(A3)+,D2
	MOVE.L	#bitplaneMaskTable,A4
	AND.L	#$000000FF,D1
	AND.L	#$000000FF,D2
	ASL.L	#$03,D1
	ADD.L	D1,A4
	MOVE.L	D2,D1
	ASL.L	#$02,D1
	ADD.L	D1,D2
	ASL.L	#$05,D2
	ADD.L	D2,A4
	MOVE.W	(A3)+,D1
	MOVE.W	(A3)+,D2
	TST.B	loadingHardwareSprite
	BEQ	loadBitmapData
	JMP	loadHardwareSprite

loadBitmapData:
	MOVE.W	D1,D3
	MOVE.L	A4,A2
lbC05B6C2:
	MOVE.L	(A4)+,D6
	MOVE.L	(A4)+,D7
	CLR.L	D5
	MOVE.L	#$0000000F,D0
lbC05B6CE:
	MOVE.B	#$00,D5
	BTST	D0,D6
	BEQ	lbC05B6DC
	BSET	#$01,D5
lbC05B6DC:
	BTST	D0,D7
	BEQ	lbC05B6E6
	BSET	#$03,D5
lbC05B6E6:
	BSET	#$04,D0
	BTST	D0,D6
	BEQ	lbC05B6F4
	BSET	#$00,D5
lbC05B6F4:
	BTST	D0,D7
	BEQ	lbC05B6FE
	BSET	#$02,D5
lbC05B6FE:
	CMP.B	#$01,D5
	BNE	lbC05B708
	BSET	D0,D5
lbC05B708:
	BCLR	#$04,D0
	DBRA	D0,lbC05B6CE
	MOVE.L	D5,D0
	SWAP	D5
	MOVE.W	D5,D0
	MOVE.W	D0,(A1)+
	NOT.L	D0
	AND.L	D0,D6
	MOVE.L	D6,(A1)+
	AND.L	D0,D7
	MOVE.L	D7,(A1)+
	DBRA	D3,lbC05B6C2
	LEA	$00A0(A2),A4
	DBRA	D2,loadBitmapData
	RTS

loadHardwareSprite:
	MOVE.W	D2,D6
	MOVE.W	(A3),D0
	ASL.W	#$04,D0
	ADD.W	#$0080,D0
	MOVE.W	$0002(A3),D3
	ADD.W	spriteYOffset,D3
	ADD.W	D3,D6
	ASL.L	#$08,D3
	ASL.L	#$08,D6
	MOVE.W	D0,D1
	LSR.W	#$01,D1
	MOVE.B	D1,D3
	MOVE.W	D3,(A1)+
	MOVE.W	D6,D1
	BTST	#$10,D3
	BEQ	lbC05B760
	BSET	#$02,D1
lbC05B760:
	BTST	#$10,D6
	BEQ	lbC05B76C
	BSET	#$01,D1
lbC05B76C:
	BTST	#$00,D0
	BEQ	lbC05B778
	BSET	#$00,D1
lbC05B778:
	MOVE.W	D1,(A1)+
lbC05B77A:
	MOVE.W	(A4),D0
	EOR.W	#$FFFF,D0
	MOVE.W	D0,(A1)+
	MOVE.W	$0004(A4),(A1)+
	LEA	$00A0(A4),A4
	DBRA	D2,lbC05B77A
	MOVE.L	#$00000000,(A1)+
	CLR.W	D1
	CLR.W	D2
	RTS

loadPaletteColors:
	MOVE.L	#copperlistColor16,A0
	MOVE.L	#spritePalette,A1
	MOVE.W	#$0007,D0
.loop:	MOVE.W	(A1)+,(A0)+
	ADDQ.L	#$02,A0
	DBRA	D0,.loop
	RTS

initializeSpritePointers:
	MOVE.W	#$0007,D3
.loop:	MOVE.W	D3,D1
	MOVE.L	#emptySprite,D0
	JSR	setSpritePointer
	DBRA	D3,.loop
	RTS

setSpriteFromTable:
	MOVE.L	#graphicsPointerTable,A1
	AND.W	#$00FF,D0
	ASL.W	#$02,D0
	MOVE.L	$00(A1,D0.W),D0
setSpritePointer:
	MOVE.L	#copperlistSprite0,A0
	ASL.W	#$03,D1
	MOVE.W	D0,$04(A0,D1.W)
	SWAP	D0
	MOVE.W	D0,$00(A0,D1.W)
	RTS

updateSpritePositions:
	MOVE.W	#$0094,D1
lbC05B808:
	MOVE.L	#graphicsPointerTable,A0
	MOVE.L	$00(A0,D1.W),A0
	MOVE.W	D1,D0
	ASL.W	#$02,D0
	MOVE.L	#graphicsRenderingParameters,A1
	MOVE.W	$0A(A1,D0.W),D0
	ADD.W	spriteYOffset,D0
	MOVE.B	$0002(A0),D3
	SUB.B	(A0),D3
	MOVE.B	D0,(A0)
	ADD.B	D3,D0
	MOVE.B	D0,$0002(A0)
	ADDQ.W	#$04,D1
	CMP.W	#$00C4,D1
	BNE	lbC05B808
	RTS

renderMaskedGraphicsObject:
	MOVE.L	D5,-(SP)
	MOVE.W	D1,-(SP)
	MOVEM.L	A4-A6,-(SP)
	AND.W	#$00FF,D0
	move.w	d0,d5
	ASL.W	#$02,D0
	MOVE.L	#graphicsPointerTable,A1
	MOVE.L	$00(A1,D0.W),A1
	ASL.W	#$02,D0
	MOVE.L	#graphicsRenderingParameters,A2
	LEA	$04(A2,D0.W),A2
	MOVE.W	$0004(A2),D0
	MOVE.W	$0006(A2),D3
	MOVE.L	renderFrameBuffer,A0
	cmp.w	#$33,d5					; added: render directly to chip if message background or top bar
	beq.s	.copyChip
	cmp.w	#16,d3
	bcs.s	.copyChip
	lea	fastRenderBuffer,a0
.copyChip:
	AND.L	#$000000FF,D0
	AND.L	#$000000FF,D3
	ASL.L	#$01,D0
	ADD.L	D0,A0
	MOVE.L	D3,D0
	ASL.L	#$02,D0
	ADD.L	D0,D3
	ASL.L	#$03,D3
	ADD.L	D3,A0
	LEA	$1F40(A0),A4
	LEA	$3E80(A0),A5
	LEA	$5DC0(A0),A6
	MOVE.W	(A2),D1
	MOVE.W	$0002(A2),D4
.yLoop:	MOVE.L	A0,A2
	MOVE.W	D1,D3
.xLoop:	MOVE.W	(A1)+,D5
	MOVE.W	(A0),D0
	AND.W	D5,D0
	OR.W	(A1)+,D0
	MOVE.W	D0,(A0)+
	MOVE.W	(A4),D0
	AND.W	D5,D0
	OR.W	(A1)+,D0
	MOVE.W	D0,(A4)+
	MOVE.W	(A5),D0
	AND.W	D5,D0
	OR.W	(A1)+,D0
	MOVE.W	D0,(A5)+
	MOVE.W	(A6),D0
	AND.W	D5,D0
	OR.W	(A1)+,D0
	MOVE.W	D0,(A6)+
	DBRA	D3,.xLoop
	LEA	$0028(A2),A0
	LEA	$1F68(A2),A4
	LEA	$3EA8(A2),A5
	LEA	$5DE8(A2),A6
	DBRA	D4,.yLoop
	MOVEM.L	(SP)+,A4-A6
	MOVE.W	(SP)+,D1
	MOVE.L	(SP)+,D5
	RTS

renderObjectColumn:
	MOVE.W	(A1)+,D0
	SWAP	D0
	MOVE.W	#$FFFF,D0
	ROR.L	D3,D0
	MOVE.L	D0,D6
	SWAP	D0
	MOVE.W	D0,D6
	MOVE.L	D0,D7
	SWAP	D0
	MOVE.W	D0,D7
	MOVE.L	D7,-(SP)
	MOVE.L	(A1)+,D0
	MOVE.L	D0,D7
	CLR.W	D0
	SWAP	D7
	CLR.W	D7
	LSR.L	D3,D0
	LSR.L	D3,D7
	MOVE.L	D0,D4
	SWAP	D7
	MOVE.W	D7,D4
	MOVE.W	D0,D7
	SWAP	D7
	MOVE.L	D7,-(SP)
	MOVE.L	(A1)+,D0
	MOVE.L	D0,D7
	CLR.W	D0
	SWAP	D7
	CLR.W	D7
	LSR.L	D3,D0
	LSR.L	D3,D7
	MOVE.L	D0,D5
	SWAP	D7
	MOVE.W	D7,D5
	MOVE.W	D0,D7
	SWAP	D7
	CMP.W	#$0010,renderGraphicsCurrentX
	BCC	lbC05B96E
	MOVE.W	(A0),D0
	SWAP	D0
	MOVE.W	$1F40(A0),D0
	AND.L	D6,D0
	OR.L	D4,D0
	MOVE.W	D0,$1F40(A0)
	SWAP	D0
	MOVE.W	D0,(A0)+
	MOVE.W	$3E7E(A0),D0
	SWAP	D0
	MOVE.W	$5DBE(A0),D0
	AND.L	D6,D0
	OR.L	D5,D0
	MOVE.W	D0,$5DBE(A0)
	SWAP	D0
	MOVE.W	D0,$3E7E(A0)
	BRA	lbC05B974

lbC05B96E:
	ADD.L	#$00000002,A0
lbC05B974:
	MOVE.L	(SP)+,D4
	MOVE.L	(SP)+,D6
	ADDQ.W	#$01,renderGraphicsCurrentX
	CMP.W	#$0010,renderGraphicsCurrentX
	BCC	lbC05B9B6
	MOVE.W	(A0),D0
	SWAP	D0
	MOVE.W	$1F40(A0),D0
	AND.L	D6,D0
	OR.L	D4,D0
	MOVE.W	D0,$1F40(A0)
	SWAP	D0
	MOVE.W	D0,(A0)
	MOVE.W	$3E80(A0),D0
	SWAP	D0
	MOVE.W	$5DC0(A0),D0
	AND.L	D6,D0
	OR.L	D7,D0
	MOVE.W	D0,$5DC0(A0)
	SWAP	D0
	MOVE.W	D0,$3E80(A0)
lbC05B9B6:
	SUBQ.W	#$01,renderGraphicsCurrentX
	RTS

renderGraphicsObjectAtPosition:
	MOVE.W	D1,-(SP)
	MOVE.W	D2,-(SP)
	AND.W	#$00FF,D0
	ASL.W	#$02,D0
	MOVE.L	#graphicsPointerTable,A1
	MOVE.L	$00(A1,D0.W),A1
	ASL.W	#$02,D0
	MOVE.L	#graphicsRenderingParameters,A2
	LEA	$04(A2,D0.W),A2
	;MOVE.L	renderFrameBuffer,A0
	lea	fastRenderBuffer,a0
	MOVE.W	D4,D0
	EXT.L	D0
	EXT.L	D5
	LSR.L	#$03,D0
	AND.B	#$FE,D0
	ADD.L	D0,A0
	MOVE.L	D5,D0
	ASL.L	#$02,D0
	ADD.L	D5,D0
	ASL.L	#$03,D0
	ADD.L	D0,A0
	MOVE.W	(A2),A6
	MOVE.W	$0002(A2),D2
	MOVE.W	D4,D3
	AND.L	#$0000000F,D3
	MOVE.W	D4,D0
	ASR.W	#$04,D0
	SUBQ.W	#$02,D0
	MOVE.W	D0,lbW05BA66
	MOVE.W	D0,renderGraphicsCurrentX
	MOVE.W	D5,D0
	SUB.W	#$0010,D0
	MOVE.W	D0,renderGraphicsCurrentY
lbC05BA28:
	MOVE.L	A0,A2
	MOVE.W	A6,D1
	CMP.W	#$0080,renderGraphicsCurrentY
	BCC	lbC05BA48
lbC05BA38:
	JSR	renderObjectColumn
	ADDQ.W	#$01,renderGraphicsCurrentX
	DBRA	D1,lbC05BA38
lbC05BA48:
	MOVE.W	lbW05BA66,renderGraphicsCurrentX
	LEA	$0028(A2),A0
	ADDQ.W	#$01,renderGraphicsCurrentY
	DBRA	D2,lbC05BA28
	MOVE.W	(SP)+,D2
	MOVE.W	(SP)+,D1
	RTS

	ifne	WHDLOAD
	section OriginalData,bss
	ds.l	1
gameData:
	ds.b	408540
	else
	section OriginalData,data
	ds.l	1
gameData:
	incbin	"scr.exe.decrypted"
	endc
saveLapRecords:
	ds.l	1
readWriteSaveSlotData:
	ds.l	1
infiniteBoost:
	ds.l	1

ORIGINAL_LOAD_ADDRESS		equ	$e700
audioChannelMasks		equ	gameData+$c50
audioChannel0Period		equ	gameData+$cfc8
sampleParameterTable		equ	gameData+$cfca
sampleGrindPeriod		equ	gameData+$cfe2
sampleImpactVolume		equ	gameData+$d005
audioSample4Volume		equ	gameData+$d015
sampleGroundCollisionPeriod	equ	gameData+$d032
sampleEnginePointer		equ	gameData+$d03a
sampleEngineSize		equ	gameData+$d03e
joystickState			equ	gameData+$d18e
lbW00D190			equ	gameData+$94
lbB00D194			equ	gameData+$98
uppercaseTable			equ	gameData+$d198
lowercaseTable			equ	gameData+$d250
sineTable			equ	gameData+$e342
reciprocalTable			equ	gameData+$e546
arctanTable			equ	gameData+$f546
transformationMatrix		equ	gameData+$10546
playerNamesWithSpaces		equ	gameData+$105aa
playerNames			equ	gameData+$105ab
opponentDriverNames		equ	gameData+$105ea
obfuscationWhitespace		equ	gameData+$1065b
nameInputBuffer			equ	gameData+$1066b
opponentBehaviorTraits		equ	gameData+$1068a
trackNames			equ	gameData+$106aa
attenuationTable		equ	gameData+$107ca
distanceLookupTable		equ	gameData+$1084a
trackGeometryDatabase		equ	gameData+$10882
segmentGeometryOffsetTable	equ	gameData+$108a2
trackDataOffsetTable		equ	gameData+$109a2
geometryParameterTable		equ	gameData+$109c2
lbW01172C			equ	gameData+$1172c
playerContextConfiguration	equ	gameData+$1176c
primaryFontBitmapData		equ	gameData+$11782
lbB0117ED			equ	gameData+$117ed
lbB0117F7			equ	gameData+$117f7
lbB0117F8			equ	gameData+$117f8
lbL01197A			equ	gameData+$1197a
lbW01197E			equ	gameData+$1197e
lbB011980			equ	gameData+$11980
imageMainGameBackgroundPalette	equ	gameData+$11a84
imageMainGameBackground		equ	gameData+$11aa4
imageMenuScreenPalette		equ	gameData+$15532
imageMenuScreen			equ	gameData+$15552
alternateFontBitmapData		equ	gameData+$18bc2
imageTrackPreviewBackgroundPalette	equ	gameData+$1d274
imageTrackPreviewBackground	equ	gameData+$1d294
imageStandingsBackgroundPalette	equ	gameData+$224d0
imageStandingsBackground	equ	gameData+$224f0
imagePlayersPalette		equ	gameData+$27376
imagePlayers			equ	gameData+$27396
imageWreck			equ	gameData+$2f0b6
imageWon			equ	gameData+$3607c
imageLost			equ	gameData+$3c83e
imagePromotion			equ	gameData+$4274c
lbL049700			equ	gameData+$49700
lbW049A46			equ	gameData+$49a46
lbW049A4E			equ	gameData+$49a4e
lbW049A56			equ	gameData+$49a56
encodedControlIndices		equ	gameData+$49d9a
keyboardMatrixTable		equ	gameData+$49e00
lbL04A180			equ	gameData+$4a180
lbB04A3A2			equ	gameData+$4a3a2
lbW04A3A4			equ	gameData+$4a3a4
lbW04A420			equ	gameData+$4a420
lbW04A49A			equ	gameData+$4a49a
lbL04A4BC			equ	gameData+$4a4bc
playerGraphicsMask		equ	gameData+$4a4d6
lbW04AA40			equ	gameData+$4aa40
leagueStatisticsTextTable	equ	gameData+$4aa5e
alternateEndScreenEnabledFlag	equ	gameData+$4acf6
interpolationBlendFactor	equ	gameData+$4be4e
textStringTable			equ	gameData+$4bf9a
lbB04C057			equ	gameData+$4c057
aiBaseSkillTable		equ	gameData+$4c3f4
divisionBaseOffsets		equ	gameData+$4c442
player1OpponentIndices		equ	gameData+$4c4c8
player2OpponentIndices		equ	gameData+$4c4ce
specialSegmentLookupTable	equ	gameData+$4cbc4
menuStringOffsetTable		equ	gameData+$4d5d0
aiMovementPatterns		equ	gameData+$4d734
lbL04DFB8			equ	gameData+$4dfb8
lbB04E1F4			equ	gameData+$4e1f4
lbB04E7E2			equ	gameData+$4e7e2
lbL04E82C			equ	gameData+$4e82c
defaultRecordTemplate		equ	gameData+$4e830
lbL04FD6C			equ	gameData+$4fd6c
gameMessageMode			equ	gameData+$4ff5a
gameMessageIndex		equ	gameData+$4ff5b
gameMessageTable		equ	gameData+$4ff5c
divisionRowPositions		equ	gameData+$50464
trackColumnOffsets		equ	gameData+$5046c
raceCount			equ	gameData+$50478
currentPlayerID			equ	gameData+$50479
lbB05047E			equ	gameData+$5047e
menuTextStrings			equ	gameData+$5047f
lbL050548			equ	gameData+$50548
trackRecordMessage		equ	gameData+$50555
raceResultsText			equ	gameData+$50592
resultsTableHeader		equ	gameData+$50620
commandSkipStandingsScreen	equ	gameData+$50e8a
commandRestoreDriverNames	equ	gameData+$50e8e
diskIOMessages			equ	gameData+$50f41
obfuscationLcgState		equ	gameData+$51020
lbB0513DE			equ	gameData+$513de
messageTypeTable		equ	gameData+$513e3
playersControlKeys		equ	gameData+$5143a
trackAbbreviationCodes1		equ	gameData+$516e0
trackAbbreviationCodes2		equ	gameData+$516e1
lbL051E52			equ	gameData+$51e52
lbB051E56			equ	gameData+$51e56
lbL051E5A			equ	gameData+$51e5a
obfuscationCipherIndex		equ	gameData+$52586
controlKeys			equ	gameData+$5143a
keycodeTable			equ	gameData+$49a6d
dustCloudOffsetTable		equ	gameData+$5289c
dustCloudAnimSequence		equ	gameData+$528ac
steeringOffsetTable		equ	gameData+$52b5a
trackDisplayYOffsets		equ	gameData+$52b9a
lbB0530CA			equ	gameData+$530ca
cameraAngleThresholds		equ	gameData+$533d4
saveLoadMenuText		equ	gameData+$53ece
lbB0544B8			equ	gameData+$544b8
lbB0544B9			equ	gameData+$544b9
lbW054632			equ	gameData+$54632
lbW054F84			equ	gameData+$54f84
savedRandomSeed1		equ	gameData+$54fb8
savedRandomSeed3		equ	gameData+$54fbc
opponentSuspensionDampingTable	equ	gameData+$55bea
leagueTextTable			equ	gameData+$55c54
lbB055C56			equ	gameData+$55c56
lbB055C63			equ	gameData+$55c63
trackSpecificYOffset		equ	gameData+$55cad
trackIDLookupTable		equ	gameData+$561c2
lbL0563C6			equ	gameData+$563c6
lbL0563EC			equ	gameData+$563ec
lapRecordsLoadedFlag		equ	gameData+$563f0
lbL0563F4			equ	gameData+$563f4
displayColumnOffset		equ	gameData+$56402
menuCursorObjectType		equ	gameData+$56518
lbL05651A			equ	gameData+$5651a
lbB056DC0			equ	gameData+$56dc0
trackSpecificRenderDepthOverrides	equ	gameData+$57730
damageBarVerticalOffset		equ	gameData+$57baa
damageBarColor			equ	gameData+$57bab
lbW0580E0			equ	gameData+$580e0
bitMaskTable			equ	gameData+$58160
trackColorIndex2		equ	gameData+$5aab2
trackColorIndex1		equ	gameData+$5aab3
mountainShape0Data		equ	gameData+$5b09e
mountainShape1Data		equ	gameData+$5b0c0
mountainShape2Data		equ	gameData+$5b0e8
mountainShape3Data		equ	gameData+$5b132
mountainShape4Data		equ	gameData+$5b168
mountainData00			equ	gameData+$5b18a
mountainData01			equ	gameData+$5b194
mountainData02			equ	gameData+$5b19e
mountainData03			equ	gameData+$5b1a8
mountainData04			equ	gameData+$5b1b2
mountainData05			equ	gameData+$5b1bc
mountainData06			equ	gameData+$5b1c6
mountainData07			equ	gameData+$5b1d0
mountainData08			equ	gameData+$5b1da
mountainData09			equ	gameData+$5b1e4
mountainData0a			equ	gameData+$5b1ee
mountainData0b			equ	gameData+$5b1f8
mountainData0c			equ	gameData+$5b202
mountainData0d			equ	gameData+$5b20c
mountainData10			equ	gameData+$5b236
mountainData11			equ	gameData+$5b248
mountainData12			equ	gameData+$5b25a
mountainData13			equ	gameData+$5b26c
mountainData20			equ	gameData+$5b27e
mountainData21			equ	gameData+$5b28c
mountainData22			equ	gameData+$5b29a
mountainData23			equ	gameData+$5b2a8
mountainData30			equ	gameData+$5b2b6
trackMountainCountsAnglesAndIndices	equ	gameData+$5b388
spritePalette			equ	gameData+$5b7b4
spriteYOffset			equ	gameData+$5b7c4
dmaconValueToSet		equ	gameData+$5b7de
graphicsRenderingParameters	equ	gameData+$5ba6c
rightWheelHeight		equ	gameData+$5ba76
leftWheelHeight			equ	gameData+$5baa6
chainRenderParams		equ	gameData+$5bba6
bitplaneMaskTable		equ	gameData+$5beb6

sampleEngineParameters		equ	gameData+$d74
downsampledSampleEngineTable	equ	gameData+$d78
palette				equ	gameData+$13a
sourcePalette			equ	gameData+$15a
keyboardState			equ	gameData+$3d6
serialReceiveBuffer		equ	gameData+$456
serialTransmitBuffer		equ	gameData+$556
ciaBTimerBSet			equ	gameData+$9a8
serialBufferIndex		equ	gameData+$b54
lbB000B55			equ	gameData+$b55
serialWriteIndex		equ	gameData+$b56
serialReadIndex			equ	gameData+$b57
lbB000B58			equ	gameData+$b58
lbW000B5A			equ	gameData+$b5a
grindSampleID			equ	gameData+$c60
audioDMAEnableGuard		equ	gameData+$cee
bitplane1Pointer		equ	gameData+$d112
copperlistUpdatePendingFlag	equ	gameData+$d116
framesSinceCopperlistUpdateAccumulator	equ	gameData+$d117
gameDataRegionStart		equ	gameData+$d3f8		; label only, marks start of init-cleared region
playerContextValues		equ	gameData+$d3f8
gasInputIntensityValue		equ	gameData+$d3fa
gasInputAccumulatorValue	equ	gameData+$d3fb
aiBaseSpeedHigh			equ	gameData+$d3fc
aiBaseSpeedLow			equ	gameData+$d3fd
fuelConsumptionRate		equ	gameData+$d3fe
trackWidthMultiplier		equ	gameData+$d401
trackViewOffsetX		equ	gameData+$d404
trackViewOffsetY		equ	gameData+$d406
subGridOffsetX			equ	gameData+$d407
subGridOffsetZ			equ	gameData+$d409
trackProgressionByte		equ	gameData+$d40a
opponentSubSegmentProgress	equ	gameData+$d40c
trackProgressionOffset		equ	gameData+$d40e
lbB00D40F			equ	gameData+$d40f
lbW00D410			equ	gameData+$d410
trackDistance			equ	gameData+$d412
trackDistanceHigh		equ	gameData+$d413
currentMenuItem			equ	gameData+$d416
encodeDecodeFlag		equ	currentMenuItem
tempByte0			equ	gameData+$d417
tempByte1			equ	gameData+$d418
tempByte2			equ	gameData+$d419
tempByte3			equ	gameData+$d41a
tempByte4			equ	gameData+$d41b
playerSegmentIndex		equ	gameData+$d41c
opponentSegmentIndex		equ	gameData+$d41d
lapCrossingDetectionFlag	equ	gameData+$d41e
player1LapCounter		equ	gameData+$d420
player2LapCounter		equ	gameData+$d421
baseCoordinateX			equ	gameData+$d422
cameraGridOffsetXLow		equ	gameData+$d423
baseCoordinateY			equ	gameData+$d426
cameraGridOffsetZLow		equ	gameData+$d427
perpendicularOffsetY		equ	gameData+$d42a
rawDisplacementValue		equ	gameData+$d42b
tempAttenuatedValue		equ	gameData+$d42c
attenuatedDisplacementValue	equ	gameData+$d42d
cameraGridOffsetXHigh		equ	gameData+$d42e
cameraGridOffsetZHigh		equ	gameData+$d432
lbW00D434			equ	gameData+$d434
lbW00D436			equ	gameData+$d436
trackRenderingEnableFlag	equ	gameData+$d438
opponentSpeedFractional		equ	gameData+$d43c
fuelConsumptionTimer		equ	gameData+$d43d
drawBridgeActive		equ	gameData+$d43f
trackDirection			equ	gameData+$d440
restartTimerCountdown		equ	gameData+$d441
framesToProcess			equ	gameData+$d442
distanceCharacteristic		equ	gameData+$d443
aiEnabled			equ	gameData+$d444
boundaryCollisionDirectionFlag	equ	gameData+$d445
collisionActiveFlag		equ	gameData+$d446
inputStateFlags			equ	gameData+$d447
segmentRepeatCounter		equ	gameData+$d448
collisionDistanceTemp		equ	gameData+$d44a
segmentSteeringFlags		equ	gameData+$d44d
accumulatedForceFrontLeft	equ	gameData+$d44f
accumulatedForceFrontRight	equ	gameData+$d450
accumulatedForceRear		equ	gameData+$d451
damageAccumulationActive	equ	gameData+$d454
accumulatedCarDamage		equ	gameData+$d455
highCompressionFrameCount	equ	gameData+$d456
cameraAngleIndex		equ	gameData+$d457
segmentDepthCounter		equ	gameData+$d458
trackSegmentLimitDoubled	equ	gameData+$d459
maxSegmentIndexDoubled		equ	gameData+$d45a
raceMode			equ	gameData+$d45b
lbB00D45C			equ	gameData+$d45c
trackDirectionMultiplier	equ	gameData+$d45d
displayRowOffset		equ	gameData+$d45e
displayTrackID			equ	gameData+$d45f
renderingLoopIndex		equ	gameData+$d460
segmentPropertyFlags		equ	gameData+$d461
boostActiveFlag			equ	gameData+$d462
gameExitFlag			equ	gameData+$d463
playerInputState		equ	gameData+$d464
wheelOutOfLateralBoundsFlag	equ	gameData+$d465
segmentRenderingFlag		equ	gameData+$d466
lbB00D467			equ	gameData+$d467
lbB00D468			equ	gameData+$d468
flameAnimationFrame		equ	gameData+$d469
trackModeParameter		equ	gameData+$d46a
leagueSessionMode		equ	gameData+$d46b
blinkCountdownTimer		equ	gameData+$d46c
textHorizontalOffset		equ	gameData+$d46d
textYOffset			equ	gameData+$d46e
frameBufferSyncMask		equ	gameData+$d46f
raceActiveFlag			equ	gameData+$d470
drawBridgeUpdateFlag		equ	gameData+$d471
frameProcessingFlag		equ	gameData+$d472
majorImpactCooldownTimer	equ	gameData+$d473
crashRecoveryTimer		equ	gameData+$d474
raceCompletionCheckFlag		equ	gameData+$d475
networkConnectionState		equ	gameData+$d476
lineDrawingModeFlag		equ	gameData+$d477
geometryFormatFlag		equ	gameData+$d479
segmentProcessingIndex		equ	gameData+$d47a
segmentOrientationPrimary	equ	gameData+$d47b
previousSegmentOffset		equ	gameData+$d47c
hardImpactCount			equ	gameData+$d47d
wheelMovementActive		equ	gameData+$d47e
lbB00D47F			equ	gameData+$d47f
currentSegmentIndex		equ	gameData+$d485
trackGeometryTypeIndex		equ	gameData+$d486
blinkFlag			equ	gameData+$d488
lapTimeSubsecondVisibility	equ	gameData+$d489
currentTrackCoordinate		equ	gameData+$d48b
unusedDisplayFlag2		equ	gameData+$d48c
maxMenuIndex			equ	gameData+$d48d
gameMessageActiveFlag		equ	gameData+$d48e
segmentConfigLoadedFlag		equ	gameData+$d48f
renderModeFlag			equ	gameData+$d490
trackOffsetBase			equ	gameData+$d491
diskOperationAborted		equ	gameData+$d492
gridSweepDirection		equ	gameData+$d493
lbB00D494			equ	gameData+$d494
maxBoostFuel			equ	gameData+$d495
trackSegmentLimit		equ	gameData+$d497
maxSegmentIndex			equ	gameData+$d498
maxLapsForRace			equ	gameData+$d499
renderingOrderMode		equ	gameData+$d49a
lastValidSegmentIndex		equ	gameData+$d49b
offTrackStateFlags		equ	gameData+$d49c
aiPatternControlFlags		equ	gameData+$d49d
prevSegmentDepthCounter		equ	gameData+$d49e
prevTrackProgressionOffset	equ	gameData+$d49f
playerLateralPosition		equ	gameData+$d4a1
segmentDataIndexScaled		equ	gameData+$d4a3
pauseState			equ	gameData+$d4a4
pauseKeyPressed			equ	gameData+$d4a5
lbB00D4A6			equ	gameData+$d4a6
opponentTargetLateralPosition	equ	gameData+$d4a7
accelerationStateFlag		equ	gameData+$d4a8
framesSinceCopperlistUpdate	equ	gameData+$d4a9
raceMatchupScreenTypeFlag	equ	gameData+$d4aa
lbB00D4AB			equ	gameData+$d4ab
frameCounter			equ	gameData+$d4ac
lbB00D4AD			equ	gameData+$d4ad
lbB00D4AE			equ	gameData+$d4ae
raceCompletionState		equ	gameData+$d4af
drawBridgeAnimationPhase	equ	gameData+$d4b0
displayFlags			equ	gameData+$d4b1
raceWinnerBits			equ	gameData+$d4b2
raceOutcomeFlags		equ	gameData+$d4b4
savedHoleRenderingPosition	equ	gameData+$d4b5
targetDamageLevel		equ	gameData+$d4b6
opponentAheadFlag		equ	gameData+$d4b8
disableWheelUpdateFlag		equ	gameData+$d4b9
curveSmoothingFlag		equ	gameData+$d4ba
trackSideIndicatorCopy		equ	gameData+$d4bb
singleBufferRenderMode		equ	gameData+$d4bc
aiMovementOverride		equ	gameData+$d4bd
opponentSegmentOffset1		equ	gameData+$d4be
opponentSegmentOffset2		equ	gameData+$d4bf
aiActionTimer			equ	gameData+$d4c0
rollTransitionFlag		equ	gameData+$d4c1
aiPatternOffset			equ	gameData+$d4c2
opponentCollisionTimer		equ	gameData+$d4c3
raceStartComplete		equ	gameData+$d4c4
segmentDataStartIndex		equ	gameData+$d4c5
steeringInputDirection		equ	gameData+$d4c6
draftingTimer			equ	gameData+$d4c7
frameBufferToggle		equ	gameData+$d4c8
globalFrameCounter		equ	gameData+$d4c9
menuHighlightMode		equ	gameData+$d4ca
multiplayerRaceDisplayFlag	equ	gameData+$d4cb
lapTimeDisplayDuration		equ	gameData+$d4cc
frameThrottleFlag		equ	gameData+$d4cd
frameThrottleAccumulator	equ	gameData+$d4cf
lbB00D4D0			equ	gameData+$d4d0
offRoadSideFlags		equ	gameData+$d4d1
lbB00D4D2			equ	gameData+$d4d2
textTransparencyMode		equ	gameData+$d4d3
segmentBaseSteeringOffset	equ	gameData+$d4d4
currentPlayerNameOffset		equ	gameData+$d4d5
gridLookupX			equ	gameData+$d4d5
selectedMenuItem		equ	gameData+$d4d6
gridLookupY			equ	gameData+$d4d6
collisionImpactLevel		equ	gameData+$d4d7
segmentOrientationAlternate	equ	gameData+$d4d9
wheelBouncePhaseAccumulator	equ	gameData+$d4da
wheelRotationFrame		equ	gameData+$d4db
segmentAlternateFlag		equ	gameData+$d4dc
wheelBaseHeight			equ	gameData+$d4dd
unusedDisplayFlag1		equ	gameData+$d4de
raceStartTimer			equ	gameData+$d4df
multiplayerSyncFlag		equ	gameData+$d4e0
trackSideIndicator		equ	gameData+$d4e1
gameModeStateFlags		equ	gameData+$d4e2
wheelAnimationAccumulator	equ	gameData+$d4e3
tempByte5			equ	gameData+$d4e4
segmentHalfFlags		equ	gameData+$d4e6
renderingIndex			equ	gameData+$d4e8
chainLiftVelocity		equ	gameData+$d4e9
chainVerticalPosition		equ	gameData+$d4ea
opponentCollisionActive		equ	gameData+$d4eb
opponentDistanceOffset		equ	gameData+$d4ec
opponentLateralPosition		equ	gameData+$d4ed
aiCurrentSpeed			equ	gameData+$d4ee
lbB00D4EF			equ	gameData+$d4ef
aiTargetSpeed			equ	gameData+$d4f0
aiTargetSpeedHigh		equ	gameData+$d4f1
trackHeightDifference		equ	gameData+$d4f2
enginePitchDelta		equ	gameData+$d4f4
enginePitchDeltaLow		equ	gameData+$d4f5
tempWord1			equ	gameData+$d4f6
playerOpponentLateralDistance	equ	gameData+$d4f7
raceSetupFlags			equ	gameData+$d4f7
tempWord2			equ	gameData+$d4f8
wheelDataOffset			equ	gameData+$d4f9
cameraHeightBaseline		equ	gameData+$d4fa
raceStartRoll			equ	gameData+$d500
raceStartRollLow		equ	gameData+$d501
splineControlPoint1		equ	gameData+$d502
splineControlPoint2		equ	gameData+$d504
splineControlPoint3		equ	gameData+$d506
splineControlPoint4		equ	gameData+$d508
additionalInterpolationPoints1	equ	gameData+$d50a
additionalInterpolationPoints2	equ	gameData+$d50c
segmentBezierOffset1		equ	gameData+$d50e
segmentBezierOffset2		equ	gameData+$d510
opponentSegmentQueueOffset	equ	gameData+$d512
processedSegmentIndices1	equ	gameData+$d514
processedSegmentIndices2	equ	gameData+$d516
speedBarLength			equ	gameData+$d518
lbW00D51C			equ	gameData+$d51c
minimumRenderQueueOffset	equ	gameData+$d51e
previousSpeedBarLength		equ	gameData+$d520
lateralPositionOutOfBounds	equ	gameData+$d522
lbB00D524			equ	gameData+$d524
visibilityAccumulator		equ	gameData+$d526
prevVisibilityAccumulator	equ	gameData+$d528
segmentProgressDistance		equ	gameData+$d52a
segmentProgressDistanceLow	equ	gameData+$d52b
cameraYawPerspectiveOffset	equ	gameData+$d52e
cameraRotationFlags		equ	gameData+$d530
reverseDirectionFlag		equ	gameData+$d532
enginePitchAccumulator		equ	gameData+$d534
perspectiveDepthDivisor		equ	gameData+$d536
opponentDistance		equ	gameData+$d538
opponentDistanceLow		equ	gameData+$d539
maxCompressionVelocity		equ	gameData+$d53a
steeringScaleFactor		equ	gameData+$d53c
playerDistanceDifference	equ	gameData+$d53e
forwardPositionIntermediate	equ	gameData+$d540
segmentBlendParam		equ	gameData+$d541
viewportCenterY			equ	gameData+$d542
trackDirectionInversionFlag	equ	gameData+$d544
segmentSlopeFlags		equ	gameData+$d54a
adjustedDistanceValue		equ	gameData+$d54c
lateralTrackPosition		equ	gameData+$d54d
lbB00D554			equ	gameData+$d554
previousSegmentProperties	equ	gameData+$d555
horizonFillStartY		equ	gameData+$d556
maxRenderingIndex		equ	gameData+$d557
polygonFillStartY		equ	gameData+$d558
trackBaseOffset			equ	gameData+$d559
offsetFromRoadCenter		equ	gameData+$d55a
lateralRoadPosition		equ	gameData+$d55c
speedMinor			equ	gameData+$d55d
trackSurfaceHeight		equ	gameData+$d55e
wheelSpeed			equ	gameData+$d560
viewOffsetX			equ	gameData+$d562
viewStepX			equ	gameData+$d564
viewOffsetY			equ	gameData+$d566
viewStepY			equ	gameData+$d568
quadRectHalfWidth		equ	gameData+$d56a
quadRectWidth			equ	gameData+$d56c
quadRectHalfHeight		equ	gameData+$d56e
quadRectHeight			equ	gameData+$d570
stepSizeXHalf			equ	gameData+$d572
stepSizeYHalf			equ	gameData+$d574
lbW00D578			equ	gameData+$d578
lbW00D57A			equ	gameData+$d57a
stepSizeXQuarter		equ	gameData+$d57c
stepSizeYQuarter		equ	gameData+$d57e
lbW00D580			equ	gameData+$d580
lbW00D582			equ	gameData+$d582
quadTranslateX			equ	gameData+$d584
quadTranslateY			equ	gameData+$d586
adjustedViewX			equ	gameData+$d588
adjustedViewY			equ	gameData+$d58a
primaryGeometryOffset		equ	gameData+$d58c
alternateGeometryOffset		equ	gameData+$d590
trackSurfaceFrontLeft		equ	gameData+$d594
trackSurfaceFrontRight		equ	gameData+$d598
trackSurfaceRear		equ	gameData+$d59c
trackOffsetAdjustment		equ	gameData+$d5a0
postWreckStateFlag		equ	gameData+$d5a2
wheelHeightFrontLeft		equ	gameData+$d5a4
wheelHeightFrontRight		equ	gameData+$d5a8
wheelHeightRear			equ	gameData+$d5ac
suspensionTravelFrontLeft	equ	gameData+$d5b0
suspensionTravelFrontRight	equ	gameData+$d5b4
suspensionTravelRear		equ	gameData+$d5b8
geometryDatabaseOffset		equ	gameData+$d5bc
rawTrackDataOffset		equ	gameData+$d5c0
obfuscationBufferPointer	equ	rawTrackDataOffset
lbB00D5C8			equ	gameData+$d5c8
rotatedCameraX			equ	gameData+$d5cc
carHeightPosition		equ	gameData+$d5d0
rotatedCameraZ			equ	gameData+$d5d4
cameraWorldX			equ	gameData+$d5d8
lbW00D5DA			equ	gameData+$d5da
cameraWorldY			equ	gameData+$d5dc
lbB00D5DD			equ	gameData+$d5dd
lbW00D5DE			equ	gameData+$d5de
cameraWorldZ			equ	gameData+$d5e0
lbW00D5E2			equ	gameData+$d5e2
cameraAngleX			equ	gameData+$d5e4
cameraAngleY			equ	gameData+$d5e6
cameraAngleYLow			equ	gameData+$d5e7
cameraAngleZ			equ	gameData+$d5e8
worldXSpeed			equ	gameData+$d5ea
worldYSpeed			equ	gameData+$d5ec
worldZSpeed			equ	gameData+$d5ee
rotationSpeedX			equ	gameData+$d5f0
rotationSpeedY			equ	gameData+$d5f2
rotationSpeedZ			equ	gameData+$d5f4
worldAccelerationX		equ	gameData+$d5f6
worldAccelerationY		equ	gameData+$d5f8
worldAccelerationZ		equ	gameData+$d5fa
angularAccelerationX		equ	gameData+$d5fc
angularAccelerationY		equ	gameData+$d5fe
angularAccelerationZ		equ	gameData+$d600
wheelCornerXFrontLeft		equ	gameData+$d602
wheelCornerXFrontRight		equ	gameData+$d604
wheelCornerXRearCenter		equ	gameData+$d606
wheelCornerYFrontLeft		equ	gameData+$d608
wheelCornerYFrontRight		equ	gameData+$d60a
wheelCornerYRearCenter		equ	gameData+$d60c
baseTargetRoll			equ	gameData+$d60e
baseRollAngle			equ	gameData+$d610
additionalYawOffset		equ	gameData+$d612
clampedSuspensionFrontLeft	equ	gameData+$d614
clampedSuspensionFrontRight	equ	gameData+$d616
clampedSuspensionRear		equ	gameData+$d618
previousSuspensionFrontLeft	equ	gameData+$d61a
previousSuspensionFrontRight	equ	gameData+$d61c
previousSuspensionRear		equ	gameData+$d61e
suspensionVelocityFrontLeft	equ	gameData+$d620
suspensionVelocityFrontRight	equ	gameData+$d622
suspensionVelocityRear		equ	gameData+$d624
targetPitchRate			equ	gameData+$d626
targetRollRate			equ	gameData+$d628
gasOutputAccumulatorValue	equ	gameData+$d62a
gasOutputIntensityValue		equ	gameData+$d62b
carLocalVelocityX		equ	gameData+$d62c
carLocalVelocityY		equ	gameData+$d62e
carLocalVelocityZ		equ	gameData+$d630
adjustedRollAngle		equ	gameData+$d632
adjustedPitchAngle		equ	gameData+$d634
adjustedYawAngle		equ	gameData+$d636
averageWheelVelocity		equ	gameData+$d638
averageWheelVelocityLow		equ	gameData+$d639
transformedAngularVelocityX	equ	gameData+$d63a
transformedAngularVelocityY	equ	gameData+$d63c
transformedAngularVelocityZ	equ	gameData+$d63e
rollSpringAngle			equ	gameData+$d640
pitchSpringAngle		equ	gameData+$d642
yawSpringAngle			equ	gameData+$d644
lbW00D646			equ	gameData+$d646
rollDisplacement		equ	gameData+$d648
pitchReferenceZero		equ	gameData+$d64a
pitchDisplacement		equ	gameData+$d64c
rollSpringComponent		equ	gameData+$d64e
pitchSpringComponent		equ	gameData+$d650
yawSpringComponent		equ	gameData+$d652
lateralOpponentCollisionForce	equ	gameData+$d654
verticalOpponentCollisionForce	equ	gameData+$d656
forwardOpponentCollisionForce	equ	gameData+$d658
segmentTargetAngle		equ	gameData+$d65a
carSpeedMagnitude		equ	gameData+$d65c
opponentFrontWheelAccel		equ	gameData+$d65e
opponentWheelAccelerationRL	equ	gameData+$d660
opponentWheelAccelerationRR	equ	gameData+$d662
opponentWheelPositions		equ	gameData+$d666
opponentRearLeftWheelPosition	equ	gameData+$d668
opponentRearRightWheelPosition	equ	gameData+$d66a
opponentFrontWheelHeightPrev	equ	gameData+$d66e
opponentWheelHeightRL		equ	gameData+$d670
opponentWheelHeightRR		equ	gameData+$d672
opponentWheelVelocities		equ	gameData+$d676
opponentRearLeftWheelVelocity	equ	gameData+$d678
opponentRearRightWheelVelocity	equ	gameData+$d67a
opponentWheelForceTotal		equ	gameData+$d67e
opponentWheelForceRL		equ	gameData+$d680
opponentWheelForceRR		equ	gameData+$d682
boundsMinX			equ	gameData+$d686
boundsMaxX			equ	gameData+$d688
boundsMinY			equ	gameData+$d68a
trackCoordinatesX		equ	gameData+$d68e
trackCoordinatesY		equ	gameData+$d6ae
segmentProcessedFlags		equ	gameData+$d6d0
lbL00D76C			equ	gameData+$d76c
trackSegmentData		equ	gameData+$d770
inputCoordX1			equ	gameData+$d864
inputCoordY1			equ	gameData+$d866
inputCoordX2			equ	gameData+$d868
inputCoordY2			equ	gameData+$d86a
clampedCoordX1			equ	gameData+$d888
clampedCoordY1			equ	gameData+$d88a
clampedCoordX2			equ	gameData+$d88c
clampedCoordY2			equ	gameData+$d88e
coordinateLookupTable		equ	gameData+$d8b0
lbW00D8B4			equ	gameData+$d8b4
lbW00D8B6			equ	gameData+$d8b6
transformedCoordinates1		equ	gameData+$d9a0
transformedCoordinates2		equ	gameData+$d9a2
quadVertexX4			equ	gameData+$d9b0
quadVertexX5			equ	gameData+$d9b2
quadVertexX6			equ	gameData+$d9b4
quadVertexX7			equ	gameData+$d9b6
lbW00D9B8			equ	gameData+$d9b8
lbW00D9BA			equ	gameData+$d9ba
lbW00D9BC			equ	gameData+$d9bc
lbW00D9BE			equ	gameData+$d9be
quadVertexX0			equ	gameData+$d9c0
quadVertexX1			equ	gameData+$d9c2
quadVertexX2			equ	gameData+$d9c4
quadVertexX3			equ	gameData+$d9c6
lbW00D9C8			equ	gameData+$d9c8
lbW00D9CA			equ	gameData+$d9ca
lbW00D9CC			equ	gameData+$d9cc
lbW00D9CE			equ	gameData+$d9ce
transformedVertexBounds		equ	gameData+$d9f0
lbW00D9F4			equ	gameData+$d9f4
lbW00D9F6			equ	gameData+$d9f6
quadVertexY4			equ	gameData+$daf0
quadVertexY5			equ	gameData+$daf2
quadVertexY6			equ	gameData+$daf4
quadVertexY7			equ	gameData+$daf6
lbW00DAF8			equ	gameData+$daf8
lbW00DAFA			equ	gameData+$dafa
lbW00DAFC			equ	gameData+$dafc
lbW00DAFE			equ	gameData+$dafe
quadVertexY0			equ	gameData+$db00
quadVertexY1			equ	gameData+$db02
quadVertexY2			equ	gameData+$db04
quadVertexY3			equ	gameData+$db06
lbW00DB08			equ	gameData+$db08
lbW00DB0A			equ	gameData+$db0a
lbW00DB0C			equ	gameData+$db0c
lbW00DB0E			equ	gameData+$db0e
lbL00DB30			equ	gameData+$db30
transformMatrix34		equ	gameData+$db64
transformMatrix38		equ	gameData+$db68
transformMatrix3E		equ	gameData+$db6e
transformMatrix44		equ	gameData+$db72
transformMatrix46		equ	gameData+$db74
transformMatrix48		equ	gameData+$db76
trackSegmentGrid		equ	gameData+$db80
debrisParticleXPositions	equ	gameData+$dc80
debrisParticleYPositions	equ	gameData+$dcc0
debrisParticleXVelocities	equ	gameData+$dd00
debrisParticleYVelocities	equ	gameData+$dd40
segmentGeometryIndices		equ	gameData+$ddc0
segmentAlternateGeometryIndices	equ	gameData+$de24
trackSegmentCoordinates		equ	gameData+$de88
trackSegmentPropertiesTable	equ	gameData+$deec
segmentInterpolationPoint1	equ	gameData+$df50
raceRecordDisplayBuffer		equ	gameData+$df6c
drawBridgeSegmentBase1		equ	gameData+$dfb6
drawBridgeSegmentBase2		equ	gameData+$dfb8
segmentInterpolationPoint2	equ	gameData+$e018
segmentWorldPositions		equ	gameData+$e0e0
obstacleSegmentIndices		equ	gameData+$e1a8
obstacleTypes			equ	gameData+$e1c8
trackFeatureData		equ	gameData+$e1e8
playerStatsArray		equ	gameData+$e208
lbB00E209			equ	gameData+$e209
lbB00E216			equ	gameData+$e216
lbB00E217			equ	gameData+$e217
lapTimeSeconds			equ	gameData+$e220
lbB00E221			equ	gameData+$e221
lbB00E22E			equ	gameData+$e22e
lbB00E22F			equ	gameData+$e22f
lapTimeSubseconds		equ	gameData+$e238
lbB00E239			equ	gameData+$e239
lbB00E246			equ	gameData+$e246
lbB00E247			equ	gameData+$e247
segmentVisibilityData		equ	gameData+$e252
drawBridgeHeightValues		equ	gameData+$e282
lbL00E2B6			equ	gameData+$e2b6
leagueStandingsTable		equ	gameData+$e2c2
currentDivision			equ	gameData+$e2ce
holeRenderingPosition		equ	gameData+$e2cf
currentPlayerContext		equ	gameData+$e2d0
aiSkillLevelTable		equ	gameData+$e2d2
playerRaceWins			equ	gameData+$e2de
playerSecondPlaceFinishes	equ	gameData+$e2ea
raceParticipationCounters	equ	gameData+$e2f6
playerRankingScores		equ	gameData+$e302
sortedRaceStandings		equ	gameData+$e30e
trackDataBuffer			equ	gameData+$e319
numTrackSegments		equ	gameData+$e31a
playerSpawnSegment		equ	gameData+$e31b
lapApproachSegment		equ	gameData+$e31c
finishLineSegmentIndex		equ	gameData+$e31d
startWorldPosition		equ	gameData+$e31e
boostFuelLevel			equ	gameData+$e320
selectedTrackInDivision		equ	gameData+$e322
bestLapRecordHolder		equ	gameData+$e323
bestRaceRecordHolder		equ	gameData+$e324
lbB00E325			equ	gameData+$e325
lbB00E326			equ	gameData+$e326
player1ID			equ	gameData+$e327
player2ID			equ	gameData+$e328
opponentID			equ	gameData+$e329
trackMetadataBuffer		equ	gameData+$e32a
trackDamageFrameBase		equ	gameData+$e32b
trackBoostFuelPlayer1		equ	gameData+$e32c
trackBoostFuelPlayer2		equ	gameData+$e32d
obstacleCount			equ	gameData+$e32e
trackFeatureCount		equ	gameData+$e32f
writeMode			equ	gameData+$e331
lapLineSegment			equ	gameData+$e332
currentTrackID			equ	gameData+$e333
bufferEncodedFlag		equ	gameData+$e334
currentRaceNumber		equ	gameData+$e335
playerHolePositions		equ	gameData+$e336
ciaTimerFlag			equ	gameData+$48aa8
lbW049538			equ	gameData+$49538
networkPacketReadyFlag		equ	gameData+$4953a
networkGameMode			equ	gameData+$4953c
steeringInputDirectionBackup	equ	gameData+$4953d
checksumAccumulator		equ	gameData+$4953e
networkDataCounter1		equ	gameData+$49540
savedNetworkCounter		equ	gameData+$49542
networkDataCounter2		equ	gameData+$49544
lbW049546			equ	gameData+$49546
lbW049548			equ	gameData+$49548
lbW04954A			equ	gameData+$4954a
lbW04954C			equ	gameData+$4954c
lbW04954E			equ	gameData+$4954e
lbB049550			equ	gameData+$49550
lbB049551			equ	gameData+$49551
lbB049552			equ	gameData+$49552
lbB049553			equ	gameData+$49553
lbB049554			equ	gameData+$49554
lbB049555			equ	gameData+$49555
lbB049556			equ	gameData+$49556
lbB049557			equ	gameData+$49557
lbB049558			equ	gameData+$49558
lbB049559			equ	gameData+$49559
lbB04955A			equ	gameData+$4955a
networkInputSyncEnabled		equ	gameData+$4955b
receivedGameStateID		equ	gameData+$4955c
receivedGameInitFlag		equ	gameData+$4955d
receivedPlayerCommand		equ	gameData+$4955e
receivedPlayerState		equ	gameData+$4955f
receivedInputState		equ	gameData+$49560
lbB049561			equ	gameData+$49561
gameStateID			equ	gameData+$49562
networkInitPhase		equ	gameData+$49563
networkProtocolState		equ	gameData+$49564
localPlayerStateCache		equ	gameData+$49565
localInputStateCache		equ	gameData+$49566
raceSeriesCounter		equ	gameData+$49567
localPlayerReadyFlag		equ	gameData+$49568
opponentRelativePosition	equ	gameData+$49569
lbB04956A			equ	gameData+$4956a
lbB04956B			equ	gameData+$4956b
lbB04956C			equ	gameData+$4956c
lbB04956D			equ	gameData+$4956d
lbB04956E			equ	gameData+$4956e
receivedKey			equ	gameData+$4956f
lbW049570			equ	gameData+$49570
totalRaceCounter		equ	gameData+$49572
lbW049574			equ	gameData+$49574
lbW049576			equ	gameData+$49576
lbB0499D6			equ	gameData+$499d6
lbB0499D7			equ	gameData+$499d7
lbL04A4AE			equ	gameData+$4a4ae
lbB04A4BA			equ	gameData+$4a4ba
lbB04A4BB			equ	gameData+$4a4bb
lbB04A4C8			equ	gameData+$4a4c8
bitplaneMask1			equ	gameData+$4a4ca
bitplaneMask2			equ	gameData+$4a4ce
bitplaneMaskPointer		equ	gameData+$4a4d2
lbB04AA3E			equ	gameData+$4aa3e
useAlternateFontFlag		equ	gameData+$4ab4a
lbB04AB4B			equ	gameData+$4ab4b
playerNameRenderingPosition	equ	gameData+$4ab4c
foregroundColorMask1		equ	gameData+$4b12e
foregroundColorMask2		equ	gameData+$4b132
backgroundColorMask1		equ	gameData+$4b136
backgroundColorMask2		equ	gameData+$4b13a
textCursorColumn		equ	gameData+$4b13e
textCursorRow			equ	gameData+$4b13f
characterByteOffset		equ	gameData+$4b140
characterPixelOffset		equ	gameData+$4b141
savedTransparencyFlag		equ	gameData+$4b142
textControlCodeState		equ	gameData+$4b143
controlCodeByteCounter		equ	gameData+$4b144
engineAudioNoiseFlag		equ	gameData+$4cf46
maxInputLength			equ	gameData+$4d13c
directionalInputBits		equ	gameData+$4d13d
currentInputPosition		equ	gameData+$4d13e
displayUpdateFlag		equ	gameData+$4f024
buttonReleaseMask		equ	gameData+$4f2dA
bufferSelector			equ	gameData+$4f3be
lbB050474			equ	gameData+$50474
textRenderingFlag		equ	gameData+$50475
additionalPlayerCount		equ	gameData+$50476
remainingRaces			equ	gameData+$50477
standingsDisplayModeFlag	equ	gameData+$5047a
raceSeriesProgress		equ	gameData+$5047b
selectedDivision		equ	gameData+$5047c
divisionSelectedFlag		equ	gameData+$5047d
lbB0513DC			equ	gameData+$513dc
lbB0513DD			equ	gameData+$513dd
menuInitializedFlag		equ	gameData+$528bc
framesToWait			equ	gameData+$52fd8
framesToWaitWhenFading		equ	gameData+$52fda
creakingSoundCooldownTimer	equ	gameData+$52fdb
impactSoundCooldownTimer	equ	gameData+$539b6
grindSoundCooldownTimer		equ	gameData+$539b7
randomSeed1			equ	gameData+$53ea2
randomSeed2			equ	gameData+$53ea4
randomSeed2Low			equ	gameData+$53ea5
randomSeed3			equ	gameData+$53ea6
currentSaveSlotIndex		equ	gameData+$544b4
disableDirectionalInputFlag	equ	gameData+$544b5
selectedSaveSlotIndex		equ	gameData+$544b6
backupSaveSlotIndex		equ	gameData+$544b7
lbB0544BA			equ	gameData+$544ba
saveSlotHighlightFlag		equ	gameData+$544bb
lbB0544BC			equ	gameData+$544bc
lbB054608			equ	gameData+$54608
aiLookAheadDistance		equ	gameData+$555e0
aiCorneringSkill		equ	gameData+$555e1
damageFrameLimit		equ	gameData+$555e2
minBoundaryDistance		equ	gameData+$557de
collisionSoundCooldown		equ	gameData+$557e0
suppressMenuTextFlag		equ	gameData+$55e30
segmentRenderDepthTable		equ	gameData+$57770
transformedGridX		equ	gameData+$577C0
transformedGridY		equ	gameData+$577C2
lbB0579FA			equ	gameData+$579fa
lbW0579FC			equ	gameData+$579fc
lbW0579FE			equ	gameData+$579fe
segmentRenderFlags		equ	gameData+$57a00
segmentDataWritePointer		equ	gameData+$57a02
lbB057D75			equ	gameData+$57d75
lbB0581A0			equ	gameData+$581a0
lbW0581A2			equ	gameData+$581a2
lbW0581A4			equ	gameData+$581a4
lbW0581A6			equ	gameData+$581a6
lineDrawingBufferPointer	equ	gameData+$59a44
renderCommandQueueOffset	equ	gameData+$59a48
savedXCoordinate		equ	gameData+$59ad4
edgeDirectionFlag		equ	gameData+$59da6
clipRequiredFlag		equ	gameData+$59da7
clipIterationCounter		equ	gameData+$59da8
renderingFlag			equ	gameData+$59da9
farSegmentQueueOffset		equ	gameData+$5ac2c
mountainHorizontalAngles	equ	gameData+$5b036
mountainShapeIndices		equ	gameData+$5b066
lbB05B096			equ	gameData+$5b096
lbB05B097			equ	gameData+$5b097
lbB05B098			equ	gameData+$5b098
mountainSegmentCount		equ	gameData+$5b099
mountainScreenX			equ	gameData+$5b09a
mountainScreenY			equ	gameData+$5b09c
scanlineCounter			equ	gameData+$5b3ca
lbW05B3CC			equ	gameData+$5b3cc
lbW05B3CE			equ	gameData+$5b3ce
currentEdgePointer1		equ	gameData+$5b3d0
currentEdgePointer2		equ	gameData+$5b3d4
segmentAlternateRenderFlag	equ	gameData+$5b3d8
segmentProcessedFlag		equ	gameData+$5b3da
edgeClipFailedFlag		equ	gameData+$5b3dc
lbB05B3DE			equ	gameData+$5b3de
lbB05B3E2			equ	gameData+$5b3e2
currentSegmentQueueOffset	equ	gameData+$5b3e6
barrierSegmentQueueOffset	equ	gameData+$5b3e8
lbB05B3EA			equ	gameData+$5b3ea
lbB05B3EC			equ	gameData+$5b3ec
lbL05B3F0			equ	gameData+$5b3f0
lbL05B3F4			equ	gameData+$5b3f4
lbL05B3F8			equ	gameData+$5b3f8
edgeSortBuffer			equ	gameData+$5b484
renderDataBuffer		equ	gameData+$5b504
loadingHardwareSprite		equ	gameData+$5b840
spriteUpdatePendingFlag		equ	gameData+$5b841
lbW05BA66			equ	gameData+$5ba66
renderGraphicsCurrentX		equ	gameData+$5ba68
renderGraphicsCurrentY		equ	gameData+$5ba6a
graphicsPointerTable		equ	gameData+$5bdac
frameBuffers			equ	gameData+$5be84
displayFrameBuffer		equ	gameData+$5be88
renderFrameBuffer		equ	gameData+$5be8c
viewportTopAddress		equ	gameData+$5be90

	section Data,data

resultScreenPointerTable:
	dc.l	frameBuffer1
	dc.l	imageWon
	dc.l	imageLost
	dc.l	imageWreck
	dc.l	imagePromotion

mountainSilhouetteTable:
	dc.l	mountainShape0Data,mountainData00
	dc.l	mountainShape0Data,mountainData01
	dc.l	mountainShape0Data,mountainData02
	dc.l	mountainShape0Data,mountainData03
	dc.l	mountainShape0Data,mountainData04
	dc.l	mountainShape0Data,mountainData05
	dc.l	mountainShape0Data,mountainData06
	dc.l	mountainShape0Data,mountainData07
	dc.l	mountainShape0Data,mountainData08
	dc.l	mountainShape0Data,mountainData09
	dc.l	mountainShape0Data,mountainData0a
	dc.l	mountainShape0Data,mountainData0b
	dc.l	mountainShape0Data,mountainData0c
	dc.l	mountainShape0Data,mountainData0d
	dc.l	mountainShape1Data,mountainData0c
	dc.l	mountainShape1Data,mountainData0d
	dc.l	mountainShape2Data,mountainData10
	dc.l	mountainShape2Data,mountainData11
	dc.l	mountainShape2Data,mountainData12
	dc.l	mountainShape2Data,mountainData13
	dc.l	mountainShape3Data,mountainData20
	dc.l	mountainShape3Data,mountainData21
	dc.l	mountainShape3Data,mountainData22
	dc.l	mountainShape3Data,mountainData23
	dc.l	mountainShape4Data,mountainData00
trackMountainDataTable:
	dc.l	trackMountainCountsAnglesAndIndices,trackMountainCountsAnglesAndIndices

name_graphics:	dc.b	"graphics.library",0

	ifeq	WHDLOAD
version:	dc.b	"$VER: Stunt Car Racer Unleashed 1.0 (09.05.2026)",0
	endif

	section	ChipData,data_c
copperlistStart:
	dc.w	$0801,$fffe
copperlist:
	dc.w	bpl1pth,$0007,bpl1ptl,$8000,bpl2pth,$0007,bpl2ptl,$A000,bpl3pth
	dc.w	$0007,bpl3ptl,$C000,bpl4pth,$0007,bpl4ptl,$E000,color00
copperlistColor0:
	dc.w	$0000,color01,$0000,color02,$0000,color03,$0000,color04,$0000
	dc.w	color05,$0000,color06,$0000,color07,$0000,color08,$0000,color09
	dc.w	$0000,color10,$0000,color11,$0000,color12,$0000,color13,$0000
	dc.w	color14,$0000,color15,$0000,color16
copperlistColor16:
	dc.w	$0000,color17,$0000,color18,$0000,color19,$0000,color20,$0000
	dc.w	color21,$0000,color22,$0000,color23,$0000,color24,$0000,color25
	dc.w	$0000,color26,$0000,color27,$0000,color28,$0000,color29,$0000
	dc.w	color30,$0000,color31,$0000,spr0pth
copperlistSprite0:
	dc.w	$0000,spr0ptl,$0000,spr1pth,$0000,spr1ptl,$0000,spr2pth,$0000
	dc.w	spr2ptl,$0000,spr3pth,$0000,spr3ptl,$0000,spr4pth,$0000,spr4ptl
	dc.w	$0000,spr5pth,$0000,spr5ptl,$0000,spr6pth,$0000,spr6ptl,$0000
	dc.w	spr7pth,$0000,spr7ptl,$0000,$FFFF	; originally $FA01,$FF00,intreq,$8010,
	dc.w	$FFFE

	section BSS,bss
plotPixelOffset:
	ds.w	1
fastRenderBuffer:
	ds.l	40*200
bitmapGraphicsBuffer:	ds.b	$7aa8
leagueSeasonData:	ds.b	$1b
randomSeedBuffer1:	ds.b	5
randomSeedBuffer2:	ds.b	5
obfuscatedLeagueBuffer:	ds.b	$1db
saveSlotNameBuffer:	ds.b	10		; this must be a contiguous block at least up to multiplayerObfuscationTable
savedSlotIndex:	ds.b	1
saveSlotFlags:	ds.b	$f
saveDataValidationBuffer:	ds.b	$1e2
saveDataChecksumValue:	ds.l	1
transferBuffer:	ds.b	$20			; load/save slots get loaded here (512 bytes)
tempMessageBuffer1:	ds.b	$80
tempMessageBuffer2:	ds.b	$3c
tempPlayerCountBackup:	ds.b	4
tempMessageBuffer3:	ds.b	$20
remoteRaceRecordBuffer:	ds.b	$100
lapRecordTable:	ds.b	$100
raceRecordTable:	ds.b	$100
multiplayerObfuscationTable:	ds.b	$100
playerNamesBuffer:	ds.b	$e0
opponentTraitsBuffer:	ds.b	$20
segmentDataPointers:	ds.l	$33
drawBridgeSegmentPointer:	ds.l	$1d
segmentRenderBuffer:	ds.b	$80
segmentGeometryData:	ds.b	$4b0
renderCommandQueue:	ds.b	$670
endOfBuffers:

sp_quit:	ds.l	1
base_vector:	ds.l	1
base_graphics:	ds.l	1
gb_copinit_old:	ds.l	1
gb_ActiView_old:	ds.l	1
tv_Lev1IntVect_old:	ds.l	1
tv_Lev2IntVect_old:	ds.l	1
tv_Lev3IntVect_old:	ds.l	1
tv_Lev4IntVect_old:	ds.l	1
tv_Lev5IntVect_old:	ds.l	1
tv_Lev6IntVect_old:	ds.l	1
tv_Lev7IntVect_old:	ds.l	1
dmaconr_old:	ds.w	1
intenar_old:	ds.w	1
ciaacra_old:	ds.b	1
ciaacrb_old:	ds.b	1
ciabcra_old:	ds.b	1
ciabcrb_old:	ds.b	1
quit:			ds.b	1

	section	ChipBSS,bss_c
sampleData:		ds.b	43310
sampleEngineData:	ds.b	3172
downsampledEngineData:	ds.b	3200
emptySprite:	ds.l	1
spriteBuffer:	ds.b	$360
lineDrawingBuffer:	ds.b	$2710
lineDrawingBufferEnd:
frameBuffer1:   ds.b    40*200*4
frameBuffer2:   ds.b    40*200*4

_ciaa		equ	$00BFE001
_ciab		equ	$00BFD000
_custom		equ	$00DFF000
ac_len		equ	$00000004
ac_per		equ	$00000006
adkcon		equ	$0000009E
aud0		equ	$000000A0
beamcon0	equ	$1dc
bltafwm		equ	$00000044
bltamod		equ	$00000064
bltbmod		equ	$00000062
bltcdat		equ	$00000070
bltdmod		equ	$00000066
bpl1mod		equ	$00000108
bpl1pth		equ	$0e0
bpl1ptl		equ	$0e2
bpl2mod		equ	$0000010A
bpl2pth		equ	$0e4
bpl2ptl		equ	$0e6
bpl3pth		equ	$0e8
bpl3ptl		equ	$0ea
bpl4pth		equ	$0ec
bpl4ptl		equ	$0ee
bplcon0		equ	$00000100
bplcon1		equ	$00000102
bplcon2		equ	$00000104
ciacra		equ	$00000E00
ciacrb		equ	$00000F00
ciaddra		equ	$00000200
ciaicr		equ	$00000D00
ciapra		equ	$00000000
ciaprb		equ	$00000100
ciasdr		equ	$00000C00
ciatbhi		equ	$00000700
ciatblo		equ	$00000600
color00 	equ	$180
color01 	equ	$182
color02 	equ	$184
color03 	equ	$186
color04 	equ	$188
color05 	equ	$18a
color06 	equ	$18c
color07 	equ	$18e
color08 	equ	$190
color09 	equ	$192
color10		equ	$194
color11		equ	$196
color12		equ	$198
color13		equ	$19a
color14		equ	$19c
color15		equ	$19e
color16		equ	$1a0
color17		equ	$1a2
color18		equ	$1a4
color19		equ	$1a6
color20		equ	$1a8
color21		equ	$1aa
color22		equ	$1ac
color23		equ	$1ae
color24		equ	$1b0
color25		equ	$1b2
color26		equ	$1b4
color27		equ	$1b6
color28		equ	$1b8
color29		equ	$1ba
color30		equ	$1bc
color31		equ	$1be
cop1lc		equ	$00000080
cop1lch		equ	$080
copjmp1		equ	$00000088
ddfstop		equ	$00000094
ddfstrt		equ	$00000092
diwstop		equ	$00000090
diwstrt		equ	$0000008E
dmacon		equ	$00000096
dmaconr		equ	$00000002
dsklen		equ	$00000024
dsksync		equ	$0000007E
intena		equ	$0000009A
intenar		equ	$01c 
intreq		equ	$0000009C
intreqr		equ	$0000001E
joy1dat		equ	$0000000C
serdat		equ	$00000030
serdatr		equ	$00000018
serper		equ	$00000032
spr0pth		equ	$120
spr0ptl		equ	$122
spr1pth		equ	$124
spr1ptl		equ	$126
spr2pth		equ	$128
spr2ptl		equ	$12a
spr3pth		equ	$12c
spr3ptl		equ	$12e
spr4pth		equ	$130
spr4ptl		equ	$132
spr5pth		equ	$134
spr5ptl		equ	$136
spr6pth		equ	$138
spr6ptl		equ	$13a
spr7pth		equ	$13c
spr7ptl		equ	$13e

CIACRAF_RUNMODE	equ	$00000008
CIACRBF_RUNMODE	equ	$00000008
CIAF_COMCD	equ	$00000020
CIAF_COMCTS	equ	$00000010
CIAF_COMDSR	equ	$00000008
CIAF_COMDTR	equ	$00000080
CIAF_DSKSEL0	equ	$00000008
CIAF_PRTRBUSY	equ	$00000001
CIAF_PRTRPOUT	equ	$00000002
CIAF_PRTRSEL	equ	$00000004
CIAICRB_TB	equ	$00000001
CIAICRF_ALRM	equ	$00000004
CIAICRF_FLG	equ	$00000010
CIAICRF_SETCLR	equ	$00000080
CIAICRF_SP	equ	$00000008
CIAICRF_TA	equ	$00000001
CIAICRF_TB	equ	$00000002
DMAB_BLITTER	equ	$00000006
DMAF_ALL	equ	$01FF
DMAF_AUD0	equ	$00000001
DMAF_AUD1	equ	$00000002
DMAF_AUD2	equ	$00000004
DMAF_AUD3	equ	$00000008
DMAF_AUDIO	equ	$0000000F
DMAF_BLITHOG	equ	$00000400
DMAF_BLITTER	equ	$00000040
DMAF_BLTDONE	equ	$00004000
DMAF_BLTNZERO	equ	$00002000
DMAF_COPPER	equ	$00000080
DMAF_DISK	equ	$00000010
DMAF_MASTER	equ	$00000200
DMAF_RASTER	equ	$00000100
DMAF_SETCLR	equ	$00008000
INTB_AUD0	equ	$00000007
INTB_COPER	equ	$00000004
INTB_DSKBLK	equ	$00000001
INTB_SETCLR	equ	$0000000F
INTB_TBE	equ	$00000000
INTB_VERTB	equ	$00000005
INTF_AUD0	equ	$00000080
INTF_AUD1	equ	$00000100
INTF_AUD2	equ	$00000200
INTF_AUD3	equ	$00000400
INTF_BLIT	equ	$00000040
INTF_COPER	equ	$00000010
INTF_DSKBLK	equ	$00000002
INTF_DSKSYNC	equ	$00001000
INTF_EXTER	equ	$00002000
INTF_INTEN	equ	$00004000
INTF_PORTS	equ	$00000008
INTF_RBF	equ	$00000800
INTF_SETCLR	equ	$00008000
INTF_SOFTINT	equ	$00000004
INTF_TBE	equ	$00000001
INTF_VERTB	equ	$00000020

_LVOOpenLibrary		equ	-$228
_LVOCloseLibrary	equ	-$19e
_LVOForbid		equ	-$84
_LVOPermit		equ	-$8a
_LVOSuperVisor		equ	-$1e
_LVOCacheControl	equ	-$288
_LVOLoadView		equ	-$de
_LVOWaitTOF		equ	-$10e
AttnFlags		equ	$128
CACR_EnableI		equ	$00000001
CACR_FreezeI		equ	$00000002
CACR_ClearI		equ	$00000008
CACR_IBE		equ	$00000010
CACR_EnableD		equ	$00000100
CACR_FreezeD		equ	$00000200
CACR_ClearD		equ	$00000800
CACR_DBE		equ	$00001000
CACR_WriteAllocate	equ	$00002000
CACR_EnableE		equ	$40000000
CACR_CopyBack		equ	$80000000
gb_ActiView		equ	34
gb_copinit		equ	38
tv_Lev1IntVect	equ	$00000064
tv_Lev2IntVect	equ	$00000068
tv_Lev3IntVect	equ	$0000006C
tv_Lev4IntVect	equ	$00000070
tv_Lev5IntVect	equ	$00000074
tv_Lev6IntVect	equ	$00000078
tv_Lev7IntVect	equ	$0000007C
tv_UserIntVects	equ	$00000100
