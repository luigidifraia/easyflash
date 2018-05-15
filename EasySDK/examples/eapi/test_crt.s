
; EasyFlashSDK sample code for embedding the EasyAPI in a CRT
; see README.md for details

* = $0000

EASYFLASH_CONTROL = $DE02
EASYFLASH_LED     = $80
EASYFLASH_16K     = $07
EASYFLASH_KILL    = $04

; Entry points for EasyAPI (EAPI)
EAPIBase            = $7800         ; <= Use any page-aligned address here
EAPIInit            = EAPIBase + $14
EAPIWriteFlash      = $df80 + 0
EAPIEraseSector     = $df80 + 3
EAPISetBank         = $df80 + 6
EAPIGetBank         = $df80 + 9

EAPI_ZP_REAL_CODE_BASE = $4b        ; 2 bytes

; =============================================================================
; 00:0:0000 (LOROM, bank 0)
bankStart_00_0:
    ; This code resides on LOROM, it becomes visible at $8000
    ; The EAPI becomes visible at $B800..$BBFF as this code runs in 16K mode

    !pseudopc $8000 {

        ; === the main application entry point ===

        ; copy the EAPI code to EAPIBase - we don't run it here
        ; since the banking would make it invisible

        ldx #0
-       lda $b800, x
        sta EAPIBase, x
        lda $b900, x
        sta EAPIBase + $0100, x
        lda $ba00, x
        sta EAPIBase + $0200, x
        dex
        bne -

        ; copy the main code to $C000 - we don't run it here
        ; since the banking would make it invisible

        ldx #0
-       lda main,x
        sta $c000,x
        dex
        bne -

        jmp testCheckEasyFlash

main:
        !pseudopc $C000 {

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

everythingOK
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
        }

        ; fill the whole bank with value $ff
        !align $ffff, $a000, $ff
    }

; =============================================================================
; 00:1:0000 (HIROM, bank 0)
bankStart_00_1:
    ; This code runs in Ultimax mode after reset, so this memory becomes
    ; visible at $E000..$FFFF first and must contain a reset vector
    !pseudopc $e000 {
coldStart:
        ; === the reset vector points here ===
        sei
        ldx #$ff
        txs
        cld

        ; enable VIC (e.g. RAM refresh)
        lda #8
        sta $d016

        ; write to RAM to make sure it starts up correctly (=> RAM datasheets)
startWait:
        sta $0100, x
        dex
        bne startWait

        ; copy the final start-up code to RAM (bottom of CPU stack)
        ldx #(startUpEnd - startUpCode)
l1:
        lda startUpCode, x
        sta $0100, x
        dex
        bpl l1
        jmp $0100

startUpCode:
        !pseudopc $0100 {
            ; === this code is copied to the stack area, does some inits ===
            ; === scans the keyboard and kills the cartridge or          ===
            ; === starts the main application                            ===
            lda #EASYFLASH_16K + EASYFLASH_LED
            sta EASYFLASH_CONTROL

            ; Check if one of the magic kill keys is pressed
            ; This should be done in the same way on any EasyFlash cartridge!

            ; Prepare the CIA to scan the keyboard
            lda #$7f
            sta $dc00   ; pull down row 7 (DPA)

            ldx #$ff
            stx $dc02   ; DDRA $ff = output (X is still $ff from copy loop)
            inx
            stx $dc03   ; DDRB $00 = input

            ; Read the keys pressed on this row
            lda $dc01   ; read coloumns (DPB)

            ; Restore CIA registers to the state after (hard) reset
            stx $dc02   ; DDRA input again
            stx $dc00   ; Now row pulled down

            ; Check if one of the magic kill keys was pressed
            and #$e0    ; only leave "Run/Stop", "Q" and "C="
            cmp #$e0
            bne kill    ; branch if one of these keys is pressed

            ; same init stuff the kernel calls after reset
            ldx #0
            stx $d016
            jsr $ff84   ; Initialise I/O

            ; These may not be needed - depending on what you'll do
            jsr $ff87   ; Initialise System Constants
            jsr $ff8a   ; Restore Kernal Vectors
            jsr $ff81   ; Initialize screen editor

            ; start the application code
            jmp $8000

kill:
            lda #EASYFLASH_KILL
            sta EASYFLASH_CONTROL
            jmp ($fffc) ; reset
        }
startUpEnd:

        ; fill it up to $e000 + $1800 to put the EAPI there
        !align $ffff, $e000 + $1800, $ff

        ; Insert EAPI binary from file offset 2
        !binary "../../eapi/out/eapi-am29f040-14", $0300, 2

	; Insert a default name for the menu entry
        !convtab "asc2ulpet.ct"
        !text "EF-Name:EasyAPI-Example"
        !align $ffff, $e000 + $1b18, $00

        ; fill it up to $FFFA to put the vectors there
        !align $ffff, $fffa, $ff

        !word reti        ; NMI
        !word coldStart   ; RESET

        ; we don't need the IRQ vector and can put RTI here to save space :)
reti:
        rti
        !byte 0xff
    }

; =============================================================================
; 01:0:0000 (LOROM, bank 1)
bankStart_01_0:
        ; fill the whole bank with value 1 = 'A'
        !fill $2000, 1

; =============================================================================
; 01:1:0000 (HIROM, bank 1)
bankStart_01_1:
        ; fill the whole bank with value 2 = 'B'
        !fill $2000, 2

; =============================================================================
; 02:0:0000 (LOROM, bank 2)
bankStart_02_0:
        ; fill the whole bank with value 3 = 'C'
        !fill $2000, 3

; =============================================================================
; 02:1:0000 (HIROM, bank 2)
bankStart_02_1:
        ; fill the whole bank with value 4 = 'D'
        !fill $2000, 4
