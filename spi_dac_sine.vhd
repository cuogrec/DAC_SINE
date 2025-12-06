library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_dac_sine is
    Port ( 
        clk_100M : in  STD_LOGIC;     -- 100 MHz clock
        rst      : in  STD_LOGIC;     -- Active-high reset
        data_in  : in  STD_LOGIC_VECTOR(11 downto 0);  -- 12-bit m?u

        -- DAC MCP4921 interface
        dac_cs_n : out STD_LOGIC;
        dac_sck  : out STD_LOGIC;
        dac_sdi  : out STD_LOGIC
    );
end spi_dac_sine;

architecture rtl of spi_dac_sine is

    -- FSM state
    type state_type is (IDLE, LOAD, TRANSMIT, FINISH);
    signal state_reg, state_next : state_type;

    -- Counters
    signal bit_count_reg, bit_count_next : unsigned(4 downto 0);
    signal sck_count_reg, sck_count_next : unsigned(3 downto 0); -- 0..9

    -- Shift register for SPI
    signal shift_reg, shift_reg_next : std_logic_vector(15 downto 0);

    -- Outputs
    signal dac_cs_n_reg, dac_cs_n_next : std_logic;
    signal dac_sck_reg, dac_sck_next   : std_logic;
    signal dac_sdi_reg, dac_sdi_next   : std_logic;

    -- 16-bit word cho MCP4921: [C3..C0][D11..D0]
    signal sine_sample : std_logic_vector(15 downto 0);

begin

    -- C?u hình MCP4921: 
    -- bit15: A/B=0, bit14:BUF=0, bit13:GA=1, bit12:SHDN=1  => "0011"
    sine_sample <= "0011" & data_in;

    ------------------------------------------------
    -- Register process (synchronous reset)
    ------------------------------------------------
    process(clk_100M)
    begin
        if rising_edge(clk_100M) then
            if rst = '1' then
                state_reg     <= IDLE;
                bit_count_reg <= (others => '0');
                sck_count_reg <= (others => '0');
                shift_reg     <= (others => '0');

                dac_cs_n_reg  <= '1';
                dac_sck_reg   <= '0';
                dac_sdi_reg   <= '0';
            else
                state_reg     <= state_next;
                bit_count_reg <= bit_count_next;
                sck_count_reg <= sck_count_next;
                shift_reg     <= shift_reg_next;

                dac_cs_n_reg  <= dac_cs_n_next;
                dac_sck_reg   <= dac_sck_next;
                dac_sdi_reg   <= dac_sdi_next;
            end if;
        end if;
    end process;

    ------------------------------------------------
    -- Next state logic
    ------------------------------------------------
    process(state_reg, bit_count_reg, sck_count_reg, shift_reg,
            dac_cs_n_reg, dac_sck_reg, dac_sdi_reg, sine_sample)
    begin
        -- gi? giá tr? m?c ??nh
        state_next     <= state_reg;
        bit_count_next <= bit_count_reg;
        sck_count_next <= sck_count_reg;
        shift_reg_next <= shift_reg;

        dac_cs_n_next  <= dac_cs_n_reg;
        dac_sck_next   <= dac_sck_reg;
        dac_sdi_next   <= dac_sdi_reg;

        case state_reg is

            when IDLE =>
                dac_cs_n_next  <= '1';
                dac_sck_next   <= '0';
                sck_count_next <= (others => '0');
                -- luôn load m?u m?i
                state_next     <= LOAD;

            when LOAD =>
                shift_reg_next <= sine_sample;
                bit_count_next <= to_unsigned(15, 5); -- 16 bit: 15..0
                dac_cs_n_next  <= '0';                -- kéo CS th?p
                state_next     <= TRANSMIT;

            when TRANSMIT =>
                sck_count_next <= sck_count_reg + 1;

                case sck_count_reg is
                    when "0000" =>
                        -- ??t data, SCK = 0
                        dac_sck_next <= '0';
                        dac_sdi_next <= shift_reg(15);

                    when "0100" =>
                        -- C?nh lên SCK (sampling)
                        dac_sck_next <= '1';

                    when "1001" =>
                        -- K?t thúc 1 bit: kéo SCK xu?ng, shift d? li?u
                        dac_sck_next   <= '0';
                        shift_reg_next <= shift_reg(14 downto 0) & '0';

                        if bit_count_reg = 0 then
                            state_next <= FINISH;
                        else
                            bit_count_next <= bit_count_reg - 1;
                        end if;
                        sck_count_next <= (others => '0');

                    when others =>
                        null;
                end case;

            when FINISH =>
                dac_cs_n_next <= '1';
                dac_sck_next  <= '0';
                state_next    <= IDLE;

        end case;
    end process;

    ------------------------------------------------
    -- Output map
    ------------------------------------------------
    dac_cs_n <= dac_cs_n_reg;
    dac_sck  <= dac_sck_reg;
    dac_sdi  <= dac_sdi_reg;

end rtl;
