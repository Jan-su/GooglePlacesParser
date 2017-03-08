module Parser exposing (..)
import Html exposing (..)
import Array
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http  
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Basics exposing(..)

type alias FilePath = String
type alias Query = String
type alias Flags = {query: Query}
type alias PicRef = String
type alias Model = {picRef: PicRef, status: String}

main =
  Html.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

waitForQuery = {picRef = "http://ribalych.ru/wp-content/uploads/2014/07/55019.jpg",  status = "Успех. Жду дальнейших указаний!"}
processingQuery = {picRef ="http://vgif.ru/gifs/147/vgif-ru-20060.gif", status = "Обработка запроса!"}
error = {picRef ="https://s-media-cache-ak0.pinimg.com/originals/bb/58/a5/bb58a5e37834d2d4cce9b42c59a01c7c.jpg", status = "Ошибка!!!"}

type Msg = PostToServer (Result Http.Error String)

init : Flags -> ( Model, Cmd Msg )
init flags= 
  (processingQuery, sendPost flags)

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )     
update msg model =
  case msg of
    PostToServer  response->
      case response of
        Ok val ->
          (waitForQuery, Cmd.none) 
        Err _ ->
          (error, Cmd.none)





view : Model -> Html Msg
view model = 
  div[]
    [div[][model.status|>text]
    , div[]
        [img [src model.picRef, style [
                                  ("width", "400px"), 
                                  ("height", "350px")
                                  ]][]
        ]
  ]

sendPost:Flags -> Cmd Msg
sendPost flags=
  Http.send PostToServer (post flags)

encodeFilter: Flags -> Encode.Value
encodeFilter flags=
   Encode.object
    [
      ("query", Encode.string flags.query)
    ]


post :  Flags -> Http.Request String
post flags =
  Http.request
    { method = "POST"
    , headers = []
    , url = "../send_to_server/"
    , body = Http.jsonBody (encodeFilter flags)
    , expect = Http.expectJson Decode.string
    , timeout = Nothing
    , withCredentials = False
    }