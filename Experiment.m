clear;
load walking;

exp_num = input('exp_num? ');

if exp_num == 1
%% exp1: Incremental Learning

num_edge_set = {
    50000;
    75000;
    100000;
    125000;
    150000
    };
num_exp = length(num_edge_set);

[err, gen] = cellfun(@(x) DHN(x,3), num_edge_set, 'UniformOutput', false);

% Plot
idcs = [14, 18];
for id=idcs
    figure(id);
    clf;
    idx = id;

    for i=1:num_exp
        subplot(2,3,i);
        hold on;
        plot(orig_data(:,idx), '--r');
        dat = gen{i}; 
        plot(dat(:,idx),'b');
        axis([0,300,0,4000]);
        title(sprintf('# of HE = %d', num_edge_set{i}));
        xlabel('frame number');
        ylabel('joint angle value');
    end
    subplot(2,3,6);
    plot(cell2mat(num_edge_set), log(cell2mat(err)));
    title('Log Error');
    xlabel('# of HE');
    ylabel('Log error');
end

elseif exp_num ==2
%% exp2: Markov order

step_set = {3; 4; 5; 6; 7};
num_exp = length(step_set);

[err, gen] = cellfun(@(x) DHN(100000,x), step_set, 'UniformOutput', false);

% Plot
idcs = [14, 18];
for id=idcs
    figure(id);
    clf;
    idx = id;

    for i=1:num_exp
        subplot(2,3,i);
        hold on;
        plot(orig_data(:,idx), '--r');
        dat = gen{i}; 
        plot(dat(:,idx),'b');
        axis([0,300,0,4000]);
        title(sprintf('Markov order = %d', step_set{i}));
        xlabel('frame number');
        ylabel('joint angle value');
    end
    subplot(2,3,6);
    plot(cell2mat(step_set), log(cell2mat(err)));
    title('Log Error');
    xlabel('Markov order');
    ylabel('Log error');
end

end
%%













