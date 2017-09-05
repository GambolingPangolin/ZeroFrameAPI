module ZeroFrame.Core exposing (
  -- Model wrapper 
  Z 
  , wrap
  , andThen
  , fmap
  , sequence
  
  -- Message wrapper and system messages
  , M
  , WrapperMessage (..)

  -- Lifters
  , liftInit
  , liftSubscriptions
  , liftUpdate 
  , liftView

  -- Utilities
  , command
  , commandThen
  , response
  , include
  , forward
  )

{-| We have collected the logic for passing message up to the ZeroFrame wrapper in this model.  

# Model wrapper
@docs Z, wrap, andThen, fmap, sequence

# Messages
@docs M, WrapperMessage

# Lifting
@docs liftInit, liftSubscriptions, liftUpdate, liftView

# Utilities
@docs command, commandThen, response, include, forward
-}

import Platform.Cmd as C
import List as L
import Tuple as T
import Tuple exposing (first, second)
import Json.Encode exposing (Value)
import Json.Encode as E
import Json.Decode as D
import Either exposing (Either(..))
import Either as Ei
import Html exposing (Html)
import Maybe as M
import Platform.Sub as S
import ZeroFrame.Ports exposing (sendZeroFrameMsg, recvZeroFrameMsg)


-- Compact representations of system messages.
type RawMsg =
  C String Value
  | R Int Value 

{-| Wrapper for a model.
-}
type Z a b =
  Z
    Int -- An available id
    (List (Either (Cmd a) (Int, RawMsg))) -- Domain commands or outgoing messages
    (List (Int, Value -> Maybe a)) -- Response handlers 
    b -- Model

model : Z a b -> b
model (Z _ _ _ m) = m

{-| Wrap a model in a fresh context.
-}
wrap : b -> Z a b
wrap m = Z 0 [] [] m 

{-| Sequence wrapped model computations.
-}
andThen : (a -> Z m b) -> Z m a -> Z m b
andThen f (Z i c1 d1 m1) = case f m1 of
  Z j c2 d2 m2 -> 
    let
      g = Ei.map (\(k,v) -> (k+i,v))
      d3 = d1 ++ L.map (T.mapFirst (\k -> k+i)) d2
      c3 = L.map g c2 ++ c1
    in Z (i+j) c3 d3 m2

{-| Persist the result of a computation after a subsequent computation
    
    x |> carryThrough y
-}
carryThrough : Z m b -> Z m a -> Z m a 
carryThrough zb za = za |> andThen (\x -> zb |> andThen (wrap x |> always)) 

{-| Modify the value in a ZeroNet context.
-}
fmap : (a -> b) -> Z m a -> Z m b
fmap f (Z i c d m) = Z i c d (f m) 

{-| Sequence a list of ZeroFrame actions into a list-valued ZeroFrame action.
-}
sequence : List (Z a b) -> Z a (List b)
sequence xs = case xs of
  [] -> wrap []
  (z::zs) -> fmap (::) z |> andThen (\cz -> fmap cz (sequence zs))

--
-- Architecture lifting functions
--

{-| Lift a domain update function to a ZeroNet-Elm update.
    
    update = liftUpdate innerUpdate
-}
liftUpdate : (model -> Either WrapperMessage msg -> Z msg model) -> 
  Z msg model -> 
  M msg -> 
  (Z msg model, Cmd (M msg))
liftUpdate u zm mm = 
  let
    insertMessage x z  = z |> andThen (flip u x) 
    handleMsg (model, res) = case res of
      Just msg -> u model (Right msg)
      Nothing -> wrap model 
    z2 = case mm of
      Forward m -> insertMessage (Right m) zm
      Response _ t v -> 
        responseMessage t v zm |> andThen handleMsg
      Command i c -> case c of
        "ping" -> zm |> carryThrough (response i <| E.string "pong")
        "wrapperReady" -> insertMessage (Left WrapperReady) zm
        "wrapperOpenedWebsocket" -> insertMessage (Left WrapperOpenedWebsocket) zm
        "wrapperClosedWebsocket" -> insertMessage (Left WrapperClosedWebsocket) zm
        _ -> zm
      MErr -> zm
  in flush z2

