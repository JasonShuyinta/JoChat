include "console.iol"
include "serverInterface.iol"
include "file.iol"


execution{ concurrent }

type decifraMsg:void{
  .messaggioCifrato: string
  .chiavePriv: string
}

type messNormale:void{
  .messaggioDecifrato:string
}

type controllo:void{
  .firma:string
  .keyPub:string
  .messaggio:string
}

type verifica:void{
  .risultato:string
}

interface ControlliInterface {
  RequestResponse:
    controlloFirma(controllo)(verifica),
    decrypt(decifraMsg)(messNormale)
}

inputPort Server2Nodo {
    Location: LOCATION
    Protocol: sodep
    Interfaces: ServerInterface
}

outputPort Privata {
    Interfaces: ControlliInterface
}

embedded {
    Java:"lib.Privata" in Privata
}

main {

  //salvataggio della chiave privata del nodo
  [ SaveKey( infoPrivata ) ] {
    synchronized( token ) {
    global.chiaviPrivate = infoPrivata
  }
}

  //invio di un messaggio privato con decifratura e scrittura su file
  [ invioPrivato( info )] {
    synchronized( token ) {
      decifraMsg.chiavePriv = global.chiaviPrivate;
      decifraMsg.messaggioCifrato = info.msg; 
      decrypt@Privata(decifraMsg)(messNormale);

      testo=messNormale.messaggioDecifrato;
      pathMittente1 = info.nomeMittente + "/" + info.nomeMittente +"-"+info.nomeDestinatario+".txt"
      pathMittente2 = info.nomeMittente + "/" + info.nomeDestinatario + "-"+info.nomeMittente+".txt"

      pathDestinatario1 = info.nomeDestinatario + "/" + info.nomeMittente +"-"+info.nomeDestinatario+".txt"
      pathDestinatario2 = info.nomeDestinatario + "/" + info.nomeDestinatario + "-"+info.nomeMittente+".txt"

      exists@File( pathMittente1 )( exists1 )
      exists@File( pathMittente2 )( exists2 )
      if(testo!="%"){
        if( exists1 == true ) {
          file.filename = pathMittente1
          file.content = info.nomeMittente + ": " +testo + "\n"
          file.append = 1
          writeFile@File( file )( void )

          file2.filename = pathDestinatario1
          file2.content = info.nomeMittente + ": " +testo + "\n"
          file2.append = 1
          writeFile@File( file2 )( void )
        }

        else if ( exists2 == true ) {
          file3.filename = pathMittente2
          file3.content = info.nomeMittente + ": " +testo + "\n"
          file3.append = 1
          writeFile@File( file3 )( void )

          file4.filename = pathDestinatario2
          file4.content = info.nomeMittente + ": " +testo + "\n"
          file4.append = 1
          writeFile@File( file4 )( void )
        }

        else {
          file5.filename = info.nomeMittente + "/" + info.nomeMittente +"-"+info.nomeDestinatario+".txt"
          file5.content = info.nomeMittente + ": " +testo + "\n"
          file5.append = 1
          writeFile@File( file5 )( void )

          file6.filename = info.nomeDestinatario + "/" + info.nomeMittente +"-"+info.nomeDestinatario+".txt"
          file6.content = info.nomeMittente + ": " +testo + "\n"
          file6.append = 1
          writeFile@File( file6 )( void )
        }
      }
    }
  }

  //invio della notifica ai vari nodi membri di un gruppo
  [sendNotifica(notifica)]{
    synchronized( token ) {
      println@Console(notifica)()
    }
  }

  //controllo della firma digitale sui messaggi inviati
  [ invioChatGruppo( infoChatGruppo ) ]{
    synchronized( token ) {
      controllo.firma=infoChatGruppo.firma;
      controllo.messaggio=infoChatGruppo.messaggio;
      //controllo.messaggio="TEST";
      controllo.keyPub=infoChatGruppo.chiavePub;
      controlloFirma@Privata(controllo)(verifica)
      if(verifica.risultato=="fallito"){
        println@Console("MESSAGGIO ANOMALO")()
      }
      else{
        if(infoChatGruppo.messaggio!="%"){
          print@Console( infoChatGruppo.mittente + "@" + infoChatGruppo.nomeChat + ":" )();
          println@Console( infoChatGruppo.messaggio )()
        }
      }
    }
  }

  //stampa sui file i messaggi della chat di gruppo
  [stampaFile( infoChatGruppo)]{
    synchronized( token ) {
      if(infoChatGruppo.messaggio!="%"){
      file7.filename = infoChatGruppo.nomeChat + ".txt";
      file7.content = infoChatGruppo.mittente + ":" + infoChatGruppo.messaggio + "\n";
      file7.append = 1;
      writeFile@File( file7 )( void )
      }
    }
  }

}
