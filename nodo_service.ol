include "console.iol"
include "serverInterface.iol"
include "file.iol"


execution{ concurrent }

type decifraMsg: void{
  .msg:raw
  .valoreN:string
  .valoreD:string
}

interface DecryptInterface {
  RequestResponse:
    decrypt(decifraMsg)(string)
}


inputPort Server2Nodo {
    Location: LOCATION
    Protocol: sodep
    Interfaces: ServerInterface
}


outputPort Privata {
    Interfaces: DecryptInterface
}

embedded {
    Java:"lib.Privata" in Privata
}


main {

      [ SaveKey( infoPrivata ) ] {
        global.valoreN = infoPrivata.valN;
        global.valoreD = infoPrivata.valD
      }

    [ invioPrivato( info )] {

      decifraMsg.valoreN = global.valoreN;
      decifraMsg.valoreD = global.valoreD;
      decifraMsg.msg = info.msg; //messaggio cifrato
      //println@Console(decifraMsg.valoreN)();
      decrypt@Privata(decifraMsg)(MessaggioDecifrato);

      pathMittente1 = info.nomeMittente + "/" + info.nomeMittente +"-"+info.nomeDestinatario+".txt"
      pathMittente2 = info.nomeMittente + "/" + info.nomeDestinatario + "-"+info.nomeMittente+".txt"

      pathDestinatario1 = info.nomeDestinatario + "/" + info.nomeMittente +"-"+info.nomeDestinatario+".txt"
      pathDestinatario2 = info.nomeDestinatario + "/" + info.nomeDestinatario + "-"+info.nomeMittente+".txt"

      exists@File( pathMittente1 )( exists1 )
      exists@File( pathMittente2 )( exists2 )

      if( exists1 == true ) {
        file.filename = pathMittente1
        file.content = info.nomeMittente + ": " +MessaggioDecifrato + "\n"
        file.append = 1
        writeFile@File( file )( void )

        file2.filename = pathDestinatario1
        file2.content = info.nomeMittente + ": " +MessaggioDecifrato + "\n"
        file2.append = 1
        writeFile@File( file2 )( void )
      }

      else if ( exists2 == true ) {
        file3.filename = pathMittente2
        file3.content = info.nomeMittente + ": " +MessaggioDecifrato + "\n"
        file3.append = 1
        writeFile@File( file3 )( void )

        file4.filename = pathDestinatario2
        file4.content = info.nomeMittente + ": " +MessaggioDecifrato + "\n"
        file4.append = 1
        writeFile@File( file4 )( void )
      }
      else {

        file5.filename = info.nomeMittente + "/" + info.nomeMittente +"-"+info.nomeDestinatario+".txt"
        file5.content = info.nomeMittente + ": " +MessaggioDecifrato + "\n"
        file5.append = 1
        writeFile@File( file5 )( void )

        file6.filename = info.nomeDestinatario + "/" + info.nomeMittente +"-"+info.nomeDestinatario+".txt"
        file6.content = info.nomeMittente + ": " +MessaggioDecifrato + "\n"
        file6.append = 1
        writeFile@File( file6 )( void )
      }
}

    [ setMessage( request ) ]{
    print@Console( request.username + "@" + request.chat_name + ":" )();
    println@Console( request.message )()
    }
}
