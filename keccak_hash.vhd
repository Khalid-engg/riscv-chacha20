-- ============================================================================
-- keccak_hash.vhd  -  Keccak / SHA3-256 circuit  -  ONE FILE
--
-- Contents (in this order, because each part must be defined before it is used):
--   Part 1  keccak_globals              types: lane (64 bits), plane, state (5x5 lanes)
--   Part 2  keccak_round_constants_gen  the 24 round constants
--   Part 3  keccak_round                one Keccak-f[1600] round: theta, rho, pi, chi, iota
--   Part 4  keccak_hash                 TOP: start/done controller, SHA3-256
--
-- Parts 1-3: official Keccak team VHDL (KeccakVHDL 3.0, high-speed core),
--            public domain (CC0) - see the notice at the start of each part.
--            Used without changes.
-- Part 4:    written for this project
--
-- Set File Type in Vivado to: VHDL 2008
-- ============================================================================


-- ============================================================================
-- Part 1: keccak_globals - types
-- ============================================================================
-- The Keccak sponge function, designed by Guido Bertoni, Joan Daemen,
-- Michaël Peeters and Gilles Van Assche. For more information, feedback or
-- questions, please refer to our website: http://keccak.noekeon.org/

-- Implementation by the designers,
-- hereby denoted as "the implementer".

-- To the extent possible under law, the implementer has waived all copyright
-- and related or neighboring rights to the source code in this file.
-- http://creativecommons.org/publicdomain/zero/1.0/
library STD;
 use STD.textio.all;


  library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.std_logic_misc.all;
    use IEEE.std_logic_arith.all;
    

library work;


package keccak_globals is


constant num_plane : integer := 5;
constant num_sheet : integer := 5;
constant logD : integer :=4;
constant N : integer := 64;



--types
 type k_lane        is  array ((N-1) downto 0)  of std_logic;    
 type k_plane        is array ((num_sheet-1) downto 0)  of k_lane;    
 type k_state        is array ((num_plane-1) downto 0)  of k_plane;  

end package;

-- ============================================================================
-- Part 2: keccak_round_constants_gen - round constants
-- ============================================================================
-- The Keccak sponge function, designed by Guido Bertoni, Joan Daemen,
-- Michaël Peeters and Gilles Van Assche. For more information, feedback or
-- questions, please refer to our website: http://keccak.noekeon.org/

-- Implementation by the designers,
-- hereby denoted as "the implementer".

-- To the extent possible under law, the implementer has waived all copyright
-- and related or neighboring rights to the source code in this file.
-- http://creativecommons.org/publicdomain/zero/1.0/

library work;
	use work.keccak_globals.all;
	
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;	


entity keccak_round_constants_gen is
port(

    round_number: in unsigned(4 downto 0);
    round_constant_signal_out    : out std_logic_vector(63 downto 0));

end keccak_round_constants_gen;

architecture rtl of keccak_round_constants_gen is


  ----------------------------------------------------------------------------
  -- Internal signal declarations
  ----------------------------------------------------------------------------

 
  signal round_constant_signal: std_logic_vector(63 downto 0);
 
  
begin  -- Rtl




round_constants : process (round_number)
begin
	case round_number is
            when "00000" => round_constant_signal <= X"0000000000000001" ;
	    when "00001" => round_constant_signal <= X"0000000000008082" ;
	    when "00010" => round_constant_signal <= X"800000000000808A" ;
	    when "00011" => round_constant_signal <= X"8000000080008000" ;
	    when "00100" => round_constant_signal <= X"000000000000808B" ;
	    when "00101" => round_constant_signal <= X"0000000080000001" ;
	    when "00110" => round_constant_signal <= X"8000000080008081" ;
	    when "00111" => round_constant_signal <= X"8000000000008009" ;
	    when "01000" => round_constant_signal <= X"000000000000008A" ;
	    when "01001" => round_constant_signal <= X"0000000000000088" ;
	    when "01010" => round_constant_signal <= X"0000000080008009" ;
	    when "01011" => round_constant_signal <= X"000000008000000A" ;
	    when "01100" => round_constant_signal <= X"000000008000808B" ;
	    when "01101" => round_constant_signal <= X"800000000000008B" ;
	    when "01110" => round_constant_signal <= X"8000000000008089" ;
	    when "01111" => round_constant_signal <= X"8000000000008003" ;
	    when "10000" => round_constant_signal <= X"8000000000008002" ;
	    when "10001" => round_constant_signal <= X"8000000000000080" ;
	    when "10010" => round_constant_signal <= X"000000000000800A" ;
	    when "10011" => round_constant_signal <= X"800000008000000A" ;
	    when "10100" => round_constant_signal <= X"8000000080008081" ;
	    when "10101" => round_constant_signal <= X"8000000000008080" ;
	    when "10110" => round_constant_signal <= X"0000000080000001" ;
	    when "10111" => round_constant_signal <= X"8000000080008008" ;	    	    
	    when others => round_constant_signal <=(others => '0');
        end case;
