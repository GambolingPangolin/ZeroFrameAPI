port module ZeroFrame.Ports exposing (
  RawWrapperMessage
  , sendZeroFrameMsg
  , recvZeroFrameMsg
  ) 

{-| This module contains the two ports needed to interact with the ZeroFrame wrapper.  End-users should use 'ZeroFrame.Core.command' and 'ZeroFrame.Core.response' to interact with the wrapper.

# Ports
@docs sendZeroFrameMsg, recvZeroFrameMsg

# Message type
@docs RawWrapperMessage
-}

import Json.Encode exposing (Value)

{-| Raw messages to send out to the wrapper.
-}
type alias RawWrapperMessage =
  { id : Int
  , cmd : String
  , params : Value
  , to : Maybe Int
  , result : Value }

{-| Send a message out to the wrapper.  
-}
port sendZeroFrameMsg : RawWrapperMessage -> Cmd msg 

{-| Receive a message from the wrapper.
-}
port recvZeroFrameMsg : (Value -> msg) -> Sub msg
