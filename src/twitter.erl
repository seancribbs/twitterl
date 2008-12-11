%%%-------------------------------------------------------------------
%%% File:      twitter.erl
%%% @author    Sean Cribbs <seancribbs@gmail.com> []
%%% @copyright 2008 Sean Cribbs
%%% @doc Bindings for the Twitter API
%%% Include 'twitter.hrl' in your module to get the records.
%%% @end
%%%
%%% @since 2008-10-30 by Sean Cribbs
%%% @type auth() = {User::string(), Password::string()}
%%% @type id() = integer() | string()
%%% @type user() = id() | email()
%%% @type device() = atom() | string()
%%%-------------------------------------------------------------------
-module(twitter).

-author('seancribbs@gmail.com').

-export([
  public_timeline/0, friends_timeline/1, friends_timeline/2,
  user_timeline/1, user_timeline/2, status/1, update/2, update/3,
  replies/1, replies/2, destroy_status/2, friends/1, friends/2,
  followers/1, followers/2, user/1, direct_messages/1, direct_messages/2,
  direct_messages_sent/1, direct_messages_sent/2, create_direct_message/3,
  destroy_direct_message/2, create_friend/2, create_friend/3,
  friendship_exists/3, verify_credentials/1, update_location/2,
  update_delivery_device/2, rate_limit_status/1, favorites/1, favorites/2,
  favorites/3, create_favorite/2, destroy_favorite/2, follow/2, trends/0,
  search/1, search/2, parse_twitter_time/1, build_json/1
]).

-compile([native]).

-include_lib("twitter/include/twitter.hrl").

