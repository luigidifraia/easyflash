; This example is an updated version of the one found at the following BitBucket location:
; https://bitbucket.org/skoe/easyflash/src/ee80f932cfacd12397cd831d82e727c074ba39ef/EasySDK/eapi/test.s

* = $0801 - 2
        !word $0801

        !word bNext     ; Address of next BASIC instruction
        !word 2018      ; Line number
        !byte $9e       ; SYS-token
        !text "2061"    ; 2061 in ASCII
        !byte 0         ; Line terminator
bNext:
        !word 0         ; Line number = 0, end of program

; Entry points for EasyAPI (EAPI)
EAPIBase            = $7800         ; <= Use any page-aligned address here
EAPIInit            = EAPIBase + $14
EAPIWriteFlash      = $df80 + 0
EAPIEraseSector     = $df80 + 3
EAPISetBank         = $df80 + 6
EAPIGetBank         = $df80 + 9

EAPI_ZP_REAL_CODE_BASE = $4b        ; 2 bytes

; =============================================================================
;
; Load File
;
; =============================================================================

        lda #fileNameEnd - fileName
        ldx #<fileName
        ldy #>fileName
        jsr $ffbd       ; SETNAM

        lda #1          ; file number
        ldx $ba         ; get prev. dev number
        bne driveSet    ; none?
        ldx #8          ; fall back to dev 8
driveSet:
        ldy #0          ; load, use new address
        jsr $ffba       ; SETLFS

        lda #0
        ldx #<EAPIBase
        ldy #>EAPIBase
        jsr $ffd5       ; LOAD
        bcs loadError

        jmp testCheckEasyFlash

loadError:
        sta $0400
        lda #2
        sta $d020
        jmp *

; =============================================================================

        !convtab pet

fileName:
        !text "eapi-????????-??"
fileNameEnd:


; =============================================================================
;
; Check if the driver supports this EasyFlash (if any)
;
; =============================================================================

testCheckEasyFlash:
        ; this pointer is used by EAPI to find out where it is
        lda #<EAPIBase
        sta EAPI_ZP_REAL_CODE_BASE
        lda #>EAPIBase
        sta EAPI_ZP_REAL_CODE_BASE + 1

        jsr EAPIInit
        bcs cefNotCompatible

        ; Show Manufacturer ID
        stx $0400
        ; and number of physical banks or slots
        sty $0401

        jmp testRead


cefNotCompatible:
        lda #1
        sta $d020
        jmp *

; =============================================================================
;
; Read from those banks that were filled with sample data when provisioned
;
; =============================================================================

testRead:
        ; Switch to bank 1, get a byte from LOROM and HIROM
        lda #1
        jsr EAPISetBank
        lda $8000
        ldx $a000
        ; and put them to the screen, we should see "A" and "B" there
        sta $0400 + 2
        stx $0400 + 3

        ; Switch to bank 2, get a byte from LOROM and HIROM
        lda #2
        jsr EAPISetBank
        lda $8000
        ldx $a000
        ; and put them to the screen, we should see "C" and "D" there
        sta $0400 + 4
        stx $0400 + 5

        jmp testErase

; =============================================================================
;
; Erase all sectors but the first, one by one
;
; =============================================================================

eraseError:
        lda #7
        sta $d020
        jmp *


testErase:
        lda #8          ; Starting from 2nd sector
teNext:
        ; set 1st bank of 64k sector
        jsr EAPISetBank

        ldy #$80        ; point to $8000, 1st byte of LOROM bank
        jsr EAPIEraseSector
        bcs eraseError

        ldy #$e0        ; point to $e000, 1st byte of HIROM bank (Ultimax)
        jsr EAPIEraseSector
        bcs eraseError

        ; 8k * 8 = 64k => Step 8
        ;clc
        adc #8
        cmp #64         ; we have bank 8..63 => stop at 64
        bne teNext

        ; put first byte of each bank onto screen
        ldx #0
teCheckEmpty:
        txa
        jsr EAPISetBank
        lda $8000
        sta $0400 + 40,x
        lda $a000           ; not in Ultimax => HIROM is at $a000
        sta $0400 + 120,x
        inx
        cpx #64
        bne teCheckEmpty

; =============================================================================
;
; Write the bank number to the first byte of each bank, starting from bank 8
;
; =============================================================================

testWrite:
        lda #8          ; bank in a
twNext:
        jsr EAPISetBank

        ; bank is in a = value to write
        ldx #0
        ldy #$80        ; point to $8000, 1st byte of LOROM bank
        jsr EAPIWriteFlash
        bcs writeError

        ldy #$e0        ; point to $e000, 1st byte of HIROM bank (Ultimax)
        jsr EAPIWriteFlash
        bcs writeError

        ;clc
        adc #1
        cmp #64         ; we have bank 8..63 => stop at 64
        bne twNext

        ; put first byte of each bank onto screen
        ldx #0
twCheck:
        txa
        jsr EAPISetBank
        lda $8000
        sta $0400 + 200,x
        lda $a000
        sta $0400 + 280,x
        inx
        cpx #64
        bne twCheck

; =============================================================================
;
; Check if there is an error if we write illegal data
;
; =============================================================================

testWriteError:
        lda #8          ; bank in a
        jsr EAPISetBank

        ; there's a 8 at $8000 now, we'll try to write 255
        lda #$ff
        ldx #0
        ldy #$80
        jsr EAPIWriteFlash
        ; 10d7
        bcc writeErrorMissing

everythingOK:
        dec $d020
        jmp everythingOK


writeError:
        lda #8
        sta $d020
        jmp *

writeErrorMissing:
        lda #9
        sta $d020
        jmp *
