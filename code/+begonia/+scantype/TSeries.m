classdef TSeries < begonia.data_management.DataInfo
    
    properties(Abstract)
        cycles
        channels
        channel_names
        frame_count
        img_dim
        
        dx
        dy
        dt
        
        zoom
        frame_position_um
    end
    
    methods (Abstract)
        mat = get_mat(self,channel,cycle);
    end
    
    methods 
        function img = get_std_img(self,channel,cycle)
            if nargin < 3
                cycle = 1;
            end
            
            save_key = sprintf('img_std_ch%d_cy%d',channel,cycle);
            
            if self.has_var(save_key)
                img = self.load_var(save_key);
            else
                mat = self.get_mat(channel,cycle);

                c = begonia.util.Chunker(mat);

                img_sum = zeros(size(mat,1),size(mat,2));
                img_sum_sq = zeros(size(mat,1),size(mat,2));
                
                for i = 1:c.chunks
                    begonia.logging.log(1,'Calculating std image : chunk %d/%d',i,c.chunks);

                    chunk = c.chunk(i);
                    img_sum = img_sum + sum(chunk,3);
                    img_sum_sq = img_sum_sq + sum(chunk.*chunk,3);
                end
                N = size(mat,3);
                img = (img_sum_sq - img_sum .* img_sum / N) / (N-1);
                self.save_var(save_key,img);
                begonia.logging.log(1,'Complete');
            end
        end


        function img = get_max_img(self,channel,cycle)
            if nargin < 3
                cycle = 1;
            end
            
            save_key = sprintf('img_max_ch%d_cy%d',channel,cycle);
            
            if self.has_var(save_key)
                img = self.load_var(save_key);
            else
            
                mat = self.get_mat(channel,cycle);

                c = begonia.util.Chunker(mat);

                imgs = cell(1,c.chunks);
                for i = 1:c.chunks
                    begonia.logging.log(1,'Calculating max image : chunk %d/%d',i,c.chunks);

                    chunk = c.chunk(i);

                    imgs{i} = max(chunk,[],3);
                end
                img = cat(3,imgs{:});
                img = max(img,[],3);
                self.save_var(save_key,img);
                begonia.logging.log(1,'Complete');
            end
        end

        function img = get_avg_img(self,channel,cycle)
            if nargin < 3
                cycle = 1;
            end
            
            save_key = sprintf('img_avg_ch%d_cy%d',channel,cycle);
            
            if self.has_var(save_key)
                img = self.load_var(save_key);
            else
                mat = self.get_mat(channel,cycle);

                c = begonia.util.Chunker(mat);

                imgs = cell(1,c.chunks);
                frames = zeros(1,1,c.chunks);
                for i = 1:c.chunks
                    begonia.logging.log(1,'Calculating average image : chunk %d/%d',i,c.chunks);
                    
                    chunk = c.chunk(i);
                    frames(i) = size(chunk,3);

                    imgs{i} = mean(chunk,3);
                end
                img = cat(3,imgs{:});
                img = sum(img .* frames,3) / sum(frames);
                self.save_var(save_key,img);
                begonia.logging.log(1,'Complete');
            end
        end
    end
end

