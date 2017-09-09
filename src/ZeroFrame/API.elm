port module ZeroFrame.API exposing (
    wrapperConfirm
    , wrapperInnerLoaded
    , wrapperGetLocalStorage
    , wrapperGetState
    , wrapperNotification
    , wrapperOpenWindow
    , wrapperPermissionAdd
    , wrapperPrompt
    , wrapperPushState
    , wrapperSetLocalStorage
    , wrapperSetTitle
    , wrapperSetViewport
    , certAdd
    , certSelect
    , channelJoin
    , dbQuery
    , fileDelete
    , fileGet
    , fileList
    , fileQuery
    , fileRules
    , fileWrite
    , serverInfo
    , siteInfo
    , sitePublish
    , siteSign
    , mergerSiteAdd
    , mergerSiteDelete
    , mergerSiteList
    )

{-| This library makes (eventually) all of the ZeroFrame API calls available to Elm so that Elm can be used to develop apps for ZeroNet. 

# Wrapper calls
@docs wrapperConfirm, wrapperInnerLoaded, wrapperGetLocalStorage, wrapperSetLocalStorage, wrapperGetState, wrapperNotification, wrapperOpenWindow, wrapperPermissionAdd, wrapperPrompt, wrapperPushState, wrapperSetTitle, wrapperSetViewport

# UI server calls
@docs certAdd, certSelect, channelJoin, dbQuery, fileDelete, fileGet, fileList, fileQuery, fileRules, fileWrite, serverInfo, siteInfo, sitePublish, siteSign 

# Merger plugin
@docs mergerSiteAdd, mergerSiteDelete, mergerSiteList

-}

import Json.Encode exposing (Value)
import Json.Encode as E

import Json.Decode exposing (decodeValue)
import Json.Decode as D

import List exposing (concat,map)
import Result as R

import Maybe as M

import ZeroFrame.Core exposing (Z, command, commandThen)

-- Wrapper calls

{-| Use wrapperConfirm to post a confirmation message to the user.

    wrapperConfirm "Go for it?" (Just "Go!")

-}
wrapperConfirm : String -> Maybe String -> (Bool -> msg) -> Z msg ()
wrapperConfirm message caption handler =
    let
        v = concat [
            [E.string message]
            , optional E.string caption
            ] |> E.list

        h v = case decodeValue D.bool v of
          Ok x -> Just (handler x)
          Err _ -> Nothing

    in commandThen "wrapperConfirm" v h 

{-| Applies window.location.hash to page url.  Call when the page is fully loaded to jump to the desired anchor point.

-}

wrapperInnerLoaded : () -> Z msg ()
wrapperInnerLoaded () = command "wrapperInnerLoaded" E.null


{-| Request the contents of the browser's local storage for the site.

-}

wrapperGetLocalStorage : (Value -> msg) -> Z msg () 
wrapperGetLocalStorage handler = 
  commandThen "wrapperGetLocalStorage" E.null (handler >> Just)

{-| Request the browser's current history state object.

-}

wrapperGetState : (Value -> msg) -> Z msg ()
wrapperGetState h =
  commandThen "wrapperGetState" E.null (h >> Just)

{-| Display a notification.

Usage: wrapperNotification ("info"|"error"|"done") message [timeout]

-}
wrapperNotification : String -> String -> Maybe Int -> Z msg ()
wrapperNotification t message to =
    let
        v = concat [
            [E.string t, E.string message]
            , optional E.int to
            ] |> E.list
    in command "wrapperNotification" v
       

{-| Navigates or opens a new popup.

Usage: wrapperOpenWindow url [target] [specs]

-}

wrapperOpenWindow : String -> Maybe String -> Maybe String -> Z msg ()
wrapperOpenWindow u t s =
    let
       v = concat [
           [E.string u]
           , optional E.string t
           , optional E.string s
           ] |> E.list
    in command "wrapperOpenWindow" v

