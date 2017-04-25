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
    )

import Json.Encode exposing (Value)
import Json.Encode as E

import Json.Decode exposing (decodeValue)
import Json.Decode as D

import List exposing (concat,map)
import Result as R

type alias ErrMsg = String

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

-- Wrapper calls

-- wrapperConfirm message button_caption
port wrapperConfirm_ : Value -> Cmd msg
port onWrapperConfirm_ : (Bool -> msg) -> Sub msg

wrapperConfirm : String -> Maybe String -> Cmd msg
wrapperConfirm message caption =
    let
        v = concat [
            [E.string message]
            , optional E.string caption
            ] |> E.list
    in
       wrapperConfirm_ v

onWrapperConfirm : Sub ZeroFrameMsg
onWrapperConfirm = onWrapperConfirm_ WrapperConfirmClick

-- Applies window.location.hash to page url.  Call when the page is fully 
-- loaded to jump to the desired anchor point
port wrapperInnerLoaded : () -> Cmd msg 

-- Return the browser's local store for the site
port wrapperGetLocalStorage : () -> Cmd msg
port onGetLocalStorage_ : (Value -> msg) -> Sub msg

onGetLocalStorage : Sub ZeroFrameMsg
onGetLocalStorage = onGetLocalStorage_ LocalStorage

-- Get the browser's current history state object
port wrapperGetState : () -> Cmd msg
port onGetState_ : (Value -> msg) -> Sub msg

onGetState : Sub ZeroFrameMsg
onGetState = onGetState_ HistoryState

-- Display a notification
-- wrapperNotification (info|error|done) message [timeout]
port wrapperNotification_ : Value -> Cmd msg

wrapperNotification : String -> String -> Maybe Int -> Cmd msg
wrapperNotification t message to =
    let
        v = concat [
            [E.string t, E.string message]
            , optional E.int to
            ] |> E.list
    in
       wrapperNotification_ v

-- Navigates or opens a new popup
-- wrapperOpenWindow _url [target] [specs]
port wrapperOpenWindow_ : Value -> Cmd msg

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

-- Request a permission
port wrapperPermissionAdd : String -> Cmd msg

-- Prompt for text input
port wrapperPrompt_ : Value -> Cmd msg
port onPrompt_ : (String -> msg) -> Sub msg

wrapperPrompt : String -> Maybe String -> Cmd msg
wrapperPrompt m t =
    let
        v = concat [
            [E.string m]
            , optional E.string t
            ] |> E.list
    in
       wrapperPrompt_ v

onPrompt : Sub ZeroFrameMsg
onPrompt = onPrompt_ PromptInput

-- Change the url and add new entry to browser's history
-- wrapperPushState stateJSON title url
port wrapperPushState_ : Value -> Cmd msg

wrapperPushState : Value -> String -> String -> Cmd msg
wrapperPushState st ti ur =
    let
        v = E.list [st, E.string ti, E.string ur] 
    in
       wrapperPushState_ v


-- Change the url without adding a history entry
-- wrapperReplaceState stateJSON title url
port wrapperReplaceState_ : Value -> Cmd msg

wrapperReplateState st ti ur =
    let
        v = E.list [st, E.string ti, E.string ur] 
    in
       wrapperReplaceState_ v


-- Set the browser's local data store for this site
-- wrapperSetLocalStorage stringJSON
port wrapperSetLocalStorage : Value -> Cmd msg

-- Set the title
port wrapperSetTitle : String -> Cmd msg

-- Set the viewport meta tag content
port wrapperSetViewport : String -> Cmd msg


-- UI server calls

-- Add a new certificate for the user
-- cert should be a signature for auth_address#auth_type/auth_user_name
-- uiCertAdd domain auth_type auth_user_name cert
port certAdd_ : Value -> Cmd msg
port onCertAdd_ : (Value -> msg) -> Sub msg

certAdd : String -> String -> String -> String -> Cmd msg
certAdd d at aun c =
    let
        v = map E.string [d,at,aun,c] |> E.list
    in
       certAdd_ v

