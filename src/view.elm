module View exposing (view)

import Types exposing (..)
import Constants exposing (..)
import Model exposing (..)
import Pattern exposing (Pattern)
import Set exposing (Set)
import Copy

import Html exposing (Html, div, text, span, button, input, img, ul, li)
import Html.Attributes as Attributes exposing (class, style, value, type_, disabled, src)
import Html.Events exposing (onClick, onInput, onMouseOver, onMouseOut)


view : Model -> Html Msg
view model =
  div [class "container clearfix"]
    [ pageHeader
    , boardStuff model
    , controls model
    , gameRules
    ]

boardStuff : Model -> Html Msg
boardStuff model =
  span [class "board-stuff"]
    [ offsetSlider model.iOffset UpdateOffsetI "vertical"
    , drawBoard model
    , offsetSlider model.jOffset UpdateOffsetJ "horizontal"
    ]


pageHeader : Html Msg
pageHeader =
 div [class "page-header"] [text Copy.title]

controls : Model -> Html Msg
controls model =
  span [class "controls"]
    [ pauseButton model.paused
    , clearButton model
    , intervalSlider model.interval
    , patternButtons model
    , eraserButton model
    , saveBoardButton
    , population model
    ]

eraserButton : Model -> Html Msg
eraserButton model =
  let
    klass = if model.isEraser then "selected" else ""
    klasses = "pattern-button " ++ klass
  in
    button [onClick SetEraser, class klasses]
      [(img [src "assets/images/eraser.png"] [])]


drawBoard : Model -> Html Msg
drawBoard model =
  let
    board = model.board
    klass1 = if model.paused then "paused" else ""
    klass2 = if model.isEraser then "eraser" else ""
  in
    div [class ("board " ++ klass1 ++ " " ++ klass2)] (List.map (drawRow model) boardIndexes)

drawRow : Model -> Int -> Html Msg
drawRow model i =
  div [class "row"] (List.map (drawCell model i) boardIndexes)

drawCell : Model -> Int -> Int -> Html Msg
drawCell model i j =
  let
    iVal = (i + model.iOffset) % boardSize
    jVal = (j + model.jOffset) % boardSize

    pair = (iVal, jVal)
    hasTempLife = isAlive model.tempBoard pair
    hasLife = isAlive model.board pair
    klass1 = if hasTempLife then "temp-life" else ""
    klass2 = if hasLife then "life" else ""
    stylePairs = if hasTempLife || hasLife then [] else [("background-color", rgb (jVal - iVal))]
  in
    span [ class "cell-container"
         , onClick (SetTempToBoard pair)
         , onMouseOver (SetTempBoard pair)
         , onMouseOut ClearTempBoard
    ] [
      div
        [ class ("cell " ++ klass1 ++ " " ++ klass2)
        , style stylePairs
        ] []
    ]

rgb : Int -> String
rgb val =
  let
    h = toString ((360 * val) // (boardSize // 1))
  in
    "hsl(" ++ h ++ ",100%,80%)"

pauseButton : Bool -> Html Msg
pauseButton isPaused =
  let
    str = if isPaused then Copy.unpause else Copy.pause
  in
    button [ onClick TogglePause, class "control-button"] [ text str ]

clearButton : Model -> Html Msg
clearButton model =
  let
    boardIsEmpty = Set.isEmpty model.board
  in
    button [class "control-button", onClick ClearBoard, disabled boardIsEmpty] [text Copy.clear]

patternButton : Model -> Pattern -> Html Msg
patternButton model pattern =
  let
    klass = if (model.pattern == pattern && not model.isEraser) then "selected" else ""
    klasses = "pattern-button " ++ klass
  in
    button [onClick (SetPattern pattern), class klasses] [patternPreview pattern]

intervalSlider : Float -> Html Msg
intervalSlider interval =
  input
    [ type_ "range"
    , Attributes.min (toString intervalMin)
    , Attributes.max (toString intervalMax)
    , Attributes.step (toString intervalStep)
    , value (toString interval)
    , onInput UpdateInterval
    , class "interval-slider"
    ] []

offsetSlider : Int -> (String -> Msg) -> String -> Html Msg
offsetSlider val updateFunc klass =
  input
    [ type_ "range"
    , Attributes.min "0"
    , Attributes.max (toString (boardSize - 1))
    , Attributes.step "1"
    , value (toString (val % boardSize))
    , onInput updateFunc
    , class klass
    ] []

patternButtons : Model -> Html Msg
patternButtons model =
  span [class "pattern-buttons"] (
    List.map (\pattern -> patternButton model pattern) Pattern.patterns
  )

patternPreview : Pattern -> Html Msg
patternPreview pattern =
  let
    set = Set.fromList pattern
    patternRage = List.range 0 4
  in
    span [] (List.map (\i->
      div [class "row"] (List.map (\j->
        let
          klass = if isAlive set (i, j) then "life" else ""
        in
          span [class ("cell " ++ klass)] []
      ) patternRage)
    ) patternRage)

saveBoardButton : Html Msg
saveBoardButton =
  button [onClick SaveBoard, class "control-button save-button"] [text Copy.saveBoard]

population : Model -> Html Msg
population model =
  let
    pop = Set.size model.board
    fullWidth = 300
    px = toString (clamp 3 300 pop) ++ "px"
  in
    div [class "population"]
      [ text Copy.population
      , text ": "
      , text(toString pop)
      , div [class "population-bar", style [("width", px)]] []
      ]

gameRules : Html Msg
gameRules =
  div [class "info"]
    [ div [class "rules"]
      [ text "Rules"
        , ul []
          [ li [class "rule"] [text Copy.aliveRule]
          , li [class "rule"] [text Copy.deadRule]
          ]
      ]
    ]
