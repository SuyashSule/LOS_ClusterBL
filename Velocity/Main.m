tic
aID = getenv('SLURM_ARRAY_TASK_ID')
if(isempty(aID))
  warning('aID is empty. Replacing it with 1.')  
  aID = '1'; %Runs only for first value of AP density when aID=1
end
rng('shuffle');

densityBS = [100,150,200,300,400,500]*10^(-6);
densityBL_PPP = [0.01];
% densityBS = 200*10^(-6);
% densityBL_PPP = 0.1;
L = 100;
V = [0.2, 0.5, 1]; %velocity in m/s
hb = 1.8; %height blocker
hr = 1.4; %height receiver (UE)
ht = 5; %height transmitter (BS)
frac = (hb-hr)/(ht-hr);
simTime = 1*60*60; %sec Total Simulation time
tstep = 0.001;
% tstep = 1; %(sec) time step
mu = 2; %Expected bloc dur =1/mu sec
R = 100; %m Radius
omegaVal = [0, pi/3]; %self blockage angle

%Parameters for Matern Cluster Process
numPerCl = 10;
densityParent = densityBL_PPP./numPerCl
radiusCluster = 10;%1/4.0./sqrt(densityParent);
densityDaughter = numPerCl./pi./radiusCluster.^2%densityBL_PPP*16/pi;
% densityParent = [0.1/64];
% radiusCluster = 2/4.0./sqrt(densityParent);
% densityDaughter = densityBL_PPP*16/pi;

data = zeros(length(densityBS),length(V),4);

for indexBS=1:length(densityBS)
     for indexV=1:length(V)
         sprintf("densityBS = %f, densityBL = %f, velocity = %f",densityBS(indexBS),densityBL_PPP,V);
         [numBS, BS_locs] = PPP_generate(densityBS(indexBS),L);
         [BL_locs_initial, clusterCenters, numbPointsWithinSimWindow] = ...
             MCP_generate(densityParent,radiusCluster,densityDaughter,L);
         isUE_insideCluster = UE_insideCluster(clusterCenters, radiusCluster);
         [avg_blockage_probability, avg_blockage_duration, blockage_freq] = ...
             MobilityWithinCluster(BS_locs, BL_locs_initial, clusterCenters, ...
             radiusCluster, V(indexV), L, mu, frac, simTime, tstep);
%          outage_instances = prod(blockage_instances,1);
%          avg_blockage_probability = sum(outage_instances)/length(outage_instances);
%          blockages_durations = []; avg_blockage_duration = 0;
%          count = 0; 
%          for i=1:1:length(outage_instances)
%              if outage_instances(i)==1
%                  count = count+1;
%              elseif outage_instances(i)==0 && count~=0
%                  blockages_durations = [blockages_durations count];
%              end
%          end
%          if isempty(blockage_durations)~=0
%          avg_blockage_duration = sum(blockages_durations)/length(blockages_durations);
%          end
         data(indexBS,indexV,:) = ...
             [isUE_insideCluster,avg_blockage_probability,avg_blockage_duration, blockage_freq];
%          data(1,1,:)
     end
end

% RunAnimation(timestamps, BS_locs, BL_locations, V_vectors, 0.1*tstep, simTime);
save(strcat('SimVelocity_2_5_10','_',num2str(aID),'.mat'),'data')
toc
