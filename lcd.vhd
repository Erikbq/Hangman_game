------------------------------------------------------------------ 
-- lcd.vhd -- general LCD testing program 
------------------------------------------------------------------ 
-- Author -- Dan Pederson, 2004 
-- -- Barron Barnett, 2004 
-- -- Jacob Beck, 2006 
------------------------------------------------------------------ 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 


entity lcd is 
Port ( LCD_DB: out std_logic_vector(7 downto 0); --DB( 7 through 0) 
RS:out std_logic; --WE 
RW:out std_logic; --ADR(0) 
CLK:in std_logic; --GCLK2 
--ADR1:out std_logic; --ADR(1) 
--ADR2:out std_logic; --ADR(2) 
--CS:out std_logic; --CSC 
LCD_E:out std_logic; --LCD_E 
rst:in std_logic; --BTN 
--rdone: out std_logic); --WriteDone output to work with DI05 test 
ps2d, ps2c: in std_logic; 
tecla:out std_logic_vector(7 downto 0)); 
end lcd; 

architecture Behavioral of lcd is 

------------------------------------------------------------------ 
-- Component Declarations 
------------------------------------------------------------------ 

component kb_code port ( 
clk, reset: in std_logic; 
ps2d, ps2c: in std_logic; 
rd_key_code: in std_logic; 
key_code: out std_logic_vector(7 downto 0); 
kb_buf_empty: out std_logic 
); 
end component kb_code; 

------------------------------------------------------------------ 
-- Local Type Declarations 
----------------------------------------------------------------- 
-- Symbolic names for all possible states of the state machines. 

--LCD control state machine 
type mstate is ( 
stFunctionSet, --Initialization states 
stDisplayCtrlSet, 
stDisplayClear, 
stPowerOn_Delay, --Delay states 
stFunctionSet_Delay, 
stDisplayCtrlSet_Delay, 
stDisplayClear_Delay, 
stInitDne, --Display charachters and perform standard operations 
stActWr, 
stCharDelay --Write delay for operations 
--stWait --Idle state 
); 

--Write control state machine 
type wstate is ( 
stRW, --set up RS and RW 
stEnable, --set up E 
stIdle --Write data on DB(0)-DB(7) 
); 


------------------------------------------------------------------ 
-- Signal Declarations and Constants 
------------------------------------------------------------------ 

signal clk_div_count : integer range 0 to 49 := 0; 
signal activateW:std_logic:= '0'; --Activate Write sequence 
signal count: unsigned (16 downto 0):= (others => '0'); --15 bit        
count variable for timing delays 
signal delayOK:std_logic:= '0'; --High when count has reached the 
right delay time 
signal oneUS_enable  : std_logic := '0'; 
signal stCur:mstate:= stPowerOn_Delay; --LCD control state machine 
signal stNext:mstate; 
signal stCurW:wstate:= stIdle; --Write control state machine 
signal stNextW:wstate; 
signal writeDone:std_logic:= '0'; --Command set finish 

signal rd_key_code:std_logic; 
signal key_read:std_logic_vector(7 downto 0); 
signal key_saved:std_logic_vector(7 downto 0); 
signal kb_empty:std_logic; 
signal contador:unsigned(3 downto 0):="1011"; 
signal gameover:std_logic:='0'; 

type LCD_CMDS_T is array(integer range 24 downto 0) of std_logic_vector 
(9 downto 0); 

signal certo:std_logic_vector(4 downto 0) := "00000"; 

signal LCD_CMDS : LCD_CMDS_T := ( 0 => "00"&X"3C", --Function Set 
1 => "00"&X"0C", --Display ON, Cursor OFF, Blink OFF 
2 => "00"&X"01", --Clear Display 
3 => "00"&X"02", --return home 

4 => "10"&X"4A", --J --------- V 
5 => "10"&X"4F", --O 
6 => "10"&X"47", --G --------- C 
7 => "10"&X"4F", --O --------- E 
8 => "10"&X"20", --SPACE 
9 => "10"&X"44", --D --------- G - P 
10 => "10"&X"41", --A --------- A - E 
11 => "10"&X"20", --SPACE ----- N - R 
12 => "10"&X"46", --F --------- H - D 
13 => "10"&X"4F", --O - E 
14 => "10"&X"52", --R --------- U - U 
15 => "10"&X"43", --C --------- SPACE 
16 => "10"&X"41", --A --------- SPACE 
17 => "00"&X"C0", --Select second line 
18 => "10"&X"5F", -- _ 
19 => "10"&X"5F", -- _ 
20 => "10"&X"5F", -- _ 
21 => "10"&X"5F", -- _ 
22 => "10"&X"5F", -- _ 
23 => "00"&X"CC", --Select 
24 => "10"&X"35" -- 5 
); 


