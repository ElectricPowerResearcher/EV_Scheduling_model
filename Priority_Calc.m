function fleet_state = Priority_Calc(fleet_data)
%% Setup Simulation
FleetStatus(24, 6) = 0;
test_vehicle(24, 9) = 0; 
test_num = 3; %random vehicle number to check on

%Algorithm Variables
bias_SoC = 1;
bias_Laxity = 1;
bias_TimeParked = 0;


%% Begin Iteration
start_hour = 0; %testing using 1 will move to 13 or 15 when ready to process
fleet_priorities(24,length(fleet_data)) = 0; 
fleet_laxity(24,length(fleet_data)) = 0; 
N_100_priority(23, 2) = 0;

 for hour = start_hour:23
   %% Check vehicle locations
   fleet_data = Vehicle_home(fleet_data, hour);

   %% Calculate Priority
    for x = 1: length(fleet_data)
     
        %extract variables for vehicle
        t_arr =  fleet_data(1, x);
        t_dep = fleet_data(2, x);
        start_SoC = fleet_data(3, x);
        req_SoC = fleet_data(4, x);
        curr_SoC = fleet_data(5, x);
        bev_state = fleet_data(6, x);
        batt_size = fleet_data(8, x);
        charge_rate = fleet_data(9, x);
        
        if (((t_arr - hour) <= 1) && ((t_arr - hour) > 0 ))
            %Vehicle Arriving in next hour - set Current SoC to arrival
            curr_SoC = start_SoC;
            fleet_data(5, x) = start_SoC;
        end
        
        
        
        %Calculate Laxity
        if ((t_dep< t_arr) && (t_dep < hour))
         t_rem = t_dep-hour + 24;           
        else
         t_rem = t_dep-hour;                    
        end

        t_charge = (req_SoC-curr_SoC)*batt_size/charge_rate;

        t_laxity =  t_rem - t_charge ;
        if (t_laxity < 0)
            %if laxity is negative set to 0.1
            t_laxity = 0.1;
        end
        

        if (bev_state == 0)%If not plugged in
            %Set Priority to 0
            priority = 0;  
            t_laxity = 0;
     
        elseif(req_SoC <= curr_SoC)
            %Set Priority to 0
            priority = 0;  
            t_laxity = 0;
        else
            
            %Calculate charge priority
            
            if curr_SoC < 0.40 %if SoC is less than 40, priority 100
                priority = 100;
            elseif (t_laxity < 0.5 && t_laxity > 0 && t_rem > 0 )%if less than 30 min laxity, priority 100
                priority = 100;
            else
                %Laxity Priority
                priority = (t_rem - t_laxity) / t_rem *100;
%                 %SoC Priority
%                 priority = priority  + (curr_SoC/req_SoC)*bias_SoC;
%                 %Length Parked Priority
%                % priority = priority  + (curr_SoC/t_parked)*bias_SoC;
%                 %Normalise Priority
%                 priority = priority/(bias_SoC+bias_Laxity)*100 ;
%                 
            end              
        end
        
        
        fleet_priorities(hour+1, x) = priority;
        fleet_laxity(hour+1, x) = t_laxity;

    end



   
    %% Rank Vehicles
    
    
    
    %% Charge Vehicles
    temp = fleet_priorities(hour+1, :);
    temp = sort(temp);
    N_100_priority(hour+1, 1) = sum(fleet_priorities(hour+1, :)==100);
    cutoff_p = temp(1, length(temp)*0.5)-1;
    N_100_priority(hour+1, 2) = sum(fleet_priorities(hour+1, :)>cutoff_p) -sum(fleet_priorities(hour+1, :)==100) ;
    
    for x = 1: length(fleet_data)
        priority = fleet_priorities(hour+1, x);
        if (fleet_data(6, x) == 0) % Not Plugged In
            %State = Not Plugged in
            fleet_data(6, x) = 0;
     
        elseif (priority == 100) % Immediate Charge
            %State = Charging
            fleet_data(6, x) = 1;
            %Current SoC = Current SoC + hour of charge
            fleet_data(5, x) = fleet_data(5, x) + charge_rate/batt_size;
            
        elseif (priority > cutoff_p) % Above cutoff for charge
            %State = Charging
            fleet_data(6, x) = 1;
            %Current SoC = Current SoC + hour of charge
            fleet_data(5, x) = fleet_data(5, x) + charge_rate/batt_size;

        else % Below cutoff for charge
            %State = Plugged in Not Charging
            fleet_data(6, x) = 2;
            %Current SoC = Current SoC;
            fleet_data(5, x) = fleet_data(5, x) + 0;

        end
    end    
    
    %% Record Stats
    
    %Record test vehicle state
        test_vehicle(hour+ 1, 1) = fleet_data(1, test_num);
        test_vehicle(hour+ 1, 2) = fleet_data(2, test_num);
        test_vehicle(hour+ 1, 3) = fleet_data(3, test_num);
        test_vehicle(hour+ 1, 4) = fleet_data(4, test_num);
        test_vehicle(hour+ 1, 5) = fleet_data(5, test_num);
        test_vehicle(hour+ 1, 6) = fleet_data(6, test_num);
        test_vehicle(hour+ 1, 7) = fleet_data(7, test_num);
        test_vehicle(hour+ 1, 8) = fleet_data(8, test_num);
        test_vehicle(hour+ 1, 9) = fleet_data(9, test_num);
        test_vehicle(hour+ 1, 11) = priority;
        test_vehicle(hour+ 1, 12) = fleet_laxity(hour+1, test_num);
        
    
    %Record fleet state
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

for hour = 0:start_hour-1
           
end

% figure1 = figure;
% plot(FleetStatus(1:24, 1), FleetStatus(1:24, 6),FleetStatus(1:24, 1), FleetStatus(1:24, 2),FleetStatus(1:24, 1), FleetStatus(1:24, 3), FleetStatus(1:24, 1), FleetStatus(1:24, 4))
% title('Vehicles States for Charge ASAP')
% xlabel('Hour of Day') 
% ylabel('Number of vehicles') 
% axis([0 23 0 max(FleetStatus(1:24, 6))*1.1])
% legend('Vehciles at Home', 'Vehicles not at home', 'Vehicles Charging', 'Vehicles Not Charging')

figure1 = figure;
plot(FleetStatus(1:24, 1), FleetStatus(1:24, 3), FleetStatus(1:24, 1), FleetStatus(1:24, 4))
title('Vehicles States for Charge Priority Scheduling')
xlabel('Hour of Day') 
ylabel('Number of vehicles') 
axis([0 23 0 max(FleetStatus(1:24, 6))*1.1])
legend('Vehicles Charging', 'Vehicles Not Charging')

% min_Power_DTD = min(FleetStatus(1:24, 3))*charge_rate
% min_Power_DTU = min(FleetStatus(1:24, 4))*charge_rate

figure1 = figure;
plot(FleetStatus(1:24, 1), FleetStatus(1:24, 6), FleetStatus(1:24, 1), N_100_priority(:, 1) , FleetStatus(1:24, 1), N_100_priority(:, 2) )
title('Vehicles at 100 Priority')
xlabel('Hour of Day') 
ylabel('Number of vehicles') 
axis([0 23 0 max(FleetStatus(1:24, 6))*1.1])
legend('Vehicles at Home', 'Vehicles with 100 priority', 'Vehicles above cutoff < 100 priority')

% Return Status of Fleet
fleet_state = FleetStatus;
 

end

