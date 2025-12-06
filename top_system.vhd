library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_system is
    Port (
        clk     : in  std_logic;   -- 100 MHz
        rst     : in  std_logic;   -- active-high

        cs_dac  : out std_logic;
        sck_dac : out std_logic;
        dac_out : out std_logic    -- SDI t?i MCP4921
    );
end top_system;

architecture Behavioral of top_system is

    signal lut_out : std_logic_vector(11 downto 0); -- data t? LUT sin
    signal fsclk   : std_logic;                     -- clock m?u cho LUT

begin

    --------------------------------------------------------------------
    -- Clock divider t?o fsclk cho LUT
    --------------------------------------------------------------------
    u_clk_div : entity work.tao_xung_sclk_lut
        port map (
            clk         => clk,
            rst         => rst,
            sclk_output => fsclk
        );

    --------------------------------------------------------------------
    -- LUT sine generator
    --------------------------------------------------------------------
    u_lut : entity work.sine_lut
        port map (
            clk    => fsclk,
            rst    => rst,
            data_o => lut_out
        );

    --------------------------------------------------------------------
    -- DAC SPI driver
    --------------------------------------------------------------------
    u_dac : entity work.spi_dac_sine
        port map (
            clk_100M => clk,
            rst      => rst,
            data_in  => lut_out,

            dac_cs_n => cs_dac,
            dac_sck  => sck_dac,
            dac_sdi  => dac_out
        );

end Behavioral;
