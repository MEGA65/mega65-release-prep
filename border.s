.setcpu "4510"

.macro copy32 src, dest
  ldy #$03
:
  lda src,y
  sta dest,y
  dey
  bpl :- 
.endmacro

.macro ld32 loc, valhi, vallo
  lda #((vallo) & $ff)
  sta loc
  lda #((vallo) >> 8)
  sta loc+1
  lda #((valhi) & $ff)
  sta loc+2
  lda #((valhi) >> 8)
  sta loc+3
.endmacro

.macro lda32z loc
  nop
  lda (loc),z
.endmacro

.macro sta32z loc
  nop
  sta (loc),z
.endmacro

.macro adw loc, val
  clc
  lda loc
  adc #val
  sta loc
  lda loc+1
  adc #00
  sta loc+1
.endmacro

.macro subw loc, val
  sec
  lda loc
  sbc #val
  sta loc
  lda loc+1
  sbc #00
  sta loc+1
.endmacro

ptr = $43
bkp = $fd0
.code
.org $2000

  sei
  ; lda #$00
  ; ldx #$f3
  ; ldy #$00
  ; ldz #$e4
  ; map
  ; nop
  ; cli

  ; backup ptr
  copy32 ptr, bkp

; *** TOP LINE ***
  ; prep scr ptr
  ld32 ptr, $0ff8, $0800
  
  ; get current clr at left of line
  ldz #$00
  lda32z ptr
  sta lastcol

  ldz #79
  lda32z ptr  ; get current (into y)
  tay
  dez
:
  lda32z ptr  ; get next (into x)
  tax
  tya
  sta32z ptr  ; put current into next
  txa
  tay
  dez
  bpl :-

; *** LEFT LINE ***
  lda #24
  sta cnt

  ; prep scr ptr
  ld32 ptr, $0ff8, $0800 + (24*80)

  ; get current clr at bottom-left of line
  ldz #$00
  lda32z ptr
  sta tmp

  lda lastcol
  tay

  ld32 ptr, $0ff8, $0800 + 80 ; top-left of line
:
  lda32z ptr  ; get next (into x)
  tax

  tya
  sta32z ptr  ; put current into next
  txa
  tay

  adw ptr, 80

  dec cnt
  lda cnt
  bne :-

  lda tmp
  sta lastcol

; *** BOTTOM LINE ***
  lda #$79
  sta cnt

  ; prep scr ptr
  ld32 ptr, $0ff8, $0800 + (24*80)

  ; get last clr
  ldz #79
  lda32z ptr
  sta tmp

  lda lastcol
  tay

  ldz #$00
  inz
:
  lda32z ptr  ; get next (into x)
  tax
  tya
  sta32z ptr  ; put current into next
  txa
  tay
  inz
  cpz #80
  bne :-

  lda tmp
  sta lastcol

; *** RIGHT LINE ***
  ldz #$00
  lda #24
  sta cnt

  lda lastcol
  tay

  ld32 ptr, $0ff8, $0800 + (23*80) + 79
:
  lda32z ptr  ; get next (into x)
  tax

  tya
  sta32z ptr  ; put current into next
  txa
  tay

  subw ptr, 80

  dec cnt
  lda cnt
  bne :-

  ; restore ptr
  copy32 bkp, ptr

  rts

cnt:
  .byte 00
lastcol:
  .byte 00
tmp:
  .byte 00
