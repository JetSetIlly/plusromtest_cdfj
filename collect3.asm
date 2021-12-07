;===============================================================================
; Program Information
;===============================================================================

    ; Program:      Collect 3
    ; Program by:   Darrell Spice, Jr
    ; Last Update:  February 11, 2020
    ;
    ; Super simple game of "collect the objects" used to show how to develop
    ; an Atari 2600 homebrew game using CDFJ.
    ;
    ; More information available here:
    ; https://atariage.com/forums/forum/262-cdfj/
    

    
;===============================================================================
; Build Instructions
;===============================================================================
    
    ; Open a terminal
    ; CD into the directory containing collect3.asm
    ; type the command:
    ;   make
    
    
    
;===============================================================================
; Change Log
;===============================================================================

    ; 2019.12.15 - initial version with stubs for Splash, Menu, and Game screens
    ; 2019.12.19 - source improvements
    ; 2020.01.20 - console detection: 2600/7800 and NTSC/PAL/SECAM
    ; 2020.02.08 - menu
    ; 2020.02.11 - score & timer display
    
    
;===============================================================================
; Initialize dasm
;===============================================================================

        PROCESSOR 6502
        include vcs.h       
        include macro.h
        include cdfj.h
    
        
        
;===============================================================================
; Define constants
;----------------------------------------
;   Define constants used by 6507 code, as well as those used by both
;   6507 code and the C code.
;
;   To make it easier to synchronize values between the 6507 and C code the
;   make process will auto-export anything with a _ prefix to file:
;       main/defines_from_dasm_for_c.h
;
;   it does this by using awk to parse the symbol file created by dasm
;===============================================================================

; which ARM function to run
_FN_INIT        = 0 ; Initialize()
_FN_GAME_OS     = 1 ; GameOverScan()
_FN_GAME_VB     = 2 ; GameVerticalBlank()
_FN_MENU_OS     = 3 ; MenuOverScan()
_FN_MENU_VB     = 4 ; MenuVerticalBlank()
_FN_SPLASH_OS   = 5 ; SplashOverScan()
_FN_SPLASH_VB   = 6 ; SplashVerticalBlank()

; datastream usage for Splash Screen
_DS_SPLASH_P0L  = DS0DATA
_DS_SPLASH_P1L  = DS1DATA
_DS_SPLASH_P0R  = DS2DATA
_DS_SPLASH_P1R  = DS3DATA

; datastream usage for Menu
_DS_MENU_GRAPHICS    = DS0DATA
_DS_MENU_CONTROL     = DS1DATA
_DS_MENU_COLORS      = DS2DATA

; datastream usage for Game Kernel
_DS_GRP0        = DS0DATA
_DS_GRP1        = DS1DATA
_DS_COLUP0      = DS2DATA
_DS_COLUP1      = DS3DATA

; datastream usage for Score Kernel, DO NOT use same DS# as Game Kernel
_DS_SCORE0_COLOR    = DS31DATA
_DS_SCORE0_GFXA     = DS30DATA
_DS_SCORE0_GFXB     = DS29DATA
_DS_TIMER_GFXA      = DS28DATA
_DS_TIMER_GFXB      = DS27DATA
_DS_SCORE1_COLOR    = DS26DATA
_DS_SCORE1_GFXA     = DS25DATA
_DS_SCORE1_GFXB     = DS24DATA

    
; timer values
VB_TIM64T = 47
OS_TIM64T = 33

; color values
_BLACK           = $00
_WHITE           = $0E
_GREY            = $00
_YELLOW          = $10
_ORANGE          = $20
_BROWN           = $30
_RED             = $40
_PURPLE          = $50
_VIOLET          = $60
_INDIGO          = $70
_BLUE            = $80
_BLUE2           = $90
_TURQUOISE       = $A0
_CYAN            = $B0
_GREEN           = $C0
_YELLOW_GREEN    = $D0
_OCHRE_GREEN     = $E0
_OCHRE           = $F0

_HAIR            = $F4
_FACE            = $4C

; controls spacing in main menu
MM_TITLE_GAP        = 20    ; gap after game title
MM_OPTION_GAP       = 8     ; gap between options
MM_START_GAP        = 20    ; gab before START option
MM_LOGO_GAP         = 20    ; gap before company logo
MM_END              = $80
_MM_OPTION_HEIGHT   = 7   

_ARENA_HEIGHT       = 182


;===============================================================================
; Define custom Macros
;----------------------------------------
;   This function appears at the same position in both banks of 6507 code
;===============================================================================
        MAC POSITION_OBJECT
        ; sets X position of any object.  X holds which object, A holds position
PosObject:              ; A holds X value
        sec             ; 2  
        sta WSYNC       ; X holds object, 0=P0, 1=P1, 2=M0, 3=M1, 4=Ball
DivideLoop:
        sbc #15         ; 2  
        bcs DivideLoop  ; 2  4
        eor #7          ; 2  6
        asl             ; 2  8
        asl             ; 2 10
        asl             ; 2 12
        asl             ; 2 14
        sta.wx HMP0,X   ; 5 19
        sta RESP0,X     ; 4 23 <- set object position
SLEEP12: rts            ; 6 29
        ENDM
        
        
        
;===============================================================================
; Define Zero Page RAM Usage
;----------------------------------------
;   ZP RAM variables can only be seen by the 6507 CPU
;   Likewise C variables can only be seen by the ARM CPU
;===============================================================================

        SEG.U VARS
        ORG $80       
        
Mode:           ds 1    ; $00 = splash, $01 = menu, $80 = game    
LoopCounter:    ds 1      
TimeLeftOS:     ds 1
TimeLeftVB:     ds 1

        echo "----",($00FE - *) , "bytes of RAM left (space reserved for 2 byte stack)"
             
        

;===============================================================================
; Define Start of Cartridge
;----------------------------------------
;   CDFJ cartridges must start with the Harmony/Melody driver.  The driver is
;   the ARM code that emulates the CDFJ coprocessor.
;===============================================================================

        SEG CODE    
        ORG $0000
    
HM_DRIVER:        
        INCBIN cdfdriver20190317.bin

        
        
;===============================================================================
; ARM user code
; Banks 0 thru 4
;----------------------------------------
;   The ARM code starts at $0800 and grows into bank 0+
;===============================================================================

        ORG $0800
        
    ; include the custom ARM code.
        INCBIN main/bin/armcode.bin
        
        
        
;===============================================================================
; ARM Indirect Data
;----------------------------------------
;   Data that the C code indirectly accesses can be stored immediately after the
;   custom ARM code.
;===============================================================================

PLAYER_LEFT:
        .byte %00010000 ;  1
        .byte %00010000 ;  2
        .byte %00010000 ;  3
        .byte %00111000 ;  4
        .byte %00111000 ;  5
        .byte %01011000 ;  6
        .byte %01010100 ;  7
        .byte %01010000 ;  8
        .byte %00010000 ;  9
        .byte %00010000 ; 10
        .byte %00010000 ; 11
        .byte %00010000 ; 12
        .byte %00010000 ; 13
        .byte %00010000 ; 14
        .byte %00010000 ; 15
        .byte %00011000 ; 16    
        
