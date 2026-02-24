library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AUTOMAT_MASINA_DE_SPALAT is
 Port ( 
        set_temperatura: in std_logic_vector(2 downto 0);--000=inactiv,001=30°C,10=40°C,11=60°C ,100=90 grade
        set_viteza: in std_logic_vector(1 downto 0);-- 00=800,01=1000,10=1200 rpm
        select_AUTO:in std_logic_vector(2 downto 0);-- 001 prespalare,010 spalare,011 clatire,100 clatire 2,101 centrifugare
        usa_inchisa :in std_logic;  -- prin apasarea unui buton sa inchidem usa       
        start: in std_logic;
        clk: in std_logic;
        
        --butoanele pentru inregistrarea inputului de la utilizator
        buton_stanga: in std_logic;
        buton_dreapta: in std_logic;
        buton_reset:in std_logic;

        
        --pentru SSD
        anod_arr:out std_logic_vector(7 downto 0);
        catod_arr:out std_logic_vector(6 downto 0);
        
        --output pe leduri
         start_LED: out std_logic;--1
         blocked_door:out std_logic;--2
         start_wash: out std_logic;--3
         target_temp: out std_logic_vector(2 downto 0);--4 000 inactiv,1 30 grade ,2 40 grade ,3 60 grade, 4 90 grade  
         target_speed: out std_logic_vector(1 downto 0);--5 00 inactiv,01 800,10 1000,11 1200 RPM 
         washing_states: out std_logic_vector(2 downto 0);--000INAFARA SPALARII,--001prespalare 010spalare 011clatire 100clatire2 101centrifugare 110asteptare 1 minut--5
         apa_incalzita:out std_logic;
         LED_prespalare:out std_logic;
         LED_clatire2:out std_logic
       --  MASINA_DE_SPALAT_READY_LED:out std_logic--dupa ce setarile spalarii sunt realizate si timpul e calculat,aprindem un led,ca sa stie user-ul ca poate apasa butonul de incepere a spalarii
        --in plus,variabilele pentru Seven Seg Display(SSD)
         );
end AUTOMAT_MASINA_DE_SPALAT;

architecture Behavioral of AUTOMAT_MASINA_DE_SPALAT is
type stare_tip is(INACTIV,SELECTARE_MOD,MOD_AUTO,SET_TEMP,SET_VIT,SELECT_PRESP,SELECT_CLATIRE_SUP,CALC_TIMP_TOTAL,NUMARATOARE_INVERSA_DEBLOCARE_USA,INCEPE_SPALAREA,EXEC_PRESPALARE,EXEC_SPALARE_PRINCIPALA,EXEC_CLATIRE,EXEC_CLATIRE2,EXEC_CENTRIFUGARE,WAIT_USA_DEBL,INCALZIRE_APA);
signal stare: stare_tip := INACTIV;

signal timer_loaded: std_logic := '0';  --pentru ca numaratorul sa nu se incarce de mai multe ori pentru a creea posibilitatea intarzierilor
signal clk_60Hz:std_logic:='0';

    signal minute: integer:=40;--minimul pentru fiecare tip de spalare,orice setari ar fi facute
    signal secunde: integer:=0;--secunde,la inceput

signal secunde_int: integer:=0;
signal minute_int: integer:=0;

signal minute_bcd:std_logic_vector(7 downto 0);
signal secunde_bcd:std_logic_vector(7 downto 0);

signal timp_formatSSD: std_logic_vector(31 downto 0):=(others=>'0');
signal zeroes:std_logic_vector(15 downto 0):=(others => '0');

signal target_temp_semnal:std_logic_vector(2 downto 0):="000";
signal target_temp_semnal_int:integer:=0;
    signal t_heat : integer:=15;
    signal secunde_incalzire_apa:integer:=0;

signal minute_semnal:std_logic_vector(6 downto 0):=(others=>'0');
signal secunde_semnal:std_logic_vector(6 downto 0):=(others=>'0');

