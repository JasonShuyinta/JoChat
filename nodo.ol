include "serverInterface.iol"
include "file.iol"
include "console.iol"
include "runtime.iol"
include "string_utils.iol"

type cifraMsg: void{
  .msg:string
  .valoreN:string
  .valoreE:string
}

type risposta: void{
  .messCifrato: raw
}

type operazioneCifr: void{
  .risposta: raw
}

interface PrivataInterface {
  RequestResponse:
  generatoreChiavi(void)(string),
  splitKeysPriv(string)(string),
  splitKeysPub(string)(string),
  splitKeysNtoE(string)(string),
  splitKeysNtoD(string)(string),
  splitKeysN(string)(string),
  encrypt(cifraMsg)(operazioneCifr)
}

outputPort Nodo2Server {
  Location: "socket://localhost:9000"
  Protocol: sodep
  Interfaces: ServerInterface
}

outputPort Nodo2Nodo {
  Protocol: sodep
  Interfaces: ServerInterface
}

outputPort Server2Nodo {
    Protocol: sodep
    Interfaces: ServerInterface
}



outputPort Privata {
    Interfaces: PrivataInterface
}

init
{
  install(
    FileNotFound => println@Console("Specify a valid log file or create it before launching the Monitor. The file already exists.")()
  )
  if (#args != 2){
    println@Console( "Inserisci: <nome nodo> <numeroPorta>" )()
    throw( Error )
  }

  //embedding dinamico del servizio nodo_service.ol
  socketLocation = "socket://localhost:"+args[1]+"/"
  with( emb ) {
    .filepath = "-C LOCATION=\"" + socketLocation + "\" nodo_service.ol";
    .type = "Jolie"
  };
  loadEmbeddedService@Runtime( emb )()
}

embedded {
    Java:     "lib.Privata" in Privata
}


