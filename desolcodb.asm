
;  ORG $9DBE

; Game main loop
;
L9DDD:
  LD A,(LDB7A)            ; Get Health
  OR A
  JP Z,LB9A2              ; Player is dead
  CALL LADE5              ; Decode current room
  CALL LA88F              ; Display 96 tiles on the screen
  CALL LB96B              ; Display Health
  CALL LB8EA              ; Show look/shoot selection indicator
  CALL LB76B
  CALL LB551
  CALL LA0F1              ; Scan keyboard
  CP $0F                  ; CLEAR
  JP Z,LBA3D
  CP $04                  ; Up
  JP Z,LA99B
  CP $01                  ; Down
  JP Z,LA966
  CP $02                  ; Left
  JP Z,LA9EB
  CP $03                  ; Right
  JP Z,LAA1A
  XOR A                   ; Not a valid key
  LD (LDB7C),A
  JP LA8C6

L9E19:
  CALL LB653
  CALL LA0F1              ; Scan keyboard
  CP $36                  ; Yellow "2nd" key
  JP Z,LAAAF              ; Look / Shoot
  CP $28                  ; "XT0n" key
  JP Z,LB930              ; Look / Shoot Mode
  CP $30                  ; "ALPHA" key
  JP Z,LB0A2              ; Open the Inventory
L9E2E:
  CALL L9FEA              ; Copy shadow screen to ZX screen
  JP L9DDD

; Quit menu item selected
L9E51:
  ret ;STUB

; Put tile on the screen (NOT aligned to 8px column), 16x8 -> 16x16 on shadow screen
; Uses XOR operation so it is revertable.
;   L = row; A = X coord; B = height; IX = tile address
L9E5F:
  ld e,l
  ld h,$00
  ld d,h
  add hl,de               ; now HL = L * 2
  add hl,de               ; now HL = L * 3
  add hl,hl
  add hl,hl               ; now HL = L * 12
  add hl,hl               ; now HL = L * 24
  ld e,a
  and $07
  ld c,a                  ; C = offset within 8px column
  srl e
  srl e
  srl e                   ; E = number of 8px column
  add hl,de               ; now HL = offset on the shadow screen
  ld de,ShadowScreen
  add hl,de               ; HL = address in the shadow screen
L9E8D:                  ; loop by B
  ld d,(ix+$00)
  ld e,$00
  ld a,c
  or a
  jr z,L9E9D
L9E96:
  srl d
  rr e
  dec a
  jr nz,L9E96
L9E9D:
  ld a,(hl)
  xor d
  ld (hl),a
  inc hl
  ld a,(hl)
  xor e
  ld (hl),a
  ld de,24-1
  add hl,de               ; to the next line
  inc ix
  inc ix
  djnz L9E8D
  ret

; Put tile on the screen (aligned to 8px column), 16x8 -> 16x16 on shadow screen
; NOTE: we're using masked tiles here but ignoring the mask
;   L = row; E = 8px column; IX = tile address
L9EAD:
  ld a,e
  add a,a
  add a,a
  add a,a
  add a,a
  ld ($86D7),a          ; penCol
  ld a,l                ; penRow
  ld b,8                ; 8 row pairs
  call GetScreenAddr    ; now HL = screen addr
L9EAD_1:
  push bc
; Draw 1st line
  ld a,(ix+$01)
  ld (hl),a             ; write 1st byte
  inc hl
  ld c,a
  ld a,(ix+$03)
  ld (hl),a             ; write 2nd byte
  ld b,a
  ld de,24-1
  add hl,de             ; to the 2nd line
; Draw 2nd line
  ld (hl),c             ; write 1st byte
  inc hl
  ld (hl),b             ; write 2nd byte
  pop bc
  ld de,24-1
  add hl,de             ; to the next line
  ld de,$0004
  add ix,de
  djnz L9EAD_1
  ret

