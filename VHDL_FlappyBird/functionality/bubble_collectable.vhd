library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;


entity bubble_collectable is
	port (
		CLOCK_25		 			: in std_logic;
		pipe_x, gap_y 				: in integer;
		bubble_active 				: in std_logic;
		pixel_row, pixel_column 	: in std_logic_vector(9 downto 0);
		game_active					: in std_logic;
		colour 						: out std_logic_vector(11 downto 0);
		pixel_enable				: out std_logic);
end entity bubble_collectable;


architecture behaviour of bubble_collectable is
	component bubble_rom is
		port (
		address		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (11 DOWNTO 0));
	end component;

    constant PIPE_WIDTH    : integer := 76;
    constant GAP_HEIGHT    : integer := 120;
    constant BUBBLE_WIDTH  : integer := 34;
    constant BUBBLE_HEIGHT : integer := 39;

    signal bubble_address : std_logic_vector(10 downto 0);
    signal bubble_pixel   : std_logic_vector(11 downto 0);
    signal use_bubble : std_logic := '0';
	 
begin
	BUBBLE : bubble_rom port map (address => bubble_address, clock => CLOCK_25, q => bubble_pixel);

	-- rendering address of rom and stuff
	process (CLOCK_25)
    	variable row_int : integer;
		variable col_int : integer;
		variable bubble_left : integer;
		variable bubble_top  : integer;
		variable local_x : integer;
		variable local_y : integer;
	begin
		if rising_edge(CLOCK_25) then
			row_int := to_integer(unsigned(pixel_row));
			col_int := to_integer(unsigned(pixel_column));

			use_bubble <= '0';
			bubble_address <= "00000000000";

			-- centering sprite
			bubble_left := pipe_x + (PIPE_WIDTH - BUBBLE_WIDTH) / 2;
			bubble_top  := gap_y + (GAP_HEIGHT - BUBBLE_HEIGHT) / 2;

			if bubble_active = '1' then
				-- make sure bubble range is established
				if col_int >= bubble_left and col_int < bubble_left + BUBBLE_WIDTH and row_int >= bubble_top and row_int < bubble_top + BUBBLE_HEIGHT then
					local_x := col_int - bubble_left;
					local_y := row_int - bubble_top;

					bubble_address <= std_logic_vector(to_unsigned(local_y * BUBBLE_WIDTH + local_x, 11));
					use_bubble <= '1';
				end if;
			end if;
		end if;
	end process;

	-- gotta love transparency
	process(CLOCK_25)
	begin
		pixel_enable <= '0';

		if use_bubble = '1' and game_active = '1' then
			if bubble_pixel /= "000000000000" then
				pixel_enable <= '1';
				colour <= bubble_pixel;
			end if;
		end if;
	end process; 
	 
end architecture behaviour;