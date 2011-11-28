-module(torrent_supervisor).
-behaviour(supervisor).
-export([start_link/0, start_in_shell/0, init/1, start_child/2]).

start_link() ->
    %%supervisor:start_link(?MODULE, []).
    start_in_shell().

start_in_shell() ->
    {ok, Pid} = supervisor:start_link({local, ?MODULE}, ?MODULE, []),
    unlink(Pid),
    {ok, Pid}.

init(_Args) ->
    TorrentdataChild = {torrentdata, {torrentdata, start_link, []},
	     transient, 2000, worker, [torrentdata]},
    {ok,{{one_for_one,3,1}, [TorrentdataChild]}}.
    %%Put more children here

start_child(Child, Args) ->
    Id = now(),
    case Child of 
	tracker ->
	    TrackerChild = {Id, {tracker_interactor, start_link, Args},
			    transient, 2000, worker, [tracker_interactor]},
	    supervisor:start_child(torrent_supervisor, TrackerChild);
	_ -> ok
    end.
	       
