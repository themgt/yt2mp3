express = require 'express'
ffmpeg  = require 'fluent-ffmpeg'
http    = require 'http'
ytdl    = require 'ytdl'
path    = require 'path'
fs      = require 'fs'
qs      = require 'querystring'

app = express()
server = http.createServer(app)

app.configure ->
  app.set 'port', process.env.PORT || 3000
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'jade'

server.listen app.get('port'), ->
  console.log "Express server listening on port #{app.get 'port'}"

app.get '/', (req, res)     -> res.render 'index'
app.get '/play', (req, res) -> 
  ytdl.getInfo req.query.url, (err, info) ->
    if err?
      success = false
    else
      console.log info
      success = true
      title = info.title
      thumb = info.thumbnail_url
    
    res.render 'play', yt_url: req.query.url, title: title, thumb: thumb, success: success

app.get '/convert', (req, res) ->
  console.log "processing #{req.query.url}"
  
  res.contentType('mp3')
  dest = path.join( __dirname, 'tmp', req.query.url )
  
  ytdl.getInfo req.query.url, (err, info) ->
    if err?
      console.log err.message
      return
    
    pathToMovie = path.join( __dirname, 'tmp', info.video_id )
    
    if fs.existsSync("#{pathToMovie}.mp3")
      console.log "already downloaded"
      res.sendfile("#{pathToMovie}.mp3")
    else if fs.existsSync pathToMovie
      convert_and_send(pathToMovie, res)
    else
      console.log "downloading and converting"
      file = fs.createWriteStream(pathToMovie)
      ytdl(req.query.url).pipe(file)
      file.on 'close', -> convert_and_send(pathToMovie, res)

convert_and_send = (pathToMovie, res) ->
  console.log "converting"
  new ffmpeg({ source: pathToMovie, nolog: true })
    .withAudioCodec('libmp3lame')
    .toFormat('mp3')
    .saveToFile "#{pathToMovie}.mp3", (retcode, error) ->
      unless err?
        res.sendfile("#{pathToMovie}.mp3")