signal lcd_cmd_ptr : integer range 0 to LCD_CMDS'HIGH + 1 := 0; 
begin 


leitura: kb_code PORT MAP (CLK, rst, ps2d, ps2c, rd_key_code, key_read, 
kb_empty); 


lendo: process (clk) 
begin 
if (clk'event and clk = '1') then 
if (kb_empty = '1') then 
rd_key_code <= '0'; 
elsif (kb_empty = '0') then 
tecla <= key_read; 
key_saved <= key_read; 
if ((gameover = '0') and (key_saved /= "01001101") and (key_saved /= 
"01000101") and (key_saved /= "01001110") and (key_saved /= "01000111") and ( 
key_saved /= "01001111")) then 
contador <= contador -1; 
end if; 
rd_key_code <= '1'; 
end if; 
end if; 
end process; 

certo(4) <= '1' when (key_saved = "01001101" and gameover = '0'); 
certo(3) <= '1' when (key_saved = "01000101" and gameover = '0'); 
certo(2) <= '1' when (key_saved = "01001110" and gameover = '0'); 
certo(1) <= '1' when (key_saved = "01000111" and gameover = '0'); 
certo(0) <= '1' when (key_saved = "01001111" and gameover = '0'); 

LCD_CMDS(18) <= "10"&X"4D" when (certo(4) = '1') else "10"&X"5F"; 
LCD_CMDS(19) <= "10"&X"45" when (certo(3) = '1') else "10"&X"5F"; 
LCD_CMDS(20) <= "10"&X"4E" when (certo(2) = '1') else "10"&X"5F"; 
LCD_CMDS(21) <= "10"&X"47" when (certo(1) = '1') else "10"&X"5F"; 
LCD_CMDS(22) <= "10"&X"4F" when (certo(0) = '1') else "10"&X"5F"; 

LCD_CMDS(24) <= "10"&X"35" when (contador = 11) else 
"10"&X"35" when (contador = 10) else 
"10"&X"34" when (contador = 9) else 
"10"&X"34" when (contador = 8) else 
"10"&X"33" when (contador = 7) else 
"10"&X"33" when (contador = 6) else 
"10"&X"32" when (contador = 5) else 
"10"&X"32" when (contador = 4) else 
"10"&X"31" when (contador = 3) else 
"10"&X"31" when (contador = 2) else 
"10"&X"30" when (contador /= 2); 

gameover <= '1' when ((contador <= 2) or (certo = "11111")); 

LCD_CMDS(4) <= "10"&X"56" when (gameover='1') else "10"&X"4A"; 
LCD_CMDS(6) <= "10"&X"43" when (gameover='1') else "10"&X"47"; 
LCD_CMDS(7) <= "10"&X"45" when (gameover='1') else "10"&X"4F"; 
LCD_CMDS(14) <= "10"&X"55" when (gameover='1') else "10"&X"52"; 
LCD_CMDS(15) <= "10"&X"20" when (gameover='1') else "10"&X"43"; 
LCD_CMDS(16) <= "10"&X"20" when (gameover='1') else "10"&X"41"; 

LCD_CMDS(9) <= "10"&X"47" when (gameover='1' and LCD_CMDS(24) /= "10"&X"30") 
else 
"10"&X"50" when (gameover='1' and LCD_CMDS(24) = "10"&X"30"); 
LCD_CMDS(10) <= "10"&X"41" when (gameover='1' and LCD_CMDS(24) /= "10"&X"30") 
else 
"10"&X"45" when (gameover='1' and LCD_CMDS(24) = "10"&X"30"); 
LCD_CMDS(11) <= "10"&X"4E" when (gameover='1' and LCD_CMDS(24) /= "10"&X"30") 
else 
"10"&X"52" when (gameover='1' and LCD_CMDS(24) = "10"&X"30"); 
LCD_CMDS(12) <= "10"&X"48" when (gameover='1' and LCD_CMDS(24) /= "10"&X"30") 
else 
"10"&X"44" when (gameover='1' and LCD_CMDS(24) = "10"&X"30"); 
LCD_CMDS(13) <= "10"&X"45" when (gameover='1' and LCD_CMDS(24) = "10"&X"30"); 

process (CLK)
begin
  if (CLK'event and CLK = '1') then
    if (clk_div_count = 49) then
      oneUS_enable  <= '1';
      clk_div_count <= 0;
    else
      oneUS_enable  <= '0';
      clk_div_count <= clk_div_count + 1;
    end if;
  end if;
end process;

-- This process incriments the count variable unless delayOK = 1. 
process (CLK) 
begin 
  if (CLK'event and CLK = '1') then
    if (oneUS_enable = '1') then -- Ação só ocorre quando o enable está ativo
      if delayOK = '1' then 
        count <= (others => '0'); -- Forma mais segura de zerar
      else 
        count <= count + 1; 
      end if; 
    end if;
  end if; 
end process;

--This goes high when all commands have been run 
writeDone <= '1' when (lcd_cmd_ptr = LCD_CMDS'HIGH + 1) 
else '0'; 
--rdone <= '1' when stCur = stWait else '0'; 
--Increments the pointer so the statemachine goes through the commands 
process (CLK, rst) 
begin 
  if (rst = '1') then
    lcd_cmd_ptr <= 0;
  elsif (CLK'event and CLK = '1') then 
    if (oneUS_enable = '1') then
      if ((stNext = stInitDne or stNext = stDisplayCtrlSet or stNext = stDisplayClear) and writeDone = '0') then 
        lcd_cmd_ptr <= lcd_cmd_ptr + 1;
      elsif stCur = stPowerOn_Delay or stNext = stPowerOn_Delay then 
        lcd_cmd_ptr <= 0; 
      elsif writeDone = '1' then 
        lcd_cmd_ptr <= 3;
      end if; 
    end if;
  end if; 
end process;

-- Determines when count has gotten to the right number, depending on the 
state. 

delayOK <= '1' when ((stCur = stPowerOn_Delay and count = "00100111001010010") 
or --20050 
(stCur = stFunctionSet_Delay and count = "00000000000110010") or --50 
(stCur = stDisplayCtrlSet_Delay and count = "00000000000110010") or --50 
(stCur = stDisplayClear_Delay and count = "00000011001000000") or --1600 
(stCur = stCharDelay and count = "00000000000100101")); --37
Delay for character writes and shifts 
--(stCur = stCharDelay and count = "00000000000100101")) --37 This 
is proper delay between writes to ram. 
else '0'; 

-- This process runs the LCD status state machine 
process (CLK, rst) 
begin 
  if (rst = '1') then 
    stCur <= stPowerOn_Delay;
  elsif (CLK'event and CLK = '1') then 
    if (oneUS_enable = '1') then -- Ação só ocorre quando o enable está ativo
      stCur <= stNext; 
    end if;
  end if; 
end process;


-- This process generates the sequence of outputs needed to initialize and 
write 
to the LCD screen 
process (stCur, delayOK, writeDone, lcd_cmd_ptr) 
begin 

case stCur is 

-- Delays the state machine for 20ms which is needed for proper startup. 
when stPowerOn_Delay => 
if delayOK = '1' then 
stNext <= stFunctionSet; 
else 
stNext <= stPowerOn_Delay; 
end if; 
RS <= LCD_CMDS(lcd_cmd_ptr)(9); 
RW <= LCD_CMDS(lcd_cmd_ptr)(8); 
LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0); 
activateW <= '0'; 

-- This issuse the function set to the LCD as follows 
-- 8 bit data length, 2 lines, font is 5x8. 
when stFunctionSet => 
RS <= LCD_CMDS(lcd_cmd_ptr)(9); 
 
RW <= LCD_CMDS(lcd_cmd_ptr)(8); 
LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0); 
activateW <= '1'; 
stNext <= stFunctionSet_Delay; 

--Gives the proper delay of 37us between the function set and 
--the display control set. 
when stFunctionSet_Delay => 
RS <= LCD_CMDS(lcd_cmd_ptr)(9); 
RW <= LCD_CMDS(lcd_cmd_ptr)(8); 
LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0); 
activateW <= '0'; 
if delayOK = '1' then 
stNext <= stDisplayCtrlSet; 
else 
stNext <= stFunctionSet_Delay; 
end if; 

--Issuse the display control set as follows 
--Display ON, Cursor OFF, Blinking Cursor OFF. 
when stDisplayCtrlSet => 
RS <= LCD_CMDS(lcd_cmd_ptr)(9); 
RW <= LCD_CMDS(lcd_cmd_ptr)(8); 
LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0); 
activateW <= '1'; 
stNext <= stDisplayCtrlSet_Delay; 

--Gives the proper delay of 37us between the display control set 
--and the Display Clear command. 
when stDisplayCtrlSet_Delay => 
RS <= LCD_CMDS(lcd_cmd_ptr)(9); 
RW <= LCD_CMDS(lcd_cmd_ptr)(8); 
LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0); 
activateW <= '0'; 
if delayOK = '1' then 
stNext <= stDisplayClear; 
else 
stNext <= stDisplayCtrlSet_Delay; 
end if; 

