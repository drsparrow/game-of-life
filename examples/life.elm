import Html exposing (Html, div, text, node, span, button, input)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onMouseOver, onMouseOut)
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
type alias BoardRowIndexes = List Pair
type alias BoardIndexes = List BoardRowIndexes

type alias Model = {
  board : Board,
  paused : Bool,
  fullBoard : BoardRowIndexes,
  interval : Float,
  lastUpdate : Float,
  tempBoard : Board
}

boardSize = 40
noCmd = Cmd.none

libraryList =
  [ ("blinker", pairsToDict [(2,1), (2,2), (2,3)])
  , ("glider",  pairsToDict [(3,1), (3,2), (3, 3), (2, 3), (1, 2)])
  , ("llws",  pairsToDict [(1,1), (4,1), (5,2), (5,3), (5,4), (4,4), (3,4), (2,4), (1,3)])
  ]

library =
  Dict.fromList libraryList

pairsToDict : List Pair -> Board
pairsToDict list =
  Dict.fromList (List.map (\p -> (p, True)) list)

model : Model
model =
  { board = Dict.empty
  , paused = True
  , fullBoard = List.concat fullBoard
  , interval = second
  , lastUpdate = 0
  , tempBoard = Dict.empty
  }


init : (Model, Cmd Msg)
init =
  (model, noCmd)


fullBoard : BoardIndexes
fullBoard =
  buildBoard (boardSize - 1)
--
--
buildBoard : Int -> BoardIndexes
buildBoard cur =
  let
    miniBoard = [fullRow (boardSize - 1) cur]
  in
    if cur == 0 then miniBoard else List.append (buildBoard (cur - 1)) miniBoard

fullRow : Int -> Int -> BoardRowIndexes
fullRow i j =
  let
    pair = [(i, j)]
  in
    if i == 0 then pair else List.append (fullRow (i-1) j) pair



-- UPDATE


type Msg
  = TogglePause
  | Tick Time
  | ToggleCell Pair
  | UpdateInterval String
  | ClearBoard
  | SetBoard String
  | SetTempBoard String
  | ClearTempBoard


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ToggleCell pair ->
      ({ model | board = toggleCell model.board pair }, noCmd)
    TogglePause ->
      ({ model | paused = not model.paused }, noCmd)
    Tick newTime ->
      let
        isRecent = (newTime - model.lastUpdate) < model.interval
        shouldRedraw = not (model.paused || isRecent)
      in
        if shouldRedraw then
          ({ model | board = newDict model, lastUpdate = newTime }, noCmd)
        else
          (model, noCmd)
    UpdateInterval str ->
      ({model | interval = Result.withDefault second (String.toFloat str)}, noCmd)
    ClearBoard ->
      ({model | board = Dict.empty}, noCmd)
    SetBoard pattern ->
      ({model | board = Dict.union (boardFromLib pattern) model.board}, noCmd)
    SetTempBoard pattern ->
      ({model | tempBoard = boardFromLib pattern}, noCmd)
    ClearTempBoard ->
      ({model | tempBoard = Dict.empty}, noCmd)


boardFromLib : String -> Board
boardFromLib key =
  Maybe.withDefault Dict.empty (Dict.get key library)

subscriptions : Model -> Sub Msg
subscriptions model =
  Time.every 67 Tick

toggleCell : Board -> Pair -> Board
toggleCell board pair =
  let
    cur = isAlive board pair
  in
    Dict.insert pair (not cur) board


nums : Int -> List Int
nums int =
  if int == 0 then
    [0]
  else
    List.append (nums (int - 1)) [int]

isAlive : Board -> Pair -> Bool
isAlive board pair =
  Maybe.withDefault False (Dict.get pair board)

allNeighbors : Pair -> List Pair
allNeighbors pair =
  let
    i = Tuple.first pair
    j = Tuple.second pair
  in
    [
      (i-1, j-1), (i-1, j), (i-1, j+1),
      (i, j-1),             (i, j+1),
      (i+1, j-1), (i+1, j), (i+1, j+1)
    ]

occupiedNeighbors : Pair -> Board -> Int
occupiedNeighbors pair board =
  let
    neighbors = allNeighbors pair
  in
    List.length (List.filter (\p -> isAlive board p) neighbors)

updatedPos : Pair -> Board -> Bool
updatedPos pair board =
  let
    count = occupiedNeighbors pair board
  in
    if (isAlive board pair) then
      count == 2 || count == 3
    else
      count == 3

newDict : Model -> Board
newDict model =
  let
    board = model.board
    list = List.map (\p -> (p, (updatedPos p board))) model.fullBoard
  in
    Dict.fromList list


onBoard : Pair -> Bool
onBoard pair =
  let
    i = Tuple.first pair
    j = Tuple.second pair
  in
    i >= 0 && j >= 0 && i < boardSize && j < boardSize


-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ div [] [stylesheet "life.css"]
    , pauseButton model.paused
    , intervalSlider model.interval
    , clearButton
    , patternButtons
    , drawBoard model
    ]


drawBoard model =
  let
    board = model.board
    klass = if model.paused then "paused" else ""
  in
    div [class ("board " ++ klass)] (List.map (drawRow model) (nums (boardSize - 1)))

drawRow model i =
  div [class "row"] (List.map (drawCell model i) (nums (boardSize - 1)))

drawCell model i j =
  let
    klass1 = if isAlive model.tempBoard (i, j) then "temp-life" else ""
    klass2 = if isAlive model.board (i, j) then "life" else ""
  in
    div [class ("cell " ++ klass1 ++ " " ++ klass2), onClick (ToggleCell (i, j))] []

pauseButton isPaused =
  let
    str = if isPaused then "Unpause" else "Pause"
  in
    button [ onClick TogglePause, class "pause-button"] [ text str ]

clearButton =
  button [class "clear-button", onClick ClearBoard] [text "Clear"]

patternButton pattern =
  button [onClick (SetBoard pattern), onMouseOver (SetTempBoard pattern), onMouseOut ClearTempBoard] [text pattern]

intervalSlider interval =
  input
    [ type_ "range"
    , Html.Attributes.min "80"
    , Html.Attributes.max "2000"
    , Html.Attributes.step "10"
    , value (toString interval)
    , onInput UpdateInterval
    ] []

patternButtons =
  let
    keys = List.map (\p -> Tuple.first p) libraryList
  in
    span [] (
      List.map (\key -> patternButton key) keys
    )


-- https://gist.github.com/coreytrampe/a120fac4959db7852c0f
stylesheet href =
  let
    tag = "link"
    attrs =
        [ attribute "rel"       "stylesheet"
        , attribute "property"  "stylesheet"
        , attribute "href"      href
        ]
    children = []
  in
    node tag attrs children
