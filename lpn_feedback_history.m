%Main Simulation backbone code for "Quantum-classical reinforcement learning
%for decoding noisy classical parity information"
function lpn_result=lpn_feedback_history(n,p,E,M)

dataN=n;

HN=1;
H=[1 1;1 -1]/sqrt(2);
for i=1:dataN+1
    HN=kron(H,HN);
end

% % hidden bit string
h=randi([0,1],dataN,1);
hindex=bi2de(h','left-msb')+1;

% % variables for repeating the measurement
gM=zeros(dataN,M);
gprob=zeros(1,M);

% variables for greedy algorithm
g=[]; %temporary guess bit string
k=1; %number of data samples
w=1; %filtering variable
tot_input=zeros(2^(dataN+1),1); %state vector for total input+parity
lpn_result.ins_bi = []; %log for input bit string
lpn_result.out = []; %log for output bit
lpn_result.g_log = []; %log for guess bit string
lpn_result.totH_log = []; %log for final state vector
lpn_result.sp_log = []; %log for fidelity
lpn_result.hd_log = []; %log for hamming distance
lpn_result.w_log = []; %log for filtering variable

% while k==1 || lpn_result.sp_log(length(lpn_result.sp_log))<0.7
while k==1 || (k<2^(dataN) && lpn_result.sp_log(length(lpn_result.sp_log))<0.97)
    % you can change the condition for termination.
    
    %receive input(data) bit string. Each input(data) bit string is
    %extracted from uniform random distribution.
    %output bit is calculated from hidden bit string, and binomial
    %error is added to output bit.
    ins=zeros(2^dataN,1);
    rnum=randi([1,2^dataN],1,1);
    ins(rnum) = 1;
    rst=de2bi(rnum-1,'left-msb')';
    lpn_result.ins_bi = [lpn_result.ins_bi, [zeros(dataN-length(rst),1); rst]];
    lpn_result.out = [lpn_result.out; mod(mod(sum(lpn_result.ins_bi(:,k).*h),2)+binornd(1,p),2)];
    
    if lpn_result.out(k)==0
        outs=[1;0];
    elseif lpn_result.out(k)==1
        outs=[0;1];
    end
    
    %vector state for accumulated input and output bit string.
    tot_input = tot_input + kron(ins, outs);
    
    
    for epoch=1:E
        % %Put weights. Those training data that appears less than w% of the data
        % %that appears most frequenty (i.e., likely to be the correct answer) is filtered out.
        % %As the hamming distance is reduced (i.e. closer to the answer), the weight increases.
        totE=round(tot_input/max(tot_input)*w);
        totsel1=totE(1:2:end);
        totsel2=totE(2:2:end);
        tot_partial=totsel1+totsel2;
        
        %make bus states with guess bit string.
        %values that have never been received in this simulation is target
        %of bus states.
        bus_ind=find(~tot_partial);
        bus=zeros(2^(dataN+1),1);        
        if k>1
            for tmp=1:length(bus_ind)
                tmp_bus=zeros(2^dataN,1);
                tmp_bus(bus_ind(tmp))=1;
                tmp_bus_bi=de2bi(bus_ind(tmp)-1,'left-msb');
                tmp_bus_binary=[zeros(1,dataN-length(tmp_bus_bi)) tmp_bus_bi]';
                tmp_bus_out=mod(sum(tmp_bus_binary.*g),2);
                if tmp_bus_out==0
                    tmp_bus_out_state=[1;0];
                elseif tmp_bus_out==1
                    tmp_bus_out_state=[0;1];
                end
                bus=bus+kron(tmp_bus,tmp_bus_out_state);
            end
        end
        
        tot2=totE+bus;
        N=sum(abs(tot2));
        tot2=tot2/sqrt(N);
        
        %apply hadamard gates to all qubits.
        totH=HN*tot2;
        
        
        %projective measurement and partial trace
        data1=totH(2:2:length(totH));
        
        
        % If the read-out qubit is not 1, then set the guessed g as a
        % random string and go to the next epoch iteration
        if norm(data1) < 1e-1
            g=randi([0,1],dataN,1);
            continue;
        end
        
        data1=data1/norm(data1);
        
        % Based on the probability distribution given by the final state,
        % output the answer bit string. Collect M numbers of the outcomes,
        % and chose the one with the minimum hamming distance.
        hd_test = [];
        t=[];
        
        %measurement.
        %for each measurement, calculate hamming distance between 
        %1. output bit that we already have - and -
        %2. output bit that can be calculated from measurement output.
        prob_table=[1:2^dataN;abs(data1').^2];
        for l=1:M
            m_ind=randsrc(1,1,prob_table);
            g_end=de2bi(m_ind-1,'left-msb');
            gM(:,l)=[zeros(1,dataN-length(g_end)) g_end]';
            gprob(l)=abs(data1(m_ind))^2;
            t=[t, mod(sum(lpn_result.ins_bi.*gM(:,l)),2)'];
            hd_test=[hd_test; pdist2(t(:,l)',lpn_result.out','hamming')];
        end
        
        %find measurement outcome with the minimum hamming distance.
        minhd_ind=find(hd_test==min(hd_test));
        
        %There could be multiple choices that gives minimum hamming distance.
        %Just random.
        if isempty(g)
            g = zeros(dataN, 1);
        end
        
        
        %greedy algorithm with history save.
        %compare the best measurement outcome of all accumulated stages.
        %choose the one with the smallest hamming distance compared to
        %real output bit.
        tmp_minhd_ind = minhd_ind(randi(size(minhd_ind,1)));
        old_g=g;
        old_t = mod(sum(lpn_result.ins_bi.*old_g),2)';
        old_hd= pdist2(old_t',lpn_result.out','hamming');
        tmp_g=gM(:,tmp_minhd_ind);
        tmp_minhd = min(hd_test);
        g=tmp_g;
        for i = 1:size(lpn_result.g_log, 2)
            old_g=lpn_result.g_log(:,i);
            old_t = mod(sum(lpn_result.ins_bi.*old_g,1),2)';
            old_hd= pdist2(old_t',lpn_result.out','hamming');
            if old_hd < tmp_minhd
                tmp_minhd = old_hd;
                g = old_g;
            end
        end
        
        %update filtering variable. recommend 0.8~1.2
        %update the log of variables.
        w=0.4*sqrt(min(min(hd_test), old_hd)) + 0.8;
        lpn_result.hd_log=[lpn_result.hd_log, pdist2(h',g','hamming')];
        lpn_result.sp_log = [lpn_result.sp_log,abs(data1(hindex))^2];
        lpn_result.g_log = [lpn_result.g_log, g];
        lpn_result.totH_log = [lpn_result.totH_log, totH];
        lpn_result.w_log = [lpn_result.w_log, w];
    end
    k=k+1;
end
end