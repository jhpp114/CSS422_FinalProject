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
GetInput
    LEA Mes_Start_Adr,  A1  ; ask start loc
    MOVE.B  #14, D0   
    Trap    #15     
    
    LEA UserInput,  A1  
    MOVE.B  #2, D0  
    TRAP    #15 
    
    CLR.L   D0
        
   
*   Subroutine
*_________________________________________________
ConvertInput        
       MOVE.B  (A1)+,  D0
       JSR    ConvertASCII
       ADDA.L    D0, A2    
       LSL.B    #4, D0  
       *LSR.B    
ConvertASCII
        * 30~39 Number
        * 41~46 Cap Letter Till F
        * 61~66 Till f
        CMPI.B   #$40,   D0 * 40 is immeidate data use CMPI  
        BLT IsNumber * If less than 40 then execute 
        CMPI.B  #$41,   D0  * if not compare with 41 (A)    
        BGE IsLetter    *Bigger than or Equal to 41 then execute    
IsNumber
        SUB.B   #$30,   D0   
        *BRA ConvertASCII    
        RTS 
IsLetter
        * figure out either small leter or capital letter   
        CMPI.B  #$46,   D0  * Compare with small letter F         
        BLE CapitalLetter   * if less or equal to 46 than small letter     
        BRA SmallLetter     * else go to capital letter 
CapitalLetter   
        SUB.B   #$37,   D0  
SmallLetter  
        * tomorrow continue (less than 39) then subtract 30
    SIMHALT             ; halt simulator

* Put variables and constants here
* Basic Print Message   
*____________________________________________________________________
CR  EQU $0D     *   Carriage Return
LF  EQU $0A     *   Line Feed

Mes_Welcome     DC.B    'Welcome to Disassembler Program', CR,  LF
                            DC.B    'Final Project for CSS 422',    CR, LF, 0
Mes_Start_Adr       DC.B    'Please Enter Starting Location: ', 0
Mes_End_Adr     DC.B    'Please Enter Ending Location: ', 0


* Define Storage
*_____________________________________________________________________
UserInput   DS.L    1   
    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