%%%-------------------------------------------------------------------
%%% @doc Returns the 20 most recent statuses from non-protected users who
%%% have set a custom icon.
%%% @end
%%% @spec public_timeline() -> [#twitter_status]
%%%-------------------------------------------------------------------
public_timeline() ->
  JSON = get_json("http://twitter.com/statuses/public_timeline.json"),
  lists:map(fun parse_status/1, JSON).

%%%-------------------------------------------------------------------
%%% @doc Returns the 20 most recent statuses from people you follow
%%% @spec friends_timeline(Auth::auth()) -> [#twitter_status]
%%%-------------------------------------------------------------------
friends_timeline(Auth) when is_tuple(Auth) ->
  friends_timeline(Auth, []).
%%% @spec friends_timeline(Auth::auth(), UrlParams::proplist()) -> [#twitter_status]
friends_timeline(Auth, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Params) ->
  JSON = get_json("http://twitter.com/statuses/friends_timeline.json", Auth, Params),
  lists:map(fun parse_status/1, JSON).

%%%-------------------------------------------------------------------
%%% @doc Returns the 20 most recent statuses from the auth user
%%% @spec user_timeline(Auth::auth()) -> [#twitter_status]
%%%-------------------------------------------------------------------
user_timeline(Auth) when is_tuple(Auth) andalso size(Auth) == 2 ->
  friends_timeline(Auth, []).
%%% @spec friends_timeline(Auth::auth(), UrlParams::proplist()) -> [#twitter_status]
user_timeline(Auth, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Params) ->
  JSON = get_json("http://twitter.com/statuses/user_timeline.json", Auth, Params),
  lists:map(fun parse_status/1, JSON).

%%%-------------------------------------------------------------------
%%% @doc Loads a status by ID
%%% @spec show(StatusID::id()) -> #twitter_status
%%%-------------------------------------------------------------------
status(StatusID) when is_integer(StatusID) ->
  status(integer_to_list(StatusID));
status(StatusID) when is_list(StatusID) ->
  parse_status(get_json(["http://twitter.com/statuses/show/",StatusID,".json"])).

%%%-------------------------------------------------------------------
%%% @doc Sets the authenticated user's status
%%% @spec update(Auth::auth(), Message::string()) -> #twitter_status
%%%-------------------------------------------------------------------
update(Auth, Message) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Message) ->
  update(Auth, Message, []).
update(Auth, Message, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Message), is_list(Params) ->
  parse_status(post_json("http://twitter.com/statuses/update.json", Auth, [{status, Message}|Params])).

%%%-------------------------------------------------------------------
%%% @doc Returns the 20 most recent @replies
%%% @spec replies(Auth::auth()) -> [#twitter_status]
%%%-------------------------------------------------------------------
replies(Auth) when is_tuple(Auth) andalso size(Auth) == 2 ->
  replies(Auth, []).
replies(Auth, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Params) ->
  JSON = get_json("http://twitter.com/statuses/replies.json", Auth, Params),
  lists:map(fun parse_status/1, JSON).

%%%-------------------------------------------------------------------
%%% @doc Destroys a given status (assuming you own it)
%%% @spec destroy_status(Auth::auth(), StatusID::id()) -> #twitter_status
%%%-------------------------------------------------------------------
destroy_status(Auth, StatusID) when is_tuple(Auth) andalso size(Auth) == 2, is_integer(StatusID) ->
  destroy_status(Auth, integer_to_list(StatusID));
destroy_status(Auth, StatusID) when is_tuple(Auth) andalso size(Auth) == 2, is_list(StatusID) ->
  parse_status(post_json(["http://twitter.com/statuses/destroy/",StatusID,".json"], Auth)).

%%%-------------------------------------------------------------------
%%% @doc Retrieves 100 of the authenticating user's friends (people they follow)
%%% @spec friends(Auth::auth()) -> [#twitter_user]
%%%-------------------------------------------------------------------
friends(User) when is_integer(User) ->
  friends(integer_to_list(User));
friends(User) when is_list(User) ->
  friends(User, []);
friends(Auth) when is_tuple(Auth) andalso size(Auth) == 2 ->
  friends(Auth, []).

friends(User, Params) when is_integer(User), is_list(Params) ->
  friends(integer_to_list(User), Params);
friends(User, Params) when is_list(User), is_list(Params) ->
  JSON = get_json(["http://twitter.com/statuses/friends/",User,".json"], Params),
  lists:map(fun parse_user/1, JSON);
friends(Auth, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Params) ->
  JSON = get_json("http://twitter.com/statuses/friends.json", Auth, Params),
  lists:map(fun parse_user/1, JSON).

%%%-------------------------------------------------------------------
%%% @doc Retrieves 100 of the authenticating user's followers
%%% @spec followers(Auth::auth()) -> [#twitter_user]
%%%-------------------------------------------------------------------
followers(User) when is_integer(User) ->
  followers(integer_to_list(User));
followers(User) when is_list(User) ->
  followers(User, []);
followers(Auth) when is_tuple(Auth) andalso size(Auth) == 2 ->
  followers(Auth, []).

followers(User, Params) when is_integer(User), is_list(Params) ->
  followers(integer_to_list(User), Params);
followers(User, Params) when is_list(User), is_list(Params) ->
  JSON = get_json(["http://twitter.com/statuses/followers/",User,".json"], Params),
  lists:map(fun parse_user/1, JSON);
followers(Auth, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Params) ->
  JSON = get_json("http://twitter.com/statuses/followers.json", Auth, Params),
  lists:map(fun parse_user/1, JSON).

%%%-------------------------------------------------------------------
%%% @doc Reads extended information for a user
%%% @spec user(User::user()) -> #twitter_user
%%%-------------------------------------------------------------------
user(User) when is_integer(User) ->
  user(integer_to_list(User));
user(User) when is_list(User) ->
  URL = case lists:member($@, User) of
    false -> ["http://twitter.com/users/show/",User,".json"];
    _ -> add_params("http://twitter.com/users/show.json", [{email, User}])
  end,
  parse_user(get_json(URL)).

%%%-------------------------------------------------------------------
%%% @doc Retrieves the 20 most recent direct messages
%%% @spec direct_messages(Auth::auth()) -> [#twitter_direct_message]
%%%-------------------------------------------------------------------
direct_messages(Auth) when is_tuple(Auth) andalso size(Auth) == 2 ->
  direct_messages(Auth, []).
direct_messages(Auth, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Params) ->
  JSON = get_json("http://twitter.com/direct_messages.json", Auth, Params),
  lists:map(fun parse_direct_message/1, JSON).

%%%-------------------------------------------------------------------
%%% @doc Retrieves the 20 most recent direct messages
%%% @spec direct_messages_sent(Auth::auth()) -> [#twitter_direct_message]
%%%-------------------------------------------------------------------
direct_messages_sent(Auth) when is_tuple(Auth) andalso size(Auth) == 2 ->
  direct_messages_sent(Auth, []).
direct_messages_sent(Auth, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Params) ->
  JSON = get_json("http://twitter.com/direct_messages/sent.json", Auth, Params),
  lists:map(fun parse_direct_message/1, JSON).

%%%-------------------------------------------------------------------
%%% @doc Sends a new direct message
%%% @spec create_direct_message(Auth::auth(), Recipient::id(), Text::string()) -> #twitter_direct_message
%%%-------------------------------------------------------------------
create_direct_message(Auth, Recipient, Text) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Text) ->
  parse_direct_message(post_json("http://twitter.com/direct_messages/new.json", Auth, [{user, Recipient}, {text, Text}])).

%%%-------------------------------------------------------------------
%%% @doc Deletes a direct message
%%% @spec destroy_direct_message(Auth::auth(), ID::id()) -> #twitter_direct_message
%%%-------------------------------------------------------------------
destroy_direct_message(Auth, ID) when is_tuple(Auth) andalso size(Auth) == 2, is_integer(ID) ->
  destroy_direct_message(Auth, integer_to_list(ID));
destroy_direct_message(Auth, ID) when is_tuple(Auth) andalso size(Auth) == 2, is_list(ID) ->
  parse_direct_message(post_json(["http://twitter.com/direct_messages/destroy/",ID,".json"], Auth)).

%%%-------------------------------------------------------------------
%%% @doc Adds a friend (follows them)
%%% @spec create_friend(Auth::auth(), ID::id()) -> #twitter_user
%%%-------------------------------------------------------------------
create_friend(Auth, ID) when is_tuple(Auth) andalso size(Auth) == 2, is_integer(ID) ->
  create_friend(Auth, integer_to_list(ID));
create_friend(Auth, ID) when is_tuple(Auth) andalso size(Auth) == 2, is_list(ID) ->
  create_friend(Auth, ID, []).

create_friend(Auth, ID, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_integer(ID), is_list(Params) ->
  create_friend(Auth, integer_to_list(ID), Params);
create_friend(Auth, ID, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(ID), is_list(Params) ->
  parse_user(post_json(["http://twitter.com/friendships/create/",ID,".json"], Auth, Params)).

%%%-------------------------------------------------------------------
%%% @doc Checks whether a friendship exists between users
%%% @spec friendship_exists(Auth::auth(), User1::id(), User2::id()) -> true | false
%%%-------------------------------------------------------------------
friendship_exists(Auth, User1, User2) when is_tuple(Auth) andalso size(Auth) == 2 ->
  case get_json("http://twitter.com/friendships/exists.json", Auth, [{user_a, User1}, {user_b, User2}]) of
    <<"true">> -> true;
    <<"false">> -> false;
    _ -> error
  end.

%%%-------------------------------------------------------------------
%%% @doc Checks whether the given credentials will authenticate
%%% @spec verify_credentials(Auth::auth()) -> true | false
%%%-------------------------------------------------------------------
verify_credentials(Auth) when is_tuple(Auth) andalso size(Auth) == 2 ->
  try get_json("http://twitter.com/account/verify_credentials.json", Auth) of
    {struct, _} -> true;  % Naive, but it will probably work because of the 401 code when unauthorized
    _ -> false
  catch
    throw:{error, authorization_required} -> false;
    throw:{error, forbidden} -> false;
    E -> E
  end.

%%%-------------------------------------------------------------------
%%% @doc Updates the authenticated user's location
%%% @spec update_location(Auth::auth(), Location) -> #twitter_user
%%%-------------------------------------------------------------------
update_location(Auth, Location) when is_tuple(Auth) andalso size(Auth) == 2 ->
  parse_user(post_json("http://twitter.com/account/update_location.json", Auth, [{location, Location}])).

%%%-------------------------------------------------------------------
%%% @doc Updates the authenticated user's delivery device
%%% @spec update_delivery_device(Auth::auth(), Device::device()) -> #twitter_user
%%%-------------------------------------------------------------------
update_delivery_device(Auth, Device) when is_tuple(Auth) andalso size(Auth) == 2 ->
  parse_user(post_json("http://twitter.com/account/update_delivery_device.json", Auth, [{device, Device}])).


%%%-------------------------------------------------------------------
%%% @doc Checks the number of remaining API requests left this hour
%%% @spec rate_limit_status(Auth::auth()) -> #twitter_rate_limit_status
%%%-------------------------------------------------------------------
rate_limit_status(Auth) when is_tuple(Auth) andalso size(Auth) == 2 ->
  parse_rate_limit_status(get_json("http://twitter.com/account/rate_limit_status.json", Auth)).

%%%-------------------------------------------------------------------
%%% @doc Lists 20 most recent favorited statuses for authenticated user
%%% @spec favorites(Auth::auth()) -> [#twitter_status]
%%%-------------------------------------------------------------------
favorites(Auth) when is_tuple(Auth) andalso size(Auth) == 2 ->
  favorites(Auth, self, []).

favorites(Auth, User) when is_tuple(Auth) andalso size(Auth) == 2, is_integer(User) ->
  favorites(Auth, integer_to_list(User));
favorites(Auth, User) when is_tuple(Auth) andalso size(Auth) == 2, is_list(User) ->
  favorites(Auth, User, []).

favorites(Auth, self, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Params) ->
  JSON = get_json("http://twitter.com/favorites.json", Auth, Params),
  lists:map(fun parse_status/1, JSON);
favorites(Auth, User, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(User), is_list(Params) ->
  JSON = get_json(["http://twitter.com/favorites/", User, ".json"], Auth, Params),
  lists:map(fun parse_status/1, JSON).

%%%-------------------------------------------------------------------
%%% @doc Favorites a given status
%%% @spec create_favorite(Auth::auth(), ID::id()) -> #twitter_status
%%%-------------------------------------------------------------------
create_favorite(Auth, ID) when is_tuple(Auth) andalso size(Auth) == 2, is_integer(ID) ->
  create_favorite(Auth, integer_to_list(ID));
create_favorite(Auth, ID) when is_tuple(Auth) andalso size(Auth) == 2, is_list(ID) ->
  parse_status(post_json(["http://twitter.com/favorites/create/",ID,".json"], Auth, [])).

%%%-------------------------------------------------------------------
%%% @doc Unfavorites a given status
%%% @spec destroy_favorite(Auth::auth(), ID::id()) -> #twitter_status
%%%-------------------------------------------------------------------
destroy_favorite(Auth, ID) when is_tuple(Auth) andalso size(Auth) == 2, is_integer(ID) ->
  destroy_favorite(Auth, integer_to_list(ID));
destroy_favorite(Auth, ID) when is_tuple(Auth) andalso size(Auth) == 2, is_list(ID) ->
  parse_status(post_json(["http://twitter.com/favorites/destroy/",ID,".json"], Auth, [])).

%%%-------------------------------------------------------------------
%%% @doc Enables notifications for a given user
%%% @spec follow(Auth::auth(), User::id()) -> #twitter_user
%%%-------------------------------------------------------------------
follow(Auth, User) when is_tuple(Auth) andalso size(Auth) == 2, is_integer(User) ->
  follow(Auth, integer_to_list(User));
follow(Auth, User) when is_tuple(Auth) andalso size(Auth) == 2, is_list(User) ->
  parse_user(post_json(["http://twitter.com/notifications/follow/",User,".json"], Auth)).

%%%-------------------------------------------------------------------
%%% @doc Lists the latest most popular search terms on Twitter
%%% @spec trends() -> {AsOf::httptime(), [#twitter_search_trend]}
%%%-------------------------------------------------------------------
trends() ->
  parse_trends(get_json("http://search.twitter.com/trends.json")).

%%%-------------------------------------------------------------------
%%% @doc Searchs for recent statuses with the given search terms
%%%-------------------------------------------------------------------
search(Terms) when is_list(Terms) ->
  search(Terms, []).
search(Terms, Params) when is_list(Terms), is_list(Params) ->
  parse_search_results(get_json("http://search.twitter.com/search.json", [{q, Terms}|Params])).

%%%-------------------------------------------------------------------
%%% @doc Converts any number of twitter objects to mochijson2-compatible structs
%%%-------------------------------------------------------------------
build_json(List) when is_list(List) ->
  lists:map(fun build_json/1, List);
build_json(Bin) when is_binary(Bin) ->
  Bin;
build_json(Int) when is_integer(Int) ->
  Int;
build_json(Float) when is_float(Float) ->
  Float;
build_json(undefined) -> null;
build_json(null) -> null;
build_json(false) -> false;
build_json(true) -> true;
build_json(Atom) when is_atom(Atom) ->
  list_to_binary(atom_to_list(Atom));
build_json({Date, Time}) when is_tuple(Date) andalso size(Date) == 3, 
                              is_tuple(Time) andalso size(Time) == 3 ->
  list_to_binary(httpd_util:rfc1123_date({Date, Time}));
build_json(User) when is_record(User, twitter_user) ->
  {struct, 
    [
      {<<"id">>, build_json(User#twitter_user.id)},
      {<<"name">>, build_json(User#twitter_user.name)},
      {<<"screen_name">>, build_json(User#twitter_user.screen_name)},
      {<<"location">>, build_json(User#twitter_user.location)},
      {<<"description">>, build_json(User#twitter_user.description)},
      {<<"profile_image_url">>, build_json(User#twitter_user.profile_image_url)},
      {<<"url">>, build_json(User#twitter_user.url)},
      {<<"protected">>, build_json(User#twitter_user.protected)},
      {<<"followers_count">>, build_json(User#twitter_user.followers_count)},
      {<<"profile_background_color">>, build_json(User#twitter_user.profile_background_color)},
      {<<"profile_text_color">>, build_json(User#twitter_user.profile_text_color)},
      {<<"profile_link_color">>, build_json(User#twitter_user.profile_link_color)},
      {<<"profile_sidebar_fill_color">>, build_json(User#twitter_user.profile_sidebar_fill_color)},
      {<<"profile_sidebar_border_color">>, build_json(User#twitter_user.profile_sidebar_border_color)},
      {<<"favourites_count">>, build_json(User#twitter_user.favourites_count)},
      {<<"utc_offset">>, build_json(User#twitter_user.utc_offset)},
      {<<"time_zone">>, build_json(User#twitter_user.time_zone)},
      {<<"following">>, build_json(User#twitter_user.following)},
      {<<"notifications">>, build_json(User#twitter_user.notifications)},
      {<<"statuses_count">>, build_json(User#twitter_user.statuses_count)},
      {<<"status">>, build_json(User#twitter_user.status)}
    ]
  };
build_json(Status) when is_record(Status, twitter_status) ->
  {struct, 
    [
      {<<"id">>, build_json(Status#twitter_status.id)},
      {<<"text">>, build_json(Status#twitter_status.text)},
      {<<"user">>, build_json(Status#twitter_status.user)},
      {<<"created_at">>, build_json(Status#twitter_status.created_at)},
      {<<"in_reply_to_status_id">>, build_json(Status#twitter_status.in_reply_to_status_id)},
      {<<"in_reply_to_user_id">>, build_json(Status#twitter_status.in_reply_to_user_id)},
      {<<"favorited">>, build_json(Status#twitter_status.favorited)},
      {<<"truncated">>, build_json(Status#twitter_status.truncated)},
      {<<"source">>, build_json(Status#twitter_status.source)}
    ]
  };
build_json(DirectMessage) when is_record(DirectMessage, twitter_direct_message) ->
  {struct, 
    [
      {<<"id">>, build_json(DirectMessage#twitter_direct_message.id)},
      {<<"text">>, build_json(DirectMessage#twitter_direct_message.text)},
      {<<"created_at">>, build_json(DirectMessage#twitter_direct_message.created_at)},
      {<<"sender">>, build_json(DirectMessage#twitter_direct_message.sender)},
      {<<"recipient">>, build_json(DirectMessage#twitter_direct_message.recipient)}
    ]
  };
build_json(RateLimitStatus) when is_record(RateLimitStatus, twitter_rate_limit_status) ->
  {struct, 
    [
      {<<"remaining_hits">>, build_json(RateLimitStatus#twitter_rate_limit_status.remaining_hits)},
      {<<"hourly_limit">>, build_json(RateLimitStatus#twitter_rate_limit_status.hourly_limit)},
      {<<"reset_time_in_seconds">>, build_json(RateLimitStatus#twitter_rate_limit_status.reset_time_in_seconds)},
      {<<"reset_time">>, build_json(RateLimitStatus#twitter_rate_limit_status.reset_time)}
    ]
  };
build_json(SearchTrend) when is_record(SearchTrend, twitter_search_trend) ->
  {struct, 
    [
      {<<"name">>, build_json(SearchTrend#twitter_search_trend.name)},
      {<<"url">>, build_json(SearchTrend#twitter_search_trend.url)}
    ]
  };
build_json(SearchResults) when is_record(SearchResults, twitter_search_results) ->
  {struct, 
    [
      {<<"results">>, build_json(SearchResults#twitter_search_results.results)},
      {<<"since_id">>, build_json(SearchResults#twitter_search_results.since_id)},
      {<<"max_id">>, build_json(SearchResults#twitter_search_results.max_id)},
      {<<"refresh_url">>, build_json(SearchResults#twitter_search_results.refresh_url)},
      {<<"results_per_page">>, build_json(SearchResults#twitter_search_results.results_per_page)},
      {<<"total">>, build_json(SearchResults#twitter_search_results.total)},
      {<<"page">>, build_json(SearchResults#twitter_search_results.page)},
      {<<"q">>, build_json(SearchResults#twitter_search_results.q)}
    ]
  };
build_json(SearchResult) when is_record(SearchResult, twitter_search_result) ->
  {struct, 
    [
      {<<"id">>, build_json(SearchResult#twitter_search_result.id)},
      {<<"text">>, build_json(SearchResult#twitter_search_result.text)},
      {<<"to_user_id">>, build_json(SearchResult#twitter_search_result.to_user_id)},
      {<<"from_user">>, build_json(SearchResult#twitter_search_result.from_user)},
      {<<"from_user_id">>, build_json(SearchResult#twitter_search_result.from_user_id)},
      {<<"iso_language_code">>, build_json(SearchResult#twitter_search_result.iso_language_code)},
      {<<"profile_image_url">>, build_json(SearchResult#twitter_search_result.profile_image_url)},
      {<<"created_at">>, build_json(SearchResult#twitter_search_result.created_at)}
    ]
  };
build_json(_) -> null.

%%%-------------------------------------------------------------------
%%% Private API
%%%-------------------------------------------------------------------
get_json(URL) ->
  parse_json(api_get(URL)).
get_json(URL, Params) when is_list(Params) ->
  parse_json(api_get(URL, Params));
get_json(URL, Auth) when is_tuple(Auth) andalso size(Auth) == 2 ->
  parse_json(api_get(URL, Auth)).
get_json(URL, Auth, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Params) ->
  parse_json(api_get(URL, Auth, Params)).

post_json(URL, Auth) when is_tuple(Auth) andalso size(Auth) == 2 ->
  parse_json(api_post(URL, Auth)).
post_json(URL, Auth, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Params) ->
  parse_json(api_post(URL, Auth, Params)).

api_get(URL) ->
  api_get(URL, []).
api_get(URL, Params) when is_list(Params) ->
  ok = start(),
  handle_request(http:request(add_params(lists:flatten(URL), Params)));
api_get(URL, Auth) when is_tuple(Auth) andalso size(Auth) == 2 ->
  api_get(URL, Auth, []).
api_get(URL, Auth, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Params) ->
  ok = start(),
  handle_request(http:request(get, {add_params(lists:flatten(URL), Params), [basic_auth(Auth)]}, [], [])).

api_post(URL, Auth) when is_tuple(Auth) andalso size(Auth) == 2 ->
  api_post(URL, Auth, []).
api_post(URL, Auth, Params) when is_tuple(Auth) andalso size(Auth) == 2, is_list(Params) ->
  ok = start(),
  handle_request(http:request(post, {lists:flatten(URL), [basic_auth(Auth)],"application/x-www-form-urlencoded", mochiweb_util:urlencode(Params)}, [], [])).

handle_request({ok, Result}) ->
  {Status, _Headers, Body} = Result,
  case Status of
    {_,200,_} ->
      Body;
    {_,201,_} ->
      ok;
    {_,401,_} ->
      throw({error, authorization_required});
    {_,403,_} ->
      throw({error, forbidden});
    _ ->
      throw({error, Status})
  end;

handle_request({error, Reason}) ->
  throw({error, Reason}).

add_params(URL, []) ->
  URL;
add_params(URL, Params) when is_list(Params) ->
  lists:flatten([URL,"?",mochiweb_util:urlencode(Params)]).

basic_auth({User, Password}) ->
  basic_auth(User, Password).
basic_auth(User, Password) ->
  {"Authorization", lists:flatten(["Basic ", binary_to_list(base64:encode(lists:flatten([User,":",Password])))])}.

start() ->
  case inets:start() of
    {error,{already_started, inets}} -> ok;
    {error, Reason} -> {error, Reason};
    _ -> ok
  end.

parse_json(Data) ->
  mochijson2:decode(Data).

parse_status({struct, PropList}) ->
  #twitter_status {
    id=proplists:get_value(<<"id">>, PropList),
    text=proplists:get_value(<<"text">>, PropList),
    user=parse_user(proplists:get_value(<<"user">>, PropList)),
    created_at=parse_twitter_time(proplists:get_value(<<"created_at">>, PropList)),
    truncated=proplists:get_value(<<"truncated">>, PropList),
    favorited=proplists:get_value(<<"favorited">>, PropList),
    source=proplists:get_value(<<"source">>, PropList),
    in_reply_to_user_id=proplists:get_value(<<"in_reply_to_user_id">>, PropList),
    in_reply_to_status_id=proplists:get_value(<<"in_reply_to_status_id">>, PropList)
  };
parse_status(_) -> undefined.

parse_direct_message({struct, PropList}) ->
  #twitter_direct_message {
    id=proplists:get_value(<<"id">>, PropList),
    text=proplists:get_value(<<"text">>, PropList),
    created_at=parse_twitter_time(proplists:get_value(<<"created_at">>, PropList)),
    sender=parse_user(proplists:get_value(<<"sender">>, PropList)),
    recipient=parse_user(proplists:get_value(<<"recipient">>, PropList))
  };
parse_direct_message(_) -> undefined.

parse_user({struct, PropList}) ->
  #twitter_user {
    id=proplists:get_value(<<"id">>, PropList),
    screen_name=proplists:get_value(<<"screen_name">>, PropList),
    name=proplists:get_value(<<"name">>, PropList),
    description=proplists:get_value(<<"description">>, PropList),
    url=proplists:get_value(<<"url">>, PropList),
    profile_image_url=proplists:get_value(<<"profile_image_url">>, PropList),
    protected=proplists:get_value(<<"protected">>, PropList),
    location=proplists:get_value(<<"location">>, PropList),
    followers_count=proplists:get_value(<<"followers_count">>, PropList),
    status=parse_status(proplists:get_value(<<"status">>, PropList)),
    profile_background_color=proplists:get_value(<<"profile_background_color">>, PropList),
    profile_text_color=proplists:get_value(<<"profile_text_color">>, PropList),
    profile_link_color=proplists:get_value(<<"profile_link_color">>, PropList),
    profile_sidebar_fill_color=proplists:get_value(<<"profile_sidebar_fill_color">>, PropList),
    profile_sidebar_border_color=proplists:get_value(<<"profile_sidebar_border_color">>, PropList),
    favourites_count=proplists:get_value(<<"favourites_count">>, PropList),
    utc_offset=proplists:get_value(<<"utc_offset">>, PropList),
    time_zone=proplists:get_value(<<"time_zone">>, PropList),
    following=proplists:get_value(<<"following">>, PropList),
    notifications=proplists:get_value(<<"notifications">>, PropList),
    statuses_count=proplists:get_value(<<"statuses_count">>, PropList)
  };
parse_user(_) -> undefined.

parse_rate_limit_status({struct, PropList}) ->
  #twitter_rate_limit_status {
    remaining_hits=proplists:get_value(<<"remaining_hits">>, PropList),
    hourly_limit=proplists:get_value(<<"hourly_limit">>, PropList),
    reset_time_in_seconds=proplists:get_value(<<"reset_time_in_seconds">>, PropList),
    reset_time=parse_twitter_time(proplists:get_value(<<"reset_time">>, PropList))
  };
parse_rate_limit_status(_) -> undefined.

parse_trends({struct, PropList}) ->
  {httpd_util:convert_request_date(binary_to_list(proplists:get_value(<<"as_of">>, PropList))),
    lists:map(fun parse_trend/1, proplists:get_value(<<"trends">>, PropList))};
parse_trends(_) -> undefined.

parse_trend({struct, PropList}) ->
  #twitter_search_trend {
    name=proplists:get_value(<<"name">>, PropList),
    url=proplists:get_value(<<"url">>, PropList)
  };
parse_trend(_) -> undefined.

parse_search_results({struct, PropList}) ->
  #twitter_search_results {
    results=lists:map(fun parse_search_result/1, proplists:get_value(<<"results">>, PropList)),
    since_id=proplists:get_value(<<"since_id">>, PropList),
    max_id=proplists:get_value(<<"max_id">>, PropList),
    refresh_url=proplists:get_value(<<"refresh_url">>, PropList),
    results_per_page=proplists:get_value(<<"results_per_page">>, PropList),
    total=proplists:get_value(<<"total">>, PropList),
    page=proplists:get_value(<<"page">>, PropList),
    q=proplists:get_value(<<"query">>, PropList)
  };
parse_search_results(_) -> undefined.

parse_search_result({struct, PropList}) ->
  #twitter_search_result {
    id=proplists:get_value(<<"id">>, PropList),
    text=proplists:get_value(<<"text">>, PropList),
    to_user_id=proplists:get_value(<<"to_user_id">>, PropList),
    from_user=proplists:get_value(<<"from_user">>, PropList),
    from_user_id=proplists:get_value(<<"from_user_id">>, PropList),
    iso_language_code=proplists:get_value(<<"iso_language_code">>, PropList),
    profile_image_url=proplists:get_value(<<"profile_image_url">>, PropList),
    created_at=httpd_util:convert_request_date(binary_to_list(proplists:get_value(<<"created_at">>, PropList)))
  };
parse_search_result(_) -> undefined.

% Parses <<"Tue Nov 11 14:34:06 +0000 2008">> format
parse_twitter_time(Bin) when is_binary(Bin) ->
  parse_twitter_time(binary_to_list(Bin));
parse_twitter_time([
    _D,_A,_Y, _SP,
    M, O, N, _SP,
    D1, D2, _SP,
    H1, H2, $:,
    M1, M2, $:,
    S1, S2, _SP,
    $+, $0, $0, $0, $0, _SP,
    Y1, Y2, Y3, Y4 | _Rest
  ]) ->
    Year = list_to_integer([Y1,Y2,Y3,Y4]),
    Month = http_util:convert_month([M,O,N]),
    Day = list_to_integer([D1,D2]),
    Hour = list_to_integer([H1,H2]),
    Minute = list_to_integer([M1,M2]),
    Second = list_to_integer([S1,S2]),
    {{Year,Month,Day},{Hour,Minute,Second}};
parse_twitter_time(Whatever) -> Whatever.