--Issues the display clear command. 
when stDisplayClear => 
RS <= LCD_CMDS(lcd_cmd_ptr)(9); 
RW <= LCD_CMDS(lcd_cmd_ptr)(8); 
LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0); 
activateW <= '1'; 
stNext <= stDisplayClear_Delay; 

--Gives the proper delay of 1.52ms between the clear command 
--and the state where you are clear to do normal operations. 
when stDisplayClear_Delay => 
RS <= LCD_CMDS(lcd_cmd_ptr)(9); 
RW <= LCD_CMDS(lcd_cmd_ptr)(8); 
LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0); 
activateW <= '0'; 
if delayOK = '1' then 
stNext <= stInitDne; 
else 
stNext <= stDisplayClear_Delay; 
end if; 

--State for normal operations for displaying characters, changing the 
--Cursor position etc. 
when stInitDne => 
RS <= LCD_CMDS(lcd_cmd_ptr)(9); 
RW <= LCD_CMDS(lcd_cmd_ptr)(8); 
LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0); 
activateW <= '0'; 
 
stNext <= stActWr; 

when stActWr => 
RS <= LCD_CMDS(lcd_cmd_ptr)(9); 
RW <= LCD_CMDS(lcd_cmd_ptr)(8); 
LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0); 
activateW <= '1'; 
stNext <= stCharDelay; 