{-| Request a permission.

-}
wrapperPermissionAdd : String -> Z msg ()
wrapperPermissionAdd s = command "wrapperPermissionAdd" (E.string s)

{-| Prompt for input.

Usage: wrapperPrompt promptMessage ("text"|"password"|etc.)

The default type is "text".

-}

wrapperPrompt : String -> Maybe String -> (String -> msg) -> Z msg ()
wrapperPrompt m t h =
    let
        v = concat [
            [E.string m]
            , optional E.string t
            ] |> E.list
        h2 = decodeValue D.string >> R.toMaybe >> M.map h 
    in commandThen "wrapperPrompt" v h2 

{-| Change the url and add a new entry to the browser's history.

Usage: wrapperPushState stateJSON title url

-}

wrapperPushState : Value -> String -> String -> Z msg ()
wrapperPushState st ti ur =
    let
        v = E.list [st, E.string ti, E.string ur] 
    in command "wrapperPushState" v


{-| Change the url without modifying the browser's history.

Usage: wrapperReplaceState stateJSON title url

-}

wrapperReplaceState : Value -> String -> String -> Z msg ()
wrapperReplaceState st ti ur =
    let
        v = E.list [st, E.string ti, E.string ur] 
    in command "wrapperReplaceState" v


{-| Set the browser's local data store for this site

Usage: wrapperSetLocalStorage JSONdata

-}

wrapperSetLocalStorage : Value -> Z msg ()
wrapperSetLocalStorage v = command "wrapperSetLocalStorage" v


{-| Set the title.

-}

wrapperSetTitle : String -> Z msg ()
wrapperSetTitle title = command "wrapperSetTitle" (E.string title)

{-| Set the viewport meta tag content.

-}

wrapperSetViewport : String -> Z msg ()
wrapperSetViewport s = command "wrapperSetViewport" (E.string s)


-- UI server calls

{-| Add a new certificate for the user.

Usage: certAdd domain authType authUserName cert
where cert is a signature for authAddress#authType/authUserName using the domain public key.

-}

certAdd : String -> String -> String -> String -> (Result String Value -> msg) -> Z msg ()
certAdd d at aun c h =
    let
        v = map E.string [d,at,aun,c] |> E.list
    in commandThen "certAdd" v (withResult h)

{-| Display certificate selector, passing a list of accepted domains.

-}

certSelect : List String -> Z msg ()
certSelect cs = 
  command "certSelect" (E.list <| map E.string cs)


{-| Request notifications about site's events. 

-}

channelJoin : String -> Z msg ()
channelJoin c = 
  command "channelJoin" (E.string c)

{-| Query the database by passing an SQL query.

-}
dbQuery : String -> (Result String (List Value) -> msg) -> Z msg ()
dbQuery q h = 
  let
      h2 = handleResult >> R.andThen (decodeValue <| D.list D.value) >> h >> Just
  in commandThen "dbQuery" (E.string q) h2 

{-| Delete a file, passing the inner path to the file.

-}
fileDelete : String -> (String -> msg) -> Z msg ()
fileDelete path h =
  commandThen "fileDelete" (E.string path) (withErr h) 


{-| Get contents of a file.

Usage: fileGet innerPath [required] ["base64"|"text"] [timeout]

-}

fileGet : String -> Maybe Bool -> Maybe String -> Maybe Int -> (Result String String -> msg) -> Z msg () 
fileGet ip r fmt to h =
    let
        v = concat [
            [E.string ip]
            , optional E.bool r
            , optional E.string fmt
            , optional E.int to
            ] |> E.list
        h2 = handleResult >> R.andThen (decodeValue D.string) >> h >> Just
    in commandThen "fileGet" v h2

{-| List files in a directory (recursively), passing the inner path.

-}

fileList : String -> (Result String Value -> msg) -> Z msg ()
fileList s h = 
  commandThen "fileList" (E.string s) (withResult h) 

