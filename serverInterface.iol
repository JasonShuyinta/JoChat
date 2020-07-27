type Nodi:void{
.numeroPorta: string
.nomeNodo: string
}

type ListaChat: Chat

type ListaNodi: Nodi

type Chat: void {
    .nomeChat: string
}

type joinRequest: void {
    .nomeNodo: string
    .numeroPorta: string
    .chiavePub: string
}

type Dati:void{
    .numeroPorta: string
    .nomeChat: string
}

type Info: void {
    .numeroPorta: string
    .msg: string
    .usernameMittente: string
}

type Informazioni: void {
    .nomeMittente: string
    .nomeDestinatario: string
    .msg: string
}

type listaPartecipanti: void {
    .numeroPorta*: string
}

type infoDestinatario: void {
    .numeroPorta: string
    .chiavePub: string
}


type gruppo: void {
    .nome: string
    .porta: string
}

type porte: void {
    .numeroPortaGruppo*: string
}

type infoChatGruppo: void {
    .nomeChat: string
    .mittente: string
    .messaggio: string
    .firma: string
    .chiavePub: string
}

interface ServerInterface {
RequestResponse:
    getNodi( string ) ( string ),
    addNameChat( string )( string ),
    checkEsistenzaGruppo( string ) ( string ),
    getInfoDestinatario( string )( infoDestinatario ),
    getChat( void )( string ),
    sendInfoPrivate( Info )( void ),
    sendNomeGruppo( string )( listaPartecipanti ),
    richiestaPorteGruppo ( string ) (porte)
OneWay:
    join( joinRequest ),
    log(string),
    sendChat( string ),
    invioPrivato( Informazioni ),
    SaveKey( string ),
    creaGruppo( gruppo ),
    gestioneGruppo( gruppo ),
    invioChatGruppo( infoChatGruppo ),
    sendNotifica(string),
    offline(string),
    uscitaGruppo(Dati),
    deleteNodo(Nodi),
    stampaFile(infoChatGruppo)
}
