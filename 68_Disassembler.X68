*-----------------------------------------------------------
* Title      : 68k   Disassembler    
* Written by :
* Date       : 06/xx/2020    
* Description: Final Project    
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
*_______Basic Print Out Welcome Message__________   
    LEA Mes_Welcome,    A1  
    MOVE.B  #13,    D0  
    TRAP    #15 
    
*_______Get User Input____________________________
Get_Input_Start_ADR
    CLR.L   D2  
    CLR.L   D3
   
    LEA Mes_Start_Adr,  A1  ; ask start loc
    MOVE.B  #14, D0   
    Trap    #15     
    LEA UserInput,  A1  ;   get user input  
    MOVE.B  #2, D0  
    TRAP    #15 
 
    JSR ConvertInput        
    * check if the address is odd then throw error just read right bit  
    *ANDI.B  #1, D3  
    BTST #0,    D3 * is Even?  
    BNE Invalid_Adr_Not_Even  * Not even then go to invalid        
    
    * Store user Input start address to A5
    MOVE.L  D3, StartLocData
    MOVE.L  StartLocData, A5  
    
*_________Check Start Adr is Even Number__________________

        
Get_Input_End_ADR  
    CLR.L   D2  
    CLR.L   D3  
    
    LEA Mes_End_Adr,    A1  ;   ask ending loc  
    MOVE.B  #14,    D0       
    TRAP    #15 
    
    LEA EndLocData, A1  ;   get user input  
    MOVE.B  #2, D0  
    Trap    #15 
 
    JSR ConvertInput    
    * check if the address is odd then throw error just read right bit 
    BTST    #0, D3  
    BNE Invalid_Adr_Not_Even    
    * Store user Input start address to A6  
    MOVE.L  D3, EndLocData
    MOVE.L  EndLocData, A6  
    
*________________________________________________________   
*   Compare Starting Address and End Address see if it make sense       
Check_Input_Address
    CLR.L   D2  * clr out before use it 
    CLR.L   D3  * clr out before use it 
    MOVE.L  A5, D2  * move starting adr to d2 to check   
    MOVE.L  A6, D3  * move ending adr to d3 to check    
    CMP.L   D3, D2  * end address is not bigger than starting addr and address same? Error  
    BGE Invalid_Starting_Ending_Adr
    
    *___________Clear All Unnecessary register____________________________  
    CLR.L   D2 
    CLR.L   D3  
    CLR.L   D0  *  clear d0 before use it in disassemble
    CLR.L   D1  
    MOVE.L  #$00000000, A1  
    MOVE.L  #$00000000, A2    
    MOVE.L  #$00000000, A3    
    MOVE.L  #$00000000, A4    
    
    *BRA Finish  
    
*_______End of User Input Adr______________________________ 

    JSR Print_Cur_Addr
    LEA ProgramEnd, A2  * A2    store   program end 
    JSR Disassemble

*_______Start of reading machine code______________________

Disassemble                     * while A5 is less than A6
        CLR.L   D1      

        MOVE.L A5, D0
        CMP.L A6, D0
        BGE OUTPUT_RESULT
        
        MOVE.B (A5), D1        * read a byte from from A5, store to D1. This contains opcode
        
        *valid opcode bits cases: 10-EF
        CMP.B #$10, D1     
        BLT    INVALID_OPCODE   * invalid, need to move on to the next word
        
        CMP.B  #$3F, D1          * 0001 - 0011 -> -> 10 - 3F -> MOVE, MOVEA            * 
        BLE    MOVEMOVEA
        
        CMP.B  #$4F, D1          * 0100 -> 40 - 4F -> MOVEM, LEA, JSR, RTS
        BLE MOVEM_LEA_JSR_RTS
        
        CMP.B #$6F, D1           * 0110 -> 50 - 5F -> BCC (note it should not be 5F)
        BLE _BXX  
        
        CMP.B #$80, D1           * 60 - 7F invalid
        BLT    INVALID_OPCODE    * invalid, need to move on to the next word

        
        CMP.B #$8F, D1           * 1000 -> 80 - 8F -> OR
        BLE _OR
        
        CMP.B #$9F, D1           * 1001 -> 90 - 9F -> SUB
        BLE _SUB
        
        CMP.B #$B0, D1           * A0 - AF invalid
        BLT    INVALID_OPCODE    * invalid, need to move on to the next word

        CMP.B #$BF, D1           * 1011 -> B0 - BF -> CMP
        BLE _CMP
        
        CMP.B #$CF, D1           * 1100 -> C0- CF -> AND
        BLE _AND
        
        CMP.B #$DF, D1           * 1101 -> D0 - DF -> ADD
        BLE _ADD
        
        CMP.B #$EF, D1           * 1110 -> E0 - EF -> LSL, ASR
        BLE _LSL_ASR
        
        BRA INVALID_OPCODE
        