{-| Simple JSON file query command.

Examples:

* `fileQuery "data/users/*/data.json" "topics"` returns a list containing the topics node from each matched file.
* `fileQuery "data/users/*/data.json" "comments.1@2"` returns `data["comments"]["1@2"]` from each matched file.
* `fileQuery "data/users/*/data.json" ""` returns all content for each matched file. 

-}

fileQuery : String -> String -> (Result String (List Value) -> msg) -> Z msg ()
fileQuery dip q h =
  let
      v = (E.list [E.string dip, E.string q])
      h2 = handleResult >> R.andThen (decodeValue <| D.list D.value) >> h >> Just 
  in commandThen "fileQuery" v h2

{-| Get the rules for a file, passing the inner path.

-}

fileRules : String -> (Result String Value -> msg) -> Z msg ()
fileRules path h = 
  commandThen "fileRules" (E.string path) (withResult h)

{-| Write to a file.

Usage: `fileWrite innerPath contentBase64`

-}

fileWrite : String -> String -> (String -> msg) -> Z msg ()
fileWrite ip cb64 h = 
  let
      v = E.list [E.string ip, E.string cb64]
  in commandThen "fileWrite" v (withErr h) 

{-| Request server information.

-}
serverInfo : (Result String Value -> msg) -> Z msg ()
serverInfo h = 
  commandThen "serverInfo" E.null (withResult h)

{-| Request site information.

-}
siteInfo : (Result String Value -> msg) -> Z msg ()
siteInfo h =
  commandThen "siteInfo" E.null (withResult h)

{-| Publish site.

Usage: `sitePublish [privateKey] [innerPath] [sign]` 

-}

sitePublish : Maybe String -> Maybe String -> Maybe Bool -> (String -> msg) -> Z msg () 
sitePublish pk ip s h =
    let
       v = concat [
           optional E.string pk
           , optional E.string ip
           , optional E.bool s 
           ] |> E.list
    in commandThen "sitePublish" v (withErr h)

{-| Sign a content.json file.

Usage: `siteSign [privateKey] [innerPath]`

-}

siteSign : Maybe String -> Maybe String -> (String -> msg) -> Z msg ()
siteSign pk ip h =
    let
        v = concat [
            optional E.string pk
            , optional E.string ip
            ] |> E.list
    in commandThen "siteSign" v (withErr h)

-- MERGER plugin

{-| Start downloading new merger sites.

Usage: `mergerSiteAdd ["A", "B"]

-}
mergerSiteAdd : List String -> Z msg ()
mergerSiteAdd ss = 
  command "mergerSiteAdd" (E.list <| map E.string ss)

{-| Stop seeding and delete a merged site.

Usage: `mergerSiteDelete siteAddress`

-}
mergerSiteDelete : String -> Z msg ()
mergerSiteDelete s =
  command "mergerSiteDelete" (E.string s)

{-| Request merged sites.

Usage: `mergerSiteList getDetails`

-}
mergerSiteList : Bool -> (Value -> msg) -> Z msg ()
mergerSiteList details h =
  commandThen "mergerSiteList" (E.bool details) (h >> Just)

-- HELPER functions

optional : (a -> b) -> Maybe a -> List b
optional f mx =
    case mx of
        Just x -> [f x]
        Nothing -> []

possibleErr : Value -> Maybe String
possibleErr v =
    case decodeValue (D.field "error" D.string) v of
        Ok errMsg -> Just errMsg
        Err _ -> Nothing

handleResult : Value -> Result String Value 
handleResult v =
    case decodeValue (D.field "error" D.string) v of
        Ok errMsg -> Err errMsg
        Err _ -> Ok v

withResult : (Result String Value -> msg) -> Value -> Maybe msg
withResult h = handleResult >> h >> Just

withErr : (String -> msg) -> Value -> Maybe msg
withErr h = possibleErr >> M.map h
