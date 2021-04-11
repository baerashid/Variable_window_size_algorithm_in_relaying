function Im1(block)

%%
%% The setup method is used to set up the basic attributes of the
%% S-function such as ports, parameters, etc. Do not add any other
%% calls to the main body of the function.
%%

setup(block);

%endfunction

%% Function: setup ===================================================
%% Abstract:
%%   Set up the basic characteristics of the S-function block such as:
%%   - Input ports
%%   - Output ports
%%   - Dialog parameters
%%   - Options
%%
%%   Required         : Yes
%%   C MEX counterpart: mdlInitializeSizes
%%
function setup(block)

global sr
global ws_start
global ws_end
global buff_Im1
global t_Im1
global n_t_Im1
global SampleTime
global f


f = 60;
t_Im1 = 0;%global simulation time
n_t_Im1 = 0;%number of time sample
sr = block.DialogPrm(1).Data;
ws_start = block.DialogPrm(2).Data;
ws_end = block.DialogPrm(3).Data;
SampleTime = floor(10000000*1/sr)/10000000;%time step of func execution
buff_Im1 = zeros(1,ws_end);

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
block.NumDialogPrms     = 3;

% Register sample times
%  [0 offset]            : Continuous sample time
%  [positive_num offset] : Discrete sample time
%
%  [-1, 0]               : Inherited sample time
%  [-2, 0]               : Variable sample time

block.SampleTimes = [SampleTime 0];

% Specify the block simStateCompliance. The allowed values are:
%    'UnknownSimState', < The default setting; warn and assume DefaultSimState
%    'DefaultSimState', < Same sim state as a built-in block
%    'HasNoSimState',   < No sim state
%    'CustomSimState',  < Has GetSimState and SetSimState methods
%    'DisallowSimState' < Error out when saving or restoring the model sim state
block.SimStateCompliance = 'DefaultSimState';



%% -----------------------------------------------------------------
%% The MATLAB S-function uses an internal registry for all
%% block methods. You should register all relevant methods
%% (optional and required) as illustrated below. You may choose
%% any suitable name for the methods and implement these methods
%% as local functions within the same file. See comments
%% provided for each function for more information.
%% -----------------------------------------------------------------

%block.RegBlockMethod('PostPropagationSetup',    @DoPostPropSetup);
%block.RegBlockMethod('InitializeConditions', @InitializeConditions);
%block.RegBlockMethod('Start', @Start);
block.RegBlockMethod('Outputs', @Outputs);     % Required
%block.RegBlockMethod('Update', @Update);
%block.RegBlockMethod('Derivatives', @Derivatives);
block.RegBlockMethod('Terminate', @Terminate); % Required

%end setup

%%
%% Outputs:
%%   Functionality    : Called to generate block outputs in
%%                      simulation step
%%   Required         : Yes
%%   C MEX counterpart: mdlOutputs
%%
function Outputs(block)

global sr
global ws_start
global ws_end
global buff_Im1
global t_Im1
global n_t_Im1
global SampleTime
global f

t_Im1 = t_Im1 + SampleTime;
n_t_Im1 = n_t_Im1 + 1;
buff_Im1 = [block.InputPort(1).Data,buff_Im1(1:ws_end-1)];

res_Ir1 = 0;
for i=1:ws_end
    res_Ir1 = res_Ir1 + buff_Im1(i)*cos( 2*pi*f* (t_Im1 - (i-1)*SampleTime) ) * SampleTime;%time in cos goes back
end

res = buff_Im1(1)*sin(2*pi*f*(t_Im1)) - buff_Im1(ws_end)*sin(2*pi*f* (t_Im1 - (SampleTime*ws_end))) - (2*pi*f)*res_Ir1;

block.OutputPort(1).Data =  res;
%
%end Outputs


%%
%% Terminate:
%%   Functionality    : Called at the end of simulation for cleanup
%%   Required         : Yes
%%   C MEX counterpart: mdlTerminate
%%
function Terminate(block)

%end Terminate