INVALID_OPCODE                   * skip to the next word
        
        ADDA #$2, A5
        BRA Disassemble 
        
* for all below methods,      

*___________________________________________________________________________________
* start of get EA
* precondition: A5 points to the first byte of the current machine code, D1 contains the first byte of the command      
*_____________________________________________________________________________________  
MOVEMOVEA
    LSL.L  #8, D1 
    ADDA #1, A5
    MOVE.B (A5)+, D1            * full opcode word in D1
    * clear out before use  
    CLR.L   D2      
    CLR.L   D3  
    CLR.L   D4  
    CLR.L   D5  

    MOVE.W  D1, D2              * copy D1 to D2, for dest mode
    MOVE.W  D1, D3              * copy D1 to D3, for dest register
    MOVE.W  D1, D4              * copy D1 to D4, for src mode
    MOVE.W  D1, D5              * copy D1 to D5, for src register
  
    LSL.W  #7,  D2   
    LSR.W  #8,  D2                     
    LSR.W  #5,  D2              * now D2 in binary: 0000 0000 0000 0000 0000 0000 0000 0xxx, xxx is dest mode

    LSL.W  #4,  D3              
    LSR.W  #8,  D3                     
    LSR.W  #5,  D3             * now D3 is 0000 0000 0000 0000 0000 0000 0000 0xxx, xxx is dest register
    
    LSL.W  #8,  D4 
    LSL.W  #2,  D4             
    LSR.W  #8,  D4                     
    LSR.W  #5,  D4              * now D4 is 0000 0000 0000 0000 0000 0000 0000 0xxx, xxx is src mode
    
    LSL.W  #8,  D5  
    LSL.W  #5,  D5
    LSR.W  #8,  D5               
    LSR.W  #5,  D5              * now D5 is 0000 0000 0000 0000 0000 0000 0000 0xxx, xxx is src register
    
MOVEMOVEA_OUTPUT              * condition: D1 contains size (0000 0000 0000 00xx), D2 contains Dest mode, D3 contains dest register, D4 contains src mode, D5 contains src register    
    CMP.W #5,   D2
    BEQ   INVALID_OPCODE
    
    CMP.W #1,   D2
    BEQ   MOVEA_OUTPUT

MOVE_OUTPUT    
    LEA MOVE_VALUE,  A1         * print "MOVE"    
    MOVE.B  #14, D0   
    Trap    #15 
   
    LEA MOVEMOVEA_SRC, A0
    CMP.B   #3, D1
    BEQ     PRINTWORD
    CMP.B   #2, D1
    BEQ     PRINTLONGWORD
    JMP     PRINTBYTE
    
    
MOVEA_OUTPUT    
        
    LEA MOVEA_VALUE,  A1        * print "MOVEA"     
    MOVE.B  #14, D0   
    Trap    #15    
    LEA MOVEMOVEA_SRC, A0
    CMP.B   #3, D1
    BEQ     PRINTWORD
    CMP.B   #2, D1
    BEQ     PRINTLONGWORD
    JMP     INVALID_OPCODE

    
MOVEMOVEA_SRC 
    CMP.B #0, D4
    BEQ M_PRINT_DATA_REG 
       
    CMP.B #1, D4 
    BEQ M_PRINT_ADDRESS_REG

    CMP.B  #2, D4
    BEQ M_PRINT_PAREN_ADDRESS_REG
    
    CMP.B  #3, D4
    BEQ M_PRINT_INCRE_ADDRESS_REG

    CMP.W #$4, D4
    BEQ M_PRINT_DECRE_ADDRESS_REG
    
    CMP.W #$7,D4
    BEQ M_PRINT_ABSOLUTE_IMMEDIATE_DATA
    
    BRA INVALID_OPCODE

