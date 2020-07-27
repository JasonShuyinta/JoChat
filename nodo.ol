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
  .messaggio:string
}

type coppiaChiavi: void{
  .chiavePubblica:string
  .chiavePrivata:string
}

type messaggioCifrato:void{
  .messaggio:string
}

type firmaMessaggio:void{
  .firmaDigitale:string
}

interface PrivataInterface {
  RequestResponse:
  generatoreChiavi(void)(coppiaChiavi),
  encrypt(cifraMsg)(messaggioCifrato),
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
    FileNotFound => println@Console("Parametri di input non corretti")()
  )
  if (#args != 2){
    println@Console( "Inserisci: <nome nodo> <numeroPorta>" )()
    throw( FileNotFound )
  }

  //embedding dinamico del servizio nodo_service.ol
  socketLocation = "socket://localhost:"+args[1]+"/"
  with( emb ) {
    .filepath = "-C LOCATION=\"" + socketLocation + "\" nodo_service.ol";
    .type = "Jolie"
  };
  loadEmbeddedService@Runtime( emb )()
}

//embedding del servizio Java
embedded {
    Java: "lib.Privata" in Privata
}


main {
  registerForInput@Console(  )(  );
  request.nomeNodo = args[0];
  request.numeroPorta = args[1];

  //controlla l'esistenza del nodo tramite le cartelle
  exists@File( request.nomeNodo )( exists )

  while(exists == true) {
    println@Console( "Il nome inserito non è valido. Prova ad unserire un'altro nome: " )();
    in(request.nomeNodo)
    exists@File( request.nomeNodo )( exists )
  }
  //se il nodo non esiste, crea la sua cartella
  mkdir@File( request.nomeNodo )( response );

  //genera la chiave pubblica e la chiave privata per la la crittografia asimmetrica
  //e la firma digitale
  generatoreChiavi@Privata()(coppiaChiavi);
  chiavePub = coppiaChiavi.chiavePubblica;
  chiavePriv = coppiaChiavi.chiavePrivata;
  request.chiavePub=chiavePub;

  //imposta dinamicamente la location della porta del nodo
  Nodo2Nodo.location = "socket://localhost:"+args[1];
  SaveKey@Nodo2Nodo(chiavePriv)

  //aggiungi il nodo appena creato alla lista dei nodi del server
  join@Nodo2Server( request );
  println@Console(  )(  );


  while (opzione != "6") {
    println@Console( "=====================================" )(  );
    println@Console( "Premi (1) per visualizzare le chat di gruppo attive" )(  );
    println@Console( "Premi (2) per visualizzare i nodi attivi" )(  );
    println@Console( "Premi (3) per creare una chat di gruppo" )(  );
    println@Console( "Premi (4) per accedere a una chat di gruppo" )(  );
    println@Console( "Premi (5) per accedere a una chat privata" )(  );
    println@Console( "Premi (6) per uscire" )(  );
    in( opzione );

    if( opzione != "1" && opzione != "2" && opzione != "3" && opzione != "4" && opzione != "5" && opzione != "6"   ) {
      println@Console( "Il comando inserito non e' valido " )(  )
    }
    else if ( opzione == "1") {
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
    else if ( opzione == "3"){
      println@Console( "Inserisci il nome della tua Chat " )(  );
      in( nome );

      esito=null;

      //controlla che il nome del gruppo sia  disponibile
      while(esito!="true") {
        addNameChat@Nodo2Server( nome )( esito );

        //Se il nome del gruppo inserito e' valido inseriscilo nell'albero dei gruppi
        if( esito == "true") {
        gruppo.nome = nome;
        gruppo.porta = args[1];
        creaGruppo@Nodo2Server(gruppo);
        sendChat@Nodo2Server( nome );
        println@Console( "Chat di gruppo '" + nome + "' attiva " )(  );


        //Intestazione del file della chat di gruppo
        file.filename = nome+".txt";
        file.content = "Chat di gruppo: "+nome+"\n";
        file.append = 1;
        writeFile@File( file )( void );

        //assegna la chiave privata al pacchetto per la firma digitale
        pacchettoFirma.privKey=chiavePriv;

        println@Console( "Inserisci il messaggio : " )(  )
        println@Console( "(per uscire dalla chat inviare '$')" )()
        println@Console( "(per visualizzare i messaggi precedenti inviare '%')" )()
        println@Console( "(N.B Non puoi scrivere un messaggio senza partecipanti)" )()

        in( message );

        //il carattere "$" serve per uscire da questa sezione
        while( message != "$") {

          //ottieni le porte dei membri del gruppo
          richiestaPorteGruppo@Nodo2Server(gruppo.nome)(porte);

          //assegna dinamicamente la location della porta dei nodi membri del gruppo
          for (i=0, i<#porte.numeroPortaGruppo, i++){
            //controllo per evitare l'auto-invio del messaggio
            if (porte.numeroPortaGruppo[i] != args[1]){
              mySocketLocation = "socket://localhost:"+porte.numeroPortaGruppo[i];
              Nodo2Nodo.location = mySocketLocation;

              //visualizza i messaggi precedenti con il carattere "%"
              if( message == "%") {
                fileNome=nome+".txt";
                exists@File( fileNome )( exists3 )
                  if(exists3==true){
                    println@Console( "===========================" )(  )
                    println@Console( "Messaggi precedenti:" )(  )
                    letturaFile1.filename = nome +".txt";
                    readFile@File( letturaFile1 )( msgPrecedenti );
                    println@Console( msgPrecedenti )(  );
                    println@Console( "============================" )(  )
                  }
                i=#porte.numeroPortaGruppo
              }

              //tramite chiave privata e messaggio crea la firma digitale
              pacchettoFirma.messaggio=message;
              creaFirma@Privata(pacchettoFirma)(firmaMessaggio)

              //invia il messaggio, allegando la firma digitale
              infoChatGruppo.nomeChat = gruppo.nome;
              infoChatGruppo.mittente = args[0];
              infoChatGruppo.messaggio = message;
              infoChatGruppo.firma = firmaMessaggio.firmaDigitale;
              infoChatGruppo.chiavePub = chiavePub;
              invioChatGruppo@Nodo2Nodo( infoChatGruppo )
            }
          }
          //scrittura sul file dei messaggi
          stampaFile@Nodo2Nodo(infoChatGruppo)
          in( message )
        }

        //invio dati necessari al server per l'uscita dal gruppo
        Dati.numeroPorta=args[1];
        Dati.nomeChat=nome;
        uscitaGruppo@Nodo2Server(Dati)

        //ottiene le porte aggiornate dei membri del gruppo
        richiestaPorteGruppo@Nodo2Server(nome)(porte);
        for (i=0, i<#porte.numeroPortaGruppo, i++){
          if (porte.numeroPortaGruppo[i] != args[1]){
            mySocketLocation = "socket://localhost:"+porte.numeroPortaGruppo[i];
            Nodo2Nodo.location = mySocketLocation

            //invia una notifica ai membri rimanenti del gruppo
            notifica="Il nodo "+ args[0]+" ha abbandonato il gruppo "+nomeChatGruppo;
            sendNotifica@Nodo2Nodo(notifica)
            }
          }
        } else {
          println@Console( "ATTENZIONE: Nome già usato, inseriscine un altro" )(  )
          in( nome )
        }
      }
    }

    //"Premi 4 per accedere a una chat di gruppo"
    else if ( opzione == "4") {
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
        else {
          //aggiunta del nodo all'interno dell'albero che gestisce le chat di gruppo
          gruppo.nome = nomeChatGruppo;
          gruppo.porta = args[1];
          gestioneGruppo@Nodo2Server(gruppo);
          //recupera le porte dei nodi membri del gruppo
          richiestaPorteGruppo@Nodo2Server(nomeChatGruppo)(porte)
          //setta dinamicamente la location delle porte dei membri del gruppo
          for (i=0, i<#porte.numeroPortaGruppo, i++){
            if (porte.numeroPortaGruppo[i] != args[1]){
              mySocketLocation = "socket://localhost:"+porte.numeroPortaGruppo[i];
              Nodo2Nodo.location = mySocketLocation
              //notifica l'entrata di un nuovo nodo nel gruppo
              notifica="Il nodo "+ args[0]+" e' entrato nel gruppo "+nomeChatGruppo;
              sendNotifica@Nodo2Nodo(notifica)
            }
          }

          println@Console( "Chat: '" + nomeChatGruppo +"'")(  );
          println@Console( "Inserisci il messaggio : " )(  )
          println@Console( "(per uscire dalla chat inviare '$')" )()
          println@Console( "(per visualizzare i messaggi precedenti inviare '%')" )()
          println@Console( "(N.B Non puoi scrivere un messaggio senza partecipanti)" )()

          //assegna la chiave privata al pacchetto per la firma digitale
          pacchettoFirma.privKey=chiavePriv;
          in( message );

          //il carattere "$" permette l'uscita del gruppo
          while ( message != "$") {

            //ottieni le porte dei membri del gruppo
            richiestaPorteGruppo@Nodo2Server(gruppo.nome)(porte);

            //setta dinamicamente la location delle porte dei membri del gruppo
            for (i=0, i<#porte.numeroPortaGruppo, i++){
              if (porte.numeroPortaGruppo[i] != args[1]){
                mySocketLocation = "socket://localhost:"+porte.numeroPortaGruppo[i];
                Nodo2Nodo.location = mySocketLocation;

                //visualizza messaggi precedenti
                if( message == "%") {
                  fileNomeGruppo=nomeGruppo+".txt";
                  exists@File( fileNomeGruppo )( exists4 )
                    if(exists4==true){
                      println@Console( "===========================" )(  )
                      println@Console( "Messaggi precedenti:" )(  )
                      letturaFile2.filename = nomeGruppo +".txt";
                      readFile@File( letturaFile2 )( msgPrecedenti );
                      println@Console( msgPrecedenti )(  );
                      println@Console( "============================" )(  )
                    }
                  i=#porte.numeroPortaGruppo
                }

                //allega il messaggio assieme alla chiave privata per la firma digitale
                pacchettoFirma.messaggio=message;
                creaFirma@Privata(pacchettoFirma)(firmaMessaggio)

                //invia messaggio con firma digitale
                infoChatGruppo.nomeChat = gruppo.nome;
                infoChatGruppo.mittente = args[0];
                infoChatGruppo.messaggio = message;
                infoChatGruppo.firma = firmaMessaggio.firmaDigitale;
                infoChatGruppo.chiavePub = chiavePub;
                invioChatGruppo@Nodo2Nodo( infoChatGruppo )
              }
            }
            stampaFile@Nodo2Nodo(infoChatGruppo)
            in( message )
          }

          //gestisci l'uscita dal gruppo
          Dati.numeroPorta=args[1];
          Dati.nomeChat=nomeChatGruppo;
          uscitaGruppo@Nodo2Server(Dati);

          //ottieni le porte dei membri del gruppo
          richiestaPorteGruppo@Nodo2Server(nomeChatGruppo)(porte);
          for (i=0, i<#porte.numeroPortaGruppo, i++){
            if (porte.numeroPortaGruppo[i] != args[1]){
              //setta dinamicamente la locatione delle porte dei membri del gruppo
              mySocketLocation = "socket://localhost:"+porte.numeroPortaGruppo[i];
              Nodo2Nodo.location = mySocketLocation
              //invia una notifica ai membri rimanenti
              notifica="Il nodo "+ args[0]+" ha abbandonato il gruppo "+nomeChatGruppo;
              sendNotifica@Nodo2Nodo(notifica)
            }
          }
        }
      }
    }

    //Chat privata tra due nodi
    else if ( opzione == "5") {
      println@Console( "Inserisci il nome del nodo con cui vuoi comunicare: " )(  )
      in( nomeNodoDestinatario )
      //controllo l'esistenza del nodo tramite le cartelle
      exists@File( nomeNodoDestinatario )( exists )
      while(exists == false) {
        println@Console( "Nome inserito errato, inserisci il nome corretto del destinatario:" )(  );
        in( nomeNodoDestinatario )
        exists@File( nomeNodoDestinatario )( exists )
      };

      //ottieni le informazioni necessarie per chattare privatamente con un nodo
      getInfoDestinatario@Nodo2Server( nomeNodoDestinatario )( infoDestinatario );

      //ottieni la chiave pubblica del destinatario per la cifratura del messaggio
      cifraMsg.chiavePub=infoDestinatario.chiavePub;

      println@Console( "Inserisci il messaggio : " )(  )
      println@Console( "(per uscire dalla chat inviare '$')" )()
      println@Console( "(per visualizzare i messaggi precedenti inviare '%')" )()

      //setta dinamicamente la location della porta del destinatario
      mySocketLocation = "socket://localhost:"+infoDestinatario.numeroPorta;
      Nodo2Nodo.location = mySocketLocation;

      in( messaggio )

      while ( messaggio != "$") {
        cifraMsg.msg=messaggio;

        //visualizza i messaggi precedenti della chat
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
          else{
            println@Console( "===========================" )(  )
            println@Console( "Non hai mai avuto una chat privata con "+nomeNodoDestinatario )(  )
            println@Console( "===========================" )(  )
          }
        }

        //cripta il messaggio tramite chiave pubblica
        encrypt@Privata(cifraMsg)(messaggioCifrato);

        //invio del messaggio criptato
        informazioni.nomeMittente = args[0];
        informazioni.nomeDestinatario = nomeNodoDestinatario;
        informazioni.msg=messaggioCifrato.messaggio;
        invioPrivato@Nodo2Nodo( informazioni );
        in( messaggio )
      }
    }
  }
  //se l'utente digita "6" elimina la cartella associata al nodo
  deleteDir@File(args[0])(response);

  //elimina il nodo dalla lista dei nodi
  Nodi.nomeNodo=args[0];
  Nodi.numeroPorta=args[1];
  deleteNodo@Nodo2Server(Nodi);
  if (response == true){
    println@Console("Ciao "+args[0]+": hai abbandonato la rete.")()
    //invia notifica al monitor
    offline@Nodo2Server("L'utente " + args[0] + " ha abbandonato la rete!")
  }
}
