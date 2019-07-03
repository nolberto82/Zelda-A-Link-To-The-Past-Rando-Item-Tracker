
;;;;;;;;;;;;;;;;;;;;;;;;;
; created by nolberto82 ;
;;;;;;;;;;;;;;;;;;;;;;;;;

header
lorom

;light world = 96 items
;dark world  = 121 items
	
;Overworld Map Zoomed Out
org $0ABCFD
		db $00
	
;Overworld Map Crystals Numbers Disable
org $0AC554
		dw $F0A9
		
;erase item totals from 3rd slo sram		
org $0CD4D3		
		autoclean jsl erasedata

freecode
erasedata:
		sta $700000,x
		sta $700a00,x
		sta $700b00,x
		sta $700c00,x
		sta $700d00,x
		sta $700000,x
		rtl	

;Increase Indoors Item Obtained
org $A0B85E
		autoclean jsl itemincrease
	
freecode
itemincrease:					;Save item obtained based on entrance to 3rd slot save Ram
		phx
		phy
		php
		sta $7ef423	
		lda $1b
		beq +					;If not in dungeon skip
		rep #$30		
		lda $a0
		tax
		sep #$20
		lda $700a00,x
		inc
		sta $700a00,x
+		plp
		ply
		plx
		sep #$30
		rtl		

;Item Counter
org $008602
		autoclean jsl itemtotal

freecode
itemtotal:
		php
		pha
		phy
		phx
		sep #$30
		ldx #$00
		lda $7ef423
		jsr hextodec
		ora #$2490
		sta	$7ec7d4
		tya
		jsr hextodec
		ora #$2490
		sta	$7ec7d2
		tya
		jsr hextodec
		ora #$2490
		sta	$7ec7d0	
		sep #$30	
		plx
		ply
		pla
		plp
		lda $a23,x
		asl
		rtl		

hextodec:
		sep #$30
		ldy #$00
-		cmp #$0a
		bcc +
		sbc #$0a
		iny
		bra -
+		rep #$30
		and #$00ff
		rts

;change sprites to 8x8 size for digits		
org $008670
		autoclean jsl spritesize8x8
	
freecode
spritesize8x8:	
		pha
		sep #$30
		lda $11
		cmp #$07
		bne +
		lda $710
		cmp #$01
		bne +		;if not in map skip
		ldx #$1b
-		lda #$00
		sta $a04,x
		dex
		bpl -
+		rep #$30
		pla
		sta $ad0
		clc	
		rtl

		
;Need this  to prevent crash in ice palace asar being stupid with this game
org $A0F63C
		db $ff
		
;Map Chest Counter
org $A18006
		jsl main	

org $A1E000
main:
		php
		pha
		phy
		phx
		lda $11
		cmp #$07
		bne ++
		lda $710
		beq ++
		lda $636
		beq +
++		jmp ret
+		rep #$20
		ldx #$00
		ldy #$00
-		lda	$00,x
		pha
		inx #2
		cpx #$14
		bne -
		stz $00
		stz $02
		stz $04	
		stz $06
		stz $08
		stz $0c
		stz $12
		phb							
		phk							
		plb							;push and pull bank
		jsr copy_sprite0
		jsr check_if_in_lw
		jsr draw_item_numbers_rooms
		jsr draw_item_numbers_ow
		plb							;restore bank
		sep #$10
		ldx #$12
-		pla
		sta $00,x
		dex #2
		bpl -
ret:	sep #$30		
		plx
		ply
		pla
		plp
		lda $7ef443
		rtl
		
draw_item_numbers_rooms:
		rep #$30
		ldx #$0000
		stz $0a
		stz $0e
		lda $06
		asl	
		tax
		lda pointers_room,x		;load room item pointers based if light or dark world 
		sta $0c
.loop	lda ($0c)
		beq +
		tax		
		jsr handle_same_room
		sep #$20
		lda $08
		cpx #$011b
		beq ++
		cpx #$0106
		beq ++		
		lda $700a00,x				;load item number obtained from sram		
++		clc
		adc $00		
		sta $00	
		rep #$30		
		inc $0c
		inc $0c
		bra .loop
+		inc $0c
		inc $0c
-		lda ($0c)
		jsr set_sprite_pos
		inc $0c
		inc $0c
