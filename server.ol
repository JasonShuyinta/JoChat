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
        log@Server2Monitor(global.count + ". Nome del nodo : "
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



    [ sendNomeGruppo( nomeGruppo )( listaPartecipantiGruppo ) {
      listaPartecipantiGruppo.numeroPorta << global.chat.( nomeGruppo ).location
    } ]


    [ gestioneGruppo( gruppo ) ] {
      i = #global.groupChat.name;
      global.groupChat.name[i] = gruppo.nome;
      for (j=0, j<#global.groupChat.name, j++){
        if (global.groupChat.name[j] == gruppo.nome){
          global.groupChat.name[j].port[#global.groupChat.name[j].port] = gruppo.porta
        }
      }
    }

    [ gestioneGruppo2( gruppo ) ] {
      esiste = "false"
      for (i=0, i<#global.groupChat.name, i++){
        if (global.groupChat.name[i] == gruppo.nome){
          for (j=0, j<#global.groupChat.name[i].port, j++){
            if (global.groupChat.name[i].port[j] == gruppo.nome){
              esiste = "true"
            }
          }
          if (esiste=="false"){
            global.groupChat.name[i].port[#global.groupChat.name[i].port] = gruppo.porta
          }
        }
      }


    /*  for (i=0, i<#global.groupChat.name, i++){
        println@Console(global.groupChat.name[i])();
          for (j=0, j<#global.groupChat.name[i].port, j++){
            println@Console(global.groupChat.name[i].port[j])()
          }
      }*/
    }



    [ richiestaPorteGruppo( nomeChatGruppo ) ( porte ) {
      for (i=0, i<#global.groupChat.name, i++){
        if (global.groupChat.name[i] == nomeChatGruppo){
          for (j=0, j<#global.groupChat.name[i].port, j++){
            porte.numeroPortaGruppo[#porte.numeroPortaGruppo] = global.groupChat.name[i].port[j]
          }
        }
      }
    }]

    [offline(notifica)]{
      global.count++;
      log@Server2Monitor(global.count+". "+notifica)
    }

    [uscitaGruppo(Dati)]{
      for (i=0, i<#global.groupChat.name, i++){
        if (global.groupChat.name[i] == Dati.nomeChat){
          for (j=0, j<#global.groupChat.name[i].port, j++){
            if(global.groupChat.name[i].port[j] == Dati.numeroPorta){
              undef(global.groupChat.name[i].port[j])
            }
          }
        }
      }
    }

    [deleteNodo(Nodi)]{
      for(i=0, i<#global.listaNodi.nomeNodo, i++){
        if(global.listaNodi.nomeNodo[i] == Nodi.nomeNodo){
          undef(global.listaNodi.nomeNodo[i])
        }
      }
      for(i=0, i<#global.listaNodi.numeroPorta, i++){
        if(global.listaNodi.numeroPorta[i] == Nodi.numeroPorta){
          undef(global.listaNodi.numeroPorta[i])
        }
      }
    }



}
