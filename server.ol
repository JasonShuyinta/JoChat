include "serverInterface.iol"
include "console.iol"
include "string_utils.iol"
include "time.iol"
include "runtime.iol"
include "MonitorInterface.iol"
include "file.iol"


execution{ concurrent }


outputPort Server2Nodo {
  Protocol: sodep
  Interfaces: ServerInterface
}


inputPort Nodo2Server {
  Location:"socket://localhost:9000"
  Protocol: sodep
  Interfaces: ServerInterface

}

outputPort Server2Monitor {
  Location: "socket://localhost:9001"
  Protocol: sodep
  Interfaces: MonitorInterface
}

main {
    [ join( joinRequest )( message ) {
        synchronized( token ){
          global.count++;
          i = #global.listaNodi
          global.listaNodi[i] << joinRequest
        }
    }] {
        log@Server2Monitor(global.count + " Nome del nodo : "
        +global.listaNodi[i].nomeNodo + " - Numero della porta: "
        +global.listaNodi[i].numeroPorta)
      }

      [ getInfoDestinatario( nomeDestinatario ) ( infoDestinatario ) {
        synchronized( token ) {
          for( i = 0, i < #global.listaNodi, i++) {
            if( nomeDestinatario == global.listaNodi[i].nomeNodo ) {
              numeroPortaTmp = global.listaNodi[i].numeroPorta
              chiavepubblicaTmp = global.listaNodi[i].chiavePub
            }
          }
          infoDestinatario.numeroPorta << numeroPortaTmp
          infoDestinatario.chiavePub << chiavepubblicaTmp
        }
      }]

      [ sendChat( nome ) ] {
        i = #global.listaChat;
        global.listaChat[i] << nome
      }

      [ getChat(  ) ( lista ) {
        synchronized( token ) {
          for( i = 0, i < #global.listaChat , i++) {
            listaChatTemp = listaChatTemp + "\n" + global.listaChat[i]
          }
          if(listaChatTemp == null) {
            listaChatTemp = "Non e' presente nessuna chat attiva!"
          }
          lista << listaChatTemp
        }
      }]

      [ getNodi ( numeroPorta  ) ( listaNodiAttivi ) {
        synchronized( token ) {
          Server2Nodo.location=numeroPorta;

          for( i = 0, i < #global.listaNodi , i++) {
            listaNodiTemp = listaNodiTemp + "\n " + global.listaNodi[i].nomeNodo + " " + global.listaNodi[i].numeroPorta
          };
          listaNodiTemp = listaNodiTemp + "\n ";

          listaNodiAttivi << listaNodiTemp
        }
      }]


      [ addChat( request )( response ) {
        if ( !is_defined( global.chat.( request.chat_name ) ) ) {
            global.chat.( request.chat_name ) = true
        }
        ;
        /* check if the chat already exists and the username is already registered*/
        if ( !is_defined( global.chat.( request.chat_name ).users.( request.username ) )) {
            global.chat.( request.chat_name ).users.( request.username ).location = request.location;
            /* new is a jolie primitive for creating a fresh token */
            token = new;
            global.chat.( request.chat_name ).users.( request.username ).token = token;
            /* token hashmap */
            global.tokens.( token ).chat_name = request.chat_name;
            global.tokens.( token ).username = request.username
        }
        ;
        response.token = global.chat.( request.chat_name ).users.( request.username ).token
    }]


    [ addNameChat( nomeChat ) ( esito ) {
      synchronized( token ) {
      esitoTmp = "true";
      for( i = 0, i < #global.listaChatGruppo, i++) {
        if( nomeChat == global.listaChatGruppo[i] ) {
          esitoTmp = "false"
        }
      }
      if( esitoTmp == "true") {
          global.listaChatGruppo[#global.listaChatGruppo] << nomeChat
        }
      esito << esitoTmp
    }
    }]

    [ checkEsistenzaGruppo( nomeChatGruppo )( esito ) {
      synchronized( token ) {
        esitoTmp = "false";
      for( i = 0, i < #global.listaChatGruppo, i++) {
        if( nomeChatGruppo == global.listaChatGruppo[i] ) {
          esitoTmp = "true"
        }
      }
      esito << esitoTmp
      }
    } ]


    [ sendMessage( request )( response ) {
        /* validate token */
        if ( is_defined( global.tokens.( request.token ) ) ) {
            /* sending messages to all participants using dynamic binding */
            chat_name = global.tokens.( request.token ).chat_name;
            foreach( u : global.chat.( chat_name ).users ) {
                /* output port dynamic rebinding */
                Server2Nodo.location = global.chat.( chat_name ).users.( u ).location;
                /* message sending */
                if ( u != global.tokens.( request.token ).username ) {
                  with( msg ) {
                      .message = request.message;
                      .chat_name = chat_name;
                      .username = global.tokens.( request.token ).username
                  };
                  setMessage@Server2Nodo( msg )
                }
            }
            //file.filename = chat_name+"/"+msg.chat_name + ".txt";*/
            file.filename = msg.chat_name+".txt";
            file.append = 1;
            file.content = msg.username + ": " + msg.message+"\n";
            writeFile@File( file )( void )
        } else {
            throw( TokenNotValid )
        }
    }]

    [ sendNomeGruppo( nomeGruppo )( listaPartecipantiGruppo ) {
      listaPartecipantiGruppo.numeroPorta << global.chat.( nomeGruppo ).location
    } ]



}
