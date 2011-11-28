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
    Torrentdata = {torrentdata, {torrentdata, start_link, []},
	     transient, 2000, worker, [torrentdata]},
    Dynamic_Supervisor = {dynamic_supervisor, 
			  {dynamic_supervisor, start_link, []},
	                   transient, 2000, supervisor, [dynamic_supervisor]},
%   Filehandler = {filehandler, {filehandler, start_link, Args},
%		   transient, 2000, worker, [filerhandler]},
    {ok,{{one_for_one,3,1}, [Torrentdata, Dynamic_Supervisor]}}.
