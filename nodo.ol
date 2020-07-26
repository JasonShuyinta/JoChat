include "serverInterface.iol"
include "file.iol"
include "console.iol"
include "runtime.iol"
include "string_utils.iol"

type cifraMsg: void{
  .msg:string
  .chiavePub:string
}

type pacchettoFirma: void{
  .privKey:string
  .mex:string
}

type coppiaChiavi: void{
  .chiavePubblica:string
  .chiavePrivata:string
}

type mexCifrato:void{
  .okok:string
}

type firmaMessaggio:void{
  .firmaDigitale:string
}

interface PrivataInterface {
  RequestResponse:
  generatoreChiavi(void)(coppiaChiavi),
  encrypt(cifraMsg)(mexCifrato),
  creaFirma(pacchettoFirma)(firmaMessaggio)
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



    generatoreChiavi@Privata()(coppiaChiavi);
    chiavePub = coppiaChiavi.chiavePubblica;
    chiavePriv = coppiaChiavi.chiavePrivata;
    request.chiavePub=chiavePub;
    Nodo2Nodo.location = "socket://localhost:"+args[1];
    SaveKey@Nodo2Nodo(chiavePriv)
    join@Nodo2Server( request )( response );
    println@Console( response )(  );

    while (opzione != "6") {
      println@Console( "=====================================" )(  );
      println@Console( "Premi (1) per visualizzare le chat di gruppo attive" )(  );
      println@Console( "Premi (2) per visualizzare i nodi attivi" )(  );
      println@Console( "Premi (3) per creare una chat di gruppo" )(  );
      println@Console( "Premi (4) per accedere a una chat di gruppo" )(  );
      println@Console( "Premi (5) per accedere a una chat privata" )(  );
      println@Console( "Premi (6) per uscire" )(  );
      in( opzione );

      if( opzione != "1" && opzione != "2" && opzione != "3" && opzione != "4" && opzione != "5" && opzione != "6"   )
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
        addNameChat@Nodo2Server( nome )( esito );

        gruppo.nome = nome;
        gruppo.porta = args[1];
        gestioneGruppo@Nodo2Server(gruppo)


        //Se il nome non esiste già continua...
        if( esito == "true") {
        sendChat@Nodo2Server( nome );
        println@Console( "Chat di gruppo '" + nome + "' attiva " )(  );


        //scrivi una riga in modo che non sia mai vuoto
        file.filename = nome+".txt";
        file.content = "Chat di gruppo: "+nome+"\n";
        file.append = 1;
        writeFile@File( file )( void );


        pacchettoFirma.privKey=chiavePriv;

        println@Console( "Attendi che qualcuno si unisca al tuo gruppo prima di scrivere un messaggio" )(  );
        in( message );
        while( message != "$") {

          richiestaPorteGruppo@Nodo2Server(gruppo.nome)(porte);



          for (i=0, i<#porte.numeroPortaGruppo, i++){
            if (porte.numeroPortaGruppo[i] != args[1]){
            mySocketLocation = "socket://localhost:"+porte.numeroPortaGruppo[i];
            Nodo2Nodo.location = mySocketLocation;

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
        pacchettoFirma.mex=message;
        creaFirma@Privata(pacchettoFirma)(firmaMessaggio)
        infoChatGruppo.nomeChat = gruppo.nome;
        infoChatGruppo.mittente = args[0];
        infoChatGruppo.messaggio = message;
        infoChatGruppo.firma = firmaMessaggio.firmaDigitale;
        infoChatGruppo.chiavePub = chiavePub;
        invioChatGruppo@Nodo2Nodo( infoChatGruppo )
      }
    }
        in ( message )
  }
  Dati.numeroPorta=args[1];
  Dati.nomeChat=nome;
  uscitaGruppo@Nodo2Server(Dati)
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

      in( nomeGruppo );
      nomeChatGruppo = nomeGruppo;

      checkEsistenzaGruppo@Nodo2Server( nomeChatGruppo )( esito )
      if( esito == "false") {
        println@Console( "Nome gruppo non esistente" )(  )
      }
      else
      {
        gruppo.nome = nomeChatGruppo;
        gruppo.porta = args[1];
        gestioneGruppo2@Nodo2Server(gruppo);


        println@Console( "Chat: '" + nomeChatGruppo +"'")(  );
        println@Console( "Scrivi un messaggio, o premi '%' per visualizzare i messaggi precedenti" )(  )


        pacchettoFirma.privKey=chiavePriv;

            in( message );
            while ( message != "$") {


              richiestaPorteGruppo@Nodo2Server(gruppo.nome)(porte);


              for (i=0, i<#porte.numeroPortaGruppo, i++){
                if (porte.numeroPortaGruppo[i] != args[1]){
                mySocketLocation = "socket://localhost:"+porte.numeroPortaGruppo[i];
                Nodo2Nodo.location = mySocketLocation;

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
              //sendMessage@Nodo2Server( { .token = token, .message=message } )();

              pacchettoFirma.mex=message;
              creaFirma@Privata(pacchettoFirma)(firmaMessaggio)
              infoChatGruppo.nomeChat = gruppo.nome;
              infoChatGruppo.mittente = args[0];
              infoChatGruppo.messaggio = message;
              infoChatGruppo.firma = firmaMessaggio.firmaDigitale;
              infoChatGruppo.chiavePub = chiavePub;
              invioChatGruppo@Nodo2Nodo( infoChatGruppo )
            }
          }
              in( message )
            }
            Dati.numeroPorta=args[1];
            Dati.nomeChat=nomeChatGruppo;
            uscitaGruppo@Nodo2Server(Dati)
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

        cifraMsg.chiavePub=infoDestinatario.chiavePub;

        println@Console( "Inserisci il messaggio : " )(  )
        println@Console( "(per uscire dalla chat inviare '$')" )()
        println@Console( "(per visualizzare i messaggi precedenti inviare '%')" )()

        mySocketLocation = "socket://localhost:"+infoDestinatario.numeroPorta;
        Nodo2Nodo.location = mySocketLocation;

        in( messaggio )

        while ( messaggio != "$") {
          cifraMsg.msg=messaggio;

          if( messaggio == "%") {
            path1 = args[0] + "/" + args[0] +"-"+nomeNodoDestinatario+".txt"
            path2 = args[0] + "/" + nomeNodoDestinatario + "-"+args[0]+".txt"
            exists@File( path1 )( exists1 )
            exists@File( path2 )( exists2 )
            if( exists1 == true ) {
              println@Console( "===========================" )(  )
              println@Console( "Messaggi precedenti:" )(  )
              filePrivato1.filename = path1;
              readFile@File( filePrivato1 )( contenuto );
              println@Console( contenuto )(  );
              println@Console( "============================" )(  )
            }
            else if( exists2 == true ) {
              println@Console( "===========================" )(  )
              println@Console( "Messaggi precedenti:" )(  )
              filePrivato2.filename = path2;
              readFile@File( filePrivato2 )( contenuto );
              println@Console( contenuto )(  );
              println@Console( "============================" )(  )
            }
            else
            {
              println@Console( "===========================" )(  )
              println@Console( "Non hai mai avuto una chat privata con "+nomeNodoDestinatario )(  )
              println@Console( "===========================" )(  )
            }
          }

          encrypt@Privata(cifraMsg)(mexCifrato);
          informazioni.nomeMittente = args[0];                        // nome del mittente
          informazioni.nomeDestinatario = nomeNodoDestinatario;       // nome del destinatario
          informazioni.msg=mexCifrato.okok;
          invioPrivato@Nodo2Nodo( informazioni );
          in( messaggio )
        }
    }
  }
  deleteDir@File(args[0])(response);
  Nodi.nomeNodo=args[0];
  Nodi.numeroPorta=args[1];
  deleteNodo@Nodo2Server(Nodi);
  if (response == true){
    println@Console("Ciao "+args[0]+": hai abbandonato la rete.")()
    offline@Nodo2Server("L'utente " + args[0] + " ha abbandonato la rete!")
  }
}