M_PRINT_DATA_REG
    JSR PRINT_DATA_REG
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15
    LEA     COMMA,  A1      * print comma    
    MOVE.B  #14, D0   
    Trap    #15

    BRA MOVEMOVEA_DEST

M_PRINT_ADDRESS_REG
    JSR PRINT_ADDRESS_REG
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15
    LEA     COMMA,  A1      * print comma    
    MOVE.B  #14, D0   
    Trap    #15

    BRA MOVEMOVEA_DEST
    
M_PRINT_PAREN_ADDRESS_REG
    JSR PRINT_PAREN_ADDRESS_REG
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15
    LEA     COMMA,  A1      * print comma    
    MOVE.B  #14, D0   
    Trap    #15

    BRA MOVEMOVEA_DEST
    
M_PRINT_INCRE_ADDRESS_REG
    JSR PRINT_INCRE_ADDRESS_REG
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15
     LEA     COMMA,  A1     * print comma    
    MOVE.B  #14, D0   
    Trap    #15

    BRA MOVEMOVEA_DEST
    
M_PRINT_DECRE_ADDRESS_REG
    JSR PRINT_DECRE_ADDRESS_REG
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15
     LEA     COMMA,  A1     * print comma    
    MOVE.B  #14, D0   
    Trap    #15

    BRA MOVEMOVEA_DEST    
    
M_PRINT_ABSOLUTE_IMMEDIATE_DATA                    
    CMP.B #4, D5
    BEQ M_PRINT_IMMEDIATE_DATA
    
    CMP.B #0, D5
    BEQ M_PRINT_ABSOLUTE_ADDRESS
    CMP.B #1, D5
    BEQ M_PRINT_ABSOLUTE_ADDRESS
    
    BRA INVALID_OPCODE
    
M_PRINT_ABSOLUTE_ADDRESS
    JSR PRINT_ABSOLUTE_ADDRESS
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15
    LEA     COMMA,  A1      * print comma    
    MOVE.B  #14, D0   
    Trap    #15

    BRA MOVEMOVEA_DEST

    
M_PRINT_IMMEDIATE_DATA               
    JSR PRINT_IMMEDIATE_DATA
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15   
     LEA     COMMA,  A1     * print comma    
    MOVE.B  #14, D0   
    Trap    #15

    BRA MOVEMOVEA_DEST
                   
* D5 contains the register number    
PRINT_IMMEDIATE_DATA 
    *if size is byte or word
    CMP.B   #2, D1
    BEQ     READLONGWORD
    
    *if size is byte or word
    MOVE.W  (A5)+, (A2)+
    RTS
    
    *if size is long word
READLONGWORD    
    MOVE.L  (A5)+, (A2)+
    RTS
    
PRINT_ABSOLUTE_ADDRESS    
    CMP.B #0, D5
    BNE LONGWORD_ADDR
    MOVE.W  (A5)+, (A2)+
    RTS
LONGWORD_ADDR
    MOVE.L  (A5)+, (A2)+
    RTS
    
PRINT_DATA_REG
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    
    LEA D,  A1              * print "D"     
    MOVE.B  #14, D0   
    Trap    #15    

    MOVE.B  D5,  D1         *print register number
    ADD.B   #$30, D1  
    MOVE.B  #6, D0   
    Trap    #15 
    RTS
    
PRINT_ADDRESS_REG
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    
    LEA A,  A1              * print "A"     
    MOVE.B  #14, D0   
    Trap    #15    

    MOVE.B  D5,  D1         *print register number
    ADD.B   #$30, D1  
    MOVE.B  #6, D0   
    Trap    #15 
    RTS

PRINT_PAREN_ADDRESS_REG
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
        
    LEA OPENING_BRACKET,  A1              * print "("     
    MOVE.B  #14, D0   
    Trap    #15    
    
    LEA A,  A1              * print "A"     
    MOVE.B  #14, D0   
    Trap    #15    
    
    LEA CLOSING_BRACKET,  A1              * print ")"     
    MOVE.B  #14, D0   
    Trap    #15    

    MOVE.B  D5,  D1         *print register number
    ADD.B   #$30, D1  
    MOVE.B  #6, D0   
    Trap    #15 
    RTS

