module Main exposing (..)

import Html exposing (Html, program, text, div, span)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import SelectTwo exposing (..)
import SelectTwo.Html exposing (..)
import SelectTwoTypes exposing (..)
import Task
import Json.Decode as JD
import Helpers exposing ((=>))


type alias Model =
    { selectTwo : Maybe (SelectTwo Msg)
    , test : Maybe String
    , test2 : Maybe String
    , test3 : List (Maybe String)
    , test4 : Maybe { id : Int, name : String }
    }


init : ( Model, Cmd Msg )
init =
    { selectTwo = Nothing
    , test = Nothing
    , test2 = Nothing
    , test3 = []
    , test4 = Nothing
    }
        ! []


type Msg
    = Test (Maybe String)
    | Test2 (Maybe String)
    | Test3 (Maybe String)
    | Test4 (Maybe { id : Int, name : String })
    | SelectTwo (SelectTwoMsg Msg)
    | Test3Clear Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectTwo stmsg ->
            SelectTwo.update stmsg model

        Test s ->
            { model | test = s } ! []

        Test2 s ->
            { model | test2 = s } ! []

        Test3 s ->
            { model | test3 = s :: model.test3 } ! []

        Test4 s ->
            { model | test4 = s } ! []

        Test3Clear (Test3 s) ->
            { model | test3 = model.test3 |> (List.filter ((/=) s)) } ! []

        Test3Clear _ ->
            model ! []


main : Program Never Model Msg
main =
    program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    div
        [ class "parent"
        , style
            [ ( "width", "100%" )
            , ( "height", "100%" )
            ]
        , select2Close SelectTwo
        ]
        [ select2Css
        , div []
            [ select2 SelectTwo
                { default = Test model.test
                , list = testList Test
                , id_ = "test-1"
                , parents = [ "parent" ]
                , clearMsg = Just (Test Nothing)
                , showSearch = True
                , width = "300px"
                , placeholder = "Select Test"
                , disabled = model.test2 == Just "a"
                }
            ]
        , div []
            [ select2 SelectTwo
                { default = Test2 model.test2
                , list = testList2 Test2
                , parents = [ "parent" ]
                , id_ = "test-2"
                , clearMsg = Just (Test2 Nothing)
                , showSearch = True
                , width = "300px"
                , placeholder = "Select Test"
                , disabled = False
                }
            ]
        , div []
            [ select2Multiple SelectTwo
                { defaults = model.test3 |> List.map Test3
                , list = testList3 Test3
                , id_ = "test-3"
                , parents = [ "parent" ]
                , clearMsg = Test3Clear
                , width = "300px"
                , placeholder = "Select Test"
                , disabled = model.test2 == Just "a"
                }
            ]
        , div []
            [ select2Ajax SelectTwo
                { default = model.test4 |> Maybe.map (\t -> ( Just (Test4 (Just t)), text t.name, t.name )) |> Maybe.withDefault ( Nothing, text "", "" )
                , url = "//api.github.com/search/repositories"
                , data =
                    (\( url, params ) ->
                        let
                            term =
                                if params.term == "" then
                                    "test"
                                else
                                    params.term
                        in
                            (url ++ "?q=" ++ term ++ "&page=" ++ (toString params.page))
                    )
                , processResults = processResult
                , id_ = "test-1"
                , parents = [ "parent" ]
                , clearMsg = Just (Test4 Nothing)
                , showSearch = True
                , width = "300px"
                , placeholder = "Select Test"
                , disabled = model.test2 == Just "a"
                }
            ]
        , select2Dropdown model
        ]


processResult : ( String, AjaxParams ) -> ( List (GroupSelectTwoOption Msg), AjaxParams )
processResult ( string, params ) =
    (JD.decodeString
        ((JD.map2 (,)
            (JD.at [ "items" ] (JD.list itemsDecoder))
            (JD.field "total_count" JD.int)
         )
            |> JD.map
                (\( items, total_count ) ->
                    ( items |> List.map (\i -> ( Just i, i.name )) |> SelectTwo.basicSelectOptions Test4
                    , { params | more = (params.page * 30 < total_count) }
                    )
                )
        )
        string
    )
        |> Result.toMaybe
        |> Maybe.withDefault ( [], params )


type alias Item =
    { id : Int, name : String }


itemsDecoder : JD.Decoder Item
itemsDecoder =
    JD.map2 Item
        (JD.field ("id") JD.int)
        (JD.field ("name") JD.string)


testList : (Maybe String -> Msg) -> List ( String, List (SelectTwoOption Msg) )
testList msg =
    [ ( Just "a", "a" )
    , ( Just "b", "b" )
    , ( Just "c", "c" )
    , ( Just "d", "Decons Chons" )
    , ( Just "e", "Fangroana" )
    , ( Just "f", "Ender's Game" )
    ]
        |> SelectTwo.basicSelectOptions msg


testList2 : (Maybe String -> Msg) -> List ( String, List (SelectTwoOption Msg) )
testList2 msg =
    [ ( Just "a", "a", "a" ), ( Just "b", "b", "a" ), ( Just "c", "c", "b" ) ] |> SelectTwo.basicGroupSelectOptions msg


testList3 : (Maybe String -> msg) -> List (GroupSelectTwoOption msg)
testList3 msg =
    ( ""
    , [ ( Just "a", "a" )
      , ( Just "b", "b" )
      , ( Just "c", "c" )
      , ( Just "d", "Decons Chons" )
      , ( Just "e", "Fangroana" )
      , ( Just "f", "Ender's Game" )
      ]
        |> List.map
            (\( a, b ) ->
                ( Just (msg a)
                , span
                    [ style
                        [ "width" => "100%"
                        , "text-align" => "center"
                        , "display" => "inline-block"
                        ]
                    ]
                    [ text b
                    ]
                , b
                )
            )
    )
        :: []