;   DE = tiles address; A = ??; H = column; L = row
L9EDE:
  PUSH HL
  PUSH AF
  AND $3F
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  add hl,hl
  ADD HL,DE               ; now HL = source tile address
  LD DE,L9FAF
  LD BC,32
  LDIR                    ; get the tile data to the buffer
  POP AF
;  BIT 6,A
;  CALL NZ,L9EDE_1
;  BIT 7,A
;  CALL NZ,L9EDE_4
  LD IX,L9FAF
  POP HL
  LD A,H
  LD H,$00
  LD B,H
  LD C,L                  ; get row
  ADD HL,BC
  ADD HL,BC
  ADD HL,HL
  ADD HL,HL
  add hl,hl               ; now HL = row * 24
  LD C,A
  ADD HL,BC               ; now HL = offset on the shadow screen
  ld bc,ShadowScreen
  ADD HL,BC
  LD B,$08                ; 8 line pairs
L9EDE_0:                  ; loop by B
  PUSH BC
; Process 1st line
  ld a,(ix+$00)           ; get mask byte
  and (hl)
  or (ix+$01)             ; use pixels byte
  ld (hl),a
  inc hl
  ld a,(ix+$02)           ; get mask byte
  and (hl)
  or (ix+$03)             ; use pixels byte
  ld (hl),a
  ld bc,24-1
  add hl,bc               ; next line
; Process 2nd line
  ld a,(ix+$00)           ; get mask byte
  and (hl)
  or (ix+$01)             ; use pixels byte
  ld (hl),a
  inc hl
  ld a,(ix+$02)           ; get mask byte
  and (hl)
  or (ix+$03)             ; use pixels byte
  ld (hl),a
  ld bc,24-1
  add hl,bc               ; next line
; Increase tile address
  ld bc,$0004
  add ix,bc
  POP BC
  DJNZ L9EDE_0
  RET
L9EDE_1:
  ret ;STUB

L9FAF:
  DEFS 32,$00


; Copy shadow screen to ZX screen
;
L9FEA:
  jp ShowShadowScreen

; Clear shadow screen
;
L9FCF:
  ld bc,24*138-1	        ; 64 line pairs
  ld hl,ShadowScreen
  ld e,l
  ld d,h
  inc de
  xor a
  ld (hl),a
  ldir
  ret

; Scan keyboard; returns key in A
;
LA0F1:
  PUSH BC
  PUSH DE
  PUSH HL
  call ReadKeyboard
;TODO: Protect from reading same key several times
  POP HL
  POP DE
  POP BC
  RET

; Display 96 tiles on the screen
;   HL Address where the 96 tiles are placed
LA88F:
  LD DE,$0000
LA88F_0:
  PUSH HL
  PUSH DE
  LD L,(HL)
  LD A,L
  OR A
  JR Z,LA88F_1
  CP $47
  CALL Z,LBC29
  LD H,$00
  ADD HL,HL               ; HL <- HL * 16
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  add hl,hl	; HL <- HL * 32
  LD BC,Tileset1
  ADD HL,BC
  PUSH HL
  POP IX
  LD A,E
  LD L,D
  CALL L9EAD              ; Put tile on the screen
LA88F_1:
  POP DE
  POP HL
  INC HL
  INC E
  LD A,E
  CP $0C
  JP NZ,LA88F_0
  LD E,$00
  LD A,$10
  ADD A,D
  LD D,A
  CP $80
  JP NZ,LA88F_0
  RET

LA8C6:
  XOR A
  LD (LDD54),A
  JP LA8CD
;
LA8CD:
  LD C,$00
  LD A,(LDD55)
  OR A
  JR Z,LA8DF
  LD HL,LDE87
  LD A,(LDB75)            ; Direction/orientation??
  ADD A,A
  ADD A,A                 ; now A = A * 4
  JR LA8E9
LA8DF:
  LD HL,LDE47
  LD A,(LDB75)            ; Direction/orientation??
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A                 ; now A = A * 8
LA8E9:
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(LDD54)
  ADD A,A
  ADD A,A                 ; now A = A * 4
  LD E,A
  LD D,$00
  ADD HL,DE
  LD B,$04                ; 4 tiles?
