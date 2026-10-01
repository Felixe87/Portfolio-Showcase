library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity bird is 
	port (CLOCK_25, CLOCK_tick, reset : in std_logic;
		jump, game_active, is_paused, pipe_pixel_enabled, bubble_pixel_enabled : in std_logic;
		pixel_row, pixel_column : in std_logic_vector(9 downto 0);
		level : in std_logic_vector(1 downto 0);
		collision, collected : out std_logic;
		colour : out std_logic_vector(11 downto 0);
		pixel_enable : out std_logic);
end entity bird;


architecture behaviour of bird is
	component jellyfishes_rom is
        port (
            address : in std_logic_vector(13 downto 0);
            clock   : in std_logic := '1';
            q       : out std_logic_vector(11 downto 0)
        );
    end component jellyfishes_rom;
	
	-- modify these two to get the best 'feel' in the game
	constant MAX_VELOCITY : integer := 10;  -- maximum speed
	constant JUMP_VELOCITY : integer := 14;  -- speed added to velocity when jumping
	
	constant HITBOX_X : integer := 49;  -- width
	constant HITBOX_Y : integer := 57;  -- height
	constant MAX_Y : integer := (0 + (HITBOX_Y / 2));  -- top
	constant MIN_Y : integer := (450 - (HITBOX_Y / 2));  -- bottom

	constant SPRITE_WIDTH : integer := 48;
	constant SPRITE_HEIGHT : integer := 56;
	constant FRAME_SIZE : integer := SPRITE_WIDTH * SPRITE_HEIGHT;
	constant ANIM_COUNTER_MAX : integer := 2000000; -- we adding a counter!! (change this speed when testing)
	
	signal CLOCK_bird, CLOCK_flash : std_logic := '0';
	signal restart : std_logic;
	signal game_running : std_logic;
	
	signal velocity : integer range -MAX_VELOCITY*2 to MAX_VELOCITY*2 := 0;  -- *2 to prevent overflow
	signal bird_y : integer range MAX_Y - MAX_VELOCITY to MIN_Y + MAX_VELOCITY := 240;
	signal jump_prev, game_active_prev : std_logic := '0';  -- this is so that we don't constantly go up if you hold the mouse down
	signal draw_sprite : std_logic;
	signal collision_occured, collection_occured, collection_timer_active, immune : std_logic := '0';
	signal colletable_occured: std_logic := '0'; -- new
	signal immune_timer : integer range 0 to 62499999 := 0;
	signal collected_timer : integer range 0 to 833334 := 0;  -- should be enough time surely
	signal flash_counter : integer range 0 to 3124999;

	-- rendering signals
	signal vignette_enable : std_logic := '0';
	signal vignette_colour : std_logic_vector(11 downto 0);
	signal jelly_address : std_logic_vector(13 downto 0);
	signal jelly_pixel : std_logic_vector(11 downto 0);
	signal current_frame : integer range 0 to 3 := 0;
	signal anim_counter : integer range 0 to ANIM_COUNTER_MAX := 0;
    signal jump_anim_active : std_logic := '0'; -- frames 3-4-3 pattern when jumping is playing
    signal jump_anim_step : integer range 0 to 2 := 0; -- which stage is playing?
    signal anim_jump_prev : std_logic := '0'; -- seperate from jump_prev since they might be on different clocks
    signal jelly_draw_request : std_logic := '0'; -- pixel_enable is a clock cycle in behind colour so add delay (ROM latency)
    signal jelly_draw_delayed : std_logic := '0';

	-- so yeah, apparently there was always a latency thing in the rom between pixel_enable and colour?
	-- we kinda just got away with it for everything else because it wasn't animated so switching doesn't happen often
