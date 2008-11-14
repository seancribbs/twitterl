-record(twitter_user, {id,name,screen_name,location,description,
                      profile_image_url,url,protected,followers_count,
                      profile_background_color,profile_text_color,profile_link_color,
                      profile_sidebar_fill_color,profile_sidebar_border_color,
                      favourites_count,utc_offset,time_zone,following,notifications,
                      statuses_count,status}).
-record(twitter_status, {id,text,user,created_at,in_reply_to_status_id,
                         in_reply_to_user_id,favorited,truncated,source}).
-record(twitter_direct_message, {id,text,created_at,sender,recipient}).
-record(twitter_rate_limit_status,{remaining_hits,hourly_limit,
                                   reset_time_in_seconds,reset_time}).
-record(twitter_search_trend,{name,url}).
-record(twitter_search_results,{results,since_id,max_id,refresh_url,results_per_page,total,page,
                                q}).
-record(twitter_search_result,{id,text,to_user_id,from_user,from_user_id,
                               iso_language_code,profile_image_url,created_at}).