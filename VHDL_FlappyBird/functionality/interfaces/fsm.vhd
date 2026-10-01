library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fsm is
    port(CLOCK_25, reset       : in std_logic;        -- key0
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
end entity fsm;

architecture behaviour of fsm is

    type state_type is (
        MAIN_MENU,      -- pick training or game
        HOLD,           -- click to start
        PLAYING,        -- game running
        PAUSED,         -- game frozen
        GAME_OVER       -- show score
    );
   
    signal current_state : state_type := MAIN_MENU;
    signal next_state    : state_type := MAIN_MENU;
   
    -- game variables
    signal lives_counter   : integer range 0 to 3 := 3;
    signal score_counter : unsigned(9 downto 0) := (others => '0');
    signal pipes_counter   : integer := 0;
	 signal game_mode : std_logic := '0';
	 signal passed_pipe_r, passed_pipe_pulse, collision_r, collision_pulse, collected_r, collected_pulse : std_logic;

begin

	 score <= to_integer(score_counter);
	 lives <= "11" when lives_counter = 3 else "10" when lives_counter = 2 else "01" when lives_counter = 1 else "00";
	 state <= "000" when current_state = MAIN_MENU 
			else "001" when current_state = HOLD 
			else "010" when current_state = GAME_OVER 
			else "011" when current_state = PAUSED 
			else "111";
			
			
			
	
	
	process(CLOCK_25)  -- fixing some of our timing issues
	begin
		 if rising_edge(CLOCK_25) then
			  passed_pipe_pulse <= passed_pipe and not passed_pipe_r;
			  passed_pipe_r <= passed_pipe;
		 end if;
	end process;
	process(CLOCK_25)
	begin
		 if rising_edge(CLOCK_25) then
			  collision_pulse <= collision and not collision_r;
			  collision_r <= collision;
		 end if;
	end process;
	process(CLOCK_25)
	begin
		 if rising_edge(CLOCK_25) then
			  collected_pulse <= collected and not collected_r;
			  collected_r <= collected;
		 end if;
	end process;
	
	
	
	 
	 

    -- this updates everything on each clock tick
    process(CLOCK_25, reset)
    begin
        if reset = '1' then
            -- reset everything
            lives_counter <= 3;
            score_counter <= to_unsigned(0, 10);
            pipes_counter <= 0;
        elsif rising_edge(CLOCK_25) then
            current_state <= next_state;  -- move onto the next state if it's changed, or remain in the state we are in
           
            -- add score when passing pipe
            if (current_state = PLAYING and passed_pipe_pulse = '1') then
                score_counter <= score_counter + 1;
                -- count pipes for level ups only in GAME game_mode.
                if game_mode = '1' then
                    pipes_counter <= pipes_counter + 1;
                end if;
            end if;
				
				-- add score when getting collectables
            if current_state = PLAYING and collected_pulse = '1' then
               score_counter <= score_counter + 2;  -- passing_pipe + collectable = + 3 score
            end if;
           
            -- lose life when hitting pipe or ground
            if (current_state = PLAYING and collision_pulse = '1') then
                if lives_counter > 0 then
                    lives_counter <= lives_counter - 1;
                end if;
            end if;
           
            -- set difficulty level based on pipes passed 25 pipe intervals, 3 difficulties so far
            if pipes_counter >= 50 then  -- 50
                level <= "10";  
            elsif pipes_counter >= 25 then  -- 25
                level <= "01";  
            else
                level <= "00";  
            end if;
				
				if current_state = HOLD or current_state = MAIN_MENU then  -- about to start a new game, reset (inneficient, but can't be bothered making it more efficient. IF IT AINT BROKE...)
					lives_counter <= 3;
					score_counter <= to_unsigned(0, 10);
					pipes_counter <= 0;
				end if;
           
        end if;
    end process;
   
    -- decides which state comes next
    process(CLOCK_25, reset)
    begin
		  if reset = '1' then
				next_state <= MAIN_MENU;
		  elsif rising_edge(CLOCK_25) then
			  case current_state is
			  
					when MAIN_MENU =>
						 game_active <= '0';
						 is_paused <= '1';
							  
						 if training_btn = '1' then
							  next_state <= HOLD;
							  game_mode <= '0';  -- training
						 elsif game_btn = '1' then
							  next_state <= HOLD;
							  game_mode <= '1';  -- game
						 end if;
						
					when HOLD =>
						 game_active <= '1';  -- activate game but keep paused (so we can see the jellyfish)
						 
						 if start_btn = '1' then
							  next_state <= PLAYING;
						 end if;
						
					when PLAYING =>
						 is_paused <= '0';
						 
						 if pause_btn = '1' then
							  next_state <= PAUSED;
						 elsif lives_counter = 0 then
							  next_state <= GAME_OVER;
						 end if;
						
					when PAUSED =>
						 is_paused <= '1';
						 
						 if unpause_btn = '1' then
							  next_state <= PLAYING;
						 elsif main_menu_btn = '1' then
							  next_state <= MAIN_MENU;
						 end if;
						 -- also add main menu button
						
					when GAME_OVER =>
						 is_paused <= '1';
						 
						 if restart_btn = '1' then  -- again!
							  game_active <= '0';  -- reset temporarily
							  next_state <= HOLD;
						 elsif main_menu_btn = '1' then  -- I give up :(
							  next_state <= MAIN_MENU;
						 end if;     
			  end case;
		  end if;
    end process;

end architecture behaviour;