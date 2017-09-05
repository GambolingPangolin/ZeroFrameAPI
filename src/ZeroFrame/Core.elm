module ZeroFrame.Core exposing (
  -- Model wrapper 
  Z 
  , wrap
  , andThen
  , fmap
  
  -- Message wrapper and system messages
  , M
  , WrapperMessage (..)

  -- Lifters
  , liftInit
  , liftSubscription
  , liftUpdate, 
  , liftView, 

  -- Utilities
  , command
  , commandThen
  , response
  , sequence
  , include
  , forward
	)

{-| We have collected the logic for passing message up to the ZeroFrame wrapper in this model.  

# Model wrapper
@docs Z, wrap, andThen, fmap

# Messages
@docs M, WrapperMessage

# Utilities
@docs command, response, include
-}

import Cmd as C
import List as L
import Tuple as T
import JSON.Encode exposing (Value)

-- Compact representations of system messages.
type RawMsg =
  C String Value
  | R Int Value 

{-| Wrapper for a model.
-}
type Z a b =
  Z
    Int -- An available id
    List (Either (Cmd a) (Int, RawMsg)) -- Domain commands or outgoing messages
    List (Int, Value -> Maybe a) -- Response handlers 
    b -- Model

{-| Wrap a model in a fresh context.
-}
wrap : b -> Z a b
wrap m = Z 0 [] [] m 

{-| Sequence wrapped model computations.
-}
andThen : (a -> Z m b) -> Z m a -> Z m b
andThen f (Z i c d m) = case f m of
  Z j c' d' m' -> 
    let
      d'' = d ++ L.map (T.mapFirst (+i)) d'
      c'' = L.map f c' ++ c
      f (Left x) = Left x
      f (Right (k, v)) = Right (k+i,v)
    in Z (i+j) c'' d'' m'

{-| Sequence computations ignoring the result of the first computation. 
-}
butThen : Z m a -> Z m b -> Z m b
butThen za zb = za |> andThen (always zb)

carryThrough : Z m a -> Z m b -> Z m a 
carryThrough za zb = za |> andThen (\x -> zb |> butThen (wrap x))

{-| Modify the value in a ZeroNet context.
-}
fmap : (a -> b) -> Z m a -> Z m b
fmap f (Z i c d m) = Z i c d (f m) 

{-| Sequence a list of ZeroFrame actions into a list-valued ZeroFrame action.
-}
sequence : List (Z a b) -> Z a (List b)
sequence [] = wrap []
sequence (z::zs) = fmap (:) z |> andThen \cz -> fmap cz (sequenceM zs) 

--
-- Architecture lifting functions
--

{-| Lift a domain update function to a ZeroNet-Elm update.
    
    update = liftUpdate update'
-}
liftUpdate : (model -> Either WrapperMessage msg -> Z msg model) -> 
  Z msg model -> 
  M msg -> 
  (Z msg model, Cmd (M msg))
liftUpdate u zm mm = 
  let
    insertMessage x = zm |> andThen (flip u x) |> flush
    skip = (zm, C.none)
  in case mm of
    Forward m -> insertMessage (Right m) 
    Response _ t v -> zm |> responseMessage t v |> andThen (M.map (insertMessage . Right) >> M.withDefault skip)
    Command i c -> case c of
      "ping" -> carryThrough zm (respond i <| E.string "pong") |> flush 
      "wrapperReady" -> insertMessage (Left WrapperReady) 
      "wrapperOpenedWebsocket" -> insertMessage (Left WrapperOpenedWebsocket)
      "wrapperClosedWebsocket" -> insertMessage (Left WrapperClosedWebsocket)
      _ -> skip

-- Lookup the domain message associated to the response.
responseMessage : Int -> Value -> Z msg model -> Z msg (Maybe msg)
responseMessage t res (Z i c d _) = 
  let
    rc [] ys = ys
    rc (x:xs) ys = rc xs (x:ys)
    f xs [] = Z i c d Nothing
    f xs (y:ys) = if first y == t 
      then Z i c (rc xs ys) (second y res) 
      else f (y:xs) ys 
  in f [] d 
 
{-| Lift a domain model to a ZeroNet-Elm model.

    init = liftInit init'
-}
liftInit : model -> Z msg model
liftInit = wrap

{-| Lift a domain subscription function to a ZeroNet-Elm subscription.

    subscriptions = liftSubscriptions subscriptions'

-}
liftSubscriptions : (model -> Sub msg) -> Z msg model -> Sub (M msg)
liftSubscriptions f (Z _ _ _ m) = S.batch [sysMessages, Sub.map Forward (f m)]

{-| Lift a domain view to a ZeroNet-Elm view.

    view = liftView view'

-}
liftView : (model -> Html msg) -> Z msg model -> Html (M msg)
liftView v (Z _ _ _ m) = Html.map Forward (v m)

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

{-| Promote a domain message to a system message. 
-}
forward : a -> M a
forward = Forward

{-| Send a response message.

    respond 7 (E.string "success")
-}
respond : Int -> Value -> Z a b
respond t v = Z 1 [Right (0, R t v)] [] ()

{-| Send a command message with no response handler.
    
    command "wrapperInnerLoaded" E.null
-}
command : String -> Value -> Z a ()
command s v = command' s v Nothing

{-| Send a command message with a handler.

    commandThen "wrapperGetState" E.null handleState
-}
commandThen : String -> Value -> (Value -> Maybe a) -> Z a ()
commandThen s v h = command' s v (Just h)

command' : String -> Value -> Maybe (Value -> Maybe a) -> Z a () 
command' c v h = 
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
    f (Left c) = C.map Forward c
    f (Right (i, x)) = case x of
      C s p -> sendZeroFrameMsg { id = i, cmd = s, params = p, to = Nothing, result = E.null }
      R t v -> sendZeroFrameMsg { id = i, cmd = "response", params = E.null, to = t, result = v }
  in (Z i [] d m, C.batch (map f <| L.reverse cs))
