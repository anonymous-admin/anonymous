%% Author: Johan

-module(static_supervisor).
-behaviour(supervisor).
-export([start_link/0, start_in_shell/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_in_shell() ->
    {ok, Pid} = supervisor:start_link({local, ?MODULE}, ?MODULE, []),
    unlink(Pid),
    {ok, Pid}.

%% Last row is the kickoff, make sure they start in the correct order.

init(_Args) ->
    
    Database = {database, {database, start_link, []},
	     transient, 2000, worker, [database]},
    Gui = {gui, {talkToJava, start_link, []},
	   transient, 2000, worker, [talkToJava]},
    Dynamic_Supervisor = {dynamic_supervisor, 
			  {dynamic_supervisor, start_link, []},
	                   transient, infinity, supervisor, [dynamic_supervisor]},
%    Intermediate = {intermediate, {intermediate, start_link, []},
%		   transient, 2000, worker, [intermediate, data_handler, directory, 
%					     file_handler, record_operation, writer]},
    Msg_controller = {msg_controller, {msg_controller, start_link, [dict:new()]},
		      transient, 2000, worker, [msg_controller, msg_logger, server_util]},
    Interpreter = {interpreter, {interpreter, start_link, []},
		   transient, 2000, worker, [interpreter, parser]},
    {ok,{{one_for_one,3,1}, [Msg_controller, 
			     Gui,
			     Dynamic_Supervisor,
%%                           Intermediate, 
			     Database,
			     Interpreter
			     ]}}.

