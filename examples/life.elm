import Html exposing (Html, div, text, node, span, button)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Dict exposing (Dict)
import Time exposing (Time, second)




main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }



-- MODEL

type alias Pair = (Int, Int)
type alias Board = Dict Pair Bool


type alias Model = {
  board : Board,
  paused : Bool
}

boardSize = 20

model : Model
model =
  { board = Dict.empty
  , paused = True
  }


init : (Model, Cmd Msg)
init =
  (model, Cmd.none)





-- UPDATE


type Msg
  = TogglePause
  | Tick Time
  | ToggleCell Pair


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ToggleCell pair ->
      ({ model | board = toggleCell model.board pair }, Cmd.none)
    TogglePause ->
      ({ model | paused = not model.paused }, Cmd.none)
    Tick newTime ->
      (model, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions model =
  Time.every second Tick

toggleCell : Board -> Pair -> Board
toggleCell board pair =
  let
    cur = boardHas board pair
  in
    Dict.insert pair (not cur) board


nums : Int -> List Int
nums int =
  if int == 0 then
    [0]
  else
    List.append (nums (int - 1)) [int]

boardHas : Board -> Pair -> Bool
boardHas board pair =
  Maybe.withDefault False (Dict.get pair board)

-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ button [ onClick TogglePause ] [ text "toggle pause" ]
    , div [] [ text (toString model.paused) ]
    , drawBoard model.board
    ]


drawBoard board =
  div [class "board"] (List.map (drawRow board) (nums boardSize))

drawRow board i =
  div [class "row"] (List.map (drawCell board i) (nums boardSize))

drawCell board i j =
  let
    str = if boardHas board (i, j) then "X" else "O"
  in
    span [class "cell", onClick (ToggleCell (i, j))] [text str]