-		lda ($0c)
		beq +
		clc
		adc $0a
		sta $0a
		inc $0c
		inc $0c
		bra -
+		sep #$20
		lda $0a
		sec
		sbc $00
		cmp #$0a
		bmi +
		phy
		jsr hextodec2
		sta $02
		sty $03
		ply	
		jsr draw_double_digits
		bra ++
+		tax
		sep #$20
		jsr draw_single_digit_or_erase
++		rep #$30
		ldx $0a
		iny #4
		inc $0c
		inc $0c
		lda ($0c)
		cmp #$ffff					
		beq +							;if equal exit function
		stz $00
		stz $08
		stz $0a
		jmp .loop		
+		rts

draw_item_numbers_ow:
		ldx #$0000
		lda $06
		asl
		tax
		lda areaoffsetspointers,x
		sta $0e
		lda pointers_ow_01,x
		sta $0c
.loop		lda ($0c)
		cmp #$ffff
		beq .next
		jsr set_sprite_pos
		lda #$0000			
		sep #$20	
		jsr handle_items_ow_01	
		sta $08	
		lda #$01							;overworld items always equal one
		sec
		sbc $08	
		phx
		sep #$30
		tax		
		jsr draw_single_digit_or_erase
		rep #$30
		plx
		iny #4
		rep #$20
		inc $0c
		inc $0c
		bra .loop
.next	ldx #$0000
		stz $04
		lda $06
		asl
		tax
		lda pointers_ow_02,x
		sta $0c
		lda pointers_special,x
		sta $0e
.loop2	lda ($0c)
		cmp #$ffff
		beq .last
		jsr set_sprite_pos
		lda #$0000	
		sep #$20
		jsr handle_items_ow_02	
		sta $08	
		lda #$01								;overworld items always equal one
		sec
		sbc $08
		sep #$30
		tax		
		jsr draw_single_digit_or_erase
		iny #4
		rep #$30
		inc $0c
		inc $0c
		bra .loop2
.last		lda $06
		bne +
		stz $04
		lda pointers_ow_03
		sta $0c
-		stz $08
		lda ($0c)
		cmp #$ffff
		beq +
		jsr set_sprite_pos
		sep #$20
		jsr special_items
		lda #$01							;overworld items always equal one
		sec
		sbc $08
		sep #$30
		tax		
		jsr draw_single_digit_or_erase
		rep #$30
		inc $0c
		inc $0c	
		iny #4
		bra -		
+		rts
	
handle_items_ow_01:
		phx
		lda ($0e)
		tax
		cpx #$00a4
		bne +
		sta $04
		inc $0e
		lda ($0e)
		rep #$20
		clc 
		adc $04
		tax
		sep #$20
		lda $7ef280,x
		and #$10
		lsr #4
		bra ++
+		lda $7ef280,x
		and #$40
		lsr #6
++		plx
		inx
		inc $0e
		rts
		
handle_items_ow_02:
		phx
		phy
		lda $05
		tay
		lda ($0e),y
		bne +
		inc $04
		inc $05
		lda $05
		tay		
+		lda $04
		tax
		lda $7ef410,x
		and ($0e),y
		beq +
		lda #$01
		bra ++
+		lda #$00
++		ply
		plx
		inx 
		inc $05
		rts
		
set_sprite_pos:
		clc
		adc #$0402
		xba
		sta $0840,y
		rts
		
draw_single_digit_or_erase:
		lda.l digits,x
		cmp #$83
		beq +
		sta $0842,y	
		lda #$28
		sta $0843,y			
		bra ++
+		sep #$20
		lda #$f0
		sta $0841,y
++		rts
		
draw_double_digits:
		tax
		lda.l digits,x
		sta $0842+4,y
		lda #$28
		sta $0843,y	
		lda $0840,y					;load xpos prev sprite
		clc 
		adc #$06
		sta $0840+4,y	
		lda $0841,y					;load ypos prev sprite
		sta $0841+4,y
		lda $0843,y
		sta $0843+4,y
		lda $03
		tax
		lda.l digits,x
		sta $0842,y	
		iny #4
		rts

special_items:
		sep #$20
		lda $04
		beq .bit00
		bne .bit01
		bra .no
.yes		inc $08
.no		rts	
.bit00	sep #$20
		inc $04
		lda $7ef3c9
		and #$01
		bne .yes
		bra .no