--Provides a max delay between instructions. 
when stCharDelay => 
RS <= LCD_CMDS(lcd_cmd_ptr)(9); 
RW <= LCD_CMDS(lcd_cmd_ptr)(8); 
LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0); 
activateW <= '0'; 
if delayOK = '1' then 
stNext <= stInitDne; 
else 
stNext <= stCharDelay; 
end if; 
end case; 

end process; 

--This process runs the write state machine 
process (CLK, rst) 
begin 
  if (rst = '1') then 
    stCurW <= stIdle;
  elsif (CLK'event and CLK = '1') then 
    if (oneUS_enable = '1') then -- Ação só ocorre quando o enable está ativo
      stCurW <= stNextW; 
    end if;
  end if; 
end process;

--This genearates the sequence of outputs needed to write to the LCD screen 
process (stCurW, activateW) 
begin 

case stCurW is 
--This sends the address across the bus telling the DIO5 that we are 
--writing to the LCD, in this configuration the adr_lcd(2) controls the 
--enable pin on the LCD 
when stRw => 
LCD_E <= '0'; 
--CS <= '0'; 
--ADR2 <= '1'; 
--ADR1 <= '0'; 
stNextW <= stEnable; 

--This adds another clock onto the wait to make sure data is stable on 
--the bus before enable goes low. The lcd has an active falling edge 
--and will write on the fall of enable 
when stEnable => 
LCD_E <= '0'; 
--CS <= '0'; 
--ADR2 <= '0'; 
--ADR1 <= '0'; 
stNextW <= stIdle; 

--Waiting for the write command from the instuction state machine 
when stIdle => 
--ADR2 <= '0'; 
--ADR1 <= '0'; 
--CS <= '1'; 
LCD_E <= '1'; 
if activateW = '1' then 
 

stNextW <= stRw; 
else 
stNextW <= stIdle; 
end if; 
end case; 
end process; 

end Behavioral;