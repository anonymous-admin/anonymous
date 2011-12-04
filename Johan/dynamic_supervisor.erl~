%% Author: Johan

-module(dynamic_supervisor).
-behaviour(supervisor).
-export([start_link/0, init/1, start_child/2]). 

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init(_Args) ->
    {ok,{{one_for_one,3,1}, []}}.

start_child(Child, Args) ->
    Id = now(),
    case Child of 
	tracker ->
	    TrackerChild = {Id, {tracker_interactor, start_link, Args},
			    transient, 2000, worker, [tracker_interactor]},
	    supervisor:start_child(dynamic_supervisor, TrackerChild);
	torrent -> 
	    TorrentChild = {Id, {torrent, start_link, Args},
			    transient, 2000, worker, [torrent]},
	    supervisor:start_child(dynamic_supervisor, TorrentChild)
    end,
    {ok, Id}.
