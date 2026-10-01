library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;


entity floor is 
	port (CLOCK_25       : in std_logic;
			pixel_row    : in std_logic_vector(9 downto 0);
			pixel_column : in std_logic_vector(9 downto 0);
			colour       : out std_logic_vector(11 downto 0);
			pixel_enable : out std_logic
		);
end entity floor;


architecture behaviour of floor is
    component floor_rom is
        port (
            address : in std_logic_vector(16 downto 0);
            clock   : in std_logic;
            q       : out std_logic_vector(1 downto 0)
        );
    end component;

    constant FLOOR_Y : integer := 370; -- height where the floor starts

    signal floor_address : std_logic_vector(16 downto 0);
    signal floor_pixel : std_logic_vector(1 downto 0);

    signal local_x : integer range 0 to 639;
    signal local_y : integer range 0 to 109;
    signal inside_floor : std_logic;

begin
	-- ensure floor is drawn in the correct vertical range
	process(pixel_row, pixel_column)
        variable row_int : integer;
        variable col_int : integer;
    begin
        row_int := to_integer(unsigned(pixel_row));
        col_int := to_integer(unsigned(pixel_column));

        if row_int >= FLOOR_Y and row_int < FLOOR_Y + 110 then
            inside_floor <= '1';
            local_x <= col_int;
            local_y <= row_int - FLOOR_Y;
        else
            inside_floor <= '0';
            local_x <= 0;
            local_y <= 0;
        end if;
    end process;

    floor_address <= std_logic_vector(to_unsigned(local_x + local_y * 640, 17));

	FLR_ROM: floor_rom port map(address => floor_address, clock => CLOCK_25, q => floor_pixel);

	-- the important thing, converting 2 bit to vga colour values RRRRGGGGBBBB
	process(CLOCK_25)
	begin
		if rising_edge(CLOCK_25) then
        if inside_floor = '1' and floor_pixel /= "00" then
            pixel_enable <= '1'; 

		    case floor_pixel is
			    when "01" =>
				    colour <= "000100100111";
			    when "10" =>
				    colour <= "000100010101";
			    when "11" =>
				    colour <= "000000000100";
             when others =>
                pixel_enable <= '0';
                colour <= "000000000000";
			 end case;
        else
            pixel_enable <= '0';
            colour <= "000000000000";
        end if;
		end if;
	end process;

end architecture behaviour;