end process round_constants;

round_constant_signal_out<=round_constant_signal;
end rtl;


-- ============================================================================
-- Part 3: keccak_round - one Keccak-f[1600] round
-- ============================================================================
-- The Keccak sponge function, designed by Guido Bertoni, Joan Daemen,
-- Michaël Peeters and Gilles Van Assche. For more information, feedback or
-- questions, please refer to our website: http://keccak.noekeon.org/

-- Implementation by the designers,
-- hereby denoted as "the implementer".

-- To the extent possible under law, the implementer has waived all copyright
-- and related or neighboring rights to the source code in this file.
-- http://creativecommons.org/publicdomain/zero/1.0/


library work;
	use work.keccak_globals.all;
	
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;	


entity keccak_round is

port (

    round_in     : in  k_state;
    round_constant_signal    : in std_logic_vector(63 downto 0);
    round_out    : out k_state);

end keccak_round;

architecture rtl of keccak_round is


  ----------------------------------------------------------------------------
  -- Internal signal declarations
  ----------------------------------------------------------------------------

 
  signal theta_in,theta_out,pi_in,pi_out,rho_in,rho_out,chi_in,chi_out,iota_in,iota_out : k_state;
  signal sum_sheet: k_plane;
 
  
begin  -- Rtl




--connecitons

--order theta, pi, rho, chi, iota
theta_in<=round_in;
pi_in<=rho_out;
rho_in<=theta_out;
chi_in<=pi_out;
iota_in<=chi_out;
round_out<=iota_out;


--chi
i0000: for y in 0 to 4 generate
	i0001: for x in 0 to 2 generate
		i0002: for i in 0 to 63 generate
			chi_out(y)(x)(i)<=chi_in(y)(x)(i) xor  ( not(chi_in (y)(x+1)(i))and chi_in (y)(x+2)(i));
		
		end generate;	
	end generate;
end generate;

	i0011: for y in 0 to 4 generate
		i0021: for i in 0 to 63 generate
			chi_out(y)(3)(i)<=chi_in(y)(3)(i) xor  ( not(chi_in (y)(4)(i))and chi_in (y)(0)(i));
		
		end generate;	
	end generate;
	
	i0012: for y in 0 to 4 generate
		i0022: for i in 0 to 63 generate
			chi_out(y)(4)(i)<=chi_in(y)(4)(i) xor  ( not(chi_in (y)(0)(i))and chi_in (y)(1)(i));
		
		end generate;	
	end generate;


--theta

--compute sum of columns

i0101: for x in 0 to 4 generate
	i0102: for i in 0 to 63 generate
		sum_sheet(x)(i)<=theta_in(0)(x)(i) xor theta_in(1)(x)(i) xor theta_in(2)(x)(i) xor theta_in(3)(x)(i) xor theta_in(4)(x)(i);
	
	end generate;	
end generate;


i0200: for y in 0 to 4 generate
	i0201: for x in 1 to 3 generate
		theta_out(y)(x)(0)<=theta_in(y)(x)(0) xor sum_sheet(x-1)(0) xor sum_sheet(x+1)(63);
		i0202: for i in 1 to 63 generate
			theta_out(y)(x)(i)<=theta_in(y)(x)(i) xor sum_sheet(x-1)(i) xor sum_sheet(x+1)(i-1);
		end generate;	
	end generate;
end generate;

i2001: for y in 0 to 4 generate
	theta_out(y)(0)(0)<=theta_in(y)(0)(0) xor sum_sheet(4)(0) xor sum_sheet(1)(63);
	i2021: for i in 1 to 63 generate
		theta_out(y)(0)(i)<=theta_in(y)(0)(i) xor sum_sheet(4)(i) xor sum_sheet(1)(i-1);
	end generate;	

end generate;

i2002: for y in 0 to 4 generate
	theta_out(y)(4)(0)<=theta_in(y)(4)(0) xor sum_sheet(3)(0) xor sum_sheet(0)(63);
	i2022: for i in 1 to 63 generate
		theta_out(y)(4)(i)<=theta_in(y)(4)(i) xor sum_sheet(3)(i) xor sum_sheet(0)(i-1);
	end generate;	

end generate;

