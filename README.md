# ZeroFrameAPI

## v2.2.0

I totally rewrote the project to do everything in Elm except send and recieve raw wrapper messages.  The package should be considered 'alpha' software, and has not been thoroughly tested.

This package provides two central types `M msg` and `Z msg model` which wrap the domain-specific message and model types, respectively, written by end users.  To write a ZeroNet app using this package, the users write the following functions:

* `initZ : (model, Cmd msg)`
* `subscriptionsZ : model -> Sub msg`
* `updateZ : Either WrapperMessage msg -> model -> Z msg model`
* `viewZ : model -> Html msg`

The main module can always have the default implementation:

```elm
import ZeroFrame.Core exposing (liftInit, liftSubscriptions, liftUpdate, liftView)
import App exposing (initZ, subscriptionsZ, updateZ, viewZ)

main = Html.program
	{ init = liftInit initZ
	, subscriptions = liftSubscriptions subscriptionsZ
	, update = liftUpdate updateZ
	, view = liftView viewZ }
```

The only function above with an unfamiliar type is `updateZ`.  Values of type `Z msg model` can be produced in three ways.  First, `wrap : model -> Z msg model` promotes a value of type `model` to type `Z msg model`.  Second, ZeroFrame API calls produce values of type `Z msg model`.  Finally, commands can be promoted to `Z msg ()` values using `ZeroFrame.Core.include`

```elm
-- Example --
-------------

-- A simple domain message
type Msg = DataResult (Result String String)

-- Compute a file-request action by passing a message constructor in with the parameters
dataFile = fileGet "data.json" Nothing Nothing Nothing DataResult : Z Msg ()

-- Modify the return type by persisting a model through the computation
model : Model

model |> carryThrough dataFile : Z Msg Model
```

Behind the scenes, the type `Z msg model` is deconstructed by `liftUpdate` so that responses to API calls are passed into `updateZ` wrapped in the appropriate message constructor.
