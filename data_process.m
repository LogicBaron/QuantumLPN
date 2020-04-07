%Main Data-post-porcess code for "Quantum-classical reinforcement learning
%for decoding noisy classical parity information"
function data_process(n1, n2, rep, mode)
%this function convert the data into useful information.
%especially, function rearrange the fidelity and hamming distance data of
%each simulation into cell form.
%final rearranged data is saved in "./final_data" folder.
%fidelity and hamming distance is in form of cell, which {i,j,k}th cell
%have fidelity(or hamming distance) of N=i, p=p_sample(j), and kth
%repetition simulation.

if mode~="history" && mode~="reinforcement"
    disp('error');
    return;
end


%load sample values of error probability.
%basically p_sample is [0, 0.1,0.2];
%check the variable for correct post-processing.
load('./variables/p_sample','p_sample');


hd_data = cell(12, length(p_sample), rep);
sp_data = cell(12, length(p_sample), rep);

for  n = n1:n2
    for j = 1:rep
        for p_loop = 1:length(p_sample)
            if mode == "reinforcement"
            str = sprintf("./data/N=%d, p=%.2f, rep=%d_reinforcement.mat",n,p_sample(p_loop),j);
            else
            str = sprintf("./data/N=%d, p=%.2f, rep=%d_history.mat",n,p_sample(p_loop),j);
            end
            load(str, 'lpn_result');
            hd_data{n, p_loop, j} = lpn_result.hd_log;
            sp_data{n, p_loop, j} = lpn_result.sp_log;
        end
    end
end

if mode == "reinforcement"
    save(sprintf("./final_data/sp_data_N=%d~%d_reinforcement",n1,n2),'sp_data');
    save(sprintf("./final_data/hd_data_N=%d~%d_reinforcement",n1,n2),'hd_data');
else
    save(sprintf("./final_data/sp_data_N=%d~%d_history",n1,n2),'sp_data');
    save(sprintf("./final_data/hd_data_N=%d~%d_history",n1,n2),'hd_data');
end
end