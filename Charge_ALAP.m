function fleet_state = Charge_ALAP(fleet_data)
%% Setup Simulation
FleetStatus(24, 6) = 0;
test_vehicle(24, 9) = 0; 
test_num = 200; %random vehicle number to check on

%% Begin Iteration
for hour = 0:23
   % check vehicle locations
   fleet_data = Vehicle_home(fleet_data, hour);
  
  
    
   

    for x = 1: length(fleet_data)
        t_arr =  fleet_data(1, x);
        t_dep = fleet_data(2, x);
        charge_rate = fleet_data(9, x);
        req_SoC = fleet_data(4, x);
        start_SoC = fleet_data(3, x);
        batt_size = fleet_data(8, x);

        %Calculate time remaining

        if ((t_dep< t_arr) && (t_dep < hour))
         t_rem = t_dep-hour + 24;           
        else
         t_rem = t_dep-hour;                    
        end
        
        %Calculate time required to charge
        t_charge = (req_SoC-start_SoC)*batt_size/charge_rate;

        if (fleet_data(6, x) == -1) %If plugged in
            if (t_charge > t_rem-0.5)
                %Status Charging
                fleet_data(6, x) = 1;
            else
                %Status Plugged in not Charging
                fleet_data(6, x) = 2;
            end
        end





    end
   

    
    %record current vehicle state
    test_vehicle(hour+ 1, 1) = fleet_data(1, test_num);
    test_vehicle(hour+ 1, 2) = fleet_data(2, test_num);
    test_vehicle(hour+ 1, 3) = fleet_data(3, test_num);
    test_vehicle(hour+ 1, 4) = fleet_data(4, test_num);
    test_vehicle(hour+ 1, 5) = fleet_data(5, test_num);
    test_vehicle(hour+ 1, 6) = fleet_data(6, test_num);
    test_vehicle(hour+ 1, 7) = fleet_data(7, test_num);
    test_vehicle(hour+ 1, 8) = fleet_data(8, test_num);
    test_vehicle(hour+ 1, 9) = fleet_data(9, test_num);
    
   
   
   
    % record fleet stats
    FleetStatus(hour+ 1, 1)= hour;
    %Count vehicles in different states 
    % State 0 : Disconnected (not at home)
    FleetStatus(hour+ 1, 2) = sum(fleet_data(6, :)==0);
    % State 1 : Charging
    FleetStatus(hour+ 1, 3) = sum(fleet_data(6, :)==1);
    % State 2 : Not Charging
    FleetStatus(hour+ 1, 4) = sum(fleet_data(6, :)==2);
    % State -1 : Plugged in - not calculated
    FleetStatus(hour+ 1, 5) = sum(fleet_data(6, :)==-1);
    % All vehicles at home
    FleetStatus(hour+ 1, 6) =   FleetStatus(hour+ 1, 3) +  FleetStatus(hour+ 1, 4) +  FleetStatus(hour+ 1, 5);

  
end

% figure1 = figure;
% plot(FleetStatus(1:24, 1), FleetStatus(1:24, 6),FleetStatus(1:24, 1), FleetStatus(1:24, 2),FleetStatus(1:24, 1), FleetStatus(1:24, 3), FleetStatus(1:24, 1), FleetStatus(1:24, 4))
% title('Vehicles States for Charge ASAP')
% xlabel('Hour of Day') 
% ylabel('Number of vehicles') 
% axis([0 23 0 max(FleetStatus(1:24, 6))*1.1])
% legend('Vehciles at Home', 'Vehicles not at home', 'Vehicles Charging', 'Vehicles Not Charging')

% figure2 = figure;
% plot(FleetStatus(1:24, 1), FleetStatus(1:24, 3), FleetStatus(1:24, 1), FleetStatus(1:24, 4))
% title('Vehicles States for Charge ALAP Scheduling')
% xlabel('Hour of Day') 
% ylabel('Number of vehicles') 
% axis([0 23 0 max(FleetStatus(1:24, 6))*1.1])
% legend('Vehicles Charging', 'Vehicles Not Charging')

% min_Power_DTD = min(FleetStatus(1:24, 3))*charge_rate
% min_Power_DTU = min(FleetStatus(1:24, 4))*charge_rate

%Return Status of Fleet
fleet_state = FleetStatus;
 

end