.bit01	sep #$20
		lda $7ef3c9
		and #$02
		bne .yes
		bra .no	

divideby16:
		lsr #4
		rts

handle_same_room:
		phy
		ldy #$0000
		phx
		asl		
		tax
		lda $7ef000,x
		jsr divideby16
		plx
		sep #$20		
		cpx #$011b				
		beq .room1
		cpx #$0106				
		beq .room2										
		bra .end
.room1	ldy $0e
		bne .room1a
		inc $0e
		and #$20
		bne ++
		bra .end
.room1a	stz $0e
		and #$40
		bne ++
		bra .end
.room2	ldy $0e
		bne .room2a
		inc $0e
		and #$40
		bne ++
		bra .end
.room2a	stz $0e
		and #$01
		beq .end
++		inc $08	
.end		ply
		rts

check_if_in_lw:
		sep #$20
		inc $06		
		lda $aa4
		cmp #$01
		bne +
		stz $06
+		rts
		
copy_sprite0:
		ldx #$00
		lda #$4830
		sta $2116							;set vram address to  $9060
		sep #$20
-		lda.l spritenumber0graphic+0,x		;copy sprite0 graphics data
		sta $2118
		lda.l spritenumber0graphic+1,x
		sta $2119
		inx #2
		cpx #$20
		bne -
		rts		
		
hextodec2:
		sep #$20
		ldy #$0000
-		cmp #$0a
		bcc +
		sbc #$0a
		iny
		bra -
+		rts			

pointers_room:
		dw item_rooms_data_lw
		dw item_rooms_data_dw
	
pointers_ow_01:
		dw item_ow_data_01_lw
		dw item_ow_data_01_dw
		
pointers_ow_02:
		dw item_ow_data_02_lw
		dw item_ow_data_02_dw
		
pointers_ow_03:
		dw item_ow_data_03_lw
		
pointers_special:
		dw specialbits_lw
		dw specialbits_dw
		
areaoffsetspointers:
		dw areaoffsets_lw
		dw areaoffsets_dw
		
;item data is 
;1st line = roomid,0=skip
;2nd line =  main entrance xy pos
;3rd line = item number

