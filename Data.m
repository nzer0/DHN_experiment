classdef Data < handle
    properties (Access = public)
        orig_data;
        norm_data;
        data_mean;
        data_std;
        excl_idx;
        incl_idx;
        dim;
        len;
    end

    methods (Access = public)
        function obj = Data(datafile)
            trim_size = 10;
            data = dlmread(datafile, '\t');
            obj.orig_data = data(trim_size+1:end-trim_size, :);
            obj.dim = size(obj.orig_data, 2);
            obj.len = size(obj.orig_data, 1);
            obj.data_mean = mean(obj.orig_data);
            obj.data_std = std(obj.orig_data);
            obj.excl_idx = find(obj.data_std<1);
            obj.incl_idx = find(obj.data_std>=1);
            obj.norm_data = (obj.orig_data - repmat(obj.data_mean, obj.len, 1)) ./ repmat(obj.data_std, obj.len, 1);
        end
       
        function orig_scale_data = orig_scale(obj, data)
            data_len = size(data, 1);
            orig_scale_data = data .* repmat(obj.data_std, data_len, 1) + repmat(obj.data_mean, data_len, 1);
            orig_scale_data(:,obj.excl_idx) = repmat(obj.orig_data(1,obj.excl_idx), data_len, 1);
        end
    end
    
    methods (Static)
        function visualize(data)
            
            %% Data read
            % dat = dlmread('record.txt', '\t');
            bvhdat = data;
            action = (bvhdat(:,1:20)-2048) .* 180 ./ 2048;
            % action = zeros(size(action2));
            % testnum = [12];
            % action(:,testnum) = action2(:,testnum);
            % action(:,14) = ((1:100) ./ 100 * 60)';
            % action = zeros(1, 20);
            action2 = action;
            action(:,11:12) = action2(:,9:10);
            action(:,9:10) = action2(:,11:12);


            action_size = size(action, 1);

            %% Write header
            fin = fopen('Darwin.bvh');
            fout = fopen('DarwinMove.bvh', 'w');
            header = fread(fin);
            fwrite(fout, header);

            fprintf(fout, 'MOTION\nFrames: %d\nFrame Time: 0.041667\n', action_size);

            %% Match format and write actions
            for act=1:action_size
                angles = action(act, :);
                angles = repmat(angles, 3, 1)';

                % direction of each motor axis: XYZ 
                direction = [
                    -1 0 0 ;
                    1 0 0 ;
                    0 0 -1 ;
                    0 0 -1 ;
                    0 1 0 ; % 5
                    0 1 0 ;
                    0 -1 0 ;
                    0 -1 0 ;
                    1 0 0 ;
                    -1 0 0 ; % 10
                    0 0 -1 ;
                    0 0 -1 ;
                    1 0 0 ;
                    -1 0 0 ;
                    -1 0 0 ; % 15
                    1 0 0 ;
                    0 0 1 ;
                    0 0 1 ;
                    0 1 0 ;
                    -1 0 0 ; % 20
                ];

                % offset angle
                offset = zeros(20, 3);
                offset(3, 3) = -180/4;
                offset(4, 3) = 180/4;
                offset(5, 2) = 180/2;
                offset(6, 2) = -180/2;

                % mapping
                map = [19, 20, 2, 4, 6, 1, 3, 5, 8, 10, 12, 14, 16, 18, 7, 9, 11, 13, 15, 17];
                % Reshaping
                % direction = reshape(direction', 1, []);
                % offset = reshape(offset', 1, []);

                angles = (angles + offset) .* direction;
                angles = [angles(:,3), angles(:,1:2)]; % Change XYZ to ZXY
                new_angles = angles(map, :); % Reorder motor num to bvh sequence
                new_angles = reshape(new_angles', 1, []); % Serialize

                %% bvh file write

                for i=1:9 % set root pos and dummy to zero
                    fprintf(fout, '%d ', 0);
                end
                for i=1:60
                    fprintf(fout, '%d ', new_angles(i));
                end
                fprintf(fout, '\n');

            end

            addpath('MOCAP_Toolbox');
            addpath('NDLUTIL');
            bvhPlayFile('DarwinMove.bvh');

        end
    end
end