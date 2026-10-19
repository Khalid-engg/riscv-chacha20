-- ============================================================================
-- tb_poly1305_mac.vhd  -  Testbench for poly1305_mac
--
-- Test 1: same input as the C code / website
--         key = 00 01 02 ... 1f , message = "Hello my poly1305"
--         expected tag = 3910053d601020965645dce7d98522ce
-- Test 2: RFC 8439 Section 2.5.2 (KAT)
--         expected tag = a8061dc1305136c6c22b8baf0c0127a9
--
-- The tag is printed in the Tcl console, and tag_bytes shows it in the
-- waveform in normal reading order (byte 0 first).
-- File type in Vivado: VHDL 2008
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_poly1305_mac is
end tb_poly1305_mac;

architecture sim of tb_poly1305_mac is

    constant CLK_PERIOD : time := 10 ns;   -- 100 MHz, same as timing.xdc

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal start     : std_logic := '0';
    signal key       : std_logic_vector(255 downto 0) := (others => '0');
    signal msg       : std_logic_vector(511 downto 0) := (others => '0');
    signal msg_len   : std_logic_vector(6 downto 0)   := (others => '0');
    signal tag       : std_logic_vector(127 downto 0);
    signal done      : std_logic;
    signal tag_bytes : std_logic_vector(127 downto 0);  -- waveform only: byte 0 on the left

    -- put a text string into msg: byte 0 in bits 7..0 (same as the ChaCha20 testbench)
    function pack_string(s : string) return std_logic_vector is
        variable v : std_logic_vector(511 downto 0) := (others => '0');
    begin
        for i in 0 to s'length - 1 loop
            v(8 * i + 7 downto 8 * i) := std_logic_vector(to_unsigned(character'pos(s(s'low + i)), 8));
        end loop;
        return v;
    end function;

    -- key written as a normal hex string (byte 0 first) -> byte 0 in bits 7..0
    function pack_hex_key(h : std_logic_vector(255 downto 0)) return std_logic_vector is
        variable v : std_logic_vector(255 downto 0);
    begin
        for i in 0 to 31 loop
            v(8 * i + 7 downto 8 * i) := h(255 - 8 * i downto 248 - 8 * i);
        end loop;
        return v;
    end function;

    -- tag (byte 0 in bits 7..0) -> hex string in normal order, same as the C output
    function tag_to_string(t : std_logic_vector(127 downto 0)) return string is
        constant HEX : string(1 to 16) := "0123456789abcdef";
        variable str : string(1 to 32);
    begin
        for i in 0 to 15 loop
            str(2 * i + 1) := HEX(to_integer(unsigned(t(8 * i + 7 downto 8 * i + 4))) + 1);
            str(2 * i + 2) := HEX(to_integer(unsigned(t(8 * i + 3 downto 8 * i))) + 1);
        end loop;
        return str;
    end function;

begin

    clk <= not clk after CLK_PERIOD / 2;

    uut : entity work.poly1305_mac
        port map (
            clk     => clk,
            rst     => rst,
            start   => start,
            key     => key,
            msg     => msg,
            msg_len => msg_len,
            tag     => tag,
            done    => done
        );

    gen_view : for i in 0 to 15 generate
        tag_bytes(127 - 8 * i downto 120 - 8 * i) <= tag(8 * i + 7 downto 8 * i);
    end generate;

    stim : process

        procedure run_test(name      : string;
                           key_hex   : std_logic_vector(255 downto 0);
                           message   : string;
                           expected  : string) is
            variable t_start : time;
            variable cycles  : natural;
        begin
            key     <= pack_hex_key(key_hex);
            msg     <= pack_string(message);
            msg_len <= std_logic_vector(to_unsigned(message'length, 7));

            wait until rising_edge(clk);
            start <= '1';
            wait until rising_edge(clk);           -- the circuit samples start here
            t_start := now;
            start <= '0';

            if done /= '0' then
                wait until done = '0';             -- done of the previous run goes low
            end if;
            wait until done = '1';                 -- result ready
            cycles := (now - t_start) / CLK_PERIOD;

            report "==== " & name & " ====";
            report "Message : " & message & "  (" & integer'image(message'length) & " bytes)";
            report "Tag (HW): " & tag_to_string(tag);
            report "Expected: " & expected;
            report "Cycles  : " & integer'image(cycles) & "  (" &
                   integer'image(cycles * 10) & " ns at 100 MHz)";
            if tag_to_string(tag) = expected then
                report "RESULT  : PASS";
            else
                report "RESULT  : FAIL" severity error;
            end if;

            wait for 50 ns;
        end procedure;

    begin
        rst <= '1';
        wait for 50 ns;
        wait until rising_edge(clk);
        rst <= '0';

        run_test("Test 1: same input as C code / website",
                 x"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
                 "Hello my poly1305",
                 "3910053d601020965645dce7d98522ce");

        run_test("Test 2: RFC 8439 KAT",
                 x"85d6be7857556d337f4452fe42d506a80103808afb0db2fd4abff6af4149f51b",
                 "Cryptographic Forum Research Group",
                 "a8061dc1305136c6c22b8baf0c0127a9");

        report "Simulation finished";
        std.env.finish;
    end process;

end sim;
