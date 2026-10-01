library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity head is 
	port (CLOCK_50						   : in std_logic;
		SW								   : in std_logic_vector(9 downto 0);  -- Switches
		KEY								   : in std_logic_vector(3 downto 0); -- Buttons
		PS2_CLK, PS2_DAT				   : inout std_logic;  -- Mouse Data
		LEDR							   : out std_logic_vector(9 downto 0); -- LED's
		HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0);  -- 7seg displays
		VGA_R, VGA_G, VGA_B				   : out std_logic_vector(3 downto 0);  -- Display Colour Channels
		VGA_HS, VGA_VS					   : out std_logic);  -- Display Vertical and Horizontal Sync
end entity head;


architecture def of head is

	component layer_control is
		port(CLOCK_25 : in std_logic;
			colour_0, colour_1, colour_2, colour_3, colour_4, colour_5, colour_6, colour_7 : in std_logic_vector(11 downto 0);
			enable_channel : in std_logic_vector(6 downto 0);
			pixel_row, pixel_column : out std_logic_vector(9 downto 0);  -- current pixel we're drawing
			VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);  -- Display Colour Channels
			VGA_HS, VGA_VS : out std_logic);  -- Display Vertical and Horizontal Sync
	end component layer_control;
	
	component ui is
    port(CLOCK_25 : in std_logic;
        pixel_row, pixel_col : in std_logic_vector(9 downto 0);
        mouse_x, mouse_y : in std_logic_vector(9 downto 0);
        left_click : in std_logic;
        current_state : in std_logic_vector(2 downto 0);  -- 000=MAIN MENU, 001=MODE_SELECT, 010=GAME_OVER, 011=PAUSE, others=HIDE
        score : in integer range 0 to 999999;
		colour_buttons, colour_text : out std_logic_vector(11 downto 0);
        pixel_enable_buttons, pixel_enable_text : out std_logic;
        btn_training, btn_game, btn_start, btn_restart, btn_menu, btn_unpause : out std_logic);
	end component ui;
	
	component fsm is
    port(CLOCK_25, reset       : in std_logic;
        training_btn, game_btn, start_btn, main_menu_btn, restart_btn, pause_btn, unpause_btn : in std_logic;
        collision       : in std_logic;        -- 1=hit pipe
        passed_pipe     : in std_logic;        -- 1=passed pipe which adds to score
        collected     : in std_logic;        -- 1= +3 points
        game_active     : out std_logic;       -- 1=playing 0=not playing
        is_paused       : out std_logic;       -- 1=paused 0=playing
        level           : out std_logic_vector(1 downto 0);  -- "00"=L1 "01"=L2 "10"=L3
        lives           : out std_logic_vector(1 downto 0);  -- "00"=0 "01"=1 "10"=2 "11"=3
		  state				: out std_logic_vector(2 downto 0);
        score           : out integer range 0 to 999);
	end component fsm;
  
	component mouse is
		port(clock_25Mhz, reset 	  : IN std_logic;
			mouse_data				  : INOUT std_logic;
			mouse_clk 				  : INOUT std_logic;
			left_button, right_button : OUT std_logic;
			mouse_cursor_row 		  : OUT std_logic_vector(9 DOWNTO 0); 
			mouse_cursor_column 	  : OUT std_logic_vector(9 DOWNTO 0));       	
	end component mouse;
	
	component sevenseg_converter is
		port(binary_digit : in std_logic_vector(3 downto 0);
			sevenseg_out  : out std_logic_vector(6 downto 0));
	end component sevenseg_converter;
	
	component cursor is 
		port (CLOCK_25 : in std_logic;
			pixel_row, pixel_column, mouse_x, mouse_y : in std_logic_vector(9 downto 0);
			game_active, is_paused : in std_logic;
			colour : out std_logic_vector(11 downto 0);
			pixel_enable : out std_logic);
	end component cursor;

	component background is
		port (CLOCK_25 : in std_logic;
			game_tick : in std_logic;
			reset : in std_logic;
			game_active, is_paused : in std_logic;
			pixel_row : in std_logic_vector(9 downto 0);
			pixel_column : in std_logic_vector(9 downto 0);
			colour : out std_logic_vector(11 downto 0)
		);
	end component background;

	component lfsr is
		port (
			clk : in std_logic;
        	reset : in std_logic;
        	rand : out std_logic_vector(7 downto 0)
		);
	end component lfsr;

	component pipe is
		port(CLOCK_25, game_tick, reset : in std_logic;
        start_x							: in integer;
        level								: in std_logic_vector(1 downto 0);
        rand_bits							: in std_logic_vector(7 downto 0);
        pixel_row, pixel_column				: in std_logic_vector(9 downto 0);
		  game_active, is_paused : in std_logic;
		  bubble_collected				: in std_logic;
        pipe_x_out, gap_y_out               : out integer;
        bubble_active                       : out std_logic;
        colour								: out std_logic_vector(11 downto 0);
        pixel_enable						: out std_logic;
        pipe_passed                : out std_logic);
	end component pipe;

	component floor is
		port (CLOCK_25 : in std_logic;
			pixel_row : in std_logic_vector(9 downto 0);
			pixel_column : in std_logic_vector(9 downto 0);
			colour : out std_logic_vector(11 downto 0);
        	pixel_enable : out std_logic
		);
	end component floor;

	component bubble_collectable is
		port (
			CLOCK_25		 			: in std_logic;
			pipe_x, gap_y 				: in integer;
			bubble_active 				: in std_logic;
			pixel_row, pixel_column 	: in std_logic_vector(9 downto 0);
			game_active					: in std_logic;
			colour 						: out std_logic_vector(11 downto 0);
			pixel_enable				: out std_logic
		);
	end component bubble_collectable;
	
	component bird is 
		port (CLOCK_25, CLOCK_tick, reset : in std_logic;
			jump, game_active, is_paused, pipe_pixel_enabled, bubble_pixel_enabled : in std_logic;
			pixel_row, pixel_column : in std_logic_vector(9 downto 0);
			level : in std_logic_vector(1 downto 0);
			collision, collected : out std_logic;
			colour : out std_logic_vector(11 downto 0);
			pixel_enable : out std_logic);
	end component bird;
	
	component lives_visual is
		port(
			CLOCK_25 : in std_logic;
			lives : in std_logic_vector(1 downto 0);
			pixel_row, pixel_column : in std_logic_vector(9 downto 0);
			game_active : std_logic;
			colour : out std_logic_vector(11 downto 0);
			pixel_enable : out std_logic
		);
	end component lives_visual;

  
   -- Functionality
	signal CLOCK_25 : std_logic := '0';  -- start at 0 so first clock cycle it is synced with rising edge
	signal CLOCK_tick : std_logic := '0';
	signal game_tick_counter : integer range 0 to 416666 := 0;
	signal Reset 	: std_logic;
	-- Display
	signal colour_0, colour_1, colour_2, colour_3, colour_4, colour_5, colour_6, colour_7 : std_logic_vector(11 downto 0);  -- colours to be sent to VGA
	signal enable_channel : std_logic_vector(6 downto 0);
	signal enable_c1, enable_c2, enable_c3, enable_c4, enable_c5, enable_c6, enable_c7 : std_logic := '0';  -- colour channel enable control
	signal pixel_row, pixel_column : std_logic_vector(9 downto 0);  -- current row/column pixel being drawn
	-- Mouse
	signal mouse_rmb, mouse_lmb : std_logic;  -- Left and Right click
	signal mouse_x, mouse_y : std_logic_vector(9 downto 0);  -- co-ords of mouse position, max x = 640, y = 480
	-- Game
	signal game_active, is_paused : std_logic;
	signal rand_bits : std_logic_vector(7 downto 0);
	signal collision : std_logic;  -- is 1 when a collision occurs, turns to 0 when immunity is over
	signal collected : std_logic;  -- a collecable was touched
	signal passed_pipe : std_logic;  -- we passed a pipe
	signal current_menu : std_logic_vector(2 downto 0);  -- current menu being shown
	signal lives : std_logic_vector(1 downto 0);
	signal level : std_logic_vector(1 downto 0);  -- difficulty
	signal training_selected, game_selected, start_selected, main_menu_selected, restart_selected, unpause_selected : std_logic;
	signal score : integer range 0 to 999;
	signal score_ones, score_tens, score_hundreds, score_thousands, score_tenthousands, score_hundredthousands : std_logic_vector(3 downto 0);
	-- Shannanigans
	signal pipe1_x, pipe2_x, pipe3_x, pipe1_y, pipe2_y, pipe3_y : integer;
	signal bubble_active : std_logic;
	signal pipe1_colour, pipe2_colour, pipe3_colour : std_logic_vector(11 downto 0);
	signal pipe1_enable, pipe2_enable, pipe3_enable : std_logic;
	signal pipe1_passed, pipe2_passed, pipe3_passed : std_logic;  -- new pipe passed signals for each pipe
	signal lives_colour, ui_colour : std_logic_vector(11 downto 0);
	signal lives_enable, ui_enable : std_logic;
	