PLAYER_RIGHT:        
        .byte %00001000 ;  1
        .byte %00001000 ;  2
        .byte %00001000 ;  3
        .byte %00011100 ;  4
        .byte %00011100 ;  5
        .byte %00011010 ;  6
        .byte %00101010 ;  7
        .byte %00001010 ;  8
        .byte %00001000 ;  9
        .byte %00001000 ; 10
        .byte %00001000 ; 11
        .byte %00001000 ; 12
        .byte %00001000 ; 13
        .byte %00001000 ; 14
        .byte %00001000 ; 15
        .byte %00011000 ; 16      
        
PLAYER_COLOR_LEFT:
        .byte _HAIR	      ;  1 left player
        .byte _FACE	      ;  2
        .byte _FACE	      ;  3
        .byte _BLUE+2	  ;  4
        .byte _WHITE-2    ;  5
        .byte _WHITE-2    ;  6
        .byte _GREY+8	  ;  7
        .byte _GREY+4	  ;  8
        .byte _BLUE+4	  ;  9
        .byte _WHITE-2-2  ; 10
        .byte _WHITE-2-2  ; 11
        .byte _WHITE-2-2  ; 12
        .byte _BLUE	      ; 13
        .byte _BLUE+2	  ; 14
        .byte _BLUE+4	  ; 15
        .byte _BLUE+6	  ; 16        

PLAYER_COLOR_RIGHT:
        .byte _HAIR	      ;  1 right player
        .byte _FACE	      ;  2
        .byte _FACE	      ;  3
        .byte _GREEN+2	  ;  4
        .byte _WHITE-2    ;  5
        .byte _WHITE-2    ;  6
        .byte _GREY+8	  ;  7
        .byte _GREY+4	  ;  8
        .byte _GREEN+4	  ;  9
        .byte _WHITE-2-2  ; 10
        .byte _WHITE-2-2  ; 11
        .byte _WHITE-2-2  ; 12
        .byte _GREEN	  ; 13
        .byte _GREEN+2	  ; 14
        .byte _GREEN+4	  ; 15
        .byte _GREEN+6	  ; 16 

        echo "----",($5C00 - *) , "bytes of ARM and Moveable Data space left"
 
        
        
;===============================================================================
; ARM Direct Data
;----------------------------------------
;   I find it easier, and more space efficient, to store some of the data the
;   C code needs to access in the 6507 code instead of the C code.  Because the
;   build process is:
;       1) assemble 6507 code to create defines_from_dasm_for_c.h
;       2) compile C code to create ARM routines
;       3) assemble 6507 to create final ROM
;   the ARM code could change size between steps 1 and 3, which would shift data 
;   that immediately comes after it. So the data that C directly accesses needs
;   to be after an ORG so it will not move.
;
;   The ImageGraphics and ImageColors data tables are directly access by the C
;   code so must be in the Direct Data area. The data they point to is
;   indirectly accessed by the C code, so they can go in the Indirect Data area.
;   Note the labels for the tables are prefixed by _ so they'll end up in the
;   defines_from_dasm_for_c.h file, while the labels for the data the tables
;   point to are not prefixed by _
;===============================================================================
        ORG $5C00

        align 2 ; word tables accessed by the ARM must be aligned on 2 byte boundaries
_IMAGE_GRAPHICS:
        .word PLAYER_LEFT
        .word PLAYER_RIGHT
        
        align 2 ; word tables accessed by the ARM must be aligned on 2 byte boundaries
_IMAGE_COLORS:
        .word PLAYER_COLOR_LEFT
        .word PLAYER_COLOR_RIGHT
        
        align 2
_MENU_GRAPHICS_OFFSET:        
        .word  _BUF_MENU_GRAPHICS - _MENU_GRAPHICS + MenuGfxCollectLogo
        .word  _BUF_MENU_GRAPHICS - _MENU_GRAPHICS + MenuGfxPlayers
        .word  _BUF_MENU_GRAPHICS - _MENU_GRAPHICS + MenuGfxArena
        .word  _BUF_MENU_GRAPHICS - _MENU_GRAPHICS + MenuGfxCheck1
        .word  _BUF_MENU_GRAPHICS - _MENU_GRAPHICS + MenuGfxCheck2
        .word  _BUF_MENU_GRAPHICS - _MENU_GRAPHICS + MenuGfxTVtype
        .word  _BUF_MENU_GRAPHICS - _MENU_GRAPHICS + MenuGfxStart
        
_IMAGE_HEIGHTS:
        .byte 16
        .byte 16
        

_MENU_GRAPHICS:    
MenuGfxCollectLogo: 
        .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000
        .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
        .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000
        .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
        .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000
        .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
        .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000
        .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
        .byte %10000110,%00011011,%11101111,%10000011,%00001000,%00110001
        .byte %01111101,%11101011,%11101111,%10111110,%11111110,%11101110
        .byte %01111101,%11101011,%11101111,%10111110,%11111110,%11111110
        .byte %01111101,%11101011,%11101111,%10111110,%11111110,%11111110
        .byte %01111101,%11101011,%11101111,%10001110,%11111110,%11111001
        .byte %01111101,%11101011,%11101111,%10111110,%11111110,%11111110
        .byte %01111101,%11101011,%11101111,%10111110,%11111110,%11111110
        .byte %01111101,%11101011,%11101111,%10111110,%11111110,%11101110
        .byte %10000110,%00011000,%00100000,%10000011,%00001110,%11110001
        .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
        .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000
        .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
        .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000
        .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
        .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000
        .byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111
        .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000
_MENU_LOGO_HEIGHT = (* - MenuGfxCollectLogo) / 6  
        
MenuGfxPlayers:        
        .byte %00110111,%10110101,%00010011,%10011111,%11111111,%11111101
        .byte %01010111,%01010101,%01110101,%01111111,%11111111,%11111001
        .byte %01010111,%01010101,%01110101,%01111111,%11111111,%11111101
        .byte %00110111,%00011011,%00110011,%10111111,%11111111,%11111101
        .byte %01110111,%01011011,%01110101,%11011111,%11111111,%11111101
        .byte %01110111,%01011011,%01110101,%11011111,%11111111,%11111101
        .byte %01110001,%01011011,%00010101,%00111111,%11111111,%11111000
        
MenuGfxArena:        
        .byte %10110011,%00010011,%10111111,%11111111,%11111111,%11111101
        .byte %01010101,%01110101,%01011111,%11111111,%11111111,%11111001
        .byte %01010101,%01110101,%01011111,%11111111,%11111111,%11111101
        .byte %00010011,%00110101,%00011111,%11111111,%11111111,%11111101
        .byte %01010101,%01110101,%01011111,%11111111,%11111111,%11111101
        .byte %01010101,%01110101,%01011111,%11111111,%11111111,%11111101
        .byte %01010101,%00010101,%01011111,%11111111,%11111111,%11111000
        
MenuGfxCheck1:        
        .byte %10110011,%00010001,%10110011,%11011111,%11111111,%11111100
        .byte %01010101,%10111011,%01010101,%10011111,%11111111,%11111100
        .byte %01010101,%10111011,%01010101,%11011111,%11111111,%11111001
        .byte %01010011,%10111011,%01010101,%11011111,%11111111,%11111011
        .byte %01010111,%10111011,%01010101,%11011111,%11111111,%10110111
        .byte %01010111,%10111011,%01010101,%11011111,%11111111,%11010111
        .byte %10110111,%10110001,%10110101,%11011111,%11111111,%11101111