LA8F8:                    ; loop by B
  PUSH HL
  LD L,(HL)               ; tile number??
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL               ; HL = L * 16
  add hl,hl
  LD DE,Tileset1+$7A*32   ; was: $E8E7
  ADD HL,DE
  EX DE,HL
  CALL LA92E
  PUSH BC
  CALL LA956
  LD A,C
  CALL L9EDE
  POP BC
  POP HL
  INC HL
  DJNZ LA8F8
  LD A,(LDD54)
  CP $03
  JR Z,LA927
  INC A
  LD (LDD54),A
  XOR A
  LD (LDD55),A
  JP L9E19
LA927:
  XOR A
  LD (LDD54),A
  JP L9E19
LA92E:
  INC C
  LD A,(LDB76)            ; Get X coord in tiles
  add a,a
  LD H,A
  LD A,(LDB77)            ; Get Y coord in lines
;  add a,a
  SUB 16      ; was: $08
  LD L,A
  LD A,C
  CP $01
  RET Z
  CP $02
  JR NZ,LA94C
LA941:
  LD A,(LDB75)
  CP $02
  JR Z,LA94A
  INC H
  RET
LA94A:
  DEC H
  RET
LA94C:
  LD A,16     ; was: $08
  ADD A,L
  LD L,A
  LD A,C
  CP $04
  JR Z,LA941
  RET
LA956:
  LD C,$00
  LD A,(LDB75)
  OR A
  RET Z
  CP $01
  RET Z
  CP $03
  RET Z
  LD C,$80
  RET

; Move Down
LA966:
  LD A,(LDB75)
  OR A
  JP Z,LA97C
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01
  JP NZ,LA97C
  XOR A
  LD (LDB75),A
  JP LA8C6
LA97C:
  XOR A
  LD (LDB75),A
  CALL LAA60
  CP $01
  JP NZ,LA8CD
  LD A,(LDB77)
  PUSH AF
  ADD A,$08
  LD (LDB77),A
  LD A,(LDB78)
  PUSH AF
  INC A
  LD (LDB78),A
  JR LA9D1
;
; Move Up
LA99B:
  LD A,(LDB75)
  CP $01
  JP Z,LA9B3
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01
  JP NZ,LA9B3
  LD A,$01
  LD (LDB75),A
  JP LA8C6
LA9B3:
  LD A,$01
  LD (LDB75),A
  CALL LAA60
  CP $01
  JP NZ,LA8CD
  LD A,(LDB77)
  PUSH AF
  ADD A,$F8
  LD (LDB77),A
  LD A,(LDB78)
  PUSH AF
  DEC A
  LD (LDB78),A
LA9D1:
  LD A,(LDB84)
  OR A
  JP Z,LA9E6
  CALL LB72E
  OR A
  JP Z,LA9E6
  CALL LB74C
  OR A
  JP Z,LB07B           ; Decrease Health by 4, restore Y coord
LA9E6:
  POP AF
  POP AF
  JP LA8CD
;
; Move Left
LA9EB:
  LD A,(LDB75)
  CP $02
  JP Z,LAA03
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01
  JP NZ,LAA03
  LD A,$02
  LD (LDB75),A
  JP LA8C6
LAA03:
  LD A,$02
  LD (LDB75),A
  CALL LAA60
  CP $01
  JP NZ,LA8CD
  LD A,(LDB76)            ; Get X coord in tiles
  PUSH AF
  DEC A                   ; X = X - 1
  LD (LDB76),A
  JR LAA47
;
; Move Right
LAA1A:
  LD A,(LDB75)
  CP $03
  JP Z,LAA32
  LD A,(LDB7D)            ; Get look/shoot switch value
  CP $01                  ; Shoot mode?
  JP NZ,LAA32             ; no => jump
  LD A,$03
  LD (LDB75),A
  JP LA8C6
