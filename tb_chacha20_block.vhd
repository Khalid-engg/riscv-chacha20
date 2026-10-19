library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_chacha20_block is
end entity;

architecture sim of tb_chacha20_block is
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal start     : std_logic := '0';
    signal key       : std_logic_vector(255 downto 0) := (others => '0');
    signal nonce     : std_logic_vector(95 downto 0)  := (others => '0');
    signal counter   : std_logic_vector(31 downto 0)  := x"00000001";
    signal done      : std_logic;
    signal block_out : std_logic_vector(511 downto 0);

    type byte_array_t is array (natural range <>) of std_logic_vector(7 downto 0);

    constant PLAINTEXT : byte_array_t(0 to 19) := (
        x"48", x"65", x"6C", x"6C", x"6F", x"20", x"43", x"68", x"61", x"43",
        x"68", x"61", x"32", x"30", x"20", x"54", x"65", x"73", x"74", x"21"
    );

    constant EXPECTED_CIPHER : byte_array_t(0 to 19) := (
        x"D7", x"62", x"8B", x"D2", x"3A", x"71", x"7B", x"12", x"F9", x"F9",
        x"FF", x"1D", x"41", x"1D", x"28", x"59", x"AE", x"7C", x"5D", x"81"
    );

begin
    clk <= not clk after 5 ns;

    uut: entity work.chacha20_block
        port map (
            clk       => clk,
            rst       => rst,
            start     => start,
            key       => key,
            nonce     => nonce,
            counter   => counter,
            done      => done,
            block_out => block_out
        );

    process
        variable ks_byte     : std_logic_vector(7 downto 0);
        variable cipher_byte : std_logic_vector(7 downto 0);
    begin
        wait for 20 ns;
        rst <= '0';

        wait for 10 ns;
        start <= '1';
        wait for 10 ns;
        start <= '0';

        wait until done = '1';
        wait for 1 ns;

        for i in 0 to 19 loop
            ks_byte := block_out(i*8 + 7 downto i*8);
            cipher_byte := PLAINTEXT(i) xor ks_byte;

            assert cipher_byte = EXPECTED_CIPHER(i)
                report "Mismatch at byte " & integer'image(i)
                severity failure;
        end loop;

        report "ChaCha20 test PASSED." severity note;
        wait;
    end process;
end architecture;