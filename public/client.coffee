# client
$(document).ready( ->
  
  #to get query:
  getPar = (par) ->
    par = par.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]")
    regexS = "[\\?&]#{par}=([^&#]*)"
    regex = new RegExp(regexS)
    results = regex.exec(window.location.search)
    if(results is null) then return ""
    else return decodeURIComponent(results[1].replace(/\+/g, " "))

  # open the socket
  url = "ws://#{window.location.host}"
  console.log("Opening web socket to #{url}")
  socket = if window['MozWebSocket'] then new MozWebSocket(url) else new WebSocket(url)

  name = getPar("name")
  console.log(name)
  color = ""
  #pieces = {}

  listProps = (object) ->
    string = ""
    for key, value of object
      string += "#{key}: #{value}, "
    string

# make pieces an observable array, and when server gives client pieces it does a push loop pushing every piece onto observablePieces, using var a = ko.observableArray(); ko.utils.arrayPushAll(a, [1, 2, 3]);
  ###
  setPieces = ->
    for n in [1..8]
      id = "p#{n}"
      pieces[id] = {id: "p#{n}", position: [n,2], color: "white", type: "pawn", firstMove: true}
    pieces.r1 = {id: "r1", position: [1,1], color: "white", type: "rook"}
    pieces.r2 = {id: "r2", position: [8,1], color: "white", type: "rook"}
    pieces.k1 = {id: "k1", position: [2,1], color: "white", type: "knight"}
    pieces.k2 = {id: "k2", position: [7,1], color: "white", type: "knight"}
    pieces.b1 = {id: "b1", position: [3,1], color: "white", type: "bishop"}
    pieces.b2 = {id: "b2", position: [6,1], color: "white", type: "bishop"}
    pieces.q1 = {id: "q1", position: [5,1], color: "white", type: "queen"}
    pieces.king1 = {id: "king1", position: [4,1], color: "white", type: "king"}
   for n in [9..16]
      id = "p#{n}"
      pieces[id] = {id: "p#{n}", position: [n-8,7], color: "black", type: "pawn", firstMove: true}
    pieces.r3 = {id: "r3", position: [1,8], color: "black", type: "rook"}
    pieces.r4 = {id: "r4", position: [8,8], color: "black", type: "rook"}
    pieces.k3 = {id: "k3", position: [2,8], color: "black", type: "knight"}
    pieces.k4 = {id: "k4", position: [7,8], color: "black", type: "knight"}
    pieces.b3 = {id: "b3", position: [3,8], color: "black", type: "bishop"}
    pieces.b4 = {id: "b4", position: [6,8], color: "black", type: "bishop"}
    pieces.q2 = {id: "q2", position: [5,8], color: "black", type: "queen"}
    pieces.king2 = {id: "king2", position: [4,8], color: "black", type: "king"}

  setPieces()
  ###
  
  # UI stuff
  samePos = (p1, p2) ->
    (p1[0] is p2[0]) and (p1[1] is p2[1])

  move = (piece, place) ->

  # Knockout UI stuff
  class tile
    constructor: (data) ->
      @color = data.color
      @position = data.position
      myPos = @position
      @piece = ko.computed => 
        _.find pieces, (piece) -> samePos(myPos, piece.position)

  pieces = ko.observableArray([])

  class chessViewModel 
    constructor: ->
      # create the board
      @tiles = ko.observableArray([])
      for y in [1..8]
        for x in [8..1]
          if (x+y)%2 is 0 then col = "black" else col = "white"
          @tiles.unshift(new tile({color: col, position: [x,y]}))
      @move = (piece, place) ->
        pieceToMove = _.find pieces, (foundPiece) -> samePos(foundPiece.position, piece.position)
        pieceToMove.position = place

  chessVM = new chessViewModel()
  ko.applyBindings(chessVM)
  
  # jQuery UI stuff
  $('#piece1').data('position', [2,8])
  $('#tile1').data('position', [1,8])
  moveAllowed = false
  activePiece = null
  $( ->
    $(".piece").draggable({ 
      revert: "invalid"
      start: (event, ui) -> 
        # once a piece is picked up, browse through all the tiles for the possible moves, light up those tiles(possibly in droppable)
        #if samePos($(this).position, [8,1]) then moveAllowed = true
        console.log ko.dataFor(this).piece()
        activePiece = ko.dataFor(this).piece()
    })
    $(".tile").droppable({
      activeClass: "active"
      hoverClass: "hover" 
      # drops need to fit entirely in the tile
      tolerance: "fit"
      # only accept drop if moveAllowed is true
      accept: -> true
      ###
        socket.send(JSON.stringify({type: 'moveRequest', piece: activePiece, place: ko.dataFor(this).position}))
        console.log "active place: #{ko.dataFor(this).position}"
        moveAllowed
        ###
      # to do on drop
      drop: (event, ui) -> 
        # enable sweet animation if there's a battle?
        tile = ko.dataFor(this)
        socket.send(JSON.stringify({type: 'moveRequest', piece: activePiece, place: tile.position}))
        activePiece.position = tile.position
        console.log("Moved #{activePiece} to #{tile.position}")
        #tile.piece().position = tile.position
        #console.log tile.piece().position
    })
  )
  
    # listeners
  socket.onopen = -> 
    console.log("Socket opened and sending server greeting")
    #send the name to the server after getting it from the query string
    socket.send(JSON.stringify({type: 'greeting', name: name}))

  socket.onmessage = (message) ->
    data = JSON.parse(message.data)
    #console.log("Received #{data} from server")
    switch(data.type)
      when 'info'
        console.log("Receieved initial info")
        color = data.color
        ko.utils.arrayPushAll(pieces, _.toArray(data.pieces))
        console.log(pieces())
        console.log(pieces()[0])
        #pieces = data.pieces
        #_.each data.pieces, (piece) ->
        #  pieces[piece.id] = piece 
        #console.log(listProps(pieces))

      when 'moveConfirm'
        #move(data.piece, data.place)
        console.log("Legal move")
        moveAllowed = true
        if data.gameOver 
          if data.winner is color then console.log "Congrats #{name}! Domination station"
          else console.log "Ooh #{name}, what happened man? I thought you had that."
      when 'moveDeny'
        console.log "Illegal move! Try again foo"
        moveAllowed = false
      else console.log("Data type not recognized.")

)