item_rooms_data_lw:
		;link's house - entrance 01
		dw $0104,$0000
		dw $817a		
		dw $0001,$0000
		
		;sanctuary - entrance 02
		dw $0012,$0000
		dw $763a		
		dw $0001,$0000	

		;rooms hyrule castle - entrance 04
		dw $0072,$0071,$0080,$0032,$0011,$0000
		dw $7c50		
		dw $0001,$0001,$0001,$0001,$0003,$0000

		;rooms eastern palace - entrance 08
		dw $00b9,$00aa,$00a8,$00a9,$00b8,$00c8,$0000
		dw $d84d		
		dw $0001,$0001,$0001,$0001,$0001,$0001,$0000
		
		;rooms desert palace - entrance 09
		dw $0085,$0075,$0074,$0073,$0033,$0000
		dw $1a90		
		dw $0001,$0001,$0001,$0002,$0001,$0000

		;cave with bat thing - entrance 11
		dw $00e3,$0000
		dw $5262		
		dw $0001,$0000

		;cave of lumberjacks - entrance 12
		dw $00e2,$0000
		dw $5419		
		dw $0001,$0000
		
		;cave death mountain 1 - entrance 1c
		dw $00fe,$0000
		dw $af22		
		dw $0001,$0000
		
		;cave death mountain 2 - entrance 1e
		dw $00ff,$0000
		dw $b921		
		dw $0002,$0000
		
		;cave death mountain 3 - entrance 1f
		dw $00ef,$0000
		dw $bc2a		
		dw $0005,$0000
		
		;cave death mountain 4 - entrance 23
		dw $00ea,$0000
		dw $761b		
		dw $0001,$0000
		
		;rooms hyrule castle agahnim - entrance 24
		dw $00e0,$00d0,$0000
		dw $7849		
		dw $0001,$0001,$0000
		
		;cave lost woods - entrance 25
		dw $00e1,$0000
		dw $3f1f		
		dw $0001,$0000		
		
		;secret entrance hyrule castle - entrance 32
		dw $0055,$0000
		dw $8c4c		
		dw $0002,$0000	
		
		;rooms tower of hera - entrance 33
		dw $0077,$0087,$0027,$0007,$0000
		dw $8212		
		dw $0001,$0002,$0002,$0001,$0000

		;cave kakariko village - entrance 39
		dw $002f,$0000
		dw $1d4c		
		dw $0005,$0000

		;treasure game lost woods - entrance 3c
		dw $0100,$0000
		dw $400f		
		dw $0001,$0000

		;tavern kakariko village - entrance 42
		dw $0103,$0000
		dw $316c		
		dw $0001,$0000
		
		;sahasrahla's hideout - entrance 45
		dw $0105,$0000
		dw $b650		
		dw $0004,$0000	
		
		;sweeping woman kakariko village - entrance 4b
		dw $0108,$0000
		dw $255f		
		dw $0001,$0000
		
		;cave aginah desert - entrance 4d
		dw $010a,$0000
		dw $3597		
		dw $0001,$0000
		
		;swamp ruins - entrance 4e
		dw $010b,$0000
		dw $71ae		
		dw $0001,$0000
		
		;cave death mountain 5 - entrance 4f
		dw $010c,$0000
		dw $b619		
		dw $0001,$0000

		;cave south of flute guy(same room after this) - entrance 51
		dw $011b,$0000
		dw $8433		
		dw $0001,$0000
		
		;cave graveyard(same room as previous one) - entrance 52
		dw $011b,$0000
		dw $4497		
		dw $0001,$0000
		
		;cave of ice - entrance 56
		dw $0120,$0000
		dw $ce8a		
		dw $0001,$0000
		
		;cave waterfall - entrance 5c
		dw $0114,$0000
		dw $c220		
		dw $0002,$0000
		
		;blinds' house kakariko village - entrance 61
		dw $011d,$0000
		dw $2e49		
		dw $0005,$0000
		
		;treasure game south of kakariko village - entrance 67
		dw $0118,$0000
		dw $3b7d		
		dw $0001,$0000
		
		;cave west of lake hylia - entrance 6c
		dw $0123,$0000
		dw $9aae		
		dw $0005,$0000
		
		;cave west of sanctuary - entrance 6e
		dw $0124,$0000
		dw $6336		
		dw $0001,$0000

		;cave east of desert palace - entrance 72
		dw $0126,$0000
		dw $318d		
		dw $0001,$0000

		;king's tomb - entrance 72
		dw $0113,$0000
		dw $8b38		
		dw $0001,$0000
		
		;end of data
		dw $ffff	

item_ow_data_01_lw:
		;hill near tower death mountain - area 03
		dw $7819			
		
		;floating island death mountain - area 05
		dw $af10
		
		;race game kakariko village - area 28
		dw $127f		
			
		;grove hidden treasure - area 2a
		dw $4b75		
		
		;desert ledge - area 30
		dw $0ba8
		
		;lake hylia island - area 35
		dw $a995		
		
		;lake swamp - area 3b
		dw $6ead	

		;master sword pedestal - area 80
		dw $2514

		;zora ledge - area 81
		dw $cc1f

		;end of data
		dw $ffff	
		
item_ow_data_02_lw:	
		;old man death mountain - area 03
		dw $6f2d
		
		;zora king - area 81
		dw $d01f		
		
		;sick boy - area 18
		dw $315f	
		
		;sahasrahla's hideout - area 1e
		dw $b654	

		;library - area 29
		dw $2f74
		
		;tablet death mountain - area 03
		dw $6a10
		
		;tablet desert - area 30
		dw $37ab

		;mushroom spot - area 00
		dw $341f

		;witch's hut - area 16
		dw $b23c
		
		;magic bat - area 
		dw $5261

		;end of data
		dw $ffff

item_ow_data_03_lw:
		;guy under the bridge - area 80
		dw $a47b
		
		;bottle guy kakariko village - area 18
		dw $2752
					
		;end of data
		dw $ffff
			
;item data is 
;1st line = roomid,0=skip
;2nd line =  main entrance xy pos
;3rd line = item number	
	