-- pi
i3001: for y in 0 to 4 generate
	i3002: for x in 0 to 4 generate
		i3003: for i in 0 to 63 generate
			--pi_out(y)(x)(i)<=pi_in((y +2*x) mod 5)(((4*y)+x) mod 5)(i);
			pi_out((2*x+3*y) mod 5)(0*x+1*y)(i)<=pi_in(y) (x)(i);
		end generate;	
	end generate;
end generate;

--rho


i4001: for i in 0 to 63 generate
	rho_out(0)(0)(i)<=rho_in(0)(0)(i);
end generate;	
i4002: for i in 0 to 63 generate
	rho_out(0)(1)(i)<=rho_in(0)(1)((i-1)mod 64);
end generate;
i4003: for i in 0 to 63 generate
	rho_out(0)(2)(i)<=rho_in(0)(2)((i-62)mod 64);
end generate;
i4004: for i in 0 to 63 generate
	rho_out(0)(3)(i)<=rho_in(0)(3)((i-28)mod 64);
end generate;
i4005: for i in 0 to 63 generate
	rho_out(0)(4)(i)<=rho_in(0)(4)((i-27)mod 64);
end generate;

i4011: for i in 0 to 63 generate
	rho_out(1)(0)(i)<=rho_in(1)(0)((i-36)mod 64);
end generate;	
i4012: for i in 0 to 63 generate
	rho_out(1)(1)(i)<=rho_in(1)(1)((i-44)mod 64);
end generate;
i4013: for i in 0 to 63 generate
	rho_out(1)(2)(i)<=rho_in(1)(2)((i-6)mod 64);
end generate;
i4014: for i in 0 to 63 generate
	rho_out(1)(3)(i)<=rho_in(1)(3)((i-55)mod 64);
end generate;
i4015: for i in 0 to 63 generate
	rho_out(1)(4)(i)<=rho_in(1)(4)((i-20)mod 64);
end generate;

i4021: for i in 0 to 63 generate
	rho_out(2)(0)(i)<=rho_in(2)(0)((i-3)mod 64);
end generate;	
i4022: for i in 0 to 63 generate
	rho_out(2)(1)(i)<=rho_in(2)(1)((i-10)mod 64);
end generate;
i4023: for i in 0 to 63 generate
	rho_out(2)(2)(i)<=rho_in(2)(2)((i-43)mod 64);
end generate;
i4024: for i in 0 to 63 generate
	rho_out(2)(3)(i)<=rho_in(2)(3)((i-25)mod 64);
end generate;
i4025: for i in 0 to 63 generate
	rho_out(2)(4)(i)<=rho_in(2)(4)((i-39)mod 64);
end generate;

i4031: for i in 0 to 63 generate
	rho_out(3)(0)(i)<=rho_in(3)(0)((i-41)mod 64);
end generate;	
i4032: for i in 0 to 63 generate
	rho_out(3)(1)(i)<=rho_in(3)(1)((i-45)mod 64);
end generate;
i4033: for i in 0 to 63 generate
	rho_out(3)(2)(i)<=rho_in(3)(2)((i-15)mod 64);
end generate;
i4034: for i in 0 to 63 generate
	rho_out(3)(3)(i)<=rho_in(3)(3)((i-21)mod 64);
end generate;
i4035: for i in 0 to 63 generate
	rho_out(3)(4)(i)<=rho_in(3)(4)((i-8)mod 64);
end generate;

i4041: for i in 0 to 63 generate
	rho_out(4)(0)(i)<=rho_in(4)(0)((i-18)mod 64);
end generate;	
i4042: for i in 0 to 63 generate
	rho_out(4)(1)(i)<=rho_in(4)(1)((i-2)mod 64);
end generate;
i4043: for i in 0 to 63 generate
	rho_out(4)(2)(i)<=rho_in(4)(2)((i-61)mod 64);
end generate;
i4044: for i in 0 to 63 generate
	rho_out(4)(3)(i)<=rho_in(4)(3)((i-56)mod 64);
end generate;
i4045: for i in 0 to 63 generate
	rho_out(4)(4)(i)<=rho_in(4)(4)((i-14)mod 64);
end generate;

--iota
i5001: for y in 1 to 4 generate
	i5002: for x in 0 to 4 generate
		i5003: for i in 0 to 63 generate
			iota_out(y)(x)(i)<=iota_in(y)(x)(i);
		end generate;	
	end generate;
end generate;


	i5012: for x in 1 to 4 generate
		i5013: for i in 0 to 63 generate
			iota_out(0)(x)(i)<=iota_in(0)(x)(i);
		end generate;	
	end generate;



		i5103: for i in 0 to 63 generate
			iota_out(0)(0)(i)<=iota_in(0)(0)(i) xor round_constant_signal(i);
		end generate;	



