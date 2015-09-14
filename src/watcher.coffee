# edge = require('edge')
edge = null
readline = require('readline')
fs = require('fs')
# edge = require('electron-edge2')
path = require('path')

class Watcher
  constructor: (edgeObject)->
    edge = edgeObject
    if ! edgeObject?
      edge = require("edge")

    @bridgeObject = null
    if fs.existsSync(path.resolve(__dirname, '..', 'bin', 'NativeWatcher.dll'))
      @bridgeObject = edge.func({
        assemblyFile: path.resolve(__dirname, '..', 'bin', 'NativeWatcher.dll'),
        typeName: 'NativeWatcher.Startup',
        methodName: 'Invoke'})
    else if fs.existsSync(path.resolve('NativeWatcher.dll'))
      @bridgeObject = edge.func({
        assemblyFile: path.resolve('NativeWatcher.dll'),
        typeName: 'NativeWatcher.Startup',
        methodName: 'Invoke'})
    else
      console.error 'No NativeWatcher.dll found'
    
  watch: (fileSystemPath, callback, recursive=true, filter="") ->
    if @bridgeObject == null
      console.error 'watcher not initialized correctly'
    else
      payload = 
        path: fileSystemPath
        filter: ''
        recursive: true
        stopping: false
        stoppingAll: false
        responseCallback: callback

      # payload2 = 
      #   path: path.resolve('H:')
      #   filter: ''
      #   recursive: true
      #   stopping: false
      #   responseCallback: (data, callback) ->
      #     callback null, true
      #     return
      @bridgeObject payload, (error, results) ->
        if error != null
          console.log error
        return
  unwatch: (fileSystemPath) ->
    if @bridgeObject == null
      console.error 'watcher not initialized correctly'
    else
      payload = 
        path: fileSystemPath
        filter: ''
        recursive: true
        stopping: true
        stoppingAll: false
        responseCallback: ->
      @bridgeObject payload, (error, results) ->
        if error != null
          console.log error
        return
  unwatchAll: ->
    if @bridgeObject == null
      console.error 'watcher not initialized correctly'
    else
      payload = 
        path: fileSystemPath
        filter: ''
        recursive: true
        stopping: true
        stoppingAll: true #can't remember if this is correct or not.
        responseCallback: ->    
###
  _listener_action = edge.func("""
        using System.Threading.Tasks;\

        public class Watcher\
        {
            public static System.IO.FileSystemWatcher theWatcher;//Possibly add hash here.
        }

        public class Startup
        {
            public async Task<object> Invoke(dynamic input)
            {
              if((bool)input.stopping)
                {
                  Watcher.theWatcher.EnableRaisingEvents = false;
                  return false;
                }
            	var responseCallback = (System.Func<object, Task<object>>)input.responseCallback;

                Watcher.theWatcher = new System.IO.FileSystemWatcher();
                Watcher.theWatcher.NotifyFilter = System.IO.NotifyFilters.LastAccess | System.IO.NotifyFilters.LastWrite
                | System.IO.NotifyFilters.FileName | System.IO.NotifyFilters.DirectoryName;
                Watcher.theWatcher.IncludeSubdirectories = (bool)input.recursive;
                Watcher.theWatcher.Path = (string)input.path;
                //System.Console.WriteLine(\"Path:\");
                //System.Console.WriteLine(Watcher.theWatcher.Path);
                Watcher.theWatcher.Filter = (string)input.filter;
                Watcher.theWatcher.Changed += delegate(object sender, System.IO.FileSystemEventArgs e) {
                    //System.Console.WriteLine(\"Changed\");
                    responseCallback(new string[]{\"Changed\", e.FullPath});};
                Watcher.theWatcher.Created+= delegate(object sender, System.IO.FileSystemEventArgs e){
                    //System.Console.WriteLine(\"Created\");
                    responseCallback(new string[]{\"Created\", e.FullPath});};
                Watcher.theWatcher.Deleted += delegate(object sender, System.IO.FileSystemEventArgs e){
                    //System.Console.WriteLine(\"Deleted\");
                    responseCallback(new string[]{\"Deleted\", e.FullPath});};
                Watcher.theWatcher.Renamed += delegate(object sender, System.IO.RenamedEventArgs e){
                    //System.Console.WriteLine(\"Rename\");
                    responseCallback(new string[]{\"Rename\", e.OldFullPath, e.FullPath});};

                // Begin watching
                Watcher.theWatcher.EnableRaisingEvents = true;

                return true;
            }
        }
    """
  )
###

  # ChangedCallback = (file) ->
  #   console.log 'File Changed: ' + file + '. Override ChangedCallback to customize'
  #   return

  # CreatedCallback = (file) ->
  #   console.log 'File Created: ' + file + '. Override CreatedCallback to customize'
  #   return

  # DeletedCallback = (file) ->
  #   console.log 'File Deleted: ' + file + '. Override DeletedCallback to customize'
  #   return

  # RenameCallback = (old_name, new_name) ->
  #   console.log 'File Rename: ' + file + '. Override RenameCallback to customize'
  #   return

  # responseCallback = (data, callback) ->
  #   switch data[0]
  #     when 'Changed'
  #       ChangedCallback data[1]
  #     when 'Created'
  #       CreatedCallback data[1]
  #     when 'Deleted'
  #       DeletedCallback data[1]
  #     when 'Rename'
  #       RenameCallback data[1], data[2]
  #   callback null, true
  #   return

  # listen = (fileSystemPath, callback, recursive=true, filter="") ->
  #   payload = 
  #     path: fileSystemPath
  #     filter: filter
  #     recursive: recursive
  #     stopping: false
  #     responseCallback: callback
  #   listener_action payload, (error, result) ->
  #     if error
  #       throw error
  #     return
      
# rl = readline.createInterface(
#   input: process.stdin
#   output: process.stdout)
# rl.question 'Press enter to exit', (answer) ->
#   rl.close()
#   return

module.exports = Watcher;