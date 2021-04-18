function Im2_rec(block)

setup(block);

function setup(block)

global sr
global ws_start
global ws_end
global t_switch
global buff_Im2
global old_buff_Im2
global t_Im2
global n_t_Im2
global SampleTime
global f
global stage_Im2 %stage of calculation
global result_Im2
global res_Ir2
global current_ws_Im2


result_Im2 = 0;
res_Ir2 = 0;
stage_Im2 = "initialize";
f = 60;
t_Im2 = 0;%global simulation time
n_t_Im2 = 0;%number of time sample
sr = block.DialogPrm(1).Data;
ws_start = block.DialogPrm(2).Data;
ws_end = block.DialogPrm(3).Data;
current_ws_Im2 = ws_start;
t_switch = block.DialogPrm(4).Data;
SampleTime = floor(10000000*1/sr)/10000000;%time step of func execution
buff_Im2 = zeros(1,ws_end);
old_buff_Im2 = zeros(1,ws_end);

% Register number of ports
block.NumInputPorts  = 1;
block.NumOutputPorts = 1;

% Setup port properties to be inherited or dynamic
block.SetPreCompInpPortInfoToDynamic;
block.SetPreCompOutPortInfoToDynamic;

% Override input port properties
block.InputPort(1).Dimensions        = 1;
block.InputPort(1).DatatypeID  = 0;  % double
block.InputPort(1).Complexity  = 'Real';
block.InputPort(1).DirectFeedthrough = true;

% Override output port properties
block.OutputPort(1).Dimensions       = 1;
block.OutputPort(1).DatatypeID  = 0; % double
block.OutputPort(1).Complexity  = 'Real';

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
global current_ws_Im2
global t_switch
global buff_Im2
global old_buff_Im2
global t_Im2
global n_t_Im2
global SampleTime
global f
global stage_Im2 %stage of calculation
global result_Im2
global res_Ir2


if (t_Im2 == 0)
    stage_Im2 = "initialize";
    current_ws_Im2 = ws_start;
elseif (t_Im2 < t_switch)
    stage_Im2 = "start_window";
    current_ws_Im2 = ws_start;
elseif current_ws_Im2 < ws_end
    stage_Im2 = "change_window";
    current_ws_Im2 = current_ws_Im2 + 1;
else
    stage_Im2 = "end_window";
    current_ws_Im2 = ws_end;
end

t_Im2 = t_Im2 + SampleTime;
n_t_Im2 = n_t_Im2 + 1;
buff_Im2 = [block.InputPort(1).Data,buff_Im2(1:ws_end-1)];

%% Ir2 calc
if stage_Im2 == "initialize" 
    ws = ws_start;
    for i=1:ws
        res_Ir2 = res_Ir2 + buff_Im2(i)*sin( 2*pi*f* (t_Im2 - (i-1)*SampleTime) ) *SampleTime; %time in sin goes back
    end
end

if stage_Im2 == "start_window" 
    ws = ws_start;
    res_Ir2 = res_Ir2 + buff_Im2(1)*sin(2*pi*f*n_t_Im2/sr)*SampleTime - old_buff_Im2(ws)*sin(2*pi*f*(n_t_Im2 - ws)/sr)*SampleTime;
end

if stage_Im2 == "change_window"
    res_Ir2 = res_Ir2 + buff_Im2(1)*sin(2*pi*f*n_t_Im2/sr)*SampleTime;
end

if stage_Im2 == "end_window"
    ws = ws_end;
    res_Ir2 = res_Ir2 + buff_Im2(1)*sin(2*pi*f*n_t_Im2/sr)*SampleTime - old_buff_Im2(ws)*sin(2*pi*f*(n_t_Im2 - ws)/sr)*SampleTime;
end

%% Im2 calc

if stage_Im2 == "initialize" 
    ws = ws_start;
    result_Im2 = buff_Im2(1)*cos(2*pi*f*(n_t_Im2)/sr) - buff_Im2(ws)*cos(2*pi*f*(n_t_Im2 - ws + 1)/sr) + (2*pi*f)*res_Ir2;
end

if stage_Im2 == "start_window" 
    ws = ws_start;
    result_Im2 = buff_Im2(1)*cos(2*pi*f*(n_t_Im2)/sr) - buff_Im2(ws)*cos(2*pi*f*(n_t_Im2 - ws + 1)/sr) + (2*pi*f)*res_Ir2;
end

if stage_Im2 == "change_window"
    ws = current_ws_Im2;
    result_Im2 = buff_Im2(1)*cos(2*pi*f*(n_t_Im2)/sr) - buff_Im2(ws)*cos(2*pi*f*(n_t_Im2 - ws + 1)/sr) + (2*pi*f)*res_Ir2;
end

if stage_Im2 == "end_window"
    ws = ws_end;
    result_Im2 = buff_Im2(1)*cos(2*pi*f*(n_t_Im2)/sr) - buff_Im2(ws)*cos(2*pi*f*(n_t_Im2 - ws + 1)/sr) + (2*pi*f)*res_Ir2;
end


old_buff_Im2 = buff_Im2;

block.OutputPort(1).Data =  result_Im2;

function Terminate(block)