begin


	-- VERY IMPORTANT NOTICE FOR ME AND ANYONE READING THIS:
	-- The bottom of the screen is NOT 0px, its actually 480px. The TOP is 0px!!!
	-- because of this all the numbers look unintuitive for 'gravity', so read this code as if gravity works upwards :D
	-- glad you figured that out 
	JELLY_ROM : jellyfishes_rom port map (address => jelly_address, clock => CLOCK_25, q => jelly_pixel);
	
	process (CLOCK_tick)  -- needed bcus og tick was too slow for pipes, but new tick too fast for bird (this adds only one latch so we good)
   begin
		-- 1/2 clock tick
		if rising_edge(CLOCK_tick) then
			CLOCK_bird <= not CLOCK_bird;
		end if;
   end process;
	
	process (CLOCK_25)
	begin
		if rising_edge(CLOCK_25) then
			if flash_counter = 3124999 then
				CLOCK_flash <= not CLOCK_flash;  -- update for 1 cycle
				flash_counter <= 0;
			else
				flash_counter <= flash_counter + 1;
			end if;
		end if;
	end process;
	
	
	process (CLOCK_25)  -- centralised to save logic components
	begin
		restart <= '0';
		if (game_active = '1' and game_active_prev = '0') then
			restart <= '1';
			game_active_prev <= '1';
		elsif (game_active = '0' and game_active_prev = '1') then
			game_active_prev <= '0';
		end if;
	end process;
	
	game_running <= '1' when (is_paused = '0' and game_active = '1') else '0';


	process (CLOCK_bird, reset)
	begin
		if (reset = '1' or restart = '1') then  -- reset when button hit or when game starts anew
			bird_y <= 240;
			velocity <= 0;
			jump_prev <= '0';
		  
		elsif (rising_edge(CLOCK_bird) and game_running = '1') then
			
			-- falling
			if (bird_y + velocity <= MIN_Y) then  -- check to avoid overflow
				if (bird_y + velocity >= MAX_Y) then
					bird_y <= bird_y + velocity;  -- fall/fly a bit
				else
					bird_y <= MAX_Y;  -- stay on ceiling
					velocity <= 0;
				end if;
			else
				bird_y <= MIN_Y;  -- remain on ground
				velocity <= 0;
			end if;
			
			if velocity < MAX_VELOCITY then  -- check to avoid overflow
				velocity <= velocity + 1;  -- accelerate downwards
			end if;
			
			-- jumping
			if (jump = '1' and jump_prev = '0') then -- edge detector for jump input
				-- technically with this check it's possible to click 'between frames', meaning you could miss an input
				-- however that's really hard to do in practice and I can't be bothered fixing it so suck it up
				
				if (velocity - JUMP_VELOCITY >= -MAX_VELOCITY) then  -- check to avoid overflow
					velocity <= velocity - JUMP_VELOCITY;  -- pull up! pull up!
				else
					velocity <= -MAX_VELOCITY;
				end if;
				
				jump_prev <= '1';  -- stop jumping
				
			elsif (jump = '0' and jump_prev = '1') then
				jump_prev <= '0';  -- button has been released, can jump again if needed
			end if;
			
		end if;
	end process;

	process(CLOCK_25, reset)
    begin
        if (reset = '1' or restart = '1') then
            current_frame <= 0;
            anim_counter <= 0;
            jump_anim_active <= '0';
            jump_anim_step <= 0;
            anim_jump_prev <= '0';

        elsif rising_edge(CLOCK_25) then
            if game_running = '1' then
                if (jump = '1' and anim_jump_prev = '0') then
				-- new jump press, resetting animation
                    jump_anim_active <= '1';
                    jump_anim_step <= 0;
                    current_frame <= 2;
                    anim_counter <= 0;
                    anim_jump_prev <= '1';
                elsif (jump = '0' and anim_jump_prev = '1') then
                    anim_jump_prev <= '0';
                elsif anim_counter = ANIM_COUNTER_MAX then
                    anim_counter <= 0;

                    if jump_anim_active = '1' then
                        -- jump animation sequence 3-4-3
                        case jump_anim_step is
                            when 0 =>
                                current_frame <= 3;
                                jump_anim_step <= 1;
                            when 1 =>
                                current_frame <= 2;
                                jump_anim_step <= 2;
                            when others =>
                                jump_anim_active <= '0';
                                current_frame <= 0;
                        end case;
                    else
                        if current_frame = 0 then
                            current_frame <= 1;
                        else
                            current_frame <= 0;
                        end if;
                    end if;
                else
                    anim_counter <= anim_counter + 1;
                end if;
            end if;
        end if;
    end process;
	
	-- collision code here. Will output when a collision happens so we can decrease the lives
	-- also when a collision happens you will be invulnerable for idk how long, and when thats happening flash in and out of existance
	collision_occured <= '1' when (immune = '0' and (bird_y = MIN_Y or (jelly_draw_delayed = '1' and jelly_pixel /= "000000000000" and pipe_pixel_enabled = '1'))) else '0';
	
	collection_occured <= '1' when (immune = '0' and jelly_draw_delayed = '1' and jelly_pixel /= "000000000000" and bubble_pixel_enabled = '1') else '0'; -- collecting a bubble (can't if you're a ghost)
	
	process(CLOCK_25, reset)
	begin
		if (reset = '1' or restart = '1') then
			immune <= '0';
			collision <= '0';
			collected <= '0';
		elsif rising_edge(CLOCK_25) then  -- somehow this creates one billion latches with the timer, so find a way to make it NOT do that
			if (collision_occured = '1' and game_running = '1') then
				immune <= '1';
				collision <= '1';
				immune_timer <= 0;  -- start timer
			end if;
			
			if (collection_occured = '1' and game_running = '1') then
				collected <= '1';
				collection_timer_active <= '1';
				collected_timer <= 0;
			end if;
			
			if collected_timer = 833334 then
				collected <= '0';
				collection_timer_active <= '0';
			elsif (collection_timer_active = '1' and game_running = '1') then
				collected_timer <= collected_timer + 1;
			end if;
		
			-- countdown timer to count immunity down
			if immune_timer = 62499999 then  -- 5 seconds
				immune <= '0';
				collision <= '0';
			elsif (immune = '1' and game_running = '1') then  -- make sure we actually want the timer to run
				immune_timer <= immune_timer + 1;
			end if;
		end if;
	end process;

	-- bird rendering
	process(CLOCK_25)
        variable row, col : integer;
        variable local_x, local_y : integer;
        variable sprite_left, sprite_top : integer;
        variable frame_offset : integer;
    begin
        if rising_edge(CLOCK_25) then

            row := to_integer(unsigned(pixel_row));
            col := to_integer(unsigned(pixel_column));
            jelly_draw_request <= '0';
            jelly_address <= "00000000000000";

			-- centering sprite (can change 320 depending)
            sprite_left := 320 - (SPRITE_WIDTH / 2);
            sprite_top := bird_y - (SPRITE_HEIGHT / 2);

            if col >= sprite_left and col < sprite_left + SPRITE_WIDTH and row >= sprite_top and row < sprite_top + SPRITE_HEIGHT and game_active = '1' then
                local_x := col - sprite_left;
                local_y := row - sprite_top;
                frame_offset := current_frame * FRAME_SIZE;
                jelly_address <= std_logic_vector(to_unsigned(frame_offset + local_y * SPRITE_WIDTH + local_x, 14));
                jelly_draw_request <= CLOCK_flash or not immune;
            end if;

            jelly_draw_delayed <= jelly_draw_request; -- matched pixel and colour
        end if;
    end process;

	-- vignette rendering
	process(CLOCK_25)
		variable row, col : integer;
		variable dx, dy : integer;
		variable rad_squared : integer;
		variable radius : integer;
	begin
		if rising_edge(CLOCK_25) then
			-- considered using just level but remembered y position constantly changes
			row := to_integer(unsigned(pixel_row));
			col := to_integer(unsigned(pixel_column));

			dx := col - 320;
			dy := row - bird_y;
			rad_squared := dx*dx + dy*dy;

			vignette_enable <= '0';

			if level = "01" then
				radius := 250;
				-- don't we just love math that could've been better math?
				if rad_squared > radius*radius then
					vignette_enable <= '1';
					vignette_colour <= "000000000100"; -- solid dark blue
				end if;

			elsif level = "10" then
				radius := 150;

				if rad_squared > radius*radius then
					vignette_enable <= '1';
					vignette_colour <= "000000000100";
				end if;
			end if;
		end if;
	end process;
	
	draw_sprite <= '1' when (jelly_draw_delayed = '1' and jelly_pixel /= "000000000000") else vignette_enable; -- handles transparency
	pixel_enable <= draw_sprite;  -- so we can read draw_sprite for collision purposes
	-- just leave black in there, it won't be displayed anyways, at least it means i don't need to put it in a process
	colour <= jelly_pixel when jelly_draw_delayed = '1' else vignette_colour when vignette_enable = '1' else "000000000000"; 

end architecture behaviour;