MenuGfxCheck2:        
        .byte %10110011,%00010001,%10110011,%00111111,%11111111,%11111100
        .byte %01010101,%10111011,%01010101,%11011111,%11111111,%11111100
        .byte %01010101,%10111011,%01010101,%11011111,%11111111,%11111001
        .byte %01010011,%10111011,%01010101,%10111111,%11111111,%11111011
        .byte %01010111,%10111011,%01010101,%01111111,%11111111,%10110111
        .byte %01010111,%10111011,%01010101,%01111111,%11111111,%11010111
        .byte %10110111,%10110001,%10110101,%00011111,%11111111,%11101111
        
MenuGfxTVtype:
        .byte %00010101,%11000101,%01001100,%01111111,%10011000,%11001101
        .byte %10110101,%11101101,%01010101,%11111111,%10101101,%10111010
        .byte %10110101,%11101101,%01010101,%11111111,%10101101,%10111011
        .byte %10110101,%01101110,%11001100,%11111111,%10101101,%11011011
        .byte %10110101,%11101110,%11011101,%11111111,%10101101,%11101011
        .byte %10110101,%11101110,%11011101,%11111111,%10101101,%11101010
        .byte %10111011,%11101110,%11011100,%01111111,%10101101,%10011101
        
MenuGfxStart:
        .byte %11111111,%11100001,%00000110,%00110000,%11000001,%11111111
        .byte %11111111,%11011111,%11011101,%11010111,%01110111,%11111111
        .byte %11111111,%11011111,%11011101,%11010111,%01110111,%11111111
        .byte %11111111,%11100011,%11011100,%00010000,%11110111,%11111111
        .byte %11111111,%11111101,%11011101,%11010111,%01110111,%11111111
        .byte %11111111,%11111101,%11011101,%11010111,%01110111,%11111111
        .byte %11111111,%11000011,%11011101,%11010111,%01110111,%11111111
        

_SpiceWareLogo:
        .byte %00001111,%11111111,%11111111,%11000001,%11111111,%11111111
        .byte %00010000,%00000000,%00000000,%01000001,%00000000,%00000000
        .byte %00010000,%00011001,%00100111,%01100011,%00100110,%01110000
        .byte %00010000,%00010101,%01010100,%00101010,%01010101,%01000000
        .byte %00001111,%10010101,%01000100,%00101010,%01010101,%01000000
        .byte %00000000,%01011001,%01000110,%00111110,%01110110,%01100000
        .byte %00000000,%01010001,%01000100,%00010100,%01010101,%01000000
        .byte %00000000,%01010001,%01010100,%00010100,%01010101,%01000000
        .byte %11111111,%10010001,%00100111,%00010100,%01010101,%01110000
        
_MENU_GRAPHICS_SIZE = * - _MENU_GRAPHICS
        
        
_MENU_CONTROL:
        .byte %00000000     ; PF0
        .byte %01000000     ; PF1
        .byte %00000000     ; PF2
        .byte 100           ; ball X location
        .byte _MENU_LOGO_HEIGHT ; rows
        .byte MM_TITLE_GAP  ; extra scanlines
        
_MENU_FIRST_OPTION_ID = (* - _MENU_CONTROL) / 6         
_MENU_PLAYERS_ID = (* - _MENU_CONTROL) / 6
        .byte %00000000     ; PF0
        .byte %01000000     ; PF1
        .byte %00000000     ; PF2
        .byte 0             ; ball X location
        .byte _MM_OPTION_HEIGHT             ; rows
        .byte MM_OPTION_GAP ; extra scanlines

_MENU_ARENA_ID = (* - _MENU_CONTROL) / 6
        .byte %00000000     ; PF0
        .byte %01000000     ; PF1
        .byte %00000000     ; PF2
        .byte 0             ; ball X location
        .byte _MM_OPTION_HEIGHT             ; rows
        .byte MM_OPTION_GAP ; extra scanlines
        
_MENU_OPTION1_ID = (* - _MENU_CONTROL) / 6
        .byte %00000000     ; PF0
        .byte %11000000     ; PF1
        .byte %00000000     ; PF2
        .byte 0             ; ball X location
        .byte _MM_OPTION_HEIGHT             ; rows
        .byte MM_OPTION_GAP ; extra scanlines

_MENU_OPTION2_ID = (* - _MENU_CONTROL) / 6
        .byte %00000000     ; PF0
        .byte %11000000     ; PF1
        .byte %00000000     ; PF2
        .byte 0             ; ball X location
        .byte _MM_OPTION_HEIGHT             ; rows
        .byte MM_OPTION_GAP ; extra scanlines
        
_MENU_TV_TYPE_ID = (* - _MENU_CONTROL) / 6
        .byte %11100000     ; PF0
        .byte %11000000     ; PF1
        .byte %00000000     ; PF2
        .byte 0             ; ball X location
        .byte _MM_OPTION_HEIGHT             ; rows
        .byte MM_START_GAP  ; extra scanlines
        
_MENU_START_ID = (* - _MENU_CONTROL) / 6
        .byte %00000000     ; PF0
        .byte %00000000     ; PF1
        .byte %00000000     ; PF2
        .byte 0             ; ball X location
        .byte _MM_OPTION_HEIGHT             ; rows
        .byte MM_END        ; extra scanlines        
        
_MENU_CONTROL_SIZE = * - _MENU_CONTROL
        
        
_MENU_COLORS:
Collect3LogoColor:
        .byte _BLUE + 2, _BLUE + 2    ; 0
        .byte 0, 0                  ; 1
        .byte _BLUE + 4, _BLUE + 4    ; 2
        .byte 0, 0                  ; 3
        .byte _BLUE + 8, _BLUE + 8    ; 4
        .byte 0, 0                  ; 5
        .byte _BLUE + 10, _BLUE + 10  ; 6
        .byte 0, 0                  ; 7
        .byte _RED + 12, _GREEN + 12  ; 8
        .byte _RED + 12, _GREEN + 12  ; 9
        .byte _RED + 12, _GREEN + 12  ; 10
        .byte _RED + 12, _GREEN + 12  ; 11
        .byte _RED + 12, _GREEN + 12  ; 12
        .byte _RED + 12, _GREEN + 12  ; 13
        .byte _RED + 12, _GREEN + 12  ; 14
        .byte _RED + 12, _GREEN + 12  ; 15
        .byte _RED + 12, _GREEN + 12  ; 16
        .byte 0, 0                  ; 17
        .byte _BLUE + 10, _BLUE + 10  ; 18
        .byte 0, 0                  ; 19
        .byte _BLUE + 8, _BLUE + 8    ; 20
        .byte 0, 0                  ; 21
        .byte _BLUE + 4, _BLUE + 4    ; 22
        .byte 0, 0                  ; 23
        .byte _BLUE + 2, _BLUE + 2    ; 24        
        
MenuOptionPlayersColor:
        .byte _GREEN + 8, _BLUE + 8
        .byte _GREEN +10, _BLUE +10
        .byte _GREEN +12, _BLUE +12
        .byte _GREEN +14, _BLUE +14
        .byte _GREEN +12, _BLUE +12
        .byte _GREEN +10, _BLUE +10
        .byte _GREEN + 8, _BLUE + 8
        
MenuOptionArenaColor:
        .byte _GREEN + 8, _BLUE + 8
        .byte _GREEN +10, _BLUE +10
        .byte _GREEN +12, _BLUE +12
        .byte _GREEN +14, _BLUE +14
        .byte _GREEN +12, _BLUE +12
        .byte _GREEN +10, _BLUE +10
        .byte _GREEN + 8, _BLUE + 8
        
