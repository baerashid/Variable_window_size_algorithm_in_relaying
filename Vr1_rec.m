function Vr1_rec(block)

setup(block);

function setup(block)

global sr
global ws_start
global ws_end
global t_switch
global buff_Vr1
global old_buff_Vr1
global t_Vr1
global n_t_Vr1
global SampleTime
global f
global stage_Vr1 %stage of calculation
global result_Vr1
global current_ws_Vr1


result_Vr1 = 0;
stage_Vr1 = "initialize";
f = 60;
t_Vr1 = 0;%global simulation time
n_t_Vr1 = 0;%number of time sample
sr = block.DialogPrm(1).Data;
ws_start = block.DialogPrm(2).Data;
ws_end = block.DialogPrm(3).Data;
current_ws_Vr1 = ws_start;
t_switch = block.DialogPrm(4).Data;
SampleTime = floor(10000000*1/sr)/10000000;%time step of func execution
buff_Vr1 = zeros(1,ws_end);
old_buff_Vr1 = zeros(1,ws_end);

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
global t_switch
global buff_Vr1
global old_buff_Vr1
global t_Vr1
global n_t_Vr1
global SampleTime
global f
global stage_Vr1
global result_Vr1
global current_ws_Vr1


if (t_Vr1 == 0)
    stage_Vr1 = "initialize";
    current_ws_Vr1 = ws_start;
elseif (t_Vr1 < t_switch)
    stage_Vr1 = "start_window";
    current_ws_Vr1 = ws_start;
elseif current_ws_Vr1 < ws_end
    stage_Vr1 = "change_window";
    current_ws_Vr1 = current_ws_Vr1 + 1;
else
    stage_Vr1 = "end_window";
    current_ws_Vr1 = ws_end;
end

t_Vr1 = t_Vr1 + SampleTime;
n_t_Vr1 = n_t_Vr1 + 1;
buff_Vr1 = [block.InputPort(1).Data, buff_Vr1(1:ws_end-1)];


disp("___________")
n_t_Vr1
disp(buff_Vr1)

%first run - direct calculation
if stage_Vr1 == "initialize" 
    ws = ws_start;
    for i=1:ws
        result_Vr1 = result_Vr1 + buff_Vr1(i)*cos( 2*pi*f* (t_Vr1 - (i-1)*SampleTime) ) * SampleTime; %time in cos goes back
    end
    disp("initialize Vr1 value")
    disp(result_Vr1)
end

%initial window size calc
if stage_Vr1 == "start_window" %recursive calc
    ws = ws_start;
    result_Vr1 = result_Vr1 + buff_Vr1(1)*cos(2*pi*f*n_t_Vr1/sr)*SampleTime - old_buff_Vr1(ws)*cos(2*pi*f*(n_t_Vr1 - ws)/sr)*SampleTime;
    result_Vr1
    disp("___________")
end

%changing window calc
if stage_Vr1 == "change_window"
    result_Vr1 = result_Vr1 + buff_Vr1(1)*cos(2*pi*f*n_t_Vr1/sr)*SampleTime;
end

%end window size calc
if stage_Vr1 == "end_window"
    ws = ws_end;
    result_Vr1 = result_Vr1 + buff_Vr1(1)*cos(2*pi*f*n_t_Vr1/sr)*SampleTime - old_buff_Vr1(ws)*cos(2*pi*f*(n_t_Vr1 - ws)/sr)*SampleTime;
end


old_buff_Vr1 = buff_Vr1;

block.OutputPort(1).Data =  result_Vr1;

function Terminate(block)