signal minute_presp:integer:=0;
signal secunde_presp:integer:=0;

signal minute_SP:integer:=0;
signal secunde_SP:integer:=0;

signal minute_C:integer:=0;
signal secunde_C:integer:=0;

signal minute_C2:integer:=0;
signal secunde_C2:integer:=0;

signal minute_CEN:integer:=0;
signal secunde_CEN:integer:=0;

signal secunde_1min:integer :=0;

constant T_PRESP        : integer := 10;  -- 10 min prespălare = 600s
constant T_WASH         : integer := 20; -- 20 min spălare principală = 1200s
constant T_RINSE       : integer := 10;  -- 10 min clătire = 600s
constant T_CLATIRE2       : integer := 20;--clatire de 2 ori
constant T_SPIN         : integer := 10;  -- 10 min centrifugare = 600s
constant T_UNLOCK       : integer := 60;   -- 1 min deblocat ușa
--definesc o variabila intr-un proces pentru contorizarea timpului

-- Parametri curenți și semnale interne:
    signal current_temp  : integer := 0;  -- temperatura selectată (°C)
    signal current_speed : integer := 0;  -- viteza selectată (rpm)
    signal prespalare_flag  : std_logic := '0';
    signal clatire2_flag   : std_logic := '0';
    signal heating_time  : integer := 0;  -- secunde de încălzire necesare
    signal remain_sec    : integer := 0;  -- secunde rămase în starea curentă
    
    signal total_time: integer := 0;--0 la inceput
    signal display_total_time : std_logic := '1';  -- 1 = afișăm timpul total (în selecție), 0 = timpul rămas (în execuție)
    
    -- definirea componentelor
    signal reset_intern:std_logic:='0';
    signal clk_out_intern:std_logic:='0';
    signal enable_intern:std_logic:='0';
    component Frequency_Divider
        port(clk_in: in std_logic;
            reset:in std_logic;
            clk_out:out std_logic;
            enable:out std_logic
        );
    end component;
    
    --definirea a 2 MPG-uri pentru 2 butoane,buton_stanga si buton_dreapta
    signal buton_stanga_ACTIVE:std_logic:='0';
    signal buton_dreapta_ACTIVE:std_logic:='0';
    signal buton_reset_ACTIVE:std_logic:='0';

    signal r_s:std_logic:='0';
    signal r_m:std_logic:='0';

    
    component MPGLISMAN
    Port ( btn : in STD_LOGIC;
           clk : in STD_LOGIC;
           en : out STD_LOGIC);
    end component;
    
    --cronometru
    component ceas
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
            
            
            done_clock: out std_logic--pentru semnalizarea terminarii numararii
                 );
    end component;
    --semnale pentru ceas
    signal tick_1sec: std_logic:='0';
    signal enable_parallel_m:std_logic:='0';
    signal enable_parallel_s:std_logic:='0';
    signal counting_s_semnal:std_logic_vector(6 downto 0);
    signal counting_m_semnal:std_logic_vector(6 downto 0);
    
    component SSD
        Port ( clk : in STD_LOGIC;
           digits : in STD_LOGIC_VECTOR(31 downto 0);
           an : out STD_LOGIC_VECTOR(7 downto 0);
           cat : out STD_LOGIC_VECTOR(6 downto 0));
    END COMPONENT;
    
    component Frequency_Divider_la_60Hz
            Port ( clk_placa : in STD_LOGIC;
            reset:in std_logic;
           clk_rez : out STD_LOGIC);
    end component;
    
    --functie pentru a transforma un numar pe 2 cifre intr-un std_logic pe 8 biti ,in care prima cifra e pe primii 4 biti iar a doua cifra pe ultimii 4 biti
    function to_bcd(val: integer) return std_logic_vector is
        variable bcd: std_logic_vector(7 downto 0);
        variable tens, ones: integer;
    begin
        tens := val / 10;
        ones := val mod 10;
        bcd := std_logic_vector(to_unsigned(tens, 4)) & std_logic_vector(to_unsigned(ones, 4));
        return bcd;
    end function;
    