PRINT_INCRE_ADDRESS_REG
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
        
    LEA OPENING_BRACKET,  A1              * print "("     
    MOVE.B  #14, D0   
    Trap    #15    
    
    LEA A,  A1                         * print "A"     
    MOVE.B  #14, D0   
    Trap    #15    
    
     MOVE.B  D5,  D1         *print register number
    ADD.B   #$30, D1  
    MOVE.B  #6, D0   
    Trap    #15 
    
    LEA CLOSING_BRACKET,  A1              * print ")"     
    MOVE.B  #14, D0   
    Trap    #15    
    
    LEA PLUS_SIGN,  A1              * print "+"     
    MOVE.B  #14, D0   
    Trap    #15    

   
    RTS
    

PRINT_DECRE_ADDRESS_REG
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    
        
    LEA MINUS_SIGN,  A1              * print "-"     
    MOVE.B  #14, D0   
    Trap    #15    
    
    LEA OPENING_BRACKET,  A1              * print "("     
    MOVE.B  #14, D0   
    Trap    #15    
    
    LEA A,  A1                         * print "A"     
    MOVE.B  #14, D0   
    Trap    #15  
    
    MOVE.B  D5,  D1         *print register number
    ADD.B   #$30, D1  
    MOVE.B  #6, D0   
    Trap    #15 
    
    LEA CLOSING_BRACKET,  A1              * print ")"     
    MOVE.B  #14, D0   
    Trap    #15    


    RTS
        
MOVEMOVEA_DEST
    MOVE.L D2, D4      
    MOVE.L D3, D5
    CMP.B #$000, D4
    BEQ MD_PRINT_DATA_REG 
       
    CMP.B  #$010, D4
    BEQ MD_PRINT_PAREN_ADDRESS_REG
    
    CMP.B  #$011, D4
    BEQ MD_PRINT_INCRE_ADDRESS_REG

    CMP.W #$100, D4
    BEQ MD_PRINT_DECRE_ADDRESS_REG
    
    CMP.W #$111,D4
    BEQ MD_PRINT_ABSOLUTE_IMMEDIATE_DATA
    
    BRA INVALID_OPCODE
MD_PRINT_DATA_REG
    JSR PRINT_DATA_REG
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15
    BRA     CHECK_INPUT_ADDRESS
MD_PRINT_ADDRESS_REG
    JSR PRINT_ADDRESS_REG
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15

    BRA     CHECK_INPUT_ADDRESS    
MD_PRINT_PAREN_ADDRESS_REG
    JSR PRINT_PAREN_ADDRESS_REG
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15

    BRA     CHECK_INPUT_ADDRESS    
MD_PRINT_INCRE_ADDRESS_REG
    JSR PRINT_PAREN_ADDRESS_REG
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15

    BRA     CHECK_INPUT_ADDRESS    
MD_PRINT_DECRE_ADDRESS_REG
    JSR PRINT_PAREN_ADDRESS_REG
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15

    BRA     CHECK_INPUT_ADDRESS    
MD_PRINT_ABSOLUTE_IMMEDIATE_DATA                    
    CMP.B #4, D5
    BEQ M_PRINT_IMMEDIATE_DATA
    
    CMP.B #0, D5
    BEQ M_PRINT_ABSOLUTE_ADDRESS
    CMP.B #1, D5
    BEQ M_PRINT_ABSOLUTE_ADDRESS
    
    BRA     CHECK_INPUT_ADDRESS    
MD_PRINT_ABSOLUTE_ADDRESS
    JSR PRINT_ABSOLUTE_ADDRESS
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15
    BRA     CHECK_INPUT_ADDRESS

    
MD_PRINT_IMMEDIATE_DATA               
    JSR PRINT_IMMEDIATE_DATA
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15   
    BRA MOVEMOVEA_DEST

                  
    *CMP.B #$1F                  * size Byte
    *BLE   MOVEMOVEA_B
      
    *CMP.B #$2F                  *size Word
    *BLE   MOVEMOVEA_W
    
    *CMP.B #$2F                  *size Longword+++
    *BLE   MOVEMOVEA_L
    
    
MOVEM_LEA_JSR_RTS
*____________________BCC BLE BGT____________________________    
_BXX    
* clear out before use
    CLR.L   D0  
    CLR.L   D2      
    CLR.L   D3  
    CLR.L   D5  
    CLR.L   D6  
    CLR.L   D7  
