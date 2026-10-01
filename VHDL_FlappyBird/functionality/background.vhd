library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity background is 
	port (CLOCK_25 : in std_logic;
		game_tick : in std_logic;
		reset : in std_logic;
		game_active, is_paused : in std_logic;
		pixel_row : in std_logic_vector(9 downto 0);
		pixel_column : in std_logic_vector(9 downto 0);
		colour : out std_logic_vector(11 downto 0)
	);
end entity background;


architecture behaviour of background is

    component background_rom is
        port (
            address : in std_logic_vector(18 downto 0);
            clock   : in std_logic;
            q       : out std_logic_vector(1 downto 0)
        );
    end component;

	constant SCREEN_WIDTH : integer := 640;

	signal bg_address 	: unsigned(18 downto 0);
    signal bg_pixel   	: std_logic_vector(1 downto 0);
	signal bg_offset 	: integer range 0 to SCREEN_WIDTH - 1 := 0;

begin
	BG_ROM: background_rom port map(std_logic_vector(bg_address), CLOCK_25, bg_pixel);

	-- scrolling bg movement
	process(game_tick, reset)
	begin
		if reset = '1' then
			bg_offset <= 0;
		elsif rising_edge(game_tick) then
			if game_active = '1' and is_paused = '0' then
			-- we only want the offset to increase when game is playing
				if bg_offset = (SCREEN_WIDTH - 1) then
					bg_offset <= 0;
				else
					-- moves at 1 clock tick (so twice as slow as the lowest pipe speed)
					bg_offset <= bg_offset + 1;
				end if;
			end if;
		end if;
	end process;

	-- assigning address
	process(CLOCK_25)
		variable row_int  : integer;
		variable col_int  : integer;
		variable scroll_x : integer;
	begin
		if rising_edge(CLOCK_25) then
			row_int := to_integer(unsigned(pixel_row));
			col_int := to_integer(unsigned(pixel_column));

			scroll_x := col_int + bg_offset;

			if scroll_x >= SCREEN_WIDTH then
				scroll_x := scroll_x - SCREEN_WIDTH;
			end if;

			bg_address <= to_unsigned(row_int * SCREEN_WIDTH + scroll_x, 19);
		end if;
	end process;

	-- the important thing, converting 2 bit to vga colour values RRRRGGGGBBBB
	process(CLOCK_25)
	begin
		 if rising_edge(CLOCK_25) then
			  case bg_pixel is
					when "00" =>
						 colour <= "000010011111";  --111100001111
					when "01" =>
						 colour <= "001010001111";  --111111110000
					when "10" =>
						 colour <= "000001011100";  --000011111111
					when others =>
						 colour <= "000101001010";  --111100001111
			  end case;
		 end if;
	end process;

end architecture behaviour;

