include "serverInterface.iol"
include "console.iol"
include "file.iol"
include "MonitorInterface.iol"


inputPort Server2Monitor {
  Location: "socket://localhost:9001"
  Protocol: sodep
  Interfaces: MonitorInterface
}

execution{ concurrent }

main {
  [ log( response ) ] {
  synchronized( token ) {
    println@Console( response )(  )
    }
  }
}
