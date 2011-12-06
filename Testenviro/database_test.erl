-module(database_test).
-include_lib("eunit/include/eunit.hrl").
-include("defs.hrl").
-export([create_record/1, display_table/0]).

start_test_() ->
    [?_assert(database:start_link() =:= ok)].

insert_record_test_() ->
    Record1 = create_record(1),
    Record2 = create_record(2),
   [?_assert(gen_server:cast(database, {notify, torrent_info, {Record1#torrent.id, Record1}}) =:= ok),
    ?_assert(gen_server:cast(database, {notify, torrent_info, {Record2#torrent.id, Record2}}) =:= ok),
    ?_assert(length(ets:tab2list(database_table)) =:= 2)].

delete_record_test_() ->
    Record1 = create_record(1),
   [?_assert(gen_server:cast(database, {notify, torrent_status, {Record1#torrent.id, deleted}}) =:= ok),
    ?_assert(length(ets:tab2list(database_table)) =:= 1)].

update_record_test_() ->
    Record2 = create_record(2),
   [?_assert(gen_server:cast(database, {notify, piece_length, {Record2#torrent.id, 50000}}) =:= ok)].
    

create_record(N) ->
    case N of
	1 ->
	    #torrent{id = 1, info_hash_tracker = 2, 
	     announce = 3, creation_date = 4, comment = 5, 
	     created_by = 6, encoding = 7, files = 8,
	     filename = 9, piece_length = 10, 
	     number_of_pieces = 11, file_length = 12,
	     bitfield = 13 };
        2->
	    #torrent{id = 14, info_hash_tracker = 15, 
	     announce = 16, creation_date = 18, comment = 19, 
	     created_by = 20, encoding = 21, files = 22,
	     filename = 23, piece_length = 24, 
	     number_of_pieces = 25, file_length = 26,
	     bitfield = 27 }
    end.

display_table() ->
    ets:tab2list(database_table).
