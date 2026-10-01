library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ui is
    port(CLOCK_25 : in std_logic;
        pixel_row, pixel_col : in std_logic_vector(9 downto 0);
        mouse_x, mouse_y : in std_logic_vector(9 downto 0);
        left_click : in std_logic;
        current_state : in std_logic_vector(2 downto 0);  -- 000=MAIN MENU, 001=START, 010=GAME_OVER, 011=PAUSE, 111=GAMEPLAY, others=HIDE
        score : in integer range 0 to 999999;
        colour_buttons, colour_text : out std_logic_vector(11 downto 0);
        pixel_enable_buttons, pixel_enable_text : out std_logic;
        btn_training, btn_game, btn_start, btn_restart, btn_menu, btn_unpause : out std_logic);
end entity ui;

architecture behaviour of ui is
    component char_rom is
        port(
            character_address : in std_logic_vector(5 downto 0);
            font_row, font_col : in std_logic_vector(2 downto 0);
            clock : in std_logic;
            rom_mux_output : out std_logic
        );
    end component;
	 
	 
	 -- screen size: 480x64-- all positions are measured from top-left corner pixel
	 constant TITLE_X_POS : integer := 144;-- 11 * 32 = 352   ->  (640 - 352) / 2 = 144 (size 32)
	 constant TITLE_Y_POS : integer := 100;
	 constant TRAINING_TEXT_X_POS : integer := 256;  -- 8 * 16 = 128  ->  (640- 128) / 2 = 256 (size 16)
	 constant TRAINING_TEXT_Y_POS : integer := 296;
	 constant GAME_TEXT_X_POS : integer := 288;  -- 4 * 16 = 64  ->  (640 - 64) / 2 = 288 (size 16)
	 constant GAME_TEXT_Y_POS : integer := 232;
	 constant START_TEXT_X_POS : integer := 208;  -- "click to start" (640 - 14 * 16) / 2 = 208
	 constant START_TEXT_Y_POS : integer := 400;  -- near bottom
	 constant GAME_OVER_TEXT_X_POS : integer := 160;  -- (640 - 10 * 32) / 2 = 160
	 constant GAME_OVER_TEXT_Y_POS : integer := 200;  -- slightly higher than middle to accommodate score
	 constant MAIN_MENU_TEXT_X_POS : integer := 248;  -- (640 - 9 * 16) / 2 = 248
	 constant MAIN_MENU_TEXT_Y_POS : integer := 340;
	 constant RESTART_TEXT_X_POS : integer := 264;  -- (640 - 7 * 16) / 2 = 264
	 constant RESTART_TEXT_Y_POS : integer := 400;
	 constant RESUME_TEXT_X_POS : integer := 272;  -- (640 - 6 * 16) / 2 = 272
	 constant RESUME_TEXT_Y_POS : integer := RESTART_TEXT_Y_POS;
	 constant QUIT_TEXT_X_POS : integer := MAIN_MENU_TEXT_X_POS;
	 constant QUIT_TEXT_Y_POS : integer := MAIN_MENU_TEXT_Y_POS;
     constant SCORE_GAME_X_POS : integer := 482; -- SCORE 000, (640 - 14 - 9 * 16) = 482, bottom-right
     constant SCORE_GAME_Y_POS : integer := 451; -- center aligned with lives rendering
     constant SCORE_OVER_X_POS : integer := 248; -- centred under GAME OVER
     constant SCORE_OVER_Y_POS : integer := 248; -- change this and GAME_OVER_TEXT_Y_POS as needed
	 
	 constant PADDING : integer := 8;  -- pixels between text and edge of button
	 
	 constant BUTTON_COLOUR : std_logic_vector(11 downto 0) := "100101011101";  -- purple
	 --constant BUTTON_HOVER_COLOUR : std_logic_vector(11 downto 0) := "000011111111";
	 
	 
	 
    
    signal char_address : std_logic_vector(5 downto 0);
    signal font_row, font_col : std_logic_vector(2 downto 0);
    signal pixel_on, idk_man_i_want_this_project_done_rn, text_enable : std_logic;
    
    signal mouse_x_int, mouse_y_int : integer;
    signal left_click_prev : std_logic := '0';
    