item_rooms_data_dw:
		;dw death mountain cave 1 - entrance 13
		dw $00f8,$0000
		dw $b721		
		dw $0002,$0000	
		
		;swamp palace - entrance 25
		dw $0028,$0037,$0036,$0046,$0034,$0035,$0076,$0066,$0006,$0000
		dw $71ae		
		dw $0001,$0001,$0001,$0001,$0001,$0001,$0002,$0001,$0001,$0000

		;dark palace - entrance 26
		dw $0009,$003a,$000a,$002a,$002b,$001a,$0019,$006a,$005a,$0000
		dw $d245		
		dw $0001,$0001,$0001,$0002,$0001,$0003,$0002,$0002,$0001,$0000

		;misery mire - entrance 27
		dw $00c2,$00c3,$00b3,$00a2,$00c1,$00d1,$0090,$0000
		dw $1993		
		dw $0001,$0002,$0001,$0001,$0001,$0001,$0001,$0000
		
		;skull woods - entrance 28
		dw $0058,$0068,$0067,$0057,$0059,$0029,$0000
		dw $2626		
		dw $0002,$0001,$0001,$0002,$0001,$0001,$0000
		
		;ice palace - entrance 2d
		dw $002e,$001f,$005f,$007e,$009e,$00ae,$003f,$00de,$0000
		dw $ba9f		
		dw $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001,$0000
		
		;thieves' town - entrance 34
		dw $00db,$00dc,$00cb,$0065,$0044,$0045,$00ac,$0000
		dw $2c56		
		dw $0002,$0001,$0001,$0001,$0001,$0001,$0001,$0000
		
		;turtle rock - entrance 35
		dw $00d6,$00b7,$00b6,$0014,$0024,$0004,$00d5,$00a4,$0000
		dw $c817		
		dw $0001,$0002,$0001,$0001,$0001,$0001,$0004,$0001,$0000
		
		;ganon's tower - entrance 37
		dw $008c,$007b,$008b,$007d,$001c,$009d,$007c,$003d,$004d,$008d,$0000
		dw $8210		
		dw $0005,$0004,$0001,$0001,$0003,$0004,$0004,$0003,$0001,$0001,$0000
		
		;dw death mountain cave 2 - entrance 3a
		dw $003c,$0000
		dw $b413		
		dw $0004,$0000
		
		;cave northeast of swamp palace - entrance 3d
		dw $011e,$0000
		dw $8c8e		
		dw $0005,$0000
		
		;dw death mountain cave 3 - entrance 41
		dw $0117,$0000
		dw $8522		
		dw $0001,$0000
		
		;dw treasure game village of outcasts - entrance 47
		dw $0106,$0000
		dw $1d52		
		dw $0001,$0000
		
		;hut village of outcasts - entrance 48
		dw $0106,$0000
		dw $2668		
		dw $0001,$0000
		
		;c shaped house village of outcasts - entrance 54
		dw $011c,$0000
		dw $3d55		
		dw $0001,$0000
		
		;cave left of misery mire - entrance 5f
		dw $010d,$0000
		dw $0f93		
		dw $0002,$0000
		
		;cave of pegs - entrance 83
		dw $0127,$000
		dw $526c	
		dw $0001,$0000
		
		;pyramid fairy
		dw $0116,$000
		dw $7256	
		dw $0002,$0000
		
		;end of data
		dw $ffff

item_ow_data_01_dw:
		;bumper cave ledge - area 4a
		dw $5b22	

		;pyramid ledge - area 5b
		dw $874f

		;digging game - area 68
		dw $187c
		
		;purple chest - area 62
		dw $505b		
		
		;end of data
		dw $ffff		

item_ow_data_02_dw:
		;stumpy - area
		dw $4f7a

		;catfish - area
		dw $c423		

		;end of data
		dw $ffff

specialbits_lw:
		db $01,$02,$04,$10,$80,$00,$01,$02,$10,$20,$80
		
specialbits_dw:
		db $08,$20		
		
areaoffsets_lw:
		db $03,$05,$28,$2a,$30,$35,$3b,$80,$81
	
areaoffsets_dw:	
		db $4a,$5b,$68,$a4,$a5		
	
digits:
		db $83,$7f,$79,$6c,$6d
		db $6e,$6f,$7c,$7d,$7e
		
spritenumber0graphic:
		db $3c,$00,$7e,$00,$ff,$00,$ff,$00,$ff,$00,$ff,$00,$7e,$00,$3c,$00
		db $c3,$3c,$bd,$7e,$66,$ff,$66,$ff,$66,$ff,$66,$ff,$bd,$7e,$c3,$3c
