%% Author: Johan

-module(dynamic_supervisor).
-behaviour(supervisor).
-export([start_link/0, init/1, start_torrent/1, start_tracker/2]). 
-include("defs.hrl").

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, [{debug, [trace]}]).

init(_Args) ->
    {ok,{{one_for_one,3,1}, []}}.

start_tracker(Tracker, TorrentId) ->
    Id = list_to_atom(Tracker#tracker_info.url),
    TrackerChild = {Id, {tracker_interactor, start_link, [[Tracker, 3000, TorrentId]]},
			 transient, 2000, worker, [tracker_interactor]},
    supervisor:start_child(dynamic_supervisor, TrackerChild).

start_torrent(Torrent) ->
    Id = list_to_atom(binary_to_list(Torrent#torrent.id)),
    TorrentChild = {Id, {torrent, start_link, [[Id, Torrent]]},
			 transient, 2000, worker, [torrent]},
    supervisor:start_child(dynamic_supervisor, TorrentChild).