MenuOption1Color:
        .byte _GREEN + 8, _BLUE + 8
        .byte _GREEN +10, _BLUE +10
        .byte _GREEN +12, _BLUE +12
        .byte _GREEN +14, _BLUE +14
        .byte _GREEN +12, _BLUE +12
        .byte _GREEN +10, _BLUE +10
        .byte _GREEN + 8, _BLUE + 8
        
MenuOption2Color:
        .byte _GREEN + 8, _BLUE + 8
        .byte _GREEN +10, _BLUE +10
        .byte _GREEN +12, _BLUE +12
        .byte _GREEN +14, _BLUE +14
        .byte _GREEN +12, _BLUE +12
        .byte _GREEN +10, _BLUE +10
        .byte _GREEN + 8, _BLUE + 8
               
MenuOptionTVTypeColor:
        .byte _GREEN + 8, _BLUE + 8
        .byte _GREEN +10, _BLUE +10
        .byte _GREEN +12, _BLUE +12
        .byte _GREEN +14, _BLUE +14
        .byte _GREEN +12, _BLUE +12
        .byte _GREEN +10, _BLUE +10
        .byte _GREEN + 8, _BLUE + 8
        
MenuOptionStartColor:
        .byte _WHITE, _WHITE
        .byte _WHITE, _WHITE
        .byte _WHITE, _WHITE
        .byte _WHITE, _WHITE
        .byte _WHITE, _WHITE
        .byte _WHITE, _WHITE
        .byte _WHITE, _WHITE
        
_MENU_COLORS_SIZE = * - _MENU_COLORS        
        

_OPTION_2:
        .byte %11111001
        .byte %11111110
        .byte %11111110
        .byte %11111101
        .byte %11111011
        .byte %11111011
        .byte %11111000        

_OPTION_3:
        .byte %11111001
        .byte %11111110
        .byte %11111110
        .byte %11111101
        .byte %11111110
        .byte %11111110
        .byte %11111001        
        
_OPTION_4:
        .byte %11111010
        .byte %11111010
        .byte %11111010
        .byte %11111000
        .byte %11111110
        .byte %11111110
        .byte %11111110        
        
_OPTION_UNCHECKED:
        .byte %10111100
        .byte %11011001
        .byte %11100011
        .byte %11100111
        .byte %11011001
        .byte %10111100
        .byte %10111100        
        
_OPTION_RED:        
        .byte _RED + 8, _BLUE + 8
        .byte _RED +10, _BLUE +10
        .byte _RED +12, _BLUE +12
        .byte _RED +14, _BLUE +14
        .byte _RED +12, _BLUE +12
        .byte _RED +10, _BLUE +10
        .byte _RED + 8, _BLUE + 8
        
_OPTION_PAL:
        .byte %11111001,%11011011
        .byte %11111010,%10101011
        .byte %11111010,%10101011
        .byte %11111001,%10001011
        .byte %11111011,%10101011
        .byte %11111011,%10101011
        .byte %11111011,%10101000
                
_OPTION_SECAM:    
        .byte %01111100,%10001101,%11011010
        .byte %11111011,%10111010,%10101000
        .byte %11111011,%10111011,%10101010
        .byte %11111101,%10011011,%10001010
        .byte %11111110,%10111011,%10101010
        .byte %11111110,%10111010,%10101010
        .byte %01111001,%10001101,%10101010       
        
_TEST_PATTERN:
        .byte %11111111 ; Score0_A
        .byte %00000000
        .byte %11111111
        .byte %00000000
        .byte %11111111
        .byte %00000000
        .byte %11111111
        .byte %11111111 ; Score0_B
        .byte %00000000
        .byte %11111111
        .byte %00000000
        .byte %11111111
        .byte %00000000
        .byte %11111111
        .byte %00000000 ; Timer_A
        .byte %11111111
        .byte %00000000
        .byte %11111111
        .byte %00000000
        .byte %11111111
        .byte %00000000
        .byte %00000000 ; Timer_B
        .byte %11111111 
        .byte %00000000
        .byte %11111111
        .byte %00000000
        .byte %11111111
        .byte %00000000
        .byte %11111111 ; Score1_A
        .byte %00000000
        .byte %11111111
        .byte %00000000
        .byte %11111111
        .byte %00000000
        .byte %11111111
        .byte %11111111 ; Score1_B
        .byte %00000000
        .byte %11111111
        .byte %00000000
        .byte %11111111
        .byte %00000000
        .byte %11111111
        
_FONT:
        .byte %11011101 ; bit 7 of TimerB bleeds into bit 7 of RightScoreB
        .byte %10101010 ; so font is design to not use bit 7
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %11011101        
_FONT_HEIGHT = * - _FONT        
        
        .byte %11011101
        .byte %10011001
        .byte %11011101
        .byte %11011101
        .byte %11011101
        .byte %11011101
        .byte %10001000

        .byte %10011001
        .byte %11101110
        .byte %11101110
        .byte %11011101
        .byte %10111011
        .byte %10111011
        .byte %10001000
        
        .byte %10011001
        .byte %11101110
        .byte %11101110
        .byte %11011101
        .byte %11101110
        .byte %11101110
        .byte %10011001
        
        .byte %11101110
        .byte %10101010
        .byte %10101010
        .byte %10001000
        .byte %11101110
        .byte %11101110
        .byte %11101110

        .byte %10001000
        .byte %10111011
        .byte %10111011
        .byte %10011001
        .byte %11101110
        .byte %11101110
        .byte %10011001

        .byte %11001100
        .byte %10111011
        .byte %10111011
        .byte %10011001
        .byte %10101010
        .byte %10101010
        .byte %11011101
        
        .byte %10001000
        .byte %11101110
        .byte %11101110
        .byte %11011101
        .byte %11011101
        .byte %10111011
        .byte %10111011       
        
        .byte %11011101
        .byte %10101010
        .byte %10101010
        .byte %11011101
        .byte %10101010
        .byte %10101010
        .byte %11011101        

        .byte %11011101
        .byte %10101010
        .byte %10101010
        .byte %11001100
        .byte %11101110
        .byte %11101110
        .byte %10011001
        
        .byte %11011101
        .byte %10101010
        .byte %10101010
        .byte %10001000
        .byte %10101010
        .byte %10101010
        .byte %10101010    
        
        .byte %10111011 ; in a 3 pixel font B is difficult to discern from 8,
        .byte %10111011 ; so use lowercase for better visibility
        .byte %10111011
        .byte %10011001
        .byte %10101010
        .byte %10101010
        .byte %10011001   
        
        .byte %11011101
        .byte %10101010
        .byte %10111011
        .byte %10111011
        .byte %10111011
        .byte %10101010
        .byte %11011101
        
        .byte %11101110 ; in a 3 pixel font D is difficult to discern from 8,
        .byte %11101110 ; so use lowercase for better visibility
        .byte %11101110
        .byte %11001100
        .byte %10101010
        .byte %10101010
        .byte %11001100
        
        .byte %10001000
        .byte %10111011
        .byte %10111011
        .byte %10011001
        .byte %10111011
        .byte %10111011
        .byte %10001000   
        
        .byte %10001000
        .byte %10111011
        .byte %10111011
        .byte %10011001
        .byte %10111011
        .byte %10111011
        .byte %10111011   
        