end rtl;


-- ============================================================================
-- Part 4: keccak_hash - TOP  (SHA3-256)
-- ============================================================================
-- Top module, same style as chacha20_encrypt / poly1305_mac:
-- pulse start, wait for done.
-- It uses the Keccak team round (Part 3) and round constants (Part 2):
--   1) load: pad the message (0x06 ... 0x80) and put it in the state
--   2) 24 rounds of Keccak-f[1600], one round per clock
--   3) digest = first 32 bytes of the state
--
-- Byte order (same as ChaCha20 / Poly1305): byte 0 is in bits 7..0
--   msg(511:0)    : message, up to 64 bytes
--   msg_len       : message length in bytes (0..64)
--   digest(255:0) : SHA3-256 hash (32 bytes)
--
-- Lane (x, y) of the Keccak state is state(y)(x); lane(0,0) = state(0)(0).
-- File type in Vivado: VHDL 2008
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.keccak_globals.all;

entity keccak_hash is
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        start   : in  std_logic;
        msg     : in  std_logic_vector(511 downto 0);
        msg_len : in  std_logic_vector(6 downto 0);
        digest  : out std_logic_vector(255 downto 0);
        done    : out std_logic
    );
end keccak_hash;

architecture rtl of keccak_hash is

    type fsm_t is (IDLE, ROUNDS, FINISHED);
    signal fsm       : fsm_t := IDLE;

    signal state     : k_state := (others => (others => (others => '0')));
    signal round_out : k_state;
    signal round_cnt : unsigned(4 downto 0) := (others => '0');   -- 0..23
    signal rc_num    : ieee.std_logic_arith.unsigned(4 downto 0); -- type used by Part 2
    signal rc        : std_logic_vector(63 downto 0);

    signal digest_r  : std_logic_vector(255 downto 0) := (others => '0');
    signal done_r    : std_logic := '0';

    -- first (and only) block: message bytes, then 0x06, zeros, and 0x80 at byte 135
    -- (SHA3-256 rate = 136 bytes; the other 64 bytes of the state start at 0)
    function load_block(m : std_logic_vector(511 downto 0); len_in : natural) return k_state is
        variable blk : std_logic_vector(1599 downto 0) := (others => '0');  -- byte i = bits 8i+7..8i
        variable s   : k_state;
        variable len : natural;
    begin
        len := len_in;
        if len > 64 then len := 64; end if;
        for i in 0 to 63 loop
            if i < len then
                blk(8 * i + 7 downto 8 * i) := m(8 * i + 7 downto 8 * i);
            end if;
        end loop;
        for i in 0 to 64 loop
            if i = len then
                blk(8 * i + 7 downto 8 * i) := x"06";                 -- SHA-3 padding start
            end if;
        end loop;
        blk(8 * 135 + 7 downto 8 * 135) := x"80";                     -- padding end
        for y in 0 to 4 loop
            for x in 0 to 4 loop
                for b in 0 to 63 loop
                    s(y)(x)(b) := blk(64 * (x + 5 * y) + b);
                end loop;
            end loop;
        end loop;
        return s;
    end function;

begin

    -- round constant for the current round (Part 2)
    rc_num <= ieee.std_logic_arith.unsigned(std_logic_vector(round_cnt));

    u_rc : entity work.keccak_round_constants_gen
        port map (
            round_number              => rc_num,
            round_constant_signal_out => rc
        );

    -- one full Keccak round: theta, rho, pi, chi, iota (Part 3)
    u_round : entity work.keccak_round
        port map (
            round_in              => state,
            round_constant_signal => rc,
            round_out             => round_out
        );

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fsm    <= IDLE;
                done_r <= '0';
            else
                case fsm is

                    when IDLE | FINISHED =>
                        if start = '1' then
                            state     <= load_block(msg, to_integer(unsigned(msg_len)));
                            round_cnt <= (others => '0');
                            done_r    <= '0';
                            fsm       <= ROUNDS;
                        end if;

                    when ROUNDS =>
                        state <= round_out;
                        if round_cnt = 23 then
                            -- digest = lanes (0,0) .. (3,0) = first 32 bytes
                            for x in 0 to 3 loop
                                for b in 0 to 63 loop
                                    digest_r(64 * x + b) <= round_out(0)(x)(b);
                                end loop;
                            end loop;
                            done_r <= '1';
                            fsm    <= FINISHED;
                        else
                            round_cnt <= round_cnt + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

    digest <= digest_r;
    done   <= done_r;

end rtl;
