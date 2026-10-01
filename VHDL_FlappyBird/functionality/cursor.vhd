library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;


entity cursor is 
	port (CLOCK_25 : in std_logic;
		pixel_row, pixel_column, mouse_x, mouse_y : in std_logic_vector(9 downto 0);
		game_active, is_paused : in std_logic;
		colour : out std_logic_vector(11 downto 0);
		pixel_enable : out std_logic);
end entity cursor;


architecture behaviour of cursor is


	-- needs to be changed to revieve inputs from sprite_rom or perhaps another sprite reading file
	-- the current char_rom functionality is TEMPORARY (not anymoreeee, we have cursor rom now!!!)
	-- once we have a working sprite system this one will be the easiest to implement, so can be the example for other things like the jellyfish or pipes

	component cursor_rom is
		port (
			address : in std_logic_vector(7 downto 0);
			clock   : in std_logic := '1';
			q       : out std_logic_vector(11 downto 0)
		);
	end component cursor_rom;
	 
	constant CURSOR_WIDTH  : integer := 12;
	constant CURSOR_HEIGHT : integer := 19;

	signal cursor_address : std_logic_vector(7 downto 0);
	signal cursor_pixel : std_logic_vector(11 downto 0);
	signal draw_sprite : std_logic := '0';
	signal draw_sprite_delayed : std_logic := '0'; -- using the same delay system as bird

begin
	CURSOR_ROM1 : cursor_rom port map (address => cursor_address, clock => CLOCK_25, q => cursor_pixel);

	process (CLOCK_25)
		variable row_int : integer range 0 to 1024;
		variable col_int : integer range 0 to 1024;
		variable x       : integer range 0 to 1024;
		variable y       : integer range 0 to 1024;

		variable local_x : integer;
		variable local_y : integer;
	begin
		if rising_edge(CLOCK_25) then
			row_int := to_integer(unsigned(pixel_row));
			col_int := to_integer(unsigned(pixel_column));
			x := to_integer(unsigned(mouse_x));
			y := to_integer(unsigned(mouse_y));

			draw_sprite <= '0';
			cursor_address <= (others => '0');
			if row_int >= y and row_int < y + CURSOR_HEIGHT and col_int >= x and col_int < x + CURSOR_WIDTH then

				local_x := col_int - x;
				local_y := row_int - y;
				cursor_address <= std_logic_vector(to_unsigned(local_y * CURSOR_WIDTH + local_x, 8));

				draw_sprite <= '1';
			end if;

			draw_sprite_delayed <= draw_sprite;
		end if;
	end process;

  
  -- active when rendering sprite all the time, EXCEPT specifically when the game is ON and it's also NOT paused
  	process(CLOCK_25)
	begin
		pixel_enable <= '0';

		if draw_sprite_delayed = '1' and cursor_pixel /= "000000000000" and (not game_active or is_paused) = '1' then
			pixel_enable <= '1';
			colour <= cursor_pixel;
		end if;
	end process;

end architecture behaviour;