LAA32:
  LD A,$03
  LD (LDB75),A
  CALL LAA60
  CP $01
  JP NZ,LA8CD
  LD A,(LDB76)            ; Get X coord in tiles
  PUSH AF
  INC A                   ; X = X + 1
  LD (LDB76),A
LAA47:
  LD A,(LDB84)
  OR A
  JP Z,LAA5C
  CALL LB72E
  OR A
  JP Z,LAA5C
  CALL LB74C
  OR A
  JP Z,LB08D              ; Decrease Health by 4, restore X coord
LAA5C:
  POP AF
  JP LA8CD
;
LAA60:
  CALL LADE5              ; Decode current room
  LD A,(LDB76)            ; Get X coord in tiles
  LD E,A
  CALL LAA7D
  LD D,$00
  ADD HL,DE
  LD A,(LDB74)
  LD E,A
  LD A,(LDB78)
  LD B,A
  CALL LAA8D
;
LAA78:
  ADD HL,DE
  DJNZ LAA78
  LD A,(HL)
  RET
;
LAA7D:
  LD A,(LDB75)
  OR A
  RET Z
  CP $01
  RET Z
  CP $02
  JR NZ,LAA8B
  DEC E
  RET
LAA8B:
  INC E
  RET
;
LAA8D:
  ret ;STUB

LAA9D:
  ret ;STUB

; Look / Shoot
LAAAF:
  ret ;STUB

; Show small message popup
;
LAB28:
  PUSH BC
  PUSH DE
  LD BC,$0060
  LD HL,LEB27             ; Decode from: Small message popup
  LD DE,LDBF5             ; Decode to
  CALL LB9F1              ; Decode the room
  LD HL,LDBF5
  CALL LB177              ; Display screen from tiles with Tileset #2
  POP DE
  POP BC
  RET

; Wait for Down key
LAD99:
  CALL LA0F1              ; Scan keyboard
  CP $01                  ; Down key?
  JR NZ,LAD99
  RET
;
; Wait for MODE key
LADA1:
  CALL LA0F1              ; Scan keyboard
  CP $37
  JR NZ,LADA1
  RET

; Decode current room
;
LADE5:
  LD A,(LDB79)            ; Get the room number
  LD HL,LDE97             ; List of encoded room addresses
  CALL LADFF              ; now HL = encoded room
  LD BC,$0060             ; decode 96 bytes
  CALL LADF5              ; Decode the room to DBF5
  RET
;
; Decode the room to DBF5
;
; HL Decode from
; BC Tile count to decode
LADF5:
  LD DE,LDBF5             ; Decode to
  CALL LB9F1              ; Decode the room
  LD HL,LDBF5
  RET
;
; Get address from table
;
; A Element number
; HL Table address
LADFF:
  ADD A,A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  RET

; Decrease Health by 4, restore Y coord
LB07B:
  LD B,$02
LB07D:
  CALL LB994              ; Decrease Health
  DJNZ LB07D
  POP AF
  LD (LDB78),A
  POP AF
  LD (LDB77),A
  JP LA8CD
;
; Decrease Health by 4, restore X coord
LB08D:
  LD B,$02
LB08F:
  CALL LB994              ; Decrease Health
  DJNZ LB08F
  POP AF                  ; Restore old X coord
  LD (LDB76),A            ; Set X coord
  JP LA8CD
LB09B:
  LD HL,$3410
  LD ($86D7),HL           ; Set penRow/penCol
  RET
;
; Open Inventory
;
LB0A2:
  LD BC,$0060             ; Titles count to decode
  LD HL,LF329             ; Encoded screen for Inventory popup
  CALL LADF5              ; Decode the room to DBF5
  CALL LB177              ; Display screen from tiles with Tileset #2
  LD A,$16
  LD (LDCF3),A            ; Left margin size for text
  LD A,$06
  LD (LDCF4),A            ; Line interval for text
  XOR A
  LD (LDCF5),A            ; Data cartridge reader slot
  LD (LDC59),A
  LD (LDC5A),A
  LD (LDCF8),A
  LD A,$08
  LD (LDC83),A
  LD A,$12
  LD (LDC84),A
  LD HL,$1630
  LD ($86D7),HL
  LD HL,SE0BB             ; " - INVENTORY - "
  CALL LBEDE              ; Load archived string and show message char-by-char

  ret ;STUB