_FONT_SPACE = (*-_FONT)/_FONT_HEIGHT
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        .byte %11111111
        
_FONT_COLON = (*-_FONT)/_FONT_HEIGHT        
        .byte %11111111
        .byte %11111111
        .byte %11011101
        .byte %11111111
        .byte %11011101
        .byte %11111111
        .byte %11111111        

_FONT_VB = (*-_FONT)/_FONT_HEIGHT          
        .byte %11111111
        .byte %11111111
        .byte %10101001
        .byte %10101010
        .byte %10101001
        .byte %10101010
        .byte %11011001

_FONT_OS = (*-_FONT)/_FONT_HEIGHT          
        .byte %11111111
        .byte %11111111
        .byte %11011100
        .byte %10101011
        .byte %10101101
        .byte %10101110
        .byte %11011001
        
_FONT_YX = (*-_FONT)/_FONT_HEIGHT
        .byte %10101010
        .byte %10101010
        .byte %10101010
        .byte %11011101
        .byte %11011010
        .byte %11011010
        .byte %11011010        

    ; value used in this echo depends upon how many banks are used for 6507 code
    ;   $5000 if using banks 4, 5 & 6
    ;   $6000 if using banks 5 & 6
    ;   $7000 if using just bank 6
    echo "----",[$6000 - *] , "bytes free for stationary data left"
 
    
        
;===============================================================================
; Bank 5 - 6507 code
;----------------------------------------
;   I normally allocate banks 0-5 for ARM code, and just use bank 6 for 6507
;   code, but in order to show an example of CDFJ bankswitching I am using bank
;   5 for the splash screen and menu routines.
;===============================================================================

        ORG $6000
        RORG $F000  

    ; this and SplashMenuVB in bank 6 are used to switch between the banks        
SplashMenuOS:        
        sta SELECTBANK6         ; switch to bank 6, then jmp SplashMenuOS_Code
        jmp SplashMenuVB_Code
        
        POSITION_OBJECT         ; this must occupy same address in both banks
        
        
        
;===============================================================================
; Two Color Graphic routine
;-------------------------------------------------------------------------------
; this works by using a "negative" image when drawing the sprites.
; The sprites are colored black while the background is the color
; that shows up as though it were the sprites.  The 2nd color is
; achieved by using the playfield and/or ball.
;
; The missiles (also black) and setting the screen & playfield to BLACK
; are used to hide the screen and playfield beyond the 48 pixel image.
;===============================================================================
ShowTwoColorGraphic:
        sty LoopCounter

S2CGloop:
        sta WSYNC
;---------------------------------------
        SLEEP 5                 ; 5  5
        Lda #_DS_MENU_GRAPHICS  ; 2  7
        sta GRP0                ; 3 10
        lda #_DS_MENU_GRAPHICS  ; 2 12
        sta GRP1                ; 3 15
        lda #_DS_MENU_GRAPHICS  ; 2 17
        sta GRP0                ; 3 20
        lda #_DS_MENU_GRAPHICS  ; 2 22
        tax                     ; 2 24
        lda #_DS_MENU_GRAPHICS  ; 2 26
        tay                     ; 2 28
        lda #_DS_MENU_COLORS    ; 2 30
        sta.w COLUPF            ; 4 34
        lda #_DS_MENU_COLORS    ; 2 36
        sta COLUBK              ; 3 39
        lda #_DS_MENU_GRAPHICS  ; 2 41
        stx GRP1                ; 3 44
        sty GRP0                ; 3 47
        sta GRP1                ; 3 50
        sta GRP0                ; 3 53
        ldx #0                  ; 2 55
        stx COLUBK              ; 3 58
        stx COLUPF              ; 3 61
        dec LoopCounter         ; 5 66
        bne S2CGloop            ; 3 69      <- OK if page crossed
        stx PF0                 ; 3 72
        stx PF1                 ; 3 75
;---------------------------------------
        stx GRP0                ; 3 78/2
        stx GRP1                ; 3  5
        stx GRP0                ; 3  8
        rts                     ; 6 14               
        
        
SplashMenuVB_Code:      ; entry point from Bank 6
        lda Mode        ; check which screen to show
        bne MenuVB      ; Mode 1 = Menu
        jmp SplashVB    ; Mode 0 = Splash
        
MenuVB:
        ; players are already in position, just need to set size/copies & color
        ldy #%11111111
        sty GRP0
        sty GRP1
        ldy #%00100000  ; Ball Size = 4
        sty CTRLPF      ; reflect playfield, score mode on   
        ldy #_BLACK
        sty COLUP0
        sty COLUP1
        ldy #%00110011 
        sty ENAM0           ; missile on
        sty ENAM1           ; missile on
        sty ENABL           ; ball on
        sty NUSIZ0          ; three copies close, missile x8
        sty NUSIZ1          ; three copies close, missile x8
        sty VDELP0          ; vertical delay on 
        sty VDELP1          ; vertical delay on

        ldx #0
        stx COLUPF
MenuVBwait:
        sta WSYNC
        bit TIMINT
        bpl MenuVBwait
        stx VBLANK              ; video output on
         
MenuKernel:
        lda #_DS_MENU_CONTROL
        sta PF0
        lda #_DS_MENU_CONTROL
        sta PF1
        lda #_DS_MENU_CONTROL
        sta PF2
        sta HMCLR
        ldx #4
        lda #_DS_MENU_CONTROL
        jsr PosObject
        sta WSYNC
        sta HMOVE
        lda #_DS_MENU_CONTROL
        tay
        jsr ShowTwoColorGraphic
        lda #_DS_MENU_CONTROL
        bmi MenuDone
        beq MenuKernel
        tay
MenuOptionGap:
        sta WSYNC
        dey
        beq MenuKernel
        bne MenuOptionGap
       
MenuDone:
        sta WSYNC
        stx ENAM0    ; X=0 after ShowTwoColorGraphic
        stx ENAM1
        stx ENABL
        
        ldx #MM_LOGO_GAP
LogoGap:
        sta WSYNC
        dex
        bpl LogoGap
        
ShowSpiceWareLogo:  
        ldx #_WHITE
        stx COLUP0
        stx COLUP1
        stx COLUPF
    
        ldy #7
        sty LoopCounter
        ; show 1st line
        sta WSYNC
;---------------------------------------
; first row of SpiceWare logo has line extending right
        SLEEP 5
        lda #_DS_MENU_GRAPHICS  ; 2  7
        sta GRP0                ; 3 10
        lda #_DS_MENU_GRAPHICS  ; 2 12
        sta GRP1                ; 3 15
        lda #_DS_MENU_GRAPHICS  ; 2 17
        sta GRP0                ; 3 20
        lda #_DS_MENU_GRAPHICS  ; 2 22
        tax                     ; 2 24
        lda #_DS_MENU_GRAPHICS  ; 2 26
        tay                     ; 2 28
        lda #_DS_MENU_GRAPHICS  ; 2 30        
        PHA                     ; 3 33 - PHA/PLA is a 7 cycle delay in 2 bytes
        PLA                     ; 4 37
        SLEEP 4                 ; 4 41        
        stx GRP1                ; 3 44 <- time critical 
        sty GRP0                ; 3 47
        sta GRP1                ; 3 50
        sta GRP0                ; 3 53
        sty PF1                 ; 3 56 - Y has $FF from extended line in SW logo
        sty PF2                 ; 3 59
        lda #_DS_MENU_GRAPHICS  ; 2 61 - next line
        sta GRP0                ; 3 64
        lda #_DS_MENU_GRAPHICS  ; 2 66
        sta GRP1                ; 3 69
        iny                     ; 2 71 - Y now 0
        sty PF1                 ; 3 74
        sty PF2                 ; 3 77/1
        SLEEP 5                 ; 5  6
        SLEEP 4                 ; 4 10
        tya                     ; 2 12    
        beq SSWLskip1           ; 3 15 - always branches
    
