function Im1_rec(block)

setup(block);

function setup(block)

global sr
global ws_start
global ws_end
global t_switch
global buff_Im1
global old_buff_Im1
global t_Im1
global n_t_Im1
global SampleTime
global f
global stage_Im1 %stage of calculation
global result_Im1
global res_Ir1
global current_ws_Im1


result_Im1 = 0;
res_Ir1 = 0;
stage_Im1 = "initialize";
f = 60;
t_Im1 = 0;%global simulation time
n_t_Im1 = 0;%number of time sample
sr = block.DialogPrm(1).Data;
ws_start = block.DialogPrm(2).Data;
ws_end = block.DialogPrm(3).Data;
current_ws_Im1 = ws_start;
t_switch = block.DialogPrm(4).Data;
SampleTime = floor(10000000*1/sr)/10000000;%time step of func execution
buff_Im1 = zeros(1,ws_end);
old_buff_Im1 = zeros(1,ws_end);

% Register number of ports
block.NumInputPorts  = 1;
block.NumOutputPorts = 2;

% Setup port properties to be inherited or dynamic
block.SetPreCompInpPortInfoToDynamic;
block.SetPreCompOutPortInfoToDynamic;

% Override input port properties
block.InputPort(1).Dimensions        = 1;
block.InputPort(1).DatatypeID  = 0;  % double
block.InputPort(1).Complexity  = 'Real';
block.InputPort(1).DirectFeedthrough = true;
block.InputPort(1).SamplingMode = 'Sample';


% Override output port properties
block.OutputPort(1).Dimensions       = 1;
block.OutputPort(1).DatatypeID  = 0; % double
block.OutputPort(1).Complexity  = 'Real';
block.OutputPort(1).SamplingMode = 'Sample';

block.OutputPort(2).Dimensions       = 2;
block.OutputPort(2).DatatypeID  = 0; % double
block.OutputPort(2).Complexity  = 'Real';
block.OutputPort(2).SamplingMode = 'Sample';

% Register parameters
block.NumDialogPrms     = 4;

% Register sample times
block.SampleTimes = [SampleTime 0];

% Specify the block simStateCompliance. The allowed values are:
block.SimStateCompliance = 'DefaultSimState';

block.RegBlockMethod('Outputs', @Outputs);     % Required
block.RegBlockMethod('Terminate', @Terminate); % Required

function Outputs(block)

global sr
global ws_start
global ws_end
global current_ws_Im1
global t_switch
global buff_Im1
global old_buff_Im1
global t_Im1
global n_t_Im1
global SampleTime
global f
global stage_Im1 %stage of calculation
global result_Im1
global res_Ir1


if (t_Im1 == 0)
    stage_Im1 = "initialize";
    current_ws_Im1 = ws_start;
elseif (t_Im1 < t_switch)
    stage_Im1 = "start_window";
    current_ws_Im1 = ws_start;
elseif current_ws_Im1 < ws_end
    stage_Im1 = "change_window";
    current_ws_Im1 = current_ws_Im1 + 1;
else
    stage_Im1 = "end_window";
    current_ws_Im1 = ws_end;
end

t_Im1 = t_Im1 + SampleTime;
n_t_Im1 = n_t_Im1 + 1;
buff_Im1 = [block.InputPort(1).Data,buff_Im1(1:ws_end-1)];

%% Ir1 calc
if stage_Im1 == "initialize" 
    ws = ws_start;
    for i=1:ws
        res_Ir1 = res_Ir1 + buff_Im1(i)*cos( 2*pi*f* (t_Im1 - (i-1)*SampleTime) ) *SampleTime; %time in cos goes back
    end
end

if stage_Im1 == "start_window" 
    ws = ws_start;
    res_Ir1 = res_Ir1 + buff_Im1(1)*cos(2*pi*f*n_t_Im1/sr)*SampleTime - old_buff_Im1(ws)*cos(2*pi*f*(n_t_Im1 - ws)/sr)*SampleTime;
end

if stage_Im1 == "change_window"
    res_Ir1 = res_Ir1 + buff_Im1(1)*cos(2*pi*f*n_t_Im1/sr)*SampleTime;
end

if stage_Im1 == "end_window"
    ws = ws_end;
    res_Ir1 = res_Ir1 + buff_Im1(1)*cos(2*pi*f*n_t_Im1/sr)*SampleTime - old_buff_Im1(ws)*cos(2*pi*f*(n_t_Im1 - ws)/sr)*SampleTime;
end

%% Im1 calc

if stage_Im1 == "initialize" 
    ws = ws_start;
    result_Im1 = buff_Im1(1)*sin(2*pi*f*(n_t_Im1)/sr) - buff_Im1(ws)*sin(2*pi*f*(n_t_Im1 - ws + 1)/sr) - (2*pi*f)*res_Ir1;
end

if stage_Im1 == "start_window" 
    ws = ws_start;
    result_Im1 = buff_Im1(1)*sin(2*pi*f*(n_t_Im1)/sr) - buff_Im1(ws)*sin(2*pi*f*(n_t_Im1 - ws + 1)/sr) - (2*pi*f)*res_Ir1;
end

if stage_Im1 == "change_window"
    ws = current_ws_Im1;
    disp(ws);
    result_Im1 = buff_Im1(1)*sin(2*pi*f*(n_t_Im1)/sr) - buff_Im1(ws)*sin(2*pi*f*(n_t_Im1 - ws + 1)/sr) - (2*pi*f)*res_Ir1;
end

if stage_Im1 == "end_window"
    ws = ws_end;
    result_Im1 = buff_Im1(1)*sin(2*pi*f*(n_t_Im1)/sr) - buff_Im1(ws)*sin(2*pi*f*(n_t_Im1 - ws + 1)/sr) - (2*pi*f)*res_Ir1;
end


old_buff_Im1 = buff_Im1;

block.OutputPort(1).Data =  result_Im1;
block.OutputPort(2).Data = [n_t_Im1,current_ws_Im1];

function Terminate(block)
