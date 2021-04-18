function Vr2_rec(block)

setup(block);

function setup(block)

global sr
global ws_start
global ws_end
global t_switch
global buff_Vr2
global old_buff_Vr2
global t_Vr2
global n_t_Vr2
global SampleTime
global f
global stage_Vr2 %stage of calculation
global result_Vr2
global current_ws_Vr2

result_Vr2 = 0;
stage_Vr2 = "initialize";
f = 60;
t_Vr2 = 0;%global simulation time
n_t_Vr2 = 0;%number of time sample
sr = block.DialogPrm(1).Data;
ws_start = block.DialogPrm(2).Data;
ws_end = block.DialogPrm(3).Data;
current_ws_Vr2 = ws_start;
t_switch = block.DialogPrm(4).Data;
SampleTime = floor(10000000*1/sr)/10000000;%time step of func execution
buff_Vr2 = zeros(1,ws_end);
old_buff_Vr2 = zeros(1,ws_end);

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
global buff_Vr2
global old_buff_Vr2
global t_Vr2
global n_t_Vr2
global SampleTime
global f
global stage_Vr2
global result_Vr2
global current_ws_Vr2


if (t_Vr2 == 0)
    stage_Vr2 = "initialize";
    current_ws_Vr2 = ws_start;
elseif (t_Vr2 < t_switch)
    stage_Vr2 = "start_window";
    current_ws_Vr2 = ws_start;
elseif current_ws_Vr2 < ws_end
    stage_Vr2 = "change_window";
    current_ws_Vr2 = current_ws_Vr2 + 1;
else
    stage_Vr2 = "end_window";
    current_ws_Vr2 = ws_end;
end

t_Vr2 = t_Vr2 + SampleTime;
n_t_Vr2 = n_t_Vr2 + 1;
buff_Vr2 = [block.InputPort(1).Data, buff_Vr2(1:ws_end-1)];
a=0;
b=0;
c=0;
d=0;
res_C=0;
res_S=0;

%first run - direct calculation
if stage_Vr2 == "initialize" 
    ws = ws_start;
    for i=1:ws
        res_C = res_C + buff_Vr2(i)*cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        res_S = res_S + buff_Vr2(i)*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        a = a + cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        b = b + cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        c = c + cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        d = d + sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
    end
    detA = (a*d - c*b);
    result_Vr2 = (-c/detA*res_C + a/detA*res_S);
end

%initial window size calc
if stage_Vr2 == "start_window" %recursive calc
    ws = ws_start;
    for i=1:ws
        res_C = res_C + buff_Vr2(i)*cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        res_S = res_S + buff_Vr2(i)*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        a = a + cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        b = b + cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        c = c + cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        d = d + sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
    end
    detA = (a*d - c*b);
    result_Vr2 = (-c/detA*res_C + a/detA*res_S);
end

%changing window calc
if stage_Vr2 == "change_window"
    ws = current_ws_Vr2;
    for i=1:ws
        res_C = res_C + buff_Vr2(i)*cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        res_S = res_S + buff_Vr2(i)*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        a = a + cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        b = b + cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        c = c + cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        d = d + sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
    end
    detA = (a*d - c*b);
    result_Vr2 = (-c/detA*res_C + a/detA*res_S);  
end

%end window size calc
if stage_Vr2 == "end_window"
    ws = ws_end;
    for i=1:ws
        res_C = res_C + buff_Vr2(i)*cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        res_S = res_S + buff_Vr2(i)*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        a = a + cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        b = b + cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        c = c + cos( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
        d = d + sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) )*sin( 2*pi*f* (t_Vr2 - (i-1)*SampleTime) );
    end
    detA = (a*d - c*b);
    result_Vr2 = (-c/detA*res_C + a/detA*res_S);  
end


old_buff_Vr2 = buff_Vr2;

block.OutputPort(1).Data =  result_Vr2;

function Terminate(block)
