-- Listing 4.20 
library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; 
entity fifo is 
generic( 
B: natural:=8 -- number of bits 
); 
port( 
clk, reset: in std_logic; 
rd, wr: in std_logic; 
w_data: in std_logic_vector (B-1 downto 0); 
empty, full: out std_logic; 
r_data: out std_logic_vector (B-1 downto 0) 
); 
end fifo; 

architecture arch of fifo is 
signal array_reg: std_logic_vector(B-1 downto 0); 
signal full_reg, empty_reg, full_next, empty_next: 
std_logic; 
signal wr_op: std_logic_vector(1 downto 0); 
signal wr_en: std_logic; 
begin 
--================================================= 
-- register file 
--================================================= 
process(clk,reset) 
begin 
if (reset='1') then 
array_reg <= (others=>'0'); 
elsif (clk'event and clk='1') then 
if wr_en='1' then 
array_reg <= w_data; 
end if; 
end if; 
end process; 
-- read port 
r_data <= array_reg; 
-- write enabled only when FIFO is not full 
wr_en <= wr and (not full_reg); 

--================================================= 
-- fifo control logic 
--================================================= 

-- register for read and write pointers 
process(clk,reset) 
begin 
if (reset='1') then 
full_reg <= '0'; 
empty_reg <= '1'; 
elsif (clk'event and clk='1') then 
full_reg <= full_next; 
empty_reg <= empty_next; 
end if; 
end process; 

-- next-state logic for read and write pointers 
wr_op <= wr & rd; 
process(wr_op, empty_reg,full_reg) 
begin 
full_next <= full_reg; 
empty_next <= empty_reg; 
case wr_op is 
when "00" => -- no op 
when "01" => -- read 
if (empty_reg /= '1') then -- not empty 
full_next <= '0'; 
empty_next <='1'; 
end if; 
when "10" => -- write 
if (full_reg /= '1') then -- not full 
empty_next <= '0'; 
full_next <='1'; 
end if; 
when others => -- write/read; 
end case; 
end process; 
-- output 
full <= full_reg; 
empty <= empty_reg; 
end arch; 