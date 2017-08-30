port module ZeroFrameAPI exposing (
    ZeroFrameMsg(..)
    , wrapperConfirm
    , onWrapperConfirm
    , wrapperInnerLoaded
    , wrapperGetLocalStorage
    , onGetLocalStorage
    , wrapperGetState
    , onGetState
    , wrapperNotification
    , wrapperOpenWindow
    , wrapperPermissionAdd
    , wrapperPrompt
    , onPrompt
    , wrapperPushState
    , wrapperSetLocalStorage
    , wrapperSetTitle
    , wrapperSetViewport
    , certAdd
    , onCertAdd
    , certSelect
    , channelJoin
    , dbQuery
    , onQueryResult
    , fileDelete
    , onFileDelete
    , fileGet
    , onFileGet
    , fileList
    , onFileList
    , fileQuery
    , onFileQuery
    , fileRules
    , onFileRules
    , fileWrite
    , onFileWrite
    , serverInfo
    , onServerInfo
    , siteInfo
    , onSiteInfo
    , sitePublish
    , onSitePublish
    , siteSign
    , onSiteSign
    , mergerSiteAdd
    , mergerSiteDelete
    , mergerSiteList
    , onMergerSiteList
    )

{-| This library makes (eventually) all of the ZeroFrame API calls available to Elm so that Elm can be used to develop apps for ZeroNet. 

# Messages
@docs ZeroFrameMsg

# Wrapper calls
@docs wrapperConfirm, onWrapperConfirm, wrapperInnerLoaded, wrapperGetLocalStorage, onGetLocalStorage, wrapperSetLocalStorage, wrapperGetState, onGetState, wrapperNotification, wrapperOpenWindow, wrapperPermissionAdd, wrapperPrompt, onPrompt, wrapperPushState, wrapperSetTitle, wrapperSetViewport

# UI server calls
@docs certAdd, onCertAdd, certSelect, channelJoin, dbQuery, onQueryResult, fileDelete, onFileDelete, fileGet, onFileGet, fileList, onFileList, fileQuery, onFileQuery, fileRules, onFileRules, fileWrite, onFileWrite, serverInfo, onServerInfo, siteInfo, onSiteInfo, sitePublish, onSitePublish, siteSign, onSiteSign

# Merger plugin
@docs mergerSiteAdd, mergerSiteDelete, mergerSiteList, onMergerSiteList

-}

import Json.Encode exposing (Value)
import Json.Encode as E

import Json.Decode exposing (decodeValue)
import Json.Decode as D

import List exposing (concat,map)
import Result as R

type alias ErrMsg = String

{-| ZeroFrameMsg describes the possible messages that ZeroFrame might send -}

type ZeroFrameMsg =
    WrapperConfirmClick Bool
    | LocalStorage Value
    | HistoryState Value
    | PromptInput String
    | CertAdd (Result String String)
    | QueryResult (Result String (List Value))
    | FileDelete (Maybe ErrMsg)
    | FileContents (Result String String)
    | FileList (Result String Value)
    | FileQuery (Result String Value)
    | FileRules (Result String Value)
    | FileWrite (Maybe ErrMsg)
    | ServerInfo (Result String Value)
    | SiteInfo (Result String Value)
    | SitePublish (Maybe ErrMsg)
    | SiteSign (Maybe ErrMsg)
    | MergerSiteList Value

-- Wrapper calls

port wrapperConfirm_ : Value -> Cmd msg
port onWrapperConfirm_ : (Bool -> msg) -> Sub msg

{-| Use wrapperConfirm to post a confirmation message to the user.

    wrapperConfirm "Go for it?" (Just "Go!")

-}
wrapperConfirm : String -> Maybe String -> Cmd msg
wrapperConfirm message caption =
    let
        v = concat [
            [E.string message]
            , optional E.string caption
            ] |> E.list
    in
       wrapperConfirm_ v

{-| Use onWrapperConfirm to listen for confirmation messages 

-}
onWrapperConfirm : Sub ZeroFrameMsg
onWrapperConfirm = onWrapperConfirm_ WrapperConfirmClick

{-| Applies window.location.hash to page url.  Call when the page is fully loaded to jump to the desired anchor point.

-}

port wrapperInnerLoaded : () -> Cmd msg 

{-| Request the contents of the browser's local storage for the site.

-}

port wrapperGetLocalStorage : () -> Cmd msg
port onGetLocalStorage_ : (Value -> msg) -> Sub msg

{-| Listen for the browser's local storage for the site.

-}

onGetLocalStorage : Sub ZeroFrameMsg
onGetLocalStorage = onGetLocalStorage_ LocalStorage

{-| Request the browser's current history state object.

-}

port wrapperGetState : () -> Cmd msg
port onGetState_ : (Value -> msg) -> Sub msg

{-| Subscription for the browser's current history state.

-}
onGetState : Sub ZeroFrameMsg
onGetState = onGetState_ HistoryState

port wrapperNotification_ : Value -> Cmd msg