begin
    CHAR_ROM1 : char_rom port map(char_address, font_row, font_col, CLOCK_25, pixel_on);
    
    mouse_x_int <= to_integer(unsigned(mouse_x));
    mouse_y_int <= to_integer(unsigned(mouse_y));
	 colour_buttons <= BUTTON_COLOUR;
	 pixel_enable_text <= text_enable or idk_man_i_want_this_project_done_rn;
    
    process(pixel_row, pixel_col, current_state, pixel_on, score)
        -- added score to sensitivity (idk if it'll break it)
        variable row_int, col_int : integer;
        variable letter_index : integer;

        variable score_display : integer range 0 to 999;
        variable score_digit : integer range 0 to 9;
        variable score_x_pos : integer;
        variable score_y_pos : integer;
    begin
        row_int := to_integer(unsigned(pixel_row));
        col_int := to_integer(unsigned(pixel_col));

        -- just to keep it neat in game, really unrealistic anyone makes it past 999
        if score > 999 then
            score_display := 999;
        else
            score_display := score;
        end if;
        
		  colour_text <= (others => '0');
        pixel_enable_buttons <= '0';
		  text_enable <= '0';
		  idk_man_i_want_this_project_done_rn <= '0';
        
        
        -- Mode select screen (state "001")
        -- Shows Training and Game buttons with green boxes
        if current_state = "000" then
		  
				-- Title flappy bird
			  if row_int >= TITLE_Y_POS and row_int < TITLE_Y_POS + 32 and col_int >= TITLE_X_POS and col_int < TITLE_X_POS + (11 * 32) then
					letter_index := (col_int - TITLE_X_POS) / 32;
					font_row <= std_logic_vector(to_unsigned((row_int - TITLE_Y_POS) / 4, 3));
					font_col <= std_logic_vector(to_unsigned((col_int - TITLE_X_POS - (letter_index * 32)) / 4, 3));
					case letter_index is
						when 0 => char_address <= "000110";  -- F (6)
						when 1 => char_address <= "001100";  -- L (12)
						when 2 => char_address <= "000001";  -- A (1)
						when 3 => char_address <= "010000";  -- P (16)
						when 4 => char_address <= "010000";  -- P (16)
						when 5 => char_address <= "011001";  -- Y (25)
						when 6 => char_address <= "100000";  -- space (32)
						when 7 => char_address <= "000010";  -- B (2)
						when 8 => char_address <= "001001";  -- I (9)
						when 9 => char_address <= "010010";  -- R (18)
						when 10 => char_address <= "000100"; -- D (4)
						when others => char_address <= "000000";
					end case;
					colour_text <= "111111111111";  -- white
					text_enable <= pixel_on;
			  end if;
			  -- strikethrough
			  if row_int >= TITLE_Y_POS + 12 and row_int < TITLE_Y_POS + 20 and col_int >= TITLE_X_POS + (7 * 32) - 4 and col_int < TITLE_X_POS + (11 * 32) + 4 then
               colour_text <= "111100111110";
					idk_man_i_want_this_project_done_rn <= '1';
			  end if;
			  -- new text
			  if row_int >= TITLE_Y_POS + 32 and row_int < TITLE_Y_POS + 64 and col_int >= TITLE_X_POS + (7 * 32) and col_int < TITLE_X_POS + (11 * 32) then
					letter_index := (col_int - (TITLE_X_POS + (7 * 32))) / 32;
					font_row <= std_logic_vector(to_unsigned((row_int - TITLE_Y_POS) / 4, 3));
					font_col <= std_logic_vector(to_unsigned((col_int - TITLE_X_POS - (letter_index * 32)) / 4, 3));
					case letter_index is
						when 0 => char_address <= "000110";  -- F
						when 1 => char_address <= "001001";  -- I
						when 2 => char_address <= "010011";  -- S
						when 3 => char_address <= "001000";  -- H
						when others => char_address <= "000000";
					end case;
					colour_text <= "111100111110";  -- pink
					text_enable <= pixel_on;
			  end if;
            
            -- Training button green box 
            if (row_int >= TRAINING_TEXT_Y_POS - PADDING and row_int < TRAINING_TEXT_Y_POS + PADDING + 16 and col_int >= TRAINING_TEXT_X_POS - PADDING and col_int < TRAINING_TEXT_X_POS + PADDING + (8 * 16)) then
                pixel_enable_buttons <= '1';
            end if;
            
            -- Training text 
            if (row_int >= TRAINING_TEXT_Y_POS and row_int < TRAINING_TEXT_Y_POS + 16 and col_int >= TRAINING_TEXT_X_POS and col_int < TRAINING_TEXT_X_POS + (8 * 16)) then
                letter_index := (col_int - TRAINING_TEXT_X_POS) / 16;
                font_row <= std_logic_vector(to_unsigned((row_int - TRAINING_TEXT_Y_POS) / 2, 3));
                font_col <= std_logic_vector(to_unsigned((col_int - TRAINING_TEXT_X_POS - (letter_index * 16)) / 2, 3));
                case letter_index is
                    when 0 => char_address <= "010100";  -- T (20)
                    when 1 => char_address <= "010010";  -- R (18)
                    when 2 => char_address <= "000001";  -- A (1)
                    when 3 => char_address <= "001001";  -- I (9)
                    when 4 => char_address <= "001110";  -- N (14)
                    when 5 => char_address <= "001001";  -- I (9)
                    when 6 => char_address <= "001110";  -- N (14)
                    when 7 => char_address <= "000111";  -- G (7)
                    when others => char_address <= "000000";
               end case;
               colour_text <= "111111111111";  -- white
					text_enable <= pixel_on;
            end if;
            
            -- Game button green box 
            if (row_int >= GAME_TEXT_Y_POS - PADDING and row_int < GAME_TEXT_Y_POS + PADDING + 16 and col_int >= GAME_TEXT_X_POS - PADDING and col_int < GAME_TEXT_X_POS + PADDING + (4 * 16)) then
                pixel_enable_buttons <= '1';
            end if;
            
            -- Game text 
            if (row_int >= GAME_TEXT_Y_POS and row_int < GAME_TEXT_Y_POS + 16 and col_int >= GAME_TEXT_X_POS and col_int < GAME_TEXT_X_POS + (4 * 16)) then
                letter_index := (col_int - GAME_TEXT_X_POS) / 16;
                font_row <= std_logic_vector(to_unsigned((row_int - GAME_TEXT_Y_POS) / 2, 3));
                font_col <= std_logic_vector(to_unsigned((col_int - GAME_TEXT_X_POS - (letter_index * 16)) / 2, 3));
                case letter_index is
                    when 0 => char_address <= "010000";  -- P
                    when 1 => char_address <= "001100";  -- L
                    when 2 => char_address <= "000001";  -- A
                    when 3 => char_address <= "011001";  -- Y
                    when others => char_address <= "000000";
                end case;
                colour_text <= "111111111111";  -- white
                text_enable <= pixel_on;
            end if;
				
		   -- click to start
         elsif current_state = "001" then
				
            if row_int >= START_TEXT_Y_POS and row_int < START_TEXT_Y_POS + 16 and col_int >= START_TEXT_X_POS and col_int < START_TEXT_X_POS + (14 * 16) then
                letter_index := (col_int - START_TEXT_X_POS) / 16;
                font_row <= std_logic_vector(to_unsigned((row_int - START_TEXT_Y_POS) / 2, 3));
                font_col <= std_logic_vector(to_unsigned((col_int - START_TEXT_X_POS - (letter_index * 16)) / 2, 3));
                case letter_index is
                    when 0 => char_address <= "000011";  -- C
                    when 1 => char_address <= "001100";  -- L
                    when 2 => char_address <= "001001";  -- I
                    when 3 => char_address <= "000011";  -- C
						  when 4 => char_address <= "001011";  -- K
						  when 5 => char_address <= "100000";  -- (space)
						  when 6 => char_address <= "010100";  -- T
						  when 7 => char_address <= "001111";  -- O
						  when 8 => char_address <= "100000";  -- (space)
						  when 9 => char_address <= "010011";  -- S
						  when 10 => char_address <= "010100";  -- T
						  when 11 => char_address <= "000001";  -- A
						  when 12 => char_address <= "010010";  -- R
						  when 13 => char_address <= "010100";  -- T
                    when others => char_address <= "000000";
                end case;
                colour_text <= "111111111111";  -- white
                text_enable <= pixel_on;
            end if;
				
			-- GAME OVER BRO
			elsif current_state = "010" then
			
				if row_int >= GAME_OVER_TEXT_Y_POS and row_int < GAME_OVER_TEXT_Y_POS + 32 and col_int >= GAME_OVER_TEXT_X_POS and col_int < GAME_OVER_TEXT_X_POS + (10 * 32) then
                letter_index := (col_int - GAME_OVER_TEXT_X_POS) / 32;
                font_row <= std_logic_vector(to_unsigned((row_int - GAME_OVER_TEXT_Y_POS) / 4, 3));
                font_col <= std_logic_vector(to_unsigned((col_int - GAME_OVER_TEXT_X_POS - (letter_index * 32)) / 4, 3));
                case letter_index is
                    when 0 => char_address <= "000111";  -- G
                    when 1 => char_address <= "000001";  -- A
                    when 2 => char_address <= "001101";  -- M
                    when 3 => char_address <= "000101";  -- E
						  when 4 => char_address <= "100000";  -- (space)
						  when 5 => char_address <= "001111";  -- O
						  when 6 => char_address <= "010110";  -- V
						  when 7 => char_address <= "000101";  -- E
						  when 8 => char_address <= "010010";  -- R
						  when 9 => char_address <= "100001";  -- !
                    when others => char_address <= "000000";
                end case;
                colour_text <= "111100111110"; -- pink
                text_enable <= pixel_on;
            end if;

                -- score vga display
                if row_int >= SCORE_OVER_Y_POS and row_int < SCORE_OVER_Y_POS + 16 and col_int >= SCORE_OVER_X_POS and col_int < SCORE_OVER_X_POS + (9 * 16) then
                    letter_index := (col_int - SCORE_OVER_X_POS) / 16;
                    font_row <= std_logic_vector(to_unsigned((row_int - SCORE_OVER_Y_POS) / 2, 3));
                    font_col <= std_logic_vector(to_unsigned((col_int - SCORE_OVER_X_POS - (letter_index * 16)) / 2, 3));

                    case letter_index is
                        when 0 => char_address <= "010011"; -- S
                        when 1 => char_address <= "000011"; -- C
                        when 2 => char_address <= "001111"; -- O
                        when 3 => char_address <= "010010"; -- R
                        when 4 => char_address <= "000101"; -- E
                        when 5 => char_address <= "100000"; -- space
                        when 6 =>
                            score_digit := score_display / 100;
                            char_address <= std_logic_vector(to_unsigned(48 + score_digit, 6));
                        when 7 =>
                            score_digit := (score_display mod 100) / 10;
                            char_address <= std_logic_vector(to_unsigned(48 + score_digit, 6));
                        when 8 =>
                            score_digit := score_display mod 10;
                            char_address <= std_logic_vector(to_unsigned(48 + score_digit, 6));
                        when others =>
                            char_address <= "100000";
                    end case;

                    colour_text <= "111100111110"; -- pink
                    text_enable <= pixel_on;
                end if;
				
				-- main menu
				if (row_int >= MAIN_MENU_TEXT_Y_POS - PADDING and row_int < MAIN_MENU_TEXT_Y_POS + PADDING + 16 and col_int >= MAIN_MENU_TEXT_X_POS - PADDING and col_int < MAIN_MENU_TEXT_X_POS + PADDING + (9 * 16)) then
                pixel_enable_buttons <= '1';
            end if;
				
				if row_int >= MAIN_MENU_TEXT_Y_POS and row_int < MAIN_MENU_TEXT_Y_POS + 16 and col_int >= MAIN_MENU_TEXT_X_POS and col_int < MAIN_MENU_TEXT_X_POS + (9 * 16) then
                letter_index := (col_int - MAIN_MENU_TEXT_X_POS) / 16;
                font_row <= std_logic_vector(to_unsigned((row_int - MAIN_MENU_TEXT_Y_POS) / 2, 3));
                font_col <= std_logic_vector(to_unsigned((col_int - MAIN_MENU_TEXT_X_POS - (letter_index * 16)) / 2, 3));
                case letter_index is
                    when 0 => char_address <= "001101";  -- M
                    when 1 => char_address <= "000001";  -- A
                    when 2 => char_address <= "001001";  -- I
                    when 3 => char_address <= "001110";  -- N
						  when 4 => char_address <= "100000";  -- (space)
						  when 5 => char_address <= "001101";  -- M
						  when 6 => char_address <= "000101";  -- E
						  when 7 => char_address <= "001110";  -- N
						  when 8 => char_address <= "010101";  -- U
                    when others => char_address <= "000000";
                end case;
                colour_text <= "111111111111";
                text_enable <= pixel_on;
            end if;
				
				-- restart
				if (row_int >= RESTART_TEXT_Y_POS - PADDING and row_int < RESTART_TEXT_Y_POS + PADDING + 16 and col_int >= RESTART_TEXT_X_POS - PADDING and col_int < RESTART_TEXT_X_POS + PADDING + (7 * 16)) then
                pixel_enable_buttons <= '1';
            end if;
				
				if row_int >= RESTART_TEXT_Y_POS and row_int < RESTART_TEXT_Y_POS + 16 and col_int >= RESTART_TEXT_X_POS and col_int < RESTART_TEXT_X_POS + (7 * 16) then
                letter_index := (col_int - RESTART_TEXT_X_POS) / 16;
                font_row <= std_logic_vector(to_unsigned((row_int - RESTART_TEXT_Y_POS) / 2, 3));
                font_col <= std_logic_vector(to_unsigned((col_int - RESTART_TEXT_X_POS - (letter_index * 16)) / 2, 3));
                case letter_index is
                    when 0 => char_address <= "010010";  -- R
                    when 1 => char_address <= "000101";  -- E
                    when 2 => char_address <= "010011";  -- S
                    when 3 => char_address <= "010100";  -- T
						  when 4 => char_address <= "000001";  -- A
						  when 5 => char_address <= "010010";  -- R
						  when 6 => char_address <= "010100";  -- T
                    when others => char_address <= "000000";
                end case;
                colour_text <= "111111111111";
                text_enable <= pixel_on;
            end if;
				
			-- pause
			elsif current_state = "011" then
				
				-- bars are 25x100, spaced 20px apart (this is for the big pause button)
				if row_int >= 240 - 50 and row_int < 240 + 50 and col_int >= 310 - 25 and col_int < 310 then
					colour_text <= "111111111111";
               idk_man_i_want_this_project_done_rn <= '1';
				elsif row_int >= 240 - 50 and row_int < 240 + 50 and col_int >= 330 and col_int < 330 + 25 then
					colour_text <= "111111111111";
               idk_man_i_want_this_project_done_rn <= '1';
				end if;
			
			
				if (row_int >= RESUME_TEXT_Y_POS - PADDING and row_int < RESUME_TEXT_Y_POS + PADDING + 16 and col_int >= RESUME_TEXT_X_POS - PADDING and col_int < RESUME_TEXT_X_POS + PADDING + (6 * 16)) then
                pixel_enable_buttons <= '1';
            end if;
				
            if row_int >= RESUME_TEXT_Y_POS and row_int < RESUME_TEXT_Y_POS + 16 and col_int >= RESUME_TEXT_X_POS and col_int < RESUME_TEXT_X_POS + (6 * 16) then
                letter_index := (col_int - RESUME_TEXT_X_POS) / 16;
                font_row <= std_logic_vector(to_unsigned((row_int - RESUME_TEXT_Y_POS) / 2, 3));
                font_col <= std_logic_vector(to_unsigned((col_int - RESUME_TEXT_X_POS - (letter_index * 16)) / 2, 3));
                case letter_index is
						  when 0 => char_address <= "010010";  -- R
						  when 1 => char_address <= "000101";  -- E
						  when 2 => char_address <= "010011";  -- S
						  when 3 => char_address <= "010101";  -- U
						  when 4 => char_address <= "001101";  -- M
						  when 5 => char_address <= "000101";  -- E
                    when others => char_address <= "000000";
                end case;
                colour_text <= "111111111111";  -- white
                text_enable <= pixel_on;
            end if;
				
				if (row_int >= QUIT_TEXT_Y_POS - PADDING and row_int < QUIT_TEXT_Y_POS + PADDING + 16 and col_int >= QUIT_TEXT_X_POS - PADDING and col_int < QUIT_TEXT_X_POS + PADDING + (9 * 16)) then
                pixel_enable_buttons <= '1';
            end if;
				
				if row_int >= QUIT_TEXT_Y_POS and row_int < QUIT_TEXT_Y_POS + 16 and col_int >= QUIT_TEXT_X_POS and col_int < QUIT_TEXT_X_POS + (9 * 16) then
                letter_index := (col_int - QUIT_TEXT_X_POS) / 16;
                font_row <= std_logic_vector(to_unsigned((row_int - QUIT_TEXT_Y_POS) / 2, 3));
                font_col <= std_logic_vector(to_unsigned((col_int - QUIT_TEXT_X_POS - (letter_index * 16)) / 2, 3));
                case letter_index is
                    when 0 => char_address <= "001101";  -- M
                    when 1 => char_address <= "000001";  -- A
                    when 2 => char_address <= "001001";  -- I
                    when 3 => char_address <= "001110";  -- N
						  when 4 => char_address <= "100000";  -- (space)
						  when 5 => char_address <= "001101";  -- M
						  when 6 => char_address <= "000101";  -- E
						  when 7 => char_address <= "001110";  -- N
						  when 8 => char_address <= "010101";  -- U
                    when others => char_address <= "000000";
                end case;
                colour_text <= "111111111111";
                text_enable <= pixel_on;
                end if;

            -- gameplay
            elsif current_state = "111" then
                if row_int >= SCORE_GAME_Y_POS and row_int < SCORE_GAME_Y_POS + 16 and col_int >= SCORE_GAME_X_POS and col_int < SCORE_GAME_X_POS + (9 * 16) then
                    letter_index := (col_int - SCORE_GAME_X_POS) / 16;
                    font_row <= std_logic_vector(to_unsigned((row_int - SCORE_GAME_Y_POS) / 2, 3));
                    font_col <= std_logic_vector(to_unsigned((col_int - SCORE_GAME_X_POS - (letter_index * 16)) / 2, 3));

                    case letter_index is
                        when 0 => char_address <= "010011"; -- S
                        when 1 => char_address <= "000011"; -- C
                        when 2 => char_address <= "001111"; -- O
                        when 3 => char_address <= "010010"; -- R
                        when 4 => char_address <= "000101"; -- E
                        when 5 => char_address <= "100000"; -- space
                        when 6 =>
                            score_digit := score_display / 100;
                            char_address <= std_logic_vector(to_unsigned(48 + score_digit, 6));
                        when 7 =>
                            score_digit := (score_display mod 100) / 10;
                            char_address <= std_logic_vector(to_unsigned(48 + score_digit, 6));
                        when 8 =>
                            score_digit := score_display mod 10;
                            char_address <= std_logic_vector(to_unsigned(48 + score_digit, 6));
                        when others =>
                            char_address <= "100000";
                    end case;

                    colour_text <= "111111111111";
                    text_enable <= pixel_on;
                end if;
            end if;
    end process;
    
    -- Mouse button detection if hovered over
    process(CLOCK_25)
    begin
        if rising_edge(CLOCK_25) then
            btn_training <= '0';
            btn_game <= '0';
            btn_start <= '0';
				btn_menu <= '0';
				btn_restart <= '0';
				btn_unpause <= '0';
            
            
				if left_click = '1' and left_click_prev = '0' then
					-- Mode select screen: Training and game buttons
					if current_state = "000" then
						 if (mouse_y_int >= TRAINING_TEXT_Y_POS - PADDING and mouse_y_int < TRAINING_TEXT_Y_POS + PADDING + 16 and mouse_x_int >= TRAINING_TEXT_X_POS - PADDING and mouse_x_int < TRAINING_TEXT_X_POS + PADDING + (8 * 16)) then
							  btn_training <= '1';
						 elsif (mouse_y_int >= GAME_TEXT_Y_POS - PADDING and mouse_y_int < GAME_TEXT_Y_POS + PADDING + 16 and mouse_x_int >= GAME_TEXT_X_POS - PADDING and mouse_x_int < GAME_TEXT_X_POS + PADDING + (4 * 16)) then
							  btn_game <= '1';
						 end if;
					end if;
						 
					-- Hold screen: "PRESS START" button
					if current_state = "001" then
						 btn_start <= '1';  -- click anywhere
					end if;
						 
						 -- game over
					if current_state = "010" then
						if (mouse_y_int >= MAIN_MENU_TEXT_Y_POS - PADDING and mouse_y_int < MAIN_MENU_TEXT_Y_POS + PADDING + 16 and mouse_x_int >= MAIN_MENU_TEXT_X_POS - PADDING and mouse_x_int < MAIN_MENU_TEXT_X_POS + PADDING + (9 * 16)) then
							 btn_menu <= '1';
						elsif (mouse_y_int >= RESTART_TEXT_Y_POS - PADDING and mouse_y_int < RESTART_TEXT_Y_POS + PADDING + 16 and mouse_x_int >= RESTART_TEXT_X_POS - PADDING and mouse_x_int < RESTART_TEXT_X_POS + PADDING + (7 * 16)) then
							 btn_restart <= '1';
						end if;
					end if;
						 
					if current_state = "011" then
						if (mouse_y_int >= QUIT_TEXT_Y_POS - PADDING and mouse_y_int < QUIT_TEXT_Y_POS + PADDING + 16 and mouse_x_int >= QUIT_TEXT_X_POS - PADDING and mouse_x_int < QUIT_TEXT_X_POS + PADDING + (9 * 16)) then
							 btn_menu <= '1';
						elsif (mouse_y_int >= RESUME_TEXT_Y_POS - PADDING and mouse_y_int < RESUME_TEXT_Y_POS + PADDING + 16 and mouse_x_int >= RESUME_TEXT_X_POS - PADDING and mouse_x_int < RESUME_TEXT_X_POS + PADDING + (6 * 16)) then
							 btn_unpause <= '1';
						end if;
					end if;
					
					left_click_prev <= '1';
					
				elsif left_click = '0' and left_click_prev = '1' then
					left_click_prev <= '0';
				end if;
				
        end if;
    end process;
    
end architecture behaviour;