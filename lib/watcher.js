var Watcher, edge, fs, path, readline;

edge = null;

readline = require('readline');

fs = require('fs');

path = require('path');

Watcher = (function() {
  function Watcher(edgeObject) {
    if (edgeObject === null) {
      edge = require("edge");
    } else {
      edge = edgeObject;
    }
    this.bridgeObject = null;
    if (fs.existsSync(path.resolve(__dirname, '..', 'bin', 'Watcher.dll'))) {
      this.bridgeObject = edge.func({
        assemblyFile: path.resolve(__dirname, '..', 'bin', 'Watcher.dll'),
        typeName: 'NativeWatcher.Startup',
        methodName: 'Invoke'
      });
    } else if (fs.existsSync(path.resolve('Watcher.dll'))) {
      this.bridgeObject = edge.func({
        assemblyFile: path.resolve('Watcher.dll'),
        typeName: 'NativeWatcher.Startup',
        methodName: 'Invoke'
      });
    } else {
      console.error('No Watcher.dll found');
    }
  }

  Watcher.prototype.watch = function(fileSystemPath, callback, filter, recursive) {
    var payload;
    if (filter == null) {
      filter = "";
    }
    if (recursive == null) {
      recursive = true;
    }
    if (this.bridgeObject === null) {
      return console.error('watcher not initialized correctly');
    } else {
      payload = {
        path: fileSystemPath,
        filter: '',
        recursive: true,
        stopping: false,
        responseCallback: callback
      };
      return this.bridgeObject(payload, function(error, results) {
        if (error !== null) {
          console.log(error);
        }
      });
    }
  };

  Watcher.prototype.unwatch = function(fileSystemPath) {
    var payload;
    if (this.bridgeObject === null) {
      return console.error('watcher not initialized correctly');
    } else {
      return payload = {
        path: fileSystemPath,
        filter: '',
        recursive: true,
        stopping: true,
        responseCallback: function() {}
      };
    }
  };

  return Watcher;

})();


/*
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
 */
