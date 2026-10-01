library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity demo is 
	port (CLOCK_50, CLOCK_25	: in std_logic;
		pixel_row, pixel_column, mouse_x, mouse_y : in std_logic_vector(9 downto 0);
		colour_0, colour_1 : out std_logic_vector(11 downto 0);
		enable_c1 : out std_logic);	
end entity demo;


architecture behaviour of demo is

	--component ball is
	--	port(clk : in std_logic;
	--		pixel_row, pixel_column, mouse_row, mouse_column : in std_logic_vector(9 downto 0);
	--		red, green, blue, draw_active : out std_logic);
	--end component ball;
	
	component cursor is 
		port (CLOCK_50, CLOCK_25 : in std_logic;
			pixel_row, pixel_column, mouse_x, mouse_y : in std_logic_vector(9 downto 0);
			colour : out std_logic_vector(11 downto 0);
			pixel_enable : out std_logic);
	end component cursor;
	
	component char_rom is
        port(character_address : IN STD_LOGIC_VECTOR (5 DOWNTO 0);  -- which letter
            font_row, font_col : IN STD_LOGIC_VECTOR (2 DOWNTO 0); -- which pixel inside letter
            clock : IN STD_LOGIC;
            rom_mux_output : OUT STD_LOGIC   -- 1 for draw 0 for not
        );
    end component char_rom;
	 
	 signal char_address : std_logic_vector(5 downto 0);
	 signal font_row, font_column : std_logic_vector(2 downto 0);
	 signal pixel_on, draw_char : std_logic;
	
begin
  -- demo script for interim interview
  -- has a cursor, text of various sizes, and basic layers
  
  
  process (CLOCK_25)  -- text in colour channel 0
	variable row_int, column_int : integer;
	variable char_index : integer;
  begin
		if rising_edge(CLOCK_25) then
			-- the text 'hello world' is hardcoded here, at time of writing I have not got a proper system for writing variable lengths of text
			
			row_int := to_integer(unsigned(pixel_row));
			column_int := to_integer(unsigned(pixel_column));
			
			if (row_int >= 50 and row_int < 58 and column_int >= 50 and column_int < 146) then
				-- small size (total length = 8 pixels * 12 characters = 96 pixels, which I then offset by + 50)
				
				char_index := (column_int - 50) / 8;  -- every 8 pixels moves onto the next char (rounds down)
				font_row <= std_logic_vector(to_unsigned(row_int - 50, 3));  -- which row inside letter (0 to 7)
				font_column <= std_logic_vector(to_unsigned((column_int - 50 - (char_index * 8)), 3));  -- which column inside letter (minus offset and current letter pos)
				
				draw_char <= '1';
				
			elsif (row_int >= 66 and row_int < 82 and column_int >= 50 and column_int < 242) then
				-- medium size, twice as big as small
				
				char_index := (column_int - 50) / 16;  -- every 16 pixels moves onto the next char
				font_row <= std_logic_vector(to_unsigned((row_int - 66) / 2, 3));
				font_column <= std_logic_vector(to_unsigned((column_int - 50 - (char_index * 16)) / 2, 3));
				
				draw_char <= '1';
				
			elsif (row_int >= 90 and row_int < 122 and column_int >= 50 and column_int < 434) then
				-- large size, twice as big as medium
			
				char_index := (column_int - 50) / 32;  -- every 32 pixels moves onto the next char
				font_row <= std_logic_vector(to_unsigned((row_int - 90) / 4, 3));
				font_column <= std_logic_vector(to_unsigned((column_int - 50 - (char_index * 32)) / 4, 3));
				
				draw_char <= '1';
			
			else 
				draw_char <= '0';
			end if;
				
			-- Pick the letter based on char_index
			case char_index is
				when 0 => char_address <= "001000";  -- H
				when 1 => char_address <= "000101";  -- E
				when 2 => char_address <= "001100";  -- L
				when 3 => char_address <= "001100";  -- L
				when 4 => char_address <= "001111";  -- O
				when 5 => char_address <= "100000";  -- [space]
				when 6 => char_address <= "010111";  -- W
				when 7 => char_address <= "001111";  -- O
				when 8 => char_address <= "010010";  -- R
				when 9 => char_address <= "001100";  -- L
				when 10 => char_address <= "000100";  -- D
				when 11 => char_address <= "100001";  -- !
				when others => char_address <= "000000";
			end case;
		end if;
  end process;
  
  colour_0 <= pixel_on & pixel_on & pixel_on & pixel_on & pixel_on & pixel_on & pixel_on & pixel_on & pixel_on & pixel_on & pixel_on & pixel_on when draw_char = '1' else "000000000000";
  
  
  --CURSOR : ball port map(CLOCK_25, pixel_row, pixel_column, mouse_x, mouse_y, r_1, g_1, b_1, enable_c1);
  CURSOR1 : cursor port map(CLOCK_50, CLOCK_25, pixel_row, pixel_column, mouse_x, mouse_y, colour_1, enable_c1);  -- red square cursor in colour channel 1
  CHAR_ROM1 : char_rom PORT MAP(char_address, font_row, font_column, CLOCK_25, pixel_on);
  
end architecture behaviour;