* clear out before usewed
    MOVE.W  (A5)+,   D2  * load full opcode BCC, BGT, BLE same so D2 has 006x      
    MOVE.W  D2, D6    
    ROL.W   #4, D6  
    *ANDI.W  #$000F, D6  
    *MULU    #8, D6  
    
    MOVE.W  D6, D5    
    ROL.W   #4, D6  
    MOVE.W  D6, D5  
    ANDI.W  #$000F, D6  
    CMP.W   #$F,    D6         
    BEQ _BLE
    CMP.W   #$E,    D6  
    BEQ _BGT
    CMP.W   #$4,    D6  
    BEQ _BCC
    BRA INVALID_OPCODE
        
_BCC
    MOVE.B  #'B',   (A2)+   * Store BCC at the end of this program  
    MOVE.B  #'C',   (A2)+   
    MOVE.B  #'C',   (A2)+  
    MOVE.B  #' ',   (A2)+   * little space
    MOVE.B  #' ',   (A2)+   * little space
    BRA BXX_Displacement 
 
    
_BLE
    
_BGT

BXX_Displacement    
    MOVE.W  D2, D6  *   Load full memory 
    MOVE.L  A5, D5  *   Load current starting adr from user
    MOVE.B  #0, D1  *   set up counter 0 to 8   
    MOVE.B  #8, D2  
    ANDI.W  #$00FF, D6  *   00XX
    CMP.W   #$00,   D6  *   if 00 then it should be 8bit displacement   
    BEQ BXX_DISPLACEMENT_WORD      
    CMP.W   #$FF,   D6  *   if  FF then it should be 16 bits displacement   
    BEQ BXX_DISPLACEMENT_LONG   
    BRA BXX_DISPLACEMENT_8Bit   *   rest of them are 8 bit  
  
   
BXX_DISPLACEMENT_8Bit
    MOVE.W  D2, D6  *   Load full memory    
    BRA Finish  *   End for now 

BXX_DISPLACEMENT_WORD

BXX_DISPLACEMENT_LONG   



*___________________END OF B brothers__________________________ 
_OR
_SUB
_CMP
_AND
_ADD
_LSL_ASR
*------------------------------------------------
* start to print final result
*------------------------------------------------
OUTPUT_RESULT
*   Subroutine
*_________________________________________________
*_______PRINT CURRENT ADDRESS______________________________ 
Print_Cur_Addr
    MOVE.L  A5, D2 * move staring addr to d2
    MOVE.B  #0, D5  * counter to read all hex
    MOVE.B  #8, D6  * total number of address is 8 bits just to set up to compare with counter    
Convert_Hex_to_Ascii
    CMP.B   D5, D6  * compare the couter
    BNE Smaller *   Set counter to read 4
    MOVE.B  #6, D0  
    MOVE.B  #32,    D1  
    RTS 
Smaller
    MOVE.B  #0, D3  
    MOVE.B  #4, D4  
Read_Each_Char              *   Read Each character 
    CMP.B   D3, D4  
    BEQ Save_Char   
    LSL.L   #1, D2  
    BCC Append_Zero 
    ADDI.B  #1, D1  
    BRA Next_Bit  

Append_Zero 
    ADDI.B  #0, D1  
Next_Bit
    ADDI.B  #1, D3  
    LSL.L   #1, D1  
    BRA Read_Each_Char  
Save_Char
    LSR.L   #1, D1  
    CMP.B   #$A,    D1  
    BLT   Convert_Ascii_to_Hex_DisplayAdr 
    ADDI.B  #$37,   D1  
    BRA   Next_HEX

Convert_Ascii_to_Hex_DisplayAdr 
    ADDI.B  #$30,   D1  
Next_HEX
    ADDI.B  #1, D5  
    MOVE.B  #6, D0  
    TRAP    #15 
    CLR.L   D1  
    BRA Convert_Hex_to_Ascii

ConvertInput        
       MOVE.B  (A1)+,  D2   
       JSR    ConvertASCII
       ADD.L    D2, D3  * copy D2 to D3 
       *ADDA.L   D3, A4      
       CMPI.B   #$0,    (A1)    
       BEQ GoBack
       LSL.L    #4, D3  * Make room for next byte  
        
       BRA  ConvertInput
GoBack  
        *MOVEA.L D3, A4  
        RTS    