; Display screen from tiles with Tileset #2
;
; HL Screen in tiles, usually $DBF5
LB177:
  LD BC,$0000
LB177_0:
  PUSH HL
  PUSH BC
  ld a,(hl)
  ld l,a
  dec a
  JR Z,LB177_1
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  add hl,hl	; * 32
  LD DE,Tileset2
  add hl,de
  ex de,hl
  ld ixl,e
  ld ixh,d
  ld l,b
  ld e,c
  call DrawTileMasked     ; was: CALL L9EDE
LB177_1:
  POP BC
  POP HL
  INC HL
  ld a,c
  add a,16
  cp 12*16
  ld c,a
  JP NZ,LB177_0
  LD C,$00
  ld a,b
  add a,16
  cp 16*8
  ld b,a
  JP NZ,LB177_0
  RET

; Delay by DC59
LB2D0:
  LD A,(LDC59)
  LD C,A
LB2D0_0:
  LD D,A
LB2D0_1:
  DEC D
  JP NZ,LB2D0_1
  DEC C
  JP NZ,LB2D0_0
  RET

LB551:
  ret ;STUB

LB653
  ret ;STUB

LB72E:
  ret ;STUB

LB74C:
  ret ;STUB

LB76B:
  ret ;STUB

; Show look/shoot selection indicator
;
LB8EA:
  LD A,(LDB7D)            ; Get look/shoot switch value
  OR A                    ; 
  JP Z,LB902              ;
  CALL LB913              ;
  LD A,$8C                ;
  CALL L9E5F              ;
  CALL LB91C              ;
  LD A,$A0                ;
  CALL L9E5F              ;
  RET                     ;
LB902:
  CALL LB913              ;
  LD A,$76                ;
  CALL L9E5F              ;
  CALL LB91C              ;
  LD A,$8A                ;
  CALL L9E5F              ;
  RET                     ;
LB913:
  LD IX,Tileset3+1        ; Small triange pointing right
  LD B,12                 ; Tile height
  LD L,$00                ; Y pos
  RET                     ;
LB91C:
  LD IX,Tileset3+32+1     ; Small triange pointing left
  LD B,12                 ; Tile height
  LD L,$00                ; Y pos
  RET                     ;

LB925:
  ret ;STUB

; Switch Look / Shoot mode
LB930:
  ret ;STUB

; Display Health
;
LB96B:
  LD HL,$012C
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,(LDB7A)           ; Get Health
  jp DrawNumber3

; Decrease Health
;
LB994:
  LD A,(LDB7A)
  SUB $02                 ; Health = Health minus 2
  CALL C,LB9A0
  LD (LDB7A),A
  RET
LB9A0:
  XOR A
  RET
;
; Player is dead, Health 0
;
LB9A2:
  CALL L9FCF              ; Clear screen 9340/9872
  LD A,$32
  LD (LDCF3),A
  LD A,$0E
  LD (LDCF4),A
  CALL LAB28              ; Show small message popup
  LD HL,$580E
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0BD             ; "The Desolate has claimed|your life too . . ."
  CALL LBEDE              ; Load archived string and show message char-by-char
  XOR A
  CALL LB9D6
  LD HL,(LDBC3)
  INC HL
  LD (LDBC3),HL
LB9C9:
  CALL L9FEA              ; Copy shadow screen to ZX screen
  CALL LA0F1              ; Scan keyboard
  CP $37                  ; "MODE" key
  JP Z,L9E19
  JR LB9C9
;
LB9D6:
  LD (LDB79),A
  LD (LDB75),A
  LD A,$06
  LD (LDB76),A            ; Set X coord = 6
  LD A,$30    ; was: $18
  LD (LDB77),A
  LD A,$03
  LD (LDB78),A
  LD A,$64                ; Health = 100
  LD (LDB7A),A
  RET

