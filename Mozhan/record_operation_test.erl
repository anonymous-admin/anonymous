-module(record_operation_test).
-include_lib("eunit/include/eunit.hrl").
-record (torrent,{filename,files,number_of_pieces,piece_length}).

is_multiple_test_() ->
    [?_assert(record_operation:is_multiple(#torrent{files = novalue}) =:= false),
     ?_assert(record_operation:is_multiple(#torrent{files = something}) =:= true)].

get_PieceNum_test_() ->
    [?_assert(record_operation:get_PieceNum(#torrent{number_of_pieces = 8}) =:= 8)].

get_FileName_test_() ->
    [?_assert(record_operation:get_FileName(#torrent{filename = "test.txt"}) =:= "test.txt")].

get_Piece_Length_test_() ->
    [?_assert(record_operation:get_Piece_Length(#torrent{piece_length = 8}) =:= 8)].