-- Lookup the domain message associated to the response.
responseMessage : Int -> Value -> Z msg model -> Z msg (model, Maybe msg)
responseMessage t res (Z i c d m) = 
  let
    rc xs ys = case xs of
      [] -> ys
      (w::ws) -> rc ws (w::ys)
    f xs ws = case ws of
      [] -> Z i c d (m, Nothing)
      (y::ys) -> if first y == t 
          then Z i c (rc xs ys) (m, second y res) 
          else f (y::xs) ys 
  in f [] d 
 
{-| Lift a domain model to a ZeroNet-Elm model.

    init = liftInit innerInit
-}
liftInit : (model, Cmd msg) -> (Z msg model, Cmd (M msg))
liftInit (model, c) = (wrap model, C.map Forward c)

{-| Lift a domain subscription function to a ZeroNet-Elm subscription.

    subscriptions = liftSubscriptions innerSubscriptions

-}
liftSubscriptions : (model -> Sub msg) -> Z msg model -> Sub (M msg)
liftSubscriptions f z = S.batch [sysMessages, Sub.map Forward (z |> model |> f)]

{-| Lift a domain view to a ZeroNet-Elm view.

    view = liftView innerView

-}
liftView : (model -> Html msg) -> Z msg model -> Html (M msg)
liftView v z = Html.map Forward (z |> model |> v)

{-| Messages from the wrapper
-}
type WrapperMessage =
  WrapperReady
  | WrapperOpenedWebsocket
  | WrapperClosedWebsocket

{-| Message wrapper 
-}
type M a =
  Forward a
  -- Cmd id cmdString
  | Command Int String
  -- Response id to result
  | Response Int Int Value
  | MErr

unpackRawMsg : Value -> M a
unpackRawMsg v = 
  let
      rsp = D.map3 Response (D.field "id" D.int) (D.field "to" D.int) (D.field "result" D.value)
      route c = case c of
        "response" -> rsp
        _ -> D.field "id" D.int |> D.map (flip Command c)
  in case D.decodeValue (D.field "cmd" D.string |> D.andThen route) v of
      Ok m -> m
      Err _ -> MErr

sysMessages : Sub (M a)
sysMessages = recvZeroFrameMsg unpackRawMsg 

-- 
-- Utilities
--

{-| Promote a domain message to a system message. 
-}
forward : a -> M a
forward = Forward

{-| Send a response message.

    respond 7 (E.string "success")
-}
response : Int -> Value -> Z a ()
response t v = Z 1 [Right (0, R t v)] [] ()

{-| Send a command message with no response handler.
    
    command "wrapperInnerLoaded" E.null
-}
command : String -> Value -> Z a ()
command s v = command_ s v Nothing

{-| Send a command message with a handler.

    commandThen "wrapperGetState" E.null handleState
-}
commandThen : String -> Value -> (Value -> Maybe a) -> Z a ()
commandThen s v h = command_ s v (Just h)

command_ : String -> Value -> Maybe (Value -> Maybe a) -> Z a () 
command_ c v h = 
  let
    d = case h of
      Just handler -> [(0, handler)] 
      Nothing -> []  
  in Z 1 [Right (0, C c v)] d ()


{-| Schedule a command.
-}
include : Cmd a -> Z a ()
include c = Z 0 [Left c] [] () 

{-| Bring the accumulated commands out of context.
-}
flush : Z a b -> (Z a b, Cmd (M a))
flush (Z i cs d m) =  
  let
    f z = case z of
      Left c -> C.map Forward c
      Right (i, x) -> case x of
        C s p -> sendZeroFrameMsg { id = i, cmd = s, params = p, to = Nothing, result = E.null }
        R t v -> sendZeroFrameMsg { id = i, cmd = "response", params = E.null, to = Just t, result = v }
  in (Z i [] d m, C.batch (L.map f <| L.reverse cs))
