library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

entity layer_control is
	port(CLOCK_25 : in std_logic;
	colour_0, colour_1, colour_2, colour_3, colour_4, colour_5, colour_6, colour_7 : in std_logic_vector(11 downto 0);
	enable_channel : in std_logic_vector(6 downto 0);
	pixel_row, pixel_column : out std_logic_vector(9 downto 0);  -- current pixel we're drawing
	VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);  -- Display Colour Channels
	VGA_HS, VGA_VS : out std_logic);  -- Display Vertical and Horizontal Sync
end entity layer_control;

architecture behaviour of layer_control is

  component vga_sync is
	port(clock_25Mhz : IN	STD_LOGIC;
			colour_in : IN	STD_LOGIC_VECTOR(11 DOWNTO 0);
			colour_out : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
			horiz_sync_out, vert_sync_out	: OUT	STD_LOGIC;
			pixel_row, pixel_column: OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
  end component vga_sync;
  
  signal colour, colour_vga : std_logic_vector(11 downto 0);

begin

	-- the plan for this file is there will be 7 pixel layers in order of priority
	-- 0 is background (lowest priority, doesn't need an enable because it's always on)
	-- 1 is pipes
	-- 2 is 'floor' (you're welcome rachel)
	-- 3 is various sprites (e.g. collectables)
	-- 4 is the jellyfish & vignette/spotlight (the two follow each other and will never cross, so same priority)
	-- 5 is menu (buttons, hearts, etc)
	-- 6 is text
	-- 7 is cursor (highest priority)
	-- all pixel data will be sent here and whatever is the highest priority that's being recieved will be sent to vga_sync
	-- when a pixel @ row/col is being drawn, the functions that want to draw there will set their enable to 1, and then will be sorted here
	-- this 'enable' signal is needed, because if I just check if the channels are active, then I'd never be able to draw BLACK on a higher channel
	
	-- format of colour is RRRRGGGGBBBB
	
	VGA : vga_sync port map(CLOCK_25, colour, colour_vga, VGA_HS, VGA_VS, pixel_row, pixel_column);
	
	colour <= colour_7 when enable_channel(6) = '1' else
          colour_6 when enable_channel(5) = '1' else
          colour_5 when enable_channel(4) = '1' else
          colour_4 when enable_channel(3) = '1' else
          colour_3 when enable_channel(2) = '1' else
          colour_2 when enable_channel(1) = '1' else
          colour_1 when enable_channel(0) = '1' else
          colour_0;
	
	-- send components to display
	VGA_R <= colour_vga(11 downto 8);
	VGA_G <= colour_vga(7 downto 4);
	VGA_B <= colour_vga(3 downto 0);

end architecture behaviour;
