-module(torrent_interpreter).
-export([read_file/1, get_info_hash/1, get_announce/1, get_filename/1, get_piece_length/1, 
	 get_creation_date/1, get_comment/1, get_number_of_pieces/1, get_bitfield/1,
	 get_created_by/1, get_encoding/1, get_files/1]).

read_file(FileName) ->
  {ok, FileContents} = file:read_file(FileName),
  {{dict, Info}, _Remainder} = parser:decode(FileContents),
  {info, Info}.

get_info_hash({info, Info}) ->
    Information = dict:fetch(<<"info">>, Info),
    BencodedInfo = binary_to_list(parser:encode(Information)),
    hash_gen(encoder(BencodedInfo),2).

get_announce({info, Info}) ->
    Info_keys = dict:fetch_keys(Info),
    case lists:member(<<"announce-list">>, Info_keys) of
	true ->
	    {list, Announce_list} = dict:fetch(<<"announce-list">>, Info),
	    to_string(Announce_list);
	false ->
	    [binary_to_list(dict:fetch(<<"announce">>, Info))]
    end.

get_creation_date({info, Info}) ->
    Creation_date = dict:fetch(<<"creation date">>, Info),
    Creation_date.

get_comment({info, Info}) ->
    Comment = dict:fetch(<<"comment">>, Info),
    binary_to_list(Comment).

get_created_by({info, Info}) ->
    Created_by = dict:fetch(<<"created by">>, Info),
    binary_to_list(Created_by).

get_encoding({info, Info}) ->
    Encoding = dict:fetch(<<"encoding">>, Info),
    binary_to_list(Encoding).

get_files({info, Info}) ->
    Files = get_info_dec(<<"files">>, Info),
    Files.

get_filename({info, Info}) ->
    Name = get_info_dec(<<"name">>, Info),
    binary_to_list(Name).
    
get_piece_length({info, Info}) ->
    get_info_dec(<<"piece length">>, Info).

get_number_of_pieces({info, Info}) ->
    PieceHashes = get_info_dec(<<"pieces">>, Info),
    HashLength = 20,
    round(length(binary_to_list(PieceHashes)) / HashLength).

get_bitfield({info, Info}) ->
    NumberOfPieces = get_number_of_pieces({info, Info}),
    create_bitfield_binary(NumberOfPieces).

%
% Internal
%

encoder(Data)->
    crypto:start(),
    Info_hash = [ hd(integer_to_list(N, 16)) || << N:4 >> <= crypto:sha(Data) ],
    Info_hash.

hash_gen(List, Num) when Num < length(List)->
    {A, B} = lists:split(Num,List),
    hash_gen(A ++ [37] ++ B, Num+3 );
hash_gen(List, _) ->
    [37] ++ List.

to_string([]) ->
    [];
to_string([H|T]) ->
    {list,B} = H,
    [binary_to_list(hd(B))] ++ to_string(T).

get_info_dec(Name, Info) ->
    {dict,{dict, Info_dec}} = {dict, dict:fetch(<<"info">>, Info)},
    dict:fetch(Name, Info_dec).

create_bitfield_binary(0) ->
    <<>>;
create_bitfield_binary(NumberOfPieces) ->
  % Here be dragons. By doing NumberOfPieces rem 8 we get the number of bits
  % that won't be fitting nicely into a byte. So they need to be padded out
  % with leading 0s. To find out how many padding zeros we need we subtract
  % that number from 8. But if we had no overflow originally subtracting it
  % from 8 will give us 8. The final rem 8 turns that potential 8 into a 0
  % while leaving any other values untouched.
  LeaderLength = (8 - NumberOfPieces rem 8) rem 8,
  create_bitfield_binary(<<>>, LeaderLength, NumberOfPieces).

create_bitfield_binary(Binary, 0, 0) ->
    Binary;
create_bitfield_binary(Binary, 0, NumberOfPieces) ->
    NewBinary = <<Binary/bitstring, 1:1>>,
    create_bitfield_binary(NewBinary, 0, NumberOfPieces - 1);
create_bitfield_binary(Binary, LeaderLength, NumberOfPieces) ->
    NewBinary = <<Binary/bitstring, 0:1>>,
    create_bitfield_binary(NewBinary, LeaderLength - 1, NumberOfPieces).
