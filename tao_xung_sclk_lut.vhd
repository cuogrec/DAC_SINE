library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tao_xung_sclk_lut is 
    port (
        clk         : in  std_logic;   -- Clock 100 MHz
        rst         : in  std_logic;
        sclk_output : out std_logic    -- ~1.25 MHz (square wave)
    );
end tao_xung_sclk_lut;

architecture behavioral of tao_xung_sclk_lut is
    signal counter  : unsigned(12 downto 0) := (others => '0'); 
    signal sclk_reg : std_logic := '0';
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                counter  <= (others => '0');
                sclk_reg <= '0';
            else
                if counter = 39 then
                    counter  <= (others => '0');
                    sclk_reg <= not sclk_reg;  -- toggle m?i 40 xung
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;

    sclk_output <= sclk_reg;
end behavioral;