ConvertASCII
        CMPI.B  #$30,   D2     * Any input that are less than 30 is error    
        BLT Input_Error_Handler
        CMPI.B  #$67,   D2    * Any input that are more or equal to 67 (g) is error 
        BGE Input_Error_Handler  
        * 30~39 Number
        * 41~46 Cap Letter Till F
        * 61~66 Till f
        CMPI.B   #$39,   D2 * 40 is immeidate data use CMPI   
        BLE IsNumber * If less than 40 then execute  
        *________________________________________________
        CMPI.B  #$40,   D2  *   if it is between 3A (:) and 40 (@) throw Error   
        BLE Input_Error_Handler
        *_______________________________________________
        CMPI.B  #$41,   D2  * if not compare with 41 (A)    
        BGE IsLetter    *Bigger than or Equal to 41 then execute    
IsNumber
        SUB.B   #$30,   D2        
        RTS 
IsLetter
        * figure out either small leter or capital letter   
        CMPI.B  #$46,   D2  * Compare with small letter F            
        BLE CapitalLetter   * if less or equal to 46 than small letter     
        BRA SmallLetter     * else go to capital letter 
CapitalLetter   
        SUB.B   #$37,   D2   * 46 - 37 = F
        RTS 
SmallLetter  
        CMPI.B  #$60,   D2  * if less than or equal to 60 (') throw Error   
        BLE Input_Error_Handler
        SUB.B   #$57,   D2    
        RTS
PRINTBYTE
    LEA BYTE_SUFFIX,  A1        * print ".B"     
    MOVE.B  #14, D0   
    Trap    #15
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15
    
    JMP     (A0)    
PRINTWORD
    LEA WORD_SUFFIX,  A1        * print ".W"     
    MOVE.B  #14, D0   
    Trap    #15
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15

    JMP     (A0)


PRINTLONGWORD
    LEA LONG_SUFFIX,  A1        * print ".L"     
    MOVE.B  #14, D0   
    Trap    #15    
    LEA     TAB,  A1        * print tab     
    MOVE.B  #14, D0   
    Trap    #15
    JMP     (A0)
    

  
*_________________________Error Handle___________________________________      
Input_Error_Handler
        BRA Invalid 
        
Invalid 
        LEA Extra_Space,    A1  
        MOVE.B  #14,    D0  
        TRAP    #15 
        LEA Mes_Invalid, A1 
        MOVE.B  #14,    D0  
        TRAP    #15 
        BRA  Get_Input_Start_ADR    
        
Invalid_Starting_Ending_Adr
        LEA  Extra_Space,   A1  
        MOVE.B  #14,    D0  
        TRAP    #15 
        LEA Mes_Starting_Ending_Adr_Error,  A1  
        MOVE.B  #14,    D0  
        TRAP    #15 
        BRA Get_Input_Start_ADR
         
Invalid_Adr_Not_Even
        LEA Extra_Space,    A1  
        MOVE.B  #14,    D0  
        TRAP    #15 
        LEA Mes_EvenNumber_Error,   A1  
        MOVE.B  #14,    D0  
        TRAP    #15 
        BRA Get_Input_Start_ADR 
    

    
Finish  SIMHALT             ; halt simulator
        

* Put variables and constants here
* Basic Print Message   
*____________________________________________________________________
CR  EQU $0D     *   Carriage Return
LF  EQU $0A     *   Line Feed
Extra_Space DC.B    CR, LF, 0 
Mes_Welcome     DC.B    'Welcome to Disassembler Program', CR,  LF
                            DC.B    'Final Project for CSS 422',    CR, LF, 0
Mes_Start_Adr       DC.B    'Please Enter Starting Location: $', 0
Mes_End_Adr     DC.B    'Please Enter Ending Location: $', 0

Mes_Invalid DC.B   'The Address You provided is Invalid', CR,  LF,  0   
            
Mes_EvenNumber_Error    DC.B    'The Address You provided is not even ending number',  CR, LF, 0
Mes_Starting_Ending_Adr_Error   DC.B    'Your Starting Address is bigger or equal than Ending Adrress', CR, LF, 0   

