library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;


entity pipe is 
	port(CLOCK_25, game_tick, reset  : in std_logic;
        start_x							: in integer;
        level								: in std_logic_vector(1 downto 0);
        rand_bits							: in std_logic_vector(7 downto 0);
        pixel_row, pixel_column		: in std_logic_vector(9 downto 0);
		  game_active, is_paused 		: in std_logic;
		  bubble_collected				: in std_logic;
        pipe_x_out, gap_y_out       : out integer;
        bubble_active               : out std_logic;
        colour								: out std_logic_vector(11 downto 0);
        pixel_enable						: out std_logic;
        pipe_passed                 : out std_logic);
end entity pipe;


architecture behaviour of pipe is
	-- movement, collisions, gap generation, etc
	-- will probably be used as 3 components, so have an input for 'delay' or something so the 3 versions of this can be distance controlled
	-- this code only needs to be for one pair of pipes

    component pipe_top is
        port (
    	    address		: in std_logic_vector(11 downto 0);
		    clock		: in std_logic := '1';
		    q		: out std_logic_vector(11 downto 0)
        );
    end component pipe_top;

    component pipe_strip is
        port (
    	    address		: in std_logic_vector(6 downto 0);
		    clock		: in std_logic := '1';
		    q		: out std_logic_vector(11 downto 0)
        );
    end component pipe_strip;

	 constant SCREEN_WIDTH : integer := 640;
    constant PIPE_WIDTH : integer := 76;
    constant GAP_HEIGHT : integer := 120; -- changable depending on how we feel
    constant MIN_PIPE_HEIGHT : integer := 53; -- that's just the height the top of the column is (i'm lazy)
	 constant GAP_RANGE : integer := 454 - GAP_HEIGHT - (2 * MIN_PIPE_HEIGHT) + 1;

    signal pipe_x : integer range -100 to 2000; -- actual range of pipe (so it can despawn off-screen)
    signal gap_y : integer range 0 to 480;
    signal pipe_speed : integer range 1 to 9 := 2;

    signal top_address   : std_logic_vector(11 downto 0);
    signal strip_address : std_logic_vector(6 downto 0);
    signal top_pixel   : std_logic_vector(11 downto 0);
    signal strip_pixel : std_logic_vector(11 downto 0);
    signal use_top   : std_logic := '0';
    signal use_strip : std_logic := '0';
	 
	 -- used to reset pipes when game starts. would've used rising_edge(game_active) but quartus synthesiser is a lil bitch (it's me I'm the bitch)
	 signal game_active_prev : std_logic := '0';
begin

    -- instantiate ROMs
    TOP_ROM : pipe_top port map (address => top_address, clock => CLOCK_25, q => top_pixel);
    STRIP_ROM : pipe_strip port map (address => strip_address, clock => CLOCK_25, q => strip_pixel);

    process(level)
	-- level based speed based on fsm code, +250% of the original speed each time
    begin
        case level is
            when "00" =>
                pipe_speed <= 1;
            when "01" =>
                pipe_speed <= 2;
            when "10" =>
                pipe_speed <= 4;
            when others =>
                pipe_speed <= 1;
        end case;
    end process;

	-- movement 
	process(game_tick, reset)
    begin
        if (reset = '1' or (game_active = '1' and game_active_prev = '0')) then  -- reset when button hit or when game starts anew
				pipe_x <= start_x;
				if (start_x = 650) then -- EWWWWW
					gap_y <= 130;
				elsif (start_x = 889) then
					gap_y <= 79;
				elsif (start_x = 1128) then
					gap_y <= 208;
				end if;
				bubble_active <= '0';
				game_active_prev <= '1';
				
		  elsif (game_active = '0' and game_active_prev = '1') then  -- flip flop :D
				game_active_prev <= '0';
		  
        elsif (rising_edge(game_tick) and is_paused = '0' and game_active = '1') then
            
				-- if pipe reaches width of pipe off screen then despawn
            if pipe_x <= -PIPE_WIDTH then
                pipe_x <= SCREEN_WIDTH;
                gap_y <= MIN_PIPE_HEIGHT + (to_integer(unsigned(rand_bits)) mod GAP_RANGE);
					 
                -- bubble collectable handling
                if rand_bits(0) = '0' then  -- 50/50 chance
                    bubble_active <= '1';
                else
                    bubble_active <= '0';
                end if;
					 		 
            else
                pipe_x <= pipe_x - pipe_speed;
            end if;
				
				if bubble_collected = '1' then
					bubble_active <= '0';
				end if;
				
        end if;
    end process;

    -- rendering process
    process(CLOCK_25)  -- always use CLOCK_25 when rendering!!
        variable row_int : integer;
        variable col_int : integer;

        -- more variables
        variable local_y : integer; -- for tracking 2D pipe_top rom
        variable local_x : integer; 
        variable top_cap_y : integer;
        variable bottom_cap_y : integer;
    begin
        -- drawing pipes
        if (rising_edge(CLOCK_25)) then
            row_int := to_integer(unsigned(pixel_row));
            col_int := to_integer(unsigned(pixel_column));
		
            use_top <= '0';
            use_strip <= '0';

            -- set to zero for now
            top_address <= "000000000000";
            strip_address <= "0000000";

            top_cap_y := gap_y - MIN_PIPE_HEIGHT;
            bottom_cap_y := gap_y + GAP_HEIGHT;

            if col_int >= pipe_x and col_int < pipe_x + PIPE_WIDTH then
                local_x := col_int - pipe_x;

                if row_int < gap_y then
                    if row_int >= top_cap_y then
                        -- flipped vertically top
                        local_y := MIN_PIPE_HEIGHT - 1 - (row_int - top_cap_y);
                        top_address <= std_logic_vector(to_unsigned(local_y * PIPE_WIDTH + local_x, 12));
                        use_top <= '1';
                    else
                        -- if it's outside the range of top, then use strip
                        strip_address <= std_logic_vector(to_unsigned(local_x, 7));
                        use_strip <= '1';
                    end if;
                elsif row_int >= bottom_cap_y then
                    -- repeat except for bottom so no vertical transform needed
                    if row_int < bottom_cap_y + MIN_PIPE_HEIGHT then
                        local_y := row_int - bottom_cap_y;
                        top_address <= std_logic_vector(to_unsigned(local_y * PIPE_WIDTH + local_x, 12));
                        use_top <= '1';
                    else
                        strip_address <= std_logic_vector(to_unsigned(local_x, 7));
                        use_strip <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
	
    -- transparency handling
    process(CLOCK_25) -- you're welcome harry   (thanks -Harry)
    begin
        pixel_enable <= '0';

        if use_top = '1' then
            if top_pixel /= "000000000000" then
                pixel_enable <= game_active;
                colour <= top_pixel;
            end if;
        elsif use_strip = '1' then
            if strip_pixel /= "000000000000" then
                pixel_enable <= game_active;
                colour <= strip_pixel;
            end if;
        end if;
    end process;

    -- assigning pipe_x and gap_y outputs
    pipe_x_out <= pipe_x;
    gap_y_out <= gap_y;
	 
	 pipe_passed <= '1' when (pipe_x > 250 and pipe_x < 270) else '0'; -- we passed the middle (range because top speed we could accidentally pass exactly 320px)

end architecture behaviour;