onCertAdd : Sub ZeroFrameMsg
onCertAdd = onCertAdd_ (
    handleResult >> 
    R.andThen (decodeValue D.string) >> 
    CertAdd
    )

-- Display certificate selector
-- uiCertSelect accepted_domains
port certSelect : List String -> Cmd msg

-- Request notifications about site's events
-- uiChannelJoin channel
port channelJoin : String -> Cmd msg

-- Query the database
-- dbQuery sqlQuery
port dbQuery : String -> Cmd msg
port onQueryResult_ : (Value -> msg) -> Sub msg

onQueryResult : Sub ZeroFrameMsg
onQueryResult = onQueryResult_ (
           handleResult >>
           R.andThen (decodeValue (D.list D.value)) >> 
           QueryResult
           )

-- Delete a file
-- fileDelete inner_path
port fileDelete : String -> Cmd msg
port onFileDelete_ : (Value -> msg) -> Sub msg

onFileDelete : Sub ZeroFrameMsg
onFileDelete = onFileDelete_ (possibleErr >> FileDelete)

-- Get contents of a file
-- fileGet inner_path [required] [base64|text] [timeout]
port fileGet_ : Value -> Cmd msg
port onFileGet_ : (Value -> msg) -> Sub msg

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

onFileGet = onFileGet_ (
    handleResult >> 
    R.andThen (decodeValue D.string) 
    >> FileContents
    )

-- List files in a directory
-- fileList inner_path
port fileList : String -> Cmd msg
port onFileList_ : (Value -> msg) -> Sub msg

onFileList = onFileList_

-- Simple JSON file query command
-- fileQuery dir_inner_path query
port fileQuery_ : Value -> Cmd msg
port onFileQuery_ : (Value -> msg) -> Sub msg

fileQuery : String -> String -> Cmd msg
fileQuery dip q = fileQuery_ (E.list [E.string dip, E.string q])

onFileQuery : Sub ZeroFrameMsg
onFileQuery = onFileQuery_ (handleResult >> FileQuery)

-- Get the rules for a file
-- fileRules inner_path
port fileRules : String -> Cmd msg
port onFileRules_ : (Value -> msg) -> Sub msg

onFileRules = onFileRules_ (handleResult >> FileRules)

port fileWrite_ : Value -> Cmd msg
port onFileWrite_ : (Value -> msg) -> Sub msg

-- Write to a file
-- fileWrite inner_path content_base64
fileWrite : String -> String -> Cmd msg
fileWrite ip cb64 = fileWrite_ (E.list [E.string ip, E.string cb64])

onFileWrite : Sub ZeroFrameMsg
onFileWrite = onFileWrite_ (possibleErr >> FileWrite)

-- Get server information
port serverInfo : () -> Cmd msg
port onServerInfo_ : (Value -> msg) -> Sub msg

onServerInfo = onServerInfo_

-- Get site information
port siteInfo : () -> Cmd msg
port onSiteInfo_ : (Value -> msg) -> Sub msg

onSiteInfo = onSiteInfo_

-- Publish site
-- sitePublish [privateKey] [inner_path] [sign]
port sitePublish_ : Value -> Cmd msg
port onSitePublish_ : (Value -> msg) -> Sub msg

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

onSitePublish : Sub ZeroFrameMsg
onSitePublish = onSitePublish_ (possibleErr >> SitePublish)

-- Sign site
-- siteSign [privateKey] [inner_path]
port siteSign_ : Value -> Cmd msg
port onSiteSign_ : (Value -> msg) -> Sub msg

siteSign : Maybe String -> Maybe String -> Cmd msg
siteSign pk ip =
    let
        v = concat [
            optional E.string pk
            , optional E.string ip
            ] |> E.list
    in
       siteSign_ v

onSiteSign : Sub ZeroFrameMsg
onSiteSign = onSiteSign_ (possibleErr >> SiteSign)

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