main {
    registerForInput@Console(  )(  );
    request.nomeNodo = args[0];
    request.numeroPorta = args[1];
    exists@File( request.nomeNodo )( exists )
    while(exists == true) {
      println@Console( "Il nome inserito non è valido. Prova ad unserire un'altro nome: " )();
      in(request.nomeNodo)
      exists@File( request.nomeNodo )( exists )
    }
    mkdir@File( request.nomeNodo )( response );

    //Server2Nodo.location="socket://localhost:"+request.numeroPorta+"/";



    generatoreChiavi@Privata()(chiavi);
    splitKeysPriv@Privata(chiavi)(chiavePrivata);
    splitKeysPub@Privata(chiavi)(chiavePubblica);
    splitKeysNtoE@Privata(chiavePubblica)(valoreE);
    splitKeysNtoD@Privata(chiavePrivata)(valoreD);
    splitKeysN@Privata(chiavePubblica)(valoreN);
    request.chiavePub = chiavePubblica;

    infoPrivata.valD = valoreD;
    infoPrivata.valN = valoreN;
    Nodo2Nodo.location = "socket://localhost:"+args[1];
    SaveKey@Nodo2Nodo(infoPrivata)
    join@Nodo2Server( request )( response );
    println@Console( response )(  );

    while (opzione != "6") {
      println@Console( "=====================================" )(  );
      println@Console( "Premi 1 per visualizzare le chat di gruppo attive" )(  );
      println@Console( "Premi 2 per visualizzare i nodi attivi" )(  );
      println@Console( "Premi 3 per creare una chat di gruppo" )(  );
      println@Console( "Premi 4 per accedere a una chat di gruppo" )(  );
      println@Console( "Premi 5 per accedere a una chat privata" )(  );
      println@Console( "Premi 6 per uscire" )(  );
      in( opzione );

      if( opzione != "1" && opzione != "2" && opzione != "3" && opzione != "4" && opzione != "5"  )
      {
        println@Console( "Il comando inserito non e' valido " )(  )
      }
      else if ( opzione == "1")
      {
        //"Premi 1 per visualizzare le chat attive"
        println@Console( "Lista Chat Attive:" )(  )
        getChat@Nodo2Server( )( lista )
        println@Console( lista )(  )
}

      //"Premi 2 per visualizzare i nodi attivi"
      else if ( opzione == "2") {
        getNodi@Nodo2Server( request.numeroPorta )( lista )
        println@Console( "========================================" )(  )
        println@Console( "Lista dei nodi attivi:" )(  );
        println@Console( "" )(  );
        println@Console( " Nome - Porta" )(  );
        println@Console( lista )(  )
      }




      //"Premi 3 per creare una chat di gruppo"
      //inserire firma digitale
      else if ( opzione == "3")
      {
        println@Console( "Inserisci il nome della tua Chat " )(  );
        in( nome );

        //controlla che il nome non sia gia preso
        while(esito!="true") {
        addNameChat@Nodo2Server( nome )( esito )

        //Se il nome non esiste già continua...
        if( esito == "true") {
        sendChat@Nodo2Server( nome );
        println@Console( "Chat di gruppo '" + nome + "' attiva " )(  );
        with( add_req ) {
        .chat_name = nome;
        .username = args[0];
        .location = socketLocation
    };
        //mkdir@File( nome )(  );
        //scrivi una riga in modo che non sia mai vuoto
        file.filename = nome+".txt";
        file.content = "Chat di gruppo: "+nome+"\n";
        file.append = 1;
        writeFile@File( file )( void );

        addChat@Nodo2Server( add_req )( add_res );
        //Nodo2Group.location = socketLocation;
        //addChat@Nodo2Group( add_req )( add_res );
        token = add_res.token;
        println@Console( "Attendi che qualcuno si unisca al tuo gruppo prima di scrivere un messaggio" )(  );
        in( message );
        while( message != "$") {
          //leggi i messaggi precedenti
          if( message == "%") {
                println@Console( "===========================" )(  )
                println@Console( "Messaggi precedenti:" )(  )
                letturaFile.filename = nome +".txt";
                readFile@File( letturaFile )( msgPrecedenti );
                println@Console( msgPrecedenti )(  );
                message = "***Lettura messaggi***";
                println@Console( "============================" )(  )
              }
        sendMessage@Nodo2Server( { .token = token, .message=message } )()
        in ( message )
        }
        if( message == "$") {
              messaggioUscita = "***L'utente e' uscito dal gruppo***"
              sendMessage@Nodo2Server( { .token = token, .message = messaggioUscita} )(  )
            }
        //se il nome esiste già, inserisci un altro nome
        } else {
          println@Console( "Nome già usato, inseriscine un altro" )(  )
          in( nome )
        }
        }
    }

    //"Premi 4 per accedere a una chat di gruppo"
    else if ( opzione == "4") {
      //inserire firma digitale
      getChat@Nodo2Server(  )( lista )
      if( lista == "Non e' presente nessuna chat attiva!") {
        println@Console( lista )(  )
      }
      else {
      println@Console( "Inserisci il nome della chat di gruppo a cui vuoi partecipare:" )(  )

      in( nomeChatGruppo );

      checkEsistenzaGruppo@Nodo2Server( nomeChatGruppo )( esito )
      if( esito == "false") {
        println@Console( "Nome gruppo non esistente" )(  )
      }
      else
      {
        sendNomeGruppo@Nodo2Server( nomeChatGruppo )( listaPartecipanti );
        println@Console( listaPartecipanti[0] )(  );
        println@Console( "Chat: '" + nomeChatGruppo +"'")(  );
        println@Console( "Scrivi un messaggio, o premi '%' per visualizzare i messaggi precedenti" )(  )

        with( add_req ) {
          .chat_name = nomeChatGruppo;
          .username = args[0];
          .location = socketLocation
        };
        //Nodo2Group.location = "socket://localhost:9020";
        addChat@Nodo2Server( add_req )( add_res );
        token = add_res.token;
            in( message );
            while ( message != "$") {
              //leggi messaggi precedenti
              if( message == "%") {
                println@Console( "===========================" )(  )
                println@Console( "Messaggi precedenti:" )(  )
                myFile.filename = nomeChatGruppo+".txt";
                readFile@File( myFile )( contenuto );
                println@Console( contenuto )(  );
                message = "***Lettura messaggi***";
                println@Console( "============================" )(  )
              }
              sendMessage@Nodo2Server( { .token = token, .message=message } )();
              in( message )
            }
            if( message == "$") {
              messaggioUscita = "***L'utente e' uscito dal gruppo***"
              sendMessage@Nodo2Server( { .token = token, .message = messaggioUscita} )(  )
            }
          }
        }
      }






    //Chat privata
    //sovrascrivere i file.txt e decidere se lasciare cosi oppure comunicare tramite porte
    //aggiungere crittografia/decrittografia
    else if ( opzione == "5") {
      println@Console( "Inserisci il nome del nodo con cui vuoi comunicare: " )(  )
      in( nomeNodoDestinatario )
      exists@File( nomeNodoDestinatario )( exists )
      while(exists == false) {
        println@Console( "Nome inserito errato, inserisci il nome corretto del destinatario:" )(  );
        in( nomeNodoDestinatario )
        exists@File( nomeNodoDestinatario )( exists )
      };

        //abbiamo ottenuto la porta e la chiave pubblica
        getInfoDestinatario@Nodo2Server( nomeNodoDestinatario )( infoDestinatario );
        //println@Console( infoDestinatario.chiavePub )(  );
        //println@Console( infoDestinatario.numeroPorta )(  )
        //fine
        splitKeysNtoE@Privata(infoDestinatario.chiavePub)(valoreEDest);
        splitKeysN@Privata(infoDestinatario.chiavePub)(valoreNDest);

        cifraMsg.valoreE=valoreEDest;
        cifraMsg.valoreN=valoreNDest;

        println@Console( "Inserisci il messaggio (per uscire dalla chat inviare '$'): " )(  )
        mySocketLocation = "socket://localhost:"+infoDestinatario.numeroPorta;
        Nodo2Nodo.location = mySocketLocation;
        in( messaggio )

        while ( messaggio != "$") {
          cifraMsg.msg=messaggio;
          encrypt@Privata(cifraMsg)(messaggioCifrato)                 //messaggio criptato
          informazioni.nomeMittente = args[0];                        // nome del mittente
          informazioni.nomeDestinatario = nomeNodoDestinatario;       // nome del destinatario
          informazioni.msg = messaggioCifrato.risposta;

          invioPrivato@Nodo2Nodo( informazioni );
          in( messaggio )
        }
    }
  }
}