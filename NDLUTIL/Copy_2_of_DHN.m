%% Dynamic Hypernetwork
% All in one version

%% Data Read
orig_data = dlmread('walking2.txt', '\t');
static_data = orig_data(1,:);
data = orig_data(11:end,[1:2,9:18]);

%% Data Normalize 
dim = size(data, 2);
len = size(data, 1);

% Normalize
data_mean = mean(data);
data_std = std(data);
data_std(data_std==0) = 1;
norm_data = (data - repmat(data_mean, len, 1)) ./ repmat(data_std, len, 1);

%% Data sampling
step = 3;
num_data = len-step+1;

% at first do random, later sample in normal dist.
sample_range = step * dim;
he_order = 6;
num_edge = 100000;
hn = zeros(num_edge, sample_range+1);
data_sample = randsample(1:num_data, num_edge, true);

% Initial sample
edge_idx = 0;
for data_idx=data_sample
    sampling_data = norm_data(data_idx:data_idx+step-1,:);
    rnd_2 = randsample(1:dim,2)*3-2;%%%%%%%%%%% This '2' should be revised
    rnd_seq = [rnd_2, rnd_2+1, rnd_2+2];
    he = NaN*ones(1,sample_range+1);
    he(1+rnd_seq(1:he_order)) = sampling_data(rnd_seq(1:he_order));
    he(1) = 1; % weight
    edge_idx = edge_idx + 1;
    hn(edge_idx,:) = he;
end
fprintf('sampling completed\n');

%% Generate and resample (Posterior Inference)
% data_set = randperm(num_data);
% for data_idx=data_set
%     sampling_data = norm_data(data_idx:data_idx+step-1,:);
%     gen_data = sampling_data;
%     for to_fill=1:step
%         % build matcher
%         matcher = sampling_data;
%         matcher(to_fill,:) = NaN;
%         matcher = [0, reshape(matcher, 1, [])];
%         matcher = repmat(matcher, num_edge, 1);
%         
%         % match
%         se = (matcher - hn) .^ 2;
%         se(isnan(se)) = 0;
%         sum_se = sum(se(:,2:end),2);
%         
%         importance = hn(:,1) ./ (sum_se + 0.0001);
%         [~,sorted_idx] = sort(importance);
%         
%         rank_num = 1000;
%         ranked_idx = sorted_idx(end-rank_num+1:end);
%         ranked_importance = importance(ranked_idx);
%         sum_ranked_importance = ranked_importance' * ~isnan(hn(ranked_idx,2:end));
%         
%         % DEBUG
%         high_he = hn(sorted_idx,:);
%         high_he = reshape(high_he(end,2:end), 3, []);
%         cur_data = norm_data(data_idx:data_idx+2,:);
%         %%%
%         
%         
%         numer_hn = hn;
%         numer_hn(isnan(numer_hn)) = 0;
%         to_fill_idx = 1+to_fill:3:sample_range;
%         gen_data(to_fill,:) = ...
%             ranked_importance' * numer_hn(ranked_idx,to_fill_idx) ./ sum_ranked_importance(:,to_fill_idx);
%     end % data_generated
%     
%     % build matcher
%     matcher = gen_data;
%     matcher = [0, reshape(matcher, 1, [])];
%     matcher = repmat(matcher, num_edge, 1);
% 
%     % match
%     se = (matcher - hn) .^ 2;
%     se(isnan(se)) = 0;
%     sum_se = sum(se(:,2:end),2);
% 
%     importance = hn(:,1) ./ (sum_se + 0.0001);
% 
% end

%% Generate the data
to_fill = step;
num_gen = 1000;
gen_seq = zeros(num_gen, dim);
gen_seq(1:step-1,:) = norm_data(1:step-1,:);

for gen_idx=1:num_gen-step+1
    % build matcher
    matcher = gen_seq(gen_idx:gen_idx+step-1,:);
    matcher(to_fill,:) = NaN;
    matcher = [0, reshape(matcher, 1, [])];
    matcher = repmat(matcher, num_edge, 1);

    % match
    se = (matcher - hn) .^ 2;
    se(isnan(se)) = 0;
    sum_se = sum(se(:,2:end),2);

    importance = hn(:,1) ./ (sum_se + 0.0001);
    [~,sorted_idx] = sort(importance);

    rank_num = 1000;
    ranked_idx = sorted_idx(end-rank_num+1:end);
    ranked_importance = importance(ranked_idx);
    sum_ranked_importance = ranked_importance' * ~isnan(hn(ranked_idx,2:end));

    % % DEBUG
    % high_he = hn(sorted_idx,:);
    % high_he = reshape(high_he(end,2:end), 3, []);
    % cur_data = norm_data(data_idx:data_idx+2,:);
    % %%%

    numer_hn = hn;
    numer_hn(isnan(numer_hn)) = 0;
    to_fill_idx = 1+to_fill:3:(sample_range+1);
    gen_seq(gen_idx+step-1,:) = ...
        ranked_importance' * numer_hn(ranked_idx,to_fill_idx) ./ sum_ranked_importance(:,to_fill_idx-1);
end

gen_seq = gen_seq .* repmat(data_std, num_gen, 1) + repmat(data_mean, num_gen, 1);
gen_seq = [
    gen_seq(:,1:2), ...
    repmat(static_data(3:8), num_gen, 1), ...
    gen_seq(:,3:end), ...
    repmat(static_data(19:20), num_gen, 1)
    ];

%% Joint angles
figure(1);
% title('Comparison of generated data and original data');
% legend('Original','Generated');
clf;
j=0;
for i=[9:10]
    j=j+1;
    subplot(1,2,j);
    hold on;
    plot((orig_data(1:300,i)-2048)*180/2048, 'r--');
    plot((gen_seq(1:300,i)-2048)*180/2048, 'b');
    title(sprintf('Joint %d',i));
    legend('Original','Generated');
xlabel('frames');
ylabel('joint angle (degrees)');
end
subplot(1,2,1);
legend('Original','Generated');
xlabel('frames');
ylabel('joint angle (degrees)');

%% Hyperedge histogram
figure(2);
hist(importance(:,1), 20);
title('Number of matching Hyperedges by weights');
xlabel('Hyperedge matching score (relative)');
ylabel('Number of matching Hyperedges (#)');

%% Visualize
figure(3);
clf;
alpha(0.5);
hold on;

color = flipud(colormap('gray'));
for i=1:10;
    view(3);
    alpha(0.5)
    visualize(orig_data, i*15, color(i*6,:));
    disp(i);

end
%% Visualize 2
figure(4);
hold on;

for i=60;
%     subplot(2,5,i);
    clf;
    title(sprintf('frame: %d', i*15));
%     legend('Original', 'Generated');
    view(3);
    visualize(orig_data, i*15, 'r');
    visualize(gen_seq, i*15, 'b');
    disp(i);
%     pause;
end

%% 








