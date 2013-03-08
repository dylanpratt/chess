# server
WebSocketServer = require("ws").Server
http = require("http")
express = require("express")
chess = require("./chess.js")
_ = require("underscore")
fs = require("fs");

# point express to public (static) files
app = express()
app.use(express.static(__dirname + "/public"))

# create server and listen
server = http.createServer(app)
port = 8000
server.listen(port)

# create web socket server
wss = new WebSocketServer({server: server})

# some variables
currID = 0
sockets = {}
names = {}

wss.on("connection", (socket) ->
  sockets[currID] = socket
  myID = currID++
  #myName = req.query.name 
  # decide on colors. eventually I want to randomize this, as well as make sure if someone quits and rejoins they are assigned the proper color/board. For now first player is white, second is black. Also want to be able to have muliple games going at once.
  myName = ""
  myColor = ""
  chess.setPieces()

  listProps = (object) ->
    string = ""
    for key, value of object
      string += "#{key}: #{value}, "
    string

  # send the board/moves on load
  # socket.send(JSON.stringify({type: 'board', board: board.create()}))

  socket.on("message", (message) ->
    data = JSON.parse(message)
    #console.log("Received #{data} from #{myName}")
    switch(data.type)
      when 'greeting'
        myName = data.name
        if names[myName]? 
          console.log("#{myName} is back! Sending color and board info")
          # send initial board info
          socket.send(JSON.stringify({type: 'info', color: myColor, pieces: chess.pieces}))
        else 
          if myID is 0 then myColor = "white" else myColor = "black"
          names[myName] = {name: myName, color: myColor}
          fs.writeFileSync('names.txt', JSON.stringify(names))
          console.log("Player #{myID} joined (#{myName}). #{myName} will be #{myColor}")
          socket.send(JSON.stringify({type: 'info', color: myColor, pieces: chess.pieces}))
      when 'moveRequest'
        if chess.move(data.piece.id, data.place)
          console.log("Legal move. Sending to players.")
          # will have to only send to players of current game
          _.each sockets, (currSocket) ->
            currSocket.send(JSON.stringify({type: 'moveConfirm', piece: data.piece, place: data.place, gameOver: chess.gameOver, winner: chess.winner}))
        else 
          console.log("Illegal move! Notifying #{myName} to try again.")
          socket.send(JSON.stringify({type: 'moveDeny'}))

      else console.log("Data type not recognized.")
    )

  socket.on("close", ->
    console.log("#{myName} left")
    delete sockets[myID])
)

console.log("Server running and up at http://localhost:#{port}")