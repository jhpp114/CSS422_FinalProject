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
GetInputStartADR    
    LEA Mes_Start_Adr,  A1  ; ask start loc
    MOVE.B  #14, D0   
    Trap    #15     
    *BRA Invalid 
    LEA UserInput,  A1  
    MOVE.B  #2, D0  
    TRAP    #15 
    
    CLR.L   D2  
    CLR.L   D3  
    JSR ConvertInput        
    * Store user Input start address to A5
    MOVE.L  D3, StartLocData
    MOVE.L  StartLocData, A5  
    
        
GetInputEndADR  
    CLR.L   D2  
    CLR.L   D3  
    LEA Mes_End_Adr,    A1  
    MOVE.B  #13,    D0  
    TRAP    #15 
  
*   Subroutine
*_________________________________________________
ConvertInput        
       MOVE.B  (A1)+,  D2   
       JSR    ConvertASCII
       ADD.L    D2, D3        
       CMPI.B   #$0,    (A1)    
       BEQ GoBack
       *LSL.B    #4, D2     
       *LSR.B    #4, D2    
       LSL.L    #4, D3  
       *ADD.L    D2, D3 
       BRA  ConvertInput
GoBack
        RTS    
       *LSR.B    
ConvertASCII
        * 30~39 Number
        * 41~46 Cap Letter Till F
        * 61~66 Till f
        CMPI.B   #$40,   D2 * 40 is immeidate data use CMPI   
        BLT IsNumber * If less than 40 then execute 
        CMPI.B  #$41,   D2  * if not compare with 41 (A)    
        BGE IsLetter    *Bigger than or Equal to 41 then execute    
IsNumber
        *CMPI.B  #$30,   D2  
        *BLT Invalid 
        SUB.B   #$30,   D2     
        *BRA ConvertASCII  
        *CMP.W  #$0009,    D2  * Compare with 9 should be less or equal to be number      
        *BGE Invalid   * if Sub is bigger than 9 than invalid    
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
        SUB.B   #$57,   D2    
        RTS 
        * tomorrow continue (less than 39) then subtract 30
        
Invalid 
        LEA Extra_Space,    A1  
        MOVE.B  #14,    D0  
        TRAP    #15 
        
        LEA Mes_Invalid, A1 
        MOVE.B  #14,    D0  
        TRAP    #15 
        *JSR GoBack
*Finish 
*        RTS 
      
   

* Put variables and constants here
* Basic Print Message   
*____________________________________________________________________
CR  EQU $0D     *   Carriage Return
LF  EQU $0A     *   Line Feed

Mes_Welcome     DC.B    'Welcome to Disassembler Program', CR,  LF
                            DC.B    'Final Project for CSS 422',    CR, LF, 0
Mes_Start_Adr       DC.B    'Please Enter Starting Location: ', 0
Mes_End_Adr     DC.B    'Please Enter Ending Location: ', 0

Mes_Invalid DC.B   'The Address You provided is Invalid', CR,  LF
          DC.B 'Terminating Program.',  CR, LF, 0     
Extra_Space DC.B    CR, LF, 0   

* Define Storage
*_____________________________________________________________________
UserInput   DS.L    1   
StartLocData    DS.L    1   * store starting address
    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
