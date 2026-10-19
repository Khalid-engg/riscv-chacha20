-- ============================================================================
-- tb_keccak_hash.vhd  -  Testbench for keccak_hash (SHA3-256)
--
-- Test 1: same input as the C code / website
--         message = "Hello my keccak"
--         expected = 7ca8aefbab199706a6f14e350c6fd233408415946ae44eae47ec9eeae859e254
-- Test 2: FIPS 202 known answer, message = "abc"
--         expected = 3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532
--
-- The digest is printed in the Tcl console, and digest_bytes shows it in the
-- waveform in normal reading order (byte 0 first).
-- For round-by-round checking: add uut/state and uut/round_cnt to the waveform.
-- File type in Vivado: VHDL 2008
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_keccak_hash is
end tb_keccak_hash;

architecture sim of tb_keccak_hash is

    constant CLK_PERIOD : time := 10 ns;   -- 100 MHz, same as timing.xdc

    signal clk          : std_logic := '0';
    signal rst          : std_logic := '1';
    signal start        : std_logic := '0';
    signal msg          : std_logic_vector(511 downto 0) := (others => '0');
    signal msg_len      : std_logic_vector(6 downto 0)   := (others => '0');
    signal digest       : std_logic_vector(255 downto 0);
    signal done         : std_logic;
    signal digest_bytes : std_logic_vector(255 downto 0);  -- waveform only: byte 0 on the left

    -- put a text string into msg: byte 0 in bits 7..0 (same as ChaCha20 / Poly1305)
    function pack_string(s : string) return std_logic_vector is
        variable v : std_logic_vector(511 downto 0) := (others => '0');
    begin
        for i in 0 to s'length - 1 loop
            v(8 * i + 7 downto 8 * i) := std_logic_vector(to_unsigned(character'pos(s(s'low + i)), 8));
        end loop;
        return v;
    end function;

    -- digest (byte 0 in bits 7..0) -> hex string in normal order, same as the C output
    function digest_to_string(d : std_logic_vector(255 downto 0)) return string is
        constant HEX : string(1 to 16) := "0123456789abcdef";
        variable str : string(1 to 64);
    begin
        for i in 0 to 31 loop
            str(2 * i + 1) := HEX(to_integer(unsigned(d(8 * i + 7 downto 8 * i + 4))) + 1);
            str(2 * i + 2) := HEX(to_integer(unsigned(d(8 * i + 3 downto 8 * i))) + 1);
        end loop;
        return str;
    end function;

begin

    clk <= not clk after CLK_PERIOD / 2;

    uut : entity work.keccak_hash
        port map (
            clk     => clk,
            rst     => rst,
            start   => start,
            msg     => msg,
            msg_len => msg_len,
            digest  => digest,
            done    => done
        );

    gen_view : for i in 0 to 31 generate
        digest_bytes(255 - 8 * i downto 248 - 8 * i) <= digest(8 * i + 7 downto 8 * i);
    end generate;

    stim : process

        procedure run_test(name     : string;
                           message  : string;
                           expected : string) is
            variable t_start : time;
            variable cycles  : natural;
        begin
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
            report "SHA3-256 (HW): " & digest_to_string(digest);
            report "Expected     : " & expected;
            report "Cycles  : " & integer'image(cycles) & "  (" &
                   integer'image(cycles * 10) & " ns at 100 MHz)";
            if digest_to_string(digest) = expected then
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
                 "Hello my keccak",
                 "7ca8aefbab199706a6f14e350c6fd233408415946ae44eae47ec9eeae859e254");

        run_test("Test 2: FIPS 202 known answer",
                 "abc",
                 "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532");

        report "Simulation finished";
        std.env.finish;
    end process;

end sim;