begin
  --seven segm management
  SevenSeg:SSD
  port map(
        clk=>clk,
        digits=>timp_formatSSD,
        an=>anod_arr,
        cat=>catod_arr
        );
  
--  FD60hz:Frequency_Divider_la_60Hz
--  port map(clk_placa=>clk,
--           reset=>'0',
--            clk_rez=>clk_60Hz); 
  
--  --divizorul de frecventa 
--  FD:Frequency_Divider 
--  port map(clk_in=>clk,
--           reset=>'0',
--           clk_out=>clk_out_intern,
--            enable=>enable_intern
  --);
  --MPG,pentru cele 2 butoane dreapta ,apoi stanga
  MPG_1L:MPGLISMAN
  port map( btn=>buton_dreapta,
            clk=>CLK,
            en=>buton_dreapta_ACTIVE
           );
   MPG_2L:MPGLISMAN
   port map(btn=>buton_stanga,
        clk=>clk,
         en=>buton_stanga_ACTIVE
     );
     
   MPG_3L:MPGLISMAN
   port map(btn=>buton_reset,
            clk=>clk,
            en=>buton_reset_ACTIVE
     );

  
  --componenta de cronometru 
    crono:ceas
    port map(clk=>clk,
            ONEsec=>tick_1sec,
            parallel_load_s=>secunde_semnal,
            reset_s=>r_s,
            enable_parallel_load_s=>enable_parallel_s,
            counting_s=>counting_s_semnal,
            parallel_load_m=>minute_semnal,
            reset_m=>r_m,
            enable_parallel_load_m=>enable_parallel_m,
            counting_m=>counting_m_semnal
        );
  --proces pentru FSM
    process(clk)
    variable minute_1: integer:=40;
    variable secunde_1:integer:=0;
    begin   
        if buton_reset_ACTIVE='1' and start='0' and usa_inchisa='0' then
               -- Reset toate semnalele la valorile inițiale
            stare <= INACTIV;
            blocked_door <= '0';
            start_LED <= '0';
            start_wash <= '0';
            target_speed <= "00";
            target_temp <= "000";
            washing_states <= "000";
            apa_incalzita <= '0';
            LED_prespalare <= '0';
            LED_clatire2 <= '0';
            
            -- Reset variabile și semnale interne
            target_temp_semnal <= "000";
            t_heat <= 15;
            secunde_incalzire_apa <= 0;
            prespalare_flag <= '0';
            clatire2_flag <= '0';
            
            -- Reset contoare pentru fiecare fază
            minute_presp <= 0;
            secunde_presp <= 0;
            minute_SP <= 0;
            secunde_SP <= 0;
            minute_C <= 0;
            secunde_C <= 0;
            minute_C2 <= 0;
            secunde_C2 <= 0;
            minute_CEN <= 0;
            secunde_CEN <= 0;
            secunde_1min <= 0;
            
            -- Reset semnale pentru cronometru
            enable_parallel_m <= '0';
            enable_parallel_s <= '0';
            minute_semnal <= (others => '0');
            secunde_semnal <= (others => '0');
            r_m<='1';
            r_s<='1';
            minute_1:=40;
            secunde_1:=0;
               stare<=INACTIV;

        elsif rising_edge(clk) then
               --if enable_intern='1' then      
                case stare is
                    when INACTIV=>
                    blocked_door <= '0';
                    start_LED<='0';
                     r_m<='0';
            r_s<='0';
                    start_wash<='0';
                    target_speed <= "00";
                    target_temp <= "000";
                    washing_states<="000";
                    apa_incalzita<='0';
                   -- MASINA_DE_SPALAT_READY_LED<='0';
                    if start='1' and usa_inchisa='1' then
                        blocked_door <= '1';--afisez 1
                        start_LED<='1';--afisez 2
                        stare<=SELECTARE_MOD;
                   
                    end if;
                    
                    when SELECTARE_MOD=>
                    --actualizam starile
                        blocked_door <= '1';--afisez 1
                    start_LED<='1';--afisez 2             SUNT LEDURILE DEFAULT CAND USA E INCHISA
                    start_wash<='0';--afisez 3
                    target_speed <= "00";--4
                    target_temp <= "000";--5
                        if buton_stanga_ACTIVE='1' then
                            stare<=MOD_AUTO;
                        elsif buton_dreapta_ACTIVE='1' then 
                            stare<=SET_TEMP;
                        END IF;
                        
                    when MOD_AUTO=> 
                    blocked_door <= '1';--afisez 1
                    start_LED<='1';--afisez 2             SUNT LEDURILE DEFAULT CAND USA E INCHISA
                    start_wash<='0';--afisez 3
                    target_speed <= "00";--4
                    target_temp <= "000";--5
                    washing_states<="000";--6
                        if select_AUTO="001" then
                            if buton_dreapta_ACTIVE='1' then
                                target_temp <= "001";
                                target_temp_semnal<="001";
                                 target_speed <= "11"; 
                                 prespalare_flag <= '0'; 
                                 LED_prespalare<=prespalare_flag;
                                 clatire2_flag <= '0';
                                 LED_clatire2<=clatire2_flag;
                                 stare <= CALC_TIMP_TOTAL;
                            else 
                                stare<=MOD_AUTO;
                            end if;
                        elsif select_AUTO="010" then
                            if buton_dreapta_ACTIVE='1' then
                                target_temp <= "011";
                                target_temp_semnal<="011";
                                 target_speed <= "01"; 
                                 prespalare_flag <= '0'; 
                                 clatire2_flag <= '0';
                                 LED_prespalare<=prespalare_flag;
                                 LED_clatire2<=clatire2_flag;
                                stare <= CALC_TIMP_TOTAL;

                            else 
                                stare<=MOD_AUTO;
                            end if;
                        elsif select_AUTO="011" then
                            if buton_dreapta_ACTIVE='1' then
                                target_temp <= "010";
                                target_temp_semnal<="010";
                                 target_speed <= "10"; 
                                 prespalare_flag <= '0'; 
                                 clatire2_flag <= '1';
                                 LED_prespalare<=prespalare_flag;
                                 LED_clatire2<=clatire2_flag;
                                 stare <= CALC_TIMP_TOTAL;
                            else 
                                stare<=MOD_AUTO;
                            end if;
                        elsif select_AUTO="100" then
                            if buton_dreapta_ACTIVE='1' then
                                 target_temp <= "010";
                                 target_temp_semnal<="010";
                                 target_speed <= "10"; 
                                 prespalare_flag <= '1'; 
                                 clatire2_flag <= '0';
                                 LED_prespalare<=prespalare_flag;
                                 LED_clatire2<=clatire2_flag;
                                 stare<=CALC_TIMP_TOTAL;
                            
                            else
                                stare<=MOD_AUTO;
                            end if;
                        elsif select_AUTO="101" then
                            if buton_dreapta_ACTIVE='1' then
                                target_temp <= "100";
                                target_temp_semnal<="100";
                                 target_speed <= "11"; 
                                 prespalare_flag <= '0'; 
                                 clatire2_flag <= '1';
                                 LED_prespalare<=prespalare_flag;
                                 LED_clatire2<=clatire2_flag;
                                stare <= CALC_TIMP_TOTAL;
                            else 
                                stare<=MOD_AUTO;
                            end if;
                        else
                            stare<=MOD_AUTO;
                        end if; 
                        
                        when CALC_TIMP_TOTAL=>
                            if prespalare_flag='1' then 
                                minute_1:=minute_1+10;
                                
                            end if;
                            
                            if clatire2_flag='1' then
                                minute_1:=minute_1+10;
                            end if;
                            r_m<='0';
                            r_s<='0';
                            enable_parallel_m<='1';
                            enable_parallel_s<='1';--incarcam timpul in numarator
                            
                            minute_semnal<=std_logic_vector(to_unsigned(minute_1,7));--introducem in numarator minutele si secundele
                            secunde_semnal<=std_logic_vector(to_unsigned(secunde_1,7));
                            --if buton_dreapta_ACTIVE='1' then
                              --  MASINA_DE_SPALAT_READY_LED<='1';--semnalizam catre utilizator ca masina de spalat este gata pentru inceperea spalarii
                                stare<=INCEPE_SPALAREA;
                            --elsif buton_dreapta_ACTIVE='0' then 
                             --   stare<=CALC_TIMP_TOTAL;
                            --end if;
                          
                          
                       when INCEPE_SPALAREA =>
                        enable_parallel_m<='0';
                        enable_parallel_s<='0';
                      --  MASINA_DE_SPALAT_READY_LED<='0';
                        stare<=INCALZIRE_APA;
                            
                            when SET_TEMP =>
                                if buton_dreapta_ACTIVE='1' then
                                    target_temp<=set_temperatura;
                                    target_temp_semnal<=set_temperatura;
                                    stare<=SET_VIT;
                                else
                                    stare<=SET_TEMP;
                                end if;
                                
                            when SET_VIT =>
                                if buton_dreapta_ACTIVE='1' then
                                    target_speed<=set_viteza;
                                    stare<=SElect_PRESP;
                                else
                                    stare<=SET_VIT;
                                end if;
                            
                            when SELECT_PRESP =>
                                if buton_dreapta_ACTIVE='1' then    
                                    prespalare_flag<='1';
                                    stare<=SELECT_CLATIRE_SUp;
                                elsif buton_stanga_ACTIVE='1' then 
                                    prespalare_flag<='0';
                                    stare<=SELECT_CLATIRE_SUp;
                                else
                                    stare<=SELECT_PRESP;
                                end if;          
                                
                             when SELECT_CLATIRE_SUP =>
                                if buton_dreapta_ACTIVE='1' then
                                    clatire2_flag<='1';
                                    stare<=CALC_TIMP_TOTAL;
                                elsIF buton_stanga_ACTIVE='1' then
                                    clatire2_flag<='0';
                                    stare<=CALC_TIMP_TOTAL;     
                                end if;
                                    
                              when INCALZIRE_APA =>
                                if tick_1sec='1' then 
                                    secunde_incalzire_apa<=secunde_incalzire_apa+1;
                                    if secunde_incalzire_apa>=1 then  -- După 2 secunde 
                                        secunde_incalzire_apa<=0;  -- Resetează contorul
                                        t_heat<=t_heat+1;  -- Incrementează temperatura
                                        if t_heat+1>=target_temp_semnal_int then  -- Verifică cu noua valoare
                                            apa_incalzita<='1';
                                            start_wash<='1';
                                            if prespalare_flag='1' then
                                                stare<=EXEC_PRESPALARE;
                                            elsif prespalare_flag='0' then
                                                stare<=EXEC_SPALARE_PRINCIPALA;
                                            end if;
                                        end if;
                                    end if;
                                end if;

                                
                        when EXEC_PRESPALARE =>
                            washing_states<="001";
                            if tick_1sec='1' then
                                secunde_presp<=secunde_presp+1;
                                if secunde_presp=59 then 
                                    minute_presp<=minute_presp+1;
                                    secunde_presp<=0;
                                    if minute_presp>=T_PRESP-1 then
                                        stare<=EXEC_SPALARE_PRINCIPALA;
                                    end if;
                                end if;
                            end if;
                            
                        when EXEC_SPALARE_PRINCIPALA =>
                            washing_states<="010";
                            if tick_1sec='1' then
                                secunde_SP<=secunde_SP+1;
                                if secunde_SP=59 then 
                                    secunde_SP<=0;
                                    minute_SP<=minute_SP+1;
                                    if minute_SP>=T_WASH-1 then
                                        stare<=EXEC_CLATIRE;
                                    end if;
                                end if;
                            end if;
                        
                        when EXEC_CLATIRE =>
                            washing_states<="011";
                            if tick_1sec='1' then
                                secunde_C<=secunde_C+1;
                                if secunde_C=59 then 
                                    secunde_C<=0;
                                    minute_C<=minute_C+1;
                                    if minute_C>=T_RINSE-1 then
                                        if clatire2_flag='1' then 
                                            stare<=EXEC_CLATIRE2;
                                        elsif clatire2_flag='0' then 
                                            stare<=EXEC_CENTRIFUGARE;
                                        end if;
                                    end if;
                                end if;
                            end if;
                            
                        when EXEC_CLATIRE2 =>
                            washing_states<="100";
                            if tick_1sec='1' then
                                secunde_C2<=secunde_C2+1;
                                if secunde_C2=59 then 
                                    secunde_C2<=0;
                                    minute_C2<=minute_C2+1;
                                    if minute_C2>=T_CLATIRE2-1 then
                                        stare<=EXEC_CENTRIFUGARE;
                                    end if;
                                end if;
                            end if;
                            
                        when EXEC_CENTRIFUGARE =>
                            washing_states<="101";
                            if tick_1sec='1' then
                                secunde_CEN<=secunde_CEN+1;
                                if secunde_CEN=59 then 
                                    secunde_CEN<=0;
                                    minute_CEN<=minute_CEN+1;
                                    if minute_CEN>=T_SPIN-1 then
                                        stare<=WAIT_USA_DEBL;
                                    end if;
                                end if;
                            end if;
                            
                        when WAIT_USA_DEBL =>
                            washing_states<="110";
                            --incarcam 60 de secunde in numarator
                            enable_parallel_s<='1';
                            enable_parallel_m<='1';
                            minute_semnal<="0000001";
                            secunde_semnal<=(others=>'0');
                            stare<=NUMARATOARE_INVERSA_DEBLOCARE_USA;
                            
                        when NUMARATOARE_INVERSA_DEBLOCARE_USA=>
                            
                            enable_parallel_s<='0';
                            enable_parallel_m<='0';
                            if tick_1sec='1' then
                                secunde_1min<=secunde_1min+1;
                                if secunde_1min>=T_UNLOCK-1 then 
                                    stare<=INACTIV;
                                end if;
                            end if;
                   end case; 
           --end if;
        end if;
        
                                    LED_prespalare<=prespalare_flag;
                                    
                                    LED_clatire2<=clatire2_flag;
    end process;
    
    process(target_temp_semnal)
    begin
        case target_temp_semnal is
            when "001" => 
            target_temp_semnal_int<=30;
            
            when "010" => 
            target_temp_semnal_int<=40;
            
            when "011" => 
            target_temp_semnal_int<=60;
            
            when "100" =>  
            target_temp_semnal_int<=90;
            when others=>
            target_temp_semnal_int<=0;
        end case;
    end process; 
    
    --pentru afisare pe SSD
    process(clk,counting_s_semnal,counting_m_semnal) 
    begin
    if rising_edge(clk) then
            minute_int <= to_integer(unsigned(counting_m_semnal));
            secunde_int <= to_integer(unsigned(counting_s_semnal));
            minute_bcd <= to_bcd(minute_int); 
            secunde_bcd <= to_bcd(secunde_int);
            timp_formatSSD <= zeroes & minute_bcd & secunde_bcd;
    end if;
    end process;
end Behavioral;