SSWL1:
        sta WSYNC
;---------------------------------------        
        SLEEP 5                 ; 5  5
        lda #_DS_MENU_GRAPHICS  ; 2  7
        sta GRP0                ; 3 10
        lda #_DS_MENU_GRAPHICS  ; 2 12
        sta GRP1                ; 3 15
SSWLskip1:                      ;   15 from branch just before SSWL1
        lda #_DS_MENU_GRAPHICS  ; 2 17
        sta GRP0                ; 3 20
        lda #_DS_MENU_GRAPHICS  ; 2 22
        tax                     ; 2 24
        lda #_DS_MENU_GRAPHICS  ; 2 26
        tay                     ; 2 28
        lda #_DS_MENU_GRAPHICS  ; 2 30
        SLEEP 6                 ; 6 36  
        dec LoopCounter         ; 5 41
        stx GRP1                ; 3 44 <- time critical
        sty GRP0                ; 3 47
        sta GRP1                ; 3 50
        sta GRP0                ; 3 53
        bne SSWL1               ; 3 56  
                                ; 2 55 - if not taken
                                
; last row of SpiceWare logo has line extending left
        lda #_DS_MENU_GRAPHICS  ; 2 57
        tax                     ; 2 59
        stx GRP0                ; 3 62
        lda #_DS_MENU_GRAPHICS  ; 2 64
        sta GRP1                ; 3 67
        stx PF0                 ; 3 70 - X = $FF
        stx PF1                 ; 3 73
        ldx #%00000011          ; 2 75
;---------------------------------------
; last row of SpiceWare logo has line extending left
        SLEEP 5                 ; 5 80/4
        stx ENAM0               ; 3  7
        ldx #1                  ; 2  9
        stx CTRLPF              ; 3 12  ; reflect playfield
        lda #_DS_MENU_GRAPHICS  ; 2 14
        sta GRP0                ; 3 17
        lda #_DS_MENU_GRAPHICS  ; 2 19
        tax                     ; 2 21
        lda #_DS_MENU_GRAPHICS  ; 2 23
        tay                     ; 2 25
        lda #_DS_MENU_GRAPHICS  ; 2 27
        pha                     ; 3 30
        pla                     ; 4 34
        pha                     ; 3 37
        pla                     ; 4 41       
        stx GRP1                ; 3 44 <- time critical 
        sty GRP0                ; 3 47
        sta GRP1                ; 3 50
        sta GRP0                ; 3 53
        ldy #0                  ; 2 55
        sty PF1                 ; 3 58
        sty PF0                 ; 3 61
        sty ENAM0               ; 3 64
        sty GRP1                ; 3 67
        sty GRP0                ; 3 70
        sty GRP1                ; 3 73
EndShowSpiceWareLogo:                   
        
MenuOS:
        ldy #_FN_MENU_OS    ; going to run function MenuOverScan()
        jmp SplashMenuOS


SplashVB:
        ; players are already in position, just need to set size/copies & color
        ldx #1
        stx NUSIZ0
        stx NUSIZ1
        
        lda #DSCOMM         ; retrieves value in _TEMP_COLOR
        sta COLUP0
        sta COLUP1

        ldx #0
SplashVBwait:
        sta WSYNC
        bit TIMINT
        bpl SplashVBwait
        stx VBLANK              ; video output on
        ldy #192

SplashKernel:
        sta WSYNC
        lda #_DS_SPLASH_P0L    ; values from datastream pointing at _SPLASH0
        sta GRP0
        lda #_DS_SPLASH_P1L    ; values from datastream pointing at _SPLASH1
        sta GRP1
        lda #_DS_SPLASH_P0R    ; values from datastream pointing at _SPLASH2
        tax
        lda #_DS_SPLASH_P1R    ; values from datastream pointing at _SPLASH3
        jsr SLEEP12
        jsr SLEEP12
        SLEEP 4
        stx GRP0
        sta GRP1
        dey
        bne SplashKernel

SplashOS:
        ldy #_FN_SPLASH_OS      ; going to run function SplashOverScan()
        jmp SplashMenuOS
        

        ; NOTE:     _ means these labels will be available for the C code. 
        ; WARNING:  the values will be $Fxxx due to the RORG $F000, so the
        ;           C code will need to modify them to become $6xxx by doing:
        ;               ((_MENU_GFX0 & 0xfff) | 0x6000)
        
_MENU_GFX0:
        .byte #%10101110
        .byte #%11101000
        .byte #%10101000
        .byte #%10101100
        .byte #%10101000
        .byte #%10101000
        .byte #%10101110
        .byte #%00000000

_MENU_GFX1:
        .byte #%11001010
        .byte #%10101010
        .byte #%10101010
        .byte #%10101010
        .byte #%10101010
        .byte #%10101010
        .byte #%10101110
        .byte #%00000000

_SPLASH_GFX0:
        .byte #%00110110
        .byte #%01000101
        .byte #%01000101
        .byte #%00100110
        .byte #%00010100
        .byte #%00010100
        .byte #%01100100
        .byte #%00000000

_SPLASH_GFX1:
        .byte #%01000010
        .byte #%01000101
        .byte #%01000101
        .byte #%01000111
        .byte #%01000101
        .byte #%01000101
        .byte #%01110101
        .byte #%00000000

_SPLASH_GFX2:
        .byte #%00110101
        .byte #%01000101
        .byte #%01000101
        .byte #%00100111
        .byte #%00010101
        .byte #%00010101
        .byte #%01100101
        .byte #%00000000
               
_SPLASH_26:
        .byte #%01100011
        .byte #%00010100
        .byte #%00010100
        .byte #%00100110
        .byte #%00100101
        .byte #%01000101
        .byte #%01110010
        .byte #%00000000

_SPLASH_78:
        .byte #%01110010
        .byte #%00010101
        .byte #%00010101
        .byte #%00100010
        .byte #%00100101
        .byte #%01000101
        .byte #%01000010
        .byte #%00000000
        
        ORG $6FEA
        RORG $FFEA
B5init:        
        sta SELECTBANK6
        jmp B5init      ; should never get here, but just in case
        ds 12, 0        ; reserve space for CDFJ registers
        .WORD B5init    ; while CDFJ will only power up in bank 5, an accidental
        .WORD B5init    ; BRK instruction could occur, so gracefully handle it
        
        
        
;===============================================================================
; Bank 6 - 6507 code
;----------------------------------------
;   CDFJ will always start in bank 6 because banks 0-5 could contain ARM code
;===============================================================================

        ORG $7000
        RORG $F000
        
    ; this and SplashMenuOS in bank 5 are used to switch between the banks                
SplashMenuVB:        
        sta SELECTBANK5         ; switch to bank 5, then jmp SplashMenuVB_Code 
        jmp SplashMenuOS_Code      
        
        POSITION_OBJECT         ; this must occupy same address in both banks        
        
        ; CallArmCode is only called form bank 6. If we needed to also call it
        ; from bank 5 then we would set up a macro like POSITION_OBJECT
