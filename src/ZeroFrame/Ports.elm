port module ZeroFrame.Ports exposing (
  RawWrapperMessage
	, sendZeroFrameMsg
	, recvZeroFrameMsg
	) 

type alias RawWrapperMessage =
  { id : Int
  , cmd : String
  , params : Value
  , to : Maybe Int
  , result : Value }

port sendZeroFrameMsg : RawWrapperMessage -> Cmd msg 
port recvZeroFrameMsg : (RawWrapperMessage -> msg) -> Sub msg
