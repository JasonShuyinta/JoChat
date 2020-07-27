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
  //inserimento dei nuovi nodi all'interno della lista e stampa su monitor
  [join( joinRequest )] {
      synchronized( token ){
        global.count++;
        i = #global.listaNodi
        global.listaNodi[i] << joinRequest

      log@Server2Monitor(global.count + ". Nome del nodo : "
      +global.listaNodi[i].nomeNodo + " - Numero della porta: "
      +global.listaNodi[i].numeroPorta)
    }
  }

  //invia informazioni del nodo destinatario per l'invio del messaggio
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

  //inserimento di una nuova chat nella lista delle chat di gruppo
  [ sendChat( nome ) ] {
    synchronized( token ) {
      i = #global.listaChat;
      global.listaChat[i] << nome
    }
  }

  //ottieni la lista delle chat di gruppo
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

  //ottieni la lista dei nodi attivi
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

  //aggiungi una nuova chat di gruppo alla lista delle chat di gruppo
  [ addNameChat( nomeChat ) ( esito ) {
    synchronized( token ) {
      esitoTmp = "true";
      for( i = 0, i < #global.listaChatGruppo, i++) {
        if( nomeChat == global.listaChatGruppo[i] ) {
          esitoTmp = "false"
        }
      }
      if( esitoTmp == "true") {
        global.listaChatGruppo[#global.listaChatGruppo] = nomeChat
      }
      esito << esitoTmp
    }
  }]

  //controlla l'esistenza di un gruppo all'interno della lista 
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
  }]

  //ottienii la location delle porte dei partecipanti di un gruppo
  [ sendNomeGruppo( nomeGruppo )( listaPartecipantiGruppo ) {
    synchronized( token ) {
    listaPartecipantiGruppo.numeroPorta << global.chat.( nomeGruppo ).location
    }
  }]

  //aggiungi un nuovo gruppo alla lista delle chat di gruppo
  [ creaGruppo( gruppo ) ] {
  synchronized( token ) {
    i = #global.groupChat.name;
    global.groupChat.name[i] = gruppo.nome;
    for (j=0, j<#global.groupChat.name, j++){
      if (global.groupChat.name[j] == gruppo.nome){
        global.groupChat.name[j].port[#global.groupChat.name[j].port] = gruppo.porta
      }
    }
  }
}

  //aggiungi un nuovo membro ad un grupppo già esistente
  [ gestioneGruppo( gruppo ) ] {
    synchronized( token ) {
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
  }
}

  //ottieni la location delle porte dei componenti del gruppo passato nella request
  [ richiestaPorteGruppo( nomeChatGruppo ) ( porte ) {
    synchronized( token ) {
    for (i=0, i<#global.groupChat.name, i++){
      if (global.groupChat.name[i] == nomeChatGruppo){
        for (j=0, j<#global.groupChat.name[i].port, j++){
          porte.numeroPortaGruppo[#porte.numeroPortaGruppo] = global.groupChat.name[i].port[j]
        }
      }
    }
  }
}]

  //stampa a monitor l'uscita del gruppo di un membro
  [offline(notifica)]{
    synchronized( token ) {
    global.count++;
    log@Server2Monitor(global.count+". "+notifica)
  }
}

  //elimina dalla lista dei componenti del gruppo, il membro passato nella request
  [uscitaGruppo(Dati)]{
    synchronized( token ) {
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
}

  //elimina il nodo dalla lista dei nodi attivi
  [deleteNodo(Nodi)]{
    synchronized( token ) {
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
}