CallArmCode:
        ldx #<_DS_TO_ARM
        stx DSPTR
        ldx #>_DS_TO_ARM    ; NOTE: if _DS_TO_ARM = 0 we can leave out this LDX
        stx DSPTR
        sty DSWRITE         ; save in _RUN_FUNC, Y holds which function to call
        ldx SWCHA           ; read state of both joysticks
        stx DSWRITE         ; save in _SWCHA 
        ldx SWCHB           ; read state of console switches
        stx DSWRITE         ; save in _SWCHB
        ldx INPT4           ; read state of left joystick firebutton
        stx DSWRITE         ; save in _INPT4 
        ldx INPT5           ; read state of right joystick firebutton
        stx DSWRITE         ; save in _INPT5
        ldx TimeLeftVB      ; Time remaining in VB (only tracked for game screen)
        stx DSWRITE         ; save in _VB_TIME
        ldx TimeLeftOS      ; Time remaining in OS (only tracked for game screen)
        stx DSWRITE         ; save in _OS_TIME
        ldx #$FF            ; FF = Run ARM code w/out digital audio interrupts
        stx CALLFN          ; runs main() in the C code
        lda #DSCOMM         ; get the current game mode
        sta Mode            ; and save it        
        rts        
       
InitSystem:
; Console Detection Routine
;
; normally we'd use CLEAN_START, but to detect if console is 2600 or 7800
; we need to take a look at the ZP RAM values in $80, $D0, and $D1 before
; zeroing out RAM
;
;   if $D0 contains $2C and $D1 contains $A9 then
;       system = 7800           // game was loaded from Harmony menu on a 7800
;   else if both contain $00 then
;       system = ZP RAM $80     // game was flashed to Harmony/Melody so CDFJ
;                               // driver checked $D0 and $D1 for us and saved
;                               // results in $80
;   else
;       system = 2600           // game was loaded from Harmony menu on a 2600

        sei 
        cld
        
        ldy #0              ; assume system = 2600        
        ldx $d0
        beq .foo ; if $00 then game might be flashed on Harmony/Melody
        cpx #$2c
        bne .is2600         ; if not $2C then loaded via Harmony Menu on 2600        
        ldx $d1
        cpx #$a9
        bne .is2600
        dey                 ; 7800: y=$FF
        bne .done           ; this will always branch
        
.foo        
        ldx $d1
        bne .is2600         ; if not $00 then loaded via Harmony Menu on 2600
        ldy $80             ; else get the value saved by the CDFJ driver
        
.is2600                     ; 2600: y == 0
.done                       ; 7800: y != 0
; end of console detection routine, y contains results

        ldx #0
        txa
CLEAR_STACK:
        dex
        txs
        pha
        bne CLEAR_STACK     ; SP=$FF, X = A = 0
        
        ; Fast Fetch mode must be turned on so we can read the datastreams
        ; Note: Fast Fetch mode overrides LDA #, so need to use LDX # or
        ;       LDY # if not reading a CDFJ register
        ldx #FASTON
        stx SETMODE
        
        ldx #<_DS_TO_ARM
        stx DSPTR
        ldx #>_DS_TO_ARM    ; NOTE: if _DS_TO_ARM = 0 we can leave out this LDX
        stx DSPTR
        ldx #_FN_INIT       ; going to run function Initialize()
        stx DSWRITE         ; save in _RUN_FUNC
        sty DSWRITE         ; save 2600/7800 value in _SWCHA 
        sty DSWRITE         ; save 2600/7800 value in _SWCHB
        sty DSWRITE         ; save 2600/7800 value in _INPT4 
        sty DSWRITE         ; save 2600/7800 value in _INPT5
        ldx #$FF            ; FF = Run ARM code w/out digital audio interrupts
        stx CALLFN          ; runs main() in the C code        
        ldy #_FN_SPLASH_OS      ; going to run function SplashOverScan()
        bne SplashMenuOS_Code
        
OverScan:
        ldy #_FN_GAME_OS        ; going to run function GameOverScan()
SplashMenuOS_Code:    ; entry point from bank 5 & InitSystem with Y already set        
        sta WSYNC
        ldx #2
        stx VBLANK              ; video output off
        ldx #OS_TIM64T
        stx TIM64T              ; set timer for OS       
        jsr CallArmCode
                
        lda INTIM
        sta TimeLeftOS
OSwait:        
        stx WSYNC
        bit TIMINT
        bpl OSwait
        
VerticalSync:
        ldy #2
        ldx #VB_TIM64T
        sty WSYNC
; --- start scanline 1 of Vertical Sync ---        
        sty VSYNC           ; 3  3  turn on Vertical Sync signal
        stx TIM64T          ; 4  7        
        sty WSYNC           ; 3 10/0
; --- start scanline 2 of Vertical Sync ---        
        ; use otherwise wasted time to zero out some TIA registers
        ldx #0              ; 2  2
        stx GRP0            ; 3  5
        stx GRP1            ; 3  8
        stx VDELP0          ; 3 11
        stx VDELP1          ; 3 14
        stx WSYNC           ; 3 17/0
; --- start scanline 3 of Vertical Sync ---        
        ; use otherwise wasted time to figure out
        ; which ARM Vertical Blank routine to run
        lda Mode            ; 3  3 $00 = splash, $01 = menu, $80 = game
        bmi vbgame          ; 2  5  3  6 if taken
        beq vbsplash        ; 2  7     |  3  8 if taken
        ldy #_FN_MENU_VB    ; 2  9     |     |  run function MenuVerticalBlank()
        .byte $0c           ; 4 13     |     |  NOP ABSOLUTE, skips over ldy #_FN_SPLASH_VB         
vbsplash:                   ;    |     |     |
        ldy #_FN_SPLASH_VB  ;    |     |  2 10  run function SplashVerticalBlank()
        .byte $0c           ; 4 17     |  4 14  NOP ABSOLUTE, skips over ldy #_FN_GAME_VB
vbgame:                     ;    |     |     |
        ldy #_FN_GAME_VB    ;    |  2  8     |  run function GameVerticalBlank()
                            ;   17     8    14  17 cycles worse case scenerio
        stx WSYNC           ; end of VerticalSync scanline 3
        stx VSYNC           ; turn off Vertical Sync signal            
        jsr CallArmCode
        
        ; ARM VB routines send back the initial positions of the 5 objects      
        ldx #4
vbSetInitialX:        
        lda #DSCOMM         ; will get _BALL_X, _M1_X, _M0_X, _P1_X, and _P0_X
        jsr PosObject
        dex        
        bpl vbSetInitialX
        sta WSYNC
        sta HMOVE
        
        ; figure out which 6507 Vertical Blank routine to run
        lda Mode            ; $00 = splash, $01 = menu, $80 = game
        bmi GameVB
        jmp SplashMenuVB
        
GameVB:        
        ; players are already in position, just need to set size/copies
        ldx #0
        stx NUSIZ0
        stx NUSIZ1
        
        lda #DSCOMM         ; will get _TEMP_COLOR to set background color in
        sta COLUBK          ; order to test the new Arena menu option
        
        ldx #0
        lda INTIM
        sta TimeLeftVB
GameVBwait:
        sta WSYNC
        bit TIMINT
        bpl GameVBwait
        stx VBLANK              ; video output on
        ldy #_ARENA_HEIGHT
         
