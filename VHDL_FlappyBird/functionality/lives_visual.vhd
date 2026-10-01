library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;


entity lives_visual is
    port(
        CLOCK_25 : in std_logic;
        lives : in std_logic_vector(1 downto 0);
        pixel_row, pixel_column : in std_logic_vector(9 downto 0);
		  game_active : std_logic;
        colour : out std_logic_vector(11 downto 0);
        pixel_enable : out std_logic
    );
end entity lives_visual;

architecture behaviour of lives_visual is
    component golden_clamshell_rom is
        port(
		    address		: in std_logic_vector(9 downto 0);
		    clock		: in std_logic  := '1';
		    q		: out std_logic_vector(11 downto 0)
	    );
    end component golden_clamshell_rom;

    component silver_clamshell_rom is
        port(
		    address		: in std_logic_vector(9 downto 0);
		    clock		: in std_logic  := '1';
		    q		: out std_logic_vector(11 downto 0)
	    );
    end component silver_clamshell_rom;

    constant CLAM_WIDTH  : integer := 26;
    constant CLAM_HEIGHT : integer := 22;
    constant CLAM_GAP : integer := 5; -- constant gap between clams
    constant PADDING_X : integer := 14; -- padding from edge of the screen
    constant PADDING_Y : integer := 10;
    constant SCREEN_HEIGHT : integer := 480;
    constant CLAM_Y : integer := SCREEN_HEIGHT - PADDING_Y - CLAM_HEIGHT;

    constant CLAM1_X : integer := PADDING_X;
    constant CLAM2_X : integer := CLAM1_X + CLAM_WIDTH + CLAM_GAP;
    constant CLAM3_X : integer := CLAM2_X + CLAM_WIDTH + CLAM_GAP;

    signal clam_address : std_logic_vector(9 downto 0); -- one address since BOTH are same size
    signal golden_pixel, silver_pixel : std_logic_vector(11 downto 0);
    signal use_golden, draw_sprite : std_logic := '0';

begin
-- instantiate roms
    GOLDEN : golden_clamshell_rom port map(address => clam_address, clock => CLOCK_25, q => golden_pixel);
    SILVER : silver_clamshell_rom port map(address => clam_address, clock => CLOCK_25, q => silver_pixel);

    process(CLOCK_25)
        variable row_int : integer;
		variable col_int : integer;
		variable lives_int  : integer;
		variable local_x : integer;
		variable local_y : integer;
    begin
        if rising_edge(CLOCK_25) then
				row_int := to_integer(unsigned(pixel_row));
				col_int := to_integer(unsigned(pixel_column));
            lives_int := to_integer(unsigned(lives));

            clam_address <= "0000000000";
				use_golden <= '0';
				draw_sprite <= '0';

            if col_int >= CLAM1_X and col_int < CLAM1_X + CLAM_WIDTH and row_int >= CLAM_Y and row_int < CLAM_Y + CLAM_HEIGHT then
                -- first clam
                local_x := col_int - CLAM1_X;
                local_y := row_int - CLAM_Y;
                clam_address <= std_logic_vector(to_unsigned(local_y * CLAM_WIDTH + local_x, 10));
					 
					 draw_sprite <= '1';

                if lives_int >= 1 then
                    use_golden <= '1';
                end if;
            elsif col_int >= CLAM2_X and col_int < CLAM2_X + CLAM_WIDTH and row_int >= CLAM_Y and row_int < CLAM_Y + CLAM_HEIGHT then
                -- second clam
                local_x := col_int - CLAM2_X;
                local_y := row_int - CLAM_Y;
                clam_address <= std_logic_vector(to_unsigned(local_y * CLAM_WIDTH + local_x, 10));
					 
					 draw_sprite <= '1';

                if lives_int >= 2 then
                    use_golden <= '1';
                end if;
            elsif col_int >= CLAM3_X and col_int < CLAM3_X + CLAM_WIDTH and row_int >= CLAM_Y and row_int < CLAM_Y + CLAM_HEIGHT then
                -- third clam
                local_x := col_int - CLAM3_X;
                local_y := row_int - CLAM_Y;
                clam_address <= std_logic_vector(to_unsigned(local_y * CLAM_WIDTH + local_x, 10));
					 
					 draw_sprite <= '1';

                if lives_int >= 3 then
                    use_golden <= '1';
                end if;
            end if;
        end if;
    end process;

    -- transparency handling
    process(CLOCK_25)
    begin
        pixel_enable <= '0';
		  
		  if (game_active = '1' and draw_sprite = '1') then
			  if use_golden = '1' then
					if golden_pixel /= "000000000000" then
						 pixel_enable <= '1';
						 colour <= golden_pixel;
					end if;
			  else
					if silver_pixel /= "000000000000" then
						 pixel_enable <= '1';
						 colour <= silver_pixel;
					end if;
			  end if;
		  end if;
    end process;


end architecture behaviour;