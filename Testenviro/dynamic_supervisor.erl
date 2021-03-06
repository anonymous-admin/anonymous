%% Author: Johan

-module(dynamic_supervisor).
-behaviour(supervisor).
-export([start_link/0, init/1, start_child/2]). 
-include("defs.hrl").

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init(_Args) ->
    {ok,{{one_for_one,3,1}, []}}.

start_child(Child, Args) ->
    case Child of 
	tracker ->
	    Id = list_to_atom(Args#tracker_info.url),
	    TrackerChild = {Id, {tracker_interactor, start_link, [[Id, Args]]},
			    transient, 2000, worker, [tracker_interactor]},
	    Pid = supervisor:start_child(dynamic_supervisor, TrackerChild);
	torrent -> 
	    Id = list_to_atom(binary_to_list(Args#torrent.id)),
	    TorrentChild = {Id, {torrent, start_link, [[Id, Args]]},
			    transient, 2000, worker, [torrent]},
	    Pid = supervisor:start_child(dynamic_supervisor, TorrentChild)
    end,
    {ok, Pid}.
