%% EV Fleet modelling using different scheduling methods
%{
Michael McDonald s1425486@sms.ed.ac.uk
BEng Hons Individual Project
Creation Date: 22/03/2018
Last edit: 23/03/2018
%}
clear;

% %%  Load Data From File
% csvName = 'LoadData.csv' ;  % recorded data file from test
% DataFileRead = csvread(csvName);
% 
% %Load in whole file
% t_start = 1;
% t_end = length(DataFileRead);
% 
% 
% D_time = DataFileRead(t_start:t_end, 1);
% D_arrival = DataFileRead(t_start:t_end, 2);
% D_departure = DataFileRead(t_start:t_end, 3);
% D_location = DataFileRead(t_start:t_end, 4);
% D_chargeIn = DataFileRead(t_start:t_end, 5);
% clear DataFileRead;
% 
% % %plot Loaded Data
% % figure1 = figure;
% % plot(D_time, D_arrival, D_time, D_departure, D_time, D_location)
% % title('Data Loaded in')
% % xlabel('Hour of Day') 
% % ylabel('Probability') 
% % legend('P arrival','P departure','P at home (User1)') 

%% Fleet Definitions

% Vehicle = Nissan Leaf
% Full electric vehicle
fleet_N = 300;  %Fleet Size 



% Produce arrival and departue times using normal data
rng('default') % For reproducibility
%Arrival Times
fleet_data(1, 1:fleet_N) = normrnd(19.16,3.62,[fleet_N, 1]);
%Departure Time
fleet_data(2, 1:fleet_N) = normrnd(10.53,3.26,[fleet_N, 1]);
%Current SoC - Set as gaussian distribution for mixed arrival times
fleet_data(3, 1:fleet_N) = normrnd(0.5,0.1,[fleet_N, 1]);
%Required SoC
fleet_data(4, 1:fleet_N) = 0.9; %  normrnd(8.5,0.5,[fleet_N, 1]);  % just set all vehicles to be planned for 90% complation charge
%Priority Algorithm
fleet_data(5, 1:fleet_N) = 0;
%Current State
fleet_data(6, 1:fleet_N) = 0;
%Priority Rank
fleet_data(7, 1:fleet_N) = 0;
%Battery Size (kWh)
fleet_data(8, 1:fleet_N) = 40;
%Charge Rate (kW)
fleet_data(9, 1:fleet_N) = 3;


%As day is continuous need to move times greater tham 24 to next morning
for x = 1: fleet_N
   if  (fleet_data(1,x) >= 24)
      fleet_data(1,x) = fleet_data(1,x) - 24 ;
   end
   if  (fleet_data(2,x) >= 24)
      fleet_data(2,x) = fleet_data(2,x) - 24 ;
   end
end


%% Begin Simulation
FleetStatus(24, 6) = 0;
test_vehicle(24, 9) = 0; 
test_num = 200;
for hour = 0:23;

   % check vehicle locations
   fleet_data = Vehicle_home(fleet_data, hour);
  
   % Charge upon arrival 
%   fleet_data = Charge_ASAP(fleet_data, hour);   
    
   
   
   % charge priority vehicles
%    fleet_data = Priority_Calc(fleet_data, hour);
   

    
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
  FleetStatus(hour+ 1, 2) = sum(fleet_data(6, 1:fleet_N)==0);
  % State 1 : Charging
  FleetStatus(hour+ 1, 3) = sum(fleet_data(6, 1:fleet_N)==1);
  % State 2 : Not Charging
  FleetStatus(hour+ 1, 4) = sum(fleet_data(6, 1:fleet_N)==2);
  % State -1 : Plugged in - not calculated
  FleetStatus(hour+ 1, 5) = sum(fleet_data(6, 1:fleet_N)==-1);
  % All vehicles at home
  FleetStatus(hour+ 1, 6) =   FleetStatus(hour+ 1, 3) +  FleetStatus(hour+ 1, 4) +  FleetStatus(hour+ 1, 5);

  
end

figure1 = figure;
plot(FleetStatus(1:24, 1), FleetStatus(1:24, 5))
title('Vehicles at Home')
xlabel('Hour of Day') 
ylabel('Number of vehicles') 
axis([0 23 0 max(FleetStatus(1:24, 6))*1.1])

% figure2 = figure;
% plot(FleetStatus(1:24, 1), FleetStatus(1:24, 3), FleetStatus(1:24, 1), FleetStatus(1:24, 4))
% title('Vehicles at Home')
% xlabel('Hour of Day') 
% ylabel('Number of vehicles') 
% legend('Vehicles Charging', 'Vehicles not Charging')
% 
% figure3 = figure;
% plot(FleetStatus(1:24, 1), test_vehicle(1:24, 6))
% title('Vehicles SoC')
% xlabel('Hour of Day') 
% ylabel('SoC') 