begin
  -- Port Definitions:
  Reset <= not KEY(0); -- all buttons must be inverse, i.e. make them active HIGH
  enable_channel(0) <= enable_c1;
  enable_channel(1) <= enable_c2;
  enable_channel(2) <= enable_c3;
  enable_channel(3) <= enable_c4;
  enable_channel(4) <= enable_c5;
  enable_channel(5) <= enable_c6;
  enable_channel(6) <= enable_c7;
  
  -- new combine all pipe passed signals into one
  passed_pipe <= pipe1_passed or pipe2_passed or pipe3_passed;
  enable_c1 <= pipe1_enable or pipe2_enable or pipe3_enable;
  colour_1 <= pipe1_colour when pipe1_enable = '1' else pipe2_colour when pipe2_enable = '1' else pipe3_colour when pipe3_enable = '1' else "000000000000";
  enable_c5 <= lives_enable or ui_enable;
  colour_5 <= lives_colour when lives_enable = '1' else ui_colour;
  
  -- LED's
  LEDR(9) <= Reset;
  LEDR(8) <= collision;
  
  
  -- Clock Divider(s)
  process (CLOCK_50)
  begin
	-- 25MHz clock generator (for rendering and mouse)
	if rising_edge(CLOCK_50) then
		CLOCK_25 <= not CLOCK_25;
	end if;
  end process;
  
  process (CLOCK_50)
  begin
	-- framerate (fps) clock generator for GAME UPDATES & logic (30Hz) (half speed of screen)
	if Reset = '1' then
		CLOCK_tick <= '0';
		game_tick_counter <= 0;
	elsif rising_edge(CLOCK_50) then
		if game_tick_counter = 416665 then
			CLOCK_tick <= not CLOCK_tick;  -- update for 1 cycle
			game_tick_counter <= 0;
      else
			game_tick_counter <= game_tick_counter + 1;
      end if;
	end if;
  end process;
  
  -- Score Display
  process(CLOCK_25)
  begin
	if rising_edge(CLOCK_25) then
		score_ones <= std_logic_vector(to_unsigned(score mod 10, 4));
		score_tens <= std_logic_vector(to_unsigned(((score mod 100) / 10), 4));
		score_hundreds <= std_logic_vector(to_unsigned(((score mod 1000) / 100), 4));
		score_thousands <= std_logic_vector(to_unsigned(((score mod 10000) / 1000), 4));
		score_tenthousands <= std_logic_vector(to_unsigned(((score mod 100000) / 10000), 4));
		score_hundredthousands <= std_logic_vector(to_unsigned(((score mod 1000000) / 100000), 4));
	end if;
  end process;
  
  
  
  
  -- Components
  DISPLAY : layer_control port map(CLOCK_25, colour_0, colour_1, colour_2, colour_3, colour_4, colour_5, colour_6, colour_7, enable_channel, 
  pixel_row, pixel_column, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS);
  
  FSM1 : fsm port map(CLOCK_25, Reset, training_selected, game_selected, start_selected, main_menu_selected, restart_selected, mouse_rmb, unpause_selected,
  collision, passed_pipe, collected, game_active, is_paused, level, lives, current_menu, score);
  
  MOUSE1 : mouse port map(CLOCK_25, Reset, PS2_DAT, PS2_CLK, mouse_lmb, mouse_rmb, mouse_y, mouse_x);
  CURSOR1 : cursor port map(CLOCK_25, pixel_row, pixel_column, mouse_x, mouse_y, game_active, is_paused, colour_7, enable_c7);
  BACKGROUND1 : background port map(CLOCK_25, CLOCK_tick, Reset, game_active, is_paused, pixel_row, pixel_column, colour_0);
  FLOOR1 : floor port map(CLOCK_25, pixel_row, pixel_column, colour_2, enable_c2);
  USER_INTERFACE : ui port map(CLOCK_25, pixel_row, pixel_column, mouse_x, mouse_y, mouse_lmb, current_menu, score,
  ui_colour, colour_6, ui_enable, enable_c6, training_selected, game_selected, start_selected, restart_selected, main_menu_selected, unpause_selected);

  LFSR1 : lfsr port map (CLOCK_25, Reset, rand_bits);
  
  PIPE1 : pipe port map (CLOCK_25, CLOCK_tick, Reset, 650, level, rand_bits, pixel_row, pixel_column, game_active, is_paused, collected,
  pipe1_x, pipe1_y, bubble_active, pipe1_colour, pipe1_enable, pipe1_passed);
  
  PIPE2 : pipe port map (CLOCK_25, CLOCK_tick, Reset, 889, level, rand_bits, pixel_row, pixel_column, game_active, is_paused, '0',
  pipe2_x, pipe2_y, open, pipe2_colour, pipe2_enable, pipe2_passed);
  
  PIPE3 : pipe port map (CLOCK_25, CLOCK_tick, Reset, 1128, level, rand_bits, pixel_row, pixel_column, game_active, is_paused, '0',
  pipe3_x, pipe3_y, open, pipe3_colour, pipe3_enable, pipe3_passed);
  
  BUBBLE : bubble_collectable port map(CLOCK_25, pipe1_x, pipe1_y, bubble_active, pixel_row, pixel_column, game_active, colour_3, enable_c3);
  
  LIVES1 : lives_visual port map(CLOCK_25, lives, pixel_row, pixel_column, game_active, lives_colour, lives_enable);
  
  JELLYFISH : bird port map(CLOCK_25, CLOCK_tick, Reset, mouse_lmb, game_active, is_paused, enable_c1, enable_c3, 
  pixel_row, pixel_column, level, collision, collected, colour_4, enable_c4);
  
  -- score display 7seg
  ONES : sevenseg_converter port map(score_ones, HEX0);
  TENS : sevenseg_converter port map(score_tens, HEX1);
  HUNDREDS : sevenseg_converter port map(score_hundreds, HEX2);
  THOUSANDS : sevenseg_converter port map(score_thousands, HEX3);
  TENTHOUSANDS : sevenseg_converter port map(score_tenthousands, HEX4);
  HUNDREDTHOUSANDS : sevenseg_converter port map(score_hundredthousands, HEX5);
  
end architecture def;