%Main Simulation code for "Quantum-classical reinforcement learning
%for decoding noisy classical parity information"
function lpn_parpool(N,rep,E,M,mode)
%n, m, p, rep represent the length of the hidden bit string, number of
%samples, error rate, and the number of repetitions, respectively.
%emax defines the number of epoch. emax=1 means no epoch
%emin is the number of epoch for when m=1, i.e. the beginning of the
%algorithm. emax is usually set to 5 to 10.
%In each epoch, the hidden string is guessed M times, and the one with
%minimum hamming distance (compared to the training data) is chosen.
%We use M=1, but M=5 to 10 is more reasonable
%You can change each variable properly for your experimental purpose.


if mode~="history" && mode~="reinforcement"
    disp('error');
    return;
end

%load sample values of error probability.
%basically p_sample is [0, 0.1,0.2];
load('./variables/p_sample','p_sample');


%using parallel pool tools for multi-thread program running.
%you can increase or decrease the number of pool worker according to your
%computer performance.
parpool(4);

for j = 1:rep
    for n=2:N
        for p = 1:length(p_sample)
            fprintf('%dth repetition : N=%d, p=%.2f\n', j, n, p);
            if mode == "reinforcement"
                %Run QC-LPN algorithm with reinforcement policy
                lpn_result=lpn_feedback_reinforcement(n,p_sample(p),eval(E),eval(M));
                lpn_result.condition = [n,p_sample(p),j];
                str = sprintf("./data/N=%d, p=%.2f, rep=%d_reinforcement.mat",n,p_sample(p),j);
                parsave(str, lpn_result);
            elseif mode == "history"
                %Run QC-LPN algorithm with history policy
                lpn_result=lpn_feedback_history(n,p_sample(p),eval(E),eval(M));
                lpn_result.condition = [n,p_sample(p),j];
                str = sprintf("./data/N=%d, p=%.2f, rep=%d_history.mat",n,p_sample(p),j);
                parsave(str, lpn_result);
            end
            %Each data is saved in "./data" folder.
            %log of fidelity, hamming data, input bit string, parity bit
            %and other informations are saved in structure  variable "lpn_result"   
        end
    end
end

%end up the parellel pooling.
%you must use this command if the program stops while parellel pooling
%isn't over yet.
delete(gcp('nocreate'));

end


function parsave(fname, lpn_result)
%function for save each output structure "lpn_result".
%For multi-thread programming, you should use alternative function to avoid
%collision.
save(fname, 'lpn_result');
end