GameKernel:
        sta WSYNC
;---------------------------------------                
        lda #_DS_GRP0   ; 2  2 values from datastream pointing at _PLAYER0
        sta GRP0        ; 3  5
        lda #_DS_GRP1   ; 2  7 values from datastream pointing at _PLAYER1
        sta GRP1        ; 3 10
        lda #_DS_COLUP0 ; 2 12 values from datastream pointing at _COLOR0
        sta COLUP0      ; 3 15
        lda #_DS_COLUP1 ; 2 17 values from datastream pointing at _COLOR1
        sta COLUP1      ; 3 20
        dey             ; 2 22
        bne GameKernel  ; 2 24 (3 25)
        
ScoreKernel:
        sta WSYNC               ; 3 27/0
;---------------------------------------        
        ldx #0                  ; 2  2
        stx PF0                 ; 3  5
        stx PF1                 ; 3  8
        stx PF2                 ; 3 11
        stx COLUBK              ; 3 14
        stx COLUPF              ; 3 17
        stx COLUP0              ; 3 20
        stx COLUP1              ; 3 23
        inx                     ; 2 25 X = 1
        stx VDELP0              ; 3 28
        stx VDELP1              ; 3 31
        stx RESP0               ; 3 34 roughly position player 0
        stx RESP1               ; 3 37 roughly position player 1
        dex                     ; 2 39 X = $00, no shift
        stx HMP1                ; 3 42 fine tune position player 1
        dex                     ; 2 44 $fx = shift right 1
        stx HMP0                ; 3 47 fine tune position player 0 
        ldx #%00000110          ; 2 49 3 copies medium spacing
        stx NUSIZ0              ; 3 52 
        stx NUSIZ1              ; 3 55
        ldx #%00000011          ; 2 57
        stx PF1                 ; 3 60
        ldx #%11000011          ; 2 62
        stx PF2                 ; 3 65
        sta WSYNC               ; 3 68/0
;---------------------------------------                
        sta HMOVE               ; 3  3
        ldx #6                  ; 2  5
        stx LoopCounter         ; 3  8
        ldx #_WHITE             ; 2 10 timer color
        lda #_DS_SCORE1_COLOR   ; 2 12
        tay                     ; 2 14 right score color
ScoreLoop:
        sta WSYNC
;---------------------------------------
        lda #_DS_SCORE0_COLOR   ; 2  2 left score color
        sta COLUPF              ; 3  5
        lda #_DS_SCORE0_GFXA    ; 2  7  
        sta GRP0                ; 3 10
        lda #_DS_SCORE0_GFXB    ; 2 12
        sta GRP1                ; 3 15 _DS_SCORE1_GFX0 now visible in GRP0
        lda #_DS_TIMER_GFXA     ; 2 17
        sta GRP0                ; 3 20 _DS_SCORE1_GFX1 now visible in GRP1        
        lda #_DS_TIMER_GFXB     ; 2 22        
        SLEEP 14                ;14 36
        sta GRP1                ; 3 39 _DS_TIMER_GFX0 now visible in GRP0
        stx COLUPF              ; 3 42 set timer color
        lda #_DS_SCORE1_GFXA    ; 2 44
        sta GRP0                ; 3 47 _DS_TIMER_GFX1 now visible in GRP1
        lda #_DS_SCORE1_GFXB    ; 2 49
        sty COLUPF              ; 3 52 right score color
        sta GRP1                ; 3 55 _DS_SCORE2_GFX0 now visible in GRP0      
        sta GRP0                ; 3 58 _DS_SCORE2_GFX1 now visible in GRP1
        dec LoopCounter         ; 5 63
        bpl ScoreLoop           ; 2 65 3 66 if taken
        ldx #_BLACK             ; 2 67
        stx COLUPF              ; 3 70
        jmp OverScan
        
        ORG $7FED
        RORG $FFED
        jmp InitSystem
        ds 12, 0    ; reserve space for CDFJ registers
        .WORD InitSystem
        .WORD InitSystem
        
;===============================================================================
; Display Data
;----------------------------------------
;   4K of RAM shared between the 6507 and ARM.
;
;   NOTE: anything prefixed with _ ends up in main/defines_from_dasm_for_c.h
;         so that the C code will have the same values as the 6507 code
;===============================================================================

    SEG.U DISPLAYDATA
    ORG $0000

_DS_TO_ARM:     
_RUN_FUNC:      ds 1        ; function to run
_SWCHA:         ds 1        ; joystick directions to ARM code
_SWCHB:         ds 1        ; console switches to ARM code
_INPT4:         ds 1        ; left firebutton state to ARM code
_INPT5:         ds 1        ; right firebutton state to ARM code
_VB_TIME:       ds 1        ; VB Time Remaining
_OS_TIME:       ds 1        ; OS Time Remaining

_DS_FROM_ARM:
_MODE:          ds 1        ; $00 = splash, $01 = menu, $80 = game 
_BALL_X:        ds 1        ; position of ball
_M1_X:          ds 1        ; position of missile 1
_M0_X:          ds 1        ; position of missile 0
_P1_X:          ds 1        ; position of player 1
_P0_X:          ds 1        ; position of player 0
_TEMP_COLOR:    ds 1

;----------------------------------------
; To save space in RAM we can share the space used by the datastream buffers
; for the Splash, Menu, and Game screens.
;----------------------------------------
    align 4             ; using myMemsetInt to zero out RAM is faster than
                        ; myMemset, but it requires the starting address to be
                        ; 4 byte aligned 
OverlapDisplayDataRam:  ; mark the beginning of overlapped RAM
; Splash screen datastream buffers
_BUF_SPLASH0:   ds 192
_BUF_SPLASH1:   ds 192
_BUF_SPLASH2:   ds 192
_BUF_SPLASH3:   ds 192

    echo "----",($1000 - *) , "Splash bytes of Display Data RAM left"
;----------------------------------------
; this ORG overlaps the Menu datastreams on top of the Splash datastreams
;----------------------------------------
    ORG OverlapDisplayDataRam
; Menu datastream buffers
_BUF_MENU_GRAPHICS: ds _MENU_GRAPHICS_SIZE
_BUF_MENU_CONTROL:  ds _MENU_CONTROL_SIZE
_BUF_MENU_COLORS:   ds _MENU_COLORS_SIZE

    echo "----",($1000 - *) , "Menu bytes of Display Data RAM left"
    
;----------------------------------------
; this ORG overlaps the Game datastreams on top of the Splash and Menu datastreams
;----------------------------------------
    ORG OverlapDisplayDataRam
; Game datastream buffers
_GameZeroOutStart:
_BUF_PLAYER0:       ds 192
_BUF_PLAYER1:       ds 192
_BUF_COLOR0:        ds 192
_BUF_COLOR1:        ds 192
_BUF_SCORE0_A:      ds 7
_BUF_SCORE0_B:      ds 7
_BUF_TIMERA:        ds 7
_BUF_TIMERB:        ds 7
_BUF_SCORE1_A:      ds 7
_BUF_SCORE1_B:      ds 7
_BUF_SCORE0_COLOR:  ds 1
_BUF_SCORE1_COLOR:  ds 1

    align 4             ; need to be 4 byte aligned to use myMemsetInt
_GameZeroOutBytes = *-_GameZeroOutStart

; $876 bytes free before overlap

    echo "----",($1000 - *) , "Game bytes of Display Data RAM left"        