; Decode the room/screen
;
; HL Decode from
; BC Decode to
LB9F1:
  LD A,(HL)
  CP $FF
  JR Z,LB9F1_1
  LDI
LB9F1_0:
  RET PO
  JR LB9F1
LB9F1_1:
  INC HL
  LD A,(HL)
  INC HL
  INC HL
LB9F1_2:
  DEC HL
  DEC A
  LDI
  JR NZ,LB9F1_2
  JR LB9F1_0

; Show titles and show Menu
LBA07:
  LD A,$44
  LD (LDC59),A
  LD (LDC85),A
  LD HL,$3A1E
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE09D             ; "MaxCoderz Presents"
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL LBA81
  CALL LBC7D              ; Clear shadow screen and copy to A28F/A58F
  CALL LBC34
  LD HL,$3A2E
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE09F             ; "a tr1p1ea game"
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL LBA81
  CALL LBC7D              ; Clear shadow screen and copy to A28F/A58F
  CALL LBC34
  XOR A
  LD (LDC85),A

; Return to Menu
;
LBA3D:
  LD A,(LDC55)
  INC A
  CP $08
  CALL Z,LBC2F
  LD (LDC55),A
  DI
  LD HL,LF515
  CALL LA88F              ; Display 96 tiles on the screen
  LD HL,LF4B5             ; Main menu screen
  EI
  CALL LB177              ; Display screen from tiles with Tileset #2
  LD C,$09                ; left triangle X pos
  LD IX,Tileset3          ; Tile arrow right
  DI
  CALL LBA88
  LD C,$4D                ; right triangle X pos
  LD IX,Tileset3+32       ; Tile arrow left
  DI
  CALL LBA88
  CALL L9FEA              ; Copy shadow screen to ZX screen
  CALL LA0F1              ; Scan keyboard
  CP $36                  ; look/shoot key
  JP Z,LBA93
  cp $09                  ; Enter key
  jp z,LBA93
  CP $04                  ; Up key
  JP Z,LBBCC
  CP $01                  ; Down key
  JP Z,LBBDC
  JP LBA3D

LBA81:
  CALL LBC34	
  CALL LBC34	
  RET

; Draw menu item selection triangles
;
LBA88:
  LD A,(LDB8F)
  LD L,A                  ; L = Y coord
  LD A,C                  ; A = X coord
  LD B,16                 ; 8 = tile height
  CALL L9E5F              ; Draw tile by XOR operation
  RET
;
LBA93:
  LD A,(LDB8F)
  CP $3A
  JP Z,LBAB2              ; New menu item
  CP $46
  JP Z,LBB82              ; Continue menu item
  CP $52
  JP Z,LBBEC              ; Info menu item
  CP $5E
  JP Z,LBF64              ; Credits menu item
  CP $6A
  JP Z,L9E51              ; Quit menu item
  JP LBA3D
;
; New menu item selected
LBAB2:
  LD A,(LDB73)
  OR A
  JP Z,LBADE
  CALL LB925
  CALL LAB28              ; Show small message popup
  LD HL,$2C07
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0A3             ; "OverWrite Current Game?|Alpha = Yes :: Clear = No"
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL L9FEA              ; Copy shadow screen to ZX screen
LBACE:
  CALL LA0F1              ; Scan keyboard
  CP $0F
  JP Z,LBA3D
  CP $30
  JP Z,LBADE
  JP LBACE
;
; New Game
;
LBADE:
  XOR A
  LD (LDCF7),A            ; Weapon slot
  LD (LDB7D),A            ; Get look/shoot switch value
  LD (LDBC7),A
  CALL LB9D6
  LD HL,$0000
  LD (LDBC3),HL
  LD (LDBC5),HL
  LD HL,$DB9C
  LD B,$22
LBADE_0:
  LD (HL),$00
  INC HL
  DJNZ LBADE_0
  LD HL,$DC5B
  LD B,$22
