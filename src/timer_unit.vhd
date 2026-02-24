library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ceas is
      Port (
            clk: in std_logic;
            ONEsec: out std_logic;
            
            parallel_load_s: in std_logic_vector(6 downto 0);
            reset_s:in std_logic;
            enable_parallel_load_s:in std_logic;
            counting_s:out std_logic_vector(6 downto 0);
            
            parallel_load_m:in std_logic_vector(6 downto 0);
            reset_m:in std_logic;
            enable_parallel_load_m:in std_logic;
            counting_m:out std_logic_vector(6 downto 0);
            
            done_clock: out std_logic
                 );
end ceas;

architecture Behavioral of ceas is
constant board_frequency: integer := 100000000;
signal counter: integer :=0; 
signal finish: std_logic :='0';

signal numarare_s,numarare_m: unsigned(6 downto 0):=(others=> '0');
signal gata_numararea: std_logic:='0';

begin
process(clk)
begin
    if rising_edge(clk) then    
        if counter=board_frequency-1 then 
            finish <= '1';
            counter <= 0;
        else
            finish <= '0';
            counter <= counter + 1;
        end if;
    end if;
end process;

ONEsec<=finish;

process(clk)
begin
    if rising_edge(clk) then

        if reset_s='1' or reset_m='1' then
            numarare_s <= (others=>'0');
            numarare_m <= (others=>'0');

        elsif enable_parallel_load_s='1' or enable_parallel_load_m='1' then

            if enable_parallel_load_s='1' then
                numarare_s <= unsigned(parallel_load_s);
            end if;

            if enable_parallel_load_m='1' then
                numarare_m <= unsigned(parallel_load_m);
            end if;

        elsif finish='1' then
            if numarare_s = 0 then
                if numarare_m > 0 then
                    numarare_s <= "0111011"; -- 59
                    numarare_m <= numarare_m - 1;
                end if;
            else
                numarare_s <= numarare_s - 1;
            end if;
        end if;
    end if;
end process;

counting_s <= std_logic_vector(numarare_s);
counting_m <= std_logic_vector(numarare_m);

process(clk)
begin
    if rising_edge(clk) then
        if enable_parallel_load_s='1' or enable_parallel_load_m='1' or reset_s='1' or reset_m='1' then
            gata_numararea<='0';
        elsif numarare_s=0 and numarare_m=0 then
            gata_numararea<='1';
        end if;
    end if;
end process;

done_clock<=gata_numararea;

end Behavioral;