{-| Display a notification.

Usage: wrapperNotification ("info"|"error"|"done") message [timeout]

-}

wrapperNotification : String -> String -> Maybe Int -> Cmd msg
wrapperNotification t message to =
    let
        v = concat [
            [E.string t, E.string message]
            , optional E.int to
            ] |> E.list
    in
       wrapperNotification_ v

port wrapperOpenWindow_ : Value -> Cmd msg

{-| Navigates or opens a new popup.

Usage: wrapperOpenWindow url [target] [specs]

-}

wrapperOpenWindow : String -> Maybe String -> Maybe String -> Cmd msg
wrapperOpenWindow u t s =
    let
       v = concat [
           [E.string u]
           , optional E.string t
           , optional E.string s
           ] |> E.list
    in
       wrapperOpenWindow_ v

{-| Request a permission.

-}
port wrapperPermissionAdd : String -> Cmd msg

port wrapperPrompt_ : Value -> Cmd msg
port onPrompt_ : (String -> msg) -> Sub msg

{-| Prompt for input.

Usage: wrapperPrompt promptMessage ("text"|"password"|etc.)

The default type is "text".

-}

wrapperPrompt : String -> Maybe String -> Cmd msg
wrapperPrompt m t =
    let
        v = concat [
            [E.string m]
            , optional E.string t
            ] |> E.list
    in
       wrapperPrompt_ v

{-| Subscribe to the user input from prompts.

-}
onPrompt : Sub ZeroFrameMsg
onPrompt = onPrompt_ PromptInput

port wrapperPushState_ : Value -> Cmd msg

{-| Change the url and add a new entry to the browser's history.

Usage: wrapperPushState stateJSON title url

-}

wrapperPushState : Value -> String -> String -> Cmd msg
wrapperPushState st ti ur =
    let
        v = E.list [st, E.string ti, E.string ur] 
    in
       wrapperPushState_ v


port wrapperReplaceState_ : Value -> Cmd msg

{-| Change the url without modifying the browser's history.

Usage: wrapperReplaceState stateJSON title url

-}

wrapperReplaceState : Value -> String -> String -> Cmd msg
wrapperReplaceState st ti ur =
    let
        v = E.list [st, E.string ti, E.string ur] 
    in
       wrapperReplaceState_ v


{-| Set the browser's local data store for this site

Usage: wrapperSetLocalStorage JSONdata

-}

port wrapperSetLocalStorage : Value -> Cmd msg

{-| Set the title.

-}

port wrapperSetTitle : String -> Cmd msg

{-| Set the viewport meta tag content.

-}

port wrapperSetViewport : String -> Cmd msg


-- UI server calls

-- Add a new certificate for the user
-- cert should be a signature for auth_address#auth_type/auth_user_name
-- uiCertAdd domain auth_type auth_user_name cert
port certAdd_ : Value -> Cmd msg
port onCertAdd_ : (Value -> msg) -> Sub msg

{-| Add a new certificate for the user.

Usage: certAdd domain authType authUserName cert
where cert is a signature for authAddress#authType/authUserName using the domain public key.

-}

certAdd : String -> String -> String -> String -> Cmd msg
certAdd d at aun c =
    let
        v = map E.string [d,at,aun,c] |> E.list
    in
       certAdd_ v

{-| Subscribe to responses to certAdd.

-}

onCertAdd : Sub ZeroFrameMsg
onCertAdd = onCertAdd_ (
    handleResult >> 
    R.andThen (decodeValue D.string) >> 
    CertAdd
    )

{-| Display certificate selector, passing a list of accepted domains.

-}

port certSelect : List String -> Cmd msg

{-| Request notifications about site's events. 

-}

port channelJoin : String -> Cmd msg

{-| Query the database by passing an SQL query.

-}
port dbQuery : String -> Cmd msg
port onQueryResult_ : (Value -> msg) -> Sub msg

{-| Subscribe to query results.

-}

onQueryResult : Sub ZeroFrameMsg
onQueryResult = onQueryResult_ (
           handleResult >>
           R.andThen (decodeValue (D.list D.value)) >> 
           QueryResult
           )
{-| Delete a file, passing the inner path to the file.

-}
port fileDelete : String -> Cmd msg
port onFileDelete_ : (Value -> msg) -> Sub msg

{-| Subscribe to responses to fileDelete calls.

-}
onFileDelete : Sub ZeroFrameMsg
onFileDelete = onFileDelete_ (possibleErr >> FileDelete)

port fileGet_ : Value -> Cmd msg
port onFileGet_ : (Value -> msg) -> Sub msg

{-| Get contents of a file.

Usage: fileGet innerPath [required] ["base64"|"text"] [timeout]

-}

fileGet : String -> Maybe Bool -> Maybe String -> Maybe Int -> Cmd msg
fileGet ip r fmt to =
    let
        v = concat [
            [E.string ip]
            , optional E.bool r
            , optional E.string fmt
            , optional E.int to
            ] |> E.list
    in
       fileGet_ v

