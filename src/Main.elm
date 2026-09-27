port module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class, type_, pattern, value, placeholder)
import Html.Events exposing (onInput, onClick)
import Json.Encode as Encode
import Json.Decode as Decode
import Dict exposing (Dict)


-- MAIN
main : Program () Model Msg
main =
    Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- PORTS

port exportBudget : Encode.Value -> Cmd msg
port importBudget : (List (List String) -> msg) -> Sub msg


-- MODEL

type alias Entry =
    { description : String
    , amount : String
    }

type alias Model =
    { entries : Dict Int Entry
    , exportMsg : String
    , currentPage: Page
    , display: String
    }


type Page
    = HomePage
    | BudgetPage
    | AccountsPage AccountName


type AccountName
    = DefaultAccount
    | AccountA
    | AccountB



init : () -> ( Model, Cmd Msg )
init flags =
    ( {
        entries = Dict.singleton 0 {description = "First", amount = "0.0"}
        , exportMsg = ""
        , currentPage = HomePage
        , display = ""
      }
    , Cmd.none
    )


-- UPDATE

type Msg
    = CategoryChanged Int String
    | AmountChanged Int String
    | Export
    | Import (List (List String))
    | GoToBudget
    | ChangeDisplay Int
    | GoToAccount AccountName



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CategoryChanged index description ->
            if Dict.member index model.entries then
                ( { model | entries = Dict.update index (Maybe.map (\entry ->
                    { entry | description = description })) model.entries
                  }
                , Cmd.none
                )
            else
                ( { model | entries = Dict.union model.entries (
                    Dict.singleton index ( Entry description "" )
                    )
                  }
                , Cmd.none
                )

        AmountChanged index amount ->
            ( { model | entries = Dict.update index (Maybe.map (\entry ->
                { entry | amount = amount })) model.entries
              }
            , Cmd.none
            )

        Export ->
            let
                budgetValue = budgetEncoder model.entries
            in
                ( { model | exportMsg = "Exported!" }, exportBudget budgetValue )


        Import budgetTable ->
            let
                newEntries =
                    budgetTable
                    |> List.map mapToEntry
                    |> List.indexedMap indexedEntry
                    |> Dict.fromList

            in
                ( { model | entries = newEntries }, Cmd.none )

        GoToAccount accountName ->
            ({ model | currentPage = AccountsPage accountName }, Cmd.none )


        ChangeDisplay newDigit ->
            ({ model | display = model.display ++ String.fromInt newDigit }, Cmd.none )


        GoToBudget ->
            ({ model | currentPage = BudgetPage }, Cmd.none )

indexedEntry : Int -> Entry -> ( Int, Entry )
indexedEntry index entry =
    ( index, entry )


mapToEntry : List String -> Entry
mapToEntry budgetRow =
    let
        first = getHead budgetRow
        second = getHead (List.drop 1 budgetRow)
    in
        Entry first second


getHead : List String -> String
getHead budgetTable =
    case List.head budgetTable of
        Just head ->
            head
        Nothing ->
            "ERR"


budgetEncoder : Dict Int Entry -> Encode.Value
budgetEncoder entries =
    Encode.list entryEncoder <| Dict.values entries


entryEncoder : Entry -> Encode.Value
entryEncoder entry =
    Encode.object
      [ ("description", Encode.string entry.description)
      , ("amount", Encode.string entry.amount)
      ]


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    importBudget Import



-- VIEW

view : Model -> Html Msg
view model =
    case model.currentPage of
        HomePage ->
            div [class "bg-yellow-500 w-dvw"]
                [ div [ class "flex flex-col gap-y-5" ]
                      [ div [ class "flex flex-row gap-x-5 justify-evently" ]
                        [ button [ class "flex-1", concat 1 ] [ text "1" ]
                        , button [ class "flex-1", concat 2 ] [ text "2" ]
                        , button [ class "flex-1", concat 3 ] [text "3"]
                        ]
                      , div [ class "flex flex-row gap-x-5 items-center" ]
                        [ button [ class "flex-1", concat 4 ] [ text "4" ]
                        , button [ class "flex-1", concat 5 ] [ text "5" ]
                        , button [ class "flex-1", concat 6 ] [ text "6" ]
                        ]
                      , div [ class "flex flex-row gap-x-5" ]
                        [ button [ class "flex-1", concat 7 ] [ text "7" ]
                        , button [ class "flex-1", concat 8 ] [ text "8" ]
                        , button [ class "flex-1", concat 9 ] [ text "9" ]
                        ]
                      , p [ class "bg-white w-1/2" ] [ text model.display ]
                      , div [ class "flex flex-row gap-x-5" ] [ button [ class "flex-1" ] [ text "USD" ], button [ class "flex-1" ] [ text "MXN" ], button [ class "flex-1" ] [ text "Otro" ]]
                      , button [ onClick (GoToAccount DefaultAccount) ] [ text "Cuentas" ]
                      ]
                ]


        AccountsPage account ->

            case account of

                DefaultAccount ->
                    div []
                        [ h2 [] [ text "Default Account" ]
                        , accountButtons
                        ]

                AccountA ->
                    div []
                        [ h2 [] [ text "Account A" ]
                        , accountButtons
                        ]

                AccountB ->
                    div []
                        [ text "Account B"
                        , accountButtons
                        ]


        BudgetPage ->
            div []
                [ h1 [] [ text "Presupuesto" ]
                , table []
                    ([ tr [] [ th [] [text "Categoria"], th [] [ text "Cuanto" ] ] ] ++
                    List.map writeEntry (Dict.toList model.entries)  ++
                    [ writeTableRow (Dict.size model.entries) "" "" (String.toFloat "0") ])
                , button [ onClick Export ] [ text "Exportar" ]
                , p [ placeholder "0" ] [ text model.exportMsg ]
                ]


accountButtons : Html Msg
accountButtons =
    div [ class "flex flex-col gap-5" ]
        [ button [ onClick (GoToAccount DefaultAccount) ] [ text "Default Account" ]
        , button [ onClick (GoToAccount AccountA) ] [ text "Account A" ]
        , button [ onClick (GoToAccount AccountB) ] [ text "Account B" ]
        ]


concat : Int -> Html.Attribute Msg
concat num =
    onClick (ChangeDisplay num)


writeEntry : ( Int, Entry ) -> Html Msg
writeEntry (index, entry) =
  writeTableRow index entry.description entry.amount (String.toFloat entry.amount)


writeTableRow : Int -> String -> String -> Maybe Float -> Html Msg
writeTableRow index description amount maybeFloat =
  tr []
  [ td [] [ input [ type_ "text", value description, onInput ( CategoryChanged index ) ] [] ]

  , td []
    [ input
      [ type_ "text"
      , pattern "\\d{0,}\\.?\\d\\d"
      , value amount
      , onInput ( AmountChanged index )
      , class ( if maybeFloat == Nothing then "bg-red-800" else "bg-black" )
      ] []
    ]
  ]

-- DETECT ENTER

ifIsEnter : msg -> Decode.Decoder msg
ifIsEnter msg =
    Decode.field "key" Decode.string
        |> Decode.andThen (\key -> if key == "Enter" then Decode.succeed msg else Decode.fail "some other key")


