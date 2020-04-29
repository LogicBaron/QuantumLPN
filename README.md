# QuantumLPN
A Project for Simulation of Quantum LPN solver.

Reference Paper :
  

-----------------
##Start Simulation

These codes are written in matlab.
Basically, you can use "lpn.mat" for your simulation.

At the point of your code execution, you can set several arguments including mode "history" or "reinforcement".

lpn_history.mat and lpn_reinforcement.mat file will executed according to your mode choice.

Generally, "history" mode takes much more time and memory as it registers and views all informations generated during the simulation : More detailed explanation is stated in the paper.

As the Simulation Code is based on Language, You can use pooling to speed up.

If your machine supports multi-core processors you can use "lpn_parpool.mat" files for simulation.

you can get more information about pooling on MATLAB : https://www.mathworks.com/help/parallel-computing/parpool.html;jsessionid=4dca125053a9bcde71f06250bfb6 .

More details of Simulation settings and problem is stated in the paper.

----------------
##Simulation Results

Each simulation results are saved in the "data" directory.

As the datas are spreaded, you can run "data_postprocess.mat" for clustering the datas.

In the post-processing, you should set variables which means the settings of the simulations.

The post-proceed datas are saved in the "final_data" directory.
