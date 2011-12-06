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

init(_Args) ->
    Database = {database, {database, start_link, []},
	     transient, 2000, worker, [database]},
%    Gui = {gui, {talkToJava, start, []},
%	   transient, 2000, worker, [talkToJava]},
    Dynamic_Supervisor = {dynamic_supervisor, 
			  {dynamic_supervisor, start_link, []},
	                   transient, 2000, supervisor, [dynamic_supervisor]},
%    Filehandler = {filehandler, {filehandler, start_link, Args},
%		   transient, 2000, worker, [filerhandler]},
    Msg_controller = {msg_controller, {msg_controller, start_link, [dict:new()]},
		      transient, 2000, worker, [msg_controller, msg_logger, server_util]},
    Interpreter = {interpreter, {interpreter, start_link, []},
		   transient, 2000, worker, [interpreter, parser]},
    {ok,{{one_for_one,3,1}, [Database, Dynamic_Supervisor, Msg_controller, Interpreter]}}.