{-| Subscribe to responses to fileGet calls.

-}
onFileGet : Sub ZeroFrameMsg
onFileGet = onFileGet_ (
    handleResult >> 
    R.andThen (decodeValue D.string) 
    >> FileContents
    )

{-| List files in a directory (recursively), passing the inner path.

-}

port fileList : String -> Cmd msg
port onFileList_ : (Value -> msg) -> Sub msg

{-| Subscribe to responses to fileList calls.

-}
onFileList : Sub ZeroFrameMsg
onFileList = onFileList_ (handleResult >> FileList)

-- Simple JSON file query command
-- fileQuery dir_inner_path query
port fileQuery_ : Value -> Cmd msg
port onFileQuery_ : (Value -> msg) -> Sub msg

{-| Simple JSON file query command.

Examples:

* `fileQuery "data/users/*/data.json" "topics"` returns a list containing the topics node from each matched file.
* `fileQuery "data/users/*/data.json" "comments.1@2"` returns `data["comments"]["1@2"]` from each matched file.
* `fileQuery "data/users/*/data.json" ""` returns all content for each matched file. 

-}

fileQuery : String -> String -> Cmd msg
fileQuery dip q = fileQuery_ (E.list [E.string dip, E.string q])

{-| Subscribe to responses of fileQuery calls.

-}

onFileQuery : Sub ZeroFrameMsg
onFileQuery = onFileQuery_ (handleResult >> FileQuery)

{-| Get the rules for a file, passing the inner path.

-}

port fileRules : String -> Cmd msg
port onFileRules_ : (Value -> msg) -> Sub msg

{-| Subscribe to responses to fileRules calls.

-}

onFileRules : Sub ZeroFrameMsg
onFileRules = onFileRules_ (handleResult >> FileRules)

port fileWrite_ : Value -> Cmd msg
port onFileWrite_ : (Value -> msg) -> Sub msg

{-| Write to a file.

Usage: `fileWrite innerPath contentBase64`

-}

fileWrite : String -> String -> Cmd msg
fileWrite ip cb64 = fileWrite_ (E.list [E.string ip, E.string cb64])

{-| Subscribe to responses to fileWrite messages.

-}

onFileWrite : Sub ZeroFrameMsg
onFileWrite = onFileWrite_ (possibleErr >> FileWrite)

{-| Request server information.

-}

port serverInfo : () -> Cmd msg
port onServerInfo_ : (Value -> msg) -> Sub msg

{-| Subscribe to responses to serverInfo calls.

-}
onServerInfo : Sub ZeroFrameMsg
onServerInfo = onServerInfo_ (handleResult >> ServerInfo)

{-| Request site information.

-}

port siteInfo : () -> Cmd msg
port onSiteInfo_ : (Value -> msg) -> Sub msg

{-| Subscribe to responses to siteInfo calls.

-}

onSiteInfo : Sub ZeroFrameMsg
onSiteInfo = onSiteInfo_ (handleResult >> SiteInfo)

port sitePublish_ : Value -> Cmd msg
port onSitePublish_ : (Value -> msg) -> Sub msg

{-| Publish site.

Usage: `sitePublish [privateKey] [innerPath] [sign]` 

-}

sitePublish : Maybe String -> Maybe String -> Maybe Bool -> Cmd msg
sitePublish pk ip s =
    let
       v = concat [
           optional E.string pk
           , optional E.string ip
           , optional E.bool s 
           ] |> E.list
    in
       sitePublish_ v

{-| Subscribe to responses to sitePublish calls.

-}

onSitePublish : Sub ZeroFrameMsg
onSitePublish = onSitePublish_ (possibleErr >> SitePublish)

port siteSign_ : Value -> Cmd msg
port onSiteSign_ : (Value -> msg) -> Sub msg

{-| Sign a content.json file.

Usage: `siteSign [privateKey] [innerPath]`

-}

siteSign : Maybe String -> Maybe String -> Cmd msg
siteSign pk ip =
    let
        v = concat [
            optional E.string pk
            , optional E.string ip
            ] |> E.list
    in
       siteSign_ v

{-| Subscribe to responses to siteSign calls.

-}

onSiteSign : Sub ZeroFrameMsg
onSiteSign = onSiteSign_ (possibleErr >> SiteSign)

-- MERGER plugin

{-| Start downloading new merger sites.

Usage: `mergerSiteAdd ["A", "B"]

-}
port mergerSiteAdd : List String -> Cmd msg

{-| Stop seeding and delete a merged site.

Usage: `mergerSiteDelete siteAddress`

-}
port mergerSiteDelete : String -> Cmd msg

{-| Request merged sites.

Usage: `mergerSiteList getDetails`

-}
port mergerSiteList : Bool -> Cmd msg
port onMergerSiteList_ : (Value -> msg) -> Sub msg

{-| Subscription for responses to mergerSiteList.

-}

onMergerSiteList : Sub ZeroFrameMsg
onMergerSiteList = onMergerSiteList_ MergerSiteList

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
