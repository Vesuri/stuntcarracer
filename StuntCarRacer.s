	incdir	"scr:"

	section	Code,code
startup:
;	moveq	#0,d2
;	jmp	debug
	move.l	sp,sp_quit
	move.b	#$80,skipSaveSlotScreen
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

	; Open libraries
	move.l	4.w,a6
	moveq	#0,d0
	lea	name_graphics,a1
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,base_graphics
	beq	startupFailure

	; Get Vector Base Register
	jsr	_LVOForbid(a6)
	move.w	AttnFlags(a6),d0
	beq	.no680x0
	lea	GetVBR(pc),a5
	jsr	_LVOSuperVisor(a6)

	; Enable caches
	move.l	#CACR_CopyBack|CACR_WriteAllocate|CACR_DBE|CACR_EnableD|CACR_IBE|CACR_EnableI,d0
	move.l	#CACR_CopyBack|CACR_EnableE|CACR_DBE|CACR_ClearD|CACR_EnableD|CACR_FreezeD|CACR_IBE|CACR_ClearI|CACR_FreezeI|CACR_EnableI,d1
	jsr	_LVOCacheControl(a6)
	move.l	d0,cachebits_old

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
	; Disable interrupts and DMA
	lea	_custom,a6
	move.w	#INTF_BLIT|INTF_VERTB,intreq(a6)
	move.w	#INTF_BLIT|INTF_VERTB,intreq(a6)
	move.w	#$ffff-INTF_SETCLR,intena(a6)
;	waitb
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
	move.w	AttnFlags(a6),d0
	beq.b	.no680x0
	move.l	cachebits_old,d0
	move.l	#CACR_CopyBack|CACR_EnableE|CACR_DBE|CACR_ClearD|CACR_EnableD|CACR_FreezeD|CACR_IBE|CACR_ClearI|CACR_FreezeI|CACR_EnableI,d1
	jsr	_LVOCacheControl(a6)
.no680x0:
	moveq	#0,d0
	rts

; Get VBR address
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

****************************************************************************
begin:	JSR	initialize
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
;	MOVE.L	#lbL05BE94,D0
        move.l  #frameBuffer1,d0
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
	MOVE.W	#$003C,lbW05B7C4
	MOVE.W	#$0038,_custom+ddfstrt
	MOVE.W	#$00D0,_custom+ddfstop
	MOVE.W	#$0000,_custom+bpl1mod
	MOVE.W	#$0000,_custom+bpl2mod
	MOVE.W	#$0000,_custom+bplcon1
	MOVE.W	#$0024,_custom+bplcon2
	MOVE.L	#copperlist,A0
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
	JSR	generateDownsampledSamples
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
	bsr	setQuitOnRMB
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
	CMP.B	#$F0,D0
	BCC	lbC00095E
	TST.B	D0
	BPL	lbC000958
	AND.B	#$7F,D0
	MOVE.B	#$00,$00(A0,D0.W)
	BRA	lbC00095E

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
	MOVEM.L	D0-D7/A0-A6,-(SP)
	CLR.W	D1
	CLR.W	D2
	JSR	verticalBlank
	BTST	#$05,_custom+serdatr
	BEQ	verticalBlankInterruptDone
	MOVE.B	serialWriteIndex,D0
	CMP.B	serialReadIndex,D0
	BEQ	verticalBlankInterruptDone
	JSR	serialTransmitEmptyInterrupt
verticalBlankInterruptDone:
	MOVEM.L	(SP)+,D0-D7/A0-A6
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

playAudioSample:
	MOVEM.L	D0/D3/D4/A0/A1,-(SP)
	AND.W	#$0007,D0		; Mask to 0-7 (8 samples)
	ASL.W	#$04,D0			; Multiply by 16 (entry size)
	LEA	sampleParameterTable,A0		; Load audio parameter table base
	LEA	$00(A0,D0.W),A0		; A0 = pointer to sample entry
	MOVE.W	$000C(A0),D0		; Load channel number (0-3) from offset +$0C
	ASL.W	#$02,D0			; Multiply by 4 (audioChannelMasks entry size)
	LEA	audioChannelMasks,A1	; Load channel masks table
	MOVE.W	$02(A1,D0.W),D3		; D3 = DMA enable bit (DMAF_AUD0/1/2/3)
	MOVE.W	D3,D4
	ASL.W	#$07,D4			; D4 = Interrupt enable bit (INTF_AUD0/1/2/3)
	MOVE.W	D4,_custom+intena	; Disable audio interrupt
	MOVE.W	D3,_custom+dmacon	; Disable audio DMA
	MOVE.W	#$0000,$00(A1,D0.W)	; Clear channel active flag
	ASL.W	#$02,D0			; Multiply by 4 again (D0 = channel * 16)
	LEA	_custom,A1		; A1 = $DFF000
	LEA	$00(A1,D0.W),A1		; A1 = $DFF000 + (channel * 16)
	MOVE.L	(A0),$00A0(A1)		; Set sample pointer (ac_ptr)
	MOVE.L	$0004(A0),D0		; Load sample length in bytes
	LSR.L	#$01,D0			; Divide by 2 (convert to words)
	MOVE.W	D0,$00A4(A1)		; Set sample length (ac_len)
	MOVE.W	$000A(A0),$00A8(A1)	; Set volume (ac_vol)
	MOVE.W	$0008(A0),$00A6(A1)	; Set period (ac_per)
	MOVE.W	D3,audioDMAEnableGuard		; Store pending interrupt flag
	BSET	#INTB_SETCLR,D3		; Set bit 15 (enable operation)
	MOVE.W	D4,_custom+intreq	; Clear pending interrupt
	BSET	#INTB_SETCLR,D4		; Set bit 15
	MOVE.W	D4,_custom+intena	; Enable audio interrupt
	MOVE.W	D3,_custom+dmacon	; Enable audio DMA (starts playback)
	CLR.W	audioDMAEnableGuard		; Clear pending flag
	MOVEM.L	(SP)+,D0/D3/D4/A0/A1
	RTS

disableAudio:
	MOVE.W	#(DMAF_AUD0|DMAF_AUD1|DMAF_AUD2|DMAF_AUD3|DMAF_AUDIO),_custom+dmacon
	MOVE.W	#(INTF_AUD0|INTF_AUD1|INTF_AUD2|INTF_AUD3),_custom+intena
	RTS

generateDownsampledSamples:
	MOVE.L	#$00000C64,D6
	MOVE.L	#downsampledEngineData,A1
	MOVE.L	#sampleEngineData,A2
	MOVE.L	#$00000006,D5
	MOVE.L	#sampleParameters,A5
	MOVE.L	#sampleEngineData,(A5)+
	LSR.L	#$01,D6
	MOVE.L	D6,(A5)+
	ASL.L	#$01,D6
generateDownsampledSamplesLoop:
	MOVE.L	A2,A0
	MOVE.L	A1,A2
	MOVE.L	A1,(A5)+
	LSR.W	#$01,D6
	MOVE.W	D6,D0
	SUBQ.W	#$01,D0
copySampleLoop:
	MOVE.B	(A0)+,(A1)+
	ADD.L	#$00000001,A0
	DBRA	D0,copySampleLoop
	MOVE.L	A1,D0
	BCLR	#$00,D0
	MOVE.L	D0,A1
	SUB.L	-$0004(A5),D0
	LSR.L	#$01,D0
	MOVE.L	D0,(A5)+
	DBRA	D5,generateDownsampledSamplesLoop
	MOVE.L	sampleParameters,baseSamplePointer
	MOVE.L	downsampledSampleTable,D0
	ASL.L	#$01,D0
	MOVE.L	D0,sampleSizeTable
	RTS

readJoystickState:
	jsr	testQuit
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
	MOVE.L	renderFrameBuffer,D3
	ADD.L	#$00000284,D3
	MOVE.L	D3,viewportTopAddress
	MOVE.L	displayFrameBuffer,bitplane1Pointer
	MOVE.B	#$80,copperlistUpdatePendingFlag
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
clearKeyboardStateLoop:
	MOVE.B	#$00,$00(A0,D1.W)
	SUBQ.B	#$01,D1
	BPL	clearKeyboardStateLoop
	MOVE.L	#memory_7A01A,A0
clearGameStateLoop:
	MOVE.B	#$00,(A0)+
	CMP.L	#memory_7B6FA,A0
	BLT	clearGameStateLoop
	JSR	initializeGraphicsData
	JMP	loadMenuDataToRAM

copyPalette:
	MOVE.L	#sourcePalette,A0
	MOVE.W	#$000F,D0
lbC00D37A:
	MOVE.W	(A1)+,(A0)+
	DBRA	D0,lbC00D37A
	RTS

copyPaletteToCopperlist:
	MOVE.L	#palette,A1
	MOVE.L	#copperlistColor0,A0
	MOVE.W	#$000F,D4
copyPaletteToCopperlistLoop:
	MOVE.W	(A1)+,D3
	ASL.W	#$01,D3
	MOVE.B	D3,D0
	AND.B	#$0F,D0
	BEQ	copyPaletteB
	OR.B	#$01,D3
copyPaletteB:
	MOVE.B	D3,D0
	AND.B	#$F0,D0
	BEQ	copyPaletteG
	OR.B	#$10,D3
copyPaletteG:
	MOVE.W	D3,D0
	AND.W	#$0F00,D0
	BEQ	copyPaletteR
	OR.W	#$0100,D3
copyPaletteR:
	MOVE.W	D3,(A0)+
	ADD.L	#$00000002,A0
	DBRA	D4,copyPaletteToCopperlistLoop
	RTS

copyMainGameBackground:
	MOVE.L	frameBuffers,A1
	MOVE.L	#imageMainGameBackground,A0
	JSR	decompressRLEImage
	MOVE.L	frameBuffers,A0
	MOVE.L	A0,A1
	ADD.W	#$7D00,A1
	MOVE.W	#$7CFF,D3
copyMainGameBackgroundLoop:
	MOVE.B	(A0)+,(A1)+
	DBRA	D3,copyMainGameBackgroundLoop
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

lbC048A00:
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

lbC048A56:
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

lbC048AAA:
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
	ADD.W	collisionStateFlags1,D0
	ASR.W	#$03,D0
	BPL	lbC048B0A
	CLR.W	D0
lbC048B0A:
	MOVE.W	D0,lbW049570
	MOVE.L	trackCenterX,D0
	ASR.L	#$03,D0
	ADD.W	lbW049570,D0
	BPL	lbC048B24
	CLR.W	D0
lbC048B24:
	MOVE.L	trackCenterY,D3
	ASR.L	#$03,D3
	ADD.W	lbW049570,D3
	BPL	lbC048B38
	CLR.W	D3
lbC048B38:
	MOVE.L	trackCenterZ,D4
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
	MOVE.W	carVelocity,D0
	JSR	sendSerialWordWithChecksum
	MOVE.W	lateralRoadPosition,D0
	TST.B	reverseDirectionFlag
	BPL	lbC048BA2
	NEG.W	D0
	ADD.W	#$0180,D0
lbC048BA2:
	MOVE.W	D0,D0
	JSR	sendSerialWordWithChecksum
	CMP.B	#$40,lbB00D4A5
	BEQ	sendGameStatePacket
	CMP.B	#$80,lbB00D4A5
	BEQ	sendGameStatePacket
	MOVE.B	#$00,D4
	MOVE.B	#$19,D1
	JSR	checkKeyPressed
	BNE	lbC048BDA
	MOVE.B	networkGameMode,D4
lbC048BDA:
	MOVE.B	D4,lbB00D4A5
sendGameStatePacket:
	MOVE.B	lbB00D4A5,D0
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
	MOVE.B	wreckCountdownTimer,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	gameModeStateFlags,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	raceStartTimer,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	objectDisplayThreshold,D0
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
	MOVE.B	eventTimerCountdown,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	gameTimingCounter,D0
	JSR	sendSerialByteWithChecksum
	MOVE.W	checksumAccumulator,D0
	JSR	sendSerialWordWithChecksum
	TST.B	lbB04956E
	BNE	lbC048D30
	MOVE.B	opponentSegmentIndex,lbB04956A
	MOVE.W	gameStateCounter,lbW049576
	TST.B	lbB04956E
	BNE	lbC048D30
	CLR.W	networkDataCounter1
	JSR	waitForNetworkByte
	MOVE.B	D0,opponentSegmentIndex
	JSR	waitForNetworkWord
	MOVE.W	D0,gameStateCounter
	TST.B	selectedRaceType
	BPL	lbC048D2E
	MOVE.B	opponentSegmentIndex,D0
	CMP.B	numTrackSegments,D0
	BCC	lbC048D30
	MOVE.W	#$00FF,D0
	JSR	calculateDistanceOrAngle
lbC048D2E:
	RTS

lbC048D30:
	MOVE.B	#$80,networkPacketReadyFlag
	CLR.B	lbB04956E
	RTS

handleNetworkProtocol:
	TST.B	networkPacketReadyFlag
	BNE	lbC048FEE
	MOVE.B	lbB00D4A5,lbB049550
	MOVE.B	playerInputState,lbB049551
	MOVE.B	gameModeStateFlags,lbB049552
	MOVE.B	wreckCountdownTimer,lbB049553
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
	JSR	lbC048AAA
	MOVE.B	D3,lbB049550
	JSR	waitForNetworkByte
	MOVE.B	D0,D0
	MOVE.B	lbB049551,D3
	JSR	lbC048AAA
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
	JSR	lbC048AAA
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
	MOVE.L	lbW049546,lbL00D666
	MOVE.W	lbW04954A,lbW00D66A
	MOVE.W	lbW04954C,lbW00D4EE
	MOVE.W	lbW04954E,networkEngineFlag
	MOVE.B	lbB049550,lbB00D4A5
	MOVE.B	lbB049551,playerInputState
	MOVE.B	lbB049552,gameModeStateFlags
	MOVE.B	lbB049553,wreckCountdownTimer
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
	SUB.B	gameTimingCounter,D0
	BPL	lbC048FBE
	JSR	networkTimingSync1
	JSR	synchronizeNetworkState
	JSR	longNetworkDelay
	BRA	handleNetworkProtocol

lbC048FBE:
	BEQ	lbC048FCA
	MOVE.B	#$80,lbB04956E
lbC048FCA:
	TST.B	selectedRaceType
	BPL	lbC048FEC
	JSR	lbC055AB6
	JSR	calculatePlayerDistance
	JSR	updateEngineState
	JSR	processTrackSegmentData
lbC048FEC:
	RTS

lbC048FEE:
	JSR	checkNetworkStatus
	BEQ	lbC049004
	JSR	lbC04903A
	JSR	networkHandshakeLoop
lbC049004:
	MOVE.B	lbB04956A,opponentSegmentIndex
	MOVE.W	lbW049576,gameStateCounter
	TST.B	networkConnectionState
	BEQ	lbC049028
	SUBQ.B	#$01,networkConnectionState
lbC049028:
	MOVE.B	#$80,networkPacketReadyFlag
	MOVE.W	#$FFFF,storedDepth
	RTS

lbC04903A:
	JSR	receiveNetworkGamePacket
	BCS	lbC0490F8
	MOVE.B	receivedGameInitFlag,D4
	TST.B	receivedGameStateID
	BNE	lbC04906E
	BTST	#$00,D4
	BEQ	lbC04906C
	MOVE.B	networkGameMode,D0
	EOR.B	#$C0,D0
	MOVE.B	D0,lbB00D4A5
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
	MOVE.B	#$80,currentTrackIDs
	MOVE.B	#$05,gameEndModeFlag
	MOVE.B	#$00,gameModeStateFlags
	MOVE.B	#$00,playerInputState
	MOVE.B	#$00,lbB00D4A5
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
	MOVE.B	#$80,currentTrackIDs
	RTS

lbC0490F8:
	RTS

sendNetworkGamePacket:
	CLR.W	checksumAccumulator
	MOVE.W	#$1256,D0
	JSR	sendSerialWordWithChecksum
	MOVE.B	#$34,D0
	JSR	sendSerialByteWithChecksum
	MOVE.B	gameInitFlag2,D0
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
	JSR	lbC048A56
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
	TST.B	gameEndModeFlag
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
	MOVE.B	D0,gameInitFlag2
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

lbC0493C0:
	MOVE.B	D0,inputStateFlags
	MOVE.B	#$80,receivedKey
	TST.B	gameInitFlag1
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
	MOVE.B	receivedKey,D0		; Load remote player's key press
	BMI	lbC049480		; If $80 (no key), return negative
	MOVE.B	maxMenuIndex,D3		; Load max menu index
	ADDQ.B	#$01,D3			; Convert to count (max+1)
	CMP.B	D3,D0			; Check if selection > max
	BGT	lbC049480		; If out of range, return negative
	MOVE.B	receivedKey,selectedMenuItem	; Valid: update current menu selection
	RTS				; Return positive (valid)

lbC049480:
	MOVE.B	#$80,D0			; Return $80 with negative flag
	RTS

lbC049486:
	TST.B	networkGameMode
	BEQ	lbC0494F6
	MOVE.B	#$01,gameInitFlag2
	MOVE.B	#$F1,networkProtocolState
	JSR	waitForNetworkHandshake
	BCS	lbC04950A
lbC0494AA:
	JSR	lbC05128A
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
	JSR	lbC05128A
	MOVE.B	#$18,D1
	JSR	checkKeyPressed
	BNE	lbC0494F6
lbC04950A:
	MOVE.B	#$00,gameInitFlag2
	MOVE.B	#$00,lbB00D4A5
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
	JSR	renderMenuCursor
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
	JSR	displayNetworkMessage
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
	JSR	renderMenuCursor
	MOVE.W	#$0012,D3
	JSR	displayNetworkMessage
	MOVE.B	#$80,gameInitFlag1
	JSR	waitForDisplaySync
	MOVE.L	(SP)+,renderFrameBuffer
	JSR	resetTextYOffset
	TST.B	networkGameMode
	BMI	lbC04967E
	JSR	displayNetworkWaitMessage
lbC04967E:
	JSR	synchronizeLeagueSetup
	ANDI.B	#$1E,CCR
	RTS

lbC04968A:
	MOVE.B	#$00,networkGameMode
	MOVE.B	#$01,currentMenuItem
	JSR	renderMenuCursor
	MOVE.W	#$0000,D3
	JSR	displayNetworkMessage
	JSR	waitForDisplaySync
	MOVE.L	(SP)+,renderFrameBuffer
	JSR	resetTextYOffset
	ORI.B	#$01,CCR
	RTS

displayNetworkMessage:
	MOVE.L	#lbL049700,A0
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	displayFrameBuffer,renderFrameBuffer
	JSR	renderNetworkString
	MOVE.L	(SP)+,renderFrameBuffer
	RTS

renderNetworkString:
	MOVE.B	$00(A0,D3.W),D0
	CMP.B	#$FF,D0
	BEQ	lbC0496FE
	JSR	renderCharacter
	ADDQ.W	#$01,D3
	BRA	renderNetworkString

lbC0496FE:
	RTS

synchronizeLeagueSetup:
	MOVE.B	#$00,networkSyncStateFlag
	MOVE.B	#$40,networkPlayerStateCache
	TST.B	networkGameMode
	BMI	lbC0497D4
lbC049758:
	JSR	checkSpaceKeyPressed
	BEQ	lbC049844
	MOVE.W	#$00C0,D7
	MOVE.L	#networkTransferBuffer,A6
	JSR	receiveLeagueDataPacket
	BMI	lbC049758
	MOVE.L	#networkTransferBuffer,A6
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
	JSR	screenUpdate
	MOVE.B	additionalPlayerCount,D0
	CMP.B	#$07,D0
	BCS	lbC0497B6
lbC0497E8:
	TST.B	additionalPlayerCount
	BEQ	lbC0497B6
	JSR	displayNetworkWaitMessage
	MOVE.L	#networkTransferBuffer,A6
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
	MOVE.L	#networkTransferBuffer,A6
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

swapPlayerContextForNetwork:
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

displayNetworkWaitMessage:
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	displayFrameBuffer,renderFrameBuffer
	JSR	drawScreenFrame
	MOVE.B	#$01,currentMenuItem
	JSR	renderMenuCursor
	MOVE.W	#$002E,D3
	JSR	displayNetworkMessage
	JSR	resetTextYOffset
	MOVE.L	(SP)+,renderFrameBuffer
	RTS

synchronizeNetworkGame:
	CMP.B	#$80,networkGameMode
	BNE	synchronizeNetworkSetup
	MOVE.B	networkSyncStateFlag,D0
	OR.B	#$10,D0
	TST.B	inputCancelFlag
	BPL	lbC049B60
	BSET	#$03,D0
lbC049B60:
	MOVE.B	D0,localInputStateCache
	MOVE.B	networkPlayerStateCache,localPlayerStateCache
	MOVE.B	#$B2,networkProtocolState
	JSR	waitForNetworkHandshake
	TST.B	networkSyncStateFlag
	BNE	lbC049BF2
	TST.B	inputCancelFlag
	BNE	lbC049BF2
synchronizeNetworkSetup:
	JSR	checkSpaceKeyPressed
	BEQ	lbC049BF2
	TST.B	networkPlayerStateCache
	BNE	lbC049BB4
	MOVE.L	#selectedTrack,A6
	MOVE.W	#$0002,D7
	BRA	lbC049BE8

lbC049BB4:
	MOVE.B	#$01,networkSyncStateFlag
	MOVE.B	#$01,D0
	JSR	syncMultiplayerRecords
	MOVE.B	#$00,networkSyncStateFlag
	MOVE.L	#networkTransferBuffer,A6
	MOVE.W	#$00FF,D7
	CMP.B	#$40,networkPlayerStateCache
	BNE	lbC049BE8
	MOVE.W	#$01FF,D7
lbC049BE8:
	JSR	sendLeagueDataPacket
	BMI	synchronizeNetworkSetup
lbC049BF2:
	RTS

lbC049BF4:
	MOVE.B	#$00,lbB00D494
	JSR	displayNetworkWaitMessage
	MOVE.B	#$B2,networkProtocolState
	JSR	waitForNetworkHandshake
	JSR	checkSpaceKeyPressed
	BEQ	lbC049C42
	MOVE.B	receivedPlayerState,networkPlayerStateCache
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
	MOVE.B	#$00,networkSyncStateFlag
	JSR	receiveAdditionalSyncData
lbC049C78:
	JMP	lbC04D590

receiveAdditionalSyncData:
	JSR	checkSpaceKeyPressed
	BEQ	lbC049CE6
	MOVE.W	#$0002,D7
	MOVE.L	#networkTransferBuffer,A6
	TST.B	networkPlayerStateCache
	BEQ	lbC049CB0
	MOVE.W	#$00FF,D7
	CMP.B	#$40,networkPlayerStateCache
	BNE	lbC049CB0
	MOVE.W	#$01FF,D7
lbC049CB0:
	JSR	receiveLeagueDataPacket
	BMI	receiveAdditionalSyncData
	TST.B	networkPlayerStateCache
	BNE	lbC049CDC
	MOVE.L	#selectedTrack,A0
	MOVE.L	#networkTransferBuffer,A6
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
	JSR	lbC049DA0
	TST.B	networkGameMode
	BMI	lbC049D48
lbC049D02:
	JSR	checkSpaceKeyPressed
	BEQ	lbC049D70
	MOVE.L	#networkTransferBuffer,A6
	MOVE.W	#$0004,D7
	JSR	receiveLeagueDataPacket
	BMI	lbC049D02
	JSR	lbC049DDE
	MOVE.B	opponentID,D0
	JSR	lbC049D72
	MOVE.L	#networkTransferBuffer,A1
	JSR	lbC049D8A
	TST.B	networkGameMode
	BMI	lbC049D70
lbC049D48:
	JSR	checkSpaceKeyPressed
	BEQ	lbC049D70
	MOVE.L	#lbL049D9A,A6
	MOVE.W	#$0004,D7
	JSR	sendLeagueDataPacket
	BMI	lbC049D48
	TST.B	networkGameMode
	BMI	lbC049D02
lbC049D70:
	RTS

lbC049D72:
	SUBQ.B	#$04,D0
	MOVE.B	D0,D3
	ASL.B	#$02,D0
	ADD.B	D3,D0
	ADDQ.B	#$04,D0
	MOVE.B	D0,D2
	MOVE.B	#$04,D1
	MOVE.L	#DDDDDDDD.MSG,A2
	RTS

lbC049D8A:
	MOVE.B	$00(A1,D1.W),$00(A2,D2.W)
	SUBQ.B	#$01,D2
	SUBQ.B	#$01,D1
	BPL	lbC049D8A
	RTS

lbC049DA0:
	MOVE.L	#lbW049E00,A0
	MOVE.L	#controlKeys,A1
	MOVE.L	#lbL049D9A,A2
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

lbC049DDE:
	MOVE.L	#networkTransferBuffer,A0
	MOVE.L	#lbW049E00,A2
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
	MOVE.B	#$00,opponentVisibilityFlag
	TST.B	networkGameMode
	BEQ	lbC049F40
	MOVE.W	networkEngineFlag,D0
	BPL	lbC049F42
	NEG.W	D0
	CMP.W	#$003C,D0
	BLT	lbC049F40
	MOVE.B	#$80,opponentVisibilityFlag
lbC049F2E:
	MOVE.W	storedDepth,D0
	BMI	lbC049F40
	ADD.W	#$0020,storedDepth
lbC049F40:
	RTS

lbC049F42:
	SUB.W	#$0100,D0
	CMP.W	#$003C,D0
	BLT	lbC049F40
	MOVE.B	#$01,opponentVisibilityFlag
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
	MOVE.L	#networkTransferBuffer,A6
	MOVE.W	#$0063,D7
	JSR	receiveLeagueDataPacket
	BMI	lbC049F88
	MOVE.L	#playerStatsArray,A0
	MOVE.L	#networkTransferBuffer,A6
	MOVE.W	#$0047,D7
lbC049FB6:
	MOVE.B	(A6)+,(A0)+
	DBRA	D7,lbC049FB6
	MOVE.B	(A6)+,raceOutcomeFlags
	EOR.B	#$C0,raceOutcomeFlags
	MOVE.B	(A6)+,displayFlags
	MOVE.B	(A6)+,raceFlag1
	MOVE.B	(A6)+,raceFlag2
	MOVE.L	#lbL050548,A0
	MOVE.W	#$000B,D7
lbC049FE6:
	MOVE.B	$000C(A6),$000D(A0)
	MOVE.B	(A6)+,(A0)+
	DBRA	D7,lbC049FE6
	RTS

lbC049FF4:
	MOVE.L	#networkTransferBuffer,A6
	MOVE.L	#playerStatsArray,A0
	MOVE.W	#$0047,D7
copyGameStateData:
	MOVE.B	(A0)+,(A6)+
	DBRA	D7,copyGameStateData
	MOVE.B	raceOutcomeFlags,(A6)+
	MOVE.B	displayFlags,(A6)+
	MOVE.B	raceFlag1,(A6)+
	MOVE.B	raceFlag2,(A6)+
	MOVE.L	#lbL050548,A0
	MOVE.W	#$000B,D7
lbC04A02C:
	MOVE.B	$000D(A0),$000C(A6)
	MOVE.B	(A0)+,(A6)+
	DBRA	D7,lbC04A02C
lbC04A038:
	JSR	checkSpaceKeyPressed
	BEQ	lbC04A056
	MOVE.L	#networkTransferBuffer,A6
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
	JSR	lbC04A16C
	MOVE.B	opponentID,D1
	ADD.B	#$0C,D1
	MOVE.B	#$01,D2
	JSR	lbC04A16C
lbC04A0EE:
	RTS

lbC04A0F0:
	MOVE.B	currentPlayerID,D2
	ADD.B	#$0C,D2
	MOVE.B	#$00,D1
	JSR	lbC04A112
	MOVE.B	opponentID,D2
	ADD.B	#$0C,D2
	MOVE.B	#$01,D1
lbC04A112:
	TST.B	$00(A3,D1.W)
	BEQ	lbC04A156
	TST.B	$00(A0,D2.W)
	BNE	lbC04A126
	BRA	lbC04A158

lbC04A126:
	MOVE.W	D2,-(SP)
	MOVE.B	#$03,D2
	JSR	lbC04A158
	MOVE.W	#$0003,D1
	MOVE.W	(SP)+,D2
	JSR	compareAndCopyPlayerStats
	MOVE.L	#playerStatsArray,A0
	MOVE.L	#lapTimeSeconds,A1
	MOVE.L	#lapTimeSubseconds,A2
	MOVE.L	#lbL04A180,A3
lbC04A156:
	RTS

lbC04A158:
	MOVE.B	$00(A3,D1.W),$00(A0,D2.W)
	MOVE.B	$02(A3,D1.W),$00(A1,D2.W)
	MOVE.B	$04(A3,D1.W),$00(A2,D2.W)
	RTS

lbC04A16C:
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
	MOVE.L	#lbL00E2C2,A6
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
	JSR	waitForDisplaySync
	JMP	displayMenuScreen

lbC04A214:
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
	MOVE.B	#$36,temp
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
	SUBQ.B	#$01,temp
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

lbC04A730:
	MOVE.B	D0,lbB055C63
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.B	#$0D,D1
	JSR	renderLeagueText
	MOVE.B	raceSeriesProgress,D0
	ADDQ.B	#$01,D0
	JSR	lbC0506CA
	MOVE.B	#$F4,D1
	JSR	renderLeagueText
	MOVE.B	raceCount,D0
	TST.B	additionalPlayerCount
	BEQ	lbC04A774
	ASL.B	#$01,D0
lbC04A774:
	JMP	lbC0506CA

lbC04A77A:
	TST.B	lbB00D4AA
	BMI	lbC04A7D4
	JSR	resetTextYOffset
	MOVE.B	#$0B,D0
	JSR	lbC04A730
	MOVE.W	#$0000,D3
	JSR	renderTextFromTable
	JSR	lbC04A214
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	JSR	resetTextYOffset
	MOVE.B	#$14,D2
	JSR	renderTrackInfoDisplay
	MOVE.B	#$80,D0
	JSR	transferLapRecords
	JSR	lbC050974
	JMP	lbC056128

lbC04A7D4:
	JSR	setTextYOffset4
	MOVE.B	#$0A,D0
	JSR	lbC04A730
	JSR	configurePlayersAndCars
	MOVE.B	#$11,D0
	JSR	lbC0561D2
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
	JMP	lbC056128

lbC04A844:
	MOVE.L	#lbB00E30E,A6
	CLR.W	D6
	MOVE.B	lbB00D4E8,D6
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
lbC04A8D6:
	MOVE.B	lbB00D4E8,D2
	MOVE.L	#lbB00E30E,A2
	MOVE.B	$00(A2,D2.W),savedPlayerIndex
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
	MOVE.L	#lbL00E2F6,A1
	CLR.W	D0
	MOVE.B	savedPlayerIndex,D0
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
	MOVE.L	#lbL00E2DE,A1
	CLR.W	D0
	MOVE.B	savedPlayerIndex,D0
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
	MOVE.L	#lbL00E2EA,A1
	CLR.W	D0
	MOVE.B	savedPlayerIndex,D0
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
	MOVE.L	#lbL00E302,A1
	CLR.W	D0
	MOVE.B	savedPlayerIndex,D0
	MOVE.B	$00(A1,D0.W),D0
	JSR	renderDecimal
	ADD.B	#$0B,lbB04AA3E
	ADDQ.B	#$01,lbB00D4E8
	MOVE.B	lbB00D4E8,D0
	CMP.B	maxRenderingIndex,D0
	BNE	lbC04A8D6
	JMP	lbC056128

lbC04AA42:
	JSR	renderCharacter
	ADDQ.W	#$01,D3
renderTextFromTable:
	MOVE.L	#leagueStatisticsTextTable,A0
	MOVE.B	$00(A0,D3.W),D0
	CMP.B	#$FF,D0
	BNE	lbC04AA42
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
	BPL	lbC04AC90
	JSR	decompressRLEImage
	BRA	lbC04ACAC

lbC04AC90:
	MOVE.L	A1,A3
	ADD.L	#$00001F40,A3
lbC04AC98:
	MOVE.W	(A0)+,(A1)+
	MOVE.W	(A0)+,$1F3E(A1)
	MOVE.W	(A0)+,$3E7E(A1)
	MOVE.W	(A0)+,$5DBE(A1)
	CMP.L	A3,A1
	BNE	lbC04AC98
lbC04ACAC:
	JSR	animatePaletteToTarget
	JSR	waitForDisplaySync
	RTS

copyTrackPreviewRegion:
	MOVE.L	frameBuffers,A0
	MOVE.L	displayFrameBuffer,A3
	ADD.L	#$00000140,A0
	ADD.L	#$00000140,A3
	MOVE.L	A0,A2
	ADD.L	#$00001540,A2
lbC04ACDA:
	MOVE.W	(A0)+,(A3)+
	MOVE.W	$1F3E(A0),$1F3E(A3)
	MOVE.W	$3E7E(A0),$3E7E(A3)
	MOVE.W	$5DBE(A0),$5DBE(A3)
	CMP.L	A2,A0
	BLT	lbC04ACDA
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
	MOVE.L	renderFrameBuffer,A1
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
	MOVE.L	lbB00D194,A0
	BRA	lbC04B21A

lbC04B214:
	MOVE.L	lbW00D190,A0
lbC04B21A:
	LEA	$00(A0,D0.W),A0
	ASL.W	#$08,D0
	MOVE.B	(A0),D0
lbC04B222:
	ANDI.B	#$1E,CCR
	RTS

processDirectionalInput:
	MOVE.B	#$00,inputCancelFlag
	CMP.B	#$00,D0
	BNE	lbC04B292
	LSR.W	#$08,D0
	CMP.B	#$45,D0
	BNE	lbC04B24C
	MOVE.B	#$80,inputCancelFlag
	RTS

lbC04B24C:
	CMP.B	#$4C,D0
	BNE	lbC04B25E
	MOVE.B	#$20,inputCancelFlag
	RTS

lbC04B25E:
	CMP.B	#$4D,D0
	BNE	lbC04B270
	MOVE.B	#$40,inputCancelFlag
	RTS

lbC04B270:
	CMP.B	#$4F,D0
	BNE	lbC04B282
	MOVE.B	#$10,inputCancelFlag
	RTS

lbC04B282:
	CMP.B	#$4E,D0
	BNE	lbC04B292
	MOVE.B	#$08,inputCancelFlag
lbC04B292:
	RTS

updateCoordinateTransforms:
	MOVE.L	#trackCoordinatesX,A0
	MOVE.W	$00(A0,D2.W),lateralVelocity
	MOVE.W	$20(A0,D2.W),lbW00D4F8
	JSR	calculate3DProjection
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
	MOVE.W	D0,renderDataPointer
	MOVE.W	#$0118,D1
	MOVE.W	#$011C,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$0118,D1
	MOVE.W	#$011A,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$011A,D1
	MOVE.W	#$011E,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$011C,D1
	MOVE.W	#$011E,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
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
	MOVE.W	D0,renderDataPointer
	JSR	negateViewOffset
	JSR	calculateRelativeViewOffset
	MOVE.W	#$05E0,D0
	ADD.W	#$0010,D0
	MOVE.W	D0,renderDataPointer
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
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$010A,D1
	MOVE.W	#$010C,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$010C,D1
	MOVE.W	#$010E,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$010E,D1
	MOVE.W	#$0108,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
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
	MOVE.W	D0,renderDataPointer
	MOVE.W	#$0110,D1
	MOVE.W	#$0112,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$0112,D1
	MOVE.W	#$0114,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$0114,D1
	MOVE.W	#$0116,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$0116,D1
	MOVE.W	#$0110,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$0108,D1
	MOVE.W	#$0110,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$010E,D1
	MOVE.W	#$0116,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$010A,D1
	MOVE.W	#$0112,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$010C,D1
	MOVE.W	#$0114,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$05E0,D0
	ADD.W	#$0060,D0
	MOVE.W	D0,renderDataPointer
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
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$0102,D1
	MOVE.W	#$0104,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$0104,D1
	MOVE.W	#$0106,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
	MOVE.W	#$0106,D1
	MOVE.W	#$0100,D2
	JSR	drawClippedLine
	ADDQ.W	#$04,renderDataPointer
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

processTrackSegmentData:
	MOVE.W	#$0040,D0
	JSR	calculateDistanceOrAngle
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
	MOVE.W	D0,interpolationPointsXY1
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,interpolationPointsXY2
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,interpolationPointsXY3
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,interpolationPointsXY4
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
	JSR	calculateTrackCoordinates
	MOVE.W	#$000C,D2
	MOVE.W	#$0002,D1
	JSR	calculateTrackCoordinates
	BCLR	#$07,coordinateTransformFlags
	MOVE.L	#lbL00D666,A0
	MOVE.L	#distanceLookupTable,A3
	MOVE.W	(A0),D0
	SUB.W	$0002(A0),D0
	BPL	lbC04BC42
	NEG.W	D0
lbC04BC42:
	ASR.W	#$04,D0
	MOVE.B	$00(A3,D0.W),distanceCharacteristic
	MOVE.B	trackDistanceHigh,trackProcessingFlag
	MOVE.W	networkEngineFlag,D0
	CLR.W	D3
	MOVE.B	distanceCharacteristic,D3
	SUB.W	D3,D0
	MOVE.W	D0,adjustedDistanceValue
	MOVE.W	#$0000,D1
	JSR	calculateAndStoreBounds
	MOVE.W	#$000A,D2
	MOVE.W	#$0008,D1
	MOVE.W	adjustedDistanceValue,D0
	JSR	processCoordinateTransformation
	MOVE.W	networkEngineFlag,D0
	CLR.W	D3
	MOVE.B	distanceCharacteristic,D3
	ADD.W	D3,D0
	MOVE.W	D0,adjustedDistanceValue
	MOVE.W	#$0002,D1
	JSR	calculateAndStoreBounds
	MOVE.W	#$000E,D2
	MOVE.W	#$0008,D1
	MOVE.W	adjustedDistanceValue,D0
	JSR	processCoordinateTransformation
	MOVE.W	interpolationPointsXY1,D0
	SUB.W	interpolationPointsXY3,D0
	BPL	lbC04BCD0
	NEG.W	D0
lbC04BCD0:
	CMP.W	#$0014,D0
	BLT	lbC04BCE0
	MOVE.B	#$80,curveSmoothingFlag
lbC04BCE0:
	JSR	calculateRoadEdgeControlPoints
	MOVE.W	interpolationPointsXY1,D0
	SUB.W	interpolationPointsXY3,D0
	BPL	lbC04BCF8
	NEG.W	D0
lbC04BCF8:
	CMP.W	#$0014,D0
	BLT	lbC04BD08
	MOVE.B	#$80,curveSmoothingFlag
lbC04BD08:
	MOVE.W	#$00FF,D0
calculateDistanceOrAngle:
	MOVE.B	opponentSegmentIndex,D1
	MOVE.B	D1,currentSegmentIndex
	MOVE.W	gameStateCounter,D3
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
	JSR	calculateInterpolatedValue
	MOVE.L	currentMenuItemCopy,D0
	ASR.L	#$03,D0
	MOVE.L	#boundsMinX,A0
	MOVE.W	D0,$00(A0,D1.W)
	RTS

calculateRoadEdgeControlPoints:
	MOVE.L	#trackCoordinatesX,A0
	MOVE.W	$000E(A0),D0
	SUB.W	$000A(A0),D0
	MOVE.W	D0,segmentDirectionTemp2
	ASR.W	#$01,D0
	ADD.W	D0,segmentDirectionTemp2
	MOVE.W	$002E(A0),D0
	SUB.W	$002A(A0),D0
	MOVE.W	D0,perpendicularOffsetY
	ASR.W	#$01,D0
	ADD.W	D0,perpendicularOffsetY
	MOVE.W	$000A(A0),D0
	SUB.W	perpendicularOffsetY,D0
	MOVE.W	D0,$0010(A0)
	MOVE.W	$002A(A0),D0
	ADD.W	segmentDirectionTemp2,D0
	MOVE.W	D0,$0030(A0)
	MOVE.W	$000E(A0),D0
	SUB.W	perpendicularOffsetY,D0
	MOVE.W	D0,$0014(A0)
	MOVE.W	$002E(A0),D0
	ADD.W	segmentDirectionTemp2,D0
	MOVE.W	D0,$0034(A0)
	MOVE.B	trackDistanceHigh,D0
	ADD.B	#$80,D0
	BCC	lbC04BE08
	MOVE.W	interpolationPointsXY3,interpolationPointsXY1
	MOVE.W	interpolationPointsXY4,interpolationPointsXY2
	MOVE.W	additionalInterpolationPoints1,interpolationPointsXY3
	MOVE.W	additionalInterpolationPoints2,interpolationPointsXY4
lbC04BE08:
	MOVE.B	D0,trackProcessingFlag
	MOVE.B	previousDataIndex,previousIndexBackup
	MOVE.W	#$0004,D1
	BRA	calculateAndStoreBounds

lbC04BE20:
	MOVE.L	#trackCoordinatesX,A0
	MOVE.W	$04(A0,D1.W),D0
	SUB.W	$00(A0,D1.W),D0
	MOVE.W	coordinateTransformParameter,D3
	MULS	D3,D0
	ASR.L	#$08,D0
	TST.B	coordinateTransformFlags
	BPL	lbC04BE50
	ADDQ.B	#$04,D1
	JSR	lbC04BE50
	SUBQ.B	#$04,D1
	RTS

lbC04BE50:
	ADD.W	$00(A0,D1.W),D0
	MOVE.W	D0,$00(A0,D2.W)
	RTS

calculateTrackCoordinates:
	MOVE.B	trackDistanceHigh,D0
	MOVE.L	#aiBehaviorFlag1,A0
	ADD.B	$00(A0,D1.W),D0
	ROXR.B	#$01,D3
	MOVE.B	D3,coordinateTransformFlags
	AND.W	#$00FF,D0
processCoordinateTransformation:
	MOVE.W	D0,coordinateTransformParameter
	JSR	lbC04BE20
	ADD.B	#$20,D2
	ADD.B	#$20,D1
	BRA	lbC04BE20

lbC04BE8E:
	MOVE.L	#trackCoordinatesX,A0
	MOVE.W	$00(A0,D2.W),lateralVelocity
	MOVE.W	$20(A0,D2.W),lbW00D4F8
	JSR	calculate3DProjection
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
	JSR	calculateTrackCoordinatesFromData
	MOVE.L	#trackCoordinatesX,A1
	MOVE.W	lateralVelocity,$00(A1,D1.W)
	MOVE.L	#trackCoordinatesY,A1
	MOVE.W	lbW00D4F8,$00(A1,D1.W)
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
	MOVE.L	#SELECTSingleP.MSG,A1
	MOVE.B	$00(A1,D1.W),D0
	CMP.B	#$FF,D0
	BNE	lbC04BF74
	RTS

generateDrawBridge:
	MOVE.B	currentTrackID,D0
	CMP.B	#$05,D0
	BEQ	generateTrackSegment
	RTS

generateTrackSegment:
	CMP.B	#$38,playerSegmentIndex
	BCC	lbC04C0BC
	CMP.B	#$33,playerSegmentIndex
	BCC	lbC04C0EA
lbC04C0BC:
	CMP.B	#$38,opponentSegmentIndex
	BCC	lbC04C0FE
	CMP.B	#$33,opponentSegmentIndex
	BCC	lbC04C0EA
	TST.B	trackEffectFlag
	BEQ	lbC04C0FE
	CMP.B	#$30,opponentSegmentIndex
	BCS	lbC04C0FE
lbC04C0EA:
	MOVE.B	#$0C,D0
	MOVE.B	D0,trackEffectFlag
	ADD.B	trackVariationSeed,D0
	BRA	lbC04C266

lbC04C0FE:
	TST.B	trackDirectionFlag
	BMI	lbC04C10E
	ADDQ.B	#$01,trackVariationSeed
lbC04C10E:
	MOVE.W	#$0000,segmentProgressDistance
	MOVE.B	#$00,trackEffectFlag
	MOVE.B	trackVariationSeed,D0
	AND.W	#$001F,D0
	SUB.W	#$0010,D0
	BPL	lbC04C132
	NOT.W	D0
lbC04C132:
	MOVE.B	D0,D2
	ADDQ.W	#$04,D0
	MOVE.L	#trackCharacteristicTable,A0
	MOVE.B	$00(A0,D2.W),lbB00E285
	MOVE.B	$00(A0,D2.W),lbB00E286
	ASL.W	#$05,D0
	MOVE.W	D0,lateralVelocity
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
	ADD.W	lateralVelocity,D0
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
	MOVE.B	trackDataComponent,$00(A0,D2.W)
	ADDQ.B	#$01,D2
	MOVE.B	D2,temp
	MOVE.B	#$48,D2
	SUB.B	temp,D2
	MOVE.B	(SP)+,$00(A0,D2.W)
	ADDQ.B	#$01,D2
	MOVE.B	trackDataComponent,$00(A0,D2.W)
	MOVE.B	temp,D2
	CMP.B	#$12,D2
	BEQ	lbC04C19A
	SUBQ.B	#$01,D1
	BNE	lbC04C188
	TST.B	graphicsUpdateFlag
	BEQ	lbC04C24A
	MOVE.L	#memory_7AAE6,A1
	MOVE.L	(A1),A1
	MOVE.B	$0010(A0),D0
	ASL.W	#$08,D0
	MOVE.B	$0013(A0),D0
	BCLR	#$0F,D0
	ADD.W	graphicsOffsetX,D0
	MOVE.W	D0,$0006(A1)
	MOVE.W	D0,$000C(A1)
	MOVE.W	D0,$004C(A1)
	MOVE.W	D0,$0052(A1)
	MOVE.B	$0020(A0),D0
	ASL.W	#$08,D0
	MOVE.B	$0021(A0),D0
	BCLR	#$0F,D0
	ADD.W	graphicsOffsetY,D0
	MOVE.W	D0,$0014(A1)
	MOVE.W	D0,$001A(A1)
	MOVE.W	D0,$003E(A1)
	MOVE.W	D0,$0044(A1)
lbC04C24A:
	MOVE.B	#$80,graphicsUpdateFlag
	MOVE.B	opponentSegmentIndex,D0
	CMP.B	#$2F,D0
	BNE	lbC04C294
	MOVE.B	trackVariationSeed,D0
lbC04C266:
	MOVE.L	#colorProgressionTable,A1
	MOVE.L	#paletteUpdateArray,A2
	AND.B	#$1F,D0
	LSR.B	#$01,D0
	MOVE.B	D0,D2
	MOVE.B	#$00,D1
	MOVE.B	#$C6,D0
lbC04C282:
	ADD.B	$00(A1,D2.W),D0
	MOVE.B	D0,$00(A2,D1.W)
	ADDQ.B	#$01,D1
	CMP.B	#$03,D1
	BNE	lbC04C282
lbC04C294:
	RTS

initializeGameData:
	MOVE.L	#lbW00D3F8,A0
lbC04C2BC:
	MOVE.B	#$00,(A0)+
	CMP.L	#lbL00E336,A0
	BNE	lbC04C2BC
	JSR	initializeMessageBuffer
	MOVE.B	#$00,displayUpdateFlag
	MOVE.B	#$0B,D1
lbC04C2DC:
	MOVE.B	D1,D0
	MOVE.L	#lbL00E2C2,A1
	MOVE.B	D0,$00(A1,D1.W)
	JSR	generateRandomNumber
	SUBQ.B	#$01,D1
	BPL	lbC04C2DC
	JSR	initializeGameTables
	MOVE.B	#$0A,objectDisplayThreshold
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
	MOVE.L	#lbL00E2DE,A1
	MOVE.B	#$00,$00(A1,D1.W)
	CMP.B	#$0C,D1
	BCC	lbC04C37C
	MOVE.L	#lbB00E30E,A0
	MOVE.B	D1,$00(A0,D1.W)
	MOVE.L	#lbL00E336,A0
	MOVE.B	#$0A,$00(A0,D1.W)
lbC04C37C:
	SUBQ.B	#$01,D1
	BPL	lbC04C352
	RTS

setupRandomRaceParameters:
	MOVE.L	#lbL04C3F4,A0
	MOVE.L	#lbL00E2D2,A1
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
	CMP.B	selectedTrack,D0
	BNE	lbC04C3E2
lbC04C3D0:
	JSR	configurePlayersAndCars
	JSR	setupCarPerformance
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
	MOVE.L	#lbL04C442,A1
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
	MOVE.L	#lbL04C4C8,A0
	MOVE.L	#lbL04C4CE,A1
	MOVE.B	currentRaceNumber,D1
	MOVE.B	$00(A0,D1.W),D2
	ADD.B	trackBaseOffset,D2
	MOVE.L	#lbL00E2C2,A2
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

setupCarPerformance:
	MOVE.W	#$0000,D1
	JSR	generateRandomNumber
	CMP.B	#$A0,D0
	BCS	lbC04C4EA
	MOVE.B	#$40,D1
lbC04C4EA:
	MOVE.B	D1,raceSetupFlags
	MOVE.B	player1ID,D2
	MOVE.B	player2ID,D1
	MOVE.L	#lbL00E2F6,A1
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
	MOVE.L	#lbL00E2D2,A2
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
	MOVE.B	D1,savedSegmentIndex
	BTST	#$06,raceSetupFlags
	BNE	lbC04C5A0
lbC04C582:
	MOVE.B	D1,currentMenuItemCopy
	JMP	lbC04C5A6

lbC04C58E:
	MOVE.B	D2,savedSegmentIndex
	BTST	#$06,raceSetupFlags
	BEQ	lbC04C582
lbC04C5A0:
	MOVE.B	D2,currentMenuItemCopy
lbC04C5A6:
	TST.B	networkGameMode
	BEQ	lbC04C5BA
	TST.B	raceMode
	BMI	lbC04C5FC
lbC04C5BA:
	MOVE.B	savedSegmentIndex,D1
	MOVE.L	#lbL00E2DE,A1
	ADDQ.B	#$01,$00(A1,D1.W)
	MOVE.B	currentMenuItemCopy,D1
	MOVE.L	#lbL00E2EA,A1
	ADDQ.B	#$01,$00(A1,D1.W)
	MOVE.B	displayTrackID,D0
	CMP.B	selectedTrack,D0
	BNE	lbC04C5FC
	MOVE.B	D1,lbB00E326
	MOVE.B	savedSegmentIndex,D0
	MOVE.B	D0,lbB00E325
lbC04C5FC:
	RTS

sortRaceResults:
	JSR	setupGameConfiguration
	MOVE.L	#lbB00E30E,A3
	MOVE.B	trackBaseOffset,D2
lbC04C610:
	MOVE.L	#lbL00E2C2,A2
	MOVE.B	$00(A2,D2.W),D1
	MOVE.B	D1,D0
	MOVE.B	D0,$00(A3,D2.W)
	MOVE.L	#lbL00E2DE,A0
	MOVE.B	$00(A0,D1.W),D0
	ASL.B	#$01,D0
	MOVE.L	#lbL00E2EA,A0
	ADD.B	$00(A0,D1.W),D0
	MOVE.L	#lbL00E302,A1
	MOVE.B	D0,$00(A1,D1.W)
	ADDQ.B	#$01,D2
	CMP.B	maxRenderingIndex,D2
	BLT	lbC04C610
lbC04C64C:
	MOVE.B	#$00,D0
	MOVE.B	D0,savedSegmentIndex
	MOVE.B	trackBaseOffset,D2
lbC04C65C:
	MOVE.B	D2,currentMenuItemCopy
	MOVE.B	$00(A3,D2.W),D1
	MOVE.B	$01(A3,D2.W),D0
	MOVE.B	D0,D2
	MOVE.L	#lbL00E302,A1
	MOVE.B	$00(A1,D1.W),D0
	CMP.B	$00(A1,D2.W),D0
	BLT	lbC04C6B8
	BNE	lbC04C6DA
	MOVE.L	#lbL00E2DE,A1
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
	MOVE.B	D2,curveMagnitude
	MOVE.B	currentMenuItemCopy,D2
	MOVE.B	D1,D0
	MOVE.B	D0,$01(A3,D2.W)
	MOVE.B	curveMagnitude,D0
	MOVE.B	D0,$00(A3,D2.W)
	ADDQ.B	#$01,savedSegmentIndex
lbC04C6DA:
	MOVE.B	currentMenuItemCopy,D2
	ADDQ.B	#$01,D2
	ADDQ.B	#$01,D2
	CMP.B	maxRenderingIndex,D2
	BGE	lbC04C6F4
	SUBQ.B	#$01,D2
	BRA	lbC04C65C

lbC04C6F4:
	MOVE.B	savedSegmentIndex,D0
	BNE	lbC04C64C
	RTS

readTrackDataByte:
	MOVE.B	$00(A5,D5.W),D0
	ADDQ.W	#$01,D5
	AND.B	#$FF,D0
	RTS

applyDirectionalOffset:
	TST.B	curveMagnitude
	BMI	lbC04C72E
	BTST	#$06,curveMagnitude
	BNE	lbC04C728
	ADD.B	#$10,D0
	RTS

lbC04C728:
	ADD.B	#$01,D0
	RTS

lbC04C72E:
	BTST	#$06,curveMagnitude
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
	MOVE.B	D0,trackBoostThreshold
	MOVE.B	D0,trackBoostThresholdCopy
	JSR	readTrackDataByte
	MOVE.B	D0,lateralVelocity
	MOVE.B	D0,lbW00D4F8
	MOVE.B	#$00,D1
	MOVE.B	D1,segmentAlternateFlag
	MOVE.B	D1,trackDataComponent
	MOVE.B	D1,segmentProgressDistance
	MOVE.B	D1,segmentRepeatCounter
lbC04C7D0:
	MOVE.B	segmentRepeatCounter,D0
	BEQ	lbC04C820
	SUBQ.B	#$01,segmentRepeatCounter
	MOVE.B	previousSegmentProperties,D0
	MOVE.B	D0,curveMagnitude
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	D0,$00(A1,D1.W)
	AND.B	#$10,D0
	BEQ	lbC04C80E
	MOVE.B	curveMagnitude,D0
	EOR.B	#$C0,D0
	MOVE.B	D0,curveMagnitude
lbC04C80E:
	MOVE.B	currentTrackCoordinate,D0
	JSR	applyDirectionalOffset
	JMP	lbC04C86C

lbC04C820:
	JSR	readTrackDataByte
	MOVE.B	D0,curveMagnitude
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	D0,$00(A1,D1.W)
	AND.B	#$0F,D0
	CMP.B	#$0F,D0
	BNE	lbC04C856
	MOVE.B	curveMagnitude,D0
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
	MOVE.B	D0,temp
	MOVE.B	curveMagnitude,D0
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
	MOVE.B	curveMagnitude,D0
	AND.B	#$20,D0
	BEQ	lbC04C90A
	MOVE.L	#segmentGeometryIndices,A1
	MOVE.B	$00(A1,D1.W),D0
	JMP	lbC04C910

lbC04C90A:
	JSR	readTrackDataByte
lbC04C910:
	AND.B	#$7F,D0
	OR.B	temp,D0
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
	MOVE.B	D0,curveMagnitude
	MOVE.L	#segmentInterpolationPoint1,A3
	MOVE.L	#segmentInterpolationPoint2,A4
	MOVE.W	lateralVelocity,D4
	SUB.W	curveMagnitude,D4
	MOVE.W	D4,$00(A3,D1.W)
	MOVE.B	trackModeParameter,D2
	JSR	readSegmentInterpolationValue
	MOVE.B	D0,curveMagnitude
	ADD.W	curveMagnitude,D4
	MOVE.W	D4,lateralVelocity
	MOVE.B	#$00,D2
	JSR	switchToAlternateGeometryAndReadSegmentInterpolationValue
	MOVE.B	D0,curveMagnitude
	MOVE.W	lbW00D4F8,D4
	SUB.W	curveMagnitude,D4
	MOVE.W	D4,$00(A4,D1.W)
	MOVE.B	trackModeParameter,D2
	JSR	switchToAlternateGeometryAndReadSegmentInterpolationValue
	MOVE.B	D0,curveMagnitude
	ADD.W	curveMagnitude,D4
	MOVE.W	D4,lbW00D4F8
	LSR.B	#$01,D1
	MOVE.B	(SP)+,D0
	MOVE.B	D0,D2
	ADDQ.B	#$01,D1
	CMP.B	numTrackSegments,D1
	BEQ	lbC04CA0C
	JMP	lbC04C7D0

lbC04CA0C:
	MOVE.B	trackParameter3,D1
	ADDQ.B	#$01,D1
	CMP.B	numTrackSegments,D1
	BLT	lbC04CA22
	MOVE.B	#$00,D1
lbC04CA22:
	MOVE.B	D1,startingSegmentIndex
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
	JSR	lbC05538E
	MOVE.B	#$00,D0
	MOVE.B	D0,segmentRepeatCounter
	MOVE.B	#$7C,D0
	MOVE.B	D0,temp
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
	MOVE.B	D0,temp
	BPL	lbC04CBAA
lbC04CB38:
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$0F,D0
	MOVE.B	D0,D2
	MOVE.L	#geometryParameterTable,A2
	MOVE.B	$00(A2,D2.W),D0
	BPL	lbC04CB72
	MOVE.B	lbB0555E1,D0
	SUB.B	#$0A,D0
	MOVE.B	D0,temp
	MOVE.B	lbB0555E1,D0
	JMP	lbC04CB8C

lbC04CB72:
	MOVE.B	temp,D0
	ADD.B	#$0A,D0
	BMI	lbC04CB86
	MOVE.B	D0,temp
lbC04CB86:
	MOVE.B	temp,D0
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
	MOVE.B	D0,temp
	SUBQ.B	#$01,D2
	MOVE.B	$00(A0,D2.W),D0
	AND.B	#$7F,D0
	RTS

lbC04CC14:
	MOVE.B	$00(A0,D2.W),D0
	ASL.B	#$01,D0
	AND.B	#$E0,D0
	MOVE.B	D0,temp
	MOVE.B	$00(A0,D2.W),D0
	AND.B	#$0F,D0
	RTS

handleRaceStartCountdown:
	MOVE.B	raceStartTimer,D1
	BEQ	lbC04CC8E
	CMP.B	#$E6,D1
	BCS	lbC04CC6E
	JSR	checkMultiplayerTrackSwap
	MOVE.B	#$2C,D0
	TST.B	trackSideIndicator
	BPL	lbC04CC58
	MOVE.B	#$D4,D0
lbC04CC58:
	MOVE.B	D0,carStartRotation
	MOVE.B	#$00,carStartRotationLow
lbC04CC66:
	SUBQ.B	#$01,raceStartTimer
	RTS

lbC04CC6E:
	CMP.B	#$E5,D1
	BNE	lbC04CC90
	MOVE.B	#$00,D0
	JSR	updateCarStartRotation
	MOVE.B	#$03,D0
	JSR	adjustCarHeightToTrack
	BPL	lbC04CC66
lbC04CC8E:
	RTS

lbC04CC90:
	CMP.B	#$E4,D1
	BNE	lbC04CD02
	MOVE.B	#$04,D0
	JSR	adjustCarHeightToTrack
	MOVE.B	#$FF,D0
	JSR	updateCarStartRotation
	BNE	lbC04CD00
	JSR	generateRandomNumber
	AND.B	#$1F,D0
	ADD.B	#$A0,D0
	MOVE.B	#$2C,D2				; DROP START
	TST.B	raceStartComplete
	BPL	lbC04CCD0
	MOVE.B	#$3C,D2				; PRESS FIRE
lbC04CCD0:
	TST.B	selectedRaceType
	BMI	lbC04CCDE
	MOVE.B	#$8C,D0
lbC04CCDE:
	MOVE.B	D0,raceStartTimer
	TST.B	crashRecoveryTimer
	BEQ	lbC04CCF6
	MOVE.B	#$32,crashRecoveryTimer
lbC04CCF6:
	MOVE.B	#$04,D0
	JMP	setMessageParameters

lbC04CD00:
	RTS

lbC04CD02:
	MOVE.B	#$00,D0
	JSR	updateCarStartRotation
	MOVE.B	#$02,D0
	JSR	adjustCarHeightToTrack
	TST.B	trackDirectionFlag
	BMI	lbC04CD30
	SUBQ.B	#$01,raceStartTimer
	BNE	lbC04CD30
	ADDQ.B	#$01,raceStartTimer
lbC04CD30:
	MOVE.B	raceStartComplete,D0
	BNE	lbC04CD46
	TST.B	raceStartTimer
	BPL	lbC04CD50
	RTS

lbC04CD46:
	MOVE.B	raceActiveFlag,D0
	BNE	lbC04CD70
lbC04CD50:
	MOVE.B	#$00,D0
	MOVE.B	D0,raceStartTimer
	MOVE.B	D0,collisionStateFlags
	MOVE.B	D0,lbB00D48E
	MOVE.B	#$80,D0
	MOVE.B	D0,raceStartComplete
lbC04CD70:
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
	SUB.W	D0,carPitchAdjustment
	LSR.W	#$08,D3
	MOVE.B	D3,D0
	ADDQ.B	#$02,D0
	RTS

updateCarStartRotation:
	MOVE.B	#$10,D4
	TST.B	trackSideIndicator
	BPL	lbC04CDBC
	NEG.B	D0
	MOVE.B	#$F0,D4
lbC04CDBC:
	ASL.W	#$08,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC04CDCA
	MULS	D2,D0
	ASR.L	#$08,D0
lbC04CDCA:
	MOVE.W	offsetFromRoadCenter,D3
	ASL.W	#$05,D3
	MOVE.B	carStartRotation,D7
	CMP.B	D4,D7
	BEQ	lbC04CDE4
	ADD.W	D0,carStartRotation
lbC04CDE4:
	MOVE.W	carStartRotation,D0
	SUB.W	D3,D0
	MOVE.W	D0,cameraAngleZ
	MOVE.W	#$0000,D0
	MOVE.W	D0,verticalMotion
	MOVE.B	carStartRotation,D0
	CMP.B	D4,D0
	RTS

lbC04CE06:
	MOVE.W	#$0008,D1
	MOVE.W	#$0004,D2
	MOVE.L	#lbB00D5D8,A3
lbC04CE14:
	MOVE.L	#lbL00DB30,A2
	MOVE.W	$00(A2,D2.W),D0
	CMP.B	#$08,D1
	BNE	lbC04CE28
	NEG.W	D0
lbC04CE28:
	MOVE.B	trackSideIndicator,trackSideIndicatorCopy
	MOVE.B	#$A0,curveMagnitude
	MOVE.B	curveMagnitude,D3
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
	MOVE.B	playerStateFlag,D0
	BNE	lbC04CE90
	MOVE.W	#$0000,D0
	MOVE.B	inputStateFlags,D0
	AND.B	#$03,D0
	BEQ	lbC04CEA0
	MOVE.W	#$9000,D0
	BNE	lbC04CEA0
lbC04CE90:
	MOVE.W	carVelocity,D0
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
	MOVE.B	playerStateFlag,D2
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

screenUpdate:
	JSR	drawScreenFrame
	MOVE.B	#$E0,D1
	JSR	renderLeagueText
	MOVE.B	#$01,D0
	MOVE.B	D0,currentMenuItem

lbC04CF62:
	JSR	renderMenuCursor
	MOVE.B	#$0A,D0
	MOVE.W	#$006A,D4
	MOVE.W	#$00BE,D6
	MOVE.W	#$0085,D5
	JSR	drawHorizontalLine
	JSR	copyGraphicsRegion
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
	BEQ	lbC04CF94
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
	MOVE.B	#$00,inputCancelFlag
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
	TST.B	inputCancelFlag
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
	JSR	setupDisplayMode
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	MOVE.B	#$00,D1
	MOVE.B	D1,menuHighlightMode
	JSR	renderTextString
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
renderAllMenuOptions:
	MOVE.B	#$00,D0				; Reset item counter
	MOVE.B	D0,currentMenuItem		; Store as 0
lbC04D188:
	MOVE.B	currentMenuItem,D2		; Load current item index
	MOVE.B	D2,currentMenuItemCopy			; Store for later use
	CMP.B	selectedMenuItem,D2		; Is this the selected item?
	BNE	lbC04D1B6			; Skip highlight logic if not
	MOVE.B	#$00,D0
	MOVE.B	menuHighlightMode,D2
	BNE	lbC04D1B0
	MOVE.B	#$01,D0
lbC04D1B0:
	MOVE.B	D0,menuCursorObjectType
lbC04D1B6:
	JSR	renderMenuCursor		; Draw cursor/arrow sprite
	MOVE.B	currentMenuItemCopy,D0
	ADDQ.B	#$01,D0
	JSR	renderDigit			; Draw "1", "2", "3", etc.
	MOVE.B	#$2E,D0
	JSR	renderCharacter			; Draw "."
	MOVE.B	#$20,D0
	JSR	renderCharacter			; Draw " "
	MOVE.B	currentMenuItemCopy,D2
	ADD.B	currentTrackCoordinate,D2
	MOVE.L	#menuStringOffsetTable,A2
	MOVE.B	$00(A2,D2.W),D1
	JSR	renderTextString
	CMP.B	#$18,currentTrackCoordinate
	BNE	lbC04D214
	MOVE.B	currentMenuItemCopy,D0
	ADDQ.B	#$01,D0
	JSR	renderDigit
lbC04D214:
	MOVE.B	maxMenuIndex,D0			; Load max menu index
	CMP.B	currentMenuItemCopy,D0			; Rendered all items?
	BCS	lbC04D262			; Exit loop if done
	MOVE.B	currentTrackCoordinate,D0
	CMP.B	#$1C,D0
	BNE	lbC04D188
	MOVE.B	#$23,D1
	JSR	renderLeagueText
	MOVE.B	selectedTrackGroup,D0
	ASL.B	#$01,D0
	ADD.B	currentMenuItemCopy,D0
	MOVE.B	D0,D2
	MOVE.L	#trackIDLookupTable,A2
	MOVE.B	$00(A2,D2.W),D1
	JSR	renderTrackName
	JMP	lbC04D188

lbC04D262:
	JSR	copyGraphicsRegion
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
	MOVE.B	maxMenuIndex,D2		; Load max menu index
	ADDQ.B	#$01,D2			; Convert to item count
lbC04D2D2:
	MOVE.L	#keycodeTable,A2	; Point to keycode table [1,2,3,4]
	MOVE.B	$00(A2,D2.W),D1		; Get keycode for this index
	JSR	checkKeyPressed		; Check if number key pressed
	BNE	lbC04D2F2		; Not pressed, try next
	MOVE.B	D2,selectedMenuItem		; Key pressed! Set selection
	JMP	renderAllMenuOptions	; Re-render menu

lbC04D2F2:
	SUBQ.B	#$01,D2			; Try next lower key
	BPL	lbC04D2D2		; Loop if >= 0
lbC04D2F8:
	MOVE.B	selectedMenuItem,D1	; Load current selection
	MOVE.B	inputStateFlags,D0	; Get joystick state
	AND.B	#$03,D0			; Isolate up/down bits
	BEQ	readInputLoop		; None pressed, loop back to wait
	AND.B	#$01,D0			; Check bit 0 (up direction)
	BEQ	lbC04D322		; If not up, handle down
	SUBQ.B	#$01,D1			; Decrement selection
	BPL	lbC04D332		; Valid, store it
	MOVE.B	#$00,D1			; Wrap to top (stay at 0)
	BEQ	lbC04D332
lbC04D322:				; Move selection down:
	CMP.B	maxMenuIndex,D1		; At max index?
	BEQ	lbC04D330		; Wrap around
	BCC	lbC04D332		; Beyond max, store as-is
lbC04D330:
	ADDQ.B	#$01,D1			; Increment selection
lbC04D332:
	MOVE.B	D1,selectedMenuItem	; Store new selection
	JMP	renderAllMenuOptions	; Re-render with new cursor

delayRoutine:
	MOVE.B	#$14,D2
delayWithParam:
	MOVE.B	#$14,D0
	MOVE.B	D0,curveMagnitude
lbC04D34C:
	SUBQ.B	#$01,temp
	BNE	lbC04D34C
	SUBQ.B	#$01,curveMagnitude
	BNE	lbC04D34C
	SUBQ.B	#$01,D2
	BNE	delayWithParam
	RTS

handleMenuRaceOptions:
	TST.B	D0		; Test menu selection (0 or 1)
	BNE	lbC04D378	; If 1, handle race selection
	JSR	displayStandings	; Option 0: View league standings - Display standings screen (imageStandingsBackground)
	BRA	handleMainMenu	; Return to main menu

lbC04D378:			; Option 1: Select and configure race
	JSR	lbC051462	; Show track/race type selection menus
	CMP.B	#$02,D0		; Check if user backed out
	BCC	handleMainMenu	; If >= 2, return to menu
	MOVE.B	D0,selectedRaceType	; Store race type (0=practice, 1=competition)
	MOVE.B	#$01,raceConfiguredFlag	; Set "race configured" flag
	MOVE.B	selectedTrackGroup,D0	; Load selected track index (0-3)
	ASL.B	#$01,D0		; Multiply by 2
	ADD.B	selectedRaceType,D0	; Add race type: index = track*2 + type
	JSR	configureSelectedRace	; Configure race using combined index
	JMP	delayRoutine	; Delay and return

lbC04D3AE:
	MOVE.B	#$00,D0
	JSR	saveLoadGameData
	MOVE.B	#$80,D0
	MOVE.B	D0,selectedRaceType
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
	MOVE.B	#$00,inputCancelFlag
	TST.B	raceConfiguredFlag
	BNE	lbC04D378
	MOVE.B	#$01,D0
	TST.B	selectedRaceType
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
	BLT	startGameSession
	BNE	lbC04D3C4
	JSR	initializeGameTables
	MOVE.B	#$50,D1
	JSR	checkKeyPressed
	BNE	startNewGame
	TST.B	networkGameMode
	BPL	lbC04D48C
	MOVE.B	#$C0,localInputStateCache
	MOVE.B	#$B2,networkProtocolState
	JSR	waitForNetworkHandshake
lbC04D48C:
	JMP	enterMenuSystemLoop

startNewGame:
	TST.B	networkGameMode
	BPL	lbC04D4B2
	MOVE.B	#$80,localInputStateCache
	MOVE.B	#$B2,networkProtocolState
	JSR	waitForNetworkHandshake
lbC04D4B2:
	TST.B	additionalPlayerCount
	BNE	lbC04D4CA
	MOVE.B	#$80,D0
	JSR	saveLoadGameData
	BCC	lbC04D59C
lbC04D4CA:
	JSR	initializeGameData
	JSR	displayMenuScreen
	BRA	lbC04D59C

startGameSession:
	MOVE.B	D0,networkSyncStateFlag
	ASL.B	#$02,D0
	ADD.B	#$08,D0
	MOVE.B	D0,D1
	MOVE.B	#$00,D2
lbC04D4EC:
	MOVE.L	#memory_7A01A,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.L	#trackSegmentGrid,A2
	MOVE.B	D0,$00(A2,D2.W)
	SUBQ.B	#$01,D2
	BNE	lbC04D4EC
	MOVE.B	lbB00E334,D0
	MOVE.B	D0,lbB00D4D0
	JSR	delayRoutine
	MOVE.B	#$00,D0
	JSR	saveLoadGameData
	JSR	displaySeasonSelection
	TST.B	networkPlayerStateCache
	BNE	lbC04D562
	TST.B	lbB00D492
	BMI	lbC04D55C
	MOVE.B	networkSyncStateFlag,D0
	BNE	lbC04D55C
	MOVE.B	#$80,D0
	JSR	saveLoadGameData
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
	CMP.B	#$40,networkPlayerStateCache
	BEQ	lbC04D5A2
lbC04D59C:
	JSR	initializeRaceMode
lbC04D5A2:
	JMP	handleMainMenu

restoreGameData:
	MOVE.B	#$00,D2
	MOVE.B	lbB00D4D0,lbB00E334
	MOVE.L	#trackSegmentGrid,A2
	MOVE.L	#memory_7A01A,A0
lbC04D5C2:
	MOVE.B	$00(A2,D2.W),$00(A0,D2.W)
	SUBQ.B	#$01,D2
	BNE	lbC04D5C2
	RTS

configureSelectedRace:
	MOVE.B	D0,D1			; Copy index to D1
	MOVE.L	#trackIDLookupTable,A0	; Point to track ID lookup table
	MOVE.B	$00(A0,D1.W),currentTrackID	; Load track ID (0-7)
	TST.B	currentPlayerContext	; Check player context
	BEQ	lbC04D60E		; Skip swap if player 1
	BCHG	#$00,D1			; Toggle bit 0 (swap even/odd)
lbC04D60E:
	MOVE.L	#raceConfigLookupTable,A0	; Point to config value table
	MOVE.B	$00(A0,D1.W),raceConfigValue	; Store config value
	RTS

processOpponentAI:
	MOVE.B	aiEnabled,D0
	BEQ	lbC04D732
	TST.B	networkGameMode
	BNE	lbC04D732
	MOVE.B	#$00,D1
	MOVE.B	D1,aiBehaviorFlag1
	MOVE.B	D1,aiBehaviorFlag2
	MOVE.B	D1,aiDirectionFlag
	MOVE.B	aiActionTimer,D0
	BEQ	lbC04D6A6
	TST.B	trackDirectionFlag
	BMI	lbC04D662
	SUBQ.B	#$01,aiActionTimer
lbC04D662:
	ADD.B	aiPatternOffset,D0
	AND.B	#$0F,D0
	MOVE.B	D0,D2
	MOVE.L	#aiMovementPatterns,A2
	MOVE.B	$00(A2,D2.W),D0
	BPL	lbC04D680
	NEG.B	D0
	ADDQ.B	#$01,D1
lbC04D680:
	MOVE.L	#aiBehaviorFlag1,A1
	MOVE.B	D0,$00(A1,D1.W)
	ADDQ.B	#$05,D2
	AND.B	#$0F,D2
	MOVE.L	#aiMovementPatterns,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.B	D0,aiDirectionFlag
	JMP	lbC04D71C

lbC04D6A6:
	MOVE.B	opponentSegmentIndex,D2
	MOVE.L	#segmentVisibilityData,A0
	TST.B	$00(A0,D2.W)
	BMI	lbC04D71C
	TST.B	carCrashedFlag
	BMI	lbC04D71C
	TST.B	segmentSteeringFlags
	BMI	lbC04D71C
	MOVE.B	#$08,D2
	TST.B	lbB00D49D
	BPL	lbC04D71C
	BTST	#$06,lbB00D49D
	BEQ	lbC04D6EC
	MOVE.B	#$10,D2
lbC04D6EC:
	MOVE.B	D2,aiPatternOffset
	JSR	generateRandomNumber
	AND.B	#$1F,D0
	MOVE.B	D0,temp
	MOVE.B	opponentID,D0
	CMP.B	temp,D0
	BLT	lbC04D71C
	MOVE.B	#$10,D0
	MOVE.B	D0,aiActionTimer
lbC04D71C:
	MOVE.B	reverseDirectionFlag,D0
	LSR.B	#$01,D0
	MOVE.B	segmentSteeringFlags,D3
	EOR.B	D3,D0
	MOVE.B	D0,lbB00D49D
lbC04D732:
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
	JSR	lbC04DCDA
	MOVE.B	$0003(A5),D3
	ASL.W	#$08,D3
	MOVE.B	$0002(A5),D3
	MOVE.W	lateralVelocity,D0
lbC04D7B0:
	SUB.W	D3,D0
	MOVE.W	D0,lateralRoadPosition
	MOVE.W	lbW00D4F8,lbW00D410
	MOVE.W	segmentSlopeFlags,segmentTargetAngle
	RTS

lbC04D7CE:
	JSR	lbC04DCDA
	MOVE.B	#$B5,curveMagnitude
	MOVE.W	lateralVelocity,D0
	SUB.W	lbW00D4F8,D0
	MOVE.B	curveMagnitude,D3
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
	MOVE.B	$0007(A5),curveMagnitude
	MOVE.W	lateralVelocity,D0
	ADD.W	lbW00D4F8,D0
	MOVE.B	curveMagnitude,D3
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
	JSR	calculateTrackCoordinatesFromData
	MOVE.W	lateralVelocity,D0
	MOVE.W	lbW00D4F8,D3
	JSR	calculateDivision
	MOVE.W	D0,-(SP)
	JSR	lbC0566E8
	MOVE.W	D0,lbW00D536
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
	MOVE.B	$0008(A5),curveMagnitude
	MOVE.B	curveMagnitude,D3
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
	MOVE.B	currentSegmentIndex,savedSegmentIndex
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
	MOVE.B	savedSegmentIndex,currentSegmentIndex
lbC04D980:
	JSR	lbC04DF5A
	MOVE.B	$000A(A5),D3
	ASL.W	#$08,D3
	MOVE.B	$0009(A5),D3
	SUB.W	lbW00D536,D3
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
	MOVE.W	D0,lbB00D40E
	CMP.W	D4,D0
	BLT	lbC04DA76
	MOVE.B	#$80,lbB00D40E
	MOVE.W	#$0000,D0
lbC04DA76:
	LSR.W	#$08,D0
	ADDQ.B	#$01,D0
	ASL.B	#$01,D0
	MOVE.B	D0,lbB00D4E5
	ASL.B	#$01,D0
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
	TST.B	lbB00D40E
	BPL	lbC04DABE
	ADD.B	trackModeParameter,D3
lbC04DABE:
	MOVE.B	D3,segmentDepthCounter
	AND.W	#$00FF,D3
	MOVE.W	D3,visibilityAccumulator
	RTS

calculateSegmentPhysics:
	MOVE.B	playerSegmentIndex,D1
	MOVE.B	D1,currentSegmentIndex
	JSR	loadTrackSegmentConfiguration
	MOVE.B	#$00,lbB00D49A
	MOVE.B	#$04,D1
lbC04DAEE:
	MOVE.B	D1,trackBoostThresholdCopy
	MOVE.B	playerSegmentIndex,D0
	CMP.B	currentSegmentIndex,D0
	BEQ	lbC04DB18
	MOVE.B	D0,D1
	MOVE.B	D1,currentSegmentIndex
	JSR	loadTrackSegmentConfiguration
	MOVE.B	trackBoostThresholdCopy,D1
lbC04DB18:
	MOVE.B	segmentOrientationPrimary,curveMagnitude
	MOVE.L	#wheelCornerXFrontLeft,A1
	MOVE.W	$00(A1,D1.W),D0
	ASR.W	#$04,D0
	ADD.W	lateralRoadPosition,D0
	CMP.W	#$0180,D0
	BCS	lbC04DB5E
	BSET	#$07,networkSyncBitFlag
	MOVE.W	D0,lbW00D522
	BMI	lbC04DB56
	MOVE.B	#$FF,D0
	BRA	lbC04DB86

lbC04DB56:
	MOVE.B	#$00,D0
	BRA	lbC04DB86

lbC04DB5E:
	TST.W	D0
	BPL	lbC04DB66
	NEG.W	D0
lbC04DB66:
	MOVE.B	curveMagnitude,D3
	ASL.W	#$07,D3
	BCLR	#$0F,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	CMP.W	#$0100,D0
	BLT	lbC04DB86
	MOVE.B	$000000FF,D0
lbC04DB86:
	MOVE.B	D0,previousIndexBackup
	TST.B	reverseDirectionFlag
	BPL	lbC04DB9A
	EOR.B	#$FF,D0
lbC04DB9A:
	CMP.B	#$04,D1
	BNE	lbC04DBA8
	MOVE.B	D0,lbB00D4A1
lbC04DBA8:
	MOVE.B	segmentOrientationAlternate,curveMagnitude
	MOVE.L	#wheelCornerYFrontLeft,A1
	MOVE.W	$00(A1,D1.W),D0
	ASR.W	#$03,D0
	MOVE.B	curveMagnitude,D3
	ASL.W	#$07,D3
	BCLR	#$0F,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	ADD.W	lbW00D410,D0
	MOVE.W	D0,lbB00D540
	MOVE.B	lbB00D540,D0
	ASL.B	#$01,D0
	MOVE.B	D0,lbB00D4A3
	BMI	lbC04DBF8
	CMP.B	maxSegmentIndex,D0
	BLT	lbC04DBFE
lbC04DBF8:
	JSR	lbC04DD84
lbC04DBFE:
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
	BMI	lbC04DC7E
	MOVE.B	lbB00D4A3,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,interpolationPointsXY1
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,interpolationPointsXY2
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,interpolationPointsXY3
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,interpolationPointsXY4
	ADDQ.B	#$01,D1
	BRA	lbC04DCC6

lbC04DC7E:
	MOVE.B	trackSegmentLimit,D1
	SUB.B	lbB00D4A3,D1
	SUB.B	#$04,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,interpolationPointsXY4
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,interpolationPointsXY3
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,interpolationPointsXY2
	ADDQ.B	#$01,D1
	JSR	getTrackDataPoint
	MOVE.W	D0,interpolationPointsXY1
	ADDQ.B	#$01,D1
lbC04DCC6:
	MOVE.B	trackBoostThresholdCopy,D1
	JSR	lbC04DEF2
	SUBQ.B	#$02,D1
	BPL	lbC04DAEE
	RTS

lbC04DCDA:
	TST.B	trackHeightDifference
	BMI	lbC04DD34
	BTST	#$06,trackHeightDifference
	BNE	lbC04DD12
	MOVE.W	#$0000,D0
	SUB.W	baseCoordinateX,D0
	MOVE.W	D0,lateralVelocity
	MOVE.W	#$0000,D0
	SUB.W	baseCoordinateY,D0
	MOVE.W	D0,lbW00D4F8
	RTS

lbC04DD12:
	MOVE.W	#$0000,D0
	SUB.W	baseCoordinateY,D0
	MOVE.W	D0,lateralVelocity
	MOVE.W	#$0800,D0
	ADD.W	baseCoordinateX,D0
	MOVE.W	D0,lbW00D4F8
	RTS

lbC04DD34:
	BTST	#$06,trackHeightDifference
	BNE	lbC04DD62
	MOVE.W	#$0800,D0
	ADD.W	baseCoordinateX,D0
	MOVE.W	D0,lateralVelocity
	MOVE.W	#$0800,D0
	ADD.W	baseCoordinateY,D0
	MOVE.W	D0,lbW00D4F8
	RTS

lbC04DD62:
	MOVE.W	#$0800,D0
	ADD.W	baseCoordinateY,D0
	MOVE.W	D0,lateralVelocity
	MOVE.W	#$0000,D0
	SUB.W	baseCoordinateX,D0
	MOVE.W	D0,lbW00D4F8
	RTS

lbC04DD84:
	MOVE.B	lbB00D540,D0
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
	MOVE.B	#$00,lbB00D4A3
	TST.B	lbB00D540
	BPL	lbC04DE18
	BMI	lbC04DDF4
lbC04DDDC:
	MOVE.B	trackSegmentLimit,D0
	SUBQ.B	#$04,D0
	MOVE.B	D0,lbB00D4A3
	TST.B	lbB00D540
	BMI	lbC04DE18
lbC04DDF4:
	NEG.B	trackProcessingFlag
	BNE	lbC04DE06
	MOVE.B	#$FF,trackProcessingFlag
lbC04DE06:
	NEG.B	previousIndexBackup
	BNE	lbC04DE18
	MOVE.B	#$FF,previousIndexBackup
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

calculateInterpolatedValue:
	MOVE.B	previousIndexBackup,D3
	AND.W	#$00FF,D3
	MOVE.W	interpolationPointsXY2,D0
	SUB.W	interpolationPointsXY1,D0
	MULS	D3,D0
	MOVE.W	interpolationPointsXY1,D4
	EXT.L	D4
	ASL.L	#$08,D4
	ADD.L	D4,D0
	MOVE.L	D0,D5
	MOVE.W	interpolationPointsXY4,D0
	SUB.W	interpolationPointsXY3,D0
	MULS	D3,D0
	MOVE.W	interpolationPointsXY3,D4
	EXT.L	D4
	ASL.L	#$08,D4
	ADD.L	D4,D0
	MOVE.B	trackProcessingFlag,D3
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
	MOVE.L	D0,currentMenuItemCopy
	RTS

lbC04DEF2:
	JSR	calculateInterpolatedValue
	ASL.B	#$01,D1
	MOVE.L	#carWorldX,A3
	BCLR	#$07,networkSyncBitFlag
	BEQ	lbC04DF12
	JSR	lbC04E108
lbC04DF12:
	MOVE.B	impactSeverity,D0
	CMP.B	#$0A,D0
	BLT	lbC04DF32
lbC04DF20:
	MOVE.L	#carWorldX,A0
	MOVE.L	currentMenuItemCopy,$00(A3,D1.W)
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
	ADD.L	currentMenuItemCopy,D0
	ROXR.L	#$01,D0
	MOVE.L	D0,$00(A3,D1.W)
	LSR.B	#$01,D1
	RTS

lbC04DF5A:
	MOVE.W	lateralVelocity,D0
	JSR	lbC052C5A
	MOVE.L	D0,D4
	MOVE.W	lbW00D4F8,D0
	JSR	lbC052C5A
	ADD.L	D0,D4
	MOVE.W	lbW00D536,D0
	JSR	lbC052C5A
	MOVE.B	trackGeometryTypeIndex,D2
	MOVE.L	#lbL04DFB8,A0
	MOVE.B	$00(A0,D2.W),curveMagnitude
	SUB.L	D0,D4
	LSR.L	#$08,D4
	MOVE.W	D4,D0
	MOVE.B	curveMagnitude,D3
	ASL.W	#$07,D3
	BCLR	#$0F,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	ASR.W	#$04,D0
	ADD.W	D0,lbW00D536
	RTS

calculateTrackCoordinatesFromData:
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
	MOVE.W	baseCoordinateX,lateralVelocity
	ADD.W	D3,lateralVelocity
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateY,lbW00D4F8
	ADD.W	D3,lbW00D4F8
	RTS

lbC04E02E:
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateY,lbW00D4F8
	ADD.W	D3,lbW00D4F8
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateX,lateralVelocity
	SUB.W	D3,lateralVelocity
	ADD.W	#$0800,lateralVelocity
	RTS

lbC04E070:
	BTST	#$06,trackHeightDifference
	BNE	lbC04E0C6
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateX,lateralVelocity
	SUB.W	D3,lateralVelocity
	ADD.W	#$0800,lateralVelocity
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateY,lbW00D4F8
	SUB.W	D3,lbW00D4F8
	ADD.W	#$0800,lbW00D4F8
	RTS

lbC04E0C6:
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateY,lbW00D4F8
	SUB.W	D3,lbW00D4F8
	ADD.W	#$0800,lbW00D4F8
	MOVE.B	$01(A5,D2.W),D3
	ASL.W	#$08,D3
	MOVE.B	$00(A5,D2.W),D3
	ADDQ.B	#$02,D2
	MOVE.W	baseCoordinateX,lateralVelocity
	ADD.W	D3,lateralVelocity
	RTS

lbC04E108:
	MOVE.W	lbW00D522,D0
	BMI	lbC04E120
	MOVE.W	#$0180,D0
	SUB.W	lbW00D522,D0
	BPL	lbC04E122
lbC04E120:
	NEG.W	D0
lbC04E122:
	CMP.W	#$0030,D0
	BGT	lbC04E172
	AND.L	#$000000FF,D0
	ASL.L	#$04,D0
	MOVE.L	currentMenuItemCopy,D3
	SUB.L	D0,D3
	SUB.L	#$00000100,D3
	CMP.L	#$00001000,D3
	BLT	lbC04E172
	MOVE.L	D3,currentMenuItemCopy
	MOVE.B	lbW00D522,D3
	MOVE.B	reverseDirectionFlag,D0
	EOR.B	D3,D0
	AND.B	#$80,D0
	BMI	lbC04E16A
	MOVE.B	#$40,D0
lbC04E16A:
	MOVE.B	D0,wheelBouncePhaseAccumulator
	RTS

lbC04E172:
	MOVE.L	#$00001000,currentMenuItemCopy
	MOVE.B	lbB00D49A,D0
	LSR.B	#$01,D0
	BSET	#$07,D0
	MOVE.B	D0,lbB00D49A
	RTS

loadMenuDataToRAM:
	MOVE.W	#$0000,imageMenuScreenPalette
	MOVE.W	#$00FF,D0
	MOVE.L	#playerNamesWithSpaces,A0
	MOVE.L	#memory_7A91A,A1
copyPlayerNamesLoop:
	MOVE.B	(A0)+,(A1)+
	DBRA	D0,copyPlayerNamesLoop
	MOVE.L	#divider,A0
	MOVE.L	#memory_7A61A,A1
	MOVE.L	#memory_7A71A,A2
	CLR.W	D1
	CLR.W	D2
copyDividerLoop:
	MOVE.B	$00(A0,D2.W),$00(A1,D1.W)
	MOVE.B	$00(A0,D2.W),$00(A2,D1.W)
	SUBQ.B	#$01,D2
	BPL	dividerIndexOk
	MOVE.B	#$0F,D2
dividerIndexOk:
	SUBQ.B	#$01,D1
	BNE	copyDividerLoop
	TST.B	skipSaveSlotScreen
	BNE	lbC04E826
	JSR	renderSlotGraphicsAtPosition
;	BRA	installLineEmulatorTrap
;
;installLineEmulatorTrap:
;	MOVE.L	#$9CEDCD02,D0
;	MOVE.L	D0,$24
;	BRA	cleanupInitializationAndStartGame
;
;cleanupInitializationAndStartGame:
	JSR	finalizeGraphicsRendering
	BRA	validateSaveDataChecksum

finalizeGraphicsRendering:
	BTST	#DMAB_BLITTER,_custom+dmaconr
	BNE	finalizeGraphicsRendering
	OR.B	#CIAF_DSKSEL0,_ciab+ciaprb
	MOVE.W	#(DMAF_DISK|DMAF_BLITTER|DMAF_BLITHOG),_custom+dmacon
	CLR.W	D1
	CLR.W	D2
	MOVE.B	#$00,lbB00D494
	JMP	initializeCIA

validateSaveDataChecksum:
	MOVE.L	D0,lbL0563EC		; Store return value from initializeCIA
	MOVE.L	memory_7A21A,D0		; Load value from save slot data
	ADD.L	memory_7A416,D0		; Add value from offset +508 bytes
	MOVE.L	lbL04E82C,D3		; Load stored checksum seed
	EOR.L	D3,D0			; XOR sum with seed
	MOVE.L	D0,lbL04E82C		; Store new checksum
	MOVE.B	#$80,skipSaveSlotScreen
	CLR.W	D1
	CLR.W	D2
lbC04E826:
;	JMP	enterMenuSystemLoop

enterMenuSystemLoop:
	MOVE.W	#$00FF,D0
	MOVE.L	#playerNamesWithSpaces,A0
	MOVE.L	#memory_7A91A,A1
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
	BCLR	#$07,raceMode		; Clear race active bit
	MOVE.B	#$10,gameStateID	; Menu state
	JSR	handleMainMenu		; Display and handle menu input
	TST.B	selectedRaceType		; Check for game start
	BMI	gameStateTransition	; Transition to race if set
	MOVE.B	#$12,gameStateID	; Otherwise, show intermediate screens and loop back
	JSR	displayTrackPreviewBackground
	MOVE.B	#$00,gameStateID
	JSR	loadMainGameScreen
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
	CLR.B	raceFlag1
	CLR.B	raceFlag2
lbC04E968:
	MOVE.B	selectedTrack,displayTrackID
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
	JSR	setupGameplayDisplay
	JSR	checkRaceStartReady
	BEQ	lbC04E900
	MOVE.B	#$00,D0
	JSR	displayRacePositions
	MOVE.B	#$12,gameStateID
	JSR	displayTrackPreviewBackground
	MOVE.B	#$80,D0
	JSR	transmitNetworkMessage
	MOVE.B	#$00,gameStateID
	JSR	loadMainGameScreen
	MOVE.B	#$80,D0
	JSR	displayRacePositions
	JSR	synchronizeRaceData
	MOVE.B	#$00,D0
	JSR	transmitNetworkMessage
	MOVE.B	#$00,D0
	JSR	transferLapRecords
	JSR	setupRandomRaceParameters
	JSR	displayRaceEndScreen
	JSR	displayMenuScreen
	TST.B	displayFlags
	BEQ	lbC04EA60
	MOVE.B	#$01,gameStateID
	JSR	setupGameplayDisplay
	CLR.B	displayFlags
lbC04EA60:
	MOVE.B	#$02,gameStateID
	JSR	setupGameplayDisplayAlt
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
	JSR	finalizeRaceDisplay
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

displayTrackPreviewBackground:
	JSR	initializeMessageBuffer
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
	MOVE.B	D3,hudDisplayMode1
	MOVE.B	D0,hudDisplayMode2
	JSR	displayTrackHeader
	MOVE.B	#$03,D0
	JSR	setBackgroundColor
debug:	; StuntCarRacer.s:10188
	JSR	initializeSegmentFlags
	MOVE.B	currentTrackID,D1
	JSR	processTrackDataBuffer
	JSR	initializeLookupTables
	JSR	generateDrawBridge
	JSR	loadMountainData
	JSR	generateTrackPreviewData
	JSR	renderTrackPreview
	MOVE.B	#$2C,D1
	JSR	renderLeagueText
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

loadMainGameScreen:
	TST.B	networkGameMode
	BEQ	lbC04EC48
	JSR	networkTimingSync1
	JSR	networkTimingSync1
	JSR	networkHandshakeLoop
	JSR	networkTimingSync2
lbC04EC48:
	MOVE.B	#$00,gameInitFlag1
	MOVE.B	#$00,gameInitFlag2
	JSR	initializeMessageBuffer
	JSR	copyMainGameBackground
	MOVE.L	#imageMainGameBackgroundPalette,A1
	JSR	copyPalette
	MOVE.B	#$0E,D0
	JSR	setForegroundColor
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
	JSR	initializeMultiplayerSettings
	MOVE.B	#$09,D3
	MOVE.B	#$0A,D0
	TST.B	currentPlayerContext
	BEQ	lbC04ECA4
	MOVE.B	#$00,D3
	MOVE.B	#$08,D0
lbC04ECA4:
	MOVE.B	D3,hudDisplayMode1
	MOVE.B	D0,hudDisplayMode2
	JSR	displayHUDText
	MOVE.B	#$0B,D2
	JSR	setupGameDisplay1
	JSR	setupGameDisplay2
	MOVE.B	lbB00E31B,D1
	MOVE.B	D1,opponentSegmentIndex
	MOVE.B	#$04,gameStateCounter
	MOVE.B	#$4C,previousDataIndex
	JSR	initializeTrackCoordinates
	MOVE.B	lbB00E31B,D1
	CMP.B	#$40,networkGameMode
	BNE	initializeGameSystemsAndMainLoop
	MOVE.B	#$80,trackSideIndicator
initializeGameSystemsAndMainLoop:
	JSR	initializeAudioSystem
	JSR	updateWheelSuspensionPosition
	JSR	initializeDebrisParticlePositions
	JSR	processGameFrame
	JSR	updateGameTimingAndDirection
	SUBQ.B	#$01,frameCounter
	JSR	swapDisplayBuffers
	JSR	updateGamePhysics
	JSR	processGameFrame
	JSR	updateGameTimingAndDirection
	SUBQ.B	#$01,frameCounter
	JSR	calculateTrackEffects
	JSR	swapDisplayBuffers
	MOVE.B	#$80,D0
	MOVE.B	D0,frameProcessingFlag
	MOVE.B	D0,displayUpdateFlag
	MOVE.B	#$03,D2
	JSR	delayWithParam
	JSR	animatePaletteToTarget
	MOVE.W	#$8020,gameLoopControl
	JSR	initializeGameLoop
mainGameLoop:
	SUBQ.B	#$01,frameCounter
	JSR	processPlayerInput
	JSR	updateGamePhysics
	JSR	updateEngineAudioPitch
	JSR	processGameFrame
	JSR	generateDrawBridge
	JSR	calculateTrackEffects
	JSR	processGameStatistics
	JSR	updateGameTimingAndDirection
	JSR	updateFrameTimingEffects
	MOVE.B	currentTrackIDs,D0
	AND.B	displayStateFlag,D0
	BPL	continueGameLoop
	TST.B	eventTimerCountdown
	BNE	continueGameLoop
	TST.B	networkGameMode
	BEQ	checkGameEndConditions
	TST.B	networkConnectionState
	BNE	continueGameLoop
checkGameEndConditions:
	TST.B	raceStartTimer
	BNE	lbC04EDFC
	MOVE.B	playerStateFlag,D0
	BEQ	continueGameLoop
lbC04EDFC:
	TST.B	gameEndModeFlag
	BNE	lbC04EE34
	MOVE.B	networkGameMode,D0
	BEQ	lbC04EE22
	MOVE.B	#$00,raceOutcomeFlags
	CMP.B	gameModeStateFlags,D0
	BNE	lbC04EE34
lbC04EE22:
	MOVE.B	#$0B,D2
	JSR	setupGameDisplay2
	MOVE.B	#$C0,raceOutcomeFlags
lbC04EE34:
	JSR	renderMessagePanel
	MOVE.B	#$3C,D2
	MOVE.B	#$04,D0
	JSR	displayGameMessage
	MOVE.W	#$FFF8,enginePitchDelta
	MOVE.B	#$00,wheelSpeed
	CMP.B	#$45,gameTimerCountdown
	BNE	lbC04EE74
	MOVE.B	objectDisplayThreshold,D2
	BEQ	lbC04EE74
	JSR	displayLapCompletionGraphics
lbC04EE74:
	JSR	swapDisplayBuffers
	MOVE.B	#$80,gameExitFlag
	MOVE.B	#$80,gameInitFlag1
	JSR	updateNetworkGameFlags
	JSR	disableAudio
	JSR	waitForDisplaySync
	BRA	lbC04EF74

continueGameLoop:
	JSR	swapDisplayBuffers
	JSR	checkNetworkTimeout
	MOVE.B	raceStartTimer,D0
	BNE	lbC04EF0E
	MOVE.B	collisionStateFlags,D2
	BPL	lbC04EF0E
	MOVE.B	playerStateFlag,D0
	BEQ	lbC04EF0E
	MOVE.B	carHeightPosition,D0
	BMI	lbC04EEDC
	CMP.B	#$02,D0
	BGE	lbC04EEE2
lbC04EEDC:
	MOVE.B	D2,raceCompletionCheckFlag
lbC04EEE2:
	SUBQ.B	#$01,restartTimerCountdown
	BPL	lbC04EF0E
	ADDQ.B	#$01,restartTimerCountdown
	MOVE.B	wreckCountdownTimer,D0
	BNE	lbC04EF0E
	JSR	disableAudio
	MOVE.B	lbB00D49B,D1
	JMP	initializeGameSystemsAndMainLoop

lbC04EF0E:
	TST.B	raceStartTimer
	BNE	lbC04EF2C
	TST.B	collisionStateFlags
	BMI	mainGameLoop
	TST.B	playerStateFlag
	BEQ	mainGameLoop
lbC04EF2C:
	MOVE.B	#$45,D1
	MOVE.B	playerInputState,D0
	JSR	lbC048A00
	BNE	mainGameLoop
	TST.B	gameEndModeFlag
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
	MOVE.W	#$0020,gameLoopControl
	MOVE.W	imageMenuScreenPalette,D0
	JSR	fadeToColor
	MOVE.B	#$00,D0
	MOVE.B	D0,displayUpdateFlag
	JSR	disableAudio
	TST.B	selectedRaceType
	BPL	lbC04F00A
	TST.B	additionalPlayerCount
	BEQ	lbC04F014
	MOVE.B	currentPlayerID,D1
	MOVE.L	#lbL00E336,A0
	MOVE.B	objectDisplayThreshold,$00(A0,D1.W)
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
	MOVE.B	lbB00D4B5,objectDisplayThreshold
lbC04F014:
	JSR	saveRandomState
	MOVE.B	#$80,gameInitFlag1
	RTS

initializeMessageBuffer:
	MOVE.L	#lbW00D3F8,A0
lbC04F02C:
	MOVE.B	#$00,(A0)+
	CMP.L	#segmentProcessedFlags,A0
	BNE	lbC04F02C
	MOVE.L	#H.MSG,A0
	MOVE.L	#lbW00D3F8,A1
	MOVE.B	currentPlayerContext,D1
	MOVE.B	#$00,D2
lbC04F050:
	MOVE.B	$00(A0,D1.W),$00(A1,D2.W)
	ADDQ.B	#$01,D1
	ADDQ.B	#$01,D2
	CMP.B	#$0B,D2
	BNE	lbC04F050
	MOVE.W	#$007F,previousEffectParameter
	MOVE.B	#$BA,wheelBaseHeight
	MOVE.B	#$02,D1
lbC04F076:
	MOVE.B	#$09,D0
	MOVE.L	#playerStatsArray,A1
	MOVE.B	D0,$00(A1,D1.W)
	SUBQ.B	#$01,D1
	BPL	lbC04F076
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
	MOVE.W	#$0400,lbW00D542
	MOVE.W	#$FF00,visualEffectFlags
	JSR	disableAudio
	MOVE.B	#$04,maxLapsForRace
	JSR	lbC054FA2
	MOVE.B	#$3B,lbB053EA5
	MOVE.B	lbB00E32C,D1
	TST.B	currentPlayerContext
	BEQ	lbC04F0FC
	MOVE.B	lbB00E32D,D1
lbC04F0FC:
	MOVE.B	#$00,D0
	MOVE.B	#$01,D3
	ANDI.B	#$0F,CCR
lbC04F108:
	ABCD	D3,D0
	SUBQ.B	#$01,D1
	BNE	lbC04F108
	MOVE.B	D0,lbB00E320
	MOVE.B	D0,lbB00D495
	MOVE.B	objectDisplayThreshold,lbB00D4B5
	MOVE.L	#keyboardState,A0
	MOVE.W	#$007F,D0
lbC04F130:
	MOVE.B	#$00,$00(A0,D0.W)
	DBRA	D0,lbC04F130
	MOVE.L	#memory_3D80,A0
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

initializeMultiplayerSettings:
	TST.B	additionalPlayerCount
	BEQ	lbC04F19C
	MOVE.B	currentPlayerID,D1
	MOVE.L	#lbL00E336,A0
	MOVE.B	$00(A0,D1.W),objectDisplayThreshold
lbC04F19C:
	JMP	initializeGameObjects

processPlayerInput:
	JSR	readControllerInput
	MOVE.B	playerStateFlag,D0
	BEQ	lbC04F1DE
	MOVE.B	raceStartTimer,D0
	BNE	lbC04F1DE
	MOVE.B	inputStateFlags,D0
	AND.B	#$0C,D0
	BEQ	lbC04F1DE
	CMP.B	#$04,D0
	BEQ	lbC04F1DA
	MOVE.B	#$0F,D0
	BNE	lbC04F1DE
lbC04F1DA:
	MOVE.B	#$F1,D0
lbC04F1DE:
	MOVE.B	D0,steeringInputDirection
	MOVE.B	inputStateFlags,D0
	AND.B	#$10,D0
	EOR.B	#$10,D0
	MOVE.B	D0,raceActiveFlag
	MOVE.B	#$00,D2
	MOVE.B	#$00,D1
	MOVE.B	carVelocity,D0
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
	JSR	processEngineAudio
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

checkNetworkTimeout:
	TST.B	networkTimeoutFlag
	BMI	lbC04F2FC
	MOVE.B	#$19,D1
	MOVE.B	lbB00D4A5,D0
	JSR	lbC048A00
	BEQ	lbC04F2FC
	RTS

lbC04F2FC:
	TST.B	networkTimeoutFlag
	BMI	lbC04F310
	MOVE.B	#$80,networkTimeoutFlag
	RTS

lbC04F310:
	MOVE.B	#$00,networkTimeoutFlag
	MOVE.B	#$80,gameInitFlag1
	MOVE.B	#$80,gameInitFlag3
	JSR	disableAudio
	MOVE.W	#$0000,enginePitchDelta
	MOVE.B	lbB00D48E,D0
	MOVE.W	D0,-(SP)
	MOVE.B	gameMessageIndex,D0
	MOVE.W	D0,-(SP)
	MOVE.B	gameMessageMode,D0
	MOVE.W	D0,-(SP)
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	displayFrameBuffer,renderFrameBuffer
	JSR	renderMessagePanel
	MOVE.B	#$4C,D2
	MOVE.B	#$02,D0
	JSR	setMessageParameters
	JSR	updateGameMessageDisplay
	MOVE.L	(SP)+,renderFrameBuffer
	JSR	lbC049486
	MOVE.W	(SP)+,D0
	MOVE.B	D0,gameMessageMode
	MOVE.W	(SP)+,D0
	MOVE.B	D0,gameMessageIndex
	MOVE.W	(SP)+,D0
	MOVE.B	D0,lbB00D48E
	MOVE.B	#$00,gameInitFlag1
	MOVE.B	#$00,gameInitFlag3
initializeGameLoop:
	MOVE.B	#$07,D0
	JSR	playAudioSample
	JSR	updateEngineAudioPitch
	RTS

swapDisplayBuffers:
	TST.B	framesToWait
	BNE	swapDisplayBuffers
	EOR.B	#$01,bufferSelector
	MOVE.B	bufferSelector,D0
	ADD.B	#$05,D0
	MOVE.B	#$00,framesToWait	; fixed 06
	MOVE.L	frameBuffers,D0
	MOVE.L	D0,D3
	MOVE.B	displayStateFlag,D4
	EOR.B	#$80,D4
	MOVE.B	D4,displayStateFlag
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
.wait:	tst.b   copperlistUpdatePendingFlag	; fixed
	bmi	.wait
	RTS

updateGameTimingAndDirection:
	ADDQ.B	#$01,gameTimingCounter	; Increment frame counter
	MOVE.B	#$00,D2			; Assume forward direction
	MOVE.B	#TIMESTEP_FACTOR,D0			; Direction adjustment value
	BEQ	lbC04F452		; Skip if zero
	ADD.B	D0,directionCalculation	; Add to direction accumulator
	BCS	lbC04F452		; If carry, direction is forward
	SUBQ.B	#$01,D2			; Otherwise $FF = reverse
lbC04F452:
	MOVE.B	D2,trackDirectionFlag	; Store direction flag
	MOVE.B	eventTimerCountdown,D0
	BEQ	lbC04F472		; Skip if no event pending
	SUBQ.B	#$01,eventTimerCountdown	; Decrement countdown
	BNE	lbC04F472		; Skip if not yet zero
	JSR	handleGameStateChange	; Trigger state change when reaches zero
lbC04F472:
	TST.B	selectedRaceType
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
	BPL	lbC04F4D6
	JSR	lbC04F4D6
lbC04F4D6:
	MOVE.B	wreckCountdownTimer,D0
	BEQ	lbC04F536		; Exit if no countdown active
	BMI	lbC04F526		; Handle expired countdown
	LSR.B	#$02,D0			; Divide by 4
	AND.B	#$01,D0			; Get LSB (blink state)
	MOVE.B	D0,wreckBlinkFlag
	TST.B	raceStartTimer
	BNE	lbC04F512
	MOVE.B	playerStateFlag,D0
	BNE	lbC04F512
	MOVE.B	wreckCountdownTimer,D0
	CMP.B	#$06,D0
	BCS	lbC04F536
lbC04F512:
	TST.B	trackDirectionFlag
	BMI	lbC04F536
	SUBQ.B	#$01,wreckCountdownTimer
	BNE	lbC04F536
lbC04F526:
	MOVE.B	#$80,D0
	MOVE.B	D0,currentTrackIDs
	MOVE.B	D0,wreckCountdownTimer
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

handleGameStateChange:
	MOVE.B	D1,D0
	MOVE.B	D0,-(SP)
	JSR	processGameStateTransition
	MOVE.B	#$02,D2
	MOVE.B	#$03,D1
	MOVE.B	#$80,D0
	JSR	applyGameStateParameters
	MOVE.B	(SP)+,D0
	MOVE.B	D0,D1
	RTS

checkLapCompletion:
	TST.B	D1
	BNE	lbC04F5DA
	BTST	#$06,collisionStateFlags
	BNE	lbC04F602
lbC04F5DA:
	MOVE.L	#playerSegmentIndex,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#lapCrossingDetectionFlag,A1
	MOVE.B	$00(A1,D1.W),D2
	BPL	lbC04F604
	CMP.B	finishLineSegmentIndex,D0
	BNE	lbC04F602
	MOVE.B	#$00,$00(A1,D1.W)
lbC04F602:
	RTS

lbC04F604:
	CMP.B	startingSegmentIndex,D0
	BNE	lbC04F602
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
	JSR	swapPlayerContextForNetwork
	TST.B	D1
	BNE	lbC04F6D6
	MOVE.B	player1LapCounter,D0
	CMP.B	#$01,D0
	BEQ	lbC04F680
	JSR	updateRaceRecords
	MOVE.B	#$1B,D0
	MOVE.B	D0,eventTimerCountdown
	JSR	updateRaceTimerDisplay
	JSR	saveLapTimeToBuffer
lbC04F680:
	MOVE.B	D1,savedPlayerIndex
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
	MOVE.B	savedPlayerIndex,D1
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
	MOVE.B	D0,raceResultFlag
	BEQ	lbC04F714
	MOVE.B	#$00,eventTimerCountdown
	JSR	handleGameStateChange
lbC04F714:
	JSR	clearGameDataSlot
	RTS

checkRaceCompletion:
	MOVE.W	#$0001,D1
lbC04F720:
	TST.B	gameEndModeFlag
	BNE	lbC04F798
	MOVE.L	#player1LapCounter,A1			; Lap counter array
	MOVE.B	$00(A1,D1.W),D0			; Get player's lap count
	CMP.B	maxLapsForRace,D0			; Compare with max laps (typically 4)
	BNE	lbC04F798			; Skip if not finished
	MOVE.B	D0,gameEndModeFlag		; Set race end flag
	MOVE.B	wreckCountdownTimer,D0
	BNE	lbC04F758
	MOVE.B	#$2C,D0
	MOVE.B	D0,wreckCountdownTimer
lbC04F758:
	MOVE.W	D1,-(SP)
	JSR	setupRaceDisplayMode
	MOVE.W	(SP)+,D1
	CMP.W	#$000B,D2
	BEQ	lbC04F780
	MOVE.B	#$54,D2
	TST.B	selectedRaceType
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
	OR.B	raceResultFlag,D0
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

updateRaceTimerDisplay:
	MOVE.B	D1,D0
	MOVE.B	D0,-(SP)
	MOVE.B	#$02,D1
	MOVE.B	#$00,D2
	MOVE.B	eventTimerCountdown,D0
	BEQ	lbC04F7EA
	MOVE.B	#$80,D0
lbC04F7EA:
	JSR	applyGameStateParameters
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
	move.b	framesSinceCopperlistUpdate,d0	; fixed
	add.b	d0,d0
	;MOVE.B	#$13,D0			; Add 19 milliseconds
lbC04F832:
	MOVE.L	#lapTimeSubseconds,A0
	MOVE.L	#lapTimeSeconds,A1
	MOVE.L	#playerStatsArray,A2
	ANDI.B	#$0F,CCR
	MOVE.B	$00(A0,D1.W),D3
	ABCD	D3,D0			; BCD add to subseconds
	BCC	lbC04F8AE
	MOVE.B	D0,$00(A0,D1.W)		; Store updated subseconds
	MOVE.B	$00(A1,D1.W),D0		; Load seconds
	MOVE.B	#$00,D3
	ABCD	D3,D0			; Carry into seconds
	MOVE.B	D0,$00(A1,D1.W)
	CMP.B	#$60,D0			; Check if >= 60 seconds
	BCS	lbC04F88C		; Skip if < 60
	MOVE.B	#$00,$00(A1,D1.W)	; Reset seconds to 0
	ANDI.B	#$0F,CCR
	MOVE.B	$00(A2,D1.W),D0
	MOVE.B	#$01,D3
	ABCD	D3,D0			; Increment minutes
	CMP.B	#$0A,D0			; Check if >= 10 minutes
	BGE	lbC04F88C		; Don't overflow
	MOVE.B	D0,$00(A2,D1.W)		; Store minutes
lbC04F88C:
	TST.B	D1
	BNE	lbC04F8AC
	TST.B	eventTimerCountdown
	BNE	lbC04F8AC
	TST.B	player1LapCounter
	BEQ	lbC04F8AC
	JSR	updateRaceTimerDisplay
lbC04F8AC:
	RTS

lbC04F8AE:
	MOVE.B	D0,$00(A0,D1.W)
	RTS

processGameStatistics:
	MOVE.B	offTrackAccumulationFlag,D0
	BEQ	lbC04F8E0
	MOVE.B	accumulatedOffTrackForceX,D0
	ADD.B	accumulatedOffTrackForceY,D0
	ROXR.B	#$01,D0
	ADD.B	accumulatedOffTrackForceZ,D0
	ROXR.B	#$01,D0
	MOVE.B	D0,performanceStylePoints
	JSR	updatePerformanceMetrics
lbC04F8E0:
	MOVE.B	gameTimerCountdown,D0
	BEQ	lbC04F916
	SUBQ.B	#$01,gameTimerCountdown
	CMP.B	#$45,D0
	BEQ	triggerLapCompletion
	MOVE.B	offTrackAccumulationFlag,D0
	BNE	lbC04F95C
	RTS

triggerLapCompletion:
	MOVE.B	objectDisplayThreshold,D2
	JSR	displayLapCompletionGraphics
	JMP	lbC04F95C

lbC04F916:
	MOVE.B	offTrackAccumulationFlag,D0
	BEQ	lbC04F996
	MOVE.W	maxDistanceFromTrack,D0
	CMP.W	#$1400,D0
	BCS	lbC04F95C
	MOVE.B	objectDisplayThreshold,D2
	BEQ	lbC04F95C
	SUBQ.B	#$01,D2
	MOVE.B	D2,objectDisplayThreshold
	JSR	displayLapCounterGraphics
	MOVE.B	#$45,D0
	MOVE.B	D0,gameTimerCountdown
	MOVE.B	#$0A,D0
	MOVE.B	#$05,D0
	BNE	lbC04F986
lbC04F95C:
	MOVE.B	maxDistanceFromTrack,D0
	CMP.B	#$07,D0
	BCC	lbC04F96E
	MOVE.B	#$07,D0
lbC04F96E:
	ASL.B	#$02,D0
	CMP.B	#$40,D0
	BCS	lbC04F97C
	MOVE.B	#$40,D0
lbC04F97C:
	MOVE.B	D0,audioSample4Volume
	MOVE.B	#$04,D0
lbC04F986:
	JSR	playAudioSample
	MOVE.B	#$00,D0
	MOVE.B	D0,offTrackAccumulationFlag
lbC04F996:
	RTS

processGameStateTransition:
	MOVE.B	#$0B,D2
	MOVE.B	raceResultFlag,D0
	BNE	setupGameDisplay2
	MOVE.B	#$07,D2
setupGameDisplay2:
	MOVE.B	D2,displayModeFlag2
	MOVE.B	#$11,D0
	CMP.B	#$07,D2
	BEQ	lbC04F9C0
	MOVE.B	#$12,D0
lbC04F9C0:
	BRA	lbC04F9EC

setupRaceDisplayMode:
	MOVE.B	#$0B,D2
	JSR	validateGameState
	BPL	setupGameDisplay1
	MOVE.B	#$07,D2
setupGameDisplay1:
	MOVE.B	D2,displayModeFlag1
	MOVE.B	#$0F,D0
	CMP.B	#$07,D2
	BEQ	lbC04F9EC
	MOVE.B	#$10,D0
lbC04F9EC:
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

updateFrameTimingEffects:
	MOVE.B	frameCounter,D0
	AND.B	#$03,D0
	BEQ	lbC04FA3A
	RTS

lbC04FA3A:
	MOVE.B	#$00,D1
	MOVE.B	D1,D5
	MOVE.B	#$00,D2
	MOVE.W	carRenderDistance,D0
	MOVE.W	D0,D3
	LSR.W	#$02,D3
	ADD.W	D3,D0
	LSR.W	#$02,D0
	JMP	lbC04FA5E

lbC04FA58:
	SUB.W	#$03E8,D0
	ADDQ.B	#$01,D5
lbC04FA5E:
	CMP.W	#$03E8,D0
	BGE	lbC04FA58
	JMP	lbC04FA72

lbC04FA6C:
	SUB.W	#$0064,D0
	ADDQ.B	#$01,D2
lbC04FA72:
	CMP.W	#$0064,D0
	BGE	lbC04FA6C
	JMP	lbC04FA86

lbC04FA80:
	SUB.B	#$0A,D0
	ADDQ.B	#$01,D1
lbC04FA86:
	CMP.B	#$0A,D0
	BGE	lbC04FA80
	MOVE.B	D0,currentMenuItemCopy
	MOVE.B	D1,curveMagnitude
	MOVE.B	D2,savedSegmentIndex
	MOVE.B	D5,speedDisplayThousands
	MOVE.B	#$01,textHorizontalOffset
	MOVE.B	#$04,textYOffset
	MOVE.B	#$1F,D0
	JSR	renderCharacter
	MOVE.B	#$06,D0
	JSR	renderCharacter
	MOVE.B	#$17,D0
	JSR	renderCharacter
	MOVE.B	#$F0,D0
	TST.B	carCrashedFlag
	BPL	lbC04FAE6
	MOVE.B	#$FD,D0
lbC04FAE6:
	JSR	renderDigitAndAdvance
	MOVE.B	speedDisplayThousands,D0
	JSR	renderDigitAndAdvance
	MOVE.B	savedSegmentIndex,D0
	JSR	renderDigitAndAdvance
	MOVE.B	curveMagnitude,D0
	JSR	renderDigitAndAdvance
	MOVE.B	currentMenuItemCopy,D0
	JSR	renderDigitAndAdvance
	MOVE.B	#$00,textHorizontalOffset
	MOVE.B	#$00,textYOffset
	TST.B	gameEndModeFlag
	BNE	lbC04FB3C
	JSR	setupRaceDisplayMode
lbC04FB3C:
	RTS

calculateTrackEffects:
	MOVE.W	carVelocity,D0
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
	MOVE.W	D0,trackEffectParameter
	SUB.W	previousEffectParameter,D0
	BNE	lbC04FB7C
	JMP	lbC04FC1A

lbC04FB7C:
	MOVE.L	frameBuffers,A6
	ADD.L	#$00001B3C,A6
	MOVE.W	previousEffectParameter,D4
	MOVE.W	trackEffectParameter,D5
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
	JSR	lbC057E76
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
	MOVE.W	trackEffectParameter,previousEffectParameter
	RTS

applyGameStateParameters:
	MOVE.B	D2,lbB00D4E8
	MOVE.B	D0,lbB00D489
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
	MOVE.B	lbB00D4E8,D2
	MOVE.L	#lapTimeSeconds,A2
	MOVE.B	$00(A2,D2.W),D0
	LSR.B	#$04,D0
	JSR	renderDigit
	MOVE.B	lbB00D4E8,D2
	MOVE.L	#lapTimeSeconds,A2
	MOVE.B	$00(A2,D2.W),D0
	AND.B	#$0F,D0
	JSR	renderDigit
	ADDQ.B	#$04,textHorizontalOffset
	MOVE.B	lbB00D4E8,D2
	MOVE.L	#lapTimeSubseconds,A2
	MOVE.B	$00(A2,D2.W),D0
	LSR.B	#$04,D0
	TST.B	lbB00D489
	BMI	lbC04FD2C
	MOVE.B	#$F0,D0
lbC04FD2C:
	JSR	renderDigit
	MOVE.B	lbB00D4E8,D2
	MOVE.L	#lapTimeSubseconds,A2
	MOVE.B	$00(A2,D2.W),D0
	AND.B	#$0F,D0
	TST.B	lbB00D489
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
	MOVE.B	#$80,lbB00D48E
	MOVE.B	D2,gameMessageIndex
	MOVE.B	D0,gameMessageMode
	RTS

displayGameMessage:
	JSR	setMessageParameters
updateGameMessageDisplay:
	TST.B	lbB00D48E
	BMI	lbC04FE14
lbC04FE12:
	RTS

lbC04FE14:
	MOVE.B	wreckCountdownTimer,D0
	BEQ	lbC04FE36
	BMI	lbC04FE2A
	CMP.B	#$03,D0
	BGE	lbC04FE36
lbC04FE2A:
	CMP.B	#$3C,gameMessageIndex
	BNE	lbC04FE12
lbC04FE36:
	TST.B	networkTimeoutFlag
	BMI	lbC04FE12
	MOVE.B	#$80,textTransparencyMode
	MOVE.B	#$80,singleBufferRenderMode
	MOVE.B	#$00,D0
	TST.B	wreckBlinkFlag
	BEQ	lbC04FE62
	MOVE.B	#$0F,D0
lbC04FE62:
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
	TST.W	carVelocity
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
	MOVE.L	#clampedDistanceX,A0
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
	MOVE.B	wreckCountdownTimer,D0
	BNE	lbC0501AA
	CMP.B	#$40,gameModeStateFlags
	BEQ	lbC050174
	CMP.B	#$80,gameModeStateFlags
	BEQ	lbC050174
	MOVE.B	networkGameMode,gameModeStateFlags
lbC050174:
	MOVE.B	#$02,D0
	MOVE.B	D0,postWreckStateFlag
	MOVE.B	#$92,D0
	MOVE.B	D0,wheelBaseHeight
	MOVE.B	#$82,D0
	MOVE.B	D0,visualEffectFlags
	MOVE.B	#$3C,D0
	MOVE.B	D0,wreckCountdownTimer
	MOVE.B	#$02,D0
	MOVE.B	#$00,D2
	JSR	setMessageParameters
lbC0501AA:
	RTS

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
	JSR	screenUpdate
	JMP	gameModeSelected

addMultiplayerPlayers:
	MOVE.B	#$00,D0			; Initialize menu option
	MOVE.B	#$01,D2			; Menu parameter 2
	MOVE.B	#$14,D1			; Menu ID $14 ("Add another player?" prompt)
	JSR	displayMenu		; Display menu and get user choice
	CMP.B	#$00,D0			; Check if option 0 selected
	BNE	lbC05021A		; Exit if other option chosen
	ADDQ.B	#$01,additionalPlayerCount	; Increment player count
gameModeMultiplayer:
	JSR	screenUpdate		; Update display
	MOVE.B	additionalPlayerCount,D0
	CMP.B	#$07,D0			; Check if < 7 players
	BCS	addMultiplayerPlayers	; Loop back to add more
lbC05021A:
	MOVE.B	additionalPlayerCount,D0
	BEQ	addMultiplayerPlayers	; If 0 players, force selection
gameModeSelected:
	MOVE.B	#$00,D0
	MOVE.B	D0,textRenderingFlag
	RTS

gameModeComputerLink:
	JSR	establishComputerLink
	BCS	selectGameMode
	BRA	gameModeSelected

displayLeagueRaceResults:
	JSR	sortRaceResults		; Sort race standings
	MOVE.B	#$10,D0
	MOVE.B	D0,displayColumnOffset		; Set display offset
	MOVE.B	#$0E,D0
	MOVE.B	D0,DRIVERBESTLAP.MSG	; Set column position
	MOVE.B	multiplayerRaceDisplayFlag,D0		; Load multiplayer race flag
	AND.B	standingsDisplayModeFlag,D0		; AND with display mode flag
	BPL	lbC050324		; If either not negative, use simple mode
	JSR	drawScreenFrame		; === FULL LEAGUE STANDINGS DISPLAY PATH ===
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
	MOVE.B	additionalPlayerCount,D1	; Calculate position based on division:
	MOVE.L	#divisionRowPositions,A1
	MOVE.B	$00(A1,D1.W),D0		; Get row position
	MOVE.B	D0,D2
	ADDQ.B	#$02,D0
	MOVE.B	D0,displayColumnOffset
	JSR	renderTrackInfoDisplay	; Display "Track: The [NAME]"
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
	JSR	lbC05088E
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
	MOVE.B	D0,DRIVERBESTLAP.MSG
	ADDQ.B	#$02,D0
	MOVE.B	additionalPlayerCount,D2
	CMP.B	#$07,D2
	BNE	lbC050318
	SUBQ.B	#$01,D0
lbC050318:
	MOVE.B	D0,displayColumnOffset
	JMP	lbC050384

lbC050324:				; === SIMPLE RESULTS DISPLAY PATH ===
	JSR	setupDisplayMode
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	TST.B	multiplayerRaceDisplayFlag		; Check multiplayer flag
	BMI	lbC05037A
	MOVE.B	#$86,D1			; Display league header:
	JSR	renderLeagueText	; "DRIVERS CHAMPIONSHIP" or similar
	CMP.B	#$03,raceSeriesCounter		; Check race series counter
	BCS	lbC050398
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	JSR	setTextYOffset4
	MOVE.B	#$13,D1
	JSR	renderStatsText		; "FINAL SEASON"
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
	JSR	lbC056412
lbC0503B0:
	JSR	lbC0503C8
	ADDQ.B	#$01,displayRowOffset
	JSR	lbC056018
	BNE	lbC0503B0
	RTS

lbC0503C8:
	MOVE.B	#$05,D1
	MOVE.B	displayRowOffset,D2
	JSR	setTextPosition
	ADDQ.B	#$01,currentMenuItem
	RTS

renderTrackInfoDisplay:
	MOVE.B	D2,lbB050474		; Save Y coordinate
	MOVE.B	currentTrackID,D1	; Get track ID (0-7)
	MOVE.L	#trackDisplayYOffsets,A0	; Point to Y offset lookup table
	MOVE.B	$00(A0,D1.W),D1		; Load Y offset for this track
	SUBQ.B	#$06,D1			; Adjust Y (-6 pixels)
	TST.B	additionalPlayerCount		; Check if in league mode
	BEQ	lbC05040E		; Skip adjustment if not
	TST.B	currentPlayerContext	; Check if player 2 context
	BEQ	lbC05040E		; Skip if player 1
	SUBQ.B	#$02,D1			; Further adjust Y (-2 more pixels)
lbC05040E:
	JSR	setTextPosition		; Set cursor position (X=D1, Y=D2)
	MOVE.B	#$0F,D0			; Color $0F (white)
	JSR	setBackgroundColor	; Set text background
	MOVE.B	#$93,D1			; String offset $93 = "Track:  The "
	JSR	renderMenuString	; Render prefix text
	MOVE.B	currentTrackID,D1	; Get track ID again
	JSR	renderTrackName		; Render track name (e.g., "LITTLE RAMP")
	MOVE.B	additionalPlayerCount,D0	; Check league mode
	BEQ	lbC050462		; Skip if not in league
	MOVE.B	currentPlayerContext,D0	; Check player context
	BEQ	lbC050462		; Skip if player 1
	MOVE.B	#$21,D1			; X = $21 (33 decimal)
	MOVE.B	lbB050474,D2		; Restore saved Y coordinate
	JSR	setTextPosition		; Position cursor
	MOVE.B	#$63,D1			; String offset $63 = " S."
	JSR	renderMenuString	; Render opponent indicator
lbC050462:
	RTS

lbC050576:
	JSR	renderCharacter
	ADDQ.B	#$01,D1
renderStatsText:
	MOVE.L	#TRACKBONUSPOI.MSG,A1
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
	JSR	lbC0506EE
	MOVE.B	#$2E,D0
	JSR	renderCharacter
	MOVE.L	#lapTimeSubseconds,A1
	MOVE.B	$00(A1,D1.W),D0
	JMP	lbC0506EE

lbC0506A4:
	MOVE.B	#$2D,D0
	MOVE.B	#$07,D2
lbC0506AC:
	JSR	renderCharacter
	SUBQ.B	#$01,D2
	BNE	lbC0506AC
	RTS

lbC0506BA:
	MOVE.B	D0,-(SP)
	JSR	lbC05082E
	MOVE.B	(SP)+,D0
	JMP	renderDecimal

lbC0506CA:
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
lbC0506EE:
	MOVE.B	D0,-(SP)
	LSR.B	#$04,D0
	JSR	renderDigit
lbC0506F8:
	MOVE.B	(SP)+,D0
	AND.B	#$0F,D0
lbC0506FE:
	JMP	renderDigit

lbC050704:
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
	MOVE.B	D1,curveMagnitude
	MOVE.B	D1,D0
	MOVE.B	selectedTrack,D2
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
	MOVE.L	#lbL04C442,A0
	MOVE.L	#memory_7A9FA,A1
	MOVE.L	#engineCharacteristics,A2
	MOVE.L	#memory_7A91A,A3
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
	MOVE.B	curveMagnitude,D1
	SUBQ.B	#$01,D1
	BPL	lbC050782
	MOVE.B	additionalPlayerCount,D1
	ADDQ.B	#$01,D1
lbC050814:
	MOVE.B	D1,raceCount
	MOVE.B	#$00,raceSeriesProgress
	RTS

lbC050824:
	MOVE.B	#$20,D0
	JSR	renderCharacter
lbC05082E:
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

lbC05088E:
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
	MOVE.B	#$0E,D0
	MOVE.B	D0,currentMenuItem
	MOVE.B	#$00,menuCursorObjectType
	MOVE.B	#$03,D0
	JSR	lbC056412
	MOVE.B	#$23,D1
	JSR	renderStatsText
	MOVE.B	raceFlag2,D1
	BEQ	lbC0508E2
	MOVE.L	#lbL00E2DE,A1
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
	MOVE.B	raceFlag1,D1
	BEQ	lbC050922
	MOVE.L	#lbL00E2EA,A1
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
	MOVE.L	#networkTransferBuffer,A0
	MOVE.L	#memory_7A01A,A1
	MOVE.W	#$00BF,D0
	TST.B	networkSyncStateFlag
	BNE	lbC05096C
lbC050964:
	MOVE.B	(A0)+,(A1)+
	DBRA	D0,lbC050964
	RTS

lbC05096C:
	MOVE.B	(A1)+,(A0)+
	DBRA	D0,lbC05096C
	RTS

lbC050974:
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
	JSR	lbC056412
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
	MOVE.B	D0,raceFlag1
lbC050A88:
	MOVE.B	#$0E,D2
	JSR	compareAndCopyPlayerStats
	BCS	lbC050AB0
	MOVE.B	#$C9,D2
	JSR	lbC050B1E
	MOVE.B	displayFlags,D0
	OR.B	#$41,D0
	MOVE.B	D0,displayFlags
lbC050AB0:
	MOVE.B	currentPlayerID,D2
	JSR	compareAndCopyPlayerStats
	ADD.B	#$0C,D2
	JSR	lbC050704
	MOVE.B	player1LapCounter,D0
	CMP.B	#$04,D0
	BNE	lbC050B1A
	MOVE.B	D2,D0
	MOVE.B	D0,D1
	MOVE.B	#$0D,D2
	JSR	compareAndCopyPlayerStats
	BCS	lbC050AF2
	MOVE.B	currentPlayerID,D0
	MOVE.B	D0,raceFlag2
lbC050AF2:
	MOVE.B	#$0F,D2
	JSR	compareAndCopyPlayerStats
	BCS	lbC050B1A
	MOVE.B	#$D6,D2
	JSR	lbC050B1E
	MOVE.B	displayFlags,D0
	OR.B	#$81,D0
	MOVE.B	D0,displayFlags
lbC050B1A:
	MOVE.W	(SP)+,D1
	RTS

lbC050B1E:
	MOVE.W	D1,-(SP)
	MOVE.B	currentPlayerID,D0
	ASL.B	#$04,D0
	MOVE.B	D0,D1
	MOVE.B	#$0C,D0
	MOVE.B	D0,temp
lbC050B34:
	MOVE.L	#playerNames,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#SELECTSingleP.MSG,A2
	MOVE.B	D0,$00(A2,D2.W)
	ADDQ.B	#$01,D1
	ADDQ.B	#$01,D2
	SUBQ.B	#$01,temp
	BNE	lbC050B34
	MOVE.W	(SP)+,D1
	RTS

transferLapRecords:
	MOVE.B	D0,temp
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
	TST.B	temp
	BMI	lbC050C02
lbC050B90:
	MOVE.L	#lbL050548,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.L	#memory_7A61A,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.L	#Newtrackrecor.MSG,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.L	#memory_7A71A,A1
	MOVE.B	D0,$00(A1,D1.W)
	ADDQ.B	#$01,D1
	ADDQ.B	#$01,D2
	CMP.B	#$0C,D2
	BNE	lbC050B90
	MOVE.L	#memory_7A61A,A1
	MOVE.B	lbB00E216,$00(A1,D1.W)
	MOVE.B	lbB00E22E,$01(A1,D1.W)
	MOVE.B	lbB00E246,$02(A1,D1.W)
	MOVE.L	#memory_7A71A,A1
	MOVE.B	lbB00E217,$00(A1,D1.W)
	MOVE.B	lbB00E22F,$01(A1,D1.W)
	MOVE.B	lbB00E247,$02(A1,D1.W)
	RTS

lbC050C02:
	MOVE.L	#memory_7A61A,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#lbL050548,A2
	MOVE.B	D0,$00(A2,D2.W)
	MOVE.L	#memory_7A71A,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#Newtrackrecor.MSG,A2
	MOVE.B	D0,$00(A2,D2.W)
	ADDQ.B	#$01,D1
	ADDQ.B	#$01,D2
	CMP.B	#$0C,D2
	BNE	lbC050C02
	MOVE.L	#memory_7A61A,A1
	MOVE.B	$00(A1,D1.W),lbB00E216
	MOVE.B	$01(A1,D1.W),lbB00E22E
	MOVE.B	$02(A1,D1.W),lbB00E246
	MOVE.L	#memory_7A71A,A1
	MOVE.B	$00(A1,D1.W),lbB00E217
	MOVE.B	$01(A1,D1.W),lbB00E22F
	MOVE.B	$02(A1,D1.W),lbB00E247
	RTS

syncMultiplayerRecords:
	MOVE.B	networkSyncStateFlag,D3
	EOR.B	D3,D0
	BNE	lbC050CE8
	MOVE.B	lbB00D494,D0
	BMI	lbC050CE8
	MOVE.B	networkPlayerStateCache,D0
	BMI	lbC050CE8
	BEQ	lbC05094A
	CMP.B	#$40,D0
	BEQ	lbC050CA6
	JMP	lbC0511A8

lbC050CA6:
	MOVE.B	networkSyncStateFlag,D0
	BEQ	lbC050CEA
	MOVE.B	#$00,D1
lbC050CB4:
	MOVE.L	#memory_7A61A,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#networkTransferBuffer,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.L	#memory_7A71A,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#memory_7A51A,A1
	MOVE.B	D0,$00(A1,D1.W)
	SUBQ.B	#$01,D1
	BNE	lbC050CB4
	JSR	lbC05117C
lbC050CE8:
	RTS

lbC050CEA:
	JSR	lbC051192
	BCS	lbC050CE8
	MOVE.L	#networkTransferBuffer,A0
	MOVE.L	#memory_7A61A,A1
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
	MOVE.L	#memory_7A51A,A0
	MOVE.L	#memory_7A71A,A1
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
lbC050DBE:
	MOVE.L	#lbB01066B,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#HALL.MSG,A1
	CMP.B	$00(A1,D1.W),D0
	BNE	lbC050DE4
	SUBQ.B	#$01,D1
	BPL	lbC050DBE
	MOVE.B	#$40,D2
	BNE	lbC050E0A
lbC050DE4:
	MOVE.B	#$01,D1
lbC050DE8:
	MOVE.L	#lbB01066B,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#MP.MSG,A1
	CMP.B	$00(A1,D1.W),D0
	BNE	lbC050E0A
	SUBQ.B	#$01,D1
	BPL	lbC050DE8
	MOVE.B	#$01,D2
lbC050E0A:
	MOVE.B	D2,networkPlayerStateCache
	MOVE.B	networkSyncStateFlag,D0
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
	JSR	lbC050FF2
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

lbC050FEA:
	JSR	renderCharacter
	ADDQ.B	#$01,D1
lbC050FF2:
	MOVE.L	#NOTloadedsave.MSG,A1
	MOVE.B	$00(A1,D1.W),D0
	CMP.B	#$FF,D0
	BNE	lbC050FEA
	RTS

lbC051008:
	MOVE.W	lbW051020,D0
	ASL.W	#$02,D0
	ADD.W	lbW051020,D0
	MOVE.W	D0,lbW051020
	LSR.W	#$02,D0
	RTS

lbC051022:
	MOVE.B	#$00,D0
	JMP	lbC051030

lbC05102C:
	MOVE.B	#$80,D0
lbC051030:
	MOVE.B	D0,currentMenuItem
	MOVE.L	#networkTransferBuffer,rawTrackDataOffset
	MOVE.W	#$683B,lbW051020
	MOVE.B	#$00,D1
lbC05104C:
	JSR	lbC051008
	MOVE.L	#memory_7A81A,A1
	MOVE.B	D0,$00(A1,D1.W)
	ADDQ.B	#$01,D1
	BNE	lbC05104C
	MOVE.B	#$0F,D2
	TST.B	currentMenuItem
	BMI	lbC051086
	MOVE.B	lbB052586,D0
	MOVE.L	rawTrackDataOffset,A0
	MOVE.B	D0,$00(A0,D2.W)
	JMP	lbC051096

lbC051086:
	MOVE.L	rawTrackDataOffset,A0
	MOVE.B	$00(A0,D2.W),D0
	MOVE.B	D0,lbB052586
lbC051096:
	MOVE.B	#$00,D2
	MOVE.L	rawTrackDataOffset,A0
	MOVE.L	#memory_7A81A,A1
	TST.B	currentMenuItem
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
	MOVE.B	D0,currentMenuItemCopy
	MOVE.B	D1,speedDisplayThousands
	MOVE.B	lbB052586,D1
	MOVE.B	$00(A1,D1.W),D0
	ADDQ.B	#$01,lbB052586
	MOVE.B	speedDisplayThousands,D1
	ADDQ.B	#$01,D1
	TST.B	currentMenuItem
	BPL	lbC051110
	CMP.B	currentMenuItemCopy,D1
	BEQ	lbC05111C
	BNE	lbC0510D0
lbC051110:
	CMP.B	currentMenuItemCopy,D0
	BNE	lbC0510D0
	MOVE.B	D1,D0
lbC05111C:
	MOVE.L	rawTrackDataOffset,A0
	MOVE.B	D0,$00(A0,D2.W)
	MOVE.B	lbB052586,D0
	ADD.B	$00(A1,D1.W),D0
	MOVE.B	D0,lbB052586
	CMP.B	#$0E,D2
	BNE	lbC051140
	ADDQ.B	#$01,D2
lbC051140:
	ADDQ.B	#$01,D2
	BNE	lbC0510CC
	TST.B	currentMenuItem
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

lbC05117C:
	JSR	lbC051022
	ADD.L	#$00000100,rawTrackDataOffset
	JMP	lbC051096

lbC051192:
	JSR	lbC05102C
	ADD.L	#$00000100,rawTrackDataOffset
	JMP	lbC051096

lbC0511A8:
	MOVE.B	networkSyncStateFlag,D0
	BEQ	lbC05121C
	MOVE.B	#$7F,D1
lbC0511B6:
	MOVE.L	#BigEdMaxBoost.MSG,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#memory_7A43A,A1
	MOVE.B	D0,$00(A1,D1.W)
	CMP.B	#$3C,D1
	BCC	lbC0511E6
	MOVE.L	#lbL00E2DE,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#memory_7A4BA,A1
	MOVE.B	D0,$00(A1,D1.W)
lbC0511E6:
	CMP.B	#$0C,D1
	BCC	lbC051202
	MOVE.L	#lbL00E336,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#memory_7A4FA,A1
	MOVE.B	D0,$00(A1,D1.W)
lbC051202:
	SUBQ.B	#$01,D1
	BPL	lbC0511B6
	MOVE.B	additionalPlayerCount,D0
	MOVE.B	D0,memory_7A4F6
	JSR	lbC051022
	RTS

lbC05121C:
	JSR	lbC05102C
	BCS	lbC051288
	MOVE.B	#$7F,D1
lbC05122A:
	MOVE.L	#memory_7A43A,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#BigEdMaxBoost.MSG,A1
	MOVE.B	D0,$00(A1,D1.W)
	CMP.B	#$3C,D1
	BCC	lbC05125A
	MOVE.L	#memory_7A4BA,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#lbL00E2DE,A1
	MOVE.B	D0,$00(A1,D1.W)
lbC05125A:
	CMP.B	#$0C,D1
	BCC	lbC051276
	MOVE.L	#memory_7A4FA,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.L	#lbL00E336,A1
	MOVE.B	D0,$00(A1,D1.W)
lbC051276:
	SUBQ.B	#$01,D1
	BPL	lbC05122A
	MOVE.B	memory_7A4F6,D0
	MOVE.B	D0,additionalPlayerCount
lbC051288:
	RTS

lbC05128A:
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
	MOVE.L	#t.MSG,A1
	MOVE.B	$00(A1,D1.W),D2
	MOVE.B	#$04,D0
	JSR	displayGameMessage
lbC0512F2:
	MOVE.B	#$67,D1
lbC0512F6:
	MOVE.B	D1,currentMenuItemCopy
	JSR	checkKeyPressed
	BNE	lbC051386
	MOVE.B	currentMenuItemCopy,D0
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
	MOVE.B	#$00,D0
	JSR	playAudioSample
lbC051366:
	MOVE.B	currentMenuItemCopy,D1
	JSR	checkKeyPressed
	BEQ	lbC051366
	MOVE.B	#$03,D2
	JSR	delayWithParam
	JMP	lbC051396

lbC051386:
	MOVE.B	currentMenuItemCopy,D1
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

transmitNetworkMessage:
	MOVE.B	D0,temp
	MOVE.B	additionalPlayerCount,D0
	BEQ	lbC05142C
	MOVE.B	currentPlayerID,D0
	JSR	lbC049D72
	MOVE.L	#controlKeys,A1
	TST.B	temp
	BPL	lbC05142E
lbC05141E:
	MOVE.B	$00(A2,D2.W),$00(A1,D1.W)
	SUBQ.B	#$01,D2
	SUBQ.B	#$01,D1
	BPL	lbC05141E
lbC05142C:
	RTS

lbC05142E:
	JSR	lbC049D8A
	JMP	lbC049CE8

lbC051462:
	MOVE.B	#$80,D0
	MOVE.B	D0,textRenderingFlag
	BCLR	#$00,raceConfiguredFlag
	BNE	lbC05149A
	MOVE.B	#$03,D2
	MOVE.B	selectedTrack,D0
	EOR.B	#$03,D0
	MOVE.B	#$18,D1
	JSR	displayMenu
	EOR.B	#$03,D0
	MOVE.B	D0,selectedTrackGroup
lbC05149A:
	MOVE.B	#$40,textRenderingFlag
	MOVE.B	#$02,D2
	MOVE.B	selectedRaceType,D0
	AND.B	#$01,D0
	MOVE.B	#$1C,D1
	JSR	displayMenu
	MOVE.B	#$00,D2
	MOVE.B	D2,textRenderingFlag
	RTS

displayStandings:
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
	MOVE.L	#memory_7A61A,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.L	#memory_7A71A,A2
	MOVE.B	$00(A2,D2.W),D0
	MOVE.L	#lbL00DF6C,A1
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
	MOVE.L	#LRHBSSBRHJRCS.MSG,A1
	MOVE.B	$00(A1,D1.W),D0
	JSR	renderCharacter
	MOVE.L	#RHBSSBRHJRCSJ.MSG,A1
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
	JSR	lbC05082E
	MOVE.B	#$02,D0
	MOVE.B	D0,textHorizontalOffset
	JMP	lbC051616

lbC0516B4:
	SUBQ.B	#$01,currentMenuItem
	BPL	lbC0515A6
	MOVE.B	#$00,D0
	MOVE.B	D0,textHorizontalOffset
	JSR	animatePaletteToTarget
	JSR	waitForDisplaySync
	MOVE.L	(SP)+,renderFrameBuffer
	JMP	displayMenuScreen

getSegmentAtGridCoordinate:
	MOVE.B	trackViewOffsetY,D0
	ADD.B	selectedMenuItem,D0
	CMP.B	#$10,D0
	BCC	lbC051750
	ASL.B	#$04,D0
	MOVE.B	D0,temp
	MOVE.B	trackViewOffsetX,D0
	ADD.B	currentPlayerNameOffset,D0
	CMP.B	#$10,D0
	BCC	lbC051750
	AND.B	#$0F,D0
	OR.B	temp,D0
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
	ADD.B	lbB00D42E,D0
	MOVE.B	D0,baseCoordinateX
	ASL.B	#$03,D3
	ADD.B	lbB00D432,D3
	MOVE.B	D3,baseCoordinateY
	RTS

adjustNetworkCoordinates:
	MOVE.B	D0,temp
	MOVE.B	D2,curveMagnitude
	CMP.B	temp,D2
	BCC	lbC051966
	ADD.B	curveMagnitude,D0
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
	ADD.B	curveMagnitude,D0
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

processCoordinateData:
	LSR.W	#$08,D0
	MOVE.B	D0,savedSegmentIndex
	MOVE.L	#lbB00D5D8,A0
	MOVE.L	#lbB00D407,A1
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
	TST.B	savedSegmentIndex
	BMI	lbC051A40
	BTST	#$06,savedSegmentIndex
	BNE	lbC051A22
	MOVE.L	lbB00D5D8,lbL00D5CC
	MOVE.L	lbB00D5E0,lbL00D5D4
	RTS

lbC051A22:
	MOVE.L	lbB00D5D8,lbL00D5D4
	MOVE.L	#$08000000,D0
	SUB.L	lbB00D5E0,D0
	MOVE.L	D0,lbL00D5CC
	RTS

lbC051A40:
	BTST	#$06,savedSegmentIndex
	BNE	lbC051A72
	MOVE.L	#$08000000,D0
	SUB.L	lbB00D5D8,D0
	MOVE.L	D0,lbL00D5CC
	MOVE.L	#$08000000,D0
	SUB.L	lbB00D5E0,D0
	MOVE.L	D0,lbL00D5D4
	RTS

lbC051A72:
	MOVE.L	#$08000000,D0
	SUB.L	lbB00D5D8,D0
	MOVE.L	D0,lbL00D5D4
	MOVE.L	lbB00D5E0,lbL00D5CC
	RTS

calculate3DProjection1:
	MOVE.W	cameraAngleY,D0
	ADD.W	#$2000,D0
	AND.W	#$C000,D0
	MOVE.W	D0,cameraRotationFlags
	JSR	processCoordinateData
	MOVE.L	lbB00D5DC,D0
	LSR.L	#$08,D0
	LSR.L	#$03,D0
	MOVE.W	D0,carHeightPosition
	MOVE.W	#$0780,D3
	MOVE.W	collisionStateFlags1,D0
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
	MOVE.W	D0,lbW00D4FA
	MOVE.L	lbL00D5CC,D0
	LSR.L	#$08,D0
	LSR.L	#$04,D0
	AND.W	#$07FF,D0
	NEG.W	D0
	MOVE.B	D0,lbB00D423
	LSR.W	#$08,D0
	MOVE.B	D0,lbB00D42E
	MOVE.L	lbL00D5D4,D0
	LSR.L	#$08,D0
	LSR.L	#$04,D0
	AND.W	#$07FF,D0
	NEG.W	D0
	MOVE.B	D0,lbB00D427
	LSR.W	#$08,D0
	MOVE.B	D0,lbB00D432
	MOVE.W	cameraAngleY,D0
	ADD.W	#$2000,D0
	AND.W	#$3FFE,D0
	SUB.W	#$2000,D0
	MOVE.W	D0,lbW00D52E
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
	BLT	lbC051BC6
	TST.B	collisionStateFlags
	BMI	lbC051BC4
	MOVE.B	#$80,collisionStateFlags
	MOVE.B	offsetFromRoadCenter,trackSideIndicator
	MOVE.B	#$10,restartTimerCountdown
	JSR	initializeDebrisParticlePositions
lbC051BC4:
	RTS

lbC051BC6:
	BTST	#$06,collisionStateFlags
	BNE	lbC051BC4
	MOVE.B	#$00,collisionStateFlags
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
	MOVE.B	D1,currentPlayerNameOffset
	MOVE.B	D2,selectedMenuItem
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
	MOVE.B	#$E0,lbB00D49A
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
	MOVE.W	lbW00D51E,renderDataPointer
	MOVE.W	#$0000,D1
	MOVE.B	#$00,segmentProcessedFlag
	MOVE.B	#$00,processedSegmentIndices1
	MOVE.B	#$00,savedPlayerIndex
	ADD.W	#$0010,renderDataPointer
	MOVE.L	#memory_3D80,lineDrawingBufferPointer
	JSR	drawTrackSegmentWireframe
	JSR	renderTrackNear
lbC051DA6:
	MOVE.B	currentTrackCoordinate,D1
	MOVE.B	maxMenuIndex,D2
	RTS

renderTrackPreview:
	MOVE.W	#$0060,lbW00D51E
	MOVE.B	#$80,lbB00D468
	MOVE.B	cameraAngleIndex,D1
	AND.B	#$03,D1
	MOVE.L	#lbL051E52,A1
	MOVE.B	$00(A1,D1.W),lbB00D5D8
	MOVE.L	#lbB051E56,A1
	MOVE.B	$00(A1,D1.W),lbB00D5E0
	MOVE.L	#lbL051E5A,A1
	MOVE.B	$00(A1,D1.W),cameraAngleY
	MOVE.B	#$03,lbB00D5DC
	MOVE.B	#$F0,lbB00D5DD
	MOVE.B	#$00,lbB00D5C8
	MOVE.W	#$0700,lbW00D542
	JSR	initializeRenderingState
	JSR	copyTrackPreviewRegion
	JSR	animatePaletteToTarget
	MOVE.B	#$80,segmentConfigLoadedFlag
	JSR	renderTrackPreviewGrid
	MOVE.B	#$00,segmentConfigLoadedFlag
	MOVE.W	#$0000,lbW00D51E
	MOVE.B	#$00,lbB00D468
	RTS

lbC051E5E:
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
initializeAudioSystem:
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
	MOVE.L	#lbL00D5CC,A0
lbC051F08:
	MOVE.B	#$00,(A0)+
	CMP.L	#lbL00D65E,A0
	BNE	lbC051F08
	MOVE.B	#$F0,raceStartTimer
	JSR	loadTrackSegmentConfiguration
	MOVE.L	#trackSegmentCoordinates,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$0F,D0
	MOVE.B	D0,currentPlayerNameOffset
	MOVE.B	$00(A1,D1.W),D0
	LSR.B	#$04,D0
	MOVE.B	D0,selectedMenuItem
	MOVE.W	#$0000,D0
	MOVE.W	D0,lbW00D5DA
	MOVE.W	D0,lbW00D5E2
	MOVE.B	currentPlayerNameOffset,D0
	AND.W	#$00FF,D0
	ASL.W	#$07,D0
	ADD.W	#$0040,D0
	MOVE.W	D0,lbB00D5D8
	MOVE.B	selectedMenuItem,D0
	AND.W	#$00FF,D0
	ASL.W	#$07,D0
	ADD.W	#$0040,D0
	MOVE.W	D0,lbB00D5E0
	MOVE.B	#$04,lbB00D5DC
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
	JSR	calculate3DProjection1
	JSR	applyTrackSegmentGeometry
	JSR	checkRoadBoundaries
	JSR	updateGamePhysics
	MOVE.W	#$0000,lbW00D5DE
	MOVE.W	#$0010,lbB00D5DC
	MOVE.L	carWorldZ,D0
	MOVE.L	D0,D3
	MOVE.B	raceStartComplete,D2
	BEQ	lbC05200E
	ASL.L	#$08,D0
	ASL.L	#$01,D0
	ADD.L	#$00180000,D0
	MOVE.L	D0,lbB00D5DC
	MOVE.B	#$E6,raceStartTimer
lbC05200E:
	LSR.L	#$02,D3
	MOVE.W	D3,trackSurfaceHeight
	JSR	lbC04CE06
	MOVE.B	#$08,D1
	MOVE.L	#carWorldX,A1
	MOVE.L	#trackCenterX,A2
lbC05202C:
	MOVE.L	#$00001000,$00(A1,D1.W)
	MOVE.L	#$00001000,$00(A2,D1.W)
	SUBQ.B	#$04,D1
	BPL	lbC05202C
	MOVE.L	#$00000000,previousDistanceX
	MOVE.W	#$0000,previousDistanceZ
	JSR	calculate3DProjection1
	MOVE.B	#$B0,chainVerticalPosition
	MOVE.B	#$01,chainLiftVelocity		; fixed $08
	RTS

calculatePlayerDistance:
	MOVE.W	gameStateCounter,D0
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
	MOVE.W	D0,lbW00D53E
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
	MOVE.W	D4,carRenderDistance
	EOR.W	#$8000,D5
	LSR.W	#$08,D5
	MOVE.B	D5,carCrashedFlag
	RTS

validateGameState:
	MOVE.B	player2LapCounter,D0
	SUB.B	player1LapCounter,D0
	BNE	lbC052122
	MOVE.B	playerSegmentIndex,D0
	SUB.B	startingSegmentIndex,D0
	BCC	lbC0520F6
	ADD.B	numTrackSegments,D0
lbC0520F6:
	MOVE.B	opponentSegmentIndex,D3
	SUB.B	startingSegmentIndex,D3
	BCC	lbC05210C
	ADD.B	numTrackSegments,D3
lbC05210C:
	SUB.B	D0,D3
	BNE	lbC052122
	MOVE.W	lbW00D53E,D0
	BNE	lbC052122
	MOVE.B	networkGameMode,D0
lbC052122:
	RTS

lbC052124:
	MOVE.B	lbB00E320,D3
	ANDI.B	#$0F,CCR
	ABCD	D3,D0
	CMP.B	lbB00D495,D0
	BCS	lbC052140
	MOVE.B	lbB00D495,D0
lbC052140:
	MOVE.B	D0,lbB00E320
	MOVE.B	#$1F,D0
	JSR	renderCharacter
	MOVE.B	#$09,D0
	JSR	renderCharacter
	MOVE.B	#$16,D0
	JSR	renderCharacter
	MOVE.B	#$04,textHorizontalOffset
	MOVE.B	#$02,textYOffset
	MOVE.B	lbB00E320,D0
	LSR.B	#$04,D0
	JSR	renderDigitAndAdvance
	MOVE.B	lbB00E320,D0
	AND.B	#$0F,D0
	JSR	renderDigitAndAdvance
	MOVE.B	#$00,textHorizontalOffset
	MOVE.B	#$00,textYOffset
	RTS

processEngineAudio:
	MOVE.B	raceActiveFlag,D0
	OR.B	postWreckStateFlag,D0
	BNE	lbC052210
	MOVE.B	accelerationStateFlag,D0
	BMI	lbC0521CC
	MOVE.B	inputStateFlags,D0
	AND.B	#$03,D0
	BEQ	lbC052210
lbC0521CC:
	MOVE.B	lbB00E320,D0
	BEQ	lbC052210
	TST.B	trackDirectionFlag
	BMI	lbC052200
	SUBQ.B	#$01,lbB00D43D
	BPL	lbC052200
	MOVE.B	lbB00D3FE,D2
	MOVE.B	D2,lbB00D43D
	MOVE.B	#$99,D0
	JSR	lbC052124
lbC052200:
	MOVE.B	#$80,boostActiveFlag
	ASL.W	gasOutputAccumulatorValue
	RTS

lbC052210:
	MOVE.B	#$00,boostActiveFlag
	RTS

displayLapCompletionGraphics:
	MOVE.B	#$17,D1
	BRA	lbC05222E

displayLapCounterGraphics:
	MOVE.B	#$19,D1
	BRA	lbC05222E

displayGameObjectDigit:
	MOVE.B	#$1B,D1
lbC05222E:
	MOVE.W	D1,-(SP)
	MOVE.L	#rightWheelWidth,A0
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

initializeGameObjects:
	MOVE.B	#$09,D2
lbC05228C:
	CMP.B	objectDisplayThreshold,D2
	BGE	lbC0522A0
	JSR	displayGameObjectDigit
	BRA	lbC0522A6

lbC0522A0:
	JSR	displayLapCompletionGraphics
lbC0522A6:
	SUBQ.B	#$01,D2
	BPL	lbC05228C
	RTS

saveLoadGameData:
	MOVE.B	D0,currentMenuItem
	MOVE.L	#randomSeed1,A0
	MOVE.L	#memory_7A035,A1
	MOVE.B	#$04,D1
lbC0522C4:
	TST.B	currentMenuItem
	BMI	lbC0522DE
	MOVE.B	(A0)+,$00(A1,D1.W)
	JMP	lbC0522EC

lbC0522D8:
	ANDI.B	#$1E,CCR
	RTS

lbC0522DE:
	MOVE.B	lbB00E334,D0
	BPL	lbC0522D8
	MOVE.B	$00(A1,D1.W),(A0)+
lbC0522EC:
	SUBQ.B	#$01,D1
	BPL	lbC0522C4
	TST.B	currentMenuItem
	BMI	lbC05231E
	MOVE.B	#$0B,D1
lbC052300:
	MOVE.L	#ascii.MSG3,A1
	MOVE.B	$00(A1,D1.W),D0
	EOR.B	#$3B,D0
	MOVE.L	#lbL00E2B6,A1
	MOVE.B	D0,$00(A1,D1.W)
	SUBQ.B	#$01,D1
	BPL	lbC052300
lbC05231E:
	MOVE.B	#$1A,D1
lbC052322:
	TST.B	currentMenuItem
	BPL	lbC05234C
	MOVE.L	#memory_7A01A,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.B	D0,currentMenuItemCopy
	MOVE.L	#memory_7A03F,A1
	MOVE.B	$00(A1,D1.W),D0
	MOVE.B	D0,savedSegmentIndex
lbC05234C:
	MOVE.B	#$00,D2
	MOVE.B	D2,curveMagnitude
lbC052356:
	ADDQ.B	#$01,curveMagnitude
	BNE	lbC052366
	ADDQ.B	#$01,D2
	BMI	lbC052482
lbC052366:
	JSR	generateRandomNumber
	MOVE.B	D0,speedDisplayThousands
	TST.B	currentMenuItem
	BMI	lbC0523AC
	MOVE.L	#lbL00E2B6,A1
	CMP.B	$00(A1,D1.W),D0
	BNE	lbC052356
	MOVE.B	D2,D0
	MOVE.L	#memory_7A01A,A1
	MOVE.B	D0,$00(A1,D1.W)
	MOVE.B	curveMagnitude,D0
	MOVE.L	#memory_7A03F,A1
	MOVE.B	D0,$00(A1,D1.W)
	JMP	lbC0523D6

lbC0523AC:
	CMP.B	currentMenuItemCopy,D2
	BNE	lbC052356
	MOVE.B	curveMagnitude,D0
	CMP.B	savedSegmentIndex,D0
	BNE	lbC052356
	MOVE.B	speedDisplayThousands,D0
	MOVE.L	#networkTransferBuffer,A1
	MOVE.B	D0,$00(A1,D1.W)
lbC0523D6:
	SUBQ.B	#$01,D1
	BPL	lbC052322
	MOVE.L	#randomSeed1,A0
	MOVE.B	#$04,D1
	MOVE.B	#$09,D2
lbC0523EA:
	MOVE.B	(A0)+,D0
	TST.B	currentMenuItem
	BMI	lbC052404
	MOVE.L	#memory_7A03A,A1
	MOVE.B	D0,$00(A1,D1.W)
	BPL	lbC052412
lbC052404:
	MOVE.L	#memory_7A03A,A1
	CMP.B	$00(A1,D1.W),D0
	BNE	lbC052482
lbC052412:
	SUBQ.B	#$01,D1
	BPL	lbC0523EA
	TST.B	currentMenuItem
	BPL	lbC052472
	MOVE.L	#lbL00E2B6,A3
	MOVE.L	#networkTransferBuffer,A0
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
	MOVE.L	#ascii.MSG3,A1
	MOVE.B	D0,$00(A1,D1.W)
	SUBQ.B	#$01,D1
	BPL	lbC052454
lbC052472:
	MOVE.B	#$80,D0
	MOVE.B	D0,lbB00E334
	ANDI.B	#$1E,CCR
	RTS

lbC052482:
	MOVE.B	#$3B,lbB053EA5
	MOVE.B	currentMenuItem,D0
	BPL	saveLoadGameData
	ORI.B	#$01,CCR
	RTS

	MOVE.B	#$03,framesToWaitWhenFading
lbC0524A2:
	TST.B	framesToWaitWhenFading
	BNE.L	lbC0524A2
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
	ADDQ.B	#$01,lbB052586
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
	JSR	lbC0493C0
lbC05257E:
	MOVE.B	D0,inputStateFlags
	RTS

handleCollisionEffects:
	MOVE.B	#$06,crashAudioSampleID		; Set audio sample #6 (collision sound)
	MOVE.B	impactSeverity,D0
	CMP.B	#$10,D0			; Cap at 16 (decimal)
	BLT	lbC0525AC
	MOVE.B	#$10,D0
lbC0525AC:
	MOVE.B	D0,collisionImpactLevel		; Store severity
	MOVE.B	#$0F,D1			; Only 16 particles (0-15)
	TST.B	networkGameMode
	BEQ	lbC0525C4
	MOVE.B	#$03,D1			; Only 4 particles in network mode!
lbC0525C4:
	JSR	generateRandomNumber
	AND.W	#$001C,D0		; Random 0-28 (multiples of 4)
	ADD.W	#$01C2,D0		; Add 450 (range 450-478)
	MOVE.W	D0,sampleGroundCollisionPeriod		; Store audio parameter
	BRA	lbC0526A2		; Jump to particle update loop

lbC0525DC:
	RTS

initializeDebrisParticlePositions:
	MOVE.W	#$003E,D1		; D1 = 62 (32 particles * 2)
	MOVE.W	#$00D4,D0		; D0 = 212 (off-screen Y position)
lbC0525E6:
	MOVE.L	#debrisParticleYPositions,A1
	MOVE.W	D0,$00(A1,D1.W)		; Set Y position to 212
	SUBQ.B	#$02,D1			; Previous particle
	BPL	lbC0525E6		; Loop for all 32
	RTS

processCollisionState:
	MOVE.B	#$01,crashAudioSampleID		; Set audio sample #1 (crash sound)
	MOVE.B	wheelBouncePhaseAccumulator,D0		; Check audio pitch modifier
	BNE	lbC052614		; Skip if non-zero
	MOVE.B	postWreckStateFlag,D0	; Check if in wreck state
	BEQ	lbC0525DC		; Exit if no collision
lbC052614:				; Continue if collision detected
	TST.B	collisionStateFlags	; Check collision flag
	BMI	lbC0525DC		; Exit if MSB set
	MOVE.B	impactSeverity,D0	; Get impact severity (0-255)
	CMP.B	#$01,D0
	BLT	lbC0525DC		; Exit if too low
	CMP.B	#$32,D0			; Cap at 50 (decimal)
	BLT	lbC052638
	MOVE.B	#$32,D0
lbC052638:
	MOVE.B	D0,collisionImpactLevel		; Store severity
	MOVE.B	#$1F,D1			; Prepare for 32 particles (0-31)
	JSR	generateRandomNumber	; Get random value
	AND.B	#$07,D0			; Mask to 0-7
	MOVE.B	D0,D2			; Save random value
	MOVE.B	collisionImpactLevel,D0		; Reload severity
	LSR.B	#$01,D0			; Divide by 2
	BRA	lbC052682

	CMP.B	#$08,D0
	BGE	lbC05266A
	MOVE.B	#$08,D0
	BNE	lbC052682
lbC05266A:
	CMP.B	#$06,D2
	BLT	lbC052682
	MOVE.B	#$0D,D0
	CMP.B	#$07,D2
	BNE	lbC052682
	MOVE.B	#$03,D0
lbC052682:
	CMP.B	#$1F,D0
	BCS	lbC05268E
	MOVE.B	#$1F,D0
lbC05268E:
	EOR.B	#$1F,D0
	AND.W	#$00FF,D0
	ASL.W	#$02,D0
	ADD.W	#$00AA,D0
	MOVE.W	D0,sampleEnginePeriod
lbC0526A2:
	ASL.B	#$01,D1			; D1 = 62 (particle index * 2)
	MOVE.B	D1,currentDataIndex	; Store particle count
	MOVE.B	playerStateFlag,D0
	BEQ	initializeDebrisParticlePositions	; If no crash, init positions
	MOVE.B	crashAudioSampleID,D0		; Load audio sample ID
	JSR	playAudioSample		; Play crash sound
	MOVE.L	#debrisParticleXPositions,A4
	MOVE.L	#debrisParticleXVelocities,A5
	MOVE.B	currentDataIndex,D1	; D1 = 62 (start at last particle)
lbC0526D2:
	JSR	validateAndRenderParticle		; Check if particle on screen
	BNE	lbC0526F0		; Skip if off-screen
	ADDQ.W	#$02,$40(A5,D1.W)	; Increment Y velocity (gravity!)
	MOVE.W	$40(A5,D1.W),D0		; Load Y velocity
	ADD.W	D0,$40(A4,D1.W)		; Update Y position
	MOVE.W	$00(A5,D1.W),D0		; Load X velocity
	ADD.W	D0,$00(A4,D1.W)		; Update X position
lbC0526F0:
	SUBQ.B	#$02,D1			; Move to previous particle
	BPL	lbC0526D2		; Loop for all 32 particles
	MOVE.B	currentDataIndex,D1
lbC0526FC:
	MOVE.W	$40(A4,D1.W),D0		; Get Y position
	CMP.W	#$0080,D0		; Check if below screen (Y < 128)
	BCS	lbC052780		; Skip if still on screen
	JSR	generateRandomNumber	; Particle has fallen off screen - respawn it
	AND.W	#$0007,D0		; Random 0-7
	MOVE.W	D0,D3
	CLR.W	D0
	MOVE.B	collisionImpactLevel,D0		; Reload impact severity
	LSR.W	#$01,D0			; Halve it
	TST.B	collisionStateFlags	; Check collision type
	BMI	lbC05272A		; Branch for major collision
	LSR.W	#$01,D0			; Further reduce for minor collision
lbC05272A:
	ADD.W	D3,D0			; Add randomness
	NOT.W	D0			; Invert (negative velocity)
	MOVE.W	D0,$40(A5,D1.W)		; Set new Y velocity (upward)
	TST.B	collisionStateFlags
	BPL	lbC052748		; Branch for normal collision
	JSR	initializeMajorCrashParticle		; Initialize for major crash
	JMP	lbC05276E

lbC052748:				; Normal collision respawn
	JSR	generateRandomNumber
	AND.W	#$007F,D0		; Random 0-127
	ADD.W	#$0040,D0		; Set X position
	MOVE.W	D0,$00(A4,D1.W)
	MOVE.W	D0,D5			; Save for velocity calc
	JSR	generateRandomNumber
	OR.W	#$FFF8,D0		; Force high bits
	ADD.W	#$007F,D0		; Range calculation
	MOVE.W	D0,$40(A4,D1.W)		; Set Y position
lbC05276E:
	MOVE.W	D5,D0
	SUB.W	#$0080,D0		; Center at 128
	ASR.W	#$03,D0			; Divide by 8
	MOVE.W	D0,$00(A5,D1.W)		; Set X velocity
	JSR	validateAndRenderParticle		; Validate particle
lbC052780:
	SUBQ.B	#$02,D1
	BPL	lbC0526FC		; Loop for all particles
	RTS

validateAndRenderParticle:
	MOVE.B	D1,savedPlayerIndex	; Save particle index
	MOVE.W	$40(A4,D1.W),D5		; Load Y position
	CMP.W	#$0080,D5		; Check if Y >= 128
	BCC	lbC0527AE		; Reset if off bottom
	MOVE.W	$00(A4,D1.W),D0		; Load X position
	CMP.W	#$0100,D0		; Check if X >= 256
	BCC	lbC0527AE		; Reset if off right
	CMP.W	#$0001,D5		; Check if Y < 1
	BCC	lbC0527B6		; Continue if valid
lbC0527AE:
	MOVE.W	#$00D2,$40(A4,D1.W)	; Reset Y to 210 (off-screen)
	RTS

lbC0527B6:
	TST.B	collisionStateFlags
	BPL	lbC0527CC		; Branch for normal rendering
	JSR	renderDustCloud		; Render as sprite (major crash)
	JMP	lbC05282A

lbC0527CC:				; Normal pixel rendering
	MOVE.W	D0,D4
	CMP.W	#$00FE,D0
	BCC	lbC0527AE
	MOVE.L	viewportTopAddress,A0	; Calculate framebuffer address from X,Y coordinates
	EXT.L	D0
	EXT.L	D5
	LSR.L	#$03,D0			; X / 8 (byte offset)
	AND.B	#$FE,D0			; Align to even
	ADD.L	D0,A0			; Add X offset
	MOVE.L	D5,D0
	ASL.L	#$02,D0			; Y * 4
	ADD.L	D5,D0			; Y * 5
	ASL.L	#$03,D0			; Y * 40 (scanline width)
	ADD.L	D0,A0			; Add Y offset
	MOVE.B	#$03,D0			; Plot 4 pixels in 2x2 pattern
	JSR	setPixelColor		; Set color 3
	JSR	plotPixel		; Plot pixel
	ADDQ.W	#$01,D4
	JSR	plotPixel		; Plot right pixel
	SUB.L	#$00000028,A0		; Move up one scanline (40 bytes)
	SUBQ.W	#$01,D4
	JSR	plotPixel		; Plot upper-left
	ADDQ.W	#$01,D4
	MOVE.B	#$0F,D0
	JSR	setPixelColor		; Set color 15 (bright)
	JSR	plotPixel		; Plot upper-right (brightest)
lbC05282A:
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	#$00,D0
	RTS

initializeMajorCrashParticle:
	JSR	generateRandomNumber
	AND.W	#$00FF,D0		; Random X: 0-255
	MOVE.W	D0,$00(A4,D1.W)		; Set X position (full screen width)
	MOVE.W	D0,D5			; Save for velocity
	JSR	generateRandomNumber
	AND.W	#$0007,D0		; Random 0-7
	ADD.W	#$0076,D0		; Add 118 (range 118-125)
	MOVE.W	D0,$40(A4,D1.W)		; Set Y position (upper screen)
	RTS

renderDustCloud:
	MOVE.B	D1,D2
	LSR.B	#$01,D2			; Particle index / 2
	ADD.B	frameCounter,D2		; Add frame counter for animation
	AND.W	#$000F,D2		; Mask to 0-15
	MOVE.L	#dustCloudAnimSequence,A0		; Dust cloud animation sequence table
	MOVE.B	$00(A0,D2.W),D2		; Get frame index
	ASL.B	#$01,D2			; Multiply by 2
	MOVE.W	$00(A4,D1.W),D4		; Load X position
	MOVE.L	#dustCloudOffsetTable,A0		; Offset table
	SUB.W	$00(A0,D2.W),D4		; Adjust X by offset
	ADD.W	#$0020,D4		; Add 32 (center)
	MOVE.W	$40(A4,D1.W),D5		; Load Y position
	ADD.W	#$0010,D5		; Add 16 (center)
	MOVE.B	D2,D0
	LSR.B	#$01,D0			; Index / 2
	ADD.B	#$1D,D0			; Add 29 (dust cloud ID offset)
	JMP	renderGraphicsObjectAtPosition		; Render dust cloud

updateWheelSpeed:
	MOVE.W	carVelocity,D0
	BPL	lbC0528CA
	NEG.W	D0
lbC0528CA:
	MOVE.W	D0,impactSeverity
	MOVE.B	playerStateFlag,D1
	BNE	lbC0528EA
	MOVE.W	wheelSpeed,D0
	LSR.W	#$04,D0			; fixed $02
	SUB.W	D0,wheelSpeed
	RTS

lbC0528EA:
	CMP.W	#$0800,D0
	BGE	lbC0528FC
	ASL.W	#$03,D0
	MOVE.W	D0,wheelSpeed
	RTS

lbC0528FC:
	ASL.W	#$01,D0
	ADD.W	#$3000,D0
	BCC	lbC05290A
	MOVE.W	#$FF00,D0
lbC05290A:
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
	MOVE.W	D4,lateralVelocity
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
	MOVE.B	lateralVelocity,D3
	EOR.B	D3,D0
	MOVE.B	D0,temp
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
	TST.B	temp
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
	MOVE.B	lateralVelocity,steeringInputDirection
	MOVE.W	segmentProgressDistance,D0
	MOVE.B	D0,D2
	MOVE.B	segmentProgressDistance,D3
	BEQ	lbC052A88
	SUB.W	#$1E00,D0
	BPL	lbC052AC2
	MOVE.B	#$FF,D2
lbC052A88:
	MOVE.B	D2,curveMagnitude
	MOVE.W	carVelocity,D0
	BPL	lbC052A9A
	NEG.W	D0
lbC052A9A:
	ADD.W	#$0A00,D0
	BPL	lbC052AA6
	MOVE.W	#$7F00,D0
lbC052AA6:
	MOVE.B	curveMagnitude,D3
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
	TST.B	lateralVelocity
	BPL	lbC052ACE
	NEG.W	D0
lbC052ACE:
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
	TST.B	playerStateFlag
	BNE	lbC052B14
lbC052B10:
	MOVE.W	#$0000,D4
lbC052B14:
	MOVE.W	D4,yawRotationRate
	RTS

lbC052B1C:
	MOVE.B	D0,curveMagnitude
	MOVE.W	carVelocity,D0
	MOVE.B	curveMagnitude,D3
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
	MOVE.B	curveMagnitude,D3
	AND.W	#$00FF,D3
	MULU	D0,D3
	MOVE.W	D3,D0
	MOVE.B	D0,temp
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
	MOVE.B	D3,temp
	LSR.W	#$08,D0
	RTS

	BCLR	#$07,trackSideIndicatorCopy
	ASL.W	#$08,D0
	OR.B	temp,D0
	MOVE.B	curveMagnitude,D3
	AND.W	#$00FF,D3
	TST.B	trackSideIndicatorCopy
	BPL	lbC052C28
	NEG.W	D3
lbC052C28:
	MULS	D0,D3
	ASR.L	#$08,D3
	MOVE.W	D3,D0
	MOVE.B	D0,temp
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

lbC052C5A:
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
	MOVE.L	#targetRollAngle,A4
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
	MOVE.L	#lbW00D5F6,A4
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
	MOVE.L	#lbW00D63A,A4
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
	MOVE.W	lbW00D63C,D0
	MOVE.W	#$0004,D1
	JSR	matrixMultiply
	ADD.W	rotationSpeedZ,D0
	MOVE.W	D0,lbW00D63E
	RTS

verticalBlank:
	add.b	#1,framesSinceCopperlistUpdateAccumulator
	CLR.W	D1
	CLR.W	D2
	TST.B	framesToWait
	BEQ	lbC052FF0
	SUBQ.B	#$01,framesToWait
lbC052FF0:
	TST.B	framesToWaitWhenFading
	BEQ	lbC053000
	SUBQ.B	#$01,framesToWaitWhenFading
lbC053000:
	TST.B	displayUpdateFlag
	BPL	lbC05301A
	TST.B	gameInitFlag3
	BNE	lbC05301A
	JSR	updateWheelGraphics
lbC05301A:
	MOVE.W	gameLoopControl,_custom+dmacon
	MOVE.W	enginePitchAccumulator,D0
	ADD.W	enginePitchDelta,D0
	BPL	lbC053056
	TST.B	gameExitFlag
	BEQ	lbC053052
	MOVE.W	#DMAF_AUD0,_custom+dmacon
	MOVE.W	#INTF_AUD0,_custom+intena
	BRA	verticalBlankDone

lbC053052:
	MOVE.W	#$0000,D0
lbC053056:
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
	MOVE.L	#sampleParameters,A0
	LEA	_custom,A1
	ASL.W	#$03,D4
	MOVE.L	$00(A0,D4.W),aud0(A1)
	MOVE.W	$06(A0,D4.W),aud0+ac_len(A1)
	MOVE.W	D3,audioChannel0Period
verticalBlankDone:
	RTS

	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

lbC0530D0:
	MOVE.B	savedPlayerIndex,D1
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
	MOVE.W	#$0114,D3
	BEQ	lbC05311A
	MULS	D3,D0
	ASR.L	#$08,D0
lbC05311A:
	ADD.W	D6,D0
	RTS

updateOpponentLapTime:
	MOVE.W	D1,D3
	MOVE.L	#trackProgressionByte,A0
	ASL.B	#$01,D3
	TST.B	$00(A0,D3.W)
	BNE	lbC05315A
	MOVE.B	$01(A0,D3.W),D0			; Load opponent time modifier
	EOR.B	#$FF,D0				; Invert bits
	MOVE.B	D0,curveMagnitude
	MOVE.B	#$0D,D0				; Multiplier
	JSR	multiplyAndRandomize		; Add randomness
	CMP.B	#$0A,D0
	BCS	lbC053154			; If < 10, use as-is
	ADD.B	#$06,D0				; Otherwise add 6
lbC053154:
	JSR	lbC04F832			; Update timer with this value
lbC05315A:
	RTS

updateGamePhysics:
	move.b	framesSinceCopperlistUpdate,physicsUpdateCount
	sub.b	#2,physicsUpdateCount
updateGamePhysicsLoop:
	JSR	calculateTransformMatrices
	JSR	calculateWheelCornerPositions
	JSR	calculateSegmentPhysics
	JSR	calculateTrackPositions
	JSR	transformWorldCoordinates
	JSR	updateWheelSpeed
	JSR	calculateViewAngles
	JSR	detectTrackBoundaryCollisions
	MOVE.B	frameProcessingFlag,D0
	BEQ	lbC0531C0
	JSR	updateCarOrientation
	JSR	calculateSteeringResponse
	JSR	calculateSecondaryCoordinates
	JSR	updateCollisionState
	JSR	updateVelocityDamping
	JSR	integrateVelocityComponents
	JSR	calculateTertiaryCoordinates
lbC0531C0:
	JSR	applyVelocityIntegration
	JSR	updateWorldPosition
	sub.b	#1,physicsUpdateCount
	bpl.s	updateGamePhysicsLoop
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
	ADD.L	D0,lbB00D5D8
	MOVE.W	worldYSpeed,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC05327E
	MULS	D2,D0
	ASR.L	#$08,D0
lbC05327E:
	EXT.L	D0
	ASL.L	#$07,D0
	ADD.L	D0,lbB00D5DC
	MOVE.W	worldZSpeed,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC05329A
	MULS	D2,D0
	ASR.L	#$08,D0
lbC05329A:
	EXT.L	D0
	ASL.L	#$06,D0
	ADD.L	D0,lbB00D5E0
	MOVE.W	lbB00D5DC,D0
	CMP.W	#$03E8,D0
	BLT	lbC0532BA
	MOVE.W	#$03E8,lbB00D5DC
lbC0532BA:
	MOVE.W	lbW00D63A,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC0532CC
	MULS	D2,D0
	ASR.L	#$08,D0
lbC0532CC:
	ADD.W	D0,cameraAngleX
	MOVE.W	lbW00D63C,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC0532E4
	MULS	D2,D0
	ASR.L	#$08,D0
lbC0532E4:
	ADD.W	D0,cameraAngleY
	MOVE.W	lbW00D63E,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC0532FC
	MULS	D2,D0
	ASR.L	#$08,D0
lbC0532FC:
	ADD.W	D0,cameraAngleZ
	MOVE.W	#$0000,D2
	TST.B	raceCompletionCheckFlag
	BPL	lbC053320
	MOVE.B	lbB00D49A,D0
	CMP.B	#$E0,D0
	BNE	lbC053320
	ADDQ.B	#$02,D2
lbC053320:
	MOVE.L	#ascii.MSG1,A0
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
	MOVE.W	D0,lbW00D542
	RTS

applyVelocityIntegration:
	MOVE.W	lbW00D5F6,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC0533EE
	MULS	D2,D0
	ASR.L	#$08,D0
lbC0533EE:
	ADD.W	D0,worldXSpeed
	MOVE.W	lbW00D5F8,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC053406
	MULS	D2,D0
	ASR.L	#$08,D0
lbC053406:
	ADD.W	D0,worldYSpeed
	MOVE.W	lbW00D5FA,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC05341E
	MULS	D2,D0
	ASR.L	#$08,D0
lbC05341E:
	ADD.W	D0,worldZSpeed
	RTS

integrateVelocityComponents:
	MOVE.W	lbW00D5FC,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC053438
	MULS	D2,D0
	ASR.L	#$08,D0
lbC053438:
	ADD.W	D0,rotationSpeedX
	MOVE.W	yawRotationRate,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC053450
	MULS	D2,D0
	ASR.L	#$08,D0
lbC053450:
	ADD.W	D0,rotationSpeedY
	MOVE.W	lbW00D600,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC053468
	MULS	D2,D0
	ASR.L	#$08,D0
lbC053468:
	ADD.W	D0,rotationSpeedZ
	RTS

calculateTrackPositions:
	MOVE.W	cameraAngleX,D0
	JSR	calculateSine
	MOVE.W	D0,lateralVelocity
	MOVE.W	cameraAngleZ,D0
	JSR	calculateSine
	EXT.L	D0
	ASL.L	#$03,D0
	MOVE.W	lateralVelocity,D3
	EXT.L	D3
	ASL.L	#$04,D3
	MOVE.L	lbB00D5DC,D4
	SUB.L	D3,D4
	ASR.L	#$08,D4
	MOVE.L	D4,trackCenterZ
	MOVE.L	lbB00D5DC,D4
	ADD.L	D3,D4
	MOVE.L	D4,D5
	SUB.L	D0,D5
	ASR.L	#$08,D5
	MOVE.L	D5,trackCenterY
	ADD.L	D0,D4
	ASR.L	#$08,D4
	MOVE.L	D4,trackCenterX
	RTS

detectTrackBoundaryCollisions:
	MOVE.B	#$00,offTrackCollisionFlag
	MOVE.B	#$00,maxDistanceFromTrack
	MOVE.L	carWorldX,D0
	SUB.L	trackCenterX,D0
	SUB.L	trackOffsetAdjustment,D0
	MOVE.L	D0,distanceFromTrackX
	BMI	negativeDistanceClamp
	CMP.L	#$00001400,D0
	BCS	applyDistanceClamps
	BRA	positiveDistanceClamp

negativeDistanceClamp:
	CMP.L	#$FFFFFD00,D0
	BCC	applyDistanceClamps
	MOVE.L	#$FFFFFD00,D0
	BRA	applyDistanceClamps

positiveDistanceClamp:
	MOVE.L	#$00001400,D0
applyDistanceClamps:
	MOVE.W	D0,clampedDistanceX
	MOVE.W	D0,D6
	MOVE.W	previousDistanceX,D3
	SUB.W	D3,D0
	JSR	applyMomentumAmplification
	BMI	resetTrackPosition
	MOVE.W	lateralVelocityX,D4
	MOVE.W	D0,lateralVelocityX
	CMP.W	#$0400,D0
	BLT	checkTrackThreshold
	CMP.W	#$0200,D4
	BGE	checkTrackThreshold
	ADDQ.B	#$01,offTrackCollisionFlag
checkTrackThreshold:
	MOVE.W	lateralVelocityX,D0
	MOVE.B	trackWidthMultiplier,D3
	ASL.W	#$08,D3
	SUB.W	D3,D0
	BMI	clearTrackCounters
	CMP.W	#$0700,D0
	BLT	clearTrackCounters
	CMP.W	maxDistanceFromTrack,D0
	BCS	updateMaxTrackPosition
	MOVE.W	D0,maxDistanceFromTrack
updateMaxTrackPosition:
	SUB.W	#$0600,D0
	TST.B	trackDirectionFlag
	BMI	processTrackDirection
	ADDQ.B	#$01,offTrackFrameCounter
	MOVE.B	offTrackFrameCounter,D3
	CMP.B	offTrackFrameThreshold,D3
	BGE	processTrackDirection
	LSR.W	#$08,D0
	MOVE.B	D0,D3
	LSR.B	#$01,D3
	ADD.B	D3,D0
	ADD.B	accumulatedOffTrackForceX,D0
	BCC	preventSpeedOverflow
	MOVE.B	#$FF,D0
preventSpeedOverflow:
	MOVE.B	D0,accumulatedOffTrackForceX
	MOVE.B	#$80,offTrackAccumulationFlag
processTrackDirection:
	MOVE.W	lateralVelocityX,D0
	CMP.W	#$1200,D0
	BCS	enforceTrackBounds
	MOVE.W	#$11FF,lateralVelocityX
enforceTrackBounds:
	BRA	finalizeTrackUpdate

resetTrackPosition:
	MOVE.W	#$0000,lateralVelocityX
clearTrackCounters:
	MOVE.B	#$00,offTrackFrameCounter
finalizeTrackUpdate:
	MOVE.W	clampedDistanceX,previousDistanceX
	MOVE.L	carWorldY,D0
	SUB.L	trackCenterY,D0
	SUB.L	trackOffsetAdjustment,D0
	MOVE.L	D0,distanceFromTrackY
	BMI	negativeYDistanceClamp
	CMP.L	#$00001400,D0
	BCS	applyYDistanceClamps
	BRA	positiveYDistanceClamp

negativeYDistanceClamp:
	CMP.L	#$FFFFFD00,D0
	BCC	applyYDistanceClamps
	MOVE.L	#$FFFFFD00,D0
	BRA	applyYDistanceClamps

positiveYDistanceClamp:
	MOVE.L	#$00001400,D0
applyYDistanceClamps:
	MOVE.W	D0,clampedDistanceY
	MOVE.W	D0,D6
	MOVE.W	previousDistanceY,D3
	SUB.W	D3,D0
	JSR	applyMomentumAmplification
	BMI	resetYTrackPosition
	MOVE.W	lateralVelocityY,D4
	MOVE.W	D0,lateralVelocityY
	CMP.W	#$0400,D0
	BLT	checkYTrackThreshold
	CMP.W	#$0200,D4
	BGE	checkYTrackThreshold
	ADDQ.B	#$01,offTrackCollisionFlag
checkYTrackThreshold:
	MOVE.W	lateralVelocityY,D0
	MOVE.B	trackWidthMultiplier,D3
	ASL.W	#$08,D3
	SUB.W	D3,D0
	BMI	lbC05371A
	CMP.W	#$0700,D0
	BLT	lbC05371A
	CMP.W	maxDistanceFromTrack,D0
	BCS	lbC0536B0
	MOVE.W	D0,maxDistanceFromTrack
lbC0536B0:
	SUB.W	#$0600,D0
	TST.B	trackDirectionFlag
	BMI	lbC0536F8
	ADDQ.B	#$01,offTrackFrameCounter
	MOVE.B	offTrackFrameCounter,D3
	CMP.B	offTrackFrameThreshold,D3
	BGE	lbC0536F8
	LSR.W	#$08,D0
	MOVE.B	D0,D3
	LSR.B	#$01,D3
	ADD.B	D3,D0
	ADD.B	accumulatedOffTrackForceY,D0
	BCC	lbC0536EA
	MOVE.B	#$FF,D0
lbC0536EA:
	MOVE.B	D0,accumulatedOffTrackForceY
	MOVE.B	#$80,offTrackAccumulationFlag
lbC0536F8:
	MOVE.W	lateralVelocityY,D0
	CMP.W	#$1200,D0
	BCS	lbC05370E
	MOVE.W	#$11FF,lateralVelocityY
lbC05370E:
	BRA	lbC053722

resetYTrackPosition:
	MOVE.W	#$0000,lateralVelocityY
lbC05371A:
	MOVE.B	#$00,offTrackFrameCounter
lbC053722:
	MOVE.W	clampedDistanceY,previousDistanceY
	MOVE.L	carWorldZ,D0
	SUB.L	trackCenterZ,D0
	SUB.L	trackOffsetAdjustment,D0
	MOVE.L	D0,distanceFromTrackZ
	BMI	lbC053756
	CMP.L	#$00001400,D0
	BCS	lbC053770
	BRA	lbC05376A

lbC053756:
	CMP.L	#$FFFFFD00,D0
	BCC	lbC053770
	MOVE.L	#$FFFFFD00,D0
	BRA	lbC053770

lbC05376A:
	MOVE.L	#$00001400,D0
lbC053770:
	MOVE.W	D0,clampedDistanceZ
	MOVE.W	D0,D6
	MOVE.W	previousDistanceZ,D3
	SUB.W	D3,D0
	JSR	applyMomentumAmplification
	BMI	lbC05383A
	MOVE.W	lateralVelocityZ,D4
	MOVE.W	D0,lateralVelocityZ
	CMP.W	#$0400,D0
	BLT	lbC0537AC
	CMP.W	#$0200,D4
	BGE	lbC0537AC
	ADDQ.B	#$01,offTrackCollisionFlag
lbC0537AC:
	MOVE.W	lateralVelocityZ,D0
	MOVE.B	trackWidthMultiplier,D3
	ASL.W	#$08,D3
	SUB.W	D3,D0
	BMI	lbC053842
	CMP.W	#$0700,D0
	BLT	lbC053842
	CMP.W	maxDistanceFromTrack,D0
	BCS	lbC0537D8
	MOVE.W	D0,maxDistanceFromTrack
lbC0537D8:
	SUB.W	#$0600,D0
	TST.B	trackDirectionFlag
	BMI	lbC053820
	ADDQ.B	#$01,offTrackFrameCounter
	MOVE.B	offTrackFrameCounter,D3
	CMP.B	offTrackFrameThreshold,D3
	BGE	lbC053820
	LSR.W	#$08,D0
	MOVE.B	D0,D3
	LSR.B	#$01,D3
	ADD.B	D3,D0
	ADD.B	accumulatedOffTrackForceZ,D0
	BCC	lbC053812
	MOVE.B	#$FF,D0
lbC053812:
	MOVE.B	D0,accumulatedOffTrackForceZ
	MOVE.B	#$80,offTrackAccumulationFlag
lbC053820:
	MOVE.W	lateralVelocityZ,D0
	CMP.W	#$1200,D0
	BCS	lbC053836
	MOVE.W	#$11FF,lateralVelocityZ
lbC053836:
	BRA	lbC05384A

lbC05383A:
	MOVE.W	#$0000,lateralVelocityZ
lbC053842:
	MOVE.B	#$00,offTrackFrameCounter
lbC05384A:
	MOVE.W	clampedDistanceZ,previousDistanceZ
	MOVE.W	lateralVelocityX,D0
	ADD.W	lateralVelocityY,D0
	ASR.W	#$01,D0
	MOVE.W	D0,lateralVelocity
	ADD.W	lateralVelocityZ,D0
	ASR.W	#$01,D0
	MOVE.W	D0,collisionStateFlags1
	JSR	calculateSpatialDistortion
	MOVE.W	lateralVelocityX,D0
	SUB.W	lateralVelocityY,D0
	MOVE.W	D0,D3
	ASL.W	#$01,D0
	ADD.W	D3,D0
	BPL	lbC053894
	NEG.W	D0
lbC053894:
	CMP.W	#$1000,D0
	BLT	lbC0538A0
	MOVE.W	#$1000,D0
lbC0538A0:
	TST.W	D3
	BPL	lbC0538A8
	NEG.W	D0
lbC0538A8:
	MOVE.W	D0,lateralMotion
	MOVE.W	lateralVelocity,D0
	SUB.W	lateralVelocityZ,D0
	MOVE.W	D0,verticalMotion
	MOVE.B	collisionStateFlags1,D0
	OR.B	collisionStateFlags2,D0
	MOVE.B	D0,playerStateFlag
	BNE	lbC053942
	TST.B	raceStartTimer
	BNE	lbC053942
	MOVE.W	#$FF80,D3
	MOVE.W	cameraAngleX,D0
	BPL	lbC053914
	MOVE.B	currentTrackID,D0
	CMP.B	#$07,D0
	BNE	lbC053904
	MOVE.B	#$F8,D1
	BRA	lbC053920

lbC053904:
	CMP.B	#$04,D0
	BNE	lbC053942
	MOVE.W	#$FFF8,D3
	BRA	lbC053920

lbC053914:
	CMP.W	#$1000,D0
	BLT	lbC053920
	MOVE.W	#$FF00,D3
lbC053920:
	SUB.W	verticalMotion,D3
	BPL	lbC053942
	MOVE.B	rotationSpeedX,D0
	BPL	lbC05393C
	CMP.B	#$FF,D0
	BNE	lbC053942
lbC05393C:
	MOVE.W	D3,verticalMotion
lbC053942:
	JSR	handleRaceStartCountdown
	MOVE.W	yawAngleOffset,lbW00D646
	JSR	handleCollisionBetweenCars
	TST.B	crashSoundCooldownTimer
	BEQ	lbC053968
	SUBQ.B	#$01,crashSoundCooldownTimer
lbC053968:
	TST.B	offTrackCollisionFlag
	BEQ	lbC0539B4
	MOVE.B	maxDistanceFromTrack,D0
	CMP.B	#$07,D0
	BCC	lbC053984
	MOVE.B	#$07,D0
lbC053984:
	ASL.B	#$02,D0
	CMP.B	#$40,D0
	BCS	lbC053992
	MOVE.B	#$40,D0
lbC053992:
	MOVE.B	D0,sampleCrashVolume
	TST.B	crashSoundCooldownTimer
	BNE	lbC0539B4
	MOVE.B	#$03,D0
	JSR	playAudioSample
	MOVE.B	#$05,crashSoundCooldownTimer
lbC0539B4:
	RTS

updateCarOrientation:
	MOVE.W	baseRollAngle,D0
	ADD.W	carPitchAdjustment,D0
	MOVE.W	D0,adjustedPitchAngle
	MOVE.B	gasOutputAccumulatorValue,D0
	OR.B	carVelocity,D0
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
	ADD.W	yawAngleOffset,D0
	ADD.W	additionalYawOffset,D0
	MOVE.W	D0,adjustedYawAngle
	JSR	calculateRollAngleTransition
	RTS

updateVelocityDamping:
	MOVE.W	rotationSpeedX,D3
	ASR.W	#$01,D3			; fixed $04
	MOVE.W	verticalMotion,D0
	SUB.W	D3,D0
	TST.B	playerStateFlag
	BEQ	lbC053A5C
	MOVE.W	adjustedYawAngle,D3
	ASR.W	#$02,D3
	ADD.W	D3,D0
lbC053A5C:
	MOVE.W	D0,lbW00D5FC
	MOVE.W	rotationSpeedZ,D3
	ASR.W	#$01,D3			; fixed $04
	MOVE.W	lateralMotion,D0
	SUB.W	D3,D0
	MOVE.W	D0,lbW00D600
	RTS

calculateRollAngleTransition:
	MOVE.W	baseTargetRoll,D4
	ADD.W	rollAngleModifier,D4
	MOVE.W	D4,D3
	SUB.W	targetRollAngle,D3
	BPL	lbC053A94
	NEG.W	D3
lbC053A94:
	JSR	getSteeringMultiplier
	CMP.W	D0,D3
	BCS	lbC053ABE
	TST.B	targetRollAngle
	BPL	lbC053AAC
	NEG.W	D0
lbC053AAC:
	SUB.W	D0,D4
	MOVE.W	D4,adjustedRollAngle
	MOVE.B	#$80,rollTransitionFlag
	RTS

lbC053ABE:
	MOVE.W	rollAngleModifier,D0
	SUB.W	targetRollAngle,D0
	MOVE.W	D0,adjustedRollAngle
	MOVE.B	#$00,rollTransitionFlag
	RTS

getSteeringMultiplier:
	TST.B	playerStateFlag
	BEQ	lbC053AEE
	MOVE.W	carPitchAdjustment,D0
	ASL.W	#$01,D0
	RTS

lbC053AEE:
	MOVE.W	#$0000,D0
	RTS

updateCollisionState:
	MOVE.L	#$00000001,D7
	TST.B	playerStateFlag
	BEQ	lbC053B2E
	MOVE.B	lbW00D646,D0
	BPL	lbC053B12
	EOR.B	#$FF,D0
lbC053B12:
	CMP.B	#$03,D0
	BGE	lbC053B3E
	TST.B	collisionStateFlags
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
	MOVE.W	targetRollAngle,D0
	BPL	lbC053B52
	NEG.W	D0
lbC053B52:
	MOVE.W	lbW00D62E,D3
	BPL	lbC053B5E
	NEG.W	D3
lbC053B5E:
	CMP.W	D3,D0
	BGE	lbC053B66
	MOVE.W	D3,D0
lbC053B66:
	MOVE.W	carVelocity,D3
	BPL	lbC053B72
	NEG.W	D3
lbC053B72:
	CMP.W	D3,D0
	BGE	lbC053B7A
	MOVE.W	D3,D0
lbC053B7A:
	MOVE.L	#$00000005,D7
	TST.B	engineTimer
	BPL	lbC053BA4
	TST.B	carCrashedFlag
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
	SUB.W	D3,lbW00D5F6
	MOVE.W	worldYSpeed,D3
	MULS	D0,D3
	SWAP	D3
	ASR.W	D7,D3
	SUB.W	D3,lbW00D5F8
	MOVE.W	worldZSpeed,D3
	MULS	D0,D3
	SWAP	D3
	ASR.W	D7,D3
	SUB.W	D3,lbW00D5FA
	RTS

calculateSpatialDistortion:
	MOVE.W	#$0000,lbW00D64A
	MOVE.L	distanceFromTrackX,D0
	ADD.L	distanceFromTrackY,D0
	ASR.L	#$01,D0
	SUB.L	distanceFromTrackZ,D0
	ASR.L	#$04,D0
	MOVE.W	D0,D3
	EOR.W	#$8000,D3
	MOVE.W	D3,lbW00D64C
	JSR	lbC053D24
	MOVE.B	segmentDirectionSource,segmentDirectionTemp2
	MOVE.B	segmentDirectionTemp1,lbB00D652
	MOVE.L	distanceFromTrackX,D0
	SUB.L	distanceFromTrackY,D0
	ASR.L	#$03,D0
	MOVE.W	D0,lbW00D648
	JSR	lbC053D24
	MOVE.B	segmentDirectionTemp2,curveMagnitude
	MOVE.B	segmentDirectionSource,D0
	JSR	multiplyAndRandomize
	MOVE.B	D0,lbB00D650
	MOVE.B	segmentDirectionTemp1,D0
	JSR	multiplyAndRandomize
	MOVE.B	D0,lbB00D64E
	MOVE.B	lbB00D64E,curveMagnitude
	MOVE.B	lbW00D648,trackSideIndicatorCopy
	MOVE.W	collisionStateFlags1,D0
	MOVE.B	curveMagnitude,D3
	AND.W	#$00FF,D3
	TST.B	trackSideIndicatorCopy
	BPL	lbC053C98
	NEG.W	D3
lbC053C98:
	ASL.W	#$07,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	MOVE.W	D0,rollAngleModifier
	MOVE.B	lbB00D650,curveMagnitude
	MOVE.B	lbW00D64A,trackSideIndicatorCopy
	MOVE.W	collisionStateFlags1,D0
	MOVE.B	curveMagnitude,D3
	AND.W	#$00FF,D3
	TST.B	trackSideIndicatorCopy
	BPL	lbC053CD6
	NEG.W	D3
lbC053CD6:
	ASL.W	#$07,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	MOVE.W	D0,carPitchAdjustment
	MOVE.B	lbB00D652,curveMagnitude
	MOVE.B	lbW00D64C,trackSideIndicatorCopy
	MOVE.W	collisionStateFlags1,D0
	MOVE.B	curveMagnitude,D3
	AND.W	#$00FF,D3
	TST.B	trackSideIndicatorCopy
	BPL	lbC053D14
	NEG.W	D3
lbC053D14:
	ASL.W	#$07,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	MOVE.W	D0,yawAngleOffset
	RTS

lbC053D24:
	TST.W	D0
	BPL	lbC053D2C
	NEG.W	D0
lbC053D2C:
	MOVE.B	#$FF,D1
	CMP.W	#$0100,D0
	BGE	lbC053D3A
	MOVE.B	D0,D1
lbC053D3A:
	MOVE.B	D1,segmentDirectionTemp1
	LSR.B	#$01,D1
	MOVE.L	#attenuationTable,A0
	MOVE.B	$00(A0,D1.W),D0
	MOVE.B	D0,segmentDirectionSource
	RTS

calculate3DProjection:
	MOVE.W	lateralVelocity,D0
	MOVE.W	lbW00D4F8,D3
	TST.B	segmentConfigLoadedFlag
	BPL	lbC053D9C
	ASR.W	#$01,D0
	ASR.W	#$01,D3
	MOVE.W	D3,lbW00D536
	ADD.B	#$31,lbW00D536
	ASR.W	#$01,D3
	ADD.W	#$4900,D3
	JSR	calculateDivision
	SUB.W	lbW00D52E,D0
	ASR.W	#$03,D0
	MOVE.L	#coordinateLookupTable,A0
	MOVE.W	D0,$00(A0,D1.W)
	RTS

lbC053D9C:
	JSR	calculateDivision
	SUB.W	lbW00D52E,D0
	ASR.W	#$03,D0
	MOVE.L	#coordinateLookupTable,A0
	MOVE.W	D0,$00(A0,D1.W)
	JSR	lbC0566E8
	MOVE.W	D0,lbW00D536
	RTS

transformCoordinate:
	MOVE.L	#trackSegmentData,A0
	MOVE.W	$00(A0,D1.W),D0
	SUB.W	lbW00D4FA,D0
	NEG.W	D0
	ASR.W	#$02,D0
	MOVE.W	lbW00D536,D3
	TST.B	segmentConfigLoadedFlag
	BPL	lbC053DF0
	MOVE.W	#$4C1B,D4
	MULS	D4,D0
	ASL.L	#$01,D0
	SWAP	D0
lbC053DF0:
	JSR	calculateDivision
	SUB.W	lbW00D542,D0
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
	BRA	lbC053EBA

lbC053EB2:
	JSR	renderCharacter
	ADDQ.W	#$01,D3
lbC053EBA:
	MOVEA.L	#LOADgameposit.MSG,A1
	MOVE.B	$00(A1,D3.W),D0
	CMP.B	#$FF,D0
	BNE	lbC053EB2
	RTS

displaySeasonSelection:
	JSR	drawScreenFrame
	JSR	copyGraphicsRegion
	MOVE.W	#$012A,D1
	JSR	displayMessageWithColors
	JSR	waitForInputPress
	JSR	drawScreenFrame
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	MOVE.W	#$0000,D1
	TST.B	networkSyncStateFlag
	BEQ	lbC054086
	MOVE.W	#$0016,D1
lbC054086:
	JSR	displayMessage
	JSR	copyGraphicsRegion
	MOVE.L	renderFrameBuffer,-(SP)
	MOVE.L	displayFrameBuffer,renderFrameBuffer
	MOVE.B	#$80,disableDirectionalInputFlag
	JSR	handleSeasonSelectionDisplay
	MOVE.B	#$00,disableDirectionalInputFlag
	MOVE.B	#$03,D0
	JSR	setForegroundColor
	MOVE.L	(SP)+,renderFrameBuffer
	RTS

handleSeasonSelectionDisplay:
	JSR	loadSaveGameFromDisk
	TST.B	lbB00D492
	BPL	lbC0540DC
	RTS

lbC0540DC:
	JSR	displayAllSaveSlots
	MOVE.B	#$00,textTransparencyMode
lbC0540EA:
	MOVE.B	#$0F,lbB0544B8
	MOVE.B	#$0B,lbB0544B9
	MOVE.B	selectedSaveSlotIndex,D0
	TST.B	networkSyncStateFlag
	BEQ	lbC054110
	MOVE.B	lbB0544B7,D0
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
	TST.B	networkSyncStateFlag
	BNE	lbC05419A
lbC05416C:
	JSR	waitForInputPress
	JSR	processDirectionalInput
	TST.B	inputCancelFlag
	BNE	handleSlotNavigation
	CMP.B	#$0D,D0
	BNE	lbC05416C
	CMP.B	#$20,lbB01066B
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
	TST.B	inputCancelFlag
	BNE	handleSlotNavigation
	CMP.B	#$20,lbB01066B
	BNE	lbC05424A
	MOVE.B	#$7F,D1
	MOVE.W	D1,D1
	JSR	displayMessageWithColors
	MOVE.B	#$00,currentInputPosition
	BRA	lbC05419A

handleSlotNavigation:
	BMI	lbC054366
	JSR	refreshSaveSlotDisplay
	BTST	#$06,inputCancelFlag
	BNE	lbC054240
	BTST	#$05,inputCancelFlag
	BNE	lbC054236
	BTST	#$03,inputCancelFlag
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
	MOVE.L	#networkTransferBuffer,A0
	TST.B	networkSyncStateFlag
	BEQ	lbC0542D2
	JSR	displaySlotRight
	BEQ	advanceSecondarySlot
	BPL	lbC05428A
	RTS

advanceSecondarySlot:
	MOVE.B	currentSaveSlotIndex,D3
	ADDQ.B	#$01,D3
	CMP.B	#$1E,D3
	BLT	lbC0542C4
	MOVE.B	#$00,D3
lbC0542C4:
	MOVE.B	D3,lbB0544B7
	JSR	saveSlotTextAndDisplay
	RTS

lbC0542D2:
	JSR	displaySlotLeft
	BEQ	lbC0542E2
	BPL	lbC05428A
	RTS

lbC0542E2:
	MOVE.B	currentSaveSlotIndex,selectedSaveSlotIndex
	JSR	saveSlotTextAndDisplay
	MOVE.B	#$00,D0
	JSR	syncMultiplayerRecords
	RTS

displayConfirmationDialog:
	MOVE.B	#$00,lbB00D492
	TST.B	D0
	BNE	lbC05430E
	RTS

lbC05430E:
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
	BEQ	lbC054366
	MOVE.B	#$03,D0
	JSR	setForegroundColor
	MOVE.W	#$0091,D1
	JSR	displayMessageWithColors
	MOVE.B	#$32,D2
	JSR	delayWithParam
	MOVE.B	#$01,D0
	RTS

lbC054366:
	MOVE.B	#$80,lbB00D492
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
	TST.B	networkSyncStateFlag
	BEQ	lbC0543F6
	MOVE.B	D0,lbB0544B7
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

displaySlotLeft:
	MOVE.W	#$0000,D3
	BRA	lbC054480

displaySlotRight:
	MOVE.W	#$0001,D3
lbC054480:
	CMP.W	#$0320,D3
	BCC	lbC0544AA
	MOVE.W	D0,D1
	MOVE.W	#$0000,D0
	MOVE.W	#$0001,D2
	MOVE.L	#memory_0400,A1
	JSR	renderSlotGraphics
	CLR.W	D1
	CLR.W	D2
lbC0544A2:
	JSR	displayConfirmationDialog
	RTS

lbC0544AA:
	MOVE.B	#$80,D0
	BRA	lbC0544A2

saveSlotTextAndDisplay:
	CLR.L	D0
	MOVE.W	lbW054632,D0
	SUB.L	#$00000017,D0
	ASL.L	#$04,D0
	MOVE.W	#$0007,D3
	MOVE.L	#lbB01066B,A0
	MOVE.L	#memory_7A21A,A1
	ADD.L	D0,A1
lbC0544E0:
	MOVE.B	$00(A0,D3.W),$00(A1,D3.W)
	DBRA	D3,lbC0544E0
	MOVE.B	#$00,$000F(A1)
lbC0544F0:
	MOVE.L	#memory_7A21A,A0
	MOVE.W	#$0016,D0
	MOVE.L	#$47826653,memory_7A234
	MOVE.B	selectedSaveSlotIndex,memory_7A224
	MOVE.B	lbB0544B7,memory_7A225
	JSR	displaySlotRight
	BEQ	lbC054526
	BPL	lbC0544F0
lbC054526:
	RTS

loadSaveGameFromDisk:
	MOVE.B	#$01,lbB054608
lbC054530:
	MOVE.B	#$00,saveSlotHighlightFlag
	MOVE.B	#$00,lbB00D492
	MOVE.L	#memory_7A21A,A0
	MOVE.W	#$0016,D0
	JSR	displaySlotLeft
	BEQ	lbC05455C
	BMI	lbC054606
	BRA	loadSaveGameFromDisk

lbC05455C:
	MOVE.B	memory_7A224,D0
	MOVE.B	memory_7A225,D3
	CMP.L	#$47826653,memory_7A234
	BEQ	lbC0545FA
	MOVE.B	#$80,saveSlotHighlightFlag
	TST.B	networkSyncStateFlag
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
	MOVE.B	#$80,lbB00D492
	BRA	lbC0545F2

lbC0545C0:
	JSR	drawScreenFrame
	MOVE.B	#$01,textYOffset
	MOVE.W	#$0000,D1
	TST.B	networkSyncStateFlag
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
	MOVE.B	D3,lbB0544B7
lbC054606:
	RTS

renderSlotGraphicsAtPosition:
	MOVE.W	#$0000,D0
	MOVE.W	#$0005,D1
	MOVE.W	#$0001,D2
	MOVE.W	#$0000,D3
	MOVE.L	#memory_7A21A,A0
	MOVE.L	#memory_0400,A1
	JSR	renderSlotGraphics
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
	MOVE.L	#lbB01066B,A1
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
	MOVE.L	#memory_7A21A,A0
	LEA	$00(A0,D0.W),A0
	MOVE.W	#$0000,D3
lbC054700:
	TST.B	lbB0544BC
	BPL	lbC054718
	MOVE.L	#lbB01066B,A0
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

renderSlotGraphics:
	JSR	setupSlotRenderingParams
	JMP	finalizeGraphicsRendering

;	ds.w	1

setupSlotRenderingParams:
	MOVEM.L	D1-D7/A0-A5,-(SP)
	LINK	A6,#-$0024
	MOVE.W	D0,D4
	AND.W	#$0003,D4
	MOVE.W	D4,-$0024(A6)
	MOVE.W	D1,-$0022(A6)
	MOVE.W	D2,-$0020(A6)
	MOVE.W	D3,-$001E(A6)
	MOVE.L	A0,-$001C(A6)
	MOVE.L	A1,-$0018(A6)
	ROL.W	#$01,D0
	AND.W	#$0001,D0
	ADDQ.W	#$01,D0
	MOVE.W	D0,-$0014(A6)
	MOVEQ	#$1E,D0
	MOVE.W	D2,D3
	BEQ	lbC054870
	ADD.W	D1,D3
	CMP.W	#$06E0,D3
	BGT	lbC054870
	AND.L	#$18FF,D1
	DIVU	#$000B,D1
	CMP.W	#$0001,-$0014(A6)
	BEQ.S	lbC0547DE
	ADD.W	D1,D1
lbC0547DE:
	MOVE.W	D1,-$0012(A6)
	SWAP	D1
	MOVE.W	D1,-$0010(A6)
	BSR	startDiskMotorAndWait
lbC0547EC:
	MOVE.W	-$0010(A6),D0
	MOVEQ	#$0B,D1
	SUB.W	D0,D1
	CMP.W	-$0020(A6),D1
	BLE.S	lbC0547FE
	MOVE.W	-$0020(A6),D1
lbC0547FE:
	MOVE.W	D1,-$000E(A6)
	BSR	readDiskSectorWithRetry
	BNE.S	readDiskTrack
	CMP.W	#$0001,-$001E(A6)
	BNE.S	lbC05481A
	BSR	initializeMFMTrackBuffer
	BSR	writeBufferToDiskTrack
	BNE.S	readDiskTrack
lbC05481A:
	MOVE.W	-$0020(A6),D0
	SUB.W	-$000E(A6),D0
	BEQ.S	readDiskTrack
	MOVE.W	D0,-$0020(A6)
	MOVE.W	-$000E(A6),D0
	LSL.L	#$08,D0
	ADD.L	D0,D0
	ADD.L	D0,-$001C(A6)
	CLR.W	-$0010(A6)
	MOVE.W	-$0014(A6),D0
	ADD.W	D0,-$0012(A6)
	BRA.S	lbC0547EC

readDiskTrack:
	MOVE.L	D0,-(SP)
	BSR	setupDiskHardware
	BSR	waitBlitterDMADisabled
	MOVE.L	(SP)+,D0
	BEQ.S	lbC054870
	MOVEQ	#$00,D1
	MOVE.W	-$0012(A6),D1
	CMP.W	#$0001,-$0014(A6)
	BEQ.S	lbC054860
	LSR.W	#$01,D1
lbC054860:
	MULU	#$000B,D1
	ADD.W	-$0010(A6),D1
	ADD.W	-$0006(A6),D1
	MOVE.L	D1,$0028(SP)
lbC054870:
	UNLK	A6
	TST.L	D0
	MOVEM.L	(SP)+,D1-D7/A0-A5
	RTS

readDiskSectorWithRetry:
	MOVEQ	#$04,D4
lbC05487C:
	CLR.W	-$0004(A6)
	CLR.W	-$0006(A6)
	CLR.W	-$0008(A6)
	MOVE.W	-$0012(A6),D2
	BSR	positionDiskHead
	BNE	lbC054944
	MOVEQ	#$1D,D0
	BTST	#$02,$00BFE001
	BEQ	lbC054944
	MOVE.L	-$0018(A6),A5
	LEA	$0400(A5),A5
	MOVE.L	#$AAAAAAAA,(A5)
	MOVE.W	#$4489,$0004(A5)
	BSR	clearTrackBuffer
	BSR	waitBlitterDMADisabled
	BSR	performDiskRead
	BNE	lbC054944
	MOVE.W	-$000C(A6),D0
	BEQ.S	lbC05491A
	MULU	#$0440,D0
	LEA	$0006(A5),A0
	BSR	validateTrackData
	LEA	_custom+intreqr,A4
	BSR	waitDiskOperation
	BNE.S	lbC054952
	CMP.W	#$0001,-$001E(A6)
	BEQ.S	lbC0548F6
	MOVE.W	-$0006(A6),D0
	SUB.W	-$000E(A6),D0
	BEQ.S	lbC054956
lbC0548F6:
	MOVE.L	-$0018(A6),A5
	LEA	$0400(A5),A5
	MOVE.W	-$000C(A6),D0
	MULU	#$0440,D0
	ADD.L	D0,A5
	MOVE.L	#$AAAAAAAA,(A5)
	MOVE.W	#$4489,$0004(A5)
	MOVE.L	A5,A0
	BSR	encodeMFMClockBits
lbC05491A:
	MOVE.W	-$000A(A6),D0
	BEQ.S	lbC054938
	MULU	#$0440,D0
	LEA	$0006(A5),A0
	BSR	validateTrackData
	LEA	-$0002(A6),A4
	CLR.W	(A4)
	BSR	waitDiskOperation
	BNE.S	lbC054952
lbC054938:
	MOVE.W	-$0006(A6),D0
	SUB.W	-$000E(A6),D0
	BEQ.S	lbC054956
	MOVEQ	#$1A,D0
lbC054944:
	MOVE.L	D0,-(SP)
	MOVEQ	#$02,D2
	BSR	positionDiskHead
	BSR	recalibrateDiskHeadToTrack0
	MOVE.L	(SP)+,D0
lbC054952:
	DBRA	D4,lbC05487C
lbC054956:
	BSR	stopDiskDMA
	RTS

writeBufferToDiskTrack:
	MOVEQ	#$04,D2
	CLR.W	-$0006(A6)
lbC054962:
	BSR	applyDriveConfiguration
	MOVE.L	#$000000C8,D0
	BSR	driveDelay
	MOVEQ	#$1C,D0
	BTST	#$03,$00BFE001
	BEQ.S	lbC0549CA
	LEA	_custom,A0
	MOVE.W	#$4000,dsklen(A0)
	MOVE.L	-$0018(A6),dskpt(A0)
	MOVE.W	#$6600,adkcon(A0)
	MOVE.W	#$9100,adkcon(A0)
	CMP.W	#$0050,-$0012(A6)
	BCS.S	lbC0549A8
	MOVE.W	#$A000,adkcon(A0)
lbC0549A8:
	MOVE.W	#(DMAF_DISK|DMAF_SETCLR),dmacon(A0)
	MOVE.W	#INTF_DSKBLK,intreq(A0)
	MOVE.W	#$D961,dsklen(A0)
	MOVE.W	#$D961,dsklen(A0)
	BSR	checkDiskReadStatus
	BEQ.S	lbC0549CA
	DBRA	D2,lbC054962
lbC0549CA:
	MOVE.L	D0,-(SP)
	MOVE.L	#$00000002,D0
	BSR	driveDelay
	MOVE.L	(SP)+,D0
	RTS

performDiskRead:
	MOVEQ	#$0A,D2
lbC0549DC:
	LEA	$0006(A5),A0
	MOVE.W	#$0040,D0
	BSR	validateTrackData
	BSR	checkDiskReadStatus
	BNE.S	lbC054A24
	BSR	validateSectorHeaderChecksum
	BEQ.S	lbC0549FA
	DBRA	D2,lbC0549DC
	BRA.S	lbC054A26

lbC0549FA:
	BSR	decodeSectorHeader
	BNE.S	lbC054A2A
	CMP.W	-$0012(A6),D1
	BNE.S	lbC054A2A
	CMP.B	#$0B,D2
	BGE.S	lbC054A2A
	CMP.B	#$0B,D3
	BGT.S	lbC054A2A
	SUBQ.B	#$01,D3
	MOVE.W	D3,-$000C(A6)
	MOVE.W	#$000B,-$000A(A6)
	SUB.W	D3,-$000A(A6)
	MOVEQ	#$00,D0
lbC054A24:
	RTS

lbC054A26:
	MOVEQ	#$18,D0
	RTS

lbC054A2A:
	MOVEQ	#$1B,D0
	RTS

lbC054A2E:
	MOVEQ	#$19,D0
	RTS

waitDiskOperation:
	MOVE.L	-$0018(A6),A5
	LEA	$0400(A5),A5
	MOVE.W	-$0008(A6),D0
	MULU	#$0440,D0
	ADD.L	D0,A5
	MOVE.L	#$00001770,D0
	BSR	setDiskTimeout
lbC054A4E:
	BTST	#$01,$0001(A4)
	BNE	lbC054B56
	BSR	checkTimeoutExpired
	BEQ	lbC054B5A
	TST.L	$0440(A5)
	BEQ.S	lbC054A4E
	BSR	validateSectorHeaderChecksum
	BNE.S	lbC054A26
	BSR	decodeSectorHeader
	BNE.S	lbC054A2A
	CMP.W	-$0012(A6),D1
	BNE.S	lbC054A2A
	MOVE.W	D2,D3
	LEA	$0008(A5),A0
	BSR	decodeMFMLongwords
	MOVE.B	#$0B,D0
	SUB.B	-$0007(A6),D0
	LEA	$0008(A5),A0
	BSR	writeMFMEncodedLongword
	BSR	calculateMFMChecksum
	LEA	$0030(A5),A0
	BSR	writeMFMEncodedLongword
	CMP.W	-$0010(A6),D3
	BLT	lbC054B48
	MOVE.W	-$000E(A6),D0
	ADD.W	-$0010(A6),D0
	CMP.W	D0,D3
	BGE	lbC054B48
	BTST	#$01,$0001(A4)
	BNE	lbC054B56
	MOVE.W	-$0004(A6),D0
	BTST	D3,D0
	BNE	lbC054B48
	CMP.W	#$0001,-$001E(A6)
	BNE.S	lbC054B06
	BSR	calculateSectorOffset
	MOVE.L	-$001C(A6),A0
	ADD.L	D1,A0
	LEA	$0040(A5),A1
	BSR	fillDataWithBlitter
	BTST	#$01,$0001(A4)
	BNE	lbC054B56
	LEA	$0040(A5),A0
	MOVE.W	#$0400,D1
	BSR	calculateMFMChecksumWithParams
	LEA	$0038(A5),A0
	BSR	writeMFMEncodedLongword
	BSR	markSectorAsRead
	BRA.S	lbC054B48

lbC054B06:
	LEA	$0040(A5),A0
	MOVE.W	#$0400,D1
	BSR	calculateMFMChecksumWithParams
	MOVE.L	D0,-(SP)
	LEA	$0038(A5),A0
	BSR	decodeMFMLongwords
	CMP.L	(SP)+,D0
	BNE	lbC054A2E
	BTST	#$01,$0001(A4)
	BNE.S	lbC054B56
	BSR.S	calculateSectorOffset
	LEA	$0040(A5),A0
	MOVE.L	-$001C(A6),A1
	ADD.L	D1,A1
	BSR	copyDataWithBlitter
	BSR	markSectorAsRead
	MOVE.W	-$0006(A6),D0
	CMP.W	-$000E(A6),D0
	BEQ.S	lbC054B56
lbC054B48:
	ADDQ.W	#$01,-$0008(A6)
	CMP.W	#$000B,-$0008(A6)
	BNE	waitDiskOperation
lbC054B56:
	MOVEQ	#$00,D0
	RTS

lbC054B5A:
	MOVEQ	#-$01,D0
	RTS

calculateSectorOffset:
	MOVE.L	D3,D1
	SUB.W	-$0010(A6),D1
	MOVE.L	#$00000200,D0
	MULU	D0,D1
	RTS

markSectorAsRead:
	MOVE.W	-$0004(A6),D0
	BSET	D3,D0
	MOVE.W	D0,-$0004(A6)
	ADDQ.W	#$01,-$0006(A6)
	RTS

clearTrackBuffer:
	MOVE.L	A5,A0
	MOVEQ	#$0A,D1
	MOVEQ	#$00,D0
lbC054B84:
	LEA	$0440(A0),A0
	MOVE.L	D0,(A0)
	DBRA	D1,lbC054B84
	RTS

decodeSectorHeader:
	LEA	$0008(A5),A0
	BSR	decodeMFMLongwords
	MOVE.W	D0,D3
	AND.W	#$00FF,D3
	MOVE.W	D0,D2
	LSR.W	#$08,D2
	SWAP	D0
	MOVE.W	D0,D1
	AND.W	#$00FF,D1
	LSR.W	#$08,D0
	CMP.B	#$FF,D0
	RTS

decodeMFMLongwords:
	MOVE.L	(A0)+,D0
	MOVE.L	(A0)+,D1
	AND.L	#$55555555,D0
	AND.L	#$55555555,D1
	ADD.L	D0,D0
	OR.L	D1,D0
	RTS

validateSectorHeaderChecksum:
	BSR	calculateMFMChecksum
	MOVE.L	D0,-(SP)
	LEA	$0030(A5),A0
	BSR	decodeMFMLongwords
	CMP.L	(SP)+,D0
	RTS

calculateMFMChecksum:
	LEA	$0008(A5),A0
	MOVEQ	#$28,D1
calculateMFMChecksumWithParams:
	MOVE.L	D2,-(SP)
	LSR.W	#$02,D1
	SUBQ.W	#$01,D1
	MOVEQ	#$00,D0
lbC054BE8:
	MOVE.L	(A0)+,D2
	EOR.L	D2,D0
	DBRA	D1,lbC054BE8
	MOVE.L	(SP)+,D2
	AND.L	#$55555555,D0
	RTS

initializeMFMTrackBuffer:
	MOVE.L	-$0018(A6),A0
	LEA	$0400(A0),A1
	MOVE.L	#$AAAAAAAA,D0
	MOVE.L	D0,D1
	MOVE.L	D0,D2
	MOVE.L	D0,D3
	MOVE.L	D0,D4
	MOVE.L	D0,D5
	MOVE.L	D0,D6
	MOVE.L	D0,D7
lbC054C16:
	MOVEM.L	D0-D7,-(A1)
	CMP.L	A1,A0
	BNE.S	lbC054C16
	RTS

copyDataWithBlitter:
	MOVE.L	A2,-(SP)
	BSR	initializeBlitter
	ADD.L	D0,A0
	SUBQ.L	#$01,A0
	MOVE.L	A0,$0050(A2)
	ADD.L	D0,A0
	MOVE.L	A0,$004C(A2)
	ADD.L	D0,A1
	SUBQ.L	#$01,A1
	MOVE.L	A1,$0054(A2)
	MOVE.W	#$1DD8,$0040(A2)
	MOVE.W	#$0002,$0042(A2)
	LSL.W	#$02,D0
	OR.W	#$0008,D0
	MOVE.W	D0,$0058(A2)
	MOVE.L	(SP)+,A2
	RTS

fillDataWithBlitter:
	MOVEM.L	D1-D3/A2,-(SP)
	BSR	initializeBlitter
	MOVE.W	D0,D1
	LSL.W	#$02,D1
	OR.W	#$0008,D1
	MOVE.L	A0,$0050(A2)
	MOVE.L	A0,$004C(A2)
	MOVE.L	A1,$0054(A2)
	MOVE.W	#$1DB1,$0040(A2)
	MOVE.W	#$0000,$0042(A2)
	MOVE.W	D1,$0058(A2)
	BSR	waitBlitterDMADisabled
	MOVE.L	A0,$0050(A2)
	MOVE.L	A1,$004C(A2)
	MOVE.L	A1,$0054(A2)
	MOVE.W	#$2D8C,$0040(A2)
	MOVE.W	D1,$0058(A2)
	BSR	waitBlitterDMADisabled
	MOVE.L	A0,D2
	ADD.L	D0,D2
	SUBQ.L	#$02,D2
	MOVE.L	A1,D3
	ADD.L	D0,D3
	ADD.L	D0,D3
	SUBQ.L	#$02,D3
	MOVE.L	D2,$0050(A2)
	MOVE.L	D2,$004C(A2)
	MOVE.L	D3,$0054(A2)
	MOVE.W	#$0DB1,$0040(A2)
	MOVE.W	#$1002,$0042(A2)
	MOVE.W	D1,$0058(A2)
	BSR	waitBlitterDMADisabled
	MOVE.L	A1,D3
	ADD.L	D0,D3
	MOVE.L	A0,$0050(A2)
	MOVE.L	D3,$004C(A2)
	MOVE.L	D3,$0054(A2)
	MOVE.W	#$1D8C,$0040(A2)
	MOVE.W	#$0000,$0042(A2)
	MOVE.W	D1,$0058(A2)
	BSR	waitBlitterDMADisabled
	MOVE.L	D0,D1
	MOVE.L	A1,A0
	BSR	encodeMFMClockBits
	ADD.L	D1,A0
	BSR	encodeMFMClockBits
	ADD.L	D1,A0
	BSR.S	encodeMFMClockBits
	MOVEM.L	(SP)+,D1-D3/A2
	RTS

waitBlitterDMADisabled:
	BTST	#DMAB_BLITTER,_custom+dmaconr
	BNE.S	waitBlitterDMADisabled
	RTS

initializeBlitter:
	LEA	_custom,A2
	BSR	waitBlitterDMADisabled
	MOVE.W	#(DMAF_BLITTER|DMAF_SETCLR),dmacon(A2)
	MOVE.L	#$FFFFFFFF,bltafwm(A2)
	MOVE.W	#$5555,bltcdat(A2)
	CLR.W	bltamod(A2)
	CLR.W	bltbmod(A2)
	CLR.W	bltdmod(A2)
	RTS

writeMFMEncodedLongword:
	MOVE.L	D0,-(SP)
	LSR.L	#$01,D0
	BSR	convertToMFMEncoding
	MOVE.L	(SP)+,D0
	BSR	convertToMFMEncoding
encodeMFMClockBits:
	MOVE.B	(A0),D0
	BTST	#$00,-$0001(A0)
	BNE.S	lbC054D66
	BTST	#$06,D0
	BNE.S	lbC054D6C
	BSET	#$07,D0
	BRA.S	lbC054D6A

lbC054D66:
	BCLR	#$07,D0
lbC054D6A:
	MOVE.B	D0,(A0)
lbC054D6C:
	RTS

convertToMFMEncoding:
	AND.L	#$55555555,D0
	MOVE.L	D0,D2
	EOR.L	#$55555555,D2
	MOVE.L	D2,D1
	ADD.L	D2,D2
	LSR.L	#$01,D1
	BSET	#$1F,D1
	AND.L	D2,D1
	OR.L	D1,D0
	BTST	#$00,-$0001(A0)
	BEQ.S	lbC054D96
	BCLR	#$1F,D0
lbC054D96:
	MOVE.L	D0,(A0)+
	RTS

validateTrackData:
	LEA	_custom,A1
	MOVE.W	#$4000,dsklen(A1)
	MOVE.W	#(DMAF_DISK|DMAF_SETCLR),dmacon(A1)
	MOVE.W	#$6600,adkcon(A1)
	MOVE.W	#$9500,adkcon(A1)
	MOVE.W	#$4489,dsksync(A1)
	MOVE.L	A0,dskpt(A1)
	MOVE.W	#INTF_DSKBLK,intreq(A1)
	LSR.W	#$01,D0
	OR.W	#$8000,D0
	MOVE.W	D0,dsklen(A1)
	MOVE.W	D0,dsklen(A1)
	RTS

checkDiskReadStatus:
	LEA	_custom,A1
	MOVE.L	#$00001770,D0
	BSR	setDiskTimeout
lbC054DE8:
	BTST	#$01,intreqr+1(A1)
	BNE.S	lbC054DFA
	BSR	checkTimeoutExpired
	BNE.S	lbC054DE8
	MOVEQ	#-$01,D0
	BRA.S	stopDiskDMA

lbC054DFA:
	MOVEQ	#$00,D0
stopDiskDMA:
	MOVE.W	#$0002,_custom+intreq
	MOVE.W	#$4000,_custom+dsklen
	TST.L	D0
	RTS

setupDiskHardware:
	MOVE.W	#$0400,_custom+adkcon
	MOVEQ	#-$01,D1
driveSelect:
	MOVE.B	D1,_ciab+ciaprb
	MOVE.W	-$0024(A6),D0
	ADDQ.L	#$03,D0
	BCLR	D0,D1
	MOVE.B	D1,_ciab+ciaprb
	BSET	D0,D1
	MOVE.B	D1,_ciab+ciaprb
	RTS

startDiskMotorAndWait:
	MOVEQ	#-$01,D1
	MOVE.B	D1,_ciab+ciaprb
	BCLR	#$07,D1
	BSR.S	driveSelect
	MOVE.L	#$000000C8,D0
	BSR	driveDelay
	RTS

positionDiskHead:
	MOVEM.L	D2/D3,-(SP)
	MOVE.L	D2,D3
	BSR	applyDriveConfiguration
	MOVE.W	-$0024(A6),D0
	ADD.W	D0,D0
	LEA	lbW054F84,A0
	MOVE.W	$00(A0,D0.W),D0
	BPL.S	lbC054E72
	BSR	recalibrateDiskHeadToTrack0
	BNE.S	lbC054EA2
lbC054E72:
	LSR.W	#$01,D0
	LSR.W	#$01,D2
	MOVEQ	#$01,D1
	SUB.W	D0,D2
	BEQ.S	lbC054E8E
	BPL.S	lbC054E82
	MOVEQ	#-$01,D1
	NEG.W	D2
lbC054E82:
	MOVEQ	#$06,D0
lbC054E84:
	BSR	stepDiskHeadOneTrack
	MOVEQ	#$06,D0
	SUBQ.W	#$01,D2
	BNE.S	lbC054E84
lbC054E8E:
	MOVE.W	-$0024(A6),D0
	ADD.W	D0,D0
	LEA	lbW054F84,A0
	MOVE.W	D3,$00(A0,D0.W)
	BSR	applyDriveConfiguration
	MOVEQ	#$00,D0
lbC054EA2:
	MOVEM.L	(SP)+,D2/D3
	RTS

recalibrateDiskHeadToTrack0:
	MOVEM.L	D2,-(SP)
	MOVEQ	#$55,D2
lbC054EAE:
	BTST	#$04,$00BFE001
	BEQ.S	lbC054EC8
	MOVEQ	#$06,D0
	MOVEQ	#-$01,D1
	BSR	stepDiskHeadOneTrack
	DBRA	D2,lbC054EAE
	MOVEQ	#$1E,D0
	BRA.S	lbC054ED8

lbC054EC8:
	MOVE.W	-$0024(A6),D0
	ADD.W	D0,D0
	LEA	lbW054F84,A0
	CLR.W	$00(A0,D0.W)
	MOVEQ	#$00,D0
lbC054ED8:
	MOVEM.L	(SP)+,D2
	RTS

stepDiskHeadOneTrack:
	MOVE.L	D0,-(SP)
	BSR	buildCIABDiskControlByte
	TST.B	D1
	BMI.S	lbC054EEC
	BCLR	#$01,D0
lbC054EEC:
	BCLR	#$00,D0
	MOVE.B	D0,$00BFD100
	BSET	#$00,D0
	MOVE.B	D0,$00BFD100
	MOVE.L	(SP)+,D0
	BSR	driveDelay
	RTS

applyDriveConfiguration:
	BSR	buildCIABDiskControlByte
	MOVE.B	D0,$00BFD100
	RTS

buildCIABDiskControlByte:
	move.l	a0,-(sp)
	MOVEM.W	D1/D2,-(SP)
	MOVE.W	-$0024(A6),D0
	MOVE.B	$00BFD100,D2
	OR.B	#$7F,D2
	ADD.B	#$03,D0
	BCLR	D0,D2
	SUB.B	#$03,D0
	ADD.W	D0,D0
	lea	lbW054F84,a0
	MOVE.W	(A0,D0.W),D1
	BTST	#$00,D1
	BEQ.S	lbC054F40
	BCLR	#$02,D2
lbC054F40:
	MOVE.B	D2,D0
	MOVEM.W	(SP)+,D1/D2
	move.l	(sp)+,a0
	RTS

driveDelay:
	BSR	setDiskTimeout
lbC054F4C:
	BTST	#$00,$00BFEE01
	BNE.S	lbC054F4C
	SUBQ.L	#$01,D0
	BNE.S	driveDelay
	RTS

checkTimeoutExpired:
	BTST	#$00,$00BFEE01
	BNE.S	lbC054F82
	SUBQ.L	#$01,D0
	BEQ.S	lbC054F82
setDiskTimeout:
	MOVE.B	#$08,$00BFEE01
	MOVE.B	#$CC,$00BFE401
	MOVE.B	#$02,$00BFE501
lbC054F82:
	RTS

saveRandomState:
	MOVE.L	randomSeed1,lbL054FB8
	MOVE.B	randomSeed3,lbB054FB9
	RTS

lbC054FA2:
	MOVE.L	lbL054FB8,randomSeed1
	MOVE.B	lbB054FB9,randomSeed3
	RTS

updateEngineState:
	MOVE.B	opponentID,D1
	MOVE.B	#$00,D2
	MOVE.B	D2,engineTimer
	MOVE.B	previousDataIndex,D0
	MOVE.B	D0,currentDataIndex
	SUB.B	lbB00D4A1,D0
	BCC	lbC054FEA
	NEG.B	D0
	SUBQ.B	#$01,D2
lbC054FEA:
	MOVE.B	D0,trackBoostThreshold
	MOVE.B	D2,lateralVelocity
	MOVE.B	carRenderDistance,D0
	BEQ	updateEngineAndSound
	JMP	lbC05513E

updateEngineAndSound:
	MOVE.B	engineState,D0
	CMP.B	#$40,D0
	BCC	lbC055030
	TST.B	carCrashedFlag
	BMI	lbC05502A
	CMP.B	#$32,trackBoostThreshold
	BCC	lbC055030
lbC05502A:
	SUBQ.B	#$01,engineTimer
lbC055030:
	CMP.B	#$10,D0
	BCC	processEngineSoundAndEffects
	TST.B	networkGameMode
	BEQ	lbC05504C
	TST.B	networkEngineFlag
	BNE	processEngineSoundAndEffects
lbC05504C:
	MOVE.B	trackBoostThreshold,D0
	CMP.B	#$32,D0
	BCC	processEngineSoundAndEffects
	MOVE.B	lateralRoadPosition,D0
	CMP.B	#$01,D0
	BCS	lbC05507A
	BNE	processEngineSoundAndEffects
	MOVE.B	speedMinor,D0
	CMP.B	#$80,D0
	BCC	processEngineSoundAndEffects
lbC05507A:
	JSR	processEngineSound
	JMP	lbC0550A6

processEngineSoundAndEffects:
	MOVE.B	#$00,D0
	MOVE.B	D0,engineSoundType
	MOVE.B	#$00,engineEffectFlag
	MOVE.B	engineState,D0
	CMP.B	#$18,D0
	BCC	lbC0550DC
lbC0550A6:
	MOVE.L	#engineCharacteristics,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$08,D0
	BEQ	lbC0550D0
	TST.B	carCrashedFlag
	BMI	lbC0550D0
	MOVE.B	engineState,D0
	CMP.B	#$0E,D0
	BCC	lbC05513E
lbC0550D0:
	JSR	updateEnginePerformanceHigh
	JMP	lbC0551B6

lbC0550DC:
	TST.B	carCrashedFlag
	BMI	lbC055132
	CMP.B	#$32,D0
	BCC	lbC05510C
	MOVE.L	#engineCharacteristics,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$02,D0
	BEQ	lbC055126
	JSR	setEngineParameters
	JMP	lbC05516A

lbC05510C:
	CMP.B	#$C8,D0
	BCC	lbC05513E
	MOVE.L	#engineCharacteristics,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$20,D0
	BEQ	lbC05513E
lbC055126:
	JSR	updateEnginePerformanceStandard
	JMP	lbC05516A

lbC055132:
	JSR	updateEnginePerformanceStandard
	JMP	lbC0551B6

lbC05513E:
	MOVE.B	#$40,D2
	MOVE.L	#engineCharacteristics,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$08,D0
	BEQ	lbC055158
	MOVE.B	#$6E,D2
lbC055158:
	MOVE.B	D1,D0
	AND.B	#$01,D0
	BEQ	lbC055164
	NOT.B	D2
lbC055164:
	MOVE.B	D2,currentDataIndex
lbC05516A:
	MOVE.B	#$02,D0
	MOVE.B	D0,savedSegmentIndex
	MOVE.B	opponentSegmentIndex,D1
	MOVE.B	D1,currentSegmentIndex
lbC055180:
	MOVE.L	#trackSegmentPropertiesTable,A1
	MOVE.B	$00(A1,D1.W),D0
	AND.B	#$0F,D0
	MOVE.B	D0,D2
	MOVE.L	#geometryParameterTable,A2
	MOVE.B	$00(A2,D2.W),D0
	BPL	lbC0551A6
	MOVE.B	#$80,currentDataIndex
lbC0551A6:
	JSR	advanceToNextSegment
	SUBQ.B	#$01,savedSegmentIndex
	BNE	lbC055180
lbC0551B6:
	MOVE.B	aiDirectionFlag,D0
	BMI	lbC0551D8
	BNE	lbC0551E8
	MOVE.B	currentDataIndex,D0
	SUB.B	previousDataIndex,D0
	BEQ	lbC055224
	BCC	lbC0551E8
lbC0551D8:
	CMP.B	#$F0,D0
	BCC	lbC055224
	MOVE.B	#$F7,D0
	BNE	lbC0551F4
lbC0551E8:
	CMP.B	#$10,D0
	BCS	lbC055224
	MOVE.B	#$09,D0
lbC0551F4:
	ADD.B	previousDataIndex,D0
	MOVE.B	aiEnabled,D2
	BEQ	lbC055224
	CMP.B	#$E1,D0
	BCC	lbC055224
	CMP.B	#$20,D0
	BCS	lbC055224
	TST.B	networkGameMode
	BNE	lbC055224
	MOVE.B	D0,previousDataIndex
lbC055224:
	RTS

updateEnginePerformanceHigh:
	MOVE.B	trackBoostThreshold,D0
	CMP.B	#$38,D0
	BCC	lbC055286
	TST.B	lateralVelocity
	BMI	lbC05527C
	BPL	lbC055268
updateEnginePerformanceStandard:
	MOVE.B	trackBoostThreshold,D0
	CMP.B	#$38,D0
	BCC	lbC055286
	MOVE.B	lbB00D4A1,D0
	TST.B	lateralVelocity
	BMI	lbC055274
	CMP.B	#$A0,D0
	BCC	lbC05527C
lbC055268:
	MOVE.B	#$E0,D0
	MOVE.B	D0,currentDataIndex
	RTS

lbC055274:
	CMP.B	#$60,D0
	BCS	lbC055268
lbC05527C:
	MOVE.B	#$20,D0
	MOVE.B	D0,currentDataIndex
lbC055286:
	RTS

setEngineParameters:
	MOVE.B	lbB00D4A1,D0
	MOVE.B	D0,currentDataIndex
	RTS

processOpponentLogic:
	MOVE.B	raceStartComplete,D0
	BEQ	lbC055356
	MOVE.B	crashRecoveryTimer,D0
	BNE	lbC055356
	MOVE.B	opponentSegmentIndex,D1
	JSR	loadTrackSegmentConfiguration
	JSR	lbC0557E2
	JSR	processOpponentAI
	JSR	lbC055504
	JSR	lbC05553C
	JSR	lbC055408
	MOVE.B	segmentOrientationAlternate,D0
	MOVE.B	D0,curveMagnitude
	MOVE.W	lbW00D4EE,D0
	MOVE.B	curveMagnitude,D3
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
	ADD.B	D3,lbB00D43C
	BCC	lbC055318
	ADDQ.W	#$01,D0
lbC055318:
	ADD.W	D0,gameStateCounter
	MOVE.B	gameStateCounter,D0
	CMP.B	trackModeParameter,D0
	BCS	lbC055356
	SUB.B	trackModeParameter,D0
	MOVE.B	D0,gameStateCounter
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
	JSR	processTrackSegmentData
	JSR	generateRandomNumber
	AND.W	#$007F,D0
	ADD.B	#$68,D0
	MOVE.L	#boundsMinX,A0
	MOVE.L	#lbL00D666,A1
	MOVE.B	#$06,D1
lbC05537C:
	MOVE.W	$00(A0,D1.W),D3
	ADD.W	D0,D3
	MOVE.W	D3,$00(A1,D1.W)
	SUBQ.B	#$02,D1
	BPL	lbC05537C
	RTS

lbC05538E:
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
	MOVE.B	lbB00E32B,D2
lbC0553D2:
	MOVE.B	D2,offTrackFrameThreshold
	JSR	generateRandomNumber
	MOVE.L	#lbW01172C,A0
	AND.B	$00(A0,D1.W),D0
	ADD.B	$08(A0,D1.W),D0
	MOVE.B	D0,lbB0555E0
	JSR	generateRandomNumber
	AND.B	$10(A0,D1.W),D0
	ADD.B	$18(A0,D1.W),D0
	MOVE.B	D0,lbB0555E1
lbC055406:
	RTS

lbC055408:
	MOVE.W	#$0000,currentMenuItemCopy
	MOVE.B	lbB00D4EF,D0
	ASL.B	#$01,D0
	MOVE.B	lbW00D4EE,D0
	BMI	lbC055494
	ROXL.B	#$01,D0
	TST.B	engineTimer
	BPL	lbC055444
	TST.B	carCrashedFlag
	BPL	lbC055444
	SUB.B	#$14,D0
	BCC	lbC055444
	MOVE.B	#$00,D0
lbC055444:
	MOVE.B	D0,curveMagnitude
	MOVE.B	lbW00D4EE,D0
	JSR	multiplyAndRandomize
	ASR.W	#$06,D3
	MOVE.W	D3,currentMenuItemCopy
	MOVE.B	aiEnabled,D0
	BEQ	lbC055494
	MOVE.W	lbW00D4F0,D0
	BMI	lbC055494
	MOVE.W	#$0000,D3
	MOVE.B	lbW00D4EE,D3
	SUB.W	D3,D0
	TST.B	segmentSteeringFlags
	BPL	lbC05548E
	SUB.W	D3,D0
	SUB.W	#$0023,D0
lbC05548E:
	MOVE.W	D0,lbW00D4F0
lbC055494:
	MOVE.W	lbW00D4F0,D0
	SUB.W	currentMenuItemCopy,D0
	TST.B	aiEnabled
	BEQ.L	lbC0554E4
	MOVE.W	boundsMinX,D3
	ADD.W	boundsMaxX,D3
	LSR.W	#$01,D3
	SUB.W	boundsMinY,D3
	MOVE.W	D3,D4
	BPL.L	lbC0554C6
	NEG.W	D4
lbC0554C6:
	CMPI.W	#$0200,D4
	BCS.L	lbC0554D2
	MOVE.W	#$01FE,D4
lbC0554D2:
	LSR.W	#$01,D4
	MOVE.W	D4,D5
	ASR.W	#$02,D5
	ADD.W	D4,D5
	TST.W	D3
	BPL.L	lbC0554E2
	NEG.W	D5
lbC0554E2:
	ADD.W	D5,D0
lbC0554E4:
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC0554F0
	MULS	D2,D0
	ASR.L	#$08,D0
lbC0554F0:
	ADD.W	D0,lbW00D4EE
	BPL	lbC055502
	MOVE.W	#$0000,lbW00D4EE
lbC055502:
	RTS

lbC055504:
	MOVE.B	lbB00D3FC,D0
	MOVE.B	lbB00D3FD,D2
	MOVE.B	aiActionTimer,D1
	BEQ	lbC05551E
	SUB.B	#$19,D0
lbC05551E:
	MOVE.B	aiEnabled,D1
	BNE	lbC05552E
	MOVE.B	#$00,D0
	MOVE.B	D0,D2
lbC05552E:
	MOVE.B	D0,lbB00D4F1
	MOVE.B	D2,lbW00D4F0
	RTS

lbC05553C:
	TST.B	aiEnabled
	BNE	lbC055548
	RTS

lbC055548:
	MOVE.B	opponentSegmentIndex,D1
	MOVE.L	#segmentVisibilityData,A0
	MOVE.B	$00(A0,D1.W),D0
	BMI	lbC05556C
	CMP.B	lbB0555E0,D0
	BCS	lbC05556C
	MOVE.B	lbB0555E0,D0
lbC05556C:
	AND.B	#$7F,D0
	MOVE.B	D0,collisionDistanceTemp
	MOVE.B	lbW00D4EE,D0
	SUB.B	collisionDistanceTemp,D0
	BCS	lbC0555A0
	BEQ	lbC0555D6
	MOVE.B	#$80,boundaryCollisionDirectionFlag
	NEG.W	lbW00D4F0
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
	ASL.W	lbW00D4F0
lbC0555D4:
	RTS

lbC0555D6:
	MOVE.B	#$80,boundaryCollisionDirectionFlag
	RTS

processEngineSound:
	MOVE.B	raceStartComplete,D0
	BNE	lbC0555FA
	RTS

lbC0555F0:
	MOVE.B	#$03,engineSoundType
	RTS

lbC0555FA:
	MOVE.B	aiEnabled,D0
	BEQ	lbC05560E
	MOVE.B	playerStateFlag,D0
	BNE	lbC055654
lbC05560E:
	MOVE.W	carHeightPosition,D0
	SUB.W	lbL00D666,D0
	MOVE.W	D0,D4
	ADD.W	#$0028,D0
	BPL	lbC055626
	NEG.W	D0
lbC055626:
	CMP.W	#$00C0,D0
	BGE	lbC0555F0
	TST.B	engineSoundType
	BEQ	lbC055654
	SUBQ.B	#$01,engineSoundType
	MOVE.W	#$0100,D3
	SUB.W	D0,D3
	TST.W	D4
	BPL	lbC05564C
	NEG.W	D3
lbC05564C:
	ASL.W	#$04,D3
	MOVE.W	D3,lbW00D656
lbC055654:
	MOVE.B	trackBoostThreshold,D0
	CMP.B	#$2D,D0
	BCC	lbC055688
	MOVE.B	engineState,D0
	CMP.B	#$08,D0
	BCC	lbC055688
	MOVE.B	#$08,D0
	TST.B	lateralVelocity
	BMI	lbC055682
	MOVE.B	#$F8,D0
lbC055682:
	MOVE.B	D0,velocityAdjustment
lbC055688:
	TST.B	engineEffectFlag
	BMI	lbC0556C2
	MOVE.W	#$0003,D3
	MOVE.W	#$0000,D0
	TST.B	crashRecoveryTimer
	BNE	lbC0556AA
	MOVE.W	lbW00D4EE,D0
lbC0556AA:
	SUB.W	carVelocity,D0
	BPL	lbC0556B8
	MOVE.W	#$FFFD,D3
lbC0556B8:
	ASR.W	#$01,D0
	ADD.W	D3,D0
	MOVE.W	D0,speedDifferential
lbC0556C2:
	MOVE.B	#$80,collisionActiveFlag
	MOVE.B	#$80,engineEffectFlag
	MOVE.W	#$0200,D3
	MOVE.W	velocityAdjustment,D0
	BPL	lbC0556E2
	NEG.W	D0
lbC0556E2:
	ADD.W	D0,D3
	MOVE.W	lbW00D656,D0
	BPL	lbC0556F0
	NEG.W	D0
lbC0556F0:
	ADD.W	D0,D3
	MOVE.W	speedDifferential,D0
	BPL	lbC0556FE
	NEG.W	D0
lbC0556FE:
	ADD.W	D0,D3
	LSR.W	#$08,D3
	MOVE.L	#accumulatedOffTrackForceX,A0
	MOVE.W	#$0002,D2
lbC05570C:
	MOVE.B	$00(A0,D2.W),D0
	ADD.B	D3,D0
	BCC	lbC05571A
	MOVE.B	#$FF,D0
lbC05571A:
	MOVE.B	D0,$00(A0,D2.W)
	SUBQ.B	#$01,D2
	BPL	lbC05570C
	MOVE.B	#$80,offTrackAccumulationFlag
	RTS

handleCollisionBetweenCars:
	TST.B	lbB0557E0
	BEQ	lbC05573E
	SUBQ.B	#$01,lbB0557E0
lbC05573E:
	TST.B	collisionActiveFlag
	BEQ	lbC0557DC
	MOVE.B	#$00,collisionActiveFlag
	MOVE.W	lbW00D4EE,D0
	SUB.W	speedDifferential,D0
	BPL	lbC055764
	MOVE.W	#$0000,D0
lbC055764:
	MOVE.W	D0,lbW00D4EE
	MOVE.W	lbW00D656,D0
	ASR.W	#$04,D0
	SUB.W	D0,lbW00D676
	SUB.W	D0,lbW00D678
	SUB.W	D0,lbW00D67A
	MOVE.W	velocityAdjustment,D0
	ADD.W	D0,rollAngleModifier
	MOVE.W	lbW00D656,D0
	ADD.W	D0,carPitchAdjustment
	MOVE.W	speedDifferential,D0
	ADD.W	D0,yawAngleOffset
	MOVE.W	#$0000,velocityAdjustment
	MOVE.W	#$0000,lbW00D656
	MOVE.W	#$0000,speedDifferential
	TST.B	lbB0557E0
	BNE	lbC0557DC
	MOVE.B	#$02,D0
	JSR	playAudioSample
	MOVE.B	#$05,lbB0557E0
lbC0557DC:
	RTS

lbC0557E2:
	MOVE.W	#$8000,minBoundaryDistance
	MOVE.W	#$0028,D0
	TST.B	segmentSteeringFlags
	BPL	lbC0557FC
	MOVE.W	#$007C,D0
lbC0557FC:
	MOVE.W	D0,lbW00D4F8
	MOVE.W	#$0000,D7
	MOVE.W	boundsMinX,D0
	SUB.W	lbL00D666,D0
	CMP.W	minBoundaryDistance,D0
	BLT	lbC055822
	MOVE.W	D0,minBoundaryDistance
lbC055822:
	ADD.W	lbW00D4F8,D0
	BPL	lbC055838
	CMP.W	#$FFA0,D0
	BCC	lbC055838
	MOVE.W	#$FFA0,D0
lbC055838:
	MOVE.W	D0,D6
	SUB.W	lbW00D66E,D0
	JSR	applyMomentumAmplification
	BPL	lbC05584E
	MOVE.W	#$0000,D0
lbC05584E:
	CMP.W	#$0400,D0
	BLT	lbC05585A
	MOVE.W	#$03FF,D0
lbC05585A:
	OR.W	D0,D7
	SUB.W	lbW00D4F8,D0
	MOVE.W	D0,lbL00D65E
	MOVE.W	D6,lbW00D66E
	MOVE.W	boundsMaxX,D0
	SUB.W	lbW00D668,D0
	CMP.W	minBoundaryDistance,D0
	BLT	lbC05588A
	MOVE.W	D0,minBoundaryDistance
lbC05588A:
	ADD.W	lbW00D4F8,D0
	BPL	lbC0558A0
	CMP.W	#$FFA0,D0
	BCC	lbC0558A0
	MOVE.W	#$FFA0,D0
lbC0558A0:
	MOVE.W	D0,D6
	SUB.W	lbW00D670,D0
	JSR	applyMomentumAmplification
	BPL	lbC0558B6
	MOVE.W	#$0000,D0
lbC0558B6:
	CMP.W	#$0400,D0
	BLT	lbC0558C2
	MOVE.W	#$03FF,D0
lbC0558C2:
	OR.W	D0,D7
	SUB.W	lbW00D4F8,D0
	MOVE.W	D0,lbW00D660
	MOVE.W	D6,lbW00D670
	MOVE.W	boundsMinY,D0
	SUB.W	lbW00D66A,D0
	CMP.W	minBoundaryDistance,D0
	BLT	lbC0558F2
	MOVE.W	D0,minBoundaryDistance
lbC0558F2:
	ADD.W	lbW00D4F8,D0
	BPL	lbC055908
	CMP.W	#$FFA0,D0
	BCC	lbC055908
	MOVE.W	#$FFA0,D0
lbC055908:
	MOVE.W	D0,D6
	SUB.W	lbW00D672,D0
	JSR	applyMomentumAmplification
	BPL	lbC05591E
	MOVE.W	#$0000,D0
lbC05591E:
	CMP.W	#$0400,D0
	BLT	lbC05592A
	MOVE.W	#$03FF,D0
lbC05592A:
	OR.W	D0,D7
	SUB.W	lbW00D4F8,D0
	MOVE.W	D0,lbW00D662
	MOVE.W	D6,lbW00D672
	MOVE.W	D7,D0
	ASR.W	#$08,D0
	OR.B	D7,D0
	MOVE.B	D0,aiEnabled
	MOVE.W	lbL00D65E,D4
	ADD.W	lbW00D660,D4
	ADD.W	lbW00D662,D4
	MOVE.W	lbL00D65E,D7
	ASL.W	#$02,D7
	MOVE.W	D4,D0
	ADD.W	lbL00D65E,D0
	ADD.W	D7,D0
	ASR.W	#$03,D0
	MOVE.W	D0,lbW00D67E
	MOVE.W	lbW00D660,D7
	ASL.W	#$02,D7
	MOVE.W	D4,D0
	ADD.W	lbW00D660,D0
	ADD.W	D7,D0
	ASR.W	#$03,D0
	MOVE.W	D0,lbW00D680
	MOVE.W	lbW00D662,D7
	ASL.W	#$02,D7
	MOVE.W	D4,D0
	ADD.W	lbW00D662,D0
	ADD.W	D7,D0
	ASR.W	#$03,D0
	MOVE.W	D0,lbW00D682
	MOVE.B	opponentID,D1
	MOVE.L	#engineCharacteristics,A0
	MOVE.B	$00(A0,D1.W),D0
	AND.B	#$04,D0
	BEQ	lbC0559EC
	MOVE.W	lbW00D67A,D0
	OR.W	lbW00D682,D0
	AND.W	#$FFFC,D0
	BNE	lbC0559EC
	JSR	generateRandomNumber
	AND.B	#$0F,D0
	BNE	lbC0559EC
	MOVE.W	#$00A0,lbW00D67A
lbC0559EC:
	MOVE.W	lbW00D67E,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC0559FE
	MULS	D2,D0
	ASR.L	#$08,D0
lbC0559FE:
	ADD.W	lbW00D676,D0
	MOVE.W	D0,lbW00D676
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC055A16
	MULS	D2,D0
	ASR.L	#$08,D0
lbC055A16:
	ASR.W	#$01,D0
	ADD.W	D0,lbL00D666
	MOVE.W	lbW00D680,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC055A30
	MULS	D2,D0
	ASR.L	#$08,D0
lbC055A30:
	ADD.W	lbW00D678,D0
	MOVE.W	D0,lbW00D678
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC055A48
	MULS	D2,D0
	ASR.L	#$08,D0
lbC055A48:
	ASR.W	#$01,D0
	ADD.W	D0,lbW00D668
	MOVE.W	lbW00D682,D0
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC055A62
	MULS	D2,D0
	ASR.L	#$08,D0
lbC055A62:
	ADD.W	lbW00D67A,D0
	MOVE.W	D0,lbW00D67A
	MOVE.B	#TIMESTEP_FACTOR,D2
	BEQ	lbC055A7A
	MULS	D2,D0
	ASR.L	#$08,D0
lbC055A7A:
	ASR.W	#$01,D0
	ADD.W	D0,lbW00D66A
	MOVE.W	#$0128,lateralVelocity
	MOVE.B	#$00,D1
	MOVE.B	#$02,D2
	JSR	lbC055B32
	MOVE.W	#$0170,lateralVelocity
	MOVE.B	#$00,D1
	TST.W	D4
	BPL	lbC055AAC
	ADDQ.B	#$02,D1
lbC055AAC:
	MOVE.B	#$04,D2
	JSR	lbC055B32
lbC055AB6:
	MOVE.W	lbL00D666,inputCoordX1
	ADD.W	#$0050,inputCoordX1
	MOVE.W	lbW00D668,inputCoordX2
	ADD.W	#$0050,inputCoordX2
	MOVE.W	lbW00D66A,inputCoordY1
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

lbC055B18:
	MOVE.L	#lbL00D666,A0
	MOVE.W	$00(A0,D1.W),D0
	SUB.W	$00(A0,D2.W),D0
	MOVE.W	D0,D4
	TST.W	D0
	BPL	lbC055B30
	NEG.W	D0
lbC055B30:
	RTS

lbC055B32:
	MOVE.L	#lbW00D676,A4
	MOVE.B	D1,trackBoostThresholdCopy
	JSR	lbC055B18
	MOVE.W	lateralVelocity,D3
	SUB.W	D0,D3
	BPL	lbC055BA0
	TST.W	D4
	BPL	lbC055B58
	MOVE.B	D2,D1
lbC055B58:
	MOVE.L	#lbL00D666,A0
	ADD.W	D3,$00(A0,D1.W)
	CMP.B	#$04,D2
	BEQ	lbC055B74
	MOVE.B	#$00,D1
	JMP	lbC055BF0

lbC055B74:
	MOVE.B	#$00,D1
	MOVE.B	#$02,D2
	JSR	lbC055BF0
	MOVE.B	#$04,D1
	JSR	lbC055BF0
	MOVE.B	#$00,D1
	JSR	lbC055BF0
	MOVE.B	#$04,D2
	MOVE.B	trackBoostThresholdCopy,D1
lbC055BA0:
	CMP.B	#$04,D2
	BNE	lbC055BE8
	MOVE.B	aiEnabled,D0
	BNE	lbC055BE8
	TST.B	currentMenuItemCopy
	BMI	lbC055BBC
lbC055BBC:
	MOVE.W	$00(A4,D1.W),D0
	SUB.W	$0004(A4),D0
	BMI	lbC055BD0
	CMP.W	#$0010,D0
	BGE	lbC055BE8
lbC055BD0:
	MOVE.B	#$04,D1
	MOVE.L	#lbW055BEA,A0
lbC055BDA:
	MOVE.W	$00(A0,D1.W),D0
	ADD.W	D0,$00(A4,D1.W)
	SUBQ.B	#$02,D1
	BPL	lbC055BDA
lbC055BE8:
	RTS

lbC055BF0:
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
lbC055E8A:
	MOVE.W	(A1),(A4)+
	MOVE.W	(A1)+,(A0)+
	MOVE.W	(A1),$1F3E(A4)
	MOVE.W	(A1)+,$1F3E(A0)
	MOVE.W	(A1),$3E7E(A4)
	MOVE.W	(A1)+,$3E7E(A0)
	MOVE.W	(A1),$5DBE(A4)
	MOVE.W	(A1)+,$5DBE(A0)
	CMP.L	A3,A0
	BNE	lbC055E8A
	MOVE.B	#$41,displayUpdateFlag
	JSR	setupDisplayMode
	JSR	copyGraphicsRegion
	JMP	animatePaletteToTarget

setupDisplayMode:
	MOVE.B	selectedTrack,D0
	MOVE.B	D0,displayTrackID
	JSR	drawScreenFrame
	MOVE.B	#$0F,D0
	JSR	setBackgroundColor
	TST.B	suppressMenuTextFlag
	BNE	lbC055EF6
	TST.B	textRenderingFlag
	BEQ	lbC055EF8
lbC055EF6:
	RTS

lbC055EF8:
	TST.B	additionalPlayerCount
	BNE	lbC055F52
	MOVE.B	#$09,D2
	MOVE.B	currentPlayerContext,D0
	BEQ	lbC055F26
	MOVE.B	D2,lbB04C057
	MOVE.B	#$BB,D1
	JSR	renderTextString
	JMP	lbC055F36

lbC055F26:
	MOVE.B	D2,lbB055C56
	MOVE.B	#$00,D1
	JSR	renderLeagueText
lbC055F36:
	MOVE.B	#$04,D0
	SUB.B	displayTrackID,D0
	JSR	renderDigit
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	RTS

lbC055F52:
	MOVE.B	#$A0,D1
	JMP	renderMenuString

setupGameplayDisplayAlt:
	MOVE.B	#$80,D0
	BRA	lbC055F68

setupGameplayDisplay:
	MOVE.B	#$00,D0
lbC055F68:
	MOVE.B	D0,lbB00D4AA
	JSR	setupDisplayMode
	MOVE.B	displayTrackID,D0
	ASL.B	#$01,D0
	MOVE.B	D0,temp
	MOVE.B	currentRaceNumber,D0
	TST.B	additionalPlayerCount
	BEQ	lbC055F9C
	MOVE.B	remainingRaces,D0
	EOR.B	#$01,D0
lbC055F9C:
	AND.B	#$01,D0
	ADD.B	temp,D0
	MOVE.B	D0,D1
	JSR	configureSelectedRace
	BTST	#$00,displayFlags
	BNE	lbC055FC0
	JMP	lbC04A77A

lbC055FC0:
	MOVE.B	#$0B,D2
	JSR	renderTrackInfoDisplay
	JSR	lbC050974
	JMP	lbC056128

finalizeRaceDisplay:
	JSR	setupDisplayMode
	JSR	lbC056216
	JMP	lbC056128

configureRaceSetup:
	JSR	setupGameConfiguration
	MOVE.B	trackBaseOffset,lbB00D4E8
	TST.B	additionalPlayerCount
	BEQ	lbC05600C
	JSR	displayLeagueRaceResults
	BRA	lbC056128

lbC05600C:
	JSR	setupDisplayMode
	JMP	lbC04A844

lbC056018:
	MOVE.B	#$00,D0
	JSR	setBackgroundColor
	MOVE.B	lbB00D4E8,D2
	MOVE.L	#lbB00E30E,A2
	MOVE.B	$00(A2,D2.W),D1
	MOVE.B	D1,savedPlayerIndex
	JSR	renderPlayerName
	JSR	renderSpace
	MOVE.B	savedPlayerIndex,D1
	TST.B	multiplayerRaceDisplayFlag
	BPL	lbC05606E
	JSR	renderLapTime
	JSR	lbC05082E
	ADD.B	#$0C,D1
	JSR	renderLapTime
	BRA	lbC0560B4

lbC05606E:
	MOVE.L	#lbL00E2F6,A1
	MOVE.B	$00(A1,D1.W),D0
	JSR	renderDecimal
	MOVE.L	#lbL00E2DE,A1
	MOVE.B	$00(A1,D1.W),D0
	JSR	lbC0506BA
	MOVE.L	#lbL00E2EA,A1
	MOVE.B	$00(A1,D1.W),D0
	JSR	lbC0506BA
	JSR	lbC050824
	MOVE.L	#lbL00E302,A1
	MOVE.B	$00(A1,D1.W),D0
	JSR	renderDecimal
lbC0560B4:
	ADDQ.B	#$01,lbB00D4E8
	MOVE.B	lbB00D4E8,D0
	CMP.B	maxRenderingIndex,D0
	RTS

	MOVE.B	#$07,D0
	JSR	lbC0561D2
	MOVE.B	#$60,D1
	JSR	renderLeagueText
	JSR	renderMenuCursor
	MOVE.B	#$6A,D1
	JSR	renderLeagueText
	MOVE.B	lbB00E325,D1
	JSR	renderPlayerName
	MOVE.B	#$E9,D1
	JSR	renderLeagueText
	JSR	renderMenuCursor
	MOVE.B	#$78,D1
	JSR	renderLeagueText
	MOVE.B	lbB00E326,D1
	JSR	renderPlayerName
	MOVE.B	#$EF,D1
	JSR	renderLeagueText
lbC056128:
	JSR	copyGraphicsRegion
	JSR	waitForDisplaySync
resetTextYOffset:
	MOVE.B	#$00,textYOffset
	RTS

copyGraphicsRegion:
	MOVE.L	frameBuffers,A0
	ADD.L	#$00000B6C,A0
	ADD.L	#$FFFFFEC0,A0
	MOVE.L	A0,A3
	ADD.L	#$00007D00,A3
	MOVE.W	#$007E,D4
lbC05615C:
	MOVE.W	#$000D,D3
lbC056160:
	MOVE.W	(A0)+,(A3)+
	MOVE.W	$1F3E(A0),$1F3E(A3)
	MOVE.W	$3E7E(A0),$3E7E(A3)
	MOVE.W	$5DBE(A0),$5DBE(A3)
	DBRA	D3,lbC056160
	ADD.L	#$0000000C,A0
	ADD.L	#$0000000C,A3
	DBRA	D4,lbC05615C
	RTS

waitForDisplaySync:
	JSR	readControllerInput
	AND.B	#$10,D0
	BNE	waitForDisplaySync
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

lbC0561D2:
	MOVE.B	D0,currentMenuItem
	JSR	configurePlayersAndCars
	JSR	renderMenuCursor
	MOVE.B	player1ID,D1
	JSR	renderPlayerName
	MOVE.B	#$28,D1
	JSR	renderLeagueText
	MOVE.B	player2ID,D1
	JSR	renderPlayerName
	MOVE.B	#$01,D0
	JSR	setBackgroundColor
	JMP	resetTextYOffset

lbC056216:
	MOVE.B	#$80,alternateEndScreenEnabledFlag
	MOVE.B	#$0B,D1
	MOVE.L	#lbL00E2C2,A0
	MOVE.L	#lbB00E30E,A1
lbC05622E:
	MOVE.B	$00(A1,D1.W),$00(A0,D1.W)
	SUBQ.B	#$01,D1
	BPL	lbC05622E
	JSR	setupGameConfiguration
	MOVE.B	#$0F,D1
	MOVE.B	#$0C,D2
	JSR	setTextPosition
	MOVE.B	#$D7,D1
	JSR	renderLeagueText
	MOVE.B	#$01,D0
	MOVE.B	D0,currentMenuItem
	MOVE.B	trackBaseOffset,D2
	BNE	lbC05629C
	MOVE.B	lbB00E30E,D0
	CMP.B	currentPlayerID,D0
	BNE	lbC0562F2
	MOVE.B	currentPlayerContext,D0
	BEQ	lbC05629C
	JSR	renderMenuCursor
	MOVE.B	#$CE,D1
	JSR	renderTextString
	JMP	lbC05632A

lbC05629C:
	JSR	renderMenuCursor
	MOVE.B	#$B7,D1
	JSR	renderLeagueText
	MOVE.B	trackBaseOffset,D2
	MOVE.L	#lbB00E30E,A2
	MOVE.B	$00(A2,D2.W),D1
	CMP.B	currentPlayerID,D1
	BNE	lbC0562CC
	MOVE.B	D1,alternateEndScreenEnabledFlag
lbC0562CC:
	JSR	renderPlayerName
	MOVE.B	trackBaseOffset,D2
	BNE	lbC0562F2
	JSR	renderMenuCursor
	MOVE.B	#$A7,D1
	JSR	renderTextString
	JMP	lbC05632A

lbC0562F2:
	MOVE.B	maxRenderingIndex,D2
	SUBQ.B	#$01,D2
	CMP.B	#$0B,D2
	BEQ	lbC05632A
	JSR	renderMenuCursor
	MOVE.B	#$C7,D1
	JSR	renderLeagueText
	MOVE.B	maxRenderingIndex,D2
	SUBQ.B	#$01,D2
	MOVE.L	#lbB00E30E,A2
	MOVE.B	$00(A2,D2.W),D1
	JSR	renderPlayerName
lbC05632A:
	MOVE.B	#$02,D0
	MOVE.B	D0,displayTrackID
lbC056334:
	JSR	setupGameConfiguration
	MOVE.B	trackBaseOffset,D2
	MOVE.L	#lbL00E2C2,A0
	MOVE.B	$00(A0,D2.W),D1
	MOVE.B	-$01(A0,D2.W),$00(A0,D2.W)
	MOVE.B	D1,-$01(A0,D2.W)
	SUBQ.B	#$01,displayTrackID
	BPL	lbC056334
	MOVE.B	currentPlayerID,D0
	CMP.B	lbB00E30E,D0
	BNE	lbC05639A
	MOVE.B	currentPlayerContext,D1
	BNE	lbC0563B6
	MOVE.B	D0,currentPlayerContext
	MOVE.L	#lbL00E2C2,A0
	MOVE.B	#$0B,D1
lbC056388:
	MOVE.B	D1,$00(A0,D1.W)
	SUBQ.B	#$01,D1
	BPL	lbC056388
	MOVE.B	#$00,D0
	BRA	lbC0563AA

lbC05639A:
	JSR	lbC0563D2
	MOVE.L	#lbL0563C6,A1
	MOVE.B	$00(A1,D1.W),D0
lbC0563AA:
	MOVE.B	D0,selectedTrack
	BEQ	lbC0563B6
	RTS

lbC0563B6:
	MOVE.B	#$06,D0
	ASL.B	#$01,D0
	SUBQ.B	#$02,D0
	MOVE.B	D0,objectDisplayThreshold
	RTS

lbC0563D2:
	MOVE.B	#$0B,D1
lbC0563D6:
	MOVE.L	#lbL00E2C2,A1
	CMP.B	$00(A1,D1.W),D0
	BEQ	lbC0563EA
	SUBQ.B	#$01,D1
	BPL	lbC0563D6
lbC0563EA:
	RTS

renderMenuCursor:
	MOVE.B	#$02,D0
lbC056412:
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
	BNE	lbC0564B4
	MOVE.W	#$0018,D4
lbC0564B4:
	MOVE.W	#$000D,D3
lbC0564B8:
	MOVE.W	(A0)+,(A3)+
	MOVE.W	(A0)+,$1F3E(A3)
	MOVE.W	(A0)+,$3E7E(A3)
	MOVE.W	(A0)+,$5DBE(A3)
	DBRA	D3,lbC0564B8
	ADD.L	#$00000030,A0
	ADD.L	#$0000000C,A3
	DBRA	D4,lbC0564B4
	SUBQ.B	#$01,lbB00D554
	BMI	lbC0564F6
	MOVE.L	A2,A0
	ADD.L	#$00000140,A4
	MOVE.L	A4,A3
	MOVE.W	#$000F,D4
	BRA	lbC0564B4

lbC0564F6:
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
	MOVE.L	#levelNames,A0		; Point to track names table
	MOVE.B	#$0F,D2			; Set length to 15 characters
lbC056548:
	MOVE.B	D2,temp			; Store character count
	ASL.B	#$04,D1			; Multiply track index by 16 (each name is 16 bytes)
	MOVE.B	#$00,D2			; Initialize character counter
lbC056554:
	MOVE.B	$00(A0,D1.W),D0		; Load character from track name
	JSR	renderCharacter		; Render the character
	ADDQ.B	#$01,D1			; Move to next character
	ADDQ.B	#$01,D2			; Increment counter
	CMP.B	temp,D2			; Check if 15 characters rendered
	BNE	lbC056554		; Loop until done
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

lbC0566E8:
	MOVE.L	#arctanTable,A0
	TST.W	D4
	BPL	lbC0566F6
	NEG.W	D4
lbC0566F6:
	TST.W	D5
	BPL	lbC0566FE
	NEG.W	D5
lbC0566FE:
	CMP.W	D4,D5
	BGE	lbC056706
	EXG	D4,D5
lbC056706:
	LSR.W	#$04,D7
	AND.B	#$FE,D7
	MOVE.W	$00(A0,D7.W),D0
	MULU	D4,D0
	SWAP	D0
	ADD.W	D5,D0
	RTS

initializeRenderingState:
	JSR	calculate3DProjection1
	MOVE.B	#$00,D0
	MOVE.B	D0,lbB00D4AE
	MOVE.B	D0,lbB00D45C
	MOVE.B	D0,lbB00D47F
	MOVE.W	#$FFFF,storedDepth
	MOVE.B	#$00,curveSmoothingFlag
	JSR	initializeRenderBuffer
	RTS

processGameFrame:
	JSR	initializeRenderingState
	MOVE.B	#$00,D0
	MOVE.B	D0,currentPlayerNameOffset
	MOVE.B	D0,selectedMenuItem
	JSR	getSegmentAtGridCoordinate
	BCS	lbC05678E
	CMP.B	#$FF,D0
	BNE	lbC0567F6
	MOVE.B	lbB00D407,D0
	MOVE.B	lbB00D409,D2
	JSR	adjustNetworkCoordinates
	CMP.B	#$FF,D0
	BNE	lbC0567F6
lbC05678E:
	MOVE.B	#$C0,collisionStateFlags
	TST.B	networkGameMode
	BEQ	lbC0567A6
	JSR	synchronizeNetworkState
lbC0567A6:
	TST.B	selectedRaceType
	BPL	lbC0567BC
	JSR	processOpponentLogic
	JSR	processTrackSegmentData
lbC0567BC:
	MOVE.B	lbB00D49F,lbB00D40E
	MOVE.W	lbW00D528,visibilityAccumulator
	MOVE.B	lbB00D49E,segmentDepthCounter
	BRA	lbC056880

;	JSR	busyWaitDelay
;	JSR	renderHorizon
;	JSR	renderMountainHorizon
;	JMP	lbC0569E2

lbC0567F6:
	MOVE.B	D0,currentSegmentIndex
	JSR	applyTrackSegmentGeometry
	JSR	checkRoadBoundaries
	MOVE.B	currentSegmentIndex,D0
	MOVE.B	D0,playerSegmentIndex
	BTST	#$06,collisionStateFlags
	BNE	lbC056826
	MOVE.B	D0,lbB00D49B
lbC056826:
	JSR	calculateTrackPosition
	MOVE.B	lbB00D40E,lbB00D49F
	MOVE.W	visibilityAccumulator,lbW00D528
	MOVE.B	segmentDepthCounter,lbB00D49E
	TST.B	networkGameMode
	BEQ	lbC05685E
	JSR	synchronizeNetworkState
	BRA	lbC056880

lbC05685E:
	TST.B	selectedRaceType
	BPL	lbC056880
	JSR	processOpponentLogic
	JSR	calculatePlayerDistance
	JSR	updateEngineState
	JSR	processTrackSegmentData
lbC056880:
	MOVE.B	#$80,D0
	MOVE.B	D0,processedSegmentIndices1
	MOVE.B	D0,processedSegmentIndices2
	MOVE.B	playerSegmentIndex,currentSegmentIndex
	MOVE.B	#$00,segmentDataStartIndex
	MOVE.B	lbB00D40E,D0
	BPL	lbC0568BA
	JSR	advanceToNextSegment
	MOVE.B	#$00,lbB00D40E
lbC0568BA:
	TST.B	lbB00D40E
	BNE	lbC0568E2
	JSR	retreatToPreviousSegment
	CMP.B	lbB00D4A6,D1
	BNE	lbC0568DC
	MOVE.W	#$0000,storedDepth
lbC0568DC:
	JSR	advanceToNextSegment
lbC0568E2:
	JSR	transformTrackSegmentCoordinates
	JSR	processTrackVisibility
	JSR	processRenderData
	JSR	processTrackSegments
	MOVE.B	#$00,lbB00D4E5
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
	MOVE.W	renderDataPointer,lbW05AC2C
	MOVE.W	transformedCoordinates1,lbW0579FC
	MOVE.W	transformedCoordinates2,lbW0579FE
	JSR	transformCoordinates
	JSR	drawTrackLines
	TST.B	selectedRaceType
	BMI	lbC05699E
	MOVE.W	#$FFFF,storedDepth
lbC05699E:
	TST.B	networkGameMode
	BEQ	lbC0569AE
	JSR	handleNetworkProtocol
lbC0569AE:
	MOVE.W	renderDataPointer,-(SP)
	JSR	renderHorizon
	JSR	renderMountainHorizon
	MOVE.W	(SP)+,renderDataPointer
	JSR	updateOpponentVisibility
	JSR	renderTrackFar
	MOVE.W	lbW05AC2C,renderDataPointer
	JSR	renderTrackNear
lbC0569E2:
	TST.B	raceStartTimer
	BNE	lbC0569FC
	TST.B	collisionStateFlags
	BPL	lbC0569FC
	JSR	handleCollisionEffects
lbC0569FC:
	JSR	processCollisionState
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
	BEQ	finishHUDRendering
	MOVE.B	flameAnimationFrame,D0
	ADDQ.B	#$01,D0
	CMP.B	#$03,D0
	BLT	lbC056A7A
	MOVE.B	#$00,D0
lbC056A7A:
	MOVE.B	D0,flameAnimationFrame
	MOVE.W	D0,-(SP)
	ADD.B	#$06,D0
	CMP.B	#$08,D0
	BNE	lbC056A92
	MOVE.B	#$31,D0				; left flames
lbC056A92:
	JSR	renderMaskedGraphicsObject
	MOVE.W	(SP)+,D0
	ADD.B	#$08,D0
	CMP.B	#$0A,D0
	BNE	lbC056AAA
	MOVE.B	#$32,D0				; right flames
lbC056AAA:
	JSR	renderMaskedGraphicsObject
finishHUDRendering:
	JSR	updateGameMessageDisplay
	RTS

updateWheelGraphics:
	MOVE.B	wheelSpeed,D0
	ADD.B	D0,wheelAnimationAccumulator
	BCC	selectWheelSprites
	JSR	advanceWheelRotationFrame
selectWheelSprites:
	MOVE.B	wheelRotationFrame,D0
	ADD.B	#$25,D0
	CMP.W	#$007E,rightWheelHeight
	BGE	setRightWheelSprite
	ADD.B	#$06,D0
setRightWheelSprite:
	MOVE.W	#$0000,D1
	JSR	setSpriteFromTable
	MOVE.B	#$05,D0
	SUB.B	wheelRotationFrame,D0
	ADD.B	#$25,D0
	CMP.W	#$007E,leftWheelHeight
	BGE	setLeftWheelSprite
	ADD.B	#$06,D0
setLeftWheelSprite:
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
	JSR	processTrackSegmentData2
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
	JSR	lbC051E5E
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
	JSR	calculateTrackCoordinatesFromData
	JSR	calculate3DProjection
	JSR	transformCoordinate
	BTST	#$06,collisionStateFlags
	BEQ	lbC056C94
	JSR	checkFarClippingPlane
	BCS	lbC056C9A
lbC056C94:
	JSR	lbC056DC2
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
	JSR	calculateTrackCoordinatesFromData
	JSR	calculate3DProjection
	JSR	transformCoordinate
	BTST	#$06,collisionStateFlags
	BEQ	lbC056D50
	JSR	checkFarClippingPlane
	BCS	lbC056D56
lbC056D50:
	JSR	lbC056DC2
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

lbC056DC2:
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
	MOVE.L	#previewSegmentPointers,A0
	ASL.W	#$02,D0
	MOVE.L	$00(A0,D0.W),A0
	MOVE.W	(A0),previewSegmentFlags
	MOVE.L	#segmentProcessedFlags,A3
	MOVE.L	#trackSegmentData,A6
	MOVE.B	trackSegmentLimitDoubled,D1
	JSR	lbC056F24
	MOVE.B	trackSegmentLimitDoubled,D1
	ADDQ.B	#$02,D1
lbC056F24:
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
	BTST	#$07,previewSegmentFlags
	BNE	lbC056FD0
	BRA	lbC056F8E

lbC056F5E:
	BTST	#$06,previewSegmentFlags
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
	JSR	lbC057020
	MOVE.W	D1,D3
	BCLR	#$01,D3
	OR.B	#$40,$00(A3,D3.W)
	SUBQ.B	#$04,D1
	BPL	lbC056F94
	ADDQ.B	#$04,D1
	MOVE.W	renderDataPointer,D3
	CMP.W	#$0020,D3
	BEQ	lbC05701E
	MOVE.W	D3,-(SP)
	SUB.W	#$0010,D3
	TST.W	D1
	BEQ	lbC057006
	ADDQ.W	#$04,D3
lbC057006:
	MOVE.W	D3,renderDataPointer
	MOVE.W	D1,D2
	ADD.B	#$78,D1
	JSR	drawClippedLine
	MOVE.W	(SP)+,renderDataPointer
lbC05701E:
	RTS

lbC057020:
	MOVEM.L	D1-D7/A3-A6,-(SP)
	MOVE.B	D1,savedPlayerIndex
	MOVE.W	#$0200,$78(A6,D1.W)
	MOVE.W	D1,D0
	LSR.W	#$02,D0
	JSR	processTrackCharacteristics
	MOVE.B	savedPlayerIndex,D1
	MOVE.W	D1,D2
	AND.W	#$0002,D2
	ADD.B	#$78,D1
	JSR	lbC04BE8E
	MOVEM.L	(SP)+,D1-D7/A3-A6
	RTS

processTrackSegmentData2:
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
	CMP.B	trackParameter3,D2
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
	MOVE.W	#$0020,renderDataPointer
	RTS

renderBarrierPost:
	ASL.W	#$02,D3
	MOVE.W	D3,renderDataPointer
	MOVE.L	#coordinateLookupTable,A4
	MOVE.L	#transformedVertexBounds,A5
	MOVE.B	D1,savedPlayerIndex
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
	JSR	lbC0573E2
	MOVE.B	savedPlayerIndex,D1
	MOVE.W	D1,D2
	SUBQ.B	#$04,D2
	JSR	drawClippedLine
	RTS

lbC0573CC:
	MOVE.L	#renderCommandQueue,A1
	MOVE.W	renderDataPointer,D3
	MOVE.L	#$80000000,$00(A1,D3.W)
	RTS

lbC0573E2:
	MOVE.B	D1,savedPlayerIndex
	MOVE.B	D1,D0
	AND.B	#$02,D0
	MOVE.B	D0,lbB00D4E8
	MOVE.B	D0,D2
	CMP.W	#$0078,D1
	BLT	lbC057408
	MOVE.W	#$0200,-$04(A6,D1.W)
	BRA	lbC057414

lbC057408:
	MOVE.L	#lbW00D434,A2
	MOVE.W	$00(A2,D2.W),-$04(A6,D1.W)
lbC057414:
	MOVE.B	lbB00D40E,D0
	JSR	processTrackCharacteristics
	MOVE.B	lbB00D4E8,D1
	MOVE.B	#$08,D2
	MOVE.B	lbB00D40F,D0
	AND.W	#$00FF,D0
	JSR	processCoordinateTransformation
	MOVE.B	savedPlayerIndex,D1
	CMP.W	#$0078,D1
	BGE	lbC057474
	MOVE.B	#$00,D0
	MOVE.B	lbB00D40F,curveMagnitude
	MOVE.W	$00(A6,D1.W),D0
	SUB.W	-$04(A6,D1.W),D0
	MOVE.B	curveMagnitude,D3
	ASL.W	#$07,D3
	BCLR	#$0F,D3
	MULS	D3,D0
	ASL.L	#$01,D0
	SWAP	D0
	ADD.W	D0,-$04(A6,D1.W)
lbC057474:
	SUBQ.B	#$04,D1
	MOVE.B	#$08,D2
	JSR	lbC04BE8E
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

generateTrackPreviewData:
	JSR	initializeTrackPreviewBuffers
	MOVE.L	#previewDataBuffer,previewDataWritePointer
	MOVE.B	#$00,segmentDataStartIndex
	MOVE.L	#trackSegmentData,A6
	MOVE.B	#$00,D1
lbC05750E:
	MOVE.B	D1,currentSegmentIndex
	MOVE.W	D1,D0
	MOVE.L	#previewSegmentPointers,A0
	ASL.W	#$02,D0
	MOVE.L	previewDataWritePointer,$00(A0,D0.W)
	MOVE.W	#$0000,previewSegmentFlags
	JSR	advanceToNextSegment
	JSR	loadTrackSegmentConfiguration
	TST.B	segmentSteeringFlags
	BPL	lbC057566
	MOVE.B	#$40,previewSegmentFlags
	MOVE.B	trackDirectionInversionFlag,D3
	MOVE.B	reverseDirectionFlag,D0
	EOR.B	D0,D3
	BPL	lbC057566
	MOVE.B	#$80,previewSegmentFlags
lbC057566:
	JSR	retreatToPreviousSegment
	JSR	loadTrackSegmentConfiguration
	MOVE.W	#$0000,visibilityAccumulator
	MOVE.B	segmentSlopeFlags,trackHeightDifference
	NEG.B	trackHeightDifference
	JSR	processTrackSegmentData2
	MOVE.B	segmentDataStartIndex,D1
	MOVE.L	#segmentProcessedFlags,A3
	MOVE.L	previewDataWritePointer,A4
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
	OR.W	previewSegmentFlags,D0
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
	JSR	calculateTrackCoordinatesFromData
	MOVE.W	lateralVelocity,(A4)+
	MOVE.W	lbW00D4F8,(A4)+
	MOVE.W	$00(A6,D1.W),(A4)+
	ADDQ.B	#$02,D1
	BTST	#$01,D1
	BNE	lbC05767C
lbC0576C0:
	CMP.B	trackSegmentLimitDoubled,D1
	BNE	lbC0575DC
	MOVE.L	A4,previewDataWritePointer
	MOVE.B	currentSegmentIndex,D1
	ADDQ.B	#$01,D1
	CMP.B	numTrackSegments,D1
	BLT	lbC05750E
	RTS

lbC0576E4:
	ADDQ.B	#$04,D1
	BRA	lbC0576C0

initializeTrackPreviewBuffers:
	CLR.W	D3
	MOVE.L	#trackPreviewParameters,A0
	MOVE.B	numTrackSegments,D3
	BRA	lbC057702

lbC0576FC:
	MOVE.B	#$78,$00(A0,D3.W)
lbC057702:
	DBRA	D3,lbC0576FC
	MOVE.L	#trackPreviewOverrideTable,A1
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
	MOVE.L	#previewSegmentPointers,A0
	ASL.W	#$02,D0
	MOVE.L	$00(A0,D0.W),A6
	MOVE.W	#$0004,D1
lbC0577DC:
	MOVE.W	(A6)+,D0
	MOVE.L	#memory_7AB5A,A0
	MOVE.W	D0,$00(A0,D1.W)
	MOVE.W	D0,previewSegmentFlags
	MOVE.B	D0,currentSegmentIndex
	JSR	transformSegmentToViewSpace
	MOVE.B	transformedGridX,D0
	EXT.W	D0
	MOVE.B	lbB00D42E,D4
	ASL.W	#$08,D4
	MOVE.B	lbB00D423,D4
	ASR.W	#$01,D4
	ASL.W	#$02,D0
	ASL.W	#$08,D0
	ADD.W	D0,D4
	MOVE.W	D4,transformedGridX
	MOVE.B	transformedGridY,D0
	EXT.W	D0
	MOVE.B	lbB00D432,D4
	ASL.W	#$08,D4
	MOVE.B	lbB00D427,D4
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
	JSR	lbC053D9C
	MOVE.W	(A6)+,D0
	MOVE.L	A6,-(SP)
	MOVE.L	#trackSegmentData,A6
	MOVE.W	D0,$00(A6,D1.W)
	SUB.W	lbW00D4FA,D0
	NEG.W	D0
	ASR.W	#$03,D0
	MOVE.W	lbW00D536,D3
	JSR	lbC053DF0
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
	BTST	#$07,previewSegmentFlags
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
	BTST	#$06,previewSegmentFlags
	BEQ	lbC05796E
lbC057938:
	MOVE.W	#$0200,$78(A6,D1.W)
	MOVE.W	$00(A4,D1.W),$78(A4,D1.W)
	MOVE.W	lbW00D4FA,D0
	SUB.W	#$0200,D0
	ASR.W	#$03,D0
	ADD.B	#$78,D1
	MOVE.W	lbW00D536,D3
	JSR	lbC053DF0
	JSR	applyScreenSpaceRotation
	SUB.B	#$78,D1
	BRA	lbC057974

lbC05796E:
	MOVE.W	#$8000,$78(A6,D1.W)
lbC057974:
	JSR	applyScreenSpaceRotation
	MOVE.L	(SP)+,A6
	CMP.L	previewDataWritePointer,A6
	BLT	lbC05798C
	MOVE.L	#previewDataBuffer,A6
lbC05798C:
	ADDQ.B	#$02,D1
	BTST	#$01,D1
	BNE	lbC057842
	MOVE.B	currentSegmentIndex,D2
	MOVE.L	#trackPreviewParameters,A0
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

updatePerformanceMetrics:
	MOVE.B	performanceStylePoints,D0
	CMP.B	lbB00D455,D0
	BEQ	lbC057A1A
	BCC	lbC057A1C
lbC057A1A:
	RTS

lbC057A1C:
	ADDQ.B	#$01,lbB00D455
	MOVE.B	lbB057BAA,D2
	BTST	#$00,lbB00D455
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
	MOVE.B	#$0B,lbB057BAB
	CMP.B	lbB057BAA,D2
	BLE	lbC057A8A
	MOVE.B	#$0C,lbB057BAB
lbC057A8A:
	MOVE.B	D2,lbB057BAA
	MOVE.B	lbB00D455,D0
	CMP.B	#$F0,D0
	BCS	lbC057AAA
	SUBQ.B	#$01,lbB00D455
lbC057AA4:
	JMP	initiateCarWreck

lbC057AAA:
	MOVE.L	frameBuffers,A0
	ADD.L	#$00000004,A0
	MOVE.B	lbB00D455,D4
	AND.W	#$00FF,D4
	ADD.B	#$08,D4
	MOVE.W	D4,D0
	MOVE.B	lbB057BAA,D5
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
	JSR	lbC057B86
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
	MOVE.B	lbB057BAB,D0
	JSR	setPixelColor
	JSR	plotPixel
	SUB.L	#$00007D00,A0
	JSR	plotPixel
	JMP	updatePerformanceMetrics

lbC057B54:
	ADDQ.B	#$01,performanceStylePoints
	BEQ	lbC057AA4
	JSR	lbC057B6A
	JMP	updatePerformanceMetrics

lbC057B6A:
	MOVE.B	#$02,D2
lbC057B6E:
	MOVE.B	performanceStylePoints,D0
	MOVE.L	#accumulatedOffTrackForceX,A2
	MOVE.B	D0,$00(A2,D2.W)
	SUBQ.B	#$01,D2
	BPL	lbC057B6E
	RTS

lbC057B86:
	MOVE.W	D4,D3
	AND.W	#$000F,D3
	ASL.W	#$02,D3
	MOVE.L	#lbW058160,A3
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
	BLS	chainAnimationComplete		; fixed BEQ
	SUB.B	chainLiftVelocity,D0
	MOVE.B	D0,chainVerticalPosition
	ADD.B	#$01,chainLiftVelocity		; fixed $08
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
	LSR.B	#$01,D0
	BCS	lbC057C62
	BCLR	#$06,lbB057D05
	BCLR	#$06,lbB057D1B
	BRA	lbC057C72

lbC057C62:
	BSET	#$06,lbB057D05
	BSET	#$06,lbB057D1B
lbC057C72:
	LSR.B	#$01,D0
	BCS	lbC057C8C
	BCLR	#$06,lbB057D09
	BCLR	#$06,lbB057D1D
	BRA	lbC057C9C

lbC057C8C:
	BSET	#$06,lbB057D09
	BSET	#$06,lbB057D1D
lbC057C9C:
	LSR.B	#$01,D0
	BCS	lbC057CB6
	BCLR	#$06,lbB057D0D
	BCLR	#$06,lbB057D21
	BRA	lbC057CC6

lbC057CB6:
	BSET	#$06,lbB057D0D
	BSET	#$06,lbB057D21
lbC057CC6:
	LSR.B	#$01,D0
	BCS	lbC057CE0
	BCLR	#$06,lbB057D11
	BCLR	#$06,lbB057D25
	BRA	lbC057CF0

lbC057CE0:
	BSET	#$06,lbB057D11
	BSET	#$06,lbB057D25
lbC057CF0:
	RTS

plotPixel:
	MOVE.B	D4,D0
	AND.W	#$000F,D0
	EOR.W	#$000F,D0
	CMP.W	#$0008,D0
	BGE	lbC057D16
	; FIXME Self modifying code here!
	dc.b	$01
lbB057D05:
	dc.b	$E8,$00,$01,$01
lbB057D09:
	dc.b	$E8,$1F,$41,$01
lbB057D0D:
	dc.b	$E8,$3E,$81,$01
lbB057D11:
	dc.b	$E8,$5D,$C1,$4E,$75

lbC057D16:
	AND.W	#$0007,D0
	; FIXME Self modifying code here!
	dc.b	$01
lbB057D1B:
	dc.b	$D0,$01
lbB057D1D:
	dc.b	$E8,$1F,$40,$01
lbB057D21:
	dc.b	$E8,$3E,$80,$01
lbB057D25:
	dc.b	$E8,$5D,$C0,$4E,$75

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
lbC057D4E:
	JSR	plotPixel
	ADDQ.W	#$01,D4
	MOVE.B	D4,D0
	AND.B	#$0F,D0
	BNE	lbC057D66
	ADD.L	#$00000002,A0
lbC057D66:
	CMP.W	D4,D6
	BNE	lbC057D4E
	RTS

applyBitplaneMask:
	MOVE.W	D4,D2
	NOT.W	D2
	; FIXME Self modifying code here!
	dc.w	$6000
	ds.b	1
lbB057D75:
	dc.b	$02

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

lbC057E76:
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
	MOVE.W	D1,lbB00D55A
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
	CMP.W	lbB00D55A,D0
	BNE	lbC0580DA
	ADDQ.L	#$06,A0
	MOVE.W	(A0)+,D4
	BPL	lbC057FE0
	SUBQ.B	#$01,lbB0581A0
	BMI	lbC0580DA
	MOVE.L	A1,A0
	MOVE.W	(A0)+,D0
	CMP.W	lbB00D55A,D0
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
	CMP.W	lbB00D55A,D0
	BNE	lbC0580DA
	ADDQ.L	#$06,A3
	MOVE.W	(A3)+,D5
	BPL	lbC058028
	SUBQ.B	#$01,lbB0581A0
	BMI	lbC0580DA
	MOVE.L	A2,A3
	MOVE.W	(A3)+,D0
	CMP.W	lbB00D55A,D0
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
	SUBQ.W	#$01,lbB00D55A
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
	MOVE.W	renderDataPointer,D0
	MOVE.L	lineDrawingBufferPointer,A0
	CMP.L	#memory_60A8,A0
	BLT	lbC0581EC
	TST.B	lineDrawingModeFlag
	BMI	lbC0581EC
	MOVE.L	#$80000000,$00(A1,D0.W)
	CLR.W	D1
	CLR.W	D2
	RTS

lbC0581EC:
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

initializeRenderBuffer:
	MOVE.L	#memory_3D80,A0
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
	MOVE.W	#$0020,renderDataPointer
	RTS

manageRenderBounds:
	MOVE.B	#$FF,previousSegmentIndex
	MOVE.W	renderDataPointer,D0
lbC0588FE:
	MOVE.L	#renderCommandQueue,A0
	SUB.W	#$0020,D0
	CMP.W	#$FF00,minBoundaryDistance
	BLT	lbC058922
	BTST	#$05,$1E(A1,D0.W)
	BNE	lbC058922
	SUB.W	#$0020,D0
lbC058922:
	AND.W	#$FFE0,D0
	MOVE.W	D0,storedDepth
	RTS

processTrackSegments:
	MOVE.B	#$FF,D4
	MOVE.B	lbB00D4A6,D0
	CMP.B	currentSegmentIndex,D0
	BNE	lbC05894A
	MOVE.B	lbB00D524,D4
	ASL.B	#$02,D4
lbC05894A:
	MOVE.B	D4,previousSegmentIndex
	MOVE.B	#$00,processedSegmentIndices1
	MOVE.W	#$0030,renderDataPointer
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
	CMP.W	#$05E0,renderDataPointer
	BCC	lbC058D5E
	MOVE.B	#$FF,D4
	MOVE.B	lbB00D4A6,D0
	CMP.B	currentSegmentIndex,D0
	BNE	lbC0589C0
	MOVE.B	lbB00D524,D4
	ASL.B	#$02,D4
lbC0589C0:
	MOVE.B	D4,previousSegmentIndex
	TST.B	previousSegmentIndex
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
	CMP.B	previousSegmentIndex,D1
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
	MOVE.B	D1,savedPlayerIndex
	MOVE.B	segmentAlternateFlag,D0
	ASL.B	#$01,D0
	EOR.B	D1,D0
	AND.B	#$04,D0
	MOVE.B	D0,segmentAlternateRenderFlag
	MOVE.L	#segmentProcessedFlags,A3
	MOVE.B	$00(A3,D1.W),segmentProcessedFlag
	JSR	lbC0530D0
	CMP.W	#$0030,renderDataPointer
	BEQ	lbC058B84
	TST.W	$00(A6,D2.W)
	BMI	lbC058A84
	TST.W	$00(A6,D1.W)
	BMI	lbC058A84
	MOVE.B	D2,D2
	ADD.B	#$00,D2
	ADD.B	#$00,D1
	JSR	drawClippedLine
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058A98

lbC058A84:
	MOVE.W	renderDataPointer,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058A98:
	ADD.W	#$0004,renderDataPointer
	TST.W	$02(A6,D2.W)
	BMI	lbC058AD0
	TST.W	$02(A6,D1.W)
	BMI	lbC058AD0
	MOVE.B	D2,D2
	ADD.B	#$02,D2
	ADD.B	#$02,D1
	JSR	drawClippedLine
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058AE4

lbC058AD0:
	MOVE.W	renderDataPointer,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058AE4:
	ADD.W	#$0004,renderDataPointer
	TST.W	$78(A6,D2.W)
	BMI	lbC058B1C
	TST.W	$78(A6,D1.W)
	BMI	lbC058B1C
	MOVE.B	D2,D2
	ADD.B	#$78,D2
	ADD.B	#$78,D1
	JSR	drawClippedLine
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058B30

lbC058B1C:
	MOVE.W	renderDataPointer,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058B30:
	ADD.W	#$0004,renderDataPointer
	TST.W	$7A(A6,D2.W)
	BMI	lbC058B68
	TST.W	$7A(A6,D1.W)
	BMI	lbC058B68
	MOVE.B	D2,D2
	ADD.B	#$7A,D2
	ADD.B	#$7A,D1
	JSR	drawClippedLine
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058B7C

lbC058B68:
	MOVE.W	renderDataPointer,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058B7C:
	ADD.W	#$0004,renderDataPointer
lbC058B84:
	TST.B	segmentAlternateRenderFlag
	BEQ	drawTrackSegmentWireframe
	TST.B	segmentProcessedFlag
	BPL	drawTrackSegmentWireframe
	BTST	#$06,segmentProcessedFlag
	BNE	drawTrackSegmentWireframe
	MOVE.W	renderDataPointer,D3
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D3.W)
	MOVE.L	#$80000000,$04(A1,D3.W)
	ADD.W	#$0008,renderDataPointer
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
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058C10

lbC058BFC:
	MOVE.W	renderDataPointer,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058C10:
	ADD.W	#$0004,renderDataPointer
	TST.W	$02(A6,D1.W)
	BMI	lbC058C48
	TST.W	$7A(A6,D1.W)
	BMI	lbC058C48
	MOVE.B	D1,D2
	ADD.B	#$02,D2
	ADD.B	#$7A,D1
	JSR	drawClippedLine
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058C5C

lbC058C48:
	MOVE.W	renderDataPointer,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058C5C:
	ADD.W	#$0004,renderDataPointer
lbC058C64:
	TST.B	segmentProcessedFlag
	BPL	lbC058C8C
	MOVE.W	renderDataPointer,D3
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D3.W)
	ADDQ.W	#$04,renderDataPointer
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
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058CD0

lbC058CBC:
	MOVE.W	renderDataPointer,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058CD0:
	ADD.W	#$0004,renderDataPointer
lbC058CD8:
	MOVE.W	renderDataPointer,D3
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
	ADDQ.W	#$04,renderDataPointer
	MOVE.L	#segmentProcessedFlags,A3
	MOVE.B	D1,processedSegmentIndices1
	CMP.W	#$05E0,renderDataPointer
	BCS	lbC0589EA
lbC058D5E:
	RTS

drawTrackLines:
	MOVE.B	#$00,lbB00D467
	MOVE.L	#trackSegmentData,A6
	MOVE.B	#$00,D2
	MOVE.B	#$04,D1
lbC058D76:
	CMP.W	#$05E0,renderDataPointer
	BCC	lbC059008
	MOVE.B	D1,savedPlayerIndex
	MOVE.B	D2,processedSegmentIndices1
	TST.W	$00(A6,D2.W)
	BMI	lbC058DBE
	TST.W	$00(A6,D1.W)
	BMI	lbC058DBE
	MOVE.B	D2,D2
	ADD.B	#$00,D2
	ADD.B	#$00,D1
	JSR	drawClippedLine
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058DD2

lbC058DBE:
	MOVE.W	renderDataPointer,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058DD2:
	ADD.W	#$0004,renderDataPointer
	TST.W	$02(A6,D2.W)
	BMI	lbC058E0A
	TST.W	$02(A6,D1.W)
	BMI	lbC058E0A
	MOVE.B	D2,D2
	ADD.B	#$02,D2
	ADD.B	#$02,D1
	JSR	drawClippedLine
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058E1E

lbC058E0A:
	MOVE.W	renderDataPointer,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058E1E:
	ADD.W	#$0004,renderDataPointer
	TST.W	$78(A6,D2.W)
	BMI	lbC058E56
	TST.W	$78(A6,D1.W)
	BMI	lbC058E56
	MOVE.B	D2,D2
	ADD.B	#$78,D2
	ADD.B	#$78,D1
	JSR	drawClippedLine
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058E6A

lbC058E56:
	MOVE.W	renderDataPointer,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058E6A:
	ADD.W	#$0004,renderDataPointer
	TST.W	$7A(A6,D2.W)
	BMI	lbC058EA2
	TST.W	$7A(A6,D1.W)
	BMI	lbC058EA2
	MOVE.B	D2,D2
	ADD.B	#$7A,D2
	ADD.B	#$7A,D1
	JSR	drawClippedLine
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058EB6

lbC058EA2:
	MOVE.W	renderDataPointer,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058EB6:
	ADD.W	#$0004,renderDataPointer
	TST.W	$78(A6,D1.W)
	BMI	lbC058EEE
	TST.W	$00(A6,D1.W)
	BMI	lbC058EEE
	MOVE.B	D1,D2
	ADD.B	#$78,D2
	ADD.B	#$00,D1
	JSR	drawClippedLine
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058F02

lbC058EEE:
	MOVE.W	renderDataPointer,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058F02:
	ADD.W	#$0004,renderDataPointer
	TST.W	$02(A6,D1.W)
	BMI	lbC058F3A
	TST.W	$7A(A6,D1.W)
	BMI	lbC058F3A
	MOVE.B	D1,D2
	ADD.B	#$02,D2
	ADD.B	#$7A,D1
	JSR	drawClippedLine
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058F4E

lbC058F3A:
	MOVE.W	renderDataPointer,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058F4E:
	ADD.W	#$0004,renderDataPointer
	TST.W	$00(A6,D1.W)
	BMI	lbC058F86
	TST.W	$02(A6,D1.W)
	BMI	lbC058F86
	MOVE.B	D1,D2
	ADD.B	#$00,D2
	ADD.B	#$02,D1
	JSR	drawClippedLine
	MOVE.B	savedPlayerIndex,D1
	MOVE.B	processedSegmentIndices1,D2
	BRA	lbC058F9A

lbC058F86:
	MOVE.W	renderDataPointer,D0
	MOVE.L	#renderCommandQueue,A1
	MOVE.L	#$80000000,$00(A1,D0.W)
lbC058F9A:
	ADD.W	#$0004,renderDataPointer
	MOVE.L	#renderCommandQueue,A0
	MOVE.W	renderDataPointer,D3
	MOVE.L	#memory_7AB5A,A3
	MOVE.W	$00(A3,D1.W),curveMagnitude
	MOVE.B	temp,D0
	MOVE.B	D0,$00(A0,D3.W)
	MOVE.B	curveMagnitude,$02(A0,D3.W)
	TST.B	lbB00D467
	BNE	lbC058FF4
	CMP.B	lbB00D4A6,D0
	BNE	lbC058FF4
	MOVE.W	D3,D0
	ADDQ.W	#$04,D0
	JSR	lbC0588FE
	MOVE.B	#$80,lbB00D467
lbC058FF4:
	ADDQ.W	#$04,renderDataPointer
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
	MOVE.W	renderDataPointer,D3
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
	MOVE.W	lbW00D542,D0
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
	MOVE.W	#$0000,renderDataPointer
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
	MOVE.W	D0,lbB00D55A
	CMP.W	#$0081,D0
	BCC	lbC05938A
	MOVE.W	(A2)+,D3
	MOVE.W	D3,lbB00D558
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
	MOVE.W	lbB00D558,D0
	ASL.W	#$02,D0
	ADD.W	lbB00D558,D0
	ASL.W	#$03,D0
	LEA	$00(A4,D0.W),A4
	MOVE.W	#$007F,D4
	SUB.W	lbB00D558,D4
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
	MOVE.W	lbB00D558,D4
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

renderPlayerCarModel:
	TST.B	carCrashedFlag
	BMI	lbC059A42
	MOVE.W	carRenderDistance,D0
	CMP.W	#$000A,D0
	BCS	lbC059A42
	CMP.W	#$0C80,D0
	BGE	lbC059A42
	MOVE.W	renderDataPointer,-(SP)
	MOVE.W	#$05E0,renderDataPointer
	JSR	clampAndSetupCoordinates
	MOVE.B	#$80,trackRenderingEnableFlag
	MOVE.W	#$05E0,renderDataPointer
	TST.B	curveSmoothingFlag
	BNE	lbC0594B8
	CMP.W	#$001C,networkEngineFlag
	BLT	lbC0594B8
	CMP.W	#$00E4,networkEngineFlag
	BGT	lbC0594B8
	ADD.W	#$0080,renderDataPointer
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderDataPointer,D3
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
	SUB.W	#$0080,renderDataPointer
lbC0594B8:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderDataPointer,D3
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
	MOVE.W	renderDataPointer,D3
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
	MOVE.W	renderDataPointer,D3
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
	MOVE.W	renderDataPointer,D3
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
	MOVE.W	renderDataPointer,D3
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
	MOVE.W	renderDataPointer,D3
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
	MOVE.W	renderDataPointer,D3
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
	MOVE.W	renderDataPointer,D3
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
	MOVE.W	renderDataPointer,D3
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
	MOVE.W	(SP)+,renderDataPointer
lbC059A42:
	RTS

clipLineAndMakeEdge:
	CMP.W	D2,D1
	BGE	lbC059A52
	EXG	D1,D2
lbC059A52:
	MOVE.L	lineDrawingBufferPointer,A0
	CMP.L	#memory_60A8,A0
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

lbC059AD6:
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
	JSR	lbC059D32
	MOVE.W	D3,-(SP)
	MOVE.W	D6,D1
	MOVE.W	D7,D2
	JSR	lbC059D32
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

lbC059D32:
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
	MOVE.W	D1,lbB00D55A
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
	MOVE.W	lbB00D55A,D0
	CMP.W	lbW05B3CE,D0
	BNE	lbC05A06A
	MOVE.W	lbB00D55A,-(SP)
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
	CMP.W	lbB00D55A,D4
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
	CMP.W	lbB00D55A,D5
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
	SUBQ.W	#$01,lbB00D55A
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
	MOVE.W	(SP)+,lbB00D55A
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
	MOVE.W	(SP)+,lbB00D55A
	SUBQ.B	#$01,scanlineCounter
	MOVE.L	(A1),A0
	ADD.L	#$00000008,A0
	BRA	lbC05A1D2

renderTrackSurfaceEdge:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderDataPointer,D3
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
	MOVE.W	renderDataPointer,D3
	BRA	lbC05A270

lbC05A23A:
	MOVE.B	$1D(A4,D3.W),D0
	BMI	lbC05A26C
	CMP.B	#$03,D0
	BEQ	lbC05A26C
	MOVE.B	hudDisplayMode1,D0
	JSR	setPixelColor
	MOVE.L	$10(A4,D3.W),D0
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A26C
	MOVE.L	D0,A3
	JSR	rasterizeVerticalEdge
lbC05A26C:
	SUB.W	#$0020,D3
lbC05A270:
	CMP.W	depthValue,D3
	BNE	lbC05A23A
	RTS

renderLeftBarrierEdges:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderDataPointer,D3
	BRA	lbC05A2C2

lbC05A28C:
	MOVE.B	$1D(A4,D3.W),D0
	BMI	lbC05A2BE
	CMP.B	#$03,D0
	BEQ	lbC05A2BE
	MOVE.B	hudDisplayMode1,D0
	JSR	setPixelColor
	MOVE.L	$14(A4,D3.W),D0
	AND.L	#$00FFFFFF,D0
	BEQ	lbC05A2BE
	MOVE.L	D0,A3
	JSR	rasterizeVerticalEdge
lbC05A2BE:
	SUB.W	#$0020,D3
lbC05A2C2:
	CMP.W	depthValue,D3
	BNE	lbC05A28C
	RTS

renderLeftRoadEdge:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderDataPointer,D3
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
	CMP.W	depthValue,D3
	BNE	lbC05A2DE
	RTS

renderRightRoadEdge:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderDataPointer,D3
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
	CMP.W	depthValue,D3
	BNE	lbC05A322
	RTS

renderRightBarrier:
	MOVE.B	#$80,renderingFlag
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderDataPointer,D3
lbC05A36A:
	MOVE.W	D3,lbW05B3E8
	MOVE.L	$10(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BNE	lbC05A3A0
lbC05A380:
	SUB.W	#$0020,D3
	CMP.W	depthValue,D3
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
	MOVE.B	hudDisplayMode2,D5
lbC05A3BC:
	TST.B	segmentRenderingFlag
	BEQ	lbC05A3CC
	MOVE.B	hudDisplayMode1,D5
lbC05A3CC:
	MOVE.B	D5,lbB05B3EC
	MOVE.L	D0,(A1)+
	MOVE.B	$10(A4,D3.W),D0
	MOVE.B	D0,lbB05B3EA
	MOVE.B	D0,lbB05B3DE
	EOR.B	#$40,D0
	MOVE.B	D0,lbB05B3E2
	CMP.W	#$0020,lbW05B3E8
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
	CMP.W	depthValue,D3
	BEQ	lbC05A454
	CMP.W	#$0020,D3
	BNE	lbC05A3FA
	BRA	lbC05A472

lbC05A448:
	SUBQ.L	#$04,A1
lbC05A44A:
	CMP.W	renderDataPointer,D3
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
	JSR	lbC059AD6
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
	MOVE.W	renderDataPointer,D3
lbC05A500:
	MOVE.W	D3,lbW05B3E8
	MOVE.L	$14(A4,D3.W),D0
	MOVE.L	D0,D4
	AND.L	#$00FFFFFF,D0
	BNE	lbC05A536
lbC05A516:
	SUB.W	#$0020,D3
	CMP.W	depthValue,D3
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
	MOVE.B	hudDisplayMode2,D5
lbC05A552:
	TST.B	segmentRenderingFlag
	BEQ	lbC05A562
	MOVE.B	hudDisplayMode1,D5
lbC05A562:
	MOVE.B	D5,lbB05B3EC
	MOVE.L	D0,(A1)+
	MOVE.B	$14(A4,D3.W),D0
	MOVE.B	D0,lbB05B3EA
	MOVE.B	D0,lbB05B3DE
	EOR.B	#$40,D0
	MOVE.B	D0,lbB05B3E2
	CMP.W	#$0020,lbW05B3E8
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
	CMP.W	depthValue,D3
	BEQ	lbC05A5EA
	CMP.W	#$0020,D3
	BNE	lbC05A590
	BRA	lbC05A608

lbC05A5DE:
	SUBQ.L	#$04,A1
lbC05A5E0:
	CMP.W	renderDataPointer,D3
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
	JSR	lbC059AD6
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
	MOVE.W	renderDataPointer,D3
	MOVE.W	D3,lbW05B3E8
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
	CMP.W	#$0020,lbW05B3E8
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
	CMP.W	depthValue,D3
	BEQ	lbC05A776
	CMP.W	#$0020,D3
	BNE	lbC05A71C
	BRA	lbC05A794

lbC05A76A:
	SUBQ.L	#$04,A1
lbC05A76C:
	CMP.W	renderDataPointer,D3
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
	JSR	lbC059AD6
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
	SUB.W	#$0020,renderDataPointer
	CMP.W	#$0040,renderDataPointer
	BLT	lbC05A9BA
lbC05A83C:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderDataPointer,D3
lbC05A848:
	SUB.W	#$0020,D3
	BEQ	lbC05A858
	TST.B	$1E(A4,D3.W)
	BMI	lbC05A848
lbC05A858:
	MOVE.W	D3,depthValue
	CMP.W	lbW00D51E,D3
	BLT	lbC05A9BA
	TST.B	lbB00D49A
	BNE	lbC05A8B2
	JSR	renderRightBarrier
	JSR	renderRightBarrierEdges
	JSR	renderLeftBarrier
	JSR	renderLeftBarrierEdges
	JSR	renderPlayerCarIfOpponentAhead
	JSR	renderPlayerCarIfOpponentBehind
	JSR	renderTrackSurface
	JSR	renderLeftRoadEdge
	JSR	renderRightRoadEdge
	JSR	renderPlayerCarIfOpponentHidden
	BRA	lbC05A9AC

lbC05A8B2:
	TST.B	offsetFromRoadCenter
	BPL	lbC05A936
	JSR	renderPlayerCarIfOpponentAhead
	JSR	renderLeftBarrier
	JSR	renderLeftBarrierEdges
	JSR	renderTrackSurface
	JSR	renderRightRoadEdge
	JSR	renderPlayerCarIfOpponentHidden
	JSR	renderRightBarrier
	JSR	renderRightBarrierEdges
	MOVE.W	renderDataPointer,D3
	CMP.W	lbW05B3E8,D3
	BEQ	lbC05A926
	TST.B	raceStartTimer
	BNE	lbC05A926
	MOVE.W	renderDataPointer,-(SP)
	MOVE.W	lbW05B3E8,renderDataPointer
	JSR	renderLeftRoadEdge
	MOVE.W	(SP)+,renderDataPointer
	BRA	lbC05A92C

lbC05A926:
	JSR	renderLeftRoadEdge
lbC05A92C:
	JSR	renderPlayerCarIfOpponentBehind
	BRA	lbC05A9AC

lbC05A936:
	JSR	renderPlayerCarIfOpponentBehind
	JSR	renderRightBarrier
	JSR	renderRightBarrierEdges
	JSR	renderTrackSurface
	JSR	renderLeftRoadEdge
	JSR	renderPlayerCarIfOpponentHidden
	JSR	renderLeftBarrier
	JSR	renderLeftBarrierEdges
	MOVE.W	renderDataPointer,D3
	CMP.W	lbW05B3E8,D3
	BEQ	lbC05A9A0
	TST.B	raceStartTimer
	BNE	lbC05A9A0
	MOVE.W	renderDataPointer,-(SP)
	MOVE.W	lbW05B3E8,renderDataPointer
	JSR	renderRightRoadEdge
	MOVE.W	(SP)+,renderDataPointer
	BRA	lbC05A9A6

lbC05A9A0:
	JSR	renderRightRoadEdge
lbC05A9A6:
	JSR	renderPlayerCarIfOpponentAhead
lbC05A9AC:
	MOVE.W	depthValue,renderDataPointer
	BNE	lbC05A83C
lbC05A9BA:
	RTS

renderTrackFar:
	SUB.W	#$0020,renderDataPointer
	MOVE.W	renderDataPointer,D3
	CMP.W	lbW05AC2C,D3
	BLT	lbC05AA6A
	SUB.W	#$0020,D3
	MOVE.W	D3,depthValue
	TST.B	lbB00D49A
	BNE	lbC05AA10
	JSR	renderRightTrackSidePanel
	JSR	renderLeftTrackSidePanel
	JSR	renderPlayerCarIfOpponentAhead
	JSR	renderPlayerCarIfOpponentBehind
	JSR	renderTrackSurface
	JSR	renderPlayerCarIfOpponentHidden
	BRA	lbC05AA66

lbC05AA10:
	TST.B	offsetFromRoadCenter
	BPL	lbC05AA42
	JSR	renderPlayerCarIfOpponentAhead
	JSR	renderLeftTrackSidePanel
	JSR	renderTrackSurface
	JSR	renderPlayerCarIfOpponentHidden
	JSR	renderRightTrackSidePanel
	JSR	renderPlayerCarIfOpponentBehind
	BRA	lbC05AA66

lbC05AA42:
	JSR	renderPlayerCarIfOpponentBehind
	JSR	renderRightTrackSidePanel
	JSR	renderTrackSurface
	JSR	renderPlayerCarIfOpponentHidden
	JSR	renderLeftTrackSidePanel
	JSR	renderPlayerCarIfOpponentAhead
lbC05AA66:
	BRA	renderTrackFar

lbC05AA6A:
	RTS

renderPlayerCarIfOpponentAhead:
	TST.B	opponentVisibilityFlag
	BEQ	lbC05AAB0
	BPL	lbC05AA92
	RTS

renderPlayerCarIfOpponentBehind:
	TST.B	opponentVisibilityFlag
	BMI	lbC05AA92
	RTS

renderPlayerCarIfOpponentHidden:
	TST.B	opponentVisibilityFlag
	BNE	lbC05AAB0
lbC05AA92:
	MOVE.W	depthValue,D3
	CMP.W	storedDepth,D3
	BGT	lbC05AAB0
	JSR	renderPlayerCarModel
	MOVE.W	#$FFFF,storedDepth
lbC05AAB0:
	RTS

renderLeftTrackSidePanel:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderDataPointer,D3
	MOVE.B	#$0F,D7
	BTST	#$00,$1C(A4,D3.W)
	BEQ	lbC05AAD4
	MOVE.B	hudDisplayMode2,D7
lbC05AAD4:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderDataPointer,D3
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
	MOVE.W	renderDataPointer,D3
	MOVE.B	#$0F,D7
	BTST	#$00,$1C(A4,D3.W)
	BEQ	lbC05AB90
	MOVE.B	hudDisplayMode2,D7
lbC05AB90:
	MOVE.L	#renderCommandQueue,A4
	MOVE.W	renderDataPointer,D3
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
	MOVE.W	lbW00D542,D0
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
	MOVE.B	lbB00D5E7,D3
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
	MOVE.W	#$0000,renderDataPointer
	MOVE.B	(A6)+,lbB05B097
lbC05AF20:
	MOVE.B	(A6)+,D1
	MOVE.B	(A6)+,D2
	MOVE.L	A6,-(SP)
	JSR	drawClippedLine
	MOVE.L	(SP)+,A6
	ADDQ.W	#$04,renderDataPointer
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
	MOVE.L	#memory_6490,A1				; cbits
	MOVE.W	#$0000,D4
lbC05B606:
	JSR	loadGraphicsElement
	ADDQ.W	#$01,D4
	CMP.W	#$000A,D4
	BNE	lbC05B61A
	MOVE.W	#$000F,D4
lbC05B61A:
	CMP.W	#$0034,D4
	BNE	lbC05B606
	MOVE.L	A1,-(SP)
	MOVE.L	#imageMainGameBackground,A0
	MOVE.L	#bitplaneMaskTable,A1
	JSR	decompressRLEObjectToMask
	MOVE.L	(SP)+,A1
	MOVE.W	#$000A,D4
lbC05B63C:
	JSR	loadGraphicsElement
	ADDQ.W	#$01,D4
	CMP.W	#$000F,D4
	BNE	lbC05B63C
	RTS

loadGraphicsElement:
	CLR.B	loadingHardwareSprite
	CMP.W	#$0025,D4		; skip hardware sprite graphics at indices 37-48
	BLT	lbC05B66C
	CMP.W	#$0030,D4
	BGT	lbC05B66C
	MOVE.B	#$80,loadingHardwareSprite
lbC05B66C:
	MOVE.W	D4,D0
	ASL.W	#$02,D0
	MOVE.L	#graphicsDataTable,A5			; graphic.pointers
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
	BEQ	lbC05B6BE
	JMP	loadHardwareSprite

lbC05B6BE:
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
	DBRA	D2,lbC05B6BE
	RTS

loadHardwareSprite:
	MOVE.W	D2,D6
	MOVE.W	(A3),D0
	ASL.W	#$04,D0
	ADD.W	#$0080,D0
	MOVE.W	$0002(A3),D3
	ADD.W	lbW05B7C4,D3
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
	MOVE.L	#lbL05B7B4,A1
	MOVE.W	#$0007,D0
lbC05B7AA:
	MOVE.W	(A1)+,(A0)+
	ADDQ.L	#$02,A0
	DBRA	D0,lbC05B7AA
	RTS

initializeSpritePointers:
	MOVE.W	#$0007,D3
lbC05B7CA:
	MOVE.W	D3,D1
	MOVE.L	#lbL000DB4,D0
	JSR	setSpritePointer
	DBRA	D3,lbC05B7CA
	RTS

setSpriteFromTable:
	MOVE.L	#graphicsDataTable,A1
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
	MOVE.L	#graphicsDataTable,A0
	MOVE.L	$00(A0,D1.W),A0
	MOVE.W	D1,D0
	ASL.W	#$02,D0
	MOVE.L	#graphicsRenderingParameters,A1
	MOVE.W	$0A(A1,D0.W),D0
	ADD.W	lbW05B7C4,D0
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
	ASL.W	#$02,D0
	MOVE.L	#graphicsDataTable,A1
	MOVE.L	$00(A1,D0.W),A1
	ASL.W	#$02,D0
	MOVE.L	#graphicsRenderingParameters,A2
	LEA	$04(A2,D0.W),A2
	MOVE.W	$0004(A2),D0
	MOVE.W	$0006(A2),D3
	MOVE.L	renderFrameBuffer,A0
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
lbC05B8A0:
	MOVE.L	A0,A2
	MOVE.W	D1,D3
lbC05B8A4:
	MOVE.W	(A1)+,D5
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
	DBRA	D3,lbC05B8A4
	LEA	$0028(A2),A0
	LEA	$1F68(A2),A4
	LEA	$3EA8(A2),A5
	LEA	$5DE8(A2),A6
	DBRA	D4,lbC05B8A0
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
	MOVE.L	#graphicsDataTable,A1
	MOVE.L	$00(A1,D0.W),A1
	ASL.W	#$02,D0
	MOVE.L	#graphicsRenderingParameters,A2
	LEA	$04(A2,D0.W),A2
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

	section Data,data
audioChannelMasks:
	dc.l	$00000001,$00000002,$00000004,$00000008
audioChannel0Period:
	dc.l	$07000000
sampleParameters:	EQU	*-2
	ds.w	1
downsampledSampleTable:
	ds.l	15
lbL000DB4:
	ds.l	1
sampleParameterTable:
	; sample 0: $0000F4B8, 2436 bytes, period 150, volume 30, channel 1, Short sound effect
	dc.l	$0000F4B8,$00000984
	dc.w	$0096,$001E,$0001,$0000
	; sample 1: $0000FE3C, 9032 bytes, period 180, volume 64, channel 1, engine
	dc.l	$0000FE3C,$00002348
sampleEnginePeriod:
	dc.w	$00B4,$0040,$0001,$0000
	; sample 2: $00012184, 8014 bytes, period 238, volume 56, channel 1, Crash/collision
	dc.l	$00012184,$00001F4E
	dc.w	$00EE,$0038,$0001,$0000
	; sample 3: $000140D2, 3108 bytes, period 400, volume 50, channel 1, Impact sound
	dc.l	$000140D2,$00000C24
	dc.w	$0190
	ds.b	1
sampleCrashVolume:
	dc.b	$32
	dc.w	$0001,$0000
	; sample 4: $00014CF6, 5170 bytes, period 238, volume 64, channel 2, Secondary sound 
	dc.l	$00014CF6,$00001432
	dc.w	$00EE
	ds.b	1
audioSample4Volume:
	dc.b	$40
	dc.w	$0002,$0000
	; sample 5: $00016128, 8430 bytes, period 280, volume 64, channel 3, Background audio
	dc.l	$00016128,$000020EE
	dc.w	$0118,$0040,$0003,$0000
	; sample 6: $00018216, 7120 bytes, period 500, volume 64, channel 1, ground collision
	dc.l	$00018216,$00001BD0
sampleGroundCollisionPeriod:
	dc.w	$01F4,$0040,$0001,$0000
baseSamplePointer:
	dc.l	sampleEngineData
sampleSizeTable:
	dc.w	$0000,$0C64,$012C,$0030,$0000,$0000
joystickState:
	dc.w	$FFFF
lbW00D190:
	dc.l	lowercaseTable
lbB00D194:
	dc.l	uppercaseTable
uppercaseTable:
	dc.b	$00,$31,$32,$33,$34,$35,$36,$37,$38,$39
	dc.b	$30,$00,$00,$00,$00,$30,$51,$57,$45,$52,$54,$59,$55,$49
	dc.b	$4F,$50,$00,$00,$00,$31,$32,$33,$41,$53,$44,$46,$47,$48
	dc.b	$4A,$4B,$4C,$3A,$00,$00,$00,$34,$35,$36,$00,$5A,$58,$43
	dc.b	$56,$42,$4E,$4D,$2C,$2E,$2F,$00,$2E,$37,$38,$39,$20,$08
	dc.b	$00,$0D,$0D,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	ds.b	104
lowercaseTable:
	dc.b	$00,$31,$32,$33,$34,$35,$36,$37
	dc.b	$38,$39,$30,$00,$00,$00,$00,$30,$71,$77,$65,$72,$74,$79
	dc.b	$75,$69,$6F,$70,$00,$00,$00,$31,$32,$33,$61,$73,$64,$66
	dc.b	$67,$68,$6A,$6B,$6C,$3A,$00,$00,$00,$34,$35,$36,$00,$7A
	dc.b	$78,$63,$76,$62,$6E,$6D,$2C,$2E,$2F,$00,$2E,$37,$38,$39
	dc.b	$20,$08,$00,$0D,$0D,$00,$00,$00,$00,$00,$00,$00,$00,$00
	ds.b	106
sineTable:
	incbin	"sineTable"
reciprocalTable:
	incbin	"reciprocalTable"
arctanTable:
	incbin	"arctanTable"
transformationMatrix:
	dc.w	$1614,$0218,$0F04,$1715,$0316,$1817,$140F,$1502,$0403
	dc.w	$1110,$1211,$454D,$332C,$6430,$0D09,$626E,$6509,$7363
	dc.w	$6F32,$0D09,$0D09,$7274,$730D,$090D,$4645,$5443,$4809
	dc.w	$6D6F,$7665,$2E62,$0930,$2861,$352C,$6435,$2E77,$292C
	dc.w	$6430,$0D09,$6164,$6471,$2E77,$0923,$312C,$6435,$0D66
	dc.w	$6574,$6368,$0961,$6E64,$692E
playerNamesWithSpaces:
	dc.b	' '
playerNames:
	dc.b	'Hot Rod      ',$D
	dc.b	$09
	dc.b	' Whizz Kid    '
	dc.b	$09
	dc.b	'T Bad Guy      '
	dc.b	$09
	dc.b	'b The Dodger   '
	dc.b	$09
	dc.b	'b'
BigEdMaxBoost.MSG:
	dc.b	' Big Ed       '
	dc.b	$09
	dc.b	'# Max Boost    p1 Dare Devil   ',$D
	dc.b	$09
	dc.b	' High Flyer   .b Bully Boy    ml Jumping Jack ,d Roa'
	dc.b	'd Hog     b. '
ascii.MSG3:
	dc.b	'             '
	dc.b	$09
	dc.b	$0D
	dc.b	$09
lbB01066B:
	dc.b	$0D,$09,$0D,"GTRACK",$0D,$09,$0D,$09,"move.b",$09,"d1,d0",$0D,$09,"asl."
engineCharacteristics:
	dc.l	$22206220,$3E043014,$4A100800
	dc.b	"e.b",$09,"d0,d"
	dc.b	"2",$0D,$09,"movea.l",$09,"#"
levelNames:
	dc.b	'LITTLE RAMP     '
	dc.b	'STEPPING STONES '
	dc.b	'HUMP BACK       '
	dc.b	'BIG RAMP        '
	dc.b	'SKI JUMP        '
	dc.b	'DRAW BRIDGE     '
	dc.b	'HIGH JUMP       '
	dc.b	'ROLLER COASTER  ',0
	dc.b	$81,$94,$00,$30,$A8,$0C,$80,$01,$81,$0F,$E0
	dc.b	$64,$08,$1E,$80,$01,$81,$0F,$E0,$14,$08,$1E,$80,$01,$81
	dc.b	$00,$F0,$03,$08,$03,$80,$01,$41,$02,$00,$64,$98,$01,$80
	dc.b	$02,$00,$00,$FF,$50,$07,$FF,$80,$00,$00,$00,$CF,$50,$07
	dc.b	$FF,$80,"ve.b",$09,"d0,DV",$0D,$09
	dc.b	"jsr",$09,"FETCH",$0D,$09,"mov"
	dc.b	"e.b",$09,"d0,DUH",$0D,$09,"mo"
	dc.b	"ve.b",$09,"d0,DVH",$09,$0D,$09
	dc.b	$0D,$09,"move.b",$09,"#0,d1"
	dc.b	$0D,$09,"mo",$E9,$E5,$FA,$F3,$F8,$E3,$ED,$E2,$FE,$8A
	dc.b	$ED,$EF,$E5,$EC,$EC,$8A,$E9,$F8,$EB,$E7,$E7,$E5,$E4,$EE
	dc.b	$8A,$9B,$93,$92,$92,"PDU"
attenuationTable:
	dc.w	$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FEFE,$FEFE
	dc.w	$FDFD,$FDFD,$FCFC,$FBFB,$FBFA,$FAF9,$F9F8,$F8F7,$F7F6
	dc.w	$F6F5,$F4F4,$F3F3,$F2F1,$F0F0,$EFEE,$EDEC,$ECEB,$EAE9
	dc.w	$E8E7,$E6E5,$E4E3,$E2E1,$E0DF,$DEDD,$DBDA,$D9D8,$D6D5
	dc.w	$D4D2,$D1CF,$CECC,$CBC9,$C8C6,$C5C3,$C1BF,$BEBC,$BAB8
	dc.w	$B6B4,$B2B0,$AEAC,$A9A7,$A5A2,$A09D,$9B98,$9592,$8F8C
	dc.w	$8986,$837F,$7C78,$7470,$6C68,$635E,$5953,$4D47,$3F37
	dc.w	$2D20
distanceLookupTable:
	dc.w	$1B1B,$1B1B,$1B1A,$1A1A,$1919,$1918,$1717,$1615,$1413
	dc.w	$1211,$0F0E,$0B09,$0707,$0707,$0707,$0707,$2331,$362C
	dc.b	"d0",$0D,$09,"beq",$09,"gt11",$0D,$09,"move"
	dc.b	".b"
trackGeometryDatabase:
	dc.w	$50B2,$A3B2,$A9FF,$FEB2,$59B3,$20DA,$D8B3,$3BB4,$0A46
	dc.w	$2E20,$9EB4,$A980,$852E,$60A5,$30C9,$8190
segmentGeometryOffsetTable:	; This is a lookup table containing ~130 encoded offset values that map segment type/configuration indices to geometry data locations within trackGeometryDatabase
	dc.w	$0DB5,$1BB5,$24B5,$36B5,$44B5,$52B5,$5CB5,$66B5,$6FB5
	dc.w	$78B5,$86B5,$94B5,$9DB5,$A6B5,$B2B5,$CAB5,$D3B5,$EBB5
	dc.w	$F7B5,$01B6,$0AB6,$14B6,$1DB6,$27B6,$31B6,$3AB6,$43B6
	dc.w	$4DB6,$57B6,$60B6,$69B6,$72B6,$7BB6,$84B6,$90B6,$99B6
	dc.w	$A2B6,$ABB6,$B7B6,$C0B6,$C9B6,$D5B6,$E1B6,$EDB6,$F9B6
	dc.w	$02B7,$0BB7,$14B7,$1DB7,$26B7,$32B7,$3EB7,$4CB7,$56B7
	dc.w	$5FB7,$68B7,$7AB7,$83B7,$8CB7,$95B7,$9EB7,$A7B7,$B0B7
	dc.w	$B9B7,$C3B7,$CCB7,$D6B7,$E8B7,$F1B7,$FAB7,$03B8,$0CB8
	dc.w	$16B8,$1FB8,$28B8,$31B8,$3AB8,$46B8,$4FB8,$58B8,$70B8
	dc.w	$A720,$7EB8,$87B8,$90B8,$9EB8,$ACB8,$B5B8,$BFB8,$C9B8
	dc.w	$D5B8,$DEB8,$E7B8,$F0B8,$FAB8,$03B9,$15B9,$27B9,$39B9
	dc.w	$4BB9,$54B9,$60B9,$6AB9,$74B9,$7EB9,$88B9,$91B9,$9AB9
	dc.w	$A3B9,$ACB9,$B5B9,$BEB9,$CAB9,$D4B9,$E0B9,$F8B9,$04BA
	dc.w	$0DBA,$1FBA,$28BA,$A320,$7DA3,$31BA,$AA20,$3ABA,$44BA
	dc.w	$4EBA,$58BA
trackDataOffsetTable:	; Each word is an encoded offset that, when transformed, points to a specific track's compressed data in trackGeometryDatabase
	dc.w	$62BA,$DEBA,$6FBB,$00BC,$8EBC,$1FBD,$F4BD,$82BE,$F5A7
	dc.w	$4C00,$A54C,$B2A3,$0017,$4163,$6375,$7261
geometryParameterTable:
	dc.w	$0080,$20C0,$0073,$80C0,$A959,$0002,$A95E,$854B,$0400
	dc.w	$4003,$1200,$AB80,$8001,$2040,$0300,$00C0,$0400,$0040
	dc.w	$0300,$01C0,$0400,$0140,$0300,$02C0,$0400,$0240,$0300
	dc.w	$03C0,$0400,$0340,$0300,$04C0,$0400,$0440,$0300,$05C0
	dc.w	$0400,$0540,$0300,$06C0,$0400,$0640,$0300,$07C0,$0400
	dc.w	$0740,$0300,$08C0,$0400,$080C,$80A8,$0D00,$0000,$FF80
	dc.w	$680A,$8712,$00AB,$8780,$013E,$4003,$0000,$C004,$0000
	dc.w	$4C03,$0501,$CA04,$DF00,$7303,$0702,$EB04,$BC01,$B203
	dc.w	$0503,$2205,$9502,$0A04,$FB03,$6D05,$6803,$7A04,$E704
	dc.w	$CD05,$3204,$0005,$C805,$4006,$F204,$9C05,$9A06,$C506
	dc.w	$A605,$4C06,$5B07,$5B07,$4C06,$0CC0,$57FA,$0000,$0001
	dc.w	$80E8,$0887,$1203,$AB87,$8001,$3E3F,$0300,$00BF,$0400
	dc.w	$0035,$03DF,$00B3,$0405,$0114,$03BC,$018C,$0407,$02DD
	dc.w	$0295,$024D,$0405,$0392,$0268,$03F5,$03FB,$0332,$0232
	dc.w	$0485,$03E7,$04BF,$01F2,$04FF,$02C8,$053A,$01A6,$0563
	dc.w	$029A,$06A4,$004C,$06B3,$015B,$0708,$4040,$FF00,$2080
	dc.w	$B51C,$00AB,$8080,$0120,$78FF,$8700,$8700,$78FF,$2C00
	dc.w	$3C01,$3C01,$2C00,$E100,$F001,$F001,$E100,$9601,$A502
	dc.w	$A502,$9601,$4A02,$5A03,$5A03,$4A02,$FF02,$0E04,$0E04
	dc.w	$FF02,$B303,$C304,$C304,$B303,$6804,$7705,$7705,$6804
	dc.w	$1D05,$2C06,$2C06,$1D05,$D105,$E106,$E106,$D105,$8606
	dc.w	$9507,$9507,$8606,$3A07,$4A08,$4A08,$3A07,$EF07,$FF08
	dc.w	$FF08,$EF07,$A408,$B309,$B309,$A408,$0C80,$0010,$0000
	dc.w	$00FF,$90C0,$0C7A,$1400,$AB7A,$8001,$3240,$0300,$00C0
	dc.w	$0400,$004C,$031C,$01CA,$04FB,$0071,$0336,$02EB,$04F4
	dc.w	$01AF,$034C,$0322,$05E9,$0204,$045C,$046D,$05D9,$0371
	dc.w	$0463,$05CD,$05C1,$04F5,$0460,$0641,$06A0,$058E,$0550
	dc.w	$07C8,$0673,$063B,$0632,$0861,$073B,$07FC,$0603,$090B
	dc.w	$08F4,$070C,$C000,$F800,$0000,$0190,$400B,$7A14,$03AB
	dc.w	$7A80,$0132,$4003,$0000,$C004,$0000,$3503,$FB00,$B304
	dc.w	$1C01,$1403,$F401,$8E04,$3602,$DD02,$E902,$5004,$4C03
	dc.w	$9202,$D903,$FB03,$5C04,$3202,$C104,$8E03,$6305,$BE01
	dc.w	$A005,$0A03,$6006,$3701,$7306,$7102,$5007,$9E00,$3B07
	dc.w	$C401,$3208,$F4FF,$F407,$0301,$0309,$0840,$40FF,$0020
	dc.w	$7CB0,$1800,$AB7C,$8001,$2078,$FF87,$0087,$0078,$FF32
	dc.w	$0041,$0141,$0132,$00EC,$00FC,$01FC,$01EC,$00A6,$01B6
	dc.w	$02B6,$02A6,$0160,$0270,$0370,$0360,$021B,$032A,$042A
	dc.w	$041B,$03D5,$03E4,$04E4,$04D5,$038F,$049F,$059F,$058F
	dc.w	$0449,$0559,$0659,$0649,$0503,$0613,$0713,$0703,$06BE
	dc.w	$06CD,$07CD,$07BE,$0678,$0787,$0887,$0878,$0700,$0000
	dc.w	$0000,$0000,$0000,$0000,$0000,$0000,$6061,$0344,$2628
	dc.w	$2A2C,$0000,$0200,$0400,$0600,$0800,$0A00,$0C00,$0E00
	dc.w	$1000,$0020,$4060,$0121,$4161,$0202,$0202,$0202,$0261
	dc.w	$4121,$0160,$4020,$0000,$0000,$0000,$0060,$2151,$0222
	dc.w	$4262,$0313,$0020,$4070,$2141,$6102,$2232,$0002,$0406
	dc.w	$E729,$CA4B,$2C46,$9655,$8524,$33B2,$2100,$0000,$0000
	dc.w	$0010,$2040,$6001,$2141,$6102,$0202,$0202,$0271,$6141
	dc.w	$2101,$6040,$2000,$0010,$1010,$1010,$1090,$8010,$0000
	dc.w	$0000,$0000,$8090,$0001,$0203,$0405,$0607,$0809,$0A0B
	dc.w	$1B80,$1C80,$1D80,$1E80,$1F80,$2080,$A180,$8000,$0000
	dc.w	$0000,$0000,$0000,$4E1D,$DB0A,$A836,$3422,$0000,$009B
	dc.w	$2019,$E018,$A017,$6016,$2014,$E013,$A012,$6011,$200F
	dc.w	$E00E,$A048,$2726,$3544,$6313,$4271,$2150,$0013,$0362
	dc.w	$4222,$0251,$21E0,$8005,$0585,$0000,$8505,$0505,$3222
	dc.w	$0261,$4121,$7040,$A080,$0040,$0141,$0242,$0333,$6300
	dc.w	$2030,$3030,$3030,$3030,$3030,$1000,$0000,$0000,$0000
	dc.w	$0000,$0000,$0000,$0000,$90B0,$3030,$3030,$3030,$30A0
	dc.w	$8000,$0000,$0000,$0000,$0090,$B030,$3030,$3030,$3030
	dc.w	$30A0,$8000,$2142,$53E4,$65E6,$5748,$0060,$4192,$62A3
	dc.w	$6314,$4400,$2040,$D060,$60D0,$4020,$0463,$B303,$4282
	dc.w	$3160,$00A6,$8000,$0000,$0000,$8035,$4787,$4675,$2544
	dc.w	$6303,$2241,$6000,$0827,$36C5,$4443,$3221,$0050,$5050
	dc.w	$50C0,$3020,$1000,$0000,$1030,$6011,$5122,$7200,$6041
	dc.w	$A2D2,$62F2,$7272,$7272,$7222,$B232,$A212,$F131,$6000
	dc.w	$0A68,$4726,$0563,$4221,$0000,$1030,$6021,$7142,$1363
	dc.w	$3405,$5555,$2676,$4718,$6839,$8A00,$0000,$0000,$C776
	dc.w	$2655,$0534,$6313,$4271,$2121,$6030,$1000,$0000,$0000
	dc.w	$0000,$008A,$8000,$0000,$0000,$804C,$0041,$0344,$0647
	dc.w	$094A,$0C70,$5030,$1000,$1030,$5070,$AA80,$0000,$0000
	dc.w	$0080,$2A59,$4939,$A963,$6363,$6347,$0000,$0010,$3050
	dc.w	$0131,$7142,$2314,$6262,$62D2,$42A2,$0261,$B101,$4000
	dc.w	$0040,$0141,$0242,$0343,$0464,$4526,$0767,$0010,$2030
	dc.w	$4040,$4040,$4040,$0000,$0000,$0010,$3060,$218D,$8000
	dc.w	$0000,$0000,$0000,$0000,$0000,$8000,$9C80,$1C80,$9C80
	dc.w	$8000,$0000,$0000,$0000,$1020,$4060,$0131,$7100,$1030
	dc.w	$7031,$71B2,$5262,$0000,$0010,$3060,$2102,$0300,$1030
	dc.w	$6021,$7162,$5344,$0070,$6152,$4334,$2516,$0700,$0000
	dc.w	$0000,$0000,$802E,$0001,$F152,$A363,$9434,$5400,$30D0
	dc.w	$7011,$A131,$4141,$4140,$1000,$0000,$1040,$1161,$4040
	dc.w	$4040,$4040,$3020,$1000,$9AC0,$8000,$0000,$0000,$0000
	dc.w	$0000,$0000,$8000,$0C80,$2403,$0221,$6030,$1000,$0047
	dc.w	$4665,$2505,$0515,$3575,$80E6,$1645,$7424,$5323,$1346
	dc.w	$2514,$1322,$4170,$3000,$0001,$1233,$5475,$1738,$597A
	dc.w	$0271,$D121,$6030,$1000,$0000,$0010,$3060,$21D1,$7102
	dc.w	$0040,$8131,$D161,$F171,$7122,$6121,$6030,$1000,$0000
	dc.w	$0060,$4122,$0363,$4425,$0666,$4728,$0000,$1030,$6021
	dc.w	$7152,$4324,$45E6,$8021,$4263,$0526,$2860,$27C0,$2740
	dc.w	$26E0,$26A0,$2680,$2680,$26A0,$26E0,$2720,$A760,$0000
	dc.w	$0001,$0203,$0405,$0607,$0868,$492A,$0B6B,$0070,$5132
	dc.w	$1373,$5435,$0600,$5031,$1272,$5334,$1506,$0060,$4122
	dc.w	$0373,$6465,$6667,$6869,$6A6B,$0060,$4122,$0353,$2464
	dc.w	$2565,$2666,$2767,$0081,$61A2,$4252,$5252,$5200,$4172
	dc.w	$1435,$5677,$193A,$5B00,$2142,$6305,$2647,$681A,$5B64
	dc.w	$1443,$7222,$5101,$4020,$1000,$0005,$0505,$1525,$45E5
	dc.w	$0000,$2212,$F151,$3111,$6030,$0000,$5031,$2223,$3455
	dc.w	$7618,$0021,$4263,$0526,$4768,$797A,$5271,$2160,$3010
	dc.w	$0000,$0000,$0000,$2000,$4000,$6032,$0000,$6000,$4000
	dc.w	$2000,$0000,$0000,$2000,$4000,$6032,$0000,$6000,$4000
	dc.w	$2000,$0000,$0000,$2000,$4000,$6032,$0000,$6000,$4000
	dc.w	$2000,$0000,$0000,$2000,$4000,$6032,$0000,$6000,$4000
	dc.w	$2000,$0063,$43A3,$F242,$0241,$0140,$2847,$6606,$2544
	dc.w	$6303,$2241,$6000,$1473,$4303,$4202,$4101,$4000,$7414
	dc.w	$4303,$4202,$4101,$4000,$1453,$1352,$1251,$1150,$A080
	dc.w	$7434,$7333,$7232,$7131,$E080,$2362,$2261,$2170,$4020
	dc.w	$0042,$4252,$7213,$43F3,$8000,$0000,$0080,$8505,$0505
	dc.w	$050C,$5947,$5504,$5241,$5000,$0010,$3050,$E050,$3010
	dc.w	$0000,$0000,$0080,$0000,$0000,$0404,$0404,$0404,$73E3
	dc.w	$3352,$4100,$4404,$4303,$4202,$4101,$4000,$4141,$4141
	dc.w	$4141,$31A1,$01E0,$3000,$18C0,$1680,$1440,$1200,$0FC0
	dc.w	$0D80,$0B40,$0900,$06C0,$0480,$0240,$0000,$7E4C,$1A08
	dc.w	$1644,$1302,$1140,$1000,$6030,$1000,$0010,$3060,$2113
	dc.w	$0010,$A00E,$400B,$E009,$8007,$2004,$C002,$6000,$0000
	dc.w	$E818,$4776,$2655,$0534,$0000,$0010,$3060,$2171,$4200
	dc.w	$2142,$6305,$2647,$680A,$0060,$3171,$3272,$3373,$3474
	dc.w	$0020,$5011,$5112,$5213,$5314,$0040,$0141,$0242,$0343
	dc.w	$94F4,$0040,$0141,$0242,$0343,$F394,$2C0F,$0F25,$0005
	dc.w	$A0CF,$6A9F,$6B24,$5050,$2500,$0019,$6380,$2F04,$6486
	dc.w	$1F65,$6657,$0E68,$67C0,$0D64,$04E0,$0C69,$9F17,$0000
	dc.w	$0000,$0000,$0000,$CC02,$C601,$1617,$B710,$0001,$2019
	dc.w	$1894,$3104,$032A,$4200,$2A53,$002A,$6400,$2A75,$282A
	dc.w	$8629,$2A97,$002A,$A82A,$2AB9,$2B2A,$CA00,$2ADB,$0004
	dc.w	$EC09,$0AD3,$FD16,$1766,$FE00,$17EF,$1B1A,$8DDF,$0605
	dc.w	$222F,$0202,$2146,$0358,$0122,$382A,$2A0E,$000F,$A0CF
	dc.w	$009F,$3B3C,$3C25,$1348,$4900,$3280,$2F04,$6486,$1F65
	dc.w	$6657,$0E68,$67C0,$0D64,$04E0,$0C69,$9F2E,$2F2E,$2F2E
	dc.w	$2F2E,$2F38,$C002,$4C03,$C601,$7C7D,$9710,$7F7E,$0020
	dc.w	$034C,$2030,$339F,$3315,$1E1F,$6464,$6464,$5E0C,$D006
	dc.w	$E016,$17D7,$F11B,$1A4D,$F260,$F300,$9F00,$4900,$5A6B
	dc.w	$0000,$4800,$4CFD,$46FE,$1617,$17EF,$1B1A,$8DDF,$0709
	dc.w	$3034,$0809,$03D4,$083F,$0FBE,$11BD,$13BB,$15BA,$2CF3
	dc.w	$1E42,$1011,$1213,$1415,$162F,$0535,$2E2E,$1340,$0560
	dc.w	$043A,$8F7A,$1C1D,$1E1F,$2227,$434D,$0D47,$0E17,$1696
	dc.w	$1F1A,$1B0C,$2F20,$3F00,$9F48,$0039,$0048,$4948,$0038
	dc.w	$00DF,$034C,$07EF,$7D7C,$56FE,$7E7F,$C0FD,$4C03,$E0FC
	dc.w	$336F,$4A71,$1F64,$645E,$CDF5,$C7F4,$1716,$16E3,$1A1B
	dc.w	$8CD3,$A0C3,$301F,$4B8C,$A381,$930B,$0C14,$8204,$0384
	dc.w	$710A,$0911,$600C,$0B8C,$50A0,$4000,$1F00,$8D20,$8710
	dc.w	$1716,$D601,$1A1B,$4C02,$6003,$0006,$0529,$3106,$0100
	dc.w	$5201,$4D1B,$4C25,$4F28,$4D34,$5C26,$2C01,$0118,$8007
	dc.w	$A0C0,$003F,$0000,$0080,$806D,$6E4F,$6E6D,$6D6E,$6E6D
	dc.w	$6D6E,$A030,$008D,$2087,$1017,$16D6,$011A,$1B4C,$0260
	dc.w	$0377,$9F29,$0000,$7640,$2900,$0045,$4D0D,$470E,$1716
	dc.w	$B61F,$0003,$2F18,$1954,$3E03,$04EA,$4D31,$EA5C,$0DEA
	dc.w	$6B0D,$EA7A,$8EEA,$8900,$EA98,$00EA,$A700,$EAB6,$90EA
	dc.w	$C511,$EAD4,$59C4,$E30A,$0951,$F217,$16E7,$F100,$16E0
	dc.w	$1A1B,$8CD0,$0A09,$2B29,$0508,$20D6,$0E4E,$0F4B,$134B
	dc.w	$1446,$1011,$1516,$2021,$2223,$280F,$0F23,$406A,$AABD
	dc.w	$71AA,$AC21,$AA9B,$64AA,$8ACF,$AA79,$00AA,$6800,$AA57
	dc.w	$00AA,$466F,$AA35,$F2AA,$2473,$8413,$090A,$5302,$1617
	dc.w	$E601,$0097,$101B,$1A0D,$2020,$3024,$0040,$5033,$0150
	dc.w	$5253,$9461,$3350,$2A72,$4C04,$8355,$5491,$9453,$5200
	dc.w	$A450,$3320,$B44C,$1F25,$0CD4,$06E4,$1617,$D7F5,$1B1A
	dc.w	$4DF6,$60F7,$4D5F,$477A,$4E7A,$564C,$FD46,$FE16,$1737
	dc.w	$EF00,$81DF,$1918,$14CE,$0403,$0708,$2B28,$0601,$03D8
	dc.w	$1554,$1836,$20C2,$0042,$27C9,$204E,$2A2A,$04A0,$11A0
	dc.w	$CC00,$7F38,$3333,$2C00,$0032,$804C,$0464,$863C,$6566
	dc.w	$572B,$6867,$C02A,$6404,$E029,$2B3F,$2035,$5CC0,$252D
	dc.w	$0DC6,$2457,$4797,$335D,$5800,$430D,$2D20,$531C,$3F1D
	dc.w	$3F00,$0093,$6D6E,$2F6D,$6E6E,$6D20,$C332,$00D3,$6404
	dc.w	$07E3,$6665,$76F2,$70E7,$F170,$16E0,$6768,$80D0
	dc.w	$0464,$A0C0,$709F,$7070,$70C2,$0064,$642B,$008D,$2087
	dc.w	$1017,$16D6,$011A,$1B4C,$0260,$0300,$9F00,$35DF,$E000
	dc.w	$E1E2,$2B38,$400D,$034C,$470E,$7D7C,$961F,$7E7F,$002F
	dc.w	$4C03,$203F,$339F,$3333,$151E,$1F22,$4464,$5E0D,$DF07
	dc.w	$EF17,$1676,$FE00,$E7FD,$0016,$EC1A,$1B8C,$DC04,$0448
	dc.w	$4809,$0703,$6206,$5507,$5014,$433D,$E441,$D82D,$5A2E
	dc.w	$502F,$C604,$0D26,$3334,$3536,$341D,$1D04,$4006,$203F
	dc.w	$009F,$003B,$254D,$3E26,$6464,$2B0D,$DF07,$EF17,$1656
	dc.w	$FE1A,$1BCC,$FDE0,$FC00,$5F00,$0000,$0000,$CDF6,$C3F5
	dc.w	$1716,$34E4,$00AA,$D300,$AAC2,$00A4,$B100,$11A0,$1819
	dc.w	$8C90,$A080,$005F,$0000,$0000,$008D,$2087,$1017,$16D6
	dc.w	$011A,$1B4C,$0260,$0300,$9F3A,$7A36,$00B7,$003D,$2743
	dc.w	$4D0D,$470E,$1716,$961F,$1A1B,$0C2F,$0606,$2C2A,$060E
	dc.w	$27D3,$28CE,$02D3,$1755,$1652,$1552,$1E1F,$2021,$2225
	dc.w	$2627,$2829,$2A2B,$2C2D,$4E00,$0025,$0005,$A0CF,$389F
	dc.w	$0182,$8282,$8282,$074A,$008C,$2F86,$1F16,$1757,$0E1B
	dc.w	$1ACD,$0DE0,$0C19,$9F08,$0FF5,$F5F5,$F56C,$745C,$C002
	dc.w	$2D0D,$C601,$5747,$9710,$5D58,$0020,$0D2D,$2030,$1C9F
	dc.w	$1D1E,$1F22,$2727,$2743,$3800,$D04C,$0306,$E005,$06F7
	dc.w	$F134,$66F2,$4117,$E312,$1480,$D364,$04A0,$C370,$7F4B
	dc.w	$3533,$3333,$3333,$8043,$034C,$8733,$0605,$F624,$3467
	dc.w	$2500,$9636,$1A1B,$0C46,$2056,$007F,$235B,$7070,$7070
	dc.w	$7000,$D604,$6406,$E665,$66D7,$F768,$6740,$F864,$0460
	dc.w	$F92B,$3F00,$0000,$4CFD,$46FE,$1617,$17EF,$1B1A,$8DDF
	dc.w	$0303,$5059,$0700,$062A,$0729,$0E36,$1A54,$1B4A,$4D52
	dc.w	$4C5A,$FE04,$BDFF,$0484,$0B85,$0C20,$7798,$4CA3,$8BA5
	dc.w	$2638,$E90F,$8526,$A41B,$840A,$2097,$8AC9,$2CD0,$3E4C
	dc.w	$95B6,$2054,$B3A5,$2618,$69F4,$854B,$A905,$854C,$2000
	dc.w	$A5A5,$2A85,$37A5,$2B85,$3820,$E9B4,$A526,$8527,$1869
	dc.w	$F985,$4BA9,$0585,$4C20,$5F9A,$F0AD,$BDF5,$0430,$04B0
	dc.w	$A690,$B490,$A2B0,$B04C,$968B,$0022,$E320,$7661
lbW01172C:
	dc.w	$0707,$0707,$0707,$0707,$413A,$3E41,$4851,$484F,$0000
	dc.w	$0000,$0000,$0000,$4841,$4548,$4F58,$4F56,$0703,$0303
	dc.w	$0303,$0703,$6657,$5759,$5969,$6264,$0703,$0303,$0301
	dc.w	$0303,$6155,$5356,$585B,$5A62
H.MSG:
	dc.b	$48,$00,$F0,$00,$EC,$00,$10,$60,$5B,$00,$00,$54,$0C,$40
	dc.b	$01,$3A,$01,$0C,$6E,$69,$01,$00
primaryFontBitmapData:
	dc.w	$0000,$0000,$0000,$0000,$9595,$9595,$AAEA,$EAEA,$1515
	dc.w	$1515,$156A,$6A6A,$75C3,$0000,$0000,$8080,$4040,$C000
	dc.w	$0080,$8080,$5555,$5555,$55AA,$AAAA,$5555,$5555,$55AA
	dc.w	$AAAA,$BDFF,$C3C0,$C3F3,$BFBF,$0000,$C0C0,$C0C0,$4040
	dc.w	$FF80,$8080,$8080,$8080,$8080,$8080,$8080,$80FF,$0808
	dc.w	$087F,$0808,$0800,$0101,$0101,$0101,$01FF,$0000
	ds.b	1
lbB0117ED:
	dc.b	$7F,$00,$00,$00,$00,$00,$00,$00,$00,$00
lbB0117F7:
	dc.b	$18
lbB0117F8:
	dc.b	$18,$00,$00,$02,$04,$08,$10,$20,$40,$00,$00,$3C,$42,$42
	dc.b	$42,$42,$3C,$00,$00,$10,$30,$10,$10,$10,$38,$00,$00,$3C
	dc.b	$42,$0C,$30,$40,$7E,$00,$00,$7E,$04,$0C,$02,$42,$3C,$00
	dc.b	$00,$04,$0C,$14,$24,$7E,$04,$00,$00,$7E,$40,$7C,$02,$02
	dc.b	$7C,$00,$00,$3C,$40,$7C,$42,$42,$3C,$00,$00,$7E,$04,$08
	dc.b	$10,$20,$20,$00,$00,$3C,$42,$3C,$42,$42,$3C,$00,$00,$3C
	dc.b	$42,$3C,$04,$08,$10,$00,$00,$00,$10,$00,$00,$10,$00,$00
	dc.b	$00,$00,$10,$00,$00,$10,$20,$00,$18,$18,$18,$18,$18,$00
	dc.b	$18,$00,$00,$00,$7E,$00,$7E,$00,$00,$00,$30,$18,$0C,$06
	dc.b	$0C,$18,$30,$00,$00,$38,$44,$04,$08,$10,$00,$10,$3C,$66
	dc.b	$6E,$6A,$6E,$60,$3C,$00,$00,$3C,$42,$42,$7E,$42,$42,$00
	dc.b	$00,$78,$44,$7C,$42,$42,$7C,$00,$00,$3C,$42,$40,$40,$42
	dc.b	$3C,$00,$00,$7C,$42,$42,$42,$42,$7C,$00,$00,$7E,$40,$78
	dc.b	$40,$40,$7E,$00,$00,$7E,$40,$78,$40,$40,$40,$00,$00,$3C
	dc.b	$42,$40,$4E,$42,$3E,$00,$00,$42,$42,$7E,$42,$42,$42,$00
	dc.b	$00,$38,$10,$10,$10,$10,$38,$00,$00,$04,$04,$04,$04,$44
	dc.b	$38,$00,$00,$44,$48,$70,$48,$44,$42,$00,$00,$20,$20,$20
	dc.b	$20,$20,$3E,$00,$00,$42,$66,$5A,$42,$42,$42,$00,$00,$42
	dc.b	$62,$52,$4A,$46,$42,$00,$00,$3C,$42,$42,$42,$42,$3C,$00
	dc.b	$00,$7C,$42,$7C,$40,$40,$40,$00,$00,$3C,$42,$42,$42,$42
	dc.b	$3C,$06,$00,$7C,$42,$7C,$48,$44,$42,$00,$00,$3E,$40,$3C
	dc.b	$02,$02,$7C,$00,$00,$7C,$10,$10,$10,$10,$10,$00,$00,$42
	dc.b	$42,$42,$42,$42,$3E,$00,$00,$42,$42,$42,$42,$24,$18,$00
	dc.b	$00,$42,$42,$42,$5A,$66,$42,$00,$00,$42,$24,$18,$18,$24
	dc.b	$42,$00,$00,$44,$44,$28,$10,$10,$10,$00,$00,$7E,$04,$08
	dc.b	$10,$20,$7E,$00,$01,$00,$00,$00,$00,$00,$00,$FF,$80,$00
	dc.b	$00,$00,$00,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$00,$01
	dc.b	$00,$00,$00,$FF,$00,$00,$00,$80
lbL01197A:
	dc.l	$01000000
lbW01197E:
	ds.w	1
lbB011980:
	dc.b	$00,$01,$00,$00,$00,$FF,$00,$00,$00,$FF,$00,$00,$3C,$02
	dc.b	$3E,$42,$3E,$00,$00,$40,$7C,$42,$42,$42,$7C,$00,$00,$00
	dc.b	$3E,$40,$40,$40,$3E,$00,$00,$02,$3E,$42,$42,$42,$3E,$00
	dc.b	$00,$00,$3C,$42,$7E,$40,$3C,$00,$00,$1C,$22,$20,$78,$20
	dc.b	$20,$00,$00,$00,$3E,$42,$42,$3E,$02,$3C,$00,$40,$40,$7C
	dc.b	$42,$42,$42,$00,$10,$00,$30,$10,$10,$10,$38,$00,$00,$08
	dc.b	$00,$08,$08,$08,$48,$30,$00,$20,$20,$24,$38,$24,$22,$00
	dc.b	$00,$30,$10,$10,$10,$10,$38,$00,$00,$00,$24,$5A,$5A,$42
	dc.b	$42,$00,$00,$00,$7C,$42,$42,$42,$42,$00,$00,$00,$3C,$42
	dc.b	$42,$42,$3C,$00,$00,$00,$7C,$42,$42,$7C,$40,$40,$00,$00
	dc.b	$3E,$42,$42,$3E,$02,$02,$00,$00,$5C,$62,$40,$40,$40,$00
	dc.b	$00,$00,$3E,$60,$3C,$06,$7C,$00,$00,$20,$7C,$20,$20,$24
	dc.b	$18,$00,$00,$00,$42,$42,$42,$42,$3E,$00,$00,$00,$42,$42
	dc.b	$42,$24,$18,$00,$00,$00,$42,$42,$5A,$5A,$24,$00,$00,$00
	dc.b	$42,$24,$18,$24,$42,$00,$00,$00,$42,$42,$42,$3E,$02,$3C
	dc.b	$00,$00,$7E,$04,$18,$20,$7E,$00,$00,$00,$00,$FF,$00,$00
	dc.b	$00,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$00,$00,$00
	dc.b	$00,$00,$00,$81,$FF,$00,$00,$00,$00,$00,$00,$FF,$30,$18
	dc.b	$0C,$06,$0C,$18,$30,$00,$80,$00
imageMainGameBackgroundPalette:
	dc.w	$0000,$0443,$0554,$0770,$0451,$0233,$0257,$0247,$0123,$0200
	dc.w	$0311,$0422,$0644,$0332,$0555,$0777
imageMainGameBackground:	incbin	"image0"
imageMenuScreenPalette:
	dc.w	$0000,$0777,$0555,$0222,$0000,$0743,$0632,$0421,$0310
	dc.w	$0240,$0021,$0046,$0025,$0710,$0500,$0740
imageMenuScreen:
	incbin	"imageMenuScreen"
alternateFontBitmapData:
	incbin	"alternateFontBitmapData"
imageTrackPreviewBackgroundPalette:
	dc.w	$0022,$0443,$0554,$0770,$0123,$0222,$0030,$0247,$0000
	dc.w	$0200,$0311,$0050,$0555,$0332,$0333,$0777
imageTrackPreviewBackground:	incbin	"image2"
imageStandingsBackgroundPalette:
	dc.w	$0000,$0221,$0332,$0443,$0034,$0110,$0030,$0770,$0000
	dc.w	$0200,$0311,$0070,$0555,$0221,$0333,$0777
imageStandingsBackground:	incbin	"image3"
imagePlayersPalette:
	dc.w	$0222,$0777,$0555,$0222,$0000,$0743,$0632,$0421,$0310
	dc.w	$0240,$0030,$0035,$0025,$0710,$0500,$0740
imagePlayers:
	incbin	"imagePlayers"
resultScreenPointerTable:	; fixme; data missing
	dc.l	frameBuffer1
	dc.l	imagePlayersPalette-2	; won
	dc.l	imagePlayersPalette-2	; lost
	dc.l	imagePlayersPalette-2	; wreck
	dc.l	imagePlayersPalette-2	; promotion
lbL049700:
	dc.b	$1F,$0E,$10,"Link abandoned",$FF,$1F,$0E,$10,"Link complete",$FF,$1F,$11,$10
	dc.b	"Linking",$FF,$1F,$0F,$10,"Please wait",$FF,$00
lbW049A46:
	dc.w	$0002,$040A,$162A,$4872
lbW049A4E:
	dc.w	$0101,$0306,$0A0F,$151C
lbW049A56:
	dc.w	$0001,$0001,$0001,$0002,$0102,$0001,$0203,$0002,$0103
	dc.w	$0003,$0201,$0001,$0203,$0400,$0102,$0304,$0002,$0103
	dc.w	$0402,$0003,$0104,$0001,$0203,$0405,$0102,$0005,$0304
	dc.w	$0002,$0305,$0104,$0003,$0402,$0501,$0004,$0103,$0205
	dc.w	$0001,$0203,$0405,$0600,$0102,$0304,$0506,$0002,$0104
	dc.w	$0305,$0602,$0004,$0105,$0306,$0204,$0005,$0103,$0604
	dc.w	$0003,$0106,$0205,$0001,$0203,$0405,$0607,$0002,$0103
	dc.w	$0406,$0507,$0003,$0102,$0407,$0506,$0004,$0307,$0105
	dc.w	$0206,$0005,$0104,$0207,$0306,$0007,$0106,$0205,$0304
	dc.w	$0006,$0107,$0204,$0305
lbL049D9A:
	ds.l	1
	ds.w	1
lbW049E00:
	dc.w	$0E45,$0102,$0304,$0506,$0708,$090A,$0B0C,$4142,$1011
	dc.w	$1213,$1415,$1617,$1819,$1A1B,$4463,$2021,$2223,$2425
	dc.w	$2627,$2829,$2A0D,$6000,$3132,$3334,$3536,$3738,$393A
	dc.w	$611C,$6440,$6750,$5152,$5354,$5556,$5758,$592B,$2C3B
	dc.w	$4C47,$4A4F,$484E,$5E49,$4D4B,$6869,$626A,$6665,$6B6C
	dc.w	$6D6E,$6F70,$7172,$305F,$465A,$5B5C,$5D3D,$3E3F,$2D2E
	dc.w	$2F1D,$1E1F,$0F3C,$4373,$7475,$7677,$7879,$7A7B,$7C7D
	dc.w	$7E7F
lbL04A180:
	ds.l	2
lbB04A3A2:
	ds.b	2
lbW04A3A4:
	dc.w	$0000,$0780,$0000,$29E0,$0000,$4C40,$0000,$07A8,$0000
	dc.w	$2A08,$0000,$4C68,$0000,$07D0,$0000,$2A30,$0000,$4C90
	dc.w	$0000,$07F8,$0000,$2A58,$0000,$4CB8,$0000,$0E66,$0000
	dc.w	$0E74,$0000,$156E,$0000,$157C,$0000,$0D72,$0000,$0D7C
	dc.w	$0000,$0D86,$0000,$01E0,$0000,$0A78,$0000,$1310,$0000
	dc.w	$01EA,$0000,$0A82,$0000,$131A,$0000,$01F4,$0000,$0A8C
	dc.w	$0000,$1324,$0000,$01FE,$0000,$0A96,$0000,$132E
lbW04A420:
	dc.w	$0307,$0B09,$0608,$0A04,$0001,$0502
lbW04A49A:
	dc.w	$C000,$C000,$0000,$0000,$0000,$0000,$0000,$0000,$0003
	dc.w	$0003
lbL04A4BC:
	dc.l	$0B0B0B0B,$05020E01,$040F090B
playerGraphicsMask:
	dc.l	$FFFFFFFF,$FFFFFFFF,$FFFFE000,$07FFFFFF,$F800001F
	dc.l	$E0000FFF,$FFFFFC00,$001FE000,$1FFFFFFF,$FE00001F
	dc.l	$E0003FFF,$FFFFFF00,$001FE000,$3FFFFFFF,$FF00001F
	dc.l	$E0007FFF,$FFFFFF80,$001FE000,$7FFFFFFF,$FF80001F
	dc.l	$E000FFFF,$FFFFFFC0,$001FE000,$FFFFFFFF,$FFC0001F
	dc.l	$E001FFFF,$FFFFFFC0,$001FE001,$FFFFFFFF,$FFC0001F
	dc.l	$E001FFFF,$FFFFFFE0,$001FE003,$FFFFFFFF,$FFE0001F
	dc.l	$E003FFFF,$FFFFFFE0,$001FE003,$FFFFFFFF,$FFE0001F
	dc.l	$E007FFFF,$FFFFFFF8,$001FE007,$FFFFFFFF,$FFF8001F
	dc.l	$E007FFFF,$FFFFFFF8,$001FE003,$FFFFFFFF,$FFF0001F
	dc.l	$E003FFFF,$FFFFFFF0,$001FE003,$FFFFFFFF,$FFF0001F
	dc.l	$E003FFFF,$FFFFFFE0,$001FE003,$FFFFFFFF,$FFE0001F
	dc.l	$E003FFFF,$FFFFFFE0,$001FE001,$FFFFFFFF,$FFE0001F
	dc.l	$E001FFFF,$FFFFFFE0,$001FE001,$FFFFFFFF,$FFE0001F
	dc.l	$E001FFFF,$FFFFFFC0,$001FE001,$FFFFFFFF,$FFC0001F
	dc.l	$E001FFFF,$FFFFFFC0,$001FE000,$FFFFFFFF,$FF80001F
	dc.l	$E0007FFF,$FFFFFF80,$001FE000,$7FFFFFFF,$FF80001F
	dc.l	$E0007FFF,$FFFFFF80,$001FE000,$3FFFFFFF,$FF00001F
	dc.l	$E0000FFF,$FFFFFC00,$001FE000,$07FFFFFF,$F800001F
	dc.l	$E0000FFF,$FFFFF800,$001FE000,$3FFFFFFF,$FFF8001F
	dc.l	$E007FFFF,$FFFFFFFF,$C01FE07F,$FFFFFFFF,$FFFFFE1F
	dc.l	$E7FFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
	dc.l	$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
	dc.l	$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
	dc.l	$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
	dc.l	$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
	dc.l	$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
	dc.l	$FFFFFFFF,$FFFFFFFF
	dc.w	$FFFF
lbW04AA40:
	ds.w	1
leagueStatisticsTextTable:
	dc.b	$1F,$14,$0F,"V",$FF,$1F,$07,$10,"Winner 2pts     Best Lap 1pt",$FF," Raced "
	dc.b	$FF," Wins  ",$FF," Laps   ",$FF," Points ",$FF,$1F,$07,$0A,"First      Se"
	dc.b	"cond        Third",$FF,$00
alternateEndScreenEnabledFlag:
	dc.b	$80,$00
coordinateTransformParameter:
	ds.w	1
	dc.b	$17,$13,$19,$08,$15,$0A,$08,$15,$09,$1F
textStringTable:
	dc.b	$1F,$11,$0B,"SELECT",$FF,"Practise ",$FF,"Start the Racing Season",$FF
	dc.b	"Load/Save/Replay       ",$FF,"Load",$FF,"Save",$FF,"Replay",$FF,"Cancel",$FF
	dc.b	"LOAD from Tape",$FF,"LOAD from Disc",$FF,"SAVE to Tape",$FF,"SAVE to Disc",$FF
	dc.b	$1F,$07,$14,"   Filename?  >",$FF,"to the SUPER LEAGUE",$FF,$1F,$0C
lbB04C057:
	dc.b	$09,"SUPER DIVISION ",$FF,"EXCELLENT DRIVING - WELL DONE",$FF
	dc.b	"Hall of Fame",$FF,$00
trackCharacteristicTable:
	dc.l	$D2BBB7B3,$B1ADABA7,$A6A4A2A1,$9F9F9F9E
colorProgressionTable:
	dc.l	$F7F7F6F6,$F5F5F6F7,$F8F9FBFD,$FF0205FD
lbL04C3F4:
	dc.l	$786E645A,$50463C32,$281E140A
lbL04C442:
	dc.l	$09060300
lbL04C4C8:
	ds.l	1
	dc.w	$0101
lbL04C4CE:
	dc.l	$01010202
	dc.w	$0202
specialSegmentLookupTable:
	dc.b	$03,$04,$04,$03
menuStringOffsetTable:
	dc.l	$EC0A142C,$44494E55,$5C6B5500,$7A875500,$0A1F7100
	dc.l	$2B400000,$49494949,$0A0A5500
aiMovementPatterns:
	dc.b	$20,$50,$60,$70
lbB04D738:
	dc.b	$70,$60,$50,$20,$E0,$B0
lbB04D73E:
	dc.b	$A0,$90
lbC04D740:
	dc.b	$90,$A0,$B0,$E0
lbL04DFB8:
	dc.l	$00D480D4,$0000ABAB,$40400000
lbB04E1F4:
	ds.b	104
	dc.b	$FF,$FF,$FF,$FF
lbB04E7E2:
	ds.b	24
lbL04E82C:
	dc.l	$28195027
divider:
	dc.b	'------------'
	dc.b	$09
	ds.b	1
	ds.b	1
	ds.b	1
lbL04FD6C:
	dc.l	$16171617,$02040204
gameMessageMode:
	ds.b	1
gameMessageIndex:
	ds.b	1
gameMessageTable:
	dc.b	$03,'<WRCECK'
	dc.b	$03,' RACCE !< WaON aT  '
	dc.b	$03,' RACCE ! LOaST '
	dc.b	$03,' DRCOP !<STaART'
	dc.b	$03,'<PRCESS! FIaRE '
	dc.b	$03,'PAUCSED'
	dc.b	$03,' LACPS ! OVaER '
	dc.b	$03,'DEFCINE! KEaYS '
	dc.b	$03,'<STCEER! LEaFT '
	dc.b	$03,'<STCEER!<RIaGHT'
	dc.b	$03,'<AHCEAD!+BOaOST'
	dc.b	$03,' BACCK !+BOaOST'
	dc.b	$03,' BACCK !   a   '
	dc.b	$03,'VERCIFY! KEaYS '
	dc.b	$03,'<FACULT!<FOaUND<T'
	dc.b	$06,$1A
divisionRowPositions:
	dc.b	$0C
	dc.b	$0C
	dc.b	$0C
	dc.b	$0C
	dc.b	$0B
	dc.b	$0B
	dc.b	$0A
	dc.b	$0A
trackColumnOffsets:
	dc.l	$13131312,$11100F0F
raceCount:
	dc.b	$06
currentPlayerID:
	dc.b	$0B
lbB05047E:
	ds.b	1
SELECTSingleP.MSG:
	dc.b	$1F,$11,$0B,"SELECT",$FF,"Single Player League",$FF,"Multiplayer",$FF
	dc.b	"Enter another driver",$FF,"Continue",$FF,"Tracks in DIVISION ",$FF,$00,$00,$00,$00,$00,$00
	dc.b	" S.",$FF,"        s",$FF,"Computer Link",$FF,"sssssssssssssssssssssTrack:  The ",$FF
	dc.b	$1F,$0A,$09,"DRIVERS CHAMPIONSHIP",$FF,$1F,$0E,$14,"Track record",$FF,$00
lbL050548:
	dc.b	"------------",$FF
Newtrackrecor.MSG:
	dc.b	"------------",$FF,$1F,$0C,$0F,"New track record",$FF
TRACKBONUSPOI.MSG:
	dc.b	"TRACK BONUS POINTS",$FF,$1F,$0E,$0C,"FINAL SEASON",$FF,"Race Time: ",$FF
	dc.b	"Best Lap : ",$FF,$1F,$10,$01," SLIPSTREAM ",$FF,$1F,$10,$05,"SUPER LEAGUE",$FF
	dc.b	$1F,$00,$07,"TRACK  DRIVER   LAP-TIME    DRIVER  RACE-TIME",$FF,$1F,$06
DRIVERBESTLAP.MSG:
	dc.b	$0E,"DRIVER      BEST-LAP RACE-TIME",$FF
lbB050E86:
	dc.b	"DIR "
HALL.MSG:
	dc.b	"HALL"
MP.MSG:
	dc.b	"MP$",$00,$10,$39,$00,$01,$BB,$94,$6B,$00,$00,$0C
	dc.b	$10,$39,$00,$01,$BB,$6B,$6B,$00,$00,$8A,$4E,$B9,$00,$06
	dc.b	$45,$32,$10,$3C,$00,$01,$13,$C0,$00,$01,$BB,$16,$4E,$B9
	dc.b	$00,$06,$4B,$0E,$12,$3C,$00,$0C,$4E,$B9,$00,$06,$4C,$2E
	dc.b	$10,$39,$00,$01,$BB,$94,$6A,$00,$00,$0C,$12,$3C,$00,$00
	dc.b	$4E,$B9,$00,$05,$F6,$F2,$14,$39,$00,$01,$CA,$31,$24,$7C
	dc.b	$00,$05,$F6,$36,$12,$32,$20,$00,$4E,$B9,$00,$05,$F6,$F2
	dc.b	$10,$39,$00,$01,$BB,$94,$6A,$00,$00,$24,$4E,$B9,$00,$06
	dc.b	$4B,$0E,$14,$39,$00,$01,$BB,$94,$54,$02,$02,$02,$00,$07
	dc.b	$24,$7C,$00,$05,$F6,$36,$12,$32,$20,$00,$4E,$B9,$00,$05
	dc.b	$F6,$F2,$4E,$B9,$00,$06,$44,$70,$4E,$B9,$00,$06,$48,$8A
	dc.b	$4E,$B9,$00,$06,$48,$34,$10,$39,$00,$01,$BB,$94,$4E,$75
	dc.b	$05,$0D,$43,$14,$2A,$43,$43,$43,$71,$8F,$94
NOTloadedsave.MSG:
	dc.b	" NOT",$FF," loaded",$FF," saved",$FF,"Incorrect data found ",$FF
	dc.b	"File name already exists",$FF,"Problem encountered",$FF
	dc.b	"File name is not suitable",$FF,$1F,$05,$13,"Insert game position save ",$FF
	dc.b	"tape",$FF,"disc",$FF,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F
	dc.b	$FF
	even
lbW051020:
	dc.w	$683B
lbB0513DE:
	dc.b	$00,$01,$04,$03,$02
t.MSG:
	dc.b	$B4,$A4,$94,$84,$74
DDDDDDDD.MSG:
	dc.b	$2A,$40,$21,$22,$44,$2A,$40,$21,$22,$44,$2A,$40,$21,$22
	dc.b	$44,$2A,$40,$21,$22,$44,$2A,$40,$21,$22,$44,$2A,$40,$21
	dc.b	$22,$44,$2A,$40,$21,$22,$44,$2A,$40,$21,$22,$44
LRHBSSBRHJRCS.MSG:
	dc.b	"L"
RHBSSBRHJRCSJ.MSG:
	dc.b	"RHBSSBRHJRCSJDB"
lbL051E52:
	dc.l	$04000408
lbB051E56:
	dc.b	$00,$04,$08,$04
lbL051E5A:
	dc.l	$004080C0
lbB052586:
	dc.b	$11,$11
controlKeys:
	dc.b	$2A,$40,$21,$22,$44	; #, space, S, D, return
keycodeTable:
	dc.b	$01
	dc.b	$02
	dc.b	$03
	dc.b	$04
	ds.b	1
dustCloudOffsetTable:
	dc.l	$00200020,$00200028,$00180020,$00200020
dustCloudAnimSequence:
	dc.b	$03,$06,$07,$02,$01,$05,$00,$04,$00,$05,$01,$02,$07,$06
	dc.b	$02,$07
steeringOffsetTable:
	dc.l	$000000D9
	dc.w	$FF27
trackDisplayYOffsets:
	dc.l	$0F0D1010,$100F100D
	ds.w	1
lbB0530CA:
	dc.b	$00,$00,$4B,$26,$49,$27
ascii.MSG1:
	dc.b	$2C,$00,$0A,$00,$D3,$00,$F5,$00
LOADgameposit.MSG:
	dc.b	$1F,$0B,$09,"LOAD game position",$FF,$1F,$0B,$09,"SAVE game position",$FF
	dc.b	"Drive not ready",$FF,"Disc write protected",$FF,"Insert disc",$FF,"Disc error",$FF
	dc.b	"Incorrect data found  ",$FF,"Type in file name",$FF,$1F,$07,$16,"                            "
	dc.b	$1F,$07,$17,"                             ",$FF,$1F,$08,$17,$FF,"Disc error: retry or escape"
	dc.b	$FF,$1F,$08,$16,"Warning: this disc has not",$1F,$08,$17,"been used for game saving",$FF
	dc.b	$1F,$05,$0F,"Insert formatted game save disc",$1F,$0E,$11,"into drive 0.",$1F,$09,$14
	dc.b	"Press any key to continue",$FF,$00
	even
	dc.w	$0008
lbB0544B8:
	dc.b	$0F
lbB0544B9:
	dc.b	$0B
lbW054632:
	dc.w	$8000
lbW054F84:
	dc.w	$FFFF,$FFFF,$FFFF,$FFFF
lbL054FB8:
	dc.l	$3B3B1E49
lbB054FB9:	EQU	*-3
	dc.b	$3B,$3B,$35,$62
lbW055BEA:
	dc.w	$0004,$0004,$FFFC
leagueTextTable:
	dc.w	$1F0F
lbB055C56:
	dc.b	$09,"DIVISION ",$FF,$1F,$0E
lbB055C63:
	dc.b	$0D,"RACE  ",$FF,$1F,$06,$0B,"Track:  ",$FF,"The ",$FF," V ",$FF,$1F,$03,$18
  	dc.b    "steer to rotate view or fire to continue",$FF,$1F
trackSpecificYOffset:
	dc.b	$0F,$15,"The ",$FF,$1F,$11,$0F,"RESULT",$FF,"Race Winner: ",$FF,"Fastest Lap: ",$FF,$1F,$0E,$0B
	dc.b	"RESULTS TABLE",$1F,$06,$0E,"DRIVER     RACED WIN LAP  PTS",$FF,"Promotion for  ",$FF
	dc.b	"Relegation for ",$FF," CHANGES",$FF,$1F,$12,$0E,"NAME?",$FF," 2pts",$FF," 1pt",$FF," of ",$FF,$00
trackIDLookupTable:
	dc.w	$0002,$0103,$0607,$0405
raceConfigLookupTable:
	dc.l	$08050C05,$05080C08
lbL0563C6:
	dc.l	$03030302,$02020101,$01000000
lbL0563EC:
	dc.l	$2F76EA80
skipSaveSlotScreen:
	dc.b	$00,$06,$04,$00
lbL0563F4:
	dc.l	$0D101316,$1013100F,$14170A0E
	dc.w	$1216
displayColumnOffset:
	dc.b	$0E,$0B,$11,$0C,$13,$FC,$00,$03,$00,$06,$4C,$18
menuCursorObjectType:
	dc.b	$02,$00
lbL05651A:
	dc.l	$00004070,$00004F70,$00005E70,$00006D70,$00003170
lbB056DC0:
	ds.b	2
trackPreviewOverrideTable:
	dc.b	$80,$00,$00,$00,$00,$00,$00,$00		; 4 entries of (segment_index, override_value) pairs, $80 terminates the list
	dc.b	$80,$00,$00,$00,$00,$00,$00,$00
	dc.b	$30,$18,$80,$00,$00,$00,$00,$00
	dc.b	$80,$00,$00,$00,$00,$00,$00,$00
	dc.b	$1A,$18,$80,$00,$00,$00,$00,$00
	dc.b	$0F,$28,$1C,$28,$80,$00,$00,$00
	dc.b	$80,$00,$00,$00,$00,$00,$00,$00
	dc.b	$3D,$30,$80,$00,$00,$00,$00,$00
lbB057BAA:
	dc.b	$04
lbB057BAB:
	dc.b	$0B,$FC,$F3,$CF,$3F,$03,$0C,$30,$C0
lbW0580E0:
	dc.w	$FFFF,$FFFF,$7FFF,$7FFF,$3FFF,$3FFF,$1FFF,$1FFF,$0FFF
	dc.w	$0FFF,$07FF,$07FF,$03FF,$03FF,$01FF,$01FF,$00FF,$00FF
	dc.w	$007F,$007F,$003F,$003F,$001F,$001F,$000F,$000F,$0007
	dc.w	$0007,$0003,$0003,$0001,$0001,$0000,$0000,$8000,$8000
	dc.w	$C000,$C000,$E000,$E000,$F000,$F000,$F800,$F800,$FC00
	dc.w	$FC00,$FE00,$FE00,$FF00,$FF00,$FF80,$FF80,$FFC0,$FFC0
	dc.w	$FFE0,$FFE0,$FFF0,$FFF0,$FFF8,$FFF8,$FFFC,$FFFC,$FFFE
	dc.w	$FFFE
lbW058160:
	dc.w	$8000,$8000,$4000,$4000,$2000,$2000,$1000,$1000,$0800
	dc.w	$0800,$0400,$0400,$0200,$0200,$0100,$0100,$0080,$0080
	dc.w	$0040,$0040,$0020,$0020,$0010,$0010,$0008,$0008,$0004
	dc.w	$0004,$0002,$0002,$0001,$0001
hudDisplayMode2:
	dc.b	$0A
hudDisplayMode1:
	dc.b	$09
mountainShape0Data:
	dc.w	$0004,$0000,$0000,$80C8,$0000,$804B,$8019,$8078
	dc.w	$801E,$0400,$0200,$0404,$0602,$0601,$0504,$0004,$080C
mountainShape1Data:
	dc.w	$0004,$0000,$0000,$80C8,$0000,$80FA,$0000,$8050,$801E
	dc.w	$0500,$0202,$0400,$0602,$0604,$0602,$0403,$0008,$0C05
	dc.w	$0304,$0C10
mountainShape2Data:
	dc.w	$0007,$0000,$0000,$81F4,$0000,$8348,$0000
	dc.w	$84A6,$0000,$8302,$805C,$8230,$8069,$833E,$80E6,$0A00
	dc.w	$0202,$0404,$0600,$0A02,$0804,$0806,$0C08,$0A0A,$0C08
	dc.w	$0C04,$0404,$000C,$1C10,$0503,$0410,$1405,$0408,$1424
	dc.w	$180F,$031C,$2024
mountainShape3Data:
	dc.w	$0006,$0000,$0000,$805A,$0000,$808C
	dc.w	$0000,$0000,$8140,$805A,$8140,$808C,$8140,$0700,$0202
	dc.w	$0400,$0602,$0804,$0A06,$0808,$0A02,$0F04,$0008,$140C
	dc.w	$0E04,$040C,$1810
mountainShape4Data:
	dc.w	$0004,$0000,$0008,$0032,$0000,$028A
	dc.w	$0000,$02BC,$0008,$0402,$0400,$0200,$0604,$0601,$0604
	dc.w	$0004,$080C

mountainData00:
	dc.w	$0180,$004B,$001C,$0104,$0010
mountainData01:
	dc.w	$0100,$007D,$0012,$00C0,$001E
mountainData02:
	dc.w	$0180,$0064,$0014,$0136,$0025
mountainData03:
	dc.w	$0100,$0046,$0018,$00D8,$0024
mountainData04:
	dc.w	$0180,$00C8,$0027,$00F0,$001F
mountainData05:
	dc.w	$0100,$0032,$000C,$00A8,$001A
mountainData06:
	dc.w	$0172,$0070,$0019,$00E6,$0014
mountainData07:
	dc.w	$00FA,$0064,$000C,$00BB,$0012
mountainData08:
	dc.w	$0180,$00C6,$001C,$013B,$0018
mountainData09:
	dc.w	$0100,$0023,$0028,$006E,$0037
mountainData0a:
	dc.w	$0159,$005C,$002A,$00F0,$001E
mountainData0b:
	dc.w	$00FA,$002D,$000F,$0080,$000B
mountainData0c:
	dc.w	$017C,$0088,$002B,$00D2,$0023
mountainData0d:
	dc.w	$0100,$004B,$0029,$009B,$0037
	dc.w	$0064,$019A,$00FA,$002D,$004B,$023F,$00AA,$002D
	dc.w	$00B9,$0145,$007D,$0046,$0032,$012C,$00A5,$0015
mountainData10:
	dc.w	$00FA,$01A4,$0253,$0181,$002E,$0118,$0034,$019F,$0073
mountainData11:
	dc.w	$004B,$0127,$01F4,$00AF,$0032,$0087,$003C,$00FF,$0048
mountainData12:
	dc.w	$0087,$00C5,$00FA,$0096,$0046,$0069,$0050,$00AA,$005F
mountainData13:
	dc.w	$0087,$0113,$01A9,$0091,$002A,$003C,$0032,$008C,$004D
mountainData20:
	dc.w	$0010,$0018,$0050,$0010,$0050,$0018,$0050
mountainData21:
	dc.w	$0010,$0018,$003C,$0010,$003C,$0018,$003C
mountainData22:
	dc.w	$0028,$003C,$0039,$0028,$0039,$003C,$0039
mountainData23:
	dc.w	$0069,$007D,$002A,$0069,$002A,$007D,$002A
mountainData30:
	dc.w	$0000

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
trackMountainCountsAnglesAndIndices:
	dc.b	$20,$05,$00,$0F,$0D,$15,$0A,$1F,$0B,$25,$0C,$2F,$05,$35
	dc.b	$02,$3F,$03,$45,$00,$4F,$01,$55,$04,$5F,$05,$65,$02,$6F
	dc.b	$01,$75,$00,$7F,$05,$85,$02,$8F,$03,$95,$04,$9F,$05,$A5
	dc.b	$00,$AF,$09,$B5,$06,$BF,$07,$C5,$08,$CF,$05,$D5,$00,$DF,$03,$E5,$04,$EF,$01,$F5,$02,$FF,$05,$00
lbL05B7B4:
	dc.l	$00000000,$0FFF0C88,$00000000,$0FFF0C88
lbW05B7C4:
	dc.w	$002C
gameLoopControl:
	dc.w	$0020
graphicsRenderingParameters:      ; structs of 8 words, only 3-6 used (size, position)
	dc.w	$0000,$0000,$0001,$0039
rightWheelWidth:
	dc.w	$0010
rightWheelHeight:
	dc.w	$0077
	dc.w	$0000,$0000
	dc.w	$0002,$0000,$0001,$0039,$0010,$0077,$0000,$0000
	dc.w	$0004,$0000,$0001,$0039,$0010,$0077,$0000,$0000
	dc.w	$0008,$0000,$0001,$0039,$0002
leftWheelHeight:
	dc.w	$0077,$0000,$0000
	dc.w	$000A,$0000,$0001,$0039,$0002,$0077,$0000,$0000
	dc.w	$000C,$0000,$0001,$0039,$0002,$0077,$0000,$0000
	dc.w	$0000,$0044,$0003,$001B,$0002,$007B,$0000,$0000
	dc.w	$0004,$0044,$0003,$001B,$0002,$007B,$0000,$0000
	dc.w	$0008,$0044,$0003,$001B,$000E,$007B,$0000,$0000
	dc.w	$000C,$0044,$0003,$001B,$000E,$007B,$0000,$0000
	dc.w	$0002,$007B,$000F,$0014,$0002,$007B,$0000,$0000
	dc.w	$0002,$0090,$0001,$000E,$0002,$0090,$0000,$0000
	dc.w	$0010,$0090,$0001,$000E,$0010,$0090,$0000,$0000
	dc.w	$0002,$0010,$0000,$0005,$0002,$0010,$0000,$0000
	dc.w	$0011,$0010,$0000,$0005,$0011,$0010,$0000,$0000
	dc.w	$000E,$0000,$0000,$0007,$0006,$00BE,$0000,$0000
	dc.w	$000E,$0008,$0000,$0007,$0006,$00BE,$0000,$0000
	dc.w	$000E,$0010,$0000,$0007,$000D,$00BE,$0000,$0000
	dc.w	$000E,$0018,$0000,$0007,$000D,$00BE,$0000,$0000
	dc.w	$000F,$0000,$0000,$0007,$0004
chainRenderParams:
	dc.w	$0010,$0000,$0000
	dc.w	$000F,$0008,$0000,$0007,$0004,$0018,$0000,$0000
	dc.w	$000F,$0010,$0000,$0007,$000F,$0010,$0000,$0000
	dc.w	$000F,$0018,$0000,$0007,$000F,$0018,$0000,$0000
	dc.w	$0010,$0000,$0001,$0007,$0004,$0000,$0000,$0000
	dc.w	$0010,$0008,$0001,$0007,$0004,$0000,$0000,$0000
	dc.w	$0010,$0010,$0001,$0007,$0004,$0000,$0000,$0000
	dc.w	$0010,$0018,$0001,$0007,$0004,$0000,$0000,$0000
	dc.w	$0010,$0020,$0001,$0007,$0004,$0000,$0000,$0000
	dc.w	$0010,$0028,$0001,$0007,$0004,$0000,$0000,$0000
	dc.w	$0000,$0060,$0003,$0021,$0000,$0000,$0000,$0000
	dc.w	$0005,$0060,$0003,$001E,$0000,$0000,$0000,$0000
	dc.w	$0009,$0060,$0003,$0025,$0000,$0000,$0000,$0000
	dc.w	$000D,$0060,$0004,$0023,$0000,$0000,$0000,$0000
	dc.w	$0000,$0086,$0002,$001B,$0000,$0000,$0000,$0000
	dc.w	$0003,$0086,$0003,$0021,$0000,$0000,$0000,$0000
	dc.w	$0007,$0086,$0003,$0021,$0000,$0000,$0000,$0000
	dc.w	$000B,$0086,$0003,$0023,$0000,$0000,$0000,$0000
	dc.w	$0001,$00B0,$0000,$000F,$0011,$0077,$0000,$0000
	dc.w	$0003,$00B0,$0000,$000F,$0011,$0077,$0000,$0000
	dc.w	$0005,$00B0,$0000,$000F,$0011,$0077,$0000,$0000
	dc.w	$0008,$00B0,$0000,$000F,$0002,$0077,$0000,$0000
	dc.w	$000A,$00B0,$0000,$000F,$0002,$0077,$0000,$0000
	dc.w	$000C,$00B0,$0000,$000F,$0002,$0077,$0000,$0000
	dc.w	$0000,$00B0,$0000,$000F,$0011,$0077,$0000,$0000
	dc.w	$0002,$00B0,$0000,$000F,$0011,$0077,$0000,$0000
	dc.w	$0004,$00B0,$0000,$000F,$0011,$0077,$0000,$0000
	dc.w	$0007,$00B0,$0000,$000F,$0002,$0077,$0000,$0000
	dc.w	$0009,$00B0,$0000,$000F,$0002,$0077,$0000,$0000
	dc.w	$000B,$00B0,$0000,$000F,$0002,$0077,$0000,$0000
	dc.w	$0010,$0044,$0003,$001B,$0002,$007B,$0000,$0000
	dc.w	$0010,$00AC,$0003,$001B,$000E,$007B,$0000,$0000
	dc.w	$0010,$0086,$0003,$001B,$0008,$001B,$0000,$0000

bitplaneMaskTable:      ; fixme - the last couple of kilobytes are corrupt
	incbin	"bitplaneMaskTable"

name_graphics:	dc.b	"graphics.library",0

	section	ChipData,data_c
copperlist:
	dc.w	bpl1pth,$0007,bpl1ptl,$8000,bpl2pth,$0007,bpl2ptl,$A000,bpl3pth
	dc.w	$0007,bpl3ptl,$C000,bpl4pth,$0007,bpl4ptl,$E000,color00
copperlistColor0:
	dc.w	$0000,color01,$0000,color02,$0000,color03,$0000,color04,$0000
	dc.w	$018A,$0000,$018C,$0000,$018E,$0000,$0190,$0000,$0192
	dc.w	$0000,$0194,$0000,$0196,$0000,$0198,$0000,$019A,$0000
	dc.w	$019C,$0000,$019E,$0000,$01A0
copperlistColor16:
	dc.w	$0000,$01A2,$0000,$01A4,$0000,$01A6,$0000,$01A8,$0000
	dc.w	$01AA,$0000,$01AC,$0000,$01AE,$0000,$01B0,$0000,$01B2
	dc.w	$0000,$01B4,$0000,$01B6,$0000,$01B8,$0000,$01BA,$0000
	dc.w	$01BC,$0000,color31,$0000,spr0pth
copperlistSprite0:
	dc.w	$0000,spr0ptl,$0000,$0124,$0000,$0126,$0000,$0128,$0000
	dc.w	$012A,$0000,$012C,$0000,$012E,$0000,$0130,$0000,$0132
	dc.w	$0000,$0134,$0000,$0136,$0000,$0138,$0000,$013A,$0000
	dc.w	$013C,$0000,$013E,$0000,$FA01,$FF00,intreq,$8010,$FFFF
	dc.w	$FFFE

sampleData:
	incbin	"rawAudioSampleData"
sampleEngineData:
	incbin	"sample0"
downsampledEngineData:
	ds.b	3200

	section BSS,bss
palette:
	ds.w    16
sourcePalette:
  	ds.w    16
keyboardState:
	ds.b    128
serialReceiveBuffer:
	ds.b    256
serialTransmitBuffer:
	ds.b    256
ciaBTimerBSet:
	ds.b	2
serialBufferIndex:
	ds.l    1
lbB000B55:	EQU	*-3
serialWriteIndex:	EQU	*-2
serialReadIndex:	EQU	*-1
lbB000B58:
	ds.b	2
lbW000B5A:
	ds.w	1
crashAudioSampleID:
	ds.b	2
audioDMAEnableGuard:
	ds.w	1
bitplane1Pointer:
	ds.l	1
copperlistUpdatePendingFlag:
	ds.b	1
framesSinceCopperlistUpdateAccumulator:
	ds.b	1
lbW00D3F8:
	ds.w	1
gasInputIntensityValue:
	ds.b	1
gasInputAccumulatorValue:
	ds.b	1
lbB00D3FC:
	ds.b	1
lbB00D3FD:
	ds.b	1
lbB00D3FE:
	ds.b	3
trackWidthMultiplier:
	ds.b	3
trackViewOffsetX:
	ds.b	2
trackViewOffsetY:
	ds.b	1
lbB00D407:
	ds.b	2
lbB00D409:
	ds.b	1
trackProgressionByte:
	ds.w	1
gameStateCounter:
	ds.w	1
lbB00D40E:
	ds.b	1
lbB00D40F:
	ds.b	1
lbW00D410:
	ds.w	1
trackDistance:
	ds.w	1
trackDistanceHigh:	EQU	*-1
	ds.b	2
currentMenuItem:
	ds.b	1
speedDisplayThousands:
	ds.b	1
currentMenuItemCopy:
	ds.b	1
savedSegmentIndex:
	ds.b	1
curveMagnitude:
	ds.b	1
temp:
	ds.b	1
playerSegmentIndex:
	ds.b	1
opponentSegmentIndex:
	ds.b	1
lapCrossingDetectionFlag:
	ds.w	1
player1LapCounter:
	ds.b	1
player2LapCounter:
	ds.b	1
baseCoordinateX:
	ds.b	1
lbB00D423:
	ds.b	3
baseCoordinateY:
	ds.b	1
lbB00D427:
	ds.b	3
perpendicularOffsetY:
	ds.b	1
segmentDirectionTemp1:
	ds.b	1
segmentDirectionTemp2:
	ds.b	1
segmentDirectionSource:
	ds.b	1
lbB00D42E:
	ds.b	4
lbB00D432:
	ds.b	2
lbW00D434:
	ds.w	1
lbW00D436:
	ds.w	1
trackRenderingEnableFlag:
	ds.b	4
lbB00D43C:
	ds.b	1
lbB00D43D:
	ds.b	2
trackEffectFlag:
	ds.b	1
trackDirection:
	ds.b	1
restartTimerCountdown:
	ds.b	1
physicsUpdateCount:
	ds.b	1
distanceCharacteristic:
	ds.b	1
aiEnabled:
	ds.b	1
boundaryCollisionDirectionFlag:
	ds.b	1
collisionActiveFlag:
	ds.b	1
inputStateFlags:
	ds.b	1		; Bits: 0=accelerate, 1=brake, 2=left, 3=right, 4=boost
segmentRepeatCounter:
	ds.b	2
collisionDistanceTemp:
	ds.b	3
segmentSteeringFlags:
	ds.b	2
accumulatedOffTrackForceX:
	ds.b	1
accumulatedOffTrackForceY:
	ds.b	1
accumulatedOffTrackForceZ:
	ds.b	3
offTrackAccumulationFlag:
	ds.b	1
lbB00D455:
	ds.b	1
offTrackFrameCounter:
	ds.b	1
cameraAngleIndex:
	ds.b	1
segmentDepthCounter:
	ds.b	1
trackSegmentLimitDoubled:
	ds.b	1
maxSegmentIndexDoubled:
	ds.b	1
raceMode:
	ds.b	1
lbB00D45C:
	ds.b	1
trackDirectionMultiplier:
	ds.b	1
displayRowOffset:
	ds.b	1
displayTrackID:
	ds.b	1
renderingLoopIndex:
	ds.b	1
segmentPropertyFlags:
	ds.b	1
boostActiveFlag:
	ds.b	1
gameExitFlag:
	ds.b	1
playerInputState:
	ds.b	1
networkSyncBitFlag:
	ds.b	1
segmentRenderingFlag:
	ds.b	1
lbB00D467:
	ds.b	1
lbB00D468:
	ds.b	1
flameAnimationFrame:
	ds.b	1
trackModeParameter:
	ds.b	1
networkPlayerStateCache:
	ds.b	1
wreckCountdownTimer:
	ds.b	1
textHorizontalOffset:
	ds.b	1
textYOffset:
	ds.b	1
currentTrackIDs:
	ds.b	1
raceActiveFlag:
	ds.b	1
graphicsUpdateFlag:
	ds.b	1
frameProcessingFlag:
	ds.b	1
gameTimerCountdown:
	ds.b	1
crashRecoveryTimer:
	ds.b	1
raceCompletionCheckFlag:
	ds.b	1
networkConnectionState:
	ds.b	1
lineDrawingModeFlag:
	ds.b	2
geometryFormatFlag:
	ds.b	1			; determines packed vs extended format
segmentProcessingIndex:
	ds.b	1
segmentOrientationPrimary:
	ds.b	1
previousSegmentIndex:
	ds.b	1
offTrackCollisionFlag:
	ds.b	1
playerStateFlag:
	ds.b	1
lbB00D47F:
	ds.b	6
currentSegmentIndex:
	ds.b	1
trackGeometryTypeIndex:
	ds.b	2
wreckBlinkFlag:
	ds.b	1
lbB00D489:
	ds.b	2
currentTrackCoordinate:
	ds.b	1
displayModeFlag2:
	ds.b	1
maxMenuIndex:
	ds.b	1
lbB00D48E:
	ds.b	1
segmentConfigLoadedFlag:
	ds.b	1
renderModeFlag:
	ds.b	1
trackOffsetBase:
	ds.b	1
lbB00D492:
	ds.b	1
gridSweepDirection:
	ds.b	1
lbB00D494:
	ds.b	1
lbB00D495:
	ds.b	2
trackSegmentLimit:
	ds.b	1
maxSegmentIndex:
	ds.b	1
maxLapsForRace:
	ds.b	1
lbB00D49A:
	ds.b	1
lbB00D49B:
	ds.b	1
collisionStateFlags:
	ds.b	1
lbB00D49D:
	ds.b	1
lbB00D49E:
	ds.b	1
lbB00D49F:
	ds.b	2
lbB00D4A1:
	ds.b	2
lbB00D4A3:
	ds.b	1
networkTimeoutFlag:
	ds.b	1
lbB00D4A5:
	ds.b	1
lbB00D4A6:
	ds.b	1
currentDataIndex:
	ds.b	1
accelerationStateFlag:
	ds.b	1
framesSinceCopperlistUpdate:
	ds.b	1
lbB00D4AA:
	ds.b	1
lbB00D4AB:
	ds.b	1
frameCounter:
	ds.b	1
lbB00D4AD:
	ds.b	1
lbB00D4AE:
	ds.b	1
gameEndModeFlag:
	ds.b	1
trackVariationSeed:
	ds.b	1
displayFlags:
	ds.b	1
raceResultFlag:
	ds.b	2
raceOutcomeFlags:
	ds.b	1
lbB00D4B5:
	ds.b	1
performanceStylePoints:
	ds.b	2
carCrashedFlag:
	ds.b	1
gameInitFlag3:
	ds.b	1
curveSmoothingFlag:
	ds.b	1
trackSideIndicatorCopy:
	ds.b	1
singleBufferRenderMode:
	ds.b	1
aiDirectionFlag:
	ds.b	1
aiBehaviorFlag1:
	ds.b	1
aiBehaviorFlag2:
	ds.b	1
aiActionTimer:
	ds.b	1
rollTransitionFlag:
	ds.b	1
aiPatternOffset:
	ds.b	1
engineSoundType:
	ds.b	1
raceStartComplete:
	ds.b	1
segmentDataStartIndex:
	ds.b	1
steeringInputDirection:
	ds.b	1			; 0=no steering, -15=left,15=right
engineTimer:
	ds.b	1
displayStateFlag:
	ds.b	1
gameTimingCounter:
	ds.b	1
menuHighlightMode:
	ds.b	1
multiplayerRaceDisplayFlag:
	ds.b	1
eventTimerCountdown:
	ds.b	1
trackDirectionFlag:
	ds.b	2
directionCalculation:
	ds.b	1
lbB00D4D0:
	ds.b	1
offRoadSideFlags:
	ds.b	1
lbB00D4D2:
	ds.b	1
textTransparencyMode:
	ds.b	1
segmentBaseSteeringOffset:
	ds.b	1
currentPlayerNameOffset:
	ds.b	1
selectedMenuItem:
	ds.b	1
collisionImpactLevel:
	ds.b	2
segmentOrientationAlternate:
	ds.b	1
wheelBouncePhaseAccumulator:
	ds.b	1
wheelRotationFrame:
	ds.b	1
segmentAlternateFlag:
	ds.b	1
wheelBaseHeight:
	ds.b	1
displayModeFlag1:
	ds.b	1
raceStartTimer:
	ds.b	1
multiplayerSyncFlag:
	ds.b	1
trackSideIndicator:
	ds.b	1
gameModeStateFlags:
	ds.b	1
wheelAnimationAccumulator:
	ds.b	1
savedPlayerIndex:
	ds.b	1
lbB00D4E5:
	ds.b	1
coordinateTransformFlags:
	ds.b	2
lbB00D4E8:
	ds.b	1
chainLiftVelocity:
	ds.b	1
chainVerticalPosition:
	ds.b	1
engineEffectFlag:
	ds.b	1
networkEngineFlag:
	ds.b	1
previousDataIndex:
	ds.b	1
lbW00D4EE:
	ds.w	1
lbB00D4EF:	EQU	*-1
lbW00D4F0:
	ds.w	1
lbB00D4F1:	EQU	*-1
trackHeightDifference:
	ds.b	2
enginePitchDelta:
	ds.w	1
enginePitchDeltaLow:	EQU	*-1
lateralVelocity:
	ds.w	1
trackBoostThreshold:	EQU	*-1
raceSetupFlags:  EQU    *-1
lbW00D4F8:
	ds.w	1
trackBoostThresholdCopy:	EQU	*-1
lbW00D4FA:
	ds.w	3
carStartRotation:
	ds.b	1
carStartRotationLow:
	ds.b	1
interpolationPointsXY1:
	ds.w	1
interpolationPointsXY2:
	ds.w	1
interpolationPointsXY3:
	ds.w	1
interpolationPointsXY4:
	ds.w	1
additionalInterpolationPoints1:
	ds.w	1
additionalInterpolationPoints2:
	ds.w	1
segmentBezierOffset1:
	ds.w	1
segmentBezierOffset2:
	ds.w	1
storedDepth:
	ds.w	1
processedSegmentIndices1:
	ds.b	2
processedSegmentIndices2:
	ds.b	2
trackEffectParameter:
	ds.w	2
lbW00D51C:
	ds.w	1
lbW00D51E:
	ds.w	1
previousEffectParameter:
	ds.w	1
lbW00D522:
	ds.w	1
lbB00D524:
	ds.b	2
visibilityAccumulator:
	ds.w	1
lbW00D528:
	ds.w	1
segmentProgressDistance:
	ds.w	1
trackDataComponent:	EQU	*-1
	ds.b	2
lbW00D52E:
	ds.w	1
cameraRotationFlags:
	ds.b	2
reverseDirectionFlag:
	ds.b	2
enginePitchAccumulator:
	ds.w	1
lbW00D536:
	ds.w	1
carRenderDistance:
	ds.w	1
engineState:	EQU	*-1
maxDistanceFromTrack:
	ds.w	1
steeringScaleFactor:
	ds.w	1
lbW00D53E:
	ds.w	1
lbB00D540:
	ds.b	1
trackProcessingFlag:
	ds.b	1
lbW00D542:
	ds.w	1
trackDirectionInversionFlag:
	ds.b	6
segmentSlopeFlags:
	ds.b	2
adjustedDistanceValue:
	ds.w	1
previousIndexBackup:	EQU	*-1
	ds.b	6
lbB00D554:
	ds.b	1
previousSegmentProperties:
	ds.b	1
visualEffectFlags:
	ds.w	1
lbB00D558:
	ds.b	1
maxRenderingIndex:
	ds.b	1
lbB00D55A:
	ds.b	1
trackBaseOffset:
	ds.b	1
offsetFromRoadCenter:
	ds.w	1
lateralRoadPosition:
	ds.w	1
speedMinor:	EQU	*-1
trackSurfaceHeight:
	ds.w	1
wheelSpeed:
	ds.b	2
viewOffsetX:
	ds.w	1
viewStepX:
	ds.w	1
viewOffsetY:
	ds.w	1
viewStepY:
	ds.w	1
quadRectHalfWidth:
	ds.w	1
quadRectWidth:
	ds.w	1
quadRectHalfHeight:
	ds.w	1
quadRectHeight:
	ds.w	1
stepSizeXHalf:
	ds.w	1
stepSizeYHalf:
	ds.w	1
lbW00D578:
	ds.w	1
lbW00D57A:
	ds.w	1
stepSizeXQuarter:
	ds.w	1
stepSizeYQuarter:
	ds.w	1
lbW00D580:
	ds.w	1
lbW00D582:
	ds.w	1
quadTranslateX:
	ds.w	1
quadTranslateY:
	ds.w	1
adjustedViewX:
	ds.w	1
adjustedViewY:
	ds.w	1
primaryGeometryOffset:
	ds.w	2
alternateGeometryOffset:
	ds.w	2
trackCenterX:
	ds.l	1
trackCenterY:
	ds.l	1
trackCenterZ:
	ds.l	1
trackOffsetAdjustment:
	ds.b	2
postWreckStateFlag:
	ds.b	2
carWorldX:
	ds.l	1
carWorldY:
	ds.l	1
carWorldZ:
	ds.l	1
distanceFromTrackX:
	ds.l	1
distanceFromTrackY:
	ds.l	1
distanceFromTrackZ:
	ds.l	1
geometryDatabaseOffset:
	ds.w	2
rawTrackDataOffset:
	ds.w	4
lbB00D5C8:
	ds.b	4
lbL00D5CC:
	ds.l	1
carHeightPosition:
	ds.b	4
lbL00D5D4:
	ds.l	1
lbB00D5D8:
	ds.b	2
lbW00D5DA:
	ds.w	1
lbB00D5DC:
	ds.b	1
lbB00D5DD:
	ds.b	1
lbW00D5DE:
	ds.w	1
lbB00D5E0:
	ds.b	2
lbW00D5E2:
	ds.w	1
cameraAngleX:
	ds.w	1
cameraAngleY:
	ds.b	1
lbB00D5E7:
	ds.b	1
cameraAngleZ:
	ds.w	1
worldXSpeed:
	ds.w	1
worldYSpeed:
	ds.w	1
worldZSpeed:
	ds.w	1
rotationSpeedX:
	ds.w	1
rotationSpeedY:
	ds.w	1
rotationSpeedZ:
	ds.w	1
lbW00D5F6:
	ds.w	1
lbW00D5F8:
	ds.w	1
lbW00D5FA:
	ds.w	1
lbW00D5FC:
	ds.w	1
yawRotationRate:
	ds.w	1
lbW00D600:
	ds.w	1
wheelCornerXFrontLeft:
	ds.w	1
wheelCornerXFrontRight:
	ds.w	1
wheelCornerXRearCenter:
	ds.w	1
wheelCornerYFrontLeft:
	ds.w	1
wheelCornerYFrontRight:
	ds.w	1
wheelCornerYRearCenter:
	ds.w	1
baseTargetRoll:
	ds.w	1
baseRollAngle:
	ds.w	1
additionalYawOffset:
	ds.w	1
clampedDistanceX:
	ds.w	1
clampedDistanceY:
	ds.w	1
clampedDistanceZ:
	ds.w	1
previousDistanceX:
	ds.w	1
previousDistanceY:
	ds.w	1
previousDistanceZ:
	ds.w	1
lateralVelocityX:
	ds.w	1
lateralVelocityY:
	ds.w	1
lateralVelocityZ:
	ds.w	1
verticalMotion:
	ds.w	1
lateralMotion:
	ds.w	1
gasOutputAccumulatorValue:
	ds.b	1
gasOutputIntensityValue:
	ds.b	1
targetRollAngle:
	ds.w	1
lbW00D62E:
	ds.w	1
carVelocity:
	ds.b	2
adjustedRollAngle:
	ds.w	1
adjustedPitchAngle:
	ds.w	1
adjustedYawAngle:
	ds.w	1
collisionStateFlags1:
	ds.w	1
collisionStateFlags2:	EQU	*-1
lbW00D63A:
	ds.w	1
lbW00D63C:
	ds.w	1
lbW00D63E:
	ds.w	1
rollAngleModifier:
	ds.w	1
carPitchAdjustment:
	ds.w	1
yawAngleOffset:
	ds.w	1
lbW00D646:
	ds.w	1
lbW00D648:
	ds.w	1
lbW00D64A:
	ds.w	1
lbW00D64C:
	ds.w	1
lbB00D64E:
	ds.b	2
lbB00D650:
	ds.b	2
lbB00D652:
	ds.b	2
velocityAdjustment:
	ds.w	1
lbW00D656:
	ds.w	1
speedDifferential:
	ds.w	1
segmentTargetAngle:
	ds.w	1
impactSeverity:
	ds.b	2
lbL00D65E:
	ds.l	1
lbW00D660:	EQU	*-2
lbW00D662:
	ds.w	2
lbL00D666:
	ds.l	1
lbW00D668:	EQU	*-2
lbW00D66A:
	ds.w	2
lbW00D66E:
	ds.w	1
lbW00D670:
	ds.w	1
lbW00D672:
	ds.w	2
lbW00D676:
	ds.w	1
lbW00D678:
	ds.w	1
lbW00D67A:
	ds.w	2
lbW00D67E:
	ds.w	1
lbW00D680:
	ds.w	1
lbW00D682:
	ds.w	2
boundsMinX:
	ds.w	1
boundsMaxX:
	ds.w	1
boundsMinY:
	ds.w	2
trackCoordinatesX:
	ds.l	8
trackCoordinatesY:
	ds.l	8
	ds.w	1	;dc.w	$0024
segmentProcessedFlags:
	ds.l	39
lbL00D76C:
	ds.l	1
trackSegmentData:
	ds.l	61
inputCoordX1:
	ds.w	1
inputCoordY1:
	ds.w	1
inputCoordX2:
	ds.w	1
inputCoordY2:
	ds.w	15
clampedCoordX1:
	ds.w	1
clampedCoordY1:
	ds.w	1
clampedCoordX2:
	ds.w	1
clampedCoordY2:
	ds.w	17
coordinateLookupTable:
	ds.l	1
lbW00D8B4:
	ds.w	1
lbW00D8B6:
	ds.w	117
transformedCoordinates1:
	ds.w	1
transformedCoordinates2:
	ds.w	7
quadVertexX4:
	ds.w	1
quadVertexX5:
	ds.w	1
quadVertexX6:
	ds.w	1
quadVertexX7:
	ds.w	1
lbW00D9B8:
	ds.w	1
lbW00D9BA:
	ds.w	1
lbW00D9BC:
	ds.w	1
lbW00D9BE:
	ds.w	1
quadVertexX0:
	ds.w	1
quadVertexX1:
	ds.w	1
quadVertexX2:
	ds.w	1
quadVertexX3:
	ds.w	1
lbW00D9C8:
	ds.w	1
lbW00D9CA:
	ds.w	1
lbW00D9CC:
	ds.w	1
lbW00D9CE:
	ds.w	17
transformedVertexBounds:
	ds.l	1
lbW00D9F4:
	ds.w	1
lbW00D9F6:
	ds.w	125
quadVertexY4:
	ds.w	1
quadVertexY5:
	ds.w	1
quadVertexY6:
	ds.w	1
quadVertexY7:
	ds.w	1
lbW00DAF8:
	ds.w	1
lbW00DAFA:
	ds.w	1
lbW00DAFC:
	ds.w	1
lbW00DAFE:
	ds.w	1
quadVertexY0:
	ds.w	1
quadVertexY1:
	ds.w	1
quadVertexY2:
	ds.w	1
quadVertexY3:
	ds.w	1
lbW00DB08:
	ds.w	1
lbW00DB0A:
	ds.w	1
lbW00DB0C:
	ds.w	1
lbW00DB0E:
	ds.w	17
lbL00DB30:
	ds.l	13
transformMatrix34:
	ds.w	2
transformMatrix38:
	ds.w	3
transformMatrix3E:
	ds.w	2
transformMatrix44:
	ds.w	1
transformMatrix46:
	ds.w	1
transformMatrix48:
	ds.w	5
trackSegmentGrid:
	ds.b	16*16
debrisParticleXPositions:
	ds.w	32
debrisParticleYPositions:
	ds.w	32
debrisParticleXVelocities:
	ds.w	32
debrisParticleYVelocities:
	ds.w	32
segmentGeometryIndices:
	ds.b	100
segmentAlternateGeometryIndices:
	ds.b	100
trackSegmentCoordinates:	; lookup table mapping track segment indices to their 2D grid coordinates, with each coordinate packed into a single byte
	ds.b	100
trackSegmentPropertiesTable:
	ds.b	100
segmentInterpolationPoint1:
	ds.l	7
lbL00DF6C:
	ds.l	18
	ds.w	1
graphicsOffsetX:
	ds.w	1
graphicsOffsetY:
	ds.w	48
segmentInterpolationPoint2:
	ds.l	50
segmentWorldPositions:
	ds.l	50
obstacleSegmentIndices:
	ds.l	5
	ds.l	3
obstacleTypes:
	ds.l	5
	ds.l	3
trackFeatureData:
	ds.l	5
	ds.l	3
playerStatsArray:
	ds.b	1
lbB00E209:
	ds.b	13
lbB00E216:
	ds.b	1
lbB00E217:
	ds.b	9
lapTimeSeconds:
	ds.b	1
lbB00E221:
	ds.b	13
lbB00E22E:
	ds.b	1
lbB00E22F:
	ds.b	9
lapTimeSubseconds:
	ds.b	1
lbB00E239:
	ds.b	13
lbB00E246:
	ds.b	1
lbB00E247:
	ds.b	11
segmentVisibilityData:
	ds.l	12
paletteUpdateArray:
	ds.w	1
	ds.b	1
lbB00E285:
	ds.b	1
lbB00E286:
	ds.b	48
lbL00E2B6:
	ds.l	3
lbL00E2C2:
	ds.l	3
selectedTrack:
	ds.b	1
objectDisplayThreshold:
	ds.b	1
currentPlayerContext:
	ds.b	2
lbL00E2D2:
	ds.l	3
lbL00E2DE:
	ds.l	3
lbL00E2EA:
	ds.l	3
lbL00E2F6:
	ds.l	3
lbL00E302:
	ds.l	3
lbB00E30E:
	ds.b	11
trackDataBuffer:
	ds.b	1		; unused
numTrackSegments:
	ds.b	1
lbB00E31B:
	ds.b	1
trackParameter3:
	ds.b	1
finishLineSegmentIndex:
	ds.b	1
startWorldPosition:
	ds.w	1
lbB00E320:
	ds.b	1
raceConfigValue:
	ds.b	1
selectedRaceType:
	ds.b	1
raceFlag1:
	ds.b	1
raceFlag2:
	ds.b	1
lbB00E325:
	ds.b	1
lbB00E326:
	ds.b	1
player1ID:
	ds.b	1
player2ID:
	ds.b	1
opponentID:
	ds.b	1
trackMetadataBuffer:
	ds.b	1
lbB00E32B:
	ds.b	1
lbB00E32C:
	ds.b	1
lbB00E32D:
	ds.b	1
obstacleCount:
	ds.b	1
trackFeatureCount:
	ds.b	2
networkSyncStateFlag:
	ds.b	1
startingSegmentIndex:
	ds.b	1
currentTrackID:
	ds.b	1
lbB00E334:
	ds.b	1
currentRaceNumber:
	ds.b	1
lbL00E336:
	ds.l	3
ciaTimerFlag:
	ds.b	2
lbW049538:
	ds.w	1
networkPacketReadyFlag:
	ds.b	2
networkGameMode:
	ds.b	2
checksumAccumulator:
	ds.w	1
networkDataCounter1:
	ds.w	1
savedNetworkCounter:
	ds.w	1
networkDataCounter2:
	ds.w	1
lbW049546:
	ds.w	1
lbW049548:
	ds.w	1
lbW04954A:
	ds.w	1
lbW04954C:
	ds.w	1
lbW04954E:
	ds.w	1
lbB049550:
	ds.b	1
lbB049551:
	ds.b	1
lbB049552:
	ds.b	1
lbB049553:
	ds.b	1
lbB049554:
	ds.b	1
lbB049555:
	ds.b	1
lbB049556:
	ds.b	1
lbB049557:
	ds.b	1
lbB049558:
	ds.b	1
lbB049559:
	ds.b	1
lbB04955A:
	ds.b	1
gameInitFlag1:
	ds.b	1
receivedGameStateID:
	ds.b	1
receivedGameInitFlag:
	ds.b	1
receivedPlayerCommand:
	ds.b	1
receivedPlayerState:
	ds.b	1
receivedInputState:
	ds.b	1
lbB049561:
	ds.b	1
gameStateID:
	ds.b	1
gameInitFlag2:
	ds.b	1
networkProtocolState:
	ds.b	1
localPlayerStateCache:
	ds.b	1
localInputStateCache:
	ds.b	1
raceSeriesCounter:
	ds.b	1
localPlayerReadyFlag:
	ds.b	1
opponentVisibilityFlag:
	ds.b	1
lbB04956A:
	ds.b	1
lbB04956B:
	ds.b	1
lbB04956C:
	ds.b	1
lbB04956D:
	ds.b	1
lbB04956E:
	ds.b	1
receivedKey:
	ds.b	1
lbW049570:
	ds.w	1
totalRaceCounter:
	ds.w	1
lbW049574:
	ds.w	1
lbW049576:
	ds.w	1
lbB0499D6:
	ds.b	1
lbB0499D7:
	ds.b	1
lbL04A4AE:
	ds.l	3
lbB04A4BA:
	ds.b	1
lbB04A4BB:
	ds.b	1
lbB04A4C8:
	ds.b	2
bitplaneMask1:
	ds.l	1
bitplaneMask2:
	ds.l	1
bitplaneMaskPointer:
	ds.l	1
lbB04AA3E:
	ds.b	2
useAlternateFontFlag:
	ds.b	1
lbB04AB4B:
	ds.b	1
playerNameRenderingPosition:
	ds.l	1
foregroundColorMask1:
	ds.l	1
foregroundColorMask2:
	ds.l	1
backgroundColorMask1:
	ds.l	1
backgroundColorMask2:
	ds.l	1
textCursorColumn:
	ds.b	1
textCursorRow:
	ds.b	1
characterByteOffset:
	ds.b	1
characterPixelOffset:
	ds.b	1
savedTransparencyFlag:
	ds.b	1
textControlCodeState:
	ds.b	1
controlCodeByteCounter:
	ds.b	2
engineAudioNoiseFlag:
	ds.b	2
maxInputLength:
	ds.b	1
inputCancelFlag:
	ds.b	1
currentInputPosition:
	ds.b	2
displayUpdateFlag:
	ds.b	2
buttonReleaseMask:
	ds.b	2
bufferSelector:
	ds.b	2
lbB050474:
	ds.b	1
textRenderingFlag:
	ds.b	1
additionalPlayerCount:
	ds.b	1
remainingRaces:
	ds.b	1
standingsDisplayModeFlag:
	ds.b	1
raceSeriesProgress:
	ds.b	1
selectedTrackGroup:
	ds.b	1
raceConfiguredFlag:
	ds.b	1
lbB0513DC:
	ds.b	1
lbB0513DD:
	ds.b	1
menuInitializedFlag:
	ds.b	2
framesToWait:
	ds.b	1
framesToWaitForJotain:
	ds.b	1
framesToWaitWhenFading:
	ds.b	2
crashSoundCooldownTimer:
	ds.b	2
randomSeed1:
	ds.w	1
randomSeed2:
	ds.b	1
lbB053EA5:
	ds.b	1
randomSeed3:
	ds.b	2
currentSaveSlotIndex:
	ds.b	1
disableDirectionalInputFlag:
	ds.b	1
selectedSaveSlotIndex:
	ds.b	1
lbB0544B7:
	ds.b	1
lbB0544BA:
	ds.b	1
saveSlotHighlightFlag:
	ds.b	1
lbB0544BC:
	ds.b	2
lbB054608:
	ds.b	2
lbB0555E0:
	ds.b	1
lbB0555E1:
	ds.b	1
offTrackFrameThreshold:
	ds.b	2
minBoundaryDistance:
	ds.w	1
lbB0557E0:
	ds.b	2
suppressMenuTextFlag:
	ds.b	2
trackPreviewParameters:
	ds.b	80
transformedGridX:
	ds.b	2
transformedGridY:
	ds.b	2
lbB0579FA:
	ds.b	2
lbW0579FC:
	ds.w	1
lbW0579FE:
	ds.w	1
previewSegmentFlags:
	ds.w	1
previewDataWritePointer:
	ds.l	1
lbB0581A0:
	ds.b	2
lbW0581A2:
	ds.w	1
lbW0581A4:
	ds.w	1
lbW0581A6:
	ds.w	1
lineDrawingBufferPointer:
	ds.l	1
renderDataPointer:
	ds.w	1
savedXCoordinate:
	ds.w	1
edgeDirectionFlag:
	ds.b	1
clipRequiredFlag:
	ds.b	1
clipIterationCounter:
	ds.b	1
renderingFlag:
	ds.b	1
lbW05AC2C:
	ds.w	1
mountainHorizontalAngles:
	ds.l	12
mountainShapeIndices:
	ds.l	12
lbB05B096:
	ds.b	1
lbB05B097:
	ds.b	1
lbB05B098:
	ds.b	1
mountainSegmentCount:
	ds.b	1
mountainScreenX:
	ds.w	1
mountainScreenY:
	ds.w	1
scanlineCounter:
	ds.b	2
lbW05B3CC:
	ds.w	1
lbW05B3CE:
	ds.w	1
currentEdgePointer1:
	ds.l	1
currentEdgePointer2:
	ds.l	1
segmentAlternateRenderFlag:
	ds.b	2
segmentProcessedFlag:
	ds.b	2
edgeClipFailedFlag:
	ds.b	2
lbB05B3DE:
	ds.b	4
lbB05B3E2:
	ds.b	4
depthValue:
	ds.w	1
lbW05B3E8:
	ds.w	1
lbB05B3EA:
	ds.b	2
lbB05B3EC:
	ds.b	4
lbL05B3F0:
	ds.l	1
lbL05B3F4:
	ds.l	1
lbL05B3F8:
	ds.l	1
	ds.l	2			; Fixed
	ds.l	32
edgeSortBuffer:
	ds.l	32
renderDataBuffer:
	ds.l	64
loadingHardwareSprite:
	ds.b	1
spriteUpdatePendingFlag:
	ds.b	1
lbW05BA66:
	ds.w	1
renderGraphicsCurrentX:
	ds.w	1
renderGraphicsCurrentY:
	ds.w	1
graphicsDataTable:
	ds.l	54
frameBuffers:
	ds.l	1
displayFrameBuffer:
	ds.l	1
renderFrameBuffer:
	ds.l	1
viewportTopAddress:
	ds.l	1

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
cachebits_old:	ds.l	1
dmaconr_old:	ds.w	1
intenar_old:	ds.w	1
ciaacra_old:	ds.b	1
ciaacrb_old:	ds.b	1
ciabcra_old:	ds.b	1
ciabcrb_old:	ds.b	1
quit:			ds.b	1

	section	ChipBSS,bss_c
memory_00000:	ds.b	$10000
memory_70000:	ds.b	$10000
frameBuffer1:   ds.b    40*200*4
frameBuffer2:   ds.b    40*200*4

memory_0400	equ	(memory_00000+$0400)
memory_3D80	equ	(memory_00000+$3D80)
memory_60A8	equ	(memory_00000+$60A8)
memory_6490	equ	(memory_00000+$6490)
memory_79360	equ	(memory_70000+$9360)
memory_7A01A	equ	(memory_70000+$A01A)
memory_7A035	equ	(memory_70000+$A035)
memory_7A03A	equ	(memory_70000+$A03A)
memory_7A03F	equ	(memory_70000+$A03F)
memory_7A21A	equ	(memory_70000+$A21A)
memory_7A224	equ	(memory_70000+$A224)
memory_7A225	equ	(memory_70000+$A225)
memory_7A234	equ	(memory_70000+$A234)
memory_7A416	equ	(memory_70000+$A416)
networkTransferBuffer	equ	(memory_70000+$A41A)
memory_7A43A	equ	(memory_70000+$A43A)
memory_7A4BA	equ	(memory_70000+$A4BA)
memory_7A4F6	equ	(memory_70000+$A4F6)
memory_7A4FA	equ	(memory_70000+$A4FA)
memory_7A51A	equ	(memory_70000+$A51A)
memory_7A61A	equ	(memory_70000+$A61A)
memory_7A71A	equ	(memory_70000+$A71A)
memory_7A81A	equ	(memory_70000+$A81A)
memory_7A91A	equ	(memory_70000+$A91A)
memory_7A9FA	equ	(memory_70000+$A9FA)
previewSegmentPointers	equ	(memory_70000+$AA1A)
memory_7AAE6	equ	(memory_70000+$AAE6)
memory_7AB5A	equ	(memory_70000+$AB5A)
previewDataBuffer	equ	(memory_70000+$ABDA)
renderCommandQueue	equ	(memory_70000+$B08A)
memory_7B6FA	equ	(memory_70000+$B6FA)

dsksync:	EQU	$0000007E
CIAF_PRTRBUSY:	EQU	$00000001
copjmp1:	EQU	$00000088
ciasdr:	EQU	$00000C00
DMAF_BLTNZERO:	EQU	$00002000
adkcon:	EQU	$0000009E
serdat:	EQU	$00000030
tv_UserIntVects:	EQU	$00000100
DMAF_MASTER:	EQU	$00000200
INTF_EXTER:	EQU	$00002000
CIACRBF_RUNMODE:	EQU	$00000008
_custom:	EQU	$00DFF000
CIACRAF_RUNMODE:	EQU	$00000008
ddfstop:	EQU	$00000094
bplcon2:	EQU	$00000104
diwstrt:	EQU	$0000008E
ac_per:	EQU	$00000006
intreq:	EQU	$0000009C
bplcon0:	EQU	$00000100
bplcon1:	EQU	$00000102
INTF_AUD1:	EQU	$00000100
INTB_AUD0:	EQU	$00000007
INTF_AUD0:	EQU	$00000080
INTF_AUD3:	EQU	$00000400
INTF_BLIT:	EQU	$00000040
INTF_AUD2:	EQU	$00000200
INTF_SOFTINT:	EQU	$00000004
INTF_DSKBLK:	EQU	$00000002
INTB_DSKBLK:	EQU	$00000001
aud0:	EQU	$000000A0
diwstop:	EQU	$00000090
INTF_RBF:	EQU	$00000800
CIAICRF_SETCLR:	EQU	$00000080
ddfstrt:	EQU	$00000092
CIAF_COMCTS:	EQU	$00000010
dmaconr:	EQU	$00000002
DMAF_BLITHOG:	EQU	$00000400
CIAF_COMCD:	EQU	$00000020
CIAICRF_ALRM:	EQU	$00000004
INTF_TBE:	EQU	$00000001
ciapra:	EQU	$00000000
ciaprb:	EQU	$00000100
CIAF_COMDTR:	EQU	$00000080
CIAICRF_FLG:	EQU	$00000010
CIAF_COMDSR:	EQU	$00000008
DMAF_COPPER:	EQU	$00000080
CIAF_DSKSEL0:	EQU	$00000008
intena:	EQU	$0000009A
INTB_SETCLR:	EQU	$0000000F
INTF_PORTS:	EQU	$00000008
INTF_SETCLR:	EQU	$00008000
bltafwm:	EQU	$00000044
intreqr:	EQU	$0000001E
tv_Lev7IntVect:	EQU	$0000007C
tv_Lev6IntVect:	EQU	$00000078
tv_Lev5IntVect:	EQU	$00000074
tv_Lev4IntVect:	EQU	$00000070
CIAICRF_SP:	EQU	$00000008
tv_Lev3IntVect:	EQU	$0000006C
tv_Lev2IntVect:	EQU	$00000068
tv_Lev1IntVect:	EQU	$00000064
joy1dat:	EQU	$0000000C
bltbmod:	EQU	$00000062
bpl2mod:	EQU	$0000010A
serper:	EQU	$00000032
ciaddra:	EQU	$00000200
CIAICRF_TB:	EQU	$00000002
CIAF_PRTRSEL:	EQU	$00000004
bltamod:	EQU	$00000064
bpl1mod:	EQU	$00000108
CIAICRF_TA:	EQU	$00000001
INTB_COPER:	EQU	$00000004
DMAF_BLITTER:	EQU	$00000040
INTF_COPER:	EQU	$00000010
INTF_DSKSYNC:	EQU	$00001000
DMAB_BLITTER:	EQU	$00000006
INTF_VERTB:	EQU	$00000020
ciaicr:	EQU	$00000D00
INTB_VERTB:	EQU	$00000005
dskpt:	EQU	$00000020
DMAF_SETCLR:	EQU	$00008000
DMAF_DISK:	EQU	$00000010
cop1lc:	EQU	$00000080
DMAF_BLTDONE:	EQU	$00004000
DMAF_AUD0:	EQU	$00000001
_ciaa:	EQU	$00BFE001
DMAF_AUD1:	EQU	$00000002
DMAF_AUD2:	EQU	$00000004
DMAF_AUD3:	EQU	$00000008
serdatr:	EQU	$00000018
_ciab:	EQU	$00BFD000
dmacon:	EQU	$00000096
DMAF_AUDIO:	EQU	$0000000F
bltcdat:	EQU	$00000070
ciatbhi:	EQU	$00000700
DMAF_RASTER:	EQU	$00000100
INTB_TBE:	EQU	$00000000
CIAICRB_TB:	EQU	$00000001
ac_len:	EQU	$00000004
dsklen:	EQU	$00000024
ciacra:	EQU	$00000E00
ciacrb:	EQU	$00000F00
CIAF_PRTRPOUT:	EQU	$00000002
ciatblo:	EQU	$00000600
bltdmod:	EQU	$00000066
INTF_INTEN:	EQU	$00004000
bpl1pth = $0e0
bpl1ptl = $0e2
bpl2pth = $0e4
bpl2ptl = $0e6
bpl3pth = $0e8
bpl3ptl = $0ea
bpl4pth = $0ec
bpl4ptl = $0ee
color00  = $180
color01  = $182
color02  = $184
color03  = $186
color04  = $188
color05  = $18a
color06  = $18c
color07  = $18e
color08  = $190
color09  = $192
color10 = $194
color11 = $196
color12 = $198
color13 = $19a
color14 = $19c
color15 = $19e
color16 = $1a0
color17 = $1a2
color18 = $1a4
color19 = $1a6
color20 = $1a8
color21 = $1aa
color22 = $1ac
color23 = $1ae
color24 = $1b0
color25 = $1b2
color26 = $1b4
color27 = $1b6
color28 = $1b8
color29 = $1ba
color30 = $1bc
color31 = $1be
cop1lch = $080
intenar = $01c 
spr0pth = $120
spr0ptl = $122
spr1pth = $124
spr1ptl = $126
spr2pth = $128
spr2ptl = $12a
spr3pth = $12c
spr3ptl = $12e
spr4pth = $130
spr4ptl = $132
spr5pth = $134
spr5ptl = $136
spr6pth = $138
spr6ptl = $13a
spr7pth = $13c
spr7ptl = $13e
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
DMAF_ALL		equ	$01FF
TIMESTEP_FACTOR		equ	$30 ; fixed $EE