LBADE_1:
  LD (HL),$00
  INC HL
  DJNZ LBADE_1
  LD HL,$DB90
  LD B,$09
LBADE_2:
  LD (HL),$00
  INC HL
  DJNZ LBADE_2
  LD HL,$DCA2
  LD B,$48
LBADE_3:
  LD (HL),$00
  INC HL
  DJNZ LBADE_3
  LD HL,$DC96
  CALL LBC6B
  LD HL,$DC9A
  CALL LBC6B
  LD HL,$DC9E
  CALL LBC6B
  CALL LBC7D              ; Clear shadow screen and copy to A28F/A58F
  LD A,$44
  LD (LDC59),A
  LD (LDC85),A
  LD A,$0E
  LD (LDCF4),A            ; Line interval for text
  XOR A
  LD (LDCF3),A            ; Left margin size for text
  LD HL,$3A14
  LD ($86D7),HL
  LD HL,SE115             ; "In the Distant Future . . ."
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL LBA81
  CALL LBC7D              ; Clear shadow screen and copy to A28F/A58F
  CALL LBA81
  CALL LBC84              ; Set zero penRow/penCol
  LD HL,SE117             ; "'The Desolate' Space Cruiser|leaves orbit. ..."
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD HL,$72B6
  LD ($86D7),HL
  LD HL,SE0B9             ; String with arrow down sign
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL WaitAnyKey         ; Wait for any (was: Wait for Down key)
  CALL L9FCF              ; Clear shadow screen
  CALL LBC84              ; Set zero penRow/penCol
  LD HL,SE119             ; "The ship sustains heavy|damage. ..."
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL WaitAnyKey         ; Wait for any key (was: Wait for MODE key)
;
; Game start
;
LBB7E:
  XOR A
  LD (LDC85),A
; Continue menu item selected
LBB82:
  LD A,$01
  LD (LDB73),A
  LD A,$FF
  LD (LDC59),A
  CALL LB2D0              ; Delay
  JP L9DDD
;
LBB92:
  LD A,(LDB73)
  OR A                    ; do we have the game to continue?
  JP NZ,LBBA4
  LD A,(LDB8F)
  ADD A,-24               ; up two steps
  LD (LDB8F),A
  JP LBA3D
; Menu up step
LBBA4:
  LD A,(LDB8F)
  ADD A,-12
  LD (LDB8F),A
  JP LBA3D
LBBAF:
  LD A,(LDB73)
  OR A                    ; do we have the game to continue?
  JP NZ,LBBC1
  LD A,(LDB8F)
  ADD A,24                ; down two steps
  LD (LDB8F),A
  JP LBA3D
; Menu down step
LBBC1:
  LD A,(LDB8F)
  ADD A,12
  LD (LDB8F),A
  JP LBA3D
; Menu up key pressed
LBBCC:
  LD A,(LDB8F)
  CP $3A                  ; "New Game" selected?
  JP Z,LBA3D              ; yes => continue
  CP $52                  ; "Info" selected?
  JP Z,LBB92
  JP LBBA4
; Menu down key pressed
LBBDC:
  LD A,(LDB8F)
  CP $6A                  ; "Quit" selected?
  JP Z,LBA3D
  CP $3A                  ; "New Game" selected?
  JP Z,LBBAF
  JP LBBC1
;
; Info menu item, show Controls
;
LBBEC:
  LD BC,$0060             ; Counter = 96 bytes or tiles
  LD HL,LF329             ; Decode from - Encoded screen for Inventory popup
  LD DE,LDBF5             ; Where to decode
  CALL LB9F1              ; Decode the room
  LD HL,LDBF5
  CALL LB177              ; Display screen from tiles with Tileset #2
  LD A,$0A
  LD (LDCF3),A            ; Left margin size for text
  LD A,$0E
  LD (LDCF4),A            ; Line interval for text
  LD HL,$163C
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0A5             ; "- Controls -"
  CALL LBEDE              ; Load archived string and show message char-by-char
  LD HL,$240A
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE0A7             ; "2nd = Look / Shoot|Alpha = Inventory ..."
  CALL LBEDE              ; Load archived string and show message char-by-char
  CALL L9FEA              ; Copy shadow screen to ZX screen
  CALL LADA1              ; Wait for MODE key
  JP LBA3D                ; Return to Menu