RTS_VALUE               DC.W        'RTS',0     * Requested
JSR_VALUE               DC.W        'JSR',0     * Requested
LEA_VALUE               DC.W        'LEA',0     * Requested
NEG_VALUE               DC.W        'NEG',0     * Requested
CMPI_VALUE              DC.W        'CMPI',0    * Requested
CMP_VALUE               DC.W        'CMP',0     * Requested
SUB_VALUE               DC.W        'SUB',0     * Requested
SUBQ_VALUE              DC.W        'SUBQ',0    * Requested
DIVS_VALUE              DC.W        'DIVS',0    * Requested
BRA_VALUE               DC.W        'BRA',0     * Requested
MULS_VALUE              DC.W        'MULS',0    * Requested
ADD_VALUE               DC.W        'ADD',0     * Requested
ADDA_VALUE              DC.W        'ADDA',0    * Requested
AS_VALUE                DC.W        'AS',0      * Requested ASR, ASL
LS_VALUE                DC.W        'LS',0      * Requested LSR, LSL
RO_VALUE                DC.W        'RO',0      * Requested ROR, ROL
BCLR_VALUE              DC.W        'BCLR',0    * Unfinished
LEFT_DIRECTION          DC.W        'L',0
RIGHT_DIRECTION         DC.W        'R',0
OR_VALUE                DC.W        'OR',0      * Extra
MOVEA_VALUE             DC.W        'MOVEA',0   * Requested
MOVE_VALUE              DC.W        'MOVE',0    * Requested
MOVEQ_VALUE             DC.W        'MOVEQ',0   * Extra
DATA_VALUE              DC.W        'DATA',0
HIGHER_VALUE            DC.W        'HI',0
LOWER_OR_SAME_VALUE     DC.W        'LS',0
CARRY_CLEAR_VALUE       DC.W        'CC',0
NOT_EQUAL_VALUE         DC.W        'NE',0
EQUAL_VALUE             DC.W        'EQ',0
OVERFLOW_CLEAR_VALUE    DC.W        'VC',0 *
OVERFLOW_SET_VALUE      DC.W        'VS',0
PLUS_VALUE              DC.W        'PL',0
MINUS_VALUE             DC.W        'MI',0
GREATER_OR_EQUAL_VALUE  DC.W        'GE',0 *
LESS_THAN_VALUE         DC.W        'LT',0 *
GREATER_THAN_VALUE      DC.W        'GT',0
LESS_OR_EQUAL_VALUE     DC.W        'LE',0
CARRY_SET_VALUE         DC.W        'CS',0 *
SR_VALUE                DC.W        'SR',0
CCR_VALUE               DC.W        'CCR',0
OPENING_BRACKET         DC.W        '(',0
CLOSING_BRACKET         DC.W        ')',0
PLUS_SIGN               DC.W        '+',0
MINUS_SIGN              DC.W        '-',0
DATA_REGISTER           DC.W        'D',0
ADDRESS_REGISTER        DC.W        'A',0
COMMA                   DC.W        ',',0
SPACE                   DC.W        ' ',0
BINARY_SYMBOL           DC.W        '%',0
HEX_SYMBOL              DC.W        '$',0
IMMEDIATE_DATA_SYMBOL   DC.W        '#',0
BYTE_SUFFIX             DC.W        '.B',0
WORD_SUFFIX             DC.W        '.W',0
LONG_SUFFIX             DC.W        '.L',0
ZERO                    DC.W        '0',0
ONE                     DC.W        '1',0
TWO                     DC.W        '2',0
THREE                   DC.W        '3',0
FOUR                    DC.W        '4',0
FIVE                    DC.W        '5',0
SIX                     DC.W        '6',0
SEVEN                   DC.W        '7',0
EIGHT                   DC.W        '8',0
NINE                    DC.W        '9',0
A                       DC.W        'A',0
B                       DC.W        'B',0
C                       DC.W        'C',0
D                       DC.W        'D',0
E                       DC.W        'E',0
F                       DC.W        'F',0
TAB                     DC.W        '  ',0

   
*_______________________________________________________________________________
* Variables to check if it goes to correct area
Move_Print  DC.B    'MOVE', 0   
BCC_Print   DC.B    'BCC',  0   

* Define Storage
*_____________________________________________________________________
UserInput   DS.L    1   
StartLocData    DS.L    1   * store starting address
EndLocData  DS.L    1   *   Store ending address    
ProgramEnd DS.L 1   *   variable to store location where this program ends
    END    START        ; last line of source













*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