;
LBC29:
  LD A,(LDC55)
  ADD A,L
  LD L,A
  RET
;
LBC2F:
  XOR A
  LD (LDC55),A
  RET
;
LBC34:
  LD B,$14
LBC36:
  CALL LB2D0              ; Delay
  DJNZ LBC36
  RET

LBC6B:
  ret ;STUB

LBC7D:
  CALL L9FCF              ; Clear shadow screen
  CALL L9FEA              ; Copy shadow screen to ZX screen
  RET

; Set zero penRow/penCol
;
LBC84:
  LD HL,$0000
  LD ($86D7),HL           ; Set penRow/penCol
  RET

; Draw string  on the screen using FontProto
;   HL = String address
LBEDE:
  ld a,(hl)
  inc hl
  or a
  ret z
  cp $7C	; '|'
  jr z,LBEDE_1
  push hl
  call DrawChar
  CALL LB2D0              ; Delay
  CALL L9FEA              ; Copy shadow screen to ZX screen
  pop hl
  jr LBEDE
LBEDE_1:
  PUSH BC
  LD A,($86D8)
  LD C,A
  LD A,(LDCF4)            ; Line interval for text
  ADD A,C
  LD ($86D8),A
  LD A,(LDCF3)            ; Get left margin size for text
  LD ($86D7),A
  POP BC
  jr LBEDE

; Set variables for Credits
;
LBF54:
  XOR A
  LD (LDD57),A
  LD (LDD56),A
  LD (LDC85),A
  LD A,$96
  LD (LDC59),A
  RET
;
; Credits menu item selected
LBF64:
  CALL L9FCF              ; Clear shadow screen
  CALL L9FEA              ; Copy shadow screen to ZX screen
  CALL LBF54
  JR LBF81
;
; The End
;
LBF6F:
  CALL L9FCF              ; Clear shadow screen
  CALL LBF54
  LD HL,$2E46
  LD ($86D7),HL           ; Set penRow/penCol
  LD HL,SE11F             ; "The End"
  CALL LBEDE              ; Load archived string and show message char-by-char
;
; Credits screen text scrolls up
;
LBF81:
  LD A,126                ; To draw new strings on the very bottom
  LD ($86D8),A            ; penRow
LBF686:
  JP LBF6F_4
LBF6F_2:
  call L9FEA              ; Copy shadow screen to ZX screen
  CALL LB2D0              ; Delay
LBF6F_3:
  CALL LA0F1              ; Scan keyboard
  or a                    ; any key pressed?
  jp nz,LBA3D             ; Return to main Menu
  CALL LBFD5              ; Scroll shadow screen up one line
;  CALL LBFEC
  JR LBF686
LBF6F_4:
  LD A,(LDD56)
  INC A
  LD (LDD56),A
  CP 12
  JP NZ,LBF6F_2
  XOR A
  LD (LDD56),A
  LD A,(LDD57)
  LD E,A
  LD D,$00
  LD HL,LDDF2
  ADD HL,DE
  LD A,(HL)
  LD ($86D7),A
  LD A,(LDD57)
  LD HL,LDD58
  CALL LADFF              ; Get address from table
  CALL DrawString         ; Draw string on shadow screen without any delays
  LD A,(LDD57)
  INC A                   ; increase the counter
  LD (LDD57),A
  CP $47
  JP NZ,LBF6F_3
  JP LBA3D                ; Return to main Menu
LBFD5:
  LD DE,ShadowScreen
  LD HL,ShadowScreen+24
  LD BC,137*24
  LDIR
  RET
LBFEC:
;  LD DE,$A2D7
;  LD HL,$9340
;  LD BC,$02B8
;  LDIR
  RET
